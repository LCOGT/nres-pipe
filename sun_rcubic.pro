pro sun_rcubic
; This routine does a robust weighted minimum-chi^2 fit to the residuals
; remaining after the 4-parameter fit to solar line positions vs x-posn
; and order, as done by the first part of thar_fitall.pro.
; It fits residuals of the form
;  res(jx,jord) =(c_00 + c_01*jord + c_02*jord^2 + c_03*jord^3)
;           + jx*(c_10 + c_11*jord + c_12*jord^2)
;         + jx^2*(c_20 + c_21*jord)
;         + jx^3*(c_30)
; Where jx = x - (nx/2.)
; and jord = iord - (nord/2)  (or jord = y0m - (max(y0m)+min(y0m))/2.)
; Weights are first set according to the expected errors matcherr_c,
; and are then adjusted to ignore lines that differ from the current
; best fit by more that thrsherr sigma.

; common block
common sun_am, mm_c,d_c,sinalp_c,fl_c,y0_c,z0_c,gltype_c,priswedge_c,lamcen_c,$
       r0_c,pixsiz_c,nx_c,nord_c,nl_c,linelam_c,$
       dsinalp_c,dfl_c,dy0_c,dz0_c,dlam2_c,$
       nblock_c,nfib_c,npoly_c,ordwid_c,medboxsz_c,$
       matchlam_c,matcherr_c,matchdif_c,matchord_c,matchxpos_c,$
       matchwts_c,matchbest_c,nmatch_c,$
       lam_c,y0m_c,coefs_c,ncoefs_c,$
       site_c,fibindx_c,fileorg_c,ierr_c

; constants
thr1=0.1                  ; threshold dif for retaining data, (nm)
tiny=1.e-10

; make starting weights
matchwts_0=1./(1.+(matchdif_c^2/dlam2_c))
thrsh=5.*sqrt(dlam2_c) < thr1          ; exclude outliers
s=where(abs(matchdif_c) gt thrsh,ns)
if(ns gt 0) then matchwts_0(s)=tiny

; make functions to fit
ncoefs_c=15                                ; force 10 coeffs for sun data
coefs_c=coefs_c(0:9)
funs=fltarr(nmatch_c,ncoefs_c)
jx=matchxpos_c-nx_c/2.
jord=findgen(nord_c)-nord_c/2.
;jord=y0m_c-(max(y0m_c)+min(y0m_c))/2.     ; fit to x posn on chip, not ord no

funs(*,0)=1.
funs(*,1)=jord(matchord_c)
funs(*,2)=(jord(matchord_c))^2
funs(*,3)=(jord(matchord_c))^3
funs(*,4)=jx
funs(*,5)=jx*jord(matchord_c)
funs(*,6)=jx*(jord(matchord_c))^2
funs(*,7)=jx^2
funs(*,8)=jx^2*jord(matchord_c)
funs(*,9)=jx^3

; do the first fit
coefs_0=lstsqr(matchdif_c,funs,matchwts_0,10,rms,chisq,outp0,1,cov)

; compute scatter over points with non-tiny weights, do the fit again
sg=where(matchwts_0 ge 1.5*tiny,nsg)
if(nsg gt 0) then rmsw=sqrt(total((outp0(sg))^2)/nsg)

matchwts_c=1./(1.+(outp0^2/rmsw^2))
thrsh=3.*rmsw < 0.01          ; exclude outliers
s=where(abs(outp0) gt thrsh,ns)
if(ns gt 0) then matchwts_c(s)=tiny
coefs_c=lstsqr(matchdif_c,funs,matchwts_c,10,rms,chisq,outp,1,cov)

; compute scatter over points with non-tiny weights
sg=where(matchwts_c ge 1.5*tiny,nsg)
if(nsg gt 0) then rms_c=sqrt(total((outp(sg))^2)/nsg)
chi2_c=chisq

; make new wavelength model for matched lines
matchbest_c=matchlam_c - (matchdif_c-outp)

; make updated wavelength solution on pixel grid
kx=dindgen(nx_c)-nx_c/2.
for i=0,nord_c-1 do begin
  lam_c(*,i)=lam_c(*,i) + coefs_c(0) + coefs_c(1)*jord(i) + $
             coefs_c(2)*jord(i)^2 + coefs_c(3)*jord(i)^3 + $
        kx*( coefs_c(4) + coefs_c(5)*jord(i) + coefs_c(6)*jord(i)^2 ) + $
      kx^2*( coefs_c(7) + coefs_c(8)*jord(i) ) + $
      kx^3*( coefs_c(9))
endfor
 
end
