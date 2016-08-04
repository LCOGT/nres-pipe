pro uniqixg,ixg,ixl,lamg,lamlist,ixu,ixlu,tdif
; This routine accepts
; It returns tdif(ixu), where ixu is the list of unique indices in ixg,
; and for each ixu value, tdif is the smallest (in magnitude) difference 
; lamg(ixg)-lamlist(ixl),
; among all ixg entries having that value of ixu.
; ixlu contains the index from ixl corresponding to the smallest difference.

; determine unique ixg values
so=sort(ixg)
ixgs=ixg(so)
ixui=uniq(ixgs)
ixu=ixgs(ixui)
nxu=n_elements(ixu)

; brute force check each value for multiplicity.  Compute desired wavelength
; difference(s).  Pick the smallest abs value whether single or multiple.
tdif=dblarr(nxu)
adif=dblarr(nxu)
ixlu=lonarr(nxu)
for i=0,nxu-1 do begin
  si=where(ixg eq ixu(i),nsi)
  ddif=lamg(ixg(si))-lamlist(ixl(si))
  adif(i)=min(abs(ddif),im)
  tdif(i)=ddif(im)
  ixlu(i)=ixl(si(im))
endfor

end
