pro rd_coefts,listin,cfts,parm4,itemp,mjd,tslamb,match
; this routine reads the wavelength solution coefficients cfts(15,nt)
; from the nt-long string array of THAR*.fits files contained in listin.
; Also reads and returns array tslamb(nx,nord,nt) containing the wavelength
; solutions for fiber1 for all times.
; Also reads the time series of matched-line information, which it embeds
; in a structure named match.  This can deal with up to 1000 matched lines.
; Also reads the CCD inlet temperature tt_itemp from the header of the original
; data file, and returns the time series in itemp(nt)
; The observation start time is returned in mjd.

root=getenv('NRESROOT')

;openr,iun,listin,/get_lun
;ss=''
;files=['']
;nfiles=0
;while(not eof(iun)) do begin
  ;readf,iun,ss
  ;files=[files,strtrim(ss,2)]
  ;nfiles=nfiles+1
;endwhile
;close,iun
;free_lun,iun
;files=files(1:*)
files=listin
nfiles=n_elements(files)

cfts=fltarr(15,nfiles)            ; rcubic coefficients
parm4=dblarr(4,nfiles)            ; 4-parameter fit values
itemp=fltarr(nfiles)
mjd=dblarr(nfiles)
for i=0,nfiles-1 do begin
  dd=readfits(files(i),hdr0,/silent)
  if(i eq 0) then begin
    sz=size(dd)
    nx=sz(1)
    nord=sz(2)
    tslamb=dblarr(nx,nord,nfiles)
  endif
  origfile=sxpar(hdr0,'ORIGNAME')
  origpath=root+'rawdat/'+strtrim(origfile,2)
  od=readfits(origpath,hdrorig,/silent)
  itemp(i)=sxpar(hdrorig,'TT_ITEMP')
  mjd(i)=sxpar(hdrorig,'MJD-OBS')
  
  tslamb(*,*,i)=dd(*,*,1)
  fxbopen,unit,files(i),1,hdr
  fxbread,unit,v0,'SINALP'        ; 4-parameter fit values
  fxbread,unit,v1,'FL'
  fxbread,unit,v2,'Y0'
  fxbread,unit,v3,'Z0'
  parm4(*,i)=[v0(1),v1(1),v2(1),v3(1)]
  fxbclose,unit
  fxbopen,unit,files(i),2,hdr
  for j=0,14 do begin
    fxbread,unit,val,j+1,2
    cfts(j,i)=val
  endfor
  fxbclose,unit
endfor

matchdat=dblarr(1000,10,nfiles)
matchnames=['matchlam','matchamp','matchwid','matchline','matchxpos',$
      'matchord','matcherr','matchdif','matchwts','matchbest']
nmatch=lonarr(nfiles)
for i=0,nfiles-1 do begin
  fxbopen,unit,files(i),3,hdr3
  fxbread,unit,v0,'matchlam'
  fxbread,unit,v1,'matchamp'
  fxbread,unit,v2,'matchwid'
  fxbread,unit,v3,'matchline'
  fxbread,unit,v4,'matchxpos'
  fxbread,unit,v5,'matchord'
  fxbread,unit,v6,'matcherr'
  fxbread,unit,v7,'matchdif'
  fxbread,unit,v8,'matchwts'
  fxbread,unit,v9,'matchbest'
  fxbclose,unit
  nmatchi=n_elements(v0)
  nmatch(i)=nmatchi
  matches=reform([v0,v1,v2,v3,v4,v5,v6,v7,v8,v9],nmatchi,10)
  matchdat(0:nmatchi-1,*,i)=matches
endfor

match={matchnames:matchnames,nmatch:nmatch,matchdat:matchdat}

end
