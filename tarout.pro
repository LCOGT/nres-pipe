pro tarout,tarlist,tarpath
; This routine creates a directory tardir in the directory specified in tarpath
; (usually nresrooti+'tar/').  It then copies all of the files listed in the 
; string array tarlist into this directory, and creates a compressed tarball of 
; the entire  directory named after the EXTR file in the directory.  
; Last, it creates a file named 'beammeup.txt' in the reduced/tar directory,
; containing the full pathname to the tarball.

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

stop

if(ix lt 0) then goto,fini           ; didn't find an 'EXTR' filename

epos=strpos(tarlist(ix),'.fits')
if(epos le 4) then goto,fini         ; nothing in the filename body
body=strmid(tarlist(ix),pos+4,epos-4)

; make directory to hold files to be tarred.
dirpath=tarpath+'/tardir'
cmd1='mkdir '+dirpath
stop
spawn,cmd1

for i=0,nf-1 do begin
  curfile=tarlist(i)
  cmd2='cp curfile dirpath'
  stop
  spawn,cmd2
endfor

; tar the directory
tarfname=dirpath+'/TAR'+strtrim(body,2)+'.tar.gz'
cmd3='tar -czf '+tarfname+' '+dirpath
stop
spawn,cmd3

; write out the tarball's name 
openw,iun,dirpath+'beammeup.txt',/get_lun
printf,iun,tarfname
close,iun
free_lun,iun

fini:
stop

end
