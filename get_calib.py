import nres_comm as nr
import os.path
import numpy as np


def get_calib(stype,filename,cdat,chdr,gerr):
    """Put description here"""

    gerr = 0

    import stds_rd

    types, fnames, navgs, sites, cameras, jdates, flags, stdhdr = stds_rd.stds_rd()

    #for testing
    stype='DARK'

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
        print('No valid files of type ', stype, 'found in get_calib'
        gerr=1
        filename='NULL'
        cdat=[[0.]]
        chdr=['NULL']
        quit()

    fnames1=fnames[s]
    navgs1=navgs[s]
    jdates1=jdates[s]

    jddif1=abs(jdates1-nr.jdc)

    ix = np.argmin(jdiff)
    md=jdiff[ix]

    dt=1.5*nr.md) > (md + 1.5)
    s2 = np.where((jddif1 < dt) and (navgs1 > 1))
    ns2=len(s2)

    if ns2 > 0:
        fnames2 = fnames1[s2]
        navgs2 = navgs1[s2]
        jdates2 = jdates1[s2]
        jdiff2 = abs(jdates2-nr.jdc)
        md2 = min(jdiff2,ix2)
        filename = fnames2[ix2]
    else:
        filename=fnames1[ix]

    path=nresrooti












