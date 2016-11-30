import os.path
import csv


names = []
ras = []
decs = []
vmags = []
bmags = []
gmags = []
rmags = []
imags = []
jmags = []
kmags = []
pmras = []
pmdecs = []
plaxs = []
rvs = []
teffs = []
loggs = []
zeros = []


def targs_rd():
    """
    Reads the contents of NRES file targest.csv and returns the column
    vector values in arrays names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,
    pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros

    Column names are returned in the string array targhdr.



    Run this first to set path:
    import os.path
    os.environ["NRESROOT"] = "/Users/rolfsmei/Documents/research/nres_4/nres_copy4/"

    To make callable arrays:
    names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr=targs_rd.targs_rd()

    """
    nresroot = os.getenv("NRESROOT")
    targfile = nresroot + 'reduced/csv/targets.csv'
    struc = open(targfile, "rb")
    targhdr = csv.reader(struc).next()

    with open(targfile) as csvfile:
        readCSV = csv.reader(csvfile, delimiter=',')
        # Skips Header Row
        next(readCSV, None)

        for row in readCSV:
            name = row[0]
            ra = row[1]
            dec = row[2]
            vmag = row[3]
            bmag = row[4]
            gmag = row[5]
            rmag = row[6]
            imag = row[7]
            jmag = row[8]
            kmag = row[9]
            pmra = row[10]
            pmdec = row[11]
            plax = row[12]
            rv = row[13]
            teff = row[14]
            logg = row[15]
            zero = row[16]

            names.append(name)
            ras.append(ra)
            decs.append(dec)
            vmags.append(vmag)
            bmags.append(bmag)
            gmags.append(gmag)
            rmags.append(rmag)
            imags.append(imag)
            jmags.append(jmag)
            kmags.append(kmag)
            pmras.append(pmra)
            pmdecs.append(pmdec)
            plaxs.append(plax)
            rvs.append(rv)
            teffs.append(teff)
            loggs.append(logg)
            zeros.append(zero)

        return names, ras, decs, vmags, bmags, gmags, rmags, imags, jmags, kmags, pmras, pmdecs, plaxs, rvs, teffs, loggs, zeros, targhdr


