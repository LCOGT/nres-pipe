;+
; NAME:
;   EXOFAST_CHI2
;
; PURPOSE: 
;   Computes the chi2 for a transit and/or RV for a single planet
;
; CALLING SEQUENCE:
;    chi2 = exofast_chi2(pars)
;
; INPUTS:
;
;    PARS - a parameter array containing all of the parameters in the
;           model.
;
;           gamma     = pars[0]       ;; systemic velocity
;           slope     = pars[1]       ;; slope in RV
;           tc        = pars[2]       ;; transit center time
;           logP      = pars[3]       ;; alog10(Period/days)
;           sqrtecosw = pars[4]       ;; eccentricity/arg of periastron
;           sqrtesinw = pars[5]       ;; eccentricity/arg of periastron
;           logK      = pars[6]       ;; alog10(velocity semi-amplitude/(m/s))
;           cosi      = pars[7]       ;; cosine of inclination of the orbit
;           p         = pars[8]       ;; rp/rstar
;           log(ar)   = pars[9]       ;; alog10(a/rstar)
;           logg      = pars[10]      ;; stellar surface gravity
;           teff      = pars[11]      ;; stellar effective temperature
;           feh       = pars[12]      ;; stellar metallicity
;           depth2    = pars[13]      ;; secondary eclipse depth
;           u1        = pars[14]      ;; linear limb darkening coeff
;           u2        = pars[15]      ;; quadratic limb darkening coeff
;           u3        = pars[16]      ;; 1st non-linear limb darkening coeff (not supported)
;           u4        = pars[17]      ;; 2nd non-linear limb darkening coeff (not supported)
;           F0        = pars[18]      ;; baseline flux
;           coeffs = pars[19:npars-1] ;; detrending variables
;
; OPTIONAL INPUTS:
;    PSNAME      - The name of a PS file. If set, a plot the
;                  data/model will be written to this file.
; OPTIONAL OUTPUTS:
;    DETERMINANT - The determinant of the parameterization above and
;                  the uniform priors we wish to impose. In this case,
;                  it is always 1d0 (but is required by EXOFAST_DEMC).
;    MODELRV     - The RV model at each time (rv.bjd).
;    MODELFLUX   - The model light curve at each time (transit.bjd).
;   
;
; RESULT:
;    The chi^2 of the model given the data and parameters.
;
; COMMON BLOCKS:
;   CHI2_BLOCK - See exofast.pro for definition
;
; MODIFICATION HISTORY
; 
;  2012/06 -- Public release -- Jason Eastman (LCOGT)
;  2012/07 -- Fixed major bug in mstar/rstar prior width derivation
;  2012/12 -- Add Long cadence, quadratic limb darkening fit.
;  2012/12 -- Changed eccentricity constraint to e < (1-Rstar/a)
;  2013/02 -- Fixed bug that broke detrending, introduced in 2012/12
;-

function exofast_chi2, pars, determinant=determinant, $
                        modelrv=modelrv, modelflux=modelflux, psname=psname

COMMON chi2_block, rv, transit, priors, band, options

chi2 = 0.d0

