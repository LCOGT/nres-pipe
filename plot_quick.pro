pro plot_quick
; This routine writes a quick-look postscript file to directory
; reduced/plot
; The file has a name tied to the open-shutter time and the site.
; A suffix _0 or _2 identifies the active fiber.  If 2 fibers have starlight,
; then two plots are generated, one for each fiber.
; The plots are designed to resemble Dave Latham's TRES quick-look plots
; as closely as seems reasonable.
; 

@nres_comm
@thar_comm

; constants
c=299792.458d0               ; light speed in km/s
black=0
blue=64
green=128
red=192          ; or whatever
coltab=6                                  ; color table
; air wavelengths (AA) for overplotted lines in plots 4,5,6,7
lamplot=[396.85d,656.281d,670.79d,589.0d,589.6d] 
; plot xtitles,ytitles
xtit=['Wavelength (Angstrom)','Shift (km/s)']
ytit=['Relative Intensity','','ADU','Photons']
titl=['Rotating template correlation','Non-rotating template correlation',$
      'Mg b 5184','Ca II H 3968.5','H alpha 6562.81','Li 6707.9',$
      'NaD 5890 and 5896']

; pull the data to be plotted or printed out of the common blocks
exptime=echdat.exptime
jd=2450000.5d0+echdat.mjd
site=echdat.siteid
objects=strupcase(strtrim(get_words(echdat.objects,nobj,delim='&'),2))
nx=nx_c
nord=nord_c
baryshifts=rvindat.baryshifts          ; 2 elements, one per fiber
targra=[rvindat.targstrucs[0].ra,rvindat.targstrucs[1].ra]  ; decimal degree
targdec=[rvindat.targstrucs[0].dec,rvindat.targstrucs[1].dec] ; decimal degree
rvvo=rvred.rvvo   ;cross-correl RV, 2 elements, one per fiber ; km/s
ampcco=rvred.ampcco  ; cross-correl amplitude, one element per fiber ; max=1

; make string sexigesimal versions of RA, Dec
rah=targra/15.        ; RA in hours
rastr=strarr(2)       ; RA, Dec strings
decstr=strarr(2)
for i=0,1 do begin
  ras=sixty(rah(i))
  rastr(i)=string(ras(0),format='(i2.0,"h")') + $
           string(ras(1),format='(i2.0,"m")') + $
           string(ras(2),format='(f5.2,"s")')
  decs=sixty(targdec(i))
  if(targdec(i) ge 0) then sgn='+' else sgn='-'
  decstr(i)=sgn+string(decs(0),format='(i2.0,"d")') + $
                string(decs(1),format='(i2.0,"m")') + $
                string(decs(2),format='(f4.1,"s")')
endfor

; which fiber are we plotting?  If two, loop over them
if(nobj eq 2) then begin
  if(objecst(0) ne 'THAR' and objects(1) ne 'THAR') then begin
    print,'FAIL in plot_quick:  no ThAr fiber'
    goto,fini
  endif else begin
    nplot=1
    if(objects(0) ne 'THAR') then iplot0=0 else iplot0=1
  endelse
endif
if(nobj eq 3) then begin
; in this case, fiber 1 is ThAr and one or both of fibers [0,2] are objects
  if(objects(1) ne 'THAR') then begin
    print,'FAIL in plot_quick:  no ThAr fiber'
    goto,fini
  endif
  if(objects(0) ne 'NONE' and objects(1) ne 'NONE') then begin
; get here if 2 fibers have starlight
    nplot=2
    iplot0=0
  endif else begin
; get here if only one has starlight
    nplot=1
    if(objects(0) ne 'NONE') then iplot0=2 else iplot0=0
  endelse
endif

for i=0,nplot-1 do begin
  iplot=iplot0+2*i
  specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
     grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
      coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
  xx=pixsiz_c*(findgen(nx_c)-nx_c/2.)
  lambda3ofx,xx,mm_c,iplot,specstruc,lam,y0m,/air          ; air wavelengths

; get wavelengths and fluxes for the desired plots and plot intervals
  get_plotdat,lam,corspec,[513.3,523.5],iord0,lam0,plt0    ; Mg b order
  get_plotdat,lam,corspec,[513.3,523.5],iord3,lam3,plt3,/noblaze  ; Mg b again
  get_plotdat,lam,corspec,[394.0,401.5],iord4,lam4,plt4,/noblaze  ; Ca H
  get_plotdat,lam,corspec,[652.0,664.5],iord5,lam5,plt5,/noblaze  ; H alpha
  get_plotdat,lam,corspec,[655.0,677.0],iord6,lam6,plt6,/noblaze  ; Li 6708
  get_plotdat,lam,corspec,[585.0,595.5],iord7,lam7,plt7,/noblaze  ; Na D

; get wavelengths and fluxes for the corresponding ZERO file
  zstar=rvindat.zstar(*,*,iplot/2)
  zlam=rvindat.zlam(*,*,iplot/2)
  get_plotdat,zlam,zstar,[513.3,523.5],iord0z,lam0z,plt0z ; Mg b order zero spec

; shifts and cross-correlation values for plots 1 & 2.
  x1=rvred.delvo(*,i)
  plt1=rvred.ccmo(*,i)
  
