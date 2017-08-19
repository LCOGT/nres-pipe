function copy_header, header

  new_header = strarr(size(header))
  new_header[*] = header[*]
  return, new_header

end