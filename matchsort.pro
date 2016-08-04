pro matchsort,match,matchsodat,matchlineu,nhitl,nhitt
; This routine accepts a structure match containing the data array
; matchdat(1000,10,nt).  The 2nd dimension of matchdat indexes various
; attributes of the spectrum lines that have been matched with standard
; Thorium lines in the nt observed spectra (these are named in match.matchnames)
; The number of lines detected in each time slice is given in match.nmatch(nt).
; Routine matchsort identifies the unique values of matchline = (wavelengths
; of standard lines) (nm).  It then creates a new array 
; matchsodat(nuniq,10,nt) containing the same values as in matchdat, but
; with each matched line's attributes placed in the slot (0:nuniq-1)   
; corresponding to its unique matchline value.  This makes it possible to
; create time series of particular matched Th lines.
; Unique lines that are not seen in a given input file receive zero values
; for all their attributes.
; Also returned are vectors 
; matchlineu = wavelengths of the unique lines (nm)
; nhitl(nuniq) = number of time steps in which each unique line is found
; nhitt(nt) = number of unique lines found for each time step

; identify unique matched standard line wavelengths
names=match.matchnames
s=where(names eq 'matchline',ns)
s=s(0)
if(ns eq 1) then begin
  mlines=match.matchdat(*,s,*)
endif else begin
  print,'Cannot find matchlines!'
  stop
endelse
sg=where(mlines gt 0.,ns)
m0=mlines(sg)
so=sort(m0)
m1=m0(so)
m1u=uniq(m1)
matchlineu=m1(m1u)

; make output arrays
nuniq=n_elements(matchlineu)
sz=size(match.matchdat)
nattr=sz(2)
nt=sz(3)
matchsodat=dblarr(nuniq,nattr,nt)
nhitl=lonarr(nuniq)
nhitt=lonarr(nt)

; loop over time steps
for i=0,nt-1 do begin
  nmi=match.nmatch(i)
  for j=0,nmi-1 do begin
    sm=where(matchlineu eq match.matchdat(j,s,i),nsm)
    if(nsm eq 1) then begin
      matchsodat(sm,*,i)=match.matchdat(j,*,i)
    endif else begin
      if(nsm gt 1) then print,'multiple matches it, j =',i,j
    endelse
  endfor
endfor

; make nhitl and nhitt arrays
for i=0,nuniq-1 do begin
  sh=where(matchsodat(i,s,*) gt 0.,nsh)
  nhitl(i)=nsh
endfor
for i=0,nt-1 do begin
  sh=where(matchsodat(*,s,i) ne 0.,nsh)
  nhitt(i)=nsh
endfor

stop

end
