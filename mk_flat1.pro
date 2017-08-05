pro mk_flat1
; This routine makes a flat-field spectrum from the current extracted
; spectrum in nres common, presumably one of type 'DOUBLE'.
; If nfib=2, then a flat of dimension (nx,nord,2) is created.
; If nfib=3, then a flat of dimension (nx,nord,3) is created, but only
; the 2 orders indicated by fib0 and fib1 have real data;  the other is
; filled with zeros.
; The output flat field is stored in nres common, and also is written
; as a FITS file to reduced/flat, with a corresponding line added to
; the reduced/csv/standards.csv file.

@nres_comm

; constants
rutname='mk_flat1'
flatmin=0.01                ; minimum interesting value of flat
snmin=0.05                  ; minimum interesting S/N for flat
nsmrms=51                   ; rms smoothing to look for bad data
nmedian=11                  ; median smoothing for determining max value

; make output array
nx=specdat.nx
nord=specdat.nord
nfib=specdat.nfib
flat=fltarr(nx,nord,nfib)
parmstr=string(nx)+' '+string(nord)+' '+string(nfib)+' '+string(fib0)
logo_nres2,rutname,'INFO','inparms = '+parmstr

rmsspec=echdat.specrms

; set to zero all points where flat le flatmin or where S/N le snmin
sg=where((rmsspec le 1.e4) and (rmsspec gt 0.),nsg)
sn=fltarr(nx,nord,nfib)
sn(sg)=corspec(sg)/rmsspec(sg)

; normalize flats to unity at max of median-filtered raw spectrum,
; but stay away from the edges
jf=[fib0,fib1]
if(mfib eq 3 and fib1 eq 2) then jf=[1,2,0]
if(mfib eq 3 and fib1 eq 1) then jf=[0,1,2]
for i=0,nord-1 do begin
  for j=0,mfib-1 do begin
    dat=corspec(*,i,j)
    flatt=fltarr(nx)
; bad data rejection
    mdat=median(dat,nmedian)
    mdat(0:3)=mdat(4)
    mdat(nx-4:nx-1)=mdat(nx-5)
    mdif=dat-mdat
    mrms=smooth(mdif^2,nsmrms,/edge_truncate)
    sbad=where((corspec(*,i,j) le 0.) or (abs(mdif) ge 5.*mrms),nsbad) 
    if(nsbad gt 0) then dat(sbad)=mdat(sbad)
    md=max(mdat(nsmrms:nx-nsmrms-1))
    flatt=dat/md
    s=where(flatt le flatmin or sn(*,i,j) le snmin,ns)
    if(ns gt 0) then flatt(s)=0.
    flat(*,i,jf(j))=flatt
  endfor
endfor

;jd=systime(/julian)      ; file creation time, for sorting similar trace files
;mjd=jd-2400000.5d0
;daterealc=date_conv(jd,'R')
;datestrc=string(daterealc,format='(f13.5)')
fout='FLAT'+datestrd+'.fits'
filout=nresrooti+flatdir+fout

; make header for FITS file
;mkhdr,hdr,flat
hdr = dathdr
update_data_size_in_header, hdr, flat

nfravg=1
sxaddpar,hdr,'MJD',mjdc,'Creation date'
sxaddpar,hdr,'MJD-OBS',mjdd,'Data date'
sxaddpar,hdr,'NFRAVGD',nfravg,'Avgd this many frames'
sxaddpar,hdr,'ORIGNAME',strip_fits_extension(filname),'Original raw filename'
sxaddpar,hdr,'SITEID',site
sxaddpar,hdr,'INSTRUME',camera
sxaddpar,hdr,'OBSTYPE',type
sxaddpar,hdr,'EXPTIME',exptime
sxaddpar,hdr,'OBSTYPE',type
sxaddpar,hdr,'FIB0',fib0
sxaddpar,hdr,'FIB1',fib1

; and write it out
speco='FLAT'+datestrd+'.fits'
objects=sxpar(dathdr,'OBJECTS')
sxaddpar,hdr,'OBJECTS',objects
specout=nresrooti+'/'+flatdir+speco
writefits,filout,flat,hdr
logo_nres2,rutname,'INFO','WRITE '+filout

; add line to standards.csv
; use 3rd flag character to show which fibers are active:
; [0,1] -> 1, [1,2] -> 2, [0,1,2] -> 3
cflg='0000'
if(fib0 eq 0) then cflg='0010'
if(fib0 eq 1) then cflg='0020' 
stds_addline,'FLAT','flat/'+fout,1,strtrim(site,2),strtrim(camera,2),jdd,cflg
logo_nres2,rutname,'INFO','ADDLINE standards.csv'

end
