pro pflat2d,datin,datout,xfn,yfn
; This routine flattens the 2D array datin, assuming that this array
; is represented (within small errors) as a product of a function of
; x and a function of y.  It averages over x to obtain the y function,
; normalizes this out, averages what remains over y to obtain the x
; function, averages that out, and returns the ratio (1. + residuals)
; in array datout.  The normalizing functions used are returned in xfn, yfn.

; get size
sz=size(datin)
nx=sz(1)
ny=sz(2)

; ratio out the y variation
dax=rebin(datin,1,ny)
yfn=reform(dax,ny)
dax=rebin(dax,nx,ny)
r1=datin/dax

; do same for x variation
day=rebin(r1,nx,1)
xfn=reform(day)
day=rebin(day,nx,ny)
datout=r1/day

end
