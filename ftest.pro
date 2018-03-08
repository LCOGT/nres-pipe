pro ftest
; This routine is a tester for fits output syntax.  It attempts to write a multi-extension
; fits file that does not contain binary tables.

; constants
nx=4096
nord=67
nblock=12
nitem0=4
nitem1=3
nitem2=2
filout=getenv('NRESCODE')+'/ftestout.fits'

; make image files to write out
im0=fltarr(nx,nord,nitem0)+1.234
im1=dblarr(nx,nord,nitem1)+5.678
im2=fltarr(nblock,nord,nitem2)-0.987

; make dummy header keywords
siteid='lsc'
exptime=720.0
mjd=58101.46113d0
t0=19.550
t1=20.550
t2=21.550

; h0=primary HDU, floating point nx x nord x nitem0
mkhdr,hdr0,im0
sxaddpar,hdr0,'SITEID',siteid
sxaddpar,hdr0,'EXPTIME',string(exptime,format='(f10.2)')
sxaddpar,hdr0,'MJD',string(mjd,format='(f12.5)')
sxaddpar,hdr0,'T0',string(t0,format='(f7.3)')
fits_write,filout,im0,hdr0,xtension='IMAGE'

mkhdr,hdr0,im0
fits_open,filout,fcb,/append
;fits_write,fcb,im0,hdr0,extname='SPECTRA'

; h1 = first extension, double precision nx x nord x nitem1
mkhdr,hdr1,im1
sxaddpar,hdr1,'MJD',string(mjd,format='(f12.5)')
sxaddpar,hdr1,'T1',string(t1,format='(f7.3)')
fits_write,fcb,im1,hdr1,extname='WAVELENGTH'

; h2 = second extension, floating point nblock x nord x nitem2
mkhdr,hdr2,im2
sxaddpar,hdr2,'MJD',string(mjd,format='(f12.5)')
sxaddpar,hdr2,'T2',string(t2,format='(f7.3)')
fits_write,fcb,im2,hdr2,extname='RV_BLOCKFIT'

fits_close,fcb

end
