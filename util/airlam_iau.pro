function airlam_iau,lamv
; this routine computes the IAU standard transformation giving
; the air wavelength lama for a given vacuum wavelength lamv (both in Angstroms)

lama=lamv/(1.0d0 + 2.735182d-4 + 131.4182d0/lamv^2 + 2.76249d8/lamv^4)

return,lama

end
