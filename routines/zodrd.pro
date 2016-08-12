pro zodrd,file,var
; this routine reads a zodiac dump file in filename 'file' into the
; zodiac variable var

hdr=lonarr(20)
close,11
openr,11,file
readu,11,hdr
print,hdr
d1=hdr(2) > 1
d2=hdr(3) > 1
d3=hdr(4) > 1
if (hdr(1) eq 0) then var=intarr(d1,d2,d3) else var=fltarr(d1,d2,d3)
readu,11,var
close,11
end
