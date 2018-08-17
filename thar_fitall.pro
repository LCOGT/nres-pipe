pro thar_fitall,sgsite,fibindx,ierr,trp=trp,tharlist=tharlist,cubfrz=cubfrz,$
  oskip=oskip
; This is the main routine to fit wavelength solutions to ThAr spectra.
; On input, sgsite = one of {'SQA','ELP','TEN','ALI','LSC','CPT','BPL'},
; encoding the identity of the spectrograph. 
;      tharlist = name of a text file containing the full paths of input
;                 data IDL .idl files, one per line.  All these will be averaged.
;      fibindx = fiber index {0,1,2} to be processed.
; On output, ierr = 0 is normal; anything else is a fatal error.
; If keyword cubfrz is set, then the 15 rcubic coefficients are frozen
; (taken as given in the spectrographs.csv entry).
; If keyword oskip is set and not zero, then order oskip-1 is skipped in the
; wavelength solution.  Used in search for bad lines.

; common block

@thar_comm

common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun,ie0,ie1,ie2

; constants
rutname='thar_fitall'
radian=180.d0/!pi
nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
outpath=nresrooti+'reduced/thar/'
dw=0.1         ; (nm) unmatched lines get their difference against model set to
               ; this value.
minmatch=20    ; must match at least this many lines to run thar_rcubic
ierr=0

; get SG parameters, set up massaged input in common block
;thar_setup,sgsite,fibindx,ierr,trp=trp,tharlist=tharlist
thar_setup2,sgsite,fibindx,ierr,trp=trp,tharlist=tharlist
;if(ierr_c ne 0) then stop
if(ierr_c ne 0) then begin
  logo_nres2,rutname,'ERROR','FATAL ierr='+string(ierr)+' from thar_setup'
  goto,fini
endif
site_c=sgsite
fibindx_c=fibindx
;print,'In thar_fitall, fibindx=',fibindx
;stop

if(keyword_set(oskip)) then oskip_c=oskip-1 else oskip_c=[-1]

; run amoeba search to find optimum values of a0,f0,g0,z0
p0=[0.d0,0.d0,0.d0,0.d0,0.d0,0.d0,0.d0]+5.d-4 ; [sin(alp), fl (mm), y0 (mm), z0]
                                              ; ex0, ex1, ex2
scale=0.3*[dsinalp_c,dfl_c,dy0_c,dz0_c,dex0_c,dex1_c,dex2_c]
ftol=1.d-4
ncalls=0L
nmax=1000
function_val=double([0.,0.,0.,0.,0.,0.,0.])
niter_c=0

; debugging data
inmatch=lonarr(nmax)
isalp=dblarr(nmax)
ifl=dblarr(nmax)
iy0=dblarr(nmax)
iz0=dblarr(nmax)
ifun=dblarr(nmax)
ie0=dblarr(nmax)
ie1=dblarr(nmax)
ie2=dblarr(nmax)
if(ierr_c ne 0) then begin
  logo_nres2,rutname,'ERROR','FATAL err=1'
  goto,fini
endif

; trying mpfit now ######################
; vals=amoeba(ftol,function_name='thar_amoeba',ncalls=ncalls,nmax=nmax,$
;             function_val=function_val,p0=p0,scale=scale)
; ierr=ierr+ierr_c
; if(ierr_c ne 0) then stop
; if(ierr_c ne 0) then goto,fini
; print,'ncalls = ',ncalls

; #########hack to force spectrograph parms to remain fixed
;vals=[0.,0.,0.,0.]
;nmatch_c=11
;nmatch=nmatch_c
;dlam2_c=1.e4
;matchlam_c=dblarr(nmatch)
;matchamp_c=fltarr(nmatch)
;matchwid_c=fltarr(nmatch)
;matchline_c=dblarr(nmatch)
;matchxpos_c=dblarr(nmatch)
;matchord_c=lonarr(nmatch)
;matcherr_c=fltarr(nmatch)
;matchdif_c=fltarr(nmatch)
;matchwts_c=fltarr(nmatch)
;matchbest_c=dblarr(nmatch)
;goto,skipfit
; #########

