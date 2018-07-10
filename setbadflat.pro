pro setbadflat,flatfile
; This routine reads the file standards.csv, and locates the line (if any)
; referring to obstype=FLAT, site=site, camera=camera, and mjdd=mjdc +/- .0001,
; (all referring to current values in nres_comm.
; If the line is found, then its flag character 1 (the "do not use" flag) is
; set to 1, and standards.csv is rewritten.

@nres_comm
jdthrsh=0.0001d0

; get the standards.csv table
stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr 

; identify the line in question
s=where(fnames eq flatfile,ns)

; change the flags string
if(ns ne 0) then begin         ; if not, then exit
  flagin=flags(s(0))       ; explicitly take 1st element, just in case
  strput,flagin,'1',0
  flags(s(0))=flagin
; write out modified standards.csv
  stds_write,types,fnames,navgs,sites,cameras,jdates,flags,hdrs

endif

end
