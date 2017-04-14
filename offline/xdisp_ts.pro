pro xdisp_ts,filin,instance,tracein,datdir,tsout
; This routine reads a list of input files from ascii file filin.  These should be 'fixed'
; 4096 x 4096 stellar (or perhaps flat) spectrum images from NRES.
; it accepts instance = the processing instance for these data, eg 'RDlsc1'
; also datdir = subdirectory of $NRESRAW containing the input data
; It also reads a TRACE file tracein (eg 'TRAC2017xxx.xxxxx') to give approx order posns
; It then assembles time series (ie, spanning all files) into a structure tsout,
; containing the following:
; .nt = number of time steps
; .nord = number of orders for which measurements are reported
; .iord = indices of orders, from indicated TRACE file
; .mjd(nt) = MJD of exposure start time
; .exptime(nt) = exposure time
; .objects(nt) = objects string, eg 'Procyon&thar&none'
; .fname(nt) = name of input file
; .ypos(nt,nord) = y position (pix) of orders evaluated at x=2048
; .intn(nt,nord) = peak intensity of order
; .thary(nt,5) = y position (pix) of selected ThAr lines
; .tharx(nt,5) = x position (pix) of selected ThAr lines

; constants
root=getenv('NRESROOT')
rooti=root+'/'+instance+'/'
tracepath=rooti+'reduced/trace/'+tracein
rawdat=getenv('NRESRAWDAT')
datpath=rawdat+'/'+datdir+'/'
ody=20.                      ; nominal separation between fibers (pix)
thx=[2236.,2020.,2002.,2253.,2113.]     ; nominal x,y posns of selected ThAr lines
thy=[629.,1219.,2158.,3061.,3327.]
nthar=n_elements(thx)
ythrsh=15.      ; y-coincidence threshold for order peaks

; read trace file, extract nominal order positions
dd=readfits(tracepath,trhdr)
y0=reform(dd(0,*,0,0))             ; fiber1 y-coords at x=2048.
nord=n_elements(y0)
iord=lindgen(nord)

; read filin
openr,iun,filin,/get_lun
fname=['']
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  fname=[fname,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
fname=fname(1:*)
nt=n_elements(fname)

; make output arrays
mjd=dblarr(nt)
exptime=fltarr(nt)
objects=strarr(nt)
ypos=fltarr(nt,nord)
intn=fltarr(nt,nord)
tharx=fltarr(nt,nthar)
thary=fltarr(nt,nthar)

; loop over files
for i=0,nt-1 do begin
  datin=datpath+fname(i)
  dat=readfits(datin,hdr)
  mjd(i)=sxpar(hdr,'MJD-OBS')
  exptime(i)=sxpar(hdr,'EXPTIME')
  objects(i)=sxpar(hdr,'OBJECTS')

; make expected order positions
  words=get_words(objects(i),delim='&',nw)
  if(nw ne 3) then stop
  words=strtrim(strlowcase(words),2)
  yexpect=y0
  if(words(2) ne 'none') then yexpect=y0-ody
  if(words(0) ne 'none') then yexpect=y0+ody

; find order peaks.  first, make clean intensity vs y
  uu=reform(rebin(dat(2044:2051,*),1,4096))
  uu=smooth(smooth(uu,3),3)
  uum=median(uu,23)
  uud=uu-uum
  scale=0.2*max(uud(0:150))       ; something about the minimum peak height
; find local maxima exceeding scale
  s=where(uud ge scale and uud ge shift(uud,1) and uud ge shift(uud,-1),ns)

; look for peaks near expected locations. If more than one, take the closer.
  for j=0,nord-1 do begin
    dy=abs(s-yexpect(j))
    sg=where(dy le ythrsh,nsg) 
    if(nsg gt 0) then begin
      if(nsg eq 1) then iy=s(sg)
      endif else begin
        mxi=min(dy(sg),ix)
        iy=s(sg(ix))
      endelse
; estimate peak amplitude, location
    i0=uu(iy)
    im=uu(iy-1)
    ip=uu(iy+1)
    intn(i,j)=i0
    ds=-0.5*(ip-im)/(ip+im-2.*i0)
    ypos(i,j)=iy+ds
    
  endfor

; find amplitude, location of selected ThAr lines.
  for j=0,nthar-1 do begin
    dbox=dat(thx(j)-7:thx(j)+7,thy(j)-7:thy(j)+7)
    dbmx=reform(rebin(dbox,1,15),15)  ; marginalized over x
    dbmy=rebin(dbox,15)               ; marginalized over y
    maxx=max(dbmy,ix)
    if(ix ge 2 and ix le 12) then begin   ; max near endpoint is bogus
      ids=ix-7.
      v0=dbmy(ix)
      vm=dbmy(ix-1)
      vp=dbmy(ix+1)
      ds=-0.5*(vp-vm)/(vp+vm-2.*v0)
      tharx(i,j)=thx(j)+ids+ds
    endif else begin
      tharx(i,j)=0.
    endelse

    maxy=max(dbmx,iy)
    if(iy ge 2 and iy le 12) then begin   ; max near endpoint is bogus
      ids=iy-7.
      v0=dbmx(iy)
      vm=dbmx(iy-1)
      vp=dbmx(iy+1)
      ds=-0.5*(vp-vm)/(vp+vm-2.*v0)
      thary(i,j)=thy(j)+ids+ds
    endif else begin
      thary(i,j)=0.
    endelse

  endfor

endfor

; assemble output structure
; .nt = number of time steps
; .nord = number of orders for which measurements are reported
; .iord = indices of orders, from indicated TRACE file
; .mjd(nt) = MJD of exposure start time
; .exptime(nt) = exposure time
; .objects(nt) = objects string, eg 'Procyon&thar&none'
; .fname(nt) = name of input file
; .ypos(nt,nord) = y position (pix) of orders evaluated at x=2048
; .intn(nt,nord) = peak intensity of order
; .thary(nt,5) = y position (pix) of selected ThAr lines
; .tharx(nt,5) = x position (pix) of selected ThAr lines

tsout={nt:nt,nord:nord,iord:iord,mjd:mjd,exptime:exptime,objects:objects,$
       fname:fname,ypos:ypos,intn:intn}

stop

end
