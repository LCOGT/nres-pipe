function allstats,dat,stats
; This routine computes the minimum,mean,median,maximum,standard deviation
; of the array dat, and returns results in the vector
; stats=[min,mean,median,max,stddev]

image_statistics,dat,min=mn,mean=men,max=mx,stddev=std
med=median(dat)
stats=[mn,men,med,mx,std]
return,stats

end
