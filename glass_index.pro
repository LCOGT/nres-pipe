pro glass_index,type,lam,nn
; This routine accepts a string glass type, which is one of
; 'BK7', 'SF2', 'SiO2', 'LLF1', 'PBM2', 'LF5'
; and a wavelength vector lam (in microns).
; It returns the refractive index nn at each wavelength.

; constants
a=[[2.2697665d0,-9.6395197d-3,1.1025458d-2,7.9465126d-5,1.0120957d-5,$
    -4.4096694d-7],$
   [2.6360314d0,-8.9450876d-3,2.5228056d-2,1.1120943d-3,-3.7887387d-5,$
    6.3760973d-6]]     ; dispersion formula coeffs for BK7, SF2
b=[[0.67071081d0,0.433322857d0,0.877379057d0],$  ; SiO2   different dispersion 
   [1.21640125d0,1.33664540d-1,8.83399468d-1],$       ; LLF1
   [1.39446503d0,1.59230985d-1,2.45470216d-1],$       ; PBM2
   [1.28035628d0,1.6350597d-1,8.93930112d-1]]         ; LF5

                                                ;formula coeffs for LLF1, etc
c=[[0.00449192312d0,0.0132812976d0,95.8899878d0],$    ; SiO2
   [8.57807248d-3,4.20143003d-2,1.07593060e+2],$      ; LLF1
   [1.10571872d-2,5.07194882d-2,3.14440142d1],$       ; PBM2
   [9.29854416d-3,4.49135769d-2,1.10493685d2]]        ; LF5

case type of
 'BK7': begin
    pgm=0
    goto,acoeffs
    end
  'SF2': begin
    pgm=1
    goto,acoeffs
    end
  'SiO2': begin
    pgm=0
    goto,bcoeffs
    end
  'LLF1': begin
    pgm=1
    goto,bcoeffs 
    end
  'PBM2': begin
    pgm=2
    goto,bcoeffs
    end
  'LF5': begin
    pgm=3
    goto,bcoeffs
    end
  else: begin
    print,'illegal glass type'
    stop
    end
endcase

acoeffs:
  nn=sqrt(a(0,pgm) + a(1,pgm)*lam^2 + a(2,pgm)/lam^2 + a(3,pgm)/lam^4 + $
        a(4,pgm)/lam^6 + a(5,pgm)/lam^8)
goto,fini

bcoeffs:
  lam2=lam^2
  nn=sqrt(1.d0 + b(0,pgm)*lam2/(lam2-c(0,pgm)) + $
                 b(1,pgm)*lam2/(lam2-c(1,pgm)) + $
                 b(2,pgm)*lam2/(lam2-c(2,pgm)))

fini:

end
