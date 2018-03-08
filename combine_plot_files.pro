pro combine_plot_files, reduced_basename
ps_files = file_search('*.ps')
foreach file, ps_files do begin
  spawn, 'ps2pdf ' + file
  spawn, 'rm -f ' + file
endforeach

pdf_files = file_search('*.pdf')

spawn, 'gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=' + strtrim(reduced_basename, 2) +'.pdf *.pdf'

foreach file, pdf_files do begin
  spawn, 'rm -f ' + file
endforeach

end
