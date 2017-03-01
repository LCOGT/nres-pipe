import nres_comm as nr
import os.path

def get_calib(stype,filename,cdat,chdr,gerr):
    """Put description here"""

    gerr = 0

    import stds_rd

    types, fnames, navgs, sites, cameras, jdates, flags, stdhdr = stds_rd.stds_rd()

    #for testing stype='DARK'

    stypeu=stype  #Need to verify this should be nr.type
    siteu=nr.site
    camerau=nr.camera

    #find where in array matches type, site, camera
    #s = np.where(np.logical_and(np.asarray(types) == stypeu, np.asarray(sites) == siteu, np.asarray(cameras) == camerau)) #works
    #s = np.where(np.logical_and(np.asarray(types) == stypeu, np.asarray(sites) == siteu, np.asarray(cameras) == camerau,np.asarray(flags) == '0'))
    #bottom one is apparently too long.
