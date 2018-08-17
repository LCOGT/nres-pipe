pro dlamdparm3,site0,lam,dlamdparms,dparmnorm,dlamdcoefs,dcoefnorm,gotsp=gotsp
; This routine accepts a site name site0 (to allow reading spectrograph physical
; data). 
; It then computes lam(nx,nord), 
; dlam/dparms(nx,nord,7) giving wavelength derivs wrt the parms7 parameters,
; and dlam/dcoefs(nx,nord,ncoefs) giving wavelength derivs wrt the ncoefs
; coefs values.
; The max(abs(dlamdparms)) and max(abs(dlamdcoefs)) are returned in
; dparmnorm(7) and in dcoefnorm(ncoefs), resp.
; The computed derivative functions are then divided by the normalization
; constants, so that max(abs(dlamdparms(*,*,-)))=1.0, and
; likewise for max(abs(dlamdcoefs)).
; The normalized functions are returned in dlamdparms(nx,nord,7), and
; in dlamdcoefs(nx,nord,ncoefs), resp. 
; If keyword_set(gotsp) then do not get spectrograph parameters specially for
; this routine, rather use the ones already in thar_comm.


@nres_comm
@thar_comm

radian=180.d0/!pi

if(not keyword_set(gotsp)) then begin
; get spectrograph data from spectrographs.csv  Use today's MJD
  site=strupcase(strtrim(site0,2))
  mjdc=systime(/julian)-2400000.5d0
  get_specdat,mjdc,err
  specstruc=specdat
endif else begin
  specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
   grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
   ex0:ex0_c,ex1:ex1_c,ex2:ex2_c,$
   coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
endelse

nx=specdat.nx
nord=specdat.nord
pixsiz=specdat.pixsiz
xx=pixsiz*(dindgen(nx)-nx/2.)
mm=specdat.ord0+findgen(nord)
ncoefs=specdat.ncoefs

lambda3ofx,xx,mm,1,specstruc,lam,y0m

sinalp0=specdat.sinalp
dsinalp=1.e-5
fl0=specstruc.fl
dfl=0.1
y00=specstruc.y0
dy0=0.01
z00=specstruc.z0
dz0=1.e-5
ex0=specstruc.ex0
dex0=1.e-3
ex1=specstruc.ex1
dex1=1.e-3
ex2=specstruc.ex2
dex2=1.e-3

; make output arrays
dlamdparms=dblarr(nx,nord,7)
dlamdcoefs=dblarr(nx,nord,ncoefs)
dparmnorm=dblarr(7)
dcoefnorm=dblarr(ncoefs)

; make wavelength functions with perturbed inputs
specdat1=specstruc
sinalp1=sinalp0+dsinalp
grinc1=radian*asin(sinalp1)
specdat1.grinc=grinc1
specdat1.sinalp=sinalp1
lambda3ofx,xx,mm,1,specdat1,lam1,y0m1

specdat1=specstruc
specdat1.fl=fl0+dfl
lambda3ofx,xx,mm,1,specdat1,lam2,y0m2

specdat1=specstruc
specdat1.y0=y00+dy0
lambda3ofx,xx,mm,1,specdat1,lam3,y0m3

specdat1=specstruc
specdat1.z0=z00+dz0
lambda3ofx,xx,mm,1,specdat1,lam4,y0m4

specdat1=specstruc
specdat1.ex0=ex0+dex0
lambda3ofx,xx,mm,1,specdat1,lam5,y0m5

specdat1=specstruc
specdat1.ex1=ex1+dex1
lambda3ofx,xx,mm,1,specdat1,lam6,y0m6

specdat1=specstruc
specdat1.ex2=ex2+dex2
lambda3ofx,xx,mm,1,specdat1,lam7,y0m7

; make derivatives wrt sinalp,fl,y0,z0
dlamdparms(*,*,0)=(lam1-lam)/dsinalp
dlamdparms(*,*,1)=(lam2-lam)/dfl
dlamdparms(*,*,2)=(lam3-lam)/dy0
dlamdparms(*,*,3)=(lam4-lam)/dz0
dlamdparms(*,*,4)=(lam5-lam)/dex0
dlamdparms(*,*,5)=(lam6-lam)/dex1
dlamdparms(*,*,6)=(lam7-lam)/dex2

; normalize derivatives wrt parms so max(abs(deriv)))=1.  Save norm constants.
for i=0,6 do begin
  mxa=max(abs(dlamdparms(*,*,i)))
  dparmnorm(i)=1.
; dlamdparms(*,*,i)=dlamdparms(*,*,i)/mxa
endfor

; make functions that go into rcubic polynomial, hence dlam/dcoef(i)
jx=findgen(nx)-nx/2.
jx=rebin(jx,nx,nord)
jord=findgen(nord)-nord/2.
jord=rebin(reform(jord,1,nord),nx,nord)

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

funs=fltarr(nx,nord,ncoefs)
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

dlamdcoefs=funs

for i=0,ncoefs-1 do begin
  mxc=max(abs(dlamdcoefs(*,*,i)))
  dcoefnorm(i)=1.
; dlamdcoefs(*,*,i)=dlamdcoefs(*,*,i)/mxc
endfor

;dlamdcoefs(*,*,0)=1.
;dlamdcoefs(*,*,1)=jord
;dlamdcoefs(*,*,2)=jord^2
;dlamdcoefs(*,*,3)=jord^3
;dlamdcoefs(*,*,4)=jx
;dlamdcoefs(*,*,5)=jx*jord
;dlamdcoefs(*,*,6)=jx*jord^2
;dlamdcoefs(*,*,7)=jx^2
;dlamdcoefs(*,*,8)=jx^2*jord
;dlamdcoefs(*,*,9)=jx^3
;if(ncoefs eq 15) then begin
;  dlamdcoefs(*,*,10)=jord^4
;  dlamdcoefs(*,*,11)=jx*jord^3
;  dlamdcoefs(*,*,12)=jx^2*jord^2
;  dlamdcoefs(*,*,13)=jx^3*jord
;  dlamdcoefs(*,*,14)=jx^4
;endif

end
