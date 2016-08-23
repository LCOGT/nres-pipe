pro avg_doub2trip,flist
; This routine combines a list of DOUBLE files into a single averaged
; TRIPLE file, saves the output into the /reduced/trip directory, and writes
; a summary line into the standards.csv file.
; On input, flist = string array containing the names of the input files,
; which are to be found in the reduced/dble directory.
; No processing will be done unless these files conform to the following rules.
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

; constants
nresroot=getenv('NRESROOT')
dbledir=nresroot+'reduced/dble/'
tripdir=nresroot+'reduced/trip/'

; match input list with standards.csv to get flag values, site name
; in the process check that all images come from same site.
stds_rd,types,fnames,navgs,sites,cameras,jdates,flags,stdhdr
nfile=n_elements(flist)
flag2=intarr(nfile)
for i=0,nfile-1 do begin
  s=where(fnames eq flist(i),ns)
  if(ns ne 1) then begin
    print,'input DOUBLE file not found in standards.csv  ',flist(i)
    print,'avg_doub2trip FAIL'
    goto,fini
  endif else begin
    flag2(i)=fix(strmid(flags(s),2,1))
    if(i eq 0) then begin
      site=sites(s)
      s0name=fnames(0)
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
pathname=nresroot+dbldir+s0name
dd=readfits(pathname,dblehdr0)
mjd=sxpar(dblehdr0,'MJD-OBS')

; use site name to find nfib value for these data from spectrographs.csv
get_specdat,mjd,err

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

; do case of list with either flags(char2)=1 or =2
if(opt eq 1 or opt eq 2) then begin
  for i=0,nfile-1 do begin
    fil01=files(i)
    fil12=fil01
    if(nfib eq 3) then force=1 else force=0
    thar_triple,fil01,fil12,tripstruc,rms,force2=force,/cubfrz,/nofits
    if(i eq 0) then outs=[tripstruc] else outs=[outs,tripstruc]
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
  endfor

endif

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
if(ns gt 1 and ns le 4) then begin
  fibcoefs=mean(outs(*).fibcoefs,dimension=3)
  sinalpav=mean(outs(*).sinalpav,dimension=3)
  flav=mean(outs(*).flav,dimension=3)
  y0av=mean(outs(*).y0av,dimension=3)
  z0av=mean(outs(*).z0av,dimension=3)
  coefsav=mean(outs(*).coefsav,dimension=3)
endif else begin
  fibcoefs=median(outs(*).fibcoefs,dimension=3)
  sinalpav=median(outs(*).sinalpav,dimension=3)
  flav=median(outs(*).flav,dimension=3)
  y0av=median(outs(*).y0av,dimension=3)
  z0av=median(outs(*).z0av,dimension=3)
  coefsav=median(outs(*).coefsav,dimension=3)
endelse

; make wavelength scale from averaged parameters
xx=pixsiz_c*(dindgen(nx)-nx/2.d0)
mm=ord0+lindgen(nord_c)
fibno=1
specstruc={d:grspc_c,gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,rot:rot_c,$
    sinalp:sinalpav,fl:flav,y0:y0av,z0:z0av,coefs:coefsav}
lambda3ofx,xx,mm,fibno,specstruc,lam,y0m,air=0

; write the output fits file
; The header of this file is complex, because it contains spectrograph
; parameters, rcubic fit coefficients, fibcoefs relating spectra from
; different fibers

; make creation date, output filename
; ### should change creation date to data date ###
jd=systime(/julian)      ; file creation time, for sorting similar calib files
mjd=jd-2400000.5d0
daterealc=date_conv(jd,'R')
datestrc=string(daterealc,format='(f13.5)')
fout='TRIP'+datestrc+'.fits'
filout=tripdir+fout
branch='trip/'

; make output header = 1st input header with mods, write out the data
mkhdr,hdrout,lamav
sxaddpar,hdrout,'MJD',mjd
sxaddpar,hdrout,'NFRAVGD',nfile
sxaddpar,hdrout,'ORIGNAM0',fil01
sxaddpar,hdrout,'ORIGNAM1',fil12
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

; write line into standards.csv
stds_addline,'TRIPLE',branch+fout,2,site,camera,jd,'0000'

; optionally write out log information.

end
