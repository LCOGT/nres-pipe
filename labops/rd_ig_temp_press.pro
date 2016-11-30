pro rd_ig_temp_press,names,odat
; This routine reads the data text file from Brook's pressure control expt,
; putting the column headings in string array names, and the data in
; floating array odat(ncol,nt).  Points with nan values are replaced with zeros.

; constants
hdrfile='~/Downloads/   '
datfile='~/Downloads/superfin_analog_in_out_dt-20161128-0833.txt'

names=['Time_Stamp', 'P regulator control', 'DAC loopback output', $
'Instrument P', 'Atmospheric P', 'Internal regulator P', 'P regulator control',$
'V ref as pressure', 'DAC loopback input', 'Spare 1 P', 'Spare 2 P', $
'Temperature 1', 'Temperature 2', 'Temperature 3', 'Temperature 4', $
'Temperature 5', 'Temperature 6', 'Temperature 7', 'Temperature 8', $
'Slot 1 current', 'Slot 2 current', 'Slot 3 current', 'Slot 4 current', $
'Slot 5 current', 'Slot 6 current', 'Slot 7 current', 'Slot 8 current', $
'Slot 9 current', 'Slot 10 current', 'Slot 11 current', 'Slot 12 current', $
'Inlet temperature', 'Outlet temperature', 'TentAir', 'CalResistor', $
'TentIntake', 'OutsideAir', 'ACoutput', 'ChamberPressSenTemp', 'RTD7', $
'CtrlValveTemp', 'AirSupplyPress', 'Bench_Temp','dt_chamber_mv',$
'dt_atmo_mv','dt_monitor_mv','dt_control_mv']

ncols=n_elements(names)

openr,iun,datfile,/get_lun
ss=''
nt=0L
while(not eof(iun)) do begin
  readf,iun,ss
  nt=nt+1L
endwhile
point_lun,iun,0

odat=dblarr(ncols,nt)
for i=0,nt-1 do begin
  readf,iun,ss
  words=strtrim(get_words(ss,nwd),2)
  s=where(words eq 'nan',ns)
  if(ns gt 0) then words(s)='0.0'
  odat(*,i)= double(words)
endfor

stop

close,iun
free_lun,iun

end
