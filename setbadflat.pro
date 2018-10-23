pro setbadflat,flatfile
; This routine reads the file standards.csv, and locates the line (if any)
; referring to obstype=FLAT, fname eq flatfile
; (all referring to current values in nres_comm).
; If the line is found, then its flag character 0 (the "do not use" flag) is
; set to 1, and standards.csv is rewritten.

@nres_comm

; get the standards.csv table
stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr 

; identify the line in question
s=where(fnames eq flatfile,ns)

; change the flags string
if(ns ne 0) then begin         ; if not, then exit
  flagin=flags(s(0))       ; explicitly take 1st element, just in case
  strput,flagin,'1',0
  flags(s(0))=flagin

; if there is more than one match, then remove all matching lines but the first
  nlines=n_elements(fnames)
  nondup=intarr(nlines)+1
  if(ns ge 2) then begin
    nondup(s(1:ns-1))=0
  endif
  sg=where(nondup eq 1)
    
; write out modified standards.csv
  stds_write,types(sg),fnames(sg),navgs(sg),sites(sg),cameras(sg),jdates(sg),$
      flags(sg),stdhdr

endif

end
