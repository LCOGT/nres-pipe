pro ts_thar,flist,namet,mjdt,sinalpt,flt,y0t,z0t,coeft,fibct,lamcent,lamrant
; This routine opens the muncha output files listed in flist, and strips
; out and returns time series of the ThAr fit parameters
;  namet(nfile)= names of input files
;  mjdt(nfile) = MJD of shutter open
;  sinalpt(nfile) = sin(alpha)
;  flt(nfile) = FL
;  y0t(nfile) = y0
;  z0t(nfile) = z0
;  coeft(nfile,15) = poly fit coefficients
;  fibct(nfile,10) = fibcoef fit coeficients
;  lamcent(nfile,3) = center lam of red, green blue orders
;  lamrant(nfile,3) = wavelength range of red, green, blue orders

; open flist, count files
openr,iun,flist,/get_lun
ss=''
namet=[]
while(not eof(iun)) do begin
  readf,iun,ss
  namet=[namet,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
nfile=n_elements(namet)

; make output arrays
mjdt=dblarr(nfile)
sinalpt=dblarr(nfile)
flt=dblarr(nfile)
y0t=dblarr(nfile)
z0t=dblarr(nfile)
coeft=dblarr(nfile,15)
fibct=dblarr(nfile,10)
lamcent=dblarr(nfile,3)
lamrant=dblarr(nfile,3)

; loop over the input files
for i=0,nfile-1 do begin
  fits_open,namet(i),fcb
  fits_read,fcb,d0,hdr0,exten=0         ; get the 0th extension header

; read needed numbers out of the header
  mjdt(i)=sxpar(hdr0,'MJD-OBS')
  sinalpt(i)=sxpar(hdr0,'SINALP')
  flt(i)=sxpar(hdr0,'FL')
  y0t(i)=sxpar(hdr0,'Y0')
  z0t(i)=sxpar(hdr0,'Z0')
  for j=0,14 do begin
    key='C'+string(j,format='(i02)')
    coeft(i,j)=sxpar(hdr0,key)
  endfor
  for j=0,9 do begin
    key='FIBC'+string(j,format='(i1)')
    fibct(i,j)=sxpar(hdr0,key)
  endfor
  lamcent(i,*)=[sxpar(hdr0,'LAMCENR'),sxpar(hdr0,'LAMCENG'),$
    sxpar(hdr0,'LAMCENB')]
  lamrant(i,*)=[sxpar(hdr0,'LAMRANR'),sxpar(hdr0,'LAMRANG'),$
    sxpar(hdr0,'LAMRANB')]

  fits_close,fcb
endfor

end


