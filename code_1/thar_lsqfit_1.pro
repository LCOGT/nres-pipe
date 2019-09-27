pro thar_lsqfit_1,dvals,dcoefs,rchisq,mchisq,nmatch,dofit=dofit,$
    recomp=recomp
; this routine computes dvals = desired perturbations to the main parmeters
; defining the wavelength solution, and to the restricted quartic fit coefs
; using an SVD-based least squares fit to the wavelength differences of all
; matched lines.
; On return,
; dvals=[a0,f0,g0,z0,ex0,ex1,ex2] defined as follows: 
; (0) a0 = perturbation to sin(angle of incidence)
; (1) f0 = perturbation to camera focal length (mm)
; (2) g0 = perturbation to y-coord at which gamma=0 (mm)
; (3) z0 = perturbation to redshift z (or refractive index of medium)
; (4) ex0 = perturbation to cubic distortion term
; (5) ew1 = perturbation to later chromatic aberration term
; (6) ew2 = perturbation to detector rotation term
; dcoefs(0:14) = perturbation to common array coefs_c(0:14)
; rchisq = reduced chisq averaged over all matched lines.

; Also contained in a common data area thar_am are the following:
; Nominal parameters describing the spectrograph, including
; mm(nord) = diffraction order vs order index
; d = grating groove spacing in lines/mm
; sinalp = sin(nominal incidence angle)
; fl = nominal camera focal length (mm)
; gltype = string identifying cross-dispersing prism glass type
; apex = prism apex angle (degree)
; lamcen = nominal wavelength for order on center of detector (micron)
; ncoefs, coefx = coefficients in a restricted cubic (or quartic, depending
; on the value of ncoefs) expansion of the residual errors after fitting
; the "big four" parameters.
; The order index, x-position, width, and amplitude of each line found in
; the observed spectrum.  These are termed "catalog" lines.
; The standard ThAr line list, giving wavelengths of ~3600 ThAr lines,
; (known as "line list" lines),
; pared down to exclude those that are outside the plausible range of
; values, or that are deemed unsuitable because of variable wavelengths.
; The function uses the perturbation input parameters and common parms
; to compute the model wavelength lam of each pixel in the spectrum.
; For each acceptable line in the catalog of the tharin spectrum, it computes
; a model wavelength by interpolation into the lam array.
; It then uses a line_wcs-like pattern match, based on pairs of lines in each
; list, for pairs of lines that are likely matches between the lists.
; it accepts corresponding lines in these matched pairs as matched lines.
; When done with all lines, it
; computes the mean squared wavelength error of the
; matching lines, and the number of matching lines.  Whether the routine uses
; a cubic or quartic expansion is determined by the size of the common array
; coefs_c:  10 -> cubic, 15 -> quartic.
; The mean squared
; wavelength error dlam2 is returned by the function, and lam, nmatch,
; and the y-coords y0m of the order centers are returned in the
; common area.
; Also in common are vectors containing various quantities 
; related to the matched lines:
;  matchlam = model wavelength of each matched "catalog" line
;  matchamp = amplitude (ie, total e-) of matched "catalog" line
;  matcherr = uncertainty of obs'd "catalog" line position (nm)
;  matchdif = difference between model line lambda and linelist lambda (nm)
;  matchord = order index (0 to nord-1) in which matched line appears
;  matchxpos = x-coord of observed matched "catalog" line (pix)
;  diff = vector of the same length as the number of observed lines.  Elements
;    are the same as matchdif for matched lines, if unmatched then a standard
;    large positive value (typ 0.3 nm).
; If keyword recomp is set, then the least-squares fitting functions are recomputed
; before the fit is attempted.  Otherwise, values from thar_comm_stg2 are used.
;

; common block
@nres_comm
@thar_comm_1

; common area for debugging data
common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun,ie0,ie1,ie2

; constants
rutname='thar_lsqfit_1'
radian=180.d0/!pi
ierr_c=0
dw=0.3           ; expect guess wavelengths to be better than this (nm)
ds=0.015          ; expect wavelength differences to be better than this (nm)
dwu=0.1          ; set line differences to this number if unmatched (nm)
thr1=0.02                  ; threshold dif for retaining data, (nm)
tiny=1.e-20
clipthr=5.       ; threshold for clipping poorly-fitting lines

;print,'thar_mpfit parms:',parmsin

; set up calling parameters for current SG
wavelen=dblarr(nx_c,nord_c)
sinalp=sinalp_c
fl=fl_c
y0=y0_c
z0=z0_c
ex0=ex0_c
ex1=ex1_c
ex2=ex2_c

xx=pixsiz_c*(findgen(nx_c)-float(nx_c)/2.)      ; x-coord in mm
fibno=fibindx_c
specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
   grspc:grspc_c,rot:rot_c,sinalp:sinalp,fl:fl,y0:y0,z0:z0,ex0:ex0,ex1:ex1,$
   ex2:ex2,coefs:coefs_c,$
    ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
