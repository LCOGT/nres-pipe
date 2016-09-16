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
root=getenv('NRESROOT')
plotdir=root+'reduced/plot/'
c=299792.458d0               ; light speed in km/s
black=0
blue=192
green=128
red=64
coltab=6                                  ; color table
; air wavelengths (AA) for overplotted lines in plots 4,5,6,7
lamplot=[396.85d,656.281d,670.79d,589.0d,589.6d] 
; plot xtitles,ytitles
xtits=['Wavelength (Angstrom)','Shift (km/s)']
ytits=['Relative Intensity','','k ADU','k Photons']
titls=['Rotating template correlation','Non-rotating template correlation',$
      'Mg b 5184','Ca II H 3968.5','H alpha 6562.81','Li 6707.9',$
      'NaD 5890 and 5896']
ppr=[5.,3.5]                     ; pixels per resolution element for NRES, Sedg
gai=[1.,2.5]                     ; gain e-/ADU for NRES, Sedg
cs0=0.78                      ; big character size
cs1=0.68                     ; small character size
cs2=1.5                      ; very big character size

; pull the data to be plotted or printed out of the common blocks
exptime=echdat.exptime
mjd=sxpar(dathdr,'MJD-OBS')                ; observation start time
jd=2400000.5d0+mjd                         ; ditto
site=echdat.siteid
objcts=sxpar(dathdr,'OBJECTS')
objects=strupcase(strtrim(get_words(objcts,nobj,delim='&'),2))
nx=nx_c
nord=nord_c
baryshifts=c*rvindat.baryshifts          ; 2 elements, one per fiber
targra=[rvindat.targstrucs[0].ra,rvindat.targstrucs[1].ra]  ; decimal degree
targdec=[rvindat.targstrucs[0].dec,rvindat.targstrucs[1].dec] ; decimal degree
rvvo=rvred.rvvo   ;cross-correl RV, 2 elements, one per fiber ; km/s
ampcco=rvred.ampcco  ; cross-correl amplitude, one element per fiber ; max=1

; get the flat data
flat=flatdat.flat

; make string sexigesimal versions of RA, Dec
rah=targra/15.        ; RA in hours
rastr=strarr(2)       ; RA, Dec strings
decstr=strarr(2)
for i=0,1 do begin
  ras=sixty(rah(i))
  rastr(i)=string(ras(0),format='(i2.2,":")') + $
           string(ras(1),format='(i2.2,":")') + $
           string(ras(2),format='(f5.2)')
  decs=sixty(targdec(i))
  if(targdec(i) ge 0) then sgn='+' else sgn='-'
  decstr(i)=sgn+string(decs(0),format='(i2.2,":")') + $
                string(decs(1),format='(i2.2,":")') + $
                string(decs(2),format='(f4.1)')
endfor

; which fiber are we plotting?  If two, loop over them
; iplot0 is the first fiber index to plot, one of {0,2}
; nplot is the number of fibers with starlight, one of {1,2}
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
    if(objects(0) eq 'NONE') then iplot0=2 else iplot0=0
  endelse
endif

for i=0,nplot-1 do begin
  iplot=iplot0+2*i
  ip2=iplot/2
  specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
     grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
      coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
  xx=pixsiz_c*(findgen(nx_c)-nx_c/2.)
   lambda3ofx,xx,mm_c,iplot,specstruc,lam,y0m,/air          ; air wavelengths
;  lambda3ofx,xx,mm_c,iplot,specstruc,lam,y0m          ; vacuum wavelengths

; get wavelengths and fluxes for the desired plots and plot intervals
  ist=iplot-fib0
  pltspec=corspec(*,*,ist)
  get_plotdat,lam,pltspec,[513.3,523.5],iord0,lam0,plt0,/norm   ; Mg b order
  get_plotdat,lam,pltspec,[513.3,523.5],iord3,lam3,plt3,/noblaze; more Mg b
  plt3=plt3*flat(*,iord3,iplot)
  get_plotdat,lam,pltspec,[394.5,399.5],iord4,lam4,plt4,/noblaze  ; Ca H
  plt4=plt4*flat(*,iord4,iplot)
  get_plotdat,lam,pltspec,[652.0,664.5],iord5,lam5,plt5,/noblaze  ; H alpha
  plt5=plt5*flat(*,iord5,iplot)
  get_plotdat,lam,pltspec,[655.0,677.0],iord6,lam6,plt6,/noblaze  ; Li 6708
  plt6=plt6*flat(*,iord6,iplot)
  get_plotdat,lam,pltspec,[585.0,595.5],iord7,lam7,plt7,/noblaze  ; Na D
  plt7=plt7*flat(*,iord7,iplot)
  get_plotdat,lam,pltspec,[513.3,523.5],iord8,lam8,plt8            ; more Mg b

