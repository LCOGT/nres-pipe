function mychebyshev,x,ord
; This function returns the legendre polynomial of order ord, evaluated
; at the values x (which may be a vector), for orders 0-6 ONLY.
; Unlike the IDL legendre function, this one does not throw an error
; for |x| > 1, allowing its use (with caution) on the extended arrays
; used in, eg, lambda3ofx.pro

compile_opt hidden

if(ord lt 0 or ord gt 6) then begin
  print,'mylegendre requires 0 <= ord <= 4'
  y=x-x            ; return all zeros
  goto,fini
endif

case ord of
  0: y=x-x+1.
  1: y=x
  2: y=(2*x^2-1.)
  3: y=(4.*x^3-3.*x)
  4: y=(8*x^4-8.*x^2+1.)
  5: y=(16.*x^5-20.*x^3+5.*x)
  6: y=(32.*x^6-48.*x^4+18*x^2-1.)
endcase

fini:
return,y

end
