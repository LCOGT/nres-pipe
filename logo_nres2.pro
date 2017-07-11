pro logo_nres2,rutname,log_level,logval
; This routine concatenates a leading timetag, the 8-char fixed-width
; string log_level, the string rutname, 
; and a parameter logval, containing whatever you wish to say, perhaps
; with tag values appended.
; and appends the result to the NRES logfile 
;  $NRESROOT/NRESINST/log_muncha.txt.
; The currently-understood values of log_level are
; one of 'DEBUG', 'INFO', 'WARNING', 'ERROR', and 'CRITICAL'.
; logval may be either a scalar string or a structure (containing tags and
; values).  Only scalar tags are allowed;  no vectors.
; Valid data types for structure elements are: byte, int, long, float, 
; double, string.
; The tag name strings are searchable using standard LCO tools.

; constants
ts0=210866760000.d0               ; JD of 0h 1 Jan 1970

root=getenv('NRESROOT')
inst=getenv('NRESINST')
logo='log_muncha.txt'
outfil=strtrim(root,2)+strtrim(inst,2)+'/'+strtrim(logo,2)
openw,iuno,outfil,/get_lun,/append

tsys=systime(/sec)               ; only IDL system time respecting fractional s.
jdsys=(ts0+tsys)/86400.d0        ; julian date, to ms.
caldat,jdsys,mm,dd,yy,hh,mn,ss      ; convert to calendar date
yys=string(yy,format='(i4)')
mms=string(mm,format='(i02)')
dds=string(dd,format='(i02)')
hhs=string(hh,format='(i02)')
mns=string(mn,format='(i02)')
sss=string(ss,format='(f06.3)')
datims=yys+'-'+mms+'-'+dds+' '+hhs+':'+mns+':'+sss+' '  ; output date/time str

rutnames=strtrim(rutname,2)
rutlen=strlen(rutnames)
if(rutlen gt 15) then rutnames=strmid(rutnames,0,15)  ; routine name string
 
levs=string(log_level,format='(a8)')+' '        ; log level string

; look at logval, determine if string or structure
sz=size(logval)
ltyp=-1                                  ; indicates illegal arg type
if(sz(0) eq 0 or sz(0) eq 1) then begin
  if(sz(sz(0)+1) eq 7) then ltyp=0       ; indicates string
  if(sz(sz(0)+1) eq 8) then ltyp=1       ; indicates structure
endif

if(ltyp eq 0) then begin
  tagss=logval
endif
if(ltyp eq 1) then begin
  tags=tag_names(logval)
  ntags=n_elements(tags)
  tagss='{'
  for i=0,ntags-1 do begin
     ctag=tags(i)
     vtag=logval.(i)
     sz=size(vtag) 
     vtype=sz(sz(0)+1)
     tagss=tagss+'"'+strtrim(ctag,2)+'":'
     case vtype of
       1: tagss=tagss+strtrim(string(fix(vtag)),2)+', '
       2: tagss=tagss+strtrim(string(vtag),2)+', '
       3: tagss=tagss+strtrim(string(vtag),2)+', '
       4: tagss=tagss+strtrim(string(vtag,format='(e14.7)'),2)+', '
       5: tagss=tagss+strtrim(string(vtag,format='(e19.12)'),2)+', '
       7: tagss=tagss+'"'+vtag+'" ,'
     endcase
  endfor 
; truncate the last comma, put in trailing '}'
  tlen=strlen(tagss)
  tagss=strmid(tagss,0,tlen-2)+' }'
endif

; assemble the whole string
ostring=datims+rutnames+levs+tagss

stop

printf,iuno,ostring

close,iuno
free_lun,iuno

end
