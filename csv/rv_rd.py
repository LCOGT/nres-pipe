import os.path
import csv

targnames = []
crdates = []
bjds = []
sites = []
exptimes = []
orgnames = []
specos = []
nmatchs = []
amoerrs = []
rmsgoods = []
mgbdisps = []
rvkmpss = []
ampccs = []
widccs = []
lammids = []
baryshifts = []
rroas = []
rroms = []
rroes = []

def rv_rd():
    """
    Reads the contents of NRES file rv.csv and returns the column
    vector values in arrays targnames,bjds,sites,exptimes,orgnames,specos,
    nmatchs,amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammid,baryshifts

    Column names are returned in the string array rvhdr.

    To retrieve all vectors in Python:

    Run this first to set path:
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"

    targnames,crdates,bjds,sites,exptimes,orgnames,specos,nmatchs, amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammids,baryshifts, rroas,rroms,rroes, rvhdr
     = rv_rd.rv_rd()

    """
    nresroot = os.getenv("NRESROOT")
    rvfile = nresroot + 'reduced/csv/rv.csv'
    struc = open(rvfile, "rb")
    rvhdr = csv.reader(struc).next()

    with open(rvfile) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        # Skips Header Row
        next(readCSV, None)

        for row in readCSV:
            targname  = row[0]
            crdate  = row[1]
            bjd  = row[2]
            site  = row[3]
            exptime  = row[4]
            orgname  = row[5]
            speco  = row[6]
            nmatch  = row[7]
            amoerr  = row[8]
            rmsgood  = row[9]
            mgbdisp  = row[10]
            rvkmps  = row[11]
            ampcc  = row[12]
            widcc  = row[13]
            lammid = row[14]
            baryshift  = row[15]
            rroa  = row[16]
            rrom  = row[17]
            rroe  = row[18]

            targnames.append(targname)
            crdates.append(crdate)
            bjds.append(bjd)
            sites.append(site)
            exptimes.append(exptime)
            orgnames.append(orgname)
            specos.append(speco)
            nmatchs.append(nmatch)
            amoerrs.append(amoerr)
            rmsgoods.append(rmsgood)
            mgbdisps.append(mgbdisp)
            rvkmpss.append(rvkmps)
            ampccs.append(ampcc)
            widccs.append(widcc)
            lammids.append(lammid)
            baryshifts.append(baryshift)
            rroas.append(rroa)
            rroms.append(rrom)
            rroes.append(rroe)

        return targnames,crdates,bjds,sites,exptimes,orgnames,specos,nmatchs, amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammids,baryshifts, rroas,rroms,rroes, rvhdr
