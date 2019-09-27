pro thar_fitall_1,filin,fibindx,ierr,tharlist=tharlist,$
oskip=oskip,trp=trp
; This is the main Stage-2 routine to fit wavelength solutions to ThAr spectra.
; On input, filin=the name of a Stage-1 (muncha) output file
;      fibindx = fiber index {0,1,2} to be processed.
; On output, ierr = 0 is normal; anything else is a fatal error.
; If keyword cubfrz is set, then the 15 rcubic coefficients are frozen
; (taken as given in the spectrographs.csv entry).
; If keyword oskip is set and not zero, then order oskip-1 is skipped in the
; wavelength solution.  Used in search for bad lines.

; common blocks

@thar_comm_1

common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun,ie0,ie1,ie2

; constants
rutname='thar_fitall_1'
radian=180.d0/!pi
nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
outpath=nresrooti+'reduced/thar/'
dw=0.1         ; (nm) unmatched lines get their difference against model set to
               ; this value.
minmatch=20    ; must match at least this many lines to do lstsqr fit
ierr=0

; get SG parameters, set up massaged input in common block
thar_setup_1,filin,fibindx,ierr,dbg=dbg,tharlist=tharlist,trp=trp
if(ierr_c ne 0) then begin
  logo_nres2,rutname,'ERROR','FATAL ierr='+string(ierr)+' from thar_setup'
  goto,fini
endif
fibindx_c=fibindx

if(keyword_set(oskip)) then oskip_c=oskip-1 else oskip_c=[-1]

; construct dofit array from dofitstr string in thar_comm_1
dofit=fix(byte(dofitstr)-48)

niter_c=0

; debugging data
nmax=50
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

; save interesting values for each iteration
niter_thar=9
ii_parms=dblarr(7,niter_thar+1)
ii_coefs=dblarr(15,niter_thar+1)
ii_lam=dblarr(4096,67,niter_thar+1)

ii_parms(*,0)=[sinalp_c,fl_c,y0_c,z0_c,ex0_c,ex1_c,ex2_c]
ii_coefs(*,0)=coefs_c
ii_lam(*,*,0)=lam_c

for j=0,niter_thar-1 do begin

print,'thar_iter_j =',j

if((j mod 4) eq 0) then recomp=1 else recomp=0

thar_lsqfit_1,dvals,dcoefs,rchisq,mchisq,nmatch,dofit=dofit,$
    recomp=recomp
nmatch_c=nmatch
rchisq_c=rchisq
mchisq_c=mchisq

logo_nres2,rutname,'INFO',{state:'after mpfit',nmatch:nmatch_c,$
     scatter:sqrt(dlam2_c)}
print,dvals(0)
;stop

; update the model parameters in common
sinalp_c=sinalp_c-dvals(0)
grinc_c=radian*asin(sinalp_c)
fl_c=fl_c-0.5*dvals(1)
y0_c=y0_c-0.5*dvals(2)
z0_c=z0_c-0.5*dvals(3)
ex0_c=ex0_c-0.5*dvals(4)
ex1_c=ex1_c-0.5*dvals(5)
ex2_c=ex2_c-0.5*dvals(6)
; and update the coefs_c values
coefs_c=coefs_c-0.5*dcoefs

ii_parms(*,j+1)=[sinalp_c,fl_c,y0_c,z0_c,ex0_c,ex1_c,ex2_c]
ii_coefs(*,j+1)=coefs_c
ii_lam(*,*,j+1)=lam_c
inmatch(j)=nmatch_c
isalp(j)=sinalp_c
ifl(j)=fl_c
iy0(j)=y0_c
iz0(j)=z0_c
ie0(j)=ex0_c
ie1(j)=ex1_c
ie2(j)=ex2_c

endfor               ; end of iterative fitting loop

; no explicit output from this routine -- everything of interest lives
; in the common block thar_am

fini:

end
