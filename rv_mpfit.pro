function rv_mpfit,parms
; This routine generates a model spectrum block modl using parameters
; in input array parms.  It computes the chi^2 components from data contained
; in the common data area, and returns the sqrt of these components.

common rv_lsq,lambl,zbl,dbl

; unpack parms
rr=parms(0)
aa=parms(1)
bb=parms(2)

; model on modified wavelength grid
lamr=lambl/(1.d0+rr)
zblr=interpol(zbl,lambl,lamr,/lsquadratic)

; scale the result
npt=n_elements(lambl)
xx=dindgen(npt)-npt/2.
xx=xx/max(abs(xx))          ; Leg1 function
zblr=zblr*(aa+bb*xx)

; make normalized difference, using noise=sqrt(signal)
dif=(dbl-zblr)/sqrt(dbl > 1.)

; truncate 1st and last 5 points, to avoid errors from interpolating off
; the range of valid values.
dif=dif(5:npt-6)

return,dif

end
