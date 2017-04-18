pro thar_wavelen,dbg=dbg,trp=trp,tharlist=tharlist,cubfrz=cubfrz,$
  oskip=oskip
; This routine takes the extracted spectrum in common structure echdat,
; spectrograph information from the file reduce/spectrographs.csv,
; and ThAr line list from file reduce/config/tharlist.txt
; to compute a wavelength map lam(nx,nord,nfib), where nfib is the
; number of fibers into the spectrograph, but only those tagged as ThAr get
; data.
; If there are no such fibers, an empty array lam(1,1,1) is returned.
;
; On return, results are found in the common structure tharred.
; In particular, lam_all(nx,nord,nfib) contains the wavelength solution
; for each fiber i = {0 to nfib-1}.  If sinalp_all(i) ne 0., then this
; function was determined by fitting a ThAr spectrum in the corresponding
; fiber.  If sinalp_all(i) = 0, then the wavelength solution is formed by
; using fibcoefs_c to extrapolate from fiber = 1.
; 
; If keyword dbg is set, then a plot is produced and sent to the console
; showing the residual errors of fits to ThAr spectra.
; If keyword trp is set and not zero, either or both of coefs_c and 
; fibcoefs_c are taken from spectrographs.csv, not from TRIPLE file.
; If keyword cubfrz is set, then rcubic coefficients are frozen when
; thar_fitall is run.
; If keyword oskip is set and not zero, then order oskip is skipped in
; the wavelength solution.  Used in testing for bad lines.

@nres_comm

@thar_comm

common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun

; constants, header data
ncoefs_c=15            ; number of coefs for restricted cubic fits
jd=sxpar(dathdr,'MJD-OBS')+2400000.5d0
;nresroot=getenv('NRESROOT')
matchedlines=nresrooti+'reduced/config/mtchThAr.txt' ; name of output file
                           ; for well-matched ThAr lines

; want lamp IDs, etc too

; find number of ThAr fibers
objects=sxpar(dathdr,'OBJECTS')
words=get_words(objects,nwd,delim='&')
sth=where(strtrim(strupcase(words),2) eq 'THAR',nsth)
if(words(0) eq 'NONE') then sth=sth-1        ; deal with leading 'NONE'

; if none, set defaults and return

if(nsth le 0) then begin
  lam=fltarr(1,1,1)
  goto,fini
endif

; otherwise make output arrays
;dat=echdat.spectrum
nx=specdat.nx
nord=specdat.nord
nfib=specdat.nfib
sinalp_all=dblarr(nfib)
fl_all=dblarr(nfib)
y0_all=dblarr(nfib)
z0_all=dblarr(nfib)
lam_all=dblarr(nx,nord,nfib)
coefs_all=fltarr(ncoefs_c,nfib)
sgsite=strtrim(strupcase(site),2)
nmatch_all=lonarr(nfib)
amoerr_all=fltarr(nfib)
rmsgood_all=fltarr(nfib)
mgbdisp_all=dblarr(nfib)
lammid_all=dblarr(nfib)

; loop over ThAr fibers
for ifib=0,nsth-1 do begin
  fibdat=sth(ifib)             ; desired index into dat array

;  deal with case in which we have 3 fibers, with fiber 0 not illuminated
  if(nfib eq 3 and mfib eq 2 and fib0 eq 1) then fibdat=fibdat-1

  fibindx=fibdat+fib0          ; index of this fiber, with 1 always reference
  tharspec_c=corspec(*,*,fibdat)

; put input data into desired format

; call thar_fitall.pro to do the work
  thar_fitall,sgsite,fibindx,ierr,trp=trp,tharlist=tharlist,cubfrz=cubfrz,$
    oskip=oskip

; put results into output arrays
  lam_all(*,*,fibindx)=lam_c
  sinalp_all(fibindx)=sinalp_c
  fl_all(fibindx)=fl_c
  y0_all(fibindx)=y0_c
  z0_all(fibindx)=z0_c
  coefs_all(*,fibindx)=coefs_c
  nmatch_all(fibindx)=nmatch_c
  amoerr_all(fibindx)=sqrt(dlam2_c)
  rmsgood_all(fibindx)=rms_c
  mgbdisp_all(fibindx)=mgbdisp_c
  lammid_all(fibindx)=lammid_c

