function lsqblkfit2,lamblock,zblock,dblock,wts,cov,modelo,resido
; This routine accepts the wavelength array lamblock, the ZERO intensity array
; zblock (both modified to account for the estimated barycentric and
; cross-correlation shifts), and the observed data array dblock.
; It performs an iterated least-squares fit to minimize the weighted squared
; difference between dblock and a redshifted, scaled model given by the
; following.  Let u = zblock(lamblock*(1.-rr)) - <zblock(lamblock*(1.-rr))>,
;      where <> denotes mean value.  Then
;   model = u*bb + aa
; Values of {rr, aa, bb} are returned as a double-precision array.
; Also returned in the calling sequence is the covariance array cov
; describing the returned variables, and
;  modelo = the best-fit model corresp to dblock
;  resido = dblock-modelo
; 
; Procedure is to set rr=0 initially, compute dzdx = d/dx(zblock) 

; constants
c=2.99792458d5               ; speed of light, km/s
delmin=3.d-10                ; 10 cm/s
rr0max=0.001                 ; 300 km/s = comparable to width of block
itermax=10                   ; max allowed number of iterations
rutname='lsqblkfit'

uu0=double(zblock-total(zblock*wts)/total(wts))     ; starting u vector
aa0=double(total(dblock*wts)/total(wts))            ; first guess at aa
bb0=double(total((dblock-aa0)*uu0*wts)/total(uu0^2*wts)) ; first guess at aa
rr0=0.d0
np=n_elements(zblock)

; iteratively do least-squares fit for parameters aa, bb, ss
funs=fltarr(np,3)
for i=0,itermax-1 do begin
  lamt=lamblock*(1.+rr0)      ; current redshifted wavelength array
  dlamdx=deriv(lamt)
  zbt=interpol(zblock,lamblock,lamt,/quadratic)   ; ZERO array on curr lam grid

; dzdx=deriv(zbt)
  um=zbt-aa0
  model=(zbt-aa0)*bb0 + aa0               ; current model
  dzdx=deriv(model)
  resid=dblock-model

; do least-squares fit to adjust aa, bb, rr to minimiza residuals
  funs(*,0)=1.0                 ; aa
  funs(*,1)=um                  ; bb
  funs(*,2)=dzdx
  if(max(abs(zbt)) eq 0.0) then begin  ; test for non-overlap with ZERO fn
    cc=[0.,0.,0.]
    ierr=0
  endif else begin
    cc=lstsqr(resid,funs,wts,3,rms,chisq,outp,1,cov,ierr,/gauss)
  endelse
  if(ierr ne 0) then begin
    logo_nres2,rutname,'WARNING','singular matrix found in lsqblkfit'
  endif

; modify model parameters
  aa0=aa0+cc(0)
  bb0=bb0+cc(1)
  delrr=cc(2)*mean(dlamdx/lamt)      ; pix shift expressed as redshift

  rr0=rr0+delrr
  modelo=(zbt-aa0)*bb0 + aa0 + cc(2)*dzdx
  resido=dblock-modelo

; we are finished if delrr is small enough, or if rr0 is too big)
  if(abs(delrr) le delmin or abs(rr0) ge rr0max) then goto,done

endfor

done:

vals=[aa0,bb0,rr0]
return,vals

end
