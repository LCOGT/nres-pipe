pro fake_header3,filin,filout
; this routine reads a Sedgwick FLAT type data file and fixes OBSTYPE keyword
; as necessary to fix various oddball values that turn up in real data.

dd=readfits(filin,hdr)
hdro=hdr
sz=size(dd)
nx=sz(1)
stop
if(nx eq 2080) then begin
  obstype=sxpar(hdro,'OBSTYPE')
  nn=strpos(obstype,'FLAT')
  if(nn ge 0) then begin
    sxaddpar,hdro,'OBSTYPE','FLAT'
    if(sxpar(hdro,'OBJECTS') eq 0) then begin
      sxaddpar,hdro,'OBJECTS','FLAT&FLAT'
    endif
  endif
endif else begin
  print,'File is not from Sedgwick'
endelse

writefits,filout,dd,hdro

end
