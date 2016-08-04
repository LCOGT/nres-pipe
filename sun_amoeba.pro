function sun_amoeba,parmsin
; this function accepts a 4-element vector parmsin:
; (0) a0 = perturbation to angle of incidence (radian)
; (1) f0 = perturbation to camera focal length (mm)
; (2) g0 = perturbation to y-coord at which gamma=0 (mm)
; (3) z0 = perturbation to redshift z (or refractive index of medium)
; Also contained in a common data area thar_am are the following:
; Nominal parameters describing the spectrograph, including
; mm(nord) = diffraction order vs order index
; d = grating groove spacing in lines/mm
; sinalp = sin(nominal incidence angle)
; fl = nominal camera focal length (mm)
; gltype = string identifying cross-dispersing prism glass type
; priswedge = prism apex angle (degree)
; lamcen = nominal wavelength for order on center of detector (micron)
; iord_c(nl), xpos_c(nl), linelam_c(nl) =
; The order index, x-position, and vacuum(?) wavelength of each of the 
; nl solar spectrum lines identified in the observed spectrum.
;
; The function uses the perturbation input parameters 
; to compute the model wavelength lam of each pixel in the spectrum.
; For each line in the input line list, it computes
; a model wavelength from the x-coord by interpolation into the lam array.
; It then computes the mean squared wavelength error of the
; line list.  The mean squared wavelength error 
; dlam2 is returned by the function, and lam,
; and the y-coords y0m of the order centers are returned in the
; common area.
; Also in common are vectors containing various quantities 
; related to the modeled lines:
;  matchlam = model wavelength of the line
;  matchdif = difference between model line lambda and linelist lambda (nm)
;

; common block
common sun_am, mm_c,d_c,sinalp_c,fl_c,y0_c,z0_c,gltype_c,priswedge_c,lamcen_c,$
       r0_c,pixsiz_c,nx_c,nord_c,nl_c,linelam_c,$
       dsinalp_c,dfl_c,dy0_c,dz0_c,dlam2_c,$
       nblock_c,nfib_c,npoly_c,ordwid_c,medboxsz_c,$
       matchlam_c,matcherr_c,matchdif_c,matchord_c,matchxpos_c,$
       matchwts_c,matchbest_c,nmatch_c,$
       lam_c,y0m_c,coefs_c,ncoefs_c,$
       site_c,fibindx_c,fileorg_c,ierr_c

; constants
thrshlam=0.02               ; threshold (nm) for accepting a lambda match
radian=180.d0/!pi

; set up calling parameters for current SG
a0=parmsin(0)
f0=parmsin(1)
g0=parmsin(2)
z1=parmsin(3)
wavelen=dblarr(nx_c,nord_c)
sinalp=sin(asin(sinalp_c+a0))
fl=fl_c+f0
y0=y0_c+g0
z0=z0_c+z1
xx=pixsiz_c*(findgen(nx_c)-float(nx_c)/2.)      ; x-coord in mm
lambdaofx,xx,mm_c,d_c,gltype_c,priswedge_c,lamcen_c,r0_c,sinalp,fl,$
          y0,z0,lam_c,y0m_c,/air

; make dlambda/dx, for later use
dlamdx=fltarr(nx_c,nord_c)
for i=0,nord_c-1 do begin
  dlamdx(*,i)=deriv(lam_c(*,i))
endfor

; compute model wavelengths of input lines, from their x-positions
; make list of unique iord values
matchlam_c=dblarr(nl_c)
matchdif_c=dblarr(nl_c)
for i=0,nl_c-1 do begin
  iix=long(matchxpos_c(i))
  isx=matchxpos_c(i)-double(iix)
  matchlam_c(i)=lam_c(iix,matchord_c(i))+isx*dlamdx(iix,matchord_c(i))
  matchdif_c(i)=linelam_c(i)/10.-matchlam_c(i)   ; convert linelam_c to nm
endfor

; compute number of matched lines, mean squared error, in nm.
dlam2_c=total(matchdif_c^2)/nl_c          
print,'rms=',sqrt(dlam2_c),' nm   nline=',nl_c

;stop

return,dlam2_c

end