; fill lam_all with wavelengths for all fibers.
specstruc={gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,grinc:grinc_c,$
   grspc:grspc_c,rot:rot_c,sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c,$
    coefs:coefs_c,ncoefs:ncoefs_c,fibcoefs:fibcoefs_c}
xx=pixsiz_c*(dindgen(nx_c)-nx_c/2.)
for i=0,nfib-1 do begin
  if(sinalp_all(i) eq 0.) then begin
    lambda3ofx,xx,mm_c,i,specstruc,lam_t,y0m_t,air=0    ; always vacuum lam
    lam_all(*,*,i)=lam_t
  endif
endfor

  if(keyword_set(dbg)) then begin
    dellam=matchbest_c-matchlam_c+matchdif_c
    ndellam=n_elements(dellam)
    quartile,dellam,med,q,dq
    sgood=where(abs(dellam) le 5./1.35*dq,nsgood)
    rmsall=stddev(dellam)
    rmsgood=stddev(dellam(sgood))
    print,'Ndellam, Nsgood = ',ndellam,nsgood
    print,'RMSall, RMSgood = ',rmsall,rmsgood, '(nm)'
    xtit='Lambda (nm)'
    ytit='Fit Err (nm)'
    tit='Fiber '+strtrim(string(fibindx),2)
    plot,matchline_c,dellam,psym=3,tit=tit,xtit=xtit,ytit=ytit,charsiz=1.5
    stop
;   plot,inmatch(0:niter_c-1),tit='inmatch',xtit='iter',ytit='matches',$
;       charsiz=1.5,/ynoz
;   stop
;   plot,isalp(0:niter_c-1),tit='sinalp',xtit='iter',ytit='sinalp',$
;       charsiz=1.5,/ynoz
;   stop
;   plot,ifl(0:niter_c-1),tit='fl',xtit='iter',ytit='fl',$
;       charsiz=1.5,/ynoz
;   stop
;   plot,iy0(0:niter_c-1),tit='y0',xtit='iter',ytit='y0',$
;       charsiz=1.5,/ynoz
;   stop
;   plot,iz0(0:niter_c-1),tit='z0',xtit='iter',ytit='z0',$
;       charsiz=1.5,/ynoz
;   stop
;   plot,alog10(ifun(0:niter_c-1)),tit='fun',xtit='iter',ytit='log fun',$
;       charsiz=1.5,/ynoz
;   stop

; use keyboard entries and cursor clicks to identify unique well-matched ThAr
; standard lines.
    ss=''
    print,'Select good lines? Y/N'
    read,ss
    if(strupcase(strtrim(ss,2)) eq 'Y') then begin
      print,'Click on 7 (x,y) points to define good curve'
      xd=fltarr(7)
      yd=fltarr(7)
      for k=0,6 do begin
        cursor,x,y,3
        xd(k)=x
        yd(k)=y
      endfor

; fit quartic polynomial to these points, plot it
    xmin=min(matchline_c)
    xmax=max(matchline_c)
    xmid=(xmax-xmin)/2.
    cc=poly_fit(xd-xmid,yd,4)
    yy=poly(matchline_c-xmid,cc)
    del=dellam-yy
    oplot,matchline_c,yy

; get a tolerance value from the user, identify points within tolerance,
; oplot these points.
    print,'Enter acceptance tolerance (nm)'
    read,tol
    sp=where(abs(del) le tol,nsp)
    if(nsp gt 0) then begin
      matchline_c=matchline_c(sp)
      dellam=dellam(sp)
      som=sort(matchline_c)
      matchline_c=matchline_c(som)
      dellam=dellam(som)
      somu=uniq(matchline_c)
      matchline_c=matchline_c(somu)
      dellam=dellam(somu)
      oplot,matchline_c,dellam,psym=1,symsiz=.6,thick=3
    endif

; write this list of unique standard ThAr lines to a new standard list.
    sol=sort(matchline_c)
    mtc=matchline_c(sol)
    umtc=uniq(mtc)
    mtc=mtc(umtc)      ; contains only unique lines, in wavelength order
