pro write_readme_file, filenames
  openw,iun,'README',/get_lun,/append
  foreach filename, filenames do begin

    if strpos(filename, 'blaze') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Extracted spectrum with the blaze function subtracted'
    endif else if strpos(filename, 'noflat') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Extracted spectrum with no flat field correction applied'
    endif else if strpos(filename, 'e91.fits') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Extracted spectrum with flat field correction applied. This is the primary reduced data product.'
    endif else if strpos(filename, 'rv.fits') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Radial velocity solution'
    endif else if strpos(filename, 'flat') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Flat field used in the reduction'
    endif else if strpos(filename, 'arc') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': ThAr arc lamp file used in the reduction'
    endif else if strpos(filename, 'trace') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Extraction region (the trace) used in the reduction'
    endif else if strpos(filename, 'wave') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Wavelength-to-pixel map'
    endif else if strpos(filename, '.pdf') ge 0 then begin
      printf,iun,strtrim(filename,2) + ': Quality control plots of the extracted spectrum'
    endif

  endforeach
  close,iun
  free_lun,iun

end