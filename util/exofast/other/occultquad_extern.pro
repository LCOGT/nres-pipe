pro occultquad_extern, z0, u1, u2, p0, muo1, mu0
;+
; NAME:
;   OCCULTQUAD_EXTERN
;
; PURPOSE: 
;   This routine computes the lightcurve for occultation of a
;   quadratically limb-darkened source without microlensing. 
;
; DESCRIPTION:
;   This is an IDL wrapper for the fortran version of the code, and is
;   a 2-5x faster, drop-in replacement for EXOFAST_OCCULTQUAD; see
;   complete documentation there. The shared libraries must be
;   compiled for your system before you can use this. See README file
;   in this directory.
;
; MODIFICATION HISTORY
;  2012/06 -- Jason Eastman, Public release
;-

nz = n_elements(z0)
muo1 = dblarr(nz)
mu0 = dblarr(nz)

if !version.memory_bits eq 64 then begin
    dummy = call_external(getenv('EXOFAST_PATH') + '/other/exofast.so', $
                          'occultquadfortran64_', double(z0), double(u1), $
                          double(u2), double(p0), muo1, mu0, nz)
endif else begin
    dummy = call_external(getenv('EXOFAST_PATH') + '/other/exofast.so', $
                          'occultquadfortran_', double(z0), double(u1), $
                          double(u2), double(p0), muo1, mu0, nz)
    
endelse

end
