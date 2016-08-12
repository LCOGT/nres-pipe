pro scrgle,y,t,nu,pow
; Uses Scargle's power spectrum algorithm for unevenly-spaced data.
; On input
;   y  =  observed data
;   t  =  corresponding times
;   nu =  frequencies for which power will be computed
;
; On output
;   pow =  computed power.

; get sizes of things
ny=n_elements(y)
np=n_elements(nu)
pow=fltarr(np)
nuc=nu*2.*!pi
taua=fltarr(np)

; loop over frequencies
for i=0,np-1 do begin
  phi=2.*nuc(i)*t
  st=total(sin(phi))
  ct=total(cos(phi))
  if(nuc(i) ne 0) then tau=atan(st,ct)/(2.*nuc(i)) else tau=0.
  taua(i)=tau
  cw=cos(nuc(i)*(t-tau))
  sw=sin(nuc(i)*(t-tau))
; cw=cos(nuc(i)*t)
; sw=sin(nuc(i)*t)
  syc=total(y*cw)
  sc2=total(cw*cw)
  sys=total(y*sw)
  ss2=total(sw*sw)
  if(sc2 ne 0.) then term1=syc^2/sc2 else term1=0.
  if(ss2 ne 0.) then term2=sys^2/ss2 else term2=0.
  pow(i)=(term1+term2)/2.
endfor

end
