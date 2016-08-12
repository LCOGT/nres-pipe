pro psl,name=name
	if(keyword_set(name)) then name=name else name='idl.ps'
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=15,xsize=20,/landscape,xoff=1,$
	  /color,filename=name,/encapsul
end
