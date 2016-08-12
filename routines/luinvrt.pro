pro luinvrt,a,ai
; Uses LU decomposition to invert the matrix a. Inverse is returned in
; ai.  Uses IDL built-in command ludcmp and lubksb.

sz=size(a)
nx=sz(1)
if(sz(0) ne 2 or sz(1) ne sz(2)) then begin
  print,'matrix must be square and 2D in luinvrt'
  goto,fini
endif

b=a
ludc,b,index

ai=fltarr(nx,nx)
for i=0,nx-1 do begin
  c=fltarr(nx)
  c(i)=1.
  ai(i,*)=reform(lusol(b,index,c),1,nx)
endfor

fini:
end
