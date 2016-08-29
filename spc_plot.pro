PRO spc_plot, objectName, obsCode, hjd, objHeader, k, ap, best_index, Teff, logg, mh, vsini, peak, best_dv, bc_bary, wl, wl_i, $
							best_ct_fft, SNRresele, _spectrum_org, continuum, blazefit, $
							con_xstart, con_xend, bestTemplate, bestTemplate_org, spec_Ipl, $
							best_ccf, best_xshift, CRVAL1, CDELT1, nPadPixels, $
							best_index_norot, best_xshift_norot, best_ct_fft_norot, best_dv_norot, best_ccf_norot, peak_norot, $
							orders=orders, SPCversion=SPCversion, smoothPlot=smoothPlot, chi2=chi2, plotDetailsOff=plotDetailsOff, plotContinuumFitOff=plotContinuumFitOff, spectrograph = spectrograph, $
							removeCosmicRays = removeCosmicRays, cosmicRaySigmaCut=cosmicRaySigmaCut, noNonRotPlot = noNonRotPlot, plotPublish=plotPublish, $
							continuumSubs=continuumSubs, knotsPlaced=knotsPlaced, charsize=charsize, thick=thick, symsize=symsize
	;Speed of light
	c = 299792458d
	
	csmXYout = 0.85
	csmMulti = 0.90
	
	spectrum_org = _spectrum_org

;	if(not KEYWORD_SET(noNonRotPlot)) then begin
;		thick = 1.5
;	endif else begin
;		thick = 2.5
;	endelse
;
;	if(KEYWORD_SET(plotPublish)) then begin
;		thick = 2.5
;	endif

	;Make a blue circle as the user symbol
	if(repack_checkGDL() eq 0) then begin
		USERSYM, COS(FINDGEN(17) * (!PI*2/16.))/2., SIN(FINDGEN(17) * (!PI*2/16.))/2., /FILL, color=djs_icolor("blue")
	endif else begin
		;Increase thick for GDL
		thick = 3
	endelse
	
	bi = best_index[k]
	
	spc_create_titlestr, titleStr, titleStrShort, objectName, obsCode, hjd, Teff[bi, k], logg[bi, k], mh[bi, k], vsini[bi, k], $
				ap, peak[k], best_dv[k], bc_bary[0], SNRresele[k], objHeader=objHeader, SPCversion=SPCversion
			

	n_axis1 = N_ELEMENTS(spectrum_org[*,0])
	n_orders = N_ELEMENTS(spectrum_org[0,*])
	if(KEYWORD_SET(removeCosmicRays)) then begin
		;Fit the continuum
		specContFit_sigmah = 1.0
		specContFit_sigmal = 0.3
		skipplot = 1
		percentToContinuumFit = 0
			
		continuum_org = dblarr(n_axis1, n_orders)
		
		for ap2 = 0, n_orders-1 do begin		
			repack_cc_fitcontinuum, wl, spectrum_org, ap2, k, continuum_org, con_xstart, con_xend, percentToContinuumFit, $
				3, 600, specContFit_sigmal, specContFit_sigmah, skipplot, $
				/splineFit, interact=interact
		
			repack_removeCosmicRay_Spectrum, wl, spectrum_org, ap2, k, continuum_org, con_xstart, con_xend, percentToContinuumFit, $
							3, 600, specContFit_sigmal, specContFit_sigmah, skipplot, $
							/splineFit, interact=interact, cosmicRaySigmaCut=cosmicRaySigmaCut, /silent
		endfor
	endif	
				
	if(KEYWORD_SET(chi2)) then begin
		print, 'Best fit chi2: ' + titleStr
		titleStr += ', chi2 fit'
	endif else begin
		print, 'Best fit: ' + titleStr
	endelse
	
	;Fit plot
	!p.multi=[0,1,2]

