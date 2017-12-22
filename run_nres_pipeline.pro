pro run_nres_pipeline
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
    if nargs lt 2 then begin
        print, 'At least two arguments are required to run the NRES pipeline.'
        print, 'Filename'
        print, 'Do Radial Velocity calculation (0 or 1)'
    endif else begin
        if long(args[1]) then begin
          nostar = !NULL
        endif else begin
          nostar = 1
        endelse
        muncha, args[0], nostar=nostar
    endelse
end