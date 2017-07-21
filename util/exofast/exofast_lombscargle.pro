;+
; NAME:
;   EXOFAST_LOMBSCARGLE
;
; PURPOSE: 
;   This function returns the NMIN best periods determined by a
;   lomb-scargle periodogram. 
; 
; CALLING SEQUENCE:
;   periods = exofast_lombscargle(time, rv [BESTPARS=,
;   SCALE=, NMIN=, MINPERIOD=, MAXPERIOD=,NOSLOPE=, /NYQUIST, /PLOT])
;
; INPUTS:
;   TIME        - A time (eg, BJD_TDB) for each of the RV data points
;   RV          - The RV data points
;
; OPTIONAL OUTPUTS:  
;   BESTPARS    - The best (analytically fit) parameters determined from
;                 the lomb-scargle periodogram (assumes circular orbit).
;   SCALE       - The scale (~error) of the period, determined by the
;                 spacing of the sampling of the periodogram.
;   NMIN        - The number of periods corresponding to chi^2 minima
;                 to return (default=5)
;   MINPERIOD   - The minimum period to explore. Default = 1 unit of
;                 time (typically days). This value is not used if
;                 /NYQUIST is set.
;   MAXPERIOD   - The maximum period to explore. Default is the full
;                 range of dates.
;
; OPTIONAL KEYWORDS
;   NOSLOPE     - If set, no slope is assumed. Otherwise, a linear
;                 term is analytically fit to the RV data.
;   NYQUIST     - If set, the minimum period explored is the nyquist
;                 frequency (half the minimum spacing between two
;                 times). This takes precedence over MINPERIOD. Unless
;                 the times are uniformly spaced (which is not
;                 typical), use of this keyword is not recommended.
;   PLOT        - A diagnostic tool. If set, the lomb-scargle
;                 periodogram will be plotted, with the best period(s)
;                 overplotted. This is useful for determining good
;                 bounds, or if the observed behavior is unexpected.
;
; DEPENDENCIES:
;   BUIELIB (http://www.boulder.swri.edu/~buie/idl/)
;
; OUTPUTS:
;    result     - An NMIN elements array containing the best periods
;                 determined from the lomb-scargle periodogram.
;
; MODIFICATION HISTORY 
;  2009/05/01 -- Jason Eastman (Ohio State University)
;-

function exofast_lombscargle,time,rv,bestpars=bestpars,scale=scale,nmin=nmin,$
                             minperiod=minperiod,maxperiod=maxperiod,$
                             noslope=noslope,plot=plot
                              

mintime = min(time,max=maxtime)

if n_elements(nmin) eq 0 then nmin = 5
if n_elements(minperiod) eq 0 then minperiod = 1.d0
if n_elements(maxperiod) eq 0 then maxperiod = (maxtime - mintime)

;; optimal period sampling
duration = max(time) - min(time)
periods = double(minperiod)
np = 1
repeat begin
   periods = [periods,periods[np-1] + periods[np-1]^2/(4d0*!dpi*duration)]
   np++
endrep until periods[np-1] ge maxperiod
chi2 = dblarr(np)
pars = dblarr(7,np)

minchi2 = !values.d_infinity


for i=0L, np-1 do begin

    initpars = [0.d0,periods[i],0.d0,0.d0,0.d0,0.d0,0.d0]

    if keyword_set(noslope) then $
      chi2[i] = exofast_getchi2_rv_fitcirnom(initpars) $
    else chi2[i] = exofast_getchi2_rv_fitcir(initpars)

    pars[*,i] = initpars

endfor

;; find the NMIN local minima
minima = lclxtrem(chi2)
nminima = n_elements(minima)
best = minima[nminima - nmin > 0:nminima-1]

bestpars = pars[*,best]
scale = periods[best+1] - periods[best-1]

;; plot the lomb-scargle periodogram
if keyword_set(plot) then begin
    window, 0, retain=2
    plot, periods, chi2
    oplot, periods[best],chi2[best],color='0000ff'x,psym=1
    print, 'Type ".con" to continue'
    stop
endif

return, periods[best]

end
