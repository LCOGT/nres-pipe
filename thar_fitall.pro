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

niter_thar=2
ii_parms=dblarr(7,niter_thar+2)
ii_coefs=dblarr(15,niter_thar+2)
ii_lam=dblarr(4096,67,niter_thar+1)

ii_parms(*,0)=[sinalp_c,fl_c,y0_c,z0_c,ex0_c,ex1_c,ex2_c]
ii_coefs(*,0)=coefs_c
ii_lam(*,*,0)=lam_c

for j=0,niter_thar-1 do begin

thar_lsqfit,dvals,dcoefs,rchisq,mchisq
;nmatch_c=nmatch
rchisq_c=rchisq
mchisq_c=mchisq

logo_nres2,rutname,'INFO',{state:'after mpfit',nmatch:nmatch_c,$
     scatter:sqrt(dlam2_c)}
;print,dvals(0)

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

;stop

endfor

; fill in some diagnostic values
mgbord=38               ; order containing Mg b lines
dlamnom=10.5777         ; nominal wavelength span of mgbord, in nm
mgbdisp_c=lam_c(nx_c-1,mgbord)-lam_c(0,mgbord)-dlamnom
lammid_c=total(lam_c(2000,mgbord-5:mgbord+5))/11.
matchbest_c=matchlam_c - (matchdif_c-outp_c)

; no explicit output from this routine -- everything of interest lives
; in the common block thar_am

fini:

end
