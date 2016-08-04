pro ts_diag0,bot,top,diagout
; This routine is a script to run diagnostics on time series of NRES data.
; the files processed are chosen according to the input arguments bot, top,
; as described below.
; bot, top = arguments defining the range of filenames to be retrieved.
;         There are 3 possibilities:
;         (1) bot, top are positive long doubles, eg 2016148.21365.  In this
;           case, filenames with embedded date strings in the range [top,bot]
;           are returned.
;         (2) bot is as above, but top is negative.  In this case, 
;           filenames with embedded date strings >= bot are returned.
;         (3) bot is a negative integer -N.  In this case,
;           the last N entries in the default-sorted ls listing of the indicated
;           directory are returned.
;
; Data are returned in structure diagout.  They are
;  cfts(15,nt) = wavelength solution restricted cubic coefficients
;  parm4(4,nt) = spectrograph major parameters {sinalp,fl,y0,z0} 
;  itemp(nt) = Sinistro inlet temperature (degree C)
;  tslamb(nx,nord,nt) = wavelength solutions for fiber1
;  match = structure containing line matching data
;  ts2(nt,4) = 
; 0=blocks 0-5 and 1= blocks 6-11, both with zeroes in the roall array ignored.
; 2=blocks 0-5 and 3= blocks 6-11, with both zeroes and bad orders ignored
;  roall(nord,nblock,nt) = containing the redshifts by order
; and block for each time, for fiber=1. 

; get the wavelength solution info
tflist=get_ts_flist('THAR',bot,top)
rd_coefts,tflist,cfts,parm4,itemp,mjd,tslamb,match

; get info on star spectrum shifts
rvflist=get_ts_flist('RADV',bot,top)
ts2med,rvflist,ts2,roall

; make the output structure
diagout={cfts:cfts,parm4:parm4,itemp:itemp,mjd:mjd,tslamb:tslamb,match:match,$
         ts2:ts2,roall:roall}

; plot some general diagnostics
; wavelength solution
plot_lamdiag,diagout

; stellar rv
plot_rvdiag,diagout

end