;
; do the fit using mpfit, not amoeba
;vals=mpfit('thar_mpfit',p0,parinfo=parinfo_c,/quiet)
;##########
;p0=p0(0:6)
;parinfo_c=parinfo_c(0:6)
;;vals=mpfit('thar_mpfit2',p0,parinfo=parinfo_c,ftol=1.d-6,/quiet)
;      ftol=5.d-6)
;fomall=dblarr(201)
;dpaa=.01*(findgen(201)-100.)*1.e-5
;for j=0,200 do begin
;  tvals=thar_mpfit([dpaa(j),0.,0.,0.])
;  fomall(j)=total((clip_c*tvals)^2)
;endfor
; do the fit using thar_lsqfit. Iterate niter_thar times.
; save interesting values for each iteration
niter_thar=4
ii_parms=dblarr(7,niter_thar+1)
ii_coefs=dblarr(15,niter_thar+1)
ii_lam=dblarr(4096,67,niter_thar+1)

ii_parms(*,0)=[sinalp_c,fl_c,y0_c,z0_c,ex0_c,ex1_c,ex2_c]
ii_coefs(*,0)=coefs_c
ii_lam(*,*,0)=lam_c

for j=0,niter_thar-1 do begin

print,'thar_iter_j =',j

thar_lsqfit,dvals,dcoefs,rchisq,mchisq,nmatch
nmatch_c=nmatch
rchisq_c=rchisq
mchisq_c=mchisq

; identify lines with unusually bad fits, set their weights to zero
;;
; this data clipping is now done within thar_lsqfit, hence is not needed here.
;sm=where(abs(diff_c) le 0.8*dw,nsm)
;if(nsm gt 10) then begin         ; 10 = min acceptable number of matched lines
;  normdif=diff_c/xperr_c
;  quartile,normdif(sm),med,q,dq
;  sigq=dq/1.349                ; gaussian sigma estim from interquartile range
;  sf=where(abs(diff_c) le 0.8*dw and abs(normdif) gt 4.*sigq,nsf)  ; points 

;  if(nsf gt 0) then begin       ; redo mpfit with weights
;    clip_c(sf)=0.d0
;    niter_c=0             ; reset so matched line list will be recomputed
;   vals=mpfit('thar_mpfit',p0,parinfo=parinfo_c,/quiet)
;;    vals=mpfit('thar_mpfit2',p0,parinfo=parinfo_c,ftol=1.d-6,/quiet)
;  thar_lsqfit,dvals,dcoefs,rchisq,mchisq,nmatch
;  endif
;endif

; ##############
;skipfit:
; ##############

logo_nres2,rutname,'INFO',{state:'after mpfit',nmatch:nmatch_c,$
     scatter:sqrt(dlam2_c)}
print,dvals(0)
stop

; update the model parameters in common
sinalp_c=sinalp_c-dvals(0)
grinc_c=radian*asin(sinalp_c)
fl_c=fl_c-dvals(1)
y0_c=y0_c-dvals(2)
z0_c=z0_c-dvals(3)
ex0_c=ex0_c-dvals(4)
ex1_c=ex1_c-dvals(5)
ex2_c=ex2_c-dvals(6)
; and update the coefs_c values
coefs_c=coefs_c-dcoefs

ii_parms(*,j+1+1)=[sinalp_c,fl_c,y0_c,z0_c,ex0_c,ex1_c,ex2_c]
ii_coefs(*,j+1)=coefs_c
ii_lam(*,*,0)=lam_c

endfor

stop

; do weighted least-squares solution to restricted cubic functions of order
; to minimize residuals.  Skip this if nmatch_c is too small
;if(nmatch_c ge minmatch) then begin
;  thar_rcubic,cubfrz=cubfrz
;  logo_nres2,rutname,'INFO',{state:'after rcubic',nmatch:nmatch_c,$
;     scatter:sqrt(dlam2_c)}
;endif else begin
;  rms_c=0.
;  lammid_c=0.
;  mgbdisp_c=0.
;endelse

; no explicit output from this routine -- everything of interest lives
; in the common block thar_am

fini:

end
