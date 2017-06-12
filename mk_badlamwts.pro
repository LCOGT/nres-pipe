pro mk_badlamwts,lam03
; This routine makes an array badlamwts(nx,nord,3) with values of
; 1.0 for presumed good data, or 0.0 for data that are presumed bad
; because of wavelength-dependent corrupting factors.
; On input,
; lam03(nx,nord,3) = wavelength in nm per pixel, order, fiber
; Information to build the array is read from a text file found in
; RDsite/reduced/config/badlam.txt, consisting of blocks of bad-data assertions.
; These may be of two sorts:
; One prefaced by "w" (for wavelength) is intended for atmospheric absorption
;    features or similar artifacts, for which the nominal x-coord of the
;    feature is different between fibers 0 and 2, and for which it is
;    expected to be absent in fiber 1.
; One prefaced by "x" (for x-coord) is for bloomed Ar lines or similar,
;    which occur at the same x-coord for different fibers, including fiber 1,
;    and perhaps including neighboring orders.
; For a first version, pixels that are taken to be bad lie within rectangles
; of specified width in wavelength (for "w" features) or pixels (for "x"
; features), and in half-width in orders (for "x" features).

@nres_comm

; constants
nord=specdat.nord
nx=specdat.nx

; make the output file --  originally all assumed good
blw=fltarr(nx*nord,3)+1.
blx=reform(blw,nx,nord,3)

; read and parse the input file
rd_badlams,nent,etype,elam,ehwid,ehht

; 
; loop over entries, setting appropriate pixels to zero
for i=0,nent-1 do begin
  case etype(i) of
    'w': begin
      lammin=elam(i)-ehwid(i)
      lammax=elam(i)+ehwid(i)
      s0=where(lam03(*,*,0) ge lammin and lam03(*,*,0) le lammax,ns0)
      s2=where(lam03(*,*,2) ge lammin and lam03(*,*,2) le lammax,ns2)
      if(ns0 gt 0) then blw(s0,0)=0.
      if(ns2 gt 0) then blw(s2,2)=0.
      end
    'x': begin
      dif=abs(lam03(*,*,1)-elam(i))
      mind=min(dif,ix)
      iord=long(ix/nx)
      xx=ix-iord*nx
      xmin=(xx-ehwid(i))>0
      xmax=(xx+ehwid(i))<(nx-1)
      omin=(iord-ehht(i))>0
      omax=(iord+ehht(i))<(nord-1)
      blx(xmin:xmax,omin:omax,*)=0.
      end
  endcase
endfor

; combine "w" and "x" types
blw=reform(blw,nx,nord,3)
badlamwts=blw*blx

;stop

end
