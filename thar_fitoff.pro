pro thar_fitoff,fibindx,filin,filout,cubfrz=cubfrz,tharlist=tharlist
; This routine reads a ThAr DOUBLE extracted spectrum file filin, and
; puts its corspec array into the common data area.
; It then calls thar_fitall to fit a model of the spectrograph to
; the observed ThAr line positions
; Results embedded in a "tharstruc" structure are saved in common and are
; written to an output idl save file filout.
; On input, filin must be a full pathname.
; Keyword cubfrz is passed on to thar_fitall;  if set, it prevents modification
; of the rcubic coefficients read from spectrographs.csv.

@nres_comm
@thar_comm
common thar_dbg,inmatch,isalp,ifl,iy0,iz0,ifun

; constants
outdir=nresrooti+'reduced/thar/'
infile=filin
outfile=outdir+filout
ierr_c=0                             ; clear errors in common before starting

; read the input file
corspec=readfits(infile,hdr)
sz=size(corspec)
nx_c=sz(1)
nord_c=sz(2)
site=strtrim(sxpar(hdr,'SITEID'),2)
sgsite=site
mjdc=sxpar(hdr,'MJD')

; adjust fibindx (which nominally runs [0-2]) to correspond to indices in
; corspec
objects=sxpar(hdr,'OBJECTS')
words=get_words(objects,nwd,delim='&')
; case of only fibers 0,1 available
; fibindx is in range [1,2] for a 2-fiber system
; fibindx is in range [0,1,2] for a 3-fiber system
; fibin0 is the index of the plane in corspec that contains data we need.
if(nwd eq 2) then fibin0=fibindx-1
; case of 3 possible fibers, the first one empty
if(nwd eq 3 and strtrim(strupcase(words(0)),2) ne 'THAR') then fibin0=fibindx-1
if(nwd eq 3 and strtrim(strupcase(words(0)),1) eq 'THAR') then fibin0=fibindx
tharspec_c=corspec(*,*,fibin0)

; call thar_fitall
thar_fitall,sgsite,fibin0,ierr,cubfrz=cubfrz,tharlist=tharlist

tharstruc={mm:mm_c,grspc_c:grspc_c,sinalp:sinalp_c,y0:y0_c,z0:z0_c,$
gltype:gltype_c,apex:apex_c,lamcen:lamcen_c,rot:rot_c,pixsiz:pixsiz_c,nx:nx_c,$
nord:nord_c,iord:iord_c,xpos:xpos_c,amp:amp_c,wid:wid_c,$
linelam:linelam_c,matchlam:matchlam_c,matchdif:matchdif_c,lam:lam_c,y0m:y0m_c,$
ncoefs:ncoefs_c,coefs:coefs_c,outp:outp_c}

save,tharstruc,file=outfile

end
