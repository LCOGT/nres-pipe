pro select_std,stdtype,mjdd,site,ccd,navg,targstruc,name_out,sel_type,err
; This routine selects a standard file for use in NRES calibration or RV
; estimation, given some information about the constraints on the file,
; and the kind of standard data desired.
; On input,
;  stdtype= one of 'BIAS','DARK','FLAT','TRIPLE','TRACE', or 'ZERO'
;  mjdd = MJD of data that are to be calibrated
;  site = site from which data are required, one of 'SQA','BPL'.'LSC','CPT',
;         'OGG','ELP','TFN','ALI', or 'NULL'
;  ccd = string name of the camera to which BIAS, DARK, or FLAT apply.
;  navg = minimum number of frames to be avg'd together
;  targstruc = structure containing data from the targets.csv file.  This
;    argument is ignored unless stdtype = 'ZERO'.
; On output,
;  name_out = path to the selected standard file, or 'NULL' if no acceptable
;      standard file is found.  Paths are relative to ???
;  sel_type = string describing how the chosen file was selected. Options are:
;    'MJD_nearest' -> file is nearest in MJD to input mjdd, satisfying other
;         constraints.
;    'MJD_smaller' -> as above, but standard must have smaller MJD than mjdd
;         (ie, be taken before the data).
;    'In_targs' -> for ZERO file, name_out was demanded by targets.csv entry.
;    'Targ_name' -> for ZERO file, name_out matches the current target name,
;         and has the largest MJD.
;    'Std_spec_NN' -> for ZERO file, standard ZERO spectrum NN was deemed to
;         be the best match in Teff, logg to the target.
;    'NULL' -> no suitable standard could be found.
;  err = 0 on good exit, otherwise 1.

err=0

; test input
stdtype=strupcase(strtrim(stdtype,2))
if(stdtype ne 'BIAS' and stdtype ne 'DARK' and stdtype ne 'FLAT' and $
   stdtype ne 'TRIPLE' and stdtype ne 'TRACE' and stdtype ne 'ZERO') then begin
  print,'stdtype = ',stdtype,' invalid in select_std'
  err=1
  goto,fini
endif


; BIAS, DARK, FLAT, TRIPLE, TRACE require same site and camera as were 
; used to acquire the data.  Not so for ZERO.
if(stdtype eq 'BIAS' or stdtype eq 'DARK' or stdtype eq 'FLAT' or $
  stdtype eq 'TRACE' or stdtype eq 'TRIPLE') then begin

; stdtype is legal, so read the standards.csv file
  stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr

; select on stdtype, site, camera, navg, flag ne bad
  s=where(types eq stdtype and sites eq site and cameras eq camera and $
          navgs ge navg and strmid(flags0,1) eq '0',ns)
  if(ns gt 0) then begin
    fnames=fnames(s)
    navgs=navgs(s)
    sites=sites(s)
    cameras=cameras(s)
    jdates=jdates(s)
    flags=flags(s)
  endif else begin   ; get here if no file matching the conditions is found
    err=1
    goto,fini
  endelse  

; select among this set of files based on MJD
  dmjd=jdates-2400000.5d0-mjdd 
  mdmjd=min(abs(dmjd),ix)     ; choose closest in time, ignoring sign of diff
  name_out=fnames(ix)
  sel_type='MJD_nearest'
  err=0
  goto,fini  

; ZERO requires data for same target star, or for one deemed to be similar.
endif else begin

  zeros_rd,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags,$
   zerohdr

; first look for a non-null ZERO keyword in targstruc.  If so, use it.
  if(targstruc.zero ne 'NULL') then begin
    name_out=targstruc.zero
; test that name_out is a valid entry in the zeros list
    s1=where(strtrim(name_out,2) eq strtrim(fnames,2),ns1)
    if(ns1 gt 0) then begin
      sel_type='In_targs'
      err=0
      goto,fini
    endif else begin
      name_out='NULL'
      sel_type='NULL'
      err=1
      print,'select_std: In_targs selected file does not exist in stds list'
      goto,fini
    endelse
  endif else begin
    if(targstruc.ra eq 0. and targstruc.dec eq 0.) then begin  ; null input struc
      name_out='NULL'
      sel_type='NULL'
      err=3
    stop
      goto,fini
    endif
  endelse
  
; Next look for ZERO files with the same target name.  Choose the one with
; the latest jd.
  s2=where(strtrim(targnames,2) eq strtrim(targstruc.targname,2),ns2)
  if(ns2 gt 0) then begin
    jdposs=jdates(s2)
    mxjd=max(jdposs,ix)
    is2=s2(ix)
    name_out=fnames(is2)
    sel_type='Targ_name'
    err=0
    goto,fini
  endif

; then look for valid target Teff, logg.  If found, choose std ZERO that is
; close.  Distinguish std ZERO files by 2nd digit of flag = 1.
  if(targstruc.teff gt 0. and targstruc.logg gt 0.) then begin
; get standard 
    get_best_zero,fnames,teffs,loggs,bmvs,jmks,flags,$
          targstruc.teff,targstruc.logg,-9.99,-9.99,'teff_logg',name_out,jerr
    if(jerr eq 0) then begin
      sel_type='Teff_logg'
      err=0
      goto,fini
    endif
  endif

; then look for valid B-V color.  Match to a MS star among std files.
  if((targstruc.bmag gt 0.) and (targstruc.vmag gt 0.)) then begin
; get standard
    bmvts=targstruc.bmag-targstruc.vmag
    get_best_zero,fnames,teffs,loggs,bmvs,jmks,flags,$
          -9.99,-9.99,bmvts,-9.99,'B-V',name_out,jerr
    if(jerr eq 0) then begin
      sel_type='B-V'
      err=0
      goto,fini
    endif
  endif

; then look for a valid J-K color.  Match to a MS star among std files.
  if((targstruc.jmag gt 0.) and (targstruc.kmag gt 0.)) then begin
; get standard
    jmkts=targstruc.jmag-targstruc.kmag
    get_best_zero,fnames,teffs,loggs,bmvs,jmks,flags,$
          -9.99,-9.99,-9.99,jmkts,'J-K',name_out,jerr
    if(jerr eq 0) then begin 
      sel_type='J-K'
      err=0
      goto,fini
    endif
  endif

; as a last resort, choose a 'typical' star, ie a late G MS star among std files
; In particular, do a search for best match to teff=5250., logg=4.0
  get_best_zero,fnames,teffs,loggs,bmvs,jmks,flags,$
        5250.,4.0,-9.99,-9.99,'teff_logg',name_out,jerr
  if(jerr eq 0) then begin
    sel_type='Default'
    err=0
    goto,fini
  endif else begin
    name_out='NULL'
    sel_type='NULL'
    err=2
  endelse

endelse

fini:

end
