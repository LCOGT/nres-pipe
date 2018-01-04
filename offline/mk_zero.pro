pro mk_zero,listin,trp=trp,tharlist=tharlist,cubfrz=cubfrz
; This routine creates a ZERO calibration file, containing a spectrum
; array zout(nx,nord,2) in which
; zout(*,*,0) = a massaged average of the target spectra contained in listin
; zout(*,*,1) = a massaged average of the ThAr spectra ditto.
; The routine is free-standing, ie, it is not called from muncha.pro.
; It also fits a wavelength solution to the ThAr spectrum, and stores the
; wavelength solution parameters in the output file fits header, and
; the wavelength grid corresponding to the star fiber (0 or 2) in
; the fits extension double array lamz(nx,nord).
; Input files are FITS files from $NRESROOT/NRESINST/reduced/blaz, listed in the
; ascii text tile listin.  They must all be taken with the same telescope
; and spectrograph, ideally close together in time to avoid significant
; (compared to the linewidths) relative Doppler shifts.
; The input files should be calibrated (corrected for bias, dark, flat),
; as will naturally be true if the data are produced by muncha.pro.
; All input files must be taken in single-telescope mode, so that only
; 2 fibers are illuminated.  Either telescope fiber may be used, but it must
; be the same for all input files.
; Output is a ZERO FITS file which goes into $NRESROOT/reduced/zero,
; and a new line in the reduced/csv/zeros.csv file.
;
; If keyword cubfrz is set, then rcubic coefficients are taken as read from
; spectrographs.csv, ie, no fit is done to modify them.
;
; The method is to average the input spectra, and then smooth the results
; in wavelength with a pseudo-gaussian with ~3.6 pix fwhm to kill
; high-frequency noise.  The wavelength solution is derived by fitting
; a model to the averaged, smoothed ThAr spectrum, then interpolating
; to the wavelength grid appropriate to the stellar input fiber.

@nres_comm

; common block for ThAr reduction
@thar_comm

; initialize tarlist to an empty list
tarlist = []
; constants
 nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
c=299792.458d0               ; light speed in km/s
tarlist=['']                 ; to avoid undefined var in thar_setup

; make creation jd
jdc=systime(/julian)
mjdc=jdc-2400000.5d0
sxaddpar,hdro,'MJDC',mjdc
daterealc=date_conv(jdc,'R')
datestrc=string(daterealc,format='(f13.5)')
fileout='zero/ZERO'+datestrc+'.fits'
output_path=nresrooti+'/reduced/'+fileout

; read the list
flist=['']
ss=''
openr,iun,listin,/get_lun
nf=0
while(not eof(iun)) do begin
  readf,iun,ss
  flist=[flist,strtrim(ss,2)]
  nf=nf+1
endwhile
close,iun
free_lun,iun
flist=flist(1:*)
nfiles=n_elements(flist)

; read the first file, get sizes of things
; put data into nres_comm or thar_comm variables, as appropriate
fname=nresrooti+flist[-1]
dd=readfits(fname,hdr,/silent)
sz=size(dd)
nx=sz(1)
nord=sz(2)
mfib=sz(3)                   ; number of illuminated fibers
objects=sxpar(hdr,'OBJECTS')
objs=strupcase(strtrim(get_words(objects,nwd,delim='&'),2))
site=sxpar(hdr,'SITEID')
mjdobs=sxpar(hdr,'MJD-OBS')
mjdd=mjdobs
jdd=mjdd+2400000.5d0
datereald=date_conv(jdd,'R')
datestrd=string(datereald,format='(f13.5)')
datestrd=strtrim(strlowcase(site),2)+strtrim(datestrd,2)
fileout='zero/ZERO'+datestrd+'.fits'
output_path=nresrooti+'/reduced/'+fileout

camera=sxpar(hdr,'INSTRUME')
if(mfib eq 1 or((mfib eq 3) and ((objs(0) ne 'NONE') and $
     (objs(2) ne 'NONE')))) then begin
  print,'mk_zero input files must have exactly 2 illuminated fibers'
  goto,fini
