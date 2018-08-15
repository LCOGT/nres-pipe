pro run_ch,flist,plot=plot
; reads a list of flat files from flist, tests each with 
; test_flat, and prints the results.

openr,iun,flist,/get_lun
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  fname=strtrim(ss,2)
  flat=readfits(fname,hdr,/silent)
  fib0=sxpar(hdr,'FIB0')
  fib1=sxpar(hdr,'FIB1')
  nfravgd=sxpar(hdr,'NFRAVGD')
  g=check_flat(flat,hdr)
  print,fname,'  ',g,' fib0, fib1, nfravgd =',fib0,fib1,nfravgd

  if(keyword_set(plot)) then begin
  !p.multi=[0,3,1]
  for i=0,2 do begin
    plot,flat(*,35,i),yran=[0,1.2]
  endfor
  aa=''
  read,aa
  endif

endwhile

close,iun
free_lun,iun

end
