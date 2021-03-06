pro rv_setup,ierr
; This routine sets up data structures involving the
; extracted data stored in common structure echdat and one or two standard ZERO
; files (depending on how the fibers are illuminated) identified by routine 
; find_zero.  Spectra, meta- and ancillary data are returned in the common
; structure rvindat.

@nres_comm

; constants
rutname='rv_setup'
null=-99.9
nresroot=getenv('NRESROOT')
zeroroot=nresrooti+'reduced/'
ierr=0

; count star fibers; return target structure(s) with info on target(s)
; grind through these 1 fiber at a time, because of all the special cases
targnames=strarr(2)            ; names for targets on fibers 0 and 2, resp.
targra=dblarr(2)
targdec=dblarr(2)
zeronames=strarr(2)            ; names of ZERO files
zerotypes=strarr(2)             ; type of selection for each ZERO file
zerorrt=dblarr(2)           ; ZERO net (baryc + intrinsic) redshift - unity
tlon=dblarr(2)              ; telescope longitudes
tlat=dblarr(2)               ; telescope latitudes
talt=dblarr(2)                ; telescope height
objects=get_words(sxpar(dathdr,'OBJECTS'),nwd,delim='&')
; remove '_' and following characters from each word in objects array
for i=0,nwd-1 do begin
  ss=objects(i)
  ix=strpos(ss,'_')
  if(ix gt 0) then objects(i)=strmid(ss,0,ix)
endfor
objects=strupcase(objects)
centtimes=expmred.expfwt     ; flux-weighted mean exp JD
baryshifts=dblarr(2)            ; barycentric z for each target at centtimes
coosrc=lonarr(2)             ; source for target coords: 0 = csv, 1 = targhdr
tlat=[tel1dat.latitude,tel2dat.latitude]
tlon=[tel1dat.longitude,tel2dat.longitude]
talt=[tel1dat.height,tel2dat.height]
;tlat=sxpar(dathdr,'LATITUDE')        ; telescope latitude
;tlon=sxpar(dathdr,'LONGITUD')      ; telescope E. longitude
;talt=sxpar(dathdr,'HEIGHT')        ; telescope elevation ASL (m) 

; valid cases are: nfib=2 and objects='ThAr&Target'
;               or nfib=3 and objects='NONE&ThAr&Target'
;                          or objecst='Target&Thar&NONE'
;                          or objects='Target1&Thar&Target2'

;stop

; If nfib=2, then we assume that telescope 1 is absent, and telescope 2
; has the target, and connects to fiber 2 (hence targnames(1), targra(1), etc) 
if(nfib eq 2) then begin
  if(objects(0) ne 'THAR') then begin
    logo_nres2,rutname,'CRITICAL','With nfib=2, fiber 0 must be ThAr'
    ierr=1
    goto,fini
  endif
  if(objects(1) eq 'NONE' or objects(1) eq 'THAR') then begin
    logo_nres2,rutname,'CRITICAL','with nfib=2, fiber 1 must be target'
    ierr=1
    goto,fini
  endif

  targnames(0)='NULL'
  zeronames(0)='NULL'
  zerotypes(0)='NULL'
  targra(0)=0.d0
  targdec(0)=0.d0
  targnames(1)=strcompress(strupcase(objects(1)),/remove_all)
  targra(1)=tel2dat.ra
  targdec(1)=tel2dat.dec
  targ1struc=get_targ_props(targnames(1),targra(1),targdec(1))
; get_targ_props returns a structure containing name, RA, DEC, Vmag, B-V,
; logg, PMRA, PMDEC.  If no name or position match, get a structure full
; of nulls.
  if(targra(1) eq 0.d0 and targdec(1) eq 0.d0) then coosrc(1)=0 else $
    coosrc(1)=1
; coosrc identifies whether (0) coords from targets.csv or (1) from telhdr.
  if(coosrc(1) eq 0) then begin
    targra(1)=targ1struc.ra
    targdec(1)=targ1struc.dec
  endif
; here and below, reverse sign of tlon because headers give E longitude,
; but nresbarycorr expects W. longitude.
  baryshifts(1)=nresbarycorr(targnames(1),centtimes(1),targra(1),targdec(1),$
     tlat(1),-tlon(1),talt(1))
endif

