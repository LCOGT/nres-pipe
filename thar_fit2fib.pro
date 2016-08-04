pro thar_fit2fib,filin,nb,fitcoefs,rms
; This routine accepts filin, the name of a ThAr DOUBLE file.
; It first runs thar_cc2fib to estimate the shifts between lines from the 
; 2 fibers as a function of x position and order number, segmenting each
; order into nb blocks in order to get the x-coord dependence.
; It then performs a robust fit of these shifts to an expression of the form
;  dx = a + b*n + c*x + d*x*n + e*n^2 + f*x*n^2 + g*x^2,
; where x = pixel number and n = order index (starting at 0).
; Results are returned in fitcoefs = [a, b, c, d, e, f, g]
; RMS of the fit in pixel units is returned in rms.

; measure the cross-correlations
thar_cc2fib,filin,nb,nx,nord,dx,ccamp

; make preliminary fitting weights, based on the cc amplitudes.
wts=fltarr(nord,nb)+1.
medcc=median(ccamp)
s=where(ccamp lt 1.5*medcc)     ; only take blocks with strong cc signal
wts(s)=0.

; make fitting functions
xx=(findgen(nb)+0.5-nb/2.)*nx/nb
xx=rebin(reform(xx,1,nb),nord,nb)
nn=findgen(nord)-nord/2.
nn=rebin(nn,nord,nb)

funs=fltarr(nb*nord,7)
funs(*,0)=1.
funs(*,1)=reform(nn,nb*nord)
funs(*,2)=reform(xx,nb*nord)
funs(*,3)=reform(xx*nn,nb*nord)
funs(*,4)=reform(nn^2,nb*nord)
funs(*,5)=reform(xx*nn^2,nb*nord)
funs(*,6)=reform(xx^2,nb*nord)
wts=reform(wts,nb*nord)

; do a fit
yy=reform(dx,nb*nord)
cc0=lstsqr(yy,funs,wts,7,rms0,chisq0,outp0,1,cov)

; locate poor fitting points based on quartile stats of residuals
quartile,outp0,med,q,dq
sb=where(abs(outp0) gt 4./1.35*dq,nsb)     ; nominally 4-sigma

if(nsb gt 0) then wts(sb)=0.              ; zero wt to bad points

; redo the fit
fitcoefs=lstsqr(yy,funs,wts,7,rms,chisq1,outp1,1,cov)

end
