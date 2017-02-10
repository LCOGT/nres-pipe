pro zeros_addline,fname,navg,site,camera,jdate,targname,teff,logg,bmv,jmk,flag
; Reads the zeros.csv file, appends a line containing the data in the
; argument list, sorts the resulting list into increasing time order,
; and writes the result back out to zeros.csv.
; Calling this routine with no arguments causes the zeros.csv file
; to be sorted into time order, without otherwise changing it.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
zerofile=nresrooti+'reduced/csv/zeros.csv'

zeros_rd,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags,zerohdr

if(n_params() eq 11) then begin
  fnames=strcompress([fnames,fname],/remove_all)
  navgs=long([navgs,navg])
  sites=strtrim([sites,site],2)
  cameras=strtrim([cameras,camera],2)
  jdates=[jdates,jdate]
  targnames=strupcase(strcompress([targnames,targname],/remove_all))
  teffs=float([teffs,teff])
  loggs=float([loggs,logg])
  bmvs=float([bmvs,bmv])
  jmks=float([jmks,jmk])
  flags=strtrim([flags,flag],2)
endif

; check to see if dates are already sorted.  If not, sort them
if(max(jdates) ne jdate) then begin
  so=sort(jdates)
  types=types(so)
  fnames=fnames(so)
  navgs=navgs(so)
  sites=sites(so)
  cameras=cameras(so)
  jdates=jdates(so)
  teffs=teffs(so)
  loggs=loggs(so)
  bmvs=bmvs(so)
  jmks=jmks(so)
  flags=flags(so)
endif

datstr={f1:fnames,f2:navgs,f3:sites,f4:cameras,f5:jdates,f6:targnames,$
        f7:teffs,f8:loggs,f9:bmvs,f10:jmks,f11:flags}
write_csv,zerofile,datstr,header=zerohdr

end
