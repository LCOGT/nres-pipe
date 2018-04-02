pro update_data_size_in_header, hdr, data
  size_data = size(data)
  dtype=size_data(size_data[0]+1)
  if(dtype eq 5) then bpval=(-64) else bpval=(-32)
  sxaddpar, hdr, 'NAXIS', size_data[0]
  sxaddpar, hdr, 'BITPIX', bpval
  sxaddpar, hdr, 'NAXIS1', size_data[1], after='NAXIS'
  sxaddpar, hdr, 'NAXIS2', size_data[2],after='NAXIS1'
  if size_data[0] gt 2 then begin
    sxaddpar, hdr, 'NAXIS3', size_data[3],after='NAXIS2'
  endif
end
