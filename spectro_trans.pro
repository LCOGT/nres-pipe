pro spectro_trans,site0,mjd
; This routine reads the appropriate (given site0, mjd) spectrograph parameters 
; line from spectrographs.csv, and uses the coefs data to construct the
; correction function vs pixel and order number.  It then fits this function
; with a similar function constructed from Legendre polynomials, and writes
; a new line into the csv file, identical to the first except that the
; coefs(15) array is replaced with the new Legendre coefficients, and also
; that the MJD of the new line is equal to the old one plus 0.001 d.
; Note that this routine uses IDL's Legendre normalization convention
; (values at +/- 1.0 equal +/- 1.0), with the result that the functions
; are orthogonal on [-1,1], but not orthonormal (by factors of up to about 2).

@nres_comm

site=site0
get_specdat,mjd,err

; make coordinate arrays we will need
nx=specdat.nx
nord=specdat.nord
jx=findgen(nx)-nx/2.
jx=rebin(jx,nx,nord)
jord=reform(findgen(nord),1,nord)-nord/2.
jord=rebin(jord,nx,nord)
lx=2.*jx/nx
lord=2.*jord/nord

cfun=fltarr(nx,nord)
coefs=specdat.coefs
cfun=cfun+coefs(0) + coefs(1)*jord + coefs(2)*jord^2 + coefs(3)*jord^3 + $
     coefs(4)*jx + coefs(5)*jx*jord + coefs(6)*jx*jord^2 + $
     coefs(7)*jx^2 + coefs(8)*jx^2*jord + $
     coefs(9)*jx^3 + coefs(10)*jord^4 + coefs(11)*jx*jord^3 + $
     coefs(12)*jx^2*jord^2 + coefs(13)*jx^3*jord + coefs(14)*jx^4

;stop

; make functions for legendre poly fit
lx0=legendre(lx,0)
lx1=legendre(lx,1)
lx2=legendre(lx,2)
lx3=legendre(lx,3)
lx4=legendre(lx,4)
lo0=legendre(lord,0)
lo1=legendre(lord,1)
lo2=legendre(lord,2)
lo3=legendre(lord,3)
lo4=legendre(lord,4)

ntot=long(nx)*long(nord)
funs=fltarr(ntot,15)
funs(*,0)=reform(lo0,ntot)
funs(*,1)=reform(lo1,ntot)
funs(*,2)=reform(lo2,ntot)
funs(*,3)=reform(lo3,ntot)
funs(*,4)=reform(lx1,ntot)
funs(*,5)=reform(lx1*lo1,ntot)
funs(*,6)=reform(lx1*lo2,ntot)
funs(*,7)=reform(lx2,ntot)
funs(*,8)=reform(lx2*lo1,ntot)
funs(*,9)=reform(lx3,ntot)
funs(*,10)=reform(lo4,ntot)
funs(*,11)=reform(lx1*lo3,ntot)
funs(*,12)=reform(lx2*lo2,ntot)
funs(*,13)=reform(lx3*lo1,ntot)
funs(*,14)=reform(lx4,ntot)

; Do the least-squares fit
wt=fltarr(ntot)+1.
rcfun=reform(cfun,ntot)
cc=lstsqr(rcfun,funs,wt,15,rms,chisq,outp,1,cov)

stop

end
