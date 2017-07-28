pro trace_refine,tracein,flatin1,flatin2,nleg=nleg,dely=dely
; This routine accepts the name of a trace file found in tracedir,
; and uses it to extract profiles for all orders and fibers from the
; input files flatin1 and, optionally, flatin2.
; These should be raw tungsten-halogen flats.  If the trace covers only 2 fibers,
; then only flatin1 is required.  If 3 fibers, then
; flatin1 should contain data for fibers [0,1], and flatin2 for [1,2]
; The routine creates an improved trace file by iteratively computing
; cross-dispersion 1st moments of the flat orders, and fitting adjustments
; to the trace file polynomial coefficients to minimize the rms difference
; between predicted and observed order center positions.
; The resulting trace file is written to tracedir, and a line describing
; it is added to csv/standards.csv.
; Results are packed into array tracprof
; which is dimensioned tracprof(nc,nord,nfib,nblock+1)
; where nc is (cowid > nleg).
; tracprof(0:nleg-1,*,*,0) contains trace legendre coeffs trace1(nleg,nord,nfib)
; tracprof(0:cowid-1,*,*,1:nblock) contains cross-dispersion profile functions
;  prof1(cowid,nord,nfib,nblock)
; For fibers that are not illuminated (as indicated by fib0,fib1, and the
; number of input files), all corresponding tracprof values are set to zero.
; If keyword nleg is set, its value becomes the new number of legendre
; polynomials used to describe the order positions.  If not, the value
; in the input trace file is used.
; If keyword dely is set, the input trace file is modified to shift the
; orders upwards (to larger y) by an amount equal to dely pixels.
; This shift is independent of x, order number, and fiber.

@nres_comm

jdc=systime(/julian)
mjdc=jdc-2400000.5d0

itermax=10
sig0=10.                ; guess at read noise in e- per pixel.
minamp=20.              ; min allowed amplitude of block-avgd cross-disp prof

; how many images are input?
ninfil=n_params()-1

; set up needed directories, constants in common
verbose=1                         ; 0=print nothing; 1=dataflow tracking

nresroot=getenv('NRESROOT')
; normally don't expect nres_comm to be populated before this routine is called
nresrooti=nresroot+getenv('NRESINST')
biasdir='reduced/bias/'
darkdir='reduced/dark/'
specdir='reduced/spec/'
diagdir='reduced/diag/'
csvdir='reduced/csv/'
flatdir='reduced/flat/'
tracedir='reduced/trace/'
filin0=tracein

; read the input trace file, unpack it, stick needed stuff into common
tracefil=nresrooti+tracedir+tracein
tracea=readfits(tracefil,tracehdr,/silent)
nx=sxpar(tracehdr,'NX')
; set nx for size of arrays with overscan trimmed off
if(nx eq 2080L) then nx=2048

nfib=sxpar(tracehdr,'NFIB')
nord=sxpar(tracehdr,'NORD')
npoly=sxpar(tracehdr,'NPOLY')
if(keyword_set(nleg)) then nleg=nleg else nleg=npoly
ord_wid=sxpar(tracehdr,'ORDWIDTH')
medboxsz=sxpar(tracehdr,'MEDBOXSZ')
site=strupcase(sxpar(tracehdr,'SITEID'))
camera=sxpar(tracehdr,'INSTRUME')
cowid=sxpar(tracehdr,'COWID')
nblock=sxpar(tracehdr,'NBLOCK')
sig=sig0*sqrt(cowid)     ; expected read noise per ebox x-position
fib0=sxpar(tracehdr,'FIB0')
fib1=sxpar(tracehdr,'FIB1')

trace=reform(tracea(0:npoly-1,*,*,0))

if(keyword_set(dely)) then trace(0,*,*)=trace(0,*,*)+dely

prof=tracea(0:cowid-1,*,*,1:*)

;if(nfib ne (ninfil+1)) then begin
;  print,'NFIB and number of input files do not agree'
;  stop
;end

; Are there dark fibers?  Happens iff nfib=3 and nfilin=1
if(nfib eq 3 and ninfil eq 1) then begin
  if(fib0 eq 0) then zdark=2 else zdark=0
