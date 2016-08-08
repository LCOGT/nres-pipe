pro rd_assem_temp,ifil,jd,tamb,tbase,tcoll,tair,tambn
; Reads Rob's assembly_area_temperature files and returns vectors for
; ambient, base, collimator, chamber air temperature
; ifil=0 means old data (with inlet temperature)
; ifil=1 means new data (with new ambient temperature probe)

files=['/scratch/rsiverd/environment/20160802--assembly_area_temperature.log',$
'/scratch/rsiverd/environment/20160803--assembly_area_temperature.log.oops',$
'/scratch/rsiverd/environment/assembly_area_temperature.log']


openr,iun,files(ifil),/get_lun
ss=''
nline=0L
while(not eof(iun)) do begin
  readf,iun,ss
  nline=nline+1L
endwhile

jd=dblarr(nline)
tamb=dblarr(nline)
tbase=dblarr(nline)
tcoll=dblarr(nline)
tair=dblarr(nline)
tambn=dblarr(nline)

v0=0.d0
v1=0.d0
v2=0.d0
v3=0.d0
v4=0.d0
v5=0.d0

point_lun,iun,0
for i=0L,nline-1 do begin
  if(ifil eq 0) then begin
    readf,iun,v0,v1,v2,v3,v4
  endif else begin
    readf,iun,v0,v1,v2,v3,v4,v5
  endelse
  jd(i)=v0
  tamb(i)=v1
  tair(i)=v2
  tbase(i)=v3
  tcoll(i)=v4
  if(ifil eq 0) then begin
    tambn(i)=tamb(i)
  endif else begin
    tambn(i)=v5
  endelse
endfor

close,iun
free_lun,iun

end