;specTmp= _spectrum_org(*, ap)/blazefit[*,ap]
;spectmp2 = (spectmp - continuum[*,k])/continuum[*,k] * total(continuum[*,k])/n_axis1
;specTmpInt = interpol(spectmp2, wl[*,ap], wl_i[0:5589,k]);, /spline)
;specShift = shift(specTmpInt, best_ct_fft[k])
;specShiftBw = specShift*blaze_ipl

	specShift = shift(spec_Ipl(*, k), best_ct_fft[k])
	if(KEYWORD_SET(smoothPlot)) then begin
		specShift = MEDIAN(specShift, N_ELEMENTS(specShift) / 600, /double)
	endif 
	;templateNorm =  bestTemplate[*,k]/total(bestTemplate[*,k]) * total(specShift)
	;templateNorm =  bestTemplate[*,k]/mean(bestTemplate[*,k]) * median(specShift)	
	
	;templateNorm = bestTemplate[*,k] / sqrt(total( (bestTemplate[*,k] - mean(bestTemplate[*,k], /double))^2 ))
	;specShift = specShift / sqrt(total( (specShift - mean(specShift, /double))^2 ))

	n_axis_t = N_ELEMENTS(specShift)
	n_axis_t_s = n_axis_t - npadpixels
	
	specShift = specShift[0:n_axis_t_s] ;- specShift[n_axis_t-1] + 1
	specShift = specShift / abs(total(specShift,/double)) * n_axis_t_s

	templateNorm = bestTemplate[0:n_axis_t_s,k] ;- bestTemplate[n_axis_t-1, k]
	;templateNorm = templateNorm / abs(total(templateNorm,/double)) * n_axis_t_s


