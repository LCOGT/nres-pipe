pro fibcoefs_rd,sites,jdates,cameras,fibcoefs,fibhdr
; Reads the contents of NRES file fibcoefs.csv and returns the column
; vector values in arrays sites,jdates,cameras,fibcoefs.
; Column names are returned in the string array stdhdr.

nresroot=getenv('NRESROOT')
;nresrooti=nresroot+getenv('NRESINST')
nresrooti=nresroot+'code/csv/'
fibcoefsfile=nresrooti+'fibcoefs.csv'

dat=read_csv(fibcoefsfile,header=fibhdr)
sites=dat.field01
jdates=dat.field02+2400000.5d0
cameras=dat.field03
fibcoefs=[dat.field04,dat.field05,dat.field06,dat.field07,dat.field08,$
  dat.field09,dat.field10,dat.field11,dat.field12,dat.field13,dat.field14,$
  dat.field15,dat.field16,dat.field17,dat.field18,dat.field19,dat.field20,$
  dat.field21,dat.field22,dat.field23]
nl=n_elements(sites)
fibcoefs=reform(fibcoefs,nl,20)
fibcoefs=transpose(fibcoefs)

end
