pro epsp,name=name
	set_plot,'ps'
	!p.font=0
	device,/times,/encapsul,bits_per_pixel=8,ysize=20,xsize=24,$
	   /portrait,xoff=2.5,yoff=3.5,file=name,/color
end
