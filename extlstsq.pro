pro extlstsq,sprofile,dfpdy,d2fpdy2,ebo,vbo,ewts,datparms,nfun,ifun,fitc
; This routine performs the weighted least-squares fit to estimate the
; shape and scaling of observed counts across the order profile, for a single
; fiber.
; The routine is flexible as to which functions (and how many) it fits.
; Possible functions (with their integer labels) are as follows:
;   0 = profile function of cross-disp position.  This should always be fit.
;   1 = constant offset function (unity) across order
;   2 = d(profile)/dy, normalized by total flux integrated across order
;   3 = d2(profile)/dy2
;  
; On input
;  sprofile(nx,cowid,nord) = model profile, incorporating best knowledge 
;     of shape, width, and centering within the extraction box.
;  dfpdy(nx,cowid,nord) = derivative of sprofile across the order,
;     normalized by total flux under sprofile.
;  d2fpdy2(nx,cowid,nord)= derivative of dfpdy across the order
;  ebo(nx,cowid,nord) = observed intensities in extraction boxes
;  vbo(nx,cowid,nord) = model variance map of data in ebox
;  ewts(nx,cowid,nord) = relative weights applied to pixels in ebo
;  datparms = structure containing values of nx, nord, nfib, mfib, cowid, remain
;  nfun = number of functions to fit.  Must be 1, 2, or 3
;  ifun(3) = int array containing indices of funs to be fit in range [0,3].
;     The first nfuns values are used to identify which functions will be fit.
;     The first value must be zero, and no value may repeat in the 1st nfuns
;     items.  Thus, for instance, nfuns=2, ifuns=[0,2,anything] means fit
;       the profile amplitude and the 1st derivative.
;       nfuns=3, ifuns=[0,2,3] means simultaneously fit the profile amplitude,
;       the normalized 1st derivative, and the 2nd derivative.     
; On output
;  fitc(nx,nord,5) = fitted coefficients for the given fiber, arranged as
;      [0,1,2,3,4] = [exintn,excon,exdy,exdy2,exsig] where
;    exintn(nx,nord) = estimated integrated counts across orders
;    excon(nx,nord) = constant background added to profile
;    exdy(nx,nord) = amplitude of 1st deriv of profile, normalized by total
;      flux  =  across-order displacement in pix of actual profile 
;      relative to expected position.
;    exdy2 = amplitude of 2nd deriv of profile, normalized by total flux
;    exsig(nx,nord) = formal rms of values in exintn
;  parameters that are not included in the fit are returned = 0.

; unpack datparms
nx=datparms.nx
nord=datparms.nord
nfib=datparms.nfib
mfib=datparms.mfib
cowid=datparms.cowid
remain=datparms.remain

; make unity array
unity=fltarr(nx,cowid,nord)+1.

; estimate intensity vs x via optimal weighted fit to shifted profiles

; renormalize profiles so that total(profile(y)^2) is constant for all x
; This is necessary because the profile interpolation process results in
; profiles of slightly different width, depending on what fraction of a
; a pixel they are shifted by. This in turn leads to variable response to
; the same optical profile, as a function of distance from profile center
; to pixel center coord.
;
fprofile=sprofile
;fprof2=cowid*rebin(fprofile^2,nx,1,nord)   ; fprof2(nx,1,nord)
;fprof2=rebin(fprof2,nx,cowid,nord)         ; fprof2(nx,cowid,nord)
;mpro2=fltarr(nord)
;for i=0,nord-1 do begin
  ;mpro2(i)=median(fprof2(*,0,i))
  ;fprofile(*,*,i)=fprofile(*,*,i)*mpro2(i)/fprof2(*,*,i)
;endfor

funs=fltarr(nx,cowid,nord,4)
funs(*,*,*,0)=fprofile
funs(*,*,*,1)=unity
funs(*,*,*,2)=dfpdy
funs(*,*,*,3)=d2fpdy2
fewts=ewts
febo=ebo

fitc=fltarr(nx*nord,5)

