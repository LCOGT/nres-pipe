pro expmeter
; This routine examines the expmeter data stream expmdat and returns
; (in common) statistics on the behavior of all 3 fibers for the
; current image.  If one or the other telescopes is not used for the
; image, all of its return values are returned as zeros.
; Data are returned as structure expmred.  It contains
;   expm exposure time
;   flux-weighted mean time of each fiber exposure
;   total accumulated counts for each fiber
;   relative rms variation of intensity from each fiber
; Before exit, writes a FITS file containing the expfwt, expcnt, exprms
; statistics for each fiber into the expm directory.
;      

@nres_comm

; this is brought in by ingest.pro
;expmdat={nt_expm:nt_expm,jd_expm:jd_expm,fib0c:fib0c,fib1c:fib1c,fib2c:fib2c,$
;        flg_expm:flg_expm}

; stub stuff in next line --  should refer to keyword from expmhdr
expetime=sxpar(dathdr,'EXPTIME')

; more stub stuff --  use exposure center time instead of flux-weighted
; mean, accumulated counts and rms intensity are invented.

expstart=2400000.5d0+sxpar(dathdr,'MJD-OBS')
expmid=expstart+expetime/86400.d0

if(nfib eq 2) then begin       ; do this if only 2 fibers exist
  expfwt=[expmid,expmid]
  expcnt=[1.35e8,0.98e8]       ; invented data
  exprms=[0.42,0.53]           ; ditto
endif

if(nfib eq 3) then begin       ; do this if 3 fibers exist
  expfwt=[expmid,expmid,expmid]
  expcnt=[1.35e8,0.98e8,2.02e8]
  exprms=[0.42,0.53,0.31]
endif

expmred={expetime:expetime,expfwt:expfwt,expcnt:expcnt,exprms:exprms}

print,'Finished expmeter.pro'

dato=[expfwt,expcnt,exprms]
mkhdr,hdr,dato
sxaddpar,hdr,'NFIB',nfib
filout=nresrooti+expmdir+'EXPM'+datestrd+'.fits'
writefits,filout,dato,hdr

end
