import nres_comm as nr
import os.path
import numpy as np
from astropy.io import fits


def get_calib(stype,cdat,chdr):
    """Put description here


    """

    gerr = 0

    import stds_rd

    types, fnames, navgs, sites, cameras, jdates, flags, stdhdr = stds_rd.stds_rd()

    #for testing
    #stype='DARK'

    stypeu=stype  #Need to verify this should be nr.type
    siteu=nr.site
    camerau=nr.camera

    #find where in array matches type, site, camera

    #need to test this out further, I think it's working, but need to verify
    s = np.where(np.all([np.asarray(types) == stypeu, np.asarray(sites) == siteu, np.asarray(cameras) == camerau,
                         np.asarray(flags) == '0'], axis=0))
    ns=len(s)



    #Do some error handling, holding off until I get some sample files to test with
    if ns < 0:
        print('No valid files of type ', stype, 'found in get_calib')
        gerr=1
        filename='NULL'
        cdat=[[0.]]
        chdr=['NULL']
        quit()

    fnames1=np.array(fnames)[s]
    navgs1=np.array(navgs)[s]
    jdates1=np.array(jdates)[s]

    jdiff1=np.absolute(np.float64(jdates1) - np.float64(nr.jdc))

    ix = np.argmin(jdiff1)
    md=jdiff1[ix]

    dt=np.maximum((1.5*md),(md + 1.5))

    #Probably need to add line that works for my data set.  s2 returning no results

    s2 = np.where(np.all([(np.asarray(jdiff1) < np.asarray(dt)), (np.asarray(navgs1) > "1")], axis=0))

    ns2=len(s2)

    if ns2 > 0:
        fnames2 = np.array(fnames1)[s2]
        navgs2 = np.array(navgs1)[s2]
        jdates2 = np.array(jdates1)[s2]
        jdiff2 = np.absolute(np.float64(jdates2) - np.float64(nr.jdc))
        ix2 = np.argmin(jdiff2)
        md2 = jdiff2[ix2]
        filename = fnames2[ix2]
    else:
        filename=fnames1[ix]

    #hack around not having full data sets, uncomment next row, and remove the following when ready
    path=nr.nresroot+'reduced/'+filename


    #path = '/Users/rolfsmei/Documents/research/pipeline/TestData/sqa0m801-en03-20150415-0001-e00.fits'

    if stype == "BIAS":
        nr.biasdat,nr.biashdr = fits.getdata(path, header=True)
        nr.biasfile = path

    if stype == "FLAT":
        nr.flatdat, nr.flathdr = fits.getdata(path, header=True)
        nr.flatfile = path

    if stype == "TRACE":
        nr.tracedat, nr.tracehdr = fits.getdata(path, header=True)
        nr.tracefile = path














