import datetime
import hashlib
import logging
import os
import sep
import shutil
import smtplib
import time
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from glob import glob
from PyPDF2 import PdfFileReader, PdfFileWriter
import tarfile
import tempfile

import numpy as np
import requests
from astropy.io import fits
from astropy.table import Table
from kombu import Connection, Exchange
from time import sleep

from lco_ingester import ingester
from lco_ingester.exceptions import RetryError, DoNotRetryError, BackoffRetryError, NonFatalDoNotRetryError


from nrespipe import dbs
from nrespipe import settings
from nrespipe.plots import plot_signal_to_noise

from astroquery.simbad import Simbad
import re


logger = logging.getLogger('nrespipe')


def get_md5(filepath):
    """
    Calculate the MD% checksum of a file

    Parameters
    ----------
    filepath : str
               Full path to file for which to calculate an MD5

    Returns
    -------
    md5 : str
          Hexadecimal representation of the MD5 checksum
    """
    with open(filepath, 'rb') as file:
        md5 = hashlib.md5(file.read()).hexdigest()
    return md5


def need_to_process(filename, checksum, db_address):
    record = dbs.get_processing_state(filename, checksum, db_address)
    return not record.processed or checksum != record.checksum


def filename_is_blacklisted(filename):
    # Only get raw files
    if not '00.fits' in filename:
        return True

    for blacklisted_filetype in settings.blacklisted_filenames:
        if blacklisted_filetype in filename:
            return True


def is_raw_nres_file(header):
    telescope = header.get('TELESCOP')

    if telescope is not None:
        is_nres = 'nres' in telescope.lower()
    else:
        is_nres = False

    try:
        is_raw = int(header.get('RLEVEL', '00')) == 0
    except:
        is_raw = False
    return is_nres and is_raw


def which_nres(path):
    header = fits.getheader(path)
    return header['SITEID'].lower(), header['TELESCOP'].lower()


def wait_for_task_rabbitmq(broker_url, username, password):
    """
    Wait for the RabbitMQ service to start before we try to run a command

    Parameters
    ----------
    broker_url : str
                 url to the RabbitMQ broker
    username : str
               username for the RabbitMQ server
    password : str
               password for the RabbitMQ server
    """
    attempt = 1

    connected = False

    while not connected:
        logger.info('Connecting to RabbitMQ host: Attempt #{i}'.format(i=attempt))
        try:
            response = requests.get("http://{base_url}:15672/api/whoami".format(base_url=broker_url), auth=(username, password))
            if response.status_code < 300:
                connected = True
                logger.info('Successfully connected to RabbitMQ')
        except requests.ConnectionError:
            # Wait 1 second and try again
            attempt += 1
            time.sleep(1)


def post_to_fits_exchange(broker_url, image_path):
    exchange = Exchange('fits_files', type='fanout')
    with Connection(broker_url) as conn:
        producer = conn.Producer(exchange=exchange)
        producer.publish({'path': image_path})
        producer.release()


def date_range_to_idl(date_range):
    """
    Convert a set of dates into a string that can be used by the IDL pipeline

    Parameters
    ----------
    date_range : iterable
                 2 elements

    Returns
    -------
    date_string : str
    """
    return ",".join([datetime_to_idl(date_range[0]), datetime_to_idl(date_range[1])])


def datetime_to_idl(d):
    """
    Convert a datetime object to the format that the IDL pipeline expects

    Parameters
    ----------
    d : datetime

    Returns
    -------
    fractional_day_string : str

    Notes
    -----
    The output string has the following structure: yyyyddd.xxxxx, where
    yyyy is the four digit year.
    ddd is the day number of the year
    xxxxx is fractional day of the year.
    """
    seconds_in_one_day = 86400.0
    # Note the +1 here. January 1st is day 1, not 0
    day = (d - datetime.datetime(d.year, 1, 1, 0, 0, 0)).total_seconds() / seconds_in_one_day + 1
    return  "{year:04d}{day:09.5f}".format(year=d.year, day=day)


