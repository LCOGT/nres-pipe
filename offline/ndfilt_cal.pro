pro ndfilt_cal,flist,dark,angle,flux
; This routine estimates recorded flux vs rotation angle for a list of
; flat-field images taken at different rotations of the ND filter.
; It accepts a list of images, one of which should be identified (by filename)
; as "dark".  It returns vectors of the ND rotation angle for each frame,
; and the flux integrated over a box spanning [500:3500,200:1000] on the
; dark-subtracted images.

; count input files
openr,iun,flist,/get_lun
ss=''
files=['']
while(not eof(iun)) do begin
  readf,iun,ss
  files=[files,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
files=files[1:*]
nfiles=n_elements(files)

; make output vectors
angle=fltarr(nfiles)
flux=fltarr(nfiles)

; read dark array
dark=float(readfits(dark,dhdr),/silent)

; do the work
for i=0,nfiles-1 do begin
  dd=readfits(files(i),hdr,/silent)
  angle(i)=sxpar(hdr,'NDANGLE')
  dif=float(dd)-dark
  flux(i)=total(dif(500:3500,200:1000))
endfor

print,'Dark angle = ',sxpar(dhdr,'NDANGLE')

end

