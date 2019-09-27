pro thar_setup_1,filin,fibindx,ierr,dbg=dbg,tharlist=tharlist,trp=trp
; This routine accepts identifiers for the spectrograph being modeled,
; one extracted ThAr input spectrum,
; and for the fiber index (0,1,2) being used.
; It reads the appropriate spectrograph configuration file,
; finds input spectrum in nres_comm corspec array and renames it tharspec_c,
; and proceeds to fill as much as it can of the thar_am common block,
; which is used by other routines.
; On return, ierr=0 is normal, anything else is a fatal error.

; common blocks
@thar_comm_1
@nres_comm

; constants
nresroot=getenv('NRESROOT')
nresinst='RD'+strtrim(site,2)+'1/'        ; site from nres_comm
nresrooti=nresroot+nresinst
stage2root=getenv('STAGE2ROOT')
rutname='thar_setup_1'
linelist=nresrooti+'reduced/config/arc_ThAr_Redman.txt'
if(keyword_set(tharlist)) then begin
  linelist=nresrooti+'reduced/config/'+strtrim(tharlist,2)
endif
;linelist=nresrooti+'reduced/config/arc_Thar0.txt'
radian=180.d0/!pi
thrshamp=4.5        ; accept obs'd lines with amplitudes above thrshamp*sigma
                    ; where sigma is based on the amplitude in e-
thrshwid=5.                 ; accept lines with widths within 1.35*dq*thrshwid
                            ; of the median value.

radian=180.d0/!pi
nsqdthr=400                 ; min acceptable total number of lines in input 
gsw=0                       ; set to 0 to use 3-pt line parameter estimates
                            ; set to 1 to use 9-pt gaussian fit estimates
wslope=[0.1/2048,0.8/4096]   ; slope of linewidth vs xpos relation, for
                            ; SQA and all other sites, respectively.
wrang=[[500,1500],[1000,3000]]  ; range of pixels to use in linewidth estimate,
                            ; for SQA and all other sites, resp.
ierr_c=0

; set wslop, wrang values according to site.
if(strupcase(strtrim(site,2)) eq 'SQA') then begin
  wslop=wslope(0)
  wran=wrang(*,0)
endif else begin
  wslop=wslope(1)
  wran=wrang(*,1)
endelse

; read the spectrograph specdat file, tuck data away in thar_am, but
; get every data item we can from header of input data file.
fits_open,filin,fcb
fits_read,fcb,dat0,hdr0,exten=0
fits_close,fcb
get_specdat_1,mjdd,err,siter=strtrim(site,2)
ord0=specdat.ord0                       ; spectrum lowest diffraction order
nx_c=sxpar(hdr0,'NX')                   ; no of detector columns
nord_c=sxpar(hdr0,'NORD')               ; no of diffraction orders
mm_c=ord0 + lindgen(nord_c)             ; diffraction orders
grspc_c=specdat.grspc                   ; grating groove spacing (mm)
grinc_c=specdat.grinc                   ; grating incidence angle
;sinalp_c=sxpar(hdr0,'sinalp')           ; sin nominal incidence angle
;fl_c=sxpar(hdr0,'FL')                   ; camera nominal fl (mm)
;y0_c=sxpar(hdr0,'Y0')                   ; y posn at which gamma=0 (mm)
;z0_c=sxpar(hdr0,'Z0')                   ; (n-1) of air in SG (no units)
sinalp_c=specdat.sinalp
fl_c=specdat.fl
y0_c=specdat.y0
z0_c=specdat.z0
gltype_c=specdat.gltype                 ; cross-disperser glass type (eg 'BK7')
apex_c=specdat.apex                     ; cross-disp prism apex angle (degree)
lamcen_c=specdat.lamcen                 ; nominal wavelen at FOV center (micron)
rot_c=specdat.rot                       ; detector rotation angle (degree)
pixsiz_c=specdat.pixsiz                 ; detector pixel size (mm)
;***
fib0=sxpar(hdr0,'FIB0')                 ; index of 1st lighted fiber

ncoefs_c=15                             ; hard-wired ncoefs, for now
coefs_c=specdat.coefs
;coefs_c=dblarr(ncoefs_c)
;for i=0,ncoefs_c-1 do begin
;  cstr='C'+string(i,format='(i02)')
;  coefs_c(i)=double(sxpar(hdr0,cstr))
;endfor

ex0_c=0.d0      ; Initialize the ex parameters to zero, because they don't
ex1_c=0.d0      ; exist in the model that yields the current lam_c.
ex2_c=0.d0

; get the list of wavelength params to fit as opposed to be frozen, put into thar_comm
thar_get_dofit_1,site,dstr          ; gets the most recent version
dofitstr=dstr

;*** changed code
; 2019/04/03: Deprecating the use of default.csv.  If we want to update the
; spectrograph parameters, we should do it by adding a line to 
; spectrographs.csv.  Henceforth the default parameters will come from there.

