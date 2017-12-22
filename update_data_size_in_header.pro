pro update_data_size_in_header, hdr, data
  size_data = size(data)
  sxaddpar, hdr, 'NAXIS', size_data[0]
  sxaddpar, hdr, 'BITPIX', -32
  sxaddpar, hdr, 'NAXIS1', size_data[1], after='NAXIS'
  sxaddpar, hdr, 'NAXIS2', size_data[2],after='NAXIS1'
  if size_data[0] gt 2 then begin
    sxaddpar, hdr, 'NAXIS3', size_data[3],after='NAXIS2'
  endif
end