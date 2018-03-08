pro rd_globfile,filin,head,spec,wav,corr,blks,metric
; This routine accepts the pathname to an NRES output .glob file, and returns
; the following structures:
;  head contains headers of the various extensions of the multi-extn fits
;    input files.  Tags are:
;  .hdr0 = header of primary data unit, all mandatory keywords
;  .hdr1 = header of 1st extension, keywords that relate to the observation
;          as a whole.
;  .hdr2 = header of 2nd extension, keywords that relate to ThAr fitting
;          and wavelength scales
;  .hdr3 = header of 3rd extension, keywords that relate to cross-correlation
;          estimate of RV
;  .hdr4 = header of 4th extension, keywords that relate to block-fit
;          RV estimation
;  .hdrjoint = merged contents of hdr0 - hdr4, alphabetically sorted and
;          with duplicate entries removed.
;
;  spec contains various intensity vs x-pixel index, order index spectra  
;       (all float)
;  .extr(nx,nord) = raw (not flat-fielded in any way) extracted spectrum 
;       of target star vs x index and order index.
;  .blaz(nx,nord) = blaze-subtracted extracted target star spectrum vs 
;       x index and order index
;  .spec(nx,nord) =  flat-fielded extracted target star spectrum vs
;       x index and order index
;  .thar_i(nx,nord) = raw ThAr extracted intensity
;  .thar_f(nx,nord) = flat-fielded ThAr extracted intensity
;
; wav contains the wavelength solution for the current spectrum as a function
; of x-pixel index and order index, for each of the 3 fibers.
;  .wav0(nx,nord) = wavelength (nm) for the fiber carrying the object starlight
;  .wav1(nx,nord) = wavelength (nm) for the fiber containing the reference
;     (ThAr) light.
;  .wav2(nx,nord) = wavelength (nm) for the fiber that carries neither the
;     current object starlight nor the reference light.  Usually ignorable.
; One can determine the physical fibers used from the FIB0 keyword in hdr1:
;   FIB0 = 0 means wav0 contains light from fiber 0,
;   FIB0 = 1 means wav0 contains light from fiber 2.
;   wav1 contains light from fiber 1 in any case.
;
; corr contains the cross-correlation between the target spectrum and the
; chosen ZERO file, and related date, both for the order containing Mgb lines.
; (all float32).
;  .ccm(2,nlag) = cross-correlation vs fiber, lag index.
;  .lagvel(2,nlag) = lag value (km/s) vs lag index.
; For both ccm and lagvel, fiber index 0 corresponds to the fiber that carries
; light from this file's target.  Fiber index 1 corresponds to the other fiber.
; Thus, if keyword FIB0 = 0, then ccm(0,*) comes from fiber 0, and 
;                                 ccm(1,*) comes from fiber 2.;
;       if keyword FIB0 = 1, then ccm(0,*) comes from fiber 2, and 
;                                 ccm(1,*) comes from fiber 0.
;
; blks contains the block-fitting parameters, and related diagnostics. (all
; float32).  For these arrays, the meaning of the first (fiber) index is
; the same as for the corr arrays described above.
;  .redshft(2,nord,nblk) = redshift correction relative to the cross-correlation
;      redshift, per fiber, order and block
;  .errrshft(2,nord,nblk) = formal error of redshift estimate
;  .scale(2,nord,nblk) = estimated scale parameter
;  .serrscale(2,nord,nblk) = formal error of scale parameter
;  .lx1coef(2,nord,nblk) = estimated amplitude of L1 scaling term
;  .errlx1(2,nord,nblk) = formal error of lx1coef
;  .pldp(2,nord,nblk) = photon-limited doppler precision per fiber, order, block
   
; metric contains scalar metrics that may be of use in constructing diagnostic
; time series.  Almost all of these are harvested from the header keywords.
;        Time-related quantities
;   .mjd = MJE of shutter open (d)
;   .exptime = spectrum exposure time (s)
;   .fwctime = flux-weighted center time of exposure
;        Spectrograph configuration quantities
;   .fib0 = 1st illuminated fiber
;   .nfib = number of illuminated fibers
;   .cstag_mm =  collimator stage position (mm)
;   .cstag_et =  collimator stage encoder tics
;   .cstag_pp =  collimator stage ??
;   .fstag_mm = fiber stage position (mm)
;   .fstag_et = fiber stage encoder tics
;   .fstag_pp = fiber stage ??
;        Wavelength-related quantities
;   .clam_blu = center wavelength of blue order (nm) (float64)
;   .clam_mgb = center wavelength of Mgb order (nm) (float64)
;   .clam_red = center wavelength of red order (nm) (float64)
;   .lamran_blue=wavelength range of blue order (nm) (float64)
;   .lamran_mgb=wavelength range of mgb order (nm) (float64)
;   .lamran_red=wavelength range of red order (nm) (float64)
;   .sinalp = wavelength solution sin(alpha) parameter
;   .fl = wavelength solution focal length parameter
;   .y0 = wavelength solution y0 parameter
;   .z0 = wavelength solution z0 parameter
;   .coefs[ncoefs] = wavelength solution polynomial coeffs
;   .fibcoe[nfcoefs] = TRIPLE polynomial coefficients
;         Temperature and Pressure data
;   .wmstemp = outside ambient temperature (C)
;   .iglatemp = igloo temperature outside tent (C)
;   .nrespres = instrument pressure (psi)
;         Names of Calibration files
;   .l1idbias = Bias file
;   .l1iddark = Dark file
;   .l1idflat = Flat file
;   .l1idtrac = Trace file
;   .l1idtrip = TRIPLE file
;   .l1idzero = ZERO file
;   .tharlist = file with list of catalog ThAr lines;
;         Spectrum Image quantities
;   .nelectr0 = total detected electrons in target fiber
;   .nelectr1 = total detected electrons in referance fiber

