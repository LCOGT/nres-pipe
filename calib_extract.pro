pro calib_extract,flatk=flatk,dble=dble
; This routine calibrates (bias and background subtracts) an NRES image 
; stored in common, extracts to yield 1-dimensional spectra for as many
; orders and fibers as there are, divides these by an appropriate flat field
; file, and places results and metadata in common.
; If the image is intended to serve as a FLAT, then set keyword flatk
; and division by the flat will not be done.
; If the keyword dble is set, then the output fits file is given a name
; '.../spec/DBLE********.*****'. In any case, the output filename is saved 
; in nres_comm in variable speco.
; It gets necessary info about the spectrograph from the "spectrographs"
; config file, and from the image main block header.

compile_opt hidden

@nres_comm
; common data for NRES image reduction routines
;common nres,filin0,nfib,mfib,fib0,fib1,$
;       nresroot,nresrooti,tempdir,expmdir,thardir,specdir,ccordir,rvdir,$
;       classdir,diagdir,blazdir,extrdir,$
;       csvdir,biasdir,darkdir,flatdir,tracedir,dbledir,tripdir,zerodir,$
;       jdc,mjdc,jdd,mjdd,datestrc,datestrd,$
;       filname,dat,dathdr,cordat,varmap,$
;       extrspec,corspec,blazspec,flatspec,rmsspec,rmsblaz,speco,ampflat,$
;       badlamwts,$
;       expmdat,expmhdr,expmvals,agu1,agu1hdr,agu2,agu2hdr,$
;       teldat1,tel1hdr,tel2dat,tel2hdr,$
;       type,site,telescop,camera,exptime,objects,$
;       ccd,specdat,orddiff,tracedat,echdat,$
;       flatdat,agu1red,agu2red,$
;       expmred,tharred,rvindat,rvred,spclassred,$
;       verbose

; constants
rutname='calib_extract'

; get spectrograph info, notably nord
get_specdat,mjdd,err
nord=specdat.nord
nx=specdat.nx
ccd_find,err
if(err ne 0) then begin
  logo_nres2,rutname,'ERROR','FATAL CCD parameters not found'
  if(verbose) then print,'in calib_extract, CCD parameters not found.  Fatal error.'
  goto,fini
endif

; make needed arrays to allow wavelength computation
; make a tentative lambda array for all 3 fibers
xx=(findgen(nx)-nx/2.)*specdat.pixsiz
mm=specdat.ord0+lindgen(nord)
lam03=dblarr(nx,nord,3)
for i=0,2 do begin
  lambda3ofx,xx,mm,i,specdat,lamt,y0t
  lam03(*,*,i)=lamt
endfor
mk_badlamwts,lam03

; locate suitable bias, dark, flat and trace data
errsum=0
get_calib,'BIAS',biasfile,bias,biashdr,gerr  ; find bias via the default method
logo_nres2,rutname,'INFO','READ '+biasfile
errsum=errsum+gerr
get_calib,'DARK',darkfile,dark,darkhdr,gerr
logo_nres2,rutname,'INFO','READ '+darkfile
errsum=errsum+gerr
if(not keyword_set(flatk)) then begin
  get_calib,'FLAT',flatfile,flat,flathdr,gerr
  logo_nres2,rutname,'INFO','READ '+flatfile
  flatdat={flat:flat,flatfile:flatfile,flathdr:flathdr}
  tarlist=[nresrooti+'reduced/'+flatfile]
  errsum=errsum+gerr
endif
get_calib,'TRACE',tracefile,tracprof,tracehdr,gerr
logo_nres2,rutname,'INFO','READ '+tracefile
errsum=errsum+gerr
if(errsum gt 0) then begin
  if(verbose) then print,'Failed to locate calibration file(s) in calib_extract.  FATAL error'
  logo_nres2,rutname,'ERROR','FATAL Failed to locate calibration file(s)'
  logo_nres2,rutname,'ERROR','summed error gerr = '+string(gerr)
  goto,fini
endif

; if either fiber0 or fiber2 profile data exist and are all zero, fill 
; values in from the other one.
sz=size(tracprof)
cnfib=sz(3)
cnblk=sz(4)
if(cnfib eq 3) then begin
  v0=max(abs(tracprof(*,*,0,1:*)))
  v2=max(abs(tracprof(*,*,2,1:*)))
  if(((v0 ne 0.) or (v2 ne 0)) and not ((v0 eq 0) and (v2 eq 0))) then begin
