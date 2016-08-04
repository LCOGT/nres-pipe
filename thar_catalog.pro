pro thar_catalog,tharin,thrsh,gsw,iord,xpos,amp,wid,xposg,ampg,widg,chi2g,ierr
; This routine accepts a ThAr spectrum tharin(nx,nord).
; It searches each order for significant lines, and lists the positions
; order number iord, pixel position xpos along with estimates of the
; amplitude amp (in ADU) and the FWHM wid (in pixels).
; If input parameter gsw ne 0,
; line parameters xposg,widg,ampg,chi2g are also returned, giving results
; of a gaussian fit to the 9 points centered on the line.
; Gain is assumed to be 2 e-/ADU, and lines are taken to be real if their
; peak height above background exceeds thrsh*photon noise, and if the 
; intensity decreases for at least 2 pixels in both directions from the
; maximum.
; For a normal return, ierr=0.  Otherwise indicates a fatal error.

; constants
qhwid=50                ; estimate background from +/- qhwid box
gain=2.0                ; arbitrary reciprocal gain e-/ADU
wconst=2.*sqrt(2.*alog(2.))     ; constant for computing FWHM

; get sizes of things
sz=size(tharin)
nx=sz(1)
nord=sz(2)

; make output arrays
iord=[0]
xpos=[0.]
amp=[0.]
wid=[0.]
xposg=[0.d0]    ; line params from gaussian fitting
ampg=[0.]
widg=[0.]
chi2g=[0.]
ierr=0

; loop over orders
for ior=0,nord-1 do begin
  tt=smooth(smooth(tharin(*,ior),3),3)           ; noise suppression
  sm2=shift(tt,-2)
  sm1=shift(tt,-1)
  sp1=shift(tt,1)
  sp2=shift(tt,2)

; search for local maxima
  sm=where((tt gt sm1) and (tt gt sp1) and (sm1 gt sm2) and (sp1 gt sp2),nsm)
  if(nsm gt 0) then begin

; estimate noise --  first, one number for the entire order
  mtt=median(tt,qhwid)
  dtt=tt-mtt
  quartile,dtt,med,q,dq
  noisec=dq/1.35           ; estimate of gaussian sigma from interquartile range

; now make a position-dependent noise model, limited below by noisec.
; discard bottom and top 10 percent, make difference with running median,
; square the result, smooth it.
  so=sort(tt)
  zmin=tt(so(0.05*nx))
  zmax=tt(so(0.95*nx))
  zc=(tt > zmin) < zmax  ; smoothed data clipped at 5th and 95th percentiles
  zcm=median(zc,qhwid)
  zd2=(zc-zcm)^2
  zd2s=smooth(smooth(zd2,qhwid),qhwid)
  znoi=sqrt(zd2s > 0.) > noisec

; loop over possible peaks
    for i=0,nsm-1 do begin
      ix=sm(i)
      if(ix gt 1 and ix le (nx-2)) then begin

      ibot=(ix-qhwid) > 0
      itop=(ix+qhwid) < (nx-1)
      quartile,tt(ibot:itop),med,q,dq
      backg=q(0)                      ; take low quartile point as bkgnd
      sig=(tt(ix)-backg)
      noise=median(znoi(ibot:itop))
      if(sig/noise gt thrsh) then begin    ; seek statistically significant ones
; compute line params from central 3 points
        iord=[iord,ior]
        ds=-0.5*(tt(ix+1)-tt(ix-1))/(tt(ix-1)+tt(ix+1)-2.*tt(ix))
        xpos=[xpos,float(ix)+ds]
        cwid=2*sqrt((tt(ix)-backg)/(2.*tt(ix)-tt(ix-1)-tt(ix+1)))
        wid=[wid,cwid]
        amp=[amp,sig*cwid]

; fit a gaussian to each line, if gsw ne 0
        if(gsw ne 0) then begin
          ibotg=(ix-4) > 0
          itopg=(ix+4) < (nx-1)
          nsampg=itopg-ibotg+1
          ffg=dindgen(nsampg)-(ix-ibotg)
          ggg=tt(ibotg:itopg)
          estim=[tt(ix),double(ds),cwid]
          merrg=sqrt(noise+ggg)
          hhg=gaussfit(ffg,ggg,aag,nterms=3,estim=estim,measure_errors=merrg,$
              chisq=chisq)
          ampg=[ampg,1.2*aag(0)*aag(2)*sqrt(!pi)]  ; factor of 1.2 makes ampg
                                                   ; agree with amp
          widg=[widg,2.*aag(2)*1.056]              ; factor of 1.056 gives 
                                                   ; measured FWHM
          xposg=[xposg,ix+aag(1)]
          chi2g=[chi2g,chisq]
        endif else begin
          ampg=[ampg,0.]
          widg=[widg,0.]
          xposg=[xposg,0.]
          chi2g=[chi2g,0.]
        endelse

      endif
      endif
    endfor
  endif
endfor

np=n_elements(iord)
if(np gt 20) then begin     ; check for a bare minimum number of peaks
  iord=iord(1:*)
  xpos=xpos(1:*)
  amp=amp(1:*)
  wid=wid(1:*)
  xposg=xposg(1:*)
  ampg=ampg(1:*)
  widg=widg(1:*)
  chi2g=chi2g(1:*)
endif else begin
  ierr=1
endelse

end
