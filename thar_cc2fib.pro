pro thar_cc2fib,filin,nb,nx,nord,dx,ccamp
; This routine reads a calibrated DOUBLE ThAr spectrum from filin.
; It then cross-correlates the two fibers for each of nb segments of each
; order, and returns the shifts between the spectra in array dx(nb,nord).
; A positive shift means that lines in fiber n+1 fall at larger x values
; than the same lines in fiber n.
; The x-dimension and number of orders in the input image are returned 
; in nx, nord.
; The maximum amplitude of the cross-correlation is returned in array ccamp.

!except=2
; constants
smwid=51                 ; lowpass filter width
ccwid=50                 ; compute cc for +/- this width

; get the data
dd=readfits(filin,hdr)
sz=size(dd)
nx=sz(1)
nord=sz(2)
nfib=sz(3)
if(nfib ne 2) then begin
  print,'Must have exactly 2 fibers'
  stop
endif

ncc=2*ccwid+1
cc=fltarr(ncc)

; set up the output array
dx=fltarr(nord,nb)
ccamp=fltarr(nord,nb)

; loop over orders, blocks
for i=0,nord-1 do begin
  for j=0,nb-1 do begin
    xbot=j*nx/nb
    xtop=(j+1)*nx/nb-1
    d0=dd(xbot:xtop,i,0)
    d1=dd(xbot:xtop,i,1)
    npt=xtop-xbot+1

; get rid of saturated columns
    sb0=where(d0 gt 3.e5,nsb0)
    ibad=fltarr(npt)
    if(nsb0 gt 0) then begin
      ibad(sb0)=1.
      ibad=dilate(ibad,[1,1,1,1,1]) 
      d0=d0*(1.-ibad)
    endif

    sb1=where(d1 gt 3.e5,nsb1)
    ibad=fltarr(npt)
    if(nsb1 gt 0) then begin
      ibad(sb1)=1.
      ibad=dilate(ibad,[1,1,1,1,1]) 
      d1=d1*(1.-ibad)
    endif

; compute the cross correlations
    d0s=smooth(smooth(d0,51),51)
    d0d=d0-d0s
    d0e=fltarr(npt+2*ccwid)          ; embed d0d in this array
    d0e(ccwid:ccwid+npt-1)=d0d
    d1s=smooth(smooth(d1,51),51)
    d1d=d1-d1s
    d1e=fltarr(npt+2*ccwid)
    d1e(ccwid:ccwid+npt-1)=d1d

    for k=0,2*ccwid do begin
      sh=ccwid-k
      cc(k)=total(d0e*shift(d1e,sh))
    endfor
      
      
; find the peak
    mp=max(cc,ix)
    ix=(ix > 1) < (ncc-2)
    num=-0.5*(cc(ix+1)-cc(ix-1))
    den=cc(ix+1)+cc(ix-1)-2.*cc(ix)
    if(den ne 0.) then ds=num/den else ds=0.
;   ds=-0.5*(cc(ix+1)-cc(ix-1))/(cc(ix+1)+cc(ix-1)-2.*cc(ix))
    dx(i,j)=ix+ds-ccwid
    ccamp(i,j)=mp

  endfor
endfor

end
