pro stds_rd_1,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr,inst=inst
; Reads the contents of NRES file standards.csv and returns the column
; vector values in arrays types,fnames,navgs,sites,cameras,jdates,flags.
; Column names are returned in the string array stdhdr.
; If keyword inst is set, its value is used in place of the environment
; variable NRESINST.

nresroot=getenv('NRESROOT')
if(keyword_set(inst)) then begin
  nresrooti=nresroot+inst
endif else begin
  nresrooti=nresroot+getenv('NRESINST')
endelse
stdfile=nresrooti+'reduced/csv/standards.csv'

dat=read_csv(stdfile,header=stdhdr)
types=dat.field1
fnames=dat.field2
navgs=dat.field3
sites=dat.field4
cameras=dat.field5
jdates=dat.field6
flags=dat.field7

end
