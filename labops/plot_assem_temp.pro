pro plot_assem_temp,ps=ps
; this routine makes a nice plot of the assembly area temperature probes.
; If keyword ps is set, its value should be a string giving the name of the
; embedded postscript file to be generated.  In this case, ".eps" will be
; added to the filename automatically.

filt_assem_temp,jd,tamb,tbase,tair,tcoll,tambn,tambsm,tambnsm
;filt_assem_temp,jd,tamb,tbase,tair,tcoll,tambsm

xtit='JD - 2457600.'
ytit='Degrees C'
yran=[23.,25.]

loadct,4
red=95
blue=130
green=170
black=240
yellow=30

if(keyword_set(ps)) then psll,name=ps+'.eps'
plot,jd,tamb,psym=3,yran=yran,xtit=xtit,ytit=ytit,/xsty,/ysty,/nodata,$
   charsiz=1.5
oplot,jd,tamb,psym=3,color=blue
oplot,jd,tbase,psym=3,color=black
oplot,jd,tair,psym=3,color=green
oplot,jd,tcoll,psym=3,color=red
oplot,jd,tambsm,psym=3,color=blue
oplot,jd,tambnsm,psym=3,color=blue

if(keyword_set(ps)) then begin
  psend
  sun
endif

end



