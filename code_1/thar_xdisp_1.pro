pro thar_xdisp_1,xp0,io0,ll0,er0,xp1,io1,ll1,er1,fibc,rms
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
; Modified from thar_xdisp to employ Legendre polynomials for the fitting
; functions, rather than simple polynomials.

@thar_comm_1     ;load thar common block

; constants
lamthrsh=0.005   ; max wavelength difference for a match (nm)
thrsig=5.         ; outliers at least this many sigma from mean
svm=1.e-5        ; minimum singular value ratio used in fit

; identify and list matching lines
dx=[]
jx=[]
jord=[]
lam=[]
err=[]
nl0=n_elements(xp0)
nl1=n_elements(xp1)

for i=0L,nord_c-1 do begin
  s0=where(io0 eq i,ns0)
  s1=where(io1 eq i,ns1)
  if(ns0 gt 0 and ns1 gt 0) then begin
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

; check to be sure lst sq fit will not fail for lack of data
ndx=n_elements(dx)
if(ndx le 10) then stop

jx=jx-nx_c/2.              ; convert x1, jord to centered coordinates
jord=jord-nord_c/2.
nl=n_elements(dx)

; fit polynomial coefficients.  First create fitting functions
nfun=10
funs=fltarr(nl,nfun)
;funs(*,0)=fltarr(nl)+1.
;funs(*,1)=jord
;funs(*,2)=jx
;funs(*,3)=jx*jord
;funs(*,4)=jord^2
;funs(*,5)=jx*jord^2
;funs(*,6)=jx^2
;funs(*,7)=jord*jx^2
;funs(*,8)=jx^3
;funs(*,9)=jord^3

lx=2.*jx/nx_c
lord=2.*jord/nord_c
lx0=mylegendre(lx,0)
lx1=mylegendre(lx,1)
lx2=mylegendre(lx,2)
lx3=mylegendre(lx,3)
lo0=mylegendre(lord,0)
lo1=mylegendre(lord,1)
lo2=mylegendre(lord,2)
lo3=mylegendre(lord,3)

funs(*,0)=lx0
funs(*,1)=lo1
funs(*,2)=lx1
funs(*,3)=lx1*lo1
funs(*,4)=lo2
funs(*,5)=lx1*lo2
funs(*,6)=lx2
funs(*,7)=lx2*lo1
funs(*,8)=lx3
funs(*,9)=lo3

; make weights.  Max allowed weight corresp to 10th percentile of raw widths.
so=sort(err)
err10=err(so(nl/10))
err=(err > err10) 
wts=(err10/err)^2

; do the fit
cc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov,svdminrat=svm)

; pitch outliers, do it again
quartile,outp,med,q,dq
thrq=dq*thrsig/1.35              ; more than thrsig sigma from zero
sb=where(abs(outp) ge thrq,nsb)
if(nsb gt 0) then wts(sb)=0.
fibc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov,svdminrat=svm)

; and once more
quartile,outp,med,q,dq
thrq=dq*thrsig/1.35              ; more than thrsig sigma from zero
sb=where(abs(outp) ge thrq,nsb)
if(nsb gt 0) then wts(sb)=0.
fibc=lstsqr(dx,funs,wts,nfun,rms,chisq,outp,1,cov,svdminrat=svm)

end