; get wavelengths and fluxes for the corresponding ZERO file
  zstar=rvindat.zstar(*,*,ip2)
  zlam=rvindat.zlam(*,*,ip2)
  get_plotdat,zlam,zstar,[513.3,523.5],iord0z,lam0z,plt0z,/norm ; Mg b zero spec
; convert lam0z to air wavelengths
  lam0z=airlam(lam0z,-z0_c)

; shifts and cross-correlation values for plots 1 & 2.
  x1=rvred.delvo(ip2,*)
  plt1=rvred.ccmo(ip2,*)
  
; make S/N estimate per resolution element for Mg b order
if(nx_c gt 4000) then ppre=ppr(0) else ppre=ppr(1)     ; NRES vs Sedgwick
if(nx_c gt 4000) then gg=gai(0) else gg=gai(1)         ;     ditto
sigtyp=ptile(plt8,95)*gg*ppre        ; e- in one resolution element for
                                     ; typical bright pixels (95th percentile)
snr=sigtyp/sqrt(sigtyp + 100.)       ; assume 10 e- read noise

; make the title string
  version='1.1'      ; ###bogus###
  shorttitl=shtitlstr(objects(iplot),site,mjd,bjdtdb_c(iplot),iord0,exptime,$
       snr,version) 

; set up for plot
  fibstr='_'+string(iplot,format='(i1)')
  sitesh=strlowcase(strmid(site,0,2))
  plotname=plotdir+'/PLOT'+sitesh+datestrc+fibstr+'.ps'
  !p.font=0
  psll,name=plotname,ys=20.
  device,set_font='Helvetica'

; 1st page plot
  !p.multi=[0,1,2]
  loadct,coltab
  minx=min(lam0)
  maxx=max(lam0)
  miny=min(plt0)
  maxy=ptile(plt0,98)
  xran=[minx,maxx]
  pran=maxy-miny
  yran=[(miny-0.15*pran) > 0.,maxy+0.05*pran]
  plot,lam0,plt0,tit=shorttitl,xtit=xtits(0),ytit=ytits(0),xran=xran,yran=yran,$
     /xsty,/ysty,charsiz=cs0,/nodata
  oplot,lam0,plt0,color=blue
  oplot,lam0z,plt0z,color=red
; lots of xyouts stuff here
  xbot=xran(0)+(xran(1)-xran(0))*0.05
  xtop=xran(1)-(xran(1)-xran(0))*0.15
  ybot=yran(0)+(pran*.06)*(findgen(4)+0.3)

  xyouts,xbot,ybot(0),'Program = unknown',charsiz=cs1              ; font?
  xyouts,xbot,ybot(1),'N_COMB = unknown',charsiz=cs1
  xyouts,xbot,ybot(2),'DEC = '+decstr(ip2),charsiz=cs1
  xyouts,xbot,ybot(3),'RA  = '+rastr(ip2),charsiz=cs1
  xyouts,xtop,ybot(0),'Vrot = unknown',charsiz=cs1
  xyouts,xtop,ybot(1),'[m/H] = unknown',charsiz=cs1
  xyouts,xtop,ybot(2),'Log g = unknown',charsiz=cs1
  xyouts,xtop,ybot(3),'Teff = unknown',charsiz=cs1

 !p.multi=[3,3,2]                             ; do the 2nd row of plots
  xran=[-400.,400.]
  yran=[-0.4,1.0]
  xbot=50.
  ybot=0.8+0.05*findgen(3)
  
  plot,x1,plt1,tit=titls(0),xtit=xtits(1),ytit=ytits(1),/xsty,/ysty,$
    xran=xran,yran=yran,charsiz=cs2,/nodata
  oplot,x1,plt1,color=black
  oplot,[0.,0.],[yran],color=blue
  oplot,[rvvo(i),rvvo(i)],yran,color=green
  xyouts,xbot,ybot(0),'Peak = '+string(ampcco(ip2),format='(f5.3)'),charsiz=cs1
  xyouts,xbot,ybot(1),'BC = '+string(baryshifts(ip2),format='(f7.3)')+' km/s',$
     charsiz=cs1
  xyouts,xbot,ybot(2),'RV = '+string(rvvo(ip2),format='(f8.3)')+' km/s',$
     charsiz=cs1

