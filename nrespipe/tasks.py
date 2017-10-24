import logging
import requests
import shlex
import subprocess
import datetime
from celery import Celery
import os
from requests.auth import HTTPBasicAuth
from astropy.io import fits, ascii
from scipy import optimize
from opentsdb_python_metrics.metric_wrappers import metric_timer, send_tsdb_metric
from astropy.io import ascii

import pkg_resources

from nrespipe import dbs
from nrespipe.utils import need_to_process, is_raw_nres_file, which_nres, date_range_to_idl, funpack, get_md5, get_files_from_last_night
from nrespipe.utils import filename_is_blacklisted, copy_to_final_directory, post_to_fits_exchange, measure_sources_from_raw
from nrespipe.utils import coordinate_variance, warp_coordinates, square_offset
from nrespipe import settings
import numpy as np

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
    # Get all the lamp flats from last night and which fibers were illuminated
    flat_files =get_files_from_last_night('*w00.fits*', raw_data_root, site, nres_instrument)

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
    run_refine_trace.apply_async(kwargs={'site': site, 'camera': camera, 'nres_instrument': nres_instrument,
                                         'data_reduction_root': settings.data_reduction_root,
                                         'input_flat1': flat1, 'input_flat2': flat2},
                                 queue='celery')


def refine_trace0(site, camera, nres_instrument, raw_data_root, arc_file=None):

    if arc_file is None:
        # Take an input of a raw double frame
        arc_files = get_files_from_last_night('*a00.fits*', raw_data_root, site, nres_instrument)

        # Short circuit
        if not arc_files:
            return

        # Select the middle arc file with fibers 0 and 1 illuminated
        arc_files = [arc_file for arc_file in arc_files if fits.getval(arc_file, 'OBJECTS').split('&')[2] == 'none']
        arc_file = arc_files[(len(arc_files) + 1) // 2]

    # Run sep on the input raw double frame after subtracting the bias frame
    sources = measure_sources_from_raw(arc_file, threshold=50)

    # Using the catalog from the config directory that was used to derive the original by hand trace file
    reference_catalog_filename = pkg_resources.resource_filename(__name__, "data/trace_reference.cat")
    reference_catalog = ascii.read(reference_catalog_filename, format='fast_basic')

    # Warp the coordinates using a polynomial to figure out what the shifts are
    polynomial_order = 3
    reference_catalog['x'], reference_catalog['y']
    match_threshold = 5
    def model_function(params):
        model_x, model_y = warp_coordinates(reference_catalog['x'], reference_catalog['y'], params, polynomial_order)
        square_distances = square_offset(sources['x'], sources['y'], model_x, model_y)
        matches = square_distances ** 0.5 <= match_threshold
        if matches.sum() == 0:
            metric = 1e10
        else:
            metric = (square_distances[matches] / matches.sum()).sum()
        return metric

    # Run a grid of -25 to 25 pixels and find the best initial guess
    X, Y = np.meshgrid(np.arange(-25, 26), np.arange(-25, 26))
    X = X.ravel()
    Y = Y.ravel()
    fit_metrics = np.zeros(51 * 51)
    for i, (x, y) in enumerate(zip(X, Y)):
        # Start with just the linear component
        params = np.zeros(20)
        params[0] = x
        params[10] = y
        params[4] = 1.0
        params[11] = 1.0
        fit_metrics[i] = model_function(params)


    initial_x, initial_y = X[np.argmin(fit_metrics)], Y[np.argmin(fit_metrics)]

    params = np.zeros(20)
    params[0] = initial_x
    params[10] = initial_y
    params[4] = 1.0
    params[11] = 1.0
    # Run Nelder-Mead to find the initial shifts between the input catalog and the new files
    best_fit_coeffs = optimize.minimize(model_function, params, method='Nelder-Mead')['x']

    # Use the best fit transformation to transform the input positions measured by hand to make a trace0 file for the IDL pipeline
    # Read in the original trace0 text file
    original_trace_file = os.path.join(settings.data_reduction_root, site, nres_instrument, 'reduced', 'config', 'ref_trace.txt')

    original_trace = ascii.read(original_trace_file, data_start=3)
    original_xs = np.array([500., 1250., 2000., 2750., 3750.])

    new_trace = "By-hand ord posns at x=500,1250,2000,2750,3750 for iord=0,66, ifib=0,1, {date} {filename}\n" \
                "nfib 2 0 1\n" \
                "iord  500    1250    2000    2750   3750\n"
    new_trace = new_trace.format(date=datetime.datetime.now(), filename=os.path.basename(arc_file))

    fitted_coeffs = []
    for row in original_trace:
        # transform to the new coordinates
        new_trace_x = []
        new_trace_y = []
        for x, y in zip(original_xs, [row[i] for i in ['col2', 'col3', 'col4', 'col5', 'col6']]):
            new_x, new_y = warp_coordinates(x, y, best_fit_coeffs, 3)
            new_trace_x.append(new_x)
            new_trace_y.append(new_y)

        # Fit a a low order polynomial to the values in the elp frame
        fitted_coeffs.append(np.polyfit(new_trace_x, new_trace_y, 3))

    # resample the low order polynomial onto the original x values to pass to the pipeline
    for coeffs, row in zip(fitted_coeffs, original_trace):
        fitted_y = np.polyval(coeffs, original_xs)
        line = " {ord:2d}  {a500:4d}   {a1250:4d}     {a2000:4d}  {a2750:4d}    {a3750:4d}\n"
        formatted_line = line.format(ord=int(row['col1']), a500=int(np.round(fitted_y[0])),
                                     a1250=int(np.round(fitted_y[1])),
                                     a2000=int(np.round(fitted_y[2])), a2750=int(np.round(fitted_y[3])),
                                     a3750=int(np.round(fitted_y[4])))
        new_trace += formatted_line

    new_trace_filename = "{site}_{camera}_{nres_instrument}_{today}_trace.txt"
    new_trace_filename = new_trace_filename.format(site=site, camera=camera, nres_instrument=nres_instrument,
                                                   today=datetime.datetime.now().strftime('%Y%m%d'))
    new_trace_filename = os.path.join(settings.data_reduction_root, site, nres_instrument, 'reduced', 'config', new_trace_filename)
    with open(new_trace_filename, 'w') as f:
        f.write(new_trace)


    # Run trace0
    # (input_filename, site, camera, nres_instrument, data_reduction_root)
    run_trace0.apply_async(kwargs={'input_filename': new_trace_filename, 'site': site, 'camera': camera,
                                   'nres_instrument': nres_instrument, 'data_reduction_root': settings.data_reduction_root},
                           queue='celery')

    # Run trace refine on a set of flats
    refine_trace_from_last_night(site, camera, nres_instrument, raw_data_root)
