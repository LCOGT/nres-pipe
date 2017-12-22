pro cc16,flist,ccout,ccamp,ccwid,jd
; This routine accepts a list flist containing names of ThAr images, all
; assumed to be 4K x 4K.
; It breaks each image into 16 subimages measuring 1K x 1K, and cross-correlates
; each subimage with the corresponding subimage from the 1st image in the list.
; It estimates the positions of the resulting cross-correlation peaks, and
; stores these x,y positions in output array ccout(4,4,nt,2)
; also amplitudes and widths (in pix) go in ampout(4,4,nt) and widout(4,4,nt)
; and JD - min(long(JD)) = jd(nt)

; count entries in flist
ss=''
openr,iun,flist,/get_lun
nt=0
while(not eof(iun)) do begin
  readf,iun,ss
  nt=nt+1
endwhile
point_lun,iun,0

; set up output arrays
ccout=fltarr(4,4,nt,2)
ccamp=fltarr(4,4,nt,2)
ccwid=fltarr(4,4,nt,2)
jd=dblarr(nt)

; make apodization array
yy=fltarr(1024)+1.
xx=findgen(1024)
xx0=findgen(103)              ; 10% cosine bell apodization
yy0=0.5*(1.-cos(!pi*xx0/102.))
yy(0:102)=yy0
yy(1023-102:*)=rotate(yy0,2)
yyx=rebin(yy,1024,1024)
yyy=rebin(reform(yy,1,1024),1024,1024)
apod=yyx*yyy

; make transforms of 1st image subimages
readf,iun,ss
fname=strtrim(ss,2)
dd0=readfits(fname,hdr,/silent)
jd0=long(sxpar(hdr,'MJD-OBS')-0.5)
zz=make_array(1024,1024,4,4,/complex)
; loop over x,y subimages
for i=0,3 do begin
  for j=0,3 do begin
    img=dd0(1024*i:1024*(i+1)-1,1024*j:1024*(j+1)-1)
    ff0=fft(img*apod,-1)
    zz(*,*,i,j)=conj(ff0)
  endfor
endfor

; loop over images
point_lun,iun,0
for it=0,nt-1 do begin

; read image
  readf,iun,ss
  gname=strtrim(ss,2)
  dd=readfits(gname,ghdr,/silent)
  jd(it)=sxpar(ghdr,'MJD-OBS')-jd0

  print,'image = ',gname

; loop over 4 x 4 1Kx1K subimages
  for i=0,3 do begin
    for j=0,3 do begin

; extract subimage, apodize, make cross-correlation
      img=dd(1024*i:1024*(i+1)-1,1024*j:1024*(j+1)-1)
      ff=fft(img*apod,-1)
      cc=float(fft(ff*zz(*,*,i,j),1))

; shift zero lag, for convenience
      cc=shift(cc,512,512)
      ccsub=cc(512-20:512+20,512-20:512+20)         ; 41x41 subarray containing max

; locate maximum cc, estimate width, amplitude in ADU^2
      ccax=rebin(ccsub,41)*41.
      ccay=reform(rebin(ccsub,1,41))*41.
      ccmx=max(ccax,ixx)               ; max of ccsub summed over y
      ccmy=max(ccay,ixy)               ; max of ccsub summed over x
      sx=(ccax(ixx-1)-ccax(ixx+1))/(ccax(ixx+1)+ccax(ixx-1)-2.*ccax(ixx))/2.
      sy=(ccay(ixy-1)-ccay(ixy+1))/(ccay(ixy+1)+ccay(ixx-1)-2.*ccay(ixy))/2.

; save results in output arrays
      ccout(i,j,it,0)=ixx+sx-20.
      ccout(i,j,it,1)=ixy+sy-20.
      ccamp(i,j,it,0)=ccmx
      ccamp(i,j,it,1)=ccmy
      ccwid(i,j,it,0)=sqrt(-ccax(ixx)/(ccax(ixx+1)+ccax(ixx-1)-2.*ccax(ixx)))
      ccwid(i,j,it,1)=sqrt(-ccay(ixy)/(ccay(ixy+1)+ccay(ixx-1)-2.*ccay(ixy)))

; end x,y loops
    endfor
  endfor

; end time loop
endfor
close,iun
free_lun,iun

end
