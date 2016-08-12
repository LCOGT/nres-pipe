FUNCTION read_table, fn, dp = dp, header = hdr, colSep = csep, $
                     nskip = nskip, format = fmt, $
                     autoskip = askip, $
                     ncols = ncols, verbose = verbose
;
;+
; data = read_table(fn)
;
; read an ascii file organized in constant no of col per row, and return
;   a float array; uses the first line to deduce the number of columns (blank
;   separated), unless NCOLS is set.
;
; Optional Input:
;
;   nskip:    no of (header) lines to skip, def.: 0
;   colsep:   column separator, def.: ' '
;   ncols:    no of columns in the file, (don't try to guess using first line)
;   format:   format specification, def.: none
;             [need ncols to use format]
;   autoskip: flag, if set skip as many line as needed,
;             skip lines that start w/ a #
;   dp:       flag, if set return double precision array
;   verbose:  flag, if set print out some information about the file
;
; Optional Output:
;
;   header:  header, ie the lines skipped
;-
;
;on_error, 2
IF NOT keyword_set(csep)  THEN csep = ' '
IF NOT keyword_set(nskip) THEN nskip = 0 
IF NOT keyword_set(ncols) THEN ncols = 0 
;
dp = keyword_set(dp)
askip = keyword_set(askip)
verbose = keyword_set(verbose) 
;
spawn, /noshell,  ['wc', '-l', fn], wc
nlines = fix(wc(0))
nlines = nlines-nskip
;
openr, lu, /get_lun, fn
line = ''
;
IF nskip GT 0 THEN BEGIN
  hdr = strarr(nskip)
  FOR i = 0, nskip-1 DO BEGIN
    readf, lu, line
    IF verbose THEN print, line
    hdr(i) = line
  ENDFOR
ENDIF
;
IF askip THEN hdr = ''
;
IF ncols EQ 0 THEN BEGIN
  ;;
  IF keyword_set(fmt) THEN message, 'Need ncols when using format'
  ;;
  loop:
  point_lun, -lu, pos
  readf, lu, line
  IF askip THEN BEGIN
    str = strmid(strtrim(line, 2), 0, 1)
    IF str EQ '#' THEN BEGIN
      IF verbose THEN print, line
      hdr = [hdr, line]
      nlines = nlines-1
      GOTO, loop
    ENDIF
  ENDIF
  point_lun, lu, pos
  ;;
  vals = str_sep(line, csep)
  FOR i = 0, n_elements(vals)-1 DO BEGIN
    IF vals(i) NE '' THEN ncols = ncols+1
  ENDFOR
  ;;
ENDIF 
;
IF dp THEN $
  vals = dblarr(ncols, nlines)   $
ELSE $
  vals = fltarr(ncols, nlines)
;
IF keyword_set(fmt) THEN $
  readf, lu, vals, format = fmt $
ELSE $
  readf, lu, vals
;
close, lu
free_lun, lu
;
IF verbose THEN $
  print, fn, ' holds a', ncols, ' columns by', nlines, ' lines table'
;
IF askip AND n_elements(hdr) GT 1 THEN hdr = hdr(1:*)
;
return, vals
END
