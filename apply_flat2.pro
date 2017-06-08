pro apply_flat2,flat
; This routine fits the extracted spectrum with the current flatfield
; order by order, and subtracts a suitably scaled version of the flat
; from the data, provided that the fiber concerned is not of type 'thar'.
; It also divides the extracted spectrum by the current flatfield (including
; thar fibers)
; both spectrum and flat are found in the nres common block. 
; It then places results back in common
; as corspec(nx,nord,mfib) = flat-divided spectrum vs x for each order, fiber.
;    rmsspec(nx,nord,mfib) = formal rms of corspec
;    blazspec(nx,nord,mfib) = flat-subtracted spectrum vs x per order, fiber
;    extrspec(nx,nord,mfib) = extracted spectrum vs x per order, fiber
;    rmsblaz(nx,nord,mfib) = formal rms of blazspec, extrspec
; the coefficients of flats subtracted from blazspec are stored in array
;    ampflat, in nres_common

@nres_comm
flcutoff=0.1     ; set output to zero for pixels where value of flat is
                 ; plausibly smaller than this.
ptcut=0         ; percentile to use to make blazspec

nx=specdat.nx
nord=specdat.nord
objs=get_words(objects,delim='&')
objs=strtrim(strupcase(objs),2)

; make output arrays
corspec=fltarr(nx,nord,mfib)
rmsspec=fltarr(nx,nord,mfib)
extrspec=fltarr(nx,nord,mfib)
blazspec=fltarr(nx,nord,mfib)
rmsblaz=fltarr(nx,nord,mfib)

flate=flat(*,*,fib0:fib0+mfib-1)  ; select only part of flat with illum fibers

; select only pixels for which no pixel farther from the nearest edge
; has a flat value below flcutoff
indx=lindgen(nx)
rawspec=echdat.spectrum
rmsspec=echdat.specrms
ampflat=fltarr(nord,mfib)

for i=0,mfib-1 do begin
  if(objs(i+fib0) ne 'THAR' and objs(i+fib0) ne 'NULL') then begin
  for j=0,nord-1 do begin
    lamwts=badlamwts(*,j,i)
    sb0l=where(flate(*,j,i) lt flcutoff and indx le nx/2,nsbl)
    sb0r=where(flate(*,j,i) le flcutoff and indx gt nx/2,nsbr)
    if(nsbl gt 0) then ixl=max(indx(sb0l))+1 else ixl=0
    if(nsbr gt 0) then ixr=min(indx(sb0r))-1 else ixr=nx-1
    sg0=where(indx ge ixl and indx le ixr,nsg0)
    sgp=where(indx ge ixl and indx le ixr and lamwts eq 1,nsgp) ; pure sgood
    sb0=where(indx lt ixl or indx gt ixr,nsb0)
    sbp=where(indx lt ixl or indx gt ixr or lamwts eq 0,nbsp)  ; pure sbad
    if(nsgp gt 0) then sg=sgp
    if(nsgp eq 0 and nsg0 gt 0) then sg=sg0
    nsg=n_elements(sg) 
    ibad=lonarr(nx)+1
    ibad(sg)=0
    sb=where(ibad eq 1,nsb)
    if(nsg gt 0) then begin
; first make extracted spectrum, set to zero for points where no good flat
; exists.
    extrspec(sg0,j,i)=rawspec(sg0,j,i)
; then make blaze-subtracted spectrum, fitting only
; the brightest (100-ptcut) percent of the central 1/2 of the spectrum,
; weighted by badlamwts. If nothing is left, use the whole order.
; **************
    sg2=sg(nsg/4:3*nsg/4)
    gg=rawspec(sg2,j,i)
    ff=flate(sg2,j,i)
    scut=where(gg ge ptile(gg,ptcut),nscut)
    if(nscut gt 10) then begin
      num0=total(gg(scut)*ff(scut))
      den0=total(ff(scut)^2)
      amp=num0/(den0 > 1.)
; estimate least-sq fit to entire order
      hh=rawspec(*,j,i)-amp*flate(*,j,i)
      ampflat(j,i)=amp

;     if(nscut gt 10) then begin
;       num1=total(rawspec(scut,j,i)*flate(scut,j,i))
;       ;en1=total(flate(scut,j,i)*2)
;       amp=num1/(den1 > 1.)
;       ampflat(j,i)=amp
;       hh=rawspec(*,j,i)-amp*flate(*,j,i)
    endif else begin
      ampflat(j,i)=0.
      hh=fltarr(nx)
    endelse
      
      blazspec(sg0,j,i)=hh(sg0)
      rmsblaz(sg0,j,i)=rmsspec(sg0,j,i)

; make the ratio rawspec/flat, set to zero for bad data points
      corspec(sg,j,i)=rawspec(sg,j,i)/flate(sg,j,i)
      rmsspec(sg,j,i)=rmsspec(sg,j,i)/flate(sg,j,i)
    endif
    if(nsb gt 0) then begin
;     blazspec(sb,j,i)=0.
;     rmsblaz(sb,j,i)=1.e6
      corspec(sb,j,i)=0.
      rmsspec(sb,j,i)=1.e6
    endif
  endfor
  endif else begin
    if(objs(i+fib0) eq 'THAR') then begin
      extrspec(*,*,i)=rawspec(*,*,i)
      blazspec(*,*,i)=rawspec(*,*,i)
      corspec(*,*,i)=rawspec(*,*,i)/(flate(*,*,i) > 0.1)
      rmsblaz(*,*,i)=rmsspec(*,*,i)
      rmsspec(*,*,i)=rmsspec(*,*,i)/(flate(*,*,i) > 0.1)
    endif
  endelse
endfor

end
