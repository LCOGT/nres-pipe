pro psm
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=22,xsize=16,/portrait,yoff=2,$
	   /encaps
end
