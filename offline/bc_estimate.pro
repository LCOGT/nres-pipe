pro bc_estimate,jplfile,bc
; This routine estimates the barycentric correction for the jd
; and celestial coords rasex (eg 08:17:32) and decsex (eg -49:12:48)
; that are entered in response to a prompt.
; Result in km/s is printed and returned in bc

radian=180./!pi

rd_jplxyzvel,jplfile,tt,vx,vy,vz

print,'Enter desired JD'
jd=0.d0
read,jd

print,'Enter RA (hh:mm:ss)'
ss=''
read,ss
words=get_words(ss,delim=':',nw)
iw=fix(words)
ra=15.*ten(iw)/radian     ; ra in radians

print,'Enter Dec (dd:mm:ss)'
ss1=''
read,ss1
words1=get_words(ss1,delim=':')
iw1=fix(words1)
dec=ten(iw1)/radian        ; dec in radians

; x,y,z coords of object on unit circle
xx=cos(ra)*cos(dec)
yy=sin(ra)*cos(dec)
zz=sin(dec)

; projected velocity away from target (time series)
stop
tsv=-(xx*vx + yy*vy - zz*vz)

; find value for given JD by interpolation
bc=interpol(tsv,tt,jd)
print,'BC = ',bc

stop

end
