pro fibcoefs_addline,site,jdate,camera,fibcoef
; Reads the fibcoefs.csv file, appends a line containing the data in the
; argument list, sorts the resulting list into increasing time order,
; and writes the result back out to fibcoefs.csv.
; Calling this routine with no arguments causes the fibcoefs.csv file
; to be sorted into time order, without otherwise changing it.

nresroot=getenv('NRESROOT')
;nresrooti=nresroot+getenv('NRESINST')
nresrooti=nresroot+'code/csv/'                ; keep only one fibcoef.csv file
fibcoefsfile=nresrooti+'fibcoefs.csv'

fibcoefs_rd,sites,jdates,cameras,fibcoefs,hdr

if(n_params() eq 4) then begin
  sites=[sites,site]
  cameras=[cameras,camera]
  jdates=[jdates,jdate]
; for storage in the csv array, fibcoef(10,2) is reformed to a 20-element array
  sz=size(fibcoefs)
  nc=sz(1)
  nl=n_elements(sites)
  fibc=reform(fibcoef)
  fibco=dblarr(nc,nl)
  fibco(*,0:nl-2)=fibcoefs
  fibco(*,nl-1)=fibc
endif

; check to see if dates are already sorted.  If not, sort them
if(max(jdates) ne jdate) then begin
  so=sort(jdates)
  sites=sites(so)
  cameras=cameras(so)
  jdates=jdates(so)
  fibco=fibco(*,so)
endif

; make output structure for write_csv
fibco=transpose(fibco)                       ; make columns into rows
dat={site:sites,jdate:jdates,camera:cameras,fibc00:fibco(*,0),$
 fibc01:fibco(*,1),fibc02:fibco(*,2),fibc03:fibco(*,3),fibc04:fibco(*,4),$
 fibc05:fibco(*,5),fibc06:fibco(*,6),fibc07:fibco(*,7),fibc08:fibco(*,8),$
 fibc09:fibco(*,9),fibc10:fibco(*,10),fibc11:fibco(*,11),fibc12:fibco(*,12),$
 fibc13:fibco(*,13),fibc14:fibco(*,14),fibc15:fibco(*,15),fibc16:fibco(*,16),$
 fibc17:fibco(*,17),fibc18:fibco(*,18),fibc19:fibco(*,19)}

write_csv,fibcoefsfile,dat,header=hdr

end
