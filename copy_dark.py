import nres_comm as nr
import os.path
import numpy as np

def copy_dark():
    """This routine takes the main data segment of the current data file from
    the nres_common area and writes it to darkdir as a standard fits file.
    Keywords are added to the header to encode the date, site, camera,
    and original filename.
    A new line describing the dark frame is added to standards.csv

    """

    #grab the data file from nres_common, make the header
    from astropy.io import fits

    dark = nr.dat.astype(float)

    #here is where all the magic happens with the get calib function




    prihdr = fits.Header()
    prihdr['MJD'] = nr.mjdc, 'Creation date'
    prihdr['NFRAVGD'] = 1, 'avgd this many frames'
    prihdr['ORIGNAME'] = nr.filename, '1st filename'
    prihdr['SITEID'] = nr.site, ' '
    prihdr['INSTRUME'] = nr.camera, ' '
    prihdr['OBSTYPE'] = 'BIAS', ' '
    prihdr['EXPTIME'] = nr.exptime, ' '
    prihdu = fits.PrimaryHDU(header=prihdr)

    # Test and make directory if not present, abort if non-writable
    # Also have to update out name and location, also trigger csv update

    fits.writeto('BIASOUT.fits', nr.bias, prihdu)