lambda3ofx,xx,mm_c,fibno,specstruc,lam_c,y0m_c,air=0    ; always vacuum lam

; make dlambda/dx, for later use
dlamdx=fltarr(nx_c,nord_c)
for i=0,nord_c-1 do begin
  dlamdx(*,i)=deriv(lam_c(*,i))
endfor

; compute model wavelengths of catalog lines, from their x-positions
; make list of unique iord values
so=sort(iord_c)
ios=iord_c(so)
iou=ios(uniq(ios))
nio=n_elements(iou)

; make a list of matches between catalog and linelist lines
matchlam_c=[]          ; model wavelengths, for matches
matchamp_c=[]            ; observed amplitudes, for matches
matcherr_c=[]            ; wavelength uncertainty of obsd line, for matches
matchdif_c=[]           ; model - linelist wavelengths, for matches
matchline_c=[]           ; linelist wavelengths, for matches
matchord_c=[]             ; model order index
matchxpos_c=[]           ; obs'd x-coord associated with matched line
matchwid_c=[]            ; obs'd width of matched line (pix)
unmatchlam_c=[]        ; wavelengths of unmatched obsd lines
unmatchamp_c=[]          ; amplitudes of unmatched obsd lines

; loop over the represented orders
nos=n_elements(oskip_c)
for i=0,nio-1 do begin
; select the catalog lines in this order
  sc=where(iord_c eq i,nsc)
; if(nsc le 0) then begin
  so=where(oskip_c eq i,nso)
  if(nsc le 0 or nso eq 1) then begin  ; skip order oskip_c, for testing
    goto,skip
  endif
  xg=xpos_c(sc)     ; x positions in this order in pix
  lamg=interpol(lam_c(*,i),findgen(nx_c),xg,/quadratic)
  widg=wid_c(sc)
  ampg=amp_c(sc)
  ordg=iord_c(sc)
  
; pattern match these lines against those in line list for the given order
; (plus 0.5 nm on each end, to account for possible wavelength error)
; first make linelist line selection array = lamlist
  lamgmin=min(lam_c(*,i))-0.5
  lamgmax=max(lam_c(*,i))+0.5
  sl=where(linelam_c ge lamgmin and linelam_c le lamgmax,nsl)
  if(nsl gt 2) then lamlist=linelam_c(sl)
  if(nsl le 2) then begin
    diff_c(sc)=dwu
    nmatch_c=0
    goto,skip
  endif

; now make lists of line pair parameters -- mean and difference wavelengths.
  lineseg,lamg,lgindx,lgparm
  lineseg,lamlist,llindx,llparm
  if(lgindx(0,0) lt 0 or llindx(0,0) lt 0) then goto,skip

; match these lists of pairs
  matchline,nsc,lgindx,lgparm,nsl,llindx,llparm,$
     dw,ds,votes

; select "good" matches:  more than 4 votes or 2/3 of the max number of
; votes, whichever is larger.
  mxvote=max(votes)
  votethrsh=(5 > mxvote*2./3.)
  sv=where(votes ge votethrsh,nsv)
  if(nsv gt 0) then begin            
    ixl=sv/nsc       ; indices of matched lines in lamlist
    ixg=sv-nsc*ixl   ; indices in lamg
;       note both ixl and ixg may contain duplicate entries.

; retain only unique list of observed lines ixu (a subset of ixg).
; if some ixg values are multiple, choose the instance with smallest
; abs of difference lamg - lamlist.
    uniqixg,ixg,ixl,lamg,lamlist,ixu,ixlu,tdif
    nixu=n_elements(ixu)

    matchlam_c=[matchlam_c,lamg(ixu)]
    matchamp_c=[matchamp_c,ampg(ixu)]
    dldx=dlamdx(xg(ixu),ordg(ixu))
    matcherr_c=[matcherr_c,dldx*widg(ixu)/sqrt(ampg(ixu))]
;   matchdif_c=[matchdif_c,lamg(ixg)-lamlist(ixl)]
    matchdif_c=[matchdif_c,tdif]
    matchline_c=[matchline_c,lamlist(ixlu)]
    matchord_c=[matchord_c,ordg(ixu)]
    matchxpos_c=[matchxpos_c,xg(ixu)]
    matchwid_c=[matchwid_c,widg(ixu)]

; identify matched and unmatched lines in this order.  Update list of
; wavelength differences per observed line, set to value of dwu if unmatched
    smu=intarr(nsc)              ; set to 1 for matched lines
    smu(ixu)=1
    sunmat=where(smu eq 0,nsun)  ; unmatched obsd line indices

    unmatchlam_c=[unmatchlam_c,lamg(sunmat)]
    unmatchamp_c=[unmatchamp_c,ampg(sunmat)]
    diff_c(sc(ixu))=tdif
    diff_c(sc(sunmat))=dwu             ; default diff for unmatched lines

  endif else begin
    diff_c(sc)=dwu
  endelse
