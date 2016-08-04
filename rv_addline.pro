pro rv_addline,targname,crdate,bjd,site,exptime,orgname,speco,nmatch,amoerr,$
      rmsgood,mgbdisp,rvkmps,ampcc,widcc,lammid,baryshift,rroa,rrom,rroe
; Reads the rv.csv file, appends a line containing the data in the
; argument list, sorts the resulting list into increasing time order,
; and writes the result back out to rv.csv.
; Calling this routine with no arguments causes the standards.csv file
; to be sorted into time order, without otherwise changing it.

nresroot=getenv('NRESROOT')
rvfile=nresroot+'reduced/csv/rv.csv'

rv_rd,targnames,crdates,bjds,sites,exptimes,orgnames,specos,nmatchs,amoerrs,$
      rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammids,baryshifts,$
      rroas,rroms,rroes,rvhdr

if(n_params() eq 19) then begin
  targnames=[targnames,targname]
  crdates=[crdates,crdate]
  bjds=[bjds,bjd]
  sites=[sites,site]
  exptimes=[exptimes,exptime]
  orgnames=[orgnames,orgname]
  specos=[specos,speco]
  nmatchs=[nmatchs,nmatch]
  amoerrs=[amoerrs,amoerr]
  rmsgoods=[rmsgoods,rmsgood]
  mgbdisps=[mgbdisps,mgbdisp]
  rvkmpss=[rvkmpss,rvkmps]
  ampccs=[ampccs,ampcc]
  widccs=[widccs,widcc]
  lammids=[lammids,lammid]
  baryshifts=[baryshifts,baryshift]
  rroas=[rroas,rroa]
  rroms=[rroms,rrom]
  rroes=[rroes,rroe]
endif

; check to see if creation dates are already sorted.  If not, sort them
if(max(crdates) ne crdate) then begin
  so=sort(crdates)
  targnames=targnames(so)
  crdates=crdates(so)
  bjds=bjds(so)
  sites=sites(so)
  exptimes=exptimes(so)
  orgnames=orgnames(so)
  specos=specos(so)
  nmatchs=nmatchs(so)
  amoerrs=amoerrs(so)
  rmsgoods=rmsgoods(so)
  mgbdisps=mgbdisps(so)
  rvkmpss=rvkmpss(so)
  ampccs=ampccs(so)
  widccs=widccs(so)
  lammids=lammids(so)
  baryshifts=baryshifts(so)
  rroas=rroas(so)
  rroms=rroms(so)
  rroes=rroes(so)
endif

; make structure to contain the data
data={field01:targnames,field02:crdates,field03:bjds,field04:sites,$
      field05:exptimes,$
      field06:orgnames,field07:specos,field08:nmatchs,field09:amoerrs,$
      field10:rmsgoods,field11:mgbdisps,field12:rvkmpss,field13:ampccs,$
      field14:widccs,field15:lammids,field16:baryshifts,$
      field17:rroas,field18:rroms,field19:rroes}

write_csv,rvfile,data,header=rvhdr

end
