pro mk_supercal,type,site,camera,dateran,object
; This routine runs stand-alone (not called by muncha).  It locates all
; calibration files of the given type (BIAS, DARK, FLAT, or ZERO),
; taken with the given camera (eg fl07) at the given site (eg bpl)
; and within the given date range.
; dateran(2) contains the start and end UT date of the search given as a
; double-precision number yyyyddd.xxxxx, where
; yyyy=year
; ddd=day number
; xxxxx=fractional day.
; Note that the calibration files are assigned names based on dates in this
; format.
; The routine writes the names of these into a temporary file calibin.txt in the
; temp directory.  It then calls avg_biasdark or avg_flat to combine flats,
; or avg_zero to combine zeros.  The result is written to the appropriate
; subdirectory of /reduced, and a line describing the new calibration file
; is written to standards.csv.
; Rules for combining calibration data are:
; For BIAS and DARK, the search must yield at least 3 input files.
; ***** The following rule is no longer needed
; For FLAT, if NAXIS3=3 (3 fibers exist) there must be at least one file
;  having fib0=0 and one with fib0=1
; *****
; For ZERO, selected input files must have the given object input parameter,
;  and the search must yield at least 2 input files.

; constants
nresroot=getenv('NRESROOT')
tempdir='temp/'
biasdir='reduced/bias/'
darkdir='reduced/dark/'
flatdir='reduced/flat/'
zerodir='reduced/zero/'

; make julian dates corresp to dateran
jdran=[date_conv(dateran(0),'J'),date_conv(dateran(1),'J')]

; if BIAS, DARK, or FLAT, read standards.csv and search for matching input parms
; complain if processing rules are not obeyed.
if((type eq 'BIAS') or (type eq 'DARK') or (type eq 'FLAT')) then begin
  stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr

  sites=strtrim(strupcase(sites),2)
  cameras=strtrim(strupcase(cameras),2)
  sitet=strtrim(strupcase(site))
  camerat=strtrim(strupcase(camera))
  sg=where((sites eq sitet) and (cameras eq camerat) and (types eq type) and $
     (jdates ge jdran(0)) and (jdates le jdran(1)),nsg)
  if(nsg gt 0) then begin
    files=fnames(sg)
  endif else begin
    print,'No matching files found'
    goto,fini
  endelse
endif

; if ZERO, read zeros.csv and search for matching input parms
if(type eq 'ZERO') then begin
  zeros_rd,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,$
    flags,zerohdr
  sites=strtrim(strupcase(sites),2)
  cameras=strtrim(strupcase(cameras),2)
  sitet=strtrim(strupcase(site))
  camerat=strtrim(strupcase(camera))
  objectt=strcompress(strupcase(object),/removeall)
  sg=where((sites eq sitet) and (cameras eq camerat) and (objects eq objectt) $
    and (jdates ge jdran(0)) and (jdates le jdran(1)),nsg)
  if(nsg ge 2) then begin    ; this is test for rules compliance for ZERO
    files=fnames(sg)
  endif else begin
    print,'Not enough matching files found'
    goto,fini
  endelse
endif

; test for rules compliance
if((type eq 'BIAS' or type eq 'DARK') and nsg lt 3) then begin
  print,'Not enough matches found for BIAS or DARK averaging'
  goto,fini
endif
if(type eq 'FLAT') then begin
  flagg=flags(sg)
  flag2=strmid(flagg,2,1)
; if all flag2 values are the same, then we must examine NAXIS3, else not
  se=where(flagg eq flagg(0),nse)
  if(nse eq nsg) then begin           ; all flag values are the same
    filet=nresroot+'reduced/'+files(0)   ; first file in list
    dat=readfits(filet,hdr)
    nax3=sxpar(hdr,'NAXIS3')
; relax rule prohibiting 3 fibers with only 2 illuminated
;   if(nax3 ge 3) then begin
;     print,'Do not have 2 different fib0 values for FLAT avg'
;     goto,fini
;   endif
  endif
endif

; write out the temporary file with input file names, print number of files
; found
flist=nresroot+tempdir+'avglist.txt'
print,nsg,' files of type ',type,' found in mk_supercal'
openw,iun,flist,/get_lun
for i=0,nsg-1 do begin
  printf,iun,files(i)
endfor
close,iun
free_lun,iun

; depending on data type, call the appropriate routine to do the work
if(type eq 'BIAS' or type eq 'DARK') then avg_biasdark,type,flist
if(type eq 'FLAT') then avg_flat,flist
if(type eq 'ZERO') then avg_zero,flist

fini:
end
