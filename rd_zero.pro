pro rd_zero,zeropath,hdr,star,thar,lam
; This routine reads a ZERO file from the full pathname zeropath, returning
; arrays
; star(nx,nord) = avg star spectrum, low-pass filtered for noise rejection
; thar(nx,nord) = avg thar spectrum, low-pass filtered for noise rejection
; lam(nx,nord) = wavelength grid for star and thar arrays, in nm.

fxbopen,unit,zeropath,1,hdr        ; get 1st extension of ZERO file
fxbread,unit,star,'Star',1         ; read 'Star' col, row 1
fxbread,unit,thar,'ThAr',1         ; 'ThAr' col
fxbread,unit,lam,'Wavelength',1   ; 'Wavelength' col
fxbclose,unit
free_lun,unit

end
