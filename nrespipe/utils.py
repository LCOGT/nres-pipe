import hashlib
import os
import time

import requests
from astropy.io import fits

from nrespipe import dbs
from nrespipe.main import logger


def get_md5(filepath):
    with open(filepath, 'rb') as file:
        md5 = hashlib.md5(file.read()).hexdigest()
    return md5


def need_to_process(path, db_address):
    filepath, filename = os.path.split(path)
    checksum = get_md5(path)
    record = dbs.get_processing_state(filename, filepath, checksum, db_address)
    return not record.processed or checksum != record.checksum


def is_nres_file(path):
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
    return fits.getheader(path, 'TELESCOP').lower()


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
            time.sleep(1)