pro ingest,filin,ierr
; This routine opens the multi-extension file filin and reads its contents
; (headers and data segments) into the nres common data area.
; The name filin should be relative to the $NRESRAWDAT data directory.
; It also exracts certain of the header data that will be of general use
; later, and places their values in common.
; On normal return ierr=0, but if expected data are not found or fail basic
; sanity checks, ierr is set to a positive integer (value depending on the 
; nature  of the error).

@nres_comm
;common nres,nfib,nresroot,tempdir,expmdir,thardir,specdir,ccordir,rvdir,
;       classdir,diagdir,csvdir,flatdir,tracedir,tripdir,$
;       filname,dat,dathdr,expmdat,expmhdr,agu1dat,agu1hdr,agu2dat,agu2hdr,$
;       tel1dat,tel1hdr,tel2dat,tel2hdr,$
;       type,site,telescop,specdat,orddiff,echdat,agu1red,agu2red,expmred,$
;       tharred,crossred,rvred,spclassred

rutname='ingest'
ierr=0

logo_nres2,rutname,'INFO',' filin = '+filin
if(verbose) then begin
  print,'###Ingest'
  print,'filin = ',filin
endif

; open the input FITS file, read the main data segment and header
logo_nres2,rutname,'INFO',' Reading main data segment'
nresrawdat=getenv('NRESRAWDAT')
filename=nresrawdat+strtrim(filin,2)
dat=readfits(filename,dathdr)
type=strtrim(sxpar(dathdr,'OBSTYPE'),2)
extn=sxpar(dathdr,'EXTEND')
dat0=dat

; #########
; Hack to accommodate fl09 images from BPL
; if array is 4095 x 4072, replicate in x and y to make 4096 x 4096
;sz=size(dat0)
;nx=sz(1)
;ny=sz(2)
;if(nx eq 4095 and ny eq 4072) then begin
;  dato=fltarr(4096,4096)
; dato(0:4094,0:4071)=dat0
; daty=dat0(*,4048:4071)
; dato(0:4094,4072:4095)=daty
; datx=dato(4094,*)
; dato(4095,*)=datx
; dat=dato
; sxaddpar,dathdr,'NAXIS1',4096
; sxaddpar,dathdr,'NAXIS2',4096
; objs=sxpar(dathdr,'OBJECTS')
; words=get_words(objs,nw,delim='&')
; if(words(1) eq 'thar') then begin
;   sxaddpar,dathdr,'OBJECTS','thar&thar&none'
; endif
;endif
;nx=4096
;ny=4096
; #########  End hack

; Trim and subtract overscan
trimoscan

; allow 'SPECTRUM' and 'EXPERIMENTAL' and 'ARC' for testing
if((type ne 'TARGET') and (type ne 'DARK') and (type ne 'FLAT') and $
   (type ne 'BIAS') and (type ne 'DOUBLE') and (type ne 'SPECTRUM')) $
   and (type ne 'EXPERIMENTAL') then begin
  ierr=1
  goto,fini
endif

; get useful keywords out of the main header and into common
camera=strtrim(sxpar(dathdr,'INSTRUME'),2)
site=strtrim(sxpar(dathdr,'SITEID'),2)
filname=strtrim(sxpar(dathdr,'ORIGNAME'))
exptime=strtrim(sxpar(dathdr,'EXPTIME'))
mjdd=sxpar(dathdr,'MJD-OBS')       ; data date = start of exposure
jdd=mjdd+2400000.5d0
;if(strtrim(strupcase(site),2) ne 'SQA') then nfib=3 else nfib=2
objects=sxpar(dathdr,'OBJECTS')
wobjects=get_words(objects,delim='&',nwords)
nfib=nwords                   ; number of fibers that may be illuminated
if(strupcase(wobjects(0)) ne 'NONE') then begin
  fib0=0
  fib1=1
endif else begin
  fib0=1
  fib1=2
endelse
s=where(strupcase(wobjects) ne 'NONE',ns)
;mfib=ns > 2
; ###### see what this breaks
mfib=ns

; make the creation dates that will appear in all the headers, etc related
; to this input file
jdc=systime(/julian)
mjdc=jdc-2400000.5d0
datereald=date_conv(jdd,'R')
datestrd=string(datereald,format='(f13.5)')
datestrd=strlowcase(site)+datestrd

if((extn ne 1) or (type eq 'BIAS') or (type eq 'DARK')) then begin  
; do this skip if not CDP
  logo_nres2,rutname,'INFO',' Skipping reading Consolidated Data Product'
  goto,skipit
endif

; read the remaining data segments and their headers
fxbopen,iun,filename,1,expmhdr        ; exposure meter
nt_expm=sxpar(expmhdr,'NAXIS2')
fxbread,iun,jd_expm,'JD_START'
fxbread,iun,fib0c,'FIB0COUNTS'
fxbread,iun,fib1c,'FIB1COUNTS'
fxbread,iun,fib2c,'FIB2COUNTS'
fxbread,iun,flg_expm,'EMFLAGS'
fxbclose,iun
expmdat={nt_expm:nt_expm,jd_expm:jd_expm,fib0c:fib0c,fib1c:fib1c,fib2c:fib2c,$
        flg_expm:flg_expm}

