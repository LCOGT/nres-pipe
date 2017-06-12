pro run_muncha1,flist,flatk=flatk,nostar=nostar
; This routine reads a list of input filenames, and runs muncha.pro on
; each.

openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  ss=''
  readf,iun,ss
  fname=strtrim(ss,2)
  muncha,fname,trp=0,tharlist='mtchThAr.txt',/cubfrz,oskip=[0],flatk=flatk,$
      nostar=nostar
endwhile

close,iun
free_lun,iun

end