endif 
s0=where(objs ne 'THAR' and objs ne 'NONE',ns0) ; object fibers
s1=where(objs eq 'THAR',ns1)                    ; thar fibers
ifib0=0 & ifib1=1       ; works for SQA, NRES unless star is on fiber 2
if(objs(0) eq 'NONE') then begin
  ifib0=1 & ifib1=0     ; works with NONE&THAR&OBJ, since only 2 planes
endif                   ; are retained in this case.
if(ns0 le 0 or ns1 le 0) then begin
  print,'In mk_zero, must have 1 target and 1 ThAr fiber'
  goto,fini
endif
target=strupcase(strcompress(objs(s0),/remove_all))
target=target(0)
ix=strpos(target,'_')
if(ix gt 0) then target=strmid(target,0,ix)

; make output array, average file inputs into it
zout=fltarr(nx,nord,2)
zout(*,*,0)=dd(*,*,ifib0)            ; the star spectrum
zout(*,*,1)=dd(*,*,ifib1)            ; the ThAr spectrum 
mjdavg=mjdobs
navg=1
for i=1,nfiles-1 do begin
  fname=nresrooti+flist[i]
  dd=readfits(fname,hdr,/silent)
  zout(*,*,0)=zout(*,*,0)+dd(*,*,ifib0)
  zout(*,*,1)=zout(*,*,1)+dd(*,*,ifib1)
  mjdavg=mjdavg+sxpar(hdr,'MJD-OBS')
  navg=navg+1
endfor
zout=zout/navg
mjdavg=mjdavg/navg
ra=sxpar(hdr,'RA')
dec=sxpar(hdr,'DEC')
obj1=strupcase(strtrim(sxpar(hdr,'OBJ1'),2))
obj2=strupcase(strtrim(sxpar(hdr,'OBJ2'),2))
if(obj1 ne 'NONE' and obj2 ne 'NONE') then begin
  print,'ERROR:  You may only have 1 non-none OBJECT to make a ZERO file'
  ;stop
endif
if(obj1 ne 'NONE') then begin
  lat=sxpar(hdr,'LAT1')           ; latitude, degrees
  longi=sxpar(hdr,'LONG1')        ; E. longitude, degrees
  height=sxpar(hdr,'HT1')         ; height above sea level, m
endif
if(obj2 ne 'NONE') then begin
  lat=sxpar(hdr,'LAT2')           ; latitude, degrees
  longi=sxpar(hdr,'LONG2')        ; E. longitude, degrees
  height=sxpar(hdr,'HT2')         ; height above sea level, m
endif

; smooth the output file to suppress noise
for i=0,nord-1 do begin
  for j=0,1 do begin
    zout(*,i,j)=smooth(smooth(smooth(zout(*,i,j),3),3),3)
  endfor
endfor

; stick zout into nres common var corspec
corspec=zout
tharspec_c=corspec(*,*,1)          ; another name for ThAr spectrum

; run thar_fitall to get wavelength scale.  ThAr spec is always in fibindx=1
thar_fitall,site,1,ierr,trp=trp,tharlist=tharlist,cubfrz=cubfrz

; make the wavelength scale appropriate to the input star fiber.
specd=specdat
specd.sinalp=sinalp_c
specd.grinc=grinc_c
specd.fl=fl_c
specd.y0=y0_c
specd.z0=z0_c
specd.coefs=coefs_c
specd.fibcoefs=fibcoefs_c
xx=specdat.pixsiz*(dindgen(specdat.nx)-specdat.nx/2.d0)
mm=dindgen(specdat.nord)+specdat.ord0
fibno=s0(0)
lambda3ofx,xx,mm,fibno,specd,lamz,y0m_o       ; star fiber
lambda3ofx,xx,mm,1,specd,lamt,y0m_t           ; thar fiber

