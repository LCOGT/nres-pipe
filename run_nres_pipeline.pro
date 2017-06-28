pro run_nres_pipeline
    args = command_line_args(count=nargs)
    if nargs eq 0 then begin
        print, 'Filename required to run NRES pipeline.'
    endif else begin
        muncha, args[0]
    endelse
end