pro avg_doub2trip,flist,tharlist=tharlist,array=array
; This routine combines a list of DOUBLE files into a single averaged
; TRIPLE file, saves the output into the /reduced/trip directory, and writes
; a summary line into the standards.csv file.
; To facilitate copying results into a new line in spectrographs.csv, it
; prints the spectrograph parms, coeffs, and fcoefs to the screen in a format
; suitable for cutting and pasting into spectrographs.csv.
; On input, flist = the name of an ascii file containing the list of names
; of the input files,
; which are to be found in the reduced/dble directory.
; If keyword array is set, it indicates that flist is a string array
; containing the names.
; No processing will be done unless input files conform to the following rules.
; There must be at least 2 files in the input list, and
; EITHER
; * All files must have flags(char2)=1 or all =2, indicating the active fibers
;    were either [0,1] or [1,2].
;    In this case, the routine makes a TRIPLE from each input file.
; OR
; * There must be an even number of input files, alternating between
;    flags(char2) =1 and flags(char2)=2.  In this case, the different flags
;    may come in either order, but they must strictly alternate.
;    In this case, the routine makes a triple from each pair of input files.
; Flags(char2) may not be 3.
;
; The routine then median-averages or (for few inputs) averages the parameters
; describing the intermediate triple files, and creates a final averaged TRIPLE
; from the result.  This file is written to reduced/trip, and a summary line
; is written to reduced/csv/standards.csv.

; get common blocks for NRES, ThAr fitting
@nres_comm
@thar_comm
common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun
jdc=systime(/julian)
tarlist=[]
; constants
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
reddir=nresrooti+'reduced/'
radian=180.d0/!pi 

; read flist if necessary, or copy to array 'files'
if(keyword_set(array)) then begin
  files=flist
endif else begin
  files=['']
  ss=''
  openr,iun,flist,/get_lun
  while(not eof(iun)) do begin
    readf,iun,ss
    files=[files,strtrim(ss,2)]
  endwhile
  close,iun
  free_lun,iun
  files=files(1:*)
endelse

; match input list with standards.csv to get flag values, site name
; in the process check that all images come from same site.
stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr
nfile=n_elements(files)
flag2=intarr(nfile)
for i=0,nfile-1 do begin
  s=where(fnames eq files(i),ns)
  if(ns ne 1) then begin
    print,'input DOUBLE file not found in standards.csv  ',files(i)
    print,'avg_doub2trip FAIL'
    goto,fini
  endif else begin
    flag2(i)=fix(strmid(flags(s),2,1))
    if(i eq 0) then begin
      site=sites(s)
      site=site(0)
      s0name=fnames(s)
    endif
    if(i gt 0) then begin
      if(site ne sites(s)) then begin
        print,'Not all images from same site in avg_doub2trip ',fnames(s)
        goto,fini
      endif
    endif
  endelse
endfor

; read first input file, move useful data from header into nres_comm
pathname=reddir+s0name
dd=readfits(pathname,dblehdr0,/silent)
mjdd=sxpar(dblehdr0,'MJD-OBS')

; use site name to find nfib value for these data from spectrographs.csv
get_specdat,mjdd,err
nfib=specdat.nfib

; check to see that rules for input list are obeyed
opt=0                 ; -> rule failure unless proved othewise
if(max(abs(flag2-1)) eq 0) then opt=1      ; -> flags all=1.
if(max(abs(flag2-2)) eq 0) then opt=2      ; -> flags all=2.
if(opt eq 0) then begin                    ; test for alternating
  if((nfile mod 2) eq 0) then begin        ; yes if even number of files
    flag22=reform(flag2,2,nfile/2)
    fdif=flag22(0,*)-flag22(1,*)
    if(max(abs(fdif+1)) eq 0) then opt=3   ; alternates 0,1,0,1...
    if(max(abs(fdif-1)) eq 0) then opt=4   ; alternates 1,0,1,0...
  endif
endif

if(opt eq 0) then begin
  print,'input files do not obey rules.'
  print,'avg_doub2trip FAIL'
  goto,fini
endif

; process input files individually.  Output is an array of structures, each
; of which contains all of the information in a TRIPLE file.
; also retain list of input files, to be written into header

; do case of list with either flags(char2)=1 or =2
if(opt eq 1 or opt eq 2) then begin
  for i=0,nfile-1 do begin
    fil01=files(i)
    fil12=fil01
    if(nfib eq 3) then force=1 else force=0
    thar_triple,fil01,fil12,tripstruc,rms,force2=force,/cubfrz,/nofits,$
       tharlist=tharlist
    if(i eq 0) then outs=[tripstruc] else outs=[outs,tripstruc]
    if(i eq 0) then filinp=[fil01,fil12] else filinp=[filinp,fil01,fil12]
  endfor
endif

; do case of alternating flags(char2)=1,2
if(opt eq 3 or opt eq 4) then begin
  nfileh=nfile/2
  for i=0,nfileh-1 do begin
    if(opt eq 3) then begin
      fil01=files(2*i)
      fil12=files(2*i+1)
    endif else begin
      fil01=files(2*i+1)
      fil12=files(2*i)
    endelse
    thar_triple,fil01,fil12,tripstruc,rms,force2=force,/cubfrz,/nofits
    if(i eq 0) then outs=[tripstruc] else outs=[outs,tripstruc]
    if(i eq 0) then filinp=[fil01,fil12] else filinp=[filinp,fil01,fil12]
  endfor

endif
nfilinp=n_elements(filinp)

