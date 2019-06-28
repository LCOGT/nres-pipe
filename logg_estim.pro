function logg_estim,gaia_teff,gaia_radius
; This routine makes an estimate of the stellar log(g) based on Gaia
; estimates of teff, radius, and luminosity.  This is impossible in principle,
; because evolutionary tracks cross in teff-luminosity space.  Fortunately,
; accuracy is not required.  Method is to estimate main-sequence mass from
; teff, then compare radius with main-sequence radius.  If radius/MSradius
; is >3 and teff is in red giant range, then assume mass = 1.2 M_sun.
; Last, compute logg from mass estimate and Gaia radius.

; main sequence mass-Teff relation (from Mamajek 2011, quoting Malkov 2007 and
; Hillenbrand & White 2004.
lteff=3.453+.01*findgen(117)           ; log Teff
lmass=fltarr(117)                      ; log mass (solar units)
s=where(lteff ge 3.523,ns)
aa=[-84.48396,60.94505,-14.89538,1.240992]
lmass(s)=aa(0)+aa(1)*lteff(s)+aa(2)*lteff(s)^2+aa(3)*lteff(s)^3
s1=where(lteff lt 3.5295,ns1)
lmass(s1)=-27.81774+7.786*lteff(s1)

; mass-radius relation from Malkov 1993
xlmass=-1.+.01*findgen(200)           ; log mass for mass/radius relation
lradius=fltarr(200)                   ; log radius (solar units)
s2=where(xlmass le 0.172,ns2)
lradius(s2)=(-0.86+(xlmass(s2)+1.)*(.255814+.860465)/(1.+.172414)) 
s3=where(xlmass ge .172,ns3)
lradius(s3)=.255814+(xlmass(s3)-.172414)*(.953488-.255814)/(1.48276-.172414)

; main-sequence mass from teff
lgteff=alog10(gaia_teff)
lmsmass=interpol(lmass,lteff,lgteff)   ; log main seqence mass
msmass=10.^lmsmass

; main-sequence radius from msmass
lmsrad=interpol(lradius,xlmass,lmsmass)  ; log main sequence radius
msrad=10.^lmsrad

; trap giants
if ((gaia_radius/msrad ge 3.) and (gaia_teff le 5800.)) then mass=1.2 $
   else mass=msmass 
logg=4.438+lmsmass-2.*alog10(gaia_radius)   ; scale logg from solar value

return,logg

end
