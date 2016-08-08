;+
; NAME:
;   EXOFAST
;
; PURPOSE:
;   Simultaneously fits RV and/or transit data for a single
;   planet. Please cite Eastman et al., 2013
;   (http://adsabs.harvard.edu/abs/2013PASP..125...83E) if you make
;   use of this routine in your research. Please report errors or bugs
;   to jeastman@lcogt.net
;
; CALLING SEQUENCE:
;   exofast, [RVPATH=, TRANPATH=, BAND=, PRIORS=, PREFIX=, /CIRCULAR,
;             /NOSLOPE, /SECONDARY, /UPDATE, PNAME=, SIGCLIP=, NTHIN=,
;             MAXSTEPS=, MINPERIOD=, MAXPERIOD=, NMIN=, /DISPLAY,
;             /DEBUG, RANDOMFUNC=, SEED=, /SPECPRIORS, /BESTONLY,
;             NINTERP=, EXPTIME=, /LONGCADENCE]
;
; INPUTS:
;
;   RVPATH      - The path to the RV data file. The file must have 3 columns:
;                   1) Time (BJD_TDB -- See Eastman et al., 2010)
;                   2) RV (m/s)
;                   3) err (m/s)
;                 NOTE: The units must be as specified, or the fit
;                 will be wrong or fail.
;                 NOTE 2: If omitted, just the transit data will be fit
;   TRANPATH    - The path to the transit data file. The file must
;                 have at least 3 columns:
;                   1) Time (BJD_TDB -- See Eastman et al., 2010)
;                   2) Normalized flux
;                   3) err
;                   4) Detrend parameter 1
;                   ....
;                   N+3) Detrend parameter N
;                 NOTE: The units must be as specified, or the fit
;                 will be wrong or fail.
;                 NOTE 2: If omitted, just the RV data will bit fit
;   BAND        - The bandpass of the observed transit (see quadld.pro
;                 for allowed values).
;                 NOTE: only required if TRANPATH is specified.
;   PRIORS      - Priors on each of the parameters. See EXOFAST_CHI2
;                 for parameter definitions. Must be an N x 2
;                 elements array, where N is 15 + the number of
;                 detrending variables. If set, all non-zero values of
;                 priors[0,*] are used to start the fit, and a penalty
;                 equal to:
;                    total(((pars-priors[0,*])/priors[1,*])^2)
;                 is added to the total chi^2. 
;
;                 NOTE 1: For no prior, set the width to infinity. i.e., 
;                    priors[1,*] = !values.d_infinity.
;                 NOTE 2: Typically, the default starting guesses are
;                 good enough and need not be changed.
;
;                 TRANSIT+RV or TRANSIT-ONLY FITS: Priors on Teff and
;                 [Fe/H] (priors[*,11:12]) must be specified, either by
;                 declaring the priors array or specifying a planet
;                 name and setting the /SPECPRIORS keyword.
;
;                 RV-ONLY FITS: Priors on logg, Teff and [Fe/H]
;                 (priors[*,10:12]) must be specified, either by
;                 declaring the priors array or specifying a planet
;                 name and setting the /SPECPRIORS keyword.
;
; OPTIONAL INPUTS:
;   PREFIX      - Each of the output files will have this string as a
;                 prefix. Default is RVFILE without the
;                 extension. Cannot contain an underscore, "_".
;   MINPERIOD   - The minimum period to consider. The default is 1 day.
;   MAXPERIOD   - The maximum period to consider. The default is the
;                 range of the RV input times.
;   NMIN        - The number of minima in the Lomb-Scargle Periodogram
;                 to fit a full Keplerian orbit. Default is 5. If the
;                 eccentricity is large, this may need to be
;                 increased. The execution time of the initial global
;                 fit is directly proportional to this value (though
;                 is a small fraction of the total time of the MCMC fit).
;   PNAME       - If set, starting values from exoplanets.org for the
;                 planet PNAME will be used to seed the fit. It is
;                 insensitive to extra spaces and capitalization.
;                 e.g., "WASP-12 b" is the same as "wasp-12b".
;   SIGCLIP     - If set, an iterative fit will be performed excluding
;                 data points more than SIGCLIP*error from the best
;                 fit. Default is no clipping.
;   NTHIN       - If set, only every NTHINth element will be
;                 kept. This typically doesn't affect the
;                 resultant fit because there is a high correlation
;                 between adjacent steps and has the advantage of
;                 improved memory management and faster generation of
;                 the final plots.
;   MAXSTEPS    - The maximum number of steps to take in the MCMC
;                 chain. Note that a 32-bit installation of IDL
;                 cannot allocate more than 260 million
;                 double-precision numbers, and redundant copies of
;                 each parameter are required. A very large number
;                 will cause memory management problems. Default is
;                 100,000.
;   RANDOMFUNC  - A string specifying the name of the random number
;                 generator to use. This generator must be able to
;                 return 1,2 or 3 dimensional uniform or normal random
;                 deviates. Default is 'EXOFAST_RANDOM' (which is slow
;                 but robust).
;   SEED        - The seed to the random number generator used for the
;                 MCMC fits. Be sure not to mix seeds from different
;                 generators. The default is -systime(/seconds).
;   NINTERP     - If set, the each model data point will be an average
;                 of NINTERP samples over a duration of EXPTIME
;                 centered on the input time.
;   EXPTIME     - If set, the each model data point will be an average
;                 of NINTERP samples over a duration of EXPTIME
;                 centered on the input time.
;                 For a dicussion on binning, see:
;                 http://adsabs.harvard.edu/abs/2010MNRAS.408.1758K
; OPTIONAL KEYWORDS:
;   CIRCULAR  - If set, the fit will be forced to be circular (e=0,
;               omega_star=pi/2)
;   NOSLOPE   - If set, it will not fit a slope to the RV data.
;   SECONDARY - If set, fit a secondary eclipse. This feature is not
;               well-tested -- use at your own risk.
;   UPDATE    - Update the local copy of the exoplanets.org file (only
;               applied if PNAME is specified).
;   DISPLAY   - If set, the plots (below) will be displayed via
;               ghostview (gv).
;   SPECPRIORS- If set (and PNAME is specified), spectroscopic priors
;               from exoplanets.org will be used for logg, Teff, and
;               [Fe/H].
;   BESTONLY  - If set, only the best fit (using AMOEBA) will be
;               performed.
;   DEBUG     - If set, various debugging outputs will be printed and
;               plotted.
;   LONGCADENCE - If set, EXPTIME=29.425 and NINTERP=10 are set to handle
;                 long cadence data from Kepler.
;
; OUTPUTS:
;
;   Each of the output files will be preceeded by PREFIX (defined
;   above). The first "?" will be either "c" for circular if /circular
;   is set or "e" for eccentric. The second "?" will be either "f" for
;   flat (if /noslope is set) or "m "for slope.
;
;   mcmc.?.?.idl   - An IDL save file that contains the full chains
;                    for each parameter, including derived paramters,
;                    the corresponding names, the chi2 at each link,
;                    and the index of the burn-in period.
;   pdfs.?.?.ps    - A postscript plot of each posterior distribution
;                    function, 8 to a page.
;   covars.?.?.ps  - A postscript plot of the covariances between each
;                    parameter, 16 to a page. The title of each plot is the
;                    correlation coefficient.
;   median.?.?.tex - The LaTeX source code for a deluxe table of the median
;                    values and 68% confidence interval, rounded appropriately. 
;   best.?.?.tex   - The LaTeX source code for a deluxe table of the best fit
;                    values and 68% confidence interval, rounded appropriately.
;   model.?.?.ps   - An postscript plot of the best-fit models and residuals.
;   model.?.?.rv   - A text file containing the best-fit model RV for each
;                    input time
;   model.?.?.flux - A text file containing the best-fit model flux for each
;                    input time
;
;   NOTE: To extract a single page out of a multi-page PS file, use:
;           psselect -p# input.ps output.ps
;         where # is the page number to extract.
;
; COMMON BLOCKS:
;   CHI2_BLOCK:
;     RV      - A structure with three tags, corresponding to each
;               column of RVFILE.
;     TRANSIT - A structure with 3 + N tags, corresponding to each
;               column of the TRANFILE.
;     PRIORS  - The priors on each of the parameters
;     BAND    - The band of the observed transit
;     DEBUG   - A flag to specify if the data/fit should be
;               plotted. This is intended for debugging only; it
;               dramatically increases the execution time.
;     NORV    - A boolean to indicate the RV should not be fit
;     NOTRAN  - A boolean to indicate the transit should not be fit
;   RV_BLOCK:
;     RVDATA  - A structure with three tags, corresponding to each
;               column of RVFILE. This is to prefit the data with a
;               lomb-scargle periodogram
; EXAMPLES:  
;   ;; fit HAT-P-3b example data (using priors from exoplanets.org):
;   exofast, rvpath='hat3.rv',tranpath='hat3.flux',pname='HAT-P-3b',$
;            band='Sloani',/circular,/noslope,/specpriors,minp=2.85,maxp=2.95
;
;   ;; fit HAT-P-3b without using exoplanets.org 
;   ;; include a prior on the period too 
;   ;; this reproduces results from Eastman et al., 2013
;   per = 2.899703d0
;   uper = 5.4d-5
;   priors = dblarr(2,19)
;   priors[1,*] = !values.d_infinity
;   priors[*, 3] = [alog10(per),uper/(alog(10d0)*per)] ;; logp prior
;   priors[*,10] = [4.61d0,0.05d0] ;; logg prior
;   priors[*,11] = [5185d0,  80d0] ;; Teff prior
;   priors[*,12] = [0.27d0,0.08d0] ;; logg prior
;   exofast,rvpath='hat3.rv',tranpath='hat3.flux',band='Sloani',/circular,$
;           /noslope,priors=priors,minp=2.85,maxp=2.95,prefix='example.'
;
; MODIFICATION HISTORY
; 
;  2012/06 -- Public Release, Jason Eastman (LCOGT)
;  2012/12 -- Upgrades for Kepler data, JDE, LCOGT:
;               Change treatment of limb darkening
;                 Now fits limb darkening using Claret tables as a prior
;               Add LongCadence flag, exptime, niterp keywords
;  2012/12 -- Update documentation with corrected priors array
;  2012/12 -- Now cosi scale (for AMOEBA) is rstar/a instead of hard
;             coded at 0.1. More robust for long-period planets.
;             Added additional output files
;  2012/12 -- Added Carter error estimates for BESTONLY transit fits
;             Fit eccentricity for transit-only fits
;               requires logg prior
;               ecosw fixed at zero for "best" fit
;               ecosw is only constrained by |ecosw| <= sqrt(1-esinw^2)
;               takes a long time for MCMC due to ecosw degeneracy
;  2013/01 -- Fix bugs with prior array misuse (works with example
;             in README again)
;  2013/02 -- Fixed bug in primary transit probabilities (extra factor
;             of Rstar/Rsun)
;  2013/06 -- Fixed bug when using /specpriors keyword (which broke example)
;-
pro exofast, rvpath=rvfile, tranpath=tranfile, band=band, priors=priors, $
             prefix=prefix,$
             circular=circular,noslope=noslope, secondary=secondary, $
             update=update, pname=pname, sigclip=sigclip,$
             nthin=nthin, maxsteps=maxsteps, $
             minperiod=minperiod, maxperiod=maxperiod, nmin=nmin, $
             display=display,debug=debug, randomfunc=randomfunc,seed=seed,$
             specpriors=specpriors, bestonly=bestonly, plotonly=plotonly,$
             longcadence=longcadence, exptime=exptime, ninterp=ninterp

