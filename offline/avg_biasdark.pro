pro avg_biasdark,type,flist,array=array
; This routine accepts a calibration image type, either 'BIAS' or 'DARK',
; and the name of a list of files to be averaged.
; If keyword array is set, then flist is interpreted as
; the list of pathnames to files to be averaged, eg
; ['dark/DARK2015153.5243.fits','dark/DARK2015161.5243.fits',....]
; It median-averages the indicated files, and writes the resulting
; super-BIAS or super-DARK into the appropriate directory.
; It adds a descriptive line to the standards.csv file.
; All input files must come from the same site and camera.
; This routine is intended to be called from an offline routine mk_supercal,
; not from muncha, hence it does not reference the nres_comm common block.

; make pathnames
nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
root=nresrooti+'reduced/'
biasdir=root+'bias/'
darkdir=root+'dark/'

; check that type is okay
if(type ne 'BIAS' and type ne 'DARK') then begin
  print,'Input parameter type must be BIAS or DARK'
  stop
endif

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
ny=sxpar(hdr0,'NAXIS2')
obty=strtrim(sxpar(hdr0,'OBSTYPE'),2)
if(obty ne strtrim(type,2)) then begin
  print,'OBSTYPE of '+files(0)+' does not match requested type '+type
  stop
endif
site=strtrim(sxpar(hdr0,'SITEID'),2)
camera=strtrim(sxpar(hdr0,'INSTRUME'),2)
mjdd=sxpar(hdr0,'MJD-OBS')

; make data array, fill it up
datin=fltarr(nx,ny,nfile)
datin(*,*,0)=dd
gooddat=lonarr(nfile)
gooddat(0)=1
for i=1,nfile-1 do begin
  fn=root+files(i)
  dd=float(readfits(fn,hdr))
  nxt=sxpar(hdr,'NAXIS1')
  nyt=sxpar(hdr,'NAXIS2')
  sitet=strtrim(sxpar(hdr,'SITEID'),2)
  camerat=strtrim(sxpar(hdr,'INSTRUME'),2)
  obtyt=strtrim(sxpar(hdr,'OBSTYPE'),2)
  if((nxt ne nx) or (nyt ne ny) or (sitet ne site) or (camerat ne camera) $
       or (obtyt ne obty)) then begin
    print,'Input file '+fn+' does not match 1st input file parameters'
    gooddat(i)=0
  endif else begin
    gooddat(i)=1
    datin(*,*,i)=dd
  endelse
endfor
sg=where(gooddat eq 1,nsg)
if(nsg gt 0) then begin
  datin=datin(*,*,sg)
  nfile=nsg
endif else begin
  print,'No good files found in avg_biasdark'
  type='none'
  filout='none'
  nfile=0
  goto,fini
endelse

; median average over the input data arrays
datout=median(datin,dimension=3)

; make date of 1st input file, output filename
;jd=systime(/julian)      ; file creation time, for sorting similar calib files
;mjd=jd-2400000.5d0
jdd=mjdd+2400000.5d0
datereald=date_conv(jdd+.0001,'R')        ; add eps to avoid overwriting input
datestrd=string(datereald,format='(f13.5)')
datestrd=strlowcase(site)+datestrd
fout=type+datestrd+'.fits'
case type of
  'BIAS': begin
    filout=biasdir+fout
    branch='bias/'
    end
  'DARK': begin
    filout=darkdir+fout
    branch='dark/'
    end
endcase

; make output header = 1st input header with mods, write out the data
;sxaddpar,hdr0,'MJD',mjd
sxaddpar,hdr0,'MJD-OBS',mjdd
sxaddpar,hdr0,'NFRAVGD',nfile
sxaddpar,hdr0,'ORIGNAME',files(0)
writefits,filout,datout,hdr0

; add line to standards.csv
cflg='0000'
stds_addline,type,branch+fout,nfile,strtrim(site,2),strtrim(camera,2),jdd,cflg

; print info about what was done
fini:
print,'Wrote ',type,' file '+filout
print,'Average of ',nfile,' input files'
print,''

end
