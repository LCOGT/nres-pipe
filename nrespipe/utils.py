import hashlib
import os
from astropy.io import fits

from nrespipe import dbs


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
