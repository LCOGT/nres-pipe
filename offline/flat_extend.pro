pro flat_extend,flatin,flatout
; This routine extrapolates the flat-field profiles found
; in FLAT file flatin to cover 68 orders, rather than the current 67.
; Results are written to FITS file flatout.
; Method is to interpolate the flatin data from order 65 (better noise than
; order 66) onto the x range extrapolated to order 67.

; constants
xbot=880.
xtop=3600.
xbot65=730.
xtop65=3720.

; read input
dd=readfits(flatin,hdr)          ; flatin must be a full pathname
sz=size(dd)
nx=sz(1)
nord=sz(2)
nfib=sz(3)

; create output array
dout=fltarr(nx,nord+1,nfib)

; extrapolate flat profile from order 65
uu=reform(dd(xbot65:xtop65,65,*))
nuu=xtop65-xbot65+1
nout=xtop-xbot+1
xx65=findgen(nuu)
xout=findgen(nout)*float(nuu)/float(nout)
dout=fltarr(nx,nord+1,nfib)
dout(*,0:66,*)=dd
for ifib=0,nfib-1 do begin
  dat=smooth(smooth(uu(*,ifib),3),3)
  dout(xbot:xtop,67,ifib)=reform(interpol(dat,xx65,xout),nout,1,1)
endfor

; massage the header
hdrout=hdr
sxaddpar,hdrout,'NAXIS2',nord+1
sxaddpar,hdrout,'NORD',nord+1

; write out the results
writefits,flatout,dout,hdrout

stop

end
