function logg_estim,gaia_teff,gaia_radius,gaia_lum
; This routine makes an estimate of the stellar log(g) based on Gaia
; estimates of teff, radius, and luminosity.  This is impossible in principle,
; because evolutionary tracks cross in teff-luminosity space.  Fortunately,
; accuracy is not required.  Method is to estimate main-sequence mass from
; teff, then compare radius with main-sequence radius.  If radius/MSradius
; is >2 and teff is in red giant range, then assume mass = 0.8 M_sun.
; Last, compute logg from mass estimate and Gaia radius.


