pro writecombined,combpath,combdat,combhdr,difdat,calblocks,kerrlist
; This routine concatenates the lists of files from combined.csv and from
; the files processed into new supercals, and writes a new combined file
; with a header indicating that it is unlocked.
; On input, combpath = pathname of combined.csv for input/output
; combdat = structure of arrays containing original contents of combined.csv
; combhdr = string containing original combined.csv header
; difdat = structure of arrays containing data for all std files not yet
;          found in combined.csv
; calblocks = array of structures containing info about difdat files after
;             the latter have been organized into chunks suitable for averaging
; kerrlist = array of error flags, one for each chunk in calblocks

; constants
root=getenv('NRESROOT')
csvpath=root+'reduced/csv/'
combpath=csvpath+'combined.csv'
temppath=csvpath+'tempout.csv'           ; temporary output file, for testing
openhdr=['OPEN','OPEN','OPEN','OPEN','OPEN','OPEN','OPEN']

;make default output data array = combdat
outdat=combdat
outhdr=openhdr

; go through calblocks, assembling a vector showing which difdat files
; have and have not been used in the output.
nblk=n_elements(calblocks)
nfile=total(calblocks.navg)        ; total number of files referenced
if(nfile le 0) then goto,fini

igood=intarr(nfile)
ii=0                               ; index into igood array
for i=0,nblk-1 do begin
  if(kerrlist(i) eq 0) then begin    ; use only chunks with good error status
    igood(ii:ii+calblocks(i).navg-1)=1 ; these files were used
  endif
  ii=ii+calblocks(i).navg
endfor
sg=where(igood eq 1,nsg)

if(nsg gt 0) then begin
  field1=[outdat.field1,difdat.field1(sg)]
  field2=[outdat.field2,difdat.field2(sg)]
  field3=[outdat.field3,difdat.field3(sg)]
  field4=[outdat.field4,difdat.field4(sg)]
  field5=[outdat.field5,difdat.field5(sg)]
  field6=[outdat.field6,difdat.field6(sg)]
  field7=[outdat.field7,difdat.field7(sg)]
  outdat={field1:field1,field2:field2,field3:field3,field4:field4,$
          field5:field5,field6:field6,field7:field7}
endif

fini:
;stop
write_csv,temppath,outdat.field1,outdat.field2,outdat.field3,outdat.field4,$
    outdat.field5,outdat.field6,outdat.field7,header=outhdr

end
