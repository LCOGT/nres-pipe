import nres_comm as nr
from time import gmtime, strftime

def ingest(filin):
    """
    This routine opens the multi-extension file filin and reads its contents
    (headers and data segments) into the nres common data area.
    It also exracts certain of the header data that will be of general use
    later, and places their values in common.
    On normal return ierr=0, but if expected data are not found or fail basic
    sanity checks, ierr is set to a positive integer (value depending on the
    nature  of the error).

    """

#What does this Hack do, do I need to replicate it?

    from astropy.io import fits
    from astropy.time import Time
    ierr=0

    if(nr.verbose==0):
        print('###Ingest')
        print('filin= ' +filin)

    nr.dat, nr.dathdr = fits.getdata(filin, header=True)

    nr.filename=filin.strip()

    nr.type = nr.dathdr['OBSTYPE'].strip()

    #allow 'SPECTRUM' and 'EXPERIMENTAL' for testing"
    if nr.type <> 'TARGET' and nr.type <> 'DARK' and nr.type <> 'FLAT' and nr.type <> 'BIAS' and nr.type <> 'DOUBLE' \
        and nr.type <> 'SPECTRUM' and nr.type <> 'EXPERIMENTAL':
        ierr=1
        sys.exit()


    # Get get useful keywords out of the main header and into common

    nr.camera = nr.dathdr['INSTRUME'].strip()
    nr.site = nr.dathdr['SITEID'].strip()
    nr.filname = nr.dathdr['ORIGNAME'].strip()
    nr.exptime = nr.dathdr['EXPTIME']#.strip()
    nr.objects = nr.dathdr['OBJECTS'].upper().strip()
    wobjects=nr.objects.split('&')
    nr.nfib=len(wobjects)

    if wobjects <> 'NONE':
        fib0=0
        fib1=1
    else:
        fib0=1
        fib1=2


    ns = len(wobjects) - wobjects.count("NONE")


    #make the creation dates that will appear in all the headers, etc related
    #to this input file

    time=Time.now()
    nr.jdc=time.jd
    nr.mjdc=time.mjd

    nr.datestrc = str("{:.5f}".format(float(strftime("%Y%j", gmtime())) + (nr.jdc - int(nr.jdc))))  # I think this should work? (Check with Tim)


    expmdata, nr.expmhdr = fits.getdata(filin, "EXPOSURE_METER", header=True)
    nt_expm=nr.expmhdr['NAXIS2']
    jd_start=expmdata['JD_START']
    fib0c=expmdata['FIB0COUNTS']
    fib1c=expmdata['FIB1COUNTS']
    fib2c=expmdata['FIB2COUNTS']
    flg_expm=expmdata['EMFLAGS']
    #"stub line --  derive from header"
    nr.nfib=3

    nr.expmvals = {'nt_expm': nt_expm, 'jd_start': jd_start, 'fib0c':fib0c, 'fib1c': fib1c, 'fib2c': fib2c, 'flg_expm': flg_expm}

    # not in nres_comm, but not necessary agu1data, agu1hdr, agu2data, agu2hdr
    agu1data, nr.agu1hdr = fits.getdata(filin, "AGU_1", header=True)
    nt_agu1 = nr.agu1hdr['NAXIS2']
    fname_agu1 = agu1data['FILENAME']
    jd_agu1 = agu1data['JD_UTC']
    nsrc_agu1 = agu1data['N_SRCS']
    skyv_agu1 = agu1data['SKYVAL']
    crval1_agu1 = agu1data['CRVAL1']
    crval2_agu1 = agu1data['CRVAL2']
    cd1_1_agu1 = agu1data['CD1_1']
    cd1_2_agu1 = agu1data['CD1_2']
    cd2_1_agu1 = agu1data['CD2_1']
    cd2_2_agu1 = agu1data['CD2_2']

    nr.agu1 = {'nt_agu1': nt_agu1, 'fname_agu1': fname_agu1, 'jd_agu1': jd_agu1, 'nsrc_agu1':nsrc_agu1,
    'skyv_agu1':skyv_agu1, 'crval1_agu1':crval1_agu1, 'crval2_agu1':crval2_agu1, 'cd1_1_agu1':cd1_1_agu1,
    'cd1_2_agu1':cd1_2_agu1, 'cd2_1_agu1':cd2_1_agu1, 'cd2_2_agu1':cd2_2_agu1}

    agu2data, nr.agu2hdr = fits.getdata(filin, "AGU_2", header=True)
    nt_agu2 = nr.agu2hdr['NAXIS2']
    fname_agu2 = agu2data['FILENAME']
    jd_agu2 = agu2data['JD_UTC']
    nsrc_agu2 = agu2data['N_SRCS']
    skyv_agu2 = agu2data['SKYVAL']
    crval1_agu2 = agu2data['CRVAL1']
    crval2_agu2 = agu2data['CRVAL2']
    cd1_1_agu2 = agu2data['CD1_1']
    cd1_2_agu2 = agu2data['CD1_2']
    cd2_1_agu2 = agu2data['CD2_1']
    cd2_2_agu2 = agu2data['CD2_2']

    nr.agu2 = {'nt_agu2': nt_agu2, 'fname_agu2': fname_agu2, 'jd_agu2': jd_agu2, 'nsrc_agu2':nsrc_agu2, 'skyv_agu2':skyv_agu2,
    'crval1_agu2':crval1_agu2, 'crval2_agu2':crval2_agu2, 'cd1_1_agu2':cd1_1_agu2, 'cd1_2_agu2':cd1_2_agu2,
    'cd2_1_agu2':cd2_1_agu2, 'cd2_2_agu2':cd2_2_agu2}

    return ierr