if(nfib eq 3) then begin
  if((objects(1) ne 'THAR') or $
     (objects(0) eq 'NONE' and objects(2) eq 'NONE')) then begin
    logo_nres2,rutname,'CRITICAL','fiber 1 must be ThAr'+$
      '  and one of fibers 0,2 must not be NONE'
    ierr=1
    goto,fini
  endif

  if(objects(0) ne 'NONE') then begin
    targnames(0)=strcompress(strupcase(objects(0)),/remove_all)
    targra(0)=tel1dat.ra
    targdec(0)=tel1dat.dec 
    targ0struc=get_targ_props(targnames(0),targra(0),targdec(0))
    if(targra(0) eq 0.d0 and targdec(0) eq 0.d0) then coosrc(0)=0 else $
      coosrc(0)=1
    if(coosrc(0) eq 0) then begin
      targra(0)=targ0struc.ra
      targdec(0)=targ0struc.dec
    endif
    baryshifts(0)=nresbarycorr(targnames(0),centtimes(0),targra(0),targdec(0),$
       tlat(0),-tlon(0),talt(0))
  endif else begin
    targnames(0)='NULL'
    zeronames(0)='NULL'
    zerotypes(0)='NULL'
    targra(0)=0.d0
    targdec(0)=0.d0
    targ0struc=get_targ_props('NULL',0.d0,0.d0)
  endelse

  if(objects(2) ne 'NONE') then begin
    targnames(1)=strcompress(strupcase(objects(2)),/remove_all)
    targra(1)=tel2dat.ra
    targdec(1)=tel2dat.dec 
    targ1struc=get_targ_props(targnames(1),targra(1),targdec(1))
    if(targra(1) eq 0.d0 and targdec(1) eq 0.d0) then coosrc(1)=0 else $
      coosrc(1)=1
    if(coosrc(1) eq 0) then begin
      targra(1)=targ1struc.ra
      targdec(1)=targ1struc.dec
    endif
    baryshifts(1)=nresbarycorr(targnames(1),centtimes(1),targra(1),targdec(1),$
       tlat(1),-tlon(1),talt(1))
  endif else begin
    targnames(1)='NULL'
    zeronames(1)='NULL'
    zerotypes(1)='NULL'
    targra(1)=0.d0
    targdec(1)=0.d0
    targ1struc=get_targ_props('NULL',0.d0,0.d0)
  endelse
endif
  
targstrucs=[targ0struc,targ1struc]
nblock=specdat.nblock
nfib=specdat.nfib
nx=specdat.nx
nord=specdat.nord

; If the target matching fails, then plug in invented but plausible stellar
; properties so that the search for a ZERO file yields something.
fake_target,targstrucs,targnames,targra,targdec

; May want some others for, eg, PLDP.

; choose one or two ZERO files for the fitting.
obsmjd=sxpar(dathdr,'MJD-OBS')

zstar=fltarr(nx,nord,2)        ; ZERO file(s) star spectra
zthar=fltarr(nx,nord,2)        ; ZERO file(s) thar spectra
zlam=dblarr(nx,nord,2)         ; vac lambda corrected to zstar(s) frame of ref
zlamt=dblarr(nx,nord,2)        ; vac lambda in NRES lab frame
for i=0,1 do begin
  if(targnames(i) ne 'NULL') then begin
    select_std,'ZERO',obsmjd,'NULL','NULL',1,targstrucs(i),zeroname,zerotype,err
    if(err eq 0) then begin
      zeronames(i)=zeroname
      zerotypes(i)=zerotype
;select_std,fiber,stdtype,mjd,site,stdfiber,targstruc,name_out,sel_type;  
;  'NULL' or null means ignore.  seltype is one of "MJD_nearest", "In targs
;  file", "std spectrum NN", "forced to NULL", or whatever.

; get the ZERO data.  If only one star fiber is lit, the other plane
; of each output array contains zeros.   
      zeropath=zeroroot+zeroname
      rd_zero,zeropath,hdr,star,thar,lam,lamt
      tarlist=[tarlist,zeropath]
      
;     fxbopen,unit,zeropath,1,hdr        ; get 1st extension of ZERO file
;     fxbread,unit,star,'Star',1         ; read 'Star' col, row 1
;     fxbread,unit,thar,'ThAr',1         ; 'ThAr' col
;     fxbread,unit,lam,'Wavelength',1   ; 'Wavelength' col
;     fxbclose,unit
;     free_lun,unit
    
      zstar(*,*,i)=star
      zthar(*,*,i)=thar
      zlam(*,*,i)=lam
      zlamt(*,*,i)=lamt
      zerorrt(i)=sxpar(hdr,'REDSHIFT')  ; ZERO net (baryc + intrinsic) redshift
    endif
  endif


endfor

; build output structure

  rvindat={targstrucs:targstrucs,zeronames:zeronames,zerotypes:zerotypes,$
      baryshifts:baryshifts,zstar:zstar,zthar:zthar,zlam:zlam,zlamt:zlamt,$
      coosrc:coosrc,zerorrt:zerorrt}

fini:

if(verbose ge 1) then begin
  print,'*** cross_correl ***'
  print,'File In = ',filin0
  naxes=sxpar(dathdr,'NAXIS')
  nx=sxpar(dathdr,'NAXIS1')
  ny=sxpar(dathdr,'NAXIS2')
  print,'Naxes, Nx, Ny = ',naxes,nx,ny 
  print,'ZERO file(s) used:',zeronames
endif

end
