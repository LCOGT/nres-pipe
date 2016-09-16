function airlam,lam,z0
; This routine returns lam(vacuum), with input lam(air) in microns,
; with pressure such that n(NaD = 0.589 micron)=1.+z0.
; For dry air at STP, set z0 = 0.000295
; result is returned in a double-precision vector

lamm2=1./lam^2
nam2=1./0.589d0^2
zs=0.05792105d0/(238.0185d0-lamm2) + 0.00167917d0/(57.362d0-lamm2) 
zna=0.05792105d0/(238.0185d0-nam2) + 0.00167917d0/(57.362d0-nam2) 

zair=zs*z0/zna

return,lam*(1.d0+zair)

end
