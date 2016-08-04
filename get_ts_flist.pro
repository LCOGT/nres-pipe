function get_ts_flist,rtype,bot,top
; This function accepts
; rtype = type of desired reduced data file.  rtype is a string, must be one of:
;         SPEC = calibrated spectrum
;         RADV = radial velocity
;         THAR = ThAr wavelength solution
; bot, top = arguments defining the range of filenames to be retrieved.
;         There are 3 possibilities:
;         (1) bot, top are positive long doubles, eg 2016148.21365.  In this
;           case, filenames with embedded date strings in the range [top,bot]
;           are returned.
;         (2) bot is as above, but top is absent or negative.  In this case, 
;           filenames with embedded date strings >= bot are returned.
;         (3) bot is a negative integer -N.  In this case,
;           the last N entries in the default-sorted ls listing of the indicated
;           directory are returned.
; The returned value is a string array containing the desired filenames,
; rendered as full pathnames.

; constants
root=getenv('NRESROOT')
specdir=root+'reduced/spec/'
rvdir=root+'reduced/rv'
thardir=root+'reduced/thar'

; get directory path
case rtype of
  'SPEC': path=specdir
  'RADV': path=rvdir
  'THAR': path=thardir
else: begin
  print,'Argument rtype must be one of SPEC, RADV, THAR'
  flist=['']
  return,flist
  end
endcase

; get directory listing
cmd='ls '+path+'/'+strtrim(rtype,2)+'*.fits'
spawn,cmd,dirlist
nfil=n_elements(dirlist)

; decide which parameter option we are using
np=n_params()
if(np eq 3 and top gt 0.) then nopt=1
if(np eq 3 and top lt 0.) then nopt=2
if(np eq 2 and bot gt 0.) then nopt=2
if(bot lt 0.) then nopt=3

; strip out numerical date information from filenames, if needed.
if(nopt eq 1 or nopt eq 2) then begin
  dates=dblarr(nfil)
  for i=0,nfil-1 do begin
    ix=strpos(dirlist(i),strtrim(rtype,2))
    dates(i)=double(strmid(dirlist(i),ix+4,13))
  endfor
endif

; get the desired filenames
case nopt of
  1: begin
    s=where(dates ge bot and dates le top,ns)
    if(ns gt 0) then flist=dirlist(s) else flist=['']
    end
  2: begin
    s=where(dates ge bot,ns)
    if(ns gt 0) then flist=dirlist(s) else flist=['']
    end 
  3: begin
    nn=-long(bot)
    if(nfil ge nn) then begin
      flist=dirlist(nfil-nn:nfil-1)
    endif else begin
      flist=dirlist
    endelse
    end
  endcase

return,flist
 
end
