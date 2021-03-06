pro stds_rmlines,indx
; Reads the zeros.csv file, deletes all of the lines identified in the
; index array indx (presumably generated by a "where" statement), and
; writes the result back out to zeros.csv

zeros_rd,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags
nl=n_elements(fnames)
igood=intarr(nl)+1
igood(indx)=0
s=where(igood eq 1,ns)
if(ns gt 0) then begin
  fnames=fnames(s)
  navgs=navgs(s)
  sites=sites(s)
  cameras=cameras(s)
  jdates=jdates(s)
  targnames=targnames(s)
  teffs=teffs(s)
  loggs=loggs(s)
  bmvs=bmvs(s)
  jmks=jmks(s)
  flags=flags(s)
endif

zeros_write,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,$
    bmvs,jmks,flags

end
