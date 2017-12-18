pro rv_datin,specname
; This routine reads the fits SPEC file specname and uses information from its
; header and data segment to populate items in common block nres_comm.
; It also generates names of the THAR and EXPM files that correspond to the
; input SPEC file, reads these files, and stores needed data from them in
; nres_comm.

@nres_comm
@thar_comm

; constants
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
thardir='reduced/thar/'
rvdir='reduced/rv/'
expmdir='reduced/expm/'
extrdir='reduced/extr/'
blazdir='reduced/blaz/'

; read the SPEC file, store what is immediately useful
corspec=readfits(specname,thdr,/silent)
nblock=sxpar(thdr,'NBLOCK')
nx=sxspar(thdr,'NX')
nord=sxpar(thdr,'NORD')
nfib=sxpar(thdr,'NFIB')
specdat={nblock:nblock,nx:nx,nord:nord,nfib:nfib}

t1lon=sxpar(thdr,'LONG1')
t1lat=sxpar(thdr,'LAT1')
t1ht=sxpar(thdr,'HT1')
t1ra=sxpar(thdr,'TEL1_RA')
t1dec=sxpar(thdr,'TEL1_DEC')
t2lon=sxpar(thdr,'LONG2')
t2lat=sxpar(thdr,'LAT2')
t2ht=sxpar(thdr,'HT2')
t2ra=sxpar(thdr,'TEL2_RA')
t2dec=sxpar(thdr,'TEL2_DEC')
tel1dat={longitude:t1lon,latitude:t1lat,height:t1ht,ra:t1ra,dec:t1dec,$
         object:obj1}
tel2dat={longitude:t2lon,latitude:t2lat,height:t2ht,ra:t2ra,dec:t2dec,$
         object:obj2}

datestrd=sxpar(thdr,'DATESTRD')
tharpath=nresrooti+thardir+'THAR'+datestrd+'.fits'
expmpath=nresrooti+expmdir+'EXPM'+datestrd+'.fits'
extrpath=nresrooti+extrdir+'EXTR'+datestrd+'.fits'
blazpath=nresrooti+blazdir+'BLAZ'+datestrd+'.fits'

; read the BLAZ and EXTR files, and save their contents
blazspec=readfits('blazpath',blazhdr,/silent)
extrspec=readfits('extrpath',extrhdr,/silent)

; read the THAR file
lam=readfits(tharpath,tharhdr,/silent)



