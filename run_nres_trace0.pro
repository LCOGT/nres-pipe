pro run_nres_trace0
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
  if nargs lt 3 then begin
    print, 'Trace0: Not enough arguments. The following are required:'
    print, 'Input filename'
    print, 'Site ID (e.g. lsc)'
    print, 'Camera ID (e.g. fl09)'
  endif else begin
    trace0, args[0], args[1], args[2]
  endelse
end
