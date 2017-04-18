pro plot_qc
; This routine makes a plot of quality control diagnostics for a single
; NRES image of type TARGET.  The postscript plot is written to
; reduced/plot/PLQCssyyyyddd.ttttt_o.ps, where 
; ss= site name (lower case)
; yyyyddd.ttttt = the image data date
; o = the target fiber (0 or 2) being plotted.
; Data plotted are
; echdat.spectrum = intensity integrated across dispersion
;  plotted against x values for center 25% of standard order
;  median over center 25% of x values plotted vs order number
; echdat.specdy2 = 2nd deriv term in cross-dispersion profile fit, medianed
;  over center 25% of x values, plotted vs order number
; echdat.specdy = displacement of data from extraction block center (pix)
;  plotted vs x for standard order (nord*0.4) and
;  median over center 25% of x values, vs order number
; matchdif_c vs matchlam_c = residuals of fit to wavelength vs pix (nm)
;  for all matched ThAr lines
; c*rr0 = estimated redshift (km/s) of stellar spectrum, uncorrected for
;   barycentric motion:
;   plotted vs order and block
;   median over valid (ne 0) shifts for all blocks, plotted vs order
;   median over valid shifts for all orders, plotted vs block #
; echdat.spectrum plotted against wavelength for 4 narrow spectral ranges
;   covering particular lines in the O2 A and B bands, with true vacuum
;   wavelengths overplotted.  Intended as a measure of wavelength solution
;   reliability.

; commons
@nres_comm
@thar_comm

; constants
c=299792.458d0              ; light speed in km/s
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
plotdir=nresrooti+'reduced/plot'
black=0
blue=192
green=128
red=64
coltab=6                                  ; color table


; pull the data to be plotted or printed out of the common blocks
exptime=echdat.exptime
mjd=sxpar(dathdr,'MJD-OBS')                ; observation start time
jd=2400000.5d0+mjd                         ; ditto
site=echdat.siteid
objcts=sxpar(dathdr,'OBJECTS')
objects=strupcase(strtrim(get_words(objcts,nobj,delim='&'),2))
nx=nx_c
nord=nord_c

; which fiber are we plotting?  If two, loop over them
; iplot0 is the first fiber index to plot, one of {0,2}
; nplot is the number of fibers with starlight, one of {1,2}
if(nobj eq 2) then begin
  if(objects(0) ne 'THAR' and objects(1) ne 'THAR') then begin
    print,'FAIL in plot_quick:  no ThAr fiber'
    goto,fini
  endif else begin
    nplot=1
    if(objects(0) ne 'THAR') then iplot0=0 else iplot0=1
    object=strtrim(objects(iplot0),2)
  endelse
endif
if(nobj eq 3) then begin
; in this case, fiber 1 is ThAr and one or both of fibers [0,2] are objects
  if(objects(1) ne 'THAR') then begin
    print,'FAIL in plot_quick:  no ThAr fiber'
    goto,fini
  endif
  if(objects(0) ne 'NONE' and objects(2) ne 'NONE') then begin
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
  ist=iplot-fib0             ; got lots of fiber indices here -- which to use?
  object=strtrim(objects(iplot),2)

; code origin discontinuity here

; make output file path
  ifib=ist                        ; ###### guess
  fibs=strtrim(string(ifib),2)   ; string with index of fiber to plot
  outpath=plotdir+'/PLQC'+strmid(strlowcase(site),0,2)+datestrc+'_'+fibs+'.ps'

; compute standard order, bot and top x range
  stord=fix(nord*0.4)
  xbot=long(nx*0.375)
  xtop=long(nx*0.625)
  cs0=0.9
  cs1=.68
  cs2=1.5                ; character sizes

; postscript setup
  psll,name=outpath,ys=20.
  device,set_font='Helvetica'

  !p.multi=[0,1,3]
  loadct,coltab

; plot spectrum intensity vs x for standard order
  lambda=tharred.lam(xbot:xtop,stord,iplot)
  xran=[min(lambda),max(lambda)]
  yrmax=ptile(echdat.spectrum(xbot:xtop,stord,ifib)/1e3,98)
  yrmin=ptile(echdat.spectrum(xbot:xtop,stord,ifib)/1e3,2)
  yran=[0.8*(yrmin > 0.),1.05*yrmax]
  xtit='Wavelength (nm)'
  ytit='Summed Inten (kADU)'
  tit=object+' '+strmid(strlowcase(site),0,2)+datestrc+'_'+fibs

  spec=echdat.spectrum(xbot:xtop,stord,ifib)
  plot,lambda,spec/1e3,xran=xran,yran=yran,tit=tit,/xsty,/ysty,ytit=ytit,$
      charsiz=cs2,thick=2
  xyouts,0.95*xran(0)+0.05*xran(1),0.9*yran(0)+0.1*yran(1),'Order='+$
      strtrim(string(stord),2),charsiz=cs1

; plot order displacement vs x for standard order
  dy=echdat.specdy(xbot:xtop,stord,ifib)
  yrmax=ptile(dy,98)
  yrmin=ptile(dy,2)
  yran=[floor(yrmin),ceil(yrmax)]
  ytit='Profile dY (pix)'
  plot,lambda,dy,xran=xran,yran=yran,/xsty,/ysty,xtit=xtit,ytit=ytit,$
      charsiz=cs2,thick=2

; plot things vs order number
  ordindx=findgen(nord)
  xtit='Order Index'
  ytit0='Summed Inten (kADU)'
  ytit1='2nd Deriv (Normalized)'
  ytit2='Profile dY (pix)'
  tit='Median Over Center 25 Percent'

