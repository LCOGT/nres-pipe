pro trace_extend,tracein,traceout
; This routine extrapolates the polynomial coefficients and profiles found
; in TRACE file tracein to cover 68 orders, rather than the current 67.
; Results are written to FITS file traceout.

; read input
dd=readfits(tracein,hdr)          ; tracein must be a full pathname
sz=size(dd)
npolymax=sz(1)
nord=sz(2)
nfib=sz(3)
nblockp=sz(4)
npoly=sxpar(hdr,'NPOLY')

; create output array
dout=fltarr(npolymax,nord+1,nfib,nblockp)

; copy profiles from order 66, without changing anything
dout(*,nord,*,1:nblockp-1)=dd(*,nord-1,*,1:nblockp-1)

; copy profiles from orders 0-66 also
dout(*,0:nord-1,*,1:nblockp-1)=dd(*,0:nord-1,*,1:nblockp-1)

; copy the polynomial coefficients for orders 0-nord-1
dout(*,0:nord-1,*,0)=dd(*,0:nord-1,*,0)

; extrapolate the polynomial coeffs.  Note that the values for order 66 look
; inconsistent with other orders, so do the extrapolation from fits spanning
; the orders (nord-16:nord-2).

xx=-7.+findgen(15)             ; centered range used in order number
xxo=[9]
funs=fltarr(15,3)
for i=0,npolymax-1 do begin
  for jfib=0,nfib-1 do begin
    dat=reform(dd(i,nord-16:nord-2,jfib,0))
    cc=poly_fit(xx,dat,2)
    yy=poly(xxo,cc)
    dout(i,nord,jfib,0)=yy[0]
  endfor
endfor
    
; massage the header
hdrout=hdr
sxaddpar,hdrout,'NAXIS2',nord+1
sxaddpar,hdrout,'NORD',nord+1

; write out the results
writefits,traceout,dout,hdrout

end
