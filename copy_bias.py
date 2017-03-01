
import nres_comm as nr


def copy_bias():
    """This routine takes the main data segment of the current data file from
    the nres_common area and writes it to biasdir as a standard fits file.
    Keywords are added to the header to encode the date, site, camera,
    and original filename.
    A new line describing the bias frame is added to standards.csv

    """

    #grab the data file from nres_common, make the header
    from astropy.io import fits

    nr.bias = nr.dat.astype(float)

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


    #Test and make directory if not present, abort if non-writable




    #need to make header with something like this
    #prihdr = fits.Header()
    #prihdr['MJD'] = nr.mjdc,'Creation date'
    #prihdr['NFRAVGD'] = 1,'avgd this many frames'
    #prihdr['ORIGNAME'] = nr.filename,'1st filename'
    #prihdr['SITEID'] = nr.site,' '
    #prihdr['INSTRUME'] = nr.camera,' '
    #prihdr['OBSTYPE'] = 'BIAS',' '
    #prihdr['EXPTIME'] = nr.exptime,' '
    #prihdu = fits.PrimaryHDU(header=prihdr)
    #fits.writeto('out.fits', nr.bias, prihdr)




    #tbhdu=tbhdu = fits.BinTableHDU.from_columns(nr.dathdr)

    #    nr.dathdr
#thdulist = fits.HDUList([prihdu, tbhdu])
#thdulist.writeto('table.fits')

#fits.getdata(filin, header=True)


#prihdr = fits.Header()
#prihdr['OBSERVER'] = 'Edwin Hubble',testing
#prihdr['COMMENT'] = "Here's some commentary about this FITS file.",test2
#prihdu = fits.PrimaryHDU(header=prihdr)
#
#fits.writeto('out.fits', nr.bias, prihdr)

