function strip_fits_extension, filename

filename_length = strlen(filename)
fixed_filename = filename
if strcmp(strmid(fixed_filename, filename_length - 3, 3), '.fz') then begin
   fixed_filename = strmid(fixed_filename, 0, filename_length - 3)
   filename_length = filename_length - 3
endif

if strcmp(strmid(fixed_filename, filename_length - 5, 5), '.fits') then begin
  fixed_filename = strmid(fixed_filename, 0, filename_length - 5)
  filename_length = filename_length - 3
endif
return, fixed_filename
end