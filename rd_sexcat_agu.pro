pro rd_sexcat_agu,filin,x,y,mag,fwhm,elong,sky,ierr
; this routine reads the ascii file filin written by sextractor and
; returns the values of x_image, y_image, mag_whatever, err in mag,
; image fwhm, image elongation, and flags.
; Outputs are floating vectors. 

; open the file, read to the end of the header, pulling out column
; numbers as we go
openr,iun,strtrim(filin,2),/get_lun
ss=''
ss1=''
ierr=0
ixc=-1
iyc=-1
imc=-1
ifw=-1
iel=-1
ibk=-1
f1='(a1,i4,1x,a15)'
ncol=0
while(ss ne ' ') do begin
  if(eof(iun)) then begin
    ierr=-1
    goto,bail
  endif
  point_lun,-iun,pstrt
  readf,iun,ss,nc,ss1,format=f1
  if(ss ne '#') then goto,endh
  ncol=ncol+1
  ix=strpos(ss1,'XWIN_IMAGE')
  if(ix ge 0) then ixc=nc-1
  iy=strpos(ss1,'YWIN_IMAGE')
  if(iy ge 0) then iyc=nc-1
  im=strpos(ss1,'MAG_')
  if(im ge 0) then imc=nc-1

  ix=strpos(ss1,'FWHM_IMAGE')
  if(ix ge 0) then ifw=nc-1
  ix=strpos(ss1,'ELLIPTICITY')
  if(ix ge 0) then iel=nc-1
  ix=strpos(ss1,'BACKGROUND')
  if(ix ge 0) then ibk=nc-1

endwhile
endh:
point_lun,iun,pstrt

; count objects
nob=0
while(not eof(iun)) do begin
  readf,iun,ss
  nob=nob+1
endwhile

; make output arrays
x=fltarr(nob)
y=fltarr(nob)
mag=fltarr(nob)
fwhm=fltarr(nob)
elong=fltarr(nob)
sky=fltarr(nob)
z=fltarr(ncol)

; back to start of data, read the goods
point_lun,iun,pstrt
for i=0,nob-1 do begin
  readf,iun,z
  x(i)=z(ixc)
  y(i)=z(iyc)
  mag(i)=z(imc)
  if(ifw ge 0) then fwhm(i)=z(ifw)
  if(iel ge 0) then elong(i)=z(iel)
  if(ibk ge 0) then sky(i)=z(ibk)
endfor

bail:
close,iun
free_lun,iun

end
