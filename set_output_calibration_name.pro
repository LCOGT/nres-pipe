pro set_output_calibration_name, hdr, type
  site = strtrim(strlowcase(sxpar(hdr, 'SITEID')),2)
  telescope = strtrim(strlowcase(sxpar(hdr, 'TELESCOP')),2)
  instrument = strtrim(strlowcase(sxpar(hdr, 'INSTRUME')),2)
  dayobs = strtrim(sxpar(hdr,'DAY-OBS'), 2)
  output_filename = strtrim(STRLOWCASE(type),2) + '_' + site + '_' + telescope + '_' + instrument + '_' + dayobs
  sxaddpar,hdr,'OUTNAME',output_filename,'Output filename'
  sxaddpar,hdr,'RLEVEL', 91, 'Data processing level'
end