;; name of the chi square function
chi2func = 'exofast_chi2'

;; compile all routines now to keep output legible 
;; resolve_all doesn't interpret execute; it's also broken prior to IDL v6.4(?)
if double(!version.release) ge 6.4d0 then $
   resolve_all, resolve_function=[chi2func,'exofast_random'],/cont,/quiet

if n_elements(rvfile) ne 1 then skiprv = 1 $
else skiprv = 0

if n_elements(tranfile) ne 1 then skiptran = 1 $
else skiptran = 0

if skiprv and skiptran then begin
   print, 'ERROR: must specify at one or both of RVPATH and TRANPATH'
   return
endif

COMMON rv_block, rvdata, rvdebug
COMMON chi2_block, rv, transit, priors0, band0, options

;; this structure is global and contains fitting options
options = create_struct('norv',0,'notran',0,'exptime',0d0,'ninterp',1,'debug',0)

if keyword_set(longcadence) then begin
   options.exptime = 29.425d0 ;; 1765.5 seconds
   options.ninterp = 10 ;; twice the ideal for TrES-2b (Kipping & Bakos, 2010 -- safe but slow)
endif
if n_elements(exptime) ne 0 then options.exptime = exptime
if n_elements(ninterp) ne 0 then options.ninterp = ninterp

;; can't delete a global variable, but this tells it not to use it
priors0 = -1

;; if a transit is fit, the bandpass must be specified
if n_elements(band) eq 0 and not skiptran then message, $
   'ERROR: band must be specified if a transit is fit' $
else begin
   if n_elements(band) ne 0 then band0 = band
endelse

if n_elements(maxsteps) eq 0 then maxsteps = 100000L
if n_elements(nthin) eq 0 then nthin = 1L
if n_elements(sigclip) ne 1 then sigclip = !values.d_infinity ;; no clipping
if n_elements(nmin) eq 0 then nmin=5

;; use robust generator by default
if n_elements(randomfunc) eq 0 then randomfunc = 'exofast_random'

;; enable debugging?
if keyword_set(debug) then options.debug=1

;; default prefix for all output files (filename without extension)
if n_elements(prefix) eq 0 then begin
   if skiprv then base = tranfile $
   else base = rvfile

   prefix = file_dirname(base) + path_sep()
   basename = file_basename(base)
   basename = strsplit(basename,'.',/extract,/preserve_null)
   for i=0, n_elements(basename)-2 do prefix += basename[i] + '.'
endif 
basename = file_basename(prefix)

if not skiprv then begin
   ;; Read the RV data file into the RV structure
   readcol, rvfile, bjd, rv, err, format='d,d,d',/silent,comment='#'
   rv = create_struct('bjd',bjd,'rv',rv,'err',err)
   rvdata = rv
