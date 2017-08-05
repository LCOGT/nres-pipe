function get_output_name, header
  if sxpar(header, 'OUTNAME') then begin
    filename = strtrim(sxpar(header, 'OUTNAME'), 2)
  endif else begin
    filename = strip_fits_extension(strtrim(sxpar(header, 'ORIGNAME'),2))
  endelse
  return, filename
end

