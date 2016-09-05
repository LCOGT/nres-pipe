function shtitlstr,object,site,mjd,bjdtdb,iord0,exptime,snr,version
; This routine constructs a so-called short title from various data relating
; to an NRES image of type TARGET.

obstr=strtrim(object,2)+', '
sitstr='obs='+strupcase(strmid(site,0,2))+', '

; make datestring from mjd
jd=mjd+2400000.5d0
caldat,jd,mo,da,yr,hh,mm,ss
datestr=string([yr,mo,da],format='(i4,"-",i2.2,"-",i2.2,"_")')
timestr=string([hh,mm,ss],format='(i2.2,"h",i2.2,"m",i2.2,"s, ")')

hjdstr=string(bjdtdb,format='(f14.6)')+', '
apstr='ap = '+strtrim(string(iord0,format='(i2)'),2)+', '
expstr='expt = '+strtrim(string(exptime,format='(i4)'),2)+' s, '
snstr='S/N='+string(snr,format='(f5.1)')+', '
verstr='Ver = '+version

shtitle=obstr+sitstr+datestr+timestr+hjdstr+apstr+expstr+snstr+verstr

return,shtitle

end
