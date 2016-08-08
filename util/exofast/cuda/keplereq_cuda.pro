function keplereq_cuda, meananom, ecc

ndata = n_elements(meananom)
necc = n_elements(ecc)
if necc eq 1 then e = replicate(ecc,ndata) $
else if necc ne ndata then message, $
   'ERROR: The number of elements in ECC must be 1 or match MEANANOM'
eccanom = double(ndata)

dummy = call_external(getenv('EXOFAST_PATH') + 'cuda/exofast.so',$
                      'keplereq_cuda',double(meananom),double(ecc),ndata,$
                      eccanom,VALUE=[0,0,1,0],/D_VALUE)
return, eccanom

end
