pro thar_plot,thar,dd0,a0,x0,z0,f0,g0,lam
; makes an array with dims (nx,nord) containing wavelengths for each
; pixel in the Sedgwick spectrograph.
; Accepts the spectrum tharspec, plots ThAr vs x, order
; Reads in the ThAr hot line list, overplots the positions of the
; lines that fall on orders.
; dd0 is change in grating spacing in micron
; a0 is change in sinalpha in radians
; x0 is pixel shift on detector in
; z0 is the redshift of the lambdaofx wavelengths, in the usual cosmo sense
; f0 is the change in focal length in mm
; g0 is the change in the y-coordinate at which gamma=0, from its nominal
;             value of y0=-10

@nres_comm

; constants
;linelist='~/Thinkpad2/nres/svncode/nres/pipeline/arc_Thar0.txt'
nresroot=getenv('NRESROOT')
linelist=nresroot+'reduced/config/arc_ThAr_Redman.txt'
;linelist=nresroot+'reduced/config/arc_ThAr0.txt'
ymax=40000.            ; max y to plot

nord=specdat.nord
nx=specdat.nx
radian=180.d0/!pi
wavelen=dblarr(nx,nord)
mm=findgen(nord)+specdat.ord0     ; order #
d=specdat.grspc       ; groove spacing in micron = 79 lines/mm
dd=dd0/1000.         ; increase d by .01 micron
d=d+dd
sinalp=sin(specdat.grinc/radian)
fl=specdat.fl
print,'fl/d = ',fl/d
y0=specdat.y0
r0=specdat.rot/radian
lamcen=specdat.lamcen
gltype=specdat.glass
priswedge=specdat.apex
zz=specdat.z0
coefs=specdat.coefs

xx=specdat.pixsiz*(findgen(nx)-nx/2.d0)      ; x-coord in mm

; compute wavelength grid, using existing rcubic coefficients
lambdaofx,xx,mm,d,gltype,priswedge,lamcen,r0,sinalp,fl,y0,z0,lam,y0m,/air,$
    rcubic=coefs
lam=lam*(1.+zz+z0)

; get a representative ThAr spectrum across all orders
sz=size(thar)
nx=sz(1)
nord=sz(2)

; Get the ThAr line list
openr,iun,linelist,/get_lun
ss=''
readf,iun,ss
readf,iun,ss
nline=0
while(not eof(iun)) do begin
  readf,iun,ss
  nline=nline+1
endwhile

point_lun,iun,0
readf,iun,ss
readf,iun,ss
linelam=dblarr(nline)
lineamp=fltarr(nline)
v1=0.d0
for i=0,nline-1 do begin
  readf,iun,v1,v2
  linelam(i)=v1
  lineamp(i)=v2
endfor
close,iun
free_lun,iun

; reject lines with amplitudes less than acrit
acrit=0.001
s=where(lineamp ge acrit,ns)
linelam=linelam(s)
lineamp=lineamp(s)
nline=ns

; plot, the spectra, fourth rooted for more dynamic range
window,1,xsiz=1200,ysiz=650
if(nord lt 40) then stp=1. else stp=3.
dy=stp/nord
xran=[0.,nx]
yran=[0.,1.]
xx=[0.,nx-1]
yy=[0.,1.]
plot,xx,yy,xran=xran,yran=yran,xtit='X pix',charsiz=1.3,/nodata,/xsty

for i=0,nord-1,stp do begin
  x=findgen(nx)
  y=dy*(i-0.3+((((thar(*,i) > 1.) < ymax)/ymax))^.25)
  oplot,x,y
  if((i mod 2) eq 0) then xyouts,0,(i+0.2)*dy,string(i),charsiz=1.2
endfor

; overplot the line list
for i=0,nline-1 do begin
  dif=abs(lam-linelam(i))
  md=min(dif,ix)
  if(md le 0.1) then begin
    cord=long(ix/nx)
    if((cord mod stp) eq 0) then begin
      cx=ix-cord*nx
      oplot,[cx],[dy*(cord+.35)],psym=1,symsiz=0.8
      if(linelam(i) gt 515.15 and linelam(i) lt 517.) then begin
        oplot,[cx],[dy*(cord+.45)], psym=4,symsiz=0.8
      endif
    endif
  endif
endfor
  
stop

; print some diagnostics
print,'Center lambda = ',lam(1024,11)*10.
print,'Lambda range x = ',(lam(2047,11)-lam(0,11))*10.
print,'Lambda range y = ',(lam(1024,0)-lam(1024,21))*10.

end
