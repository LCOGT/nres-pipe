pro test

nma = 10000000L
e = dblarr(nma)+0.3d0
ma = dindgen(nma)/(nma)*2d0*!dpi
eccanom = dblarr(nma)

t0 = systime(/seconds)
t = call_external(getenv('EXOFAST_PATH') + 'cuda/exofast.so',$
                  'keplereq_cuda',ma,e,nma,eccanom,VALUE=[0,0,1,0],/D_VALUE)
tcuda = systime(/seconds)-t0

t0 = systime(/seconds)
eccanom2 = exofast_keplereq(ma,e[0])
tidl = systime(/seconds)-t0

print, 'Time for CUDA: ' + strtrim(tcuda,2)
print, 'Time for IDL : ' + strtrim(tidl,2)
print, 'Max difference between IDL and CUDA:' + strtrim(max(abs(eccanom-eccanom2)),2)
print, 'CUDA code is ' + strtrim(tidl/tcuda,2) + ' faster'

stop
end
