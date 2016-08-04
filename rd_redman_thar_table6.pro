pro rd_redman_thar_table6,tharlam,lamerr,bright
; This routine reads Redman et al's Table 6, and returns 3 vectors:
;  tharlam = vacuum Ritz wavelength (AA) of lines between 3800 and 8700 AA.
;  err = uncertainty in wavelength (AA)
;  bright = relative intensity of each line, measured somehow.

; constants
filin='~/Thinkpad2/nres/Redman_thar_table6.txt'

openr,iun,filin,/get_lun
ss=''
readf,iun,ss          ; get past the header
readf,iun,ss
readf,iun,ss
nline=0
while(not eof(iun)) do begin
  readf,iun,ss
  nline=nline+1
endwhile
point_lun,iun,0
readf,iun,ss
readf,iun,ss
readf,iun,ss

tharlam=dblarr(nline)
lamerr=fltarr(nline)
bright=fltarr(nline)
for i=0,nline-1 do begin
  readf,iun,ss
  words=get_words(ss,nw)
  tharlam(i)=double(words(2))
  lamerr(i)=float(words(3))
  bright(i)=float(words(6))
endfor

; select wavelength range
s1=where(tharlam ge 3800. and tharlam le 8700.,ns1)
tharlam=tharlam(s1)
lamerr=lamerr(s1)
bright=bright(s1)
close,iun
free_lun,iun

end
