pro extract,ierr
; This routine combines the corrected intensity data cordat, variance map
; varmap, order traces, order profiles, and width to yield the
; extracted spectrum data.  
; Where mfib = (number of illuminated fibers), returned arrays are
; exintn(nx,nord,mfib) = intensity integrated across order
; exsig(nx,nord,mfib) = rms uncertainty for extracted spectrum
; exdy(nx,nord,mfib) = displacement (pix) of order from center of extraction box
; exwid(nx,nord,mfib) = rms width of order (pix)
; All inputs and outputs come from and go back to the nres common block;
; outputs are mostly in the structure echdat.
;
; The procedure varies, depending on what kind and quality of data are
; present in the input image:
; If all illuminated fibers are ThAr, or if no illuminated fiber has a median
; signal above a threshold, then the trace positions are taken
; from the identified trace file, without modification.
; If one or more fibers are identified as 'target' or 'flat', and at least one
; has a signal above threshold, then the fiber with the greatest signal
; is used to estimate the mean order shift in the cross-dispersion direction,
; and this shift is applied to the trace positions for all fibers.

; extracta is modified from extract in two ways:
; (1) The position of the extracted cross-dispersion profile is taken to be
; fixed.  Hence cross-dispersion moment mom1 is not used to modify the
; profiles to which spectra are fitted.
; (2) ThAr spectra are extracted with fixed, uniform (in y) profiles expected
; in the cross-dispersion direction.
; Both the traces and the profiles are taken from the selected trace file.

@nres_comm

; constants
nsmsh=15L           ; width of median filter for smoothing yshift relative to 
                   ; extraction boxes
sz=size(cordat)
ny=sz(2)
nx=specdat.nx
nord=specdat.nord
nblock=specdat.nblock
ord_wid=tracedat.ord_wid
cowid=ceil(ord_wid)
if(mfib eq 3) then ordvec=tracedat.ord_vectors
if(mfib eq 2) then begin
  if(fib0 eq 0) then ordvec=tracedat.ord_vectors(*,*,0:1)
  if(fib0 eq 1) then ordvec=tracedat.ord_vectors(*,*,1:2)
endif
;***** put the following stuff in the spectrographs.csv file
gain=1.8        ; CCD gain in e-/ADU
rn=7.           ; read noise in e-
sigc=10.         ; threshold for bad data (cosmics), in sigma

; determine whether to fit for trace cross-disp shift.  If so, which fiber 
; to use to estimate this shift.


; make arrays containing the data from the extraction boxes specified in trace,
; and the variance map in the same boxes.
; also the nominal displacement of the order center from the center of the
; extraction box, and the order rms width
ebox=fltarr(nx,cowid,nord,mfib)
vbox=fltarr(nx,cowid,nord,mfib)
ordbot=round(ordvec-cowid/2.)          ; bottom boundaries of order boxes
ordtop=ordbot+cowid-1                  ; top boundary ditto.

; strip out the desired data
x=lindgen(nx)
for i=0,nord-1 do begin
; include only x values where all fibers are within detector bounds.
; By convention, fiber 0 is at larger y than fiber 1.
  s=where((ordbot(*,i,0) ge 0) and (ordtop(*,i,mfib-1) le (ny-1)),ns)
  if(ns gt 0) then begin
    for j=0,mfib-1 do begin
      for k=0,cowid-1 do begin
        sy=ny*(ordbot(s,i,j)+k) + x(s)
        ebox(s,k,i,j)=cordat(sy)
        vbox(s,k,i,j)=varmap(sy)    ; contains variance from background est.
      endfor
    endfor
  endif
endfor

; do two iterations with raw intensity data, first estimating cross-
; dispersion shifts from moments, then with y-derivative of profile.  
; Then fit for 2nd derivative to allow for width variations, and make
; model profile.  Use residuals to identify likely cosmic rays.
; Last, do the final fit with frozen shifts, width corrections, to estimate 
; profile intnsity.
for iter=0,3 do begin

