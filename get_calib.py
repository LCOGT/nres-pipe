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

    #Do some error handling, holding off until I get some sample files to test with

    fnames1=fnames(s)
    navgs1=navgs(s)
    jdates1=jdates(s)

