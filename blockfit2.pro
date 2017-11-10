pro blockfit2,lamblock,zblock,dblock,blockparms
; This routine compares the spectrum blocks 
;  zblock = a block from the ZERO file used for this spectrum
;  lamblock = the wavelength scale appropriate to zblock, including any
;    redshifts that have been applied
;  dblock = the corresponding block from the target spectrum.
; It is assumed that both zblock and dblock are taken from lowpassed
; spectra, produced by smoothing the original versions.
; The routine fits dblock to a model constructed from zblock as follows:
;    model(lamblock)=zblock(lamblock/(1.+r))*(a + b*y1)
;      where r is the redshift of dblock relative to zblock,
;      a and b are scaling constants, and y1 is the 1st-order legendre
;      polynomial on the pixel interval covered by dblock.
; The fit is done using MPFIT, with data passed to the routine rv_mpfit
; via a common block rv_lsq.
; On output, blockparms is a structure containing
;  .rr = the redshift, with RV ~ r*c
;  .aa = the scaling constant a
;  .bb = the scaling constant b
;  .cov = the formal covariance of quantities aa,bb,rr
;  .pldp = (km/s) an estimate of the RV precision attainable from dblock, 
;          assuming that dblock values correspond to observed signal in e-.
;          Note that this takes no account of noise amplification in
;          flat-fielding.  ###Should fix this.###
;          Also does not compute pldp for the ThAr spectrum.  This is not
;          a serious omission because many blocks have few or no ThAr
;          lines, but the calculation of total ThAr precision should be
;          addressed somewhere.
;

; common data area
;common rv_lsq,lambl,zbl,dbl

; constants
c=2.99792458d5
taper=[0.,.02,.10,.21,.35,.50,.65,.79,.90,.98]
taperr=rotate(taper,2)

; get size of vectors, make wts array
npt=n_elements(lamblock)
wts=fltarr(npt)+1.
; give low weight to edges of the block of nonzero data
; that are presumed to lie inside this block somewhere.
s=where(dblock ne 0.,ns)
if(ns gt 20) then begin
  wts(s(0:9))=taper
  wts(s(ns-10:ns-1))=taperr
endif else begin
  vals=[0.d0,0.d0,0.d0]
  cov=fltarr(3,3)
  pldp=0.d0
  goto,bail
endelse

; set up starting parameters
;aa0=double(total(dblock)/total(zblock))        ; 1st guess at scaling

; run lsqblkfit
;vals=mpfit('rv_mpfit',p0,parinfo=parinfo,covar=cov,/quiet)
vals=lsqblkfit(lamblock,zblock,dblock,wts,cov)

; compute pldp
dlamdx=(max(lamblock)-min(lamblock))/(npt-1)
lammid=0.5*(max(lamblock)+min(lamblock))
didlam=deriv(dblock)/dlamdx
pldpix=1./sqrt(total(didlam^2/(dblock > 1.) > 1.e-20))
pldp=c*pldpix/lammid

bail:

; make output structure
blockparms={rr:vals(2),aa:vals(0),bb:vals(1),cov:cov,pldp:pldp}

end
