pro mk_targlist,filin,filout
; This routine reads a list of ascii target names (1 target per line) from
; inputfile filin.  It queries Simbad for information about each entry.
; If a name match is found, then a line of target data is written to the
; output file filout, in the correct format for inclusion in the targets.csv
; file.
; Blank lines and lines with 1st character = '#' are ignored.

; open input, output files
openr,iun,filin,/get_lun
openw,iuno,filout,/get_lun

; read all the input lines
ss=''
while(not eof(iun)) do begin
  readf,iun,ss
  targname=strtrim(ss,2)
  if(targname eq '' or strmid(targname,0,1) eq '#') then goto, skip
  querysimbad2,targname,ra,dec,id,found=found,vmag=vmag,jmag=jmag,kmag=kmag,$
    parallax=parallax,bmag=bmag,rv=rv,pm=pm,imag=imag,sptype=sptype

  if(found) then begin
    starg='"'+targname+'",'
    ras=string(ra,format='(f9.5)')+','
    decs=string(dec,format='(f9.5)')+','
    if(keyword_set(vmag)) then vms=string(vmag,format='(f7.3)')+',' else $
         vms='-99.9,'
    if(keyword_set(bmag)) then bms=string(bmag,format='(f7.3)')+',' else $
         bms='-99.9,'
    gms='-99.9,'
    rms='-99.9,'
    if(keyword_set(imag)) then ims=string(imag,format='(f7.3)')+',' else $
         ims='-99.9,'
    if(keyword_set(jmag)) then jms=string(jmag,format='(f7.3)')+',' else $
         jms='-99.9,'
    if(keyword_set(kmag)) then kms=string(kmag,format='(f7.3)')+',' else $
         kms='-99.9,'
    if(keyword_set(pm)) then pms=string(pm(0),format='(f9.2)')+',' + $
         string(pm(1),format='(f9.2)')+',' else $
         pms='0.00,0.00,'
    if(keyword_set(parallax)) then plaxs=string(parallax,format='(f7.2)')+',' $
         else plaxs='0.00,'
    if(keyword_set(rv)) then rvs=string(rv,format='(f8.3)')+','
    nulls='"NULL"'

; guess Teff and log(g) based on B-V color and spectral classification, if any
    if(keyword_set(sptype)) then spt=sptype else spt=['G8','IV']
    guess_tefflogg,spt,vmag,bmag,teff,logg
    teffs=string(long(teff),format='(i6)')+','
    loggs=string(logg,format='(f6.3)')+','

  strout=starg+strcompress(ras+decs+vms+bms+gms+rms+ims+jms+kms+pms+plaxs $
          +rvs+teffs+loggs+nulls,/remove_all)

  printf,iuno,strout
  endif
  skip:
endwhile

close,iun
free_lun,iun
close,iuno
free_lun,iuno

end

