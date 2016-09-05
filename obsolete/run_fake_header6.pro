pro run_fake_header6,flist
; This routine runs fake_header6 on a list of files.  Modified files
; overwrite the inputs.

openr,iun,flist,/get_lun
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  filin=strtrim(ss,2)
  fake_header6,filin,filin
endwhile

close,iun
free_lun,iun

end
