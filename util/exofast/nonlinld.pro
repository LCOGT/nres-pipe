;+
; NAME:
;   NONLINLD
;
; PURPOSE: 
;   Interpolates the non-linear limb darkening tables of Claret and
;   Bloemen (2011). http://adsabs.harvard.edu/abs/2011A%26A...529A..75C
;
; DESCRIPTION:
;   Loads an IDL save file found in $EXOFAST_PATH/quadld/, then
;   does a 3D linear interpolation of the table. 
;
; CALLING SEQUENCE:
;    coeffs = nonlinld(logg, teff, feh, band [,MODEL=, METHOD=, VT=]);
; INPUTS:
;    LOGG - The log of the stellar surface gravity
;    TEFF - The stellar effective temperature
;    FEH  - The stellar metalicity
;    BAND - The observed bandpass. Allowed values are those defined in
;           Claret and Bloemen:
;             U,B,V,R,I,J,H,K, (Johnson/Cousins)
;             u',g',r',i',z', (Sloan)
;             Kepler, CoRoT, 
;             Spitzer 3.6 um, Spitzer 4.5 um, Spitzer 5.8 um Spitzer 8.0 um, 
;             u,b,v,y (Stromgren)
;
; OPTIONAL INPUTS:
;    MODEL  - The atmospheric model used to determine the limb
;             darkening values. Choose ATLAS or PHOENIX (default ATLAS).
;    METHOD - The method used. Choose L or F (default L)
;    VT     - The microturbulent velocity (0,2,4,or 8, default 2)
;   
; RESULT:
;    The non-linear limb darkening parameters
;
; COMMON BLOCKS:
;   NONLINLD_BLOCK - This is a self-contained block that stores the
;                    contents of the IDL save files. This common block saves
;                    the expensive step of restoring the same save files
;                    for repeated calls (e.g., during and MCMC fit).
;
; MODIFICATION HISTORY
; 
;  2012/06 -- Public release -- Jason Eastman (LCOGT)
;  2013/01 -- Changed save filenames so they're not case sensitive
;             (now works with OSX) -- thanks Stefan Hippler.
;-
function nonlinld, logg, teff, feh, band, model=model, method=method, vt=vt

;; restoring these is way too slow for MCMC fits
;; can't pass them from EXOFAST_MCMC in a general way
;; make them global for 100x improvement
;; only needs to talk to itself
COMMON NONLINLD_BLOCK, a1, a2, a3, a4

fehs = [-5d0+dindgen(10)*0.5,-0.3d0+dindgen(7)*0.1d0,0.5d0+dindgen(2)*0.5d0]
loggs = dindgen(11)*0.5d0
teffs = [3.5d3 + dindgen(39)*2.5d2,1.4d4 + dindgen(24)*1d3,3.75d4,$
         3.8d4+dindgen(5)*1d3,4.25d4,4.3d4+dindgen(5)*1d3,4.75d4,$
         4.8d4+dindgen(3)*1d3]
bands = ['U','B','V','R','I','J','H','K',$
         'Sloanu','Sloang','Sloanr','Sloani','Sloanz',$
         'Kepler','CoRoT','Spit36','Spit45','Spit58','Spit80',$
         'u','b','v','y']
nbands = n_elements(bands)
ndx = where(bands eq band)

if band eq 'u' then bandname = 'Stromu' $
else if band eq 'b' then bandname = 'Stromb' $
else if band eq 'v' then bandname = 'Stromv' $
else if band eq 'y' then bandname = 'Stromy' $
else bandname = band

if n_elements(a1) eq 0 then a1 = dblarr(11,79,19,nbands)
if n_elements(a2) eq 0 then a2 = dblarr(11,79,19,nbands)
if n_elements(a3) eq 0 then a3 = dblarr(11,79,19,nbands)
if n_elements(a4) eq 0 then a4 = dblarr(11,79,19,nbands)

if not keyword_set(a1[0,0,0,ndx]) and not keyword_set(a2[0,0,0,ndx]) and $
   not keyword_set(a3[0,0,0,ndx]) and not keyword_set(a4[0,0,0,ndx]) then begin

   ;; retore the 3D array of Claret values
   ;; see claretlin.pro
   
   if n_elements(model) eq 0 then model = 'ATLAS'
   if n_elements(method) eq 0 then method = 'L'
   if n_elements(vt) eq 0 then vt = 2L
   
   filename = getenv('EXOFAST_PATH') + '/quadld/' + model + '.' + method + $
              '.' + string(vt,format='(i1)') + '.' + bandname + '.nonlin.sav' 
   restore, filename

   ;; populate the array, only as needed
   a1[*,*,*,ndx] = nla1
   a2[*,*,*,ndx] = nla2
   a3[*,*,*,ndx] = nla3
   a4[*,*,*,ndx] = nla4

endif

;; where to interpolate in the axis
loggx = interpol(indgen(n_elements(loggs)),loggs,logg)
teffx = interpol(indgen(n_elements(teffs)),teffs,teff)
fehx = interpol(indgen(n_elements(fehs)),fehs,feh)

;; interpolate (linearly)
u1 = interpolate(a1[*,*,*,ndx], loggx, teffx, fehx)
u2 = interpolate(a2[*,*,*,ndx], loggx, teffx, fehx)
u3 = interpolate(a3[*,*,*,ndx], loggx, teffx, fehx)
u4 = interpolate(a4[*,*,*,ndx], loggx, teffx, fehx)

return, [u1,u2,u3,u4]

end

