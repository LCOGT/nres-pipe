import nres_comm as nr
import os.path
import numpy as np

def copy_dark():
    """This routine takes the main data segment of the current data file from
    the nres_common area and writes it to darkdir as a standard fits file.
    Keywords are added to the header to encode the date, site, camera,
    and original filename.
    A new line describing the dark frame is added to standards.csv

    For testing:
    get_calib,'BIAS',biasfile,bias,biashdr

    """

    #grab the data file from nres_common, make the header
    from astropy.io import fits

    dark = nr.dat.astype(float)

    #My sample files don't have the tables, so testing with fakedatafile

    import get_calib
    get_calib.get_calib('BIAS',nr.biasdat,nr.biashdr)

    bias=nr.biasdat.astype(float)

    nr.dark = dark-bias
    nr.dark = nr.dark/nr.exptime
    nr.exptime = 1.0

    prihdr = fits.Header()
    prihdr['MJD'] = nr.mjdc, 'Creation date'
    prihdr['NFRAVGD'] = 1, 'avgd this many frames'
    prihdr['ORIGNAME'] = nr.filename, '1st filename'
    prihdr['SITEID'] = nr.site, ' '
    prihdr['INSTRUME'] = nr.camera, ' '
    prihdr['OBSTYPE'] = 'BIAS', ' '
    prihdr['EXPTIME'] = nr.exptime, ' '
    #prihdu = fits.PrimaryHDU(header=prihdr)  Dont think I need this line, need to test out

    # Test and make directory if not present, abort if non-writable
    # Also have to update out name and location, also trigger csv update


    darko='DARK'+str(nr.datestrc)+'.fits'
    darkdir=nr.nresroot+nr.darkdir
    darkout=nr.nresroot+nr.darkdir+darko

    if not os.path.exists(darkdir):
           os.makedirs(darkdir)

    fits.writeto(darkout, dark, prihdr)

    #not sure why but stds_addline is adding to last line not appending a new row, commenting out for now
    #import stds_addline
    #stds_addline.stds_addline('DARK', 'dark/' + darko, 1, nr.site, nr.camera, nr.jdc, '0000')


    if nr.verbose==1:
        print('*** copy_dark ***')
        print('File In = ', nr.filin0)
        naxes = nr.dathdr, ['NAXIS']
        nx = nr.dathdr, ['NAXIS1']
        ny = nr.dathdr, ['NAXIS2']
        print('Naxes, Nx, Ny = ', naxes, nx, ny)
        print('BIAS file used was', nr.biasfile)
        print('Wrote file to dark dir:')
        print(darkdir)
        print('Added line to reduced/csv/standards.csv')
