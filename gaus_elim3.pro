pro gaus_elim3,a,b,x,ierr,eps=eps
; This routine solves the matrix equation a#x=b where a is an m x m matrix,
; using gauss elimination with partial pivoting.  This is a special-purpose
; code intended to run fast for use in lsqblkfit.pro.
; On exit, ierr=0 means success, 1 = a singular or near-singular matrix.
; If keyword eps is present and not zero, the criterion for the matrix
; being non-singular is that the smallest pivot abs value should be greater 
; than eps*max(a).

; constants
tiny=1.e-20
if(keyword_set(eps)) then tiny=max(abs(a))*eps
ierr=0

; get sizes of things
sz=size(a)
m=sz(1)
n=m+1

; check for the fairly common error case of all elements=0.
if(max(abs(a)) eq 0.) then begin
  ierr=1
  x=findgen(m)
  goto, fini
endif

; make augmented matrix, index array
aa=fltarr(n,m)
aa(0:m-1,*)=a
aa(n-1,*)=reform(b,1,m)

for k=0,2 do begin        ; loop over number of rows.
; test for singularity (or near singularity)
  imax=max(abs(aa(k,k:m-1)),ix)
  if(imax le tiny) then begin
    x=fltarr(m)
    ierr=1
    goto,fini
  endif

; swap rows to bring max pivot to top
  if(ix gt k) then begin
    t=aa(*,k)
    aa(*,k)=aa(*,ix)
    aa(*,ix)=t
  endif

; do for all rows below pivot
  for i=k+1,m-1 do begin       ; i indexes over rows below the pivot
    f=aa(k,i)/aa(k,k)
    for j=k,n-1 do begin      ; j indexes over columns, including last
      aa(j,i)=aa(j,i) - aa(j,k)*f
    endfor
  endfor
endfor

; Back substitute to give solution vector.
x=fltarr(m)
for i=m-1,0,-1 do begin
  x(i)=aa(n-1,i)
  for j=i+1,m-1 do begin
    x(i)=x(i)-aa(j,i)*x(j)
  endfor
  x(i)=x(i)/aa(i,i)
endfor

fini:

end