endif else begin
  zdark=-1                  ; indicates no dark fibers
endelse

; read the input image file(s) main data segment
imagein1=getenv('NRESRAWDAT')+flatin1
dat1=readfits(imagein1,hdr1,/silent)

; trim data array if necessary
sz=size(dat1)
if(sz(1) gt 4096 or sz(2) gt 4096) then dat1=dat1(0:4095,0:4095)

site1=strupcase(strtrim(sxpar(hdr1,'SITEID'),2))
camera1=strtrim(sxpar(hdr1,'INSTRUME'),2)
if(strtrim(site1,2) ne strtrim(site,2) or strtrim(camera1,2) $
     ne strtrim(camera,2)) then begin
  print,'Input files site or camera does not agree.  Fatal Error'
  stop
  goto,fini
endif
mjdd=sxpar(hdr1,'MJD-OBS')
jdd=mjdc+2400000.5d0
exptime1=sxpar(hdr1,'EXPTIME')

; get bias and dark for this file
get_calib,'BIAS',biasfile,bias,biashdr,gerr
errsum=gerr
get_calib,'DARK',darkfile,dark,darkhdr,gerr
errsum=errsum+gerr
if(errsum gt 0) then begin
    print,'Failed to locate calibration file(s) in trace_refine.  FATAL error'
  stop
  goto,fini
endif

; bias and dark subtract the data file, trim overscan if necessary
cordat=dat1-bias
cordat=cordat-exptime1*dark
sz=size(cordat)
if(sz(1) eq 2080) then cordat=cordat(0:2047,*)
ny=sz(2)

; subtract the background
order_cen,trace,ord_vectors
objs=sxpar(hdr1,'OBJECTS')
; if they are not set, put in defaults for ord_wid and nfib
if(ord_wid eq 0.) then ord_wid=10.5
if(nfib eq 0) then nfib=3
if(medboxsz eq 0) then medboxsz=23
;backsub,cordat,ord_vectors,ord_wid,nfib,medboxsz,objs

; if there are 2 input files, read and process the 2nd one
if(ninfil eq 2) then begin
  imagein2=getenv('NRESRAWDAT')+flatin2
  dat2=readfits(imagein2,hdr2,/silent)

; trim dat2 if necessary
  sz=size(dat2)
  if(sz(1) gt 4096 or sz(2) gt 4096) then dat2=dat2(0:4095,0:4095)

  exptime2=sxpar(hdr2,'EXPTIME')
; assume same site, camera, differnet exposure time.  Ignore change in MJD.
  cordat2=dat2-bias
  cordat2=cordat2-exptime2*dark
  if(sz(1) eq 2080) then cordat2=cordat2(0:2047,*)
; backsub,cordat2,ord_vectors,ord_wid,nfib,medboxsz
endif

; iterate on: extract orders & y displacements, fit new order posns,
; modify trace array.  Quit when total of y displacement rms stops changing
; adjust number of poly coeffs if necessary
if(nleg eq npoly) then trace1=trace
if(nleg gt npoly) then begin
  trace1=fltarr(nleg,nord,nfib)
  trace1(0:npoly-1,*,*)=trace
endif
if(nleg lt npoly) then begin
  trace1=trace(0:npoly-1,*,*)
endif

tdy=1.e9                              ; total rms y displacement
for iter=0,itermax do begin

  ordbot=round(ord_vectors-cowid/2.)     ; bottom boundaries of order boxes
  ordbota=ordbot
  orddy=ord_vectors-ordbot-cowid/2.
  ordtop=ordbot+cowid-1                  ; top boundary ditto.

; strip out the desired data
; ebox1, ebox2 are extraction boxes to contain intensities at all x, y, orders,
; fibers for input file 1 (ebox1) and file 2 (ebox2). 
; if ninfil=1, then ebox2 is never used.
  ebox1=fltarr(nx,cowid,nord,nfib)
  ebox2=fltarr(nx,cowid,nord,nfib)
  x=lindgen(nx)
  for i=0,nord-1 do begin
