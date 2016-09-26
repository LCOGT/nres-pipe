function dymedian,inten,dely
; This function accepts inten(nx,nord,nfib) and dely(nx,nord,nfib)
; and uses them to estimate the typical cross-dispersion shift in pixels
; of the intensity distribution, relative to the center of the extraction box.
; Measurements are ignored for fibers that are labeled NONE or THAR, or that
; have interquartile dispersions greater than 1.5 pix.
; The estimate is a median over presumed good data.
; If no good data are found, the function returns zero.

@nres_comm

; constants
skiplo=0.15               ; skip this fraction of the low-index orders
skiphi=0.85               ; skip this fraction of the high-index orders

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

; compute the median of what is left
sg=where(igood eq 1,nsg)
if(nsg gt 100) then dym=median(delyg(sg)) else goto,bail
return,dym    

; 
bail:
dym=0.
return,dym

end
