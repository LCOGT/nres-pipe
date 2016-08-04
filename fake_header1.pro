pro fake_header1,filin,fib0,fib1,filout
; this routine reads an elemental NRES lab data file filin and adds to the 
; header a minimum set of keywords needed to do extractions, trace orders,
; and make flats.

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
sxaddpar,hdro,'FIB0',fib0
sxaddpar,hdro,'FIB1',fib1
sxaddpar,hdro,'OBSTYPE','FLAT'
sxaddpar,hdro,'SITEID','bpl'
sxaddpar,hdro,'INSTRUME','fl07'

writefits,filout,dd,hdro

end
