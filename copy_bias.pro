pro copy_bias
; This routine takes the main data segment of the current data file from
; the nres_common area and writes it to biasdir as a standard fits file.
; Keywords are added to the header to encode the date, site, camera,
; and original filename.  
; A new line describing the bias frame is added to standards.csv

@nres_comm

; grab the data file from nres_common, make the header
bias=float(dat)
mkhdr,hdr,bias
sxaddpar,hdr,'MJD',mjdc,'Creation date'
sxaddpar,hdr,'NFRAVGD',1,'Avgd this many frames'
sxaddpar,hdr,'ORIGNAME',filname,'1st filename'
sxaddpar,hdr,'SITEID',site
sxaddpar,hdr,'INSTRUME',camera
sxaddpar,hdr,'OBSTYPE','BIAS'
exptime=sxpar(dathdr,'EXPTIME')
sxaddpar,hdr,'EXPTIME',exptime
biaso='BIAS'+datestrc+'.fits'
biasout=nresroot+biasdir+biaso
writefits,biasout,bias,hdr
stds_addline,'BIAS','bias/'+biaso,1,site,camera,jdc,'0000'

if(verbose ge 1) then begin
  print,'*** copy_bias ***'
  print,'File In = ',filin0
  naxes=sxpar(dathdr,'NAXIS')
  nx=sxpar(dathdr,'NAXIS1')
  ny=sxpar(dathdr,'NAXIS2') 
  print,'Naxes, Nx, Ny = ',naxes,nx,ny
  print,'Wrote file to bias dir:'
  print,biasout
  print,'Added line to reduced/csv/standards.csv'
endif

end