; do this if either v0 or v2 = 0, but not both
    if(v0 eq 0) then begin
      tracprof(*,*,0,1:*)=tracprof(*,*,2,1:*)
    endif else begin
      tracprof(*,*,2,1:*)=tracprof(*,*,0,1:*)
    endelse
  endif
endif

;stop

; debias
cordat=dat-bias
mk_variance              ; compute variance map and hold it in common, too

; subtract dark
exptime=sxpar(dathdr,'EXPTIME')
cordat=cordat-exptime*dark

; trim overscan
npoly=sxpar(tracehdr,'NPOLY')
sz=size(cordat)
nxu=sz(1)
if(nxu gt nx) then begin
  cordat=cordat(0:nx-1,*)
  logo_nres2,rutname,'INFO','Trimming nx from/to '+string(nxu)+' '+string(nx)
endif

; remove background
ord_wid=sxpar(tracehdr,'ORDWIDTH')   ; width of band to be considered for 
                                     ; extraction
medboxsz=sxpar(tracehdr,'MEDBOXSZ')
nleg=sxpar(tracehdr,'NLEG')
cowid=sxpar(tracehdr,'COWID')
nblock=sxpar(tracehdr,'NBLOCK')
trace=reform(tracprof(0:nleg-1,*,*,0))
prof=tracprof(0:cowid-1,*,*,1:nblock)
order_cen,trace,ord_vectors
tracedat={trace:trace,npoly:nleg,ord_vectors:ord_vectors,ord_wid:ord_wid,$
          medboxsz:medboxsz,tracefile:tracefile,prof:prof}
objs=sxpar(dathdr,'OBJECTS')
backsub,cordat,ord_vectors,ord_wid,nfib,medboxsz,objs
; cordat is left in common: bias, dark, background-subtracted data,
;   trimmed to remove overscan if necessary.

; extract spectra
extract,err

; flatfield
if(keyword_set(flatk)) then begin
  corspec=echdat.spectrum
  rmsspec=echdat.specrms
  logo_nres2,rutname,'INFO','flatk set, so no flat applied'
endif else begin
  apply_flat2,flat,ierr
  if(ierr ne 0) then goto,fini
  logo_nres2,rutname,'INFO','flatk=0, so apply_flat2 run'
endelse 
  
; make the header and fill it out
; do not do this if flatk is set, since it will be done in mk_flat1
if(~keyword_set(flatk)) then begin

; write corspec (raw/flat) first
  mjdobs=sxpar(dathdr,'MJD-OBS')
; make coordinates for both telescopes
  lat1=tel1dat.latitude
  long1=tel1dat.longitude
  ht1=tel1dat.height
  obj1=tel1dat.object
  lat2=tel2dat.latitude
  long2=tel2dat.longitude
  ht2=tel2dat.height
  obj2=tel2dat.object

; latitude=sxpar(dathdr,'LATITUDE')
; longitud=sxpar(dathdr,'LONGITUD')
; height=sxpar(dathdr,'HEIGHT')
  mkhdr,hdr,corspec
  sxaddpar,hdr,'MJD',mjdc,'Creation date'
  nfravg=1
  sxaddpar,hdr,'NFRAVGD',nfravg,'Avgd this many frames'
  sxaddpar,hdr,'ORIGNAME',filname,'1st filename'
  sxaddpar,hdr,'FLATFILE',flatfile,'extracted flat filename'
  sxaddpar,hdr,'SITEID',site 
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE',type
  sxaddpar,hdr,'EXPTIME',exptime
  sxaddpar,hdr,'NELECTR0',echdat.nelectron(0),format='(e12.5)'
  sxaddpar,hdr,'NELECTR1',echdat.nelectron(1),format='(e12.5)'
  sxaddpar,hdr,'MJD-OBS',mjdobs
  if(mfib eq 3) then begin
    sxaddpar,hdr,'LONG1',long1
    sxaddpar,hdr,'LONG2',long2
    sxaddpar,hdr,'LAT1',lat1
    sxaddpar,hdr,'LAT2',lat2
    sxaddpar,hdr,'HT1',ht1
    sxaddpar,hdr,'HT2',ht2
    sxaddpar,hdr,'OBJ1',obj1
    sxaddpar,hdr,'OBJ2',obj2
  endif else begin
    if(fib0 eq 0) then begin
      sxaddpar,hdr,'LONG1',long1
      sxaddpar,hdr,'LAT1',lat1
      sxaddpar,hdr,'HT1',ht1
      sxaddpar,hdr,'OBJ1',obj1
      sxaddpar,hdr,'LONG2',0.d0
      sxaddpar,hdr,'LAT2',0.d0
      sxaddpar,hdr,'HT2',0.d0
      sxaddpar,hdr,'OBJ2','none'
    endif else begin
      sxaddpar,hdr,'LONG1',0.d0
      sxaddpar,hdr,'LAT1',0.d0
      sxaddpar,hdr,'HT1',0.d0
      sxaddpar,hdr,'OBJ1','none'
      sxaddpar,hdr,'LONG2',long2
      sxaddpar,hdr,'LAT2',lat2
      sxaddpar,hdr,'HT2',ht2
      sxaddpar,hdr,'OBJ2',obj2
    endelse
  endelse
