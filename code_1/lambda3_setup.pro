pro lambda3_setup,xx,mm,specstruc,pref,ncx,nco,coefx,coefo,residx,resido,y0m
; This routine computes the prefactor pref and polynomial coefficients
; coefx(ncx), coefo(nco) which approximate the grating equation
; lambda(x,iord) = pref*(1/m)*(sum(coefx*T_n(x))*(sum(coefo*T_n(iord))))
; for fiber fibno={0, 1, or 2}
; for a cross-dispersed echelle.
; On input,
;  xx(nx) = x-coordinate vector, measured from CCD center, in mm
;  mm(nord) = vector containing order numbers for which lam is to be calculated
;  ncx = number of coefficients in x-polynomial, with ncx <= 7
;  nco = number of coefficients in order-polynomial, with nco <= 7
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
;
; On return,
; pref = prefactor  = 2*sin(alpha)*d
;  f1 = coefs of polynomial approx to (1.+sin(beta)/sin(alpha))/2.
;  f2 = coefs of polynomial approx to cos(gamma) 
;  y0m(nord) = y(order index) (units = mm) at the center of each order.
;
; Method is to use xx and specstruc to compute the angles beta and gamma
; in the physical grating equation, and from these to compute 
; (1.+sin(beta)/sin(alpha))/2  and   cos(gamma)
; These two functions are then expanded in Chebyshev polynomials with
; coefficients coefx and coefo.
; The wavelengths calculated using these outputs correspond to fiber0 and
; to vacuum. These parameters are required as inputs to routine lambda3pofx.

compile_opt hidden

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
;z0=specstruc.z0
;rcubic=specstruc.coefs(0:specstruc.ncoefs-1)
;fibcoefs=specstruc.fibcoefs

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
;for i=0,nord-1 do xo[*,i]=xxe+y0m[i]*sin(r0)

; compute sin(beta)
;sinbet=xo/fl + sinalp + a0
alp=asin(sinalp)
bet=(-alp)-atan(xxe/fl)
sinbet=sin(bet)
sinalpo=sin(alp)

;; compute lambda (microns)
; compute pref and the two functions of interest
pref=2.d0*d*sinalpo           ; units are micron
;lam=(d/mmo)*(sinalpo-sinbet)*cosgamo
xx1=xx
f1=(1.d0-sinbet/sinalpo)/2. - 1.d0
xx2=dindgen(nord)
f2=cosgam - 1.d0

stop

; extract desired f1 array from extended one, compute polynomial coeffs
f1s=f1(dn:nx+dn-1)
coefx=orthogfit(xx1,f1s,ncx,'chebyshev',residx)
coefo=orthogfit(xx2,f2,nco,'chebyshev',resido)

stop

;lam=lam(dn:nx+dn-1,*)

end