; now make cross-dispersion sums of products for use in the fit
; distinguish cases for how many coefficients
case nfun of
1: begin
a00=reform(cowid*rebin(funs(*,*,*,ifun(0))^2*fewts,nx,1,nord))
y0=reform(cowid*rebin(funs(*,*,*,ifun(0))*febo*fewts,nx,1,nord))
sn=where(a00 ne 0.,nsn)
fitc(sn,ifun(0))=y0(sn)/a00(sn)
fitc=reform(fitc,nx,nord,5)
end

2: begin
a00=reform(cowid*rebin(funs(*,*,*,ifun(0))^2*fewts,nx,1,nord))
a01=reform(cowid*rebin(funs(*,*,*,ifun(0))*funs(*,*,*,ifun(1))*fewts,$
    nx,1,nord))
a10=a01
a11=reform(cowid*rebin(funs(*,*,*,ifun(1))^2*fewts,nx,1,nord))
y0=reform(cowid*rebin(funs(*,*,*,ifun(0))*febo*fewts,nx,1,nord))
y1=reform(cowid*rebin(funs(*,*,*,ifun(1))*febo*fewts,nx,1,nord))
det=a00*a11-a01*a10
d0=y0*a11-a01*y1
d1=a00*y1-y0*a01
sn=where(det ne 0.,nsn)
fitc(sn,ifun(0))=d0/det
fitc(sn,ifun(1))=d1/det
fitc=reform(fitc,nx,nord,5)
end

3: begin
a00=reform(cowid*rebin(funs(*,*,*,ifun(0))^2*fewts,nx,1,nord))
a01=reform(cowid*rebin(funs(*,*,*,ifun(0))*funs(*,*,*,ifun(1))*fewts,$
    nx,1,nord))
a10=a01
a11=reform(cowid*rebin(funs(*,*,*,ifun(1))^2*fewts,nx,1,nord))
a02=reform(cowid*rebin(funs(*,*,*,ifun(0))*funs(*,*,*,ifun(2))*fewts,$
    nx,1,nord))
a20=a02
a12=reform(cowid*rebin(funs(*,*,*,ifun(1))*funs(*,*,*,ifun(2))*fewts,$
    nx,1,nord))
a21=a12
a22=reform(cowid*rebin(funs(*,*,*,ifun(2))^2*fewts,nx,1,nord))
y0=reform(cowid*rebin(funs(*,*,*,ifun(0))*febo*fewts,nx,1,nord))
y1=reform(cowid*rebin(funs(*,*,*,ifun(1))*febo*fewts,nx,1,nord))
y2=reform(cowid*rebin(funs(*,*,*,ifun(2))*febo*fewts,nx,1,nord))
det=a22*(a00*a11-a01*a10) - a20*(a02*a11-a01*a12) + a21*(a02*a10-a00*a12)
d0=a22*(y0*a11-a10*y1) - a20*(y2*a11-a12*y1) + a21*(y2*a10-a12*y0)
d1=a22*(a00*y1-y0*a01) - a20*(a02*y1-y2*a01) + a21*(a02*y0-y2*a00)
d2=y2*(a00*a11-a10*a01) - y0*(a02*a11-a12*a01) + y1*(a02*a10-a12*a00)
sn=where(det ne 0.,nsn)
sb=where(det eq 0.,nsb)
;if(nsb gt 0) then stop
;fitc(*,*,ifun(0))=d0/det
;fitc(*,*,ifun(1))=d1/det
;fitc(*,*,ifun(2))=d2/det
fitc(sn,ifun(0))=d0(sn)/det(sn)
fitc(sn,ifun(1))=d1(sn)/det(sn)
fitc(sn,ifun(2))=d2(sn)/det(sn)
fitc=reform(fitc,nx,nord,5)
end
endcase

; make output arrays, and nominal displacement of order from box center
exintn=fitc(*,*,0)
sg=where(exintn gt 0.,nsg)
excon=fitc(*,*,1)
exdy=fitc(*,*,2)
exdy(sg)=exdy(sg)/exintn(sg)
exdy2=fitc(*,*,3)
exdy2(sg)=exdy2(sg)/exintn(sg)
svbo=cowid*reform(rebin(vbo,nx,1,nord),nx,nord)
exsig=sqrt(svbo)
fitc(*,*,0)=exintn
fitc(*,*,1)=excon
fitc(*,*,2)=exdy
fitc(*,*,3)=exdy2
fitc(*,*,4)=exsig

end
