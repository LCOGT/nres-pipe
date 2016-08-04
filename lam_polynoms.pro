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
if(ncoefs_c eq 15) then begin
  funs(*,*,10)=jord^4
  funs(*,*,11)=jx*jord^3
  funs(*,*,12)=jx^2*jord^2
  funs(*,*,13)=jx^3*jord
  funs(*,*,14)=jx^4
endif

; add polynomials to lam
plam=fltarr(nx,nord)
for i=0,ncoefs_c-1 do begin
  plam=plam+coefs_c(i)*funs(*,*,i)
endfor

lami=lam_c
if(ifib eq 0 or ifib eq 2) then begin
  iic=ifib/2
  dxx=fibcoefs_c(iic,0)+fibcoefs_c(iic,1)*jord+fibcoefs_c(iic,2)*jx+$
   fibcoefs_c(iic,3)*jx*jord+fibcoefs_c(iic,4)*jord^2+$
   fibcoefs_c(iic,5)*jx*jord^2+fibcoefs_c(iic,6)*jx^2
endif

dlamdx=fltarr(nx,nord)
fib_poly=fltarr(nx,nord)
for i=0,nord-1 do begin
  dlamdx(*,i)=deriv(lam_c(*,i))
endfor
fib_poly=dxx*dlamdx

stop

end
