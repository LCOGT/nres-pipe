pro targs_rmlines,indx
; Reads the targets.csv file, deletes all of the lines identified in the
; index array indx (presumably generated by a "where" statement), and
; writes the result back out to zeros.csv

targs_rd,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr

nl=n_elements(nnames)
igood=intarr(nl)+1
igood(indx)=0
s=where(igood eq 1,ns)
if(ns gt 0) then begin
  names=names(s)
  ras=ras(s)
  decs=decs(s)
  vmags=vmags(s)
  bmags=bmags(s)
  gmags=gmags(s)
  rmags=rmags(s)
  imags=imags(s)
  jmags=jmags(s)
  kmags=kmags(s)
  pmras=pmras(s)
  pmdecs=pmdecs(s)
  plaxs=plaxs(s)
  rvs=rvs(s)
  teffs=teffs(s)
  loggs=loggs(s)
  zeros=zeros(s)
endif

targs_write,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,logg,zeros

end
