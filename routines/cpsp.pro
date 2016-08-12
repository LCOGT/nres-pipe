pro cpsp,name=name,xs=xs,ys=ys
	if(keyword_set(name)) then fname=name else fname='idl.ps'
	if(keyword_set(xs)) then xsiz=xs else xsiz=18.
	if(keyword_set(ys)) then ysiz=ys else ysix=18.
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=ysiz,xsize=xsiz,/portrait,xoff=1,$
	yoff=1,/color,file=fname
end
