function shtitlstr,object,site,mjd,bjdtdb,iord0,exptime,version
; This routine constructs a so-called short title from various data relating
; to an NRES image of type TARGET.

obstr=strtrim(object,2)+', '
sitstr=strupcase(strmid(site,0,2))+', '

; make datestring from mjd
jd=mjd+2450000.5d0
caldat,jd,mo,da,yr,hh,mm,ss
datestr=string([yr,mo,da],format='(i4,"-",i2.2,"-",i2.2,"_")')
timestr=string([hh,mm,ss],format='(i2.2,"h",i2.2,"m",i2.2,"s, ")')

hjdstr=string(bjdtdb,format='(f14.6)')+', '
apstr='ap = '+strtrim(string(iord,format='(i2)'),2)+', '
expstr='expt = '+strtrim(string(exptime,format='(i4)'),2)+' s, '
verstr='Ver = '+version

shtitle=obstr+sitstr+datestr+timestr+hjdstr+apstr+expstr+verstr

return,shtitle

end
