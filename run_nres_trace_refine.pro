pro run_nres_trace_refine
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
    print, 'NRES Trace Refine requires at least 3 arguments'
    print, 'Site code (e.g. LSC)'
    print, 'Instrument code (e.g. fl09)'
    print, 'First Raw input flat filename to trace'
    print, 'Second Raw input flat filename to trace from other telescope (optional)'
    print, 'Order of the Lengendre Polynomial to fit the trace (optional, default=7)'
  endif else begin
    @nres_comm
    jdc = systime(/julian)
    site = args[0]
    camera = args[1]
    nresroot=getenv('NRESROOT')
    nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
    dummy=readfits(args[2],hdrdummy)
    mjdd=sxpar(hdrdummy,'MJD-OBS')
    get_calib,'TRACE',tracefile,tracprof,tracehdr,gerr
    if nargs gt 3 then flat2=args[3] else flat2=!NULL
    if nargs gt 4 then npoly=args[4] else npoly=7
    trace_refine, file_basename(tracefile), args[2], flat2, nleg=npoly
  endelse
end
