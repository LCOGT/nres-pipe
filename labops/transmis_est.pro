pro transmis_est,starimage,skyimage,skyspec,vmag,transmis,broad=broad
; This routine estimates the transmission of the spectrograph system at the
; nominal wavelength of the AGU narrow-band filter, using a spectrum of the daytime sky
; and a simultaneous AGU image of the daytime sky, both taken through the narrow-band
; filter, combined with an image of a standard star also taken through the filter.
; Star image must be off the pinhole.
; Also estimates the optical efficiency of the telescope/AGU system (including the
; optics up through the ATIK CCD) from the total flux seen from the star.
; On input,
; starimage = pathname of AGU star image through NBF.  Must be unsaturated.
; skyimage = pathname of AGU sky image through NBF.  Also unsaturated.
; skyspec = pathname of extracted raw spectrum of sky, background-subtracted,
;           taken through NBF.
; vmag = V magnitude of star imaged in starimage
; On output, transmis is a structure with elements
;   .eff_spec = optical efficiency of the spectrograph
;   .eff_tel = optical efficiency of the telescope/AGU imaging system.
;   .eff_telspec = efficiency of the telescope/fiber/spectrograph system
; If keyword broad is set, then the telescope efficiency is computed assuming an
; "air" filter in the AGU beam (not narrow-band), and no computation of eff_spec
; is attempted.

; constants
h=6.626e-27             ; planck constant
c=2.9978e10		; light speed
dlam=206.               ; nominal bandwidth of filter, angstroms
telaper=100.            ; telescope aperture in cm
tel2nd=0.4              ; fractional diameter of central obstruction
flux0=[1392.,996.,702,452.]     ; phot/cm^2-s-A for [B,V,R,I]=0, respectively.
dmags=[.80,0.,-.60,-1.04]  ; mags of V=0. sunlike star in [B,V,R,I]
dlam0=[900.,850.,1500.,1500.]  ; eff filter bandwidth in AA.
fvlam=3.63e-9           ; erg/cm^2-AA-s from V=0
atmos=0.85              ; atmospheric transmission in V band
filtran=0.9             ; max transmission of narrowband filter
bias=450.               ; estimated bias signal for ATIK camera
cc=[.002568,-4.2518e-7,2.0036e-11]   ; dlam/dx (nm/pix) avgd over the orders where
                                        ; light from the broadband filter is found
rowbot=1600             ; low row of box containing broadband filter orders
rowtop=1900             ; top row ditto
lammid=5265.            ; broadband filter central wavelength (AA)
hnu=h*c/(lammid*1.e-8)  ; energy per photon for center of broadband filter
fibarea=25.             ; area of fiber end in AGU pix^2
tranpin2atik=0.9^2*.8*.6  ; light transmission from incidence on pinhol mirror to
                        ; detection by atik detector.  2 reflections and macro lens,
                        ; plus atik efficiency.  This is the part of the light loss
                        ; in which the fiber does not participate.
telarea=!pi*telaper^2*(1.-tel2nd^2)/4.      ; telescope area in cm^2

eff_spec=0.
eff_tel=0.
eff_telspec=0.

; do photometry on the star image
star=readfits(starimage,hdrstar,/silent)
expstar=sxpar(hdrstar,'EXPTIME')
gainstar=sxpar(hdrstar,'GAIN')           ; e- per ADU
sz=size(star)
snx=sz(1)
sny=sz(2)
; subtract background
starz=float(star)-median(star)
starzm=median(starz,7)                   ; median filter to reject oddball points
maxs=max(starzm,ix)
iyx=long(ix/snx)
ixx=ix-snx*iyx                           ; x, y coords of brightest point
; temporary override for Scheat image, which has much brighter star nearby.
ixx=688L
iyx=446L                   ; coords of tiny star on Rob's image
xx=findgen(snx)-ixx
xx=rebin(xx,snx,sny)
yy=reform(findgen(sny)-iyx,1,sny)
yy=rebin(yy,snx,sny)
rr=sqrt(xx^2+yy^2)
s=where(rr le 14,ns)
fluxstar=gainstar*total(starz(s))/expstar   ; detected photoelectrons/s from star
                                            ; seen by Atik camera in filter band.

