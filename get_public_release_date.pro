function get_public_release_date, header

propid = strlowcase(sxpar(header, 'PROPID'))
date_obs = sxpar(header, 'DATE-OBS')
; Never public
if strpos(propid, 'engineer') ge 0 then begin
  public_date = '9999-12-31T23:59:59.999'
endif else if (propid eq 'calibrate') or (propid eq 'standard') or (propid eq 'pointing') or (strpos(propid, 'epo') ge 0) then begin
  public_date = date_obs
endif else begin
  julian_date = date_conv(date_obs, 'JULIAN')
  public_date = date_conv(julian_date + 365.25, 'FITS')
endelse

return, public_date
end
