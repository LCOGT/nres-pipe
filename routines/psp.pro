pro psp,name=name,xs=xs,ys=ys,encap=encap
	if(keyword_set(name)) then name=name else name='idl.ps'
	if(keyword_set(xs)) then xs=xs else xs=18
	if(keyword_set(ys)) then ys=ys else ys=25
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=ys,xsize=xs,/portrait,xoff=0,$
	  yoff=2,filename=name,/color,encap=encap
end
