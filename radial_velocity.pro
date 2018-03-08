pro radial_velocity,ierr,nostar=nostar
; This routine computes radial velocity values based on wavelength-calibrated
; ZERO and current-spectrum data (both star and ThAr) stored in common 
; structure rvindat.
; meta- and ancillary data are returned in the common
; structure rvred, and the rv values and some metadata are written to a
; FITS binary table in directory reduce/rv
; If keyword nostar is set, the routine does a minimal setup of common
; variables, to keep subsequent diagnostic routines happy.

@nres_comm

@thar_comm                   ; include this for diagnostics of ThAr fit

; constants
null=-99.9
ierr=0
mgbordsedge=20               ; order containing Mg b lines for SQA
mgbordnres=38                ; order containing Mg b lines for NRES SGs
c=299792.458d0               ; light speed in km/s
rutname='radial_velocity'

; Call rv_setup to
; get data for fibers 0 & 2. Analyze them only if targnames not 'NULL'
rv_setup,ierr
targnames=[rvindat.targstrucs[0].targname,rvindat.targstrucs[1].targname]
targra=[rvindat.targstrucs[0].ra,rvindat.targstrucs[1].ra]
targdec=[rvindat.targstrucs[0].dec,rvindat.targstrucs[1].dec]
obsmjd=sxpar(dathdr,'MJD-OBS')
baryshifts=rvindat.baryshifts        ;  r = z-1 elements for fibers 0,2
rrts=rvindat.zerorrt      ; ZERO net (baryc + intrinsic) redshift

; if(keyword_set(nostar)) then goto,skipall

; get useful metadata, make output arrays
nx=specdat.nx
nblock=specdat.nblock
nextend=nblock-(nx mod nblock)   ; need to extend nx by this to be exact 
                                 ; multiple of nblock
nxe=nx+ nextend                  ; length of extended-in-x arrays
nord=specdat.nord
mlambot=min(matchlam_c)
mlamtop=max(matchlam_c)
mlamran=mlamtop-mlambot
; set range of allowed wavelengths for block fits
tharmatchmin=mlambot+0.05*mlamran
tharmatchmax=mlamtop-0.05*mlamran

if(strupcase(strtrim(site,2)) eq 'SQA') then mgbord=mgbordsedge $
          else mgbord=mgbordnres
redshifts=dblarr(5,nord)     ; parameterized redshift fits to cross-corr
qcrv=fltarr(6,nord,nfib-1)            ; per order and fiber QC data
rvresid=fltarr(specdat.nblock,nord,nfib-1)

; build arrays of input data to make processing of 2 fibers straightforward
; in these arrays, the 3rd index runs over star fibers only -- no ThAr.
zspec=rvindat.zstar
thspec=rvindat.zthar             ; use this only for line-shape estimates
zlam=rvindat.zlam                ; wavelength scale for star zero spectra
zeronames=rvindat.zeronames      ; names of ZERO files used
sspec=fltarr(nx,nord,nfib-1)
slam=dblarr(nx,nord,nfib-1)
if(nfib eq 2) then begin
  sspec(*,*,0)=blazspec(*,*,1)
  slam(*,*,0)=tharred.lam(*,*,1)
endif
if(nfib eq 3) then begin
  if(mfib eq 3) then begin       ; do this if all 3 fibers are illuminated
    sspec(*,*,0)=blazspec(*,*,0)
    sspec(*,*,1)=blazspec(*,*,2)
    slam(*,*,0)=tharred.lam(*,*,0)
    slam(*,*,1)=tharred.lam(*,*,2)
  endif
  if(mfib eq 2) then begin      ; do this if 3 fibers, but only 2 illuminated
    if(fib0 eq 0) then begin    ; implies fiber 2 is dark
      sspec(*,*,0)=blazspec(*,*,0)
      slam(*,*,0)=tharred.lam(*,*,0)
    endif
    if(fib0 eq 1) then begin    ; implies fiber 0 is dark
      sspec(*,*,1)=blazspec(*,*,1)
      slam(*,*,1)=tharred.lam(*,*,2)
    endif
  endif
endif

; make output arrays to be written to csv file
rcco=dblarr(2)    ; cross-correl redshift, no barycorr or zero intrinsic v
rvvo=fltarr(2)    ; same as rcco, but in km/s units
rvcco=dblarr(2)   ; cross-correl redshift in km/s, corrected for baryshifts
                  ; and for ZERO bary- and intrinsic shifts
