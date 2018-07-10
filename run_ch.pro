pro run_ch,flist
; reads a list of flat files from flist, tests each with 
; test_flat, and prints the results.

openr,iun,flist,/get_lun
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  fname=strtrim(ss,2)
  flat=readfits(fname,hdr,/silent)
  g=check_flat(flat)
  print,fname,'  ',g
endwhile

close,iun
free_lun,iun

end
