pro sunspeccsv_write,sunstruc
; This routine writes a new line in the spectrographs.csv file, containing
; all the information needed to construct a wavelength solution.
; On input, structure sunstruc contains the needed data.
; For simplicity, this routine works by reading the spectrographs.csv file
; as an array of strings, and then adding an appropriately formatted
; string before rewriting the file.

nresroot=getenv('NRESROOT')
fname=nresroot+'reduced/csv/spectrographs.csv'

; get the current spectrographs.csv file
strdat=['']
ss=''
openr,iun,fname,/get_lun
while(not eof(iun)) do begin
  readf,iun,ss
  strdat=[strdat,ss]
endwhile
close,iun
free_lun,iun
strdat=strdat[1:*]

; make a string for the new line.
st1='"'+strtrim(sunstruc.site,2)+'",'
st2=string(sunstruc.mjd,format='(f9.3)')
st3=string(sunstruc.mm(0),format='(i2)')+','
st4=string(sunstruc.grspc,format='(f8.5)')+','
st5=string(sunstruc.grinc,format='(f8.5)')+','
st6=string(sunstruc.dgrinc,format='(e8.2)')+','
st7=string(sunstruc.fl,format='(f9.5)')+','
st8=string(sunstruc.dfl,format='(f4.2)')+','
st9=string(sunstruc.y0,format='(f7.3)')+','
st10=string(sunstruc.dy0,format='(f4.2)')+','
st11=string(sunstruc.z0,format='(f10.7)')+','
st12=string(sunstruc.dz0,format='(e7.1)')+','
st13='"'+strtrim(sunstruc.gltype,2)+'",'
st14=string(sunstruc.priswedge,format='(f6.3)')+','
st15=string(sunstruc.lamcen,format='(f6.4)')+','
st16=string(sunstruc.r0,format='(f5.2)')+','
st17=string(sunstruc.pixsiz,format='(f9.7)')+','
st18=string(sunstruc.nx,format='(i4)')+','
st19=string(sunstruc.nord,format='(i2)')+','
st20=string(sunstruc.nblock,format='(i2)')+','
st21=string(sunstruc.nfib,format='(i1)')+','
st22=string(sunstruc.npoly,format='(i1)')+','
st23=string(sunstruc.ordwid,format='(f4.1)')+','
st24=string(sunstruc.medboxsz,format='(f3.0)')+','
st25=string(sunstruc.coefs(0),format='(e12.5)')+','
st26=string(sunstruc.coefs(1),format='(e12.5)')+','
st27=string(sunstruc.coefs(2),format='(e12.5)')+','
st28=string(sunstruc.coefs(3),format='(e12.5)')+','
st29=string(sunstruc.coefs(4),format='(e12.5)')+','
st30=string(sunstruc.coefs(5),format='(e12.5)')+','
st31=string(sunstruc.coefs(6),format='(e12.5)')+','
st32=string(sunstruc.coefs(7),format='(e12.5)')+','
st33=string(sunstruc.coefs(8),format='(e12.5)')+','
st34=string(sunstruc.coefs(9),format='(e12.5)')

outstr=st1+st2+st3+st4+st5+st6+st7+st8+st9+st10+st11+st12+st13+st14+st15+$
  st16+st17+st18+st19+st20+st21+st22+st23+st24+st25+st26+st27+st28+st29+$
  st30+st31+st32+st33+st34

strdato=[strdat(0),outstr,strdat(1:*)]
openw,iun,fname,/get_lun
printf,iun,strdato
close,iun
free_lun,iun

stop

end
