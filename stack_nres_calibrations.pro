pro stack_nres_calibrations
compile_opt HIDDEN
catch, error_status
if error_status ne 0 then begin
  CATCH, /CANCEL
  Help, /Last_Message, Output=theErrorMessage
  FOR j=0,N_Elements(theErrorMessage)-1 DO BEGIN
    Print, theErrorMessage[j]
  ENDFOR
  print, !ERROR_STATE.MSG_PREFIX
  PRINT, !ERROR_STATE.MSG
  exit, status=1
endif
args = command_line_args(count=nargs)
if nargs lt 4 then begin
  print, 'Stacking NRES calibrations requires at least 4 arguments'
  print, 'Calibration type (BIAS, DARK, or FLAT)'
  print, 'Site code (e.g. LSC)'
  print, 'Instrument code (e.g. fl09)'
  print, 'Date range separated by comma, see mk_supercal for date format specification.'
endif else begin
  date_range_array = double(strsplit(args[3], ',', /extract))
  mk_supercal, args[0], args[1], args[2], date_range_array
endelse

end
