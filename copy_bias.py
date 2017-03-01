
import nres_comm as nr
import os.path

def copy_bias():
    """This routine takes the main data segment of the current data file from
    the nres_common area and writes it to biasdir as a standard fits file.
    Keywords are added to the header to encode the date, site, camera,
    and original filename.
    A new line describing the bias frame is added to standards.csv

    """

    #grab the data file from nres_common, make the header
    from astropy.io import fits

    bias = nr.dat.astype(float)

    prihdr = fits.Header()
    prihdr['MJD'] = nr.mjdc, 'Creation date'
    prihdr['NFRAVGD'] = 1, 'avgd this many frames'
    prihdr['ORIGNAME'] = nr.filename, '1st filename'
    prihdr['SITEID'] = nr.site, ' '
    prihdr['INSTRUME'] = nr.camera, ' '
    prihdr['OBSTYPE'] = 'BIAS', ' '
    prihdr['EXPTIME'] = nr.exptime, ' '
    #prihdu = fits.PrimaryHDU(header=prihdr)  Don't think I need.

    biaso='BIAS'+str(nr.datestrc)+'.fits'
    biasdir=nr.nresroot+nr.biasdir
    biasout=nr.nresroot+nr.biasdir+biaso

    if not os.path.exists(biasdir):
           os.makedirs(biasdir)

    fits.writeto(biasout, bias, prihdr)

    import stds_addline
    stds_addline.stds_addline('BIAS','bias/'+biaso,1,nr.site,nr.camera,nr.jdc,'0000')

    if nr.verbose==1:
        print('*** copy_bias ***')
        print('File In = ', nr.filin0)
        naxes = nr.dathdr, ['NAXIS']
        nx = nr.dathdr, ['NAXIS1']
        ny = nr.dathdr, ['NAXIS2']
        print('Naxes, Nx, Ny = ', naxes, nx, ny)
        print('Wrote file to bias dir:')
        print(biasout)
        print('Added line to reduced/csv/standards.csv')