; open the input file, get the 0th extension header and read the first one
fits_read,filin,dd0,hdr0,exten=0
fits_read,filin,dd1,hdr1,exten=1

; get necessary header quantities
mjd=sxpar(hdr1,'MJD')
exptime=sxpar(hdr1,'EXPTIME')
fib0=sxpar(hdr1,'FIB0')
nfib=sxpar(hdr1,'NFIB')
nx=sxpar(hdr1,'NAXIS1')
nord=sxpar(hdr1,'NAXIS2')
cstag_mm=sxpar(hdr1,'CSTAG_MM')
cstag_et=sxpar(hdr1,'CSTAG_ET')
cstag_pp=sxpar(hdr1,'CSTAG_PP')
fstag_mm=sxpar(hdr1,'FSTAG_MM')
fstag_et=sxpar(hdr1,'FSTAG_ET')
fstag_pp=sxpar(hdr1,'FSTAG_PP')
wmstemp=sxpar(hdr1,'WMSTEMP')
iglatemp=sxpar(hdr1,'IGLATEMP')
nrespres=sxpar(hdr1,'NRESPRES')
nelectr0=sxpar(hdr1,'NELECTR0')
nelectr1=sxpar(hdr1,'NELECTR1')

; unpack the array data
extr=dd1(*,*,0)
blaz=dd1(*,*,1)
spec=dd1(*,*,2)
thar_i=dd1(*,*,3)
thar_f=dd1(*,*,4)

; read 2nd extension
fits_read,filin,dd2,hdr2,exten=2

; get header quantities
sinalp=sxpar(hdr2,'SINALP')
fl=sxpar(hdr2,'FL')
y0=sxpar(hdr2,'Y0')
z0=sxpar(hdr2,'Z0')

; unpack the array data
if(fib0 eq 0) then wav0=dd2(*,*,0) else wav0=dd2(*,*,2)
wav1=dd2(*,*,1)
if(fib0 eq 0) then wav2=dd2(*,*,2) else wav2=dd2(*,*,0)

; make diagnostice derived from wavelength data
clam_blu=wav1(nx/2,65)
clam_mgb=wav1(nx/2,38)
clam_red=wav1(nx/2,5)
lamran_blu=wav1(3000,65)-wav1(1000,65)
lamran_mgb=wav1(3500,nord-2)-wav1(500,nord-2)
lamran_red=wav1(4000,5)-wav1(100,5)

; read 3rd extension
fits_read,filin,dd3,hdr3,exten=3

; unpack the array data
cc_fn=dd3(*,*,0)
lag_vel=dd3(*,*,1)

; read the 4th extension
fits_read,filin,dd4,hdr4,exten=4

; get useful header values
nblock=sxpar(hdr4,'NAXIS3')

; unpack the array data
redshft=dd4(*,*,*,0)
errrshft=dd4(*,*,*,1)
scale=dd4(*,*,*,2)
errscale=dd4(*,*,*,3)
lx1coef=dd4(*,*,*,4)
errlx1=dd4(*,*,*,5)
pldp=dd4(*,*,*,6)

; make the output structures
hdrj=[hdr1,hdr2,hdr3,hdr4]
so=sort(hdrj)
hdrjs=hdrj(so)
hun=uniq(hdrjs)
hdrjoint=hdrjs(hun)
; remove ambiguous header keywords
sxdelpar,hdrjoint,'NAXIS'
sxdelpar,hdrjoint,'NAXIS1'
sxdelpar,hdrjoint,'NAXIS2'
sxdelpar,hdrjoint,'NAXIS3'
sxdelpar,hdrjoint,'BITPIX'
sxdelpar,hdrjoint,'BZERO'
sxdelpar,hdrjoint,'BSCALE'
sxdelpar,hdrjoint,'SIMPLE'
sxdelpar,hdrjoint,'END'
sxdelpar,hdrjoint,'XTENSION'

head={hdr0:hdr0,hdr1:hdr1,hdr2:hdr2,hdr3:hdr3,hdr4:hdr4,hdrjoint:hdrjoint}
spec={hdrspec:hdr1,extr:extr,blaz:blaz,spec:spec,thar_i:thar_i,thar_f:thar_f}
wav={hdrwav:hdr2,wav0:wav0,wav1:wav1,wav2:wav2}
corr={hdrcorr:hdr3,cc_fn:cc_fn,lag_vel:lag_vel}
blks={hdrblks:hdr4,redshft:redshft,errrshft:errrshft,scale:scale,$
      errscale:errscale,lx1coef:lx1coef,pldp:pldp,nblock:nblock}
metric={mjd:mjd,exptime:exptime,fib0:fib0,nfib:nfib,$
      cstag_mm:cstag_mm,cstag_et:cstag_et,cstag_pp:cstag_pp,$
      fstag_mm:fstag_mm,fstag_et:fstag_et,fstag_pp:fstag_pp,$
      clam_blu:clam_blu,clam_mgb:clam_mgb,clam_red:clam_red,$
      lamran_blu:lamran_blu,lamran_mgb:lamran_mgb,lamran_red:lamran_red,$
      sinalp:sinalp,fl:fl,y0:y0,z0:z0,$ ;coefs:coefs,fib_coe:fib_coe,$
      wmstemp:wmstemp,iglatemp:iglatemp,nrespres:nrespres,$
      l1idbias:l1idbias,l1iddark:l1iddark,l1idflat:l1idflat,l1idtrac:l1idtrac,$
      l1idtrip:l1idtrip,l1idzero:l1idzero,tharlist:tharlist,$
      nelectr0:nelectr0,nelectr1:nelectr1}

end
       
