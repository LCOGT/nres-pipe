function orthogfit,x,y,nc,type,resid
; This function returns coefficients of an expansion of y(x) in terms of
; orthogonal polynomials of order nc and of the given type.
; On input
;  x(npt) is a vector of the independent variable
;  y(npt) is a vector of the dependent variable
;  nc is the max degree of the polynomials used, with nc <= 6
;  type is one of 'legendre' or 'chebyshev' (case insensitive)
; The returned vector coef(nc+1) contains the polynomial expansion coeffs,
; calculated after rescaling x so that it lies in the range [-1,1].

ttype=strtrim(strlowcase(type),2)
xran=max(x)-min(x)
xmid=(max(x)+min(x))/2.
xx=2.*(x-xmid)/xran

; set up functions to be fitted
npt=n_elements(x)
funs=dblarr(npt,nc+1)
for i=0,nc do begin
  case ttype of
  'legendre': begin
    funs(*,i)=mylegendre(xx,i)
  end
  'chebyshev': begin
    funs(*,i)=mychebyshev(xx,i)
  end
  endcase
endfor

stop

; do the fit
wts=dblarr(npt)+1.d0
cc=lstsqr(y,funs,wts,nc+1,rms,chisq,outp,1,cov,ierr,gauss=gauss,$
  svdminrat=svdminrat,dofit=dofit)
resid=outp

stop

return,cc

end