endif

;; Read the transit data file into the TRANSIT structure
;; (with an arbitary number of detrending variables)
if not skiptran then begin
   readcmd = "readcol, tranfile, bjd, flux, err"
   fmt = ",format='d,d,d"
   createstrcmd = "trandata =  create_struct('bjd',bjd,'flux',flux,'err',err"
   openr, lun, tranfile, /get_lun
   line = ""
   readf, lun, line
   ncol = n_elements(strsplit(line))
   nlin = ncol-2 ;; the number of detrending parameters
   free_lun, lun
   for i=3L, ncol-1 do begin
      readcmd += ',d' + strtrim(i-2,2)
      fmt += ',d'
      createstrcmd += ",'d" + strtrim(i-2,2) + "',d" + strtrim(i-2,2)
   endfor
   readcmd += fmt + "',/silent,comment='#'"
   createstrcmd += ')'
   dummy = execute(readcmd)   ;; read the data file
   dummy = execute(createstrcmd) ;; create the structure
   transit=trandata
endif else nlin = 1
npars = 18+nlin

;; priors must be the appropriate format
npriors = n_elements(priors)
if npriors ne 2*npars then begin
   if n_elements(pname) eq 0 or not keyword_set(specpriors) then begin
      message, 'ERROR: priors must be a 2xNPARS element array'
      if npriors ne 0 then $
         print, 'WARNING: Overwriting PRIORS with values from exoplanets.org'
   endif
endif else priors0 = priors

;; Parameters to fit for the RV fit
tofitrv = lindgen(7)
if keyword_set(circular) then $
   tofitrv = tofitrv[where(tofitrv ne 4 and tofitrv ne 5)]
if keyword_set(noslope) then tofitrv = tofitrv[where(tofitrv ne 1)]

;; Parameters to fit for the Transit fit
tofittran = [2,3,4,5,lindgen(11+nlin)+7]
if not keyword_set(secondary) then begin
   tofittran = tofittran[where(tofittran ne 4)]
   tofittran = tofittran[where(tofittran ne 5)]
   tofittran = tofittran[where(tofittran ne 13)]
endif

;; exclude parameters as desired
tofit = indgen(npars)
if keyword_set(circular) then tofit = tofit[where(tofit ne 4 and tofit ne 5)]
if keyword_set(noslope) then tofit = tofit[where(tofit ne 1)]
if not keyword_set(secondary) then tofit = tofit[where(tofit ne 13)]

tofittran = tofittran[where(tofittran ne 16 and $
                            tofittran ne 17)]
tofit = tofit[where(tofit ne 16 and $
                    tofit ne 17)]

if skiptran then tofit = tofit[where(tofit ne 14 and tofit ne 15)]


;; do a global fit on RV only, then use that to get
;; a reasonable guess on transit data i
npriors = n_elements(priors0)
if not skiprv then begin
   print, ''

   if npriors gt 3 then begin
      if priors0[0,3] ne 0 then begin
         pprior = 10^priors0[0,3]
         perr = priors[1,3]*alog(10d0)*pprior
      endif
   endif
   
   print, 'Best peaks in the RV fit:'
   bestrv = exofast_prefitrv(circular=circular,/scaleerr,noslope=noslope,$
                             minperiod=minperiod,maxperiod=maxperiod,nmin=nmin,$
                             period=pprior, perr=perr)
   rv=rvdata ;; exofast_prefitrv scaled the errors
   ;; convert to combined parameterization
   tc = bestrv[0] 
   logp = alog10(bestrv[1])
   e = sqrt(bestrv[2]^2 + bestrv[3]^2)
   if e eq 0 then omega = !dpi/2.d0 $
   else omega = atan(bestrv[3],bestrv[2])
   sqrtecosw = sqrt(e)*cos(omega)
   sqrtesinw = sqrt(e)*sin(omega)
   logk = alog10(bestrv[4])
   gamma = bestrv[5]
   slope = bestrv[6]

   ;; find the MCMC scale of the RV parameters
   options.notran = 1
   options.norv = 0
   if npriors eq 2*npars then bestrv = transpose(priors0[0,*]) $
   else bestrv = dblarr(npars)

   bestrv[0:6] = [gamma,slope, tc,logp,sqrtecosw,sqrtesinw,logk]
   bestrv[9] = 999d0 ;; prevents eccentricity cut from excluding fit
   masterscale = [  500,    1,0.1,0.05,    0.1d0,    0.1d0, 0.1,0,0,0,0,0,0,0,0]
   rvscale = dblarr(npars)
   rvscale[tofitrv] = masterscale[tofitrv]
   
   bestrv = exofast_amoeba(1d-8,function_name=chi2func,p0=bestrv,$
                           scale=rvscale, nmax=1d5)
   rvscalemcmc = exofast_getmcmcscale(bestrv,chi2func,tofit=tofitrv)
   rvscale = dblarr(npars)
   rvscale[tofitrv] = rvscalemcmc
   period = 10^bestrv[3]
endif else begin
   rvscale = dblarr(npars)+!values.d_infinity
   gamma = 0d0
   slope = 0d0
   logk = -1000d0 ;; zero mass
endelse

;; if the planet is known, use exoplanets.org values for seed
;; period, tc, depth, i, a/rstar, logg, Teff, [Fe/H] instead generic guesses
if n_elements(pname) eq 1 then begin
   planets = readexo(update=update)   
   match = (where(strupcase(strcompress(planets.name,/remove_all)) eq $
                  strupcase(strcompress(pname,/remove_all))))(0)
   if match eq -1 then begin
      print, 'ERROR: No match for ' + pname
      names = planets.name[where(planets.transit)]
      print, 'Choose among: '
      print, names[sort(names)]
      print, 'To update your local copy, rerun with the /UPDATE keyword'
      return
   endif
   
   p = sqrt(double(planets.depth[match]))
   period = double(planets.per[match])
   
   ;; use the tc closest to the mean of input (transit) data points
   tc = planets.tt[match]
   if skiptran then np = 0 $
   else np = round((tc - mean(transit.bjd))/period)
   tc -= np*period
   
   logp = alog10(double(planets.per[match]))
   loga = alog10(double(planets.ar[match]))
   cosi = cos(double(planets.i[match])*!dpi/180d0)
   logg = double(planets.logg[match])
   teff = double(planets.teff[match])
   feh = double(planets.fe[match])
   e = double(planets.ecc[match])
   omega = double(planets.om[match])*!dpi/180d0
   sqrtecosw = sqrt(e)*cos(omega)
   sqrtesinw = sqrt(e)*sin(omega)

   ;; use spectroscopic priors from exoplanets.org
   if keyword_set(specpriors) then begin
      if npriors ne 2*npars then begin
         priors0 = dblarr(2,npars)
         priors0[1,*] = !values.d_infinity
      endif
      ulogg = double(planets.ulogg[match])
      uteff = double(planets.uteff[match])
      ufeh = double(planets.ufe[match])
      priors0[0,10:12] = [logg,teff,feh]
      ;; the errors are often under-reported, set a minimum error
      priors0[1,10:12] = [ulogg,uteff,ufeh] > [0.05d0,80d0,0.08d0]
      
      ;; also grab the period prior if no RV, no period prior set, and
      ;; transit data don't span a full period.
      if skiprv and ~finite(priors0[1,3]) then begin
         per = 10^logp
         if (max(trandata.bjd) - min(trandata.bjd)) lt per then begin
            uper = double(planets.uper[match])
            priors0[*,3] = [logp,uper/(alog(10d0)*per)]
         endif
      endif

   endif     