; make arrays with raw intensity, shift (1st moment) and width (2nd moment)
  yy=rebin(reform((findgen(cowid)-cowid/2.+0.5),1,cowid),nx,cowid)
; yy contains the pixel coords of the centers of pixels
  yy=reform(yy,nx,cowid,1,1)
  yy=rebin(yy,nx,cowid,nord,mfib)
  yy2=yy^2
  mom0=reform(cowid*rebin(ebox,nx,1,nord,mfib),nx,nord,mfib)
  mom1=reform(cowid*rebin(ebox*yy,nx,1,nord,mfib),nx,nord,mfib)
  mom2=reform(cowid*rebin(ebox*yy2,nx,1,nord,mfib),nx,nord,mfib)
  s0=where(mom0 gt 0.,ns0)
  mom1(s0)=mom1(s0)/mom0(s0)
  mom2(s0)=sqrt(mom2(s0)/mom0(s0) > 0.)

; make estimated pixel shift of obsd profile from order center, averaged
; over orders, using only fiber selected above, and only illuminated stellar 
; orders.  A scalar value.
  dymed=dymedian(mom0,mom1)

; make expected fractional pixel shift of profile from order center,
; corrected by dymed
  orddy=ordvec-ordbot-cowid/2.+dymed

; make estimate of cross-dispersion profile, corrected for estimated shifts
; make one such profile per extraction block.  (This is arbitrary, may want
; to change it later).

;; make cross-dispersion profile from tracefile prof array
; first put linear-interpolated shifted obs'd profiles into profall,
; with interpolation weights in wtsfall
  profall=fltarr(nx,cowid+4,nord,mfib)    ; to hold shifted obs'd profiles
  wtsfall=fltarr(nx,cowid+4,nord,mfib)    ; to hold weights for each cowid row

; now average results over x, within blocks.  Add zeros at end of x range
; to make nx divisible by nblock, if needed
  remain=nx mod nblock
  if(remain ne 0) then remain=nblock-remain
  tprof=tracedat.prof
  tprof=transpose(tprof,[3,0,1,2])
  ifbot=fib0
  iftop=fib0+mfib-1
  rprofile=rebin(tprof(*,*,*,ifbot:iftop),nx+remain,cowid,nord,mfib)
  rprofile=rprofile(remain/2:nx+remain/2-1,*,*,*)
           ; contains profiles normalized so that sum over y is unity.

; shift and interpolate profiles across dispersion to make model profiles
; that agree as closely as possible with the order displacements.  Use orddy
; for the displacement estimate, since it is guaranteed to have no oddball
; values resulting from low signal.
  fprofile=rprofile
  sprofile=fltarr(nx,cowid,nord,mfib)
  spwts=fltarr(nx,cowid,nord,mfib)
  ofprofile=fltarr(nx,cowid+4,nord,mfib)        ; interpolate from this array
  ofprofile(*,2:cowid+1,*,*)=fprofile
  ofwts=wtsfall
  for i=0,nord-1 do begin
    for j=0,mfib-1 do begin
      s=where(abs(orddy(*,i,j)) le 2.,ns)        ; expect this to be all points
      tofprofile=ofprofile(*,*,i,j)
      tofwts=ofwts(*,*,i,j)
      iddy=floor(orddy(s,i,j))              ; in range [-2,1]
      sddy=iddy-orddy(s,i,j)               ; in range [0,1]
      for k=0,cowid-1 do begin
        sy=nx*(k+1-iddy(s))+s
        sprofile(s,k,i,j)=tofprofile(sy)*(-sddy) + $
                          tofprofile(sy+nx)*(1.+sddy)
;       spwts(s,k,i,j)=tofwts(sy)*(-sddy) + $
;                      tofwts(sy+nx)*(1.+sddy)
      endfor
    endfor
  endfor
        ; contains variance from background est.

