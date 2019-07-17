pro run_avgdoub,flist
; This routine runs avg_doub2trip_1 on a list of pairs of files, 
; one each from fibers 0 and 2, contained in the ascii file flist.

openr,iun,flist,/get_lun
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  words=get_words(ss,nw)
  fil01=strtrim(words(0),2)
  fil12=strtrim(words(1),2)
  avg_doub2trip_1,[fil01,fil12],/array
endwhile

close,iun
free_lun,iun

end
