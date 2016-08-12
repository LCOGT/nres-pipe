function fit1d,dat,maxord,type,wt
; This routine fits each line (row) of the input array dat with all the Legendre
; polynomials from order 0 up to maxord.  If parameter wt is defined, it is
; taken to be a weighting function such that the quantity being minimized is
; sum (delta^2*wt^2).  In ordinary circumstances, wt would correspond to
; 1/sigma, where sigma is the expected rms of the corresponding data point.
; If absent, wt defaults to a vector with unit components.
; The data array returned has the same dimensionality as dat, with each line
; containing values that depend on the parameter 'type':
;  type = 0 => the fitted function
;  type = 1 => residuals (dat - fit)
;  type = 2 => ratio (dat/fit)
; If absent, type defaults to 0.
; If maxord is absent, it defaults to 4.
; If wt is present, it may be 1-dimensional with dimension equal to the first
; dimension of dat, or it may be 2-dimensional, with dimensions identical to
; dat.  Otherwise, and error will occur.
; Array dat may be 1- or 2-dimensional.

; check dimensions
  npr=n_params()
  s=size(dat)
  if(s(0) eq 1) then begin
    nx=s(1)
    nrow=1
    ndim=1
    end
  if(s(0) eq 2) then begin
    nx=s(1)
    nrow=s(2)
    ndim=2
    end
  if(s(0) gt 2 or s(0) le 0) then begin
    print,'dimension error in fit1d'
    return,0.
    end
  if(npr eq 4) then begin
    sw=size(wt)
    if(sw(0) ne s(0) or sw(1) ne s(1) or sw(2) ne s(2)) then begin
    if(sw(0) gt s(0) or sw(1) ne nx) then begin
      print,'weight dimension error in fit1d'
      return,0.
      end
    end
    end

; get type, max order, weights
  if(npr ge 2) then mord=maxord else mord=4
  if(npr ge 3) then typ=type else typ=0
  if(npr ge 4) then wgts=wt else wgts=fltarr(nx)+1.
  sw=size(wgts)

; do the work
  leg=legendre(0,mord,nx)
  if(ndim eq 1) then begin
    c=lstsqr(dat,leg,wgts,mord+1,rms,fit,typ)
    return,fit
    end
  if(ndim eq 2) then begin
    fit=fltarr(nx,nrow)
    for i=0,nrow-1 do begin
      dd=dat(*,i)
      if(sw(0) eq 1) then wgt=wgts else wgt=wgts(*,i)
      c=lstsqr(dd,leg,wgt,mord+1,rms,ft,typ)
      fit(*,i)=ft
      end
    return,fit
    end

  end

