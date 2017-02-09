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

common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun

; constants
radian=180.d0/!pi
nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
outpath=nresrooti+'reduced/thar/'
dw=0.1         ; (nm) unmatched lines get their difference against model set to
               ; this value.
ierr=0

; get SG parameters, set up massaged input in common block
thar_setup,sgsite,fibindx,ierr,trp=trp,tharlist=tharlist
if(ierr_c ne 0) then stop
if(ierr_c ne 0) then goto,fini
site_c=sgsite
fibindx_c=fibindx
print,'In thar_fitall, fibindx=',fibindx

if(keyword_set(oskip)) then oskip_c=oskip-1 else oskip_c=[-1]

; run amoeba search to find optimum values of a0,f0,g0,z0
p0=[5.d-8,0.d0,0.d0,0.d0]      ; [sin(alp), fl (mm), y0 (mm), z0]
scale=0.3*[dsinalp_c,dfl_c,dy0_c,dz0_c]
ftol=1.d-4
ncalls=0L
nmax=500
function_val=double([0.,0.,0.,0.])
niter_c=0

; debugging data
inmatch=lonarr(nmax)
isalp=dblarr(nmax)
ifl=dblarr(nmax)
iy0=dblarr(nmax)
iz0=dblarr(nmax)
ifun=dblarr(nmax)
if(ierr_c ne 0) then stop

; trying mpfit now ######################
; vals=amoeba(ftol,function_name='thar_amoeba',ncalls=ncalls,nmax=nmax,$
;             function_val=function_val,p0=p0,scale=scale)
; ierr=ierr+ierr_c
; if(ierr_c ne 0) then stop
; if(ierr_c ne 0) then goto,fini
; print,'ncalls = ',ncalls

;
; do the fit using mpfit, not amoeba
vals=mpfit('thar_mpfit',p0,parinfo=parinfo_c)

;fomall=dblarr(201)
;dpaa=.01*(findgen(201)-100.)*1.e-5
;for j=0,200 do begin
;  tvals=thar_mpfit([dpaa(j),0.,0.,0.])
;  fomall(j)=total((clip_c*tvals)^2)
;endfor

;stop

; identify lines with unusually bad fits, set their weights to zero
sm=where(abs(diff_c) le 0.8*dw,nsm)
if(nsm gt 10) then begin         ; 10 = min acceptable number of matched lines
  normdif=diff_c/xperr_c
  quartile,normdif(sm),med,q,dq
  sigq=dq/1.349                ; gaussian sigma estim from interquartile range
  sf=where(abs(diff_c) le 0.8*dw and abs(normdif) gt 4.*sigq,nsf)  ; points 
                                                      ; with large dispersion
  if(nsf gt 0) then begin       ; redo mpfit with weights
    clip_c(sf)=0.d0
    vals=mpfit('thar_mpfit',p0,parinfo=parinfo_c)
  endif
endif

; update the model parameters in common
sinalp_c=sinalp_c+vals(0)
grinc_c=radian*asin(sinalp_c)
fl_c=fl_c+vals(1)
y0_c=y0_c+vals(2)
z0_c=z0_c+vals(3)

; do weighted least-squares solution to restricted cubic functions of order
; to minimize residuals.
thar_rcubic,cubfrz=cubfrz

; no explicit output from this routine -- everything of interest lives
; in the common block thar_am

fini:

end
