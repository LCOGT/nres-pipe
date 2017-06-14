pro lambda3ofx,xx,mm,fibno,specstruc,lam,y0m,$
     air=air
; This routine computes wavelength lam(nm) as a function of x-coordinate xx
; and order number mm, for fiber fibno={0, 1, or 2}
; for a cross-dispersed echelle.
; On input,
;  xx(nx) = x-coordinate vector, measured from CCD center, in mm
;  mm(nord) = vector containing order numbers for which lam is to be calculated
;  fibno = 0, 1, or 2 depending on desired fiber number.  1 (center) is
;    the calibration fiber, 0 and 2 are star fibers.
;  spectstruc = structure containing spectrograph descriptive info, as follows
;  .d = grating groove spacing (microns)
;  .gltype = prism glass type
;  .apex = prism vertex angle (degrees)
;  .lamcen = nominal wavelength (micron) for which prism out-and-back 
;           deviation is zero
;  .rot = rotation angle of CCD (degree) relative to main dispersion along x
;  .sinalp = sin of incidence angle on grating
;  .fl = focal length of the spectrograph camera (mm)
;  .y0 = y-coordinate on CCD (mm) at which gamma angle = 0.
;  .z0 = refractive index of ambient medium surrounding SG is 1.+z0.
;       If keyword air is set, material is assumed to be dry air with
;       n(Na D) = 1.+z0
;  .coefs =  a vector of float or double
;  coefficients in a restricted cubic polynomial that accounts for non-ideal
;  behavior in the wavelength solution.  The number of elements must be
;  10 or 15.  Any or all elements may be zero;  if all are zero, the
;  polynomial correction is skipped.
;  .fibcoefs(2,7) = floating coeffs giving shift in pixel units between
;    fiber1 and fiber0 = fibcoefs(*,0)
;    fiber1 and fiber2 = fibcoefs(*,1)
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
dn=20                 ; extend x-coord by this much at each end to allow
                      ; interpolation for fibers 0 and 2

; unpack specstruc
d=specstruc.grspc
gltype=specstruc.gltype
apex=specstruc.apex
lamcen=specstruc.lamcen
r0=specstruc.rot/radian
sinalp=specstruc.sinalp
fl=specstruc.fl
y0=specstruc.y0
z0=specstruc.z0
rcubic=specstruc.coefs(0:specstruc.ncoefs-1)
fibcoefs=specstruc.fibcoefs

;print,'lambda3ofx parms:',sinalp,fl,y0,z0

; get sizes of things
nx=n_elements(xx)
nord=n_elements(mm)
nxe=nx+2*dn            ; size of extended (in x) data arrays

; make an extended xx array.  Assume it is increasing left to right
dx=(max(xx)-min(xx))/(nx-1)
xxe=dblarr(nxe)
xxe(0:dn-1)=min(xx)-rotate(dx*(1.d0+dindgen(dn)),2)
xxe(dn:nx+dn-1)=xx
xxe(nx+dn:nx+2*dn-1)=max(xx)+dx*(1.d0+dindgen(dn))

; make output arrays, some working arrays
y0m=dblarr(nord)       ; y(mm), ordered the same as mm
xo=dblarr(nxe,nord)     ; x-coordinate in SG natural coords, before det rotation
lam=dblarr(nxe,nord)
dlamda0=dblarr(nxe,nord)
dlamdfl=dblarr(nxe,nord)
dlamdy0=dblarr(nxe,nord)
dlamdr0=dblarr(nxe,nord)
mmo=rebin(reform(mm,1,nord),nxe,nord)

; fill y0m
; compute prism half-deflection angle for center wavelength
glass_index,gltype,[lamcen],nn
nnmid=nn[0]
delta=asin(nnmid*sin(apex/(2d0*radian))) - apex/(2d0*radian)
; compute central wavelengths for each order
lamc=d*2.*(sinalp)/mm    ; central wavelength for each order (microns)

; get refractive indices, center y-coordinates for each order
glass_index,gltype,lamc,nnc
y0m=4d0*fl*delta*(nnc-nnmid)    ; 2 passes through full deflection angle

; compute gamma angle, sines and cosines of same
gammar=asin((y0m-y0)/fl)
cosgam=cos(gammar)
singam=sin(gammar)
cosgamo=rebin(reform(cosgam,1,nord),nxe,nord)
singamo=rebin(reform(singam,1,nord),nxe,nord)