endif else begin
   ;; no additional data, use Hot-Jupiter-like guesses
   if skiprv then begin
      tc = mean(transit.bjd)
      logp = priors[0,3]
      sqrtecosw = priors[0,4]
      sqrtesinw = priors[0,5]
      period = 10^logp
   endif else begin
      tc = bestrv[2] 
      logp = bestrv[3]
   endelse

   if skiptran then np = 0 $
   else np = round((tc - mean(transit.bjd))/period)
   tc -= np*period

   cosi = 0d0
   p = 0.1d0
   logg = 4.438d0
   teff = priors0[0,11]
   feh = priors0[0,12]

   ;; guess at a/rstar assuming rstar=rsun, mstar=msun
   G = 2942.71377d0 ;; R_sun^3/(m_sun*day^2), Torres 2010
   loga = alog10((period^2*G/(4d0*!dpi^2))^(1d0/3d0))

endelse

depth2 = 0d0
f0=dblarr(nlin)
f0[0] = 1d0

;; if the priors are non-zero, start with those instead of the generic guesses
if priors0[0,0]  ne 0d0 then     gamma = priors0[0,0]
if priors0[0,1]  ne 0d0 then     slope = priors0[0,1]
if priors0[0,2]  ne 0d0 then        tc = priors0[0,2]
if priors0[0,3]  ne 0d0 then      logp = priors0[0,3]
if priors0[0,4]  ne 0d0 then sqrtecosw = priors0[0,4]
if priors0[0,5]  ne 0d0 then sqrtesinw = priors0[0,5]
if priors0[0,6]  ne 0d0 then      logk = priors0[0,6]
if priors0[0,7]  ne 0d0 then      cosi = priors0[0,7]
if priors0[0,8]  ne 0d0 then         p = priors0[0,8]
if priors0[0,9]  ne 0d0 then      loga = priors0[0,9]
if priors0[0,10] ne 0d0 then      logg = priors0[0,10]
if priors0[0,11] ne 0d0 then      teff = priors0[0,11]
if priors0[0,12] ne 0d0 then       feh = priors0[0,12]
if priors0[0,13] ne 0d0 then    depth2 = priors0[0,13]
if priors0[0,14] ne 0d0 then        u1 = priors0[0,14]
if priors0[0,15] ne 0d0 then        u2 = priors0[0,15]
if priors0[0,16] ne 0d0 then        u3 = priors0[0,16]
if priors0[0,17] ne 0d0 then        u4 = priors0[0,17]
if priors0[0,18] ne 0d0 then        f0 = priors0[0,18]

;; limb darkening coefficients (only quadratic for now)
if skiptran then ldcoeffs = [0,0] $
else ldcoeffs = quadld(logg, teff, feh, band)
u1 = ldcoeffs[0]
u2 = ldcoeffs[1]
u3 = 0d0
u4 = 0d0

if keyword_set(plotonly) then begin
   pars  = [gamma,slope,tc,logp,sqrtecosw,sqrtesinw,logk, cosi,$
                p,loga, logg,  teff,  feh,depth2,  u1, u2, u3, u4, f0]
   if keyword_set(circular) then circtxt = 'c.' $
   else circtxt = 'e.'
   if keyword_set(noslope) then slopetxt = 'f.' $
   else slopetxt = 'm.'

   if skiptran then options.notran = 1 $
   else options.notran = 0

   if skiprv then options.norv = 1 $
   else options.norv = 1

   modelfile = prefix + 'model.' + circtxt + slopetxt + 'ps'
   bestchi2 = call_function(chi2func,pars,psname=modelfile, $
                            modelrv=modelrv, modelflux=modelflux)
   if keyword_set(display) then spawn, 'gv ' + modelfile + ' &'
   return
endif

;; fit the Transit data alone
ucosi = (1d0/10^loga);*((1d0-e^2)/(1d0+esinw))
uteff = priors0[1,11]
ufeh = priors0[1,12]
if not skiptran then begin
   options.norv = 1
   options.notran = 0
   transit = trandata
   tranpars  = [gamma,slope,tc,logp,sqrtecosw,sqrtesinw,logk, cosi,$
                p,   loga, logg,   teff,   feh,depth2,  u1,  u2, u3, u4,f0]
   transcale = [0d0,0d0,                   rvscale[2:5], 0d0,ucosi,$
                1d-1,2d-1,0.3d0,3*uteff,3*ufeh,  1d-2,0.15,0.15,0d0,0d0,replicate(1d-2,nlin)]

   if ~finite(transcale[2]) then transcale[2] = 0.1d0

   if not keyword_set(secondary) then begin
      transcale[4] = 0d0 ;; ecosw can be constrained by secondary timing
      transcale[13] = 0d0
   endif else if ~finite(transcale[4]) then transcale[4] = 0.5

   ;; esinw can be constrained by logg
   ;; logg -> mstar/rstar -> density -> a/rstar -> esinw (not entirely obvious)
   if ~finite(priors0[1,10]) then begin
      transcale[5] = 0d0
   endif else if ~finite(transcale[5]) then transcale[5] = 0.5

   ;; no power to constrain the period
   if (max(transit.bjd)-min(transit.bjd)) lt period then begin
      transcale[3] = 0d0
      tofittran = tofittran[where(tofittran ne 3)]
   endif else if ~finite(transcale[3]) then transcale[3] = 1d-3
  
   ;; use the priors to set the scale if they're lower
   transcale = (3d0*priors0[1,*]) < transcale

   ;; iterative sigma clipping of outliers
   repeat begin
      besttran = exofast_amoeba(1d-8,function_name=chi2func,$
                                p0=tranpars,scale=transcale,nmax=1d5)
      if besttran[0] eq -1 then begin
         print, 'ERROR: could not find best transit fit (may want to rerun with /DEBUG)'
         return
      endif

      chi2 = call_function(chi2func,besttran,modelflux=modelflux)
      outliers = where(abs(trandata.flux - modelflux)/trandata.err gt $
                       sigclip,noutliers)
      if noutliers gt 0 then begin
         trandata.err[outliers] = !values.d_infinity
         transit.err[outliers] = !values.d_infinity
      endif
   endrep until noutliers eq 0

   ;; scale the transit errors so P(chi^2) = 0.5
   ;; priors cancel in dof (extra measurement, extra constraint)
   dof=n_elements(where(finite(trandata.err)))-n_elements(where(transcale ne 0d0))
   errscale = sqrt(chi2/chisqr_cvf(0.5,dof)) ;; scale such that P(chi^2) = 0.5
   trandata.err *= errscale
   transit.err *= errscale
   
   print, ''
   print, 'Transit fit:'
   print, 'Chi^2/dof = ' + strtrim(chi2/dof,2)
   print, 'Scaling errors by ' + strtrim(errscale,2)
   print, 'RMS of residuals = ' + strtrim(stddev(trandata.flux-modelflux),2)

   ;; find the stepping scale for combined AMOEBA fit
   options.notran = 0
   options.norv = 1
   transcalemcmc = exofast_getmcmcscale(besttran,chi2func,tofit=tofittran)

   if transcalemcmc[0] eq -1 then begin
      print, 'ERROR: Transit fit unconstrained. Check your starting conditions.'
      return
   endif
   transcale[tofittran] = transcalemcmc
