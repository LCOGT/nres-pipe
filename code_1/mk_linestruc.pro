pro mk_linestruc,mjds,nlines,order,lamb,linelam,xpos,amp,width,lsarray
; This routine creates an array of line structures, each one describing a
; group of measurements from different spectra, all supposedly relating to the
; same ThAr line.  
; Input parameters mjds,nlines,order,lamb,linelam,xpos,amp,width all come
; from a call to rd_matchtest.pro.
; The structures in the output array lsarray contain
; .nomlam = nominal wavelength = wavelength of first-found line
; .nomxpos = xpos (pix) of first-found line
; .nhits = number of lines found that coincide with this structure
; .order = order index for this structure
; .delx(nfiles) = vector of differences (xpos-nomxpos) for all hits
; .dellam(nfiles) = vector of differences (lamb-nomlamb) for all hits
; .errlam(nfiles) = vector of differences (lamb-linelam) for all hits
; .ampl(nfiles) = amplitudes of lines for all hits
; .wid(nfiles) = widths of lines for all hits
; .mjd(nfiles) = MJD of each hit

; constants
nord=68             ; doesn't matter if too big
lamthrsh=.01        ; wavelength match radius, nm
xthrsh=4.           ; x-coordinate match radius, pix
nfiles=n_elements(mjds)

; create lsarray
lsarray=[]
nstruc=0            ; current number of line structures in array

; make a dummy structure so searches don't reference an empty array
lsarray=[lsarray,{nomlam:200.d0,nomxpos:-100.,nhits:1,order:-1,$
        delx:fltarr(nfiles),dellam:dblarr(nfiles),errlam:dblarr(nfiles),$
        ampl:fltarr(nfiles), wid:fltarr(nfiles),mjd:dblarr(nfiles)}]

; loop over number of input files
for i=0,nfiles-1 do begin

; loop over orders
  for iord=0,nord-1 do begin
    s=where(order(0:nlines(i)-1,i) eq iord,ns)  ; applies to current input file
    if(ns le 0) then goto,skipord      ; skip if no input lines w/ this order
    
; loop over lines in the order
    for j=0,ns-1 do begin
      sord=s[j]                     ; index of current input ThAr line
      lamdif=abs(lsarray.nomlam - lamb[sord,i])
      ordarr=lsarray.order          ; order indices in lsarray elements
      sg=where(ordarr eq iord and lamdif le lamthrsh,nsg)
          ; sg indexes into lsarray
      if(nsg le 0) then begin
;       create a new lsarray entry
      errt=dblarr(nfiles)
      errt(0)=lamb[sord,i]-linelam[sord,i]
      ampt=fltarr(nfiles)
      ampt(0)=amp[sord,i]
      widt=fltarr(nfiles)
      widt(0)=width[sord,i]
      mjdt=dblarr(nfiles)
      mjdt(0)=mjds[i]
      new={nomlam:lamb[sord,i],nomxpos:xpos[sord,i],nhits:1,order:iord,$
        delx:fltarr(nfiles),dellam:dblarr(nfiles),errlam:errt,$
        ampl:ampt,wid:widt,mjd:mjdt}
      lsarray=[lsarray,new]
    
      endif else begin
        if(nsg eq 1) then begin
          sgg=sg[0]         ; sgg is index into lsarray for matching line struct
        endif else begin
          md=min(lamdif(sg),ix)
          sgg=sg(ix)
        endelse

;       update an existing lsarray entry
        hits=lsarray[sgg].nhits
      ; (no need to touch lsarray[sgg].order)
        lsarray[sgg].delx[hits]=xpos[sord,i]-lsarray[sgg].nomxpos
        lsarray[sgg].dellam[hits]=lamb[sord,i]-lsarray[sgg].nomlam
        lsarray[sgg].errlam[hits]=lamb[sord,i]-linelam[sord,i]
        lsarray[sgg].ampl[hits]=amp[sord,i]
        lsarray[sgg].wid[hits]=width[sord,i]
        lsarray[sgg].mjd[hits]=mjds[i]   
        lsarray[sgg].nhits=hits+1

      endelse
    endfor       ; end loop over lines in order
    skipord:
  endfor             ; end loop over orders
endfor               ; end loop over files

end