;	;Fit a normalization factor for the template
;	sortsubs = sort(specShift)
;	specShift_lines = specShift[sortsubs[0:n_elements(sortsubs)*0.2]]
;	templatenorm_lines = templatenorm[sortsubs[0:n_elements(sortsubs)*0.2]]
;	p0 = [total(specShift)/total(templatenorm), 0d]
;	funcargs = {data1:specShift_lines, data2:templatenorm_lines}
;	params_out = MPFIT('fkt_normalization_fac3', p0, FUNCTARGS=funcargs, /QUIET)
;	normFac = params_out[0]
;	templateNorm = templateNorm * normFac + params_out[1]
;	xrange = [ 10^wl_i[0,k], 10^wl_i[N_ELEMENTS(wl_i[*,k])-nPadPixels,k] ]
	
	;Fit a normalization factor for the template
	p0 = [total(specShift)/total(templatenorm), 0d]
	dpix = 50
	xns = 0 + dpix
	xne = N_ELEMENTS(specShift) - 1 - dpix
	funcargs = {data1:specShift[xns:xne], data2:templateNorm[xns:xne]}
	params_out = MPFIT('fkt_normalization_fac3', p0, FUNCTARGS=funcargs, /QUIET)
	normFac = params_out[0]
	templateNorm = templateNorm * normFac + params_out[1]
	xrange = [ 10^wl_i[0,k], 10^wl_i[N_ELEMENTS(wl_i[*,k])-nPadPixels,k] ]
	
	miny = min([templateNorm, specShift])*1.2
	maxy = max([templateNorm, specShift])*1.2
	minx = min(10^wl_i[*,k])
	maxx = max(10^wl_i[*,k])

	neleplot = n_axis1
	nsum = fix(N_ELEMENTS(templatenorm) / neleplot)
	
	;set_plot,'win'
	plot, 10^wl_i[*,k], templateNorm, title = titleStrShort, xtitle='Wavelength (Angstrom)', ytitle='Relative intensity', $
		xstyle=1, ystyle=1, background=djs_icolor("white"), color=djs_icolor("black"), yrange=[miny, maxy], xrange=xrange, charsize=charsize*csmMulti, thick=thick, xthick=thick, $
		ythick=thick, /nodata;, nsum=nsum
	oplot, 10^wl_i[*,k], specShift, color=djs_icolor("blue"), thick=thick;, nsum=nsum
	oplot, 10^wl_i[*,k], templateNorm, color=djs_icolor("red"), thick=thick;, nsum=nsum


	xyouts, 0.9, 0.63, /normal, String(format='(%"Teff = %4i K")', Teff[bi, k]), color=djs_icolor("black"), charsize=charsize*csmXYout
	xyouts, 0.9, 0.61, /normal, String(format='(%"Log g = %3.1f")', logg[bi, k]), color=djs_icolor("black"), charsize=charsize*csmXYout
	xyouts, 0.9, 0.59, /normal, String(format='(%"[m/H] = %4.1f")', mh[bi, k]), color=djs_icolor("black"), charsize=charsize*csmXYout
	xyouts, 0.9, 0.57, /normal, String(format='(%"Vrot = %i km/s")', vsini[bi, k]), color=djs_icolor("black"), charsize=charsize*csmXYout

	RA = sxpar(objHeader,'RA', COMMENT=racom)
	DEC = sxpar(objHeader,'DEC', COMMENT=deccom)
	if(spectrograph eq 'fies') then begin
		st = strpos(racom, '(') + 1
		len = strpos(racom, 's)') - st + 1
		RA = strmid(racom, st, len)
		st = strpos(deccom, '(') + 1
		len = strpos(deccom, 's)') - st + 1
		DEC = strmid(deccom, st, len)
	endif
	
	xpos = 0.08
	ypos = 0.63
	xyouts, xpos, ypos, /normal, String(format='(%"RA   = %s")', RA), color=djs_icolor("black"), charsize=charsize*csmXYout
	ypos -= 0.02
	xyouts, xpos, ypos, /normal, String(format='(%"DEC = %s")', DEC), color=djs_icolor("black"), charsize=charsize*csmXYout
	
	WS_ORG_N = sxpar(objHeader,'WS_ORG_N', COUNT=match)
	if(match ne 0) then begin
		ypos -= 0.02
		xyouts, xpos, ypos, /normal, String(format='(%"N_COMB = %i")', WS_ORG_N), color=djs_icolor("black"), charsize=charsize*csmXYout
	endif
	PROGRAM = sxpar(objHeader,'PROGRAM', COUNT=match)
	if(match ne 0) then begin
		ypos -= 0.02
		xyouts, xpos, ypos, /normal, String(format='(%"Program = %s")', PROGRAM), color=djs_icolor("black"), charsize=charsize*csmXYout
	endif
	

	;Crosscorrelation plot
	if(KEYWORD_SET(noNonRotPlot)) then begin
		!p.multi=[2,2,2]
		charsizeMultiplyer = 1.2
	endif else begin
		!p.multi=[3,3,2]
		charsizeMultiplyer = 1.7
	endelse
	
	neleplot = n_axis1
	nsum = fix(n_elements(best_ccf[*,k]) / neleplot)

	x_ele = findgen(n_elements(best_ccf[*,k])) - double(best_xshift[k])
	v_ele = c * (10^(-x_ele * CDELT1) - 1d)	/ 1000d + bc_bary[0]
	plot, v_ele, best_ccf[*,k], xtitle='Shift (km/s)', ytitle='', title='Rotating template correlation', $
			background=djs_icolor("white"), color=djs_icolor("black"), yrange=[-0.2,1], xstyle=1, xrange=[-400,400], charsize=charsize*charsizeMultiplyer, $
			thick=thick, xthick=thick, ythick=thick, xmargin=[10,3], nsum=nsum
	oplot, [0,0], [-1,1], color=djs_icolor("blue"), thick=thick
	oplot, [best_dv[k],best_dv[k]], [-1,1], color=djs_icolor("green"), thick=thick

	line = -findgen(10)*0.06 + 0.90
	xpos = 50
	xyouts, xpos, line[0], String(format='(%"RV   = %9.3f km/s")', best_dv[k]), color=djs_icolor("black"), charsize=charsize*csmXYout
	xyouts, xpos, line[1], String(format='(%"BC   = %9.3f km/s")', bc_bary[0]), color=djs_icolor("black"), charsize=charsize*csmXYout
	xyouts, xpos, line[2], String(format='(%"Peak = %5.3f")', peak[k]), color=djs_icolor("black"), charsize=charsize*csmXYout


	if(not KEYWORD_SET(noNonRotPlot)) then begin
		;Crosscorrelation plot non-rotating template
		!p.multi=[2,3,2]
		x_ele = findgen(n_elements(best_ccf[*,k])) - double(best_xshift[k])
		v_ele = c * (10^(-x_ele * CDELT1) - 1d)	/ 1000d + bc_bary[0]
		plot, v_ele, best_ccf_norot[*,k], xtitle='Shift (km/s)', ytitle='', title='Non-rotating template correlation', $
				background=djs_icolor("white"), color=djs_icolor("black"), yrange=[-0.2,1], xstyle=1, xrange=[-400,400], charsize=charsize*charsizeMultiplyer, $
				thick=thick, xthick=thick, ythick=thick, xmargin=[6,7], nsum=nsum
		oplot, [0,0], [-1,1], color=djs_icolor("blue"), thick=thick
		oplot, [best_dv_norot[k],best_dv_norot[k]], [-1,1], color=djs_icolor("green"), thick=thick
	
		line = -findgen(10)*0.06 + 0.90
		xyouts, xpos, line[0], String(format='(%"RV   = %9.3f km/s")', best_dv_norot[k]), color=djs_icolor("black"), charsize=charsize*csmXYout
		xyouts, xpos, line[1], String(format='(%"BC   = %9.3f km/s")', bc_bary[0]), color=djs_icolor("black"), charsize=charsize*csmXYout
		xyouts, xpos, line[2], String(format='(%"Peak = %5.3f")',  peak_norot[k]), color=djs_icolor("black"), charsize=charsize*csmXYout
	endif

	;Plot original spectrum
	if(not KEYWORD_SET(noNonRotPlot)) then begin
		!p.multi=[1,3,2]
	endif else begin
		!p.multi=[1,2,2]
	endelse
	
	if(KEYWORD_SET(smoothPlot)) then begin
		spectrum_org(*,ap) = MEDIAN(spectrum_org(*,ap), N_ELEMENTS(spectrum_org(*,ap)) / 600, /double)
	endif 
	
