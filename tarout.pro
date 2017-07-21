pro tarout,tarlist,tarpath
; This routine creates a directory tardirsssyyyyddd.fffff in the directory 
; specified in tarpath
; (usually nresrooti+'tar/').  It then copies all of the files listed in the 
; string array tarlist into this directory, and creates a compressed tarball of 
; the entire  directory named with all the trailing site & date info as in
; the tar directory.
; Having made the tarball, it deletes the directory it just tarred.
; Last, it appends the full pathname to the tarball to a file 
; named 'beammeup.txt' in the reduced/tar directory.
; The wrapper should, at some point, archive all of the files pointed to by
; beammeup, remove these files from the reduced/tar directory, and remove
; the file beammeup.txt.

; check to see that tarlist contains at least 1 entry, and at least one
; with the substring 'EXTR' in its name.
nf=n_elements(tarlist)
ix=-1
if(nf ge 1) then begin
  for i=0,nf-1 do begin
    pos=strpos(tarlist(i),'EXTR')
    if(pos ge 0) then begin
      ix=i
      break
    endif
  endfor
endif

if(ix lt 0) then goto,fini           ; didn't find an 'EXTR' filename

epos=strpos(tarlist(ix),'.fits')
if(epos le 4) then goto,fini         ; nothing in the filename body
body=strmid(tarlist(ix),pos+4,epos-pos-4)

; make directory to hold files to be tarred.  
dirpath=tarpath+'/tardir'+body

; check for existence of dirpath directory.  If nonexistent, create it.
status=file_test(dirpath,/directory)
if(~status) then begin
  cmd1='mkdir '+dirpath
  spawn,cmd1
endif

for i=0,nf-1 do begin
  curfile=tarlist(i)
  cmd2='cp '+curfile+' '+dirpath
  spawn,cmd2
endfor

; tar the directory
tarfname=tarpath+'/TAR'+strtrim(body,2)+'.tar.gz'
cmd3='tar -czf '+tarfname+' '+dirpath
spawn,cmd3

; write out the tarball's name 
openw,iun,tarpath+'/beammeup.txt',/get_lun,/append
printf,iun,tarfname
close,iun
free_lun,iun

; remove the directory we just tarred
cmd4='rm -r '+dirpath
spawn,cmd4

fini:

end
