pro logo_nres,rutname,logstr
; This routine concatenates a leading timetag and the strings rutname, logstr,
; and appends the result to the NRES logfile 
;  $NRESROOT/NRESINST/log_muncha.txt

root=getenv('NRESROOT')
inst=getenv('NRESINST')
logo='log_muncha.txt'
outfil=strtrim(root,2)+strtrim(inst,2)+'/'+strtrim(logo,2)
openw,iuno,outfil,/get_lun,/append

jdl=systime(/julian)
datereall=date_conv(jdl,'R')
datestrl=string(datereall,format='(f15.7)')


printf,iuno,datestrl+'  '+rutname+'  '+logstr

close,iuno
free_lun,iuno

end
