pro tarout2,tarlist,tarpath
; This routine creates a directory tardirsssyyyyddd.fffff in the directory 
; specified in tarpath
; (usually nresrooti+'tar/').  It then reads the key files listed in the 
; string array tarlist, and creates the needed data blocks and headers
; so that these data can be written as a single multi-extension FITS file.
; It creates this file and writes it into this directory, along with
; a separate plotting dat file. 
; It then creates a tarball of the rice-compressed main data file and the
; plot file, named with all the trailing site & date info as in
; the tar directory.
; Having made the tarball, it deletes the directory it just tarred.
; Last, it appends the full pathname to the tarball to a file 
; named 'beammeup.txt' in the reduced/tar directory.
; The wrapper should, at some point, archive all of the files pointed to by
; beammeup, remove these files from the reduced/tar directory, and remove
; the file beammeup.txt.

; constants
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
thardir='reduced/thar/'
rvdir='reduced/rv/'
extrdir='reduced/extr/'
specdir='reduced/spec/'
blazdir='reduced/blaz/'
csvdir='reduced/csv/'

; check to see that tarlist contains at least 1 entry, and at least one
; with the substring 'EXTR' in its name.

nf=n_elements(tarlist)
ix=-1
if(nf ge 1) then begin
  for i=0,nf-1 do begin
    pos=strpos(tarlist(i),'EXTR')
    if(pos ge 0) then begin
      ix=i
      break
    endif
  endfor
endif

if(ix lt 0) then begin
  filelist_to_print = strjoin(tarlist, ',')
  logo_nres2,rutname,'ERROR','No spectrum file found in list of files to tar: ' + filelist_to_print
  goto,fini           ; didn't find an 'EXTR' filename
endif
epos=strpos(tarlist(ix),'.fits')
if(epos le 4) then goto,fini         ; nothing in the filename body
body=strmid(tarlist(ix),pos+4,epos-pos-4)

extrname=tarlist[ix]
fits_read, extrname, data, hdr
orig_name = sxpar(hdr, 'ORIGNAME')
reduced_name = strtrim(strjoin(strsplit(orig_name, 'e00',/extract, /regex)) + 'e91',2)

; make directory to hold files to be tarred.  
dirpath=tarpath+reduced_name+'/'

; check for existence of dirpath directory.  If nonexistent, create it.
status=file_test(dirpath,/directory)
if(~status) then begin
  cmd1='mkdir '+dirpath
  spawn,cmd1
endif

output_filename=dirpath+reduced_name+'.fits'

; step through the tarlist, read files of type EXTR, BLAZ, SPEC, THAR, RADV.
for i=0,nf-1 do begin
  if(strpos(tarlist(i),'EXTR') ge 0) then begin
    filin=tarlist(i)
    extr2=readfits(filin,hextr,/silent)
    fib0=sxpar(hextr,'FIB0')
    if(fib0) then begin
      extr=extr2(*,*,1)
      thar_i=extr2(*,*,0)
    endif else begin
      extr=extr2(*,*,0)
      thar_i=extr2(*,*,1)        ; not flat-fielded ThAr
    endelse
  endif

if(strpos(tarlist(i),'BLAZ') ge 0) then begin
    filin=tarlist(i)
    blaz2=readfits(filin,hblaz,/silent)
    fib0=sxpar(hblaz,'FIB0')
    if(fib0) then begin
      blaz=blaz2(*,*,1)
    endif else begin
      blaz=blaz2(*,*,0)
    endelse
  endif

if(strpos(tarlist(i),'SPEC') ge 0) then begin
    filin=tarlist(i)
    spec2=readfits(filin,hspec,/silent)
    fib0=sxpar(hspec,'FIB0')
    if(fib0) then begin
      spec=spec2(*,*,1)
      thar_f=spec2(*,*,0)          ; flat-fielded ThAr
    endif else begin
      spec=spec2(*,*,0)
      thar_f=spec2(*,*,1)
    endelse
  endif

if(strpos(tarlist(i),'THAR') ge 0) then begin
    filin=tarlist(i)
    thar=readfits(filin,hthar,/silent)
    wav0=thar(*,*,0)
    wav1=thar(*,*,1)
    wav2=thar(*,*,2)
    wavthar=wav1
    if(fib0) then wavspec=wav2 else wavspec=wav0
  endif

