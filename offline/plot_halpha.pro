pro plot_halpha
; This routine makes a nice eps plot of the H-alpha order in 3 different
; stars, as seen by NRES on the commissioning trip.
; Plot goes into $NRESROOT directory

; constants
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
spec=nresrooti+'/reduced/spec/'
thar=nresrooti+'/reduced/thar/'
starnames=['HD77140','HD115383','AlphaOri']
sptypes=['A7IV','G0V','M2Ia']
vmags=[5.15,5.22,0.42]
exptimes=fltarr(3)     ; get these from headers
fnames=['2017104.48479.fits','2017104.45723.fits','2017104.42941.fits']
ifib=[1,1,0]           ; fiber with star data
jord=19                ; order containing H-alpha

; get data
pspec=fltarr(4096,3)     ; 3 stars
lam=dblarr(4096,3)
for i=0,2 do begin
  namin=spec+'SPEC'+fnames(i)
  dd=readfits(namin,hdr,/silent)
  exptimes(i)=sxpar(hdr,'EXPTIME')
  pspec(*,i)=dd(*,jord,ifib(i))
  lamin=thar+'THAR'+fnames(i)
  ll=readfits(lamin,hdrl,/silent)
  lam(*,i)=ll(*,jord,ifib(i))

; smooth the spectrum
  pspec(*,i)=smooth(smooth(pspec(*,i),3),3)

endfor

; make titles
tit=strarr(3)
for i=0,2 do begin
  smag=string(vmags(i),format='(f4.2)')
  tit(i)=starnames(i)+'  '+sptypes(i)+' Vmag='+smag+' ExpTime='+$
      string(exptimes(i),format='(i4)')+'s'
endfor

; do the plots
xtit='Vacuum Wavelength (nm)'
ytit='Flux (kADU)'
xran=[653.,660.]

!p.multi=[0,1,3]
psll,name=nresroot+'H_Alpha3.eps',/encap

for i=0,2 do begin
  plot,lam(*,i),pspec(*,i)/1000.,tit=tit(i),xtit=xtit,ytit=ytit,/xsty,$
    charsiz=1.4,thick=3
endfor

psend
sun
!p.multi=[0,1,1]

end
