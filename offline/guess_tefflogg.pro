pro guess_tefflogg,spec,vmag,bmag,teff,logg
; This routine accepts
; spec(2) = string array containing MK spectral type and luminosity class,
; and V and B magnitudes.  It returns a guess at teff and logg,
; based on interpolating into a table of teff vs B-V, with separate tables
; for dwarfs and giants.
; If spec(1) is successfully parsed, it is used to guess logg; otherwise
; the target is taken to be logg=3.8, hence a mild subgiant.

; data for interpolation from Mamajek's table
logtt=[4.62550,4.59650,4.56750,4.54100,4.51550,4.50150,4.43850,4.35150,$
      4.24850,4.20950,4.15350,4.06300,4.00200,3.95550,3.92450,3.90500,$
      3.88300,3.86450,3.84000,3.82450,3.80800,3.79250,3.77650,3.76500,$
      3.75550,3.75000,3.73850,3.72550,3.70950,3.67500,3.63500,3.60600,$
      3.59150,3.57400,3.55600,3.53850,3.50850,3.48600,3.46600,3.42800,$
      3.40650]

bmvt=[-0.32000,-0.32000,-0.32000,-0.31988,-0.31738,-0.30733,-0.28133,-0.23394,$
    -0.18961,-0.16027,-0.13166,0.087166,0.020333,0.052500, 0.11472, 0.16888,$
     0.22383, 0.28227, 0.34755, 0.40327, 0.46083, 0.51900, 0.57233, 0.625944,$
     0.66516, 0.69327, 0.73272, 0.79572, 0.88861,  1.0370,  1.1992,  1.32522,$
      1.3970,  1.4524,  1.4947,  1.5435,  1.6390,  1.7936,  1.9517,  2.06778,$
      2.1733]

; parse spec(1) for luminosity class
sp1=spec(1)

cl=0
if(strpos(sp1,'IV') ge 0) then cl=4
if(strpos(sp1,'III') ge 0) then cl=3
if(strpos(sp1,'V') ge 0 and cl ne 4) then cl=5
if(strpos(sp1,'II') ge 0 and cl ne 3) then cl=2
if(strpos(sp1,'I') ge 0 and cl eq 0) then cl=1
if(cl eq 0) then cl=5           ; default guess

logg=float(cl)-1.

; make B-V
if(bmag lt (-90.) or vmag lt (-90.)) then begin      ; invalid mag data
  bmv=0.65
endif else begin
  bmv=bmag-vmag
endelse
bmv=((-0.32) > bmv) < 2.1733

; if cl >= 4, then interpolate to get teff.
if(cl ge 4) then begin
  if(bmag lt (-90.) or vmag lt (-90.)) then begin      ; invalid mag data
    bmv=0.65
  endif else begin
    bmv=bmag-vmag
  endelse
  bmv=((-0.32) > bmv) < 2.1733

  logt=interpol(logtt,bmvt,bmv)
  teff=10.^logt
endif else begin

; use a giant color-temp relation, if color is red enough
  if(bmv ge 0.7) then begin
    teff=5000.-(bmv-0.7)*1444.
  endif else begin
; if not red enough, use the dwarf relation
    logt=interpol(logtt,bmvt,bmv)
    teff=10.^logt
  endelse

endelse

end
