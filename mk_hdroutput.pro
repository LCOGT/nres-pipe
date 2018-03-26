pro mk_hdroutput,hblaz,hthar,hrad0,hrad1,hrad2,hdrstruc
; This routine concatenates the fits headers hblaz, hthar, hrad0, hrad1,
; hrad2  into one
; long string array.  It then successively opens each of the config
; files $NRESROOT + $NRESINST + reduced/config/hdrn.txt files, which
; contain ordered lists of the desired keywords for each of the output
; header files corresponding to the output header structure tags
; {extr, spec, blaz, thar_i, thar_f, wavspec, wavthar,....}.  These 
; header files are built and returned in hdrstruc.

; constants
nresroot=getenv('NRESROOT')
nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
confpath=nresrooti+'reduced/config/'
hdr0path=confpath+'hdr0.txt'
hdr1path=confpath+'hdr1.txt'
hdr2path=confpath+'hdr2.txt'
hdr3path=confpath+'hdr3.txt'
hdr4path=confpath+'hdr4.txt'
hdr5path=confpath+'hdr5.txt'
hdr6path=confpath+'hdr6.txt'
hdr7path=confpath+'hdr7.txt'
hdr8path=confpath+'hdr8.txt'
hdr9path=confpath+'hdr9.txt'
paths=[hdr0path,hdr1path,hdr2path,hdr3path,hdr4path,hdr5path,hdr6path,$
       hdr7path,hdr8path,hdr9path]

; make concatenated input header array
hall=[hblaz,hthar,hrad0,hrad1,hrad2]
; select only keywords, strip out blanks
halls=strtrim(strmid(hall,0,8),2)

; loop over the headers to be constructed
nhdrout=10
ss=''
for i=0,nhdrout-1 do begin
  hh=[]                      ; empty header string array
  openr,iun,paths[i],/get_lun
  readf,iun,ss               ; header line in config file
  while(not eof(iun)) do begin
    readf,iun,ss
    words=get_words(ss,nw)

; get nominal comment, if any
    icomm=strpos(ss,'/')
    if(icomm gt 0) then begin
      sslen=strlen(ss)
      nomcomm=strmid(ss,icomm,sslen-icomm+1)
    endif else begin
      nomcomm=['']
    endelse

; each line is {keyword, [instance], [comment]}.  If instance is absent,
;  it defaults to zero
    keywd=strtrim(words(0),2)
    if(nw ge 2) then inst=fix(words(1)) else inst=0

; find all instances of this keyword, select the inst-th.
    s=where(halls eq keywd,ns)
    if(ns ge (inst+1)) then begin
      hcurr=hall[s[inst]]
      jcomm=strpos(hcurr,'/')   ; if not -1, there may be comment in line
      hclen=strlen(strtrim(hcurr,2)) ; line length, ignoring trailing blanks
      comlen=hclen-jcomm-1
      if(comlen le 0 and nomcomm ne '') then begin
        hcbot=strmid(hcurr,0,jcomm)
        hcurr=hcbot+nomcomm 
      endif
      hh=[hh,hcurr]
    endif else begin
      print,'ERROR keyword '+keywd+' not found, header'+string(i)
      if(strpos(keywd,'RADESYS') ge 0) then stop
    endelse
  endwhile

  close,iun
  free_lun,iun

  if(n_elements(hh) eq 0) then hh=['BLANK']

  case i of
    0: hdr0=hh
    1: hdr1=hh
    2: hdr2=hh
    3: hdr3=hh
    4: hdr4=hh
    5: hdr5=hh
    6: hdr6=hh
    7: hdr7=hh
    8: hdr8=hh
    9: hdr9=hh
    else: print,'Too Many Output Headers'
  endcase

endfor

hdrstruc0={keyall:hdr0,extr:hdr1,spec:hdr2,blaz:hdr3,wavespec:hdr4,$
   thar_i:hdr4,thar_f:hdr6,wavethar:hdr7,xcor:hdr8,wblocks:hdr9}

; delete some keywords that we may want to revive later, and rename
; some others.  This routine does so in an ad-hoc, hardwired way
hdr_revise,hdrstruc0,hdrstruc

end
