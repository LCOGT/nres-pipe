pro pscorot,name=name
;  Simulates Artie Hatzes' plots
	if(keyword_set(name)) then name=name else name='idl.ps'
	set_plot,'ps'
	!p.font=0
	device,/times,bits_per_pixel=8,ysize=10.4,xsize=16.4,/portrait,xoff=1,$
	  filename=name
end
