pro argon2alpha,image,dfl
; This routine prompts for x-coordinates of 4 bright argon lines in a NRES
; ThAr spectrum, and does a simple analysis yielding for each line an estimate 
; of the ; incidence angle alpha and its sine.
; The argon lines used are the one forming the compact quadrilateral covering
; orders 9,10,11.  Their positions are entered in left-to-right order, as
; seen on ds9.  Their x-positions should range from roughly 1340 to 1640.
; Also estimates an index of the total counts found in these argon lines per
; unit exposure time, and returns the ratio of observed/desired flux.

; constants
lamvac=[738.199,750.184,763.305,751.262]
ords=[11,10,9,10]          ; diffraction order indices
ypos=[451,412,368,403]     ; 1st guess at y=positions of lines
ord0=52                    ; diffraction order of index=0
grspc=24.0442              ; grating groove spacing in micron
fl=374.4385                ; nominal camera efl (mm)
fl=fl
nn=1.00027                 ; air refractive index at ~740 nm
xc=2048.                   ; detector center pixel location
pixsiz=0.015               ; detector pixel size (mm)
alp0=76.30324              ; nominal incidence angle (deg)
satthrsh=1.00e5            ; pixels brighter than this are assumed saturated
radian=180.d0/!pi
cosgam=.999
nsatstd=10.4                 ; desired number of saturated pix per s.

dd=readfits(image,hdr, /silent)
exptime=sxpar(hdr,'EXPTIME')

print,'Enter 4 line x-coords'
xx=fltarr(4)
read,xx
cosalp0=cos(alp0/radian)
mm=ords+ord0+dfl
sinalp=((mm*nn*lamvac)/(1000.*grspc*cosgam)+cosalp0*(xx-xc)*pixsiz/fl)/2.
alp=asin(sinalp)*radian
print,'alp=',alp

; take boxes centered (more or less) on the bright lines, and count
; the number of saturated pixels per second of exposure time.
nsat=0L
for i=0,3 do begin
  boxi=dd(xx(i)-8:xx(i)+8,ypos(i)-120:ypos(i)+120)
  s=where(boxi ge satthrsh,ns)
  nsat=nsat+ns
endfor

nsat=float(nsat)/exptime
print,'Saturated pix per s =',nsat
print,'Saturated pix relative to desired =',nsat/nsatstd

stop

end
