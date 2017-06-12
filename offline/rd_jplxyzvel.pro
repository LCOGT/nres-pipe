pro rd_jplxyzvel,filin,tt,vx,vy,vz
; This routine reads the csv file filin, containing JPL Horizons X,Y,Z
; velocity components (km/s) vs JD.  Results are returned in the vectors
; tt, vx, vy, vz.

dat=read_csv(filin,header=hdr)
tt=dat.field1
vx=dat.field3
vy=dat.field4
vz=dat.field5

end