; include only x values where all fibers are within detector bounds.
; By convention, fiber 0 is at larger y than fiber 1.
    s=where(((ordbot(*,i,nfib-1)) ge 0) and (ordtop(*,i,0) le (ny-1)),ns)
    if(ns gt 0) then begin
      for j=0,nfib-1 do begin
        if(j ne zdark) then begin
          for k=0,cowid-1 do begin
            sy=ny*(ordbot(s,i,j)+k) + x(s)
            ebox1(s,k,i,j)=cordat(sy)
            if(ninfil eq 2) then ebox2(s,k,i,j)=cordat2(sy)
          endfor
        endif
      endfor
    endif
  endfor

; compute moments
  yy=rebin(reform((findgen(cowid)-(cowid-1)/2.),1,cowid),nx,cowid)
  yy=reform(yy,nx,cowid,1,1)
  yy=rebin(yy,nx,cowid,nord,nfib)
  wtsm=fltarr(nx,nord,nfib)     ; weights applied to moments
  wtss=fltarr(nx,nord,nfib)     ; weights applied to shifts
  mom01=reform(cowid*rebin(ebox1,nx,1,nord,nfib),nx,nord,nfib)
  mom11=reform(cowid*rebin(ebox1*yy,nx,1,nord,nfib),nx,nord,nfib)
  if(ninfil eq 2) then begin
    mom02=reform(cowid*rebin(ebox2,nx,1,nord,nfib),nx,nord,nfib)
    mom12=reform(cowid*rebin(ebox2*yy,nx,1,nord,nfib),nx,nord,nfib)
    mom01(*,*,2)=0.01
    mom11(*,*,2)=0.       ; suppress input on dark fibers.
    mom02(*,*,0)=0.01
    mom12(*,*,0)=0.
; merge moments.  Dark fibers come in at a negligible level
    mom0=mom01+mom02
    mom1=mom11+mom12
  endif else begin
    mom0=mom01
    mom1=mom11
  endelse

; reject weak mom0 points, compute shifts, reject bad shifts, make wts for the rest
  s0=where(mom0 le 5.*sig,ns0)         ; sig is read noise summed across ebox
  s1=where(mom0 gt 5.*sig,ns1)
  if(ns1 gt 0) then wtss(s1)=sqrt(mom0(s1))       ; pay more attention to edges
                                 ; than an honest optimum weighting indicates
  if(ns1 gt 0) then mom1(s1)=mom1(s1)/mom0(s1)
  if(ns0 gt 0) then mom1(s0)=0.
  s2=where(abs(mom1) gt cowid/2.,ns2)
  if(ns2 gt 0) then begin
    wtss(s2)=0.
    sp=where(mom1 gt cowid/2.,nsp)
    if(nsp gt 0) then mom1(sp)=cowid/2.
    sm=where(mom1 lt (-cowid/2.),nsm)
    if(nsm gt 0) then mom1(sm)=(-cowid/2.)
  endif

; make output array, legendre polynomials
;trace1=fltarr(nleg,nord,nfib)
;trace1(0:npoly-1,*,*)=trace
  rmsa=fltarr(nord,nfib)
; if(ninfil eq 2) then begin
;   trace2=fltarr(nleg,nord,nfib)
;   trace2(0:npoly-1,*,1:2)=trace(0:npoly-1,*,1:2)
; endif
  xx=2.*(findgen(nx)/nx-0.5)
  legs=fltarr(nx,nleg)
  for i=0,nleg-1 do begin
    legs(*,i)=legendre(xx,i)
  endfor

; fit mom1 to legendre polynomials.
; Notice default IDL legendre polys are normalized so that values at +/- 1.
; are unity (modulo a minus sign), and moreover there may be missing data.
; Thus, use weighted least-squares fits, not orthonormality relations.
  for i=0,nord-1 do begin
    for j=0,nfib-1 do begin
      if(j ne zdark) then begin
        if(max(abs(mom1(*,i,j))) eq 0.) then stop
        cc=lstsqr(mom1(*,i,j),legs,wtss(*,i,j),nleg,rms,chisq,outp,1,cov)
      if(j eq 0 and i eq 25) then print,cc
        trace1(*,i,j)=trace1(*,i,j)+cc
        rmsa(i,j)=rms
      endif
    endfor
  endfor

