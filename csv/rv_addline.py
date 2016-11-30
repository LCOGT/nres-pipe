import numpy as np
import os.path
import csv
import pandas as pd

def rv_addline(targnames="",crdates="",bjds="",sites="",exptimes="",orgnames="",specos="",nmatchs="", amoerrs="",rmsgoods="",mgbdisps="",rvkmpss="",ampccs="",widccs="",lammids="",baryshifts="", rroas="",rroms="",rroes=""):
    '''
    Reads the rv.csv file, appends a line containing the data in the
    argument list, sorts the resulting list into increasing time order,
    and writes the result back out to rv.csv.
    Calling this routine with no arguments causes the standards.csv file
    to be sorted into time order, without otherwise changing it.

    Run this first to set path:
    import os.path

    '''

    nresroot=os.getenv("NRESROOT")
    rvfile=nresroot+'reduced/csv/rv.csv'

    if len(targnames)>0:
        dat=np.column_stack((targnames,crdates,bjds,sites,exptimes,orgnames,specos,nmatchs, amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammids,baryshifts, rroas,rroms,rroes))
        outfile = open(rvfile,"a")

        # get a csv writer
        writer = csv.writer( outfile )
        [ writer.writerow(x) for x in dat ]

        # close file
        outfile.close()


    df = pd.read_csv(rvfile)
    df = df.sort_values('CrDate')
    df.to_csv(rvfile,index=False)