;	miny = min(spectrum_org(con_xstart[k]:con_xend[k],ap))*0.80
;	maxy = max(spectrum_org(con_xstart[k]:con_xend[k],ap))*1.15
	;miny = min(spectrum_org[*,ap])*0.80
	neleplot = n_axis1/2d
	nsum = fix(n_elements(spectrum_org[*,ap]) / neleplot)

	maxy = max(spectrum_org[*,ap])*1.10
	if(repack_checkGDL() eq 0) then ystyle = 8+1 else ystyle = 1
	plot, 10^wl[*,ap], spectrum_org[*,ap], xtitle='Wavelength (Angstrom)', ytitle='ADU', title='Spectrum', $
		xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*charsizeMultiplyer, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
		thick=thick, xthick=thick, ythick=thick, xmargin=[5,8];, nsum=nsum
	if(not KEYWORD_SET(blazefit)) then $
		oplot, 10^wl[*,ap], continuum[*,k], color=djs_icolor("red"), nsum=nsum*4
	
	;Plot chunks of spectrum, without drawing a line to new part
	
;	ccsubs = where(continuumSubs[*,k] ne -1)
;	if(ccsubs[0] ne -1) then $
;		repack_oplot_chunks, 10^wl[*,ap], spectrum_org[*,ap], continuumSubs[ccsubs, k], continuum=continuum[*,k], knotsPlaced=knotsPlaced[*,k]
;
	;gain = repack_spec_getGainFactor(spectrograph)
	repack_spec_getRON_gain, objHeader, readoutnoise, gain, spectrograph=spectrograph
	if(repack_checkGDL() eq 0) then $
		axis, yaxis=1, charsize=charsize*charsizeMultiplyer, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
	
	;oplot, 10^wl(con_xstart[k]:con_xend[k],ap), continuum(con_xstart[k]:con_xend[k],k), color=djs_icolor("blue")
	
	if(not KEYWORD_SET(plotDetailsOff) and not KEYWORD_SET(plotPublish)) then begin
		erase
		!p.multi=[0,2,2]
		
		dvNoCorr = best_dv[k] - bc_bary[0]
		
		xmargin=[10,10]
		if(repack_checkGDL() eq 0) then ystyle=8 else ystyle=1
	

		!p.multi=[0,2,2]
	
		neleplot = n_axis1/2d
		nsum = fix(n_elements(spectrum_org[*,ap]) / neleplot)
		
		;CaII H
		wlFeature = 3968.5d
		;Move it
		wlFeature += dvNoCorr/c * wlFeature		
		repack_findApWithFeat, 10^wl, wlFeature, apPlot, spectrograph
		titleStr = 'CaII H 3968.5 ang'
		;Plot continuum fit
		miny = min(spectrum_org[*,apPlot])*0.80
		maxy = max(spectrum_org[*,apPlot])*1.10
		plot, 10^wl(*,apPlot), spectrum_org(*,apPlot), xtitle='Wavelength (Angstrom)', ytitle='ADU', title=titleStr, $
			xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
			thick=thick, xthick=thick, ythick=thick, xmargin=xmargin;, nsum=nsum
		if(repack_checkGDL() eq 0) then $
			axis, yaxis=1, charsize=charsize*csmMulti, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
