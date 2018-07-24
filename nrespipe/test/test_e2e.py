import pytest
import os
from glob import glob
import shutil
from nrespipe.dbs import create_db
from nrespipe.utils import post_to_fits_exchange
from nrespipe import tasks
import time
from astropy.io import fits
from nrespipe.settings import date_format
from nrespipe.test.zero_files import zero_files
import datetime
from dateutil import parser
from nrespipe import dbs

sites = [os.path.basename(site_path) for site_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], '*'))]
instruments = [os.path.join(site, os.path.basename(instrument_path)) for site in sites
               for instrument_path in glob(os.path.join(os.path.join(os.environ['NRES_DATA_ROOT'], site, '*')))]

days_obs = [os.path.join(instrument, os.path.basename(dayobs_path)) for instrument in instruments
            for dayobs_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, '*'))]

cameras = {'lsc': 'fl09', 'elp': 'fl17'}

nres_pipeline_directories = ['bias', 'blaz', 'ccor', 'class', 'config', 'csv', 'dark', 'dble', 'diag', 'expm',
                             'extr', 'flat', 'plot', 'rv', 'spec', 'tar', 'temp', 'thar', 'trace', 'trip', 'zero']


def wait_for_celery_to_finish():
    still_running = True
    celery_inspector = tasks.app.control.inspect()
    while still_running:
        if len(celery_inspector.active()['celery@worker']) == 0 and len(celery_inspector.scheduled()['celery@worker']) == 0 \
                and len(celery_inspector.reserved()['celery@worker']) == 0:
            still_running = False
        else:
            time.sleep(1)


def setup_directory_tree():
    for instrument in instruments:
        reduced_path = os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced')

        for nres_pipeline_directory in nres_pipeline_directories:
            full_pipeline_directory_path = os.path.join(reduced_path, nres_pipeline_directory)
            if not os.path.exists(full_pipeline_directory_path):
                os.makedirs(full_pipeline_directory_path)


def copy_config_files():
    for instrument in instruments:
        config_dir = os.path.join(pytest.config.rootdir, 'config')
        for config_file in glob(os.path.join(config_dir, '*')):
            shutil.copy(config_file, os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'config'))


def copy_csv_files():
    for instrument in instruments:
        csv_dir = os.path.join(pytest.config.rootdir, 'csv')
        for csv_file in glob(os.path.join(csv_dir, '*.csv')):
            shutil.copy(csv_file, os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'csv'))


def get_instrument_meta_data(file_path):
    data, header = fits.getdata(file_path, header=True)
    return header['SITEID'], header['TELESCOP'], header['INSTRUME']


def get_stack_time_range(filenames):
    dates_of_observations = [fits.getdata(filename, header=True)[1]['DATE-OBS']
                             for filename in filenames]
    start = parser.parse(min(dates_of_observations))
    # Pad the start and end times by a minute to deal with round-off errors
    start -= datetime.timedelta(seconds=60)

    end = parser.parse(max(dates_of_observations))
    end += datetime.timedelta(seconds=60)
    return start.strftime(date_format), end.strftime(date_format)


def stack_calibrations(filenames, calibration_type):
    for day_obs in days_obs:
        calibration_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', filenames))
        if len(calibration_files) > 0:
            start, end = get_stack_time_range(calibration_files)
            site, nres_instrument, camera = get_instrument_meta_data(calibration_files[0])
            tasks.make_stacked_calibrations.delay(site, camera, calibration_type, [start, end],
                                                  os.environ['NRES_DATA_ROOT'], nres_instrument)
    wait_for_celery_to_finish()


def reduce_individual_frames(filenames):
    for day_obs in days_obs:
        files_to_process = glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', filenames))
        for file_to_process in files_to_process:
            post_to_fits_exchange(os.environ['FITS_BROKER'], file_to_process)
    wait_for_celery_to_finish()


def test_if_internal_files_were_created(input_filenames, expected_internal_filenames):
    input_files = []
    for day_obs in days_obs:
        input_files += glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', input_filenames))
    created_files = []
    for instrument in instruments:
        created_files += glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced',
                                           expected_internal_filenames))
    assert len(input_files) == len(created_files)


def test_if_stacked_calibrations_were_created(raw_filenames, calibration_type):
    number_of_stacks_that_should_have_been_created = 0
    created_stacked_calibrations = []
    for day_obs in days_obs:
        if len(glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', raw_filenames))) > 0:
            number_of_stacks_that_should_have_been_created += 1
        created_stacked_calibrations += glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'specproc',
                                                          calibration_type.lower() + '*.fits*'))
    assert len(days_obs) == len(created_stacked_calibrations)


def set_images_to_unprocessed_in_db(filenames):
    db_session = dbs.get_session(os.environ['DB_ADDRESS'])
    files_to_remove = db_session.Query(dbs.ProcessingState).filter(dbs.ProcessingState.filename.like(filenames)).all()
    for file_to_remove in files_to_remove:
        file_to_remove.processed = False
        db_session.add(file_to_remove)
    db_session.commit()
    db_session.close()


def remove_blaze_files_from_csv(csv_file):
    with open(csv_file) as file_stream:
        csv_rows = file_stream.readlines()
    cleaned_csv_rows = [row for row in csv_rows if 'blaz' not in row.lower()]
    with open(csv_file, 'w') as file_stream:
        file_stream.writelines(cleaned_csv_rows)


