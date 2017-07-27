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
from nrespipe.utils import need_to_process, is_nres_file, which_nres, date_range_to_idl, funpack
from nrespipe import settings

import tempfile


app = Celery('nrestasks')
app.config_from_object('nrespipe.settings')

logger = logging.getLogger('nrespipe')
logger.propagate = False


@app.task(bind=True, max_retries=3, default_retry_delay=3 * 60)
@metric_timer('nrespipe', async=False)
def process_nres_file(self, path, data_reduction_root_path, db_address):
    if not os.path.exists(path):
        raise FileNotFoundError

    with tempfile.TemporaryDirectory() as temp_directory:
        input_filename = os.path.basename(path)
        path = funpack(path, temp_directory)

        if not is_nres_file(path):
            logger.info('Not NRES file. Skipping...', extra={'tags': {'filename': input_filename}})

        elif not need_to_process(path, db_address):
            logger.info('NRES File already processed. Skipping...', extra={'tags': {'filename': input_filename}})

        else:
            logger.info('Processing NRES file', extra={'tags': {'filename': input_filename}})
            nres_site, nres_instrument = which_nres(path)
            os.environ['NRESROOT'] = os.path.join(data_reduction_root_path, nres_site, '')
            os.environ['NRESINST'] = os.path.join(nres_instrument, '')
            try:
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
    os.environ['NRESROOT'] = os.path.join(data_reduction_root_path, site, '')
    os.environ['NRESINST'] = os.path.join(nres_instrument, '')


    date_range = [datetime.datetime.strptime(date_range[0], settings.date_format),
                  datetime.datetime.strptime(date_range[1], settings.date_format)]
    logger.info('Stacking Calibration frames', extra={'tags': {'site': site, 'instrument': camera,
                                                               'caltype': calibration_type,
                                                               'start': date_range[0].strftime(settings.date_format),
                                                               'end': date_range[1].strftime(settings.date_format)}})

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

@app.task
def collect_queue_length_metric(rabbit_api_root):
    response = requests.get('"http://{base_url}:15672/api/queues/%2f/celery/'.format(base_url=rabbit_api_root),
                            auth=HTTPBasicAuth('guest', 'guest')).json()
    send_tsdb_metric('nrespipe.queue_length', response['messages'], async=False)

