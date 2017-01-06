'''
This is the python version of the nres_comm common block that is used
by the main routine muncha and its subroutines.
Normally used as
import nres_comm as nr
All of its contents are then accessed as nr.whatever.
Defaults are set here, but all contents are expected to be reset at some
point as the code runs.
Comment #from blotto, blather
means that this variable's value is set or changed in routines blotto & blather
'''
import numpy as np

filin0='null'    # string name of input data file or calibration file currently
                 # being processed.  From muncha input argument.

# All of the following are set in muncha
nresroot='null'  # content of $NRESROOT environment var.
tempdir='null'   # dir for temporary data storage during reduction, if needed.
expmdir='null'   # dir for output from expmeter.pro reduction step
thardir='null'   # dir for output from tharwavelen.pro reduction step
specdir='null'   # dir for output from calib_extract.pro reduction step.
                 #    Includes flat-fielded extracted spectra.
ccordir='null'   # dir for output from cross_correl.pro reduction step
rvdir='null'     # dir for output from radial_velocity.pro reduction step
classdir='null'  # dir for spec_classify.pro reduction step
diagdir='null'   # dir for diagnostic plots to be displayed by "real" 
                 #   database code
csvdir='null'    # dir to hold searchable, editable *.csv files.  Includes:
                 # spectrographs.csv, standards.csv, targets.csv, zeros.csv
biasdir='null'   # dir to hold standardized bias images.
                 # ***** "standardized" means
                 # they contain only data for a single camera (eg 
                 # science camera), and with minimal headers.
darkdir='null'   # dir to hold standardized dark images
flatdir='null'   # dir to hold standardized extracted flat images
tracedir='null'  # dir to hold trace data in standard form, in a FITS file.
tripdir='null'   # dir to hold triple-ThAr shift data in standard form, 
                 # in a FITS file

# date-related vars from ingest, thar_fitoff, mk_flat1
jdc=2450000.0    # system time at which pipeline was run
mjdc=50000.0     # jdc - 2400000.5 days
datestrc='2016001.99999'  # string date (YYYY+DOY+fractional day) used to name 
                 # standard files (BIAS, DARK, FLAT, ZERO, TRIPLE, TRACE) 
                 # created by the pipeline.

# vars connected with spectrograph and detector geometry, etc. 
# From spectrographs.csv file, via get_specdat

specdat={
'site':'null',     # site ID housing spectrograph, eg 'lsc'
'mjd':mjdc,         # convenience copy of nr.mjd

'ord0':56,         # diffraction order of redmost order
'grspc':24.04420,  # grating groove spacing (microns)
'grinc':76.30324,  # incidence angle onto grating (degree)
'dgrinc':0.0,      # starting range for amoeba search for grinc
'sinalp':0.97156251,# sin(grinc) = sine of grating incidence angle
'fl':374.7385,     # spectrograph camera fl (mm)
'dfl':0.01,        # starting range for fl
'y0':-22.33,       # spectrograph gamma angle parameter
'dy0':0.0,         # starging range for y0
'z0':0.0002536,    # (n-1) for air surrounding spectrograph optics
'dz0':2.e-6,       # starting range for z0
'glass':'PBM2',    # string prism glass type, eg 'PBM2'
'apex':55.0,       # prism apex angle (degrees)
'lamcen':0.4790,   # nominal central wavelength (ie zero prism net deflection) 
#                  (microns)
'rot':0.0,         # rotation angle of detector (deg)
'pixsiz':0.015,    # detector pixel size (mm)
'nx':4096,         # number of active (non-overscan) pixels on detector
'nord':67,         # number of orders to be extracted
'nblock':12,       # number of blocks to use in cross-correlation reduction step
'nfib':3,          # number of fibers allowed by the spectrograph
'npoly':5,         # order of polynomial describing trace for one diffrac order
'ordwid':10.5,     # cross-dispersion order width (pix)
'medboxsiz':17,    # size of bkgnd-removal median box in binned-by-4 pixels
'ncoefs':15,       # number of coeffs describing wavelength solution(x,order)
'coefs':np.zeros(15),# coeffs describing wavelength solution(x,order)
'fibcoefs':np.zeros(10) # coeffs describing relative xpos among fibers
}
nblock=specdat['nblock']
nx=specdat['nx']
nord=specdat['nord']
nfib=specdat['nfib']
ny=nx            # assume square input data array until told otherwise

