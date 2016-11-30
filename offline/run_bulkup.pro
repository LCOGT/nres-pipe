pro run_bulkup,flist,objects
; This routine is a wrapper for bulkup.pro.  It runs bulkup on each of a list of
; files, contained in the ascii file flist.
; argument objects is a string, eg 'none&thar&thar'.  It is copied into
; the 'OBJECTS' keyword in each file.

ss=''
openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  readf,iun,ss
  filin=strtrim(ss,2)
  bulkup,filin,objects
endwhile

close,iun
free_lun,iun

end
