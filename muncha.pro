pro muncha,filin,dbg=dbg,trp=trp,tharlist=tharlist,cubfrz=cubfrz,$
  oskip=oskip,nostar=nostar, literal=literal
; This is the main routine organizing the processing pipeline for NRES
; spectroscopic data.
; On input:
;   filin = the path to a FITS data file (with extensions) written by the
; The routine also reads data from these config files:
;   csv/spectrograph.csv
;   csv/targets.csv:  target entries taken from POND before observing time
; NRES data-acquisition process.
; On output:
;   This routine writes or modifies the following files, where xxx = string
;      containing filename root:
;   If type = TARGET:
;     temp/xxx.obs.txt: list of header metadata to go into obs database table
;  in the following, the 'reduced' directory is 
;  actually 'nresroot/$NRESINST/reduced', where $NRESINST is the reduction
;  instance.
;     reduced/autog/xxx.ag.csv: contains autoguider stats
;     reduced/expm/xxx.exp.csv: contains exposure meter stats
;     reduced/thar/xxx.thar.csv:  contains lambda solution coeffs, stats
;     reduced/spec/xxx.spec.fits: extracted spectra, ThAr wavelength solution
;     reduced/ccor/xxx.ccor.fits: contains cross-corr results by order, block
;     reduced/rv/xxx.rv.csv: contains rv solution stats
;     reduced/class/xxx.cls.csv: contains stellar classification results, stats.
;     reduced/diag/xxx.diag*.ps: diagnostic plots to be saved in DB.
;   If type = DARK
;     reduced/dark/xxx.dark.fits: dark image, copied from input file
;     csv/standards.csv:  muncha updates this file
;   If type = FLAT
;     reduced/flat/xxx.flat.fits: contains extracted flats
;     reduced/trace/xxx.trc.fits: contains trace file for this flat
;     csv/standards.csv:  muncha updates this file
;   If type = DOUBLE
;     reduced/dble/xxxtrip.fits:  contains extracted double spectrum    
;     csv/standards.csv:  muncha updates this file
; If keyword dbg is set, then certain debugging plots are produced by
;  routine thar_wavelen and some of its daughter routines.
; If keyword trp is set, its value determines the source of starting
;  data for arrays coefs_c and fibcoefs_c, as follows:
;    trp=0 or absent:  coefs_c and fibcoefs_c come from the TRIPLE file.
;    trp=1: coefs_c from spectrographs.csv, fibcoefs_c from TRIPLE.
;    trp=2: coefs_c from TRIPLE and fibcoefs_c from spectrographs.csv.
;    trp=3: both coefs_c and fibcoefs_c from spectrographs.csv.
; If keyword tharlist is set, its value is taken as the name of a file
;   in reduced/config containing vacuum wavelengths and intensities of
;   good ThAr lines.  Normally, this file will have been written by
;   routine thar_wavelen, following some user editing of the Redman line list. 
; If keyword cubfrz is set, it prevents the rcubic coefficients read from
;   spectrographs.csv from being altered in the ThAr line-fitting process.
; If keyword oskip is set and not zero, then order oskip-1 is skipped in
; the wavelength solution.  Used for testing for bad lines.
; If keyword nostar is set and not zero, and if the input file is of type
;   TARGET, then processing is conducted only through the wavelength
;   solution, and no star radial velocities are computed.  This saves time
;   in cases in which we desire a lot of wavelength solutions to be averaged,
;   eg for tracking the time behavior of wavlen solution parameters.

compile_opt hidden

@nres_comm

; constants
verbose=1                         ; 0=print nothing; 1=dataflow tracking
rutname='muncha'

; record start in logfile
logstr='input filename = '+strtrim(filin,2)
logo_nres2,rutname,'INFO',logstr

nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
tempdir='temp/'
agdir='reduced/autog/'
biasdir='reduced/bias/'
blazdir='reduced/blaz/'
extrdir='reduced/extr/'
darkdir='reduced/dark/'
dbledir='reduced/dble/'
expmdir='reduced/expm/'
thardir='reduced/thar/'
specdir='reduced/spec/'
ccordir='reduced/ccor/'
rvdir='reduced/rv/'
classdir='reduced/class/'
diagdir='reduced/diag/'
csvdir='reduced/csv/'
flatdir='reduced/flat/'
tracedir='reduced/trace/'
tripdir='reduced/trip/'
zerodir='reduced/zero/'
tardir='reduced/tar/'
filin0=filin

; open the input file, read data segments and headers into common
ingest,filin,err,literal=literal
if(err) then begin
  logstr='Invalid input data in ingest.  Err = '+string(err,format='(i2)')
  logo_nres2,rutname,'INFO',logstr
  goto,fini
endif

; branch on type of input data
if(verbose) then print,'OBSTYPE = ',type
logo_nres2,rutname,'INFO',' OBSTYPE = '+type
case 1 of

; one or two stars plus ThAr.  Routines write out metadata files as they go
; (type eq 'EXPERIMENTAL'): begin         ; temporary, to deal with Rob's test file
  (type eq 'TARGET'): begin
  logo_nres2,rutname,'INFO','###TARGET block'
  if(verbose) then print,'###TARGET block'
; test for TARGET image with invalid OBJECTS keyword
  if(objects eq 'none&none&none') then begin
    logo_nres2,rutname,'ERROR','TARGET with objects=none&none&none'
    break
  endif
  calib_extract,flatk=0
  autoguider
  expmeter
  if not keyword_set(tharlist) then begin
    tharlist = 'mtchThAr.txt'
;     tharlist = 'arc_ThAr_Redman.txt'
  endif
  thar_wavelen,dbg=dbg,trp=trp,tharlist=tharlist,cubfrz=cubfrz,oskip=oskip
  if(not keyword_set(nostar)) then begin
    radial_velocity,ierr,nostar=nostar
    plot_quick           ; writes quick-look postscript plot
  endif
; spec_classify
; obs2txt                ; writes all metadata to obs.txt
  plot_qc                ; writes extract and thar quality control plot
  tarpath=nresrooti+tardir
  tarout2,tarlist,tarpath   ; collect useful output into a directory, tar it.
  end

; a bias image.  Make copy in reduced/bias dir, add entry to csv/standards.csv
  (type eq 'BIAS'): begin
  logo_nres2,rutname,'INFO','###BIAS block'
  if(verbose) then print,'###BIAS block'
  copy_bias
  end

; a dark image.  Make copy in reduced/dark dir, add entry to csv/standards.csv
  (type eq 'DARK'): begin
  logo_nres2,rutname,'INFO','###DARK block'
  if(verbose) then print,'###DARK block'
  copy_dark
  end

; a flat image
  (type eq 'FLAT' or type eq 'LAMPFLAT'): begin
  logo_nres2,rutname,'INFO','###FLAT block'
  if(verbose) then print,'###FLAT block'
  calib_extract,flatk=1
  mk_flat1         ; makes single flat extracted spec, not an average
  end

; a DOUBLE image
  (type eq 'DOUBLE' or type eq 'ARC'): begin
  logo_nres2,rutname,'INFO','###DOUBLE block'
  if(verbose) then print,'###DOUBLE block'
  calib_extract,/dble
  mk_double1,ierr      ; saves pointer to output file in standards.csv file.
  end

; bad input
  else: begin
    logo_nres2,rutname,'ERROR','FATAL  Invalid data file TYPE keyword'
    if(verbose) then print,'Invalid data file.  Type must be TARGET, BIAS, DARK, (FLAT or LAMPFLAT), or (DOUBLE or ARC).'
  end
endcase

fini:
end