def funpack(input_path, directory):
    """Unpack a fits file to a temporary directory

    Parameters
    ----------
    input_path : str
                Path to file to unpack
    directory : str
                output directory

    Notes
    -----
    If fits file is already unpacked, we just copy the file to the output directory

    """
    if os.path.splitext(input_path)[1] == '.fz':
        uncompressed_filename = os.path.splitext(os.path.basename(input_path))[0]
        output_path = os.path.join(directory, uncompressed_filename)
        os.system('funpack -O {0} {1}'.format(output_path, input_path))

    else:
        output_path = os.path.join(directory, os.path.basename(input_path))
        shutil.copy(input_path, directory)

    return output_path


def copy_to_final_directory(file_to_upload, data_reduction_root, site, nres_instrument, dayobs):
    """
    Copy the product from the IDL pipeline in beammeup.txt to its final resting place (folder)

    Parameters
    ----------
    file_to_upload : str
                    Full path to file produced by IDL pipeline
    data_reduction_root : str
                         Top level directory for reduced data
    site : str
           Site ID (e.g. elp)
    nres_instrument : str
                      NRES instance (e.g. nres01)
    dayobs : str
             DAY-OBS value for the observation, format must follow YYYYMMDD (e.g. 20170825)

    Returns
    -------
    output_path : str
                Final (full) path to the reduced file
    """
    output_directory = os.path.join(data_reduction_root, site, nres_instrument, dayobs, 'specproc')
    if not os.path.exists(output_directory):
        os.makedirs(output_directory, exist_ok=True)

    output_path = os.path.join(output_directory, os.path.basename(file_to_upload))
    if os.path.exists(output_path):
        os.remove(output_path)

    shutil.move(file_to_upload, output_directory)
    return os.path.join(output_directory, os.path.basename(file_to_upload))


def get_last_night():
    yesterday = datetime.datetime.utcnow() - datetime.timedelta(days=1)
    return yesterday.strftime('%Y%m%d')


def get_files_from_night(filename_pattern, raw_data_root, site, nres_instrument, night=None):
    """
    Get a list of files matching a pattern from last night for a given NRES

    Parameters
    ----------
    filename_pattern : str
                     Glob pattern for file names of interest, e.g. *w00*.fits*
    raw_data_root : str
                    Root directory for the raw data, e.g. /archive/engineering
    site : str
           Site code, e.g. elp
    nres_instrument : str
                    NRES instance, e.g. nres01

    night : str
            day-obs to get files from, default is last night
    Returns
    -------
    file_list : list
              List of files matching the input criteria

    Notes
    -----
    File names will be sorted in the output list.
    """
    if night is None:
        night = get_last_night()

    raw_data_path = os.path.join(raw_data_root, site, nres_instrument, night, 'raw')
    file_names = glob(os.path.join(raw_data_path, filename_pattern))
    file_names.sort()
    return file_names


def slice_from_region(pixel_section):
    """
    Split a region section keyword into an index slice for an array

    Parameters
    ----------
    pixel_section : str
                  Fits header region, e.g. 4000:4100

    Returns
    -------
    pixel_slice : slice
                  Array index slice corresponding to the input pixel set

    Notes
    -----
    pixel_section follows the FITS convention as is therefore 1-indexed.
    """

    pixels = pixel_section.split(':')
    if int(pixels[1]) > int(pixels[0]):
        pixel_slice = slice(int(pixels[0]) - 1, int(pixels[1]), 1)
    else:
        if int(pixels[1]) == 1:
            pixel_slice = slice(int(pixels[0]) - 1, None, -1)
        else:
            pixel_slice = slice(int(pixels[0]) - 1, int(pixels[1]) - 2, -1)
    return pixel_slice


def parse_region_keyword(keyword_value):
    """
    Convert a header keyword of the form [x1:x2],[y1:y2] into array index slices

    Parameters
    ----------
    keyword_value : str
                    Header keyword value
    Returns
    -------
    pixel_slices : tuple of slices
                   2-D slices of index corresponding to the region of interest
    """
    if not keyword_value:
        pixel_slices = None
    elif keyword_value.lower() == 'unknown':
        pixel_slices = None
    elif keyword_value.lower() == 'n/a':
        pixel_slices = None
    else:
        # Strip off the brackets and split the coordinates
        pixel_sections = keyword_value[1:-1].split(',')
        x_slice = slice_from_region(pixel_sections[0])
        y_slice = slice_from_region(pixel_sections[1])
        pixel_slices = (y_slice, x_slice)
    return pixel_slices


