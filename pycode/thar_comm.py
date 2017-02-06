'''
This is the python version of the thar_comm common block that is used
by the main routine muncha and its subroutines.
Normally used as
import thar_comm as nt
All of its contents are then accessed as nt.whatever.
Defaults are set here, but all contents are expected to be reset at some
point as the code runs.
Comment #from blotto, blather
means that this variable's value is set or changed in routines blotto & blather
nres_comm must be run before thar_comm.
'''
import numpy as np
import nres_comm as nr

# this group contains spectrograph parameters, read by get_specdat
# Almost all of these are redundant, ie copies of variables found in nres_comm

mm_c=nr.mm          # diffraction order number for each 
                # extracted order
grspc_c=nr.specdat['grspc']    # grating groove spacing (micron)
sinalp_c=nr.specdat['sinalp']  # sin of grating angle of incidence
fl_c=nr.specdat['fl']          # focal length of camera (mm)
y0_c=nr.specdat['y0']          # detector y coord (mm, measured from center) 
                # where gamma = 0.
z0_c=nr.specdat['z0']    # red shift for spectrum;  (1.+z0_c) is the effective 
                # refractive index of air in the optical path.
gltype_c=nr.specdat['glass']  # glass type for cross-disperser, eg BK7
apex_c=nr.specdat['apex']      # prism vertex angle in degrees
lamcen_c=nr.specdat['lamcen']  # nominal wavelength at which net prism 
                # deflection is zero (micron)
rot_c=nr.specdat['rot']        # rotation angle of detector, CCW seen from 
                # front (degree)
pixsiz_c=nr.specdat['pixsiz']  # detector pixel size (micron)
nx_c=nr.nx          # number of pixels per line in trimmed image
nord_c=nr.nord      # number of diffraction orders to be extracted from image
nfib_c=nr.nfib        # number of illuminated fibers for this spectrograph

# emission line spectrum and line parameters extracted from ThAr spectum 
tharspec_c=np.zeros((nx_c,nord_c),dtype=float) # extracted ThAr spec from 
                    # wavelength standard fiber = fiber 1.
iord_c=np.zeros(1,dtype=float)  # order numbers of each of the ThAr lines found
                #  in the current spectrum (ie, the "catalog" lines)
xpos_c=np.zeros(1,dtype=float)  # x-pixel position of each of the 
                # detected "catalog" lines (pixels)
amp_c=np.zeros(1,dtype=float) #  amplitudes (nominal e-) of each of 
                # the "catalog" lines (ADU)
wid_c=np.zeros(1,dtype=float)   # width of each of the "catalog" lines (pixels)

# parameters controlling the min chi^2 wavelength solution.  First for the
# amoeba-based routines.
dsinalp_c=1.e-4   # starting amoeba range for sinalp 
dfl_c=1.e-2       # starting amoeba range for fl
dy0_c=1.e-2       # starting amoeba range for y0
dz0_c=5.e-7       # starting amoeba range for z0

# ThAr line list parameters, normally from Redman et al.
linelam_c=np.zeros(1,dtype=float)  # wavelengths for each line in the 
                  # standard ThAr linelist (nm)
lineamp_c=np.zeros(1,dtype=float)  # brightness for each line in the 
                  # standard ThAr linelist (arbitrary units)

# information about allegedly matched "catalog" lines, ie, lines found in
# the current spectrum
matchlam_c=np.zeros(1,dtype=float)  # model wavelength of each supposedly 
                  # matched "catalog" line
matchamp_c=np.zeros(1,dtype=float)  # amplitude (total e-) of each supposedly 
                  # matched "catalog" line
matcherr_c=np.zeros(1,dtype=float)  # formal uncertainty of each supposedly 
                  # matched "catalog" line wavelength (nm)
matchdif_c=np.zeros(1,dtype=float)  # difference between model wavelength of 
                  # each matched "catalog" line and linelist wavelength
matchord_c=np.zeros(1,dtype=int)  # order index (0 to nord_c-1) in which 
                  # matched line appearsx
matchxpos_c=np.zeros(1,dtype=float)  # x-coordinate of observed matched 
                  # "catalog" line (pix)
matchwts_c=np.zeros(1,dtype=float)  # model wavelength of each supposedly 
                  # matched "catalog" line
matchline_c=np.zeros(1,dtype=float)  # wavelength for each supposedly 
                  # matched standard linelist line (nm)
matchbest_c=np.zeros(1,dtype=float)  # model wavelength for each matched 
                  # "catalog" line, after correction for polynomial shifts 
                  # from rcubic
nmatch_c=0        # number of detected "catalog" lines that are wavelength 
                  # matched to standard ThAr lines.  May be more than the 
                  # number of linelist lines, because wavelength overlap 
                  # causes many lines to appear twice.
unmatchlam_c = np.zeros(1,dtype=float)  # wavelengths of "catalog" lines 
                  # with no matches
unmatchamp_c = np.zeros(1,dtype=float)  # amplitudes of "catalog" lines 
                  # with no matches

# information about the amoeba fit and the rcubic fit
dlam2_c=1.e10     # summed squared lambda matching error, over matched lines
                  # (nm^2)
chi2_c=1.e10      # chi^2 value coming out of rcubic lstsqr.pro fit
niter_c=0         #  counts amoeba iterations as it searches for minimum
rms_c=0.          # rms of residuals to rcubic wavelength fit (nm)
mgbdisp_c=0.      # wavelength spread (max-min) in Mg-b order (nm)
lammid_c=0.       # center wavelength of Mg-b order

# various final results from wavelength fit
lam_c=np.zeros((nx_c,nord_c),dtype=float) # final wavelength model 
                  # lambda(nx,nord) (nm)
y0m_c=np.zeros(nord_c,dtype=float) # center-of-detector order y-position 
                  # for each order (mm).  This variable is poorly named, since
                  # it has nothing to do with y0_c.
ncoefs_c=15       # number of coefficients used in polynomial 
                  # wavelength correction
coefs_c=np.zeros(ncoefs_c,dtype=float) # wavelength correction polynomial 
                  # coeffs.  These multiply polynomials in x-coordinate 
                  # and order index
outp_c=np.zeros(1,dtype=float)  # residuals from last rcubic fit of catalog 
                  # wavelengths to x-position

# various astronomical constants
airmass_c=np.zeros(nfib_c-1,dtype=float)+1.  # airmass of obs for each telescop
bjdtdb_c=57000.0  #  BJD of observation
dec_c= np.zeros(nfib_c-1,dtype=float)  # declination of target (deg), per telesc
exptime_c= np.zeros(nfib_c-1,dtype=float) # expose duration for observation (s)
                  # per telescope
jdtdb=2457000.0   #  julian date of exposure start time
moonalt_c=-89.    #  moon altitude at exposure start (deg)
moonphase_c=0.    #  moon illuminated phase (percent) at exposure start
moonsep_c=np.zeros(nfib_c-1,dtype=float) #  moon separation from target at 
                  # exposure start (deg)
ra_c=np.zeros(nfib_c-1,dtype=float)  #  target RA (deg)

