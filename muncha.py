import nres_comm as nr

def muncha(filin,flatk='flatk',dbg='dbg',trp='trp',tharlist='tharlist',cubfrz='cubfrz',oskip='oskip',nostar='nostar'):
    """
     This is the main routine organizing the processing pipeline for NRES
     spectroscopic data.
     On input:
       nr.filin0 = the path to a FITS data file (with extensions) written by the
     The routine also reads data from these config files:
       csv/spectrograph.csv
       csv/targets.csv:  target entries taken from POND before observing time
     NRES data-acquisition process.
     On output:
       This routine writes or modifies the following files, where xxx = string
          containing filename root:
       If type = TARGET:
         temp/xxx.obs.txt: list of header metadata to go into obs database table
         reduced/autog/xxx.ag.csv: contains autoguider stats
         reduced/expm/xxx.exp.csv: contains exposure meter stats
         reduced/thar/xxx.thar.csv:  contains lambda solution coeffs, stats
         reduced/spec/xxx.spec.fits: extracted spectra, ThAr wavelength solution
         reduced/ccor/xxx.ccor.fits: contains cross-corr results by order, block
         reduced/rv/xxx.rv.csv: contains rv solution stats
         reduced/class/xxx.cls.csv: contains stellar classification results, stats.
         reduced/diag/xxx.diag*.ps: diagnostic plots to be saved in DB.
       If type = DARK
         reduced/dark/xxx.dark.fits: dark image, copied from input file
         csv/standards.csv:  muncha updates this file
       If type = FLAT
         reduced/flat/xxx.flat.fits: contains extracted flats
         reduced/trace/xxx.trc.fits: contains trace file for this flat
         csv/standards.csv:  muncha updates this file
       If type = DOUBLE
         reduced/dble/xxxtrip.fits:  contains extracted double spectrum
         csv/standards.csv:  muncha updates this file
     If keyword dbg is set, then certain debugging plots are produced by
      routine thar_wavelen and some of its daughter routines.
     If keyword trp is set, its value determines the source of starting
      data for arrays coefs_c and fibcoefs_c, as follows:
        trp=0 or absent:  coefs_c and fibcoefs_c come from the TRIPLE file.
        trp=1: coefs_c from spectrographs.csv, fibcoefs_c from TRIPLE.
        trp=2: coefs_c from TRIPLE and fibcoefs_c from spectrographs.csv.
        trp=3: both coefs_c and fibcoefs_c from spectrographs.csv.
     If keyword tharlist is set, its value is taken as the name of a file
       in reduced/config containing vacuum wavelengths and intensities of
       good ThAr lines.  Normally, this file will have been written by
       routine thar_wavelen, following some user editing of the Redman line list.
     If keyword cubfrz is set, it prevents the rcubic coefficients read from
       spectrographs.csv from being altered in the ThAr line-fitting process.
     If keyword oskip is set and not zero, then order oskip-1 is skipped in
     the wavelength solution.  Used for testing for bad lines.
     If keyword nostar is set and not zero, and if the input file is of type
       TARGET, then processing is conducted only through the wavelength
       solution, and no star radial velocities are computed.  This saves time
       in cases in which we desire a lot of wavelength solutions to be averaged,
       eg for tracking the time behavior of wavlen solution parameters.


    #Some testing code, Remove when done:
filin='/Users/rolfsmei/Documents/research/pipeline/TestData/sqa0m801-en03-20150415-0001-e00.fits'
import muncha
muncha.muncha(filin)
    #   filin='/Users/rolfsmei/Documents/research/data/labcam-fl09-20170308-0095-d00.fits'
    #labcam-fl09-20170310-0030-w00.fits
    #   import muncha
    #   muncha.muncha(filin)
    #
    """
    import os.path

    #constants
    nr.verbose=1           #0=print nothing; 1=dataflow tracking

    nr.nresroot = os.getenv('NRESROOT')
    nr.tempdir = 'temp/'
    nr.agdir = 'reduced/autog/'
    nr.biasdir = 'reduced/bias/'
    nr.darkdir = 'reduced/dark/'
    nr.dbledir = 'reduced/dble/'
    nr.expmdir = 'reduced/expm/'
    nr.thardir = 'reduced/thar/'
    nr.specdir = 'reduced/spec/'
    nr.ccordir = 'reduced/ccor/'
    nr.rvdir = 'reduced/rv/'
    nr.classdir = 'reduced/class/'
    nr.diagdir = 'reduced/diag/'
    nr.csvdir = 'reduced/csv/'
    nr.flatdir = 'reduced/flat/'
    nr.tracedir = 'reduced/trace/'
    nr.tripdir = 'reduced/trip/'
    nr.zerodir = 'reduced/zero/'
    nr.filin0 = filin

    # open the input file, read data segments and headers into common

    import ingest
    ierr = ingest.ingest(filin)


    #Need to build each: bias, dark, target, flat, double
    #Copy is done, run below to run, un comment out when each
    #import copy_bias
    #done=copy_bias.copy_bias()
    #next 2 lines can be removed when done, here for testing copy_bias
    #print(done)
    #print(ierr)

    #import copy_dark
    #done=copy_dark.copy_dark()
    #print(done)
    #print(ierr)

    #For Targets
    print("For Targets") # this line can be removed after done
    import calib_extract
    calib_extract.calib_extract()
    print(nr.nord)





    #Do some error handling here if ingest returns an error

