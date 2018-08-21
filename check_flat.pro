function check_flat,flat,hdr
; This function accepts a ***master flat***, and its fits header hdr,
; ie, an extracted flat-field array flat(nx,nord,nfib) intended to have valid
; data for all of its 'fiber' planes that do not correspond to object='none'.
; It performs various checks on this array to verify that it contains
; sensible flat-field data for all fibers that should be illuminated.
; It returns 1 if all of the checks pass.
; It returns 0 if any check fails.
; The checks are:
; (a) Fail if any (iord,ifib) has max(abs(deriv(flat(*,i,j))))=0.
;     for fibers that do not have object(ifib)='none'
;     This traps cases with all values = 0. or 1., for any fiber, order.
; (b) Fail if for 2 or more orders within (15 le iord le 55), 
;     mean(abs(deriv(flat(*,iord,ifib))) ge 0.02
;     This is intended to trap highly-variable flats arising from bad traces.
; (c) Fail if max(flat(1,*,*)) > 2.
; (d) Fail if the number of  pixels with value > 0.985 exceeds 0.05 

good=1                ; presume innocence
thrsh=0.02            ; mean abs(deriv) may not be larger than this.
nbad=2                ; max allowed number of orders with bad mean deriv
ordmin=15
ordmax=55             ; check derivatives only in this range

; get sizes of things
sz=size(flat)
nx=sz(1)
nord=sz(2)
nfib=sz(3)

; identify fibers with valid data
fibgood=[1L,1L,1L]
objects=get_words(sxpar(hdr,'OBJECTS'),delim='&')
sbad=where(strpos(objects,'none') ge 0,nsbad)
if(nsbad gt 0) then fibgood(sbad)=0L
sgood=where(fibgood eq 1,nsgood)
if(nsgood le 0) then begin
  good=0
  goto,fini          ; bail out if no good object fibers
endif

; look for zero derivative in any (order, good fiber)
for i=0,nsgood-1 do begin
  ii=sgood(i)
  for j=0,nord-1 do begin
    if(max(abs(deriv(flat(*,j,ii)))) eq 0.) then begin
      good=-1
      goto,fini
    endif
  endfor
endfor

; look for large mean(abs(deriv))
mad=fltarr(nord,nsgood)
for i=0,nsgood-1 do begin
  ii=sgood(i)
  for j=ordmin,ordmax do begin
    mad(j,i)=mean(abs(deriv(flat(*,j,ii))))
  endfor
endfor

sb=where(mad ge thrsh,nsb)
if(nsb gt nbad) then good=-2

; look for values ge 2. in flat(1,*,sgood)
; This catches big spikes near x=0 in averaged spectra (cause unknown)
sb=where(flat(1,*,sgood) ge 2.0,nsb)
if(nsb gt nbad) then good=-3

; look for fraction of values > 0.985 greater than 0.05
sbig=where(flat(*,*,sgood) ge 0.985,nsbig)
if(float(nsbig)/n_elements(flat(*,*,sgood)) gt 0.1) then good=-4

fini:
return,good

end