@pytest.fixture(scope='module')
def init():
    setup_directory_tree()
    copy_config_files()
    copy_csv_files()
    create_db(os.environ['DB_URL'])


@pytest.fixture(scope='module')
def process_bias_frames(init):
    reduce_individual_frames('*b00.fits*')


@pytest.fixture(scope='module')
def stack_bias_frames(process_bias_frames):
    stack_calibrations('*b00.fits*', 'BIAS')


@pytest.fixture(scope='module')
def process_dark_frames(stack_bias_frames):
    reduce_individual_frames('*d00.fits*')


@pytest.fixture(scope='module')
def stack_dark_frames(process_dark_frames):
    stack_calibrations('*d00.fits*', 'DARK')


@pytest.fixture(scope='module')
def make_tracefiles(stack_dark_frames):
    tasks.run_trace0.delay('/nres/code/config/lsc_trace.2017a.txt', 'lsc', 'fl09', 'nres01', os.environ['NRES_DATA_ROOT'])
    tasks.run_trace0.delay('/nres/code/config/nres02_trace.2017a.txt', 'elp', 'fl17', 'nres02', os.environ['NRES_DATA_ROOT'])
    for site_day_obs in days_obs:
        [site, nres_instrument, day_obs] = site_day_obs.split(os.sep)
        tasks.refine_trace_from_night.delay(site, cameras[site], nres_instrument,
                                            os.environ['NRES_DATA_ROOT'], night=day_obs)
    wait_for_celery_to_finish()


@pytest.fixture(scope='module')
def process_flat_frames(make_tracefiles):
    reduce_individual_frames('*w00.fits*')


@pytest.fixture(scope='module')
def stack_flat_frames(process_flat_frames):
    stack_calibrations('*w00.fits*', 'FLAT')


@pytest.fixture(scope='module')
def process_arc_frames(stack_flat_frames):
    reduce_individual_frames('*a00.fits*')


@pytest.fixture(scope='module')
def stack_arc_frames(process_arc_frames):
    stack_calibrations('*a00.fits*', 'ARC')


@pytest.fixture(scope='module')
def extract_zero_frames(stack_arc_frames):
    for site in ['elp', 'lsc']:
        for file_to_process in zero_files[site]['files']:
            post_to_fits_exchange(os.environ['FITS_BROKER'],
                                  os.path.join(os.environ['NRES_DATA_ROOT'], file_to_process))
    wait_for_celery_to_finish()


@pytest.fixture(scope='module')
def make_zero_frames(extract_zero_frames):
    for site in zero_files:
        files_to_stack = [os.path.join(os.environ['NRES_DATA_ROOT'], f) for f in zero_files[site]['files']]
        start, end = get_stack_time_range(files_to_stack)
        tasks.make_stacked_calibrations.delay(site, zero_files[site]['camera'], 'TEMPLATE', [start, end],
                                              os.environ['NRES_DATA_ROOT'], zero_files[site]['nres_instrument'],
                                              target=zero_files[site]['target'])
    wait_for_celery_to_finish()


@pytest.fixture(scope='module')
def cleanup_zero_creation(make_zero_frames):
    for instrument in instruments:
        remove_blaze_files_from_csv(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced',
                                                 'csv', 'standards.csv'))
    set_images_to_unprocessed_in_db('%e00.fits%')


@pytest.fixture(scope='module')
def reduce_science_frames(cleanup_zero_creation):
    reduce_individual_frames('*e00.fits*')


@pytest.mark.incremental
@pytest.mark.e2e
class TestE2E(object):
    def test_if_bias_frames_were_created(self, process_bias_frames):
        test_if_internal_files_were_created('*b00.fits*', os.path.join('bias', '*.fits'))

    def test_if_stacked_bias_frame_was_created(self, stack_bias_frames):
        test_if_stacked_calibrations_were_created('*b00.fits', 'bias')

    def test_if_dark_frames_were_created(self, process_dark_frames):
        test_if_internal_files_were_created('*d00.fits*', os.path.join('dark', '*.fits'))

    def test_if_stacked_dark_frame_was_created(self, stack_dark_frames):
        test_if_stacked_calibrations_were_created('*d00.fits', 'dark')

    def test_if_flat_frames_were_created(self, process_flat_frames):
        test_if_internal_files_were_created('*w00.fits*', os.path.join('flat', '*.fits'))

    def test_if_stacked_flat_frame_was_created(self, stack_flat_frames):
        test_if_stacked_calibrations_were_created('*w00.fits', 'flat')

    def test_if_arc_frames_were_created(self, process_arc_frames):
        test_if_internal_files_were_created('*a00.fits*', os.path.join('dble', '*.fits'))

    def test_if_stacked_arc_frame_was_created(self, stack_arc_frames):
        test_if_stacked_calibrations_were_created('*a00.fits', 'arc')

    def test_if_zero_frame_was_created(self, cleanup_zero_creation):
        for instrument in instruments:
            created_zero_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'zero', '*.fits'))
            assert len(created_zero_files) > 0

    def test_if_science_frames_were_extracted(self, reduce_science_frames):
        test_if_internal_files_were_created('*e00.fits*', os.path.join('extr', '*.fits'))

    def test_if_science_tar_files_were_created(self, reduce_science_frames):
        assert False

    def test_if_science_tar_files_have_fits_file_and_pdf_file(self, reduce_science_frames):
        assert False
