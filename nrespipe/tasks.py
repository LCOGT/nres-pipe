import logging
import requests
import shlex
import subprocess
import datetime
from celery import Celery
import os
from requests.auth import HTTPBasicAuth

from opentsdb_python_metrics.metric_wrappers import metric_timer, send_tsdb_metric

from nrespipe import dbs
from nrespipe.utils import need_to_process, is_nres_file, which_nres, date_range_to_idl
from nrespipe import settings

import tempfile
import shutil


app = Celery('nrestasks')
app.config_from_object('nrespipe.settings')

logger = logging.getLogger('nrespipe')


@app.task(bind=True, max_retries=3, default_retry_delay=3 * 60)
@metric_timer('nrespipe', async=False)
def process_nres_file(self, path, data_reduction_root_path, db_address):
    if not os.path.exists(path):
        raise FileNotFoundError

    with tempfile.TemporaryDirectory() as temp_directory:
        if os.path.splitext(path) == '.fz':
            uncompressed_filename = os.path.splitext(os.path.basename(path))[0]
            output_path = os.path.join(temp_directory, uncompressed_filename)
            os.system('funpack -O {0} {1}'.format(output_path, path))

        else:
            output_path = os.path.join(temp_directory, os.path.basename(path))
            shutil.copy(path, output_path)

        path = output_path

        if is_nres_file(path) and need_to_process(path, db_address):
            nres_instrument = which_nres(path)
            os.environ['NRESROOT'] = os.path.join(data_reduction_root_path, '')
            os.environ['NRESINST'] = os.path.join(nres_instrument, '')
            try:
                dbs.save_metadata(path, db_address)
                console_output = subprocess.check_output(shlex.split('idl -e run_nres_pipeline -quiet -args {path}'.format(path=path)))
                logger.info('IDL NRES pipeline output: {output}'.format(output=console_output))
                dbs.set_file_as_processed(path, db_address)
            except subprocess.CalledProcessError as e:
                logger.error('IDL NRES pipeline returned with a non-zero exit status. Terminal output: {output}'.format(output=e.output))


@app.task(bind=True, max_retries=3, default_retry_delay=3 * 60)
def make_stacked_calibrations(self, site, camera, calibration_type, date_range, data_reduction_root_path,
                              nres_instrument):
    """
    Stack the calibration files taken on a given night (BIAS, DARK, FLAT)
    """
    os.environ['NRESROOT'] = os.path.join(data_reduction_root_path, '')
    os.environ['NRESINST'] = os.path.join(nres_instrument, '')


    date_range = [datetime.datetime.strptime(date_range[0], settings.date_format),
                  datetime.datetime.strptime(date_range[1], settings.date_format)]

    try:
        cmd = 'idl -e stack_nres_calibrations -quiet -args {calibration_type} {site} {camera} {date_range}'
        cmd = cmd.format(calibration_type=calibration_type, site=site, camera=camera, date_range=date_range_to_idl(date_range))
        console_output = subprocess.check_output(shlex.split(cmd))
        logger.info('IDL NRES Calibration Stacker output: {output}'.format(output=console_output))
    except subprocess.CalledProcessError as e:
        logger.error('IDL Calibration Stacker returned with a non-zero exit status. Terminal output: {output}'.format(output=e.output))


@app.task
def make_stacked_calibrations_for_one_night(self, site, camera, nres_instrument):
    end = datetime.utcnow()
    start = end - datetime.timedelta(hours=24)
    date_range = [start.strftime(settings.date_format), end.strftime(settings.date_format)]
    for calibtration_type in ['BIAS', 'DARK', 'FLAT']:
        make_stacked_calibrations.delay(calibration_type=calibtration_type, site=site, camera=camera,
                                        date_range=date_range, data_reduction_root_path=settings.data_reduction_root,
                                        nres_instrument=nres_instrument)



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


@app.task
def collect_queue_length_metric(rabbit_api_root):
    response = requests.get('"http://{base_url}:15672/api/queues/%2f/celery/'.format(base_url=rabbit_api_root),
                            auth=HTTPBasicAuth('guest', 'guest')).json()
    send_tsdb_metric('nrespipe.queue_length', response['messages'], async=False)

