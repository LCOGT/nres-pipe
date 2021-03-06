pro precompile_nrespipe
  args = command_line_args(count=nargs)
  if nargs eq 0 then begin
    print, 'Output filename required to precompile idl functions.'
  endif else begin
    resolve_all,resolve_procedure='stack_nres_calibrations'
    resolve_all,resolve_procedure='run_nres_pipeline'
    resolve_all,resolve_function='thar_mpfit'
    resolve_all,resolve_function='rv_mpfit'
    resolve_all,resolve_procedure='run_nres_trace_refine'
    resolve_all,resolve_procedure='run_nres_trace0'
    SAVE, /routines,/IGNORE_NOSAVE, FILENAME=args[0]

  endelse
end