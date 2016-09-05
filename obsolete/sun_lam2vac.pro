pro sun_lam2vac,filout,filin=filin
; This routine reads lambda (AA), order index, and x-pixel coord from an
; input file (default '~/Thinkpad2/nres/lab_test/sun_lam_pix.txt', or
; the filin keyword if it is supplied) and transforms the wavelengths from
; air at STP to vacuum.  Results are written to filout, in the same form
; as the input data, with a suitably modified header line.

; constants
infile='~/Thinkpad2/nres/lab_test/sun_lam_pix.txt'
n0=2.771e-4       ;air at STP (n-1) at sodium D line
                  ; constant is chosen to make ThAr air and vacuum lams agree

if(keyword_set(filin)) then infile=filin

openr,iun,infile,/get_lun
lami=[0.d0]
ord=[0L]
xx=[0L]
ss=''
readf,iun,ss
readf,iun,ss
v1=0.d0
v2=0L
v3=0L
while(not eof(iun)) do begin
  readf,iun,v1,v2,v3
  lami=[lami,v1]
  ord=[ord,v2]
  xx=[xx,v3]
endwhile

close,iun
free_lun,iun
lami=lami[1:*]
ord=ord[1:*]
xx=xx[1:*]
nl=n_elements(lami)

;lama2=1.d4*airlam(lami/1.e4,n0)     ; airlam wants lambda in microns
;nair=lama2/lami          ; recover air refractive index from lama2
lamo=1.e4*vaclam(lami/1.e4,n0)           ; make vacuum wavelength

stop

f1='(f7.2,i10,i11)'
openw,iuno,filout,/get_lun
printf,iuno,'lambda(vacuum)     order      xx'
for i=0,nl-1 do begin
  printf,iuno,lamo(i),ord(i),xx(i),format=f1
endfor
close,iuno
free_lun,iuno

end
