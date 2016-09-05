pro fake_header6,filin,filout
; this routine reads a lab data file filin and if it is of 
; OBSTYPE = 'TARGET' and has one of its OBJECTS keyword values = 'SUN',
; it sets the RA and DEC
; keywords to 00:00:00.1 and 01:00:00, respectively.

dd=readfits(filin,hdr)
hdro=hdr
sz=size(dd)
nx=sz(1)
obstype=sxpar(hdr,'OBSTYPE')
objects=strtrim(sxpar(hdr,'OBJECTS'),2)
objs=get_words(objects,delim='&')
objs=strupcase(objs)
if (strtrim(obstype,2) eq 'TARGET') then begin
  if(strtrim(objs(0),2) eq 'SUN' or strtrim(objs(2),2) eq 'SUN') then begin
    sxaddpar,hdro,'RA','00:00:00.100'
    sxaddpar,hdro,'DEC','01:00:00.00'
  endif
endif

; strip out blank lines, just because
nl=n_elements(hdro)
hdro1=['']
for i=0,nl-1 do begin
  ss=hdro(i)
  nnbl=strlen(strtrim(ss,2))
  if(nnbl gt 0) then hdro1=[hdro1,ss]
endfor
hdro1=hdro1(1:*)   

;stop

writefits,filout,dd,hdro1

end
