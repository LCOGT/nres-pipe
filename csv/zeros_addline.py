import numpy as np
import os.path
import csv
import pandas as pd

def zeros_addline(fnames="",navgs="",sites="",cameras="",jdates="",targnames="",teffs="",loggs="",bmvs="",jmks="",flags=""):

    '''
    Reads the zeros.csv file, appends a line containing the data in the
    argument list, sorts the resulting list into increasing time order,
    and writes the result back out to zeros.csv.
    Calling this routine with no arguments causes the zeros.csv file
    to be sorted into time order, without otherwise changing it.

    Run this first to set path:
    import os.path


    '''
    
    nresroot=os.getenv("NRESROOT")
    zerofile=nresroot+'reduced/csv/zeros.csv'
    
    if len(fnames)>0:
        dat=np.column_stack((fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags))
        outfile = open(zerofile,"a")

        # get a csv writer
        writer = csv.writer( outfile )
        [ writer.writerow(x) for x in dat ]

        # close file
        outfile.close()


    df = pd.read_csv(zerofile)
    df = df.sort_values('Jdate')
    df.to_csv(zerofile,index=False)