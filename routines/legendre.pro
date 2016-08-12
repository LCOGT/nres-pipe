function legendre,minord,maxord,npt,x
; this routine returns an array of (npt, maxord-minord+1) elements consisting
; of Legendre polynomials between orders minord and maxord (both >= 0),
; evaluated at npt points.  If the input parameter x is defined, these points
; are taken as the evaluation points, and the number of points evaluated is
; either npt or the 1st dimension of x, whichever is smaller.  If npt is smaller
; then the 1st npt points of x are taken.  If x is defined and not within the
; range -1. to 1., no error message is issued, and exciting results may be
; returned.  If x is not defined, the coordinate array is forced to run from
; -1. to 1.

; decide whether to generate array of coordinates; do what's necessary.
  if (n_params() eq 4) then begin
     xx=x
     s=size(xx)
     np=s(1)
     end
  if (n_params() ne 4) then begin
     np=npt
     xx=2.*findgen(np)/(np-1.)-1.
     end

; bail out with zero returned value if no orders, or if npt le 0.
  nord=maxord-minord+1
  if((nord le 0) or (np le 0)) then begin
    z=0.
    return, z
    end
  
; make P0 and P1, create output array, load p0 and/or p1 as necessary
  pt=fltarr(np,2)+1.
  pt(*,1)=xx
  iz=1
  im=0
  leg=fltarr(np,nord)
  if (minord eq 0 and nord eq 1) then begin
    leg(*,0)=pt(*,0)
    return,leg
    end
  if (minord eq 0 and nord ge 2) then begin
    leg(*,0:1)=pt
    if(nord eq 2) then return,leg
    end
  if (minord eq 1) then begin
    leg(*,0)=pt(*,1)
    if (nord eq 1) then return,leg
    end

; get here if recursion is necessary
  for n=1,maxord-1 do begin
    a1=(2.*n+1.)/(n+1.)
    a2=n/(n+1.)
    pt(*,im)=a1*xx*pt(*,iz)-a2*pt(*,im)
    if (n ge (minord-1) and n le maxord) then leg(*,n-minord+1)=pt(*,im)
    it=iz
    iz=im
    im=it
    end

; split
  return,leg
  end
