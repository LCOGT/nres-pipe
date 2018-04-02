pro run_muncha1,flist,nostar=nostar,literal=literal,cubfrz=cubfrz
; This routine reads a list of input filenames, and runs muncha.pro on
; each.

openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  ss=''
  readf,iun,ss
  fname=strtrim(ss,2)
; muncha,fname,trp=0,tharlist='mtchThAr.txt',/cubfrz,oskip=[0],$
;     nostar=nostar,literal=literal
  muncha,fname,cubfrz=cubfrz,literal=literal
endwhile

close,iun
free_lun,iun

end