if(strpos(tarlist(i),'RADV') ge 0) then begin
    filin=tarlist(i)
    radv=readfits(filin,hrad0,/silent)      ; no data, but hrad0 is useful
    fxbopen,iun,filin,1,hrad1
    fxbread,iun,redshft,'RedShft'
    fxbread,iun,errrshft,'ErrRShft'
    fxbread,iun,scale,'Scale'
    fxbread,iun,errscale,'ErrScale'
    fxbread,iun,lx1coef,'Lx1Coef'
    fxbread,iun,errlx1,'ErrLx1'
    fxbread,iun,pldp,'PLDP'
    fxbclose,iun
    fxbopen,iun,filin,2,hrad2
    fxbread,iun,cc_fn,'CC_fn'
    fxbread,iun,lagvel,'LagVel'
    fxbclose,iun
  endif

if(strpos(tarlist(i),'PLOT') ge 0 or strpos(tarlist(i),'PLQC') ge 0) then begin
; copy file to output directory
    cmd2='cp '+tarlist(i)+' '+dirpath
    spawn,cmd2
  endif

endfor
extr=float(extr)
blaz=float(blaz)
spec=float(spec)
thar_i=float(thar_i)
thar_f=float(thar_f)

sz=size(extr)
nx=sz(1)
nord=sz(2)
szc=size(cc_fn)
nfc=szc(1)
nlag=szc(2)
szb=size(redshft)
nfib=szb(1)
nblock=szb(3)

; select cross-correlation data for the desired fiber, add coord info
; to hrad2
lagv=reform(lagvel[fib0,*])
xcorr=reform(cc_fn[fib0,*])
nlag=n_elements(lagv)
crval1=double(lagv(0))
cdelt1=(double(lagv(nlag-1)) - double(lagv(0)))/double(nlag-1)
sxaddpar,hrad2,'CRVAL1',crval1,'minimum lag value (km/s)'
sxaddpar,hrad2,'CDELT1',cdelt1,'lag increment (km/s per pix)
sxaddpar,hrad2,'CTYPE1','PIXEL','index type for lags'
sxaddpar,hrad2,'CRPIX1',1L,'pixel index corresp to CRVAL1'

; make headers from a crafty combination of the unique input headers
mk_hdroutput,hblaz,hthar,hrad0,hrad1,hrad2,hdrstruc

; Assemble output file:  0th exten is just minimal header for fits to work
imag0=fltarr(nx,nord,5)
imag0(*,*,0)=extr
imag0(*,*,1)=blaz
imag0(*,*,2)=spec
imag0(*,*,3)=thar_i
imag0(*,*,4)=thar_f

; extension names for spectrum, thar, wave data
specnames=['SPECRAW','SPECFLAT','SPECBLAZE']
tharnames=['THARRAW','THARFLAT']
wavenames=['WAVESPEC','WAVETHAR']

; write out the various spectrum-related data blocks, with headers
hdr0=hdrstruc.keyall
sxaddpar,hdr0,'EXTEND','T'
sxaddpar,hdr0,'BITPIX',32,before='EXTEND'
sxaddpar,hdr0,'SIMPLE','T',before='BITPIX'
sxaddpar,hdr0,'NAXIS',0,before='EXTEND'

writefits,output_filename,[],hdr0

hdr1=hdrstruc.extr
sxaddpar,hdr1,'XTENSION','IMAGE'
sxaddpar,hdr1,'BITPIX',-32
sxaddpar,hdr1,'NAXIS',2
sxaddpar,hdr1,'NAXIS1',nx
sxaddpar,hdr1,'NAXIS2',nord
sxaddpar,hdr1,'PCOUNT',0,'Required keyword'
sxaddpar,hdr1,'GCOUNT',1,'Required keyword'
sxaddpar,hdr1,'EXTNAME',specnames(0)
writefits,output_filename,extr,hdr1,/append

