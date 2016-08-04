pro order_cen,trace,ord_vectors
; This routine finds the cordat corrected data array
; in the nres_common data area
; and computes the trace vector array
; ord_vectors(nx,nord,nfib), containing the order center positions
; vs x, order, fiber.

@nres_comm

; get sizes of things
sz=size(cordat)
nx=sz(1)
ny=sz(2)

szt=size(trace)
nleg=szt(1)           ; No of legendre polys defined for each order
nord=szt(2)           ; No of orders

; make output data array, legendre functions
ord_vectors=fltarr(nx,nord,3)       ; always compute for 3 fibers
x=2.*(findgen(nx)-nx/2.)/nx         ; x in range [-1,1]
yord=fltarr(nx,nleg)               ; to hold the Legendre functions
for i=0,nleg-1 do begin
  yord(*,i)=legendre(x,i)
endfor

; make order center positions
for i=0,nord-1 do begin
  for j=0,nfib-1 do begin
    for k=0,nleg-1 do begin
      ord_vectors(*,i,j)=ord_vectors(*,i,j)+yord(*,k)*trace(k,i,j)
    endfor
  endfor
endfor

end
