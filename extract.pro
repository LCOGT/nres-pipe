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
; ####### hack for bifurcated fiber
if(mfib eq 1) then begin
  ordvec=tracedat.ord_vectors(*,*,2)
endif
; ###### end hack
britethrsh=nx*nord*200.        ; threshold for dy shift calculation is 200 ADU
                               ; per pixel, on avg.
;***** put the following stuff in the spectrographs.csv file
gain=1.8        ; CCD gain in e-/ADU
rn=7.           ; read noise in e-
sigc=10.         ; threshold for bad data (cosmics), in sigma

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

; determine whether to fit for trace cross-disp shift.  If so, which fiber 
; to use to estimate this shift.
objects=sxpar(dathdr,'OBJECTS')
objs=get_words(objects,nobjs,delim='&')
objs=strtrim(strupcase(objs),2)
sobjg=where(objs ne 'NONE',nobjg)-fib0    ; indices of extractable fibers
                                          ; within array cordat
sbrite=where(objs ne 'THAR' and objs ne 'NONE',nsbr)
ebrite=nx*cowid*nord*reform(rebin(ebox,1,1,1,mfib),mfib)
if(mfib ne nobjg) then begin
  print,'ERROR in extract.pro:  mfib not equal to nobjg'
  stop
endif
if(nsbr eq 0) then begin
  ; get here if there are no fibers suitable for estimating cross-disp shift
  shiftme=0
  ; the fibers to be extracted reside in ebox(*,*,*,sobjg)
endif else begin
  maxe=max(ebrite,ixe)       ; maxe in range [0,mfib-1]
  if(maxe le britethrsh) then begin
    shiftme=0
  endif else begin
    shiftme=1
    sobjg=shift(sobjg,-ixe)
  endelse
endelse

; do two iterations with raw intensity data, first estimating cross-
; dispersion shifts from moments, then with y-derivative of profile.  
; Then fit for 2nd derivative to allow for width variations, and make
; model profile.  Use residuals to identify likely cosmic rays.
; Last, do the final fit with frozen shifts, width corrections, to estimate 
; profile intnsity.

; set up output data arrays,
; loop over fibers, in the order listed in array sobjg.  If the first one,
; and if shiftme=1, then compute an offset in y = dymed to be applied to all 
; fibers and orders.  Otherwise, leave dymed value alone
spectrum=fltarr(nx,nord,mfib)
specrms=fltarr(nx,nord,mfib)
specdy=fltarr(nx,nord,mfib)
specdy2=fltarr(nx,nord,mfib)
specwid=fltarr(nx,nord,mfib)
dymed=0.

for ifib=0,mfib-1 do begin
  jfib=sobjg(ifib)
  ebo=ebox(*,*,*,jfib)
  vbo=vbox(*,*,*,jfib)


; make arrays with raw intensity, shift (1st moment) and width (2nd moment)
  yy=rebin(reform((findgen(cowid)-cowid/2.+0.5),1,cowid),nx,cowid)
; yy contains the pixel coords of the centers of pixels
  yy=reform(yy,nx,cowid,1)
  yy=rebin(yy,nx,cowid,nord)
  yy2=yy^2
  mom0=reform(cowid*rebin(ebo,nx,1,nord),nx,nord)
  mom1=reform(cowid*rebin(ebo*yy,nx,1,nord),nx,nord)
  mom2=reform(cowid*rebin(ebo*yy2,nx,1,nord),nx,nord)
  s0=where(mom0 gt 0.,ns0)
  mom1(s0)=mom1(s0)/mom0(s0)
  mom2(s0)=sqrt(mom2(s0)/mom0(s0) > 0.)

; estimate an order-independent cross-dispersion shift, if 1st fiber
; and shiftme is set
  if(shiftme eq 1 and ifib eq 0) then begin
    dymed=dymedian(mom0,mom1)
  endif

; make expected fractional pixel shift of profile from order center,
; corrected by dymed
  orddy=ordvec(*,*,jfib)-ordbot(*,*,jfib)-cowid/2.+dymed

; make estimate of cross-dispersion profile, corrected for estimated shifts
; make one such profile per extraction block.  (This is arbitrary, may want
; to change it later).

;; make cross-dispersion profile from tracefile prof array
; first put linear-interpolated shifted obs'd profiles into profall,
; with interpolation weights in wtsfall
  profall=fltarr(nx,cowid+4,nord)    ; to hold shifted obs'd profiles
  wtsfall=fltarr(nx,cowid+4,nord)    ; to hold weights for each cowid row

