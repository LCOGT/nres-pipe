pro rd_zero,zeropath,hdr,star,thar,lam,lamt
; This routine reads a ZERO file from the full pathname zeropath, returning
; arrays
; star(nx,nord) = avg star spectrum, low-pass filtered for noise rejection
; thar(nx,nord) = avg thar spectrum, low-pass filtered for noise rejection
; lam(nx,nord) = wavelength grid in rest frame of ZERO star, in nm.
; lamt(nx,nord) = wavelength grid in NRES lab frame, for thar in fiber 1

fxbopen,unit,zeropath,1,hdr        ; get 1st extension of ZERO file
fxbread,unit,star,'Star',1         ; read 'Star' col, row 1
fxbread,unit,thar,'ThAr',1         ; 'ThAr' col
fxbread,unit,lam,'WavelenStar',1   ; 'WavelenStar' col
fxbread,unit,lamt,'WavelenLab',1   ; 'WavelenLab' colk

fxbclose,unit
free_lun,unit

end
