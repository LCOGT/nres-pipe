import nres_comm as nr
import os.path
import numpy as np
import pandas as pd


def get_specdat():
    """
    This routine reads the spectrograph.csv file from the csv directory
    and returns the properties
    of the spectrograph for the site appearing in nres_common, and for
    the MJD that is the most recent relative to the input parm mjd.
    Results are placed in common structure specdat.

    """

    nr.err=0
    radian=180./np.pi

    #read csv file

    nr.nresroot = os.getenv("NRESROOT")

    #check to see if this really should be nresrooti
    filin = nr.nresroot + 'reduced/csv/spectrographs.csv'


    dats=pd.read_csv(filin)
    sites_tmp = dats['Site']

    sites=sites_tmp.values

    #find data for correct site

    #need to build screen next line is workaround
    #s=1
    #ss=1
    s = np.asarray(np.where(np.array(sites) == np.array(nr.site)),dtype=int)
    s=s.flatten()
    #print('nr.site')
    #print(nr.site)
    #print("np.array(sites)")
    #print(np.array(sites))
    #print(np.array(s))
    ns = len(s)
    #print(s[ix])


    if ns < 0:
        print('Spectrograph data not found for site = ', nr.site)
        nr.err = 1
        quit()

    #Error handling

    mjds_tmp=dats['MJD']
    mjds=mjds_tmp.values
    mjds=mjds[s]

    #print("mjds")
    #print(mjds)
    diff=np.float64(np.float64(nr.mjdc)-np.float64(mjds))
    ix=np.array(np.argmin(diff))
    ix=ix.flatten()
    print('diff')
    print(diff)
    print('ix')
    print(ix)
    #md=diff[ix]

    #print('md')
    #print(md)

    print("ix")
    print(ix)
    print('s')
    print(np.array(s))

    ss=s[ix]

    #ss=ss('0') #need to see what this does, perhaps uncomment out


    # build the coefs array
    nr.coefs=[dats["C0"][ss], dats["C1"][ss], dats["C2"][ss], dats["C3"][ss], dats["C4"][ss], dats["C5"][ss], dats["C6"][ss], dats["C7"][ss], dats["C8"][ss], dats["C9"][ss], dats["C10"][ss], dats["C11"][ss], dats["C12"][ss], dats["C13"][ss], dats["C14"][ss]]

    ncoefs=15

    nr.fibcoefs=[dats["F00"][ss],dats["F01"][ss],dats["F02"][ss],dats["F03"][ss],dats["F04"][ss],dats["F05"][ss],dats["F06"][ss],dats["F07"][ss],dats["F08"][ss],dats["F09"][ss],dats["F10"][ss],dats["F11"][ss],dats["F12"][ss],dats["F13"][ss],dats["F14"][ss],dats["F15"][ss],dats["F16"][ss],dats["F17"][ss],dats["F18"][ss],dats["F19"][ss]]

    #make sinalp, for consistency with what we need in thar_amoeba2

    nr.grinc = dats["GrInc"][ss].values
    nr.grinc = np.float(nr.grinc)


    nr.sinalp = np.sin(nr.grinc/radian)

    nr.specdat = {'site':dats["Site"][ss],'mjd':dats["MJD"][ss],'ord0':dats["Ord0"][ss],'grspc':dats["GrSpc"][ss],'grinc':dats["GrInc"][ss], 'dgrinc':dats["dGrInc"][ss],'fl':dats["FL"][ss],'dfl':dats["dFL"][ss],'y0':dats["Y0"][ss],'dy0':dats["dY0"][ss],'z0':dats["Z0"][ss],'dz0':dats["dZ0"][ss],'gltype':dats["Glass"][ss],'apex':dats["Apex"][ss],'lamcen':dats["LamCen"][ss],'rot':dats["Rot"][ss],'pixsiz':dats["PixSiz"][ss],'nx':dats["Nx"][ss],'nord':dats["Nord"][ss],'nblock':dats["Nblock"][ss],'nfib':dats["Nfib"][ss],'npoly':dats["Npoly"][ss],'ordwid':dats["Ordwid"][ss],'medboxsz':dats["Medboxsz"][ss],'sinalp':nr.sinalp,'coefs':nr.coefs,'ncoefs':ncoefs,'fibcoefs':nr.fibcoefs}



