pro plot_lamdiag,diagout
; This routine plots some diagnostics of the wavelength solution, waiting
; for a <CR>. between plots.

;diagout={cfts:cfts,parm4:parm4,itemp:itemp,mjd:mjd,tslamb:tslamb,match:match,$
;        ts2:ts2,roall:roall}

; pull needed vars out of the input structure, for convenience
cfts=diagout.cfts
parm4=diagout.parm4
mjd=diagout.mjd
itemp=diagout.itemp
tslamb=diagout.tslamb
nmatch=diagout.match.nmatch
matchlam=reform(diagout.match.matchdat(*,0,*))
matchamp=reform(diagout.match.matchdat(*,1,*))
matchwid=reform(diagout.match.matchdat(*,2,*))
matchline=reform(diagout.match.matchdat(*,3,*))
matchxpos=reform(diagout.match.matchdat(*,4,*))
matchord=reform(diagout.match.matchdat(*,5,*))
matcherr=reform(diagout.match.matchdat(*,6,*))
matchdif=reform(diagout.match.matchdat(*,7,*))
tslamb=diagout.tslamb
nt=n_elements(itemp)
nth=nt/2

; plot,temperature, number of matches, center lam (Mgb order), lam range vs time
tmin=long(min(mjd))
mjdp=24.*(mjd-tmin)
window,xsiz=1000,ysiz=600
!p.multi=[0,2,2]
xt='MJD - '+string(tmin,format='(i5)')+' (Hours)'
yt0='Temp (C)'
yt1='No of Matches'
yt2='Lam_cen Mg b order (nm)'
yt3='Lam Range Mg b order (nm)'

plot,mjdp,itemp,ytit=yt0,/ynoz,/xsty,psym=1,charsiz=1.2
plot,mjdp,nmatch,ytit=yt1,/ynoz,/xsty,psym=1,charsiz=1.2
plot,mjdp,tslamb(2048,38,*),xtit=xt,ytit=yt2,/ynoz,/xsty,psym=1,charsiz=1.2
lamran=tslamb(4095,38,*)-tslamb(0,38,*)
plot,mjdp,lamran,xtit=xt,ytit=yt3,/ynoz,/xsty,psym=1,charsiz=1.2

ss=''
read,ss

window,xsiz=1000,ysiz=600
!p.multi=[0,1,3]
; plot wavelength solution err vs nominal wavelength
xt='Wavelength (nm)'
yt='Line Posn Err (nm)'
yr=[-.005,.005]
tit='Line Position Errs'
mjds0=string(mjd(0),format='(f10.4)')
pmlam0=matchlam(0:nmatch(0)-1,0)
pmdif0=matchdif(0:nmatch(0),1,0)
plot,pmlam0,pmdif0,ytit=yt,/xsty,yran=yr,/ysty,psym=1,symsiz=.4,$
  tit=tit,charsiz=1.6
xyouts,520.,0.004,'1st='+mjds0,charsiz=1.3
mjds1=string(mjd(nth),format='(f10.4)')
pmlam1=matchlam(0:nmatch(nth)-1,nth)
pmdif1=matchdif(0:nmatch(nth)-1,nth)
plot,pmlam1,pmdif1,ytit=yt,/xsty,yran=yr,/ysty,psym=1,symsiz=.4,$
  charsiz=1.6
xyouts,520.,0.004,'Mid='+mjds1,charsiz=1.3
mjds2=string(mjd(nt-1),format='(f10.4)')
pmlam2=matchlam(0:nmatch(nt-1)-1,nt-1)
pmdif2=matchdif(0:nmatch(nt-1)-1,nt-1)
plot,pmlam1,pmdif1,xtit=xt,ytit=yt,/xsty,yran=yr,/ysty,psym=1,symsiz=.4,$
  tit=tit,charsiz=1.6
xyouts,520.,0.004,'End='+mjds2,charsiz=1.3

read,ss

end
