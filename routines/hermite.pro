function hermite,minord,maxord,x,wid
; this routine returns an array of (npt, maxord-minord+1) elements consisting
; of Hermite polynomials between orders minord and maxord (both >= 0),
; with their scale expanded by wid, and multiplied by exp(-x^2/(2.*wid^2)).
; They are evaluated at the abscissae in array x, which contains npt points.
; The functions are normalized so that integral Hn^2 dx = 1.  Note that this
; differs from the normalization in Abramowitz & Stegun, where the same
; integral is sqrt(pi)*2^n*n!

  np=n_elements(x)

; bail out with zero returned value if no orders, or x is undefined
  nord=maxord-minord+1
  if((nord le 0) or (np le 0)) then begin
    z=0.
    return, z
    end
  
; make rescaled x coordinate, exponential, normalization constant
  xp=x/wid
  xp2=xp^2
  arg=xp2/2. < 35.
  wt=exp(-arg)
  norm=sqrt(sqrt(!pi))*sqrt(wid)
  sq2=sqrt(2)

; make H0 and H1, create output array, load H0 and/or H1 as necessary
  pt=fltarr(np,2)+1.
  pt(*,1)=2.*xp
  iz=1
  im=0
  her=fltarr(np,nord)
  if (minord eq 0 and nord eq 1) then begin
    her(*,0)=pt(*,0)*wt/norm
    return,her
    end
  if (minord eq 0 and nord ge 2) then begin
    her(*,0:1)=pt*rebin(wt,np,2)/norm
    her(*,1)=her(*,1)/sq2
    if(nord eq 2) then return,her
    end
  if (minord eq 1) then begin
    her(*,0)=pt(*,1)*wt/(norm*sq2)
    if (nord eq 1) then return,her
    end

; get here if recursion is necessary
  norm=norm*sq2
  for n=1,maxord-1 do begin
    a1=2.
    a2=2.*n
    pt(*,im)=a1*xp*pt(*,iz)-a2*pt(*,im)
    norm=norm*sq2*sqrt(n+1)
    if (n ge (minord-1) and n le maxord) then her(*,n-minord+1)=$
	pt(*,im)*wt/norm
    it=iz
    iz=im
    im=it
    end

; split
  return,her
  end