; sxaddpar,hdr,'LATITUDE',latitude
; sxaddpar,hdr,'LONGITUD',longitud
; sxaddpar,hdr,'HEIGHT',height
  if(mfib eq 3) then sxaddpar,hdr,'NELECTRO2',echdat.nelectron(2),$
    format='(e12.5)'

  if(keyword_set(dble)) then begin
    speco='DBLE'+datestrd+'.fits'
    specout=nresrooti+'/'+dbledir+speco
  endif else begin
    speco='SPEC'+datestrd+'.fits'
    blazo='BLAZ'+datestrd+'.fits'
    extro='EXTR'+datestrd+'.fits'
    specout=nresrooti+'/'+specdir+speco
    blazout=nresrooti+blazdir+blazo
    extrout=nresrooti+extrdir+extro
  endelse
  objects=sxpar(dathdr,'OBJECTS')
  sxaddpar,hdr,'OBJECTS',objects
  sxaddpar,hdr,'TEL1_RA',tel1dat.ra
  sxaddpar,hdr,'TEL2_RA',tel2dat.ra
  sxaddpar,hdr,'TEL1_DEC',tel1dat.dec
  sxaddpar,hdr,'TEL2_DEC',tel2dat.dec
  sxaddpar,hdr,'NBLOCK',specdat.nblock
  sxaddpar,hdr,'NFIB',specdat.nfib
  sxaddpar,hdr,'NORD',specdat.nord
  sxaddpar,hdr,'NX',specdat.nx
  sxaddpar,hdr,'DATESTRD',datestrd
  tarlist=[tarlist,nresrooti+'reduced/'+tracefile]

  writefits,specout,corspec,hdr
  logo_nres2,rutname,'INFO','WRITE '+specout

; write extr = raw spectrum with low-signal ends trimmed
  if(not keyword_set(dble)) then begin
    writefits,extrout,extrspec,hdr        ; same hdr as specout
    logo_nres2,rutname,'INFO','WRITE '+extrout
    tarlist=[tarlist,extrout]

; then write blaze = raw - flat
    hdrb=hdr
    for j=0,mfib-1 do begin
      sj=strtrim(string(j,format='(i1)'),2)
      for i=0,nord-1 do begin
        snn=strtrim(string(i,format='(i2)'),2)
        if(strlen(snn) eq 1) then snn='0'+snn
        snn=sj+snn
        kwd='AMPFL'+snn
        sxaddpar,hdrb,kwd,ampflat(i,j)
      endfor
    endfor
    writefits,blazout,blazspec,hdrb
    logo_nres2,rutname,'INFO','WRITE '+blazout
    tarlist=[tarlist,blazout]
  endif
endif

;stop

echdat.mjdd=mjdd
echdat.mjdc=mjdc
echdat.origname=filname
echdat.siteid=site
echdat.camera=camera
echdat.exptime=exptime
if(not keyword_set(flatk))then echdat.flatname=flatfile else echdat.flatname=''

fini:

if(verbose ge 1) then begin
  print,'*** calib_extract ***'
  print,'File In = ',filin0
  naxes=sxpar(dathdr,'NAXIS')
  nx=sxpar(dathdr,'NAXIS1')
  ny=sxpar(dathdr,'NAXIS2')
  print,'Naxes, Nx, Ny = ',naxes,nx,ny
  print,'BIAS file used was ',biasfile
  print,'DARK file used was ',darkfile
  print,'TRACE file used was ',tracefile
  if(not keyword_set(flatk)) then begin
    print,'FLAT file used was ',flatfile
    if(keyword_set(dble)) then begin
      print,'spec FITS file '+speco+' written to dir reduced/dble'
    endif else begin
      print,'spec FITS file '+speco+' written to dir reduced/spec'
    endelse
  endif else begin
    print,'No FLAT used because FLATK keyword set'
  endelse
  print,'spec dimensions =',nx,nord,mfib
endif
end
