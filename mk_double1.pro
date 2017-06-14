pro mk_double1,ierr
; This routine takes an extracted 'DOUBLE' input file (which it finds in
; nres_common echdat.spectrum) and which must contain 2 ThAr spectra, in
;  fibers 0,1 if nfib=2, or
;  fibers 0,1 or fibers 1,2 if nfib=3.
; The routine writes this (nx,nord,nfib) image to a DBLE file in the
; spec data directory, and adds a line to the standards.csv file describing
; the new calibration image.

@nres_comm

rutname='mk_double1'
ierr=0                   ; if not zero, fatal error

; get information for standards.csv from the original image header
type='DOUBLE'
fname='dble/'+speco
navg=1
site=strtrim(sxpar(dathdr,'SITEID'),2)
camera=strtrim(sxpar(dathdr,'INSTRUME'),2)
jdate=jdc
objects=sxpar(dathdr,'OBJECTS')
words=get_words(objects,nwd,delim='&')
words=strtrim(strupcase(words),2)
if(nwd eq 2) then begin
  if(words(0) eq 'THAR' and words(1) eq 'THAR') then begin
    flag='0010'
  endif else begin
    logo_nres,rutname,'FATAL Bad data type '+objects
    if(verbose) then begin
      print,'Error in data type in mk_double1
    endif
    ierr=1
    goto,fini
  endelse
endif
if(nwd eq 3) then begin
  if(words(0) eq 'THAR' and words(1) eq 'THAR' and words(2) ne 'THAR') then $
    flag='0010'
  if(words(0) ne 'THAR' and words(1) eq 'THAR' and words(2) eq 'THAR') then $
    flag='0020' 
endif

; add a line to standards.csv
stds_addline,type,fname,navg,site,camera,jdate,flag
logo_nres,rutname,'ADDLINE standards.csv'

fini:
end
