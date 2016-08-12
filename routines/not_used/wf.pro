PRO WF,FILENAME,DATA,HEADER
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;	WF (stands for WriteFits)
; CALLING SEQUENCE:
;	wf, filename, data [,header] 
; PURPOSE:
;	Write an array into a disk FITS file     
; INPUTS:
;	FILENAME = String containing the name of the file to be written.
;	DATA = Image array to be written to FITS file.
; OPTIONAL INPUT:
;	HEADER = String array containing the header for the FITS file.
;		 If variable HEADER is not given, the program will generate
;		 a header array.
; OUTPUTS:
;	None
; RESTRICTIONS:
;       (1) Does not yet support REAL*4 or REAL*8 (BITPIX = -32,-64) in VMS
;       (2) It is highly recommend to set the FITS keywords BSCALE =1, and 
;           BZERO=0 when writing REAL*4 or REAL*8 data.
; MODIFICATION HISTORY:
;	WRITTEN, Jim Wofford, January, 29 1989
;	MODIFIED, Kanav Bhagat, July 25, 1990
;		ability to process multi-dimensional arrays
;		use of sxpar, sxaddpar, converted to version 2 IDL
;	MODIFIED, Michael R. Greason, August 1990
;		Added byte-swapping.
;       MODIFIED, Wayne Landsman, added BITPIX = -32,-64 support for UNIX
;       MODIFIED, Dan Haynes, correct errors in writting data, 
; WARNING:
;       wf can NOT write more than one FITS frame to a file.  If it is
;       called a second time with the same file name it overwrites the
;       previous header and images.  Could add nframe capability - if
;       someone desires it.
;
; SEE ALSO:
;       The routine rf reads FITS data files.
;-------------------------------------------------------------------------------
ON_ERROR,2
IF N_PARAMS(0) LT 2 THEN MESSAGE, $
         'Calling Sequence: WRITEFITS,FILENAME,DATA,[HEADER]',/NONAME
;
; Byte-swap the data.
;
	fitsbyte, data
;
; Get information about data
;                             
	SIZ = SIZE(DATA)
	NAXIS = SIZ(0)                    ;Number of dimensions
        NAX = SIZ(1:NAXIS)                ;Vector of dimensions
        LIM = SIZ(NAXIS+2)                ;Total number of data points
	TYPE = SIZ(NAXIS + 1)             ;Data type
;       PRINT,'TYPE IS',TYPE
;
	CASE TYPE OF
		7:  BEGIN		  ;String
			BITPIX = 8  
			BITCOMM = '1-BYTE CHARACTER'
			DATATYPE = 'LOGICAL*1'
			DATACOMM = 'CHARACTER'
		    END
		1:  BEGIN		  ;Byte
			BITPIX = 8
			BITCOMM = '1-BYTE TWOS-COMPL INTEGER'
			DATATYPE = 'LOGICAL*1'
			DATACOMM = 'BYTE'
		    END
		2:  BEGIN		  ;Integer
			BITPIX = 16
			BITCOMM = '2-BYTE TWOS-COMPL INTEGER'
			DATATYPE = 'INTEGER*2'
			DATACOMM = 'SHORT INTEGER'
		    END
		4:  BEGIN		  ;Floating point
			BITPIX = -32
			BITCOMM = '4-BYTE FLOATING POINT'
			DATATYPE = 'REAL*4'
			DATACOMM = 'FLOATING POINT'
                        if !VERSION.ARCH eq "vax" then message, $
                          'Sorry, too stupid to byte swap REAL*4 data on a VAX'
		    END
	        3:  BEGIN		  ;Longword
			BITPIX = 32
			BITCOMM = '4-BYTE TWOS-COMPL INTEGER'
			DATATYPE = 'INTEGER*4'
			DATACOMM = 'LONG INTEGER'
		    END
  	        5:  BEGIN		  ;Double precision
			BITPIX = -64
			BITCOMM = '8-BYTE FLOATING POINT'
			DATATYPE = 'REAL*8'
			DATACOMM = 'DOUBLE PRECISION FLOATING'
                        if !VERSION.ARCH eq "vax" then message, $
                          'Sorry, too stupid to byte swap REAL*8 data on a VAX'
		    END
	ENDCASE
;
	NP = N_PARAMS(0)		;# OF PARAMETERS WE HAVE
	IF NP LT 3 THEN HEADER = STRARR(36)