endif else transcale = dblarr(npars) + !values.d_infinity

;; the linear coefficient names
coeffnames = ['F_0','Baseline flux']
for i=1,nlin-1 do $
   coeffnames=[[coeffnames],['C_{'+strtrim(i-1,2)+'}','Detrending variable']]

;; output labels and units
latexnames = [['\gamma',      'Systemic velocity (m/s)'],$                 ;; 0 Step parameters
              ['\dot{\gamma}','RV slope (m/s/day)'],$                      ;; 1
              ['T_C',         'Time of transit (\bjdtdb)'],$               ;; 2
              ['\log{P}',     'Log of period'],$                           ;; 3
              ['e',           'Eccentricity'],$                            ;; 4
              ['\omega_*',    'Argument of periastron (degrees)'],$        ;; 5
              ['\log{K}',     'Log of RV semi-amplitude'],$                ;; 6
              ['\cos{i}',     'Cos of inclination'],$                      ;; 7
              ['R_{P}/R_{*}', 'Radius of planet in stellar radii'],$       ;; 8
              ['a/R_{*}',     'Semi-major axis in stellar radii'],$        ;; 9
              ['\log(g_*)',   'Surface gravity (cgs)'],$                   ;; 10
              ['\teff',       'Effective temperature (K)'],$               ;; 11
              ['\feh',        'Metalicity'],$                              ;; 12
              ['\delta_{S}',  'Eclipse depth'],$                           ;; 13
              ['u_1',         'linear limb-darkening coeff'],$             ;; 14
              ['u_2',         'quadratic limb-darkening coeff'],$          ;; 15 
              ['u_3',         'non-linear limb-darkening coeff'],$         ;; 16
              ['u_4',         'non-linear limb-darkening coeff'],$         ;; 17 
              [coeffnames       ],$                                        ;; 18:17+nlin (Linear pars [but stepped in])
              ['e\cos\omega_*',''],$                                       ;; 18+nlin (Derived pars)
              ['e\sin\omega_*',''],$                                       ;; 19+nlin
              ['T_{P}',       'Time of periastron (\bjdtdb)'],$            ;; 20+nlin
              ['b_{S}',       'Impact parameter'],$                        ;; 21+nlin
              ['T_{S,FWHM}',  'FWHM duration (days)'],$                    ;; 22+nlin
              ['\tau_S',      'Ingress/egress duration (days)'],$          ;; 23+nlin
              ['T_{S,14}',    'Total duration (days)'],$                   ;; 24+nlin
              ['P_{S}',       'A priori non-grazing eclipse prob'],$       ;; 25+nlin
              ['P_{S,G}',     'A priori eclipse prob'],$                   ;; 26+nlin
              ['T_{S}',       'Time of eclipse (\bjdtdb)'],$               ;; 27+nlin
              ['M_{*}',       'Mass (\msun)'],$                            ;; 28+nlin
              ['R_{*}',       'Radius (\rsun)'],$                          ;; 29+nlin
              ['L_{*}',       'Luminosity (\lsun)'],$                      ;; 30+nlin
              ['\rho_*',      'Density (cgs)'],$                           ;; 31+nlin
              ['P',           'Period (days)'],$                           ;; 32+nlin
              ['a',           'Semi-major axis (AU)'],$                    ;; 33+nlin
              ['M_{P}',       'Mass (\mj)'],$                              ;; 34+nlin
              ['R_{P}',       'Radius (\rj)'],$                            ;; 35+nlin
              ['\rho_{P}',    'Density (cgs)'],$                           ;; 36+nlin
              ['\log(g_{P})', 'Surface gravity'],$                         ;; 37+nlin
              ['T_{eq}',      'Equilibrium Temperature (K)'],$             ;; 38+nlin
              ['\Theta',      'Safronov Number'],$                         ;; 39+nlin
              ['\fave',       'Incident flux (\fluxcgs)'],$                ;; 40+nlin
              ['K',           'RV semi-amplitude (m/s)'],$                 ;; 41+nlin 
              ['M_P\sin i',   'Minimum mass (\mj)'],$                      ;; 42+nlin
              ['M_{P}/M_{*}', 'Mass ratio'],$                              ;; 43+nlin
              ['i',           'Inclination (degrees)'],$                   ;; 44+nlin
              ['b',           'Impact Parameter'],$                        ;; 45+nlin
              ['\delta',      'Transit depth'],$                           ;; 46+nlin
              ['T_{FWHM}',    'FWHM duration (days)'],$                    ;; 47+nlin
              ['\tau',        'Ingress/egress duration (days)'],$          ;; 48+nlin
              ['T_{14}',      'Total duration (days)'],$                   ;; 49+nlin
              ['P_{T}',       'A priori non-grazing transit prob'],$       ;; 50+nlin
              ['P_{T,G}',     'A priori transit prob']]                    ;; 51+nlin

              
;; re-organize the output table to a more intuitive order
sidelabels = ['Stellar Parameters:','Planetary Parameters:','RV Parameters:',$
              'Primary Transit Parameters:','Secondary Eclipse Parameters:']
order = [-1,[28,29,30,31]+nlin,10,11,12,$                      ;; stellar pars
         -1,4,5,[32,33,34,35,36,37,38,39,40]+nlin,$            ;; planetary pars
         -1,[18,19,20,41,42,43]+nlin,0,1,$                     ;; RV Pars
         -1,2,8,9,14,15,16,17,[44,45,46,47,48,49,50,51]+nlin,$ ;; Primary pars
         indgen(nlin)+18,$                                     ;; linear pars
         -1,13,[27,21,22,23,24,25,26]+nlin]                    ;; Secondary pars

;; fit all parameters (exclude them next, if desired)
tofit = [indgen(18+nlin)]
namendx = indgen(52+nlin)

;; if no slope is desired, exclude it
if keyword_set(noslope) then begin
   ;; exclude 1 (slope)
   tofit = mysetdiff(tofit,[1])
   namendx = mysetdiff(namendx,[1])
   ;; setdifference doesn't preserve order or duplicates
   order = mysetdiff(order,[1])
   slopetxt = 'f.'
endif else slopetxt = 'm.'

;; if we assume the orbit is circular, exclude e, omega
if keyword_set(circular) then begin
   ;; exclude 4,5 (e,omega)
   tofit = mysetdiff(tofit,[4,5])
   namendx = mysetdiff(namendx,[4,5,lindgen(9)+18+nlin])
   order = mysetdiff(order, [4,5,lindgen(9)+18+nlin])
   circtxt = 'c.'
endif else circtxt = 'e.'

;; if no secondary depth is desired, exclude it
if not keyword_set(secondary) then begin
   ;; exclude 13 (secondary depth)
   tofit = mysetdiff(tofit,[13])
   namendx = mysetdiff(namendx,[13])
   order = mysetdiff(order,[13])
