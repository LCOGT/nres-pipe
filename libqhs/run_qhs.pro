; Driver routine for Quick Histogram Smooth.
function run_qhs,          $     ; returns smoothed 2D image
         image,            $     ; input: 2D array to be smoothed
         half_xpix,        $     ; kernel half-size in X (full size is 2N+1)
         half_ypix,        $     ; kernel half-size in Y (full size is 2M+1)
         hmin,             $     ; minimum value kept in histograms
         hmax,             $     ; maximum value kept in histograms
         hquant=hquant,    $     ; desired smoothing quantile (0 <= q <= 1)
         hbins=hbins,      $     ; number of histogram bins to use
         INT_MODE=int_mode       ; EXACT mode for integer input

; Useful defaults:
if NOT keyword_set(hquant) then hquant = 0.5
if NOT keyword_set(hbins)  then hbins  = 100

;; Check dimensions of input array:
dimen = size(image)
if dimen[0] ne 2 then begin
   printf, -2, "Only 2-D images are supported!"
   return, !values.f_nan
ENDIF

;; Adjust accumulator as needed:
if keyword_set(int_mode) then begin
   printf, -2, "INTEGER MODE!"
   accum = 0   ; integer-exact mode
endif else begin
   printf, -2, "INTERPOLATE MODE!"
   ;accum = 1   ; floating-point: bin centers
   accum = 3   ; floating-point: interpolate
endelse

;; Create blank output image (IDL must allocate this):
result = 0.0 * image

;; Select library name based on OS:
lib_name = 'libqhs.so.1.0'                                           ; Linux
if (strcmp(!Version.OS,  'linux')) then lib_name = 'libqhs.so.1.0'   ; Linux
if (strcmp(!Version.OS, 'darwin')) then lib_name = 'libqhs.dylib'    ; Mac OS

;; Check that library exists:
if NOT file_test(lib_name) then begin
   printf, -2, "Error, library not found: " + lib_name
   return, !values.f_nan
endif

;; Smooth input image:
status = call_external(lib_name, 'run_qhsmooth', $
   long(dimen[1]),      $     ;  [in] image NAXIS1
   long(dimen[2]),      $     ;  [in] image NAXIS2
   float(image),        $     ;  [in] input image
   float(result),       $     ; [out] smoothed image
   long(half_xpix),     $     ; [par] kernel X half-size (pixels)
   long(half_ypix),     $     ; [par] kernel Y half-size (pixels)
   double(hquant),      $     ; [par] smoothing quantile (0 < hquant < 1)
   double(hmin),        $     ; [par] histograms lower bound
   double(hmax),        $     ; [par] histograms upper bound
   long(hbins),         $     ; [par] number of histogram bins
   long(accum)          $     ; [par] kernel cumulation mode
   )

;; Return result:
return, result
end

