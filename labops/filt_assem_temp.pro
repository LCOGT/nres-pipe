pro filt_assem_temp,jd,tamb,tbase,tair,tcoll,tambn,tambsm,tambnsm
; This routine reads Rob's assembly_area_temperatures file and filters
; it to approximately 1 sample per minute.  Results are returned in
; jd, tamb, tbase, tair, tcoll.  JD value is actually JD-2457600.

rd_assem_temp,0,jd0,tamb0,tbase0,tcoll0,tair0,tambn0
rd_assem_temp,1,jd1,tamb1,tbase1,tcoll1,tair1,tambn1
rd_assem_temp,2,jd2,tamb2,tbase2,tcoll2,tair2,tambn2
rd_assem_temp,3,jd3,tamb3,tbase3,tcoll3,tair3,tambn3
jdx=[jd0,jd1,jd3,jd2]
tambx=[tamb0,tamb1,tamb3,tamb2]
tbasex=[tbase0,tbase1,tbase3,tbase2]
tairx=[tair0,tair1,tair3,tair2]
tcollx=[tcoll0,tcoll1,tcoll3,tcoll2]
tambnx=[tambn0,tambn1,tambn3,tambn2]

; median filter tambx, replace bad points with median
tamby=median(tambx,5)
s=where(abs(tambx-tamby) gt 3.,ns)
if(ns gt 0) then tambx(s)=tamby(s)
tambny=median(tambnx,5)
s=where(abs(tambnx-tambny) gt 3.,ns)
if(ns gt 0) then tambnx(s)=tambny(s)

; rebin data in blocks of 10 points
nt=n_elements(jdx)
ntr=long(nt/10.0d0)
nts=ntr*10L
jd=rebin(jdx(0:nts-1),ntr)-2457600.d0
tamb=rebin(tambx(0:nts-1),ntr)
tbase=rebin(tbasex(0:nts-1),ntr)
tair=rebin(tairx(0:nts-1),ntr)
tcoll=rebin(tcollx(0:nts-1),ntr)
tambn=rebin(tambnx(0:nts-1),ntr)

; make smoothed tamb, tambn, aiming to filter out most of the 1-hour signal
tambsm=smooth(smooth(smooth(tamb,51),61),71)
tambnsm=smooth(smooth(smooth(tambn,51),61),71)

end
