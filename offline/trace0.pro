pro trace0,filin,sitec,camerac
; This routine reads a trace0 file (containing order positions vs iorder
; and ifib for a sample of orders, hand-read from a flat-field image).
; Input parms sitec, camerac identify the site (eg sqa) and camera (eg en03)
; for which this trace is intended.  Putting these in the calling sequence
; facilitates using one trace0 file to produce several trace0.fits outputs.
; The routine fits these positions to a quadratic function of x for each 
; order, and then fits the coefficients to polynomial functions of order npoly.
; these 3 x npoly coeficients are used to create a trace array in standard
; form (one polynomial per order x fiber, with header keywords).
; creation date.  The leading 00 in the date identifies this as trace0 output.
; The routine provides for either 2 or 3 fibers for the output trace file,
; but it assumes that the input describes only 2 fibers (to avoid overlaps
; in the red orders).  To deal with 3 fiber cases, the input must describe
; 2 adjacent fibers (0,1) or (1,2).  The code then extrapolates the trace
; positions for the two given fibers to get the positions for the remaining one.
; The routine also creates a simple a-priori version
; of the cross-dispersion profile array prof(cowid,nord,mfib,nblock),
; set equal to 1.0 for each cross-dispersion position less than ordwid in
; absolute value. 
; The trace and prof arrays are then combined into a single array
; tracprof(nc,nord,mfib,nblock+1), where nc = (nleg > cowid) and 
; cowid=ceil(ordwid).  Then
; trace = tracprof(0:nleg-1,*,*,0)
; prof  = tracprof(0:cowid-1,*,*,1:*)
; These are written to
; $NRESROOT/reduced/trace/TRAC00xx.xxxxx.fits, where the x's contain the
; creation date.  The leading 00 in the date identifies this as trace0 output.

; common 
@nres_comm

; constants
nresroot=getenv('NRESROOT')
instance=getenv('NRESINST')
nresrooti=nresroot+strtrim(instance,2)
site=sitec               ; stick site, camera inputs into common
camera=camerac

; get spectrograph information from spectrographs.csv
jdc=systime(/julian)
mjdc=jdc-2400000.5d0
get_specdat,mjdc,err
nfib=specdat.nfib
nx=specdat.nx
nomax=specdat.nord-1
npoly=specdat.npoly
ordwid=specdat.ordwid
medboxsz=specdat.medboxsz
cowid=ceil(ordwid)

; read the input file
openr,iun,filin,/get_lun
ss=''
readf,iun,ss            ; header line
readf,iun,ss            ; get number of fibers and other layout info

; input line:
; dummy, nres, mres, fib0, fib1, nx, npoly, nordmax, ordwid, medboxsiz

words=get_words(ss,nw)
;nfib=long(words(1))     ; number of fibers
mfib=long(words(1))
fib0=long(words(2))       ; index of the first fiber
fib1=long(words(3))       ; index of the 2nd fiber
;nx=long(words(5))       ; number of x-pixels
;npoly=long(words(4))    ; max order of polynomial fit to coeffs vs order no.
;nomax=long(words(7))    ; max order index number for which traces are desired
;ordwid=float(words(5))  ; width of the extracted orders, in pix
;medboxsz=long(words(6)) ; size of box for median filtering in backgrnd subtract
readf,iun,ss            ; line with x-values
words=get_words(ss,nw)
xx=fltarr(nw-1)
nsamp=nw-1
xx=float(words(1:*))
ii=0
while(not eof(iun)) do begin
  readf,iun,ss
  ii=ii+1               ; counting to norder*mfib
endwhile
point_lun,iun,0

nord=ii/mfib            ; number of orders represented in input data
iord=fltarr(nord,mfib)
dat=fltarr(nsamp,nord,mfib)
readf,iun,ss
readf,iun,ss
readf,iun,ss
for i=0,nord-1 do begin
  for j=0,mfib-1 do begin
    readf,iun,ss
    words=get_words(ss,nw)
    iord(i,j)=long(words(0))
    dat(*,i,j)=float(words(1:*))      ; y-positions of orders at given x values
  endfor
endfor

;stop

; do 2nd-order (quadratic) Legendre polynomial fits to order positions
xp=2.*(xx-nx/2.)/nx        ; x coords transformed to [-1,1]
funs=fltarr(nw-1,3)
; set up to fit to legendre polynomials
wts=fltarr(nw-1)+1.
for i=0,2 do begin
  funs(*,i)=legendre(xp,i)        ; note IDL's legendre funs = +/-1 at x = +/-1
endfor
coc=fltarr(3,nord,mfib)
for i=0,nord-1 do begin
  for j=0,mfib-1 do begin
    cc=lstsqr(dat(*,i,j),funs,wts,3,rms,chisq,outp,1,cov)
    coc(*,i,j)=cc
    print,iord(i),j,rms
  endfor
endfor

