pro plo_tv,bdat,xr,yr,tit,xtit,ytit,ps=ps
; displays bdat as a tv image and overplots a set of axes with
; coordinates  that range from xr(0:1), yr(0:1), with
; the given titles.
; keyword ps is set, also writes result to idl.ps as a postscript file.

x0=120 & y0=48 ; coords of lower left corner of plot

sz=size(bdat)
nx=sz(1)
ny=sz(2)

if(not keyword_set(ps)) then begin
  tv,bdat,x0,y0

  yz=fltarr(ny)
  plot,yz,xran=xr,yran=yr,xsty=1,ysty=1,tit=tit,xtit=xtit,ytit=ytit,$
     posit=[x0,y0,x0+nx-1,y0+ny-1],/device,/noerase

endif

if(keyword_set(ps)) then begin
; protrait mode

  x0=0.16 & y0=0.30   ;  coords of lower left corner in dev-indep units
  xwid=6.0           ;  x width in inches
  ywid=4.5           ; y width in inches
  xpaper=8.5        ; paper width in inches
  ypaper=11.        ; paper height in inches
  xwidn=xwid/xpaper
  ywidn=ywid/ypaper
  thick=7

  set_plot,'ps'
  !p.font=0
  device,/times,bits_per_pixel=8,file='idl.ps',scale_factor=1.0,/inches, $
 	 xoffset=0.0, yoffset=0.0, xsize=xpaper, ysize=ypaper,/color

  tv,bdat,x0,y0,/normal,xsiz=xwidn,ysiz=ywidn
  plot,xr,yr,/nodata,/noerase,/ynozero,/normal, $
    xsty=1,ysty=1,tit=tit,xtit=xtit,ytit=ytit, $
    posit=[x0,y0,x0+xwidn,y0+ywidn],thick=thick


  psend

  sun
endif

end
