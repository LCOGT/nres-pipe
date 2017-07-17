function dymedian,inten,dely,cc
; This function accepts inten(nx,nord,nfib) and dely(nx,nord,nfib)
; and uses them to estimate the typical cross-dispersion shift in pixels
; of the intensity distribution, relative to the center of the extraction box.
; Measurements are ignored for fibers that are labeled NONE or THAR, or that
; have interquartile dispersions greater than 1.5 pix.
; The estimate is a vector of length nord, based on a sigma-clipped fit over 
; the apparently good data.
; If no good data are found, the function returns a zero vector.
; The routine also returns array cc(2), which contains the fit coefficients that
; describe the returned linear function.

@nres_comm

; constants
skiplo=0.15               ; skip this fraction of the low-index orders
skiphi=0.85               ; skip beyond this fraction of the high-index orders

; get useful data
objects=strtrim(strupcase(get_words(sxpar(dathdr,'OBJECTS'),nobj,delim='&')),2)
objg=objects(fib0:fib0+mfib-1)
nx=specdat.nx
nord=specdat.nord
cowid=ceil(tracedat.ord_wid)

; select good fiber(s)
s=where(objg ne 'NONE' and objg ne 'THAR',ns)
if(ns eq 0) then goto,bail
intg=inten(*,*,s)
delyg=dely(*,*,s)

; select good orders
jbot=long(nord*skiplo+1)
jtop=long(nord*skiphi)
ngord=jtop-jbot+1

; make a map of good and bad pixels
igood=intarr(nx,nord,ns)+1
igood(*,0:jbot-1,*)=0
igood(*,jtop:nord-1)=0
; loop over orders, looking for terrible data
for i=0,ns-1 do begin
  for j=jbot,jtop do begin
    ; reject points with low intensity relative to rest of order
    di=intg(*,j,i)
    dy=delyg(*,j,i)
    sb=where(di lt 0.1*median(di),nsb)
    if(nsb gt 0) then igood(sb,j,i)=0
; reject points with y displacement > abs(cowid/2)
    sb=where(abs(dy) gt cowid/2.,nsb)
    if(nsb gt 0) then igood(sb,j,i)=0
  endfor
endfor

; fit a linear function of order number to the points that are left
iord0=findgen(nord)-nord/2.
delygr=reform(delyg,nx*nord,ns)
iord=rebin(reform(iord0,1,nord),nx,nord)
funs=fltarr(nx*nord,2)
funs(*,0)=1.
funs(*,1)=reform(iord,nx*nord)
twts=fltarr(ns)                   ; total of wts per fiber
cco=fltarr(2,ns)
nsgt=0
for i=0,ns-1 do begin
  wts=reform(igood(*,*,i),nx*nord)
  cc0=lstsqr(delygr(*,i),funs,wts,2,rms0,chisq0,resid0,1,cov0)
; sigma clip outliers at 4*pseudo-gaussian sigma
  sg=where(wts gt 0.,nsg)
  nsgt=nsgt+nsg
  if(nsg gt 5) then begin
    quartile,resid0(sg),medr,q,dq
    sig=dq/1.35
  endif else goto,bail
  sb=where(wts eq 0. or abs(resid0) ge 5.*sig,nsb)
  wts(sb)=0.
  twts(i)=total(wts)
  cc=lstsqr(delygr(*,i),funs,wts,2,rms,chisq,resid,1,cov)
  cco(*,i)=cc
endfor

wtsa=rebin(reform(twts,1,ns),2,ns)
prod=cco*wtsa
cca=rebin(prod,2,1)/rebin(wtsa,2,1)
if(nsgt gt 100*ns) then dym=cca(0)+cca(1)*iord0 else goto,bail
return,dym    

; 
bail:
dym=fltarr(nord)
cc=[0.,0.]

return,dym

end
