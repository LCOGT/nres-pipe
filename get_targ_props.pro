function get_targ_props,targname,targra,targdec,ierr
; This routine reads the targets.csv file and finds one line that matches the
; input target name and/or coordinates.  A target structure containing all
; the target information is returned.
; The rules for matching are:
; If the targname matches, seek coordinate matches within 20 arcsec
; If no targname match is found, seek coord matches within 2 arcsec
; If multiple matches are found, take the closest (distance on sky) match.
; If no matches are found, return with ierr=1, else ierr=0.

; constants
;rcapbig=20./3600.         ; big capture radius in degrees
rcapbig=400.              ; temporary hack until proper 2-telescope headers
                          ; are in place
rcapsm=2./3600.           ; small capture radius in degrees
radian=180.d0/!pi

; convert targname to standard form:  all caps, no spaces
targin=strcompress(strupcase(targname),/remove_all)

; get targets data.  Get back an array of structures. (?)
targs_rd,targnames,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr

; look for targname match
targnames=strcompress(strupcase(targnames),/remove_all)
s=where(strtrim(targnames,2) eq targin,ns)
if(ns eq 0) then rcap=rcapsm else rcap=rcapbig

; check coord match
if(ns gt 0) then begin
  targnamem=targnames(s)
  ram=double(ras(s))
  decm=double(decs(s))
  vmagm=float(vmags(s))
  bmagm=float(bmags(s))
  gmagm=float(gmags(s))
  rmagm=float(rmags(s))
  imagm=float(imags(s))
  jmagm=float(jmags(s))
  kmagm=float(kmags(s))
  pmram=float(pmras(s))
  pmdecm=float(pmdecs(s))
  plaxm=float(plaxs(s))
  rvm=float(rvs(s))
  teffm=float(teffs(s))
  loggm=float(loggs(s))
  zerom=zeros(s)
endif else begin
  targnamem=targnames
  ram=double(ras)
  decm=double(decs)
  vmagm=float(vmags)
  bmagm=float(bmags)
  gmagm=float(gmags)
  rmagm=float(rmags)
  imagm=float(imags)
  jmagm=float(jmags)
  kmagm=float(kmags)
  pmram=float(pmras)
  pmdecm=float(pmdecs)
  plaxm=float(plaxs)
  rvm=float(rvs)
  teffm=float(teffs)
  loggm=float(loggs)
  zerom=zeros
endelse

cosdec=cos(decm/radian)
dist=sqrt(((ram-targra)*cosdec)^2 + (decm-targdec)^2)
s1=where(dist le rcap,ns1)
if(ns1 le 0) then begin
  ierr=1
  targout={targname:'NULL',ra:0.d0,dec:0.d0,vmag:0.0,bmag:0.,gmag:0.,rmag:0.0,$
           imag:0.,jmag:0.,kmag:0.,pmra:0.,pmdec:0.,plax:0.,rv:0.,$
           teff:0.,logg:0.,zero:'NULL'}
endif else begin
  dd=dist(s1)
  md=min(dd,ix)
  ierr=0
  s2=s1(ix)
  targout={targname:targnamem(s2),ra:ram(s2),dec:decm(s2),vmag:vmagm(s2),$
           bmag:bmagm(s2),gmag:gmagm(s2),rmag:rmagm(s2),$
           imag:imagm(s2),jmag:jmagm(s2),kmag:kmagm(s2),$
           pmra:pmram(s2),pmdec:pmdecm(s2),plax:plaxm(s2),rv:rvm(s2),$
           teff:teffm(s2),logg:loggm(s2),zero:zerom(s2)}
endelse

return,targout

end
