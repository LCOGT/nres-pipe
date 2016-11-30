import numpy as np
import os.path
import csv
import pandas as pd

def targs_addline(name="",ra="",dec="",vmag="",bmag="",gmag="",rmag="",imag="",jmag="",kmag="",pmra="",pmdec="",plax="",rv="",teff="",logg="",zero=""):
    '''
    Reads the targets.csv file, appends a line containing the data in the
    argument list, sorts the resulting list into increasing RA order,
    and writes the result back out to targets.csv.
    Calling this routine with no arguments causes the targets.csv file
    to be sorted into RA order, without otherwise changing it.

    Run this first to set path:
    import os.path

    '''

    nresroot=os.getenv("NRESROOT")
    targfile=nresroot+'reduced/csv/targets.csv'

    if len(name)>0:
        dat=np.column_stack((name,ra,dec,vmag,bmag,gmag,rmag,imag,jmag,kmag,pmra,pmdec,plax,rv,teff,logg,zero))
        outfile = open(targfile,"a")

        # get a csv writer
        writer = csv.writer( outfile )
        [ writer.writerow(x) for x in dat ]

        # close file
        outfile.close()


    df = pd.read_csv(targfile)
    df = df.sort_values('RA')
    df.to_csv(targfile,index=False)