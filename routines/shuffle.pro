function shuffle,vv,seed
; This routine shuffles the elements of the vector vv into random
; order and returns the shuffled vector.

nn=n_elements(vv)
rr=randomu(seed,nn)
so=sort(rr)
ww=vv(so)
return,ww
end
