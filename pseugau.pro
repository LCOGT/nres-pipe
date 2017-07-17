pro pseugau,dat
; This routine does a pseudo-gaussian smoothing (3 x 3-pix boxcars) of
; array dat(nx,nord) along each of its orders.  Results are returned in dat.

sz=size(dat)
nx=sz(1)
nord=sz(2)

for i=0,nord-1 do begin
  tt=smooth(smooth(smooth(dat(*,i),3),3),3)
  dat(*,i)=tt
endfor

end
