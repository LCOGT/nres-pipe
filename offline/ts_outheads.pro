pro ts_outheads,flist,keylist,datout
; This routine accepts flist = a list of nt input filenames, all of them names
; of NRES output files;  also a list of <= 5 header keywords keylist.
; It opens each input file, and compiles a merged header string array,
; consisting of the headers from all of the input file extensions.
; For each input file, it then extracts the values of the designated keywords,
; and stores them in arrays of length nt.  When finished with the list, all
; the results are bundled into the structure datout, with tags 'val0, val1, etc.

; open the input file and count lines
filin=[]
openr,iun,flist,/get_lun
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  filin=[filin,strtrim(ss,2)]
endwhile
close,iun
free_lun,iun
nt=n_elements(filin)
nkey=n_elements(keylist) < 5         ; ignore keywords beyond 5

; make output arrays
t0=[]
t1=[]
t2=[]
t3=[]
t4=[]

; loop over input files
for i=0,nt-1 do begin
  
; open file, read headers of all extensions
  fits_open,filin(i),fcb
  fits_read,fcb,d0,h0,exten=0
  fits_read,fcb,d1,h1,exten=1
  fits_read,fcb,d2,h2,exten=2
  fits_read,fcb,d3,h3,exten=3
  fits_read,fcb,d4,h4,exten=4
  fits_read,fcb,d5,h5,exten=5
  fits_read,fcb,d6,h6,exten=6
  fits_read,fcb,d7,h7,exten=7
  fits_read,fcb,d8,h8,exten=8
  fxbopen,iun,filin(i),9,h9
  fxbclose,iun
  fits_close,fcb

; assemble joint header
  hdr=[h0,h1,h2,h3,h4,h5,h6,h7,h8,h9]

; update the time series
  for j=0,nkey-1 do begin
    case j of
      0: t0=[t0,sxpar(hdr,keylist(0))]
      1: t1=[t1,sxpar(hdr,keylist(1))]
      2: t2=[t2,sxpar(hdr,keylist(2))]
      3: t3=[t3,sxpar(hdr,keylist(3))]
      4: t4=[t4,sxpar(hdr,keylist(4))]
    endcase
  endfor
endfor

; put something harmless into empty time series
if(n_elements(t0) eq 0) then t0=[' ']
if(n_elements(t1) eq 0) then t1=[' ']
if(n_elements(t2) eq 0) then t2=[' ']
if(n_elements(t3) eq 0) then t3=[' ']
if(n_elements(t4) eq 0) then t4=[' ']

; make output structure
datout={indx:lindgen(nt),nkey:nkey,keywords:keylist(0:nkey-1),nt:nt,$
        t0:t0,t1:t1,t2:t2,t3:t3,t4:t4}

end
