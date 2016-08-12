function assoc_leg,l,m,x,inorm=inorm
; This routine returns the associated Legendre polynomial
; Plm(x) evaluated at the points in vector x (which must lie in
; the range -1.+1.e-6 to 1.-1.e-6), for the given l and m values
; Normalization is such that int Plm^2 dx = 4/(1 + delta(m,0)).
; (This is JCD's inorm=2), unless keyword inorm is set, in which
; case the Plm is normalized so that its maximum absolute value is 1.0.
; Method is recursion in l starting at l=m.
; This is a crude port (with fewer features) of JCD's vplm routine.

dxm=1.e-6
xx=(x > (-1.+dxm)) < (1.-dxm)
nx=n_elements(xx)
wrk=fltarr(nx,3)

; initialize at l=m
wrk(*,2)=(sqrt(1-xx^2))^m

; normalization
fct=2.*m+1.
if(m gt 1) then begin
  for k=2,m do begin
    fct=fct*(2*k-1)/float(2*k)
  endfor
endif
fct=sqrt(fct)

; multiply by normalization
wrk(*,2)=wrk(*,2)*fct

;initialize iw3 and lp
iw1=0
iw2=1
iw3=2
lp=m

; if l = m we're done
if(l eq m) then goto,fini

; if not, do recursion
lp1=lp+1
for k=lp1,l do begin

; increment storage indices
  iw1=iw2
  iw2=iw3
  iw3=((iw3+1) mod 3)

;set factors
  fc1=(2*k+1)/float((k+m)*(k-m))
  fc2=0
  if(k gt 1) then fc2=sqrt(fc1*(k-1+m)*(k-1-m)/float(2*k-3))
  fc1=sqrt(fc1*(2*k-1))

; set first term
  wrk(*,iw3)=fc1*x*wrk(*,iw2)

; when k = m+1 this is all, otherwise add second term
  if(k ne m+1) then begin
    wrk(*,iw3)=wrk(*,iw3) - fc2*wrk(*,iw1)
  endif

endfor

fini:
plm=wrk(*,iw3)
if(keyword_set(inorm)) then begin
   maxa=max(abs(plm))
   plm=plm/maxa
endif
;print,'maxa is',maxa
return,plm
;print,'maxa =',maxa
end
