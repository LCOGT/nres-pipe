pro run_muncha0,flist,flatk=flatk
; This routine reads a list of input filenames, and runs muncha.pro on
; each.

openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  ss=''
  readf,iun,ss
  fname=strtrim(ss,2)
  muncha,fname,trp=0,tharlist='mtchThAr.txt',/cubfrz,oskip=[0],flatk=flatk
endwhile

close,iun
free_lun,iun

end