;
	NL = N_ELEMENTS(HEADER)
	IF ((NL - NL/36*36) EQ 0) THEN BEGIN
		NR = NL / 36
	ENDIF ELSE BEGIN
	 	NR = NL / 36 + 1
	ENDELSE
;
	H = STRARR(NR*36)
	FOR I=0,(NL-1) DO BEGIN
		H(I) = STRING(HEADER(I),'(A)')
	ENDFOR
;
	IF NP LT 3 THEN BEGIN
	  	NAXISCOMM = 'NUMBER OF AXES'
;         
		SXADDPAR,H,'SIMPLE','T','STANDARD FITS FORMAT'
		SXADDPAR,H,'BITPIX  ',BITPIX,BITCOMM
		SXADDPAR,H,'NAXIS   ',NAXIS,NAXISCOMM 
		FOR W = 1,NAXIS DO $
			SXADDPAR,H,'NAXIS' + STRTRIM(W,2),NAX(W-1)
		SXADDPAR,H,'DATATYPE',DATATYPE,DATACOMM
  	ENDIF ELSE BEGIN
	  SXADDPAR,H,'DATATYPE',DATATYPE,DATACOMM
	  SXADDPAR,H,'BITPIX',BITPIX,BITCOMM
	  NXS = SXPAR(H,'NAXIS')
	  NX = INTARR(NXS)
	  NPNTS = 1.0
	  FOR P = 1,NXS DO BEGIN
		NX(P-1) = SXPAR(H,'NAXIS' + STRTRIM(P,2))
	  	NPNTS = NPNTS*NX(P-1)
	  ENDFOR
	  IF NPNTS NE LIM THEN MESSAGE,'Size of array and header do not match' 
	ENDELSE
; 
; Get UNIT number
;
	GET_LUN,UNIT
;
; Open file and write header information
;
  	OPENW,UNIT,FILENAME,2880
	FILE = ASSOC(UNIT,BYTARR(80,36))
;
	FOR R = 0,(NR-1) DO BEGIN
	DUM = REPLICATE(BYTE(32),80,36)
	FOR L = 0,35 DO BEGIN
		DUM(0,L) = BYTE(H(L+R*36))
	ENDFOR
	IF MAX(WHERE(DUM EQ 0B)) GE 0 THEN DUM(WHERE(DUM EQ 0B)) = 32B
	FILE(R) = DUM
	ENDFOR
;
; Write data
;
	R = NR
	NBYTES = ABS(BITPIX) / 8       
	NPIX = 2880 / NBYTES	;Pixels per record
	POS = LONG(0)
	;
	WHILE (POS LE (N_ELEMENTS(DATA)-NPIX)) DO BEGIN
 	   FILE = ASSOC(UNIT,BYTARR(2880))
;
	   CASE TYPE OF
		7:	LINE = BYTE(DATA,POS,2880)	;String
		1:	LINE = BYTE(DATA,POS,2880)	;Byte
		2:	LINE = BYTE(DATA,POS*2,2880)	;Integer
		4:	LINE = BYTE(DATA,POS*4,2880)	;Floating point
	        3:	LINE = BYTE(DATA,POS*4,2880)	;Longword
	        5:	LINE = BYTE(DATA,POS*8,2880)	;Double precision
	   ENDCASE		
	   FILE(R) = LINE
	   R = R + 1       
	   POS = POS + NPIX
	ENDWHILE
;
; Take care of last line
;
      	NBYTES2 = (N_ELEMENTS(DATA) MOD NPIX) * NBYTES
;
	IF NBYTES2 GT 0 THEN BEGIN
 	   FILE = ASSOC(UNIT,BYTARR(2880))
	   CASE TYPE OF
		7:	LINE = BYTE(DATA,POS,NBYTES2)
		1:	LINE = BYTE(DATA,POS,NBYTES2)
		2:	LINE = BYTE(DATA,POS*2,NBYTES2)
		4:	LINE = BYTE(DATA,POS*4,NBYTES2)
	        3:	LINE = BYTE(DATA,POS*4,NBYTES2)
	        5:	LINE = BYTE(DATA,POS*8,NBYTES2)
	   ENDCASE
	   FILL=BYTARR(2880-NBYTES2)
	   FILE(R) = [LINE,FILL]
	ENDIF	
;
	FREE_LUN,UNIT
;
; Byte-swap the data back to its original form.
;
	fitsbyte, data, /host
	return
END
