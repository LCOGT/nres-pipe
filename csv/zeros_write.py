import numpy as np
import os.path
import csv


def zeros_write(fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags):
    '''; Writes the vectors in the calling sequence to NRES file zeros.csv,
    ; overwriting whatever was there.  No warnings are issued.

    To setup first run these if your NRRESROOT isn't set, or change to master folder
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"
    '''
    
    nresroot=os.getenv("NRESROOT")
    
    #Writing vectors into one array
    dat=np.column_stack((fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags))
    
    #set savefile path
    zerofile=nresroot+'reduced/csv/zeros.csv'
    
    #set headers
    hdrs=['Filename','Navg','Site','Camera','Jdate','Targname','Teff','logg','B-V','J-K','Flags']
    
    # open output file
    outfile = open(zerofile,"wb")

    # get a csv writer
    writer = csv.writer( outfile )

    # write header
    writer.writerow(hdrs)

    # write data
    [ writer.writerow(x) for x in dat ]

    # close file
    outfile.close()
    


