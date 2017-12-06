pro rd_mamajek,spec,teff,logt,bmv
; Reads Eric Mamajek's table of dwarf-star properties and returns vectors
; giving spectral type spec, teff, log(teff), and B-V color.

nrescode=getenv('NRESCODE')
openr,iun,nrescode+'/offline/mamajek_dwarf_color.txt',/get_lun
ss=''
readf,iun,ss     ; table header line

; make output files
nl=83
spec=strarr(nl)
teff=fltarr(nl)
logt=fltarr(nl)
bmv=fltarr(nl)

; read the data
for i=0,82 do begin
  readf,iun,ss
  words=get_words(ss,nw)
  spec(i)=strtrim(words(0),2)
  teff(i)=float(words(1))
  logt(i)=float(words(2))
  bmv(i)=float(words(6))
endfor

close,iun
free_lun,iun

end
