pro get_calib,stype,filename,cdat,chdr,gerr
; This routine reads the standards.csv file and searches it for the standard
; file of the given stype that has acceptable flag values and that is closest
; in time and that has at least the specified number of frames averaged
; together.  
; On input, stype = one of 'BIAS','DARK','FLAT','TRACE','TRIPLE'
;    desired site, camera, are obtained from the common block
; On output,
;    filename = path to the selected fits file, relative to $NRESROOT
;    dat = the desired data file contents
;    hdr = the header of the selected fits file

; Procedure is first to select lines matching the desired type, site,
; and camera.  Among these, find the line that is closest in time (unsigned).
; Then find all lines that are less than 1.5 times as far away as the closest,
; or within 1.5 days, whichever interval is larger.  Among these, find all
; for which navg > 1 (indicating that they are super-calibs).  If there is
; at least one of these, take the closest one.  If none, take the closest
; line with navg=1.

compile_opt hidden

; common block
@nres_comm

gerr=0
;rootname=getenv('NRESROOT')

; read the standards.csv file.
; **** note that as get_calib is used, multiple reads of standards.csv are done
; in quick succession.  As the file gets large, this may become a performance
; problem.  If so, we should rewrite so that one call to stds_rd will suffice
; for all of BIAS, DARK, FLAT, TRACE, TRIPLE ****
stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr 
types=strtrim(strupcase(types),2)
sites=strtrim(strupcase(sites),2)
cameras=strtrim(strupcase(cameras),2)
stypeu=strtrim(strupcase(stype),2)
siteu=strtrim(strupcase(site),2)
camerau=strtrim(strupcase(camera),2)

; select for type, site, camera, flags
s=where((types eq stypeu) and (sites eq siteu) and $
        (cameras eq camerau) and $
        (strmid(flags,0,1) eq '0'), ns)
if(ns le 0) then begin
  print,'No valid files of type ',stype,' found in get_calib'
  gerr=1
  filename='NULL'
  cdat=[[0.]]
  chdr=['NULL']
stop
  goto,fini
endif
fnames1=fnames(s)
navgs1=navgs(s)
jdates1=jdates(s)

; find nearest jdate
jddif1=abs(jdates1-jdc)
md=min(jddif1,ix)
dt=(1.5*md) > (md + 1.5)             ; search radius
s2=where((jddif1 le dt) and (navgs1 gt 1),ns2)

if(ns2 gt 0) then begin          ; get here if there is a super-cal inside the
                                 ; search radius
  fnames2=fnames1(s2)
  navgs2=navgs1(s2)
  jdates2=jdates1(s2)
  jdiff2=abs(jdates2-jdc)
  md2=min(jdiff2,ix2)
  
; get the data to return
  filename=fnames2(ix2)
endif else begin
  filename=fnames1(ix)
endelse

; read the file
path=nresrooti+'/reduced/'+filename
cdat=readfits(path,chdr,/silent)     ; requires all these types of std files to
                             ; be standard FITS files, not tables. 
fini:

end
