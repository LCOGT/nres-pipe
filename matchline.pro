pro matchline,n1,lindx1,lparm1,n2,lindx2,lparm2,dw,ds,votes
; This routine searches for matches between the line wavelength pair lists
; lndx1,lparm1 drawn from line lists of length n1,n2.
; Matching box size is dw in wavelength (nm), and ds in separation (nm).
; Matching segments are assigned two votes, one of which is added to the
; intersection of the indices of each of the two stars involved in the
; segment.  The array of votes is returned.

; make the votes array
votes=lonarr(n1,n2)
sz=size(lindx1)
nl1=sz(2)
sz=size(lindx2)
nl2=sz(2)

mean1=reform(lparm1(0,*))
diff1=reform(lparm1(1,*))
mean2=reform(lparm2(0,*))
diff2=reform(lparm2(1,*))

; loop over elements in the 2nd list
for i=0L,nl2-1L do begin
  sg=where(abs(mean1-mean2(i)) le dw and abs(diff1-diff2(i)) le ds,nsg)
  if(nsg gt 0) then begin
    for j=0,nsg-1 do begin
      ib=lindx1(0,sg(j))
      jb=lindx2(0,i)
      iff=lindx1(1,sg(j))
      jff=lindx2(1,i)
      votes(ib,jb)=votes(ib,jb)+1
      votes(iff,jff)=votes(iff,jff)+1
    endfor
  endif
endfor

end