; fit polynomials to coefficients vs order number.
; Poly orders are up to npoly for coc(0,*,*), npoly-1 for coc(1,*,*), etc.
; Average these coefficients over fibers.
; Also fit linear function to separation between orders. 
cpc=fltarr(npoly+1,3)     ; coeffs describing coc vs order, avgd over fibers
spc=fltarr(2)               ; coeffs describing fiber separation vs order.
xord=findgen(nomax+1)
odif=reform(coc(0,*,1)-coc(0,*,0))
spc=poly_fit(iord(*,0),odif,1)   ; linear fit to spacing between fibers vs iord
spx=poly(xord,spc)          ; spacing between fibers for all orders
cc00=reform(poly_fit(iord(*,0),coc(0,*,0),npoly))
cc01=reform(poly_fit(iord(*,1),coc(0,*,1),npoly))
cpc(0:npoly,0)=(cc00+cc01)/2.
cc10=reform(poly_fit(iord(*,0),coc(1,*,0),npoly-1))
cc11=reform(poly_fit(iord(*,1),coc(1,*,1),npoly-1))
cpc(0:npoly-1,1)=(cc10+cc11)/2.
cc20=reform(poly_fit(iord(*,0),coc(2,*,0),npoly-2))
cc21=reform(poly_fit(iord(*,1),coc(2,*,1),npoly-2))
cpc(0:npoly-2,2)=(cc20+cc21)/2.

; evaluate these polynomials over the full order range to make full trace array
trace0=fltarr(3,nomax+1,nfib)    ; order posn coeffs vs order, fiber
trace0(0,*,fib0)=poly(xord,cpc(0:npoly,0))-spx/2.
trace0(0,*,fib1)=poly(xord,cpc(0:npoly,0))+spx/2.
trace0(1,*,fib0)=poly(xord,cpc(0:npoly-1,1))
trace0(1,*,fib1)=trace0(1,*,fib0)              ; same for all fibers
trace0(2,*,fib0)=poly(xord,cpc(0:npoly-2,2))
trace0(2,*,fib1)=trace0(2,*,fib0)              ; same for all fibers


; now deal with cases with 3 fibers
if(nfib eq 3) then begin
  if(fib0 eq 0) then begin
;   must extrapolate data for fiber 2.
    trace0(0,*,2)=trace0(0,*,1)+reform(spx,1,nomax+1,1)
    trace0(1,*,2)=trace0(1,*,1)
    trace0(2,*,2)=trace0(2,*,1)
  endif else begin
; must shift fibers 0,1 up by one, extrapolate for new fiber 0
    trace0(0,*,0)=trace0(0,*,1)-reform(spx,1,nomax+1,1)
    trace0(1,*,0)=trace0(1,*,1)
    trace0(2,*,0)=trace0(2,*,1)
  endelse
endif

; make the combined trace + profile array
npoly=3          ; by definition for trace0
nc=cowid > npoly
nblock=specdat.nblock
tracprof=fltarr(nc,specdat.nord,nfib,nblock+1)
tracprof(0:2,*,*,0)=trace0
tracprof(0:cowid-1,*,*,1:*)=1./cowid

; write out the tracprof array as a fits file.  First build the header.
jd=systime(/julian)      ; file creation time, for sorting similar trace files
mjd=jd-2400000.5d0
daterealc=date_conv(jd,'R')
datestrc=string(daterealc,format='(f13.5)')
strput,datestrc,'00',0
fout='trace/TRAC'+strtrim(sitec,2)+datestrc+'.fits'
filout=nresrooti+'reduced/'+fout

mkhdr,hdr,tracprof
sxaddpar,hdr,'NX',nx
sxaddpar,hdr,'NFIB',nfib
sxaddpar,hdr,'NPOLY',npoly
sxaddpar,hdr,'NORD',nomax+1
sxaddpar,hdr,'FIB0',fib0
sxaddpar,hdr,'FIB1',fib1
sxaddpar,hdr,'ORDWIDTH',ordwid
sxaddpar,hdr,'COWID',cowid
sxaddpar,hdr,'NBLOCK',nblock
sxaddpar,hdr,'MJD',mjd
sxaddpar,hdr,'FILE_IN',strtrim(filin,2)
sxaddpar,hdr,'MEDBOXSZ',medboxsz
sxaddpar,hdr,'SITEID',sitec
sxaddpar,hdr,'INSTRUME',camerac
; strip off the / from the nresinstance 
this_nres = strmid(strtrim(instance,2), 0, strlen(strtrim(instance,2)) - 1)
sxaddpar,hdr,'TELESCOP', this_nres
sxaddpar,hdr,'TELID', 'igla'
sxaddpar,hdr,'PROPID', 'calibrate'
sxaddpar,hdr,'BLKUID', '000000000'
sxaddpar,hdr,'OBSTYPE', 'TRACE'
; Calculate the standard date format for the output filename
CALDAT, jd, month, day, year, hour, minute, second
today = strtrim(year,2)+ strtrim(month,2) + strtrim(day,2)
sxaddpar,hdr, 'OUTNAME', 'trace_'+strtrim(sitec,2)+'_'+this_nres +'_'+camerac+'_' +today
now =  strtrim(year,2)+'-'+strtrim(month,2)+'-'+strtrim(day, 2) + 'T'+strtrim(hour,2) + ':' + strtrim(minute,2)+':'+strtrim(string(second, format='(F06.3)'), 2)
sxaddpar,hdr,'DATE-OBS', now
sxaddpar,hdr,'L1PUBDAT', now
sxaddpar,hdr,'RLEVEL', 91


writefits,filout,tracprof,hdr

stds_addline,'TRACE',fout,1,site,camera,jd,'0000'

; put the output file into a tarfile for archiving
fpack_stacked_calibration,filout, sxpar(hdr, 'OUTNAME')

end
