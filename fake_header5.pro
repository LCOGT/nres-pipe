pro fake_header4,filin,filout
; this routine reads a Sedgwick SPECTRUM data file filin and adds to the 
; header a minimum set of keywords needed to do extractions, trace orders,
; and make star-spectrum 'TARGET' images for the solar time series.

dd=readfits(filin,hdr)
hdro=hdr
sz=size(dd)
nx=sz(1)
object=strtrim(sxpar(hdr,'OBJECT'),2)
sxaddpar,hdro,'NX',nx
sxaddpar,hdro,'NFIB',2
sxaddpar,hdro,'NORD',25
sxaddpar,hdro,'NPOLY',3
sxaddpar,hdro,'ORDWIDTH',8.5
sxaddpar,hdro,'MEDBOXSIZ',17
sxaddpar,hdro,'FIB0',0
sxaddpar,hdro,'FIB1',1
sxaddpar,hdro,'OBSTYPE','TARGET'
sxaddpar,hdro,'SITEID','sqa'
sxaddpar,hdro,'OBJECTS','object&ThAr'

writefits,filout,dd,hdro

end
