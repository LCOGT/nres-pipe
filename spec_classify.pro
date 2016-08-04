pro spec_classify,ierr
; This routine estimates stellar structure properties teff, logg, logZ,
; vsini from data stored in common structures echdat, tharred,.....
; meta- and ancillary data are returned in the common
; structure spclassred, and some metadata are written to a
; FITS binary table in directory reduce/class

@nres_comm

; constants
null=-99.9
ierr=0

targnames=[crossred.targstrucs[0].targname,crossred.targstrucs[1].targname]
targra=[crossred.targstrucs[0].ra,crossred.targstrucs[1].ra]
targdec=[crossred.targstrucs[0].dec,crossred.targstrucs[1].dec]
obsmjd=sxpar(dathdr,'OBS-MJD')

; estimate stellar classification parameters, QC params
teff=5000.
logg=4.0
logz=0.0
vsini=2.0
errteff=200.
errlogg=0.15
errlogz=0.1
errvsini=1.0

; write results to reduce/class directory

; build output structure

classred={teff:teff,logg:logg,logz:logz,vsini:vsini,$
          errteff:errteff,errlogg:errlogg,errlogz:errlogz,errvsini:errvsini}

if(verbose ge 1) then begin
  print
  print,'*** spec_classify ***'
  print,'targets(s) =',targnames
  print,'MJD=',obsmjd
endif

end