# vars connected with input file main data segment
filname='null'   # original filename ('ORIGNAME') of the input data file
                 # From ingest
dat=np.zeros((nx,ny),dtype=float) # raw science data array (numpy). From ingest
dathdr=['null']  # header for raw input main data segment.  From ingest
cordat=np.zeros((nx,ny),dtype=float) # main science data image (numpy), 
                 # corrected (for bias, dark, background). From calib_extract
varmap=np.zeros((nx,ny),dtype=float) # 2D variance in corrected image. 
                 # From mk_variance
corspec=np.zeros((nx,nord,nfib),dtype=float)  # corrected (for flat field) 
                 #extracted spectrum From calib_extract, apply_flat, thar_fitoff
rmsspec=np.zeros((nx,nord,nfib),dtype=float) # est. rms of corspec
speco='null'     # not clear what this variable is used for
expmdat=np.zeros((4,1),dtype=float) # time-tagged intensities from 3 fibers
expmhdr=['null'] # header of exposure meter input data segment 
expmvals={'flwttime':0.} # summary values computed from exposure meter data
agu1={'vals':[0.]} # AGU1 summary data (unused)
agu1hdr=['null'] # header of AGU1 input data segment (unused)
agu2={'vals':[0.]} # AGU2 summary data (unused)
agu2hdr=['null'] # header of AGU2 input data segment (unused)
teldat1=['null'] # unused
tel1hdr=['null'] # unused
tel2dat=['null'] # unused
tel2hdr=['null'] # unused
type='null'      # type of current observation, 'BIAS','DARK','FLAT','TARGET',
                 # or 'DOUBLE'
site='null'      # site from which observation was obtained, eg 'lsc'
telescop='null'  # telescope designation, eg '1m002'
camera='null'    # camera designation, eg 'fl09'
exptime=0.       # main image exposure time (s)

ccd={            # ccd structure containing CCD camera parameters
'camera':'null', # ccd identifier, eg 'fl09'
'nx':4096,       # pixel count in x direction
'ny':4096,       # pixel count in y direction
'datsegmin':0,   # data segment min coord
'datsegmax':0,   # data segment max coord
'gain':0.,       # CCD reciprocal gain (e- per ADU)
'rdnois':0.,     # CCD read noise (e-)
'pixsiz':0.      # pixel size (micron)
}

orddiff=np.zeros((nord),dtype=float) # array containing the diffraction order
                 # for each of nord order indices
# tracedat contains information relating to the order tracing.
# These data mostly come from the designated TRACE standard file, or are
# computed from it.
nleg=5           # number of Legendre coefficients per order for traces
tracedat={
'trace':np.zeros((nleg,nord,nfib),dtype=float), # legendre coefficients for
                 # nord x nfib order y positions
'npoly':0,       # max number of polynomial coeffs used to parameterize the 
                 # variation of the nleg coefficients with order index.
'ord_vectors':np.zeros((nx,nord,nfib),dtype=float), # traced order center
                 # y-positions vs iord,ifib
'ord_wid':0.,    # full width of each order extraction box (pix)
'medboxsz':0.,   # width of the median-filtering box for background subtraction,
                 # to be applied in the 4x4-binned image.
'tracefile':'null' # name of the tracefile used to analyze the current image
}

#echdat contains data relating to the echelle extraction
echdat={
'spectrum':np.zeros((nx,nord,nfib),dtype=float), # intensity integrated across 
                 # order vs x, order, fiber
'specrms':np.zeros((nx,nord,nfib),dtype=float), # formal error of spectrum
'specdy':np.zeros((nx,nord,nfib),dtype=float), # cross-dispersion position of
                 # spectrum in extraction box
'specwid':np.zeros((nx,nord,nfib),dtype=float), # 2nd moment of cross-disp
                 # intensity
'diffrms':np.zeros((nord,nfib),dtype=float), # rms of obsd-model spectrum by
                 # order, fiber
'nx':0,          # number of pixels along the dispersion
'nord':0,        # number of orders in spectrum
'nfib':0,        # number of fibers that may be illuminated in this spectrogrph
'nthar':1,       # number of fibers carrying ThAr light, must claim to be != 0.
'mjd':0.,        # mjd of input data file
'origname':'null', # name of original image data file
'siteid':'null', # site ID for spectrograph used
'camera':'null', # CCD camera ID (INSTRUME keyword)
'exptime':0.,    # original image exposure time (s)
'objects':'none&none&none', # object names corresp to each fiber, separated
                 # by "&"
'nelectron':np.zeros((nfib),dtype=float), # total number of electrons recorded
                 # in each fiber
'craybadpix':0   # total number of cosmic ray pixels identified in image
}
nthar=echdat['nthar'] # some of the following chokes if nthar=0

