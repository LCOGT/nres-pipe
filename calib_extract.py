import nres_comm as nr
import os.path
import numpy as np
from astropy.io import fits


def calib_extract(flatk='flatk',dble='dble'):
    """This routine calibrates (bias and background subtracts) an NRES image
    stored in common, extracts to yield 1-dimensional spectra for as many
    orders and fibers as there are, divides these by an appropriate flat field
    file, and places results and metadata in common.
    If the image is intended to serve as a FLAT, then set keyword flatk
    and division by the flat will not be done.
    If the keyword dble is set, then the output fits file is given a name
    '.../spec/DBLE********.*****'. In any case, the output filename is saved
    in nres_comm in variable speco.
    It gets necessary info about the spectrograph from the "spectrographs"
    config file, and from the image main block header.

    """


    #get spectrograph info, notably nord
    import get_specdat
    get_specdat.get_specdat()

    print(nr.specdat['nord'])

    #get specdat written, need to impliment here
    #bunch of other .pro's to write for calib_extract
