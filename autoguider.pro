pro autoguider
; This routine examines the autoguider data streams agu1, agu2 and returns
; (in common) statistics on the performance of both autoguiders for the
; current image.  If one or the other telescopes is not used for the
; image, all of its return values are returned as zeros.
; Data are returned as structures agu1red and agu2red.  Each contains
;   guider operation mode (WCS_match, guide-to-brightest, or whatever)
;   mean and rms of x- and y- guider corrections
;   min and max number of stars matched for guiding
;   total number of guider frames, number with failed matches
;      

@nres_comm

; determine which AGUs are active, based on dathdr keyword '????'
aguact=intarr(2)+1           ; active = 1 assumed by default

; stub stuff in next 3 lines --  should refer to keyword from tel1hdr, tel2hdr
words=get_words(sxpar(dathdr,'OBJECTS'),nwd,delim='&')
tel1hdr=dathdr
tel2hdr=dathdr

if(nwd eq 2) then begin       ; do this if only 2 fibers exist
  aguact(0)=0 
  if(words(1) = 'NONE') then aguact(1)=0
endif

if(nwd eq 3) then begin       ; do this if there are 3 fibers
  if(words(0) = 'NONE') then aguact(0)=0
  if(words(2) = 'NONE') then aguact(1)=0
endif

dcoo1=[0.,0.]      ; mean guider displacements, x/y, AGU1
dcoo2=[0.,0.]      ; ditto for AGU2
rmscoo1=[0.,0.]    ; rms guider corrections (pix?), AGU2
rmscoo2=[0.,0.]    ; ditto for AGU2
nmstars1=[0L,0L]   ; min,max number of matched stars, AGU1
nmstars2=[0L,0L]   ; ditto for AGU2

; add total # of images, number with no matches, avg and rms skyval.

for i=0,1 do begin   ; fill in the values for each AGU
endfor

agu1red={dcoo1:dcoo1,rmscoo1:rmscoo1,nmstars1:nmstars1}
agu2red={dcoo2:dcoo2,rmscoo2:rmscoo2,nmstars2:nmstars2}

print,'Finished Autoguider.pro'

end