# flatdat contains data relating to flat-field data used
flatdat={
'flat':np.zeros((nx,ny),dtype=float), # the flat field image
'flatfile':'null', # name of flat-field image used in reduction
'flathdr':['null'] # header of flat-field image used in reduction
}

# agu1red contains data relating to reduction of AGU_1
agu1red={
'vals':[0.]        # values are as yet undefined
}

# agu2red contains data relating to reduction of AGU_2
agu2red={
'vals':[0.]        # values are as yet undefined
}

# expmred contains data relating to the exposure meter processing
expmred={
'vals':[0.]        # values are as yet undefined
}

# tharred contains data relating to the ThAr processing
tharred={
'fibth':np.zeros((nthar,),dtype=np.int),     # indices of fibers with ThAr
'lam':np.zeros((nx,nord,nthar),dtype=float), # wavelength solution per pixel,
                                             # order, fiber
'sinalp':np.zeros((nthar,),dtype=float),     # sin(grinc), fitted per thar fiber
'fl':np.zeros((nthar,),dtype=float),         # camera fl, fitted per thar fiber
'y0':np.zeros((nthar,),dtype=float),         # y0 of zero gamma, per thar fib
'z0':np.zeros((nthar,),dtype=float),         # n-1 (or relativistic z), fitted
                                             # per thar fiber
'coefs':np.zeros((specdat['ncoefs'],nthar),dtype=float), # restricted cubic 
                                             # coeffs, fitted per thar fiber
'site':site,          # observatory site ID (eg 'lsc') %%%redundant?%%%
'jd':2450000.0,       # flux-weighted JD of observation
}

# crossred contains data relating to the cross-correlation processing
crossred={
'vals':[0.]           # values are as yet undefined
}

# rvred contains data relating to the radial velocity processing
rvred={
'rroa':0.,            # weighted avg over orders of fitted stellar redshifts
'rrom':0.,            # median of fitted stellar redshift over selected
                      # orders, blocks
'rroe':0.,            # measure of scatter in rro
'rro':np.zeros((2,nord,nblock),dtype=float),    # redshift vs fiber, order,
                      # block (dimensionless)
'erro':np.zeros((2,nord,nblock),dtype=float),   # formal err in rro elements
'aao':np.zeros((2,nord,nblock),dtype=float),    # intensity scale factor vs
                      # fiber, order, block
'eaao':np.zeros((2,nord,nblock),dtype=float),   # formal uncertainty in aao
'bbo':np.zeros((2,nord,nblock),dtype=float),    # intensity x deriv parameter
                      # vs fiber, order, block
'ebbo':np.zeros((2,nord,nblock),dtype=float),   # formal uncertainty in bbo
'pldpo':np.zeros((2,nord,nblock),dtype=float),  # photon-limited doppler
                      # precision (km/s) vs fiber, order, block
'ccmo':np.zeros((2,801),dtype=float),          # Mg b order cross-correl vs lag
                      # (pixels) for each fiber
'delvo':np.zeros((2,801),dtype=float),           # velocity vs lag in pixels for
                      # each fiber
'rvvo':np.zeros(2,dtype=float),      # estimated RV (km/s) per fiber, w/o
                      # barycentric correction
'rcco':np.zeros(2,dtype=float),      # estimated cross-correl redshift
                      # (dimensionless) per fiber, w/o barycentric corr
'ampcco':np.zeros(2,dtype=float),  # amplitude of cross-correl peak, per fiber,
                      # in range [0,1]
'widcco':np.zeros(2,dtype=float)    # width of cross-correl peak, per fiber,
                      # in pixel (delvo) units
}

#spclassred contains data relating to the spectral type classifications
spclassred={
'vals':[0.]      # vals are as yet undefined
}

verbose=0        # variable governing the amount of diagnostic data printed
