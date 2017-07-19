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
    args = command_line_args(count=nargs)
    if nargs eq 0 then begin
        print, 'Filename required to run NRES pipeline.'
    endif else begin
        muncha, args[0]
    endelse
end