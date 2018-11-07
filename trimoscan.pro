pro trimoscan,ierr
; This routine converts dat to floating format, subtracts overscan, and trims 
; the data array in conformance with information stored in the header.
; Results are stuck in the nres common data area.

compile_opt hidden

@nres_comm

ierr=0
rutname='trimoscan'

; look for trim data in header.  If not found, assume this file has already
; been stitched and fixed by Rob's routines.
bss=sxpar(dathdr,'BIASSEC')
sz=size(bss)                   ; check to see that bss is a string
if(sz(-2) ne 7) then begin
  ierr=1
  logo_nres2,rutname,'ERROR','FATAL No bias section found in data header'
  goto,fini             ; if no BIASSEC keyword, assume not CDP
endif

; take data as a CDP.  convert to float
dat=float(dat)+65536.

; get ranges for bias and data sections
sz=size(dat)
nxf=sz(1)                 ; factual size of input data array
nyf=sz(2)                 ;   (never mind what the header says)
dss=sxpar(dathdr,'DATASEC')
wbs=long(get_words(bss,delim='[,:,]',nbss))-1 ; subtract 1 to get zero indexing
wds=long(get_words(dss,delim='[,:,]',ndss))-1
if(nbss ne 4 or ndss ne 4) then begin
  ierr=2
  logo_nres2,rutname,'ERROR','FATAL Bad data in bias section or data section'
  goto,fini
end

; get bias section, average and smooth it, expand it to factual size of data
nyd=wds(3)-wds(2)+1
nxd=wds(1)-wds(0)+1
; check to see that bias section falls within factual size of data section,
if(wbs(0) ge 0 and wbs(0) le (nxf-1) and wbs(1) ge 0 and wbs(1) le (nxf-1)) $
    then begin
  bsec=dat(wbs(0):wbs(1),wbs(2):wbs(3))
  bseca=reform(rebin(bsec,1,nyd))
endif else begin
  bseca=fltarr(nyd)       ; fill with zeros if no true bias section
endelse
; ### may want a more drastic smoothing than this
bseca=smooth(smooth(smooth(bseca,17),17),17)
bseca=reform(bseca,1,nyd)
bseca=rebin(bseca,nxd,nyd)

; extract data section, subtract avgd bias
dsec=dat(wds(0):wds(1),wds(2):wds(3))
dat=dsec-bseca

; replicate next-to-last column into the (bad) last column
dat(nxd-1,*)=dat(nxd-2,*)

; fix the header to reflect the current dimensions & data type
sxaddpar,hdr,'NAXIS1',nxd
sxaddpar,hdr,'NAXIS2',nyd
sxaddpar,hdr,'BITPIX',-32

fini:

end
