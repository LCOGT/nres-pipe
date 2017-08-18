pro copy_bias
; This routine takes the main data segment of the current data file from
; the nres_common area and writes it to biasdir as a standard fits file.
; Keywords are added to the header to encode the date, site, camera,
; and original filename.  
; A new line describing the bias frame is added to standards.csv

@nres_comm

rutname='copy_bias'

; grab the data file from nres_common, make the header
logo_nres2,rutname,'INFO','making bias header'
bias=float(dat)
;mkhdr,hdr,bias
hdr = copy_header(dathdr)
update_data_size_in_header, hdr, bias
sxaddpar,hdr,'MJD',mjdc,'Creation date'
sxaddpar,hdr,'MJD-OBS',mjdd,'Data date'
sxaddpar,hdr,'NFRAVGD',1,'Avgd this many frames'
sxaddpar,hdr,'ORIGNAME',strip_fits_extension(filname),'Original raw filename'
sxaddpar,hdr,'SITEID',site
sxaddpar,hdr,'INSTRUME',camera
sxaddpar,hdr,'OBSTYPE','BIAS'
exptime=sxpar(dathdr,'EXPTIME')
sxaddpar,hdr,'EXPTIME',exptime
biaso='BIAS'+datestrd+'.fits'
biasout=nresrooti+biasdir+biaso

; Create directory if not present:
save_dir = file_dirname(biasout)
if (file_test(save_dir, /DIRECTORY) EQ 0) then begin
   logo_nres2,rutname,'INFO','Creating directory '+save_dir
   file_mkdir, save_dir
endif

; Abort in case of non-writeable directory:
if (file_test(save_dir, /DIRECTORY, /WRITE) EQ 0) then begin
   logo_nres2,rutname,'INFO','FATAL Directory not writeable: '+save_dir
   printf, -2, "Error! Directory not writeable: " + save_dir
   goto,fini
endif

; write bias to file and update records:
logo_nres2,rutname,'INFO','WRITE bias image '+biasout
writefits,biasout,bias,hdr
logo_nres2,rutname,'INFO','ADDLINE standards.csv BIAS line'
stds_addline,'BIAS','bias/'+biaso,1,site,camera,jdd,'0000'
naxes=sxpar(dathdr,'NAXIS')
nx=sxpar(dathdr,'NAXIS1')
ny=sxpar(dathdr,'NAXIS2') 
strax='naxes, nx, ny = '+string(naxes)+' '+string(nx)+' '+string(ny)
logo_nres2,rutname,'INFO',strax

if(verbose ge 1) then begin
  print,'*** copy_bias ***'
  print,'File In = ',filin0
  print,'Naxes, Nx, Ny = ',naxes,nx,ny
  print,'Wrote file to bias dir:'
  print,biasout
  print,'Added line to reduced/csv/standards.csv'
endif

fini:

end
