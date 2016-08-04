pro extlstsq,sprofile,dfpdy,ebox,vbox,ewts,datparms,exintn,exsig,exdy
; This routine performs the weighted least-squares fit to estimate total
; counts across the order profiles, and shift of the profiles relative to
; the extraction box centers.  On input
;  rprofile(nx,cowid,nord,mfib) = model profile, incorporating best knowledge 
;     of shape, width, and centering within the extraction box.
;  dfpdy(nx,cowid,nord,mfib) = derivative of rprofile across the order,
;     normalized by total flux under rprofile.
;  ebox(nx,cowid,nord,mfib) = observed intensities in extraction boxes
;  vbox(nx,cowid,nord,mfib) = model variance map of data in ebox
;  ewts(nx,cowid,nord,mfib) = relative weights applied to pixels in ebox
;  datparms = structure containing values of nx, nord, nfib, mfib, cowid, remain
; On output
;  exintn(nx,nord,mfib) = estimated integrated counts across orders
;  exsig(nx,nord,mfib) = formal rms of values in exintn
;  exdy(nx,nord,mfib) = across-order displacement in pix of actual profile 
;    relative to expected position.

; unpack datparms
nx=datparms.nx
nord=datparms.nord
nfib=datparms.nfib
mfib=datparms.mfib
cowid=datparms.cowid
remain=datparms.remain

; estimate intensity vs x via optimal weighted fit to shifted profiles
; first expand the profile arrays to full width of nx, by linear interpolation
;fprofile=rebin(rprofile,nx+remain,cowid,nord,mfib)
;fprofile=fprofile(0:nx-1,*,*,*)
fprofile=sprofile
;dfpdy=rebin(dfpdy,nx,cowid,nord,mfib)
;dfpdy=dfpdy(0:nx-1,*,*,*)
; now make cross-dispersion sums of products for use in the fit
a00=reform(cowid*rebin(fprofile^2*ewts,nx,1,nord,mfib))
a01=reform(cowid*rebin(fprofile*dfpdy*ewts,nx,1,nord,mfib))
a10=a01
a11=reform(cowid*rebin(dfpdy^2*ewts,nx,1,nord,mfib))
y0=reform(cowid*rebin(fprofile*ebox*ewts,nx,1,nord,mfib))
y1=reform(cowid*rebin(dfpdy*ebox*ewts,nx,1,nord,mfib))
; solve the linear equations by determinents, vector-wise
det=a00*a11-a01*a01
d1=y0*a11-a01*y1
d2=a00*y1-y0*a01

; make output arrays, and nominal displacement of order from box center
s=where(det ne 0.,ns)
exintn=fltarr(nx,nord,mfib)
exintn(s)=d1(s)/det(s)
exsig=fltarr(nx,nord,mfib)
exdy=fltarr(nx,nord,mfib)
exdy(s)=d2(s)/det(s)
s1=where(exintn ne 0.)
exdy(s1)=exdy(s1)/exintn(s1)             ; puts exdy in pixel units
svbox=cowid*reform(rebin(vbox,nx,1,nord,mfib),nx,nord,mfib)
exsig(s)=sqrt(svbox(s))

end
