function robrms,md
; This routine returns a robust estimate of the rms of the array md,
; by iteratively discarding points that differ from the mean by more
; than 6-8 sigma.

;!EXCEPT = 2

u=md
nn=n_elements(u)
if(nn le 6) then sstrt=2.5 else sstrt=(8. < sqrt(nn))
for i=0,4 do begin
  ua=rebin(u,1)
  ud=u-ua(0)
  rms=stddev(ud)
  thr=(sstrt-.5*i > 2.5)
  if (rms[0] EQ 0) then GOTO, allgone
  s=where(abs(ud)/rms le thr,ns)
  if(ns gt 0) then begin
    u=u(s)
  endif else begin
    goto,allgone
  endelse
endfor

goto,fini

allgone:
rms=0.
fini:
return,rms
end