gamma     = pars[0]       ;; systemic velocity
slope     = pars[1]       ;; slope in RV
tc        = pars[2]       ;; transit center time
Period    = 10^(pars[3])  ;; Period of orbit
sqrtecosw = pars[4]       ;; eccentricity (uniform prior)
sqrtesinw = pars[5]       ;; argument of periastron
K         = 10^(pars[6])  ;; velocity semi-amplitude
inc       = acos(pars[7]) ;; inclination of the orbit
p         = pars[8]       ;; rp/rstar
ar        = 10^(pars[9])  ;; a/rstar
logg      = pars[10]      ;; stellar surface gravity
teff      = pars[11]      ;; stellar effective temperature
feh       = pars[12]      ;; stellar metallicity
depth2    = pars[13]      ;; secondary eclipse depth (can't trust hybrids)
u1        = pars[14]      ;; linear limb darkening coefficient
u2        = pars[15]      ;; quadratic limb darkening coefficient
u3        = pars[16]      ;; 1st non-linear limb darkening coefficient (placeholder; unsupported)
u4        = pars[17]      ;; 2nd non-linear limb darkening coefficient (placeholder; unsupported)
F0        = pars[18]      ;; baseline flux (can't trust hybrids)
;; coeffs = pars[19:npars-1] ;; detrending variables (can't trust hybrids)

determinant = 1d0

;; prevent runaways
if tc lt 0d0 or tc gt 3000000d0 then $
   return, !values.d_infinity

;; 0 <= cosi <= 1
if pars[7] gt 1 or pars[7] lt 0 then return, !values.d_infinity

;; derive e/omega, check boundaries
e = sqrtecosw^2 + sqrtesinw^2

;; limit eccentricity to avoid collision with star during periastron
;; the ignored tidal effects would become important long before this,
;; but this prevents numerical problems compared to the e < 1 constraint
;; the not/lt (instead of ge) robustly handles NaNs too
if not (e lt (1d0-1d0/ar)) then return, !values.d_infinity

if e eq 0d0 then omega = !dpi/2d0 $
else omega = atan(sqrtesinw,sqrtecosw)

;; incorportate "priors" on Mstar, Rstar from the Torres relation
;; (only possible with transit data)
if not options.notran then begin

   sini = sin(inc)
   G = 2942.71377d0 ;; R_sun^3/(m_sun*day^2), Torres 2010
   a = (10^logg*(period*86400d0)^2/(4d0*!dpi^2*ar^2*100d0) + $
        K*(Period*86400d0)*sqrt(1d0-e^2)/(2d0*!dpi*sini))/6.9566d8     ;; R_sun
   rstar = a/ar                                                        ;; R_sun
   mp = 2d0*!dpi*(K*86400d0/6.9566d8)*a^2*sqrt(1d0-e^2)/(G*period*sini);; M_sun
   mstar = 4d0*!dpi^2*a^3/(G*period^2) - mp                            ;; M_sun
   
;   ;; With Ma and Av, we can estimate the distance 
;   ;; Or, with all three, we can constrain the Radius better
;   Av = ??                                   ;; V-band extinction
;   Ma = ??                                   ;; Apparent V-band Magnitude
;
;   ;; Stefan-boltzmann Constant (L_sun/(r_sun^2*K^4))
;   sigmab = 5.670373d-5/3.839d33*6.9566d10^2 
;   lstar = 4d0*!dpi*rstar^2*teff^4*sigmaB    ;; L_sun
;
;   ;; Bolometric Correction from Flower 1996, Torres, 2010
;   logteff = alog10(teff)
;   if logteff lt 3.7 then begin
;      flowercoeffs = [-0.190537291496456d05,0.155144866764412d05,$
;                      -0.421278819301717d4,0.381476328422343d3]
;      BC = total(flowercoeffs*[1d0,logteff,logteff^2,logteff^3])  
;   endif else if logteff lt 3.9 then begin
;      flowercoeffs = [-0.370510203809015d5,0.385672629965804d5,$
;                      -0.150651486316025d5,0.261724637119416d4,$
;                      -0.170623810323864d3]
;      BC = total(flowercoeffs*[1d0,logteff,logteff^2,logteff^3,logteff^4])  
;   endif else begin
;      flowercoeffs = [-0.118115450538963d06,0.137145973583929d6,$
;                      -0.636233812100225d5,0.147412923562646d5,$
;                      -0.170587278406872d4,0.788731721804990d2]
;      BC = total(flowercoeffs*[1d0,logteff,logteff^2,$
;                               logteff^3,logteff^4,logteff^5])  
;   endelse
;
;   Mv = -2.5d0*alog10(lstar)+4.732-BC  ;; Absolute V-band Magnitude
;   distance = 10d0^((Ma-Mv-Av)/5d0 + 1d0)

   ;; Torres relation
   massradius_torres, logg, teff, feh, mstar_torres, rstar_torres
   
   ;; if you get this warning repeatedly after the beginning of the
   ;; fit, you should comment this out and provide
   ;; an independent constraint on mstar and/or rstar
   if mstar_torres lt 0.6d0 then message, $
      'WARNING: Torres relation not applicable (mstar = ' + $
      strtrim(mstar_torres,2) + ')',/continue

   ;; add "prior" penalty
   chi2 += (alog10(mstar/mstar_torres)/0.027d0)^2
   chi2 += (alog10(rstar/rstar_torres)/0.014d0)^2

endif

;; time of periastron
phase = exofast_getphase(e,omega,/primary)
tp = tc - period*phase

;; prepare the plotting device
if options.debug or keyword_set(psname) then begin
   if keyword_set(psname) then begin
      ;; astrobetter.com tip on making pretty IDL plots
      mydevice=!d.name
      set_plot, 'PS'
      aspect_ratio=1.5
      xsize=10.5
      ysize=xsize/aspect_ratio
      !p.font=0
      device, filename=psname, /color, bits=24
      device, xsize=xsize,ysize=ysize
      loadct, 39, /silent
      red = 254
      symsize = 0.33
      position1 = [0.23, 0.40, 0.95, 0.95]    ;; data plot
      position2 = [0.23, 0.20, 0.95, 0.40]    ;; residual plot
   endif else begin
      red = '0000ff'x
      symsize = 1
      device,window_state=win_state
      if win_state[0] eq 1 then wset, 0 $
      else window, 0, retain=2
      position1 = [0.07, 0.22, 0.97, 0.95]    ;; data plot
      position2 = [0.07, 0.07, 0.97, 0.22]    ;; residual plot
   endelse
endif

;; ******** RV ***********
if not options.norv then begin

   ;; time in target barycentric frame (expensive)
   if n_elements(a) eq 0 then rvbjd = rv.bjd $
   else rvbjd = bjd2target(rv.bjd, inclination=inc, a=a/215.094177d0, tp=tp, $
                           period=period, e=e,omega=omega,/primary)
   ;; rvbjd = rv.bjd ;; usually sufficient (See Eastman et al., 2013)
   
   modelrv = exofast_rv(rvbjd,tp,period,gamma,K,e,omega,slope=slope)
   rvchi2 = total(((rv.rv - modelrv)/rv.err)^2)
   
   if options.debug or keyword_set(psname) then begin
            
      ;; the pretty model
      nsteps = 1000
      mindate = min(rv.bjd,max=maxdate)
      prettytime = mindate + (maxdate-mindate)*dindgen(nsteps)/(nsteps-1.d0)
      prettymodel = exofast_rv(prettytime,tp,period,0,K,e,omega,slope=0)
      
      ;; pad the plot to the nearest 5 in the second sig-fig
      ymax = round5(max([rv.rv + rv.err - gamma,prettymodel]))
      ymin = round5(min([rv.rv - rv.err - gamma,prettymodel]))
      
      ;; center the phase curve so transit at phase 0.25, secondary at 0.75
      ;; not standard definition of 'phase' but more informative
      tc = pars[2]
      phasejd = (((prettytime - tc) mod period)/period + 1.25d0) mod 1
      time = (((rv.bjd - tc) mod period)/period + 1.25d0) mod 1
      plotsym, 0, symsize, /fill
      t0 = (mindate+maxdate)/2d0
      sorted = sort(phasejd)
      xrange=[0,1]
      
      ;; plot the data and the model (subtract slope so it phases well)
      plot, [0],[0], position=position1, $
            xrange=xrange, xtickformat='(A1)', $
            ytitle='RV (m/s)', yrange=[ymin,ymax], /ystyle
      oplot, phasejd[sorted], prettymodel[sorted], color=red
      oploterr, time, rv.rv - (rv.bjd - t0)*slope-gamma, rv.err, 8
      
      ;;  pad the plot to the nearest 5 in the second sig-fig
      ymin = round5(min(rv.rv-modelrv - rv.err))
      ymax = round5(max(rv.rv-modelrv + rv.err))
      
      ;; make the plot symmetric about 0
      if ymin lt -ymax then ymax = -ymin
      if ymax gt -ymin then ymin = -ymax
      
      ;; plot the residuals below
      plot, [0],[0], position=position2, /noerase, $
            xrange=xrange, xtitle=TeXtoIDL('Phase + (T_P - T_C)/P + 0.25'),$
            yrange=[ymin,ymax], ytitle='O-C (m/s)', $
            /xstyle, /ystyle, yminor=2,yticks=2
      oplot, [-9d9,9d9],[0,0],linestyle=2,color=red  
      oploterr, time, rv.rv-modelrv, rv.err, 8

   endif
  
   ;; compute the chi2
   chi2 += rvchi2
endif
;;********************************************************

;;********************* TRANSIT data **********************
if not options.notran then begin

   if teff lt 3500 then begin
      message, 'WARNING: Limb darkening interpolation ' + $
               'unsupported for this effective temperature (' + $
               strtrim(teff,2) + ')',/continue
      return, !values.d_infinity
   endif
      

   ldcoeffs = quadld(logg, teff, feh, band)
   u1claret = ldcoeffs[0]
   u2claret = ldcoeffs[1]
   
   ;; logg, teff, feh outside of Claret tables (Torres not applicable anyway)
   ;; a little unsettling; probably ought to exclude by Fe/H, Teff, logg
   ;; for some (uncommon) values, this is due to a bug in quadld that
   ;; doesn't correctly interpolate the sparse grid -- on my to do list.
   if ~finite(u1claret) then return, !values.d_infinity
   if ~finite(u2claret) then return, !values.d_infinity
  
   ;; errors are a conservative guess based on fig 1 of Claret & Bloemen, 2011
   ;; Real errors would be nice
   u1err = 0.05d0 
   u2err = 0.05d0
   chi2 += ((u1-u1claret)/u1err)^2
   chi2 += ((u2-u2claret)/u2err)^2
   
   npoints = n_elements(transit.bjd)

   ;; Kepler Long candence data; create several model points and average   
   if options.ninterp gt 1 then begin
      transitbjd = transit.bjd#(dblarr(options.ninterp)+1d0) + $     
                   ((dindgen(options.ninterp)/(options.ninterp-1d0)-0.5d0)/$
                    1440d*options.exptime)##(dblarr(npoints)+1d)
      modelflux = dblarr(npoints,options.ninterp) + 1d0
      planetvisible = modelflux
   endif else begin
      transitbjd = transit.bjd
      modelflux = dblarr(npoints) + 1d0
      planetvisible = dblarr(npoints) + 1d0
   endelse
   
   transitbjd = bjd2target(transitbjd, inclination=inc, a=a/215.094177d0, $
                           tp=tp, period=period, e=e,omega=omega)
   ;;transitbjd = transit.bjd ;; target coordinates more important here

   ;; the impact parameter for each BJD
   z = exofast_getb(transitbjd, i=inc, a=ar, tperiastron=tp, $
                    period=period, e=e,omega=omega,z=depth, x=x, y=y)

   ;; ModelFlux = F0*(TransitFlux + depth2*PlanetVisible + C0*X0 + ... + CN*XN)
   ;; primary transit
   primary = where(depth gt 0, complement=secondary)
   if primary[0] ne - 1 then begin
      exofast_occultquad, z[primary], u1, u2, p, mu1
      modelflux[primary] = mu1
   endif

   ;; add the flux from the planet 
   ;; i.e., everywhere but during secondary eclipse
   planetvisible = dblarr(npoints,options.ninterp) + 1d0
   if secondary[0] ne - 1 then begin
      exofast_occultquad, z[secondary]/p, 0, 0, 1d0/p, mu1
      planetvisible[secondary] = mu1
   endif
   modelflux += depth2*planetvisible 

   ;; now integrate the data points (before detrending)
   if options.ninterp gt 1 then modelflux = total(modelflux,2)/options.ninterp

   ;; detrending
   ndetrend = n_tags(transit) - 3
   for j=0, ndetrend-1 do begin
      d = transit.(j+3) - mean(transit.(j+3))
      modelflux += pars[19+j]*d
   endfor

   ;; normalization
   modelflux *= F0

   ;; chi^2
   transitchi2 = total(((transit.flux - modelflux)/transit.err)^2)

   if options.debug or keyword_set(psname) then begin
      t0 = 2450000.d0
      if (max(transit.bjd) - min(transit.bjd)) gt period then begin
         ;; more than one transit, plot in phase space
         ;; scale the time between 0 and 1, center the transit at phase 0.25
         time = (((transit.bjd-tc) mod period)/period + 1.25d0) mod 1
         xtitle = TeXtoIDL('Phase + (T_P - T_C)/P + 0.25')
      endif else begin
         ;; only one transit, plot in time - tc in hours
         np = round(mean(transit.bjd - tc)/period)
         time = (transit.bjd - tc - period*np)*24.d0
         xtitle = TeXtoIDL('Time - T_C (hrs)')
      endelse

      ;; normalize the data and model
      detrenddata = transit.flux/F0
      m = modelflux/F0
      
      ;; subtract the detrended parameters from the data and model
      for j=0, ndetrend-1 do begin
         d = transit.(j+3) - mean(transit.(j+3))
         detrenddata -= pars[19+j]*d
         m -= pars[19+j]*d
      endfor

      ;; match the model to the same timescale
      sorted = sort(time)
      x = time[sorted]
      ms = m[sorted]
      
      ;; plot the data and model
      if not keyword_set(psname) then begin
         if win_state(1) eq 1 then wset, 1 $
         else window, 1, retain=2
      endif
      
      ;; make the plot
      ymin = min(detrenddata - transit.err,/nan)
      ymax = max(detrenddata + transit.err,/nan)
      
      ;; round to nearest 0.XX5 for uniform plotting on middle of major
      ;; axis tick marks
      nearest = 0.005d0
      ymax =  ceil((ymax)/nearest)*nearest
      ymin = floor((ymin)/nearest)*nearest
      if double(fix(ymax/0.01d0)) eq ymax/0.01d0 then ymax += nearest
      if double(fix(ymin/0.01d0)) eq ymin/0.01d0 then ymin -= nearest
      
      xmin=min(x,max=xmax)
      plotsym, 0, /fill
      
      ;; plot the shell, model, and data
      plot, [0],[0], xstyle=1,ystyle=1, yrange=[ymin,ymax],xtickformat='(A1)',$
            ytitle='Normalized flux', xrange=[xmin,xmax],position=position1
      oplot, time, detrenddata, psym=8, symsize=symsize
      oplot, x, ms, thick=2, color=red, linestyle=0
      
      ;;  pad the plot to the nearest 5 in the second sig-fig
      ymin = round5(min(detrenddata-m - transit.err,/nan))
      ymax = round5(max(detrenddata-m + transit.err,/nan))
      
      ;; make the plot symmetric about 0
      if ymin lt -ymax then ymax = -ymin
      if ymax gt -ymin then ymin = -ymax
      
      ;; plot the residuals below
      plot, [0],[0],xstyle=1,ystyle=1, yrange=[ymin,ymax],ytitle='O-C',$
            xrange=[xmin,xmax],xtitle=xtitle,position=position2,/noerase,$
            yminor=2,yticks=2
      oplot, time,detrenddata-m,psym=8,symsize=symsize
      oplot, [xmin,xmax],[0,0],linestyle=2,color=red  
      
      if keyword_set(psname) then begin
         device, /close
         !p.font=-1
         set_plot, mydevice
      endif
      
   endif
   chi2 += transitchi2
endif
;*************************************************

;; add priors (priors[1,*] should be infinity for no prior)
npriors = n_elements(priors)
if npriors ne 0 and npriors ne 1 then begin
   if npriors ne n_elements(pars)*2 then $
      message, 'ERROR: PRIORS array must be a 2xNPARS array'
   chi2 += total(((pars-priors[0,*])/priors[1,*])^2)
endif

;; print out the parameters and chi2 at each step
if options.debug then print, pars, chi2, $
          format='(' + strtrim(n_elements(pars)+1,2) + '(f0.6,x))'

return, chi2

end

