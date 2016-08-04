function nresbarycorr,targname,centtime,targra,targdec,lat,long,alt
; This function computes and returns the redshift factor zbary relating to
; the target targname at the given JD centtime.
; If target = 'SUN', the target is taken to be the Sun, else a star.
; On input,
;  targname = ascii string name of target
;  centtime = JD of flux-weighted center of observation  
;  targra = RA of target (decimal degrees)
;  targdec = Declination of target (decimal degrees)
;  lat = latitude of telescope (decimal degrees)
;  long = W longitude of telescope (decimal degrees)
;  alt = elevation of telescope (m)
;
; Returned value is z = (r-1) where r is redshift of object.  Naively, RV = c*z

; constants
datname='~/Thinkpad2/idl/astrolib/data/JPLEPH.405'
radian=180.d0/!pi
rearth=6.371d3            ; earth radius in km.
c=2.99792458d5            ; light speed

; compute stellar zbary
if(targname ne 'SUN') then begin
  zbary=zbarycorr(centtime,targra,targdec,$
     lat=lat,long=long,alt=alt,/skip_eop)    ; /skip_eop forces simplifications
                                      ; that limit accuracy to ~2 cm/s
endif else begin
; compute solar z.  This code is not as accurate as the version for stars.
; First get geocentric-heliocentric RV.
  tt=[centtime-0.1,centtime+0.1]          ; time span for interpolation
  jplephread,datname,info,rawdata,tt
  jplephinterp,info,rawdata,centtime,x,y,z,vx,vy,vz,/velocity,/earth,$
     center='SUN',velunits='KM/S'
; make radial unit vector to Sun center, velocity vector
  rr=[x(0),y(0),z(0)]
  rru=rr/sqrt(total(rr^2))        ; points Sun-to-Earth
; dot product of velocity onto rru
  vv=[vx(0),vy(0),vz(0)]
  vvr=total(vv*rru)
  
; Earth rotation
  sprot=2.*!pi*(rearth+alt/1.d3)*cos(lat/radian)/86400.  ; rotation speed (km/s)
  ct2lst,lst,long,0.,centtime             ; local sidereal time (hours)
  vangle=15.*(lst+6.) mod 360.       ; direction angle of the rotation velocity
                                     ; vector in earth equator (x-y) plane.
  vangler=vangle/radian
  vrot=sprot*[cos(vangler),sin(vangler),0.]  ; rotation velocity vector
; dot product of vrot onto rru
  vrotr=total(vrot*rru)

; sum, converted to redshift
  zbary=(vvr+vrotr)/c

;  stop

endelse

return,zbary
end
