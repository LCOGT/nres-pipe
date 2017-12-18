function get_jd_from_bin_header, hdr, iun
; Get the JD_START from the fits binary table
; The column names have changed over time so we need this routine.
  FXBFIND, hdr, 'TTYPE', cols, vals, n_found
  vals = strtrim(vals,2)
  if total(vals eq 'JD_START') then begin
    fxbread,iun,jd_start,'JD_START'
  endif else if total(vals eq 'JD_UTC') then begin
    fxbread,iun,jd_start,'JD_UTC'
  endif else begin
    fxbread,iun,mjd_expm,'MJD_START'
    jd_start = mjd_expm + 2400000.5d
  endelse
  return, jd_start
end