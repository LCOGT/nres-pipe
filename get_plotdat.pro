pro get_plotdat,lamin,spec,range,iord,lam,plt,noblaze=noblaze
; This routine accepts
;  lamin(nx,nord) = wavelength array (nm), giving lambda vs pixel and order
;  spec(nx,nord) = extracted flux in ADU corredp to wavelengths in lamin
;  range(2) = min, max wavelengths (nm) for which plotting is desired.
;  The routine identifies the order iord for which the largest fraction of
;  the requested wavelength range is present in the data.  Wavelengths and
;  Fluxes in this wavelength range are returned in lam(nlam), plt(nlam).
;  Before return, lam(nlam) is converted to Angstrom units.
;  Unless keyword noblaze is set, plt is normalized to remove the blaze
;  function.

; scan lamin to find desired order.  Technique is to count the pixels in
; each order that are within required lambda range, and for which spec > 0.
iord=-1                       ; if not changed, indicates failure
sz=size(lamin)
nx=sz(1)
nord=sz(2)
gpix=lonarr(nord)
for i=0,nord-1 do begin
  if(lamin(0,i) gt range(1) or lamin(nx-1,i) lt range(0)) then begin
    gpix(i)=0
  endif else begin
    sg=where(lamin(*,i) ge range(0) and lamin(*,i) le range(1) $
            and spec(*,i) gt 0.,ns)
    gpix=ns
  endelse
endfor
ngood=max(gpix,iord)
if(ngood le 0) then iord=-1
if(iord lt 0) then goto,fini

; get the desired data
lam=lamin(s,iord)*10.                  ; wavelength in AA
plt=spec(s,iord)

; normalize if needed
if(not keyword_set(noblaze)) then begin
  contnorm,plt,pltnorm,contout
  plt=pltnorm
endif

fini:
end