hdr2=hdrstruc.spec
sxaddpar,hdr2,'XTENSION','IMAGE'
sxaddpar,hdr2,'BITPIX',-32
sxaddpar,hdr2,'NAXIS',2
sxaddpar,hdr2,'NAXIS1',nx
sxaddpar,hdr2,'NAXIS2',nord
sxaddpar,hdr2,'PCOUNT',0,'Required keyword'
sxaddpar,hdr2,'GCOUNT',1,'Required keyword'
sxaddpar,hdr2,'EXTNAME',specnames(1)
writefits,output_filename,spec,hdr2,/append

hdr3=hdrstruc.blaz
sxaddpar,hdr3,'XTENSION','IMAGE'
sxaddpar,hdr3,'BITPIX',-32
sxaddpar,hdr3,'NAXIS',2
sxaddpar,hdr3,'NAXIS1',nx
sxaddpar,hdr3,'NAXIS2',nord
sxaddpar,hdr3,'PCOUNT',0,'Required keyword'
sxaddpar,hdr3,'GCOUNT',1,'Required keyword'
sxaddpar,hdr3,'EXTNAME',specnames(2)
writefits,output_filename,blaz,hdr3,/append

hdr4=hdrstruc.thar_i
sxaddpar,hdr4,'XTENSION','IMAGE'
sxaddpar,hdr4,'BITPIX',-32
sxaddpar,hdr4,'NAXIS',2
sxaddpar,hdr4,'NAXIS1',nx
sxaddpar,hdr4,'NAXIS2',nord
sxaddpar,hdr4,'PCOUNT',0,'Required keyword'
sxaddpar,hdr4,'GCOUNT',1,'Required keyword'
sxaddpar,hdr4,'EXTNAME',tharnames(0)
writefits,output_filename,thar_i,hdr4,/append

hdr5=hdrstruc.thar_f
sxaddpar,hdr5,'XTENSION','IMAGE'
sxaddpar,hdr5,'BITPIX',-32
sxaddpar,hdr5,'NAXIS',2
sxaddpar,hdr5,'NAXIS1',nx
sxaddpar,hdr5,'NAXIS2',nord
sxaddpar,hdr5,'PCOUNT',0,'Required keyword'
sxaddpar,hdr5,'GCOUNT',1,'Required keyword'
sxaddpar,hdr5,'EXTNAME',tharnames(1)
writefits,output_filename,thar_f,hdr5,/append

hdr6=hdrstruc.wavespec
sxaddpar,hdr6,'XTENSION','IMAGE'
sxaddpar,hdr6,'BITPIX',-64
sxaddpar,hdr6,'NAXIS',2
sxaddpar,hdr6,'NAXIS1',nx
sxaddpar,hdr6,'NAXIS2',nord
sxaddpar,hdr6,'PCOUNT',0,'Required keyword'
sxaddpar,hdr6,'GCOUNT',1,'Required keyword'
sxaddpar,hdr6,'EXTNAME',wavenames(0)
writefits,output_filename,wavspec,hdr6,/append

hdr7=hdrstruc.wavethar
sxaddpar,hdr7,'XTENSION','IMAGE'
sxaddpar,hdr7,'BITPIX',-64
sxaddpar,hdr7,'NAXIS',2
sxaddpar,hdr7,'NAXIS1',nx
sxaddpar,hdr7,'NAXIS2',nord
sxaddpar,hdr7,'PCOUNT',0,'Required keyword'
sxaddpar,hdr7,'GCOUNT',1,'Required keyword'
sxaddpar,hdr7,'EXTNAME',wavenames(1)
writefits,output_filename,wavthar,hdr7,/append

; write out cross-correlation data for the desired fiber
hdrxc=hdrstruc.xcor
nxc=n_elements(xcorr)
sxaddpar,hdrxc,'XTENSION','IMAGE',before='CRPIX1'
sxaddpar,hdrxc,'BITPIX',-32,before='CRPIX1'
sxaddpar,hdrxc,'NAXIS',1,before='CRPIX1'
sxaddpar,hdrxc,'NAXIS1',nxc,before='CRPIX1'
sxaddpar,hdrxc,'PCOUNT',0,'Required keyword',before='CRPIX1'
sxaddpar,hdrxc,'GCOUNT',1,'Required keyword',before='CRPIX1'
sxaddpar,hdrxc,'EXTNAME','SPECXCOR'
writefits,output_filename,xcorr,hdrxc,/append

