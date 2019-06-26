function vmag_estim,gaia_bpmag,gaia_brmag
; This routine attempts to estimate Vmag given the Gaia magnitudes
; gaia_bpmag, gaia_brmag.
; This is a simple-minded first cut at the routine, which simply sets
; vmag = gaia_bpmag.

vme=gaia_bpmag
return,vme

end
