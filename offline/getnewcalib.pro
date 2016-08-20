pro getnewcalib,stdpath,combpath,combdat,combhdr,tn,difdat,calblocks,ierr
; This routine reads the standards.csv file containing all calibration
; files processed by muncha, and the combined.csv file, containing all
; 1st-stage calibration files that have been processed into 2nd-stage
; calibrations.  It differences these two lists, and returns a structure
; difdat containing the unused calib files, in standards.csv format, and an
; array calblocks of structures containing descriptions of chunks of files
; segregated by type, site, and creation date.  For each chunk, the
; calblocks structures  calib types, sites, cameras, creation dates, 
;   muncha-processed filenames, and flags).
; boundaries of chunks of data of the same type, site.
; On return, ierr=0 -> no error
;            ierr=1 -> no new files
;            ierr=2 -> combined.csv file is locked
;            ierr>2 -> other fatal error
; On input, structure tn contains time intervals in days used for identifying
; valid chunks of input files.

; constants
root=getenv('NRESROOT')
scrstdpath=root+'reduced/csv/scrstd.csv'
scrinputpath=root+'reduced/csv/scrinput.csv'
vtypes=['BIAS','FLAT','DARK','DOUBLE'] ; types that can be combined
vsites=['sqa','bpl','lsc','cpt','elp'] ; sites with NRES spectrographs
ntypes=n_elements(vtypes)
nsites=n_elements(vsites)

; test whether the combined.csv is locked.
; combined.csv should have exactly the format of standards.csv,
; except the header line consists of either 'OPEN','OPEN'.....
;                                    or     'LOCKED','LOCKED',...
ierr=0
dat=read_csv(combpath,header=combhdr)
;###### temporarily bypass this test, to help debugging
;if(combhdr(0) ne 'OPEN') then begin
; ierr=2                   ; bail with ierr=2 if file is locked
; goto,fini
;endif else begin
; rewrite the file with header line 'LOCKED'...
; headerlock=['LOCKED','LOCKED','LOCKED','LOCKED','LOCKED','LOCKED','LOCKED']
; write_csv,combpath,dat.field1,dat.field2,dat.field3,dat.field4,dat.field5,$
;    dat.field6,dat.field7,header=headerlock
;endelse
;###### end bypass
combdat=dat

; get the standards.csv file, exclude lines with navg ne 1, or invalid type
; or invalid site.
stds_rd,stdtypes,stdfnames,stdnavgs,stdsites,stdcameras,stdjdates,$
  stdflags,stdhdr 
s1=where((stdnavgs eq 1) and (stdtypes eq vtypes(0) or stdtypes eq vtypes(1) $
    or stdtypes eq vtypes(2) or stdtypes eq vtypes(3)) and $
    (stdsites eq vsites(0) or stdsites eq vsites(1) or stdsites eq vsites(2))$
    ,ns1)
stdtypes=stdtypes(s1)
stdfnames=stdfnames(s1)
stdnavgs=stdnavgs(s1)
stdsites=stdsites(s1)
stdcameras=stdcameras(s1)
stdjdates=stdjdates(s1)              ; creation dates of muncha output files
stdflags=stdflags(s1)

; write these lines out to a temporary file in the csv directory
write_csv,scrstdpath,stdtypes,stdfnames,stdnavgs,stdsites,stdcameras,$
    stdjdates,stdflags,header=headerlock

; diff scrstd.csv - combined.csv, strip out the "< " substring that indicates
; a line present in scrstd that is absent in combined.csv, and write the
; results as a csv file to scrinput.csv.  Read it back in to get a string array
cmd='diff '+scrstdpath+' '+combpath+' | grep "<" | tr -d "< "  | uniq > ' + $
    scrinputpath
spawn,cmd
difdat=read_csv(scrinputpath)

; difdat is a structure containing vectors in the same format as standards.csv,
; describing calib files that have not been incorporated into supercals.
; first verify that the structure is not empty, then unpack elements into
; named vectors.
sz=size(difdat)
if(sz(0) eq 0) then begin
  ierr=1           ; no good files
  goto,fini
endif  

