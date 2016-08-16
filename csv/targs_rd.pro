pro targs_rd,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr
; Reads the contents of NRES file targest.csv and returns the column
; vector values in arrays names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,
; pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros
; Column names are returned in the string array targhdr.

nresroot=getenv('NRESROOT')
targfile=nresroot+'reduced/csv/targets.csv'

tstruc=read_csv(targfile,header=targhdr)

; make output data arrays
names=tstruc.field01
ras=tstruc.field02
decs=tstruc.field03
vmags=tstruc.field04
bmags=tstruc.field05
gmags=tstruc.field06
rmags=tstruc.field07
imags=tstruc.field08
jmags=tstruc.field09
kmags=tstruc.field10
pmras=tstruc.field11
pmdecs=tstruc.field12
plaxs=tstruc.field13
rvs=tstruc.field14
teffs=tstruc.field15
loggs=tstruc.field16
zeros=tstruc.field17

end
