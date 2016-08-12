pro svdinvrt,a,minrat,ai,numc=numc
; Uses SV decomposition to invert the matrix a. Inverse is returned in
; ai.  Uses IDL built-in command svdcmp and svsol.
; Singular values smaller than minrat*(largest singular value) are set
; to zero before the inversion.
; If keyword numc is set, at most numc nonzero singular values are retained

sz=size(a)
nx=sz(1)
if(sz(0) ne 2 or sz(1) ne sz(2)) then begin
  print,'matrix must be square and 2D in svdinvrt'
  goto,fini
endif

svdc,a,w,u,v
s=where(w lt max(w)*minrat,ns)
if(ns gt 0) then w(s)=0.
if(keyword_set(numc)) then begin
  if(numc lt nx) then w(numc:nx-1)=0.
endif

ai=fltarr(nx,nx)
for i=0,nx-1 do begin
  c=fltarr(nx)
  c(i)=1.
  ai(i,*)=reform(svsol(u,w,v,c),1,nx)
endfor

fini:
end
