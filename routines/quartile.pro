pro quartile,f,med,q,dq
; This routine returns the median med, the two quartile points q(2),
; and the full separation between quartile points dq for the input data
; vector f.
; For gaussian-distributed data, dq = rms*1.349

med=median(f)
nn=n_elements(f)
if(nn lt 3) then begin
  print,'Need at least 3 data points to compute quartiles'
  q=[med,med]
  dq=0.
endif else begin
  q=fltarr(2)
  shi=where(f ge med,nshi)
  slo=where(f lt med,nslo)
  if(nslo gt 0) then q(0)=median(f(slo)) else q(0)=f(0)
  if(nshi gt 0) then q(1)=median(f(shi)) else q(1)=f(nn-1)
  dq=q(1)-q(0)
endelse

end
