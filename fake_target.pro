pro fake_target,targstrucs,targnames,targra,targdec
; This routine fills in targstrucs with invented but plausible stellar
; properties, in the case in which a target search fails.  This situation
; is identified by targstrucs.targname='NULL' but the corresponding value
; in targnames is neither 'NONE' nor 'THAR'.  

rutname='fake_target'

for i=0,1 do begin       ; loop over star fibers
  if(targstrucs(i).targname eq 'NULL' and (targnames(i) ne 'NONE') and $
      (targnames(i) ne 'THAR')) then begin
    targstrucs(i).targname=targnames(i)
    targstrucs(i).ra=targra(i)
    targstrucs(i).dec=targdec(i)
    targstrucs(i).vmag=6.0           ; invented
    targstrucs(i).bmag=6.8           ; invented
    targstrucs(i).teff=5500.         ; invented
    targstrucs(i).logg=4.0           ; invented
    logo_nres2,rutname,'INFO',{zero_match:targnames(i),teff:5500.,logg:4.0}

; leave griJK magnitudes at zero, likewise proper motion components
; and parallax.

  endif
endfor


end
