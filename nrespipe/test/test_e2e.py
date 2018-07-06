import pytest
import os
from glob import glob
import shutil
from nrespipe.dbs import create_db
from nrespipe.utils import post_to_fits_exchange
from nrespipe import tasks
import time

sites = [os.path.basename(site_path) for site_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], '*'))]
instruments = [os.path.join(site, os.path.basename(instrument_path)) for site in sites
               for instrument_path in glob(os.path.join(os.path.join(os.environ['NRES_DATA_ROOT'], site, '*')))]

days_obs = [os.path.join(instrument, os.path.basename(dayobs_path)) for instrument in instruments
            for dayobs_path in glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, '*'))]


nres_pipeline_directories = ['bias', 'blaz', 'ccor', 'class', 'config', 'csv', 'dark', 'dble', 'diag', 'expm',
                             'extr', 'flat', 'plot', 'rv', 'spec', 'tar', 'temp', 'thar', 'trace', 'trip', 'zero']


def wait_for_celery_is_finished():
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
            full_pipline_directory_path = os.path.join(reduced_path, nres_pipeline_directory)
            if not os.path.exists(full_pipline_directory_path):
                os.makedirs(full_pipline_directory_path)


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


@pytest.fixture(scope='module')
def init():
    setup_directory_tree()
    copy_config_files()
    copy_csv_files()
    create_db(os.environ['DB_URL'])


@pytest.fixture(scope='module')
def process_bias_frames(init):
    for day_obs in days_obs:
        bias_files = glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', '*b00.fits*'))
        for bias_file in bias_files:
            post_to_fits_exchange(os.environ['FITS_BROKER'], bias_file)
    wait_for_celery_is_finished()


@pytest.fixture(scope='module')
def stack_bias_frames(process_bias_frames):
    pass


@pytest.fixture(scope='module')
def process_dark_frames(stack_bias_frames):
    pass


@pytest.fixture(scope='module')
def stack_dark_frames(process_dark_frames):
    pass


@pytest.fixture(scope='module')
def make_tracefile(stack_dark_frames):
    pass


@pytest.fixture(scope='module')
def process_flat_frames(self, make_tracefile):
    pass


@pytest.fixture(scope='module')
def stack_flat_frames(process_flat_frames):
    pass


@pytest.fixture(scope='module')
def process_arc_frames(stack_flat_frames):
    pass


@pytest.fixture(scope='module')
def stack_arc_frames(process_arc_frames):
    pass


@pytest.fixture(scope='module')
def extract_zero_frames(stack_arc_frames):
    pass


@pytest.fixture(scope='module')
def make_zero_frames(extract_zero_frames):
    pass


@pytest.fixture(scope='module')
def cleanup_zero_creation(make_zero_frames):
    pass


@pytest.fixture(scope='module')
def reduce_science_frames(cleanup_zero_creation):
    pass


@pytest.mark.incremental
@pytest.mark.e2e
class TestE2E(object):
    def test_if_bias_frames_were_created(self, process_bias_frames):
        input_bias_files = []
        for day_obs in days_obs:
            input_bias_files += glob(os.path.join(os.environ['NRES_DATA_ROOT'], day_obs, 'raw', '*b00.fits*'))
        created_bias_files = []
        for instrument in instruments:
            created_bias_files += glob(os.path.join(os.environ['NRES_DATA_ROOT'], instrument, 'reduced',
                                                    'bias', '*.fits'))
        assert len(input_bias_files) == len(created_bias_files)

    def test_if_stacked_bias_frame_was_created(self, stack_bias_frames):
        assert False

    def test_if_dark_frames_were_created(self, process_dark_frames):
        pass

    def test_if_stacked_dark_frame_was_created(self, stack_dark_frames):
        pass

    def test_if_flat_frames_were_created(self, process_flat_frames):
        pass

    def test_if_stacked_flat_frame_was_created(self, stack_flat_frames):
        pass

    def test_if_arc_frames_were_created(self, process_arc_frames):
        pass

    def test_if_stacked_arc_frame_was_created(self, stack_arc_frames):
        pass

    def test_if_zero_frame_was_created(self, cleanup_zero_creation):
        pass

    def test_if_science_frames_were_extracted(self, reduce_science_frames):
        pass

    def test_if_science_tar_files_were_created(self, reduce_science_frames):
        pass

    def test_if_science_tar_files_have_fits_file_and_pdf_file(self, reduce_science_frames):
        pass
