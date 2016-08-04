pro fake_header2,filin,filout
; this routine reads an elemental NRES lab data file filin and adds to the 
; header a minimum set of keywords needed to do extractions, trace orders,
; and make solar-spectrum 'TARGET' images for the solar time series.
; For the solar time series, fiber 0 is not illuminated.

dd=readfits(filin,hdr)
hdro=hdr
sz=size(dd)
nx=sz(1)
sxaddpar,hdro,'NX',nx
sxaddpar,hdro,'NFIB',3
sxaddpar,hdro,'NORD',65
sxaddpar,hdro,'NPOLY',3
sxaddpar,hdro,'ORDWIDTH',10.5
sxaddpar,hdro,'MEDBOXSIZ',17
sxaddpar,hdro,'FIB0',1
sxaddpar,hdro,'FIB1',2
sxaddpar,hdro,'OBSTYPE','TARGET'
sxaddpar,hdro,'SITEID','bpl'
sxaddpar,hdro,'OBJECTS','NONE&ThAr&Sun'

writefits,filout,dd,hdro

end
