pro pss
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=10,xsize=15,/portrait,yoff=3,$
	/color
end