def measure_sources_from_raw(filename, threshold=50):
    """
    Measure the photometry for an input raw image with a given SEP detection threshold

    Parameters
    ----------
    filename : str
               Full path to the file of interest
    threshold : str
               Threshold in N sigma to detect sources

    Returns
    -------
    sources : astropy.table.Table
              Catalog of sources with positions x and y and fluxes

    Notes
    -----
    Positions are 1-indexed to match DS9 coordinates
    """
    # Read in the data
    data, header = fits.getdata(filename, header=True)
    data = data.astype(np.float)

    # Subtract the bias
    bias_region = parse_region_keyword(header['BIASSEC'])
    data -= np.median(data[bias_region])

    # Run sep to make the catalog
    error = (np.abs(data) + float(header['RDNOISE'])) ** 0.5

    try:
        background = sep.Background(data, bw=64, fw=3, fh=3)
    except ValueError:
        data = data.byteswap(inplace=True).newbyteorder()
        background = sep.Background(data, bw=64, fw=3, fh=3)

    sources = sep.extract(data - background, threshold, err=error)
    sources = Table(sources)

    # Fix floating point overflows in theta
    sources['theta'][sources['theta'] > (np.pi / 2.0)] -= 1e-6
    sources['theta'][sources['theta'] < (-np.pi / 2.0)] += 1e-6

    # calculate the kron flux of the sources. This roughly corresponds to flux_auto in the normal Source Extractor
    kronrad, krflag = sep.kron_radius(data, sources['x'], sources['y'], sources['a'], sources['b'], sources['theta'], 6.0)
    flux, fluxerr, flag = sep.sum_ellipse(data, sources['x'], sources['y'], sources['a'],
                                          sources['b'], sources['theta'], 2.5 * kronrad, subpix=1)

    # return the catalog of source positions and fluxes
    return Table({'x': sources['x'], 'xerr2': (sources['errx2']) ** 0.5, 'y': sources['y'],
                  'yerr2': (sources['erry2']) ** 0.5, 'covxy': sources['errxy'], 'flux': flux, 'fluxerr': fluxerr})


def coordinate_variance(x, y, xerr2, yerr2):
    return (x * x * xerr2 + y * y * yerr2) / (x * x + y * y)


