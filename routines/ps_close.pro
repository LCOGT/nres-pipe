PRO Ps_close, noprint = noprint, noid = noid, $
              saveas = saveas, printer = printer, $
              transparency = transparency, options = options, $
              lpr = lpr_cmd, silent = silent
;
;+
; Name:
;
;  PS_Close
;
; Purpose:
;
;    Closes the PostScript plotting device (opened with PS_Open),
;    adds an optional time-stamp in the lower left corner,  
;    sends the PostScript file to the default printer ($PRINTER, or `ssplw'),
;    and restore the plotting device saved by PS_Open.
;
;    If color PostScript was enabled (see keyword /COLOR in PS_Open),
;    the default printer is $COLORPRINTER, or `psc1' the high volume CF color
;    printer. 
;
; Calling sequence:
;
;    PS_Close
;
; Keywords:
;
;    NOID - If set, the time-stamp ID is not added to the plot.
;  
;    NOPRINT - If set, the PostScript plotting device is closed, and 
;      the plotting device saved by PS_Open is restore, 
;      but the PostScript file is NOT sent to the printer. 
;  
;    SAVEAS = <string>. Save the PostScript file by copying it to the
;      specified file. The plot is still printed, unless NOPRINT is set.
;  
;    PRINTER = <string>. Send the plot the specified printer.
;      By default the enviroment variable PRINTER (or COLORPRINTER) is used to
;      determine the printer to use. If it is not set the defaul values are
;      ssplw (or psc1).
;
;    TRANSPARENCY - If set, requests a transparency.
;      Not all printers support this option (-SInputSlot=Transparency).
;      (Only the color printers do)
;
;    OPTIONS = <string>. Optional extra options for the pslpr command.
;      Example: OPTIONS = '-SDuplex' to use duplex printing.
;
;    LPR = <string>. Specify the command to use to print the file; by defaut
;      pslpr is used. Note that if this keyword is specified, the keywords
;      PRINTER, TRANSPARENCY and OPTIONS are ignored. 
;      Example: LPR = '/usr/bin/lp'
;
;   SILENT - If set, disable warning messages
;
; See also: PS_Open
;-
; History:
;   17-Sep-93: added color flag to common block 
;              hence uses /h/sylvain/sbin/lwiplr to print color plots.
;    9-Apr-94: added stuff to info messages
;   13-Apr-93: cleaned up "transparency" bug
;              added LEDGER support
;   11-May-94: added /LLWR
;    7-Jul-95: removed LWIPLR support (obsolete),
;              set default printer for color plots is psc1,
;              removed `color only' restrictions,
;              for dye-sublimation printer use PRINTER='pspc',
;              for ledger b/w printer use PRINTER='psp1' or 'psp2'.
; Sep 14 1995: replaced lw by ssplw and 
;                       /h/sylvain by /home/sylvain
; Oct 23 1996: replaced LLWR (obsolete) by LPR keyword
; Mar  5 1997: added SILENT keyword
; Apr 29 1997: uses PRINTER and COLORPRINTER enviroments
;
COMMON ps_common, old_dname, old_pfont, file_name, $
  opened, encaps, color, ledger
;
  silent = keyword_set(silent)
  IF n_elements(opened)  EQ 0 THEN opened = 0
;
; handle error conditions
;  
  IF opened EQ 0 THEN  BEGIN
    message, /info, 'ERROR: PS device not opened, you must open it first.'
    message, /info, '       (use PS_Open).'
    return
  ENDIF
;
; set default printer
;
  IF NOT keyword_set(printer) THEN BEGIN
    IF color THEN pn = getenv('COLORPRINTER') ELSE pn = getenv('PRINTER')
    IF pn EQ '' THEN BEGIN
      IF color THEN pn = 'psc1' ELSE pn = 'ssplw' 
    ENDIF 
  ENDIF ELSE $
    pn = printer
;
; add the time stamp to the plot, and close the device
;  
  IF NOT keyword_set(noid) THEN put_id
  device, /close
  opened = 0
;
; save as?
;  
  IF keyword_set(saveas) THEN BEGIN
    cmd = ['cp', file_name, saveas]
    spawn, cmd, /noshell
    IF NOT silent THEN $
      message, /info, 'PostScript plot saved as ' +saveas
  ENDIF
;
  IF NOT keyword_set(noprint) THEN BEGIN
    IF encaps THEN BEGIN
      message, /info, 'EPS file, not printing it.'
    ENDIF ELSE BEGIN
      ;;
      ;; lpr = '' option ignore printer = ''
      ;;
      IF keyword_set(lpr_cmd) THEN BEGIN
        cmd = lpr_cmd
      ENDIF ELSE BEGIN
        CASE !version.arch OF
          'mipseb': cmd = 'pslpr -P'+pn
          ;;
          'sparc': BEGIN
            ;; IDL is still too stupid to be helpfull
            spawn,[ 'uname', '-r'], /noshell, result
            osver = float(result(0))
            IF osver GE 5.0 THEN $
              cmd = 'pslpr -d'+pn $
            ELSE $
              cmd = 'pslpr -P'+pn
          END
          ;;
          ELSE: cmd = 'pslpr -d'+pn
        ENDCASE
        ;;
        IF ledger THEN cmd = cmd + ' -SPageSize=Ledger'
        IF keyword_set(transparency) THEN $
          cmd = cmd + ' -SInputSlot=Transparency'
        IF keyword_set(options) THEN cmd = cmd + ' ' + options
        ;;
      ENDELSE
      
      IF color THEN $
        msg = 'Color PostScript plot printed on printer ' $
      ELSE $
        msg = 'PostScript plot printed on printer ' 
    
      cmd = cmd + ' ' + file_name
;;    print, str_sep(cmd,  ' '), format = "(99(a,':'))"
;;    stop
      spawn, str_sep(cmd,  ' '), /noshell
      IF NOT silent THEN BEGIN
        message, /info, msg+pn
        message, /info, '(using "'+cmd+'")'
      ENDIF
    ENDELSE
  ENDIF
;  
  set_plot, old_dname
  !p.font =  old_pfont
  IF NOT silent THEN $
    message, /info, 'plotting device restored as ' + old_dname
;  
  return
END
