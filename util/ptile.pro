function ptile,dat,ptl
; This routine accepts an array dat and a desired percentile 0 < ptl < 100.
; It returns the value of the dat array that occupies the ptl-th percentile.

npt=n_elements(dat)
so=sort(dat)
ptc=0. < ptl < 100.
iso=dat(so((npt-1)*ptl/100.))
return,iso

end
