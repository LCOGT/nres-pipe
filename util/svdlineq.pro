pro svdlineq,a,b,minrat,x,numc=numc
; Uses SV decomposition to solve the linear system a#x = b. x is returned in
; array x.  Uses IDL built-in command svdcmp and svsol.
; Singular values smaller than minrat*(largest singular value) are set
; to zero before the back-substitution.
; If keyword numc is set, at most numc nonzero singular values are retained

sz=size(a)
nx=sz(1)
if(sz(0) ne 2 ) then begin
  print,'matrix must be 2D in svdinvrt'
  goto,fini
endif

svdc,a,w,u,v,/double
s=where(w lt max(w)*minrat,ns)
if(ns gt 0) then w(s)=0.
if(keyword_set(numc)) then begin
  if(numc lt nx) then w(numc:nx-1)=0.
endif

print,'Zeroed w vals =',ns
print,'w = ',w

x=svsol(u,w,v,b,/double)

fini:
end