; find target star properties in targets list
targs_rd,names,ras,decs,vmags,bmags,gmags,rmags,imags,jmags,kmags,$
      pmras,pmdecs,plaxs,rvs,teffs,loggs,zeros,targhdr
names=strupcase(strcompress(names,/remove_all))
s=where(names eq target,ns)
if(ns le 0) then begin
  print,'In mk_zero, target name ',target,' is not found.'
  ;stop
  goto,fini
endif
if(ns gt 1) then s=s(ns-1)
targname=names(s)
ra=ras(s)
dec=decs(s)
rv=rvs(s)
teff=teffs(s)
logg=loggs(s)
bmag=bmags(s)
vmag=vmags(s)
jmag=jmags(s)
kmag=kmags(s)
if(bmag gt (-10) and vmag gt (-10)) then bmv=bmag-vmag else bmv=-99.9
if(jmag gt (-10) and kmag gt (-10)) then jmk=jmag-kmag else jmk=-99.9

; compute the net red shift (intrinsic plus barycentric) for the avg
; time of observation
jdavg=mjdavg+2400000d0-0.5d0
; The barycentric correction is defined so that ztrue=zmeas*zbary.
; So to get lambda in the lab frame, ztrue=0 and zbary=-zmeas.
; Combining the target star redshift with zbary then involves switching
; the sign of the target redshift.
rrv=1.d0-rv/c             ; target intrinsic red shift correction
rrtarg=nresbarycorr(targname,jdavg,ra,dec,lat,longi,height)
rrt=rrv*(rrtarg+1.d0)-1.d0                      ; net correction - unity

; convert wavelength scale to the nominal source rest frame.
lamz=lamz*(1.d0+rrt(0))

; write out the output file
fits_read,nresrooti+flist[-1], data, hdr
sxaddpar,hdr,'NAXIS', 0
sxdelpar,hdr,'NAXIS1'
sxdelpar,hdr,'NAXIS2'
sxdelpar,hdr,'NAXIS3'
sxaddpar,hdr,'OBSTYPE', 'TEMPLATE'
sxaddpar,hdr,'L1PUBDAT', sxpar(hdr,'DATE-OBS')
sxaddpar,hdr,'RLEVEL', 91

set_output_calibration_name, hdr, 'TEMPLATE'
outname = sxpar(hdr,'OUTNAME')
sxaddpar, hdr, 'OUTNAME', outname+'_'+strtrim(string(long(teff), format='(05I)'),2) + '_' + strtrim(string(long(logg * 100), format='(03I)'),2) 

fxaddpar,hdr,'OBJECT',target
fxaddpar,hdr,'SITEID',site
fxaddpar,hdr,'INSTRUME',camera
fxaddpar,hdr,'MJD-OBS',mjdd
fxaddpar,hdr,'MJDC',mjdc
fxaddpar,hdr,'FIBZ0',ifib0(0)
fxaddpar,hdr,'FIBZ1',ifib1(0)
fxaddpar,hdr,'NAVG',nfiles
fxaddpar,hdr,'MJD-OBS',mjdobs
fxaddpar,hdr,'MJD',mjdc,'Creation date'
fxaddpar,hdr,'TEFF',teff(0),'Effective Temperature'
fxaddpar,hdr,'LOGG',logg(0),'log(g)'
fxaddpar,hdr,'BMAG',bmag(0),'B Mag'
fxaddpar,hdr,'VMAG',vmag(0),'V Mag'
fxaddpar,hdr,'JMAG',jmag(0),'J Mag'
fxaddpar,hdr,'KMAG',kmag(0),'K Mag'
fxaddpar,hdr,'REDSHIFT',-rrt(0),'ZERO src redshift -1'
fxaddpar,hdr,'SINALP',sinalp_c,'Sin(alpha)'
fxaddpar,hdr,'FL',fl_c,'Focal Length (mm)'
fxaddpar,hdr,'Y0',y0_c,'Y0 (mm)'
fxaddpar,hdr,'Z0',z0_c,'Z0 - 1.'

