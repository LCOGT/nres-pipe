pro dlamdparm,site0,lam,dlamdparms,dlamdcoefs
; This routine accepts a site name site0 (to allow reading spectrograph physical
; data). 
; It then computes lam(nx,nord), 
; dlam/dparms(nx,nord,4) giving wavelength derivs wrt the parms4 parameters,
; and dlam/dcoefs(nx,nord,15) giving wavelength derivs wrt the 15 coefs values.

@nres_comm

radian=180.d0/!pi

; get spectrograph data from spectrographs.csv  Use today's MJD
site=strupcase(strtrim(site0,2))
mjdc=systime(/julian)-2400000.5d0

get_specdat,mjdc,err

nx=specdat.nx
nord=specdat.nord
pixsiz=specdat.pixsiz
xx=pixsiz*(dindgen(nx)-nx/2.)
mm=specdat.ord0+findgen(nord)
ncoefs=specdat.ncoefs

lambda3ofx,xx,mm,1,specdat,lam,y0m

sinalp0=specdat.sinalp
dsinalp=1.e-5
fl0=specdat.fl
dfl=0.1
y00=specdat.y0
dy0=0.01
z00=specdat.z0
dz0=1.e-5

; make output arrays
dlamdparms=dblarr(nx,nord,4)
dlamdcoefs=dblarr(nx,nord,ncoefs)

; make wavelength functions with perturbed inputs
specdat1=specdat
sinalp1=sinalp0+dsinalp
grinc1=radian*asin(sinalp1)
specdat1.grinc=grinc1
specdat1.sinalp=sinalp1
lambda3ofx,xx,mm,1,specdat1,lam1,y0m1

specdat1=specdat
specdat1.fl=fl0+dfl
lambda3ofx,xx,mm,1,specdat1,lam2,y0m2

specdat1=specdat
specdat1.y0=y00+dy0
lambda3ofx,xx,mm,1,specdat1,lam3,y0m3

specdat1=specdat
specdat1.z0=z00+dz0
lambda3ofx,xx,mm,1,specdat1,lam4,y0m4

; make derivatives wrt sinalp,fl,y0,z0
dlamdparms(*,*,0)=(lam1-lam)/dsinalp
dlamdparms(*,*,1)=(lam2-lam)/dfl
dlamdparms(*,*,2)=(lam3-lam)/dy0
dlamdparms(*,*,3)=(lam4-lam)/dz0

; make functions that go into rcubic polynomial, hence dlam/dcoef(i)
jx=findgen(nx)-nx/2.
jx=rebin(jx,nx,nord)
jord=findgen(nord)-nord/2.
jord=rebin(reform(jord,1,nord),nx,nord)

dlamdcoefs(*,*,0)=1.
dlamdcoefs(*,*,1)=jord
dlamdcoefs(*,*,2)=jord^2
dlamdcoefs(*,*,3)=jord^3
dlamdcoefs(*,*,4)=jx
dlamdcoefs(*,*,5)=jx*jord
dlamdcoefs(*,*,6)=jx*jord^2
dlamdcoefs(*,*,7)=jx^2
dlamdcoefs(*,*,8)=jx^2*jord
dlamdcoefs(*,*,9)=jx^3
if(ncoefs eq 15) then begin
  dlamdcoefs(*,*,10)=jord^4
  dlamdcoefs(*,*,11)=jx*jord^3
  dlamdcoefs(*,*,12)=jx^2*jord^2
  dlamdcoefs(*,*,13)=jx^3*jord
  dlamdcoefs(*,*,14)=jx^4
endif

end
