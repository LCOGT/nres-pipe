pro ts2med,fnames,ts2,roall
; This routine accepts fnames, a string array of RADV fits files, nt in number.
; For each file it computes two median values of the redshift, excluding
; zeros.  The median time series, returned in array ts2(nt,4), correspond to 
; 0=blocks 0-5 and 1= blocks 6-11, both with zeroes in the roall array ignored.
; 2=blocks 0-5 and 3= blocks 6-11, with both zeroes and bad orders ignored
; also returned is roall(nord,nblock,nt), containing the redshifts by order
; and block for each time, for fiber=1.

; loop over input files
;openr,iun,flist,/get_lun
;ss=''
;fnames=['']
;ii=0
;while(not eof(iun)) do begin
  ;readf,iun,ss
  ;fnames=[fnames,strtrim(ss,2)]
  ;ii=ii+1
;endwhile
;close,iun
;free_lun,iun

;fnames=fnames(1:*)
nt=n_elements(fnames)

ts2=dblarr(nt,4)

; prepare to ignore data from orders 0:24, 55:66.
xord=findgen(67)
xord=rebin(xord,67,12)
pbad=dblarr(67,12)
pbad(0:24,*)=1.d0
pbad(55:*,*)=1.d0
roall=dblarr(67,12,nt)

for i=0,nt-1 do begin
  fxbopen,unit,fnames(i),1,hdr
  fxbread,unit,rr,'RedShft'
  fxbclose,unit
  u0=rr(1,*,0:5)          ; data from lower half of blocks
  u1=rr(1,*,6:11)         ; data from upper half of blocks
  s0=where(u0 ne 0.,ns0)  ; u0 maybe good
  t0=where(u0 eq 0.,nt0)  ; u0 already flagged as bad
  s1=where(u1 ne 0.,ns0)  ; u1 maybe good
  t1=where(u1 eq 0.,nt1)  ; u1 already flagged as bad
  p0=pbad(*,0:5)
  if(nt0 gt 0) then p0(t0)=1.  ; =1 if bad order or bad data point
  p1=pbad(*,6:11)
  if(nt1 gt 0) then p1(t1)=1.  ; =1 if bad order or bad data point
  ts2(i,0)=median(u0(s0))
  ts2(i,1)=median(u1(s1))
  s2=where(p0 eq 0)   ; points in u0 that are neither 0 or bad order
  s3=where(p1 eq 0)   ; ditto for u1
  ts2(i,2)=median(u0(s2))
  ts2(i,3)=median(u1(s3))
  roall(*,*,i)=reform(rr(1,*,*))
endfor

end
