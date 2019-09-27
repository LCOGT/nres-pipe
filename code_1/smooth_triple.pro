pro smooth_triple,site,mjd,fibcoesm,terr
; This routine identifies a list (obtained from the csv/fibcoefs.csv file)
; of TRIP fibcoef data that include the ntot files prior to and including the
; one corresponding to mjd, taken from the given site.
; It then averages the fibcoef values for these days and returns
; fibcoesm = a full set of smoothed fibcoexx values, obtained
;   as the result of a linear
;   (in time) fit to their values read from the previous 15 days, evaluated
;   at the time of the most recent day.
; terr = 0 on success, else 1 if any error occurs.

; constants
ntot=15
terr=0
clipthr=5.0      ; clip data points more than clipthr*dq/1.35 from median

; get a list of all fibcoef data for this site
fibcoefs_rd,sites,jdates,cameras,fibcoefs,fibhdr
s=where(sites eq site,ns)
if(ns gt 0) then begin
  jdates=jdates(s)
  fibcoefs=fibcoefs(*,s)
endif
nline=n_elements(jdates)
if(nline gt 0) then begin   ; make jd and fibcoef entries for desired dates
  jd=2400000.5d0+mjd
  md=min(abs(jdates-jd),ix)
  itop=ix
  ibot=(ix-ntot) > 0
  jdgood=jdates(ibot:itop)
  fibgood=fibcoefs(*,ibot:itop)
  npt=n_elements(jdgood)
endif else begin
  terr=1
  goto,fini
endelse

; set up for fit
sz=size(fibgood)
ndim=sz(0)
nc=sz(1)
mnjd=mean(jdgood)
tt=jdgood-mnjd
ttout=jd-mnjd
funs=dblarr(nc,2)
funs(0:npt-1,0)=dblarr(npt)+1.d0
funs(0:npt-1,1)=tt
fibcoesm=dblarr(nc)

; loop over the coefficients
for i=0,nc-1 do begin
  if(ndim eq 1) then dat=fibgood(i) else dat=reform(fibgood(i,*))
  wts=dblarr(npt)+1.d0

; clip bad points
  if(npt gt 4) then begin
    quartile,dat,med,q,dq
    sb=where(abs(dat-med) gt clipthr*dq/1.35,nsb)
    if(nsb gt 0) then wts(sb)=0.
    sg=where(wts gt 0.,nsg)
  endif
  if(npt le 4) then sg=where(wts gt 0.,nsg)

; do various cases of number of good data points
  if(nsg eq 0) then begin
    fibcoesm(i)=0.  
    goto,loop
  endif
  if(nsg eq 1) then begin
    fibcoesm(i)=dat(sg)
    goto,loop
  endif
  if(nsg le 4) then begin
    fibcoesm(i)=mean(dat(sg))
    goto,loop
  endif
  if(npt lt nc) then funstrun=funs(0:npt-1,*) else funstrun=funs
  cc=lstsqr(dat,funstrun,wts,2,rms,chisq,outp,1,cov,ierr)
  fibcoesm(i)=cc(0)+cc(1)*ttout
  loop:
endfor

fini:
end