; compute unrotated x coordinates
for i=0,nord-1 do xo[*,i]=xxe+y0m[i]*sin(r0)

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
; lam=airlam(lam,z0)
  lam=airlam(lam,-2*z0)    ; gives vacuum lam, assuming optical path n = 1+z0
; ####### The factor of 2 in the above line is symptomatic of a big problem ####

endif else begin
; lam=lam*(1.+z0)
  lam=lam/(1.+z0)         ; gives rest frame lam, assuming source shifted by z0
endelse

; convert lam to nm
lam=lam*1.d3

; add restricted cubic correction
;print,'In lambda3ofx'
ncoef=n_elements(rcubic)

; make vectors for x and order
jx=findgen(nxe)-nxe/2.
jx=rebin(jx,nxe,nord)
jord=findgen(nord)-nord/2.
jord=rebin(reform(jord,1,nord),nxe,nord)

;print,'rcubic(0:1)=',rcubic(0:1)
if((ncoef ne 10) and (ncoef ne 15)) then begin
  print,'ncoef must be 10 or 15 in lambda3ofx.  Skipping polynom correc.'
  goto,skip
endif
s=where(rcubic ne 0.,ns)
if(ns eq 0) then goto,skip

; make polynomial functions
; try using legendre polynomials in the expansion, instead of these
;funs=fltarr(nxe,nord,ncoef)
;funs(*,*,0)=1.
;funs(*,*,1)=jord
;funs(*,*,2)=jord^2
;funs(*,*,3)=jord^3
;funs(*,*,4)=jx
;funs(*,*,5)=jx*jord
;funs(*,*,6)=jx*jord^2
;funs(*,*,7)=jx^2
;funs(*,*,8)=jx^2*jord
;funs(*,*,9)=jx^3
;if(ncoef eq 15) then begin
;  funs(*,*,10)=jord^4
;  funs(*,*,11)=jx*jord^3
;  funs(*,*,12)=jx^2*jord^2
;  funs(*,*,13)=jx^3*jord
;  funs(*,*,14)=jx^4
;endif

lx=2.*jx/nx
lord=2.*jord/nord
lx0=mylegendre(lx,0)
lx1=mylegendre(lx,1)
lx2=mylegendre(lx,2)
lx3=mylegendre(lx,3)
lx4=mylegendre(lx,4)
lo0=mylegendre(lord,0)
lo1=mylegendre(lord,1)
lo2=mylegendre(lord,2)
lo3=mylegendre(lord,3)
lo4=mylegendre(lord,4)

funs=fltarr(nxe,nord,ncoef)
funs(*,*,0)=lo0
funs(*,*,1)=lo1
funs(*,*,2)=lo2
funs(*,*,3)=lo3
funs(*,*,4)=lx1
funs(*,*,5)=lx1*lo1
funs(*,*,6)=lx1*lo2
funs(*,*,7)=lx2
funs(*,*,8)=lx2*lo1
funs(*,*,9)=lx3
funs(*,*,10)=lo4
funs(*,*,11)=lx1*lo3
funs(*,*,12)=lx2*lo2
funs(*,*,13)=lx3*lo1
funs(*,*,14)=lx4

; end of experiment with legendre polys

; add polynomials to lam
plam=fltarr(nxe,nord)
for i=0,ncoef-1 do begin
  plam=plam+rcubic(i)*funs(*,*,i)
endfor
lam=lam+plam

skip:

; if fibno ne 1, then compute x-pixel locations for given fiber,
; and interpolate into lam array to give correct shifted array
lami=lam
if(fibno eq 0 or fibno eq 2) then begin
  iic=fibno/2
  dx=fibcoefs(0,iic)+fibcoefs(1,iic)*jord+fibcoefs(2,iic)*jx+$
   fibcoefs(3,iic)*jx*jord+fibcoefs(4,iic)*jord^2+fibcoefs(5,iic)*jx*jord^2+$
   fibcoefs(6,iic)*jx^2+fibcoefs(7,iic)*jord*jx^2+fibcoefs(8,iic)*jx^3+$
   fibcoefs(9,iic)*jord^3
  dx=-dx
; dx=dx*(1.-fibno)
 for i=0,nord-1 do begin
   lami(*,i)=interpol(lam(*,i),jx(*,i),jx(*,i)+dx(*,i),/quadratic)
 endfor

endif
lam=lami

; extract desired lam array from extended one
lam=lam(dn:nx+dn-1,*)

end
