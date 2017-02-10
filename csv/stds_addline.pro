pro stds_addline,type,fname,navg,site,camera,jdate,flag
; Reads the standards.csv file, appends a line containing the data in the
; argument list, sorts the resulting list into increasing time order,
; and writes the result back out to standards.csv.
; Calling this routine with no arguments causes the standards.csv file
; to be sorted into time order, without otherwise changing it.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
stdfile=nresrooti+'reduced/csv/standards.csv'

stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr

if(n_params() eq 7) then begin
  types=[types,type]
  fnames=[fnames,fname]
  navgs=[navgs,navg]
  sites=[sites,site]
  cameras=[cameras,camera]
  jdates=[jdates,jdate]
  flags=[flags,flag]
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
  flags=flags(so)
endif

write_csv,stdfile,types,fnames,navgs,sites,cameras,jdates,flags,header=stdhdr

end
