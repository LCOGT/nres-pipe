pro trace1,trace0,image0
; This routine updates an existing trace solution found in TRACE file trace0
; to be minimally consistent with a specified spectrum given in fits file image0.
; It interpolates image0 in y to yield a compressed image spanning +/- 200 pix
; around the nominal position (computed from trace1) of order 10, fiber 1,
; and shifted in y as necessary to put the nominal order position at y=0 for
; all x.  The user then identifies order 9, fiber 0 on the displayed image
; and clicks >3 locations distributed in x along the center of the observed
; order.  The routine fits a 3rd-degree Legendre polynomial to the identified
; points, modifies the Legendre coefficients in the trace0 data file
; appropriately, writes the result out to the current instance of the
; reduced/trace directory, and adds a line to the current instance standards.csv
; file.

; constants
nxc=512                ; number of x points desired in plot of image
ncur=7                ; number of cursor clicks to be used

nresroot=getenv('NRESROOT')
nresrooti=nresroot+getenv('NRESINST')
rawdat=getenv('NRESRAWDAT')

; get trace0 data, extract needed coeffs
trace0i=trace0
rerun:
trace0in=nresrooti+'reduced/trace/'+trace0i
tra0=readfits(trace0in,trhdr,/silent)
sz=size(tra0)
nc=sz(1)            ; number of coeffs (sort of)
nord=sz(2)          ; number of orders
nfib=sz(3)          ; number of fibers
nbl=sz(4)           ; number of blocks (+1)
trcoefs=reform(tra0(0:4,9,*,0),5,3)  ; leg coeffs of trace order 9, all fibers

; get image data, extract useful keywords
imgin=rawdat+image0
img=readfits(imgin,hdri,/silent)
sz=size(img)
nx=sz(1)
ny=sz(2)
sitei=strlowcase(strtrim(sxpar(hdri,'SITEID'),2))
camerai=strlowcase(strtrim(sxpar(hdri,'INSTRUME'),2))
file_ini=strtrim(sxpar(hdri,'FILE_IN'),2)
objectsi=strlowcase(strtrim(sxpar(hdri,'OBJECTS'),2))
words=get_words(objectsi,nw,delim='&')
if(nfib eq 3) then begin
  if(words(0) eq 'none') then fib0=1 else fib0=0
endif else begin
  fib0=0
endelse

; set imporant keywords site, camera, to values from image file
trhdrm=trhdr
sxaddpar,trhdrm,'SITEID',sitei
sxaddpar,trhdrm,'INSTRUME',camerai
sxaddpar,trhdrm,'FILE_IN',file_ini
sxaddpar,trhdrm,'FIB0',fib0

; strip off the / from the nresinstance
this_nres = strmid(strtrim(getenv('NRESINST'),2), 0, strlen(strtrim(getenv('NRESINST'),2)) - 1)
jd = systime(/julian)
; Calculate the standard date format for the output filename
CALDAT, jd, month, day, year, hour, minute, second
today = strtrim(year,2)+ strtrim(month,2) + strtrim(day,2)
sxaddpar,trhdrm, 'OUTNAME', 'trace_'+strtrim(sitec,2)+'_'+this_nres +'_'+camerac+'_' +today
now =  strtrim(year,2)+'-'strtrim(month,2)+'-'+strtrim(day, 2) + 'T'+strtrim(hour,2) + ':' + strtrim(minute,2)+':'+strtrim(string(second, format='%0.3f'), 2)
sxaddpar,hdr,'DATE-OBS', now
sxaddpar,hdr,'L1PUBDAT', now

; scrunch data array in x, for easier plotting.  Make final x, y coord vectors
scr=nx/nxc
scf=round(scr)
nxo=long(nx/scf)     ; we want output with this many x pixels
diff=nx-nxo*scf      ; must add this many pixels to make even number of blockx
nxi=nx+diff           ; desired number of input points
tempdat=fltarr(nxi,ny)
tempdat(diff/2:nx+diff/2-1,*)=img
imgscr=rebin(img,nxi/scf,ny)
xx=2.*(findgen(nxo)-nxo/2.)/nxo           ; range -1 to 1
yy=-200.+findgen(401)