; print rms deviation
  trms=total(abs(rmsa(0:nord-3,*)))
  print,'total rms =',trms
  if(iter ge 3 and (trms gt tdy or abs(tdy-trms) le .01)) then goto,done
  tdy=trms
  
; make new ord_vectors, except for last iter
  if(iter ne itermax) then order_cen,trace1,ord_vectors

endfor      ; end iteration

done:

;fib0=0
;fib1=1

; interpolate and scrunch values in ebox1, ebox2 to yield estimates of
; cross-dispersion profiles, on a per-block basis.
ordbot=round(ord_vectors-cowid/2.)
dy=ord_vectors(*,*,0:nfib-1)-cowid/2.-ordbot(*,*,0:nfib-1)  ; in range [-.5,.5]
dyr=rebin(reform(dy,nx,1,nord,nfib),nx,cowid,nord,nfib)
sp=where(dyr ge 0.,nsp)
sm=where(dyr lt 0.,nsm)
ebox1e=fltarr(nx,cowid+2,nord,nfib)
if(ninfil eq 2) then ebox2e=fltarr(nx,cowid+2,nord,nfib)
ebox1e(*,1:cowid,*,*)=ebox1
if(ninfil eq 2) then ebox2e(*,1:cowid,*,*)=ebox2

; set up subarrays to facilitate interpolation
ebox1em=ebox1e(*,0:cowid-1,*,*)
ebox1e0=ebox1e(*,1:cowid,*,*)
ebox1ep=ebox1e(*,2:cowid+1,*,*)
if(ninfil eq 2) then begin
  ebox2em=ebox2e(*,0:cowid-1,*,*)
  ebox2e0=ebox2e(*,1:cowid,*,*)
  ebox2ep=ebox2e(*,2:cowid+1,*,*)
endif

ebox1i=fltarr(nx,cowid,nord,nfib)
ebox2i=fltarr(nx,cowid,nord,nfib)
if(nsm gt 0) then ebox1i(sm)=ebox1em(sm)*(-dyr(sm))+ebox1e0(sm)*(1.+dyr(sm))
if(nsp gt 0) then ebox1i(sp)=ebox1e0(sp)*(1.-dyr(sp))+ebox1ep(sp)*dyr(sp)
if(ninfil eq 2) then begin
  if(nsm gt 0) then ebox2i(sm)=ebox2em(sm)*(-dyr(sm))+$
                     ebox2e0(sm)*(1.+dyr(sm))
  if(nsp gt 0) then ebox2i(sp)=ebox2e0(sp)*(1.-dyr(sp))+$
                     ebox2ep(sp)*(dyr(sp))
endif
;ebox1i=ebox1e(*,1:cowid,*,*)*(1.-dyr) + ebox1e(*,2:cowid+1,*,*)*dyr
;if(ninfil eq 2) then ebox2i=ebox2e(*,1:cowid,*,*)*(1.-dyr) + $ 
;   ebox2e(*,2:cowid+1,*,*)*dyr

; sum the valid fibers of ebox1i and ebox2i
eboxsi=fltarr(nx,cowid,nord,nfib)
eboxsi(*,*,*,0:1)=ebox1i(*,*,*,0:1)
if(ninfil eq 2) then eboxsi(*,*,*,1:2)=eboxsi(*,*,*,1:2)+ebox2i(*,*,*,1:2)
if(ninfil eq 1 and nfib eq 3 and fib0 eq 1) then $
                     eboxsi(*,*,*,2)=ebox1i(*,*,*,2)

; embed eboxsi in an array with 1st dimension divisible by nblock
rem=nx mod nblock
if(rem eq 0) then begin
  eboxse=eboxsi
endif else begin
  dshft=nblock-rem
  eboxse=fltarr(nx+dshft,cowid,nord,nfib)
  eboxse(dshft/2:dshft/2+nx-1,*,*,*)=eboxsi
