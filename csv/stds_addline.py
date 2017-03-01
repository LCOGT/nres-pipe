import numpy as np
import os.path
import csv
import pandas as pd
import nres_comm as nr

def stds_addline(types="",fnames="",navgs="",sites="",cameras="",jdates="",flags=""):

    '''
    Reads the standards.csv file, appends a line containing the data in the
    argument list, sorts the resulting list into increasing time order,
    and writes the result back out to standards.csv.
    Calling this routine with no arguments causes the standards.csv file
    to be sorted into time order, without otherwise changing it.

    '''

    nr.nresroot=os.getenv("NRESROOT")
    stdfile=nr.nresroot+'reduced/csv/standards.csv'

    if len(fnames)>0:
        dat=np.column_stack((types,fnames,navgs,sites,cameras,jdates,flags))
        outfile = open(stdfile,"a")

        # get a csv writer
        writer = csv.writer( outfile )
        [ writer.writerow(x) for x in dat ]

        # close file
        outfile.close()


    df = pd.read_csv(stdfile)
    df = df.sort_values('JDdata')
    df.to_csv(stdfile,index=False)