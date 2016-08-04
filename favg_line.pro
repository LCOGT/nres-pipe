function favg_line,ddi,smwid
; This routine averages the 2-D array ddi(nx,nt) over its 2nd dimension and
; returns the resulting 1-D vector.  Averaging is done in one of two ways,
; depending on nt:
; (nt le 2):  do an arithmetic average over elements of nt
; (nt ge 3):  decompose each line of ddi into low- and high-frequency parts,
;   via smoothing with a pseudo-gaussian with characteristic width smwid.
;   Then do an arithmetic average of the low-frequency parts,
;   and a median average of the high-frequency parts,
;   and sum the low- and high-frequency parts to make the output.

; get data size
sz=size(ddi)
nx=sz(1)
if(sz(0) eq 1) then begin      ; deal with case where ddi has only 1 line
  ddi=reform(ddi,nx,1)
  nt=1
endif else begin
  nt=sz(2)
endelse

; do nt le 2 case
if(nt le 2) then begin
  ddo=rebin(ddi,nx)
endif

; do nt ge 3 case
if(nt ge 3) then begin
  ddl=fltarr(nx,nt)
  ddh=fltarr(nx,nt)
  for i=0,nt-1 do begin
    ddl(*,i)=smooth(smooth(smooth(ddi(*,i),smwid,/edge_trun),smwid,/edge_trun),$
           smwid,/edge_trun)     ; the low-frequency part
  endfor
  ddh=ddi-ddl           ; the high-frequency part
  ddla=rebin(ddl,nx)
  ddha=median(ddh,dim=2)
  ddo=ddla+ddha
endif

return,ddo

end
