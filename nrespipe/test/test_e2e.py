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
import tarfile
import logging

logger = logging.getLogger('nrespipe')
sites = [os.path.basename(site_path) for site_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], '*'))]
instruments = [os.path.join(site, os.path.basename(instrument_path)) for site in sites
               for instrument_path in glob(os.path.join(os.path.join(os.environ['NRES_DATA_ROOT'], site, '*')))]

days_obs = [os.path.join(instrument, os.path.basename(dayobs_path)) for instrument in instruments
            for dayobs_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, '*'))]

cameras = {'lsc': 'fl09', 'elp': 'fl17'}

nres_pipeline_directories = ['bias', 'blaz', 'ccor', 'class', 'config', 'csv', 'dark', 'dble', 'diag', 'expm',
                             'extr', 'flat', 'plot', 'rv', 'spec', 'tar', 'temp', 'thar', 'trace', 'trip', 'zero']


def wait_for_celery_to_finish():
    celery_inspector = tasks.app.control.inspect()
    logger.info('Processing:')
    logger_counter = 0
    while True:
        if logger_counter % 5 == 0:
            logger.info('Processing: ' + '. ' * (logger_counter // 5))
        queues = [celery_inspector.active(), celery_inspector.scheduled(), celery_inspector.reserved()]
        time.sleep(1)
        logger_counter += 1
        if any([queue is None or 'celery@worker' not in queue for queue in queues]):
            # Reset the celery connection
            celery_inspector = tasks.app.control.inspect()
            continue
        if all([len(queue['celery@worker']) == 0 for queue in queues]):
            break


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
    for instrument in instruments:
        created_stacked_calibrations += glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'tar',
                                                          calibration_type.lower() + '*.fits*'))
    assert len(set(created_stacked_calibrations)) == number_of_stacks_that_should_have_been_created


def set_images_to_unprocessed_in_db(filenames):
    db_session = dbs.get_session(os.environ['DB_URL'])
    files_to_remove = db_session.query(dbs.ProcessingState).filter(dbs.ProcessingState.filename.like(filenames)).all()
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


def fix_flags_in_zeros_csv(csv_file):
    with open(csv_file) as file_stream:
        csv_rows = file_stream.readlines()

    csv_rows = [row.replace("\"00", "\"01") for row in csv_rows]
    with open(csv_file, 'w') as output_file_stream:
        output_file_stream.writelines(csv_rows)


@pytest.fixture(scope='module')
def init():
    setup_directory_tree()
    copy_config_files()
    copy_csv_files()
    create_db(os.environ['DB_URL'])


@pytest.fixture(scope='module')
def make_tracefiles():
    tasks.run_trace0.delay('/nres/code/config/lsc_trace.2017a.txt', 'lsc', 'fl09', 'nres01', os.environ['NRES_DATA_ROOT'])
    tasks.run_trace0.delay('/nres/code/config/nres02_trace.2017a.txt', 'elp', 'fl17', 'nres02', os.environ['NRES_DATA_ROOT'])
    for site_day_obs in days_obs:
        [site, nres_instrument, day_obs] = site_day_obs.split(os.sep)
        tasks.refine_trace_from_night.delay(site, cameras[site], nres_instrument,
                                            os.environ['NRES_DATA_ROOT'], night=day_obs)
    wait_for_celery_to_finish()


@pytest.fixture(scope='module')
def extract_zero_frames():
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


@pytest.mark.bias_ingestion
class TestBiasIngestion:
    @pytest.fixture(autouse='true')
    def process_bias_frames(self, init):
        reduce_individual_frames('*b00.fits*')

    def test_if_bias_frames_were_created(self):
        test_if_internal_files_were_created('*b00.fits*', os.path.join('bias', '*.fits'))


@pytest.mark.master_bias
class TestMasterBiasCreation:
    @pytest.fixture(autouse=True)
    def stack_bias_frames(self):
        stack_calibrations('*b00.fits*', 'BIAS')

    def test_if_stacked_bias_frame_was_created(self):
        test_if_stacked_calibrations_were_created('*b00.fits*', 'bias')


