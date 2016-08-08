function lstsqr,dat,funs,wt,nfun,rms,chisq,outp,type,cov
; This routine does a weighted linear least-squares fit of the nfun functions
; contained in array funs to the data in array dat.  The weights are given
; in array wt.  Fit coefficients are returned.  If arguments outp and type
; are given, then on return outp contains:
;  type = 0 => the fitted function
;  type = 1 => residuals around fit,in the sense (data - fit)
;  type = 2 => ratio (data/fit)
; if outp is an argument but type is not given, type defaults to 0.
; on return, chisq contains the average of err^2*wt^2, so that wt is implicitly
; taken to be the reciprocal of the expected sigma at each data point.
; Also returns cov, the inverse of the normal equation matrix.  If wt=1/sigma,
; where sigma is the uncertainty of each data point, then cov is the square
; of the covariance matrix of the coefficients.
; The technique used is to construct and solve the normal equations.
; Note that this technique will give garbage for ill-conditioned systems.

; get dimensions of things, make extended arrays for generating normal eqn
; matrix
  npr=n_params()
  s=size(dat)
  if (s(0) ne 1) then begin
    print,'bad dimension in lstsqr data'
    return,0.
    end
  nx=s(1)
  wte=rebin(wt,nx,nfun)
  datw=reform(dat,nx,1)
  datw=rebin(datw,nx,nfun)*wte
  funw=funs*wte

; make normal eqn matrix, rhs
  a=fltarr(nfun,nfun)
  rhs=rebin(funw*datw,1,nfun)
  rhs=reform(rhs,nfun)
  for i=0,nfun-1 do begin
    for j=0,nfun-1 do begin
      if(i ge j) then begin
        prod=rebin(funw(*,i)*funw(*,j),1)
        a(i,j)=prod
        a(j,i)=prod
        end
      end
    end

; make cov matrix for output
; print,'a = '
; print,a
  cov=invert(a*nx,/double)
; print,'cov='
; print,cov

; solve equations by lu decomposition
  ludcmp,a,index,d
  lubksb,a,index,rhs

; Make fit function, rms
  outpt=reform(rhs,1,nfun)
  outpt=rebin(outpt,nx,nfun)*funs
  outpt=rebin(outpt,nx)*nfun
  dif=dat-outpt
  s=where(wt gt 0)
  wt2=wt^2
  dif2=dif^2
  rmst=sqrt(total(dif2(s))/n_elements(s))
  ndegfree=n_elements(s)-nfun
  chisq=total(dif2(s)*wt(s))/ndegfree

; if rms is defined, set its value
  if (npr ge 5) then rms=rmst
  if (npr le 5) then return,rhs

; make final outp,depending on type
  if (npr lt 8) then typ = 0 else typ = type
  if (typ eq 0) then begin
    outp=outpt
    return,rhs
    end
  if (typ eq 1) then begin
    outp=dif
    return,rhs
    end
  if(typ eq 2) then begin
    outp=dat/outpt
    return,rhs
    end

stop

  end
