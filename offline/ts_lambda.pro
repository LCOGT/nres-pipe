pro ts_lambda,flist,tt,wav
; This routine reads a list of nt THAR files, reads the corresponding files
; in $NRESROOT/RDlsc1/reduced/thar, and returns
; a time series of wavelength solutions
; wav(nx,nord,3,nt)
; with corresponding timestamps tt(nt)

; constants
nresroot=getenv('NRESROOT')
nresinst=getenv('NRESINST')
nresrooti=nresroot+nresinst
tharroot=nresrooti+'reduced/thar/'

; read flist
openr,iun,flist,/get_lun
ss=''
files=[]
while(not eof(iun)) do begin
  readf,iun,ss
  files=[files,strtrim(ss,2)]
endwhile
nt=n_elements(files)
close,iun
free_lun,iun

; make output file, get sizes of things
tt=dblarr(nt)
infil=tharroot+'/'+files(0)
dd=readfits(infil,hdr)
sz=size(dd)
nx=sz(1)
nord=sz(2)
nfib=sz(3)
wav=dblarr(nx,nord,nfib,nt)

; read in the wavelength data
for i=0,nt-1 do begin
  dd=readfits(files(i),hdr)
  tt(i)=sxpar(hdr,'MJD-OBS')
  wav(*,*,*,i)=dd
endfor

end
