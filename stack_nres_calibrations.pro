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
restore, getenv('NRES_IDL_PRECOMPILE')
args = command_line_args(count=nargs)
if nargs lt 4 then begin
  print, 'Stacking NRES calibrations requires at least 4 arguments'
  print, 'Calibration type (BIAS, DARK, FLAT, ARC, or TEMPLATE)'
  print, 'Site code (e.g. LSC)'
  print, 'Instrument code (e.g. fl09)'
  print, 'Date range separated by comma, see mk_supercal for date format specification.
endif else begin
  date_range_array = double(strsplit(args[3], ',', /extract))
  
  if nargs gt 4 then object=args[4] else object=!NULL
  
  if strtrim(strlowcase(args[0]),2) eq 'template' then begin
    type = 'ZERO'
  endif else if strtrim(strlowcase(args[0]),2) eq 'arc' then begin
    type = 'DOUBLE'
  endif else begin
    type = args[0]
  endelse
  
  mk_supercal, type, args[1], args[2], date_range_array, object=object
endelse

end
