import logging
import shlex
import subprocess
import datetime
from celery import Celery
import os
from astropy.io import fits
from astropy.io import ascii
from dateutil import parser

import pkg_resources

from nrespipe import dbs
from nrespipe.utils import need_to_process, is_raw_nres_file, which_nres, date_range_to_idl, funpack, get_files_from_night
from nrespipe.utils import measure_sources_from_raw, query_archive_api, get_header_from_archive_api
from nrespipe.utils import warp_coordinates, send_email, make_summary_pdf, get_missing_files, make_signal_to_noise_pdf
from nrespipe.utils import get_calibration_files_taken, download_from_s3, ingest_file, get_last_night, get_path_info
from nrespipe.traces import get_pixel_scale_ratio_and_rotation, fit_warping_polynomial, find_best_offset
from nrespipe import settings

import numpy as np

import tempfile
from celery.signals import worker_process_init


app = Celery('nrestasks')
app.config_from_object('nrespipe.settings')

logger = logging.getLogger('nrespipe')
idl_logger = logging.getLogger('idl')


@worker_process_init.connect
def configure_workers(**kwargs):
    from importlib import reload
    from opentsdb_python_metrics import metric_wrappers
    reload(metric_wrappers)


def run_idl(idl_procedure, args, data_reduction_root, site, nres_instrument):
    os.environ['NRESROOT'] = os.path.join(data_reduction_root, site, '')
    os.environ['NRESINST'] = os.path.join(nres_instrument, '')
    cmd = 'idl -e {command} -quiet -args {args}'.format(command=idl_procedure, args=" ".join(args))
    logger.info('Running the following idl command: {cmd}'.format(cmd=cmd))
    cmd = shlex.split(cmd)
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

    if settings.DO_INGEST and os.path.exists(file_upload_list):
        with open(file_upload_list) as f:
            lines_to_upload = f.read().splitlines()
            for line_to_upload in lines_to_upload:
                file_to_upload, dayobs = line_to_upload.split()
                ingest_file(file_path=file_to_upload)
        os.remove(file_upload_list)
    return console_output.returncode


@app.task(max_retries=3, default_retry_delay=3 * 60)
def process_nres_file(file_info, data_reduction_root_path, old_db_address):
    db_address = settings.db_address
    if not need_to_process(file_info, db_address):
        return

    path, filename, checksum = get_path_info(file_info)

    with tempfile.TemporaryDirectory() as temp_directory:
        if path is None:
            path = download_from_s3(file_info.get('frameid'), temp_directory)

        path = funpack(path, temp_directory)

        header = fits.getheader(path)
        if not is_raw_nres_file(header):
            logger.debug('Not raw NRES file. Skipping...', extra={'tags': {'filename': filename}})
            dbs.set_file_as_processed(filename, checksum, frameid=file_info.get('frameid'), db_address=db_address)
        else:
            logger.info('Processing NRES file', extra={'tags': {'filename': filename}})
            nres_site, nres_instrument = which_nres(path)
            return_code = run_idl('run_nres_pipeline', [path, str(settings.do_radial_velocity)],
                                  data_reduction_root_path, nres_site, nres_instrument)
            if return_code == 0:
                dbs.set_file_as_processed(filename, checksum, frameid=file_info.get('frameid'), db_address=db_address)


