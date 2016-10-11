pro extlstsq,sprofile,dfpdy,d2fpdy2,ebox,vbox,ewts,datparms,exintn,exsig,$
    exdy,excon,exdy2
; This routine performs the weighted least-squares fit to estimate total
; counts across the order profiles, and shift of the profiles relative to
; the extraction box centers.  On input
;  sprofile(nx,cowid,nord,mfib) = model profile, incorporating best knowledge 
;     of shape, width, and centering within the extraction box.
;  dfpdy(nx,cowid,nord,mfib) = derivative of sprofile across the order,
;     normalized by total flux under sprofile.
;  ebox(nx,cowid,nord,mfib) = observed intensities in extraction boxes
;  vbox(nx,cowid,nord,mfib) = model variance map of data in ebox
;  ewts(nx,cowid,nord,mfib) = relative weights applied to pixels in ebox
;  datparms = structure containing values of nx, nord, nfib, mfib, cowid, remain
; On output
;  exintn(nx,nord,mfib) = estimated integrated counts across orders
;  exsig(nx,nord,mfib) = formal rms of values in exintn
;  exdy(nx,nord,mfib) = across-order displacement in pix of actual profile 
;    relative to expected position.
;  excon(nx,nord,mfib) = constant background added to profile

; unpack datparms
nx=datparms.nx
nord=datparms.nord
nfib=datparms.nfib
mfib=datparms.mfib
cowid=datparms.cowid
remain=datparms.remain

; make unity array
unity=fltarr(nx,cowid,nord,mfib)+1.

; estimate intensity vs x via optimal weighted fit to shifted profiles
; function to be fit is  d0 + d1*sprofile + d2*dfpdy.
; first expand the profile arrays to full width of nx, by linear interpolation
;fprofile=rebin(rprofile,nx+remain,cowid,nord,mfib)
;fprofile=fprofile(0:nx-1,*,*,*)
fprofile=sprofile

; renormalize profiles so that total(profile(y)^2) is constant for all x
; This is necessary because the profile interpolation process results in
; profiles of slightly different width, depending on what fraction of a
; a pixel they are shifted by. This in turn leads to variable response to
; the same optical profile, as a function of distance from profile center
; to pixel center coord.
;
fprof2=cowid*rebin(fprofile^2,nx,1,nord,mfib)
fprof2=rebin(fprof2,nx,cowid,nord,mfib)
mpro2=fltarr(nord,mfib)
for i=0,nord-1 do begin
  for j=0,mfib-1 do begin
    mpro2(i,j)=median(fprof2(*,0,i,j))
    fprofile(*,*,i,j)=fprofile(*,*,i,j)*mpro2(i,j)/fprof2(*,*,i,j)
  endfor
endfor

;dfpdy=rebin(dfpdy,nx,cowid,nord,mfib)
;dfpdy=dfpdy(0:nx-1,*,*,*)
; now make cross-dispersion sums of products for use in the fit
;acc=reform(cowid*rebin(unity^2*ewts,nx,1,nord,mfib))
;ac0=reform(cowid*rebin(unity*fprofile*ewts,nx,1,nord,mfib))
;a0c=ac0
;ac1=reform(cowid*rebin(unity*dfpdy*ewts,nx,1,nord,mfib))
;a1c=ac1
a00=reform(cowid*rebin(fprofile^2*ewts,nx,1,nord,mfib))
a01=reform(cowid*rebin(fprofile*dfpdy*ewts,nx,1,nord,mfib))
a10=a01
a11=reform(cowid*rebin(dfpdy^2*ewts,nx,1,nord,mfib))
;yc=reform(cowid*rebin(unity*ebox*ewts,nx,1,nord,mfib))
y0=reform(cowid*rebin(fprofile*ebox*ewts,nx,1,nord,mfib))
y1=reform(cowid*rebin(dfpdy*ebox*ewts,nx,1,nord,mfib))
; solve the linear equations by determinents, vector-wise
det=a00*a11-a01*a01
d1=y0*a11-a01*y1
d2=a00*y1-y0*a01
;det=acc*(a00*a11-a01*a10) - ac0*(a0c*a11-a01*a1c) + ac1*(a0c*a10-a00*a1c)
;dc=yc*(a00*a11-a10*a01) - y0*(a0c*a11-a1c*a01) + y1*(a0c*a10-a1c*a00)
;d0=acc*(y0*a11-a10*y1) - ac0*(yc*a11-a1c*y1) + ac1*(yc*a10-a1c*y0)
;d1=acc*(a00*y1-y0*a01) - ac0*(a0c*y1-yc*a01) + ac1*(a0c*y0-yc*a00)

; make output arrays, and nominal displacement of order from box center
s=where(det ne 0.,ns)
excon=fltarr(nx,nord,mfib)
;excon(s)=dc(s)/det(s)
exintn=fltarr(nx,nord,mfib)
exintn(s)=d1(s)/det(s)
exsig=fltarr(nx,nord,mfib)
exdy=fltarr(nx,nord,mfib)
exdy(s)=d2(s)/det(s)
s1=where(exintn ne 0.)
exdy(s1)=exdy(s1)/exintn(s1)             ; puts exdy in pixel units
svbox=cowid*reform(rebin(vbox,nx,1,nord,mfib),nx,nord,mfib)
exsig(s)=sqrt(svbox(s))

stop

end
