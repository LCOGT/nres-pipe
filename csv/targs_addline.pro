pro targs_addline,name,ra,dec,vmag,bmag,gmag,rmag,imag,jmag,kmag,$
      pmra,pmdec,plax,rv,teff,logg,zero
; Reads the targets.csv file, appends a line containing the data in the
; argument list, sorts the resulting list into increasing RA order,
; and writes the result back out to targets.csv.
; Calling this routine with no arguments causes the targets.csv file
; to be sorted into RA order, without otherwise changing it.

nresroot=getenv('NRESROOT')
targfile=nresroot+'reduced/csv/targets.csv'
targhdr=['Targname','RA','Dec','Vmag','Bmag','gmag','rmag','imag','Jmag','Kmag',$
      'PMRA','PMDE','Plax','RV','Teff','Logg','ZERO']

targs_rd,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr

if(n_params() eq 17) then begin
  names=[names,name]
  ras=[ras,ra]
  decs=[decs,dec]
  vmags=[vmags,vmag]
  bmags=[bmags,bmag]
  gmags=[gmags,gmag]
  rmags=[rmags,rmag]
  imags=[imags,imag]
  jmags=[jmags,jmag]
  kmags=[kmags,kmag]
  pmras=[pmras,pmra]
  pmdecs=[pmdecs,pmdec]
  plaxs=[plaxs,plax]
  rvs=[rvs,rv]
  teffs=[teffs,teff]
  loggs=[loggs,logg]
  zeros=[zeros,zero]
endif

; check to see if RAs are already sorted.  If not, sort them
if(max(ras) ne ra) then begin
  so=sort(ras)
  names=names(so)
  ras=ras(so)
  decs=decs(so)
  vmags=vmags(so)
  bmags=bmags(so)
  gmags=gmags(so)
  rmags=rmags(so)
  imags=imags(so)
  jmags=jmags(so)
  kmags=kmags(so)
  pmras=pmras(so)
  pmdecs=pmdecs(so)
  plaxs=plaxs(so)
  rvs=rvs(so)
  teffs=teffs(so)
  loggs=loggs(so)
  zeros=zeros(so)
endif

dat={f1:names,f2:ras,f3:decs,f4:vmags,f5:bmags,f6:gmags,f7:rmags,f8:imags,$
     f9:jmags,f10:kmags,f11:pmras,f12:pmdecs,f13:plaxs,f14:rvs,f15:teffs,$
     f16:loggs,f17:zeros}
write_csv,targfile,dat,header=targhdr

end