@pytest.mark.dark_ingestion
class TestDarkIngestion:
    @pytest.fixture(autouse=True)
    def process_dark_frames(self):
        reduce_individual_frames('*d00.fits*')

    def test_if_dark_frames_were_created(self):
        test_if_internal_files_were_created('*d00.fits*', os.path.join('dark', '*.fits'))


@pytest.mark.master_dark
class TestMasterDarkCreation:
    @pytest.fixture(autouse=True)
    def stack_dark_frames(self):
        stack_calibrations('*d00.fits*', 'DARK')

    def test_if_stacked_dark_frame_was_created(self):
        test_if_stacked_calibrations_were_created('*d00.fits*', 'dark')


@pytest.mark.flat_ingestion
class TestFlatIngestion:
    @pytest.fixture(autouse=True)
    def process_flat_frames(self, make_tracefiles):
        reduce_individual_frames('*w00.fits*')

    def test_if_flat_frames_were_created(self):
        test_if_internal_files_were_created('*w00.fits*', os.path.join('flat', '*.fits'))


@pytest.mark.master_flat
class TestMasterFlatCreation:
    @pytest.fixture(autouse=True)
    def stack_flat_frames(self):
        stack_calibrations('*w00.fits*', 'FLAT')

    def test_if_stacked_flat_frame_was_created(self):
        test_if_stacked_calibrations_were_created('*w00.fits*', 'flat')


@pytest.mark.arc_ingestion
class TestArcIngestion:
    @pytest.fixture(autouse=True)
    def process_arc_frames(self):
        reduce_individual_frames('*a00.fits*')

    def test_if_arc_frames_were_created(self):
        test_if_internal_files_were_created('*a00.fits*', os.path.join('dble', '*.fits'))


@pytest.mark.master_arc
class TestMasterArcCreation:
    @pytest.fixture(autouse=True)
    def stack_arc_frames(self):
        stack_calibrations('*a00.fits*', 'ARC')

    def test_if_stacked_arc_frame_was_created(self):
        test_if_stacked_calibrations_were_created('*a00.fits*', 'arc')


@pytest.mark.zero_file
class TestZeroFileCreation:
    @pytest.fixture(autouse=True)
    def cleanup_zero_creation(self, make_zero_frames):
        for instrument in instruments:
            fix_flags_in_zeros_csv(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced',
                                                'csv', 'zeros.csv'))
            remove_blaze_files_from_csv(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced',
                                                     'csv', 'standards.csv'))
        set_images_to_unprocessed_in_db('%e00.fits%')

    def test_if_zero_frame_was_created(self):
        for instrument in instruments:
            created_zero_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'zero', '*.fits'))
            assert len(created_zero_files) > 0


@pytest.mark.science_files
class TestScienceFileCreation:
    @pytest.fixture(autouse=True)
    def reduce_science_frames(self):
        reduce_individual_frames('*e00.fits*')

    def test_if_science_frames_were_extracted(self):
        test_if_internal_files_were_created('*e00.fits*', os.path.join('extr', '*.fits'))

    def test_if_science_tar_files_were_created(self):
        for day_obs in days_obs:
            input_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', '*e00.fits*'))
            for input_file in input_files:
                expected_filename = os.path.basename(input_file).replace('e00', 'e91').replace('.fits.fz', '.tar.gz')
                assert os.path.exists(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'specproc', expected_filename))

    def test_if_science_tar_files_have_fits_file_and_pdf_file(self):
        for instrument in instruments:
            processed_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced', 'tar', '*.tar.gz'))
            for processed_file in processed_files:
                processed_tarfile = tarfile.open(processed_file)
                tarfile_contents = processed_tarfile.getnames()
                assert any(['.pdf' in filename for filename in tarfile_contents])
                assert any(['.fits' in filename for filename in tarfile_contents])