; get default spectrograph params to put in frozen params.
;thar_get_default_stg2,site,mjdd

; get trace data for later use in cubchrom
; first make a fake cordat array, with dimensions nx_c x nx_c
cordat=fltarr(nx_c,nx_c)
nfib=3                      ; also used to fool order_cen.pro into cooperating.
inst='RD'+site+'1/'
get_calib_1,'TRACE',tracefile,tracprof,tracehdr,gerr,inst=inst
ord_wid=sxpar(tracehdr,'ORDWIDTH')   ; width of band to be considered for
                                     ; extraction
medboxsz=sxpar(tracehdr,'MEDBOXSZ')
npoly=sxpar(tracehdr,'NPOLY')
cowid=sxpar(tracehdr,'COWID')
nblock=sxpar(tracehdr,'NBLOCK')
trace=reform(tracprof(0:npoly-1,*,*,0))
prof=tracprof(0:cowid-1,*,*,1:nblock)
order_cen,trace,ord_vectors
tracedat={trace:trace,npoly:npoly,ord_vectors:ord_vectors,ord_wid:ord_wid,$
          medboxsz:medboxsz,tracefile:tracefile,prof:prof}

; average TRIPLE files up to the current one to yield best-guess smoothed
; values of fib_coefXX.  Use these to replace the specdat values
; if keyword trp is set to 2 or 3.  Normally expect trp=2, in which case 
; fib_coefs values come from avg TRIPLE, all other data from specdat.
smooth_triple,site,mjdd,fibcoefsm,terr

; if successful, and if dbg keyword is not set or if it is not set to 2,
; then set new common values of coefs_c, fitcoefs_c, lam_c
;###########
if(terr eq 0) then begin
; trip_unpack,tripdat,triphdr,trp=trp ; TRIPLE data into specdat, coefs_c, 
              ; fibcoefs_c or not, depending on the value of keyword trp.
  if(trp ge 2) then fibcoefs_c=fibcoefsm
  tripfile_short_c='fibcoefs.csv'
;###########
  logo_nres2,rutname,'INFO','TRIPLE file used = '+tripfile_short_c
endif else begin
  tripfile_short_c='spectrographs.csv'
endelse

; check data size matches with config expectations
sz=size(corspec)
nx=sz(1)
nord=sz(2)
if(nx ne nx_c or nord ne nord_c) then begin
  logo_nres2,rutname,'ERROR','detector sizes config vs data do not match.'
  ierr_c=1
  ;stop
  goto,fini
endif

; look at tharspec_c, to assure that the data are sensible
tsqd=fltarr(nord)
tnsqd=lonarr(nord)
for i=0,nord-1 do begin
  mth=median(tharspec_c(*,i),15)
  diff=tharspec_c(*,i)-mth
  quartile,diff,mdif,qd,dqd
  sqd=where(diff gt 10.*dqd,nsqd)
  tnsqd(i)=nsqd   ; number of points above 10*quartile spacing above median
endfor
tnsqds=total(tnsqd)
if(tnsqds le nsqdthr) then begin
  ierr_c=2
  logo_nres2,rutname,'ERROR',{tnsqds:tnsqds}
  goto,fini
endif

; test a very blue order of tharspec_c to see if its noise properties
; show that it has been flat-fielded.  If so, obtain a FLAT for the
; corresponding date, and multiply tharspec_c by the flat for the appropriate
; fiber, so that it is essentially a raw extracted spectrum.
tdat=tharspec_c(*,nord_c-5)
quartile,tdat,tmed,tq,tdq
sb=where(tdat-tmed gt 10.*tdq,nsb)
if(nsb gt 0) then tdat(sb)=0.          ; zero out real lines
thwid=nx_c/8.
rmbot=stddev(tdat(0:2*thwid))
rmmid=stddev(tdat(nx_c/2-thwid:nx_c/2+thwid))
rmtop=stddev(tdat(nx_c-2*thwid:nx_c-1))
rmavg=(rmbot+rmtop)/2.
print,'rmavg/rmmid = ',rmavg/rmmid
if(rmavg/rmmid gt 1.4) then begin       ; do this if lots noisier at edges
  get_calib,'FLAT',filename,cdat,chdr,gerr
  tspecout=tharspec_c
  tspecout=tspecout*(cdat(*,*,1) > 0.)   ; ignore fiber index for now 
                                         ;  too confusing
  tharspec_c=tspecout
endif

; make first guess lam_c, with current specdat values
xx=pixsiz_c*(findgen(nx_c)-float(nx_c/2.))
mm=mm_c
fibno=1
lambda3ofx,xx,mm,fibno,specdat,lam_c,y0m_c   ; vacuum wavelengths

; make dlambda/dx, for later use
dlamdx=fltarr(nx_c,nord_c)
for i=0,nord_c-1 do begin
  dlamdx(*,i)=deriv(lam_c(*,i))
