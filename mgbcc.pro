pro mgbcc,zlam,zstar,lam,star,rcc,ampcc,widcc,ccm,delv,rvv
; This routine makes a rough estimate of the redshift between the 
; one-dimensional 
; ZERO spectrum zstar(zlam) and the target spectrum star(lam).
; Normally the inputs correspond to
; the order that is most nearly centered on the Mg b lines
; near 516 nm.  Results are returned in
; rcc = redshift of corspec relative to ZERO (+ => star is 
;         redshifted rel to zero),
; ampcc = amplitude of cross-correlation peak, normalized to 1 for perfect
;         correlation.
; widcc = FWHM of the cross-correlation peak, in km/s.
; ccm = cross-correlation function
; delv = x-coordinate of cross-correlation function, in km/s
; rvv = redshift corresp to peak of cc fn, in velocity units (km/s)
;       No barycentric correction included here.
;
; Technique is to interpolate both ZERO and star onto an oversampled
; grid with uniform spacing in ln(lambda), ie, in radial velocity.
; Both spectra are high-pass filtered, tapered, and padded with zeros.
; The results are cross-correlated via FFT, and the parameters of the highest
; peak in the correlation are reported.

; constants
c=299792.458d0                  ; light speed in km/s
smwid=150.                      ; highpass smoothing width in km/s

; get sizes of things
nxz=n_elements(zlam)
nxs=n_elements(lam)

; smooth star spectrum to make it easier to interpolate
star=smooth(smooth(star,3),3)

; interpolate both to uniform grid in ln(lam)
dlnlamz=abs(deriv(zlam))/zlam
dlnlams=abs(deriv(lam))/lam
rmin=min([min(dlnlamz),min(dlnlams)])    ; smallest dlnlam in either spectrum
dv=c*rmin                                ; rmin in velocity units (km/s)
lammin=min([min(zlam),min(lam)])         ; min lam in either spectrum
lammax=max([max(zlam),max(lam)])         ; max ditto
range=alog(lammax/lammin)                ; total range in ln(lam)
nn=long(range/rmin)+1            ; number of samples to span range at res rmin

lami=lammin*exp(rmin*dindgen(nn))   ; wavelength grid for interpolated data
zstari=interpol(zstar,zlam,lami,/lsquadratic)
stari=interpol(star,lam,lami,/lsquadratic)

; embed in bigger array, npts divisible by 2048
nbig=2048*(long(nn/2048)+1)
zstare=fltarr(nbig)
stare=fltarr(nbig)             ; extended zstar and star arrays
nbh=(nbig-nn)/2
zstare(nbh:nbh+nn-1)=zstari
stare(nbh:nbh+nn-1)=stari

; for each extended array, set points outside range of original data to
; a value from slightly inside range
s0s=where(stare gt 0,ns0s)
vslo=stare(s0s(10))
stare(0:s0s(10))=vslo
vshi=stare(s0s(ns0s-10))
stare(s0s(ns0s-10):*)=vshi

s0z=where(zstare gt 0,ns0z)
vzlo=zstare(s0z(10))
zstare(0:s0z(10))=vzlo
vzhi=zstare(s0z(ns0z-10))
zstare(s0z(ns0z-10):*)=vzhi

; now we can operate on these spectra with impunity.  First high-pass them
swid=smwid/dv
if((swid mod 2) eq 0) then swid=swid+1
starhp=stare-smooth(stare,swid)
zstarhp=zstare-smooth(zstare,swid)

; taper both star and ZERO --  10% cosine taper at ends of good data segments
stap=fltarr(nbig)
tbot=s0s(10)
ttop=s0s(ns0s-10)
stap(tbot:ttop)=1.
span=ttop-tbot+1
twid=fix(span*0.1)
taper0=0.5*(1.-cos(findgen(twid)*!pi/twid))
taper1=rotate(taper0,2)
stap(tbot:tbot+twid-1)=taper0
stap(ttop-twid+1:ttop)=taper1
starhpt=starhp*stap

ztap=fltarr(nbig)     
tbot=s0z(10)
ttop=s0z(ns0z-10)
ztap(tbot:ttop)=1.
span=ttop-tbot+1
twid=fix(span*0.1)
taper0=0.5*(1.-cos(findgen(twid)*!pi/twid))
taper1=rotate(taper0,2)
ztap(tbot:tbot+twid-1)=taper0
ztap(ttop-twid+1:ttop)=taper1
zstarhpt=zstarhp*ztap

; cross-correlate the high-passed, tapered spectra
fstar=fft(starhpt,1)
fzstar=fft(zstarhpt,1)
fcc=conj(fstar)*fzstar
cc=fft(fcc,-1)
norm=sqrt(total(starhpt^2))*sqrt(total(zstarhpt^2))
cc=shift(float(cc),nbig/2)/norm
vel=c*rmin*(findgen(nbig)-nbig/2.)

; find the maximum, estimate FWHM.
mxcc=max(cc,ix)
mxcch=mxcc/2.              ; halfway from max to zero
ibot=(ix-400) > 0
itop=(ix+400) < (nbig-1) 
ccm=cc(ibot:itop)
lenc=n_elements(ccm)
if(lenc lt 801) then ccm=[ccm,fltarr(801-lenc)]
delx=findgen(801)-400.
delv=delx*rmin*c           ; cc x-coord in velocity units (km/s)
ssn=where(ccm le mxcch and delx lt 0.,nssn)
ssp=where(ccm le mxcch and delx gt 0.,nssp)
hwbot=max(ssn)       ; indices of first cc values less than mxcc/2,
hwtop=min(ssp)       ; counting outwards from max cc value
difbot=mxcch-ccm(hwbot)
slpbot=ccm(hwbot+1)-ccm(hwbot)    ; slope and offset at hwbot
xbot=delx(hwbot)+difbot/slpbot
diftop=mxcch-ccm(hwtop)
slptop=ccm(hwtop-1)-ccm(hwtop)
xtop=delx(hwtop)-diftop/slptop
fwhmpix=xtop-xbot                  ; FWHM in pixel units
widcc=fwhmpix*dv                 ; in velocity units (km/s)

; fit a parabola to central part of peak.
s=where(delx ge -0.33*fwhmpix and delx le 0.33*fwhmpix,ns)
if(ns lt 5) then s=where(delx ge (-2.) and delx le 2.)
xx=delx(s)
zz=ccm(s)
rr=poly_fit(xx,zz,2)
ds=-rr(1)/(2.*rr(2))                ; position of peak in pix, relative to ix
rrp=ix-nbig/2.+ds                  ; redshift in pix
rcc=rrp*rmin
rvv=rcc*c                          ; redshift in km/s
ampcc=rr(0)+rr(1)*ds+rr(2)*ds^2

;stop

end
