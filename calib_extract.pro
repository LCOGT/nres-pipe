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

@nres_comm
; common data for NRES image reduction routines
;common nres,filin0,nfib,mfib,fib0,fib1,$
;      nresroot,tempdir,expmdir,thardir,specdir,ccordir,rvdir,classdir,diagdir,$
;       csvdir,biasdir,darkdir,flatdir,tracedir,dbledir,tripdir,zerodir,$
;       jdc,mjdc,datestrc,$ 
;       filname,dat,dathdr,cordat,varmap,corspec,rmsspec,speco,$ 
;       expmdat,expmhdr,agu1,agu1hdr,agu2,agu2hdr,$
;       teldat1,tel1hdr,tel2dat,tel2hdr,$
;       type,site,telescop,camera,exptime,ccd,specdat,orddiff,tracedat,echdat,$
;       agu1red,agu2red,$
;       expmred,tharred,crossred,rvred,spclassred,$
;       verbose 

; constants

; get spectrograph info, notably nord
get_specdat,mjdc,err
nord=specdat.nord
nx=specdat.nx
ccd_find,err
if(err ne 0) then begin
  print,'in calib_extract, CCD parameters not found.  Fatal error.'
  goto,fini
endif

; locate suitable bias, dark, flat and trace data
errsum=0
get_calib,'BIAS',biasfile,bias,biashdr,gerr  ; find bias via the default method
errsum=errsum+gerr
get_calib,'DARK',darkfile,dark,darkhdr,gerr
errsum=errsum+gerr
if(not keyword_set(flatk)) then begin
  get_calib,'FLAT',flatfile,flat,flathdr,gerr
  flatdat={flat:flat,flatfile:flatfile,flathdr:flathdr}
  errsum=errsum+gerr
endif
get_calib,'TRACE',tracefile,tracprof,tracehdr,gerr
errsum=errsum+gerr
if(errsum gt 0) then begin
  print,'Failed to locate calibration file(s) in calib_extract.  FATAL error'
  stop
  goto,fini
endif

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
if(nxu gt nx) then cordat=cordat(0:nx-1,*)

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
endif else begin
  apply_flat,flat
endelse 
  
; make the header and fill it out
; do not do this if flatk is set, since it will be done in mk_flat1
if(~keyword_set(flatk)) then begin
  mjdobs=sxpar(dathdr,'MJD-OBS')
  latitude=sxpar(dathdr,'LATITUDE')
  longitud=sxpar(dathdr,'LONGITUD')
  height=sxpar(dathdr,'HEIGHT')
  mkhdr,hdr,corspec
  sxaddpar,hdr,'MJD',mjdc,'Creation date'
  nfravg=1
  sxaddpar,hdr,'NFRAVGD',nfravg,'Avgd this many frames'
  sxaddpar,hdr,'ORIGNAME',filname,'1st filename'
  sxaddpar,hdr,'SITEID',site 
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE',type
  sxaddpar,hdr,'EXPTIME',exptime
  sxaddpar,hdr,'NELECTR0',echdat.nelectron(0),format='(e12.5)'
  sxaddpar,hdr,'NELETRO1',echdat.nelectron(1),format='(e12.5)'
  sxaddpar,hdr,'MJD-OBS',mjdobs
  sxaddpar,hdr,'LATITUDE',latitude
  sxaddpar,hdr,'LONGITUD',longitud
  sxaddpar,hdr,'HEIGHT',height
  if(mfib eq 3) then sxaddpar,hdr,'NELECTRO2',echdat.nelectron(2),$
    format='(e12.5)'

  if(keyword_set(dble)) then begin
    speco='DBLE'+datestrc+'.fits'
    specout=nresroot+'/'+dbledir+speco
  endif else begin
    speco='SPEC'+datestrc+'.fits'
    specout=nresroot+'/'+specdir+speco
  endelse
  objects=sxpar(dathdr,'OBJECTS')
  sxaddpar,hdr,'OBJECTS',objects
  writefits,specout,corspec,hdr
endif

echdat.mjd=mjdc
echdat.origname=filname
echdat.siteid=site
echdat.camera=camera
echdat.exptime=exptime

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
