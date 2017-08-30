pro fpack_stacked_calibration,input_path, output_filename
  ; This routine causes a compressed fits to be written into the
  ; reduced/tar directory, containing the
  ; file contained in /reduced/tar pointed to by filepath.
  ; This facility is intended to be used by
  ; routines that make composite calibration files.
  ; Procedure is to write filepath into /reduced/tar, make a gzipped tar file
  ; of it in the same directory, append the name of the tarfile to beammeup.txt,
  ; and delete the /reduced/tar version of the original datafile.

  nresroot=getenv('NRESROOT')
  nresrooti=nresroot+strtrim(getenv('NRESINST'),2)
  tarpath=nresrooti+'reduced/tar/'
  fits_read, input_path, data, header
  ; make the name of the copy, copy filepath into it
  ; also make the name of the tarfile
  ix=strpos(filepath,'/',/reverse_search)
  nc=strlen(filepath)
  copyname=output_filename + '.fits'
  cmd0='cp '+input_path+' '+tarpath+'/'+copyname
  spawn,cmd0

  ; obtain current directory
  cmd1='pwd'
  spawn,cmd1,startdir

  ; cd to reduced/tar
  cd,tarpath

  ; write the tarfile
  cmd2='fpack -q 64 ' + copyname
  spawn,cmd2

  ; write the tarfile name into beammeup.txt
  openw,iun,tarpath+'/beammeup.txt',/get_lun,/append
  printf,iun,tarpath+strtrim(copyname,2)+'.fz ' + sxpar(header, 'DAY-OBS') 
  close,iun
  free_lun,iun

  ; delete copy, return to original cwd
  cmd3='rm '+copyname
  spawn,cmd3
  cd,startdir

end
