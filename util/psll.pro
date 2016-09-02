pro psll,name=name,xs=xs,ys=ys,encap=encap
	if(keyword_set(name)) then name=name else name='idl.ps'
	if(keyword_set(xs)) then xs=xs else xs=25
	if(keyword_set(ys)) then ys=ys else ys=18
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=ys,xsize=xs,/landscape,$
          xoff=0, yoff=25.5, filename=name,/color,encap=encap
end
