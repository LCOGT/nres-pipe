pro get_plotdat,lamin,spec,range,iord,lam,plt,norm=norm
; This routine accepts
;  lamin(nx,nord) = wavelength array (nm), giving lambda vs pixel and order
;  spec(nx,nord) = extracted flux in ADU corresp to wavelengths in lamin
;   for correct star fiber.
;  range(2) = min, max wavelengths (nm) for which plotting is desired.
;  The routine identifies the order iord for which the largest fraction of
;  the requested wavelength range is present in the data.  Wavelengths and
;  Fluxes in this wavelength range are returned in lam(nlam), plt(nlam).
;  Before return, lam(nlam) is converted to Angstrom units.
;  If keyword norm is set, the output is renormalized so that the 98-percentile
;  point maps to unity.

; constants
ptcut=0

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
    gpix(i)=ns
  endelse
endfor
ngood=max(gpix,iord)
if(ngood le 0) then iord=-1
if(iord lt 0) then goto,fini

; get the desired data
sg1=where(lamin(*,iord) ge range(0) and lamin(*,iord) le range(1),nsg1)
lam=lamin(sg1,iord)*10.                  ; wavelength in AA
plt=spec(sg1,iord)
if(keyword_set(blaze)) then plt=blaz(sg1,iord)
if(keyword_set(extrac)) then plt=extr(sg1,iord)

; for now, never do blaze removal
; normalize if needed
;if(not keyword_set(noblaze)) then begin
;  contnorm,plt,pltnorm,contout
;  plt=pltnorm
;endif
; subtract coeff * flat if sub keyword set
if(keyword_set(sub)) then begin
  sg0=where(flat(*,iord) gt 0.,nsg0)
  if(nsg0 gt 0) then begin
    sg2=sg(nsg/3:2*nsg/3)
; estimate leastsq fit to central 1/3 of order
    
    scut=where(gg ge ptile(gg,ptcut),nscut)
    if(nscut gt 10) then begin
      num1=total(spec(scut,iord)*flat(scut,iord))
      den1=total(flat(scut,iord)^2)
      amp=num1/(den1 > 1.)
      plt=plt-amp*flat(*,iord)
    endif
  endif
endif

;stop

; normalize again (to unity) if norm keyword set
if(keyword_set(norm)) then begin
  so=sort(plt)
  nplt=n_elements(plt)
  pmax=plt(so(0.98*nplt))
  plt=plt/pmax
endif

fini:
end
