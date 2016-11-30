import numpy as np
import os.path
import csv


def stds_write(types,fnames,navgs,sites,cameras,jdates,flags):
    '''
    Writes the vectors in the calling sequence to NRES file standards.csv,
    overwriting whatever was there.  No warnings are issued.

    To setup first run these if your NRRESROOT isn't set, or change to master folder
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"
    '''

    nresroot=os.getenv("NRESROOT")

    #Writing vectors into one array
    dat=np.column_stack((types,fnames,navgs,sites,cameras,jdates,flags))

    #set savefile path
    stdsfile=nresroot+'reduced/csv/standards.csv'

    #set headers
    hdrs=['Type','Filename','Navg','Site','Camera','JDdata','Flags']

    # open output file
    outfile = open(stdsfile,"wb")

    # get a csv writer
    writer = csv.writer( outfile )

    # write header
    writer.writerow(hdrs)

    # write data
    [ writer.writerow(x) for x in dat ]

    # close file
    outfile.close()



