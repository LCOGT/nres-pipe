pro lambdaofx,xx,mm,d,gltype,priswedge,lamcen,r0,sinalp,fl,y0,z0,lam,y0m,$
     air=air,rcubic=rcubic
; This routine computes wavelength lam(nm) as a function of x-coordinate xx
; and order number mm, for a cross-dispersed echelle.
; On input,
;  xx(nx) = x-coordinate vector, measured from CCD center, in mm
;  mm(nord) = vector containing order numbers for which lam is to be calculated
;  d = grating groove spacing (microns)
;  gltype = prism glass type
;  priswedge = prism vertex angle (degrees)
;  lamcen = nominal wavelength (micron) for which prism out-and-back 
;           deviation is zero
;  r0 = rotation angle of CCD (radian) relative to main dispersion along x
;  sinalp = sin of incidence angle on grating
;  fl = focal length of the spectrograph camera (mm)
;  y0 = y-coordinate on CCD (mm) at which gamma angle = 0.
;  z0 = refractive index of ambient medium surrounding SG is 1.+z0.
;       If keyword air is set, material is assumed to be dry air with
;       n(Na D) = 1.+z0
;  If keyword rcubic is set, its value must be a vector of float or double
;  coefficients in a restricted cubic polynomial that accounts for non-ideal
;  behavior in the wavelength solution.  The number of elements must be
;  10 or 15.  Any or all elements may be zero;  if all are zero, the
;  polynomial correction is skipped.
;
; On return,
;  lam(nx,nord) = computed wavelength vs x,order (nm)
;  y0m(nord) = y(order index) (units = mm) at the center of each order.
;
; Method is to combine the diffraction equation with geometrical relations
; for image scale and rotation.

; constants
!except=2
radian=180d0/!dpi

; get sizes of things
nx=n_elements(xx)
nord=n_elements(mm)

; make output arrays, some working arrays
y0m=dblarr(nord)       ; y(mm), ordered the same as mm
xo=dblarr(nx,nord)     ; x-coordinate in SG natural coords, before det rotation
lam=dblarr(nx,nord)
dlamda0=dblarr(nx,nord)
dlamdfl=dblarr(nx,nord)
dlamdy0=dblarr(nx,nord)
dlamdr0=dblarr(nx,nord)
mmo=rebin(reform(mm,1,nord),nx,nord)

; fill y0m
; compute prism half-deflection angle for center wavelength
glass_index,gltype,[lamcen],nn
nnmid=nn[0]
delta=asin(nnmid*sin(priswedge/(2d0*radian))) - priswedge/(2d0*radian)
; compute central wavelengths for each order
lamc=d*2.*(sinalp)/mm    ; central wavelength for each order (microns)

; get refractive indices, center y-coordinates for each order
glass_index,gltype,lamc,nnc
y0m=4d0*fl*delta*(nnc-nnmid)    ; 2 passes through full deflection angle

; compute gamma angle, sines and cosines of same
gammar=asin((y0m-y0)/fl)
cosgam=cos(gammar)
singam=sin(gammar)
cosgamo=rebin(reform(cosgam,1,nord),nx,nord)
singamo=rebin(reform(singam,1,nord),nx,nord)

; compute unrotated x coordinates
for i=0,nord-1 do xo[*,i]=xx+y0m[i]*sin(r0)

; compute sin(beta)
;sinbet=xo/fl + sinalp + a0
alp=asin(sinalp)
bet=(-alp)-atan(xo/fl)
sinbet=sin(bet)
sinalpo=sin(alp)

; compute lambda (microns)
lam=(d/mmo)*(sinalpo-sinbet)*cosgamo

; correct lambda for ambient refractive index
if(keyword_set(air)) then begin
  lam=airlam(lam,z0)
endif else begin
  lam=lam*(1.+z0)
endelse

; convert lam to nm
lam=lam*1.d3

; add restricted cubic correction if keyword rcubic is set
print,'In lambdaofx'
if(keyword_set(rcubic)) then begin
  ncoef=n_elements(rcubic)
  print,'rcubic(0:1)=',rcubic(0:1)
  if((ncoef ne 10) and (ncoef ne 15)) then begin
    print,'ncoef must be 10 or 15 in lambdaofx.  Skipping polynom correc.'
    goto,skip
  endif
  s=where(rcubic ne 0.,ns)
  if(ns eq 0) then goto,skip

; make vectors for x and order
  jx=findgen(nx)-nx/2.
  jx=rebin(jx,nx,nord)
  jord=findgen(nord)-nord/2.
  jord=rebin(reform(jord,1,nord),nx,nord)
; make polynomial functions
  funs=fltarr(nx,nord,ncoef)
  funs(*,*,0)=1.
  funs(*,*,1)=jord
  funs(*,*,2)=jord^2
  funs(*,*,3)=jord^3
  funs(*,*,4)=jx
  funs(*,*,5)=jx*jord
  funs(*,*,6)=jx*jord^2
  funs(*,*,7)=jx^2
  funs(*,*,8)=jx^2*jord
  funs(*,*,9)=jx^3
  if(ncoef eq 15) then begin
    funs(*,*,10)=jord^4
    funs(*,*,11)=jx*jord^3
    funs(*,*,12)=jx^2*jord^2
    funs(*,*,13)=jx^3*jord
    funs(*,*,14)=jx^4
  endif

; add polynomials to lam
  plam=fltarr(nx,nord)
  for i=0,ncoef-1 do begin
    plam=plam+rcubic(i)*funs(*,*,i)
  endfor
  lam=lam+plam

endif

skip:
end
