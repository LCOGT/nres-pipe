pro keyword_rename,hdr,keyin,keyout
; this routine extracts the keyword keyin value and comment value (if any) from
; string array hdr.  If keyin is found, then this keyword is deleted from
; hdr, and it is replaced with {keyout value comment}.
; If keyin is not found, no action is performed.

val=sxpar(hdr,keyin,comment=comment)
if(!ERR ne -1) then begin
    sxaddpar,hdr,keyout,val,comment,before=keyin
    sxdelpar,hdr,keyin
endif

end