widcco=fltarr(2)  ; cross-correl fwhm (km/s)
ampcco=fltarr(2)  ; cross-correl height (max possible = 1)
bjdo=dblarr(2)    ; exposure center barycen date
rroa=dblarr(2)    ; avg blockfit redshift
rrom=dblarr(2)    ; median blockfit redshift
rroe=dblarr(2)    ; formal error in rroa

; make output arrays for RV results
rro=dblarr(2,nord,nblock)  ; redshift vs fiber, order, block
aao=dblarr(2,nord,nblock)  ; scale factor ditto
bbo=dblarr(2,nord,nblock)  ; Legendre 1 scale factor ditto
erro=dblarr(2,nord,nblock) ; formal uncertainty in rro (redshift units)
eaao=dblarr(2,nord,nblock) ; formal uncertainty in aao
ebbo=dblarr(2,nord,nblock) ; formal uncertainty in bbo
pldpo=dblarr(2,nord,nblock)  ; photon-limited doppler precision (km/s)
    
; make output arrays for cross-correlation results
ccmo=fltarr(2,801)  ; cross-correl fn, vs velocity shift
delvo=fltarr(2,801) ; indep var for ccmo, spans +/- 400 km/s
rvvo=fltarr(2)      ; same as rcco, but in km/s units

; make rvred output structure, in case keyword nostar is set
rvred={rroa:rroa,rrom:rrom,rroe:rroe,rro:rro,erro:erro,aao:aao,eaao:eaao,$
       bbo:bbo,ebbo:ebbo,pldpo:pldpo,ccmo:ccmo,delvo:delvo,rvvo:rvvo,$
       rcco:rcco,ampcco:ampcco,widcco:widcco,barycorr:baryshifts,$
       rvcco:rvcco}
centtimes=expmred.expfwt
bjdtdb_c=expmred.expfwt              ; ***temporary hack***

if(keyword_set(nostar)) then goto,skipall
       
; loop over star fibers.  Skip if target is NULL
for i=0,1 do begin
  if(targnames(i) ne 'NULL') then begin

; Guess redshift needed to superpose ZERO and target spectrum.
; Do this by interpolating ZERO onto constant-velocity-increment grid,
; cross-correlating order that has Mg b lines
    stardat=sspec(*,mgbord,i)
    starlam=slam(*,mgbord,i)
    zerodat=zspec(*,mgbord,i)     ; this assumes the star and ZERO spectra
                              ; are of the same format, but with separate
                              ; values of mgbord, this need not be true. 
    zerolam=zlam(*,mgbord,i)
    
    mgbcc,zerolam,zerodat,starlam,stardat,rcc,ampcc,widcc,ccm,delv,rvv
    rcco(i)=rcc                   ; no correction for baryshifts at this point
    ampcco(i)=ampcc
    widcco(i)=widcc
    bjdo(i)=sxpar(dathdr,'MJD-OBS')+2400000.5d0
    ccmo(i,*)=ccm
    delvo(i,*)=delv         ; x-coord vector for ccmo, in km/s
    rvvo(i)=rvv             ; shift of cross-correl peak, in km/s (no BC corr)
; rv in km/s, corrected for everything
    rvcco(i)=c*((1.d0+rcc)*(1.d0+baryshifts(i))-1.d0)

    zdatnew=fltarr(nx,nord)

    for j=0,nord-1 do begin

; interpolate ZERO spectrum to grid appropriate to obsrvations
      zlamj=zlam(*,j,i)*(1.d0+rcc)      ; compensate for redshift estimated
                                        ; by mgbcc.
;     ZERO data interpolated from its rest frame to moving frame, star image
;     lambda grid.
;     This is the predicted observed data, based on calculated baryshifts
;     and the remaining velocity shift measured by mgbcc.

      zdatnew(*,j)=interpol(zspec(*,j,i),zlamj,slam(*,j,i),/lsquadratic)

      sdat=smooth(smooth(smooth(sspec(*,j,i),3),3),3)  ; lowpassed obs data

      blen=long(nx/nblock)           ; number of pix in a block
      bbot=long(findgen(nblock)*(nx/float(nblock)))  ; block starting pix
      btop=bbot+blen-1

; for each block:
      for k=0,nblock-1 do begin
        zblock=zdatnew(bbot(k):btop(k),j)
        dblock=sdat(bbot(k):btop(k))
        lamblock=slam(bbot(k):btop(k),j,i)    ; block nominal wavelength grid
        nblko=n_elements(dblock)
        modelo=dblarr(nblko)
        resido=dblarr(nblko)

