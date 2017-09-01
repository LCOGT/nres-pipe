import logging
import requests
import shlex
import subprocess
import datetime
from celery import Celery
import os
from requests.auth import HTTPBasicAuth
from glob import glob
from astropy.io import fits

from opentsdb_python_metrics.metric_wrappers import metric_timer, send_tsdb_metric

from nrespipe import dbs
from nrespipe.utils import need_to_process, is_raw_nres_file, which_nres, date_range_to_idl, funpack, get_md5
from nrespipe.utils import filename_is_blacklisted, copy_to_final_directory, post_to_fits_exchange
from nrespipe import settings

import tempfile

app = Celery('nrestasks')
app.config_from_object('nrespipe.settings')

logger = logging.getLogger('nrespipe')
idl_logger = logging.getLogger('idl')



def run_idl(idl_procedure, args, data_reduction_root, site, nres_instrument):
    os.environ['NRESROOT'] = os.path.join(data_reduction_root, site, '')
    os.environ['NRESINST'] = os.path.join(nres_instrument, '')

    cmd = shlex.split('idl -e {command} -quiet -args {args}'.format(command=idl_procedure, args=" ".join(args)))
    console_output = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    logger.info('IDL NRES pipeline output:')
    for message in console_output.stdout.splitlines():
        idl_logger.info(message.decode())
    if console_output.stderr:
        logger.warning('IDL STDERR Output:')
        for message in console_output.stderr.splitlines():
            idl_logger.warning(message.decode())
    if console_output.returncode > 0:
        logger.error('IDL NRES pipeline returned with a non-zero exit status: {c}'.format(c=console_output.returncode))

    file_upload_list = os.path.join(data_reduction_root, site, nres_instrument, 'reduced', 'tar', 'beammeup.txt')
    if os.path.exists(file_upload_list):
        with open(file_upload_list) as f:
            lines_to_upload = f.read().splitlines()
        for line_to_upload in lines_to_upload:
            file_to_upload, dayobs = line_to_upload.split()
            final_product = copy_to_final_directory(file_to_upload, data_reduction_root, site, nres_instrument, dayobs)
            post_to_fits_exchange(settings.broker_url, final_product)
        os.remove(file_upload_list)
    return console_output.returncode


@app.task(max_retries=3, default_retry_delay=3 * 60)
@metric_timer('nrespipe', async=False)
def process_nres_file(path, data_reduction_root_path, db_address):
    input_filename = os.path.basename(path)

    if not os.path.exists(path):
        logger.error('File not found', extra={'tags': {'filename': input_filename}})
        raise FileNotFoundError

    if filename_is_blacklisted(path):
        logger.debug('Filename does not pass black list. Skipping...', extra={'tags': {'filename': input_filename}})
        return

    checksum = get_md5(path)
    if not need_to_process(input_filename, checksum, db_address):
        logger.debug('NRES File already processed. Skipping...', extra={'tags': {'filename': input_filename}})
        return

    with tempfile.TemporaryDirectory() as temp_directory:
        path = funpack(path, temp_directory)

        if not is_raw_nres_file(path):
            logger.debug('Not raw NRES file. Skipping...', extra={'tags': {'filename': input_filename}})
            dbs.set_file_as_processed(input_filename, checksum, db_address)
        else:
            logger.info('Processing NRES file', extra={'tags': {'filename': input_filename}})
            nres_site, nres_instrument = which_nres(path)
            return_code = run_idl('run_nres_pipeline', [path, settings.do_radial_velocity],
                                  data_reduction_root_path, nres_site, nres_instrument)
            if return_code == 0:
                dbs.set_file_as_processed(input_filename, checksum, db_address)


