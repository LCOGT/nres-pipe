pro expm_jpg_xy,flist,tt,xx,yy
; This routine reads each of a list flist of jpeg images of the exposure meter
; output ferrule (taken with the Orion webcam) and estimates the center position
; of the bright spot on the central output fiber.  It returns x,y positions
; and a JD, the latter derived from the input filename.

; constants
dir='/scratch/rsiverd/write_here/Images/'
;x0=260.
;y0=211.
;xwid=35           ; centroid over window with this halfwidth

; read flist, count files
ss=''
openr,iun,flist,/get_lun
nt=0
fnames=['']
while(not eof(iun)) do begin
  readf,iun,ss
  fnames=[fnames,strtrim(ss,2)]
  nt=nt+1
endwhile
fnames=fnames(1:*)
close,iun
free_lun,iun

; make output arrays
tt=dblarr(nt)
xx=fltarr(nt)
yy=fltarr(nt)

; make distances from x0,y0
;dd=findgen(2*xwid+1)-xwid

; loop over list of input files
for i=0,nt-1 do begin
  filin=strtrim(fnames(i),2)
; filrd=dir+filin
  filrd=filin
  read_jpeg,filrd,a
  a=float(reform(a(0,*,*)))
  sz=size(a)
  nx=sz(1)
  ny=sz(2)
  if(i eq 0) then begin
    astd=a
    astd=astd-mean(astd)
    ix=findgen(nx)-nx/2.
    ixx=rebin(ix,nx,ny)
    iy=findgen(ny)-ny/2.
    iyy=rebin(reform(iy,1,ny),nx,ny)
    ixxn=abs(ixx)*2./nx               ; normalized abs of x coord, in [0,1]
    iyyn=abs(iyy)*2./ny               ; ditto for y coord
    window=fltarr(nx,ny)+1.
    sx=where(ixxn gt 0.9)
    sy=where(iyyn gt 0.9)
    gx=10.*(ixxn(sx)-0.9)
    gy=10.*(iyyn(sy)-0.9)
    window(sx)=window(sx)*0.5*(1.+cos(!pi*gx))
    window(sy)=window(sy)*0.5*(1.+cos(!pi*gy))
    fastd=fft(astd*window,-1)
  endif

; compute cross-correlation with fourier transforms.
  aa=a-mean(a)
  fa=fft(aa*window,-1)
  fprod=fa*conj(fastd)
  cc=float(fft(fprod,1))
; shift to put zero in center of image
  cc=shift(cc,nx/2.,ny/2.)

; zx=reform(rebin(a(*,y0-2:y0+2),nx,1),nx)
; zy=reform(rebin(a(x0-2:x0+2,*),1,ny),ny)
; zx=smooth(zx,5)
; zy=smooth(zy,5)
; xcen=total(dd*zx(x0-xwid:x0+xwid))/total(zx(x0-xwid:x0+xwid))
; ycen=total(dd*zy(y0-xwid:y0+xwid))/total(zy(y0-xwid:y0+xwid))
  maxcc=max(cc,ixc)
  iym=ixc/nx
  ixm=ixc-iym*nx
  ccx=cc(ixm-1:ixm+1,iym)
  ccy=reform(cc(ixm,iym-1:iym+1))
  xcen=ixm-nx/2.-0.5*(ccx(2)-ccx(0))/(ccx(0)+ccx(2)-2.*ccx(1))
  ycen=iym-ny/2.-0.5*(ccy(2)-ccy(0))/(ccy(0)+ccy(2)-2.*ccy(1))

  
  xx(i)=xcen
  yy(i)=ycen

  filesh=strmid(filin,0,14)
  iyr=long(strmid(filesh,0,4))
  imo=long(strmid(filesh,4,2))
  ida=long(strmid(filesh,6,2))
  ihr=long(strmid(filesh,8,2))
  imi=long(strmid(filesh,10,2))
  ise=long(strmid(filesh,12,2))
  tt(i)=julday(imo,ida,iyr,ihr,imi,ise)

endfor

end