print,'reading AGU1'
fxbopen,iun,filename,2,agu1hdr                      ; AGU #1
nt_agu1=sxpar(agu1hdr,'NAXIS2')
filter_agu1=sxpar(agu1hdr,'FILTER')
if(nt_agu1 gt 0) then begin
  fxbread,iun,fname_agu1,'FILENAME'
  fxbread,iun,jd_agu1,'JD_UTC'
  fxbread,iun,nsrc_agu1,'N_SRCS'
  fxbread,iun,skyv_agu1,'SKYVAL'
  fxbread,iun,crval1_agu1,'CRVAL1'
  fxbread,iun,crval2_agu1,'CRVAL2'
  fxbread,iun,cd1_1_agu1,'CD1_1'
  fxbread,iun,cd1_2_agu1,'CD1_2'
  fxbread,iun,cd2_1_agu1,'CD2_1'
  fxbread,iun,cd2_2_agu1,'CD2_2'
endif else begin
  fname_agu1=[' ']
  jd_agu1=[0.d0]
  nsrc_agu1=[0]
  skyv_agu1=[0.]
  crval1_agu1=[0.d0]
  crval2_agu1=[0.d0]
  cd_1_1_agu1=[0.]
  cd_1_2_agu1=[0.]
  cd_2_1_agu1=[0.]
  cd_2_2_agu1=[0.]
endelse
fxbclose,iun
agu1dat={nt_agu:nt_agu1,fname_agu:fname_agu1,jd_agu:jd_agu1,$
      nsrc_agu:nsrc_agu1,skyv_agu:skyv_agu1,crval1_agu:crval1_agu1,$
      crval2_agu:crval2_agu1,cd_1_1_agu:cd_1_1_agu1,cd1_2_agu:cd_1_2_agu1,$
      cd_2_1_agu:cd_2_1_agu1,cd_2_2_agu:cd_2_2_agu1,filter:filter_agu1}

print,'reading AGU2'
fxbopen,iun,filename,3,agu2hdr                ; AGU #2
nt_agu2=sxpar(agu2hdr,'NAXIS2')
filter_agu2=sxpar(agu2hdr,'FILTER')
if(nt_agu2 gt 0) then begin
  fxbread,iun,fname_agu2,'FILENAME'
  fxbread,iun,jd_agu2,'JD_UTC'
  fxbread,iun,nsrc_agu2,'N_SRCS'
  fxbread,iun,skyv_agu2,'SKYVAL'
  fxbread,iun,crval1_agu2,'CRVAL1'
  fxbread,iun,crval2_agu2,'CRVAL2'
  fxbread,iun,cd_1_1_agu2,'CD1_1'
  fxbread,iun,cd_1_2_agu2,'CD1_2'
  fxbread,iun,cd_2_1_agu2,'CD2_1'
  fxbread,iun,cd_2_2_agu2,'CD2_2'
endif else begin
  fname_agu2=['']
  jd_agu2=[0.d0]
  nsrc_agu2=[0]
  skyv_agu2=[0.]
  crval1_agu2=[0.d0]
  crval2_agu2=[0.d0]
  cd_1_1_agu2=[0.]
  cd_1_2_agu2=[0.]
  cd_2_1_agu2=[0.]
  cd_2_2_agu2=[0.]
endelse
fxbclose,iun
agu2dat={nt_agu:nt_agu2,fname_agu:fname_agu2,jd_agu:jd_agu2,$
      nsrc_agu:nsrc_agu2,skyv_agu:skyv_agu2,crval1_agu:crval1_agu2,$
      crval2_agu:crval2_agu2,cd_1_1_agu:cd_1_1_agu2,cd_1_2_agu:cd_1_2_agu2,$
      cd_2_1_agu:cd_2_1_agu2,cd_2_2_agu:cd_2_2_agu2,filter:filter_agu2}

print,'reading telescope1'
tel1arr=readfits(filename,tel1hdr,exten=4)                ; telescope 1
long1=sxpar(tel1hdr,'LONGITUD')
lat1=sxpar(tel1hdr,'LATITUDE')
height1=sxpar(tel1hdr,'HEIGHT')
ra1s=sxpar(tel1hdr,'RA')             ; string version
dec1s=sxpar(tel1hdr,'DEC')           ; string version
rawd=get_words(ra1s,delim=':')
ra1=15.*ten(float(rawd))             ; decimal degrees
decwd=get_words(dec1s,delim=':')
dec1=ten(float(decwd))
object1=sxpar(tel1hdr,'OBJECT')
tel1dat={telarr:tel1arr,longitude:long1,latitude:lat1,height:height1,$
      ra:ra1,dec:dec1,ras:ra1s,decs:dec1s,object:object1}

print,'reading telescope2'
tel2arr=readfits(filename,tel2hdr,exten=5)                ; telescope 2
long2=sxpar(tel2hdr,'LONGITUD')
lat2=sxpar(tel2hdr,'LATITUDE')
height2=sxpar(tel2hdr,'HEIGHT')
ra2s=sxpar(tel2hdr,'RA')             ; string version
dec2s=sxpar(tel2hdr,'DEC')           ; string version
rawd=get_words(ra2s,delim=':')
ra2=15.*ten(float(rawd))             ; decimal degrees
decwd=get_words(dec2s,delim=':')
dec2=ten(float(decwd))
object2=sxpar(tel2hdr,'OBJECT')
tel2dat={telarr:tel2arr,longitude:long2,latitude:lat2,height:height2,$
      ra:ra2,dec:dec2,ras:ra2s,decs:dec2s,object:object2}

; stick longitude, latitude, height into dathdr, for later use
;sxaddpar,dathdr,'LONGITUD',-70.8046889
;sxaddpar,dathdr,'LATITUDE',-30.16772
;sxaddpar,dathdr,'HEIGHT',2201.0

skipit:

; should put some error trapping in here

fini:
;stop
end
