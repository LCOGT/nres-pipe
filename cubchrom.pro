pro cubchrom,xo,fibno,lam,gltype,cubcorr,chromcorr,rotcorr
; This routine computes the wavelength corrections dlam in nm corresponding
; to pure cubic distortion (cubcorr(xxe,iord))
; and to lateral chromatic aberration (chromcorr(xxe,iord)).
; These are scaled to correspond at most to 1pm of wavelength displacement
; of image points relative to the gaussian optics approximation, typically at
;  the detector corners.

@nres_comm
pixsiz=0.015                 ; pixel size in mm
scale=0.001/[.250,1.6e-4,5.6e-3]  ; scaling factors for cubcorr, 
                                  ; chromcor, rotcorr

; get sizes of things
sz=size(lam)
nx=sz(1)
nord=sz(2)

; make coord arrays
xx=xo

ordvec=tracedat.ord_vectors(*,*,fibno)
; ordvec is not extended in the x dimension as all the other arrays are,
; so build an extended version by quadratic extrapolation at both ends.
sz1=size(ordvec)
nxs=sz1(1)
dn=(nx-nxs)/2               ; number of extension pixels on each end
ove=fltarr(nx,nord)
ove(dn:dn+nxs-1,*)=ordvec
if(dn gt 0) then begin
  xtmp=findgen(2*dn)-dn
  for i=0,nord-1 do begin
    ytmpl=ove(0:2*dn-1,i)
    ytmph=ove(nx-2*dn:nx-1,i)
    ccl=poly_fit(xtmp(dn:*),ytmpl(dn:*),2)
    otmpl=poly(xtmp,ccl)
    ove(0:dn-1,i)=otmpl(0:dn-1)
    cch=poly_fit(xtmp(0:dn-1),ytmph(0:dn-1),2)
    otmph=poly(xtmp,cch)
    ove(nx-dn:nx-1,i)=otmph(dn:*)
  endfor
endif

yy=(ove-nx/2)*pixsiz        ; nx here is standing in for ny

; yy now accounting for rotation or curvature of orders.
;yy=rebin(reform(y0m,1,nord),nx,nord)
rr2=xx^2+yy^2            ; radius^2 in mm^2
rr2max=max(rr2)

; dispersion
dlamdx=dblarr(nx,nord)
for i=0,nord-1 do begin
  dlamdx(*,i)=deriv(lam(*,i))/deriv(xx(*,i))    ; lam shift per mm in x
endfor

; refractive index
glass_index,gltype,lam/1000.,nn
; find lamcen = index at point closest to detector center
mrr=min(rr2,ixcen)
lamcen=lam(ixcen)
nncen=nn(ixcen)

; cubic contribution
cubcorr=scale(0)*rr2*xx*dlamdx/(rr2max^1.5)

; lateral chromatic correction
chromcorr=scale(1)*(nn-nncen)*dlamdx*xx/rr2max

; chip rotation
rotcorr=scale(2)*yy*dlamdx/rr2max

end 
