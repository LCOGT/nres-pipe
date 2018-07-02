import pytest


def setup_directory_tree():
    pass


def copy_config_files():
    pass


def copy_csv_files():
    pass


def make_db():
    pass


@pytest.fixture(scope='module')
def init():
    setup_directory_tree()
    copy_config_files()
    copy_csv_files()
    make_db()


@pytest.fixture(scope='module')
def process_bias_frames(init):
    pass


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
        assert 0

    def test_if_stacked_bias_frame_was_created(self, stack_bias_frames):
        pass

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
