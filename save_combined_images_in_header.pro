pro save_combined_images_in_header, hdr, combined_filenames
  for i=0,n_elements(combined_filenames)-1 do begin
    ssi=string(i + 1,format='(i03)')
    kwd='IMCOM'+ssi
    sxaddpar,hdr,kwd,strip_fits_extension(combined_filenames[i])
  endfor
 end