endif

;; exclude u3,u4 from fit (unsupported for now)
tofit = mysetdiff(tofit,[16,17])
namendx = mysetdiff(namendx,[16,17])
order = mysetdiff(order,[16,17])

;; no transit, exclude all the transit parameters
if skiptran then begin
   ;; find the difference between the two vectors
   tofit = mysetdiff(tofit,[7,8,9,13,14,15,18])
   namendx = mysetdiff(namendx,[7,8,9,13,14,15,16,17,18,$
                   [21,22,23,24,34,35,36,37,39,44,45,46,47,48,50]+nlin])
   order = mysetdiff(order,[7,8,9,13,14,15,16,17,18,$
                   [21,22,23,24,34,35,36,37,39,44,45,46,47,48,50]+nlin])
endif

;; no rv, exclude all RV parameters
if skiprv then begin
   tofit = mysetdiff(tofit,[0,1,6])
   namendx = mysetdiff(namendx,[0,1,6,[34,36,37,39,41,42,43]+nlin])
   order =   mysetdiff(order,  [0,1,6,[34,36,37,39,41,42,43]+nlin])
endif

;; inputs labels to plotting program
latexnames = latexnames[*,namendx]

;; map the static indices onto variable indices
norder = n_elements(order)
vorder = intarr(norder)
for i=0, norder-1 do vorder[i] = where(namendx eq order[i])

;; trick TeXtoIDL
mydevice = !d.name
set_plot, 'PS'
parnames = TeXtoIDL(latexnames[0,*],font=0)
set_plot, mydevice

;; find the best fit of the two combined
scale = dblarr(npars)
pars = dblarr(npars)

if skiprv then begin
   scale = transcale
   pars = besttran
endif else if skiptran then begin
   scale = rvscale
   pars = bestrv
   pars[10:12] = priors0[0,10:12]
endif else begin
   goodtran = where((transcale le rvscale and transcale ne 0d0) or $
                    rvscale eq 0d0,complement=goodrv)
   if goodtran[0] ne -1 then begin
      scale[goodtran] = transcale[goodtran]
      pars[goodtran] = besttran[goodtran]
   endif
   if goodrv[0] ne -1 then begin
      scale[goodrv] = rvscale[goodrv]
      pars[goodrv] = bestrv[goodrv]
   endif
endelse
scale *= 3d0 ;; give us some wiggle room

if skiprv then options.norv = 1 else options.norv = 0
if skiptran then options.notran = 1 else options.notran = 0

;forprint,  parnames2, pars, scale, /t,format='(a10,x,f15.9,x,f15.9)'
;;options.debug=1
best = exofast_amoeba(1d-8,function_name=chi2func,p0=pars,scale=scale,nmax=1d5)
if best[0] eq -1 then begin
   print, 'ERROR: Could not find best combined fit'
   return
endif

;; output the best-fit model fluxes/rvs
bestchi2 = call_function(chi2func,best,modelrv=modelrv,modelflux=modelflux)
if ~lmgr(/demo) then begin
   if not skiptran then forprint, transit.bjd, modelflux, format='(f14.6,x,f0.6)', textout=prefix + 'model.' + circtxt + slopetxt + 'flux',/silent,/nocomment
   if not skiprv then forprint, rv.bjd, modelrv, format='(f14.6,x,f0.3)', textout=prefix + 'model.' + circtxt + slopetxt + 'rv',/silent,/nocomment
endif else begin
   ;; if a demo version, must be more clever (writing a file prohibited):
   if not skiptran then begin
      tranfile = prefix + 'model.' + circtxt + slopetxt + 'flux'
      spawn, 'echo ' + string(transit.bjd[0], modelflux[0], format='(f14.6,x,f0.6)') + ' > ' + tranfile
      for i=1, n_elements(modelflux)-1 do spawn, 'echo ' + string(transit.bjd[i], modelflux[i], format='(f14.6,x,f0.6)') + ' >> ' + tranfile
   endif
   
   if not skiprv then begin
      rvfile = prefix + 'model.' + circtxt + slopetxt + 'rv'
      spawn, 'echo ' + string(rv.bjd[0], modelrv[0], format='(f14.6,x,f0.3)') + ' > ' + rvfile
      for i=1, n_elements(modelrv)-1 do spawn, 'echo ' + string(rv.bjd[i], modelrv[i], format='(f14.6,x,f0.3)') + ' >> ' + rvfile
   endif
endelse

bestchi2 = call_function(chi2func,best, modelrv=modelrv, modelflux=modelflux)
print, ''
print, 'Combined fit:'

if not skiptran then begin
   ntran = strtrim(n_elements(where(finite(trandata.err))),2)
   chi2tran = strtrim(total(((modelflux - trandata.flux)/trandata.err)^2),2)
   print, 'Chi^2 of Transit data = ' + chi2tran + ' (' + ntran + ' data points)'
endif else ntran = 0

if not skiprv then begin
   nrv = strtrim(n_elements(where(finite(rvdata.err))),2)
   chi2rv = strtrim(total(((modelrv - rvdata.rv)/rvdata.err)^2),2)
   print, 'Chi^2 of RV data = ' + chi2rv + ' (' + nrv + ' data points)'
endif else nrv = 0

npriors = strtrim(n_elements(where(finite(priors0[1,*]))),2)
chi2priors = strtrim(total(((best - priors0[0,*])/priors0[1,*])^2),2)
print, 'Chi^2 of Priors = ' + chi2priors + ' (' + npriors + ' priors)'

dof = double(ntran) + nrv - n_elements(tofit)
print, 'Chi^2/dof = ' + strtrim(bestchi2/dof,2)
print, ''
;print, sqrt(bestchi2/chisqr_cvf(0.5,dof))
;print, chisqr_cvf(0.5,dof)
;stop

;; do the MCMC fit
;; must calculate scale before MCMC, because of scatter in Enoch relations
scale = exofast_getmcmcscale(best,chi2func,tofit=tofit,debug=options.debug)

if not keyword_set(bestonly) then begin
   exofast_demc, best, chi2func, pars, chi2=chi2, tofit=tofit,$
                 scale=scale, nthin=nthin,maxsteps=maxsteps,$
                 burnndx=burnndx, seed=seed, randomfunc=randomfunc0
   print, 'Synthesizing results; for long chains and/or many fitted parameters, this may take up to 15 minutes'

   ;; combine all chains
   sz = size(pars)
   npars = sz[1]
   nsteps = sz[2]
   nchains = sz[3]
   pars = reform(pars,npars,nsteps*nchains)
   chi2 = reform(chi2,nsteps*nchains)
   minchi2 = min(chi2,bestndx)
endif else begin
   pars = reform(best[tofit],n_elements(tofit),1)
   bestndx = 0
endelse

;; generate the model fit from the best MCMC values, not AMOEBA
bestamoeba = best
best[tofit] = pars[*,bestndx]
modelfile = prefix + 'model.' + circtxt + slopetxt + 'ps'
bestchi2 = call_function(chi2func,best,psname=modelfile, $
                         modelrv=modelrv, modelflux=modelflux)

;; get the named parameters out of the parameter array 
;; for each combination on input flags
offset = 0