; make the title string
  version='1.1'      ; ###bogus###
  shorttitl=shtitlstr(objects(iplot),site,mjd,bjdtdb_c,iord0,exptime,version) 

; set up for plot
  fibstr='_'+string(iplot,format='(i1)')
  sitesh=strlowcase(strmid(site,0,2))
  plotname=plotdir+'/PLOT'+sitesh+datestrc+fibstr+'.ps'
  psll,name=plotname

; 1st page plot
  !p.multi=[0,1,2]
  loadct,coltab
  minx=min(lam0)
  maxx=max(lam0)
  miny=min(plt0)
  maxy=max(plt0)
  xran=[minx,maxx]
  pran=maxy-miny
  yran=[miny-0.15*pran,maxy+0.05*pran]
  plot,lam0,plt0,tit=shorttitl,xtit=xtits(0),ytit=ytits(0),/xsty,/ynoz,$
     xran=xran,yran=yran,charsiz=1.5,/nodata
  oplot,lam0,plt0,color=blue
  oplot,lam0z,plt0z,color=red
; lots of xyouts stuff here
  xbot=xran(0)+2.5
  xtop=xran(1)-10.
  ybot=yran(0)+(pran*.05)*findgen(4)

  xyouts,xbot,ybot(0),'Program = unknown'              ; font?
  xyouts,xbot,ybot(1),'N_COMB = unknown'
  xyouts,xbot,ybot(2),'DEC = '+decstr(i)
  xyouts,xbot,ybot(3),'RA  = '+rastr(i)
  xyouts,xtop,ybot(0),'Vrot = unknown'
  xyouts,xtop,ybot(1),'[m/H] = unknown'
  xyouts,xtop,ybot(2),'Log g = unknown'
  xyouts,xtop,ybot(3),'Teff = unknown'

 !p.multi=[3,3,2]                             ; do the 2nd row
  xran=[-400.,400.]
  yran=[0.,1.]
  xbot=50.
  ybot=0.8+0.05*findgen(3)
  
  plot,x1,plt1,tit=titl(0),xtit=xtit(1),ytit=ytit(1),/xsty,/ysty,$
    xran=xran,yran=yran,charsiz=1.5,/nodata
  oplot,x1,plt1,color=black
  oplot,[0.,0.],[0.,1.],color=blue
  oplot,[rvvo(i),rvvo(i)],[0.,1.],color=green
  xyouts,xbot,ybot(0),'Peak = '+string(ampcco(i),format='(f5.3)')
  xyouts,xbot,ybot(1),'BC = '+string(baryshifts(i),format='(f7.3)')
  xyouts,xbot,ybot(2),'RV = '+string(rvvo(i),format='(f8.3)')

; do the 2nd correlation plot
  plot,x1,plt1,tit=titl(0),xtit=xtit(1),ytit=ytit(1),/xsty,/ysty,$
    xran=xran,yran=yran,charsiz=1.5,/nodata
  oplot,x1,plt1,color=black
  oplot,[0.,0.],[0.,1.],color=blue
  oplot,[rvvo(i),rvvo(i)],[0.,1.],color=green
  xyouts,xbot,ybot(0),'Peak = '+string(ampcco(i),format='(f5.3)')
  xyouts,xbot,ybot(1),'BC = '+string(baryshifts(i),format='(f7.3)')
  xyouts,xbot,ybot(2),'RV = '+string(rvvo(i),format='(f8.3)')

; do the 'spectrum' plot
  yran=[0.,1.15*max(plt3)]
  plot,lam3,plt3,tit=titl(2),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
    yran=yran,charsiz=1.5

; second page
  !p.multi=[2,2,0]

  yran=[0.,1.35*max(plt4)]
  yspan=[max(plt4),1.35*max(plt4)]
  plot,lam4,plt4,tit=titl(3),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
     yran=yran,charsiz=1.5
  oplot,[lamplot(0),lamplot(0)],yspan,color=blue

  yran=[0.,1.35*max(plt5)]
  yspan=[max(plt5),1.35*max(plt5)]
  plot,lam5,plt5,tit=titl(3),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
     yran=yran,charsiz=1.5
  oplot,[lamplot(1),lamplot(1)],yspan,color=blue

  yran=[0.,1.35*max(plt6)]
  yspan=[max(plt6),1.35*max(plt6)]
  plot,lam6,plt6,tit=titl(3),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
     yran=yran,charsiz=1.5
  oplot,[lamplot(2),lamplot(2)],yspan,color=blue

  yran=[0.,1.35*max(plt7)]
  yspan=[max(plt7),1.35*max(plt7)]
  plot,lam7,plt7,tit=titl(3),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
     yran=yran,charsiz=1.5
  oplot,[lamplot(3),lamplot(3)],yspan,color=blue
  oplot,[lamplot(4),lamplot(4)],yspan,color=blue

; last page
  yran=[0.,1.35*max(plt3)]
  yspan=[max(plt3),1.35*max(plt3)]
  plot,lam3,plt3,tit=titl(3),xtit=xtit(2),ytit=ytit(2),/xsty,/ysty,$
     yran=yran,charsiz=1.5
  oplot,[lamplot(0),lamplot(0)],yspan,color=blue

  psend

endfor

sun

fini:
end
