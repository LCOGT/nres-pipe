pro trip_unpack,tripdat,triphdr,trp=trp
; This routine accepts the data and header segments from a TRIPLE fits file,
; and loads the wavelength scale (appropriate to fiber 1) into common
; data array lam_t, and reformatted header values into common spectrograph
; parameters sinalp_t, fl_t, y0_t, z0_t, coefs_c, and fibcoefs_c.
;
; Note that a wavelength solution consists of 2 parts:
; (1) the physical parameters {sinalp, fl, y0, z0} combined with x-pixel and
; order-dependent coefficients coefs (these apply only to fiber 1), and
; (2) the fiber-dependent displacements described by fibcoefs (these come
; into play only for fibers 0 or 2).
;
; The current values for all of these variables are stored in nres_comm
; structure specdat, with copies residing in thar_comm variables sinalp_c,
; coefs_c, fibcoefs_c, etc.  The current wavelength scale lam_c is computed
; from the thar_comm versions of the variables.
;
; On startup of the thar routines, values for variables in (1) and (2) above
; are obtained from the spectrographs.csv file.  These are intended as starting
; guesses for the wavelength solution.  When a TRIPLE file is read, the data
; found therein may supersede the starting values for parts (1) or (2) or both,
; depending on the value of keyword trp:
;  (a) trp = 0 (or not set): Retain spectrograph.csv values for both 
;    parts (1) and (2), leave lam_c unchanged.  
;  (b) trp = 1: Use TRIPLE file values for part (1) data, use spectrographs.csv
;    for part (2) data.  Recalculate lam_c before proceeding.
;  (c) trp = 2: Use TRIPLE file values for part (2) data, use spectrographs.csv
;    for part (1) data.  Leave lam_c unchanged, since part(2) does not affect
;    wavelengths for fiber 1.
;  (d) trp = 3: Use TRIPLE file values for both parts (1) and (2).  Recalculate
;    lam_c before proceeding.

@thar_comm

@nres_comm

radian=180.d0/!pi

if(keyword_set(trp)) then begin
  if(trp eq 0) then updat1=0 & updat2=0
  if(trp eq 1) then updat1=1 & updat2=0
  if(trp eq 2) then updat1=0 & updat2=1
  if(trp eq 3) then updat1=1 & updat2=1
endif else begin
  updat1=0
  updat2=0
endelse

lam_t=tripdat                   ; store TRIPLE lam soln here, regardless

if(updat1) then begin
  sinalp_c=sxpar(triphdr,'SINALP')
  grinc=radian*asin(sinalp_c)
  fl_t=sxpar(triphdr,'FL')
  fl_c=fl_t
  y0_t=sxpar(triphdr,'Y0')
  y0_c=y0_t
  z0_t=sxpar(triphdr,'Z0')
  z0_c=z0_t
  ncoefs=sxpar(triphdr,'NCOEFS')
  ncoefs_c=ncoefs
 
; coefs_c array
  coefs_c=fltarr(ncoefs)
  coefs_c(0)=sxpar(triphdr,'COEFS00')
  coefs_c(1)=sxpar(triphdr,'COEFS01')
  coefs_c(2)=sxpar(triphdr,'COEFS02')
  coefs_c(3)=sxpar(triphdr,'COEFS03')
  coefs_c(4)=sxpar(triphdr,'COEFS04')
  coefs_c(5)=sxpar(triphdr,'COEFS05')
  coefs_c(6)=sxpar(triphdr,'COEFS06')
  coefs_c(7)=sxpar(triphdr,'COEFS07')
  coefs_c(8)=sxpar(triphdr,'COEFS08')
  coefs_c(9)=sxpar(triphdr,'COEFS09')
  coefs_c(10)=sxpar(triphdr,'COEFS10')
  coefs_c(11)=sxpar(triphdr,'COEFS11')
  coefs_c(12)=sxpar(triphdr,'COEFS12')
  coefs_c(13)=sxpar(triphdr,'COEFS13')
  coefs_c(14)=sxpar(triphdr,'COEFS14')

; make specdat, thar_comm values consistent
  specdat.grinc=grinc
  specdat.fl=fl_c
  specdat.y0=y0_c
  specdat.z0=z0_c
  specdat.ncoefs=ncoefs_c
  specdat.coefs=coefs_c

; remake the wavelength array
  xx=pixsiz_c*(findgen(nx_c)-float(nx_c/2.))
  mm=mm_c
  fibno=1    
  lambda3ofx,xx,mm,fibno,specdat,lam_c,y0m_c   ; vacuum wavelengths

endif

; fibcoefs_c array
if(updat2) then begin
  fibcoefs_c=fltarr(10,2)
  fibcoefs_c(0,0)=sxpar(triphdr,'FIBCOE00')
  fibcoefs_c(1,0)=sxpar(triphdr,'FIBCOE10')
  fibcoefs_c(2,0)=sxpar(triphdr,'FIBCOE20')
  fibcoefs_c(3,0)=sxpar(triphdr,'FIBCOE30')
  fibcoefs_c(4,0)=sxpar(triphdr,'FIBCOE40')
  fibcoefs_c(5,0)=sxpar(triphdr,'FIBCOE50')
  fibcoefs_c(6,0)=sxpar(triphdr,'FIBCOE60')
  fibcoefs_c(7,0)=sxpar(triphdr,'FIBCOE70')
  fibcoefs_c(8,0)=sxpar(triphdr,'FIBCOE80')
  fibcoefs_c(9,0)=sxpar(triphdr,'FIBCOE90')
  fibcoefs_c(0,1)=sxpar(triphdr,'FIBCOE01')
  fibcoefs_c(1,1)=sxpar(triphdr,'FIBCOE11')
  fibcoefs_c(2,1)=sxpar(triphdr,'FIBCOE21')
  fibcoefs_c(3,1)=sxpar(triphdr,'FIBCOE31')
  fibcoefs_c(4,1)=sxpar(triphdr,'FIBCOE41')
  fibcoefs_c(5,1)=sxpar(triphdr,'FIBCOE51')
  fibcoefs_c(6,1)=sxpar(triphdr,'FIBCOE61')
  fibcoefs_c(7,1)=sxpar(triphdr,'FIBCOE71')
  fibcoefs_c(8,1)=sxpar(triphdr,'FIBCOE81')
  fibcoefs_c(9,1)=sxpar(triphdr,'FIBCOE91')

  specdat.fibcoefs=fibcoefs_c

endif

end
