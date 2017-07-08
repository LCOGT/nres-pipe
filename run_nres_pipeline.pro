pro run_nres_pipeline
    catch, error_status
    if error_status ne 0 then begin
      CATCH, /CANCEL
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