endelse

; average over x within each block
prof0=rebin(eboxse,nblock,cowid,nord,nfib)

; replace low-signal profiles with the ones from brighter adjoining blocks.
profmax=max(prof0,dimension=2)    ; peak amplitude of profile for each block,
                                  ; order, fiber
bmid=nblock/2                 ; index of central block
for i=0,nord-1 do begin
  for j=0,nfib-1 do begin
    if(j ne zdark) then begin
      sg=where(profmax(*,i,j) ge minamp,nsg)   ; blocks with acceptable ampl
        if(nsg le 0) then begin
;         print,'No good profiles in order ',i,' fiber ',j,'  Fatal Error'
          print,'No good profiles in order ',i,' fiber ',j,'  Importing prof0.'
          prof0(*,*,i,j)=prof0(*,*,i-1,j)   ; get a profile from previous order
          goto,skipit
        endif
      lsg=min(sg)
      rsg=max(sg)
      sb=where(profmax(*,i,j) lt minamp,nsb)   ; not acceptable
      if(nsb gt 0) then begin
        for k=0,nsb-1 do begin
          if(sb(k) lt bmid) then begin 
            prof0(sb(k),*,i,j)=prof0(lsg,*,i,j)
          endif else begin
            prof0(sb(k),*,i,j)=prof0(rsg,*,i,j)
          endelse
        endfor
      endif
    endif
    skipit:
  endfor
endfor

; normalize cross-dispersion profiles so they sum to unity
prof0s=cowid*rebin(prof0,nblock,1,nord,nfib)
prof0s=rebin(prof0s,nblock,cowid,nord,nfib)
prof1=prof0/(prof0s > 1.)
prof1=transpose(prof1,[1,2,3,0])

; make the tracprof array, which is dimensioned tracprof(nc,nord,nfib,nblock+1)
; where nc is (cowid > nleg).
; tracprof(0:nleg-1,*,*,0) contains trace legendre coeffs trace1(nleg,nord,nfib)
; tracprof(0:cowid-1,*,*,1:nblock-1) contains cross-dispersion profile functions
;  prof1(cowid,nord,nfib,nblock) 
nc=cowid > nleg
tracprof=fltarr(nc,nord,nfib,nblock+1)
tracprof(0:nleg-1,*,*,0)=trace1
tracprof(0:cowid-1,*,*,1:*)=prof1

; write out the new trace array
jd=systime(/julian)      ; file creation time, for sorting similar trace files
;mjd=jd-2400000.5d0
datereald=date_conv(jdd,'R')
datestrd=string(datereald,format='(f13.5)')
strput,datestrd,'00',0
datestrd=strtrim(strlowcase(site),2)+strtrim(datestrd,2)
fout='TRAC'+datestrd+'.fits'
filout=nresrooti+tracedir+fout

mkhdr,hdr,tracprof
sxaddpar,hdr,'NX',nx
sxaddpar,hdr,'NFIB',nfib
sxaddpar,hdr,'NPOLY',nleg
sxaddpar,hdr,'NORD',nord
sxaddpar,hdr,'FIB0',fib0
sxaddpar,hdr,'FIB1',fib1
sxaddpar,hdr,'ORDWIDTH',ord_wid
sxaddpar,hdr,'MJD-OBS',mjdd,'Data date'
sxaddpar,hdr,'MJDC',mjdc,'Creation date'
sxaddpar,hdr,'FILE_IN',strtrim(flatin1,2)
sxaddpar,hdr,'MEDBOXSZ',medboxsz
sxaddpar,hdr,'SITEID',site
sxaddpar,hdr,'INSTRUME',camera
sxaddpar,hdr,'COWID',cowid
sxaddpar,hdr,'NBLOCK',nblock
writefits,filout,tracprof,hdr

flags='0010'
if(nfib eq 2) then flags='0020'
if(nfib eq 3) then flags='0030'
stds_addline,'TRACE','trace/'+fout,1,strtrim(site,2),strtrim(camera,2),jd,flags

stop

fini:
end
