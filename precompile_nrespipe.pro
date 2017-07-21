pro precompile_nrespipe
  args = command_line_args(count=nargs)
  if nargs eq 0 then begin
    print, 'Output filename required to precompile idl functions.'
  endif else begin
    resolve_all,resolve_procedure='stack_nres_calibrations'
    resolve_all,resolve_procedure='run_nres_pipeline'

    SAVE, /routines, FILENAME=args[0]

  endelse
end