pro expm_ts,listdat,instance,sumint,date,rms
; This routine reads a list of exposure meter images named in listdat.
; It subtracts a dark image from each, and then computes the background-
; subtracted difference between each of the 3 fiber channels and a nearby
; sample of unilluminated pixels.  It returns an array sumint(nt,3)
; giving the net intensity in e- by image and fiber.
; Information needed to do photometry is read from a context file contained
; in reduced/context/expmeter.txt.  This file contains one line for each
; instance of the exposure meter (different cameras, locations, binnings,
; dark images);  the line used is indexed by input parameter "instance".

; constants
root=getenv('NRESROOT')
config=root+'/reduced/config/expmeter.txt'
gain=0.26                         ; ATIK gain in e-/ADU

; read the input data into a big array
openr,iun,listdat,/get_lun
nt=0
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  nt=nt+1
endwhile
point_lun,iun,0

names=strarr(nt)
for i=0,nt-1 do begin
  readf,iun,ss
  names(i)=strtrim(ss,2)
endfor
close,iun
free_lun,iun

; read the first file, get size
dd=readfits(names(0),hdr)
sz=size(dd)
nx=sz(1)
ny=sz(2)

date=strarr(nt)
dat=fltarr(nx,ny,nt)
for i=0,nt-1 do begin
  dat(*,*,i)=float(readfits(names(i),hdr))
  date(i)=sxpar(hdr,'DATE-OBS')
endfor

; read the config file, get photometry apertures, etc.
openr,iun,config,/get_lun
ss=''
nc=0
while(not eof(iun)) do begin
  readf,iun,ss
  nc=nc+1
endwhile
point_lun,iun,0

for i=0,nc-1 do begin
  readf,iun,ss
  words=get_words(ss,nw)
  instc=fix(words(0))
  if(instc eq instance) then begin
    posrad=float(words(1:9))    ; x,y, posn, radius of 3 fibers
    backgnd=float(words(10:13)) ; backgnd box x,y posn, x,y width
    bin=fix(words(14))          ; binning = 1 or 2
    dark=words(15)              ; pathname of dark image
    goto,done
  endif
endfor

done:close,iun
free_lun,iun

; get the dark file, presumed to be a simple fits file
dark=root+strtrim(dark,2)
ddark=readfits(dark,hdr)       ; should really be a bias and a dark.
                               ; for now, assume it is really a bias.
; make array of differences, data - dark
ddarkb=rebin(ddark,nx,ny,nt)
difb=dat-ddarkb

; make masks for the 3 fibers and background
xx=rebin(findgen(nx),nx,ny)
yy=rebin(reform(findgen(ny),1,ny),nx,ny)
s0=where((xx-posrad(0))^2 + (yy-posrad(1))^2 le posrad(2)^2,ns0)
s1=where((xx-posrad(3))^2 + (yy-posrad(4))^2 le posrad(5)^2,ns1)
s2=where((xx-posrad(6))^2 + (yy-posrad(7))^2 le posrad(8)^2,ns2)
s3=where(xx ge backgnd(0) and xx le backgnd(2) and yy ge backgnd(1) and $
         yy le backgnd(3),ns3)
if(ns0 le 0 or ns1 le 0 or ns2 le 0 or ns3 le 0) then stop

; make output array
sumint=fltarr(nt,3)

; do the processing
for i=0,nt-1 do begin
  dif=difb(*,*,i)
  sumint(i,0)=gain*(total(dif(s0))-ns0*median(dif(s3)))
  sumint(i,1)=gain*(total(dif(s1))-ns1*median(dif(s3)))
  sumint(i,2)=gain*(total(dif(s2))-ns2*median(dif(s3)))
endfor

rms=stddev(difb,dimension=3)     ; variance in time, for each x,y

end