@app.task(max_retries=3, default_retry_delay=3 * 60)
def make_stacked_calibrations(site, camera, calibration_type, date_range, data_reduction_root_path,
                              nres_instrument, target=''):
    """
    Stack the calibration files taken on a given night (BIAS, DARK, FLAT, ARC, TEMPLATE)
    """
    date_range = [parser.parse(date_range[0]),
                  parser.parse(date_range[1])]
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
def refine_trace_from_night(site, camera, nres_instrument, night=None):
    if night is None:
        night = get_last_night()
    # Get all the lamp flats from last night and which fibers were illuminated
    flat_files = query_archive_api(site, night, rlevel=0, obstype='LAMPFLAT')

    if len(flat_files) == 0:
        # Short circuit
        return

    flats_1 = []
    flats_2 = []

    for f in flat_files:
        header = get_header_from_archive_api(f['id'])
        fiber = header.get('OBJECTS')
        if fiber is None:
            continue
        if fiber.split('&')[2] == 'none':
            flats_1.append(f)
        else:
            flats_2.append(f)

    # If there are observations from both telescopes
    if len(flats_1) > 0 and len(flats_2) > 0:
        # Get the middle of each
        flat1 = flats_1[(len(flats_1) + 1) // 2]
        flat2 = flats_2[(len(flats_2) + 1) // 2]
    elif len(flats_1) > 0:
        # Otherwise get the middle lamp flat
        flat1 = flats_1[(len(flats_1) + 1) // 2]
        flat2 = ''
    else:
        # Short circuit if there are only flats from fiber 1,2 and not 0,1
        # This is a requirement of the idl pipeline.
        return

    # run refine_trace on the main task queue
    # Note that flat1 should have fibers 0,1 illuminated while flat2 should have 1,2
    # The IDL pipeline seems to require this.
    run_refine_trace.apply_async(kwargs={'site': site, 'camera': camera, 'nres_instrument': nres_instrument,
                                         'data_reduction_root': settings.data_reduction_root,
                                         'input_flat1': flat1, 'input_flat2': flat2},
                                 queue='celery')


def refine_trace0(site, camera, nres_instrument, raw_data_root, arc_file=None):

    if arc_file is None:
        # Take an input of a raw double frame
        arc_files = get_files_from_night('*a00.fits*', raw_data_root, site, nres_instrument)

        # Short circuit
        if not arc_files:
            return

        # Select the middle arc file with fibers 0 and 1 illuminated
        arc_files = [arc_file for arc_file in arc_files if fits.getval(arc_file, 'OBJECTS').split('&')[2] == 'none']
        arc_file = arc_files[(len(arc_files) + 1) // 2]

    # Run sep on the input raw double frame after subtracting the bias frame
    sources = measure_sources_from_raw(arc_file, threshold=10)

    # Using the catalog from the config directory that was used to derive the original by hand trace file
    reference_catalog_filename = pkg_resources.resource_filename(__name__, "data/trace_reference.cat")
    reference_catalog = ascii.read(reference_catalog_filename, format='fast_basic')

    # Calculate the scale between the two images and hope the distortion is small
    scale_guess = get_pixel_scale_ratio_and_rotation(sources, reference_catalog)
    logger.info('Initial guess for scale = {scale}'.format(scale=scale_guess))

    offset_guess = find_best_offset(sources, reference_catalog, scale_guess)
    logger.info('Initial guess for offset = ({x}, {y})'.format(x=offset_guess['x'], y=offset_guess['y']))

    best_fit_coeffs = fit_warping_polynomial(sources, reference_catalog, scale_guess, offset_guess, polynomial_order=3)

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

        # Fit a a low order polynomial to the values in the new frame frame
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
    refine_trace_from_night(site, camera, nres_instrument, raw_data_root)


@app.task
def send_end_of_night_summary_plots(sites, instruments, sender_email, sender_password, recipient_emails, raw_data_root):
    # Get the current time utc
    now = datetime.datetime.utcnow()
    # The dayobs of interest is one day before (I think this does not work correctly for COJ)
    last_night = now - datetime.timedelta(days=1)
    dayobs = last_night.strftime('%Y%m%d')

    # For each site, make an end of night pdf
    attachments = []
    email_body = "<p>NRES Nighly Summary for {dayobs}</p>\n".format(dayobs=dayobs)
    for site, instrument in zip(sites, instruments):
        plot_directory = '{raw_data_root}/{site}/{instrument}/reduced/plot/'.format(raw_data_root=raw_data_root, site=site, instrument=instrument)
        pdf_filename = os.path.join(plot_directory, '{site}_{dayobs}.pdf'.format(site=site, dayobs=dayobs))

        make_summary_pdf(plot_directory, dayobs, pdf_filename)
        if os.path.exists(pdf_filename):
            attachments.append(pdf_filename)

        raw_files, processed_files, missing_files = get_missing_files(site, dayobs)
        email_body += "<p>{site}/{instrument}/{dayobs}:</p>\n".format(site=site, instrument=instrument,dayobs=dayobs)
        email_body += "<p>Raw Science Exposures: {num_raw}; Processed Science Exposures: {num_proc}</p>\n".format(num_raw=len(raw_files),
                                                                                                                  num_proc=len(processed_files))
        if len(missing_files) > 0:
            email_body += "<p>Data not processed by the pipeline for {site}/{instrument}/{dayobs}:</p>\n<p>".format(site=site,
                                                                                                                instrument=instrument,
                                                                                                                dayobs=dayobs)
            for missing_file in missing_files:
                email_body += "{filename}<br>\n".format(filename=missing_file)
        bias_files, dark_files, flat_files, arc_files = get_calibration_files_taken(site, dayobs)
        calibrations_taken = "<p>Bias Frames: {num_biases}; Dark Frames: {num_darks}; Flat Frames: {num_flats}; Arc Frames {num_arcs}</p>\n"
        calibrations_taken = calibrations_taken.format(num_biases=len(bias_files), num_darks=len(dark_files),
                                                       num_flats=len(flat_files), num_arcs=len(arc_files))
        email_body += calibrations_taken
        email_body += "</p>"

    input_directories = ['{raw_data_root}/{site}/{instrument}/reduced/plot'.format(raw_data_root=raw_data_root, site=site,
                                                                                   instrument=instrument, dayobs=dayobs)
                         for site, instrument in zip(sites, instruments)]
    output_text_filenames = ['{raw_data_root}/{site}/{instrument}/reduced/plot/{site}_{dayobs}_sn.txt'.format(raw_data_root=raw_data_root, site=site,
                                                                                                              instrument=instrument, dayobs=dayobs)
                             for site, instrument in zip(sites, instruments)]

    output_pdf_filename = '{raw_data_root}/plots/nres_sn_{dayobs}.pdf'.format(raw_data_root=raw_data_root, dayobs=dayobs)
    make_signal_to_noise_pdf(input_directories, sites, [dayobs] * len(sites), output_text_filenames, output_pdf_filename)
    attachments.insert(0, output_pdf_filename)
    # Send an email with the end of night plots
    send_email('NRES Nightly Summary {dayobs}'.format(dayobs=dayobs), recipient_emails, sender_email, sender_password,
               email_body, attachments)
