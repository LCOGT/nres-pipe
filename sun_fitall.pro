pro sun_fitall,sgsite,nn,fibindx,suf,ierr,speccsv=speccsv
; This is the main routine to fit wavelength solutions to solar spectra.
; On input, sgsite = one of {'SQA','ELP','TEN','ALI','LSC','CPT','BPL'},
; encoding the identity of the spectrograph. 
;      nn = string (eg '1') pointing to input filename which is constructed as
;       sgsite+'sun_lamvac_pix'+nn+'.txt'
;      fibindx = fiber index {0,1,2} to be processed.
;      suf = output filename suffix, to be appended to name constructed from
;            site, fiber, date, time.
; On output, ierr = 0 is normal; anything else is a fatal error.

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
nresroot=getenv('NRESROOT')
radian=180.d0/!pi
outpath=nresroot+'reduced/config/'
ierr=0

; get SG parameters, set up massaged input in common block
sun_setup,sgsite,fibindx,nn
ierr=ierr_c
if(ierr_c ne 0) then goto,fini
site_c=sgsite
fibindx_c=fibindx

; run amoeba search to find optimum values of a0,f0,g0,z0
p0=[0.d0,0.d0,0.d0,0.d0]      ; [sin(alp), fl (mm), y0 (mm), z0]
scale=[dsinalp_c,dfl_c,dy0_c,dz0_c]
ftol=1.d-5
ncalls=0L
function_val=double([0.,0.,0.,0.])

vals=amoeba(ftol,function_name='sun_amoeba',ncalls=ncalls,$
            function_val=function_val,p0=p0,scale=scale)
ierr=ierr+ierr_c
if(ierr_c ne 0) then goto,fini

; update the model parameters in common
sinalp_c=sinalp_c+vals(0)
fl_c=fl_c+vals(1)
y0_c=y0_c+vals(2)
z0_c=z0_c+vals(3)

; do weighted least-squares solution to restricted cubic functions of order
; to minimize residuals.
sun_rcubic

modl=10.*lam_c(matchxpos_c,matchord_c)
matchdif_c=modl-linelam_c
plot,linelam_c,matchdif_c,psym=-1,charsiz=1.5,xtit='lambda (AA)',$
       ytit='dif (AA)'
resid=matchdif_c/10.         ; line wavelength match residuals (nm)
rmserr=stddev(resid)
print,'final rmserr =',rmserr,'(nm)'

; make output filename
filout=outpath+strtrim(sgsite,2)+strtrim(string(fibindx),2)
stime=systime(/julian)
sdat=date_conv(stime,'F')       ; makes datestring in sensible form
sdate=strmid(sdat,0,4)+strmid(sdat,5,2)+strmid(sdat,8,2)+'-'+strmid(sdat,11,2)+$
      strmid(sdat,14,2)+strmid(sdat,17,2)
print,sdate
filout=filout+'_'+sdate+'_'+suf+'.idl'
mjd=stime-2400000.5d0

grinc=asin(sinalp_c)*180.d0/!pi
dgrinc=dsinalp_c/sqrt(1.-sinalp_c^2)

sunstruc={mjd:mjd,mm:mm_c,grspc:d_c,grinc:grinc,sinalp:sinalp_c,fl:fl_c,$
    y0:y0_c,z0:z0_c,gltype:gltype_c,priswedge:priswedge_c,lamcen:lamcen_c,$
    r0:r0_c,pixsiz:pixsiz_c,$
    nx:nx_c,nord:nord_c,nfib:nfib_c,nblock:nblock_c,npoly:npoly_c,$
    ordwid:ordwid_c,medboxsz:medboxsz_c,$
    dsinalp:dsinalp_c,dgrinc:dgrinc,dfl:dfl_c,dy0:dy0_c,dz0:dz0_c,$
    dlam2:dlam2_c,$
    lam:lam_c,y0m:y0m_c,coefs:coefs_c,ncoefs:ncoefs_c,resid:resid,$
    rmserr:rmserr,site:site_c,fibindx:fibindx_c}

save,sunstruc,file=filout

; if speccsv keyword is set, write a new entry to the spectrographs.csv file.
if(keyword_set(speccsv)) then sunspeccsv_write,sunstruc

fini:
stop

end