diftypes=difdat.field1
difnames=difdat.field2
difnavgs=difdat.field3
difsites=difdat.field4
difcams=difdat.field5
difjds=difdat.field6
difflags=difdat.field7

; make an array difpaths of (string) calib file pathnames, 
; ordered into chunks of
; similar data (ie of same type, from same site, close together in time).  
; The ends of chunks are
; indicated by an element consisting of the string 'xx'.
; The last chunk from each site is followed by an end-of-data string 'zz',
; unless it may be incomplete, because of a too-short time between
; the last data date and the current date.  In that case the
; end-of-data string is given as 'uu'.
; Afterwards, produce a count of chunks nchunk and a vector
; nchfile(nchunk) = number of files to process in each chunk.
; If end-of-data = 'uu', then nchfile for the last chunk is set to zero.

difpaths=['']            ; holds pathnames and chunk end indicators
; start array of structures with chunk parameters
calblocks=[{type:diftypes(0),names:strarr(100),navg:difnavgs(0),$
    site:difsites(0),cam:difcams(0),jdc:difjds(0),flag:difflags(0),$
    valid:0}]
jdcur=systime(/julian)

; loop over legal observation types
for i=0,ntypes-1 do begin
  ityp=vtypes(i)
  
; loop over possible sites
  for j=0,nsites-1 do begin
    jsite=vsites(j)
    sg=where(diftypes eq ityp and difsites eq jsite,nsg)
    if(nsg gt 0) then begin
      print,'nsg=',nsg
      for k=0,nsg-1 do begin
        if(k eq 0) then begin
; get here on 1st file of a group with same type and site
          difpaths=[difpaths,difnames(sg(k))]
        endif else begin      
          dt=difjds(sg(k))-difjds(sg(k-1))
          if(ityp eq 'DARK') then begin            ; type = 'DARK'
            if(dt le tn.t2d) then good=1 else good=0
          endif else begin                    ; type not 'DARK'
            if(dt le tn.t2) then good=1 else good=0
          endelse
; good=1 means the current file is a continuation of a valid chunk
          if(good eq 1) then begin 
            difpaths=[difpaths,difnames(sg(k))]
          endif else begin
            difpaths=[difpaths,'xx',difnames(sg(k))]
; add new element to calblocks array of structures
            calblocks=[calblocks,{type:ityp,names:strarr(100),navg:0L,$
                site:jsite,cam:difcams(sg(k)),jdc:difjds(sg(k)),$
                flag:difflags(sg(k)),valid:1}]
          endelse
        endelse 
      endfor
; check to see if the last chunk is so recent that it may be incomplete.
    dtnow=jdcur-difjds(sg(k-1))
    if(dtnow le tn.t3) then begin
      difpaths=[difpaths,'uu'] 
      calblocks=[calblocks,{type:ityp,names:strarr(100),navg:0L,site:jsite,$
          cam:difcams(sg(k-1)),jdc:difjds(sg(k-1)),flag:difflags(sg(k-1)),$
          valid:0}]
    endif else begin
        difpaths=[difpaths,'zz']
        calblocks=[calblocks,{type:ityp,names:strarr(100),navg:0L,site:jsite,$
            cam:difcams(sg(k-1)),jdc:difjds(sg(k-1)),flag:difflags(sg(k-1)),$
            valid:1}]
    endelse
    endif
  endfor

endfor

difpaths=difpaths(1:*)
calblocks=calblocks(1:*)

; read through difpaths to establish nchunks and nchfile
ndpath=n_elements(difpaths)
nchunks=0
nchfile=[0]
if(ndpath gt 0) then begin
  ic=0                        ; index of current chunk
  nc=0                        ; number of paths in current chunk
  for i=0,ndpath-1 do begin
    dpi=difpaths(i)
    if(dpi ne 'xx' and dpi ne 'uu' and dpi ne 'zz') then begin
      calblocks(nchunks).names[nc]=dpi
      nc=nc+1
      calblocks(nchunks).navg=nc ; navg stores the number of files in chunk
    endif else begin
      nchfile=[nchfile,nc]
      nchunks=nchunks+1
      nc=0
    endelse
  endfor
endif

if(nchunks gt 0) then nchfile=nchfile(1:*)

fini:

end
