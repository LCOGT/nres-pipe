pro avg_flat,flist,array=array
; This routine accepts the name flist of a file containing a list of pathnames 
; to files to be averaged. 
; If keyword array is set, flist is interpreted as a string array containg
; the filenames, eg
; ['flat/FLAT2015153.5243.fits','flat/FLAT2015161.5243.fits',....]
; It averages the indicated files, and writes the resulting
; super-FLAT into the appropriate directory.
; It adds a descriptive line to the standards.csv file.
; All input files must come from the same site and camera.
; This routine is intended to be called from an offline routine mk_supercal,
; not from muncha, hence it does not reference the nres_comm common block.
; The work is done by routine favg_line.pro, which does something sensible
; with flat data, namely decompose each input spectrum instance
; (ie, flux vs x for a given time sample, order and fiber) into a low- and a
; high-frequency part;  then average the low-frequency parts, and median the
; high-frequency parts, and sum them to give the output.
; If nfib=3 but only 2 fibers are represented in the input data, then
; the output for the missing fiber is a vector with all elements = 1.0

; constants
smwid=51                     ; smoothing width for low- high-pass split, in pix

; make pathnames
nresroot=getenv('NRESROOT')
root=nresroot+'reduced/'
flatdir=root+'flat/'
darkdir=root+'dark/'

; check 'array' keyword
if(keyword_set(array)) then begin
  files=flist
endif else begin
; read input file list
  openr,iun,flist,/get_lun
  files=['']
  ss=''
  while(not eof(iun)) do begin
    readf,iun,ss
    files=[files,strtrim(ss,2)]
  endwhile
  close,iun
  free_lun,iun
  files=files(1:*)
endelse
nfile=n_elements(files)

; read the data files and their headers
; get the first one, check each successive one for size, type, site, camera
fn=root+files(0)
dd=float(readfits(fn,hdr0))
nx=sxpar(hdr0,'NAXIS1')
nord=sxpar(hdr0,'NAXIS2')
nfib=sxpar(hdr0,'NAXIS3')
fib0=sxpar(hdr0,'FIB0')
obty=strtrim(sxpar(hdr0,'OBSTYPE'),2)
if(obty ne 'FLAT') then begin
  print,'OBSTYPE of '+files(0)+' is not FLAT in avg_flat'
  stop
endif
site=strtrim(sxpar(hdr0,'SITEID'),2)
camera=strtrim(sxpar(hdr0,'INSTRUME'),2)

; make data array, fill it up
datin=fltarr(nx,nord,nfib,nfile)
fib0a=intarr(nfile)
datin(*,*,*,0)=dd
fib0a(0)=fib0
for i=1,nfile-1 do begin
  fn=root+files(i)
  dd=float(readfits(fn,hdr))
  nxt=sxpar(hdr,'NAXIS1')
  nordt=sxpar(hdr,'NAXIS2')
  nfibt=sxpar(hdr,'NAXIS3')
  fib0t=sxpar(hdr,'FIB0')
  sitet=strtrim(sxpar(hdr,'SITEID'),2)
  camerat=strtrim(sxpar(hdr,'INSTRUME'),2)
  obtyt=strtrim(sxpar(hdr,'OBSTYPE'),2)
  if((nxt ne nx) or (nordt ne nord) or (sitet ne site) or (camerat ne camera) $
       or (obtyt ne obty) or (nfibt ne nfib)) then begin
    print,'Input file '+fn+' does not match 1st input file parameters'
    stop
  end
  datin(*,*,*,i)=dd
  fib0a(i)=fib0t
endfor

; average the input data arrays
; There are 2 cases -- nfib=2 or nfib=3.
; For nfib=2, all input images have both fibers illuminated, so an average
; over data from all files is appropriate.
; For nfib=3, for each input file either fibers 0,1 are illuminated, or 1,2.
; Thus fiber 1 output is an average over all times, fiber 0 is an average over
; only those times when fib0a=0, and fiber 2 averages only over times when
; fib0a=1.
datout=fltarr(nx,nord,nfib)
if(nfib eq 2) then begin        ; do the nfib=2 case
  for i=0,nord-1 do begin
    for j=0,nfib-1 do begin
      ddi=reform(datin(*,i,j,*),nx,nfile)
      ddo=favg_line(ddi,smwid)
      datout(*,i,j)=reform(ddo,nx,1,1)
    endfor
  endfor
endif

if(nfib eq 3) then begin        ; do the nfib=3 case
  s0=where(fib0a eq 0,ns0)
  s1=where(fib0a eq 1,ns1)

; do fibers 0,1,2 separately
; fiber 0
  for i=0,nord-1 do begin
    ddi=reform(datin(*,i,0,*),nx,nfile)
    if(ns0 gt 0) then begin
      ddi=ddi(*,s0)
      ddo=favg_line(ddi,smwid)
    endif else begin
      ddo=fltarr(nx)+1.
    endelse
    datout(*,i,0)=reform(ddo,nx,1,1)
  endfor

; fiber 1
  for i=0,nord-1 do begin
    ddi=reform(datin(*,i,1,*),nx,nfile)
    ddo=favg_line(ddi,smwid)
    datout(*,i,1)=reform(ddo,nx,1,1)
  endfor

; fiber 2
  for i=0,nord-1 do begin
    ddi=reform(datin(*,i,2,*),nx,nfile)
    if(ns1 gt 0) then begin
      ddi=ddi(*,s1)
      ddo=favg_line(ddi,smwid)
    endif else begin
      ddo=fltarr(nx)+1.
    endelse
    datout(*,i,2)=reform(ddo,nx,1,1)
  endfor

endif

; make creation date, output filename
jd=systime(/julian)      ; file creation time, for sorting similar calib files
mjd=jd-2400000.5d0
daterealc=date_conv(jd,'R')
datestrc=string(daterealc,format='(f13.5)')
fout='FLAT'+datestrc+'.fits'
filout=flatdir+fout
branch='flat/'

; make output header = 1st input header with mods, write out the data
sxaddpar,hdr0,'MJD',mjd
sxaddpar,hdr0,'NFRAVGD',nfile
sxaddpar,hdr0,'ORIGNAME',files(0)
; ##### make modified 'OBJECTS' keyword to cover all 3 fibers #####
writefits,filout,datout,hdr0

; add line to standards.csv
if(nfib eq 2) then cflg='0010' else cflg='0030' 
stds_addline,'FLAT',branch+fout,nfile,strtrim(site,2),strtrim(camera,2),jd,cflg

; print description of what was done
print,'Wrote FLAT file '+filout
print,'Average of ',nfile,' input files'
print,''

end
