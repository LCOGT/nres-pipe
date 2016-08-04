pro agu_focus_dat,flist,nfstd,x0,y0,defo,zfoc,fwhm,mag0,fwst
; This routine reads a list of AGU camera sextractor catalog files 
; from the ascii file
; flist, along with an associated list (one value per line) of requested
; defocus settings (mm).  It also takes an integer nfstd, giving the index
; (0 based) of the image that is to be used as the standard.
; It then reads all of the catalogs, computes coordinate transformations to
; match each one to the standard, identifies all nst stars that are present in
; all nt catalogs, and produces arrays
; x0(nst),y0(nst) = star coordinates in standard image
; defo(nt) = defocus corresp to each catalog (mm)
; zfoc(nst) = defocus distance of estimated (parabolic interpolation) best
;     focus for each star
; fwhm(nst) = best-focus fwhm per star
; mag0(nst) = extracted magnitude per star, for the standard image
; fwst(nst,nt) = fwhm of each matched star in each catalog.

; constants
rcap=20.               ; capture radius in pixels

; read list of catalog names and defocus values
openr,iun,flist,/get_lun
ss=''
files=['']
defo=[0]
nt=0
while(not eof(iun)) do begin
  readf,iun,ss
  words=get_words(ss,nwd)
  files=[files,strtrim(words(0),2)]
  defo=[defo,float(words(1))]
  nt=nt+1
endwhile
close,iun
free_lun,iun
files=files(1:*)
defo=defo(1:*)

; read the 'standard' catalog
fnstd=strtrim(files(nfstd),2)
rd_sexcat_agu,fnstd,x,y,mag,fwhm,elong,sky,ierr

; make output vectors that depend only on standard catalog
nst=n_elements(x)
x0=x
y0=y
mag0=mag
fwst=fltarr(nst,nt)

; make segment list for standard cat

; loop over all catalogs
; read the catalog
for i=0,nt-1 do begin
  fn=strtrim(files(i),2)
  rd_sexcat_agu,fn,x,y,mag,fwhm,elong,sky,ierr
  nsc=n_elements(x)                ; number of stars in current catalog

; make segment list for this cat

; match segment lists to make coordinate transform

; compute star coords, transformed to the standard frame

; search these coords for positional matches.  If successful, copy data into
; fwst array.  Search for closest match that satisfies dist <= rcap
  for j=0,nsc-1 do begin
    dist=sqrt((x0-x(j))^2+(y0-y(j))^2)
    md=min(dist,ix)
    if(md le rcap) then begin
      fwst(ix,i)=fwhm(j)
    endif
  endfor


; end loop over catalogs
endfor

; Identify and eliminate stars with missing data
igood=intarr(nst)
for i=0,nst-1 do begin
  if(min(abs(fwst(i,*))) ne 0.) then igood(i)=1
endfor
sg=where(igood eq 1,nsg)
if(nsg gt 0) then begin
  fwst=fwst(sg,*) 
  zfoc=fltarr(nsg)
  x0=x0(sg)
  y0=y0(sg)
  mag0=mag0(sg)
endif else begin
  print,'ERROR!'
endelse

; loop over remaining stars
for j=0,nsg-1 do begin

; estimate position of minimum fwhm
  mf=min(fwst(j,*),jx)
  dx=abs(defo-defo(jx))
  so=sort(dx)
  xx=defo(so(0:5))      ; take the 6 points nearest to the minimum
  yy=fwst(j,so(0:5))
  cc=poly_fit(xx,yy,2)
  xmin=-cc(1)/(2.*cc(2))
  zfoc(j)=xmin

; end loop over stars
endfor

end