;		wlF = min(abs(10^wl[*,apPlot] - wlFeature), sub)
;		maxy2 = spectrum_org[sub, apPlot]  + (maxy-miny)*0.2
		maxy2 = maxy - (maxy-miny)*0.1
		oplot, [wlFeature,wlFeature], [maxy2,maxy*2], color=djs_icolor("blue"), thick=2.0
		
		;H alpha
		wlFeature = 6562.d
		;Move it
		wlFeature += dvNoCorr/c * wlFeature		
		repack_findApWithFeat, 10^wl, wlFeature, apPlot, spectrograph
		titleStr = 'H alpha 6562.81 ang'
		;Plot continuum fit
		miny = min(spectrum_org[*,apPlot])*0.80
		maxy = max(spectrum_org[*,apPlot])*1.10
		plot, 10^wl(*,apPlot), spectrum_org(*,apPlot), xtitle='Wavelength (Angstrom)', ytitle='ADU', title=titleStr, $
			xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
			thick=thick, xthick=thick, ythick=thick, xmargin=xmargin;, nsum=nsum
		if(repack_checkGDL() eq 0) then $
			axis, yaxis=1, charsize=charsize*csmMulti, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
;		wlF = min(abs(10^wl[*,apPlot] - wlFeature), sub)
;		maxy2 = spectrum_org[sub, apPlot]  + (maxy-miny)*0.1
		maxy2 = maxy - (maxy-miny)*0.1
		oplot, [wlFeature,wlFeature], [maxy2,maxy*2], color=djs_icolor("blue"), thick=2.0

		;Li
		wlFeature = 6708d
		;Move it
		wlFeature += dvNoCorr/c * wlFeature		
		repack_findApWithFeat, 10^wl, wlFeature, apPlot, spectrograph
		titleStr = 'Li 6708 ang'
		;Plot continuum fit
		miny = min(spectrum_org[*,apPlot])*0.80
		maxy = max(spectrum_org[*,apPlot])*1.10
		plot, 10^wl(*,apPlot), spectrum_org(*,apPlot), xtitle='Wavelength (Angstrom)', ytitle='ADU', title=titleStr, $
			xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
			thick=thick, xthick=thick, ythick=thick, xmargin=xmargin;, nsum=nsum
		if(repack_checkGDL() eq 0) then $
			axis, yaxis=1, charsize=charsize*csmMulti, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
		maxy2 = maxy - (maxy-miny)*0.1
		oplot, [wlFeature,wlFeature], [maxy2,maxy*2], color=djs_icolor("blue"), thick=2.0


		;NaD
		wlFeature = 5890d
		;Move it
		wlFeature += dvNoCorr/c * wlFeature		
		repack_findApWithFeat, 10^wl, wlFeature, apPlot, spectrograph
		titleStr = 'NaD 5890 and 5896 ang'
		;Plot continuum fit
		miny = min(spectrum_org[*,apPlot])*0.80
		maxy = max(spectrum_org[*,apPlot])*1.10
		plot, 10^wl(*,apPlot), spectrum_org(*,apPlot), xtitle='Wavelength (Angstrom)', ytitle='ADU', title=titleStr, $
			xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
			thick=thick, xthick=thick, ythick=thick, xmargin=xmargin;, nsum=nsum
		if(repack_checkGDL() eq 0) then $
			axis, yaxis=1, charsize=charsize*csmMulti, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
