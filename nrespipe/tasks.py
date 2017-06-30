import logging
import os
import shlex
import subprocess

from celery import Celery

from nrespipe import dbs
from nrespipe.utils import need_to_process, is_nres_file

app = Celery('tasks')
app.config_from_object('nrespipe.settings')

logger = logging.getLogger('nrespipe')


@app.task(bind=True, max_retries=None, default_retry_delay=3 * 60)
def process_nres_file(self, path, db_address):
    if not os.path.exists(path):
        raise FileNotFoundError

    if is_nres_file(path) and need_to_process(path, db_address):
        os.environ['NRESROOT'] = path_to_data()
        os.environ['NRESINST'] = which_nres(path)
        try:
            dbs.save_metadata(path, db_address)
            console_output = subprocess.check_output(shlex.split('idl run_nres_pipeline -args {path}'.format(path=path)))
            logger.info('IDL NRES pipeline output: {output}'.format(console_output))
            dbs.set_file_as_processed(path)
        except subprocess.CalledProcessError as e:
            logger.error('IDL returned with a non-zero exit status. Terminal output: {output}'.format(output=e.output))


@app.task(bind=True, max_retries=None, default_retry_delay=3 * 60)
def make_stacked_calibrations(self, telescope, dayobs, calibration_type, db_address):
    # Stack the calibration files taken on a given night (BIAS, DARK, FLAT, or ZERO)
    #console_output = subprocess.check_output(shlex.split('idl stack_nres_calibrations -args {path}'.format(path=path)))
    pass


@app.task(bind=True, max_retries=None, default_retry_delay=3 * 60)
def make_rv_zero_file(self, telescope, dayobs, db_address):
    #mk_zero: make a zero file, what you compare to for a radial velocity calculation - 5 high S/N on the same star on the same night, that are consecutive is ideal, minimal acceptable: 3 spectra of the same object on the same night (iterate over per star, stack all taken within 5 hours), S/N ~50 ok, want 200,
    pass


@app.task(bind=True, max_retries=None, default_retry_delay=3 * 60)
def make_triple_arc_from_double(self, telescope, dayobs, db_address):
#avg_doubtwotrip: arcs -> make arc for all three fibers (may also be called far_triple, one calls the other), stack all from the night, would be nice to alternate filenames to be alternating between fibers 0,1 to fibers 1,2 if possible, info in the header
    pass

@app.task(bind=True, max_retries=None, default_retry_delay=3 * 60)
def make_trace_file(self, telescope, dayobs, db_address):
#trace_file: run nightly, takes a list of flats, run on all flats taken that night
    pass