; GET_XTECAL - retrieve XTECAL calibration directory
;
; The function uses the XTECAL environment variable, and if that does
; not exist, then uses $HOME/xtecal
;
; RETURNS - name of XTECAL directory
function get_xtecal

  forward_function rstrpos
  common get_xtecal_common, xtecal
  if n_elements(xtecal) GT 0 then return, xtecal

  xtecal = getenv('XTECAL')
  if xtecal(0) EQ '' then xtecal = getenv('HOME')
  if xtecal(0) EQ '' then xtecal = '~'
  xtecal = xtecal(0) + '/xtecal'

  if rstrpos(xtecal, '/') EQ strlen(xtecal)-1 then $
    xtecal = strmid(xtecal,0,strlen(xtecal)-1)

  get_lun, unit
  openr, unit, xtecal+'/appids.filt', error=err
  free_lun, unit

  if err NE 0 then begin
    xtecal = '' & dummy = temporary(xtecal)
    message, 'ERROR: could not locate XTECAL directory.  ' +$
      'Please define environment variable XTECAL.'
  endif

  xtecal = xtecal + '/'
  return, xtecal
end