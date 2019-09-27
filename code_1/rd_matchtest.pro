pro rd_matchtest,filin,nfile,mjds,nlines,lamb,linelam,xpos,ampl,width,order
; This routine reads an ascii file written by nfile invocations of
; avg_doub2trip_1, returning two arrays
; mjds(nfile) = observing dates for each file
; nlines(nfile) = the number of matched spectral lines for each file.
; Data values for the matched lines are returned in arrays 
; lamb(1000,nfile)
; linelam(1000,nfile)
; xpos(1000,nfile)
; ampl(1000,nfile)
; width(1000,nfile)
; order(1000,nfile)
; Data in these arrays are valid for column indices (0:nlines-1)

; constants
maxlines=1000

; open the input file, create output arrays
openr,iun,filin,/get_lun
mjds=dblarr(nfile)
nlines=lonarr(nfile)
lamb=dblarr(maxlines,nfile)
linelam=dblarr(maxlines,nfile)
xpos=fltarr(maxlines,nfile)
ampl=fltarr(maxlines,nfile)
width=fltarr(maxlines,nfile)
order=intarr(maxlines,nfile)

; loop over files
for i=0,nfile-1 do begin
  mjd=0.d0
  readf,iun,mjd,format='(f12.5)'
  mjds(i)=mjd
  nline=0L
  readf,iun,nline
  nlines(i)=nline
  tl=dblarr(nline)
  tf=fltarr(nline)
  ti=intarr(nline)
  readf,iun,tl
  lamb(0:nline-1,i)=tl
  readf,iun,tl
  linelam(0:nline-1,i)=tl
  readf,iun,tf
  xpos(0:nline-1,i)=tf
  readf,iun,tf
  ampl(0:nline-1,i)=tf
  readf,iun,tf
  width(0:nline-1,i)=tf
  readf,iun,ti
  order(0:nline-1,i)=ti
endfor

close,iun
free_lun,iun

end
