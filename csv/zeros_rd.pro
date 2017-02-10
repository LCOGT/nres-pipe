pro zeros_rd,fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,bmvs,jmks,flags,$
   zerohdr
; Reads the contents of NRES file zeros.csv and returns the column
; vector values in arrays fnames,navgs,sites,cameras,jdates,targnames,teffs,loggs,$
; bmvs,jmks,flags.
; Column names are returned in the string array stdhdr.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
zerofile=nresrooti+'reduced/csv/zeros.csv'
zstruc=read_csv(zerofile,header=zerohdr)

; make output data arrays
fnames=zstruc.field01
navgs=zstruc.field02
sites=zstruc.field03
cameras=zstruc.field04
jdates=zstruc.field05
targnames=zstruc.field06
teffs=zstruc.field07
loggs=zstruc.field08
bmvs=zstruc.field09
jmks=zstruc.field10
flags=zstruc.field11

end