; search linelam_c for match to lines in mtc, get corresp amplitudes
    nmtc=n_elements(mtc)
    mtca=fltarr(nmtc)
    for mm=0,nmtc-1 do begin
      difl=abs(linelam_c-mtc(mm))
      minl=min(difl,ixl)
      if(minl le 2.e-6) then mtca(mm)=lineamp_c(ixl)
    endfor

    openw,iunm,matchedlines,/get_lun      ; open matchedlines for writing
    nmtc=n_elements(mtc)
    printf,iunm,'Selected ThAr lines from thar_wavelen + dbg.  Vacuum Ritz lam'
    printf,iunm,'lambda(nm)    Bright'
    for k=0,nmtc-1 do begin
      printf,iunm,mtc(k),mtca(k),format='(f11.6,2x,f7.0)'
    endfor
    close,iunm
    free_lun,iunm
    endif

; generate coefs polynomial, fiber shift poly.
  lam_polynoms,ifib,plam,fib_poly

  endif
endfor

; make the output structure

tharred={fibth:sth,lam:lam_all,sinalp:sinalp_all,fl:fl_all,y0:y0_all,$
      z0:z0_all,coefs:coefs_all,nmatch:nmatch_all,amoerr:amoerr_all,$
      rmsgood:rmsgood_all,mgbdisp:mgbdisp_all,lammid:lammid_all,$
      site:site,jd:jd}

;stop