; check that dblock, zblock contain data that make sense.  
; If not, bail on this block
; numbers relating to spectrum intensities
        dbmean=mean(dblock)
        dbstdv=stddev(dblock)
        quartile,dblock,dbmed,q,dq
        zbmean=mean(zblock)
; numbers relating to wavelenfths.  do not bother with blocks that fall
; outside the range of wavelengths for which there are matched ThAr lines.
        blammin=min(lamblock)
        blammax=max(lamblock)
; these tests give bogus answers for BLAZ data.
        if(max(abs(dbmean)) eq 0. or max(abs(zbmean)) eq 0. or $
        blammin le tharmatchmin or blammax ge tharmatchmax) then begin 
          cov0=dblarr(3,3)
          blockparms={rr:0.d0,aa:0.d0,bb:0.d0,pldp:0.d0,cov:cov0,$
            modelo:modelo,resido:resido}
;         if(j eq 38) then stop
          goto,bail
        endif

; fit redshift and continuum normalization.
       blockfit2,lamblock,zblock,dblock,blockparms
      
; end blocks loop
      bail:
      rro(i,j,k)=blockparms.rr/(1.d0+baryshifts(i)-rrts(i))  ; correct 
                                 ; for baryshift, zbaryshift, zero rv
      aao(i,j,k)=blockparms.aa
      bbo(i,j,k)=blockparms.bb
      erro(i,j,k)=sqrt(blockparms.cov(0,0) > 0.)
      eaao(i,j,k)=sqrt(blockparms.cov(1,1) > 0.)
      ebbo(i,j,k)=sqrt(blockparms.cov(2,2) > 0.)
      pldpo(i,j,k)=blockparms.pldp

      endfor

; end loop over orders
    endfor

; Do robust average of redshift over blocks.  Estimate avg, uncertainty.
    rrot=rro(i,*,*)
    errot=erro(i,*,*)
    sz=where((rrot ne 0.) and (errot ne 0.),nsz)
    if(nsz ne 0) then begin
      rrotg=rrot(sz)
      errotg=errot(sz)
      quartile,rrotg,medro,qro,dqro
      dif=rrotg-medro
      sg=where(abs(dif) le 4.*dqro/1.35,nsg)
      if(nsg gt 0) then begin
        rroa(i)=total(rrotg(sg)/(errotg(sg)^2))/total(1./(errotg(sg)^2))
        rrom(i)=median(rrotg(sg))
        rroe(i)=1./sqrt(total(1./errotg(sg)^2))
;        if(~finite(rroa(i))) then stop
      endif else begin
        rroa(i)=0.d0
        rrom(i)=0.d0
        rroe(i)=0.d0
      endelse
    endif else begin
      rroa(i)=0.d0
      rrom(i)=0.d0
      rroe(i)=0.d0
    endelse
  endif
endfor                         ; end loop over fibers

;stop

; write results to reduced/csv directory, one line per valid target:
; target, JD, target, original input file, rv dir output filename,
; from correlation: barycentric RV, CC width, CC amplitude, noise estimate
; block-fitted avg redshift, median redshift, formal uncertainty of mean,
; more....
nmatcho=tharred.nmatch(1)
amoerro=tharred.amoerr(1)
rmsgoodo=tharred.rmsgood(1)
mgbdispo=tharred.mgbdisp(1)
lammido=tharred.lammid(1)
for i=0,1 do begin       ; loop over targets
  if(nfib eq 2) then begin
    findx=2
  endif else begin
    findx=2*i
  endelse
  atargname=strupcase(strtrim(targnames(i),2))
  if(atargname ne 'NULL') then begin
    orgname=echdat.origname
    rvkmps=c*rcco(i)
    rv_addline,atargname,mjdd,bjdtdb_c(findx),site,exptime,orgname,speco,$
      nmatcho,amoerro,rmsgoodo,$
      mgbdispo,rvkmps,ampcco(i),widcco(i),lammido,baryshifts(i),$
      rroa(i),rrom(i),rroe(i)
  endif
endfor

; write more complete results to reduced/rv directory

; build output structure