; now average results over x, within blocks.  Add zeros at end of x range
; to make nx divisible by nblock, if needed
  remain=nx mod nblock
  if(remain ne 0) then remain=nblock-remain
  tprof=tracedat.prof
  tprof=transpose(tprof,[3,0,1,2])
  rprofile=rebin(tprof(*,*,*,jfib+fib0),nx+remain,cowid,nord)
  rprofile=rprofile(remain/2:nx+remain/2-1,*,*)
         ; contains profiles normalized so that sum over y is unity.

; shift and interpolate profiles across dispersion to make model profiles
; that agree as closely as possible with the order displacements.  Use orddy
; for the displacement estimate, since it is guaranteed to have no oddball
; values resulting from low signal.
  fprofile=rprofile
  sprofile=fltarr(nx,cowid,nord)
; test
  qsprofile=fltarr(nx,cowid,nord)
  qpprofile=fltarr(nx,cowid,nord)
; end test
  spwts=fltarr(nx,cowid,nord)
  ofprofile=fltarr(nx,cowid+4,nord)        ; interpolate from this array
  ofprofile(*,2:cowid+1,*)=fprofile
  ofwts=wtsfall
  for i=0,nord-1 do begin
    s=where(abs(orddy(*,i)) le 2.,ns)        ; expect this to be all points
    tofprofile=ofprofile(*,*,i)
    tofwts=ofwts(*,*,i)
;   iddy=floor(orddy(s,i))              ; in range [-2,1]
;   sddy=iddy-orddy(s,i)               ; in range [-1,0]
    iddy=floor(orddy(*,i))
    sddy=iddy-orddy(*,i)
    for k=0,cowid-1 do begin
;     sy=nx*(k+1-iddy(s))+s
      sy=nx*(k+1-iddy)+lindgen(nx)
; linear interpolation, involving 2 data points surrounding target
;     sprofile(s,k,i)=tofprofile(sy)*(-sddy) + $   
;                       tofprofile(sy+nx)*(1.+sddy)
; It might be worthwhile to do higher-order interpolation here.
;  Quadratic interpolation
      pddy=sddy+1.                        ; in range [0,1]
      l0m=sddy*(sddy-1.)/2.               ; Lagrange interpolating polynomials
      l1m=-(sddy+1.)*(sddy-1.) 
      l2m=sddy*(sddy+1.)/2.
      l0p=pddy*(pddy-1.)/2.               ; same as above, but shifted 1 pix
      l1p=-(pddy+1.)*(pddy-1.)
      l2p=pddy*(pddy+1)/2.
      summ=tofprofile(sy)*l0m + tofprofile(sy+nx)*l1m + tofprofile(sy+2*nx)*l2m
      sump=tofprofile(sy-nx)*l0p + tofprofile(sy)*l1p + tofprofile(sy+nx)*l2p
      sprofile(*,k,i)=(summ+sump)/2.    ; involves 4 points surrounding target
    
;   if(i eq 38 and ifib eq 0) then stop
 
    endfor
  endfor

; make cross-dispersion derivatives of profiles
  dfpdy=fltarr(nx,cowid,nord)
  d2fpdy2=fltarr(nx,cowid,nord)
  for i=0,nx-1 do begin
    for j=0,nord-1 do begin
        py=reform(sprofile(i,*,j),cowid)
        dpydy=deriv(py)
        d2pydy2=deriv(dpydy)
        dfpdy(i,*,j)=reform(dpydy,1,cowid)
        d2fpdy2(i,*,j)=reform(d2pydy2,1,cowid)
    endfor
  endfor

; make optimal extraction weights
  ewts=sprofile^2/(vbo > 1.)      ; optimum a la Horne

  datparms={nx:nx,cowid:cowid,nord:nord,nfib:nfib,mfib:mfib,remain:remain}
  nfun=3
  ifun=[0,2,3]

  extlstsq,sprofile,dfpdy,d2fpdy2,ebo,vbo,ewts,datparms,nfun,ifun,fitc

; stop

