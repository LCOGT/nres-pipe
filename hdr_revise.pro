pro hdr_revise,hstruc0,hstruc
; This routine removes some header keywords that are deemed superfluous, but
; that we may want back later, renames a few others on an ad hoc basis,
; and changes the names of many based on which fiber(s) are active.
; on input,
; hstruc0={keyall:hdr0,extr:hdr1,spec:hdr2,blaz:hdr3,wavespec:hdr4,$
;  thar_i:hdr4,thar_f:hdr6,wavethar:hdr7,xcor:hdr8,wblocks:hdr9}

; pull the hstruc0 structure apart for convenience
hdr0=hstruc0.keyall
hdr1=hstruc0.extr
hdr2=hstruc0.spec
hdr3=hstruc0.blaz
hdr4=hstruc0.wavespec
hdr5=hstruc0.thar_i
hdr6=hstruc0.thar_f
hdr7=hstruc0.wavethar
hdr8=hstruc0.xcor
hdr9=hstruc0.wblocks

; rename DATESTRD because the fits standard thinks this means something
keyword_rename,hdr1,'DATESTRD','DATSTRNG'

; rename averaged redshift keywords to connect with output data columns
;keyword_rename,hdr9,'REDSHA0','ZBLKAVG'
;keyword_rename,hdr9,'REDSHM0','ZBLKMED'
;keyword_rename,hdr9,'REDSHER0','ZBLKERR'

; remove NDPOS because probably redundant
sxdelpar,hdr0,'NDPOS'

; remove F{012}{OBSTYP,SOURCE} because not currently populated by site
; software, currently not used.
sxdelpar,hdr0,'F0OBSTYP'
sxdelpar,hdr0,'F1OBSTYP'
sxdelpar,hdr0,'F2OBSTYP'
sxdelpar,hdr0,'F0SOURCE'
sxdelpar,hdr0,'F1SOURCE'
sxdelpar,hdr0,'F2SOURCE'

; if FIB0=0, then rename all AMPFL0xx keywords to AMPFLxx, remove all AMPFL1xx
; if FIB0=1, then rename all AMPFL1xx keywords to AMPFLxx, remove all AMPFL0xx
fib0=sxpar(hdr1,'FIB0')
nord=sxpar(hdr1,'NORD')
ampfl='AMPFL'
for i=0,nord-1 do begin
  strord=string(i,format='(i02)')
  if(fib0 eq 0) then begin
    namold='AMPFL0'+strord
    namnew='AMPFL'+strord
    namr='AMPFL1'+strord
  endif else begin
    namold='AMPFL1'+strord
    namnew='AMPFL'+strord
    namr='AMPFL0'+strord
  endelse
  sxdelpar,hdr3,namr
  keyword_rename,hdr3,namold,namnew
endfor
   
; rebuild header structure for output
hstruc={keyall:hdr0,extr:hdr1,spec:hdr2,blaz:hdr3,wavespec:hdr4,$
  thar_i:hdr4,thar_f:hdr6,wavethar:hdr7,xcor:hdr8,wblocks:hdr9}

end
