pro thar_triple_1,fil01,fil12,tripstruc,rms,force2=force2,cubfrz=cubfrz,$
    nofits=nofits,tharlist=tharlist
; This routine runs offline (ie, not called by muncha).
; It accepts ascii file names fil01,fil02, which should be FITS files
; containing extracted and flat-fielded ThAr/ThAr spectra, resident in 
; the NRES directory reduced/dble.
; Names must be of form, dble/DOUBLExxxxxxx.xxxxx.fits
; fil01 and fil12 must be DOUBLE (ie, thar/thar) spectra --
; if nfib=2 then they must be the same, with OBJECTS='thar&thar'
; if nfib=3 then fil01 must have OBJECTS='thar&thar&none', and
;                fil12 must have OBJECTS='none&thar&thar'.
; If keyword force2 is set, then nfib must be 3, with one fiber (0 or 2) not
; illuminated.  The routine then pretends that there are only 2 fibers,
; namely the two shown by the OBJECTS keyword to have ThAr input.
; In this case the relative displacements of the two illuminated fibers are
; given correctly in the TRIPLE file, and the other pair differences are
; the same, except flipped in sign.
; The routine gets nfib, nblock from the most recent spectrographs entry
; for the site identified in fil01.
; It then runs thar_fit2fib on each input file (only fil01 if nfib=2),
; and constructs the array fibcoefs(10,2), containing polynomial coefficients
; describing the x-pixel shifts between fibers {0,1} or {1,2}.
; For nfib=3, these are interpreted as
; x(fiber0) = x(fiber1) + sum(fibcoefs(j,0)*poly(j; jx,jord)
; x(fiber2) = x(fiber1) + sum(fibcoefs(j,1)*poly(j; jx,jord).
; For nfib=2, fibcoefs(0,*)=fibcoefs(1,*)
; Thus, typically x(fiber0) will have the opposite sign as x(fiber2).
; fibcoefs is written into a FITS file in reduced/trip/TRIPxxxxxxxx.xxxxx,
; and a new line describing the TRIPLE file is written into the
; reduced/csv/standards.csv file.
;
; If keyword cubfrz is set, this prevents thar_fitall from adjusting the
;  rcubic coefficients as read from spectrographs.csv.
;
; If keyword nofits is set, no output fits file is written, and no corresp
; line is added to standards.csv.  This is handy for applications
; (notably avg_doub2trip.pro) that average several pairs of input files
; to create one output file.

; get common blocks for NRES, ThAr fitting
@nres_comm
@thar_comm_1
common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun,ie0,ie1,ie2

; constants
nresroot=getenv('NRESROOT')
nresinst=getenv('NRESINST')
nresrooti=nresroot+nresinst
reddir=nresrooti+'reduced/'
tripdir=nresrooti+'reduced/trip/'

; read input files, decide if we have 2 fibers or 3
fnam01=reddir+strtrim(fil01,2)
fnam12=reddir+strtrim(fil12,2)
dd01=readfits(fnam01,hdr01,/silent)
dd12=readfits(fnam12,hdr12,/silent)
site=strtrim(strupcase(sxpar(hdr01,'SITEID')),2)
camera=strtrim(sxpar(hdr01,'INSTRUME'),2)
mjdd=sxpar(hdr01,'MJD-OBS')
jdd=mjdd+2400000.5d0
objects=strupcase(sxpar(hdr01,'OBJECTS'))
words=get_words(objects,nwords,delim='&')
nfib=nwords
nfiba=0              ; local version of nfib, poss modified by /force2
if(nwords eq 3 and words(0) eq 'THAR' and words(1) eq 'THAR') then begin
  nfiba=3
  fib0=0
endif
if(nwords eq 3 and keyword_set(force2) and words(1) eq 'THAR' and $
    (words(0) eq 'THAR' or words(2) eq 'THAR')) then begin
  nfiba=2                            ; nfiba forced to 2
  if(words(0) eq 'THAR') then fib0=0 else fib0=2   
endif
if(nwords eq 2 and words(0) eq 'THAR' and words(1) eq 'THAR') then begin
  nfiba=2
  fib0=0
endif
if(nfiba eq 0) then begin
  print,'Input file fil01 not ThAr DOUBLE in thar_triple'
  goto,fini
endif

; estimate a wavelength solution for star fiber of fil01
; ifib = index of star fiber in fil01
if(nfiba eq 2 and fib0 eq 0) then ifib=0
if(nfiba eq 2 and fib0 eq 2) then ifib=1  ; Don't yet have this case
if(nfiba eq 3) then ifib=0
print
print,'thar_fitoff_1 input = ',fnam01
print
thar_fitoff_1,ifib,fnam01,'thar_fitoff00.sav',cubfrz=cubfrz,tharlist=tharlist
; save stuff to be averaged with fil12 results
; name contains (input file # 0 or 1) (fiber # 0,1,2)
sinalp00=sinalp_c
fl00=fl_c
y000=y0_c
z000=z0_c
coefs00=coefs_c
lam00=lam_c
xp00=matchxpos_c
io00=matchord_c
ll00=matchline_c
er00=matcherr_c

; repeat for reference fiber fil01 (always fiber 1) 
if(nfiba eq 2 and fib0 eq 0) then ifib=1
if(nfiba eq 2 and fib0 eq 2) then ifib=2
if(nfiba eq 3) then ifib=1
print
print,'thar_fitoff_1 input =',fnam12
print
thar_fitoff_1,ifib,fnam01,'thar_fitoff01.sav',cubfrz=cubfrz,tharlist=tharlist
sinalp01=sinalp_c
fl01=fl_c
y001=y0_c
z001=z0_c
coefs01=coefs_c
lam01=lam_c
xp01=matchxpos_c
io01=matchord_c
ll01=matchline_c
er01=matcherr_c

;stop

; repeat for fil12
objects=strupcase(sxpar(hdr12,'OBJECTS'))
words=get_words(objects,nwords,delim='&')
nfib=nwords
nfiba=0
if(nwords eq 3 and words(1) eq 'THAR' and words(2) eq 'THAR') then begin
  nfiba=3
  fib0=0      ; fib0=2?
endif

if(nwords eq 3 and keyword_set(force2) and words(1) eq 'THAR' and $
    (words(0) eq 'THAR' or words(2) eq 'THAR')) then begin
  nfiba=2                            ; nfiba forced to 2
  if(words(0) eq 'THAR') then fib0=0 else fib0=2
endif

if(nwords eq 2 and words(0) eq 'THAR' and words(1) eq 'THAR') then begin
  nfiba=2
  fib0=0
endif



;if(nwords eq 3 and words(1) eq 'THAR' and words(2) eq 'THAR') then nfiba=3
;if(nwords eq 2 and words(0) eq 'THAR' and words(1) eq 'THAR') then nfiba=2
if(nfiba eq 0) then begin
  print,'Input file fil12 not ThAr DOUBLE in thar_triple'
  stop
  goto,fini
endif

if(nfiba eq 3) then begin
; estimate wavelength solution for fiber 1 of fil12
  thar_fitoff_1,1,fnam12,'thar_fitoff11.sav',cubfrz=cubfrz,tharlist=tharlist
; save stuff to be averaged with fil01 results
  sinalp11=sinalp_c
  fl11=fl_c
  y011=y0_c
  z011=z0_c
  coefs11=coefs_c
  lam11=lam_c
  xp11=matchxpos_c
  io11=matchord_c
  ll11=matchline_c
  er11=matcherr_c

; estimate wavelength solution for fiber 2 of fil12
  thar_fitoff_1,2,fnam12,'thar_fitoff12.sav',cubfrz=cubfrz,tharlist=tharlist
; save stuff to be averaged with fil01 results
  sinalp12=sinalp_c
  fl12=fl_c
  y012=y0_c
  z012=z0_c
  coefs12=coefs_c
  lam12=lam_c
  xp12=matchxpos_c
  io12=matchord_c
  ll12=matchline_c
  er12=matcherr_c
endif

;save,lam00,lam01,lam11,lam12,file='save4lam.idl'

if(nfiba eq 2) then begin
; save wavelength solution for fiber 1
  sinalpav=sinalp01
  flav=fl01
  y0av=y001
  z0av=z001
  coefsav=coefs01
  lamav=lam01
endif
if(nfiba eq 3) then begin
; average wavelength solution results for fiber 1
  sinalpav=(sinalp01+sinalp11)/2.
  flav=(fl01+fl11)/2.
  y0av=(y001+y011)/2.
  z0av=(z001+z011)/2.
  coefsav=(coefs01+coefs11)/2.
  lamav=(lam01+lam11)/2.        ; avg'd lambda grid for fiber 1
endif

; #############
; save inputs to xdisp_1, for quick debug turnaround
save,xp01,io01,ll01,er01,xp00,io00,ll00,er00,xp11,io11,ll11,er11,xp12,io12,ll12,er12,$
    file='savexdispin.idl'
; #############

; call thar_xdisp to get fibcoef estimates
fibcoefs=dblarr(10,2)
if(nfiba eq 2) then begin
  thar_xdisp_1,xp01,io01,ll01,er01,xp00,io00,ll00,er00,fibc,rms
  fibcoefs(*,0)=fibc
  fibcoefs(*,1)=-fibc
endif 
if(nfiba eq 3) then begin
  thar_xdisp_1,xp01,io01,ll01,er01,xp00,io00,ll00,er00,fibc0,rms0
; thar_xdisp,xp00,io00,ll00,er00,xp01,io01,ll01,er01,fibc0,rms0
  thar_xdisp_1,xp11,io11,ll11,er11,xp12,io12,ll12,er12,fibc1,rms1
  fibcoefs(*,0)=fibc0
  fibcoefs(*,1)=fibc1
endif

; save all the stuff that needs to be averaged into a returned structure.
; the rest of the data (for purposes of writing a fits file) goes to common
tripstruc={fibcoefs:fibcoefs,sinalpav:sinalpav,flav:flav,y0av:y0av,z0av:z0av,$
     coefsav:coefsav,lamav:lamav}

if(keyword_set(nofits)) then goto,fini

; write out FITS file
; The header of this file is complex, because it contains spectrograph
; parameters, rcubic fit coefficients, fibcoefs relating spectra from
; different fibers

; make creation date, output filename
;jd=systime(/julian)      ; file creation time, for sorting similar calib files
;mjd=jd-2400000.5d0
datereald=date_conv(jdd,'R')
datestrd=string(datereald,format='(f13.5)')
datestrd=datestrd+strlowcase(site)
fout='TRIP'+datestrd+'.fits'
filout=tripdir+fout
branch='trip/'

; make output header = 1st input header with mods, write out the data
mkhdr,hdrout,lamav
sxaddpar,hdrout,'MJD',mjdd
sxaddpar,hdrout,'NFRAVGD',2
sxaddpar,hdrout,'ORIGNAM0',fil01
sxaddpar,hdrout,'ORIGNAM1',fil12
sxaddpar,hdrout,'ORD0',mm_c(0)
sxaddpar,hdrout,'GRSPC',grspc_c
sxaddpar,hdrout,'SINALP',sinalpav
sxaddpar,hdrout,'FL',flav
sxaddpar,hdrout,'Y0',y0av
sxaddpar,hdrout,'Z0',z0av
sxaddpar,hdrout,'GLASS',gltype_c
sxaddpar,hdrout,'APEX',apex_c
sxaddpar,hdrout,'LAMCEN',lamcen_c
sxaddpar,hdrout,'ROT',rot_c
sxaddpar,hdrout,'PIXSIZ',pixsiz_c
sxaddpar,hdrout,'NX',nx_c
sxaddpar,hdrout,'NORD',nord_c
sxaddpar,hdrout,'NBLOCK',specdat.nblock
sxaddpar,hdrout,'NFIB',specdat.nfib
sxaddpar,hdrout,'NPOLY',specdat.npoly
sxaddpar,hdrout,'ORDWID',specdat.ordwid
sxaddpar,hdrout,'MEDBOXSZ',specdat.medboxsz

ncoefs=n_elements(coefsav)
sxaddpar,hdrout,'NCOEFS',ncoefs
di=['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14']
di2=[['00','10','20','30','40','50','60','70','80','90'],$
     ['01','11','21','31','41','51','61','71','81','91']]
for i=0,9 do begin
  pnam='COEFS'+di(i)
  sxaddpar,hdrout,pnam,coefsav(i)
endfor
for i=10,14 do begin
  pnam='COEFS'+di(i)
  if(ncoefs eq 15) then begin
    sxaddpar,hdrout,pnam,coefsav(i)
  endif else begin
    sxaddpar,hdrout,pnam,0.d0
  endelse
endfor

for i=0,1 do begin
  for j=0,9 do begin
    pnam='FIBCOE'+di2(j,i)
    sxaddpar,hdrout,pnam,fibcoefs(j,i)
  endfor
endfor
    
writefits,filout,lamav,hdrout
print,'FITS:',filout

; write line into standards.csv
stds_addline,'TRIPLE',branch+fout,2,site,camera,jdd,'0000'
print,'standards.csv',branch+fout

fini:

end
