pro tarzit,filepath
; This routine causes a compressed tarfile to be written into the
; reduced/tar directory, containing the 
; file contained in /reduced/tar pointed to by filepath.  
; This facility is intended to be used by
; routines that make composite calibration files.
; Procedure is to write filepath into /reduced/tar, make a gzipped tar file
; of it in the same directory, append the name of the tarfile to beammeup.txt, 
; and delete the /reduced/tar version of the original datafile.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
tarpath=nresrooti+'reduced/tar/'

; make the name of the copy, copy filepath into it
; also make the name of the tarfile
ix=strpos(filepath,'/',/reverse_search)
nc=strlen(filepath)
copyname=strmid(filepath,ix+1,nc-ix-1)
tarfname=strtrim(copyname,2)+'.tar.gz'
cmd0='cp '+filepath+' '+tarpath+'/'+copyname
spawn,cmd0

; obtain current directory
cmd1='pwd'
spawn,cmd1,startdir

; cd to reduced/tar
cd,tarpath

; write the tarfile
cmd2='tar -czf '+tarfname+' '+copyname
spawn,cmd2

; write the tarfile name into beammeup.txt
openw,iun,tarpath+'/beammeup.txt',/get_lun,/append
printf,iun,tarfname
close,iun
free_lun,iun

; delete copy, return to original cwd
cmd3='rm '+copyname
spawn,cmd3
cd,startdir

end