; Write the contents of this structure out as a multi-extension fits file,
; with lam(nx,nord,nfib) as the main table, sgparms(4,nfib) as the first
; binary table, and sgcoefs(ncoef,nfib) as the 2nd binary table.`

sgparms=dblarr(4,nfib)
sgparms(0,0:nfib-1)=reform(sinalp_all,1,nfib)
sgparms(1,0:nfib-1)=reform(fl_all,1,nfib)
sgparms(2,0:nfib-1)=reform(y0_all,1,nfib)
sgparms(3,0:nfib-1)=reform(z0_all,1,nfib)

sz=size(coefs_all)
ncoefs=sz(1)
sgcoefs=coefs_all

; write the wavelength file to thardir as a FITS file
; make the header and fill it out
mkhdr,hdr,lam_all
fxhmake,hdr,lam_all,/extend
fxaddpar,hdr,'MJD',mjdc,'Creation date'
fxaddpar,hdr,'NFRAVGD',1,'Avgd this many frames'
fxaddpar,hdr,'ORIGNAME',filname,'1st filename'
fxaddpar,hdr,'SITEID',site
fxaddpar,hdr,'INSTRUME',camera
fxaddpar,hdr,'OBSTYPE','THAR' 
fxaddpar,hdr,'EXPTIME',exptime

tharo='THAR'+datestrc+'.fits' 
tharout=nresrooti+thardir+tharo
;writefits,tharout,lam,hdr
;stds_addline,'THAR',tharo,1,site,camera,jdc,'0000'
fxwrite,tharout,hdr,lam_all

fxbhmake,hdr,nfib          ; make an extension header for nrow table
dum=dblarr(nfib)             ; dummy data array with length of columns
fxbaddcol,ind1,hdr,dum(0),'SINALP','Sin(alpha)'
fxbaddcol,ind2,hdr,dum(0),'FL','Focal Length (mm)'
fxbaddcol,ind3,hdr,dum(0),'Y0','Y0 (mm)'
fxbaddcol,ind4,hdr,dum(0),'Z0','Z0 - 1.'

fxbcreate,unit,tharout,hdr,ext1
fxbwritm,unit,['SINALP','FL','Y0','Z0'],reform(sgparms(0,*),nfib),$
  reform(sgparms(1,*),nfib),reform(sgparms(2,*),nfib),$
  reform(sgparms(3,*),nfib)

fxbfinish,unit

fxbhmake,hdr,nfib          ; make an extension header for 2nd nrow table
dum=fltarr(nfib)
fxbaddcol,jn1,hdr,dum(0),'C00','Coefs(0)'
fxbaddcol,jn2,hdr,dum(0),'C01','Coefs(1)'
fxbaddcol,jn3,hdr,dum(0),'C02','Coefs(2)'
fxbaddcol,jn4,hdr,dum(0),'C03','Coefs(3)'
fxbaddcol,jn5,hdr,dum(0),'C04','Coefs(4)'
fxbaddcol,jn6,hdr,dum(0),'C05','Coefs(5)'
fxbaddcol,jn7,hdr,dum(0),'C06','Coefs(6)'
fxbaddcol,jn8,hdr,dum(0),'C07','Coefs(7)'
fxbaddcol,jn9,hdr,dum(0),'C08','Coefs(8)'
fxbaddcol,jn10,hdr,dum(0),'C09','Coefs(9)'
fxbaddcol,jn11,hdr,dum(0),'C10','Coefs(10)'
fxbaddcol,jn12,hdr,dum(0),'C11','Coefs(11)'
fxbaddcol,jn13,hdr,dum(0),'C12','Coefs(12)'
fxbaddcol,jn14,hdr,dum(0),'C13','Coefs(13)'
fxbaddcol,jn15,hdr,dum(0),'C14','Coefs(14)'

fxbcreate,unit,tharout,hdr,ext2
fxbwritm,unit,['C00','C01','C02','C03','C04','C05','C06','C07','C08',$
  'C09','C10','C11','C12','C13','C14'],$
  reform(sgcoefs(0,*),nfib),reform(sgcoefs(1,*),nfib),$
  reform(sgcoefs(2,*),nfib),reform(sgcoefs(3,*),nfib),$
  reform(sgcoefs(4,*),nfib),reform(sgcoefs(5,*),nfib),$
  reform(sgcoefs(6,*),nfib),reform(sgcoefs(7,*),nfib),$
  reform(sgcoefs(8,*),nfib),reform(sgcoefs(9,*),nfib),$
  reform(sgcoefs(10,*),nfib),reform(sgcoefs(11,*),nfib),$
  reform(sgcoefs(12,*),nfib),reform(sgcoefs(13,*),nfib),$
  reform(sgcoefs(14,*),nfib)

fxbfinish,unit

; make an extension header for 3rd table, containing info about the
; matched ThAr lines.
nels=nmatch_c > 1
fxbhmake,hdr,nels
dum0=fltarr(nels)
dum1=dblarr(nels)
dum2=lonarr(nels)
fxbaddcol,kn1,hdr,dum1(0),'matchlam','matchlam'
fxbaddcol,kn2,hdr,dum0(0),'matchamp','matchamp'
fxbaddcol,kn3,hdr,dum0(0),'matchwid','matchwid'
fxbaddcol,kn4,hdr,dum1(0),'matchline','matchline'
fxbaddcol,kn5,hdr,dum0(0),'matchxpos','matchxpos'
fxbaddcol,kn6,hdr,dum2(0),'matchord','matchord'
fxbaddcol,kn7,hdr,dum0(0),'matcherr','matcherr'
fxbaddcol,kn8,hdr,dum1(0),'matchdif','matchdif'
fxbaddcol,kn9,hdr,dum1(0),'matchwts','matchwts'
fxbaddcol,kn10,hdr,dum1(0),'matchbest','matchbest'

fxbcreate,unit,tharout,hdr,ext3
fxbwritm,unit,['matchlam','matchamp','matchwid','matchline','matchxpos',$
      'matchord','matcherr','matchdif','matchwts','matchbest'],$
      matchlam_c,matchamp_c,matchwid_c,matchline_c,matchxpos_c,$
      long(matchord_c),matcherr_c,matchdif_c,matchwts_c,matchbest_c

fxbfinish,unit

;stop

fini:
if(verbose ge 1) then begin
  print,'*** thar_wavelen ***'
  print,'File In = ',filin0
  naxes=sxpar(dathdr,'NAXIS')
  nx=sxpar(dathdr,'NAXIS1')
  ny=sxpar(dathdr,'NAXIS2')
  print,'Naxes, Nx, Ny = ',naxes,nx,ny 
; print,'Wrote file to thar dir:'
; print,tharout
; print,'Added line to reduced/standards.csv'
endif


end
