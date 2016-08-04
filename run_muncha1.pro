pro run_muncha1,flist
; This routine reads a list of input filenames, and runs muncha.pro on
; each.  It then repeats this process nord times, skipping a different
; order in the wavelength solution each time.

nord=1

for i=0,nord do begin
openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  ss=''
  readf,iun,ss
  fname=strtrim(ss,2)
  muncha,fname,trp=0,tharlist='mtchThAr.txt',/cubfrz,oskip=[0]
endwhile

close,iun
free_lun,iun

endfor

end
