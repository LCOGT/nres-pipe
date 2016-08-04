pro svd_thar,filin,w,u,v
; This routine reads filin, which must be a THAR*.fits file from
; reduced/thar.  It takes the site information from the header and calls
; dlamdparm to generate d(lam)/d(parameter_i) for all of the 19 wavelength
; solution parameters.
; It also unpacks matchord and matchxpos from the input file, and
; evaluates the derivatives at these order and x-coord points, to yield
; vectors corresponding to the expected changes in line wavelengths for
; a unit change in each parameter.
; These vectors are then packed into an array dimensioned (19,nline),
; which is decomposed via SVD to yield output arrays w,u,v.

@nres_comm

dd=readfits(filin,hdr0)
mjd=sxpar(hdr0,'MJD')
site=strupcase(strtrim(sxpar(hdr0,'SITEID'),2))
get_specdat,mjd,err

; replace the standard wavelen parameters with the ones from input files
fxbopen,unit,filin,1,hdr1
fxbread,unit,v1,'SINALP'
fxbread,unit,v2,'FL'
fxbread,unit,v3,'Y0'
fxbread,unit,v4,'Z0'
specdat.sinalp=v1(1)
specdat.fl=v2(1)
specdat.y0=v3(1)
specdat.z0=v4(1)
fxbclose,unit

; same for coefs values
fxbopen,unit,filin,2,hdr2
fxbread,unit,v0,'C00'
fxbread,unit,v1,'C01'
fxbread,unit,v2,'C02'
fxbread,unit,v3,'C03'
fxbread,unit,v4,'C04'
fxbread,unit,v5,'C05'
fxbread,unit,v6,'C06'
fxbread,unit,v7,'C07'
fxbread,unit,v8,'C08'
fxbread,unit,v9,'C09'
fxbread,unit,v10,'C10'
fxbread,unit,v11,'C11'
fxbread,unit,v12,'C12'
fxbread,unit,v13,'C13'
fxbread,unit,v14,'C14'
fxbclose,unit
specdat.coefs=[v0(1),v1(1),v2(1),v3(1),v4(1),v5(1),v6(1),v7(1),v8(1),$
       v9(1),v10(1),v11(1),v12(1),v13(1),v14(1)]

; get matchord and matchxpos from the 3rd data segment
fxbopen,unit,filin,3,hdr3
fxbread,unit,matchord,'matchord'
fxbread,unit,matchxpos,'matchxpos'
fxbclose,unit
nlines=n_elements(matchord)

; get the derivatives of lambda wrt all the wavelength parameters
dlamdparm,site,lam,dlamdparms,dlamdcoefs

; and evaluate these at each of the matched line positions
nord=specdat.nord
mat=fltarr(19,nlines)
for i=0,3 do begin
  for j=0,nord-1 do begin
    s=where(matchord eq j,ns)
    if(ns gt 0) then begin
      mat(i,s)=reform(dlamdparms(matchxpos(s),j,i),1,ns)
    endif
  endfor
endfor
for i=0,14 do begin
  for j=0,nord-1 do begin
    s=where(matchord eq j,ns)
    if(ns gt 0) then begin
      mat(i+4,s)=reform(dlamdcoefs(matchxpos(s),j,i),1,ns)
    endif
  endfor
endfor

; do svd
svdc,mat,w,u,v

stop

end
