function get_public_release_date, header

propid = strlowcase(sxpar(header, 'PROPID'))
date_obs = sxpar(header, 'DATE-OBS')
; Never public
if strpos(propid, 'engineer') ge 0 then begin
  public_date = '9999-12-31T23:59:59.999'
endif else if (propid eq 'calibrate') or (propid eq 'standard') or (propid eq 'pointing') or (strpos(propid, 'epo') ge 0) then begin
  public_date = date_obs
endif else begin
  year = long(strmid(date_obs, 0, 4))
  public_date = strtrim(year + 1, 2) + strmid(date_obs, 4)
endelse

return, public_date
end
