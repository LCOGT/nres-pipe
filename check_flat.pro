function check_flat,flat
; This function accepts a ***master flat***,
; ie, an extracted flat-field array flat(nx,nord,nfib) intended to have valid
; data for all of its 'fiber' planes.
; It performs various checks on this array to verify that it contains
; sensible flat-field data for all fibers.
; It returns 1 if all of the checks pass.
; It returns 0 if any check fails.
; The checks are:
; (a) Fail if any (iord,ifib) has max(abs(deriv(flat(*,i,j))))=0.
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

; look for zero derivative in any (order, fiber)
for i=0,nfib-1 do begin
  for j=0,nord-1 do begin
    if(max(abs(deriv(flat(*,j,i)))) eq 0.) then begin
      good=0
      goto,fini
    endif
  endfor
endfor

; look for large mean(abs(deriv))
mad=fltarr(nord,nfib)
for i=0,nfib-1 do begin
  for j=ordmin,ordmax do begin
    mad(j,i)=mean(abs(deriv(flat(*,j,i))))
  endfor
endfor

sb=where(mad ge thrsh,nsb)
if(nsb gt nbad) then good=0

; look for values ge 2. in flat(1,*,*)
sb=where(flat(1,*,*) ge 2.0,nsb)
if(nsb gt nbad) then good=0

; look for fraction of values > 0.985 greater than 0.05
sbig=where(flat ge 0.985,nsbig)
if(nsbig gt 0.05) then good=0

fini:
return,good

end
    