;; no gamma
if skiprv then offset -= 1

;; no RV slope
if keyword_set(noslope) or skiprv then offset -= 1

tc = pars[2+offset,*]
logp = pars[3+offset,*]
period = 10^logp

;;; find the tc with the lowest covariance with period
;np = 0
;mincovar = 1d0
;done = 0
;repeat begin
;   covar = abs(correlate(period,tc + period*np))
;   if covar lt mincovar then begin
;      mincovar = covar
;      bestnp = np
;      if np ge 0 then np++
;      if np lt 0 then np--
;   endif else begin
;      if np gt 0 then np = -1 $
;      else done = 1
;   endelse
;endrep until done
;tc = tc + period*bestnp
;pars[2+offset,*] = tc

if not keyword_set(circular) then begin
   sqrtecosw = pars[4+offset,*] 
   sqrtesinw = pars[5+offset,*] 
   e = sqrtecosw^2 + sqrtesinw^2
   omega = atan(sqrtesinw,sqrtecosw)
   ecosw = e*cos(omega)
   esinw = e*sin(omega)
   pars[4+offset,*] = e
   pars[5+offset,*] = omega*180.d0/!dpi
   angular = 5+offset
endif else begin
   e = 0d0
   omega = !dpi/2d0
   offset -= 2
   esinw=0d0
   ecosw=0d0
endelse

if skiprv then begin 
   offset -= 1
   k = 0d0 ;; assume massless planet
endif else k = 10^pars[6+offset,*]

;; no transit file, skip transit parameters
if n_elements(tranfile) ne 1 then begin
   offset -= 3
   i = 90d0 ;; assume edge on
endif else begin
   cosi = pars[7+offset,*]
   i = acos(cosi)*180.d0/!dpi
   p = pars[8+offset,*]
   ar = 10^(pars[9+offset,*])
   pars[9+offset,*] = ar
endelse

logg = pars[10+offset,*]
teff = pars[11+offset,*]
feh  = pars[12+offset,*]

;; no secondary
if not keyword_set(secondary) then offset -= 1

if not skiptran then begin
   u1   = pars[14+offset,*]
   u2   = pars[15+offset,*]
   offset -= 2
   f0   = pars[18+offset,*]
endif

;; derive relevant parameters
G = 2942.71377d0 ;; R_sun^3/(m_sun*day^2), Torres 2009
mjup = 0.000954638698d0 ;; m_sun
rjup = 0.102792236d0    ;; r_sun
AU = 215.094177d0 ;; r_sun

if not skiptran then begin
   sini = sin(i*!dpi/180d0)
   a = (10^logg*(period*86400d0)^2/(4d0*!dpi^2*ar^2*100d0) + $
        K*(Period*86400d0)*sqrt(1d0-e^2)/(2d0*!dpi*sini))/6.9566d8   ;; R_sun
   rstar = a/ar                                                      ;; R_sun
   mp = 2d0*!dpi*(K*86400d0/6.9566d8)*a^2*sqrt(1d0-e^2)/(G*period*sini) ;; M_sun
   mstar = 4d0*!dpi^2*a^3/(G*period^2) - mp                             ;; M_sun
   msini = mp*sini
   q = mp/mstar
   
   rp = p*rstar                                ;; R_sun
   delta = p^2
   loggp = alog10(G*mp/rp^2*9.31686171d0)      ;; cgs
   corrmp = correlate(transpose(mp),transpose(rp),/double)

   ;; density of planet (cgs)
   rhop = mp/(rp^3)*1.41135837d0

   ;; Safronov Number eq 2, Hansen & Barman, 2007
   safronov = ar*q/p
   
endif else begin
   sini = 1d0
   massradius_torres,transpose(logg),transpose(teff),transpose(feh),mstar,rstar
   if n_elements(mstar) gt 1 then mstar = transpose(mstar)
   if n_elements(rstar) gt 1 then rstar = transpose(rstar)   

   msini = ktom2(k,e,!dpi/2d0,period,mstar)
   q = msini/mstar
   a = (G*period^2*(mstar)/(4d0*!dpi^2))^(1d0/3d0) ;; rsun
   ar = a/rstar
   
   ;; for transit durations
   p = 0d0 & rp = 0d0   ;; point planet
   cosi = 0d0           ;; central crossing
endelse

;; Stefan-boltzmann Constant (L_sun/(r_sun^2*K^4))
sigmab = 5.670373d-5/3.839d33*6.9566d10^2 
lstar = 4d0*!dpi*rstar^2*teff^4*sigmaB    ;; L_sun
Mv = -2.5d0*alog10(lstar)+4.83d0          ;; Absolute V-band Magnitude
Ma = Mv                                   ;; Apparent V-band Magnitude
distance = 10d0^((Ma-Mv)/5d0 + 1d0)

;; <F>, the time-averaged flux incident on the planet
;; (ar*(1d0+e^2/2d0)) = time averaged distance to the planet
sigmasb = 5.6704d-5 ;; stefan boltzmann constant 
incidentflux = sigmasb*teff^4/(ar*(1d0+e^2/2d0))^2/1d9    ;; 10^9 erg/s/cm^2
 
bp = ar*cosi*(1d0-e^2)/(1d0+esinw)
bs = ar*cosi*(1d0-e^2)/(1d0-esinw)

;; approximate durations taken from Winn 2010 (close enough; these
;; should only be used to schedule observations anyway)
t14 = period/!dpi*asin(sqrt((1d0+p)^2 - bp^2)/(sini*ar))*$
      sqrt(1d0-e^2)/(1d0+esinw)

;; no transit, transit duration equation is undefined -- set to zero
notransit = where(bp gt 1d0+p)
if notransit[0] ne -1 then t14[notransit] = 0d0

t23 = period/!dpi*asin(sqrt((1d0-p)^2 - bp^2)/(sini*ar))*$
      sqrt(1d0-e^2)/(1d0+esinw)

;; grazing transit, the flat part of transit is zero
grazing = where(bp gt 1d0-p)
if grazing[0] ne -1 then t23[grazing] = 0d0

tau = (t14-t23)/2d0
Tfwhm = t14-tau
primaryprobgraz = (rstar+rp)/a*(1d0 + esinw)/(1d0-e^2)    ;; equation 9
primaryprob     = (rstar-rp)/a*(1d0 + esinw)/(1d0-e^2)    ;; equation 9

;; durations of secondary
t14s = period/!dpi*asin(sqrt((1d0+p)^2 - bs^2)/(sini*ar))*$
       sqrt(1d0-e^2)/(1d0-esinw) ;; eq 14, 16
notransit = where(bs gt 1d0+p)
if notransit[0] ne -1 then t14s[notransit] = 0d0

;; flat part of eclipse
t23s = period/!dpi*asin(sqrt((1d0-p)^2 - bs^2)/(sini*ar))*$
       sqrt(1d0-e^2)/(1d0-esinw) ;; eq 15, 16
grazing = where(bs gt 1d0-p)
if grazing[0] ne -1 then t23s[grazing] = 0d0

taus = (t14s-t23s)/2d0
Tfwhms = t14s-taus
secondaryprobgraz = (rstar+rp)/a*(1d0 - esinw)/(1d0-e^2)    ;; equation 10
secondaryprob     = (rstar-rp)/a*(1d0 - esinw)/(1d0-e^2)    ;; equation 10

