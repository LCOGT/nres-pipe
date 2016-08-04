pro lineseg,lam,lindx,lparm
; This routine takes a vector of wavelengths lam of nw lines.
; It returns arrays containing the characteristics of all np=nw*(nw-1)/2 
; pairs of lines, namely
; lindx(2,np) = indices of the component lines in the original line list
; lparm(0,np) = average wavelengths (lam(i)+lam(j))/2. of the 2 component lines
; lparm(1,np) = abs difference wavelength abs(lam(j) - lam(i)) between 
;    the 2 lines.

nw=n_elements(lam)
np=long(nw)*long(nw-1)/2L

if(np ge 1) then begin
  lindx=lonarr(2,np)
  lparm=fltarr(2,np)

; do the work
  ii=0L
  for i=0L,nw-1 do begin
    for j=i+1L,nw-1 do begin
      lindx(0,ii)=i
      lindx(1,ii)=j
      lparm(0,ii)=(lam(j)+lam(i))/2.
      lparm(1,ii)=abs(lam(j)-lam(i))
      ii=ii+1
    endfor
  endfor
endif else begin
  lindx=[[-1,-1]]
  lparm=[[-1.,-1.]]
endelse


end