; do the 2nd correlation plot
  plot,x1,plt1,tit=titls(1),xtit=xtits(1),ytit=ytits(1),/xsty,/ysty,$
    xran=xran,yran=yran,charsiz=cs2,/nodata
  oplot,x1,plt1,color=black
  oplot,[0.,0.],yran,color=blue
  oplot,[rvvo(i),rvvo(i)],yran,color=green
  xyouts,xbot,ybot(0),'Peak = '+string(ampcco(ip2),format='(f5.3)'),charsiz=cs1
  xyouts,xbot,ybot(1),'BC = '+string(baryshifts(ip2),format='(f7.3)')+' km/s',$
     charsiz=cs1
  xyouts,xbot,ybot(2),'RV = '+string(rvvo(ip2),format='(f8.3)')+' km/s',$
     charsiz=cs1

; do the 'spectrum' plot
  yran=[0.,1.15*ptile(plt3/1.e3,98)]
  plot,lam3,plt3/1.e3,tit=titls(2),xtit=xtits(0),ytit=ytits(2),/xsty,/ysty,$
    yran=yran,charsiz=cs2

; second page
  !p.multi=[0,2,2]

  yran=[0.,1.20*ptile(plt4/1.e3,98)]
  yspan=[ptile(plt4/1.e3,98),1.35*ptile(plt4/1.e3,98)]
  plot,lam4,plt4/1.e3,tit=titls(3),xtit=xtits(0),ytit=ytits(2),yran=yran,$
     /xsty,/ysty,charsiz=cs0
  oplot,10.*[lamplot(0),lamplot(0)],yspan,color=blue

  yran=[0.,1.20*ptile(plt5/1.e3,98)]
  yspan=[ptile(plt5/1.e3,98),1.35*ptile(plt5/1.e3,98)]
  plot,lam5,plt5/1.e3,tit=titls(4),xtit=xtits(0),ytit=ytits(2),/xsty,/ysty,$
     yran=yran,charsiz=cs0
  oplot,10.*[lamplot(1),lamplot(1)],yspan,color=blue

  yran=[0.,1.20*ptile(plt6/1.e3,98)]
  yspan=[ptile(plt6/1.e3,98),1.35*ptile(plt6/1.e3,98)]
  plot,lam6,plt6/1.e3,tit=titls(5),xtit=xtits(0),ytit=ytits(2),/xsty,/ysty,$
     yran=yran,charsiz=cs0
  oplot,10.*[lamplot(2),lamplot(2)],yspan,color=blue

  yran=[0.,1.20*ptile(plt7/1.e3,98)]
  yspan=[ptile(plt7/1.e3,98),1.35*ptile(plt7/1.e3,98)]
  plot,lam7,plt7/1.e3,tit=titls(6),xtit=xtits(0),ytit=ytits(2),/xsty,/ysty,$
     yran=yran,charsiz=cs0
  oplot,10.*[lamplot(3),lamplot(3)],yspan,color=blue
  oplot,10.*[lamplot(4),lamplot(4)],yspan,color=blue

; last page
  yran=[0.,1.20*ptile(plt3/1.e3,98)]
  yspan=[ptile(plt3/1.e3,98),1.35*ptile(plt3/1.e3,98)]
  plot,lam8,plt8/1.e3,tit=titls(2),xtit=xtits(0),ytit=ytits(2),/xsty,/ysty,$
     yran=yran,charsiz=cs0

  psend

endfor

sun

fini:
end