;		wlF = min(abs(10^wl[*,apPlot] - wlFeature), sub)
;		maxy2 = spectrum_org[sub, apPlot]  + (maxy-miny)*0.1
		maxy2 = maxy - (maxy-miny)*0.1
		oplot, [wlFeature,wlFeature], [maxy2,maxy*2], color=djs_icolor("blue"), thick=2.0
		oplot, [5896d,5896d], [maxy2,maxy*2], color=djs_icolor("blue"), thick=2.0


;		;Red order
;		;wlFeature = 3968.5d
;		;repack_findApWithFeat, 10^wl, wlFeature, apFound
;		titleStr = 'Redest order'
;		if(spectrograph ne 'mcdonald') then begin
;			apPlot = N_ELEMENTS(wl[0,*]) - 1
;		endif else begin
;			apPlot = 2
;		endelse
;		
;		;Specifically TRES
;		if(spectrograph ne 'tres' and apPlot eq 50) then apPlot = 49
;		;Plot continuum fit
;		miny = min(spectrum_org(con_xstart[k]:con_xend[k],apPlot))*0.80
;		maxy = max(spectrum_org(con_xstart[k]:con_xend[k],apPlot))*1.15
;		plot, 10^wl(*,apPlot), spectrum_org(*,apPlot), xtitle='Wavelength (Angstrom)', ytitle='ADU', title=titleStr, $
;			xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize, yrange=[0, maxy], ystyle=1
;		
		if(not KEYWORD_SET(plotContinuumFitOff)) then begin
			for kk=0, N_ELEMENTS(orders)-1 do begin
				ap = orders[kk]
				
				;Blaze removed spectrum
				maxy = max(spectrum_org[*,ap])*1.10
				if(KEYWORD_SET(blazefit)) then begin
					plot, 10^wl[*,ap], spectrum_org[*,ap]/blazefit[*,ap], xtitle='Wavelength (Angstrom)', ytitle='ADU', title=string(format='(%"Spectrum order %i")', ap+1), $
						xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
						thick=thick, xthick=thick, ythick=thick, xmargin=[5,8];, nsum=nsum
				endif else begin
					plot, 10^wl[*,ap], spectrum_org[*,ap], xtitle='Wavelength (Angstrom)', ytitle='ADU', title=string(format='(%"Spectrum order %i")', ap+1), $
						xstyle=1, background=djs_icolor("white"), color=djs_icolor("black"), charsize=charsize*csmMulti, yrange=[0, maxy], ystyle=ystyle, YTICKFORMAT='(i)', $
						thick=thick, xthick=thick, ythick=thick, xmargin=[5,8];, nsum=nsum
				endelse
				oplot, 10^wl[*,ap], continuum[*,kk], color=djs_icolor("blue"), nsum=nsum*4
				;gain = repack_spec_getGainFactor(spectrograph)
				repack_spec_getRON_gain, objHeader, readoutnoise, gain, spectrograph=spectrograph
				if(repack_checkGDL() eq 0) then $
					axis, yaxis=1, charsize=charsize*csmMulti, yrange=(!Y.CRANGE * gain), ystyle=1, color=djs_icolor("black"), ytitle='Photons', YTICKFORMAT='(i)'
			endfor
		endif	
	endif


END