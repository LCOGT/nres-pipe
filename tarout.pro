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
    pos=strpos(tarlist(i),'SPEC')
    if(pos ge 0) then begin
      ix=i
      break
    endif
  endfor
endif

if(ix lt 0) then begin
  filelist_to_print = strjoin(tarlist, ',')
  logo_nres2,rutname,'ERROR','No spectrum file found in list of files to tar: ' + filelist_to_print
  goto,fini           ; didn't find an 'SPEC' filename
endif
epos=strpos(tarlist(ix),'.fits')
if(epos le 4) then goto,fini         ; nothing in the filename body
body=strmid(tarlist(ix),pos+4,epos-pos-4)


fits_read, tarlist[ix], data, hdr
orig_name = sxpar(hdr, 'ORIGNAME')
reduced_name = strtrim(strjoin(strsplit(orig_name, 'e00',/extract, /regex)) + 'e91',2)

; make directory to hold files to be tarred.  
dirpath=tarpath+reduced_name+'/'

; check for existence of dirpath directory.  If nonexistent, create it.
status=file_test(dirpath,/directory)
if(~status) then begin
  cmd1='mkdir '+dirpath
  spawn,cmd1
endif

for i=0,nf-1 do begin
  curfile=tarlist[i]
  filename = file_basename(curfile)
  if strpos(filename, 'SPEC') ge 0 then begin
    output_filename=reduced_name +'.fits'
  endif else if strpos(filename, 'EXTR') ge 0 then begin
    output_filename= reduced_name + '-noflat.fits'
  endif else if strpos(filename, 'BLAZ') ge 0 then begin
    output_filename= reduced_name + '-blaze.fits'
  endif else begin
    output_filename = filename
  endelse
  cmd2='cp '+curfile+' '+dirpath+output_filename
  spawn,cmd2
endfor

; tar the directory
cd, dirpath, current=orig_dir

; fpack the files
data_files = file_search('*.fits')
foreach file, data_files do begin
  logo_nres2,'tarout','INFO','Fpacking ' + file
  spawn, 'fpack -q 64 ' + file
  spawn, 'rm -f ' + file
endforeach

cd, '..'
cmd3='tar --warning=no-file-changed -czf '+reduced_name+'.tar.gz '+reduced_name

spawn,cmd3

; write out the tarball's name 
openw,iun,'beammeup.txt',/get_lun,/append
printf,iun,tarpath + reduced_name + 'tar.gz'
close,iun
free_lun,iun

; remove the directory we just tarred
cmd4='rm -r '+reduced_name
spawn,cmd4

cd, orig_dir
fini:

end
