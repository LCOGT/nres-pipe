pro lam_polynoms,ifib,plam,fib_poly
; This routine computes the two polynomial corrections to wavelength vs
; pixel, order that appear in lambda3ofx.pro.
; It is intended for real-time debugging.  To function correctly, 
; it must be called from within routine thar_wavelen, following line 70.
; coefficient arrays coefs_c and fibcoefs_c must have been loaded into the
; ThAr common data area.
; On input, ifib = the fiber index 0, 1, or 2 for the fiber wavelengths
; being computed.
; On output,
;  plam(nx,nord) contains the contribution to the computed wavelengths
;    from the global fit coefficients coefs_c.
;  fib_poly(nx,nord) contains the contributions from the fiber-dependent
;    wavelength solution coefficients fiboefs_c.  These correction values
;    should be zero for fibno=1.

; load common data
@nres_comm

@thar_comm

dn=20                  ; extend x arrays by this many pixels in each direction.
nx=specdat.nx
nord=specdat.nord
nxe=nx+2*dn            ; size of extended (in x) data arrays

; make vectors for x and order
jx=findgen(nx)-nx/2.
jx=rebin(jx,nx,nord)
jord=findgen(nord)-nord/2.
jord=rebin(reform(jord,1,nord),nx,nord)

; make polynomial functions
funs=fltarr(nx,nord,ncoefs_c)

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
;if(ncoefs_c eq 15) then begin
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

; add polynomials to lam
plam=fltarr(nx,nord)
for i=0,ncoefs_c-1 do begin
  plam=plam+coefs_c(i)*funs(*,*,i)
endfor

lami=lam_c
if(ifib eq 0 or ifib eq 2) then begin
  iic=ifib/2
; dxx=fibcoefs_c(0,iic)+fibcoefs_c(1,iic)*jord+fibcoefs_c(2,iic)*jx+$
;  fibcoefs_c(3,iic)*jx*jord+fibcoefs_c(4,iic)*jord^2+$
;  fibcoefs_c(5,iic)*jx*jord^2+fibcoefs_c(6,iic)*jx^2+$
;  fibcoefs_c(7,iic)*jord*jx^2+fibcoefs_c(8,iic)*jx^3+$
;  fibcoefs_c(9,iic)*jord^3
   dxx=fibcoefs_c(0,iic)+fibcoefs_c(1,iic)*lo1+fibcoefs_c(2,iic)*lx1+$
   fibcoefs_c(3,iic)*lx1*lo1+fibcoefs_c(4,iic)*lo2+$
   fibcoefs_c(5,iic)*lx1*lo2+fibcoefs_c(6,iic)*lx2+$
   fibcoefs_c(7,iic)*lo1*lx2+fibcoefs_c(8,iic)*lx3+$
   fibcoefs_c(9,iic)*lo3
endif

dlamdx=fltarr(nx,nord)
fib_poly=fltarr(nx,nord)
for i=0,nord-1 do begin
  dlamdx(*,i)=deriv(lam_c(*,i))
endfor
fib_poly=dxx*dlamdx

;stop

end