; subtract profile*intensity from observations, look for high-sigma outliers
  prod0=sprofile*rebin(reform(fitc(*,*,0),nx,1,nord),nx,cowid,nord)
  prod2=dfpdy*rebin(reform(fitc(*,*,2),nx,1,nord),nx,cowid,nord)*$
          rebin(reform(fitc(*,*,0),nx,1,nord),nx,cowid,nord)
  prod3=d2fpdy2*rebin(reform(fitc(*,*,3),nx,1,nord),nx,cowid,nord)*$
          rebin(reform(fitc(*,*,0),nx,1,nord),nx,cowid,nord)
  diff=ebo-prod0-prod2-prod3
  diffe=diff(*,1:cowid-2,*)                ; ignore outer pix, which get 0 wts
  rms=fltarr(nord)
; for this next bit to work properly, need to subtract a scaled (by x posn) version
; of the average of diff over x, computed separately for each block, order.
  for i=0,nord-1 do begin
; extend diff array to make its row length divisible by nblock
    diffe=fltarr(nx+remain,cowid)
    diffe(0:nx-1,*)=diff(*,*,i)
    diffe(nx:nx+remain-1,*)=diffe(nx-remain:nx-1,*)

; average over blocks, expand back to extended length, truncate added pixels
    diffes=rebin(diffe,nblock,cowid)      ; diffe smoothed using linear interpolation
    diffes=rebin(diffes,nx+remain,cowid) ; across blocks, by not specifying /samp
    diffs=diffes(0:nx-1,*)

; fit out the cross-disp shape for each x point
    sumd=rebin(diff*diffs,nx,1)    ; project out diffs(x,y) from diff(x,y), for each x
    sumd2=rebin(diffs^2,nx,1)
    ratd=sumd/(sumd2 > 1.)         ; amplitude of local diffs(x,*) in diff(x,*) 

; median-filter result, to suppress outliers
    ratd=smooth(median(ratd,7),5)

; expand this to full cross-dispersion width, subtract it from diff
    difff=diff-diffs*rebin(ratd,nx,cowid)   ; residuals after cross-disp fit

; compute rms by block
    difffe=fltarr(nx+remain,cowid)
    difffe(0:nx-1,*)=difff
    difffe(nx:nx+remain-1,*)=difffe(nx-remain:nx-1,*)
    difffea=rebin(difffe^2,nblock,1)
    rmse=sqrt(rebin(difffea,nx+remain,cowid))
    rms=rmse(0:nx-1,*)

; search for multiple-sigma outliers

    sbad=where(abs(difff) gt sigc*rms,nsbad)
; remove these, identified as cosmics
      if(nsbad gt 0) then begin
; ***** put sigma clipping code here.  Changes values in arrays ebo, vbo
      endif
  endfor
;stop

; This looks like a bad idea in cases where (eg because of saturation) the
; real profile is a poor fit to the parameterized one prod0+prod2+prod3.
; The latter often gives small or negative predicted intensities, hence
; bad variance estimates.  Comment it out, for now.
; if iter=0, redo optimal extraction weights, 
; if(iter eq 0) then begin
;   modlvar=((prod0+prod2+prod3) > 1.)*gain+rn^2
;   ewts=sprofile^2/modlvar
;   if(nsbad gt 0) then ewts(sbad)=0.  ; give no weight to adjusted data points
; endif

; redo the intensity estimates to account for cosmics.
; comment out for now, since we have not yet done anything about cosmics.
; extlstsq,sprofile,dfpdy,d2fpdy2,ebo,vbo,ewts,datparms,nfun,ifun,fitc

; fill in the output arrays for the current fiber
  spectrum(*,*,jfib)=fitc(*,*,0)
  specrms(*,*,jfib)=fitc(*,*,4)
  specdy(*,*,jfib)=fitc(*,*,2)
  specdy2(*,*,jfib)=fitc(*,*,3)
  specwid(*,*,jfib)=mom2

endfor

; censor last point in Sinistro data
ix=strpos(camera,'fl')
if(ix eq 0) then spectrum(nx-1,*,*)=spectrum(nx-2,*,*)

; useful values go into common structure echdat, including a lot of
; place-holding nulls, to be filled in by calib_extract.
nelectron=reform(nx*nord*rebin(spectrum,1,1,mfib))
echdat={spectrum:spectrum,specrms:specrms,specdy:specdy,specdy2:specdy2,$
    specwid:specwid,$
    diffrms:rms,nx:nx,nord:nord,nfib:nfib,mjd:0.d0,origname:'NULL',$
    nfravg:1L,siteid:'NULL',camera:'NULL',exptime:0.,objects:'NULL',$
    nelectron:nelectron,craybadpix:nsbad}

end