@app.task(max_retries=3, default_retry_delay=3 * 60)
def make_stacked_calibrations(site, camera, calibration_type, date_range, data_reduction_root_path,
                              nres_instrument, target=''):
    """
    Stack the calibration files taken on a given night (BIAS, DARK, FLAT, ARC, TEMPLATE)
    """
    date_range = [datetime.datetime.strptime(date_range[0], settings.date_format),
                  datetime.datetime.strptime(date_range[1], settings.date_format)]
    logger.info('Stacking Calibration frames', extra={'tags': {'site': site, 'instrument': camera,
                                                               'caltype': calibration_type,
                                                               'start': date_range[0].strftime(settings.date_format),
                                                               'end': date_range[1].strftime(settings.date_format)}})

    run_idl('stack_nres_calibrations', [calibration_type, site, camera, date_range_to_idl(date_range), target],
            data_reduction_root_path, site, nres_instrument)


@app.task
def make_stacked_calibrations_for_one_night(site, camera, nres_instrument):
    end = datetime.datetime.utcnow()
    start = end - datetime.timedelta(hours=24)
    date_range = [start.strftime(settings.date_format), end.strftime(settings.date_format)]
    for calibration_type in ['BIAS', 'DARK', 'FLAT', 'ARC']:
        make_stacked_calibrations.apply_async(kwargs={'calibration_type': calibration_type, 'site': site,
                                                      'camera': camera, 'date_range': date_range,
                                                      'data_reduction_root_path': settings.data_reduction_root,
                                                      'nres_instrument': nres_instrument},
                                              queue='celery')

@app.task
def collect_queue_length_metric(rabbit_api_root):
    response = requests.get('http://{base_url}:15672/api/queues/%2f/celery/'.format(base_url=rabbit_api_root),
                            auth=HTTPBasicAuth('guest', 'guest')).json()
    send_tsdb_metric('nrespipe.queue_length', response['messages'], async=False)


@app.task
def run_trace0(input_filename, site, camera, nres_instrument, data_reduction_root):
    run_idl('run_nres_trace0', [input_filename, site, camera], data_reduction_root, site, nres_instrument)


@app.task
def run_refine_trace(site, camera, nres_instrument, data_reduction_root, input_flat1, input_flat2=''):

    with tempfile.TemporaryDirectory() as tempdir:
        unpacked_path1 = funpack(input_flat1, tempdir)
        if input_flat2:
            unpacked_path2 = funpack(input_flat2, tempdir)
        else:
            unpacked_path2 = ''
        run_idl('run_nres_trace_refine', [site, camera, unpacked_path1, unpacked_path2], data_reduction_root, site,
                nres_instrument)


@app.task
def refine_trace_from_last_night(site, camera, nres_instrument, raw_data_root):
    yesterday = datetime.datetime.utcnow() - datetime.timedelta(days=1)
    last_night = yesterday.strftime('%Y%m%d')

    # Get all the lamp flats from last night and which fibers were illuminated
    raw_data_path = os.path.join(raw_data_root, site, nres_instrument, last_night, 'raw')
    flat_files = glob(os.path.join(raw_data_path, '*w00.fits*'))

    if len(flat_files) == 0:
        # Short circuit
        return

    flats_1 = []
    flats_2 = []

    for f in flat_files:
        fiber = fits.getval(f, 'OBJECTS', 1)
        if fiber.split('&')[2] == 'none':
            flats_1.append(f)
        else:
            flats_2.append(f)


    # If there are observations from both telescopes
    if len(flats_1) > 0 and len(flats_2) > 0:
        # Get the middle of each
        flat1 = flats_1[(len(flats_1) + 1) //  2]
        flat2 = flats_2[(len(flats_2) + 1) //  2]
    elif len(flats_1) > 0:
    # Otherwise get the middle lamp flat
        flat1 = flats_1[(len(flats_1) + 1) //  2]
        flat2 = ''
    else:
        flat1 = flats_2[(len(flats_2) + 1) //  2]
        flat2 = ''
    # run refine_trace on the main task queue
    run_refine_trace.apply_async(kwargs={'site': site, 'camera': camera, 'input_flat1': flat1, 'input_flat2': flat2},
                                 queue='celery')