fxaddpar,hdr,'C00',coefs_c(0)
fxaddpar,hdr,'C01',coefs_c(1)
fxaddpar,hdr,'C02',coefs_c(2)
fxaddpar,hdr,'C03',coefs_c(3)
fxaddpar,hdr,'C04',coefs_c(4)
fxaddpar,hdr,'C05',coefs_c(5)
fxaddpar,hdr,'C06',coefs_c(6)
fxaddpar,hdr,'C07',coefs_c(7)
fxaddpar,hdr,'C08',coefs_c(8)
fxaddpar,hdr,'C09',coefs_c(9)
fxaddpar,hdr,'C10',coefs_c(10)
fxaddpar,hdr,'C11',coefs_c(11)
fxaddpar,hdr,'C12',coefs_c(12)
fxaddpar,hdr,'C13',coefs_c(13)
fxaddpar,hdr,'C14',coefs_c(14)

fxaddpar,hdr,'F00',fibcoefs_c(0,0)
fxaddpar,hdr,'F10',fibcoefs_c(1,0)
fxaddpar,hdr,'F20',fibcoefs_c(2,0)
fxaddpar,hdr,'F30',fibcoefs_c(3,0)
fxaddpar,hdr,'F40',fibcoefs_c(4,0)
fxaddpar,hdr,'F50',fibcoefs_c(5,0)
fxaddpar,hdr,'F60',fibcoefs_c(6,0)
fxaddpar,hdr,'F70',fibcoefs_c(7,0)
fxaddpar,hdr,'F80',fibcoefs_c(8,0)
fxaddpar,hdr,'F90',fibcoefs_c(9,0)
fxaddpar,hdr,'F01',fibcoefs_c(0,1)
fxaddpar,hdr,'F11',fibcoefs_c(1,1)
fxaddpar,hdr,'F21',fibcoefs_c(2,1)
fxaddpar,hdr,'F31',fibcoefs_c(3,1)
fxaddpar,hdr,'F41',fibcoefs_c(4,1)
fxaddpar,hdr,'F51',fibcoefs_c(5,1)
fxaddpar,hdr,'F61',fibcoefs_c(6,1)
fxaddpar,hdr,'F71',fibcoefs_c(7,1)
fxaddpar,hdr,'F81',fibcoefs_c(8,1)
fxaddpar,hdr,'F91',fibcoefs_c(9,1)

; write out the data as a fits extension table.
; each column contains a single row, and each element is an array
; dimensioned (nx,nord) containing either spectrum intensity values
; or wavelengths.
; The reason to do it this way is that wavelengths must be type double,
; while the intensities want to be single-precision floats.

; there is no main data segment.
fxwrite,output_path,hdr
fxbhmake,hdr,1                    ; make extension header, only 1 row

z0=reform(zout(*,*,0))
z1=reform(zout(*,*,1))
fxbaddcol,jn1,hdr,z0,'Star','ZERO Star Inten'
fxbaddcol,jn2,hdr,z1,'ThAr','ZERO ThAr Inten'
fxbaddcol,jn3,hdr,lamz,'WavelenStar','Wavelength (nm)'
fxbaddcol,jn4,hdr,lamt,'WavelenLab','Lab Wavelength (nm)'
fxbcreate,unit,output_path,hdr,ext1

fxbwritm,unit,['Star','Thar','WavelenStar','WavelenLab'],z0,z1,lamz,lamt
fxbfinish,unit

; make a tarfile for archiving
fpack_stacked_calibration,output_path, sxpar(hdr, 'OUTNAME')


; add a line pointing to this file in the zeros.csv file
; use 3rd flag character to show which fiber was telescope fiber
; 0 -> '0', 2 -> '2'
cflg='00x0'             ; indicates error
if(s0(0) eq 0) then cflg='0000'
if(s0(0) eq 2) then cflg='0020'

zeros_addline,fileout,navg,site,camera,jdc,target,teff,logg,bmv,jmk,cflg

fini:
end
