pro plot_nice_3,ps=ps
; This routine makes a nice plot of 3 orders containing CaII K, H-beta,
; and CaII ~865 for the TESS report, Oct 2016.
; The CaII 865 order is massaged to correct an evident flat-fielding
; failure.

nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
dname=nresrooti+'reduced/spec/SPEC2016280.88409.fits'
lname=nresrooti+'reduced/thar/THAR2016280.88409.fits'
dd=readfits(dname,hdrd,/silent)
lam=readfits(lname,hdrl,/silent)

xr=[[392,395],[482,489],[857,871]]
xtit='Vacuum Wavelength (nm)'
ytit='Signal (kilo e-)'
tit='NRES Sample Orders'

labl=['Ca II K','H-beta','Ca II 866.4']
x0=lam(*,66,2)
x1=lam(*,44,2)
x2=lam(*,2,2)
xx=x2-864.3
yy=1.+0.52*exp(-xx^2/3.)
y0=smooth(dd(*,66,1),3)/1.e3
y1=smooth(dd(*,44,1),3)/1.e3
y2=smooth(dd(*,2,1)/yy,3)/1.e3

if(keyword_set(ps)) then begin
  psll,name=ps
endif

!p.multi=[0,1,3]
plot,x0,y0,xran=xr(*,0),ytit=ytit,tit=tit,/xsty,charsiz=1.5,$
    thick=2
xyouts,392.2,1.0,labl(0)
plot,x1,y1,xran=xr(*,1),ytit=ytit,/xsty,charsiz=1.5,$
    thick=2
xyouts,482.5,60.,labl(1)
plot,x2,y2,xran=xr(*,2),ytit=ytit,/xsty,xtit=xtit,charsiz=1.5,$
    thick=2
xyouts,858.,100.,labl(2)

!p.multi=[0,1,1]

if(keyword_set(ps)) then begin
  psend
  sun
endif

end