;; density of star (cgs)
rhostar = mstar/(rstar^3)*1.41135837d0

;; phases for primary and secondary transits
phase = exofast_getphase(e,omega, /primary)
phase2 = exofast_getphase(e,omega, /secondary)
phasea = exofast_getphase(e,omega, /ascending)
phased = exofast_getphase(e,omega, /descending)

;; periastron passage and secondary eclipse times
tp = tc - period*phase
ts = tc + period*(phase2-phase)
ta = tc + period*(phasea-phase) ;; ascending node (max RV)
td = tc + period*(phased-phase) ;; descending node (min RV)

;; it's possible tp,ts,ta,td could be split down the middle 
;; then the median would be meaningless -- correct that
medper = median(period)
tp = recenter(tp, medper)
ts = recenter(ts, medper)
ta = recenter(ta, medper)
td = recenter(td, medper)

;; the planet's equilibrium temperature 
;; no albedo, perfect redistribution
;; Eq 2, Hansen & Barman, 2007
teq = teff*sqrt(1d0/(2d0*ar))

;; convert times as measured in the SSB
tcbjdtdb = target2bjd(tc,inclination=i*!dpi/180d0, a=a/AU, tp=tp, $
                      period=period, e=e,omega=omega,q=q)
tpbjdtdb = target2bjd(tp,inclination=i*!dpi/180d0, a=a/AU, tp=tp, $
                      period=period, e=e,omega=omega,q=q)
tsbjdtdb = target2bjd(ts,inclination=i*!dpi/180d0, a=a/AU, tp=tp, $
                      period=period, e=e,omega=omega,q=q)

if skiptran then begin
   if not keyword_set(circular) then $
      pars = [pars,ecosw,esinw,tpbjdtdb,t14s,secondaryprob]
   
   pars = [pars,tsbjdtdb,mstar,rstar,lstar,rhostar,period,a/au,$
           teq,incidentflux,k,msini/mjup,q,t14,primaryprob]  
endif else if skiprv then begin
   ;; parameters to plot PDFs, covariances, and quote 68% confidence interval
   ;; must match output labels
   if not keyword_set(circular) then $
      pars = [pars,ecosw,esinw,tpbjdtdb,bs,tfwhms,taus,$
              t14s,secondaryprob,secondaryprobgraz]
   
   pars = [pars,tsbjdtdb,mstar,rstar,lstar,rhostar,period,a/au,rp/rjup,$
           teq,incidentflux,i,bp,delta,tfwhm,tau,t14,primaryprob,$
           primaryprobgraz]
endif else begin
   ;; parameters to plot PDFs, covariances, and quote 68% confidence interval
   ;; must match output labels
   if not keyword_set(circular) then $
      pars = [pars,ecosw,esinw,tpbjdtdb,bs,tfwhms,taus,$
              t14s,secondaryprob,secondaryprobgraz]
   
   pars = [pars,tsbjdtdb,mstar,rstar,lstar,rhostar,period,a/au,mp/mjup,rp/rjup,$
           rhop,loggp,teq,safronov,incidentflux,k,msini/mjup,q,$
           i,bp,delta,tfwhm,tau,t14,primaryprob,primaryprobgraz]
endelse

;; if only the best fit was done, print out the values and we're done
if keyword_set(bestonly) then begin
   nlabels = 0
   print, ''
   for i=0, n_elements(vorder)-1 do begin
      if vorder[i] eq -1 then begin
         if i ne n_elements(vorder)-1 then $
            if vorder[i+1] ne -1 then print, sidelabels[nlabels]
         nlabels++
      endif else begin
         print, latexnames[0,vorder[i]],latexnames[1,vorder[i]],$
                pars[vorder[i]],format='(a15,x,a40,x,f14.6)'
      endelse
   endfor

   if not skiptran then begin
      ;; calculate the analytic errors:
      ;; http://adsabs.harvard.edu/abs/2008ApJ...689..499C

      ;; for grazing (and limb-darkened) transits, p^2!=depth
      ;; Carter equations require depth
      exofast_occultquad, bp, 0, 0, p, mu1
      depth=1-mu1[0]
      
      ;; number of data points during T_FWHM
      npoints = n_elements(where(modelflux/f0[0] le (1-depth/2d0)))

      ;; equation 19
      Q = sqrt(npoints)*depth/mean(transit.err)
      theta = tau/tfwhm
      
      ;; equation 23
      sigmatc    = tfwhm*sqrt(theta/2d0)/Q
      sigmatau   = tfwhm*sqrt(6d0*theta)/Q
      sigmatfwhm = tfwhm*sqrt(2d0*theta)/Q
      sigmadepth = depth/Q
      
      print
      print, 'Errors from Carter et al., 2008 (eqs 19 & 23):'
      print, '\sigma_{T,C}    ~ ' + strtrim(sigmatc,2)
      print, '\sigma_{\tau}   ~ ' + strtrim(sigmatau,2)
      print, '\sigma_{T,FWHM} ~ ' + strtrim(sigmatfwhm,2)
      print, '\sigma_{\depth} ~ ' + strtrim(sigmadepth,2)
      print
      print, 'NOTE: depth used here ('+strtrim(depth,2)+') is not delta'
      print, '      if the transit is grazing'
      print
      print, 'NOTE: If chi2/dof of combined fit is not ~1, do not trust these -- rerun with errors equal to your original errors multiplied by the scaling'
      
   endif      
   return
endif

bestpars = pars[*,bestndx]

;; save the chain and chi2 the MCMC chain.
idlfile = prefix + 'mcmc.' + circtxt + slopetxt + 'idl'
npars = n_elements(pars[*,0])
pars = reform(pars,npars,nsteps,nchains)
chi2 = reform(chi2,nsteps,nchains)
save, pars, chi2, latexnames, burnndx, filename=idlfile

;; now trim the burn-in before making plots
pars = reform(pars[*,burnndx:nsteps-1,*],npars,(nsteps-burnndx)*nchains)
chi2 = reform(chi2[burnndx:nsteps-1,*],(nsteps-burnndx)*nchains)

;; output filenames
label = "tab:" + basename
caption = "Median values and 68\% confidence interval for " + basename
parfile = prefix + 'pdf.' + circtxt + slopetxt + 'ps'
covarfile = prefix + 'covar.' + circtxt + slopetxt + 'ps'
texfile = prefix + 'median.' + circtxt + slopetxt + 'tex'

;; make PDFs, covriances plots
exofast_plotdist, pars, finalpars, bestpars=bestpars, $
                  parnames=parnames, angular=angular,$
                  pdfname=parfile, covarname=covarfile,/degrees

;; make LaTeX table
exofast_latextab, finalpars, texfile, parnames=latexnames[0,*], $
                  units=latexnames[1,*], order=vorder,sidelabels=sidelabels, $
                  caption=caption, label=label

;; display all the plots, if desired
if keyword_set(display) then begin
   spawn, 'gv ' + parfile + ' &'
   spawn, 'gv ' + covarfile + ' &'
   spawn, 'gv ' + modelfile + ' &'
endif

end