; make cross-dispersion derivatives of profiles
  dfpdy=fltarr(nx,cowid,nord,mfib)
  d2fpdy2=fltarr(nx,cowid,nord,mfib)
  for i=0,nx-1 do begin
    for j=0,nord-1 do begin
      for k=0,mfib-1 do begin
        py=sprofile(i,*,j,k)
        dpydy=deriv(py)
        d2pydy2=deriv(dpydy)
        dfpdy(i,*,j,k)=reform(dpydy,1,cowid)
        d2fpdy2(i,*,j,k)=reform(d2pdy2,1,cowid)
      endfor
    endfor
  endfor

stop

; make optimal extraction weights, but only on the first iteration
  if(iter eq 0) then begin
;   ewts=1./((ebox > 1.)^.65+rn)     ; gain in e-/ADU, rn in e-
    ewts=sprofile^2/(vbox > 1.)      ; optimum a la Horne
;   ewts=fltarr(nx,cowid,nord,mfib)+1. ; try constant weights
;   ewts(*,0,*,*)=0.                   ; don't fit to boundary points in profile
;   ewts(*,cowid-1,*,*)=0.
  endif

  datparms={nx:nx,cowid:cowid,nord:nord,nfib:nfib,mfib:mfib,remain:remain}
  extlstsq,sprofile,dfpdy,d2fpdy2,ebox,vbox,ewts,datparms,exintn,exsig,$
    exdy,excon,exdy2

; subtract profile*intensity from observations, look for high-sigma outliers
; prodc=rebin(reform(excon,nx,1,nord,mfib),nx,cowid,nord,mfib)
  prod0=sprofile*rebin(reform(exintn,nx,1,nord,mfib),nx,cowid,nord,mfib)
  prod1=dfpdy*rebin(reform(exdy,nx,1,nord,mfib),nx,cowid,nord,mfib)*$
          rebin(reform(exintn,nx,1,nord,mfib),nx,cowid,nord,mfib)
  diff=ebox-prod0-prod1
stop
  diffe=ebox(*,1:cowid-2,*,*)                ; ignore outer pix, which get 0 wts
  rms=fltarr(nord,mfib)
  for i=0,nord-1 do begin
    for j=0,mfib-1 do begin
      rms(i,j)=stddev(diffe(*,*,i,j))   ; ignore outer pix, which get 0 wts
      sbad=where(abs(diffe(*,*,i,j)) gt sigc*rms(i,j),nsbad)
; remove these, identified as cosmics, but only for iter=0
      if(nsbad gt 0 and iter eq 0) then begin
; ***** put sigma clipping code here.  Changes values in arrays ebox, vbox
      endif
    endfor
  endfor

; if iter=0, redo optimal extraction weights, 
  if(iter eq 0) then begin
    modlvar=(prod0+prod1)*gain+rn^2
    ewts=sprofile^2/modlvar
;   ewts=1./((ebox > 1.)^.65+rn)
;   wts=fltarr(nx,cowid,nord,mfib)+1. 
;   ewts(*,0,*,*)=0.                   ; don't fit to boundary points in profile
;   ewts(*,cowid-1,*,*)=0.
    if(nsbad gt 0) then ewts(sbad)=0.  ; give no weight to adjusted data points
  endif

; redo the intensity estimates to account for cosmics.
  extlstsq,sprofile,dfpdy,ebox,vbox,ewts,datparms,spectrum,specrms,specdy,specon

endfor

; censor last point in Sinistro data
ix=strpos(camera,'fl')
if(ix eq 0) then spectrum(nx-1,*,*)=spectrum(nx-2,*,*)

; useful values go into common structure echdat, including a lot of
; place-holding nulls, to be filled in by calib_extract.
nelectron=reform(nx*nord*rebin(spectrum,1,1,mfib))
echdat={spectrum:spectrum,specrms:specrms,specdy:specdy,specon:specon,$
    specwid:mom2,$
    diffrms:rms,nx:nx,nord:nord,nfib:nfib,mjd:0.d0,origname:'NULL',$
    nfravg:1L,siteid:'NULL',camera:'NULL',exptime:0.,objects:'NULL',$
    nelectron:nelectron,craybadpix:nsbad}

end
