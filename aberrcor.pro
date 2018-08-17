pro aberrcor,xo,fibno,lam,specstruc,cubcorr,chromcorr,rotcorr
; This routine computes three components of aberration correction to
; lambda(x,iord,ifib), based on cubic distortion, lateral chromatic
; aberration, and image rotation.
; Input data are
;   xo = detector x pixel position, in mm, from center of chip
;   specdat = spectrograph structure containing (among other things)
;   .ex0 = amplitude of distortion
;   .ex1 = amplitude of lateral chromatic aberration
;   .ex2 = amplitude of rotation.
;  All of the ex? are scaled so that a value of unity implies a displacement
;  at the edge of the chip of approximately 1 mm.  Thus, one expects their
;  actual values to be considerably smaller than unity. 

; compute the aberration displacement functions
gltype=specstruc.gltype
cubchrom,xo,fibno,lam,gltype,cubcorr,chromcorr,rotcorr

; scale corrections as needed
cubcorr=specstruc.ex0*cubcorr
chromcorr=specstruc.ex1*chromcorr
rotcorr=specstruc.ex2*rotcorr

end 
