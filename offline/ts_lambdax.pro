pro ts_lambdax,subdir,flist,jd,jord,xx,lammed,lamdif
; This routine reads the THAR files in the ascii input file flist. 
; For each, it opens and reads the original input file, (found in
; $NRESRAWDAT/subdir/ORIG, where ORIG is found in the header of flist(i)
; and obtains from it
; the exposure start JD;  the list of JDs is returned in jd(nt)
; It then extracts wavelengths from a subset of {order, xpix} pairs for 
; fiber 1, as follows:
;   order = {20,38,58} {0 <= x <= 4095}
;   {0 <= order <= 66} x = {400,2000,2048,3600}
; order numbers and x-coords are returned in jord(npair),xx(npair)
; For each {order,x} pair, it then computes the median (over time) wavelength 
; and returns these in lammed{npair}.
; differences between individual differences between the median and 
; instantaneous wavelength are returned in lamdif(nt,npair).

; constants
path=getenv('NRESRAWDAT')
leaf=path+'/'+subdir+'/'         ; full path to raw data

; get list of files to process
ss=''
files=['']
openr,iun,flist,/get_lun
while(not eof(iun)) do begin
  readf,iun,ss
  files=[files,strtrim(ss,2)]
endwhile
files=files[1:*]
nt=n_elements(files)
close,iun
free_lun,iun

; make the jord, xx arrays
npair=0
nord=67
nx=4096
jord=[0L]
xx=[0L]

jord=[jord,lonarr(nx)+20]
xx=[xx,lindgen(nx)]
npair=npair+nx
jord=[jord,lonarr(nx)+38]
xx=[xx,lindgen(nx)]
npair=npair+nx
jord=[jord,lonarr(nx)+58]
xx=[xx,lindgen(nx)]
npair=npair+nx

jord=[jord,lindgen(nord)]
xx=[xx,lonarr(nord)+400]
npair=npair+nord
jord=[jord,lindgen(nord)]
xx=[xx,lonarr(nord)+2000]
npair=npair+nord
jord=[jord,lindgen(nord)]
xx=[xx,lonarr(nord)+2048]
npair=npair+nord
jord=[jord,lindgen(nord)]
xx=[xx,lonarr(nord)+3600]
npair=npair+nord

tt=dblarr(nt)
jord=jord(1:*)
xx=xx(1:*)

; make output files
lamall=dblarr(nt,npair)
lammed=dblarr(npair)
lamdif=dblarr(nt,npair)

; loop over the input files
for i=0,nt-1 do begin
  thar=readfits(files(i),hdr,/silent)
  thars=thar(*,*,1)                  ; take only fiber 1 wavelengths
  orig=sxpar(hdr,'ORIGNAME')
  origfile=leaf+strtrim(orig,2)
  dat=readfits(origfile,hdro,/silent)
  tt(i)=sxpar(hdro,'MJD-OBS')
    
; get the data
  s=xx+nx*jord
  lamall(i,*)=thars(s)
endfor

; make and subtract the median over time
lammed=median(lamall,dim=1)
lamdif=lamall-rebin(reform(lammed,1,npair),nt,npair)

stop

end