rvred={rroa:rroa,rrom:rrom,rroe:rroe,rro:rro,erro:erro,aao:aao,eaao:eaao,$
       bbo:bbo,ebbo:ebbo,pldpo:pldpo,ccmo:ccmo,delvo:delvo,rvvo:rvvo,$
       rcco:rcco,ampcco:ampcco,widcco:widcco,barycorr:baryshifts,$
       rvcco:rvcco}
       
; write the information from the cross-correlation and from the block-fitting
; procedures to rvdir as a multi-extension fits file.

rvname='RADV'+datestrd+'.fits'
rvout=nresrooti+rvdir+rvname

hdr = copy_header(dathdr)
sxdelpar, hdr, 'NAXIS1'
sxdelpar, hdr, 'NAXIS2'
sxaddpar, hdr, 'NAXIS', 0

fxaddpar,hdr,'OBJECTS',targnames(0)+'&'+targnames(1)
fxaddpar,hdr,'SITEID',site
fxaddpar,hdr,'INSTRUME',camera
fxaddpar,hdr,'FIBZ0',fib0
fxaddpar,hdr,'FIBZ1',fib1
fxaddpar,hdr,'MJD-OBS',mjdd,'Data MJD'
fxaddpar,hdr,'MJD',mjdc,'Creation date'
fxaddpar,hdr,'L1IDZER0',zeronames(0),'ZERO name fib 0'
fxaddpar,hdr,'L1IDZER2',zeronames(1),'ZERO name fib 2'

fxaddpar,hdr,'RCC',rcco(fib0),'Cross-Corr redshift'
fxaddpar,hdr,'WIDCC',widcco(fib0),'Cross-Corr width (km/s)'
fxaddpar,hdr,'AMPCC',ampcco(fib0),'Cross-Corr peak height'
fxaddpar,hdr,'RVCC',rvcco(fib0),'[km/s] Bary corrected cross-correl RV'
fxaddpar,hdr,'BJD',bjdo(fib0),'Exposure center barycen date'
fxaddpar,hdr,'ZBLKAVG',rroa(fib0),'Avg blockfit redshift'
fxaddpar,hdr,'ZBLKMED',rrom(fib0),'Median blockfit redshift'
fxaddpar,hdr,'ZBLKERR',rroe(fib0),'Blockfit redshift formal err'

; write out the data as a fits extension table.
; each column contains a single row, and each element is an array
; dimensioned (2,nord,nblock) containing various redshift fitting
; parameters or error estimates.
fxwrite,rvout,hdr ;### guess this isn't needed, causes unit leak
tarlist=[tarlist,rvout]
fxbhmake,hdr,1                   ; make extension header, only 1 row
fxbaddcol,jn1,hdr,rro,'RedShft','Redshift frm blockfit'
fxbaddcol,jn2,hdr,erro,'ErrRShft','Redshift error'
fxbaddcol,jn3,hdr,aao,'Scale','Inten scale factor'
fxbaddcol,jn4,hdr,eaao,'ErrScale','Scale error'
fxbaddcol,jn5,hdr,bbo,'Lx1Coef','Leg 1 Coeff'
fxbaddcol,jn6,hdr,ebbo,'ErrLx1','Leg 1 Err'
fxbaddcol,jn7,hdr,pldpo,'PLDP','PLDP'

fxbcreate,unit,rvout,hdr,ext1
fxbwritm,unit,['RedShft','ErrRShft','Scale','ErrScale','Lx1Coef','ErrLx1',$
               'PLDP'],rro,erro,aao,eaao,bbo,ebbo,pldpo
fxbfinish,unit

; make a 2nd extension, containing cross-correlation data.
; each column contains a single row, and each element is an array
; dimensioned (2,801) containing the cross-correlation function and
; its lag coordinate in velocity units (km/s)
fxaddpar,hdr,'LAGKMS0',rvvo(0)
fxaddpar,hdr,'LAGKMS1',rvvo(1)

fxbhmake,hdr,1                   ; make another extension header, only 1 row
fxbaddcol,hn1,hdr,ccmo,'CC_fn','Cross-Corr Function'
fxbaddcol,hn2,hdr,delvo,'LagVel','CC Lag (km/s)'
fxbcreate,unit,rvout,hdr,ext2
fxbwritm,unit,['CC_fn','LagVel'],ccmo,delvo

fxbfinish,unit

; output for debugging
if(verbose ge 1) then begin
  print
  print,'*** radial_velocity ***'
  print,'targets(s) =',targnames
  print,'MJD=',obsmjd
endif

;stop
skipall:

end
