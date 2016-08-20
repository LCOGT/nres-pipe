pro calib2control
; This routine controls the creation of 2nd-stage calibration files
; of type BIAS, DARK, FLAT, TRIPLE, 
; from 1st-stage (ie not averaged or otherwise combined) files of type
; BIAS, DARK, FLAT, DOUBLE that have already been processed by muncha.pro.
;
; This routine should be started by a cron job every T1 minutes (probably
; T1 ~ 20).  It reads the standards.csv file to locate all existing 1st-stage
; calib files, and differences this list with that in combined.csv,
; to locate calibration images that have been processed by muncha, but that
; have not yet been combined into 2nd-stage calibrations.
; It then tries to form blocks of related files, ie files of the same type,
; from the same site, with members separated in time by less than T2 ~ 4 min
; (longer for DARKs), and with the last file either followed (in time order)
; by a file of a different type from the same site, or with an age greater
; than T3 ~ 20 min.  If such a block is found, then all of its files are
; combined (in a manner appropriate to the file type) into a 2nd-stage
; calibration.  This file is placed in the appropriate reduced/subdirectory
; and its information is added as a line to the standards.csv file.
; Also all files in the block have their names added to the combined.csv file.

; constants and paths
t2=3./1440.                 ; T2 (days) max sep between non-dark block elems
t2d=7./1440.                ; T2D = max sep between DARK block elements
t3=20./1440.                ; T3 = min gap to guarantee a new block
tn={t2:t2,t2d:t2d,t3:t3}
root=getenv('NRESROOT')
configpath=root+'reduced/config/'
csvpath=root+'reduced/csv/'
stdpath=csvpath+'standards.csv'
combpath=csvpath+'combined.csv'
types=['BIAS','FLAT','DARK','DOUBLE'] ; types that can be combined
sites=['sqa','bpl','lsc','cpt','elp'] ; sites with NRES spectrographs
ntypes=n_elements(types)
nsites=n_elements(sites)

; read config file.  Results come back in calcontrol structure
rd_calcontrol,calcontrol

; do diff standards-combined.  ierr=0 means good files to process
; combfiles=list of files in combined.csv
; newfiles=calib files that do not appear in combined.csv
getnewcalib,stdpath,combpath,combdat,combhdr,tn,difdat,calblocks,ierr
if(ierr ne 0) then begin
  if(ierr eq 1) then begin    ; test for no valid files to use
                              ; if none found, rewrite combdat w/ orig header
    write_csv,combpath,combdat.field1,combdat.field2,combdat.field3,$
        combdat.field4,combdat.field5,combdat.fieldt,combdat.field6,$
        combdat.field7,header=cmbhdr
    goto,fini
  endif
  if(ierr eq 2) then begin    ; test for locked combined file
    goto,fini                 ; if so, bail out with no action
  endif
; deal here with no valid input files, or other error
; includes check that combined.csv is not locked
endif
stop

; loop over calblocks
ncblk=n_elements(calblocks)
kerrlist=intarr(ncblk)
for j=0,ncblk-1 do begin
  calibproc,calblocks(j),usedlist,kerr
  kerrlist(j)=kerr
endfor

stop

; write modified, unlocked combined.csv file
writecombined,combpath,combdat,combhdr,difdat,calblocks,kerrlist

fini:
end
