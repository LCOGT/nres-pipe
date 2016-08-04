pro ts_anal0,listin,cfts,parm4,cfavg,parmavg,rmsall,w,u,v
; This routine reads time series of the rcubic coefficients cfts(15,nt)
; and the 4 physical parameters parm4(4,nt), and returns
; cfavg(15) = median of cfts values
; parmavg(4) = median of parm4 values
; rmsall(19) = rms of each coeff and parameter, ordered [parm4,cfts]
; w,u,v = results of SVD on array resid(19,nt), which is the median-subtracted
;         time series for each parameter or coefficient, normalized by the
;         standard deviation of that matrix column.

rd_coefts,listin,cfts,parm4
cfavg=median(cfts,dim=2)
parmavg=median(parm4,dim=2)
sz=size(parm4)
nt=sz(2)

datall=dblarr(19,nt)
datall(0:3,*)=parm4
datall(4:18,*)=cfts
datavg=median(datall,dim=2)
datavg=rebin(datavg,19,nt)
resid=datall-datavg

stdv=stddev(resid,dim=2)
stdv=rebin(stdv,19,nt)
rat=resid/stdv

svdc,rat,w,u,v

stop

end