stop

; compute expected flux from star, from magnitude and telescope specs
; if broad keyword set, then compute for sum of B,V,R,I filters, assuming solar colors.
if(keyword_set(broad)) then begin
  colmag=vmag+dmags
  colbri=10.^(-0.4*colmag)          ; relative brightness at each of B,V,R,I
  phot0=colbri*dlam0*flux0          ; phot/s in each band
  modlstar=telarea*total(phot0)
endif else begin
  colbri=10.^(-0.4*vmag)*flux0(1)*dlam
  modlstar=telarea*colbri     ; expected incident photoelectrons/s from star 
                              ; in filter band
endelse

eff_tel=fluxstar/modlstar      ; efficiency through ATIK CCD
stop
eff_spec=0.
if(keyword_set(broad)) then goto,fini

;fvstar=flux0(1)*10.^(-0.4*vmag)       ; photon flux from star, phot/cm^2-AA-s
;agudtresp=total(starz(s))/(expstar*flux0(1)*telarea*dlam)   ; detected phot per incident
; agudtresp is the response of the AGU guide camera in ADU per (photons incident on
; the telescope's area outside of the atmosphere, with the narrowband filter in
; the beam).  For a perfectly transmitting system, this number should be
; 1./(gainstar*hnu), or about 1.e12. 

; read the sky image, calculate the count rate per pixel
; median(star) is a stand-in for a bias measurement
ddsky=float(readfits(skyimage,hdrsky,/silent))-median(star)
; estimate signal as median over center 1/3 x 1/3 of the image
exptsky=sxpar(hdrsky,'EXPTIME')
gainsky=sxpar(hdrsky,'GAIN')
sky_flux=median(ddsky(snx/3:2*snx/3,sny/3:2*sny/3))/exptsky     ; ADU/s-pix
fib_flux=sky_flux*gainsky*fibarea/(tranpin2atik)         ; phot/s into fiber from sky
equivmag=-2.5*alog10(fib_flux/(dlam*telarea*flux0(1)))   ; equiv mag star seen by fiber.

; read the sky spectrum, calculate the flux (spec_ADU/s) from the sky, integrated
; over the narrowband filter range of wavelengths.
sssky=float(readfits(skyspec,hdrspec,/silent))
ssexpt=sxpar(hdrspec,'EXPTIME')
;gain_spec=sxpar(hdrspec,'GAIN')
gain_spec=1.0               ; assumes image has been 'fixed'
; orders 35-38, y-coords 1610-1860
; cc=[.002568,-4.2518e-7,2.0036e-11] describes dlam/dx (nm) avgd over these orders.
; with x=findgen(4096)-2048.
sz=size(sssky)
nx=sz(1)
ny=sz(2)
xx=findgen(nx)-nx/2.
dldx=10.*poly(xx,cc)
uu=sssky(*,rowbot:rowtop)
backg=median(uu)                      ; background estimate
avgi=rebin(uu-backg,nx)
dlam=total(dldx*avgi/ptile(avgi,99))*4  ; effective bandwidth in AA (covers 4 orders)
diffi=uu-backg
quartile,diffi,med,q,dq
s=where(diffi gt med+3.*dq)             ; only points in orders, pretty much
sumi=total(diffi(s))                    ; total ADU in broadband orders.
spec_flux=sumi*gain_spec/ssexpt         ; (spec photons/s at fiber plane)

eff_telspec=spec_flux/(fib_flux*ssexpt)        ; estimated efficiency of entire
                                                ; telescope + fiber + spectrograph.
eff_spec=eff_telspec*tranpin2atik/eff_tel       ; estimated efficiency of spectrograph
                                                ; from fiber input through sinistro.
fini:

stop

transmis={eff_tel:eff_tel,eff_spec:eff_spec,eff_telspec:eff_telspec,equivmag:equivmag}

print,'Telescope-AGU efficiency (nom 0.25):',eff_tel,.25/eff_tel
print,'Fiber-Spectrograph efficiency (nom 0.13):',eff_spec,.13/eff_spec
print,'Telescope-Fiber-Spectrograph efficiency (nom 0.10):',eff_telspec,.10/eff_telspec
print,'Equiv mag seen by fiber:',equivmag

end
