pro get_gaiadat,targra,targdec,gaiaparms
; This routine uses the python script query_GAIA.py to do a Gaia cone search
; for a star near (within 1.5 arcmin) targra, targdec (J2000.0 coords). If 
; stars are found, the brightest is translated from Gaia's J2015.0 back to
; J2000.0, and if coordinates match within 2 arcsec, the match is accepted.
; In that case, Gaia results as follows are returned in structure gaiaparms:
;  .gra, .gdec = RA, Dec (decimal degrees) projected to J2000.0
;  .gpmra, .gpmdec = proper motions in RA, Dec (milli-arcsec per year on sky)
;  .gplax = parallax (arcsec), computed as 1./(Gaia distance)
;  .grv = Gaia barycentric RV (km/s)
;  .gerrv = err estimate on grv (km/s)
;  .gvmag ~= Vmag, (stellar magnitudes) computed from G_BP and G_RP
;  .gbmag = G_BP (magnitudes)
;  .grmag = G_RP (magnitudes)
;  .ggmag = G_G (magnitudes)
;  .gteff = Gaia Teff (K)
;  .glum  = Gaia Luminosity
;  .glogg ~= stellar log(g), computed from Gaia radius_val, teff, lum_val
;
;  If search is successful and all needed values are present in result, then
;  on return gerr=0, else 1.

; constants
gerr=0
pycode='query_GAIA.py'
radian=180./!pi
bigrad=1.5               ; big capture radius, arcmin
smallrad=2.0/3600.       ; small capture radius, degrees

; do the gaia cone search 
searchradius=bigrad

cmd = 'python '+pycode+' '+string(ra)+' '+string(dec)+' '+string(searchradius)
spawn,cmd,result
words=get_words(result[5],nw,delim=' ')

distance                = words[0]
gaia_ra                 = words[1]
gaia_dec                = words[2]
gaia_ppmra              = words[3]
gaia_ppmdec	        = words[4]
gaia_Gmag               = words[5]
gaia_BPmag              = words[6]
gaia_RPmag              = words[7]
gaia_Teff               = words[8]
gaia_Lum                = words[9]
gaia_Radius             = words[10]
gaia_RV                 = words[11]
gaia_errorRV            = words[12]

; compute J2000.0 coords, compare with input
cosdec=cos(targdec/radian)
gra=gaia_ra-(.015*gaia_ppmra/(cosdec*3600.))
gdec=gaia_dec-(.015*gaia_ppmdec/3600.)
dra=3600.*(targra-gra)*cosdec
ddec=3600.*(targdec-gdec)
dr=sqrt(dra^2+ddec^2)         ; unsigned separation in arcsec

; if it failed, set default values and gerr, bail out
if(dr gt smallrad) then begin
  gaiaparms={gra:dra,gdec:ddec,gpmra:0.,gpmdec:0.,gplax:0.,grv:0.,gerrv:0.,$
     gbmag:0.d0,$ gvmag:0.,gbmag:0.,grmag:0.d0,ggmag:0.d0,gteff:0.,glogg:0.,$
     glum:0.,gerr:1}

endif else begin 

; search succeeded.
  gplax=1./distance

; estimate vmag
  vmag=vmag_estim(gaia_BPmag,gaia_BRmag)

; estimate logg
  glogg=logg_estim(gaia_Teff,gaia_Radius,gaia_Lum)

; set outputs
gaiaparms={gra:gra,gdec:gdec,gpmra:gaia_ppmra,gpmdec:gaia_ppmdec,gplax:gplax,$
    grv=gaia_RV,gerrv:gaia_errorRV,gvmag:vmag,gbmag:gaia_BPmag,$
    grmag:gaia_BRmag,ggmag:gaia_Gmag,gteff:gaia_Teff,glogg:glogg,glum:gaia_Lum,$
    gerr:gerr}

endelse

end
