pro ccd_find,err
; Reads the contents of NRES file standards.csv yielding the column
; vector values.
; It then searches for the CCD named camera, and if found, returns
; its data in the common structure ccd, with err=0.
; If the desired camera is not found, returns err=1 and a structure of nulls.

@nres_comm

nresroot=getenv('NRESROOT')
ccdfile=nresroot+'reduced/csv/ccds.csv'
datc=read_csv(ccdfile,header=stdhdr)
cameras=datc.field1
nxc=datc.field2
nyc=datc.field3
datsegmins=datc.field4
datsegmaxs=datc.field5
gains=datc.field6
rdnoiss=datc.field7
pixsizs=datc.field8

s=where(strtrim(camera,2) eq strtrim(cameras,2),ns)
if(ns eq 1) then begin
  cameras=cameras(s)
  nxc=nxc(s)
  nyc=nyc(s)
  datsegmins=datsegmins(s)
  datsegmaxs=datsegmaxs(s)
  gains=gains(s)
  rdnoiss=rdnoiss(s)
  pixsizs=pixsizs(s)
  ccd={camera:cameras(0),nx:nxc(0),ny:nyc(0),datsegmin:datsegmins(0),$
       datsegmax:datsegmaxs(0),gain:gains(0),rdnois:rdnoiss(0),$
       pixsiz:pixsizs(0)}
  err=0
endif else begin
  ccd={camera:'NULL',nx:0,ny:0,datsegmin:0,datsegmax:0,gain:0.,rdnois:0.,$
       pixsiz:0.}
  err=1
endelse

end
