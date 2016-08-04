pro contnorm,datin,datout,contout
; this routine accepts array datin, which contains one order of a
; flat-fielded NRES spectrum.  It does a fit to the continuum points,
; divides by the fit, and returns the normalized spectrum.
; The normalization is done in such a way that the median value is left
; unchanged.
; The continuum fit is returned in contout.

; constants
hiclip=0.025           ; ignore points higher than (1.-hiclip) percentile
noisscal=0.1           ; try to account for noise inflation of the upper
                       ; bound via a correction based on local SNR and this
                       ; constant.
extn=100               ; extend input array by this many points on both ends.

; get length of datin, embed it in larger array for median-filtering
npt=n_elements(datin)
datine=fltarr(npt+2*extn)
datine(extn:npt+extn-1)=datin
; fill ends with median of 1st 50 non-zero data points
s0=where(datine ne 0.,ns0)
s1=where(datine eq 0.,ns1)
if(ns0 gt 0) then begin
  xmin=s0(0)                ; 1st nonzero data point
  xmax=max(s0)              ; last nonzero data point
  datine(0:xmin-1)=median(datine(xmin:xmin+49))
  datine(xmax:npt+2*extn-1)=median(datine(xmax-49:xmax))

; make various filtered versions to estimate noise, to remove spectrum lines,
; 
; low-passed data, with suppressed noise
  lpdat=smooth(smooth(datine,3),3)
; high-passed data, to estimate rms noise
  hpdat=datine-lpdat
; broad median-filtered data, for normalization.
  meddat=smooth(median(datine,149),49)
; local reciprocal SNR
  noise=smooth(median(abs(hpdat),149),49)      ; median of abs of noise, not rms
; adjusted meddat, to retain bumps between deep lines, thus give fewer
; high points in ratio of datine to meddat
; first do sigma clipping on the datine points (only high points)
  dif=datine-meddat
  quartile,dif,med,q,dq
  s=where(dif gt dq*5./1.35,ns)            ; >5 sigma points
  datine0=datine                           ; save original datine
  if(ns gt 0) then begin
    datine(s)=meddat(s)
  endif
  meddat2=median((datine > meddat),49)
  rsnr=noise/meddat

; identify points in lpdat/meddat2 in percentile range 0.88 to 1.-hiclip
  ned=n_elements(datine)
  ratio=lpdat/meddat2
  so=sort(ratio)
  ig=so(0.88*ned:(1.-hiclip)*ned)
  xx=ig-ned/2.

; fit a polynomial to these identified points, evaluate it over the pixel
; range, and make ratio datin/poly
  cc=poly_fit(double(xx),double(lpdat(ig)),11)
  zz=dindgen(ned)-ned/2.
  yy=float(poly(zz,cc))
  dnorm=datine0/yy
  datout=dnorm(extn:extn+npt-1)
  datout=datout*median(datin(s0))/median(datout(s0))
  contout=yy(extn:extn+npt-1)
  s2=where(datin eq 0,ns2)
  if(ns2 gt 0) then begin
    datout(s2)=0.
    contout(s2)=0.
  endif

endif else begin
  datout=fltarr(npt)                  ; output filled with zeros
  contout=fltarr(npt)
endelse

end
  

