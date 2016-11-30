pro bulkup,filin,objects
; This routine reads an NRES image file of size 4095 x 4072, and
; converts it to 4096 x 4096 by reproducing the last 1 column and
; last 24 rows.  It sets the 'OBJECTS' keyword value equal to the
; objects parameter in the calling sequence, and writes the result
; back out into the same filename filin.

; open the input FITS file, read the main data segment and header
filename=strtrim(filin,2)
dat=readfits(filename,dathdr)
type=strtrim(sxpar(dathdr,'OBSTYPE'),2) 
    
; if array is 4095 x 4072, replicate in x and y to make 4096 x 4096
sz=size(dat)
nx=sz(1)
ny=sz(2)
if(nx eq 4095 and ny eq 4072) then begin
  dato=fltarr(4096,4096)
  dato(0:4094,0:4071)=dat
  daty=dat(*,4048:4071)
  dato(0:4094,4072:4095)=daty
  datx=dato(4094,*)
  dato(4095,*)=datx
  dat=dato
  sxaddpar,dathdr,'NAXIS1',4096
  sxaddpar,dathdr,'NAXIS2',4096
  sxaddpar,dathdr,'OBJECTS',objects
endif

writefits,filin,dat,dathdr

end
