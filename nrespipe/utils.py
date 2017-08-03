import hashlib
import os
import time
import datetime

import requests
from astropy.io import fits

from nrespipe import dbs
from nrespipe import settings
import logging

from kombu import Connection, Exchange
import shutil

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


def filename_is_blacklisted(path):
    # Only get raw files
    if not '00.fits' in path:
        return True

    for blacklisted_filetype in settings.blacklisted_filenames:
        if blacklisted_filetype in path:
            return True


def is_raw_nres_file(path):
    try:
        header = fits.getheader(path)
    except:
        return False

    telescope = header.get('TELESCOP')

    if telescope is not None:
        is_nres = 'nres' in telescope.lower()
    else:
        is_nres = False
    return is_nres


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