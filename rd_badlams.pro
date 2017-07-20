pro rd_badlams,nent,etype,elam,ehwid,ehht
; This routine reads the file badlams.txt from directory
; $NRESROOT/$NRESINST/reduced/config/badlams.txt, and returns its contents
; in arrays etype(nent), elam(nent), ehwid(nent), ehht(nent)

compile_opt hidden

; constants
nresroot=getenv('NRESROOT')
nresinst=getenv('NRESINST')
nresrooti=nresroot+'/'+nresinst
path=nresrooti+'/reduced/config/badlams.txt'

; open the file, read the 2 header lines
ss=''
openr,iun,path,/get_lun
readf,iun,ss
readf,iun,ss

; set up empty output arrays
etype=['']
elam=[0.d0]
ehwid=[0.]
ehht=[0.]

; read the data
while(not eof(iun)) do begin
  readf,iun,ss
  words=get_words(ss,nwords)
  if(nwords lt 3) then begin
    print,'Bad input line in rd_badlam:'
    print,ss
    stop
  endif
  etype=[etype,string(words(0))]
  elam=[elam,double(words(1))]
  ehwid=[ehwid,float(words(2))]
  if(nwords ge 4) then begin
    ehht=[ehht,long(words(3))]
  endif else begin
    ehht=[ehht+0L]
  endelse

endwhile

close,iun
free_lun,iun

etype=etype(1:*)
elam=elam(1:*)
ehwid=ehwid(1:*)
ehht=ehht(1:*)
nent=n_elements(etype)

end
