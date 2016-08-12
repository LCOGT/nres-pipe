pro psh
; Sets up for postscript halftone plots.
; defaults to square 6 x 6 -inch size

set_plot,'ps'
device,bits_per_pixel=8,xsize=6.,ysize=6,/inches
end