skip:
endfor

nmatch_c=n_elements(matchord_c)
if(nmatch_c) gt 1 then begin
  nmatch_c=n_elements(matchord_c)
  dlam2_c=total(matchdif_c)^2/(nmatch_c > 1)
endif else begin
  nmatch_c=0
  dlam2_c=1.e20
endelse

; debug info
inmatch(niter_c)=nmatch_c
isalp(niter_c)=sinalp
ifl(niter_c)=fl
iy0(niter_c)=y0
iz0(niter_c)=z0
ifun(niter_c)=dlam2_c
niter_c=niter_c+1

; compute number of matched lines, mean squared error.
dlam2_c=total(matchdif_c^2)/(nmatch_c > 1)
chi2=total((matchdif_c/matcherr_c)^2)/(nmatch_c > 1)

;print,'nmatch_c, dlam = ',nmatch_c,sqrt(dlam2_c)
if(nmatch_c le 0) then begin
  ierr=1
  logo_nres2,rutname,'ERROR','FATAL ierr=1: No line matches found.'
endif

; set up for weighted SVD-based linear least squares fit to minimize residuals
dat=matchdif_c
matchwts_0=1./(1.+(matchdif_c^2/dlam2_c))
thrsh=3.*sqrt(dlam2_c) < thr1          ; exclude outliers
s=where(abs(matchdif_c) gt thrsh,ns)
if(ns gt 0) then matchwts_0(s)=tiny

; make functions to fit.  Force 15 coeffs for thar data
ncoefs_c=15
nfuns=ncoefs_c+7
funs=dblarr(nmatch_c,nfuns)
jx=matchxpos_c-nx_c/2.

; make functions to be fit, for all orders and x positions
; These are the functions multiplying the fitting parameters
if(keyword_set(recomp)) then begin
  dlamdparm3_1,site,lam,/gotsp
endif else begin
  print,'skipping dlamdparm3 compute'
endelse

; interpolate these onto the x positions & orders of the observed lines. 
dblx=dindgen(nx_c)
for j=0,nord_c-1 do begin
  s=where(matchord_c eq j,ns)
  if(ns gt 0) then begin
   for k=0,6 do begin
     funs(s,k)=interpol(dlamdparms(*,j,k),dblx,matchxpos_c(s))
   endfor
   for k=0,ncoefs_c-1 do begin
     funs(s,7+k)=interpol(dlamdcoefs(*,j,k),dblx,matchxpos_c(s))
   endfor
  endif
endfor

;stop

; fit the observed wavelength differences
cc0=lstsqr(dat,funs,matchwts_0,nfuns,rms0,chisq0,outp0,1,cov0,ierr,$
  svdminrat=1.e-8,dofit=dofit)

; identify lines with unreasonably large deviations, adjust their weights
quartile,outp0,med,q,dq
qsig=dq/1.35                      ; sigma of equiv gaussian
sc=where(abs(outp0) ge clipthr*qsig,nsg)
matchwts_1=matchwts_0
if(nsg gt 0) then matchwts_1(sc)=0.

; and fit again
cc1=lstsqr(dat,funs,matchwts_1,nfuns,rms1,chisq1,outp1,1,cov1,ierr,$
  svdminrat=1.e-8,dofit=dofit)

; and again
quartile,outp1,med,q,dq
qsig=dq/1.35                      ; sigma of equiv gaussian
sc=where(abs(outp1) ge clipthr*qsig,nsc)
matchwts_2=matchwts_1
if(nsc gt 0) then matchwts_2(sc)=0.

cc2=lstsqr(dat,funs,matchwts_2,nfuns,rms2,chisq2,outp2,1,cov2,ierr,$
  svdminrat=1.e-8,dofit=dofit)

; funs are normalized versions of derivatives of the model parameters;
; undo the normalization to yield dvals, dcoefs
dvals=cc2(0:6)/dparmnorm
dcoefs=cc2(7:*)/dcoefnorm
outp_c=outp2

;stop

schi=where(matchwts_2 gt 2*tiny,nmatch)
rchisq=total((outp2(schi)/matcherr_c(schi))^2)/(nmatch > 1)
mchisq=median((outp2(schi)/matcherr_c)^2)

;stop

; return vector diff_c, normalized by uncertainties in matcherr
; and perhaps sigma clipped to exclude bad lines
; 
; return nothing from this routine --  it is not a function
if(ierr_c eq 0) then begin
  ;print,'FOM=',total((clip_c*diff_c/xperr_c)^2)
; return,clip_c*diff_c/xperr_c
endif else begin
; return,dblarr(nsc)+1.e20
endelse

end
