pro calibproc,calblock,usedlist,kerr
; This routine accepts a structure calblock containing information about
; a group of calibration images that have been 1st-stage processed by muncha,
; and that should be combined into a 2nd-stage calibration file.
; Depending on the type of the data (eg BIAS, DARK, etc) it calls the 
; appropriate routine to create a supercal.
; A list of the files that went into the supercal is returned in string array
; usedlist.
; On output,
;  kerr = 0 -> good return
;       = 1 -> bad image type
;       = 2 -> too few entries in list of input files
;       = 3 -> calblock is not valid

; unpack important data parameters
type=strtrim(strupcase(calblock.type))
nf=calblock.navg               ; number of valid pathnames in calblock.names
flist=calblock.names(0:nf-1)   ; list of files to process
flags=calblock.flag            ;### need to make flag a string array ###
valid=calblock.valid

if(type ne 'BIAS' and type ne 'DARK' and type ne 'FLAT' and type ne 'DOUBLE') $
     then begin
  kerr=1
  goto,fini
endif
if(valid ne 1) then begin
  kerr=3
  goto,fini
endif

; call the right routine to process the data
case type of
  'BIAS': begin
      if(nf lt 3) then begin
        kerr=2
        usedlist=['']
        goto,fini
      endif else begin
        avg_biasdark,type,flist
        usedlist=flist
      endelse
    end
  'DARK': begin
      if(nf lt 3) then begin
        kerr=2
        usedlist=['']
        goto,fini
      endif else begin
        avg_biasdark,type,flist
        usedlist=flist
      endelse
    end
  'FLAT': begin
      if(nf lt 2) then begin
        kerr=2
        usedlist=['']
        goto,fini
      endif else begin
        avg_flat,flist
        usedlist=flist
      endelse
    end
  'DOUBLE': begin
      if(nf lt 2) then begin
        kerr=2
        usedlist=['']
        goto,fini
      endif else begin
        print,'Can't handle DOUBLE files yet!'
        usedlist=['']
      endelse
    end
endcase

fini:
end
