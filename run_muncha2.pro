pro run_muncha2,flist
; This routine reads a list of input filenames, and runs muncha.pro on
; each, using the /nostar option to suppress computation of radial velocities,
; but not invoking the /cubfrz option, so that new restricted cubic coeffs
; are computed.

openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  ss=''
  readf,iun,ss
  fname=strtrim(ss,2)
  muncha,fname,trp=0,tharlist='mtchThAr.txt',/nostar,oskip=[0]
endwhile

close,iun
free_lun,iun

end
