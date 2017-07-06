pro fill_badblock,badpts,dat
; This routine accepts 
; badpts = a list of the indices of bad data points
; dat(npts) = a data vector.
; It replaces each contiguous string (possibly of length 1) of bad points
; with the mean value of the points just before and just after the bad string.
; If a string start or end point falls on a boundary, the replacement value
; is the next internal point.

npts=n_elements(dat)
bpe=[-2L,badpts,npts+1]       ; extend the badpoints array beyond natural bounds
nbp=n_elements(badpts)+2
indx=lindgen(npts+1)-1
dato=dat

; identify beg and end of bad point strings
bpep=shift(bpe,1)
bpem=shift(bpe,-1)
difm=bpe-bpep         ; >1 -> this is a first bad point          
difp=bpem-bpe         ; >1 -> this is a last bad point

sbeg=where(difm(1:nbp-2) gt 1,nsbeg)
pbeg=badpts(sbeg)
send=where(difp(1:nbp-2) gt 1,nsend)
pend=badpts(send)

if(nsbeg gt 0) then begin
  for i=0,nsbeg-1 do begin
    if(pbeg(i) le 0) then dato(pbeg(i):pend(i))=dat(pend(i)+1)
    if(pend(i) ge npts-1) then dato(pbeg(i):pend(i))=dat(pbeg(i)-1)
    if(pbeg(i) gt 0 and pend(i) lt npts-1) then dato(pbeg(i):pend(i)) = $
        (dat(pbeg(i)-1)+dat(pend(i)+1))/2.
  endfor
endif

dat=dato

end
