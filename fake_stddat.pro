pro fake_stddat,n,nx,ny,nord,nfib,site,camera,target,iyr,imo,ida,teff,logg
; This routine makes fake data files of the following types in standard format, 
; and writes them into the appropriate subdir of nodbase/reduced.
; It also updates the standards.csv file appropriately.
; On input,
;  n specifies how many files of each type should be created,
; each with a nominal creation date of 12:34:56 on successive days,
; starting as the specified month imo, day ida and year iyr
;   nx, ny = the detector format in pix
;   nord, nfib = number of orders, fibers in spectra
;   site, camera = strings identifying siteID and cameraID
;   target (string), teff, logg = values to be put in ZEROs files
; 
; Output files are of types BIAS, DARK, FLAT, TRIPLE, TRACE, ZERO

; constants
jd0=julday(imo,ida,iyr,12,34,56.0)
mjd0=jd0-2400000.5d0

nresroot=getenv('NRESROOT')
nresrooto=nresroot+getenv('NRESINST')+'/reduced/'
tempdir='temp/'
agdir='autog/'
biasdir='bias/'
darkdir='dark/'
expmdir='expm/'
thardir='thar/'
specdir='spec/'
ccordir='ccor/'
rvdir='rv/'
classdir='class/'
diagdir='diag/'
csvdir='csv/'
flatdir='flat/'
tracedir='trace/'
tripdir='trip/'
zerodir='zero/'

; loop over the desired days
for ic=0,n-1 do begin
  mjd=mjd0+ic
  jd=jd0+ic
  datereal=date_conv(jd,'R')
  datestr=string(datereal,format='(f12.4)')

; bias
  bias=fltarr(nx,ny)+987.65
  mkhdr,hdr,bias
  sxaddpar,hdr,'MJD',mjd,'Creation date'
  sxaddpar,hdr,'MJD-OBS','Data date'
  sxaddpar,hdr,'NFRAVGD',3,'Avgd this many frames' 
  sxaddpar,hdr,'FILNAME1','lab_fl01_17760704.0013.fits','1st filename'
  sxaddpar,hdr,'SITEID',strlowcase(site)
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE','BIAS'
  sxaddpar,hdr,'EXPTIME',0.0
  biasname=biasdir+'BIAS'+datestr+'.fits'
  biasout=nresrooto+biasname
  writefits,biasout,bias,hdr
  stds_addline,'BIAS',biasname,1,site,camera,jd,'0000'

; dark
  dark=fltarr(nx,ny)+3.2
; start with bias header, which is mostly okay
  sxaddpar,hdr,'OBSTYPE','DARK'  
  sxaddpar,hdr,'EXPTIME',100.
  sxaddpar,hdr,'FILENAME1','lab_fl01_17760704.0016.fits','1st filename'
  sxaddpar,hdr,'NFRAVGD',10,'Avgd this many frames'
  darkname=darkdir+'DARK'+datestr+'.fits'
  darkout=nresrooto+darkname
  writefits,darkout,dark,hdr
  stds_addline,'DARK',darkname,1,site,camera,jd,'0000'

; flat
  flat=fltarr(nx,nord,nfib)+1.0
; make a mask, denoted by NaN values in flat array
  xx=2.*(findgen(nx)-nx/2.)/nx         ; range [-1,1]
  for i=0,nord-1 do begin
    wid=1.1-0.5*i/float(nord)
    s=where(abs(xx) gt wid,ns)
    if(ns gt 0) then flat(s,i,*)=!values.f_nan
  endfor
  mkhdr,hdr,flat
  sxaddpar,hdr,'MJD',mjd,'Creation date'
  sxaddpar,hdr,'NFRAVGD',7,'Avgd this many frames'
  sxaddpar,hdr,'FILNAME1','lab_fl01_17760704.0020.fits','1st filename'
  sxaddpar,hdr,'SITEID',strlowcase(site)
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE','FLAT'
  sxaddpar,hdr,'EXPTIME',1.0
  flatname=flatdir+'FLAT'+datestr+'.fits'
  flatout=nresrooto+flatname
  writefits,flatout,flat,hdr
  stds_addline,'FLAT',flatname,7,site,camera,jd,'0000'

; zero
  zero=fltarr(nx,nord,2)+4.0
  mkhdr,hdr,zero
  sxaddpar,hdr,'MJD',mjd,'Creation date'
  sxaddpar,hdr,'NFRAVGD',2,'Avgd this many frames'
  sxaddpar,hdr,'FILNAME1','lab_fl01_17760704.0025.fits','1st filename'
  sxaddpar,hdr,'SITEID',strlowcase(site)
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE','ZERO'
  sxaddpar,hdr,'EXPTIME',1.0
  sxaddpar,hdr,'TEFF',teff
  sxaddpar,hdr,'LOGG',logg
  sxaddpar,hdr,'NRESTARG',target
  zeroname=zerodir+'ZERO'+datestr+'.fits'
  zeroout=nresrooto+zeroname
  writefits,zeroout,zero,hdr
  zeros_addline,zeroname,2,site,camera,jd,target,teff,logg,-9.99,0.65,'0000'

; triple
; use an interim fits format for the triple file, consisting of a few 
; keywords followed by a table dimensioned (ncoef,nord,2) giving the
; x-shifts (fiber0 - fiber 1) and (fiber2 - fiber1).
; basis functions are legendre polynomials.
  triple=rebin(reform([5.4,-0.54,0.054,-0.0054,-0.00054],5,1,1),5,nord,2)
  triple(*,*,1)=-triple(*,*,1)
  mkhdr,hdr,triple
  sxaddpar,hdr,'MJD',mjd,'Creation date'
  sxaddpar,hdr,'NFRAVGD',4,'Avgd this many frames'
  sxaddpar,hdr,'FILNAME1','lab_fl01_17760704.0030.fits','1st filename'
  sxaddpar,hdr,'SITEID',strlowcase(site)
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE','TRIPLE'
  sxaddpar,hdr,'EXPTIME',3.0
  tripname=tripdir+'TRIP'+datestr+'.fits'
  tripout=nresrooto+tripname
  writefits,tripout,triple,hdr
  stds_addline,'TRIPLE',tripname,4,site,camera,jd,'0000'

; trace
; trace looks much like triple:
; keywords followed by a table dimensioned (ncoef,nord,nfib) giving the
; y-coord of the centers of the traces, with width in a keyword.
; basis functions are legendre polynomials.
  sep=float(ny)/(nord+1)
  yy=sep*findgen(nord)
  trace=rebin(reform([0.0,-20.,60.,-1.2,0.006],5,1,1),5,nord,nfib)
  trace(0,*,*)=rebin(reform(yy,1,nord,1),1,nord,nfib)
  mkhdr,hdr,trace
  sxaddpar,hdr,'MJD',mjd,'Creation date'
  sxaddpar,hdr,'NFRAVGD',8,'Avgd this many frames'
  sxaddpar,hdr,'FILNAME1','lab_fl01_17760704.0030.fits','1st filename'
  sxaddpar,hdr,'SITEID',strlowcase(site)
  sxaddpar,hdr,'INSTRUME',camera
  sxaddpar,hdr,'OBSTYPE','TRACE'
  sxaddpar,hdr,'EXPTIME',15.0
  tracname=tracedir+'TRAC'+datestr+'.fits'
  tracout=nresrooto+tracname
  writefits,tracout,trace,hdr
  stds_addline,'TRACE',tracname,8,site,camera,jd,'0000'

endfor

end
