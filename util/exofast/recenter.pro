;+
; NAME:
;   RECENTER
;
; PURPOSE: 
;   Recenters a distribution of periodic parameters to the domain
;      (mode-period/2,mode+period/2]
;
; CALLING SEQUENCE:
;   par = recenter(par,period)
;
; INPUTS:
;   PAR    = An array of parameters
;   PERIOD = The period of the parameter distribution
;
; EXAMPLE:
;
; MODIFICATION HISTORY
;  2012/06 -- Jason Eastman (LCOGT)
;-

function recenter, par, period

hist = histogram(par,nbins=100,locations=x)
max = max(hist,modendx)
mode = x[modendx]

repeat begin
   toohigh = where(par gt (mode + period/2d0))
   if toohigh[0] ne -1 then par[toohigh] -= period
endrep until toohigh[0] eq -1

repeat begin
   toolow = where(par le (mode - period/2d0))
   if toolow[0] ne -1 then par[toolow] += period
endrep until toolow[0] eq -1

return, par

end
