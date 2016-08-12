pro ps,name=name,encap=encap
	set_plot,'ps'
	!p.font=0
	if(keyword_set(name)) then name=name else name='idl.eps'
	device,/times,bits_per_pixel=8,ysize=25,xsize=18,/portrait,yoff=2,$
	  file=name,encap=encap,/color
end
