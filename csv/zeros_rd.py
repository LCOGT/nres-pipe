import os.path
import csv

fnames = []
navgs = []
sites = []
cameras = []
jdates = []
targnames = []
teffs = []
loggs = []
bmvs = []
jmks = []
flags = []


def zeros_rd():
    """
    Reads the contents of NRES file zeros.csv and returns the column
    vector values in arrays fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,
    bmvs,jmks,flags.

    Column names are returned in zstruc.

    To retrieve all vectors in Python:

    Run this first to set path:
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"

    fnames, navgs, sites, cameras, jdates, targnames, teffs, loggs, bmvs, jmks, flags, zstruc = zeros_rd.zeros_rd()

    """
    nresroot = os.getenv("NRESROOT")
    zerofile = nresroot + 'reduced/csv/zeros.csv'
    struc = open(zerofile, "rb")
    zstruc = csv.reader(struc).next()

    with open(zerofile) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        # Skips Header Row
        next(readCSV, None)

        for row in readCSV:
            fname = row[0]
            navg = row[1]
            site = row[2]
            camera = row[3]
            jdate = row[4]
            targname = row[5]
            teff = row[6]
            logg = row[7]
            bmv = row[8]
            jmk = row[9]
            flag = row[10]

            fnames.append(fname)
            navgs.append(navg)
            sites.append(site)
            cameras.append(camera)
            jdates.append(jdate)
            targnames.append(targname)
            teffs.append(teff)
            loggs.append(logg)
            bmvs.append(bmv)
            jmks.append(jmk)
            flags.append(flag)

        return fnames, navgs, sites, cameras, jdates, targnames, teffs, loggs, bmvs, jmks, flags, zstruc
