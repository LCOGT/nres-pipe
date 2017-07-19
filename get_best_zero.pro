pro get_best_zero,fnames,teffs,loggs,bmvs,jmks,flags,$
     teff,logg,bmv,jmk,crit,name_out,jerr
; This routine searches the zero.csv file for files that are flagged
; as 'blind' standards, and returns the one that is closest (in some sense)
; to the provided parameters teff, logg, bmv, jmk.
; Which parameters are to be compared are governed by input parameter crit:
;   crit = 'teff_logg' -> use 2D distance in teff-logg space
;        = 'B-V' -> use closest B-V value
;        = 'J-K' -> use closest J-K value
; On output,
;  name_out = the path to the desired ZERO file
;  jerr = 0 on normal exit, otherwise error.

; read the zeros.csv file, select lines with 2nd char of FLAGS = 1
flagc=strtrim(strmid(flags,1,1),2)
s=where(flagc eq '1',ns)
if(ns le 0) then begin
  print,'in get_best_zero, no entries with flags(1)=1'
  jerr=3
  ;stop
  goto,fini
endif else begin
; select the variables we are going to need
  fnames=fnames(s)
  teffs=teffs(s)
  loggs=loggs(s)
  bmvs=bmvs(s)
  jmks=jmks(s)
endelse

;crit cases
case crit of
  'teff_logg': begin
    dt=teffs-teff
    dlg=loggs-logg
    dist=sqrt((dt/1000.)^2+(dlg/2.0)^2)    ; an arbitrary distance measure
    md=min(dist,ix)
    name_out=fnames(ix)
    jerr=0
  end
  'B-V': begin
    difs=abs(bmvs-bmv)
    md=min(difs,ix)
    name_out=fnames(ix)
    jerr=0
  end
  'J-K': begin
    difs=abs(jmks-jmk)
    md=min(difs,ix)
    name_out=fnames(ix)
    jerr=0
  end
  else: begin
    print,'in get_best_zero: ',crit,' = illegal value' 
    jerr=4
  end
endcase

fini:
end 
