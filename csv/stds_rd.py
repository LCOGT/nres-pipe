import os.path
import csv

types = []
fnames = []
navgs = []
sites = []
cameras = []
jdates = []
flags = []


def stds_rd():
    """
    Reads the contents of NRES file standards.csv and returns the column
    vector values in arrays types,fnames,navgs,sites,cameras,jdates,flags.

    Column names are returned in the string array stdhdr.

    To retrieve all vectors in Python:

    Run this first to set path:
    import os.path

    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"

    types, fnames, navgs, sites, cameras, jdates, flags, stdhdr = stds_rd.stds_rd()

    """
    nresroot = os.getenv("NRESROOT")
    stdfile = nresroot + 'reduced/csv/standards.csv'
    struc = open(stdfile, "rb")
    stdhdr = csv.reader(struc).next()

    with open(stdfile) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        # Skips Header Row
        next(readCSV, None)

        for row in readCSV:
            type = row[0]
            fname = row[1]
            navg = row[2]
            site = row[3]
            camera = row[4]
            jdate = row[5]
            flag = row[6]

            types.append(type)
            fnames.append(fname)
            navgs.append(navg)
            sites.append(site)
            cameras.append(camera)
            jdates.append(jdate)
            flags.append(flag)

        return types, fnames, navgs, sites, cameras, jdates, flags, stdhdr
