pro blockfit,lamblock,zblock,dblock,blockparms
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
;  .cov = the formal covariance of quantities rr,aa,bb
;  .pldp = (km/s) an estimate of the RV precision attainable from dblock, 
;          assuming that dblock values correspond to observed signal in e-.
;          Note that this takes no account of noise amplification in
;          flat-fielding.  ###Should fix this.###
;

; common data area
common rv_lsq,lambl,zbl,dbl

; constants
c=2.99792458d5

; load data into common
npt=n_elements(lamblock)
lambl=lamblock
zbl=zblock
dbl=dblock

; set up starting parameters
aa0=double(total(dblock)/total(zblock))        ; 1st guess at scaling
pritempl={value:0.d0,fixed:0,parname:'NULL',step:0.d0}
parinfo=[pritempl,pritempl,pritempl]
parinfo[0].step=3.e-7
parinfo[0].parname='rr'
parinfo[1].parname='aa'
parinfo[2].parname='bb'

p0=[0.d0,aa0,0.d0]

; run mpfit
vals=mpfit('rv_mpfit',p0,parinfo=parinfo,covar=cov,/quiet)

; compute pldp
dlamdx=(max(lamblock)-min(lamblock))/(npt-1)
lammid=0.5*(max(lamblock)+min(lamblock))
didlam=deriv(dblock)/dlamdx
pldpix=1./sqrt(total(didlam^2/(dblock > 1.) > 1.e-20))
pldp=c*pldpix/lammid

; make output structure
blockparms={rr:vals(0),aa:vals(1),bb:vals(2),cov:cov,pldp:pldp}

end

