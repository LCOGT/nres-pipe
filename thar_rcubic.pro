pro thar_rcubic,cubfrz=cubfrz
; This routine does a robust weighted minimum-chi^2 fit to the residuals
; remaining after the 4-parameter fit to ThAr line positions vs x-posn
; and order, as done by the first part of thar_fitall.pro.
; It fits residuals of the form
;  res(jx,jord) =(c_00 + c_01*jord + c_02*jord^2 + c_03*jord^3 + c_04*jord^4)
;           + jx*(c_10 + c_11*jord + c_12*jord^2 + c_13*jord^3)
;         + jx^2*(c_20 + c_21*jord + c_22*jord^2)
;         + jx^3*(c_30 + c_31*jord)
;         + jx^4*(c40)
; Where jx = x - (nx/2.)
; and jord = iord - (nord/2)  (or jord = y0m - (max(y0m)+min(y0m))/2.)
; Weights are first set according to the expected errors matcherr_c,
; and are then adjusted to ignore lines that differ from the current
; best fit by more that thrsherr sigma.
; If keyword cubfrz is set, then the rcubic coefficients are computed, but
; are not updated in thar_comm array coefs_c.

@thar_comm

; constants
thr1=0.02                  ; threshold dif for retaining data, (nm)
thrshm=3.                  ; threshold dif for retaining data, median-sigma
tiny=1.e-10
radian=180.d0/!pi

; make starting weights
matchwts_0=1./(1.+(matchdif_c^2/dlam2_c))
thrsh=3.*sqrt(dlam2_c) < thr1          ; exclude outliers
s=where(abs(matchdif_c) gt thrsh,ns)
if(ns gt 0) then matchwts_0(s)=tiny

; make functions to fit.  Force 15 coeffs for thar data
ncoefs_c=15
funs=fltarr(nmatch_c,ncoefs_c)
jx=matchxpos_c-nx_c/2.
;jord=findgen(nord_c)-nord_c/2.
;jord=y0m_c-(max(y0m_c)+min(y0m_c))/2.     ; fit to x posn on chip, not ord no

; try using Legendre functions in the expansion, instead of these
;funs(*,0)=1.
;funs(*,1)=jord(matchord_c)
;funs(*,2)=(jord(matchord_c))^2
;funs(*,3)=(jord(matchord_c))^3
;funs(*,4)=jx
;funs(*,5)=jx*jord(matchord_c)
;funs(*,6)=jx*(jord(matchord_c))^2
;funs(*,7)=jx^2
;funs(*,8)=jx^2*jord(matchord_c)
;funs(*,9)=jx^3
;funs(*,10)=(jord(matchord_c))^4
;funs(*,11)=jx*(jord(matchord_c))^3
;funs(*,12)=jx^2*(jord(matchord_c))^2
;funs(*,13)=jx^3*jord(matchord_c)
;funs(*,14)=jx^4

; make functions for legendre poly fit
lx=2.*jx/nx_c
jord=matchord_c-nord_c/2.
lord=2.*jord/nord_c
lx0=mylegendre(lx,0)
lx1=mylegendre(lx,1)
lx2=mylegendre(lx,2)
lx3=mylegendre(lx,3)
lx4=mylegendre(lx,4)
lo0=mylegendre(lord,0)
lo1=mylegendre(lord,1)
lo2=mylegendre(lord,2)
lo3=mylegendre(lord,3)
lo4=mylegendre(lord,4)

funs(*,0)=lo0
funs(*,1)=lo1
funs(*,2)=lo2
funs(*,3)=lo3
funs(*,4)=lx1
funs(*,5)=lx1*lo1
funs(*,6)=lx1*lo2
funs(*,7)=lx2
funs(*,8)=lx2*lo1
funs(*,9)=lx3
funs(*,10)=lo4
funs(*,11)=lx1*lo3
funs(*,12)=lx2*lo2
funs(*,13)=lx3*lo1
funs(*,14)=lx4

; do the first fit
coefs_0=lstsqr(matchdif_c,funs,matchwts_0,ncoefs_c,rms,chisq,outp0,1,cov)

; compute scatter over points with non-tiny weights, do the fit again
sg=where(matchwts_0 ge 1.5*tiny,nsg)
;if(nsg gt 0) then rmsw=sqrt(total((outp0(sg))^2)/nsg)
if(nsg gt 4) then begin
  quartile,outp0(sg),med0,q,dq
  diff=outp0-med0
  rmsm=dq/1.35              ; gaussian rms estimated from interquartile range
  matchwts_c=1./(1.+(diff^2/rmsm^2))
  thrsh=thrshm*rmsm < 0.01  ; threshold for excluding data
  sb1=where(abs(diff) ge thrsh,nsb1)
  if(nsb1 gt 0) then matchwts_c(sb1)=tiny
endif
  
; #######
; Testing: try freezing coefs_c at its input value.
; Save the differences that would be applied, just to look at.
;coefs_c=coefs_c+lstsqr(matchdif_c,funs,matchwts_c,ncoefs_c,rms,chisq,$
;    outp_c,1,cov)
coefs_incr_c=lstsqr(matchdif_c,funs,matchwts_c,ncoefs_c,rms,chisq,$
    outp_c,1,cov)
;
;  End test  ###########

; compute scatter over points with non-tiny weights
sg=where(matchwts_c ge 1.5*tiny,nsg)
if(nsg gt 0) then rms_c=sqrt(total((outp_c(sg))^2)/nsg)
chi2_c=chisq

; make new wavelength model for matched lines
matchbest_c=matchlam_c - (matchdif_c-outp_c)

; update rcubic coefficients, if not frozen
if(not keyword_set(cubfrz)) then coefs_c=coefs_c-coefs_incr_c

; make updated wavelength solution on pixel grid
xx=pixsiz_c*(findgen(nx_c)-float(nx_c)/2.)      ; x-coord in mm
fibno=fibindx_c
sinalp=sin(grinc_c/radian)
specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
   grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
   coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
lambda3ofx,xx,mm_c,fibno,specstruc,lam_c,y0m_c,air=0    ; always vacuum lam

; for testing:  make new wavelength errors for matched lines using new
; wavelength grid.  This should agree with matchbest_c
newdif=[0.d0]
for i=0,nord_c-1 do begin
  sc=where(matchord_c eq i,nsc)
  if(nsc le 0) then begin
    goto,skip
  endif
  xg=matchxpos_c(sc)
  lamg=interpol(lam_c(*,i),findgen(nx_c),xg,/quadratic)
  llist=matchline_c(sc)
  newdif=[newdif,lamg-llist]
  skip:
endfor
newdif=newdif(1:*) 

; make diagnostic equal to wavelength difference across Mg b line order,
; minus a nominal value
if(strupcase(strtrim(site_c,2)) eq 'SQA') then begin
  mgbord=20
  dlamnom=8.      ; nominal wavelength span of order in nm
endif else begin
  mgbord=38
  dlamnom=10.5777
endelse
mgbdisp_c=lam_c(nx_c-1,mgbord)-lam_c(0,mgbord)-dlamnom
lammid_c=total(lam_c(2000,mgbord-5:mgbord+5))/11.

;stop

end
