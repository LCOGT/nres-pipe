pro backsub,dat,ovec,owid,nfib,nwid,objs
; This routine accepts the data array dat(nx,ny),
; ovec(nx,nord,nfib), the order width owid, and the number of active
; fibers nfib.
; It creates a copy of dat, with pixels lying within active orders
; replaced by NaN.
; It then rebins the dat array by a factor of 4 in each dimension (for speed),
; median-filters the result with a box of nwid x nwid pixels,
; expands the result to nx x ny, and subtracts the result from dat.
; A modified dat array is returned.
; ***Note*** The dimensions of dat must both be divisible by 4!

; get sizes of things
sz=size(dat)
nx=sz(1)
ny=sz(2)
sz=size(ovec)
nord=sz(2)

; make coord arrays
y=rebin(reform(findgen(ny),1,ny),nx,ny)
cowid=ceil(owid)
xx=rebin(lindgen(nx),nx,cowid)

; lay NaN stripes onto dat array
t=dat
objcs=get_words(objs,nwds,delim='&')
objcs=strtrim(strupcase(objcs),2)
for i=0,nord-1 do begin
  for j=0,nfib-1 do begin
; ignore fibers that are not illuminated
  if(objcs(j) eq 'NONE' or objcs(j) eq 'NULL') then goto,skipfib
;     compute the order indices by hand
    ybot=long(ovec(*,i,j)-owid/2.)
    yy=rebin(ybot,nx,cowid)
    yinc=rebin(reform(lindgen(cowid),1,cowid),nx,cowid)
    ytot=yy+yinc
    s=reform(xx+ny*ytot,nx*cowid)
;     make sure they are all legal
    sgood=where((s ge 0) and (s lt nx*ny),nsgood)
    if(nsgood gt 0) then t(s)=!values.f_nan
  skipfib:
  endfor
endfor

; compress, embed in larger array, median filter, expand
tc=rebin(t,nx/4,ny/4)
nx=nx/4
ny=ny/4

larger=cowid > nwid
nxtra=long(larger+1)     ; make oversize array
tco=fltarr(nx+2*nxtra,ny+2*nxtra)
tco(nxtra:nx+nxtra-1,nxtra:ny+nxtra-1)=tc   ; put data array in center
; fill in the sides
tco(0:nxtra-1,nxtra:ny+nxtra-1)=tc(0:nxtra-1,*)
tco(nx+nxtra:nx+2*nxtra-1,nxtra:ny+nxtra-1)=tc(nx-nxtra:nx-1,*)
tco(nxtra:nx+nxtra-1,0:nxtra-1)=tc(*,0:nxtra-1)
tco(nxtra:nx+nxtra-1,ny+nxtra-1:ny+2*nxtra-1)=tc(*,ny-nxtra-1:ny-1)
; fill in the corners
tco(0:nxtra-1,0:nxtra-1)=tc(0:nxtra-1,0:nxtra-1)
tco(nx+nxtra:nx+2*nxtra-1,0:nxtra-1)=tc(nx-nxtra:nx-1,0:nxtra-1)
tco(0:nxtra-1,ny+nxtra-1:ny+2*nxtra-1)=tc(0:nxtra-1,ny-nxtra-1:ny-1)
tco(nx+nxtra:nx+2*nxtra-1,ny+nxtra-1:ny+2*nxtra-1)=tc(nx-nxtra:nx-1,ny-nxtra-1:ny-1)

; median filter, extract original array from oversize one
tcof=median(tco,nwid)        ; note this treats NaNs as missing data

; try to make 1st quartile, sort of
;st=where(tco gt tcof,nst)
;tco1=tco
;if(nst gt 0) then tco1(st)=!values.f_nan
;tcog=median(tco1,nwid)

;stop

tcf=tcof(nxtra:nx+nxtra-1,nxtra:ny+nxtra-1)
;tcf=tcog(nxtra:nx+nxtra-1,nxtra:ny+nxtra-1)
nx=4*nx
ny=4*ny

backg=rebin(tcf,nx,ny)

; check for NaN results, set them to median of a bounding box
s=where(~finite(backg),ns)
if(ns gt 0) then begin
  sy=long(s/nx)   ; y coords of bad points
  sx=s-nx*sy      ; x coords ditto
  xbot=(min(sx)-50) > 0
  xtop=(max(sx)+50) < (nx-1)
  ybot=(min(sy)-50) > 0
  ytop=(max(sy)+50) < (ny-1)
  mbb=median(backg(xbot:xtop,ybot:ytop))
  if(finite(mbb)) then backg(s)=mbb else backg(s)=10.    ; moves of desperation
  print,'xran, yran = ',xbot,xtop,ybot,ytop
  print,'mbb = ',mbb
endif

dat=dat-backg

; check results for non-finite entries
s=where(~finite(dat),ns)
if(ns gt 0) then begin
  print,'Non-finite results in backsub.  Fatal error.'
  ;stop
endif

end
