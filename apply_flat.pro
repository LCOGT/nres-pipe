pro apply_flat,flat
; This routine divides the extracted spectrum by the current flatfield
; (both found in the nres common block) and places results back in common
; as corspec(nx,nord,mfib) = corrected spectrum vs x for each order, fiber.
;    rmsspec(nx,nord,mfib) = formal rms of corspec

@nres_comm
flcutoff=0.1     ; set output to zero for pixels where value of flat is
                 ; plausibly smaller than this.

nx=specdat.nx
nord=specdat.nord

; make output arrays
corspec=fltarr(nx,nord,mfib)
rmsspec=fltarr(nx,nord,mfib)

flate=flat(*,*,fib0:fib0+mfib-1)  ; select only part of flat with illum fibers

; select only pixels for which no pixel farther from the nearest edge
; has a flat value below flcutoff
indx=lindgen(nx)
corspec=echdat.spectrum
rmsspec=echdat.specrms
for i=0,mfib-1 do begin
  for j=0,nord-1 do begin
    sb0l=where(flate(*,j,i) lt flcutoff and indx le nx/2,nsbl)
    sb0r=where(flate(*,j,i) le flcutoff and indx gt nx/2,nsbr)
    if(nsbl gt 0) then ixl=max(indx(sb0l))+1 else ixl=0
    if(nsbr gt 0) then ixr=min(indx(sb0r))-1 else ixr=nx-1
    sg=where(indx ge ixl and indx le ixr,nsg)
    sb=where(indx lt ixl or indx gt ixr,nsb)
    if(nsg gt 0) then begin
      corspec(sg,j,i)=corspec(sg,j,i)/flate(sg,j,i)
      rmsspec(sg,j,i)=rmsspec(sg,j,i)/flate(sg,j,i)
    endif
    if(nsb gt 0) then begin
      corspec(sb,j,i)=0.
      rmsspec(sb,j,i)=1.e6
    endif
  endfor
endfor

end