; compute the stuff to plot
  medintn=median(echdat.spectrum(xbot:xtop,*,ifib),dimension=1)
  meddy=median(echdat.specdy(xbot:xtop,*,ifib),dimension=1)
  meddy2=median(echdat.specdy2(xbot:xtop,*,ifib),dimension=1)
  nelecs='nElectron='+string(echdat.nelectron(ifib),format='(e8.2)')
  ncray='CRbadpix='+string(echdat.craybadpix,format='(i5)')
  
; do the plots
  !p.multi=[3,3,3]
  loadct,coltab
  yran=[0.,1.05*max(medintn)/1e3]
  plot,ordindx,medintn/1e3,psym=-1,yran=yran,/xsty,/ysty,xtit=xtit,ytit=ytit0,$
     tit=tit,charsiz=cs2,thick=2
  xyouts,3,0.1*yran(1),nelecs,charsiz=cs1

  yran=[0.,1.05*max(meddy2)]
  plot,ordindx,meddy2,psym=-1,yran=yran,/xsty,/ysty,xtit=xtit,ytit=ytit1,$
     tit=tit,charsiz=cs2,thick=2

  yran=[floor(min(meddy)),ceil(max(meddy))]
  plot,ordindx,meddy,psym=-1,yran=yran,/xsty,/ysty,xtit=xtit,ytit=ytit2,$
     tit=tit,charsiz=cs2,thick=2

; new plot page --  do wavelength solution plots
  !p.multi=[0,1,2]
  loadct,coltab
  tit=strmid(strlowcase(site),0,2)+datestrc
  xtit='Wavelength (nm)'
  ytit='lambda Mismatch (nm)'
  xran=[380,880]
  yran=[-.02,.02]
  plot,matchlam_c,matchdif_c,psym=4,xran=xran,yran=yran,/xsty,/ysty,$
    xtit=xtit,ytit=ytit,tit=tit,charsiz=cs1,thick=2
  xyouts,390,-0.015,'nMatch='+strtrim(string(nmatch_c,format='(i4)'),2)

  xtit='Block Index'
  ytit='Redshift (km/s)'
  xran=[-1,specdat.nblock*nord]
  plotdat=c*reform(rvred.rro(ifib,*,*))
  sg=where(plotdat ne 0.,nsg)
  yrmin=ptile(plotdat(sg),10) > (-5.)
  yrmax=ptile(plotdat(sg),90) < 5.    ; biggest poss plot range is [-2,2] km/s
  yran=[yrmin,yrmax]
  indx=findgen(specdat.nblock*nord)
  plot,indx(sg),plotdat(sg),psym=1,xtit=xtit,ytit=ytit,tit=tit,/xsty,/ysty,$
     charsiz=cs0,thick=2,xran=xran,yran=yran
  for j=0,specdat.nblock-1 do begin
    jx=j*nord
    oplot,[jx,jx],[yran(0),yran(1)],line=2
  endfor

; new plot page --  plot spectra and vacuum line wavelengths for O2 A & B bands
  !p.multi=[0,2,2]
  loadct,coltab

  tit=strmid(strlowcase(site),0,2)+datestrc
  tit2=[' B-band',' B-band',' A-band',' A-band']
  xtit='Wavelength (nm)'
  ytit='Flux (kADU)'
  lamline=[688.1829d0,688.57326d0,761.82397d0,762.30873d0]  ; line vac wavelengths
  xra=[[687.98,688.38],[688.37,688.77],[761.70,762.10],[762.11,762.51]]
  ordrs=[16,16,9,9]               ; orders where B, A-band are found.

  iplot=iplot0+2*i
  ip2=iplot/2
  specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
     grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
      coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
  xx=pixsiz_c*(findgen(nx_c)-nx_c/2.)
; lambda3ofx,xx,mm_c,iplot,specstruc,lam,y0m,/air          ; air wavelengths
  lambda3ofx,xx,mm_c,iplot,specstruc,lam,y0m          ; vacuum wavelengths

  s0=where(lam(*,ordrs(0)) ge (xra(0,0)-.2) and lam(*,ordrs(0)) $
    le xra(1,1)+.2,ns0)
  s1=where(lam(*,ordrs(2)) ge (xra(0,2)-.2) and lam(*,ordrs(2)) $
    le xra(1,3)+.2,ns1)
  pdat0=corspec(s0,ordrs(0),ist)/1.e3
  pdat1=corspec(s1,ordrs(2),ist)/1.e3
  plam0=lam(s0,ordrs(0))
  plam1=lam(s1,ordrs(2))
  yra=[[0.,1.2*ptile(pdat0,90)],[0.,1.2*ptile(pdat1,90)]]
  
; do the plots
  for j=0,1 do begin
    plot,plam0,pdat0,xran=xra(*,j),yran=yra(*,j/2),tit=tit+tit2(j),xtit=xtit,$
      ytit=ytit,/xsty,/ysty,charsiz=1.
    oplot,[lamline(j),lamline(j)],yra(*,j/2),thick=3,color=blue
  endfor
  for j=2,3 do begin
    plot,plam1,pdat1,xran=xra(*,j),yran=yra(*,j/2),tit=tit+tit2(j),xtit=xtit,$
      ytit=ytit,/xsty,/ysty,charsiz=1.
    oplot,[lamline(j),lamline(j)],yra(*,j/2),thick=3,color=blue
  endfor

  psend
endfor

;stop

!p.multi=[0,1,1]

fini:
end
