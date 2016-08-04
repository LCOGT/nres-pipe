function mylegendre,x,ord
; This function returns the legendre polynomial of order ord, evaluated
; at the values x (which may be a vector), for orders 0-4 ONLY.
; Unlike the IDL legendre function, this one does not throw an error
; for |x| > 1, allowing its use (with caution) on the extended arrays
; used in, eg, lambda3ofx.pro

if(ord lt 0 or ord gt 4) then begin
  print,'mylegendre requires 0 <= ord <= 4'
  y=x-x            ; return all zeros
  goto,fini
endif

case ord of
  0: y=x-x+1.
  1: y=x
  2: y=(3.*x^2-1.)/2.
  3: y=(5.*x^3-3.*x)/2.
  4: y=(35*x^4-30.*x^2+3.)/8.
endcase

fini:
return,y

end