; make values of trace for all x positions in scrunched data
yt=fltarr(nxo,3)
for i=0,2 do begin
  yt(*,i)=0.
  for j=0,4 do begin
    yt(*,i)=yt(*,i)+trcoefs(j,i)*legendre(xx,j)
  endfor
endfor

; interpolate scrunched data onto new y' = y - trace(x,fiber=1)
; do this at 1/4 pixel resolution
dint=fltarr(nxo,401)
for i=0,nxo-1 do begin
  dint(i,*)=reform(interpolate(reform(imgscr(i,*),ny),0.25*yy+yt(i,1)))
endfor

; subtract background, do log or 4th-root scaling for cleaner plotting
back=median(dint,21)
ddb=(dint-back) > 1.
;lddb=alog10(ddb)
r4db=sqrt(sqrt(ddb))
bb=bytscl(r4db,min=0,max=15.)

; plot data, overplot interpolated trace posns for all fibers
dif0=yt(*,0)-yt(*,1)
dif2=yt(*,2)-yt(*,1)
bb(*,200)=255    ; fiber 1
iy0=200+4.*dif0
iy2=200+4.*dif2
dash=findgen(nxo)
sdash=where(dash mod 10 le 5,nsdash)
bb(sdash,iy0(sdash))=255
bb(sdash,iy2(sdash))=255
tv,bb
; tag traces with fiber number, larger font for illuminated ones
tsiz=fltarr(3)+0.8
objects=sxpar(hdri,'OBJECTS')
words=strtrim(get_words(objects,delim='&',nw),2)
for i=0,nw-1 do begin
  if(strupcase(words(i)) ne 'NONE') then tsiz(i)=1.5
endfor
xyouts,20,280,'fib0',color=255,size=tsiz(0),/dev
xyouts,20,205,'fib1',color=255,size=tsiz(1),/dev
xyouts,20,140,'fib2',color=255,size=tsiz(2),/dev

; get cursor input from user
print,'click '+string(ncur,format='(i2)')+' points along order corresp to fib1'
curx=fltarr(ncur)
cury=fltarr(ncur)
for i=0,ncur-1 do begin
  cursor,x,y,3,/dev
  curx(i)=2.*(x-nxo/2.)/nxo       ; x-coord in range [-1,1]
  cury(i)=(y-200.)/4.             ; y coord in pix, meas from nominal fib1 posn
; plot,[x],[y],psym=1,color=200,symsiz=1.3,/overplot,/dev
  xyouts,x-3,y-3,'+',color=255,/dev
endfor
  

; fit results to legendre polynomials
funs=fltarr(ncur,5)
wts=fltarr(ncur)+1.
for i=0,4 do begin
  funs(*,i)=legendre(curx,i)
endfor
cc=lstsqr(cury,funs,wts,5,rms,chisq,outp,1,cov)

; make updated trace coeffs, write output
traout=tra0            ; full trace 4D array
dtra=fltarr(nc,nord,nfib,nbl)
dtra(0:4,*,*,0)=rebin(cc,5,nord,nfib,1)
traout=traout+dtra
; make output filename
jdc=systime(/julian)
daterealc=date_conv(jdc,'R')
datestrc=string(daterealc,format='(f13.5)')
filleaf='trace/TRAC'+datestrc+'.fits'
filout=nresrooti+'reduced/'+filleaf

print,'Write out the new trace file? Y/N'
ss=''
read,ss
if(strtrim(strupcase(ss),2) eq 'Y') then begin
  writefits,filout,traout,trhdrm
  print,'Wrote TRACE file  '+filleaf
; put a new line in standards.csv describing this file
  stds_addline,'TRACE',filleaf,1,sitei,camerai,jdc,'0000'

; if desired, replot with new trace file
  print,'Rerun with new trace file? Y/N'
  ss=''
  read,ss
  if(strtrim(strupcase(ss),2) eq 'Y') then begin
    trace0i=filleaf
    goto,rerun  
  endif
endif

end
