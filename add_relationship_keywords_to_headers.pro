pro add_relationship_keywords_to_headers, filenames, rv_template_filename, arc_filename, trace_filename
foreach filename, filenames do begin
   fits_read, filename, data, header
   sxaddpar, header, 'L1IDARC', strip_fits_extension(arc_filename), 'ID of ARC file used.'
   sxaddpar, header, 'L1IDTMPL', strip_fits_extension(arc_filename), 'ID of template spectrum used.'
   sxaddpar, header, 'L1IDTRAC', strip_fits_extension(arc_filename), 'ID of Trace file used.'
   modfits,filename, 0, header
endforeach
end