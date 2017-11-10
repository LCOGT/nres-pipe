function lsqblkfit,lamblock,zblock,dblock,wts,cov
; This routine accepts the wavelength array lamblock, the ZERO intensity array
; zblock (both modified to account for the estimated barycentric and
; cross-correlation shifts), and the observed data array dblock.
; It performs an iterated least-squares fit to minimize the weighted squared
; difference between dblock and a redshifted, scaled model given by
;   model = zblock(lamblock*(1.-rr))*(aa + bb*x), where is the pixel coordinate
; scaled to run from -1 to +1 across the width of the block.
; Values of {rr, aa, bb} are returned as a double-precision array.
; Also returned in the calling sequence is the covariance array cov
; describing the returned variables.
; 
; Procedure is to set rr=0 initially, compute dzdx = d/dx(zblock) 

; constants
c=2.99792458d5               ; speed of light, km/s
delmin=3.d-10                ; 10 cm/s
itermax=10                   ; max allowed number of iterations

aa0=double(total(dblock*wts)/total(zblock*wts))     ; first guess at aa
bb0=0.d0                                    ; first guess at bb
rr0=0.d0                                    ; first guess at rr
np=n_elements(zblock)
xx=(dindgen(np)-np/2.)*2./np        ; x-coordinate for linear term in scaling

; iteratively do least-squares fit for parameters aa, bb, ss
funs=fltarr(np,3)
for i=0,itermax-1 do begin
  lamt=lamblock*(1.+rr0)      ; current redshifted wavelength array
  dlamdx=deriv(lamt)
  zbt=interpol(zblock,lamblock,lamt,/quadratic)   ; ZERO array on curr lam grid
  dzdx=deriv(zbt)
  model=zbt*(aa0+bb0*xx)               ; current model
  resid=dblock-model

; do least-squares fit to adjust aa, bb, rr to minimiza residuals
  funs(*,0)=zbt
  funs(*,1)=zbt*xx
  funs(*,2)=dzdx
  cc=lstsqr(resid,funs,wts,3,rms,chisq,outp,1,cov)

; modify model parameters
  aa0=aa0+cc(0)
  bb0=bb0+cc(1)
  delrr=cc(2)*mean(dlamdx/lamt)      ; pix shift expressed as redshift

  rr0=rr0+delrr

  if(abs(delrr) le delmin) then goto,done

endfor

done:

vals=[aa0,bb0,rr0]
return,vals

end
