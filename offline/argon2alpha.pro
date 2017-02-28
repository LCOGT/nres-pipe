pro argon2alpha,dfl
; This routine prompts for x-coordinates of 4 bright argon lines in a NRES
; ThAr spectrum, and does a simple analysis yielding for each line an estimate 
; of the ; incidence angle alpha and its sine.
; The argon lines used are the one forming the compact quadrilateral covering
; orders 9,10,11.  Their positions are entered in left-to-right order, as
; seen on ds9.  Their x-positions should range from roughly 1340 to 1640.

; constants
lamvac=[738.199,750.184,763.305,751.262]
ords=[11,10,9,10]          ; diffraction order indices
ord0=52                    ; diffraction order of index=0
grspc=24.0442              ; grating groove spacing in micron
fl=374.4385                ; nominal camera efl (mm)
fl=fl
nn=1.00027                 ; air refractive index at ~740 nm
xc=2048.                   ; detector center pixel location
pixsiz=0.015               ; detector pixel size (mm)
alp0=76.30324              ; nominal incidence angle (deg)
radian=180.d0/!pi
cosgam=.999

print,'Enter 4 line x-coords'
xx=fltarr(4)
read,xx
cosalp0=cos(alp0/radian)
mm=ords+ord0+dfl
sinalp=((mm*nn*lamvac)/(1000.*grspc*cosgam)+cosalp0*(xx-xc)*pixsiz/fl)/2.
alp=asin(sinalp)*radian

stop

end
