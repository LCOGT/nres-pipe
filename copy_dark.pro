pro copy_dark
; This routine takes the main data segment of the current data file from
; the nres_common area and writes it to darkdir as a standard fits file.
; Keywords are added to the header to encode the date, site, camera,
; and original filename.  
; A new line describing the dark frame is added to standards.csv

@nres_comm

; grab the data file from nres_common, make the header
dark=float(dat)
get_calib,'BIAS',biasfile,bias,biashdr     ; find bias via the default
                                  ; method, using site, camera, jdc from common
; make a bias-subtracted dark
dark=dark-bias                        ; both should be floats
exptime=sxpar(dathdr,'EXPTIME')
dark=dark/exptime                     ; normalize to 1s exposure time
exptime=1.0

; make the header and fill it out
mkhdr,hdr,dark
sxaddpar,hdr,'MJD',mjdc,'Creation date'
sxaddpar,hdr,'NFRAVGD',1,'Avgd this many frames'
sxaddpar,hdr,'ORIGNAME',filname,'1st filename'
sxaddpar,hdr,'SITEID',site
sxaddpar,hdr,'INSTRUME',camera
sxaddpar,hdr,'OBSTYPE','DARK'
sxaddpar,hdr,'EXPTIME',exptime
darko='DARK'+datestrc+'.fits'
darkout=nresroot+darkdir+darko
writefits,darkout,dark,hdr
stds_addline,'DARK','dark/'+darko,1,site,camera,jdc,'0000'

if(verbose ge 1) then begin
  print,'*** copy_dark ***'
  print,'File In = ',filin0
  naxes=sxpar(dathdr,'NAXIS')
  nx=sxpar(dathdr,'NAXIS1')
  ny=sxpar(dathdr,'NAXIS2') 
  print,'Naxes, Nx, Ny = ',naxes,nx,ny
  print,'BIAS file used was ',biasfile
  print,'Wrote file to dark dir:'
  print,darkdir
  print,'Added line to reduced/standards.csv'
endif

end
