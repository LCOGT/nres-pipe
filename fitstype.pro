pro fitstype,flist
; This routine reads a list of fits filenames, opens each fits file, and
; prints a line for each giving values of the OBSTYPE, OBJECTS, and EXPTIME
; keywords.

openr,iun,flist,/get_lun
ss=''
files=['']
while(not eof(iun)) do begin
  readf,iun,ss
  files=[files,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
files=files(1:*)
nfiles=n_elements(files)

type=strarr(nfiles)
objs=strarr(nfiles)
exptime=fltarr(nfiles)

for i=0,nfiles-1 do begin
  dd=readfits(files(i),hdr,/silent)
  type(i)=strtrim(sxpar(hdr,'OBSTYPE'),2)
  objs(i)=strtrim(sxpar(hdr,'OBJECTS'),2)
  exptime(i)=sxpar(hdr,'EXPTIME')
endfor

for i=0,nfiles-1 do begin
  print,files(i),'  ',type(i),'  ',objs(i),'  ',exptime(i)
endfor

end
