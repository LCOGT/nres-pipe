pro lepsp,xs=xs,ys=ys,name=name
	if(keyword_set(xs)) then xsize=xs else xsize=20
	if(keyword_set(ys)) then ysize=ys else ysize=16
	if(keyword_set(name)) then name=name else name='idl.eps'
	set_plot,'ps'
	!p.font=0
	device,/times,/encapsul,bits_per_pixel=8,ysize=ysize,xsize=xsize,$
	   /color,/portrait,file=name
end
