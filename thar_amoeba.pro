function thar_amoeba,parmsin
; this function accepts a 4-element vector parmsin:
; (0) a0 = perturbation to angle of incidence (radian)
; (1) f0 = perturbation to camera focal length (mm)
; (2) g0 = perturbation to y-coord at which gamma=0 (mm)
; (3) z0 = perturbation to redshift z (or refractive index of medium)
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
;

; common block
@thar_comm

; common area for debugging data
common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun

; constants
radian=180.d0/!pi
ierr_c=0
dw=0.3           ; expect guess wavelengths to be better than this (nm)
ds=0.015          ; expect wavelength differences to be better than this (nm)

; make the line catalog from the input file
;;thar_catalog,tharspec_c,thrshamp,iord,xpos,amp,wid

print,'thar_amoeba parms:',parmsin

; set up calling parameters for current SG
a0=parmsin(0)
f0=parmsin(1)
g0=parmsin(2)
z1=parmsin(3)
wavelen=dblarr(nx_c,nord_c)
sinalp=sin(asin(sinalp_c+a0))
fl=fl_c+f0
y0=y0_c+g0
z0=z0_c+z1
xx=pixsiz_c*(findgen(nx_c)-float(nx_c)/2.)      ; x-coord in mm
fibno=fibindx_c
specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
   grspc:grspc_c,rot:rot_c,sinalp:sinalp,fl:fl,y0:y0,z0:z0,coefs:coefs_c,$
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
matchlam_c=[0.d0]          ; model wavelengths, for matches
matchamp_c=[0.]            ; observed amplitudes, for matches
matcherr_c=[0.]            ; wavelength uncertainty of obsd line, for matches
matchdif_c=[0.]           ; model - linelist wavelengths, for matches
matchline_c=[0.]           ; linelist wavelengths, for matches
matchord_c=[0]             ; model order index
matchxpos_c=[0.]           ; obs'd x-coord associated with matched line
matchwid_c=[0.]            ; obs'd width of matched line (pix)
unmatchlam_c=[0.d0]        ; wavelengths of unmatched obsd lines
unmatchamp_c=[0.]          ; amplitudes of unmatched obsd lines

; loop over the represented orders
missed=0L
for i=0,nio-1 do begin
; select the catalog lines in this order
  sc=where(iord_c eq i,nsc)
  if(nsc le 0) then begin
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
    diff_c(sc)=dw
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

;    lu=lindgen(nsc)+1       ; indices of line catalog for this order
;    lu(ixg)=0               ; lines that are matched
;    su=where(lu gt 0,nsu)   ; indices of unmatched lines in catalog
;
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
; wavelength differences per observed line, set to value of dw if unmatched
    smu=intarr(nsc)              ; set to 1 for matched lines
    smu(ixu)=1
    sunmat=where(smu eq 0,nsun)  ; unmatched obsd line indices

    unmatchlam_c=[unmatchlam_c,lamg(sunmat)]
    unmatchamp_c=[unmatchamp_c,ampg(sunmat)]
    diff_c(sc(ixu))=tdif
    diff_c(sc(sunmat))=dw             ; default diff for unmatched lines

  endif else begin
    missed=missed+nsc
    diff_c(sc)=dw
  endelse
skip:
endfor

; make the following list only before the first iteration -- do this to
; keep the line list constant during the search for optimum.
; No!  First try doing the matching every time.
nmatch_c=n_elements(matchord_c)

if(nmatch_c) gt 1 then begin
  matchlam_c=matchlam_c(1:*)
  matchamp_c=matchamp_c(1:*)
  matcherr_c=matcherr_c(1:*)
  matchdif_c=matchdif_c(1:*)
  matchline_c=matchline_c(1:*)
  matchord_c=matchord_c(1:*)
  matchxpos_c=matchxpos_c(1:*)
  matchwid_c=matchwid_c(1:*)
  nmatch_c=n_elements(matchord_c)
  dlam2_c=total(matchdif_c)^2/(nmatch_c > 1)
endif else begin
  nmatch_c=0
  dlam2_c=1.e20
endelse

inmatch(niter_c)=nmatch_c
isalp(niter_c)=sinalp
ifl(niter_c)=fl
iy0(niter_c)=y0
iz0(niter_c)=z0
ifun(niter_c)=dlam2_c
niter_c=niter_c+1

; compute the polynomial fit
;thar_rcubic
;dlam2_c=total(outp_c^2)/(nmatch_c > 1)

; compute number of matched lines, mean squared error.
dlam2_c=total(matchdif_c^2)/(nmatch_c > 1)
chi2=total((matchdif_c/matcherr_c)^2)/(nmatch_c > 1)

print,'nmatch_c, dlam = ',nmatch_c,sqrt(dlam2_c),dlam2_c
;if(nmatch_c le 0) then stop

fini:
if(ierr_c eq 0) then begin
  return,dlam2_c
endif else begin
  return,1.e20
endelse

end
