pro rv_rd,targnames,crdates,bjds,sites,exptimes,orgnames,specos,nmatchs,$
      amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammid,baryshifts,$
      rroas,rroms,rroes,rvhdr

; Reads the contents of NRES file rv.csv and returns the column
; vector values in arrays targnames,bjds,sites,exptimes,orgnames,specos,
; nmatchs,amoerrs,rmsgoods,mgbdisps,rvkmpss,ampccs,widccs,lammid,baryshifts
; Column names are returned in the string array rvhdr.

nresroot=getenv('NRESROOT')
rvfile=nresroot+'reduced/csv/rv.csv'
dat=read_csv(rvfile,header=rvhdr)
targnames=dat.field01
crdates=dat.field02
bjds=dat.field03
sites=dat.field04
exptimes=dat.field05
orgnames=dat.field06
specos=dat.field07
nmatchs=dat.field08
amoerrs=dat.field09
rmsgoods=dat.field10
mgbdisps=dat.field11
rvkmpss=dat.field12
ampccs=dat.field13
widccs=dat.field14
lammid=dat.field15
baryshifts=dat.field16
rroas=dat.field17
rroms=dat.field18
rroes=dat.field19

end
