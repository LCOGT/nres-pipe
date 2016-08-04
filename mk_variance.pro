pro mk_variance
; This routine makes the variance map for the 2D image cordat.
; Input and output data are found in the nres common block.

@nres_comm

; needs bias-subtracted image in units of e-, read noise in ADU, reciprocal
; gain in e-/ADU

varmap=(cordat > 0.) + ccd.gain^2*ccd.rdnois

end
