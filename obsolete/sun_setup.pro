pro sun_setup,sgsite,fibindx,nn
; This routine accepts identifiers for the spectrograph being modeled,
; for a list of solar spectrum lines identified by hand from an obsd spectrum, 
; and for the fiber index (0,1,2) being used.
; sgsite is a string, one of {'SQA','ELP','TEN','ALI','LSC','CPT','OGG'}
; nn is also a string, eg '07', which is used to choose the input filename.
; The routine reads the appropriate spectrograph information from 
; 'reduced/csv/spectrographs.csv', and takes its input from
; ascii file reduced/config/sun_lam_pixnn.txt, where nn is an integer,
; which contains wavelengths, order indices, and x-coords
; for a list of as many solar lines as the user has patience to identify 
; by hand.
; It then proceeds to fill as much as it can of the sun_am common block,
; which is used by other routines.
; On return, ierr_c=0 is normal, anything else is a fatal error.

@nres_comm

; common block
common sun_am, mm_c,d_c,sinalp_c,fl_c,y0_c,z0_c,gltype_c,priswedge_c,lamcen_c,$
       r0_c,pixsiz_c,nx_c,nord_c,nl_c,linelam_c,$
       dsinalp_c,dfl_c,dy0_c,dz0_c,dlam2_c,$
       nblock_c,nfib_c,npoly_c,ordwid_c,medboxsz_c,$
       matchlam_c,matcherr_c,matchdif_c,matchord_c,matchxpos_c,$
       matchwts_c,matchbest_c,nmatch_c,$
       lam_c,y0m_c,coefs_c,ncoefs_c$
       site_c,fibindx_c,fileorg_c,ierr_c

; constants
nresroot=getenv('NRESROOT')
linedata=nresroot+'reduced/config/'+sgsite+'sun_lamvac_pix'+nn+'.txt'
radian=180.d0/!pi
ierr_c=0

; make mjd for selecting spectrograph info
jdc=systime(/julian)
mjdc=jdc-2400000.5d0

; load up nres common block with site name
site=sgsite

; read the spectrograph config file, tuck data away in sun_am.
get_specdat,mjdc,err
;rd_specconfig,sgsite,config
mm_c=specdat.ord0 + lindgen(specdat.nord)      ; diffraction orders
d_c=specdat.grspc                     ; grating groove spacing (mm)
sinalp_c=sin(specdat.grinc/radian)    ; sin nominal incidence angle
fl_c=specdat.fl                       ; camera nominal fl (mm)
y0_c=specdat.y0                       ; y posn at which gamma=0 (mm)
z0_c=specdat.z0                       ; (n-1) of air in SG (no units)
gltype_c=specdat.glass                ; cross-disperser glass type (eg 'BK7')
priswedge_c=specdat.apex              ; cross-disp prism apex angle (degree)
lamcen_c=specdat.lamcen               ; nominal wavelen at FOV center (micron)
r0_c=specdat.rot/radian               ; detector rotation angle (radian)
pixsiz_c=specdat.pixsiz               ; detector pixel size (mm)
nx_c=specdat.nx                       ; no of detector columns
nord_c=specdat.nord                   ; no of spectrum orders
dsinalp_c=abs(sin((specdat.grinc+specdat.dgrinc)/radian)-sinalp_c)
dfl_c=specdat.dfl
dy0_c=specdat.dy0
dz0_c=specdat.dz0
nblock_c=specdat.nblock
nfib_c=specdat.nfib
npoly_c=specdat.npoly
ordwid_c=specdat.ordwid
medboxsz_c=specdat.medboxsz
ncoefs_c=specdat.ncoefs

; read the list of line wavelengths, x-coords, order indices
openr,iun,linedata,/get_lun
ss=''
readf,iun,ss        ; skip the header line
readf,iun,ss        ; this contains the fiber number
words=get_words(ss,nwd)
fib0=long(words(1))
if(fib0 ne fibindx) then begin
  print,'fibindx and input file fib0 do not match.'
  stop
endif

nl_c=0
while(not eof(iun)) do begin
  readf,iun,ss
  nl_c=nl_c+1
endwhile
point_lun,iun,0
  
linelam_c=dblarr(nl_c)
matchxpos_c=dblarr(nl_c)
matchord_c=lonarr(nl_c)
matchdif_c=dblarr(nl_c)
readf,iun,ss
readf,iun,ss
for i=0,nl_c-1 do begin
  readf,iun,v1,v2,v3
  linelam_c(i)=v1
  matchord_c(i)=long(v2)
  matchxpos_c(i)=v3
endfor
nmatch_c=nl_c

close,iun
free_lun,iun

end
