#!/bin/bash
#
#    Test ezImg wrapper for IDL.
#
# Rob Siverd
# Created:      2015-12-10
# Last updated: 2015-12-10
#--------------------------------------------------------------------------
#**************************************************************************
#--------------------------------------------------------------------------

### Check for arguments:
#usage () { 
#   Recho "\nSyntax: $this_prog --START\n\n"
#   #Recho "\nSyntax: $this_prog arg1\n\n"
#}
#if [ "$1" != "--START" ]; then
##if [ -z "$1" ]; then
#   usage >&2
#   exit 1
#fi

##**************************************************************************##
##==========================================================================##
##--------------------------------------------------------------------------##

idl << EOF

load_name = 'sqa0m801-kb35-20151208-0021-g00.fits'
save_name = 'test_ezimg.fits'
image = float(readfits(load_name, hdr))

; Select kernel size/shape:
half_xpix = 25
half_ypix = 25
; NOTE: these are half-sizes. Resulting kernel will be 51x51.

;hmin =  500.0
;hmax = 1000.0

; If safe histogram bounds are not known in advance, start with image min/max
; and narrow it down.
hmin = double(MIN(image))    ; image minimum is safest guess
hmax = double(MAX(image))    ; image maximum is safest guess
bins = 50            ; use fewer bins (faster) to figure out limits
bsize = (hmax - hmin) / double(bins)
printf, -2, "Initial limits: " + string(hmin) + ',' + string(hmax)
printf, -2, "Initial bin size: " + string(bsize)

idata = run_qhs(image, half_xpix, half_ypix, hmin, hmax, hquant=0.5, hbins=50)
printf, -2, "Result min: " + string(MIN(idata))
printf, -2, "Result max: " + string(MAX(idata))

; Extract limits from first run, re-do with more bins:
new_hmin = double(MIN(idata) - bsize)
new_hmax = double(MAX(idata) + bsize)
idata = run_qhs(image, half_xpix, half_ypix, $
         new_hmin, new_hmax, hquant=0.5, hbins=200)


printf, -2, "Saving result to file: " + save_name
writefits, save_name, idata

EOF

exit 0

######################################################################
# CHANGELOG (25_wrapper_test.sh):
#---------------------------------------------------------------------
#
#  2015-12-10:
#     -- First created 25_wrapper_test.sh.
#
