;+
; NAME:
;   ROUND5
;
; PURPOSE: 
;   Rounds a value to the nearest 5 in the second significant
;   digit. Useful for plotting.
;
; CALLING SEQUENCE:
;    result = round5(value)
;
; INPUTS:
;    VALUE - A number to be rounded
;
; RESULT:
;    The rounded number
;
; MODIFICATION HISTORY
; 
;  2012/06 -- Public release -- Jason Eastman (LCOGT)
;-
function round5, value

if value eq 0d0 then return, 0d0

if value lt 0 then begin
    sign = '-'
    value = -value
endif else sign = ''

explo=long(alog10(value))
if (value lt 1d0) then explo=explo-1

tmp = value/10.d0^(explo-1d0)/5d0
if tmp lt 0 then tmp = floor(tmp,/l64)*5 $
else tmp = ceil(tmp,/l64)*5

roundlo=ceil(tmp)*10.d0^(explo-1d0)
if (roundlo gt 10) then rounded = sign + strtrim(ceil(roundlo,/L64),2) $
else rounded = sign + $
               strtrim(string(roundlo,format='(f255.'+strtrim(1-explo,2)+')'),2)

return, double(rounded)

end
