pro plot_rvdiag,diagout
; This routine plots diagnostics of the stellar spectrum analysis,
; waiting for a <CR> between plots.

;diagout={cfts:cfts,parm4:parm4,itemp:itemp,mjd:mjd,tslamb:tslamb,match:match,$
;        ts2:ts2,roall:roall}
c=299792.458  ; speed of light (km/s)

; pull needed vars out of the input structure, for convenience
mjd=diagout.mjd
itemp=diagout.itemp
ts2=diagout.ts2
roall=diagout.roall
nt=n_elements(itemp)
nth=nt/2
sz=size(roall)
nord=sz(1)
nblock=sz(2)
xord=findgen(nord)
roallv=roall*c

; plot the variation of roall with order number, for beginning, middle, end
; of the time series.
window,xsiz=1000,ysiz=600
!p.multi=[0,1,3]
xt='Order Index'
yt='RV Displacement (km/s)'
yr=[-2.,2.]
tit='RV Displacement'
mjds0=string(mjd(0),format='(f10.4)')
plot,xord,roallv(*,nblock/2-1,0),psym=1,ytit=yt,/xsty,yran=yr,/ysty,$
  charsiz=1.6,tit=tit
xyouts,10,1.50,'1st='+mjds0
mjds1=string(mjd(nth),format='(f10.4)')
plot,xord,roallv(*,nblock/2-1,nth),psym=1,ytit=yt,/xsty,yran=yr,/ysty,$
  charsiz=1.6
xyouts,10,1.50,'Mid='+mjds1
mjds2=string(mjd(nt-1),format='(f10.4)')
plot,xord,roallv(*,nblock/2-1,0),psym=1,xtit=xt,ytit=yt,/xsty,yran=yr,/ysty,$
  charsiz=1.6
xyouts,10,1.50,'End='+mjds2

ss=''
read,ss

; plot the variation of roall with block number, for 3 orders, for beginning,
; middle, end of time series
xblock=findgen(12)
window,xsiz=500,ysiz=600
!p.multi=[0,1,3]
xt='Block Index'
yt='RV Displacement (km/s)'
yr=[-2.,2.]
tit='RV Displacement  Orders 25,35,45,55'
mjds0=string(mjd(0),format='(f10.4)')
plot,xblock,roallv(25,*,0),ytit=yt,yran=yr,/xsty,/ysty,tit=tit,charsiz=1.4,$
  /nodata
for k=25,55,10 do begin
  pk=(k-25)/10.+1
  oplot,xblock,roallv(k,*,0),psym=-pk
endfor
xyouts,2,1.5,'1st='+mjds0
mjds1=string(mjd(nth),format='(f10.4)')
plot,xblock,roallv(25,*,nth),ytit=yt,yran=yr,/xsty,/ysty,charsiz=1.4,$
  /nodata
for k=25,55,10 do begin
  pk=(k-25)/10.+1
  oplot,xblock,roallv(k,*,nth),psym=-pk
endfor
xyouts,2,1.5,'Mid='+mjds1
mjds2=string(mjd(nt-1),format='(f10.4)')
plot,xblock,roallv(25,*,nt-1),ytit=yt,yran=yr,/xsty,/ysty,charsiz=1.4,$
  xtit=xtit,/nodata
for k=25,55,10 do begin
  pk=(k-25)/10.+1
  oplot,xblock,roallv(k,*,nt-1),psym=-pk
endfor
xyouts,2,1.5,'End='+mjds2

read,ss

window,xsiz=600,ysiz=400
!p.multi=[0,1,1]
ts2c=ts2*c
mjdmin=long(min(mjd))
mjddif=mjd-mjdmin
mjdmins=string(mjdmin,format='(i5)')
yr=[-.5,.5]
xtit='MJD - '+mjdmins
tit='Median RV by Blocks'
ytit='RV (km/s)'
so=sort(mjddif)
plot,mjddif(so),ts2c(so,2),tit=tit,xtit=xtit,ytit=ytit,/xsty,yran=yr,/ysty,$
  charsiz=1.4
oplot,mjddif(so),ts2c(so,3),thick=3
xb=mjddif(so(nt*.5))
xt=mjddif(so(nt*.63))
oplot,[xb,xt],[.8*yr(1),.8*yr(1)]
oplot,[xb,xt],[.7*yr(1),.7*yr(1)],thick=3
xyouts,mjddif(so(nt*.67)),.8*yr(1),'Blocks 0:5',charsiz=1.4
xyouts,mjddif(so(nt*.67)),.7*yr(1),'Blocks 6:11',charsiz=1.4

read,ss

; do gray-scale plot of roallv for times at beginning, middle, end of series.
; Use so array to sort into time order.
zz0=transpose(reform(roallv(*,*,so(0))))
zz1=transpose(reform(roallv(*,*,so(nth))))
zz2=transpose(reform(roallv(*,*,so(nt-1))))
zz=fltarr(nblock,nord,3)
zz(*,*,0)=zz0
zz(*,*,1)=zz1
zz(*,*,2)=zz2
window,xsiz=3*6*(nblock+1),ysiz=6*nord+20
bb=bytscl(zz,min=-0.5,max=0.5)
s=where(abs(zz) le 0.001,ns)
if(ns gt 0) then bb(s)=0
bbb=rebin(bb,6*nblock,6*nord,3,/samp)
tv,bbb(*,*,0)
tv,bbb(*,*,1),6*(nblock+1),0
tv,bbb(*,*,2),12*(nblock+1),0
xyouts,20,6*nord+5,'1st        Mid        End',charsiz=1.4,/dev

;stop

read,ss

end