def warp_coordinates(x, y, params, polynomial_order):
    x_coeffs = params[:len(params) // 2]
    warped_x = evaluate_poly_coords(x, y, x_coeffs, polynomial_order)
    y_coeffs = params[len(params) // 2:]
    warped_y  = evaluate_poly_coords(x, y, y_coeffs, polynomial_order)
    return warped_x, warped_y


def position_angle(source0, sources):
    # law of cosines u dot v / mag(u) (mag v) = cos theta
    length = lambda x: (x['x'] ** 2.0  + x['y'] * 2.0) ** 0.5
    cos_theta =  (source0['x'] * sources['x'] + source0['y'] * sources['y']) / (length(source0) * length(sources))
    return np.arccos(cos_theta)


def evaluate_poly_coords(x, y, coeffs, order):
    warped_x = 0.0
    coeff_index = 0
    for j in range(order + 1):
        for i in range(order - j + 1):
            warped_x += coeffs[coeff_index] * (x ** i) * (y ** j)
            coeff_index += 1
    return warped_x


def calculate_offsets(x1, y1, x2, y2):
    offset_all_pairs = lambda x1, x2:  x1 - np.tile(x2, (len(x1), 1)).T
    xdiff = offset_all_pairs(x1, x2)
    ydiff = offset_all_pairs(y1, y2)
    return {'x': xdiff, 'y': ydiff}


def square_offset(x1, y1, x2, y2, ranks=0):
    # Calculate the pairwise distance between all of the points
    xdiff = x1 - np.tile(x2, (len(x1), 1)).T
    ydiff = y1 - np.tile(y2, (len(y1), 1)).T
    offsets = xdiff * xdiff + ydiff * ydiff

    # Offsets now has the distance
    # offsets[n_star2, n_star1]
    # Sort by distance
    offsets.sort(axis=0)

    # return the offset of the closest match
    return offsets[ranks]


def offset(source, catalog):
    return np.sqrt((source['x'] - catalog['x']) ** 2.0 + (source['y'] - catalog['y']) ** 2.0)


def choose_2(n):
    # np.math.factorial(n) / np.math.factorial(k) / np.math.factorial(n - k)
    return n * (n - 1) // 2


def n_poly_coefficients(order):
    # Thank you mathematica. Turns out the number of coefficients for a 2-D polynomial follow:
    # Sum[Sum[1, {j, 0, n - i}], {i, 0, n}]
    # Which simplifies to (1/2) (1 + n) (2 + n)
    return (1 + order) * (2 + order) // 2


def send_email(subject, recipient_emails, sender_email, sender_password, email_body, attachment_filenames, smtp_url='smtp.gmail.com:587'):
    """
    Send the email via command line
    :param subject: str Subject line of the email
    :param recipient_emails: List of email addresses of the recipients
    :param sender_email: str Email address of the sender (must be a Google account)
    :param sender_password: str Password for the sender email account
    :param email_body: str Body of the email
    :param attachment_filenames: List of files to attach
    """
    # Create the container (outer) email message.
    msg = MIMEMultipart()
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = ", ".join(recipient_emails)

    msg.attach(MIMEText(email_body, 'html'))

    for filename in attachment_filenames:
        with open(filename, 'rb') as f:
            attachment = MIMEApplication(f.read(), 'pdf')

        attachment.add_header('Content-Disposition', 'attachment', filename=os.path.basename(filename))
        msg.attach(attachment)

    # Send the email via our the localhost SMTP server.
    server = smtplib.SMTP(smtp_url)
    server.ehlo()
    server.starttls()
    server.login(sender_email, sender_password)
    server.sendmail(sender_email, recipient_emails, msg.as_string())
    server.quit()


def extract_from_pdfs(input_directory, extraction_function):
    # Get all of the tar files in the input_directory
    tar_files = glob(os.path.join(input_directory, '*.tar.gz'))

    with tempfile.TemporaryDirectory() as temp_dir:
        for tar_filename in tar_files:
            basename = os.path.basename(tar_filename).replace('.tar.gz', '')
            with tarfile.open(tar_filename) as open_tar_file:
                # Extract the pdf file from the tar directory into a temporary directory
                open_tar_file.extract('{basename}/{basename}.pdf'.format(basename=basename), path=temp_dir)
                tmp_pdf_filename = os.path.join(temp_dir, basename, '{basename}.pdf'.format(basename=basename))
                pdf_reader = PdfFileReader(tmp_pdf_filename)
                extraction_function(pdf_reader)


def make_summary_pdf(input_directory, output_pdf_filename):
    pdf_writer = PdfFileWriter()
    extraction_function = lambda pdf_reader: pdf_writer.appendPagesFromReader(pdf_reader)
    extract_from_pdfs(input_directory, extraction_function)
    with open(output_pdf_filename, 'wb') as output_stream:
        pdf_writer.write(output_stream)


def make_signal_to_noise_pdf(input_directories, sites, daysobs, output_text_filenames, output_pdf_filename):

    signal_to_noise_table = Table(names=['target', 'mag', 'sn', 'exptime', 'site', 'dayobs'], dtype=('S60', np.float,
                                                                                                     np.float, np.float,
                                                                                                     'S3', 'S8'))
    for input_directory, site, dayobs, output_text_filename in zip(input_directories, sites, daysobs, output_text_filenames):
        extraction_function = lambda pdf_reader: extract_signal_to_noise_from_pdf(pdf_reader, signal_to_noise_table, site, dayobs)
        # Extract the Signal to noise
        extract_from_pdfs(input_directory, extraction_function)
        output_table = signal_to_noise_table[np.logical_and(signal_to_noise_table['site'] == site,
                                                            signal_to_noise_table['dayobs'] == dayobs)]
        if output_text_filename is not None:
            output_table.write(output_text_filename, format='ascii', overwrite=True)

    plot_signal_to_noise(output_pdf_filename, signal_to_noise_table, sites, daysobs)


def extract_signal_to_noise_from_pdf(pdf_reader: PdfFileReader, output_table: Table, site: str, dayobs: str):
    pdf_text_to_search = pdf_reader.getPage(0).extractText()
    # parse the output with an easy to read regex.
    regex = '^([\w_\s\+-]+)\,\s.+expt\s?=\s?(\d+) s\,.+N=\s*(\d+\.\d+),'
    m = re.search(regex, pdf_text_to_search)
    if m is not None:
        output_table.add_row({'target': m.group(1), 'mag': get_mag_from_simbad(m.group(1)),
                              'sn': m.group(3), 'exptime': m.group(2), 'site': site, 'dayobs': dayobs})
    else:
        logger.error("Failed to extract S/N", extra={'tags': {'regex': regex,
                                                              'search_text': pdf_text_to_search}})


def get_missing_files(raw_directory, specproc_directory):
    get_files_without_extensions_and_e00 = lambda filenames, extension: [os.path.basename(filename).replace(extension, "")[:-4]
                                                                         for filename in filenames]
    raw_files = get_files_without_extensions_and_e00(glob(os.path.join(raw_directory, '*e00.fits*')), '.fits.fz')
    processed_files = get_files_without_extensions_and_e00(glob(os.path.join(specproc_directory, '*.tar.gz')), '.tar.gz')
    return raw_files, processed_files, list(set(raw_files) - set(processed_files))


def get_calibration_files_taken(raw_directory):
    bias_files = glob(os.path.join(raw_directory, '*b00.fits.fz'))
    dark_files = glob(os.path.join(raw_directory, '*d00.fits.fz'))
    flat_files = glob(os.path.join(raw_directory, '*w00.fits.fz'))
    arc_files = glob(os.path.join(raw_directory, '*a00.fits.fz'))
    return bias_files, dark_files, flat_files, arc_files


target_name_translations = {'PSIPHE' : 'psi Phe',
                            'MUCAS' : 'mu Cas',
                            'KS18C14487' :'TYC 8856-529-1',
                            'BD093070': 'BD-09 3070'}


def get_mag_from_simbad(target_name : str):
    try:
        simbad_query = Simbad()
        simbad_query.add_votable_fields('flux(V)')

        search_name = target_name.split('_')[0]
        if search_name in target_name_translations:
            search_name = target_name_translations[search_name]
        logger.info('Querying Simbad for {target}'.format(target=search_name))
        result = simbad_query.query_object(search_name)
        mag = float(result['FLUX_V'][0])
    except Exception as e:
        logger.error('Simbad query failed for {target}: {exeception}'.format(target=target_name, exeception=e))
        mag = np.nan

    return mag


def download_from_s3(frameid, output_directory):
    url = f'{settings.ARCHIVE_FRAME_URL}/{frameid}'
    response = requests.get(url, headers=settings.ARCHIVE_AUTH_TOKEN, stream=True).json()
    with open(os.path.join(output_directory, response['filename']), 'wb') as f:
        f.write(requests.get(response['url']).content)
    return os.path.join(output_directory, response['filename'])


def ingest_file(file_path):
    retry = True
    try_counter = 1
    while retry:
        try:
            with open(file_path, 'rb') as f:
                ingester.upload_file_and_ingest_to_archive(f)
            os.remove(file_path)
            retry = False
        except DoNotRetryError as exc:
            logger.warning('Exception occured: {0}. Aborting.'.format(exc),
                           extra={'tags': {'filename': file_path}})
            retry = False
        except NonFatalDoNotRetryError as exc:
            logger.debug('Non-fatal Exception occured: {0}. Aborting.'.format(exc),
                         extra={'tags': {'filename': file_path}})
            retry = False
        except RetryError as exc:
            logger.debug('Retry Exception occured: {0}. Retrying.'.format(exc),
                         extra={'tags': {'filename': file_path}})
            retry = True
            try_counter += 1
        except BackoffRetryError as exc:
            logger.debug('BackoffRetry Exception occured: {0}. Retrying.'.format(exc),
                         extra={'tags': {'filename': file_path}})
            if try_counter > 5:
                logger.warning('Giving up because we tried too many times.', extra={'tags': {'filename': file_path}})
                retry = False
            else:
                sleep(5 ** try_counter)
                retry = True
                try_counter += 1
        except Exception as exc:
            logger.fatal('Unexpected exception: {0} Will retry.'.format(exc), extra={'tags': {'filename': file_path}})
            retry = True
            try_counter += 1