; build the output data from an appropriate average over structure elements
ns=n_elements(outs)
if(ns eq 1) then begin
  fibcoefs=outs.fibcoefs
  sinalpav=outs.sinalpav
  flav=outs.flav
  y0av=outs.y0av
  z0av=outs.z0av
  coefsav=outs.coefsav
endif
if(ns ge 2 and ns le 4) then begin
  fibcoefs=mean(outs(*).fibcoefs,dimension=3)
  sinalpav=mean(outs(*).sinalpav)
  flav=mean(outs(*).flav)
  y0av=mean(outs(*).y0av)
  z0av=mean(outs(*).z0av)
  coefsav=mean(outs(*).coefsav,dimension=2)
endif
if(ns gt 4) then begin
  fibcoefs=median(outs(*).fibcoefs,dimension=3)
  sinalpav=median(outs(*).sinalpav)
  flav=median(outs(*).flav)
  y0av=median(outs(*).y0av)
  z0av=median(outs(*).z0av)
  coefsav=median(outs(*).coefsav,dimension=2)
endif

; make wavelength scale from averaged parameters
xx=pixsiz_c*(dindgen(nx_c)-nx_c/2.d0)
fibno=1
specstruc={grspc:grspc_c,gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,$
    rot:rot_c,sinalp:sinalpav,fl:flav,y0:y0av,z0:z0av,coefs:coefsav,$
    ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
lambda3ofx,xx,mm_c,fibno,specstruc,lamav,y0m,air=0

; write the output fits file
; The header of this file is complex, because it contains spectrograph
; parameters, rcubic fit coefficients, fibcoefs relating spectra from
; different fibers

; make data date, output filename
jdc=systime(/julian)      ; file creation time, for sorting similar calib files
mjdc=jdc-2400000.5d0      ; mjdc for mjd_current
datereald=date_conv(jdd+.0001,'R')
datestrd=string(datereald,format='(f13.5)')
datestrd=strlowcase(site)+datestrd
fout='TRIP'+datestrd+'.fits'
filout=tripdir+fout
branch='trip/'

combined_filenames = []
for i=0,nfile-1 do begin
  fits_read,reddir+files[i],data, this_header
  combined_filenames = [combined_filenames, get_output_name(this_header)]
endfor

; make output header = 1st input header with mods, write out the data
fits_read,reddir+files[-1],data, hdrout
update_data_size_in_header, hdrout, lamav
sxaddpar,hdrout,'OBSTYPE', 'ARC'
set_output_calibration_name, hdrout, 'arc'
sxaddpar,hdrout, 'L1PUBDAT', sxpar(hdrout,'DATE-OBS')
sxaddpar,hdrout,'RLEVEL', 91

save_combined_images_in_header, hdrout, combined_filenames

sxaddpar,hdrout,'MJD',mjdd+.0001
sxaddpar,hdrout,'NFRAVGD',nfile
for i=0,nfilinp-1 do begin
  strdig=strtrim(string(i),2)
  if(strlen(strdig) eq 1) then strdig='0'+strdig
  keynam='ORGNAM'+strdig
  sxaddpar,hdrout,keynam,filinp(i)
endfor
;sxaddpar,hdrout,'ORIGNAM0',fil01
;sxaddpar,hdrout,'ORIGNAM1',fil12
sxaddpar,hdrout,'ORD0',mm_c(0)
sxaddpar,hdrout,'GRSPC',grspc_c
sxaddpar,hdrout,'SINALP',sinalpav
sxaddpar,hdrout,'DSINALP',dsinalp_c
sxaddpar,hdrout,'FL',flav
sxaddpar,hdrout,'DFL',dfl_c
sxaddpar,hdrout,'Y0',y0av
sxaddpar,hdrout,'DY0',dy0_c
sxaddpar,hdrout,'Z0',z0av
sxaddpar,hdrout,'DZ0',dz0_c
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

; put the output file into a tarfile for archiving
fpack_stacked_calibration,filout, sxpar(hdrout, 'OUTNAME')

print,'TRIPLE file written to ',filout

; write line into standards.csv
case opt of
  0: flg='0000'
  1: flg='0010'
  2: flg='0020'
  3: flg='0030'
  4: flg='0030'
endcase


stds_addline,'TRIPLE',branch+fout,2,site,camera,sxpar(hdrout,'MJD-OBS') + 0.001d + 2400000.5d,flg

; write out log information.
print,'*** avg_doub2trip ***'
print,'Files In = '
for i=0,nfile-1 do begin
  print,files(i)
endfor
naxes=sxpar(hdrout,'NAXIS')
nx=sxpar(hdrout,'NAXIS1')
ny=sxpar(hdrout,'NAXIS2')
print,'Naxes, Nx, Ny = ',naxes,nx,ny
print,'Wrote file to trip/ dir:'
print,branch+fout
print,'Added line to reduced/csv/standards.csv'
print,'Points to '+branch+fout
print
print
print,'Values for spectrographs.csv'
print,'GrInc,dGrInc,FL,dFL,Y0,dY0,Z0,dZ0'
alp=asin(sinalpav)*radian
dalp=0.01
fvals=[alp,dalp,flav,dfl_c,y0av,dy0_c,z0av,dz0_c]
svals=string(fvals,format='(f13.8)')
svals=svals+','
print,svals,format='(8a14)'
scoefs=string(coefsav,format='(e16.8)')
scoefs=scoefs+','
print,scoefs,format='(15a17)'
sfibc=string(reform(fibcoefs,20),format='(e16.8)')
sfibc=sfibc+','
print,sfibc,format='(20a17)'
print

fini:

end
