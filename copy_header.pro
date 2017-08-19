function copy_header, header

  new_header = strarr(n_elements(header))
  new_header[*] = header[*]
  return, new_header

end