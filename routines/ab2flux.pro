function ab2flux,mag,lambda,phot=phot
; this function returns the flux (erg/cm^2-s-AA) for a given AB magnitude
; and wavelength (in AA).
; Inputs may be scalars or (same length) vectors.
; If keyword phot is set, results are returned in photons/cm^2-s-AA`

; constants
cc=2.997d10          ; speed of light, cm/s
h=6.626d-27          ; planck constant cgs

arg=-(mag + 5.d0*alog10(lambda) + 2.406)/2.5
flux=10.d0^arg

if(keyword_set(phot)) then begin
  nu=cc/(lambda*1.d-8)
  phe=h*nu
  flux=flux/phe
endif

return,flux
end
