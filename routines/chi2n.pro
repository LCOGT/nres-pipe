function chi2n,x,sig,k
; This routine returns the normalized chi^2 density with
; k degrees of freedom, sampled on the grid x, with variance f sig^2.

u=x/sig

nk=k/2.-1.
if(nk le 0.) then begin
  fk=1.
endif else begin
  fk=exp(nk*alog(nk))
endelse
f2=1./2.^(k/2.)
uf=u^(k/2.-1.)
ef=exp(-u/2.)

f=fk*f2*uf*ef
return,f

end
