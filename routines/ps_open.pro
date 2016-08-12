PRO ps_open, portrait = portrait, filename = fn, font = font,  $
             square = square_plot,  encapsulated = eps, $
             sizes = sizes, offsets = offsets, page_length = plen, $
             color = cps, qms = qms, $
             bpp = nbpp, ledger = ldgr, silent = silent
;
;+
; Name:
;
;   PS_Open
;
; Purpose:
;
;   Set the plotting device to be PostScript, and save the current plotting
;   device (to restore it when the plot is done).
;
; Calling sequence:
;
;   PS_Open
;
; Keywords:
;
;   PORTRAIT - Normally, PS_Open defines the plotting area as landscape. If
;     this keyword is set, the plotting area will be portrait.
;
;   FILENAME = <string> - Normally, PS_Open uses '/tmp/idl-$USER.ps' for the
;     PostScript file, the keyword FILENAME can be used to override that value.
;     ($USER is retrieved with a getenv('USER')).
;
;   SIZES = <2-elements array> - Specify the plot size.
;     The default plotting area is 10" x 7.5".
;
;   OFFSETS = <2-elements array> - Specify the plot margins.
;     The default plotting area has 0.5", 0.5" margins.
;
;   SQUARE - if set, sets the plotting area to be square.
;     Since the plotting area includes room for labels to axis, this option 
;     alone does not gives you a square plot (cf: !P.REGION).
;
;   FONT - set !P.font to value of FONT
;
;   ENCAPSULATED - produces an encapsulated PostScript plot.
;   
;   BPP = <n> - Set the number of bits per pixel; default value is 8,
;     valid values are 8, 4, OR 2. A higher no produces a better
;     resolution but also a bigger PostScript file.
;
;   COLOR - If set, produces a color PostScript plot.
;
;   LEDGER - If set, selects ledger format (17" x 11" paper).
;     The default plotting area is 16" x 10", with 0.5" margins.
;     Not all printers can print ledger format.
;
;   PAGE_LENGTH = <x> - Specify the actual page lenght.
;     The default lenght is 17" for ledger format, 11" otherwise. 
;     This is needed because IDL's implementation of the YOFFSET keyword to
;     DEVICE in landscape mode is brain dead. The y-offset must be specified
;     relative to the page lenght. This way PS_Open() offsets are more
;     intuitive. (cf: IDL ref. guide, section: PostScript Positioning).
;
;   QMS - If set, reduces the margins for the old QMS printer
;      The horiz margin is increased by 0.8",
;      and the horiz size decreased by 1.0".
;
;   SILENT - If set, disable warning messages
;
; See also: PS_Close
;-
; History:
;   23-Aug-93: added bpp=[2,4,8] option, with 8 bpp as default
;   24-Aug-93: added support for /color, 
;              and reduced the page size for QMS color printer
;   16-Sep-93: added color flag to common block (see also PS_Close)
;    9-Apr-94: added file name to info message
;   11-Apr-94: added LEDGER support (see also PS_Close)
;   28-Apr-94: added SQUARE, and fixed color portrait offset
;    5-May-94: got /SQUARE to actually work
;    7-Jul-95: moved specific margins for QMS color printer to /QMS
;              added SIZES, OFFSETS and PAGE_LENGTH keywords.
; Mar  5 1997: added SILENT keyword
;
;
COMMON ps_common, old_dname, old_pfont, file_name, $
  opened, encaps, color, ledger
;
  silent = keyword_set(silent)
  encaps = keyword_set(eps)
  IF n_elements(opened) EQ 0 THEN opened = 0
;
  IF NOT keyword_set(portrait) THEN portrait = 0
  IF NOT keyword_set(ldgr) THEN ledger = 0 ELSE ledger = 1
  IF portrait NE 0 THEN portrait =  1
  IF NOT keyword_set(plen) THEN $
    IF ledger THEN plen = 17.0 ELSE plen = 11.0
;
  IF n_elements(sizes) EQ 0 THEN BEGIN
    ;; default sizes
    IF ledger THEN sizes = [16., 10.] ELSE sizes = [10., 7.5]
    IF portrait THEN BEGIN 
      sizes = shift(sizes, 1)
    ENDIF
  ENDIF ELSE BEGIN
    IF n_elements(sizes) NE 2 THEN BEGIN
      message, /info, 'ERROR: invalid SIZES specification'
      return
    ENDIF
  ENDELSE
;
  IF n_elements(offsets) EQ 0 THEN BEGIN
    ;; default offsets
    offsets =  [0.5, 0.5]
  ENDIF ELSE BEGIN
    IF n_elements(offsets) NE 2 THEN BEGIN
      message, /info, 'ERROR: invalid OFFSETS specification'
      return
    ENDIF
  ENDELSE
;
  IF ledger THEN BEGIN
    portrait = 1 - portrait
    sizes = shift(sizes, 1)
    offsets = shift(offsets, 1)
  ENDIF
;  
  IF opened EQ 1 THEN BEGIN
    message, /info, $
    'WARNING: device already opened to PS, closing it first.' 
    message, /info, $
    '         any plot in progress have been lost.'
  ENDIF ELSE BEGIN
    old_dname = !D.name
    old_pfont = !P.font
  ENDELSE
  
  set_plot, 'PS'
  device, /close
  opened = 1
  
  IF NOT keyword_set(fn) THEN fn = '/tmp/idl-'+getenv('USER')+'.ps'
  
  IF encaps THEN $
    device, /encapsulated, filename = fn $
  ELSE $
    device, filename = fn
;
  file_name = fn
;
  color = 0
  IF keyword_set(cps) THEN BEGIN
    device, /color
    color = 1
  ENDIF
;
  IF keyword_set(qms) THEN BEGIN 
    IF portrait THEN ii = 0 ELSE ii = 1
    sizes(ii)   = sizes(ii)   - 1.0 
    offsets(ii) = offsets(ii) + 0.8
  ENDIF

  IF keyword_set(square_plot) THEN BEGIN
    msize = min(sizes)
    sizes = [msize, msize]
  ENDIF
;
  IF portrait THEN device, /portrait, $
    /inches, xsize = sizes(0), ysize = sizes(1), $
    xoffset = offsets(0), yoffset = offsets(1) $
  ELSE device, /landscape, $
    /inches, xsize = sizes(0), ysize = sizes(1), $
    xoffset = offsets(1), yoffset = plen - offsets(0)
;
  IF keyword_set(nbpp) THEN device, bits_per_pixel = nbpp $
  ELSE device, bits_per_pixel = 8
;
  IF keyword_set(font) THEN !p.font = font
;    
  IF NOT silent THEN BEGIN
    message, /info, 'output redirect to PostScript file ' + fn
    IF keyword_set(square_plot) THEN msg = 'using a square area '$
    ELSE msg = 'using an area '
    IF color THEN msg = 'color enabled, ' + msg
    message, /info, msg + string(sizes, format = "(f4.1,' x ',f4.1)") + $
      '; offsets: ' + string(offsets, format = "(f4.1,', ',f4.1)")
  ENDIF
;
  return
END