endfor
 
; construct the catalog of observed ThAr lines.
thar_catalog,tharspec_c,thrshamp,gsw,iord_c,xpos_t,amp_t,wid_t,$
     xposg,ampg,widg,chi2g,ierrc

if(abs(mjdd-58498.81789d0) le 1.e-4) then stop

ierr_c=ierr_c+ierrc
dldx=dlamdx(xpos_t,iord_c)
xperr_c=dldx*wid_t/(sqrt(amp_t > 10.))
; make array to hold differences between obsd and matched std wavelengths
ncat=n_elements(iord_c)
diff_c=dblarr(ncat)

; select between 3-pt and gaussian estimates of line params using gsw
if(gsw eq 0) then begin
  xpos_c=xpos_t
  amp_c=amp_t
  wid_c=wid_t
endif else begin
  xpos_c=xposg
  amp_c=ampg
  wid_c=widg
endelse
widrat=((widg/(wid_t > .1)) > .1) < 10.
lchi2=alog10(chi2g > 0.001)

; If gsw=0, reject bad lines based on their width, which for good lines
; obeys a tight relation with x-position.
; Set the width zero point according to a histogram measurement, because
; averaged spectra are prone to have larger width than individual ones.
; If gsw=1,
; reject catalog lines with bad widths, too-small amplitudes, too big chi^2
; bad ratio between 3-pt and gaussian width.
quartile,wid_c,mwid,q,dq
dif=(wid_c-mwid)/(dq*1.35)             ; dispersion in gaussian sigma
siga=sqrt(amp_c)
if(gsw eq 0) then begin
; sg=where(abs(dif) le thrshwid and siga gt thrshamp,nsg)
  xp0=xpos_c-nx/2.              ; independent posn variable
  wida=wid_c-xp0*wslop           ; linewidth corr for posn
  xgood=where(xpos_c ge wran(0) and xpos_c le wran(1),nxgood)  ; measure width
              ; over an x range that is restricted to center half of detector
  h=histogram(wida(xgood),min=0,max=10.,binsiz=0.2)
  maxh=max(h,ix)                ; find peak of histogram
  dwid=wida-0.2*ix              ; distance from peak (pix units)
  sg=where(abs(dwid) le 0.5,nsg)  ; pick lines with width near histogram peak

; sg=where((wid_c ge 3.5+xpos_c/4096.) and (wid_c le 4.5+xpos_c/4096.),nsg)

;  if(nsg le 0) then stop
endif else begin
  sg=where(widg gt 3.5 and widg le 6.0 and widrat ge 0.6 and widrat le 1.4 $
     and lchi2 le 1.8 and lchi2 gt (-2.999) and siga gt thrshamp,nsg)
 ; if(nsg le 0) then stop
endelse

; Make lists of observed (not "lab") line properties.  The lines listed here
; are all observed lines that pass significance and width cutoffs.
iord_c=iord_c(sg)
xpos_c=xpos_c(sg)
amp_c=amp_c(sg)
wid_c=wid_c(sg)
diff_c=diff_c(sg)
xperr_c=xperr_c(sg)
clip_c=dblarr(nsg)+1.d0       ; weight array used to clip bad lines

; make arrays to keep track of which observed lines are matched to lab lines.
match_c=lonarr(nsg)            ; will be set = 1 for matched lines
matchindx_c=[]                 ; will be filled with indices of matched lines

; read the ThAr standard line list
openr,iun,linelist,/get_lun
ss=''
readf,iun,ss
readf,iun,ss
nline=0
while(not eof(iun)) do begin
  readf,iun,ss
  nline=nline+1
endwhile

point_lun,iun,0
readf,iun,ss
readf,iun,ss
linelam_c=dblarr(nline)
lineamp_c=fltarr(nline)
v1=0.d0
for i=0,nline-1 do begin
  readf,iun,v1,v2
  linelam_c(i)=v1
  lineamp_c(i)=v2       ; #### should perhaps add line_err here.
endfor
close,iun
free_lun,iun

; truncate standard line list to wavelengths 370 < lam < 870 nm
sg=where(linelam_c ge 370. and linelam_c le 870.,nsg)
linelam_c=linelam_c(sg)           ; convert to nm
lineamp_c=lineamp_c(sg)

; #### remove untrustworthy lines, based on an input list of wavelengths.

thar=tharspec_c

;goto,fini
logo_nres2,rutname,'INFO',{sinalp:sinalp_c,fl:fl_c,y0:y0_c,z0:z0_c}
;print,'sinalp=',sinalp_c
;print,'fl=',fl_c
;print,'y0=',y0_c
;print,'z0=',z0_c
dd0=0.
a0=0.
x0=0.
z0=0.
f0=0.
g0=0.

fini:
ierr=ierr_c

end
