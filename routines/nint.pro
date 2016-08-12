function nint,j
; returns the integer nearest to j

nn=n_elements(j)
if(nn eq 1) then begin
  aj=[j]
  jj=aj(0)          ; deals properly with both scalars and vectors
  if(jj ge 0) then ni=fix(jj+0.5) else ni=fix(jj-0.5)
endif else begin
  ni=intarr(nn)
  s=where(j ge 0,qs)
  ns=where(j lt 0,qns)
  if(qs gt 0) then ni(s)=fix(j(s)+0.5)
  if(qns gt 0) then ni(ns)=fix(j(ns)-0.5)
endelse

return,ni
end
