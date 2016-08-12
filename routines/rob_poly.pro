function rob_poly,xx,dat,wts,nord,sig,rms,chisq,outp,type,rej
; This function does a robust least-squares polynomial fit
;   dat = a[0] + a[1]*xx + .... a[nord]*xx^nord.
; Bad points are rejected if their residual about the last-performed fit
; is greater than sig*wid, where wid is the distribution core std dev,
; estimated as dq/1.349, where dq is the full interquartile spread.
; By default, data are weighted according to the corresponding wts value.
; The function returns a vector a containing the fit coefficients.
; 
; On return, rms contains the rms of the residuals for the accepted data points.
;  chisq contains the chi-squared statistic for the accepted points.
;  outp contains the r
; If arguments outp and type
; are given, then on return outp contains:
;  type = 0 => the fitted function
;  type = 1 => residuals around fit,in the sense (data - fit)
;  type = 2 => ratio (data/fit)
; if outp is an argument but type is not given, type defaults to 0.
; Returned vector rej contains 0 if the corresponding point was retained, else
;      1 if the point was rejected.

; get sizes of things
npr=n_params()
s=size(dat)
nx=s(1)
if (s(0) ne 1 or nx lt 3) then begin
  print,'bad dimension in rob_poly data'
  return,0.
endif
nfun=nord+1
funs=fltarr(nx,nfun)
funs(*,0)=1.
for i=1,nord do begin
  funs(*,i)=xx^i
endfor
iwts=wts              ; initialize iwts
rej=fltarr(nx)
if(npr le 8) then type=0

; Zeroth iteration --  check scatter before doing a fit at all.
quartile,dat,med,q,dq
dif=dat-med
wid=dq/1.35
s=where(abs(dif) gt sig*wid,ns)
if(ns gt 0) then begin
  iwts(s)=0.
  rej(s)=1.
endif
if(nx-ns lt 3) then begin
  print,'too few good points in rob_poly data'
  return,0.
endif

; fitting loop
loop:

sgood=where(rej eq 0,ngood)
ngood=nx-total(rej)
if(ngood gt 3 and ngood gt nfun+1) then begin
  cc=lstsqr(dat,funs,iwts,nfun,rms,chisq,ou,1) 
  quartile,ou(sgood),med,q,dq
  dif=ou-med
  wid=dq/1.35
  s=where(abs(dif) gt sig*wid and iwts ne 0.,ns)
  if(ns gt 0) then begin
    iwts(s)=0.
    rej(s)=1.
    goto,loop
  endif
endif

; get here when selection of points to fit has converged
if(type eq 0) then outp=dat-ou
if(type eq 1) then outp=ou
if(type eq 2) then outp=dat/(dat-ou)

return,cc

end
