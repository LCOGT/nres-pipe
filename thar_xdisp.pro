pro thar_xdisp,xp0,io0,ll0,er0,xp1,io1,ll1,er1,fibc,rms
; This routine estimates the fibcoef polynomial coefficients describing
; the x-displacements in pix between ThAr spectra from two distinct fibers.
; On input,
; xp0,io0,ll0,er0 contain (respectively) the x-positions, order indices, 
;   wavelengths (nm), and expected positional error of all of the matched 
;   ThAr lines from one of the pair of fibers processed by the routine.
; xp1,io1,ll1,er1 contain the same information for matched ThAr lines for the
;   other fiber.
; All of the above data result from running thar_fitall on their respective
;   spectra.
; The routine seeks matching pairs of lines in the two lists, where matches
; require having the same order index, and close proximity in wavelength.
; It then does a robust minimum-chi^2 fit of the displacements xp0-xp1 to
; the standard fibcoef polynomial in x posn and order index.  Data are weighted
; inversely as the square of the expected positional error, with outlier
; rejection.

@thar_comm     ;load thar common block

; constants
lamthrsh=0.005   ; max wavelength difference for a match (nm)
thrsig=5.         ; outliers at least this many sigma from mean

; identify and list matching lines
dx=[0.]
jx=[0.d0]
jord=[0L]
lam=[0.d0]
err=[0.]
nl0=n_elements(xp0)
nl1=n_elements(xp1)

for i=0L,nord_c-1 do begin
  s0=where(io0 eq i,ns0)
  s1=where(io1 eq i,ns1)
  if(ns0 gt 0) then begin
    for j=0,ns0-1 do begin
      md=min(abs(ll1(s1)-ll0(s0(j))),ix)
      if(md le lamthrsh) then begin
        dx=[dx,xp1(s1(ix))-xp0(s0(j))] 
        jx=[jx,xp1(s1(ix))]
        jord=[jord,i]
        err=[err,sqrt(er1(s1(ix))^2+er0(s0(j))^2)]
      endif
    endfor
  endif
endfor

dx=dx(1:*)

; check to be sure lst sq fit will not fail for lack of data
ndx=n_elements(dx)
if(ndx le 10) then stop

jx=jx(1:*)-nx_c/2.              ; convert x1, jord to centered coordinates
jord=jord(1:*)-nord_c/2.
err=err(1:*)
nl=n_elements(dx)

; fit polynomial coefficients.  First create fitting functions
nfun=10
funs=fltarr(nl,nfun)
funs(*,0)=fltarr(nl)+1.
funs(*,1)=jord
funs(*,2)=jx
funs(*,3)=jx*jord
funs(*,4)=jord^2
funs(*,5)=jx*jord^2
funs(*,6)=jx^2
funs(*,7)=jord*jx^2
funs(*,8)=jx^3
funs(*,9)=jord^3

; make weights.  Max allowed weight corresp to 10th percentile of raw widths.
so=sort(err)
err10=err(so(nl/10))
err=(err > err10) 
wts=(err10/err)^2

; do the fit
cc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov)

; pitch outliers, do it again
quartile,outp,med,q,dq
thrq=dq*thrsig/1.35              ; more than thrsig sigma from zero
sb=where(abs(outp) ge thrq,nsb)
if(nsb gt 0) then wts(sb)=0.
fibc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov)

; and once more
quartile,outp,med,q,dq
thrq=dq*thrsig/1.35              ; more than thrsig sigma from zero
sb=where(abs(outp) ge thrq,nsb)
if(nsb gt 0) then wts(sb)=0.
fibc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov)

end
