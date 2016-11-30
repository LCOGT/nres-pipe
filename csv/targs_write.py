import numpy as np
import os.path
import csv


def targs_write(names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,pmras,pmdecs,plaxs,rvs,teffs,logg,zeros):
    '''
    Writes the vectors in the calling sequence to NRES file targets.csv,
    overwriting whatever was there.  No warnings are issued.

    To setup first run these if your NRRESROOT isn't set, or change to master folder
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"
    '''

    nresroot=os.getenv("NRESROOT")

    #Writing vectors into one array
    dat=np.column_stack((names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,pmras,pmdecs,plaxs,rvs,teffs,logg,zeros))

    #set savefile path
    targfile = nresroot+'reduced/csv/targets.csv'

    #set headers
    hdrs=['Targname','RA','Dec','Vmag','Bmag','gmag','rmag','imag','Jmag','Kmag','PMRA','PMDE','Plax','RV','Teff','Logg','ZERO']

    # open output file
    outfile = open(targfile,"wb")

    # get a csv writer
    writer = csv.writer( outfile )

    # write header
    writer.writerow(hdrs)

    # write data
    [ writer.writerow(x) for x in dat ]

    # close file
    outfile.close()



