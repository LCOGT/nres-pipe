pro barycorr,jd,ra,dec,lat,long,bc
; This routine computes an approximate (few m/s accuracy) barycentric
; correction, given the JD, ra & dec of the target, and latitude, E. long
; of the telescope.
; Result is in km/s; + values are redshift (Earth is moving away from target).
;   To correct the observed velocity, subtract bc from
; the observed RV.

; constants
rearth=6371.
radian=180.d0/!pi
ve=rearth*2.*!pi/86400.       ; equatorial velocity

; radians
rar=ra/radian
decr=dec/radian
latr=lat/radian
longr=long/radian

; get barycentric velocity
baryvel,jd,2000.,vh,vb
v=vb(0)*cos(decr)*cos(rar) + vb(1)*cos(decr)*sin(rar) + vb(2)*sin(decr)

; make earth rotation
ct2lst,lst,long,0.,jd             ; lst = local sidereal time
phir=(lst+6.)*15./radian                  ; RA of velocity vector (radian)
vr=ve*cos(decr)*cos(rar-phir)
bc=-(v+vr)


end
