pro sunlampix2fib,sunlampixin,doublein,fibout,sunlampixout
; This routine accepts sunlampixin, an ascii file containing wavelengths,
; order indices, and pixel locations for solar spectrum lines.
; It also accepts doublein, a FITS file containing extracted ThAr spectra taken
; simultaneously in 2 fibers (0,1) or (1,2).
; It then calls tharfit2fib to cross-correlate the two ThAr spectra to determine
; fiber-to-fiber x-shifts as a function of x and order index, and to fit these
; differences to a global polynomial in order index and x.
; It then reads sunlampixin, and transforms the solar line pixel positions
; found there (corresp to the fiber identified in the 2nd line of sunlampixin) 
; to expected positions for the same lines
; seen with fibout.  It writes these positions out to sunlampixout, in the
; same form as sunlampixin.

; constants
nb=8               ; number of blocks per order for ThAr cross-correlation
nresroot=getenv('NRESROOT')

; get relative shift between fibers.
dblin=nresroot+'reduced/spec/'+doublein
slxin=nresroot+'reduced/config/'+sunlampixin
thar_fit2fib,dblin,nb,fitcoefs,rms

; get which fiber is which
dd=readfits(dblin,hdr)
objects=sxpar(hdr,'OBJECTS')
nx=sxpar(hdr,'NAXIS1')
nord=sxpar(hdr,'NAXIS2')
words=get_words(objects,nwd,delim='&')
words=strupcase(words)
s=where(words eq 'THAR',ns)
if(ns ne 2) then begin
  print,'doublein must contain ThAr in 2 fibers.  Fatal error.'
  stop
endif
if(s(0) eq 0) then begin
  fib0=0
  if(s(1) eq 1) then begin
    fib1=1
  endif else begin
    fib1=2
  endelse
endif else begin
  fib0=1
  fib1=2
endelse

; read sunlampixin
slxin=nresroot+'reduced/config/'+sunlampixin
openr,iun,slxin,/get_lun
ss=''
readf,iun,ss
readf,iun,ss
words=get_words(ss,nwd)
fibin=long(words(1))
lam=[0.d0]
ord=[0L]
pix=[0L]
v1=0.d0
v2=0L
v3=0L
   
while(not eof(iun)) do begin
  readf,iun,v1,v2,v3
  lam=[lam,v1]
  ord=[ord,v2]
  pix=[pix,v3]
endwhile
close,iun
free_lun,iun
lam=lam(1:*)
ord=ord(1:*)
pix=pix(1:*)

; make xx and nn coordinates
xx=float(pix)-nx/2.
nn=float(ord)-nord/2.

; make pixel corrections
dx=fitcoefs(0)+fitcoefs(1)*nn+fitcoefs(2)*xx+fitcoefs(3)*xx*nn+$
   fitcoefs(4)*nn^2+fitcoefs(5)*xx*nn^2+fitcoefs(6)*xx^2

; make new pixel positions for fibout, write them out
dp=dx*(fibout-fibin)
pixo=pix+dp

stop

slxout=nresroot+'reduced/config/'+sunlampixout
openw,iun,slxout,/get_lun
printf,iun,'lam(vacuum)  ord       pix'
printf,iun,'Fiber ',fibout,format='(a6,i1)'
np=n_elements(pixo)
for i=0,np-1 do begin
  printf,iun,lam(i),ord(i),pixo(i),format='(f7.2,2x,i7,2x,f11.1)'
endfor
close,iun
free_lun,iun

end