; give names to the blockfit parameter vectors, write them to a binary table
; first make the extension block header
fxbhmake,hdrblock,1,'RVBLOCKFIT'

; select block data for fiber of interest for this data set
if(fib0 eq 0) then fibi=0 else fibi=1
redshft=reform(redshft(fibi,*,*))
errrshft=reform(errrshft(fibi,*,*))
scale=reform(scale(fibi,*,*))
errscale=reform(errscale(fibi,*,*))
lx1coef=reform(lx1coef(fibi,*,*))
errlx1=reform(errlx1(fibi,*,*))
pldp=reform(pldp(fibi,*,*))

; add keywords from hdrstruc.wblocks.  The last of these MUST be 'END'
blkh=hdrstruc.wblocks
nkywd=n_elements(blkh)
endkywd=where(strmid(hdrblock,0,3) eq 'END',nendkywd)
hdrblock=hdrblock(0:endkywd-1)      ; truncate the END keyword
hdrblock=[hdrblock,blkh]            ; and the new keywords, including END

; make order and block index vectors
ordindx=rebin(lindgen(nord),nord,nblock)
blkindx=rebin(reform(lindgen(nblock),1,nblock),nord,nblock)
ordindx=reform(ordindx,nblock*nord)
blkindx=reform(blkindx,nblock*nord)

; add column info to the header 
fxbaddcol,1,hdrblock,redshft,'ZBLOCK','redshift of block rel to xcorrel'
fxbaddcol,2,hdrblock,errrshft,'ERRZBLOCK','formal error of zblock'
fxbaddcol,3,hdrblock,scale,'SCALE','scale factor for block'
fxbaddcol,4,hdrblock,errscale,'ERRSCALE','formal error of scale for  block'
fxbaddcol,5,hdrblock,lx1coef,'LX1COEF','Lx1 coeff for block
fxbaddcol,6,hdrblock,errlx1,'ERRLX1','formal error for Lx1 coeff'
fxbaddcol,7,hdrblock,pldp,'PLDP','PLDP for block'
fxbaddcol,8,hdrblock,blkindx,'BLKINDX','block index'
fxbaddcol,9,hdrblock,ordindx,'ORDINDX','order index'

; create the new extension, write the column data
fxbcreate,iuno,output_filename,hdrblock
fxbwrite,iuno,redshft,1,1
fxbwrite,iuno,errrshft,2,1
fxbwrite,iuno,scale,3,1
fxbwrite,iuno,errscale,4,1
fxbwrite,iuno,lx1coef,5,1
fxbwrite,iuno,errlx1,6,1
fxbwrite,iuno,pldp,7,1
fxbwrite,iuno,blkindx,8,1
fxbwrite,iuno,ordindx,9,1

; close the output file
fxbfinish,iuno

; tar the directory
cd, dirpath, current=orig_dir

;add_relationship_keywords_to_headers, file_search(reduced_name + '*.fits'), rv_template_filename, arc_filename, trace_filename
;stop

; fpack the files
data_files = file_search('*.fits')
foreach file, data_files do begin
  logo_nres2,'tarout','INFO','Fpacking ' + file
  spawn, 'fpack -q 64 ' + file
  spawn, 'rm -f ' + file
endforeach

combine_plot_files, reduced_name

;write_readme_file, file_search('*')

;######## testing
print,'waiting....'
wait,5
;##############

cd, '..'
;cmd3='tar --warning=no-file-changed -czf '+reduced_name+'.tar.gz '+reduced_name
cmd3='tar -czf '+reduced_name+'.tar.gz '+reduced_name

spawn,cmd3

; write out the tarball's name 
openw,iun,'beammeup.txt',/get_lun,/append
printf,iun,tarpath + reduced_name + '.tar.gz' + ' ' + sxpar(hdr, 'DAY-OBS')
close,iun
free_lun,iun

; remove the directory we just tarred
cmd4='rm -r '+reduced_name
spawn,cmd4

cd, orig_dir
fini:

end
