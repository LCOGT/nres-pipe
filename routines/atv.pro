;+
;
; NAME:
;       ATV
; 
; PURPOSE: 
;       Interactive display of 2-D images.
;
; CATEGORY: 
;       Image display.
;
; CALLING SEQUENCE:
;       atv [,array_name OR fits_file] [,min = min_value] [,max=max_value] 
;           [,/linear] [,/log] [,/histeq] [,/asinh] [,/block]
;           [,/align] [,/stretch] [,header = header]
;
; REQUIRED INPUTS:
;       None.  If atv is run with no inputs, the window widgets
;       are realized and images can subsequently be passed to atv
;       from the command line or from the pull-down file menu.
;
; OPTIONAL INPUTS:
;       array_name: a 2-D array or 3-D data cube to display
;          OR
;       fits_file:  a fits file name, enclosed in single quotes
;
; KEYWORDS:
;       min:        minimum data value to be mapped to the color table
;       max:        maximum data value to be mapped to the color table
;       linear:     use linear stretch
;       log:        use log stretch 
;       histeq:     use histogram equalization
;       asinh:      use asinh stretch
;       block:      block IDL command line until ATV terminates
;       align:      align image with previously displayed image
;       stretch:    keep same min and max as previous image
;       header:     FITS image header (string array) for use with data array
;       
; OUTPUTS:
;       None.  
; 
; COMMON BLOCKS:
;       atv_state:  contains variables describing the display state
;       atv_images: contains the internal copies of the display image
;       atv_color:  contains colormap vectors
;       atv_pdata:  contains plot and text annotation information
;       atv_spectrum: contains information about extracted spectrum
;
; RESTRICTIONS:
;       Requires IDL version 8.0 or greater.
;       Requires Craig Markwardt's cmps_form.pro routine.
;       Requires the GSFC IDL astronomy user's library routines.
;       Requires D. Fanning's Coyote Graphics library.
;       Some features may not work under all operating systems.
;
; EXAMPLE:
;       To start atv running, just enter the command 'atv' at the idl
;       prompt, either with or without an array name or fits file name 
;       as an input.  Only one atv window will be created at a time,
;       so if one already exists and another image is passed to atv
;       from the idl command line, the new image will be displayed in 
;       the pre-existing atv window.
;
; MODIFICATION HISTORY:
;       Written/maintained by Aaron J. Barth, with contributions by 
;       numerous others.  First released 17 December 1998.
;
;       This version is 3.0b4, last modified 28 July 2014.
;
;       For the most current version, instructions, revision history,
;       and further information, go to:
;              http://www.physics.uci.edu/~barth/atv
; 
;
;----------------------------------------------------------------------
;        atv startup and initialization routines
;----------------------------------------------------------------------

pro atv_initcommon

; Routine to initialize the atv common blocks.  Use common blocks so
; that other IDL programs can access the atv internal data easily.

common atv_state, state
common atv_color, r_vector, g_vector, b_vector, user_r, user_g, user_b
common atv_pdata, atvplotlist
common atv_images, $
   main_image, $
   main_image_cube, $
   display_image, $
   scaled_image, $
   blink_image1, $
   blink_image2, $
   blink_image3, $
   unblink_image, $  
   pan_image

state = {                   $
        version: '3.0b4', $     ; version # of this release
        panel_side: 2, $        ; 0=left, 1=right, 2=top for panel location
        head_ptr: ptr_new(), $  ; pointer to image header
        astr_ptr: ptr_new(), $  ; pointer to astrometry info structure
        firstimage: 1, $        ; is this the first image?
        block: 0, $             ; are we in blocking mode?
        user_decomposed: 0, $   ; device decomposed type
        wcstype: 'none', $      ; coord info type (none/angle/lambda)
        equinox: 'J2000', $     ; equinox of coord system
        display_coord_sys: 'RA--', $ ; coord system displayed
        display_equinox: 'J2000', $ ; equinox of displayed coords
        display_base60: 1B, $   ; Display RA,dec in base 60?
        cunit: '', $            ; wavelength units
        imagename: '', $        ; image file name
        title_extras: '', $     ; extras for image title
        bitdepth: 8, $          ; 8 or 24 bit color mode?
        screen_xsize: 1000, $   ; horizontal size of screen
        screen_ysize: 1000, $   ; vertical size of screen
        base_id: 0L, $          ; id of top-level base
        base_min_size: [512L, 405L], $ ; min size for top-level base
        draw_base_id: 0L, $     ; id of base holding draw window
        draw_window_id: 0L, $   ; window id of draw window
        draw_widget_id: 0L, $   ; widget id of draw widget
        mousemode: "color", $   ; color, blink, zoom, or imexam
        mode_droplist_id: 0L, $ ; id of mode droplist widget
        track_window_id: 0L, $  ; widget id of tracking window
        pan_widget_id: 0L, $    ; widget id of pan window
        pan_window_id: 0L, $    ; window id of pan window
        active_window_id: 0L, $ ; user's active window outside atv
        active_window_pmulti: lonarr(5), $ ; user's active window p.multi
        location_bar_id: 0L, $  ; id of (x,y,value) label
        wcs_bar_id: 0L, $       ; id of WCS label widget
        min_text_id: 0L,  $     ; id of min= widget
        max_text_id: 0L, $      ; id of max= widget
        menu_ids: lonarr(35), $ ; list of top menu items
        colorbar_widget_id: 0L, $ ; widget id of colorbar draw widget
        colorbar_window_id: 0L, $ ; window id of colorbar
        colorbar_size: [256,6], $  ; size of colorbar in pixels
        ncolors: 0L, $          ; image colors (!d.table_size - 9)
        box_color: 'green', $   ; color for pan box and zoom x
        panarrow_color: 'magenta', $ ; arrow color in pan window
        brightness: 0.5, $      ; initial brightness setting
        contrast: 0.5, $        ; initial contrast setting
        image_min: 0.0, $       ; min(main_image)
        image_max: 0.0, $       ; max(main_image)
        min_value: 0.0, $       ; min data value mapped to colors
        max_value: 0.0, $       ; max data value mapped to colors
        skymode: 0.0, $         ; sky mode value
        skysig: 0.0, $          ; sky sigma value
        draw_window_size: [512L, 512L], $ ; size of main draw window
        track_window_size: 121L, $ ; size of tracking window
        pan_window_size: 121L, $ ; size of pan window
        pan_scale: 0.0, $       ; magnification of pan image
        image_size: [0L,0L], $  ; size of main_image
        invert_colormap: 0L, $  ; 0=normal, 1=inverted
        coord: [0L, 0L],  $     ; cursor position in image coords
        scaling: 3, $           ; 0=lin,1=log,2=histeq,3=asinh
        asinh_beta: 0.1, $      ; asinh nonlinearity parameter
        offset: [0L, 0L], $     ; offset to viewport coords
        base_pad: [0L, 0L], $   ; padding around draw base
        zoom_level: 0L, $       ; integer zoom level, 0=normal
        zoom_factor: 1.0, $     ; magnification factor = 2^zoom_level
        centerpix: [0L, 0L], $  ; pixel at center of viewport
        cstretch: 0B, $         ; flag = 1 while stretching colors
        pan_offset: [0L, 0L], $ ; image offset in pan window
        cube: 0, $              ; is main image a 3d cube?
        osiriscube: 0, $        ; is cube an osiris-style (l,y,x) cube?
        slice: 0, $             ; which slice of cube to display
        slicebase_id: 0, $      ; widget id of slice base
        slicer_id: 0, $         ; widget id of slice slider
        sliceselect_id: 0, $    ; widget id of slice selector
        slicecombine_id: 0, $   ; widget id of slice combine box
        slicecombine: 1, $      ; # slices to combine
        slicecombine_method: 1, $ ; 0 for average, 1 for median
        nslices: 0, $           ; number of slices
        frame: 1L, $            ; put frame around ps output?
        framethick: 6, $        ; thickness of frame
        plot_coord: [0L, 0L], $ ; cursor position for a plot
        vector_coord1: [0L, 0L], $ ; 1st cursor position in vector plot  
        vector_coord2: [0L, 0L], $ ; 2nd cursor position in vector plot
        vector_pixmap_id: 0L, $ ; id for vector pixmap 
        vectorpress: 0L, $      ; are we plotting a vector?
        vectorstart: [0L,0L], $ ; device x,y of vector start
        plot_type:'', $         ; plot type for plot window
        lineplot_widget_id: 0L, $ ; id of lineplot widget
        lineplot_window_id: 0L, $ ; id of lineplot window
        lineplot_base_id: 0L, $ ; id of lineplot top-level base
        lineplot_size: [600L, 500L], $ ; size of lineplot window
        lineplot_min_size: [100L, 0L], $ ; min size of lineplot window
        lineplot_pad: [0L, 0L], $ ; padding around lineplot window
        lineplot_xmin_id: 0L, $ ; id of xmin for lineplot windows
        lineplot_xmax_id: 0L, $ ; id of xmax for lineplot windows
        lineplot_ymin_id: 0L, $ ; id of ymin for lineplot windows
        lineplot_ymax_id: 0L, $ ; id of ymax for lineplot windows
        lineplot_charsize_id: 0L, $ ; id of charsize for lineplots
        lineplot_xmin: 0.0, $   ; xmin for lineplot windows
        lineplot_xmax: 0.0, $   ; xmax for lineplot windows
        lineplot_ymin: 0.0, $   ; ymin for lineplot windows
        lineplot_ymax: 0.0, $   ; ymax for lineplot windows
        lineplot_xmin_orig: 0.0, $ ; original xmin saved from histplot
        lineplot_xmax_orig: 0.0, $ ; original xmax saved from histplot
        holdrange_base_id: 0L, $ ; base id for 'Hold Range' button
        holdrange_button_id: 0L, $ ; button id for 'Hold Range' button
        holdrange_value: 0, $   ; 0=HoldRange Off, 1=HoldRange On
        histbutton_base_id: 0L, $ ; id of histogram button base
        histplot_binsize_id: 0L, $ ; id of binsize for histogram plot
        x1_pix_id: 0L, $        ; id of x1 pixel for histogram plot
        x2_pix_id: 0L, $        ; id of x2 pixel for histogram plot
        y1_pix_id: 0L, $        ; id of y1 pixel for histogram plot
        y2_pix_id: 0L, $        ; id of y2 pixel for histogram plot
        plotcharsize: 1.5, $    ; charsize for plot window
        binsize: 0.0, $         ; binsize for histogram plots
        regionform_id: 0L, $    ; id of region form widget
        reg_ids_ptr: ptr_new(), $ ; ids for region form widget
        cursorpos: lonarr(2), $ ; cursor x,y for photometry & stats
        centerpos: fltarr(2), $ ; centered x,y for photometry
        cursorpos_id: 0L, $     ; id of cursorpos widget
        centerpos_id: 0L, $     ; id of centerpos widget
        centerbox_id: 0L, $     ; id of centeringboxsize widget
        radius_id: 0L, $        ; id of radius widget
        innersky_id: 0L, $      ; id of inner sky widget
        outersky_id: 0L, $      ; id of outer sky widget
        magunits: 0, $          ; 0=counts, 1=magnitudes
        skytype: 0, $           ; 0=idlphot,1=median,2=no sky subtract
        exptime: 1.0, $         ; exposure time for photometry
        photzpt: 25.0, $        ; magnitude zeropoint
        photprint: 0, $         ; print phot results to file?
        photprint_id: 0L, $     ; id of phot print button
        photfile: 0L, $         ; file unit of phot file
        photfilename: 'atvphot.dat', $ ; filename of phot file
        skyresult_id: 0L, $     ; id of sky widget
        photresult_id: 0L, $    ; id of photometry result widget
        photerror_id: 0L, $,    ; id of photometry error widget
        fwhm_id: 0L, $          ; id of fwhm widget
        radplot_widget_id: 0L, $ ; id of radial profile widget
        radplot_window_id: 0L, $ ; id of radial profile window
        photzoom_window_id: 0L, $ ; id of photometry zoom window
        photzoom_size: 190L, $  ; size in pixels of photzoom window
        showradplot_id: 0L, $   ; id of button to show/hide radplot
        photwarning_id: 0L, $   ; id of photometry warning widget
        photwarning: ' ', $     ; photometry warning text
        photerrors: 0, $        ; calculate photometric errors?
        ccdgain: 1.0, $         ; CCD gain
        ccdrn: 0.0, $           ; read noise
        centerboxsize: 9L, $    ; centering box size
        aprad: 5.0, $           ; aperture photometry radius
        innersky: 10.0, $       ; inner sky radius
        outersky: 20.0, $       ; outer sky radius
        headinfo_base_id: 0L, $ ; headinfo base widget id
        pixtable_base_id: 0L, $ ; pixel table base widget id
        pixtable_tbl_id: 0L, $  ; pixel table widget_table id
        stats_base_id: 0L, $    ; base widget for image stats
        statboxsize: 11L, $     ; box size for computing statistics
        statbox_id: 0L, $       ; widget id for stat box size 
        stat_npix_id: 0L, $     ; widget id for # pixels in stats box
        statxcenter_id: 0L, $   ; widget id for stat box x center
        statycenter_id: 0L, $   ; widget id for stat box y center
        statbox_min_id: 0L, $   ; widget id for stat min box
        statbox_max_id: 0L, $   ; widget id for stat max box
        statbox_mean_id: 0L, $  ; widget id for stat mean box
        statbox_median_id: 0L, $ ; widget id for stat median box
        statbox_stdev_id: 0L, $ ; widget id for stat stdev box
        statzoom_size: 300, $   ; size of statzoom window
        statzoom_widget_id: 0L, $ ; widget id for stat zoom window
        statzoom_window_id: 0L, $ ; window id for stat zoom window
        showstatzoom_id: 0L, $  ; widget id for show/hide button
        pan_pixmap: 0L, $       ; window id of pan pixmap
        current_dir: '', $      ; current readfits directory
        graphicsdevice: '', $   ; screen device
        ispsformon: 0, $        ; is cmps_form running?
        newrefresh: 0, $        ; refresh since last blink?
        blinks: 0B, $           ; remembers which images are blinked
        x_tracestep: 21L, $     ; extraction tracing step
        x_tracestep_id: 0, $    ; widget id for tracestep
        x_traceheight: 7L, $    ; extraction tracing height
        x_traceheight_id: 0, $  ; widget id for trace height
        x_xregion: [0L, 0L], $  ; extraction x region
        x_xstart_id: 0, $       ; widget id for extraction x start
        x_xend_id: 0, $         ; widget id for extraction x end
        x_traceorder: 3, $      ; extraction trace fit order
        x_traceorder_id: 0, $   ; widget id for extraction trace order 
        x_xlower: -5, $         ; extraction lower bound
        x_xlower_id: 0, $       ; widget id for extraction lower
        x_xupper: 5, $          ; extraction upper bound
        x_xupper_id: 0, $       ; widget id for extraction upper 
        x_backsub: 1, $         ; background subtraction on?
        x_back1: -25, $         ; extraction lower background 1
        x_back2: -15, $         ; extraction lower background 2
        x_back3: 15, $          ; extraction upper background 1
        x_back4: 25, $          ; extraction upper background 2
        x_back1_id: 0, $        ; widget id for lower background 1
        x_back2_id: 0, $        ; widget id for lower background 2
        x_back3_id: 0, $        ; widget id for upper background 1
        x_back4_id: 0, $        ; widget id for upper background 2
        x_fixed: 0, $           ; hold extraction parameters fixed?
        activator: 0, $         ; is "activator" mode on?
        delimiter: '/', $       ; filesystem level delimiter 
        default_align: 1, $     ; align next image by default?
        default_autoscale: 1, $ ; autoscale images by default?
        default_stretch: 0, $   ; use previous minmax for new image?
        cubehelix_start_id: 0L, $ ; cubehelix start color
        cubehelix_nrot_id: 0L, $ ; cubehelix # of rotations
        cubehelix_hue_id: 0L,   $ ; cubehelix hue strength
        cubehelix_gamma_id: 0L, $ ; cubehelix gamma parameter
        cubehelix_plot_id: 0L,  $; cubehelix color plot window id
        cubehelix_start: 0.5, $ ; cubehelix start color
        cubehelix_nrot: -1.5, $ ; cubehelix # of rotations
        cubehelix_hue: 1.0,   $ ; cubehelix hue strength
        cubehelix_gamma: 1.0  $ ; cubehelix gamma parameter
        }

atvplotlist = list()

blink_image1 = 0
blink_image2 = 0
blink_image3 = 0

end

;---------------------------------------------------------------------

pro atv_startup

; This routine initializes the atv internal variables, and creates and
; realizes the window widgets.  It is only called by the atv main
; program level, when there is no previously existing atv window.

common atv_state
common atv_color


; save the user color table and pmulti first
tvlct, user_r, user_g, user_b, /get

; Read in a color table to initialize !d.table_size and make sure
; there are enough colors

if (!d.table_size LT 12) then begin
    message, 'Too few colors available for color table'
    tvlct, user_r, user_g, user_b
    atv_shutdown
endif

; Initialize the common blocks
atv_initcommon

; seems to be necessary to check the decomposed type when first
; starting up in a new idl session, otherwise color map changes fail
; for some reason.  Don't understand why this is needed, but it
; is. Save it as a state variable in case there's a need for it later
; on.
device, get_decomposed = ud
state.user_decomposed = ud

state.active_window_pmulti = !p.multi
!p.multi = 0

osfamily = strupcase(!version.os_family)
case osfamily of
    'UNIX': state.delimiter = '/'
    'WINDOWS': state.delimiter = '\'
    else:
endcase

state.ncolors = !d.table_size


; If compiling atv to make a sav file for the atv virtual machine,
; always do it for 24-bit color with retain & decomposed set.
; Uncomment this block to compile atv for idl vm.  For some reason,
; idl vm gets !d.n_colors=256 even on a 24-bit display, so we need
; this to work around it to force 24-bit mode.
;device, true_color=24
;device, decomposed=0
;device, retain=2
;state.bitdepth=24

; For normal idl operation, use the following.  Comment this block out
; if compiling atv for idl vm.
if (!d.n_colors LE 256) then begin
    state.bitdepth = 8 
endif else begin
    state.bitdepth = 24
;    device, decomposed=0  ; not needed any more as of ATV 3.0
endelse


state.graphicsdevice = !d.name

state.screen_xsize = (get_screen_size())[0]
state.screen_ysize = (get_screen_size())[1]

; Get the current window id and color table
atv_getwindow

; error check on state.panel_side
if (state.panel_side NE 0 AND $
    state.panel_side NE 1 AND $
    state.panel_side NE 2) then state.panel_side = 2

; Define the widgets.  For the widgets that need to be modified later
; on, save their widget ids in state variables

if (state.panel_side LE 1) then begin   ; panels on left or right
   base = widget_base(title = 'atv', $
                      /row, /base_align_top, $
                      app_mbar = top_menu, $
                      uvalue = 'atv_base', $
                      /tlb_size_events)
endif else begin                        ; panels on top
   base = widget_base(title = 'atv', $  
                      /column, /base_align_right, $
                      app_mbar = top_menu, $
                      uvalue = 'atv_base', $
                      /tlb_size_events)
endelse

state.base_id = base

tmp_struct = {cw_pdmenu_s, flags:0, name:''}

top_menu_desc = [ $
                {cw_pdmenu_s, 1, 'File'}, $ ; file menu
                {cw_pdmenu_s, 0, 'ReadFits'}, $
                {cw_pdmenu_s, 0, 'WriteFits'}, $
                {cw_pdmenu_s, 0, 'WritePS'},  $
                {cw_pdmenu_s, 1, 'WriteImage'}, $
                {cw_pdmenu_s, 0, 'PNG'}, $
                {cw_pdmenu_s, 0, 'JPEG'}, $
                {cw_pdmenu_s, 2, 'TIFF'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 1, 'GetImage'}, $
                {cw_pdmenu_s, 2, ' DSS'}, $
;                {cw_pdmenu_s, 2, ' FIRST'}, $  ;broken, don't use for now
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 2, 'Quit'}, $
                {cw_pdmenu_s, 1, 'ColorMap'}, $ ; color menu
                {cw_pdmenu_s, 0, 'Grayscale'}, $
                {cw_pdmenu_s, 0, 'Blue-White'}, $
                {cw_pdmenu_s, 0, 'Red-Orange'}, $
                {cw_pdmenu_s, 0, 'Green-White'}, $
; commented out color maps that I don't really like
;                {cw_pdmenu_s, 0, 'Rainbow'}, $
;                {cw_pdmenu_s, 0, 'BGRY'}, $
;                {cw_pdmenu_s, 0, 'Stern Special'}, $
                {cw_pdmenu_s, 0, 'Velocity'}, $
                {cw_pdmenu_s, 0, 'Cubehelix'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 2, 'Cubehelix Settings'}, $
                {cw_pdmenu_s, 1, 'Scaling'}, $ ; scaling menu
                {cw_pdmenu_s, 0, 'Asinh'}, $
                {cw_pdmenu_s, 0, 'Log'}, $
                {cw_pdmenu_s, 0, 'Linear'}, $
                {cw_pdmenu_s, 0, 'HistEq'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 2, 'Asinh Settings'}, $
                {cw_pdmenu_s, 1, 'Labels'}, $ ; labels menu
                {cw_pdmenu_s, 0, 'TextLabel'}, $
                {cw_pdmenu_s, 0, 'Arrow'}, $
                {cw_pdmenu_s, 0, 'Contour'}, $
                {cw_pdmenu_s, 0, 'Compass'}, $
                {cw_pdmenu_s, 0, 'ScaleBar'}, $
                {cw_pdmenu_s, 0, 'Region'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, 'EraseLast'}, $
                {cw_pdmenu_s, 0, 'EraseAll'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, 'LoadRegions'}, $
                {cw_pdmenu_s, 2, 'SaveRegions'}, $
                {cw_pdmenu_s, 1, 'Blink'}, $
                {cw_pdmenu_s, 0, 'SetBlink1'}, $
                {cw_pdmenu_s, 0, 'SetBlink2'}, $
                {cw_pdmenu_s, 0, 'SetBlink3'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 2, 'MakeRGB'}, $
                {cw_pdmenu_s, 1, 'Rotate/Zoom'}, $
                {cw_pdmenu_s, 0, 'Rotate'}, $
                {cw_pdmenu_s, 0, '90 deg'}, $
                {cw_pdmenu_s, 0, '180 deg'}, $
                {cw_pdmenu_s, 0, '270 deg'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, 'Invert X'}, $
                {cw_pdmenu_s, 0, 'Invert Y'}, $
                {cw_pdmenu_s, 0, 'Invert XY'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, '1/16x'}, $
                {cw_pdmenu_s, 0, '1/8x'}, $
                {cw_pdmenu_s, 0, '1/4x'}, $
                {cw_pdmenu_s, 0, '1/2x'}, $
                {cw_pdmenu_s, 0, '1x'}, $
                {cw_pdmenu_s, 0, '2x'}, $
                {cw_pdmenu_s, 0, '4x'}, $
                {cw_pdmenu_s, 0, '8x'}, $
                {cw_pdmenu_s, 2, '16x'}, $
                {cw_pdmenu_s, 1, 'ImageInfo'}, $ ;info menu
                {cw_pdmenu_s, 0, 'ImageHeader'}, $
                {cw_pdmenu_s, 0, 'Photometry'}, $
                {cw_pdmenu_s, 0, 'Statistics'}, $
                {cw_pdmenu_s, 0, 'PixelTable'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, 'RA,dec (J2000)'}, $
                {cw_pdmenu_s, 0, 'RA,dec (B1950)'}, $
                {cw_pdmenu_s, 0, '--------------'}, $
                {cw_pdmenu_s, 0, 'RA,dec (J2000) deg'}, $
                {cw_pdmenu_s, 0, 'Galactic'}, $
                {cw_pdmenu_s, 0, 'Ecliptic (J2000)'}, $
                {cw_pdmenu_s, 2, 'Native'}, $
                {cw_pdmenu_s, 1, 'Help'}, $ ; help menu
                {cw_pdmenu_s, 2, 'ATV Help'} $
                ]

top_menu = cw_pdmenu(top_menu, top_menu_desc, $
                     ids = state.menu_ids, $
                     /mbar, $
                     /help, $
                     /return_name, $
                     uvalue = 'top_menu')

; set arrangement of side/top panel and main draw window based on the
; value of state.panel_side. 

; from here on the setup is very different if the panel is to be on
; top vs on the left or right side

if (state.panel_side LE 1) then begin
; panel on left or right   

   case state.panel_side of
      0: begin
         side_base = widget_base(base,/column,/base_align_right)
         state.draw_base_id = widget_base(base, /column, /base_align_left, $
                                          uvalue = 'draw_base', frame = 0)
      end
      1: begin
         state.draw_base_id = widget_base(base, /column, /base_align_left, $
                                          uvalue = 'draw_base', frame = 0)
         side_base = widget_base(base,/column,/base_align_center)
      end
   endcase
  
   state.colorbar_size = [256,6]

   sidebasesize = 254
   buttonsize = 72

   track_base = widget_base(side_base, /row, frame=1, xsize=sidebasesize+6)
   
   colorbar_base = widget_base(side_base, $
                               uvalue = 'colorbar_base', $
                               /column, /base_align_left, $
                               frame = 1, scr_xsize = sidebasesize+6)
   
   info_base = widget_base(side_base, /column, frame = 1, $
                           /base_align_center)
   buttonbar_base = widget_base(side_base,column=3,scr_xsize=sidebasesize+6, $
                                frame=1, /base_align_center)


   tmp_string = string(1000, 1000, 1.0e-10, $
                       format = '("(",i5,",",i5,")        ",g12.5)' )
   
   state.location_bar_id = widget_label (info_base, $
                                         value = tmp_string,  $
                                         uvalue = 'location_bar', frame=0)
   
   tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $
            format = '(i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )
   
   state.wcs_bar_id = widget_label (info_base, $
                                    value = tmp_string,  $
                                    uvalue = 'wcs_bar', frame=0)
   
   
   minmax_base = widget_base(info_base,/row,/base_align_center, $
                             scr_xsize = sidebasesize)
   
   state.min_text_id = cw_field(minmax_base, $
                                uvalue = 'min_text', $
                                /floating,  $
                                title = 'Min=', $
                                value = state.min_value,  $
                                /return_events, $
                                xsize = 11)
   
   state.max_text_id = cw_field(minmax_base, $
                                uvalue = 'max_text', $
                                /floating,  $
                                title = 'Max=', $
                                value = state.max_value, $
                                /return_events, $
                                xsize = 11)
   
   state.pan_widget_id = widget_draw(track_base, $
                                     xsize = state.pan_window_size, $
                                     ysize = state.pan_window_size, $
                                     frame = 0, uvalue = 'pan_window', $
                                     /button_events, /motion_events)
   
   dummy_spacing_widget = widget_base(track_base,xsize=5)
   
   
   track_window = widget_draw(track_base, $
                              xsize=state.track_window_size, $
                              ysize=state.track_window_size, $
                              frame=0, uvalue='track_window')
  
   modebase = widget_base(buttonbar_base, /column, /base_align_center)
   mode_label = widget_label(modebase,value='Mouse Mode:')


   modelist = ['Color', 'Zoom', 'Blink', 'ImExam', 'Vector']
   mode_droplist_id = widget_droplist(modebase, $
                                      uvalue = 'mode', $
                                      value = modelist)
   state.mode_droplist_id = mode_droplist_id

   button_base1 = widget_base(buttonbar_base, /column,/base_align_center)
   button_base2 = widget_base(buttonbar_base, /column,/base_align_center)

   invert_button = widget_button(button_base1, $
                                 value = 'Invert', $
                                 uvalue = 'invert', xsize=buttonsize)
   
   restretch_button = widget_button(button_base1, $
                                    value = 'Restretch', $
                                    uvalue = 'restretch_button', $
                                    xsize=buttonsize)
   
   autoscale_button = widget_button(button_base1, $
                                    uvalue = 'autoscale_button', $
                                    value = 'AutoScale', xsize=buttonsize)
   
   fullrange_button = widget_button(button_base1, $
                                    uvalue = 'full_range', $
                                    value = 'FullRange', xsize=buttonsize)
   
   zoomin_button = widget_button(button_base2, $
                                 value = 'ZoomIn', $
                                 uvalue = 'zoom_in', xsize=buttonsize)
   
   zoomout_button = widget_button(button_base2, $
                                  value = 'ZoomOut', $
                                  uvalue = 'zoom_out', xsize=buttonsize)
   
   zoomone_button = widget_button(button_base2, $
                                  value = 'Zoom1', $
                                  uvalue = 'zoom_one', xsize=buttonsize)
   
   fullview_button = widget_button(button_base2, $
                                   value = 'FullView', $
                                   uvalue = 'fullview', xsize=buttonsize)
   
   center_button = widget_button(button_base2, $
                                 value = 'Center', $
                                 uvalue = 'center', xsize=buttonsize)
   
   state.draw_widget_id = widget_draw(state.draw_base_id, $
                                      uvalue = 'draw_window', $
                                      /motion_events,  /button_events, $
                                      keyboard_events=2, $
                                      scr_xsize = state.draw_window_size[0], $
                                      scr_ysize = state.draw_window_size[1]) 
   
   state.colorbar_widget_id = widget_draw(colorbar_base, $
                                          uvalue = 'colorbar', $
                                          scr_xsize = sidebasesize, $
                                          scr_ysize = state.colorbar_size[1])
   
endif else begin
; widget layout for info panels on top

   state.colorbar_size = [6,state.pan_window_size]
   sidebasesize = 254
   buttonsize = 72

   row1base = widget_base(base, column=2, /base_align_right)

   buttonbar_base = widget_base(base,column=7, /base_align_right)

   info_base = widget_base(row1base, column=1, /base_align_right)
 
   track_base = widget_base(row1base, /row)
   
   state.min_text_id = cw_field(info_base, $
                                uvalue = 'min_text', $
                                /floating,  $
                                title = 'Min=', $
                                value = state.min_value,  $
                                /return_events, $
                                xsize = 11)
   
   state.max_text_id = cw_field(info_base, $
                                uvalue = 'max_text', $
                                /floating,  $
                                title = 'Max=', $
                                value = state.max_value, $
                                /return_events, $
                                xsize = 11)

   tmp_string = string(1000, 1000, 1.0e-10, $
                       format = '("(",i5,",",i5,")        ",g12.5)' )
   
   state.location_bar_id = widget_label (info_base, $
                                         value = tmp_string,  $
                                         uvalue = 'location_bar', frame=1)

   tmp_string = string(12, 12, 12.001, -60, 60, 60.01, ' J2000', $
            format = '(i2,":",i2,":",f6.3,"  ",i3,":",i2,":",f5.2," ",a6)' )
   
   state.wcs_bar_id = widget_label (info_base, $
                                    value = tmp_string,  $
                                    uvalue = 'wcs_bar', frame=1)

   state.colorbar_widget_id = widget_draw(track_base, $
                                          uvalue = 'colorbar', $
                                          scr_xsize = state.colorbar_size[0], $
                                          scr_ysize = state.colorbar_size[1])

   dummy_spacing_widget = widget_base(track_base,xsize=1)

   state.pan_widget_id = widget_draw(track_base, $
                                     xsize = state.pan_window_size, $
                                     ysize = state.pan_window_size, $
                                     frame = 0, uvalue = 'pan_window', $
                                     /button_events, /motion_events)
   
   dummy_spacing_widget2 = widget_base(track_base,xsize=1)
   
   track_window = widget_draw(track_base, $
                              xsize=state.track_window_size, $
                              ysize=state.track_window_size, $
                              frame=0, uvalue='track_window')
   
   mode_label = widget_label(buttonbar_base,value='Mouse Mode: ')
   
   modelist = ['Color', 'Zoom', 'Blink', 'ImExam', 'Vector']
   mode_droplist_id = widget_droplist(buttonbar_base, $
                                      uvalue = 'mode', $
                                      value = modelist)
   state.mode_droplist_id = mode_droplist_id

;  add a bit of extra space between the
;  mouse mode selector and the buttons
   dummy_spacing_widget3 = widget_base(buttonbar_base,xsize=10)
   dummy_spacing_widget4 = widget_base(buttonbar_base,xsize=10)

   invert_button = widget_button(buttonbar_base, $
                                 value = 'Invert', $
                                 uvalue = 'invert', xsize=buttonsize)

   zoomin_button = widget_button(buttonbar_base, $
                                 value = 'ZoomIn', $
                                 uvalue = 'zoom_in', xsize=buttonsize)
 
   restretch_button = widget_button(buttonbar_base, $
                                    value = 'Restretch', $
                                    uvalue = 'restretch_button', $
                                    xsize=buttonsize)

   zoomout_button = widget_button(buttonbar_base, $
                                  value = 'ZoomOut', $
                                  uvalue = 'zoom_out', xsize=buttonsize)
 
   autoscale_button = widget_button(buttonbar_base, $
                                    uvalue = 'autoscale_button', $
                                    value = 'AutoScale', xsize=buttonsize)

   zoomone_button = widget_button(buttonbar_base, $
                                  value = 'Zoom1', $
                                  uvalue = 'zoom_one', xsize=buttonsize)
   
   fullrange_button = widget_button(buttonbar_base, $
                                    uvalue = 'full_range', $
                                    value = 'FullRange', xsize=buttonsize)
     
   fullview_button = widget_button(buttonbar_base, $
                                   value = 'FullView', $
                                   uvalue = 'fullview', xsize=buttonsize)
   
   done_button = widget_button(buttonbar_base, $
                               value = 'Quit', $
                               uvalue = 'done', xsize = buttonsize)
  
   center_button = widget_button(buttonbar_base, $
                                 value = 'Center', $
                                 uvalue = 'center', xsize=buttonsize)
   
; Set widget y size for small screens. not needed any more?
; state.draw_window_size[1] = state.draw_window_size[1] < $
;  (state.screen_ysize - 300)
   
   state.draw_base_id = widget_base(base, /column, /base_align_left, $
                                    uvalue = 'draw_base', frame = 0) 
   
   state.draw_widget_id = widget_draw(state.draw_base_id, $
                                      uvalue = 'draw_window', $
                                      /motion_events,  /button_events, $
                                      keyboard_events=2, $
                                      scr_xsize = state.draw_window_size[0], $
                                      scr_ysize = state.draw_window_size[1]) 
   
endelse

; Create the widgets on screen

widget_control, base, /realize
widget_control, state.pan_widget_id, draw_motion_events = 0

; get the window ids for the draw widgets

widget_control, track_window, get_value = tmp_value
state.track_window_id = tmp_value
widget_control, state.draw_widget_id, get_value = tmp_value
state.draw_window_id = tmp_value
widget_control, state.pan_widget_id, get_value = tmp_value
state.pan_window_id = tmp_value
widget_control, state.colorbar_widget_id, get_value = tmp_value
state.colorbar_window_id = tmp_value

; set the event handlers

widget_control, top_menu, event_pro = 'atv_topmenu_event'
widget_control, state.draw_widget_id, event_pro = 'atv_draw_event'
widget_control, state.pan_widget_id, event_pro = 'atv_pan_event'

; Find window padding sizes needed for resizing routines.
; Add extra padding for menu bar, since this isn't included in 
; the geometry returned by widget_info.
; Also add extra padding for margin (frame) in draw base.

basegeom = widget_info(state.base_id, /geometry)
drawbasegeom = widget_info(state.draw_base_id, /geometry)


; Initialize the vectors that hold the current color table.
; See the routine atv_stretchct to see why we do it this way.

r_vector = bytarr(state.ncolors)
g_vector = bytarr(state.ncolors)
b_vector = bytarr(state.ncolors)

atv_getct, 0
state.invert_colormap = 0

; Create a pixmap window to hold the pan image
window, /free, xsize=state.pan_window_size, ysize=state.pan_window_size, $
  /pixmap
state.pan_pixmap = !d.window
atv_resetwindow

atv_colorbar

widget_control, state.base_id, tlb_get_size=tmp_event
state.base_pad = tmp_event - state.draw_window_size


end

;--------------------------------------------------------------------

pro atv_colorbar

; Routine to tv the colorbar 

common atv_state

atv_setwindow, state.colorbar_window_id

if (state.panel_side LE 1) then begin
   xsize = state.colorbar_size[0]
   b = congrid( findgen(state.ncolors), xsize)
   c = replicate(1, state.colorbar_size[1])
   a = b # c
endif else begin
   ysize = state.colorbar_size[1]
   b = congrid( findgen(state.ncolors), ysize)
   c = replicate(1, state.colorbar_size[0])
   a = c # b
endelse

cgimage, a, /tv, /noerase

atv_resetwindow

end

;-------------------------------------------------------------------

pro atvclear

; displays a small blank image, useful for clearing memory if atv is
; displaying a huge image.

atv, fltarr(10,10)

end


;--------------------------------------------------------------------
;                  main atv event loops
;--------------------------------------------------------------------

pro atv_topmenu_event, event

; Event handler for top menu

common atv_state
common atv_images

widget_control, event.id, get_uvalue = event_name

if (!d.name NE state.graphicsdevice and event_name NE 'Quit') then return
if (state.bitdepth EQ 24) then true = 1 else true = 0

; Need to get active window here in case mouse goes to menu from top
; of atv window without entering the main base
atv_getwindow


case event_name of
    
; File menu options:
    'ReadFits': begin
        atv_readfits, newimage=newimage
        if (newimage EQ 1) then begin
            atv_getstats, align=state.default_align
            if (state.default_align EQ 0) then begin
                state.zoom_level =  0
                state.zoom_factor = 1.0
            endif
            if (state.default_stretch EQ 0 AND $
                state.default_autoscale EQ 1) then atv_autoscale
            if (state.firstimage EQ 1) then atv_autoscale
            atv_set_minmax
            atv_displayall
            atv_settitle
            state.firstimage = 0
        endif
    end
    'WriteFits': atv_writefits
    'WritePS' : atv_writeps
    'PNG': atv_writeimage, 'png'
    'JPEG': atv_writeimage, 'jpg'
    'TIFF': atv_writeimage, 'tiff'
    'GetImage':
    ' DSS': atv_getdss
    ' FIRST': atv_getfirst
    'LoadRegions': atv_loadregion
    'SaveRegions': atv_saveregion
    'Quit':     if (state.activator EQ 0) then atv_shutdown $
      else state.activator = 0
; ColorMap menu options:            
    'Grayscale': atv_getct, 0
    'Blue-White': atv_getct, 1
    'Red-Orange': atv_getct, 3
    'BGRY': atv_getct, 4
    'Rainbow': atv_getct, 13
    'Stern Special': atv_getct, 15
    'Green-White': atv_getct, 8
    'Velocity': atv_makect, event_name
    'Cubehelix': atv_makect, event_name
    'Cubehelix Settings': atv_set_cubehelix
; Scaling options:
    'Linear': begin
        state.scaling = 0
        atv_displayall
    end
    'Log': begin
        state.scaling = 1
        atv_displayall
    end

    'HistEq': begin
        state.scaling = 2
        atv_displayall
    end

    'Asinh': begin
        state.scaling = 3
        atv_displayall
    end

    'Asinh Settings': begin
        atv_setasinh
    end

; Label options:
    'TextLabel': atv_textlabel
    'Arrow': atv_setarrow
    'Contour': atv_oplotcontour
    'Compass': atv_setcompass
    'ScaleBar': atv_setscalebar
    'Region': atv_setregion
    'EraseLast': atverase, 1
    'EraseAll': atverase

; Blink options:
    'SetBlink1': begin   
        atv_setwindow, state.draw_window_id
        blink_image1 = tvrd(true = true) 
    end
    'SetBlink2': begin   
        atv_setwindow, state.draw_window_id
        blink_image2 = tvrd(true = true)
    end
    'SetBlink3': begin   
        atv_setwindow, state.draw_window_id
        blink_image3 = tvrd(true = true)
    end

    'MakeRGB' : atv_makergb

; Zoom/Rotate options
    '1/16x': atv_zoom, 'onesixteenth'
    '1/8x': atv_zoom, 'oneeighth'
    '1/4x': atv_zoom, 'onefourth'
    '1/2x': atv_zoom, 'onehalf'
    '1x': atv_zoom, 'one'
    '2x': atv_zoom, 'two'
    '4x': atv_zoom, 'four'
    '8x': atv_zoom, 'eight'
    '16x': atv_zoom, 'sixteen'
    'Invert X': atv_invert, 'x'
    'Invert Y': atv_invert, 'y'
    'Invert XY': atv_invert, 'xy'
    'Rotate': atv_rotate, '0', /get_angle
    '0 deg': atv_rotate, '0'
    '90 deg': atv_rotate, '90'
    '180 deg': atv_rotate, '180'
    '270 deg': atv_rotate, '270'

; Info options:
    'Photometry': atv_apphot
    'ImageHeader': atv_headinfo
    'Statistics': atv_showstats
    'PixelTable': atv_pixtable

; Coordinate system options:
    '--------------':
    'RA,dec (J2000)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       state.display_base60 = 1B
       atv_gettrack             ; refresh coordinate window
    END 
    'RA,dec (B1950)': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'B1950'
       state.display_base60 = 1B
       atv_gettrack             ; refresh coordinate window
    END
    'RA,dec (J2000) deg': BEGIN 
       state.display_coord_sys = 'RA--'
       state.display_equinox = 'J2000'
       state.display_base60 = 0B
       atv_gettrack             ; refresh coordinate window
    END 
    'Galactic': BEGIN 
       state.display_coord_sys = 'GLON'
       atv_gettrack             ; refresh coordinate window
    END 
    'Ecliptic (J2000)': BEGIN 
       state.display_coord_sys = 'ELON'
       state.display_equinox = 'J2000'
       atv_gettrack             ; refresh coordinate window
    END 
    'Native': BEGIN 
       IF (state.wcstype EQ 'angle') THEN BEGIN 
          state.display_coord_sys = strmid((*state.astr_ptr).ctype[0], 0, 4)
          state.display_equinox = state.equinox
          atv_gettrack          ; refresh coordinate window
       ENDIF 
    END 

    
; Help options:            
    'ATV Help': atv_help
    
    else: print, 'Unknown event in file menu!'
endcase

; Need to test whether atv is still alive, since the quit option
; might have been selected.
if (xregistered('atv', /noshow)) then atv_resetwindow


end

;--------------------------------------------------------------------

pro atv_draw_event, event

; top-level event handler for draw widget events

common atv_state

if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0 or event.type EQ 1 or event.type EQ 2) then begin
    case state.mousemode of
        'color':  atv_draw_color_event, event
        'zoom':   atv_draw_zoom_event, event
        'blink':  atv_draw_blink_event, event
        'imexam': atv_draw_phot_event, event
        'vector': atv_draw_vector_event, event
    endcase
endif

if (event.type EQ 5 or event.type EQ 6) then $
  atv_draw_keyboard_event, event

if (xregistered('atv', /noshow)) then $
  widget_control, state.draw_widget_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro atv_draw_color_event, event

; Event handler for color mode

common atv_state
common atv_images

;if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin           ; button press
        if (event.press EQ 1) then begin
            state.cstretch = 1
            atv_stretchct, event.x, event.y, /getcursor
            atv_resetwindow
            atv_colorbar
        endif else begin
            atv_zoom, 'none', /recenter
        endelse
    end
    1: begin
       if (event.release EQ 1) then begin
          state.cstretch = 0    ; button release for button 1
          if (state.bitdepth EQ 24) then atv_refresh
          atv_draw_motion_event, event
       endif
    end
    2: begin                ; motion event
        if (state.cstretch EQ 1) then begin
            atv_stretchct, event.x, event.y, /getcursor 
            atv_resetwindow
            if (state.bitdepth EQ 24) then atv_refresh, /fast
        endif else begin 
            atv_draw_motion_event, event
        endelse
    end 
endcase

widget_control, state.draw_widget_id, /sensitive, /input_focus

end

;--------------------------------------------------------------------

pro atv_draw_keyboard_event, event


common atv_state
common atv_images
common atv_color

; Only want to look for key presses, not key releases.
if (event.release EQ 1) then return

if (event.type EQ 5) then begin

    eventchar = string(event.ch)

    if (!d.name NE state.graphicsdevice and eventchar NE 'q') then return
    if (state.bitdepth EQ 24) then true = 1 else true = 0
    
    case eventchar of
        '1': atv_move_cursor, eventchar
        '2': atv_move_cursor, eventchar
        '3': atv_move_cursor, eventchar
        '4': atv_move_cursor, eventchar
        '6': atv_move_cursor, eventchar
        '7': atv_move_cursor, eventchar
        '8': atv_move_cursor, eventchar
        '9': atv_move_cursor, eventchar
        'r': atv_rowplot, /newcoord
        'c': atv_colplot, /newcoord
        's': atv_surfplot, /newcoord
        't': atv_contourplot, /newcoord
        'h': atv_histplot, /newcoord
        'p': atv_apphot
        'i': atv_showstats
        'm': atv_changemode
        'w': print, state.coord
        'x': atvextract, /newcoord
        'e': atverase
        '-': atv_zoom, 'out'
        '=': atv_zoom, 'in'
        '+': atv_zoom, 'in'
        '!': begin  
            atv_setwindow, state.draw_window_id
            blink_image1 = tvrd(true = true) 
            atv_resetwindow
        end
        '@': begin  
            atv_setwindow, state.draw_window_id
            blink_image2 = tvrd(true = true) 
            atv_resetwindow
        end
        '#': begin  
            atv_setwindow, state.draw_window_id
            blink_image3 = tvrd(true = true) 
            atv_resetwindow
        end
        'q': if (state.activator EQ 0) then atv_shutdown $
        else state.activator = 0
        'Q': if (state.activator EQ 0) then atv_shutdown $
        else state.activator = 0


        else:                   ;any other key press does nothing
    endcase
 
endif

; Starting with IDL 6.0, can generate events on arrow keys:
if (event.type EQ 6) then begin
    case event.key of
        5: atv_move_cursor, '4'
        6: atv_move_cursor, '6'
        7: atv_move_cursor, '8'
        8: atv_move_cursor, '2'
        else:
    endcase
endif 
   
if (xregistered('atv', /noshow)) then $
  widget_control, state.draw_widget_id, /sensitive, /input_focus

end

;-------------------------------------------------------------------

pro atv_activate

; This routine is a workaround to use when you hit an error message or
; a "stop" command in another program while running atv.  If you want
; atv to become active again without typing "retall" and losing your
; current session variables, type "atv_activate" to temporarily
; activate atv again.  This will de-activate the command line but
; allow atv to be used until you hit "q" in atv or kill the atv
; window. 

; Also, if you need to call atv from a command-line idl program and
; have that program wait until you're done looking at an image in atv
; before moving on to its next step, you can call atv_activate after
; sending your image to atv.  This will make your external program
; stop until you quit out of atv_activate mode.

common atv_state

if (not(xregistered('atv', /noshow))) then begin
    print, 'No ATV window currently exists.'
    return
endif

state.activator = 1
activator = 1

while (activator EQ 1) do begin

    wait, 0.01
    void = widget_event(/nowait)
    
; If atv is killed by the window manager, then by the time we get here
; the state structure has already been destroyed by atv_shutdown.
    if (size(state, /type) NE 8) then begin
        activator = 0
    endif else begin
        activator = state.activator
    endelse
    
endwhile

widget_control, /hourglass

end

;-------------------------------------------------------------------

pro atv_changemode

; Use 'm' keypress to cycle through mouse modes

common atv_state

case state.mousemode of
    'color': begin
        state.mousemode = 'zoom'
        widget_control, state.mode_droplist_id, set_droplist_select=1
    end
    'zoom': begin
        state.mousemode = 'blink'
        widget_control, state.mode_droplist_id, set_droplist_select=2
    end
    'blink': begin
        state.mousemode = 'imexam'
        widget_control, state.mode_droplist_id, set_droplist_select=3
    end
    'imexam': begin
        state.mousemode = 'vector'
        widget_control, state.mode_droplist_id, set_droplist_select=4
    end
    'vector': begin
        state.mousemode = 'color'
        widget_control, state.mode_droplist_id, set_droplist_select=0
    end
endcase


end

;------------------------------------------------------------------

pro atv_draw_zoom_event, event

; Event handler for zoom mode

common atv_state
 
if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin 
    case event.press of
        1: atv_zoom, 'in', /recenter
        2: atv_zoom, 'none', /recenter
        4: atv_zoom, 'out', /recenter
    endcase
endif

if (event.type EQ 2) then atv_draw_motion_event, event

if (xregistered('atv', /noshow)) then $
  widget_control, state.draw_widget_id, /sensitive, /input_focus

end

;---------------------------------------------------------------------

pro atv_draw_blink_event, event

; Event handler for blink mode

common atv_state
common atv_images

if (!d.name NE state.graphicsdevice) then return
if (state.bitdepth EQ 24) then true = 1 else true = 0

case event.type of
    0: begin                    ; button press
        atv_setwindow, state.draw_window_id
                                ; define the unblink image if needed
        if ((state.newrefresh EQ 1) AND (state.blinks EQ 0)) then begin
            unblink_image = tvrd(true = true)
            state.newrefresh = 0
        endif
        
        case event.press of
            1: if n_elements(blink_image1) GT 1 then $
              tv, blink_image1, true = true
            2: if n_elements(blink_image2) GT 1 then $
              tv, blink_image2, true = true
            4: if n_elements(blink_image3) GT 1 then $
              tv, blink_image3, true = true  
            else: event.press = 0 ; in case of errors
        endcase
        state.blinks = (state.blinks + event.press) < 7
    end
    
    1: begin                    ; button release
        if (n_elements(unblink_image) EQ 0) then return ; just in case
        atv_setwindow, state.draw_window_id
        state.blinks = (state.blinks - event.release) > 0
        case state.blinks of
            0: tv, unblink_image, true = true
            1: if n_elements(blink_image1) GT 1 then $
              tv, blink_image1, true = true else $
              tv, unblink_image, true = true
            2: if n_elements(blink_image2) GT 1 then $
              tv, blink_image2, true = true else $
              tv, unblink_image, true = true
            3: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1, true = true
            endif else if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2, true = true
            endif else begin
                tv, unblink_image, true = true
            endelse
            4: if n_elements(blink_image3) GT 1 then $
              tv, blink_image3, true = true $
            else tv, unblink_image, true = true
            5: if n_elements(blink_image1) GT 1 then begin
                tv, blink_image1, true = true 
            endif else if n_elements(blink_image3) GT 1 then begin
                tv, blink_image3, true = true
            endif else begin
                tv, unblink_image, true = true
            endelse 
            6: if n_elements(blink_image2) GT 1 then begin
                tv, blink_image2, true = true
            endif else if n_elements(blink_image4) GT 1 then begin
                tv, blink_image4, true = true
            endif else begin
                tv, unblink_image, true = true
            endelse
            else: begin         ; check for errors
                state.blinks = 0
                tv, unblink_image, true = true
            end
        endcase
    end
    2: atv_draw_motion_event, event ; motion event
endcase

widget_control, state.draw_widget_id, /sensitive, /input_focus
atv_resetwindow

end

;-------------------------------------------------------------------

pro atv_draw_phot_event, event

; Event handler for ImExam mode

common atv_state
common atv_images

if (!d.name NE state.graphicsdevice) then return

if (event.type EQ 0) then begin
    case event.press of
        1: atv_apphot
        2: atv_zoom, 'none', /recenter
        4: atv_showstats
        else: 
    endcase
endif

if (event.type EQ 2) then atv_draw_motion_event, event

widget_control, state.draw_widget_id, /sensitive, /input_focus


end

;--------------------------------------------------------------------

pro atv_draw_motion_event, event

; Event handler for motion events in draw window

common atv_state

if (!d.name NE state.graphicsdevice) then return

tmp_event = [event.x, event.y]            
state.coord = $
  round( (0.5 >  ((tmp_event / state.zoom_factor) + state.offset) $
          < (state.image_size - 0.5) ) - 0.5)
atv_gettrack

widget_control, state.draw_widget_id, /sensitive, /input_focus

;if atv_pixtable on, then create a 5x5 array of pixel values and the 
;X & Y location strings that are fed to the pixel table 

if (xregistered('atv_pixtable', /noshow)) then atv_pixtable_update

end

;----------------------------------------------------------------------

pro atv_draw_vector_event, event

; Check for left button press/depress, then get coords at point 1 and 
; point 2.  Call atv_lineplot.  Calculate vector distance between
; endpoints and plot Vector Distance vs. Pixel Value with atv_vectorplot

common atv_state
common atv_images

if (!d.name NE state.graphicsdevice) then return

;atv_setwindow, state.draw_window_id

case event.type of
   0: begin                     ; button press
      if ((event.press EQ 1) AND (state.vectorpress EQ 0)) then begin          
         ; left button press
         state.vector_coord1[0] = state.coord[0]
         state.vector_coord1[1] = state.coord[1]
         state.vectorstart = [event.x, event.y]
         atv_drawvector, event
         state.vectorpress = 1
      endif
      if ((event.press EQ 2) AND (state.vectorpress EQ 0)) then begin          
         ; left button press
         state.vector_coord1[0] = state.coord[0]
         state.vector_coord1[1] = state.coord[1]
         state.vectorstart = [event.x, event.y]
         atv_drawvector, event
         state.vectorpress = 2
      endif
      if ((event.press EQ 4) AND (state.vectorpress EQ 0)) then begin 
         ; right button press
         state.vector_coord1[0] = state.coord[0]
         state.vector_coord1[1] = state.coord[1]
         state.vectorstart = [event.x, event.y]
         atv_drawdepth, event
         state.vectorpress = 4
      endif
   end
   1: begin                     ; button release
      if ((event.release EQ 1) AND (state.vectorpress EQ 1)) then begin 
         ; left button release
         state.vectorpress = 0
         state.vector_coord2[0] = state.coord[0]
         state.vector_coord2[1] = state.coord[1]
         atv_drawvector, event
         atv_vectorplot, /newcoord
      endif
      if ((event.release EQ 2) AND (state.vectorpress EQ 2)) then begin 
         ; left button release
         state.vectorpress = 0
         state.vector_coord2[0] = state.coord[0]
         state.vector_coord2[1] = state.coord[1]
         atv_drawvector, event
         atv_gaussfit, /newcoord
      endif
      if ((event.release EQ 4) AND (state.vectorpress EQ 4)) then begin
         ; right button release
         state.vectorpress = 0
         state.vector_coord2[0] = state.coord[0]
         state.vector_coord2[1] = state.coord[1]
         atv_drawdepth, event
         atv_depthplot, /newcoord
      endif

   end
   2: begin                     ; motion event
      atv_draw_motion_event, event 
      if (state.vectorpress EQ 1) then atv_drawvector, event
      if (state.vectorpress EQ 2) then atv_drawvector, event
      if (state.vectorpress EQ 4) then atv_drawdepth, event
   end
   
   

   else:
endcase

widget_control, state.draw_widget_id, /sensitive, /input_focus

end

;----------------------------------------------------------------------

pro atv_drawvector, event

common atv_state

; button press: create initial pixmap and start drawing vector
if (event.type EQ 0) then begin
    window, /free, xsize = state.draw_window_size[0], $
      ysize = state.draw_window_size[1], /pixmap
    state.vector_pixmap_id = !d.window
    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.draw_window_id]
    atv_resetwindow
endif

; button release: redisplay initial image
if (event.type EQ 1) then begin
    atv_setwindow, state.draw_window_id
    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
    atv_resetwindow
    wdelete, state.vector_pixmap_id
endif

; motion event: redraw with new vector    
if (event.type EQ 2) then begin
    atv_setwindow, state.draw_window_id

    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
    xvector = [state.vectorstart[0], event.x]
    yvector = [state.vectorstart[1], event.y]

    cgplots, xvector, yvector, /device, color = state.box_color

    atv_resetwindow
endif


end

;----------------------------------------------------------------------

pro atv_drawdepth, event

; draw the box showing the region selected for a depth plot

common atv_state


; button press: create initial pixmap and start drawing vector
if (event.type EQ 0) then begin
    window, /free, xsize = state.draw_window_size[0], $
      ysize = state.draw_window_size[1], /pixmap
    state.vector_pixmap_id = !d.window
    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.draw_window_id]
    atv_resetwindow
endif

; button release: redisplay initial image
if (event.type EQ 1) then begin
    atv_setwindow, state.draw_window_id
    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
    atv_resetwindow
    wdelete, state.vector_pixmap_id
endif

; motion event: redraw with new vector    
if (event.type EQ 2) then begin

    atv_setwindow, state.draw_window_id

    device, copy=[0, 0, state.draw_window_size[0], $
                  state.draw_window_size[1], 0, 0, state.vector_pixmap_id]
    xvector = [state.vectorstart[0], state.vectorstart[0], $
               event.x, event.x, state.vectorstart[0]]
    yvector = [state.vectorstart[1], event.y, event.y, $
              state.vectorstart[1], state.vectorstart[1]]

    cgplots, xvector, yvector, /device, color = state.box_color

    atv_resetwindow
endif


end

;----------------------------------------------------------------------

pro atv_pan_event, event

; event procedure for moving the box around in the pan window

common atv_state

if (!d.name NE state.graphicsdevice) then return

case event.type of
    0: begin                     ; button press
        widget_control, state.pan_widget_id, draw_motion_events = 1
        atv_pantrack, event
    end
    1: begin                     ; button release
        widget_control, state.pan_widget_id, draw_motion_events = 0
        widget_control, state.pan_widget_id, /clear_events
        atv_pantrack, event
        atv_refresh, /panfast
    end
    2: begin
        atv_pantrack, event     ; motion event
        widget_control, state.pan_widget_id, /clear_events
    end
    else:
endcase

end

;--------------------------------------------------------------------

pro atv_event, event

; Main event loop for atv top-level base, and for all the buttons.

common atv_state
common atv_images
common atv_color
common atv_pdata


widget_control, event.id, get_uvalue = uvalue

if (!d.name NE state.graphicsdevice and uvalue NE 'done') then return

; Get currently active window
atv_getwindow

case uvalue of

    'atv_base': begin     
        c = where(tag_names(event) EQ 'ENTER', count)
        if (count EQ 0) then begin       ; resize event
            atv_resize
            atv_refresh
        endif
    end

    'mode': case event.index of
        0: state.mousemode = 'color'
        1: state.mousemode = 'zoom'
        2: state.mousemode = 'blink'
        3: state.mousemode = 'imexam'
        4: state.mousemode = 'vector'
        else: print, 'Unknown mouse mode!'
    endcase

    'invert': begin                  ; invert the color table
        state.invert_colormap = abs(state.invert_colormap - 1)

        r_vector = reverse(r_vector)
        g_vector = reverse(g_vector)
        b_vector = reverse(b_vector)

        atv_setwindow, state.draw_window_id
        atv_stretchct
        atv_resetwindow

; For 24-bit color, need to refresh display after stretching color
; map.  Can refresh in /fast mode if there are no overplots
        if (state.bitdepth EQ 24) then begin
            if (n_elements(atvplotlist) GT 0) then begin
                atv_refresh
            endif else begin
                atv_refresh, /fast
            endelse
        endif
    end
    
    'restretch_button': atv_restretch

    'min_text': begin     ; text entry in 'min = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'max_text': begin     ; text entry in 'max = ' box
        atv_get_minmax, uvalue, event.value
        atv_displayall
    end

    'autoscale_button': begin   ; autoscale the image
        atv_autoscale
        atv_displayall
    end

    'full_range': begin    ; display the full intensity range
        state.min_value = state.image_min
        state.max_value = state.image_max
        if state.min_value GE state.max_value then begin
            state.min_value = state.max_value - 1
            state.max_value = state.max_value + 1
        endif
        atv_set_minmax
        atv_displayall
    end
    
    'zoom_in':  atv_zoom, 'in'         ; zoom buttons
    'zoom_out': atv_zoom, 'out'
    'zoom_one': atv_zoom, 'one'

    'center': begin   ; center image and preserve current zoom level
        state.centerpix = round(state.image_size / 2.)
        atv_refresh
    end

    'fullview': atv_fullview

;    'sliceselect': atv_setslice, event

    'done':  if (state.activator EQ 0) then atv_shutdown $
      else state.activator = 0

    else:  print, 'No match for uvalue....'  ; bad news if this happens

endcase
end

;----------------------------------------------------------------------

pro atv_message, msg_txt, msgtype=msgtype, window=window

; Routine to display an error or warning message.  Message can be
; displayed either to the IDL command line or to a popup window,
; depending on whether /window is set.
; msgtype must be 'warning', 'error', or 'information'.

common atv_state

if (n_elements(window) EQ 0) then window = 0

if (window EQ 1) then begin  ; print message to popup window
    case msgtype of
        'warning': t = dialog_message(msg_txt, dialog_parent = state.base_id)
        'error': t = $
          dialog_message(msg_txt,/error,dialog_parent=state.base_id)
        'information': t = $
          dialog_message(msg_txt,/information,dialog_parent=state.base_id)
        else: 
    endcase
endif else begin           ;  print message to IDL console
    message = strcompress(strupcase(msgtype) + ': ' + msg_txt)
    print, message
endelse

end

;-----------------------------------------------------------------------
;      main atv routines for scaling, displaying, cursor tracking...
;-----------------------------------------------------------------------

pro atv_displayall, newslice=newslice

; Call the routines to scale the image, make the pan image, and
; re-display everything.  Use this if the scaling changes (log/
; linear/ histeq), or if min or max are changed, or if a new image or
; image slice is passed to atv.  If the display image has just been
; moved around or zoomed without a change in scaling, then just call
; atv_refresh rather than this routine.

; the /newslice option cuts down on flickering in the pan window when
; selecting a new data cube slice from the slicer widget slider

atv_scaleimage
atv_makepan
if (keyword_set(newslice)) then begin
   atv_refresh, /panfast
endif else begin
   atv_refresh
endelse

end

;---------------------------------------------------------------------

pro atv_refresh, fast = fast, panfast = panfast

; Make the display image from the scaled_image, and redisplay the pan
; image and tracking image. 
; The /fast option skips the steps where the display_image is
; recalculated from the main_image.  The /fast option is used in 24
; bit color mode, when the color map has been stretched but everything
; else stays the same.
; The /panfast option means to calculate and display a new
; display_image, but keep the pan_image the same except for the
; location of the green box.

common atv_state
common atv_images

atv_getwindow
if (not(keyword_set(fast))) then begin
    atv_getoffset
    atv_getdisplay
    atv_displaymain
    atv_plotall
endif else begin
    atv_displaymain
endelse

; now redo the pan window as needed

atv_setwindow, state.pan_pixmap
erase
cgimage, pan_image, state.pan_offset[0], state.pan_offset[1], /tv, $
         background = 'black'
atv_panoplot
atv_resetwindow


; redisplay the pan image 

atv_setwindow, state.pan_window_id

if not(keyword_set(fast) OR keyword_set(panfast)) then begin
   cgimage, pan_image, state.pan_offset[0], state.pan_offset[1], /tv, $
            background = 'black'
endif

atv_panoplot
atv_resetwindow

; save the pixmap again with no box
atv_setwindow, state.pan_pixmap
erase
cgimage, pan_image, state.pan_offset[0], state.pan_offset[1], /tv, $
         background = 'black'
atv_panoplot, /nobox
atv_resetwindow

if (state.bitdepth EQ 24) then atv_colorbar
   
; redisplay the tracking image
if (not(keyword_set(fast))) then atv_gettrack
   
atv_resetwindow

state.newrefresh = 1


end

;--------------------------------------------------------------------

pro atv_getdisplay

; make the display image from the scaled image by applying the zoom
; factor and matching to the size of the draw window, and display the
; image.

common atv_state
common atv_images

widget_control, /hourglass   

display_image = bytarr(state.draw_window_size[0], state.draw_window_size[1])

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
view_max = round(view_min + state.draw_window_size / state.zoom_factor)

view_min = (0 > view_min < (state.image_size - 1)) 
view_max = (0 > view_max < (state.image_size - 1)) 

newsize = round( (view_max - view_min + 1) * state.zoom_factor) > 1
startpos = abs( round(state.offset * state.zoom_factor) < 0)

; Use interp & center keywords to congrid for zoomfactor < 1 :
; improvement contributed by N. Cunningham, added 4/14/06
if (state.zoom_factor LT 1.0) then begin
    tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
                                   view_min[1]:view_max[1]], $
                      newsize[0], newsize[1], /center, /interp)
endif else begin
    tmp_image = congrid(scaled_image[view_min[0]:view_max[0], $
                                     view_min[1]:view_max[1]], $
                        newsize[0], newsize[1])
endelse


xmax = newsize[0] < (state.draw_window_size[0] - startpos[0])
ymax = newsize[1] < (state.draw_window_size[1] - startpos[1])

display_image[startpos[0], startpos[1]] = tmp_image[0:xmax-1, 0:ymax-1]
tmp_image = 0

end

;-----------------------------------------------------------------------

pro atv_displaymain

; Display the main image and overplots

common atv_state
common atv_images

atv_setwindow, state.draw_window_id
cgimage, display_image, /tv, /noerase
atv_resetwindow

end

;--------------------------------------------------------------------

pro atv_getoffset
common atv_state

; Routine to calculate the display offset for the current value of
; state.centerpix, which is the central pixel in the display window.

state.offset = $
  round( state.centerpix - $
         (0.5 * state.draw_window_size / state.zoom_factor) )

end

;----------------------------------------------------------------------


pro atv_makepan

; Make the 'pan' image that shows a miniature version of the full image.

common atv_state
common atv_images

sizeratio = state.image_size[1] / state.image_size[0]

if (sizeratio GE 1) then begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[1])
endif else begin
    state.pan_scale = float(state.pan_window_size) / float(state.image_size[0])
endelse

tmp_image = $
  scaled_image[0:state.image_size[0]-1, 0:state.image_size[1]-1]

if (max(state.image_size) LT state.pan_window_size) then $
   i = 0 else i = 1

pan_image = $
  congrid(tmp_image, round(state.pan_scale * state.image_size[0])>2, $
          round(state.pan_scale * state.image_size[1])>2, $
         /center, interp=i)

state.pan_offset[0] = round((state.pan_window_size - (size(pan_image))[1]) / 2)
state.pan_offset[1] = round((state.pan_window_size - (size(pan_image))[2]) / 2)


end

;----------------------------------------------------------------------


pro atv_move_cursor, direction

; Use keypad arrow keys to step cursor one pixel at a time.
; Get the new track image, and update the cursor position.

common atv_state

i = 1L

case direction of
    '2': state.coord[1] = max([state.coord[1] - i, 0])
    '4': state.coord[0] = max([state.coord[0] - i, 0])
    '8': state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
    '6': state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    '7': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = max([state.coord[0] - i, 0])
    end
    '9': begin
        state.coord[1] = min([state.coord[1] + i, state.image_size[1] - i])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '3': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = min([state.coord[0] + i, state.image_size[0] - i])
    end
    '1': begin
        state.coord[1] = max([state.coord[1] - i, 0])
        state.coord[0] = max([state.coord[0] - i, 0])
    end

endcase

newpos = (state.coord - state.offset + 0.5) * state.zoom_factor

atv_setwindow,  state.draw_window_id
tvcrs, newpos[0], newpos[1], /device
atv_resetwindow

atv_gettrack

; If pixel table widget is open, update pixel values and cursor position
if (xregistered('atv_pixtable', /noshow)) then atv_pixtable_update


; Prevent the cursor move from causing a mouse event in the draw window
widget_control, state.draw_widget_id, /clear_events

atv_resetwindow

end

;----------------------------------------------------------------------

pro atv_set_minmax

; Updates the min and max text boxes with new values.

common atv_state

widget_control, state.min_text_id, set_value = string(state.min_value)
widget_control, state.max_text_id, set_value = string(state.max_value)

end

;----------------------------------------------------------------------

pro atv_get_minmax, uvalue, newvalue

; Change the min and max state variables when user inputs new numbers
; in the text boxes. 

common atv_state

case uvalue of
    
    'min_text': begin
        if (newvalue LT state.max_value) then begin
            state.min_value = newvalue
        endif
    end

    'max_text': begin
        if (newvalue GT state.min_value) then begin
            state.max_value = newvalue
        endif
    end
        
endcase

atv_set_minmax

end

;--------------------------------------------------------------------

pro atv_zoom, zchange, recenter = recenter
common atv_state

; Routine to do zoom in/out and recentering of image.  The /recenter
; option sets the new display center to the current cursor position.

case zchange of
    'in':    state.zoom_level = (state.zoom_level + 1) < 6
    'out':   begin
        sizeratio = fix(min(state.image_size) / 16.) > 1
        minzoom = -1.*fix(alog(sizeratio)/alog(2.0))
        state.zoom_level = (state.zoom_level - 1) > minzoom
    end
    'onesixteenth': state.zoom_level =  -4
    'oneeighth': state.zoom_level =  -3
    'onefourth': state.zoom_level =  -2
    'onehalf': state.zoom_level =  -1
    'two':   state.zoom_level =  1
    'four':  state.zoom_level =  2
    'eight': state.zoom_level =  3
    'sixteen': state.zoom_level = 4
    'one':   state.zoom_level =  0
    'none':  ; no change to zoom level: recenter on current mouse position
    else:  print,  'problem in atv_zoom!'
endcase

state.zoom_factor = (2.0)^(state.zoom_level)

if (n_elements(recenter) GT 0) then begin
    state.centerpix = state.coord
    atv_getoffset
endif

atv_refresh, /panfast


if (n_elements(recenter) GT 0) then begin
    newpos = (state.coord - state.offset + 0.5) * state.zoom_factor
    atv_setwindow,  state.draw_window_id
    tvcrs, newpos[0], newpos[1], /device 
    atv_resetwindow
    atv_gettrack
endif

atv_resetwindow

end

;-----------------------------------------------------------------------

pro atv_fullview
common atv_state

; set the zoom level so that the full image fits in the display window

sizeratio = float(state.image_size) / float(state.draw_window_size)
maxratio = (max(sizeratio)) 

state.zoom_level = floor((alog(maxratio) / alog(2.0)) * (-1))
state.zoom_factor = (2.0)^(state.zoom_level)

; recenter
state.centerpix = round(state.image_size / 2.)

atv_refresh

atv_resetwindow

end

;----------------------------------------------------------------------

pro atv_invert, ichange
common atv_state
common atv_images

; Routine to do image axis-inversion (X,Y,X&Y)

case ichange of
    'x': begin
        if ptr_valid(state.astr_ptr) then begin
            hreverse, main_image, *(state.head_ptr), $
              main_image, *(state.head_ptr), 1, /silent
            head = *(state.head_ptr)
            atv_setheader, head
        endif else begin
            main_image = reverse(main_image,1)
        endelse
    end
    
    'y': begin
        if ptr_valid(state.astr_ptr) then begin
            hreverse, main_image, *(state.head_ptr), $
              main_image, *(state.head_ptr), 2, /silent
            head = *(state.head_ptr)
            atv_setheader, head
        endif else begin
            main_image = reverse(main_image,2)
        endelse
    end
    
    
    'xy': begin
        
        if ptr_valid(state.astr_ptr) then begin
            hreverse, main_image, *(state.head_ptr), $
              main_image, *(state.head_ptr), 1, /silent
            hreverse, main_image, *(state.head_ptr), $
              main_image, *(state.head_ptr), 2, /silent
            head = *(state.head_ptr)
            atv_setheader, head
        endif else begin
            main_image = reverse(main_image,1)
            main_image = reverse(main_image,2)
        endelse
    end
    
    else:  print,  'problem in atv_invert!'
endcase

atv_getstats, /align, /noerase

;Redisplay inverted image with current zoom, update pan, and refresh image
atv_displayall

;make sure that the image arrays are updated for line/column plots, etc.
atv_resetwindow

end

;------------------------------------------------------------------

pro atv_rotate, rchange, get_angle=get_angle
common atv_state
common atv_images

; Routine to do image rotation

; If /get_angle set, create widget to enter rotation angle

widget_control, /hourglass

if (keyword_set(get_angle)) then begin

  formdesc = ['0, float,, label_left=Rotation Angle: ', $
              '1, base, , row', $
              '0, button, Cancel, quit', $
              '0, button, Rotate, quit']    

  textform = cw_form(formdesc, /column, title = 'Rotate')

  if (textform.tag2 EQ 1) then return
  if (textform.tag3 EQ 1) then rchange = textform.tag0

endif

if (not(keyword_set(get_angle)) OR (rchange EQ '90') or $
   (rchange EQ '180') OR (rchange EQ '270') $
   OR (rchange EQ '0')) then begin
    case rchange of
        '0':                    ; do nothing
        
        '90': begin 
            if ptr_valid(state.astr_ptr) then begin
                hrotate, main_image, *(state.head_ptr), $
                  main_image, *(state.head_ptr), 3
            endif else begin
                main_image = rotate(main_image, 3)
            endelse
        end
        '180': begin
            if ptr_valid(state.astr_ptr) then begin
                hrotate, main_image, *(state.head_ptr), $
                  main_image, *(state.head_ptr), 2
            endif else begin
                main_image = rotate(main_image, 2)
            endelse
        end
        '270': begin    
            if ptr_valid(state.astr_ptr) then begin
                hrotate, main_image, *(state.head_ptr), $
                  main_image, *(state.head_ptr), 1
            endif else begin
                main_image = rotate(main_image, 1)
            endelse
        end
    endcase
    
endif else begin
; arbitrary rotation angle
    rchange = float(rchange)
    if ptr_valid(state.astr_ptr) then begin
        hrot, main_image, *(state.head_ptr), $
          main_image, *(state.head_ptr), rchange, -1, -1, 2, $
          cubic=-0.5, missing=0
    endif else begin
        main_image = rot(main_image, rchange, $
                         cubic=-0.5, missing=0)
    endelse
    
endelse

;Update header information after rotation if header is present
if ptr_valid(state.head_ptr) then begin
  head = *(state.head_ptr)
  atv_setheader, head
endif

atv_getstats, /align, /noerase

;Redisplay image with current zoom, update pan, and refresh image
atv_displayall

;make sure that the image arrays are updated for line/column plots, etc.
atv_resetwindow

end

;------------------------------------------------------------------

pro atv_autoscale

; Routine to auto-scale the image.  

common atv_state 
common atv_images

widget_control, /hourglass

state.min_value = state.skymode - (2.0*state.skysig) > state.image_min
if (state.scaling LE 1) then begin
    case state.scaling of
        0: highval = 2.0
        1: highval = 4.0
    endcase
    state.max_value = state.skymode + (highval*stddev(main_image)) $
      < state.image_max
endif else begin
    state.max_value = state.image_max
endelse

if (finite(state.min_value) EQ 0) then state.min_value = state.image_min
if (finite(state.max_value) EQ 0) then state.max_value = state.image_max

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

state.asinh_beta = state.skysig

atv_set_minmax

end  

;--------------------------------------------------------------------

pro atv_restretch

; Routine to restretch the min and max to preserve the display
; visually but use the full color map linearly.  Written by DF, and
; tweaked and debugged by AJB.  It doesn't always work exactly the way
; you expect (especially in log-scaling mode), but mostly it works fine.

common atv_state

sx = state.brightness
sy = state.contrast

if (state.scaling EQ 2) then return ; do nothing for hist-eq mode

if (state.scaling EQ 0) then begin
    sfac = (state.max_value-state.min_value)
    state.max_value = sfac*(sx+sy)+state.min_value
    state.min_value = sfac*(sx-sy)+state.min_value
endif

if (state.scaling EQ 1) then begin

    offset = state.min_value - $
      (state.max_value - state.min_value) * 0.01

    sfac = alog10((state.max_value - offset) / (state.min_value - offset))
    state.max_value = 10.^(sfac*(sx+sy)+alog10(state.min_value - offset)) $
      + offset
    state.min_value = 10.^(sfac*(sx-sy)+alog10(state.min_value - offset)) $
      + offset
    
endif


; Try different behavior in asinh mode: usually want to keep the min
; value the same and just adjust the max value.  Seems to work ok.
if (state.scaling EQ 3) then begin
    sfac = asinh(state.max_value / state.asinh_beta) - $
      asinh(state.min_value / state.asinh_beta)

    state.max_value = sinh(sfac*(sx+sy) + $
          asinh(state.min_value/state.asinh_beta))*state.asinh_beta 
endif

; do this differently for 8 or 24 bit color, to prevent flashing
atv_setwindow, state.draw_window_id
if (state.bitdepth EQ 8) then begin
    atv_set_minmax
    atv_displayall
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    atv_stretchct
endif else begin
    state.brightness = 0.5      ; reset these
    state.contrast = 0.5
    atv_stretchct
    atv_set_minmax
    atv_displayall
endelse
atv_resetwindow

end

;---------------------------------------------------------------------

function atv_wcsstring, lon, lat, ctype, equinox, disp_type, disp_equinox, $
            disp_base60

common atv_state

; Routine to return a string which displays cursor coordinates.
; Allows choice of various coordinate systems.
; Contributed by D. Finkbeiner, April 2000.
; 29 Sep 2000 - added degree (RA,dec) option DPF
; Apr 2007: AJB added additional error checking to prevent crashes

; ctype - coord system in header
; disp_type - type of coords to display

headtype = strmid(ctype[0], 0, 4)

; need numerical equinox values
IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
  IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
  num_equinox = float(equinox)

IF (disp_equinox EQ 'J2000') THEN num_disp_equinox = 2000.0 ELSE $
  IF (disp_equinox EQ 'B1950') THEN num_disp_equinox = 1950.0 ELSE $
  num_disp_equinox = float(equinox)

; first convert lon,lat to RA,dec (J2000)
CASE headtype OF 
    'GLON': euler, lon, lat, ra, dec, 2 ; J2000
    'ELON': BEGIN 
        euler, lon, lat, ra, dec, 4 ; J2000
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
    'RA--': BEGIN    
        ra = lon
        dec = lat
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END 
    'DEC-': BEGIN       ; for SDSS images
        ra = lon
        dec = lat
        IF num_equinox NE 2000.0 THEN precess, ra, dec, num_equinox, 2000.0
    END
    else: begin
        wcsstring = '---No WCS Info---'
        widget_control, state.wcs_bar_id, set_value = wcsstring
        state.wcstype = 'none'
        return, wcsstring
    end
ENDCASE  

; Now convert RA,dec (J2000) to desired display coordinates:  

IF (disp_type[0] EQ 'RA--' or disp_type[0] EQ 'DEC-') THEN BEGIN 
; generate (RA,dec) string 
   disp_ra  = ra
   disp_dec = dec
   IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
     2000.0, num_disp_equinox

   IF disp_base60 THEN BEGIN ; (hh:mm:ss) format
      
      neg_dec  = disp_dec LT 0
      radec, disp_ra, abs(disp_dec), ihr, imin, xsec, ideg, imn, xsc
      wcsstring = string(ihr, imin, xsec, ideg, imn, xsc, disp_equinox, $
         format = '(i2.2,":",i2.2,":",f6.3,"   ",i2.2,":",i2.2,":",f5.2," ",a6)' )
      if (strmid(wcsstring, 6, 1) EQ ' ') then $
        strput, wcsstring, '0', 6
      if (strmid(wcsstring, 21, 1) EQ ' ') then $
        strput, wcsstring, '0', 21
      IF neg_dec THEN strput, wcsstring, '-', 14

   ENDIF ELSE BEGIN ; decimal degree format

      wcsstring = string(disp_ra, disp_dec, disp_equinox, $
                         format='("Deg ",F9.5,",",F9.5,a6)')
   ENDELSE 
ENDIF 
     

IF disp_type[0] EQ 'GLON' THEN BEGIN ; generate (l,b) string
    euler, ra, dec, l, b, 1
    
    wcsstring = string(l, b, format='("Galactic (",F9.5,",",F9.5,")")')
ENDIF 

IF disp_type[0] EQ 'ELON' THEN BEGIN ; generate (l,b) string
    
    disp_ra = ra
    disp_dec = dec
    IF num_disp_equinox NE 2000.0 THEN precess, disp_ra, disp_dec, $
      2000.0, num_disp_equinox
    euler, disp_ra, disp_dec, lam, bet, 3
    
    wcsstring = string(lam, bet, format='("Ecliptic (",F9.5,",",F9.5,")")')
ENDIF 

return, wcsstring
END

;----------------------------------------------------------------------

function atv_wavestring

; function to return string with wavelength info for spectral images.
; Currently works for HST STIS 2-d images.

common atv_state

cd = float(sxpar(*state.head_ptr,'CD1_1', /silent))
if (cd EQ 0.0) then $
   cd = float(sxpar(*state.head_ptr,'CDELT1', /silent))
crpix = float(sxpar(*state.head_ptr,'CRPIX1', /silent)) - 1
crval = float(sxpar(*state.head_ptr,'CRVAL1', /silent))
shifta = float(sxpar(*state.head_ptr, 'SHIFTA1', /silent))

if ((state.cube EQ 1) AND (state.osiriscube EQ 1)) then begin
   wavelength = crval + ((state.slice - crpix) * cd)
endif else begin
   wavelength = crval + ((state.coord[0] - crpix) * cd) + (shifta * cd)
endelse

wstring = string(wavelength, format='(F8.2)')

wavestring = strcompress('Wavelength:  ' + wstring + ' ' + state.cunit)
 
   

return, wavestring

end

;--------------------------------------------------------------------


pro atv_gettrack

; Create the image to display in the track window that tracks
; cursor movements.  Also update the coordinate display and the
; (x,y) and pixel value.

common atv_state
common atv_images

; Get x and y for center of track window

zcenter = (0 > state.coord < state.image_size)

track = bytarr(11,11)
boxsize=5
xmin = 0 > (zcenter[0] - boxsize)
xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
ymin = 0 > (zcenter[1] - boxsize) 
ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

startx = abs( (zcenter[0] - boxsize) < 0 )
starty = abs( (zcenter[1] - boxsize) < 0 ) 

track[startx,starty] = scaled_image[xmin:xmax,ymin:ymax]
track_image = rebin(track, $
                    state.track_window_size, state.track_window_size, $
                    /sample)

atv_setwindow, state.track_window_id
cgimage, track_image, /tv, /noerase

; Overplot an X on the central pixel in the track window, to show the
; current mouse position
cgplots, [0.46, 0.54], [0.46, 0.54], /normal, color = state.box_color, psym=0
cgplots, [0.46, 0.54], [0.54, 0.46], /normal, color = state.box_color, psym=0

; update location bar with x, y, and pixel value

loc_string = $
  string(state.coord[0], $
         state.coord[1], $
         main_image[state.coord[0], $
                    state.coord[1]], $
         format = '("(",i5,",",i5,") ",g12.5)') 

widget_control, state.location_bar_id, set_value = loc_string

; Update coordinate display. 

if (state.wcstype EQ 'angle') then begin
    xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat

    wcsstring = atv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
                              state.equinox, state.display_coord_sys, $
                              state.display_equinox, state.display_base60)

    widget_control, state.wcs_bar_id, set_value = wcsstring

endif    

if (state.wcstype EQ 'lambda') then begin
    wavestring = atv_wavestring()
    widget_control, state.wcs_bar_id, set_value = wavestring
endif

atv_resetwindow

end


;----------------------------------------------------------------------

pro atv_panoplot, nobox = nobox

; Routine to add overplots to the pan window or pan pixmap.  
; A replacement for the old atv_drawbox.  Now, has an option to not
; draw the box (will still draw the weathervane).  Also, does not set
; the window, so this draws to the current window, and the calling
; routine must set the window.  This can either be the pan window or
; the pan_pixmap window

common atv_state
common atv_images

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

; Create the vectors which contain the box coordinates

box_x = float((([view_min[0], $
                 view_max[0], $
                 view_max[0], $
                 view_min[0], $
                 view_min[0]]) * state.pan_scale) + state.pan_offset[0]) 

box_y = float((([view_min[1], $
                 view_min[1], $
                 view_max[1], $
                 view_max[1], $
                 view_min[1]]) * state.pan_scale) + state.pan_offset[1]) 

; set limits on box to make sure all sides always appear
box_x = 0 > box_x < (state.pan_window_size - 1)
box_y = 0 > box_y < (state.pan_window_size - 1)

; Redraw the pan image and overplot the box
;if (not(keyword_set(norefresh))) then $
device, copy=[0,0,state.pan_window_size, state.pan_window_size, 0, 0, $
              state.pan_pixmap]

if (not(keyword_set(nobox))) then $
   cgplots, box_x, box_y, /device, color = state.box_color, psym=0

if (ptr_valid(state.astr_ptr) AND state.wcstype EQ 'angle') then begin
   arrows, *(state.head_ptr), 0.5, 0.5, /normal, $
           thick=1, charsize=1.2, arrowlen=2, color=state.panarrow_color
endif

end

;----------------------------------------------------------------------

pro atv_pantrack, event

; routine to track the view box in the pan window during cursor motion

common atv_state

; get the new box coords and draw the new box

tmp_event = [event.x, event.y] 

newpos = state.pan_offset > tmp_event < $
  (state.pan_offset + (state.image_size * state.pan_scale))

state.centerpix = round( (newpos - state.pan_offset ) / state.pan_scale)


atv_setwindow, state.pan_window_id
atv_panoplot
atv_resetwindow
atv_getoffset

end

;----------------------------------------------------------------------

pro atv_resize

; Routine to resize the draw window when a top-level resize event
; occurs.  

common atv_state

widget_control, state.base_id, tlb_get_size=tmp_event

window = (state.base_min_size > tmp_event)

newbase = window - state.base_pad

newxsize = (tmp_event[0] - state.base_pad[0]) > $
  (state.base_min_size[0] - state.base_pad[0]) 
newysize = (tmp_event[1] - state.base_pad[1]) > $
  (state.base_min_size[1] - state.base_pad[1])

widget_control, state.draw_widget_id, $
  scr_xsize = newxsize, scr_ysize = newysize


state.draw_window_size = [newxsize, newysize]

atv_colorbar

widget_control, state.base_id, /clear_events
widget_control, state.draw_base_id, /sensitive, /input_focus


end

;----------------------------------------------------------------------

pro atv_scaleimage

; Create a byte-scaled copy of the image, scaled according to
; the state.scaling parameter.

common atv_state
common atv_images

; Since this can take some time for a big image, set the cursor 
; to an hourglass until control returns to the event loop.
widget_control, /hourglass

scaled_image=0

case state.scaling of
    0: scaled_image = $                 ; linear stretch
      bytscl(main_image, $
             /nan, $
             min=state.min_value, $
             max=state.max_value, $
             top = state.ncolors - 1) 
    
    1: begin                            ; log stretch
        offset = state.min_value - $
          (state.max_value - state.min_value) * 0.01

        scaled_image = $        
          bytscl( alog10(main_image - offset), $
                  min=alog10(state.min_value - offset), /nan, $
                  max=alog10(state.max_value - offset),  $
                  top=state.ncolors - 1)   
    end
    

    2: scaled_image = $                 ; histogram equalization
      bytscl(hist_equal(main_image, $
                        minv = state.min_value, $    
                        maxv = state.max_value), $
             /nan, top = state.ncolors - 1) 
    
    3:  begin                            ; asinh
        scaled_image = bytscl(asinh((main_image - state.min_value) $
                                    / state.asinh_beta), $
                min = 0, $
                max = asinh((state.max_value - state.min_value) / $
                            state.asinh_beta), $
                              /nan, top = state.ncolors - 1) 
    end

endcase

end

;----------------------------------------------------------------------

pro atv_setasinh

; get the asinh beta parameter

common atv_state

b = string(state.asinh_beta)

formline = strcompress('0,float,' + b + $
                       ',label_left=Asinh beta parameter: ,width=10')

formdesc = [formline, $
           '0, button, Set beta, quit', $
           '0, button, Cancel, quit']

textform = cw_form(formdesc, ids=ids, /column, $
                 title = 'atv asinh stretch settings')

if (textform.tag2 EQ 1) then return

state.asinh_beta = float(textform.tag0)

atv_displayall

end

;----------------------------------------------------------------------

pro atv_getstats, align=align, noerase=noerase

; Get basic image stats: min and max, and size.
; set align keyword to preserve alignment of previous image

common atv_state
common atv_images

; this routine operates on main_image, which is in the
; atv_images common block

widget_control, /hourglass

oldimagesize = state.image_size

state.image_size = [ (size(main_image))[1], (size(main_image))[2] ]

if ((oldimagesize[0] NE state.image_size[0]) OR $
    (oldimagesize[1] NE state.image_size[1])) then align = 0

state.image_min = min(main_image, max=maxx, /nan)
state.image_max = maxx

; Get sky value for autoscaling and asinh stretch.  Eliminate
; zero-valued and NaN pixels from sky calculation, i.e. for HST ACS
; drizzled images, WFPC2 mosaics, or Spitzer images.
w = where(finite(main_image) AND (main_image NE 0.0), goodcount)
if (goodcount GT 25) then begin
    sky, main_image[w], skymode, skysig, /silent
endif else if (goodcount GT 5 AND goodcount LE 25) then begin
    skysig = stddev(main_image[w])
    skymode = median(main_image[w])
endif else if (goodcount LE 5) then begin ; really pathological images
    skysig = 1.
    skymode = 0.
endif

; error checking- in case sky.pro returns a zero or negative sigma
if (skysig LE 0.0) then skysig = stddev(main_image)
if (skysig LE 0.0) then skysig = 1.0

state.skymode = skymode
state.skysig = skysig
;state.asinh_beta = state.skysig

if (state.min_value GE state.max_value) then begin
    state.min_value = state.min_value - 1
    state.max_value = state.max_value + 1
endif

; zero the current display position on the center of the image,
; unless user selected /align keyword

state.coord = round(state.image_size / 2.)
IF (NOT keyword_set(align) OR (state.firstimage EQ 1)) THEN $
  state.centerpix = round(state.image_size / 2.)
atv_getoffset

; Clear all plot annotations
if (not(keyword_set(noerase))) then atverase, /norefresh  

end

;-------------------------------------------------------------------

pro atv_setwindow, windowid

; replacement for wset.  Reads the current active window first.
; This should be used when the currently active window is an external
; (i.e. non-atv) idl window.  Use atv_setwindow to set the window to
; one of the atv windows, then display something to that window, then
; use atv_resetwindow to set the current window back to the currently
; active external window.  Make sure that device is not set to
; postscript, because if it is we can't display anything.

common atv_state
common atv_color


state.active_window_pmulti = !p.multi
!p.multi = 0

tvlct, user_r, user_g, user_b, /get

; regenerate atv color table
atv_stretchct

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
    wset, windowid
endif


end

;---------------------------------------------------------------------

pro atv_resetwindow

; reset to current active window

common atv_state
common atv_color


; The empty command used below is put there to make sure that all
; graphics to the previous atv window actually get displayed to screen
; before we wset to a different window.  Without it, some line
; graphics would not actually appear on screen.
; Also reset to user's external color map and p.multi.

if (!d.name NE 'PS') then begin
    empty
    wset, state.active_window_id
    tvlct, user_r, user_g, user_b
endif

!p.multi = state.active_window_pmulti



end

;------------------------------------------------------------------

pro atv_getwindow

; get currently active window id

common atv_state
common atv_color

if (!d.name NE 'PS') then begin
    state.active_window_id = !d.window
endif

; get current external window color table
tvlct, user_r, user_g, user_b, /get

end

;-------------------------------------------------------------------


pro atv_pixtable

; Create a table widget that will show a 5x5 array of pixel values
; around the current cursor position

if (not(xregistered('atv_pixtable', /noshow))) then begin

  common atv_state
  common atv_images

  state.pixtable_base_id = $
    widget_base(/base_align_right, $
                 group_leader = state.base_id, $
                 /column, $
                 title = 'atv pixel table')

  state.pixtable_tbl_id = $
    widget_table(state.pixtable_base_id,   $
                 value=[0,0], xsize=5, ysize=5, row_labels='', $ 
                 column_labels='', alignment=2, /resizeable_columns, $
                 column_widths = 3, units=2)

  pixtable_done = widget_button(state.pixtable_base_id, $
                                value = 'Done', $
                                uvalue = 'pixtable_done')

  widget_control, state.pixtable_base_id, /realize
  xmanager, 'atv_pixtable', state.pixtable_base_id, /no_block

endif

end

;---------------------------------------------------------------------

pro atv_pixtable_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'pixtable_done': widget_control, event.top, /destroy
    else:
endcase

end

;--------------------------------------------------------------------

pro atv_pixtable_update

common atv_state
common atv_images

zcenter = (0 > state.coord < state.image_size[0:1])

; Check and adjust the zcenter if the cursor is near the edges of the image

if (zcenter[0] le 2) then zcenter[0] = 2
if (zcenter[0] gt (state.image_size[0]-3)) then $
  zcenter[0] =  state.image_size[0] - 3

if (zcenter[1] le 2) then zcenter[1] = 2
if (zcenter[1] gt (state.image_size[1]-3)) then $
  zcenter[1] = state.image_size[1] - 3 

;pix_values = dblarr(5,5)
row_labels = strarr(5)
column_labels = strarr(5)
boxsize=2

xmin = 0 > (zcenter[0] - boxsize)
xmax = (zcenter[0] + boxsize) < (state.image_size[0] - 1) 
ymin = 0 > (zcenter[1] - boxsize) 
ymax = (zcenter[1] + boxsize) < (state.image_size[1] - 1)

row_labels = [strcompress(string(ymax),/remove_all),   $
              strcompress(string(ymin+3),/remove_all), $
              strcompress(string(ymin+2),/remove_all), $
              strcompress(string(ymin+1),/remove_all), $
              strcompress(string(ymin),/remove_all)]

column_labels = [strcompress(string(xmin),/remove_all),   $
                 strcompress(string(xmin+1),/remove_all), $
                 strcompress(string(xmin+2),/remove_all), $
                 strcompress(string(xmin+3),/remove_all), $
                 strcompress(string(xmax),/remove_all)]

pix_values = main_image[xmin:xmax, ymin:ymax]
pix_values = reverse(pix_values, 2, /overwrite)

widget_control, state.pixtable_tbl_id, set_value = pix_values, $
  column_labels=column_labels, row_labels=row_labels

; highlight the current image cursor position in the table
wx = where(long(column_labels) EQ state.coord[0], count)
wy = where(long(row_labels) EQ state.coord[1], count)

widget_control, state.pixtable_tbl_id, set_table_select = [wx,wy,wx,wy]

end



;--------------------------------------------------------------------
;    Fits file reading routines
;--------------------------------------------------------------------

pro atv_readfits, fitsfilename=fitsfilename, newimage=newimage

; Read in a new image when user goes to the File->ReadFits menu.
; Do a reasonable amount of error-checking first, to prevent unwanted
; crashes. 

common atv_state
common atv_images

newimage = 0
cancelled = 0
if (n_elements(fitsfilename) EQ 0) then window = 1 else window = 0

filterlist = ['*.fit*;*.FIT*;*.ftz*;*.FTZ*;*.fts*;*.ccd;*.fz']

; If fitsfilename hasn't been passed to this routine, get filename
; from dialog_pickfile.
if (n_elements(fitsfilename) EQ 0) then begin
   fitsfile = $
      dialog_pickfile( $
      filter = filterlist, $
      group = state.base_id, $
      /must_exist, $
      /read, $
      path = state.current_dir, $
      get_path = tmp_dir, $
      title = 'Select Fits Image')        
   if (tmp_dir NE '') then state.current_dir = tmp_dir
   if (fitsfile EQ '') then return ; 'cancel' button returns empty string
endif else begin
   fitsfile = fitsfilename
endelse

checkfz = strmid(fitsfile, 2, /reverse_offset)

; Get fits header so we know what kind of image this is.
; 10/31/2011 changed to look at exten=1 for fpack compressed files,
; since it seems that otherwise the headers are not being read.
if (checkfz EQ '.fz') then begin
   head = headfits(fitsfile, errmsg = errmsg, exten=1)
endif else begin
   head = headfits(fitsfile, errmsg = errmsg)
endelse

; Check validity of fits file header 
if (n_elements(strcompress(head, /remove_all)) LT 2) then begin
    atv_message, 'File does not appear to be a valid FITS image!', $
      window = window, msgtype = 'error'
    return
endif
if (!ERR EQ -1) then begin
    atv_message, $
      'Selected file does not appear to be a valid FITS image!', $
      msgtype = 'error', window = window
    return
endif

; Find out if this is a fits extension file, and how many extensions
; New: use fits_open rather than fits_info
fits_open, fitsfile, fcb, message = message
if (message NE '') then begin
    atv_message, message, msgtype='error', /window
    return
end
numext = fcb.nextend
fits_close, fcb

instrume = strcompress(string(sxpar(head, 'INSTRUME')), /remove_all)
origin = strcompress(sxpar(head, 'ORIGIN'), /remove_all)
naxis = sxpar(head, 'NAXIS')

; Make sure it's not a 1-d spectrum
if (numext EQ 0 AND naxis LT 2) then begin
    atv_message, 'Selected file is not a 2-d FITS image!', $
      window = window, msgtype = 'error'
    return
endif

state.title_extras = ''

; Now call the subroutine that knows how to read in this particular
; data format:

if ((checkfz EQ '.fz')) then begin
   atv_fpack_read, fitsfile, numext, head, cancelled
; next block is for Keck LRIS multiext data.  Comment this out if you
; would prefer to view individual extensions rather than a mosaic.
endif else if ((numext GT 1) AND $
               (instrume EQ 'LRIS' or instrume EQ 'LRISBLUE')) then begin
   atv_lris_read, fitsfile, head, cancelled
endif else if ((numext GT 0) AND (instrume NE 'WFPC2')) then begin
   atv_fitsext_read, fitsfile, numext, head, cancelled
endif else if ((instrume EQ 'WFPC2') AND (naxis EQ 3)) then begin
   atv_wfpc2_read, fitsfile, head, cancelled
endif else if ((naxis EQ 3) AND (origin EQ '2MASS')) then begin
   atv_2mass_read, fitsfile, head, cancelled
endif else begin
   atv_plainfits_read, fitsfile, head, cancelled
endelse

if (cancelled EQ 1) then return

; check for 2d image or 3d cube, and store the header if all is well:
s = (size(main_image))[0]
case s of
   2: begin
      atv_setheader, head
      main_image_cube = 0
      state.cube = 0
      state.nslices = 0
      atv_killcube
      end
   3: begin
      main_image_cube = main_image
      main_image = 0
      state.cube = 1
      atv_setheader, head
      atv_initcube
   end
   else: begin
      atv_message, 'Selected file is not a 2-D fits image!', $
      msgtype = 'error', window = window
      main_image_cube = 0
      main_image = fltarr(512, 512)
      newimage = 1
      state.cube = 0
      state.nslices = 0
      atv_killcube
      head = ''
      atv_setheader, head
      fitsfile = ''
   end
endcase


; Make sure it's a 2-d image
;if ( (size(main_image))[0] NE 2 ) then begin
;    atv_message, 'Selected file is not a 2-D fits image!', $
;      msgtype = 'error', window = window
;    main_image = fltarr(512, 512)
;    newimage = 1
;    return
;endif


widget_control, /hourglass

state.imagename = fitsfile
newimage = 1


end

;----------------------------------------------------------
;  Subroutines for reading specific data formats
;---------------------------------------------------------------

pro atv_fitsext_read, fitsfile, numext, head, cancelled

; Fits reader for fits extension files

common atv_state
common atv_images

numlist = ''
for i = 1, numext do begin
    numlist = strcompress(numlist + string(i) + '|', /remove_all)
endfor

numlist = strmid(numlist, 0, strlen(numlist)-1)

droptext = strcompress('0, droplist, ' + numlist + $
                       ', label_left=Select Extension:, set_value=0')

formdesc = ['0, button, Read Primary Image, quit', $
            '0, label, OR:', $
            droptext, $
            '0, button, Read Fits Extension, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, $
                   title = 'Fits Extension Selector')

if (textform.tag4 EQ 1) then begin  ; cancelled 
    cancelled = 1
    return                         
endif

if (textform.tag3 EQ 1) then begin   ;extension selected
    extension = long(textform.tag2) + 1
endif else begin
    extension = 0               ; primary image selected
endelse

; Make sure it's not a fits table: this would make mrdfits crash
head = headfits(fitsfile, exten=extension)
xten = strcompress(sxpar(head, 'XTENSION'), /remove_all)
if (xten EQ 'BINTABLE') then begin
    atv_message, 'File appears to be a FITS table, not an image.', $
      msgtype='error', /window
    cancelled = 1
    return
endif

if (extension GE 1) then begin
    state.title_extras = strcompress('Extension ' + string(extension))
endif else begin
    state.title_extras = 'Primary Image'
endelse


; Read in the image
main_image=0

; use fits_read so that extension headers will inherit primary header
; keywords.   Set /pdu to always inherit the primary header.
fits_read, fitsfile, main_image, head, exten_no = extension, /pdu


end

;----------------------------------------------------------------

pro atv_fpack_read, fitsfile, numext, head, cancelled

; fits reader for fpack-compressed .fz images with no extensions.   Note: uses
; readfits.pro to handle .fz format, but this does not handle header
; inheritance for extensions.  This is why we still use fits_read for
; normal, non-fz format images with extensions.

common atv_state
common atv_images

main_image = 0

if (numext LE 1) then begin
   main_image = readfits(fitsfile, head)
endif else begin
   numlist = ''
   for i = 1, numext do begin
      numlist = strcompress(numlist + string(i) + '|', /remove_all)
   endfor
   
   numlist = strmid(numlist, 0, strlen(numlist)-1)
   
   droptext = strcompress('0, droplist, ' + numlist + $
                          ', label_left=Select Extension:, set_value=0')
   
   formdesc = ['0, button, Read Primary Image, quit', $
               '0, label, OR:', $
               droptext, $
               '0, button, Read Fits Extension, quit', $
               '0, button, Cancel, quit']

   textform = cw_form(formdesc, /column, $
                      title = 'Fits Extension Selector')

   if (textform.tag4 EQ 1) then begin ; cancelled 
      cancelled = 1
      return                         
   endif
   
   if (textform.tag3 EQ 1) then begin ;extension selected
      extension = long(textform.tag2) + 1
   endif else begin
      extension = 0             ; primary image selected
   endelse
   
   if (extension GE 1) then begin
      state.title_extras = strcompress('Extension ' + string(extension))
   endif else begin
      state.title_extras = 'Primary Image'
   endelse
   
   main_image = readfits(fitsfile, head, exten_no = extension)

endelse

end

;------------------------------------------------------------------

pro atv_lris_read, fitsfile, head, cancelled

common atv_images

; Fits reader for Keck LRIS data.  Uses the Keck readmhdufits routine
; to assemble a single 2d image from the 4 extensions.

main_image=0
main_image = readmhdufits(fitsfile, header=head, /notrim, /nobias)

end

;------------------------------------------------------------------

pro atv_plainfits_read, fitsfile, head, cancelled

common atv_images

; Fits reader for plain fits files, no extensions.

main_image=0
fits_read, fitsfile, main_image, head

end

;------------------------------------------------------------------

pro atv_wfpc2_read, fitsfile, head, cancelled
    
; Fits reader for 4-panel HST WFPC2 images

common atv_state
common atv_images

droptext = strcompress('0, droplist,PC|WF2|WF3|WF4|Mosaic,' + $
                       'label_left = Select WFPC2 CCD:, set_value=0')

formdesc = [droptext, $
            '0, button, Read WFPC2 Image, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, title = 'WFPC2 CCD Selector')

if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return                      
endif

ccd = long(textform.tag0) + 1

widget_control, /hourglass
if (ccd LE 4) then begin
    main_image=0
    wfpc2_read, fitsfile, main_image, head, num_chip = ccd
endif

if (ccd EQ 5) then begin
    main_image=0
    wfpc2_read, fitsfile, main_image, head, /batwing
endif
        
case ccd of
    1: state.title_extras = 'PC1'
    2: state.title_extras = 'WF2'
    3: state.title_extras = 'WF3'
    4: state.title_extras = 'WF4'
    5: state.title_extras = 'Mosaic'
    else: state.title_extras = ''
endcase

end

;----------------------------------------------------------------------

pro atv_2mass_read, fitsfile, head, cancelled
    
; Fits reader for 3-plane 2MASS Extended Source J/H/Ks data cube.
common atv_state
common atv_images

droptext = strcompress('0, droplist,J|H|Ks,' + $
                       'label_left = Select 2MASS Band:, set_value=0')

formdesc = [droptext, $
            '0, button, Read 2MASS Image, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, title = '2MASS Band Selector')

if (textform.tag2 EQ 1) then begin ; cancelled
    cancelled = 1
    return                     
endif

main_image=0
main_image = mrdfits(fitsfile, 0, head, /silent, /fscale) 

band = long(textform.tag0) 
main_image = main_image[*,*,band]    ; fixed 11/28/2000

case textform.tag0 of
    0: state.title_extras = 'J Band'
    1: state.title_extras = 'H Band'
    2: state.title_extras = 'Ks Band'
    else: state.title_extras = ''
endcase

; fix ctype2 in header to prevent crashes when running xy2ad routine:
if (strcompress(sxpar(head, 'CTYPE2'), /remove_all) EQ 'DEC---SIN') then $
  sxaddpar, head, 'CTYPE2', 'DEC--SIN'

end

;----------------------------------------------------------------------

pro atv_getdss

common atv_state
common atv_images

formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
            '0, button, NED|SIMBAD, set_value=1, label_left=Object Lookup:, exclusive, tag=lookupsource', $
            '0, label, Or enter J2000 Coordinates:, CENTER', $
            '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
            '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
            '0, droplist, 1st Generation|2nd Generation Blue|2nd Generation Red|2nd Generation Near-IR, label_left=Band:, set_value=0,tag=band ', $
            '0, float, 10.0, label_left=Image Size (arcmin; max=60): ,tag=imsize', $
            '1, base, , row', $
            '0, button, GetImage, tag=getimage, quit', $
            '0, button, Cancel, tag=cancel, quit']    

archiveform = cw_form(formdesc, /column, title = 'atv: Get DSS Image')

if (archiveform.cancel EQ 1) then return

if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 60.0) then begin
    atv_message, 'Image size must be between 0 and 60 arcmin.', $
      msgtype='error', /window
    return
endif

case archiveform.band of
    0: band = '1'
    1: band = '2b'
    2: band = '2r'
    3: band = '2i'
    else: print, 'error in atv_getdss!'
endcase
    
;case archiveform.lookupsource of
;    0: ned = 1
;    1: ned = 0  ; simbad lookup
;endcase

; Temporary fix: ned lookups don't work due to change in ned
; query format.  Use SIMBAD always now, regardless of user choice.
ned = 0

widget_control, /hourglass
if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
        atv_message, errmsg, msgtype='error', /window
        return
    endif
endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec
    atv_getradec, rastring, decstring, ra, dec
endelse

; as of nov 2006, stsci server doesn't seem to recognize '2i'
; band in the way it used to.  Use eso server for 2i.
if (band NE '2i') then begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band
endif else begin
    querydss, [ra, dec], tmpimg, tmphdr, imsize=archiveform.imsize, $
      survey=band, /eso
endelse

atv, temporary(tmpimg), header=temporary(tmphdr)

end

;-----------------------------------------------------------------

pro atv_getfirst

common atv_state
common atv_images

; This feature is currently disabled in the top-level menu.  FIRST
; changed their image server to send out images as "chunked" data
; and webget.pro can't read chunked HTTP files.  If webget ever
; adds support for chunked data then we can turn this back on again.

formdesc = ['0, text, , label_left=Object Name: , width=15, tag=objname', $
            '0, button, NED|SIMBAD, set_value=0, label_left=Object Lookup:, exclusive, tag=lookupsource', $
            '0, label, Or enter J2000 Coordinates:, CENTER', $
            '0, text, , label_left=RA   (hh:mm:ss.ss): , width=15, tag=ra', $
            '0, text, , label_left=Dec (+dd:mm:ss.ss): , width=15, tag=dec', $
            '0, float, 10.0, label_left=Image Size (arcmin; max=30): ,tag=imsize', $
            '1, base, , row', $
            '0, button, GetImage, tag=getimage, quit', $
            '0, button, Cancel, tag=cancel, quit']    

archiveform = cw_form(formdesc, /column, title = 'atv: Get FIRST Image')

if (archiveform.cancel EQ 1) then return

if (archiveform.imsize LE 0.0 OR archiveform.imsize GT 30.0) then begin
    atv_message, 'Image size must be between 0 and 30 arcmin.', $
      msgtype='error', /window
    return
endif

imsize = string(round(archiveform.imsize))

case archiveform.lookupsource of
    0: ned = 1
    1: ned = 0  ; simbad lookup
endcase

widget_control, /hourglass
if (archiveform.objname NE '') then begin
    ; user entered object name
    querysimbad, archiveform.objname, ra, dec, found=found, ned=ned, $
      errmsg=errmsg
    if (found EQ 0) then begin
        atv_message, errmsg, msgtype='error', /window
        return
    endif
    
; convert decimal ra, dec to hms, dms
    sra = sixty(ra/15.0)
    rahour = string(round(sra[0]))
    ramin = string(round(sra[1]))
    rasec = string(sra[2])

    if (dec LT 0) then begin
        decsign = '-'
    endif else begin
        decsign = '+'
    endelse
    sdec = sixty(abs(dec))
 
    decdeg = strcompress(decsign + string(round(sdec[0])), /remove_all)
    decmin = string(round(sdec[1]))
    decsec = string(sdec[2])

endif else begin
    ;  user entered ra, dec
    rastring = archiveform.ra
    decstring = archiveform.dec
    atv_getradec, rastring, decstring, ra, dec

endelse

; build the url to get image

url = 'http://third.ucllnl.org/cgi-bin/firstimage'
url = strcompress(url + '?RA=' + rahour + '%20' + ramin + '%20' + rasec, $
                 /remove_all)
url = strcompress(url + '%20' + decdeg + '%20' + decmin + '%20' + $
                  decsec + '&Dec=', /remove_all)
url = strcompress(url + '&Equinox=J2000&ImageSize=' + imsize + $
                  'MaxInt=10&FITS=1&Download=1', /remove_all)

; now use webget to get the image
result = webget(url)

if (n_elements(result.image) LE 1) then begin
    atv_message, result.text, msgtype='error', /window
    return
endif else begin  ; valid image
    atv, result.image, header=result.imageheader
    result.header = ''
    result.text =  ''
    result.imageheader = ''
    result.image = ''
endelse

end

;-----------------------------------------------------------------

pro atv_getradec, rastring, decstring, ra, dec

; converts ra and dec strings in hh:mm:ss and dd:mm:ss to decimal degrees
; new and improved version by Hal Weaver, 9/6/2010

ra = 15.0 * ten(rastring)
dec = ten(decstring)


end

;---------------------------------------------------------------

pro atv_initcube

; routine to initialize the data cube slice selector

common atv_state
common atv_images


; First: if data cube is in OSIRIS IFU (lambda,x,y) format, re-form it
; into (x,y,lambda).  If it's a normal image stack (x,y,n), don't
; modify it.  This way, we can treat both kinds of cubes identically
; later on. 

if (ptr_valid(state.head_ptr)) then head = *(state.head_ptr) $
   else head = strarr(1)

; Test for whether this is an OSIRIS cube.  
currinst = strcompress(string(sxpar(head, 'CURRINST')), /remove_all)
instr = strcompress(string(sxpar(head, 'INSTR')), /remove_all)

if ((currinst EQ 'OSIRIS') AND (instr EQ 'spec')) then begin
;   print, 'Re-forming OSIRIS data cube to (x,y,lambda)...'
   nl = (size(main_image_cube))[1]
   ny = (size(main_image_cube))[2]
   nx = (size(main_image_cube))[3]
   
   tmpcube = fltarr(nx, ny, nl)
   
   for i = 0, nl-1 do begin
      tmpcube[*,*,i] = transpose(reform(main_image_cube[i,*,*]))
   endfor
   
   main_image_cube = tmpcube
   tmpcube = 0.0
   state.osiriscube = 1
endif else begin
   state.osiriscube = 0
endelse

state.nslices = (size(main_image_cube))[3]

; Create the slicer widgets if not already there
if (not(xregistered('atvslicer', /noshow))) then begin

   wtitle = 'atv data cube slicer'

   slicebase = widget_base(group_leader = state.base_id, $
                           title = wtitle, /column)
   state.slicebase_id = slicebase

   sliceselect = cw_field(slicebase, $
                             uvalue = 'sliceselect', $
                             /integer,  $
                             title = 'Select Slice:', $
                             value = state.slice,  $
                             /return_events, $
                             xsize = 7)
   state.sliceselect_id = sliceselect

   slicer = widget_slider(slicebase, /drag, scroll = 1, $
                          scr_xsize = 250, frame = 5, $
                          minimum = 0, $
                          maximum = state.nslices - 1, $
                          uvalue = 'sliceslider')
   state.slicer_id = slicer
   
   combinebase = widget_base(slicebase, /row)

   state.slicecombine_id = cw_field(combinebase, $
                                    uvalue = 'slicecombine', $
                                    /integer, $
                                    title = '# Slices to combine: ', $
                                    value = state.slicecombine, $
                                    /return_events, $
                                    xsize = 7)
   
   allslice = widget_button(combinebase, $
                            uvalue = 'allslice', $
                            value = 'All')

   noslice = widget_button(combinebase, uvalue = 'noslice', $
                           value = 'None')

   averagebase = cw_bgroup(slicebase, ['average', 'median'], $\
                      uvalue = 'average', $
                      button_uvalue = ['average', 'median'], $
                      /exclusive, set_value = state.slicecombine_method, $
                      label_left = 'Combine with: ', $
                      /no_release, $
                      /row)

   widget_control, slicebase, /realize
   xmanager, 'atvslicer', state.slicebase_id, /no_block

endif

state.slice = 0
widget_control, state.slicer_id, set_value = 0
widget_control, state.sliceselect_id, set_value = 0
widget_control, state.slicer_id, set_slider_max = state.nslices-1

if (state.slicecombine GT state.nslices) then begin
   state.slicecombine = state.nslices
   widget_control, state.slicecombine_id, set_value = state.slicecombine
endif

atvslicer_event

end

;-------------------------------------------------------------------

pro atv_killcube

; kill data cube slicer widget and go back to non-cube 2d image mode

common atv_state
common atv_images

if (xregistered('atvslicer', /noshow)) then begin
   widget_control, state.slicebase_id, /destroy
endif

state.cube = 0
state.slice = 0
state.osiriscube = 0
state.slicecombine = 1
main_image_cube = 0

end

;-------------------------------------------------------------------

pro atvslicer_event, event

common atv_state
common atv_images

; event handler for data cube slice selector widgets

if (n_elements(event) EQ 0) then begin
   event_name = 'sliceslider'
   state.slice = 0
endif else begin
   widget_control, event.id, get_uvalue = event_name
   if ((event_name EQ 'sliceslider') OR (event_name EQ 'sliceselect')) then $
      state.slice = event.value
endelse


if (event_name EQ 'sliceslider') then begin
   widget_control, state.sliceselect_id, set_value = state.slice
endif


if (event_name EQ 'sliceselect') then begin
   state.slice = 0 > event.value < (state.nslices-1)
   widget_control, state.sliceselect_id, set_value = state.slice
   widget_control, state.slicer_id, set_value = state.slice
endif

if (event_name EQ 'allslice') then begin
   state.slicecombine = state.nslices
   widget_control, state.slicecombine_id, set_value = state.slicecombine
endif

if (event_name EQ 'noslice') then begin
   state.slicecombine = 1
   widget_control, state.slicecombine_id, set_value = state.slicecombine
endif
   

if (event_name EQ 'average') then begin
   case event.value of
      'average': state.slicecombine_method = 0
      'median': state.slicecombine_method = 1
   endcase
endif

if (event_name EQ 'slicecombine') then begin
   state.slicecombine = 1 > event.value < state.nslices
   widget_control, state.slicecombine_id, set_value = state.slicecombine
endif

; get the new main image from the cube
if state.slicecombine EQ 1 then begin
   
   main_image = reform(main_image_cube[*, *, state.slice])
   
endif else begin
   
   firstslice = 0 > round(state.slice - state.slicecombine/2)
   lastslice = (firstslice + state.slicecombine - 1) < (state.nslices - 1)

   if ((lastslice - firstslice) LT state.slicecombine) then $
      firstslice = lastslice - state.slicecombine + 1

   case state.slicecombine_method of
      
      0: begin
         main_image = total(main_image_cube[*, *, firstslice:lastslice], 3) $
                      / float(state.slicecombine)
      end
      1: begin
         main_image = median(main_image_cube[*, *, firstslice:lastslice], $
                             dimension=3)
         end
   endcase
   
endelse


; if new slice selected from slider, display it
if (n_elements(event) NE 0) then begin
   atv_settitle
   atv_displayall, /newslice
endif


end

;-----------------------------------------------------------------------
;     Routines for creating output graphics
;----------------------------------------------------------------------


pro atv_writefits

; Writes image to a FITS file

common atv_state
common atv_images

; Get filename to save image

filename = dialog_pickfile(filter = '*.fits', $ 
                           file = 'atv.fits', $
                           default_extension = '.fits', $
                           dialog_parent =  state.base_id, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           /write, /overwrite_prompt)

if (tmp_dir NE '') then state.current_dir = tmp_dir

if (strcompress(filename, /remove_all) EQ '') then return   ; cancel

if (filename EQ state.current_dir) then begin
  atv_message, 'Must indicate filename to save.', msgtype = 'error', /window
  return
endif

if (ptr_valid(state.head_ptr)) then begin
  writefits, filename, main_image, (*state.head_ptr) 
endif else begin
  writefits, filename, main_image
endelse


end


;-----------------------------------------------------------------------

pro atv_writeimage, imgtype

common atv_state
common atv_images


tmpfilename = strcompress('atv.' + strlowcase(imgtype), /remove_all)
filename = dialog_pickfile(file = tmpfilename, $
                           dialog_parent = state.base_id, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           /write, /overwrite_prompt)
if (tmp_dir NE '') then state.current_dir = tmp_dir
if (strcompress(filename, /remove_all) EQ '') then return   ; cancel
if (filename EQ state.current_dir) then begin
  atv_message, 'Must indicate filename to save.', msgtype = 'error', /window
  return
endif

; From here down this routine is based on Liam E. Gumley's SAVEIMAGE
; program, modified for use with ATV.

quality = 75 ; for jpeg output

;- Check for TVRD capable device
if ((!d.flags and 128)) eq 0 then begin
    atv_message, 'Unsupported graphics device- cannot create image.', $
      msgtype='error', /window
    return
endif

depth = state.bitdepth

;- Handle window devices (other than the Z buffer)
if (!d.flags and 256) ne 0 then begin
    
  ;- Copy the contents of the current display to a pixmap
   current_window = state.draw_window_id
   xsize =  state.draw_window_size[0]
   ysize = state.draw_window_size[1]
   window, /free, /pixmap, xsize=xsize, ysize=ysize, retain=2
   device, copy=[0, 0, xsize, ysize, 0, 0, current_window]
    
  ;- Set decomposed color mode for 24-bit displays
   if (depth gt 8) then device, get_decomposed=entry_decomposed
   device, decomposed=1
endif

;- Read the pixmap contents into an array
if (depth gt 8) then begin
   image = tvrd(order=0, true=1)
endif else begin
   image = tvrd(order=0)
endelse

;- Handle window devices (other than the Z buffer)
if (!d.flags and 256) ne 0 then begin
   
  ;- Restore decomposed color mode for 24-bit displays
   if (depth gt 8) then begin
      device, decomposed=entry_decomposed
   endif

  ;- Delete the pixmap
   wdelete, !d.window
   wset, current_window

endif

;- Get the current color table
tvlct, r, g, b, /get

;- If an 8-bit image was read, reduce the number of colors
if (depth le 8) then begin
   reduce_colors, image, index
   r = r[index]
   g = g[index]
   b = b[index]
endif

; write output file

if (imgtype eq 'png') then begin
   write_png, filename, image, r, g, b
endif

if (imgtype eq 'jpg') or (imgtype eq 'tiff') then begin
      
    ;- Convert 8-bit image to 24-bit
   if (depth le 8) then begin
      info = size(image)
      nx = info[1]
      ny = info[2]
      true = bytarr(3, nx, ny)
      true[0, *, *] = r[image]
      true[1, *, *] = g[image]
      true[2, *, *] = b[image]
      image = temporary(true)
   endif
      
    ;- If TIFF format output, reverse image top to bottom
   if (imgtype eq 'tiff') then image = reverse(temporary(image), 3)

    ;- Write the image
   case imgtype of
      'jpg' : write_jpeg, filename, image, true=1, quality=quality
      'tiff' : write_tiff, filename, image, 1
      else  :
   endcase
endif
   

atv_resetwindow

end

;----------------------------------------------------------------------


pro atv_makergb

; Makes an RGB truecolor png image from the 3 blink channels.
; Can be saved using file->writeimage.
; Note- untested for 8-bit displays.  May not work there.

common atv_state
common atv_images

if (n_elements(blink_image1) EQ 1 OR $
    n_elements(blink_image2) EQ 1 OR $
    n_elements(blink_image3) EQ 1) then begin
    
    atv_message, $
      'You need to set the 3 blink channels first to make an RGB image.', $
      msgtype = 'error', /window
    return
endif

atv_getwindow

window, /free, xsize = state.draw_window_size[0], $ 
  ysize = state.draw_window_size[1], /pixmap
tempwindow = !d.window

tv, blink_image1, /true
rimage = tvrd()
tv, blink_image2, /true
gimage = tvrd()
tv, blink_image3, /true
bimage = tvrd()

tcimage = [[[rimage]], [[gimage]], [[bimage]]]

tv, tcimage, true=3

tvlct, rmap, gmap, bmap, /get
image = tvrd(/true)

wdelete, tempwindow

atv_setwindow, state.draw_window_id
tv, image, /true
atv_resetwindow


end

;----------------------------------------------------------------------

pro atv_writeps

; Writes an encapsulated postscript file of the current display.
; Calls cmps_form to get postscript file parameters.

; Note. cmps_form blocks the command line but doesn't block atv
; menus.  If we have one cmps_form active and invoke another one, it
; would crash.  Use state.ispsformon to keep track of whether we have
; one active already or not.

common atv_state
common atv_images
common atv_color

if (state.ispsformon EQ 1) then return

; cmps_form.pro crashes if atv is in blocking mode.
if (state.block EQ 1) then begin
    atv_message, 'PS output is disabled in blocking mode.', $
      msgtype = 'warning', /window
    return
endif

widget_control, /hourglass

view_min = round(state.centerpix - $
                  (0.5 * state.draw_window_size / state.zoom_factor))
; bug fix from N. Cunningham here- modified 4/14/06 to fix centering
; of overplots on the image by subtracting 1 from the max size
view_max = round(view_min + state.draw_window_size $
           / state.zoom_factor - 1)

xsize = (state.draw_window_size[0] / state.zoom_factor) > $
  (view_max[0] - view_min[0] + 1)
ysize = (state.draw_window_size[1] / state.zoom_factor) > $
  (view_max[1] - view_min[1] + 1)

aspect = float(ysize) / float(xsize)
fname = strcompress(state.current_dir + 'atv.ps', /remove_all)

atv_setwindow, state.draw_window_id
tvlct, rr, gg, bb, /get
atv_resetwindow

; make sure that we don't keep the cmps_form window as the active window
external_window_id = !d.window

state.ispsformon = 1
psforminfo = cmps_form(cancel = canceled, create = create, $
                     aspect = aspect, parent = state.base_id, $
                     /preserve_aspect, $
                     xsize = 6.0, ysize = 6.0 * aspect, $
                     /color, /encapsulated, $
                     /nocommon, papersize='Letter', $
                     bits_per_pixel=8, $
                     filename = fname, $
                     button_names = ['Create PS File'])
atv_setwindow, external_window_id

state.ispsformon = 0
if (canceled) then return
if (psforminfo.filename EQ '') then return
tvlct, rr, gg, bb


tmp_result = findfile(psforminfo.filename, count = nfiles)

result = ''
if (nfiles GT 0) then begin
    mesg = strarr(2)
    mesg[0] = 'Overwrite existing file:'
    tmp_string = $
      strmid(psforminfo.filename, $
             strpos(psforminfo.filename, state.delimiter, /reverse_search) + 1)
    mesg[1] = strcompress(tmp_string + '?', /remove_all)
    result =  dialog_message(mesg, $
                             /default_no, $
                             dialog_parent = state.base_id, $
                             /question)                 
endif

if (strupcase(result) EQ 'NO') then return
    
widget_control, /hourglass

screen_device = !d.name

; In 8-bit mode, the screen color table will have fewer than 256
; colors.  Stretch out the existing color table to 256 colors for the
; postscript plot.

set_plot, 'ps'

device, _extra = psforminfo

tvlct, rr, gg, bb, /get


; Make a full-resolution version of the display image, accounting for
; scalable pixels in the postscript output

newdisplay = bytarr(xsize, ysize)

startpos = abs(round(state.offset) < 0)

view_min = (0 > view_min < (state.image_size - 1)) 
view_max = (0 > view_max < (state.image_size - 1)) 

dimage = bytscl(scaled_image[view_min[0]:view_max[0], $
                                 view_min[1]:view_max[1]], $
                    top = 247, min=8, max=(!d.table_size-1)) + 8


newdisplay[startpos[0], startpos[1]] = temporary(dimage)

; if there's blank space around the image border, keep it black

tv, newdisplay
atv_plotall


if (state.frame EQ 1) then begin    ; put frame around image
    cgplot, [0], [0], /nodata, position=[0,0,1,1], $
      xrange=[0,1], yrange=[0,1], xstyle=5, ystyle=5, /noerase
    boxx = [0,0,1,1,0,0]
    boxy = [0,1,1,0,0,1]
    cgplot, boxx, boxy, color='black', thick=state.framethick, /overplot
endif

tvlct, temporary(rr), temporary(gg), temporary(bb)


device, /close
set_plot, screen_device


end

;----------------------------------------------------------------------
;       routines for defining the color maps
;----------------------------------------------------------------------

pro atv_stretchct, brightness, contrast,  getcursor = getcursor

; routine to change color stretch for given values of brightness and contrast.
; Complete rewrite 2000-Sep-21 - Doug Finkbeiner
; Updated 12/2006 to allow for brightness,contrast param input
; without changing the state.brightness and state.contrast values.
; Better for surface plots in plot window.

common atv_state
common atv_color

; if GETCURSOR then assume mouse position passed and save as
; state.brightness and state.contrast.  If no params passed, then use
; the current state.brightness and state.contrast.  If b, c passed
; without /getcursor, then make a new color table stretch for that
; brightness and contrast but don't modify the current
; state.brightness and state.contrast

; New in 2.0: scale the contrast by 0.75- gives better contrast by
; default when first starting up, and better in general with asinh
; scaling 

contrastscale=0.75

if (keyword_set(getcursor)) then begin 
    state.brightness = brightness/float(state.draw_window_size[0])
    state.contrast = contrast/float(state.draw_window_size[1])
    x = state.brightness*(state.ncolors-1)
    y = state.contrast*(state.ncolors-1)*contrastscale > 2 
endif else begin
    if (n_elements(brightness) EQ 0 OR n_elements(contrast) EQ 0) then begin
        x = state.brightness*(state.ncolors-1)
        y = state.contrast*(state.ncolors-1)*contrastscale > 2 
    endif else begin
        x = brightness*(state.ncolors-1)
        y = contrast*(state.ncolors-1)*contrastscale > 2
    endelse
endelse

high = x+y & low = x-y
diff = (high-low) > 1

slope = float(state.ncolors-1)/diff ;Scale to range of 0 : nc-1
intercept = -slope*low
p = long(findgen(state.ncolors)*slope+intercept) ;subscripts to select
tvlct, r_vector[p], g_vector[p], b_vector[p]

end

;------------------------------------------------------------------

pro atv_getct, tablenum

; Read in a pre-defined color table, and invert if necessary.

common atv_color
common atv_state
common atv_images


atv_setwindow, state.draw_window_id
loadct, tablenum, /silent
tvlct, r, g, b, /get

if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = r
g_vector = g
b_vector = b

atv_stretchct

; need this to re-set to external color table
atv_resetwindow

if (state.bitdepth EQ 24 AND (n_elements(pan_image) GT 10) ) then $
  atv_refresh


end

;--------------------------------------------------------------------

pro atv_makect, tablename

; Define new color tables here.  Invert if necessary.

common atv_state
common atv_color

case tablename of

    'Velocity': begin
; simple ROYGBIV color table useful for visualizing radial velocity maps
       w = findgen(256)

       sigma = 25.
       center = 170
       r = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
       r[center:255] = 255.
       sigma = 30.
       center = 0.
       r = r + 100.* exp(-1.*(w - center)^2 / (2.*sigma^2))
       
       sigma = 30.
       center1 = 100.
       g = fltarr(256)
       g[0:center1] = 255. * exp(-1.*(w[0:center1] - center1)^2 / (2.*sigma^2))
       sigma = 60.
       center2 = 140.
       g[center1:center2] = 255.
       g[center2:255] = $
          255. * exp(-1.*(w[center2:255] - center2)^2 / (2.*sigma^2))
       
       sigma = 40.
       center = 70
       b = 255.* exp(-1.*(w - center)^2 / (2.*sigma^2))
       b[0:center] = 255.
           
    end
    
    'Cubehelix': begin
; based on D. A. Green algorithm, arXiv:1108.5083 and
; Bull. Astr. Soc. India 39, 289 (2011). 

       lambda = findgen(256) / 255.0
       phi = 2.0 * !pi * $
             (state.cubehelix_start / 3.0 + state.cubehelix_nrot * lambda)
       a = state.cubehelix_hue * lambda^(state.cubehelix_gamma) * $
           (1.0 - lambda^(state.cubehelix_gamma)) / 2.0
       
       r = lambda^(state.cubehelix_gamma) + $
           a * (-0.14861 * cos(phi) + 1.78277 * sin(phi))
       g = lambda^(state.cubehelix_gamma) + $
           a * (-0.29227 * cos(phi) - 0.90649 * sin(phi))
       b = lambda^(state.cubehelix_gamma) + $
           a * (1.97294 * cos(phi))
       
       r = 0 > (r * 255.0) < 255
       g = 0 > (g * 255.0) < 255
       b = 0 > (b * 255.0) < 255
    end

; add more color table definitions here as needed...
    else: return

endcase

r = congrid(r, state.ncolors)
g = congrid(g, state.ncolors)
b = congrid(b, state.ncolors)


if (state.invert_colormap EQ 1) then begin
r = reverse(r)
g = reverse(g)
b = reverse(b)
endif

r_vector = temporary(r)
g_vector = temporary(g)
b_vector = temporary(b)

atv_stretchct

; need this to preserve external color map
atv_resetwindow

if (state.bitdepth EQ 24) then atv_refresh

end

;--------------------------------------------------------------------

pro atv_set_cubehelix

common atv_state
common atv_color

if (not (xregistered('atv_cubehelix', /noshow))) then begin

   cubehelix_base = $
      widget_base(/base_align_center, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv cubehelix settings', $
                  uvalue = 'cubehelix_base')


   state.cubehelix_start_id = cw_field(cubehelix_base, $
                                       /floating, $
                                       /return_events, $
                                       value = state.cubehelix_start, $
                                       uvalue = 'cubehelix_start', $
                                       title = 'Start Color (0:3)  ')

   state.cubehelix_nrot_id = cw_field(cubehelix_base, $
                                       /floating, $
                                       /return_events, $
                                       value = state.cubehelix_nrot, $
                                       uvalue = 'cubehelix_nrot', $
                                       title = 'Rotations  (-3:3)  ')

   state.cubehelix_hue_id = cw_field(cubehelix_base, $
                                       /floating, $
                                       /return_events, $
                                       value = state.cubehelix_hue, $
                                       uvalue = 'cubehelix_hue', $
                                       title = 'Hue         (0:3)  ')

   state.cubehelix_gamma_id = cw_field(cubehelix_base, $
                                       /floating, $
                                       /return_events, $
                                       value = state.cubehelix_gamma, $
                                       uvalue = 'cubehelix_gamma', $
                                       title = 'Gamma:      (0:3)  ')
   
   cubehelix_plot = widget_draw(cubehelix_base, frame=2, $
                                           xsize = 300, ysize = 230)

   cubehelix_buttons = widget_base(cubehelix_base, /row, /base_align_center)

   cubehelix_reset = widget_button(cubehelix_buttons, $
                                   value = 'Reset to Defaults', $
                                   uvalue = 'cubehelix_defaults')
   
   cubehelix_done = widget_button(cubehelix_buttons, value = 'Done', $
                                  uvalue = 'cubehelix_done')

   widget_control, cubehelix_base, /realize
   xmanager, 'atv_cubehelix', cubehelix_base, /no_block

   widget_control, cubehelix_plot, get_value = tmp_value
   state.cubehelix_plot_id = tmp_value

   atv_resetwindow

endif

atv_cubehelix_event

end

;-------------------------------------------------------------------

pro atv_cubehelix_event, event

common atv_state
common atv_color

if (n_elements(event) GT 0) then begin
   widget_control, event.id, get_uvalue = uvalue
endif else begin
   uvalue = 'null_event'
endelse

case uvalue of

   'cubehelix_start': begin
      startval = 0 > event.value < 3
      widget_control, state.cubehelix_start_id, set_value = startval
      state.cubehelix_start = startval
   end

   'cubehelix_nrot': begin
      nrot = (-3) > event.value < 3
      widget_control, state.cubehelix_nrot_id, set_value = nrot
      state.cubehelix_nrot = nrot
   end

   'cubehelix_hue':  begin
      hue = 0 > event.value < 3
      widget_control, state.cubehelix_hue_id, set_value = hue
      state.cubehelix_hue = hue
   end

   'cubehelix_gamma': begin
      gamma = 0 > event.value < 3
      widget_control, state.cubehelix_gamma_id, set_value = gamma
      state.cubehelix_gamma = gamma
   end

   'cubehelix_defaults': begin
      state.cubehelix_start = 0.5
      state.cubehelix_nrot = -1.5
      state.cubehelix_hue = 1.0
      state.cubehelix_gamma = 1.0
      widget_control, state.cubehelix_start_id, $
                      set_value = state.cubehelix_start
      widget_control, state.cubehelix_nrot_id, $
                      set_value = state.cubehelix_nrot
      widget_control, state.cubehelix_hue_id, $
                      set_value = state.cubehelix_hue
      widget_control, state.cubehelix_gamma_id, $
                      set_value = state.cubehelix_gamma
      state.invert_colormap = 0
   end

   'cubehelix_done': widget_control, event.top, /destroy

   else:
endcase

if (xregistered('atv_cubehelix')) then begin

   atv_makect, 'Cubehelix'
   
   atv_setwindow, state.cubehelix_plot_id
   xvector = findgen(256)
   cgplot, [0], [0], /nodata, xrange = [0,255], yrange = [0,255], $
           xtitle = 'Colormap Level', ytitle = 'Intensity', charsize=1.0, $
           xstyle=1, ystyle=1, position = [40, 80, 290, 220], $
           /device
   cgplot, xvector, xvector, /overplot, color = 'black', thick=1
   cgplot, xvector, r_vector, /overplot, color = 'red', thick=2
   cgplot, xvector, g_vector, /overplot, color = 'green', thick=2
   cgplot, xvector, b_vector, /overplot, color = 'blue', thick=2

   xsize = 256
   ysize = 30
   b = congrid( findgen(state.ncolors), xsize)
   c = replicate(1, ysize)
   a = b # c
   
   tvlct, r_vector, g_vector, b_vector

   cgimage, a, 40, 10, /tv, /noerase
   cgplot, [0],[0], /nodata, /noerase, position = [40, 10, 290, 40], $
           /device, xticks=1, xminor=1, yticks=1, yminor=1, $
           xtickname = [' ',' '], ytickname = [' ',' ']

   atv_resetwindow
endif

end

;---------------------------------------------------------------------
;    routines dealing with image header, title,  and related info
;--------------------------------------------------------------------

pro atv_settitle

; Update title bar with the image file name

common atv_state

if (state.title_extras EQ 'firstimage') then return

sizestring = strcompress('(' + string(state.image_size[0]) + 'x' + $
                         string(state.image_size[1]) + ')', /remove_all)
state.title_extras = strcompress(state.title_extras + '  ' + sizestring)

if (state.cube EQ 1) then begin
   slicestring = strcompress('[' + string(state.slice) + ']')
   state.title_extras = slicestring
endif

if (state.imagename EQ '') then begin
   title = strcompress('atv: ' + state.title_extras)
   widget_control, state.base_id, tlb_set_title = title
   
endif else begin
   ; try to get the object name from the header
   title_object = sxpar(*(state.head_ptr), 'OBJECT')

   if (strcompress(string(title_object), /remove_all) EQ '0') then $
      title_object = sxpar(*(state.head_ptr), 'TARGNAME')

   if (strcompress(string(title_object), /remove_all) EQ '0') then $
      title_object = ''

   slash = strpos(state.imagename, state.delimiter, /reverse_search)
   if (slash NE -1) then name = strmid(state.imagename, slash+1) $
   else name = state.imagename
   title = strcompress('atv:  '+ name + '  ' + state.title_extras)
   
   if (title_object NE '') then  $
      title = strcompress(title + ': ' + title_object)
   
   widget_control, state.base_id, tlb_set_title = title
endelse


end

;----------------------------------------------------------------------

pro atv_setheader, head

; Routine to keep the image header using a pointer to a 
; heap variable.  If there is no header (i.e. if atv has just been
; passed a data array rather than a filename), then make the
; header pointer a null pointer.  Get astrometry info from the 
; header if available.  If there's no astrometry information, set 
; state.astr_ptr to be a null pointer.

common atv_state

; Kill the header info window when a new image is read in

if (xregistered('atv_headinfo')) then begin
    widget_control, state.headinfo_base_id, /destroy
endif

if (xregistered('atv_stats')) then begin
    widget_control, state.stats_base_id, /destroy
endif

state.cunit = ''

if (n_elements(head) LE 1) then begin
; If there's no image header...
    state.wcstype = 'none'
    ptr_free, state.head_ptr
    state.head_ptr = ptr_new()
    ptr_free, state.astr_ptr
    state.astr_ptr = ptr_new()
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    return
endif

ptr_free, state.head_ptr
state.head_ptr = ptr_new(head)

; get exposure time for photometry, if present, otherwise set to 1s
state.exptime = float(sxpar(head, 'EXPTIME'))
if (state.exptime LE 0.0) then state.exptime = 1.0

; try to get gain and readnoise from header?
;state.ccdgain = float(sxpar(head, 'GAIN'))
;if (state.ccdgain LE 0.0) then state.ccdgain = 1.0
;state.ccdrn = float(sxpar(head, 'RDNOISE'))
;if (state.ccdrn LE 0.0) then state.ccdrn = 0.0

; Get astrometry information from header, if it exists
ptr_free, state.astr_ptr        ; kill previous astrometry info
state.astr_ptr = ptr_new()

; Keck OSIRIS data cube headers have CRVAL2 and CRVAL3 as strings
; rather than floats.  This causes extast.pro to return an error.  To
; fix, change these keywords to floats.  Do this before running
; extast, to avoid getting the error message.
if ( (strcompress(sxpar(head, 'INSTRUME'), /remove_all) EQ 'OSIRIS') and $
    (strcompress(sxpar(head, 'INSTR'), /remove_all) EQ 'spec') ) then begin
   crval2 = double(sxpar(head, 'CRVAL2'))
   crval3 = double(sxpar(head, 'CRVAL3'))
   sxaddpar, head, 'CRVAL2', crval2
   sxaddpar, head, 'CRVAL3', crval3
;   print, 'OSIRIS header keywords CRVAL2, CRVAL3 fixed.'
endif

extast, head, astr, noparams

; No valid astrometry in header
if (noparams EQ -1) then begin 
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
endif

; Here: add escape clauses for any WCS types that cause crashes.  Add
; more as needed.

checkastr = strcompress(string(astr.ctype[0]), /remove_all)
if ( (checkastr EQ 'PIXEL') OR $
     (checkastr EQ '') OR $
     (checkastr EQ 'COLUMN#') ) then begin
    widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    state.wcstype = 'none'
    return
endif

; as of recent updates, TNX format now seems to be working in 
; extast.pro so we don't need this any more
;if (checkastr EQ 'RA---TNX') then begin
;   widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
;   state.wcstype = 'none'
;   print
;   print, 'WARNING- WCS info is in unsupported TNX format.'
;   return
;endif

; Image is a 2-d calibrated spectrum:
; (these keywords work for HST STIS 2-d spectral images)
if (astr.ctype[0] EQ 'LAMBDA' OR astr.ctype[0] EQ 'WAVE') then begin
    state.wcstype = 'lambda'
    state.astr_ptr = ptr_new(astr)
    widget_control, state.wcs_bar_id, set_value = '                 '

    state.cunit = sxpar(*state.head_ptr, 'cunit1')
    state.cunit = strcompress(string(state.cunit), /remove_all)
    if (state.cunit NE '0') then begin
        state.cunit = strcompress((strmid(state.cunit,0,1)) + $
                                  strmid(state.cunit,1), $
                            /remove_all)
    endif else begin
        state.cunit = ''
    endelse   
    return
endif

; 2-D wavelength calibrated spectrum from iraf gemini reductions:
if (string(sxpar(head, 'WAT1_001')) EQ $
    'wtype=linear label=Wavelength units=angstroms') then begin
    state.wcstype = 'lambda'
    state.astr_ptr = ptr_new(astr)
    widget_control, state.wcs_bar_id, set_value = '                 '
    state.cunit = 'Angstrom'
    return
endif


; final error check on WCS, in case it's in a format that can't be
; understood by the idlastro routines.
catch, error_status

if (error_status NE 0) then begin
   print
   print, 'Warning: WCS information could not be understood.'
   wcsstring = '---No WCS Info---'
   state.wcstype='none'
   return
endif

; see if coordinates can be extracted without an error
xy2ad, 0, 0, astr, lon, lat

catch, /cancel


; Good astrometry info in header:
state.wcstype = 'angle'
widget_control, state.wcs_bar_id, set_value = '                 '

; Check for GSS type header  
if strmid( astr.ctype[0], 5, 3) EQ 'GSS' then begin
    hdr1 = head
    gsss_STDAST, hdr1
    extast, hdr1, astr, noparams
endif

; Create a pointer to the header info
state.astr_ptr = ptr_new(astr)

; Get the equinox of the coordinate system
equ = get_equinox(head, code)

if (code NE -1) then begin
    if (equ EQ 2000.0) then state.equinox = 'J2000'
    if (equ EQ 1950.0) then state.equinox = 'B1950'
    if (equ NE 2000.0 and equ NE 1950.0) then $
      state.equinox = string(equ, format = '(f6.1)')
endif else begin
    IF (strmid(astr.ctype[0], 0, 4) EQ 'GLON') THEN BEGIN 
        state.equinox = 'J2000' ; (just so it is set)
    ENDIF ELSE BEGIN   
; If no valid equinox, then ignore the WCS info.
        print, 'Warning: WCS equinox not given in image header.  Ignoring WCS info.'
        ptr_free, state.astr_ptr    ; clear pointer
        state.astr_ptr = ptr_new()
        state.equinox = 'J2000'
        state.wcstype = 'none'
        widget_control, state.wcs_bar_id, set_value = '---No WCS Info---'
    ENDELSE 
endelse

; Set default display to native system in header
state.display_equinox = state.equinox
state.display_coord_sys = strmid(astr.ctype[0], 0, 4)

end

;---------------------------------------------------------------------


pro atv_headinfo

common atv_state

; If there's no header, kill the headinfo window and exit this
; routine.
if (not(ptr_valid(state.head_ptr))) then begin
    if (xregistered('atv_headinfo')) then begin
        widget_control, state.headinfo_base_id, /destroy
    endif

    atv_message, 'No header information available for this image!', $
      msgtype = 'error', /window
    return
endif


; If there is header information but not headinfo window,
; create the headinfo window.
if (not(xregistered('atv_headinfo', /noshow))) then begin

    headinfo_base = $
      widget_base(/base_align_right, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv image header information', $
                  uvalue = 'headinfo_base')
    state.headinfo_base_id = headinfo_base

    h = *(state.head_ptr)

    headinfo_text = widget_text(headinfo_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    headinfo_done = widget_button(headinfo_base, $
                              value = 'Done', $
                              uvalue = 'headinfo_done')

    widget_control, headinfo_base, /realize
    xmanager, 'atv_headinfo', headinfo_base, /no_block

endif


end

;---------------------------------------------------------------------

pro atv_headinfo_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'headinfo_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;             routines to do plot overlays
;----------------------------------------------------------------------

pro atv_plot1plot, iplot
common atv_pdata
common atv_state

; Plot a point or line overplot on the image

atv_setwindow, state.draw_window_id

widget_control, /hourglass

x = atvplotlist[iplot].x
y = atvplotlist[iplot].y
cgplot, x, y, _extra = atvplotlist[iplot].options, /overplot

atv_resetwindow
state.newrefresh=1


end

;----------------------------------------------------------------------

pro atv_plot1text, iplot
common atv_pdata
common atv_state

; Plot a text overlay on the image
atv_setwindow, state.draw_window_id

widget_control, /hourglass

x = atvplotlist[iplot].x
y = atvplotlist[iplot].y
text = atvplotlist[iplot].text
cgtext, x, y, text, _extra = atvplotlist[iplot].options

atv_resetwindow
state.newrefresh=1

end

;----------------------------------------------------------------------

pro atv_plot1arrow, iplot
common atv_pdata
common atv_state

; TO DO: incorporate as a region overplot

; modified to work with one_arrow, based on angle/length instead of
; ending coordinate

; Plot a arrow overlay on the image
atv_setwindow, state.draw_window_id

widget_control, /hourglass

x1 = atvplotlist[iplot].x1
y1 = atvplotlist[iplot].y1
x2 = atvplotlist[iplot].x2
y2 = atvplotlist[iplot].y2

dy = float(y2 - y1)
dx = float(x2 - x1)
theta = atan(dy, dx) * !radeg
length = sqrt(dx^2 + dy^2) * state.zoom_factor
arrowsize = [length, 9, 35]

one_arrow, x1, y1, theta, '', arrowsize=arrowsize, $
           _extra = atvplotlist[iplot].options, /data

atv_resetwindow
state.newrefresh=1
end


;----------------------------------------------------------------------

function atv_degperpix, hdr 
             
; This program calculates the pixel scale (deg/pixel) and returns the value

common atv_state

On_error,2                      ;Return to caller

extast, hdr, bastr, noparams    ;extract astrom params in deg.

a = bastr.crval[0]
d = bastr.crval[1]

factor = 60.0                   ;conversion factor from deg to arcmin
d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

proj = strmid(bastr.ctype[0],5,3)

case proj of 
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y 
endcase

dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

; Convert to degrees per pixel and return scale
degperpix = 1. / dmin / 60.

return, degperpix
end

;----------------------------------------------------------------------

function atv_wcs2pix, coords, coord_sys=coord_sys, line=line

common atv_state

; check validity of state.astr_ptr and state.head_ptr before
; proceeding to grab wcs information

if ptr_valid(state.astr_ptr) then begin
    ctype = (*state.astr_ptr).ctype
    equinox = state.equinox
    disp_type = state.display_coord_sys
    disp_equinox = state.display_equinox
    disp_base60 = state.display_base60
    bastr = *(state.astr_ptr)
    
; function to convert an ATV region from wcs coordinates to pixel coordinates
    degperpix = atv_degperpix(*(state.head_ptr))
    
; need numerical equinox values
    IF (equinox EQ 'J2000') THEN num_equinox = 2000.0 ELSE $
      IF (equinox EQ 'B1950') THEN num_equinox = 1950.0 ELSE $
      num_equinox = float(equinox)
    
    headtype = strmid(ctype[0], 0, 4)
    n_coords = n_elements(coords)
endif

case coord_sys of
    
    'j2000': begin
        if (strpos(coords[0], ':')) ne -1 then begin
            ra_arr = strsplit(coords[0],':',/extract)
            dec_arr = strsplit(coords[1],':',/extract)
            ra = ten(float(ra_arr[0]), float(ra_arr[1]), $
                     float(ra_arr[2])) * 15.0
            dec = ten(float(dec_arr[0]), float(dec_arr[1]), $
                      float(dec_arr[2]))
            if (keyword_set(line)) then begin
                ra1_arr = strsplit(coords[2],':',/extract)
                dec1_arr = strsplit(coords[3],':',/extract)
                ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), $
                          float(ra1_arr[2])) * 15.0
                dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), $
                           float(dec1_arr[2]))
            endif
        endif else begin        ; coordinates in degrees
            ra=float(coords[0])
            dec=float(coords[1])
            if (keyword_set(line)) then begin
                ra1=float(coords[2])
                dec1=float(coords[3])  
            endif
        endelse
        
        if (not keyword_set(line)) then begin
            if (n_coords ne 6) then $
              coords[2:n_coords-2] = $
              strcompress(string(float(coords[2:n_coords-2]) / $
                                 (degperpix * 60.)),/remove_all) $
            else $
              coords[2:n_coords-3] = $
              strcompress(string(float(coords[2:n_coords-3]) / $
                                 (degperpix * 60.)),/remove_all)
        endif
        
    end
    
    'b1950': begin
        if (strpos(coords[0], ':')) ne -1 then begin
            ra_arr = strsplit(coords[0],':',/extract)
            dec_arr = strsplit(coords[1],':',/extract)
            ra = ten(float(ra_arr[0]), float(ra_arr[1]), $
                     float(ra_arr[2])) * 15.0
            dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
            precess, ra, dec, 1950.0, 2000.0
            if (keyword_set(line)) then begin
                ra1_arr = strsplit(coords[2],':',/extract)
                dec1_arr = strsplit(coords[3],':',/extract)
                ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), $
                          float(ra1_arr[2])) * 15.0
                dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), $
                           float(dec1_arr[2]))
                precess, ra1, dec1, 1950.0,2000.0
            endif
        endif else begin      ; convert B1950 degrees to J2000 degrees
            ra = float(coords[0])
            dec = float(coords[1]) 
            precess, ra, dec, 1950.0, 2000.0
            if (keyword_set(line)) then begin
                ra1=float(coords[2])
                dec1=float(coords[3])
                precess, ra1, dec1, 1950., 2000.0 
            endif
        endelse
        
        if (not keyword_set(line)) then begin
            if (n_coords ne 6) then $
              coords[2:n_coords-2] = $
              strcompress(string(float(coords[2:n_coords-2]) / $
                                 (degperpix * 60.)),/remove_all) $
    else $
              coords[2:n_coords-3] = $
              strcompress(string(float(coords[2:n_coords-3]) / $
                                 (degperpix * 60.)),/remove_all)
        endif
    end
    
    'galactic': begin           ; convert galactic to J2000 degrees
        euler, float(coords[0]), float(coords[1]), ra, dec, 2
        if (not keyword_set(line)) then begin
            if (n_coords ne 6) then $
              coords[2:n_coords-2] = $
              strcompress(string(float(coords[2:n_coords-2]) / $
                                 (degperpix * 60.)),/remove_all) $
            else $
              coords[2:n_coords-3] = $
              strcompress(string(float(coords[2:n_coords-3]) / $
                                 (degperpix * 60.)),/remove_all)
        endif else begin
            euler, float(coords[2]), float(coords[3]), ra1, dec1, 2
        endelse
    end
    
    'ecliptic': begin           ; convert ecliptic to J2000 degrees
  euler, float(coords[0]), float(coords[1]), ra, dec, 4
  if (not keyword_set(line)) then begin
      if (n_coords ne 6) then $ 
        coords[2:n_coords-2] = $
        strcompress(string(float(coords[2:n_coords-2]) / $
                           (degperpix * 60.)),/remove_all) $
      else $
        coords[2:n_coords-3] = $
        strcompress(string(float(coords[2:n_coords-3]) / $
                           (degperpix * 60.)),/remove_all)
  endif else begin
      euler, float(coords[2]), float(coords[3]), ra1, dec1, 4
  endelse
end

'current': begin
    ra_arr = strsplit(coords[0],':',/extract)
    dec_arr = strsplit(coords[1],':',/extract)
    ra = ten(float(ra_arr[0]), float(ra_arr[1]), float(ra_arr[2])) * 15.0
    dec = ten(float(dec_arr[0]), float(dec_arr[1]), float(dec_arr[2]))
    if (not keyword_set(line)) then begin
        coords[2] = strcompress(string(float(coords[2]) / $
                                       (degperpix * 60.)),/remove_all)
        if (n_coords gt 3) then $
          coords[3] = strcompress(string(float(coords[3]) / $
                                         (degperpix * 60.)),/remove_all)
    endif else begin
      ra1_arr = strsplit(coords[2],':',/extract)
      dec1_arr = strsplit(coords[3],':',/extract)
      ra1 = ten(float(ra1_arr[0]), float(ra1_arr[1]), float(ra1_arr[2])) * 15.0
      dec1 = ten(float(dec1_arr[0]), float(dec1_arr[1]), float(dec1_arr[2]))
  endelse
  
  if (num_equinox ne 2000.) then begin
      precess, ra, dec, num_equinox, 2000.
      if (keyword_set(line)) then precess, ra1, dec1, num_equinox, 2000.
  endif
  
end

'pixel': begin
; Do nothing when pixel.  Will pass pixel coords array back.
end

else: 

endcase

if (ptr_valid(state.astr_ptr) AND coord_sys ne 'pixel') then begin
    
    if (num_equinox ne 2000) then begin
        precess, ra, dec, 2000., num_equinox
        if (keyword_set(line)) then precess, ra1, dec1, 2000., num_equinox
    endif
    
    proj = strmid(ctype[0],5,3)
    
    case proj of 
        'GSS': begin
            gsssadxy, bastr, ra, dec, x, y
            if (keyword_set(line)) then gsssadxy, bastr, ra1, dec1, x1, y1
        end
        else: begin
            ad2xy, ra, dec, bastr, x, y 
            if (keyword_set(line)) then ad2xy, ra1, dec1, bastr, x1, y1 
        end
    endcase
    
    coords[0] = strcompress(string(x),/remove_all)
    coords[1] = strcompress(string(y),/remove_all)
    if (keyword_set(line)) then begin
        coords[2] = strcompress(string(x1),/remove_all)
        coords[3] = strcompress(string(y1),/remove_all)
    endif
endif

return, coords
end

;----------------------------------------------------------------------


pro atv_plot1region, iplot
common atv_pdata
common atv_state

; Plot a region overlay on the image
atv_setwindow, state.draw_window_id

widget_control, /hourglass

reg_array = atvplotlist[iplot].reg_array

n_reg = n_elements(reg_array)

for i=0, n_reg-1 do begin
    open_parenth_pos = strpos(reg_array[i],'(')
    close_parenth_pos = strpos(reg_array[i],')')   
    reg_type = strcompress(strmid(reg_array[i],0,open_parenth_pos),/remove_all)
    length = close_parenth_pos - open_parenth_pos
    coords_str = strcompress(strmid(reg_array[i], open_parenth_pos+1, $
                                    length-1),/remove_all)
    coords_arr = strsplit(coords_str,',',/extract) 
    n_coords = n_elements(coords_arr)
    color_begin_pos = strpos(strlowcase(reg_array[i]), 'color')
    text_pos = strpos(strlowcase(reg_array[i]), 'text')
    
    if (color_begin_pos ne -1) then begin
        color_equal_pos = strpos(reg_array[i], '=', color_begin_pos)
    endif
    
    text_begin_pos = strpos(reg_array[i], '{')
    
; Text for region
    if (text_begin_pos ne -1) then begin
        text_end_pos = strpos(reg_array[i], '}')
        text_len = (text_end_pos-1) - (text_begin_pos)
        text_str = strmid(reg_array[i], text_begin_pos+1, text_len)
        color_str = ''
        
; Color & Text for region
        if (color_begin_pos ne -1) then begin
; Compare color_begin_pos to text_begin_pos to tell which is first
            
            case (color_begin_pos lt text_begin_pos) of
                0: begin
;text before color
                    color_str = $
                      strcompress(strmid(reg_array[i], color_equal_pos+1, $
                                         strlen(reg_array[i])), /remove_all)
                end
                1: begin
                                ;color before text
                    len_color = (text_pos-1) - color_equal_pos
                    color_str = $
                      strcompress(strmid(reg_array[i], color_equal_pos+1, $
                                         len_color), /remove_all)
                end
                else:
            endcase
        endif
        
    endif else begin
        
; Color but no text for region
        if (color_begin_pos ne -1) then begin
            color_str = strcompress(strmid(reg_array[i], color_equal_pos+1, $
                                           strlen(reg_array[i])), /remove_all)
            
; Neither color nor text for region
        endif else begin
            color_str = ''
        endelse
        
        text_str = ''
        
    endelse
    
    index_j2000 = where(strlowcase(coords_arr) eq 'j2000')
    index_b1950 = where(strlowcase(coords_arr) eq 'b1950')
    index_galactic = where(strlowcase(coords_arr) eq 'galactic')
    index_ecliptic = where(strlowcase(coords_arr) eq 'ecliptic')
    
    index_coord_system = where(strlowcase(coords_arr) eq 'j2000') AND $
      where(strlowcase(coords_arr) eq 'b1950') AND $
      where(strlowcase(coords_arr) eq 'galactic') AND $
      where(strlowcase(coords_arr) eq 'ecliptic')
    
    index_coord_system = index_coord_system[0]
    
    if (index_coord_system ne -1) then begin
        
; Check that a WCS region is not overplotted on image with no WCS
        if (NOT ptr_valid(state.astr_ptr)) then begin
            atv_message, $
              'WCS Regions cannot be displayed on image without WCS information in header.', $
              msgtype='error', /window
; Erase pstruct that was formed for this region.
            atverase, 1
            return
        endif
        
        case strlowcase(coords_arr[index_coord_system]) of
            'j2000': begin
                if (strlowcase(reg_type) ne 'line') then $
                  coords_arr = atv_wcs2pix(coords_arr, coord_sys='j2000') $
                else $
                  coords_arr = $
                  atv_wcs2pix(coords_arr, coord_sys='j2000', /line) 
            end
            'b1950': begin
                if (strlowcase(reg_type) ne 'line') then $
                  coords_arr = atv_wcs2pix(coords_arr, coord_sys='b1950') $
                else $
                  coords_arr = $
                  atv_wcs2pix(coords_arr, coord_sys='b1950', /line)
            end
            'galactic': begin
                if (strlowcase(reg_type) ne 'line') then $
                  coords_arr = atv_wcs2pix(coords_arr, coord_sys='galactic') $
                else $
                  coords_arr = $
                  atv_wcs2pix(coords_arr, coord_sys='galactic', /line)
            end
            'ecliptic': begin
                if (strlowcase(reg_type) ne 'line') then $
                  coords_arr = atv_wcs2pix(coords_arr, coord_sys='ecliptic') $
                else $
                  coords_arr = $
                  atv_wcs2pix(coords_arr, coord_sys='ecliptic', /line)
            end
            else: 
        endcase
    endif else begin
        
        if (strpos(coords_arr[0], ':')) ne -1 then begin
            
; Check that a WCS region is not overplotted on image with no WCS
            if (NOT ptr_valid(state.astr_ptr)) then begin
                atv_message, $
                  'WCS Regions cannot be displayed on image without WCS', $
                  msgtype='error', /window
                return
            endif
            
            if (strlowcase(reg_type) ne 'line') then $
              coords_arr = atv_wcs2pix(coords_arr,coord_sys='current') $
            else $
              coords_arr = atv_wcs2pix(coords_arr,coord_sys='current', /line)
        endif else begin
            if (strlowcase(reg_type) ne 'line') then $
              coords_arr = atv_wcs2pix(coords_arr,coord_sys='pixel') $
            else $
              coords_arr = atv_wcs2pix(coords_arr,coord_sys='pixel', /line)
        endelse
        
    endelse
    

; use cgplot colors by name
    tstruct = atvplotlist[iplot]
    tstruct.options.color = string(color_str)    
    atvplotlist[iplot] = tstruct

    atv_setwindow,state.draw_window_id
    atv_plotwindow  
    
    case strlowcase(reg_type) of
        
        'circle': begin
            xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
              state.zoom_factor
            ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
              state.zoom_factor
            radius = float(coords_arr[2]) * state.zoom_factor
            
        ; added by AJB: rescale for postscript output for each plot type
            if (!d.name EQ 'PS') then begin
                xcenter = xcenter / state.draw_window_size[0] * !d.x_size
                ycenter = ycenter / state.draw_window_size[1] * !d.y_size
                radius = radius / state.draw_window_size[0] * !d.x_size
            endif

            tvcircle, radius, xcenter, ycenter, $
              _extra = atvplotlist[iplot].options, /device
           

            if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
              alignment=0.5, _extra = atvplotlist[iplot].options, /device
        end
        'box': begin
            angle = 0           ; initialize angle to 0
            if (n_coords ge 4) then begin
                xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                  state.zoom_factor
                ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                  state.zoom_factor
                xwidth = float(coords_arr[2]) * state.zoom_factor
                ywidth = float(coords_arr[3]) * state.zoom_factor
                if (n_coords ge 5) then angle = float(coords_arr[4])
            endif
            width_arr = [xwidth,ywidth]  

            if (!d.name EQ 'PS') then begin
                xcenter = xcenter / state.draw_window_size[0] * !d.x_size
                ycenter = ycenter / state.draw_window_size[1] * !d.y_size
                width_arr = width_arr / state.draw_window_size[0] * !d.x_size
            endif       

; angle = -angle because tvbox rotates clockwise
            tvbox, width_arr, xcenter, ycenter, angle=-angle, $
              _extra = atvplotlist[iplot].options, /device
            
            if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
              alignment=0.5, _extra = atvplotlist[iplot].options, /device
        end
        
        'ellipse': begin
            angle = 0           ; initialize angle to 0
            if (n_coords ge 4) then begin
                xcenter = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
                  state.zoom_factor
                ycenter = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
                  state.zoom_factor
                xradius = float(coords_arr[2]) * state.zoom_factor 
                yradius = float(coords_arr[3]) * state.zoom_factor
                if (n_coords ge 5) then angle = float(coords_arr[4])
            endif
            
; Correct angle for default orientation used by tvellipse
            angle=angle+180.
            
            if (!d.name EQ 'PS') then begin
                xcenter = xcenter / state.draw_window_size[0] * !d.x_size
                ycenter = ycenter / state.draw_window_size[1] * !d.y_size
                xradius = xradius / state.draw_window_size[0] * !d.x_size
                yradius = yradius / state.draw_window_size[1] * !d.y_size
            endif

              atv_plot1ellipse, xradius, yradius, xcenter, ycenter, angle, $
              _extra = atvplotlist[iplot].options
            
            if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
              alignment=0.5, _extra = atvplotlist[iplot].options, /device
        end
        'polygon': begin
            n_vert = n_elements(coords_arr) / 2
            xpoints = fltarr(n_vert)
            ypoints = fltarr(n_vert)
            for vert_i = 0, n_vert - 1 do begin
                xpoints[vert_i] = coords_arr[vert_i*2]
                ypoints[vert_i] = coords_arr[vert_i*2+1]
            endfor
            
            if (xpoints[0] ne xpoints[n_vert-1] OR $
                ypoints[0] ne ypoints[n_vert-1]) then begin
                xpoints1 = fltarr(n_vert+1)
                ypoints1 = fltarr(n_vert+1)
                xpoints1[0:n_vert-1] = xpoints
                ypoints1[0:n_vert-1] = ypoints
                xpoints1[n_vert] = xpoints[0]
                ypoints1[n_vert] = ypoints[0]
                xpoints = xpoints1
                ypoints = ypoints1
            endif
            
            xcenter = total(xpoints) / n_elements(xpoints)
            ycenter = total(ypoints) / n_elements(ypoints)
            
            plots, xpoints, ypoints,  $
              _extra = atvplotlist[iplot].options         
            
            if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
              alignment=0.5, _extra = atvplotlist[iplot].options, /device
        end
        'line': begin
            x1 = (float(coords_arr[0]) - state.offset[0] + 0.5) * $
              state.zoom_factor
            y1 = (float(coords_arr[1]) - state.offset[1] + 0.5) * $
              state.zoom_factor
            x2 = (float(coords_arr[2]) - state.offset[0] + 0.5) * $
              state.zoom_factor
            y2 = (float(coords_arr[3]) - state.offset[1] + 0.5) * $
              state.zoom_factor
            
            xpoints = [x1,x2]
            ypoints = [y1,y2]
            xcenter = total(xpoints) / n_elements(xpoints)
            ycenter = total(ypoints) / n_elements(ypoints)
            
            if (!d.name EQ 'PS') then begin
                xpoints = xpoints / state.draw_window_size[0] * !d.x_size
                ypoints = ypoints / state.draw_window_size[1] * !d.y_size
            endif

            plots, xpoints, ypoints, /device, $
              _extra = atvplotlist[iplot].options
            
            if (text_str ne '') then xyouts, xcenter, ycenter, text_str, $
              alignment=0.5, _extra = atvplotlist[iplot].options, /device
        end

        ; these are all the region types we have defined so far.  
        else: begin
            
        end
        
    endcase
    
endfor

atv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------


pro atv_plot1contour, iplot
common atv_pdata
common atv_state

; Overplot contours on the image

; TO DO: fix labels/font size for contour

atv_setwindow, state.draw_window_id
widget_control, /hourglass

xrange = !x.crange
yrange = !y.crange

; The following allows for 2 conditions, depending upon whether X and Y
; are set
dims = size( atvplotlist[iplot].z, /dim )

x = atvplotlist[iplot].x
y = atvplotlist[iplot].y
z = atvplotlist[iplot].z

if  (size(x, /n_elements ) EQ dims[0]   $
   and size(y, /n_elements) EQ dims[1]) then begin
    
   cgcontour, z, x, y, $
              position=[0,0,1,1], xrange=xrange, yrange=yrange, $
              xstyle=5, ystyle=5, /noerase, $
              _extra = atvplotlist[iplot].options
   
endif else begin
   
   cgcontour, z, $
              position=[0,0,1,1], xrange=xrange, yrange=yrange, $
              xstyle=5, ystyle=5, /noerase, $
              _extra = atvplotlist[iplot].options
   
endelse

atv_resetwindow
state.newrefresh=1
end

;---------------------------------------------------------------------

pro atv_plot1compass, iplot

; Uses idlastro routine arrows to plot compass arrows.

common atv_pdata
common atv_state

atv_setwindow, state.draw_window_id

widget_control, /hourglass

arrows, *(state.head_ptr), $
  atvplotlist[iplot].x, $
  atvplotlist[iplot].y, $
  thick = atvplotlist[iplot].thick, $
  charsize = atvplotlist[iplot].charsize, $
  arrowlen = atvplotlist[iplot].arrowlen, $
  color = atvplotlist[iplot].color, $
  notvertex = atvplotlist[iplot].notvertex, $
  /data

atv_resetwindow
state.newrefresh=1
end

;---------------------------------------------------------------------

pro atv_plot1scalebar, iplot

; uses modified version of idlastro routine arcbar to plot a scalebar

common atv_pdata
common atv_state

atv_setwindow, state.draw_window_id
widget_control, /hourglass

; routine arcbar doesn't recognize color=0, because it uses 
; keyword_set to check the color.  So we need to set !p.color = 0
; to get black if the user wants color=0

!p.color = 0

atv_arcbar, *(state.head_ptr), $
  atvplotlist[iplot].arclen, $
  position = atvplotlist[iplot].position, $
  thick = atvplotlist[iplot].thick, $
  size = atvplotlist[iplot].size, $
  color = atvplotlist[iplot].color, $
  seconds = atvplotlist[iplot].seconds, $
  /data

atv_resetwindow
state.newrefresh=1
end

;----------------------------------------------------------------------

pro atv_arcbar, hdr, arclen, LABEL = label, SIZE = size, THICK = thick, $
                DATA =data, COLOR = color, POSITION = position, $
                NORMAL = normal, SECONDS=SECONDS

common atv_state

; This is a copy of the IDL Astronomy User's Library routine 'arcbar',
; abbreviated for atv and modified to work with zoomed images.  For
; the revision history of the original arcbar routine, look at
; arcbar.pro in the pro/astro subdirectory of the IDL Astronomy User's
; Library.

; Modifications for atv:
; Modified to work with zoomed ATV images, AJB Jan. 2000 
; Moved text label upwards a bit for better results, AJB Jan. 2000
; Modified to work with cgplot, apr 2011

On_error,2                      ;Return to caller
 
extast, hdr, bastr, noparams    ;extract astrom params in deg.
 
if N_params() LT 2 then arclen = 1 ;default size = 1 arcmin

if not keyword_set( SIZE ) then size = 1.0
if not keyword_set( THICK ) then thick = !P.THICK
if not keyword_set( COLOR ) then color = !P.COLOR

a = bastr.crval[0]
d = bastr.crval[1]
if keyword_set(seconds) then factor = 3600.0d else factor = 60.0
d1 = d + (1/factor)             ;compute x,y of crval + 1 arcmin

proj = strmid(bastr.ctype[0],5,3)

case proj of 
    'GSS': gsssadxy, bastr, [a,a], [d,d1], x, y
    else:  ad2xy, [a,a], [d,d1], bastr, x, y 
endcase

dmin = sqrt( (x[1]-x[0])^2 + (y[1]-y[0])^2 ) ;det. size in pixels of 1 arcmin

if (!D.FLAGS AND 1) EQ 1 then begin ;Device have scalable pixels?
    if !X.s[1] NE 0 then begin
        dmin = convert_coord( dmin, 0, /DATA, /TO_DEVICE) - $ 
          convert_coord(    0, 0, /DATA, /TO_DEVICE) ;Fixed Apr 97
        dmin = dmin[0]
    endif else dmin = dmin/sxpar(hdr, 'NAXIS1' ) ;Fixed Oct. 96
endif else  dmin = dmin * state.zoom_factor    ; added by AJB Jan. '00

dmini2 = round(dmin * arclen)

if keyword_set(NORMAL) then begin
    posn = convert_coord(position,/NORMAL, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else if keyword_set(DATA) then begin
    posn = convert_coord(position,/DATA, /TO_DEVICE) 
    xi = posn[0] & yi = posn[1]
endif else begin
    xi = position[0]   & yi = position[1]
endelse         


xf = xi + dmini2
dmini3 = dmini2/10       ;Height of vertical end bars = total length/10.

cgplots,[xi,xf],[yi,yi], COLOR=color, /DEV, THICK=thick
cgplots,[xf,xf],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick
cgplots,[xi,xi],[ yi+dmini3, yi-dmini3 ], COLOR=color, /DEV, THICK=thick

if not keyword_set(Seconds) then begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym='!9'+string(162B)+'!X' else arcsym = "'" 
endif else begin
    if (!D.NAME EQ 'PS') and (!P.FONT EQ 0) then $ ;Postscript Font?
      arcsym = '!9'+string(178B)+'!X' else arcsym = "''" 
endelse
if not keyword_set( LABEL) then begin
    if (arclen LT 1) then arcstr = string(arclen,format='(f4.2)') $
    else arcstr = string(arclen)
    label = strtrim(arcstr,2) + arcsym 
endif

; modified this to move the numerical label upward a bit: 5/8/2000
cgtext,(xi+xf)/2, (yi+(dmini2/10)), label, SIZE = size, COLOR=color,$
  /DEV, alignment=.5, CHARTHICK=thick

return
end

;----------------------------------------------------------------------

pro atv_plotwindow
common atv_state

atv_setwindow, state.draw_window_id

; Set plot window

; improved version by N. Cunningham- different scaling for postscript
; vs non-postscript output  -- added 4/14/06
if !d.name eq 'PS' then begin
   xrange=[state.offset[0], $
           state.offset[0] + state.draw_window_size[0] $
           / state.zoom_factor] - 0.5
   yrange=[state.offset[1], $
           state.offset[1] + state.draw_window_size[1] $
           / state.zoom_factor] - 0.5
endif else begin
   xrange=[state.offset[0] + 0.5 / state.zoom_factor, $
           state.offset[0] + (state.draw_window_size[0] + 0.5) $
           / state.zoom_factor] - 0.5
   yrange=[state.offset[1] + 0.5 / state.zoom_factor, $
           state.offset[1] + (state.draw_window_size[1] + 0.5) $
           / state.zoom_factor] - 0.5
endelse

plot, [0], [0], /nodata, position=[0,0,1,1], $
 xrange=xrange, yrange=yrange, xstyle=5, ystyle=5, /noerase

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_plot1ellipse, rmax, rmin, xc, yc, pos_ang, _extra = _extra

; This is a modified version of Wayne Landsman's tvellipse, changed so
; that it won't ask for interactive input under any circumstances.

if N_params() LT 5 then pos_ang = 0. ;Default position angle

npoints = 500                   ;Number of points to connect
phi = 2*!pi*(findgen(npoints)/(npoints-1)) ;Divide circle into Npoints
ang = pos_ang/!RADEG            ;Position angle in radians
cosang = cos(ang)
sinang = sin(ang)

x =  rmax*cos(phi)              ;Parameterized equation of ellipse
y =  rmin*sin(phi)

xprime = xc + x*cosang - y*sinang ;Rotate to desired position angle
yprime = yc + x*sinang + y*cosang

cgplots, round(xprime), round(yprime), color=color, /device,  $
  _STRICT_Extra = _extra

end

;---------------------------------------------------------------------

pro atv_plotall
common atv_state
common atv_pdata

; Routine to overplot all line, text, and contour plots

nplot = n_elements(atvplotlist)

if (nplot EQ 0) then return

atv_plotwindow

for iplot = 0, nplot-1 do begin
    case atvplotlist[iplot].type of
        'points'  : atv_plot1plot, iplot
        'text'    : atv_plot1text, iplot
        'arrow'   : atv_plot1arrow, iplot
        'contour' : atv_plot1contour, iplot
        'compass' : atv_plot1compass, iplot
        'scalebar': atv_plot1scalebar, iplot
        'region'  : atv_plot1region, iplot
        else      : print, 'Problem in atv_plotall!'   
    endcase
endfor

end

;----------------------------------------------------------------------

pro atvplot, x, y, _extra = options
common atv_pdata
common atv_state

; Routine to read in line plot data and options, store in a heap
; variable structure, and plot the line plot

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVPLOT.'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

;  convert color names to index numbers, and set default=red
c = where(tag_names(options) EQ 'COLOR', count)
if (count EQ 0) then options = create_struct(options, 'color', 'red')

pstruct = {type: 'points',   $  ; points
           x: x,             $  ; x coordinate
           y: y,             $  ; y coordinate
           options: options  $  ; plot keyword options
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1plot, nplot-1

end

;----------------------------------------------------------------------

pro atvxyouts, x, y, text, _extra = options
common atv_pdata
common atv_state

; Routine to read in text overplot string and options, store in a heap
; variable structure, and overplot the text

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 3) then begin
   print, 'Too few parameters for ATVXYOUTS'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}

; set default color = 'red'
c = where(tag_names(options) EQ 'COLOR', count)
if (count EQ 0) then options = create_struct(options, 'color', 'red')

;  set default font to 1
c = where(tag_names(options) EQ 'FONT', count)
if (count EQ 0) then options = create_struct(options, 'font', 1)

pstruct = {type: 'text',   $    ; type of plot 
           x: x,             $  ; x coordinate
           y: y,             $  ; y coordinate
              text: text,       $     ; text to plot
           options: options  $  ; plot keyword options
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1text, nplot-1

end

;----------------------------------------------------------------------

pro atvarrow, x1, y1, x2, y2, _extra = options
common atv_pdata
common atv_state

; Routine to read in arrow overplot options, store in a heap
; variable structure, and overplot the arrow

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 4) then begin
   print, 'Too few parameters for ATVARROW'
   return
endif

if (n_elements(options) EQ 0) then options = {color: 'red'}


;  convert color names to index numbers, and set default=red
c = where(tag_names(options) EQ 'COLOR', count)
if (count EQ 0) then options = create_struct(options, 'color', 'red')

pstruct = {type: 'arrow',   $   ; type of plot 
           x1: x1,             $ ; x1 coordinate
           y1: y1,             $ ; y1 coordinate
           x2: x2,             $ ; x2 coordinate
           y2: y2,             $ ; y2 coordinate     
           options: options  $  ; plot keyword options
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1arrow, nplot-1

end


;---------------------------------------------------------------------

pro atvcontour, z, x, y, _extra = options
common atv_pdata
common atv_state

; Routine to read in contour plot data and options, store in a heap
; variable structure, and overplot the contours.  Data to be contoured
; need not be the same dataset displayed in the atv window, but it
; should have the same x and y dimensions in order to align the
; overplot correctly.

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

if (N_params() LT 1) then begin
   print, 'Too few parameters for ATVCONTOUR.'
   return
endif

if (n_params() EQ 1 OR n_params() EQ 2) then begin
    x = 0
    y = 0
endif

if (n_elements(options) EQ 0) then options = {c_color: 'red'}


;  convert color names to index numbers, and set default=red
c = where(tag_names(options) EQ 'C_COLOR', count)
if (count EQ 0) then options = create_struct(options, 'c_color', 'red')

pstruct = {type: 'contour',  $  ; type of plot
           z: z,             $  ; z values
           x: x,             $  ; x coordinate
           y: y,             $  ; y coordinate
           options: options  $  ; plot keyword options
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1contour, nplot-1

end

;----------------------------------------------------------------------

pro atverase, nerase, norefresh = norefresh
common atv_pdata

; Routine to erase line plots from ATVPLOT, text from ATVXYOUTS, and
; contours from ATVCONTOUR.

nplot = n_elements(atvplotlist)

if (n_params() LT 1) then begin
   if (nplot GE 1) then atvplotlist.remove, /all
endif else begin
   if (nerase GT nplot) then nerase = nplot
   for i = 1, nerase do begin
      atvplotlist.remove
   endfor
endelse

if (NOT keyword_set(norefresh)) then atv_refresh

end

;----------------------------------------------------------------------

pro atv_labelcolor, index, colorname
  
; translates menu options back to color names. Note that we use red as
; the first menu option by default, so red and black are switched from
; their normal order

  case index of
     0: colorname = 'red'
     1: colorname = 'black'
     2: colorname = 'green'
     3: colorname = 'blue'
     4: colorname = 'cyan'
     5: colorname = 'magenta'
     6: colorname = 'yellow'
     7: colorname = 'white'
     else: colorname = 'red'
  endcase

end

;----------------------------------------------------------------------

pro atv_textlabel

; widget front end for atvxyouts

formdesc = ['0, text, , label_left=Text: , width=15', $
            '0, integer, , label_left=x: ', $
            '0, integer, , label_left=y: ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 2.0, label_left=Charsize: ', $
            '0, integer, 1, label_left=Charthick: ', $
            '0, integer, 0, label_left=Orientation: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawText, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'atv text label')


if (textform.tag9 EQ 1) then begin

   atv_labelcolor, textform.tag3, labelcolor

   atvxyouts, textform.tag1, textform.tag2, textform.tag0, $
              color = labelcolor, charsize = textform.tag4, $
              charthick = textform.tag5, orientation = textform.tag6
endif

end

;---------------------------------------------------------------------

pro atv_setarrow

; widget front end for atvarrow

formdesc = ['0, integer, , label_left=Tail x: ', $
            '0, integer, , label_left=Tail y: ', $
            '0, integer, , label_left=Head x: ', $
            '0, integer, , label_left=Head y: ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, float, 1.0, label_left=LineThickness: ', $
            '0, float, 1.0, label_left=HeadThickness: ', $
            '1, base, , row', $
            '0, button, Cancel, quit', $
            '0, button, DrawArrow, quit']
            
textform = cw_form(formdesc, /column, $
                   title = 'atv arrow')

if (textform.tag9 EQ 1) then begin

   atv_labelcolor, textform.tag4, labelcolor

   atvarrow, textform.tag0, textform.tag1, $
             textform.tag2, textform.tag3, $
             color = labelcolor, thick = textform.tag5, $
             hthick = textform.tag6
   
endif

end


;--------------------------------------------------------------------

pro atv_oplotcontour

; widget front end for atvcontour

common atv_state
common atv_images

minvalstring = strcompress('0, float, ' + string(state.min_value) + $
                           ', label_left=MinValue: , width=15 ')
maxvalstring = strcompress('0, float, ' + string(state.max_value) + $
                           ', label_left=MaxValue: , width=15')

formdesc = ['0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
            '0, droplist, solid|dotted|dashed|dashdot|dashdotdotdot|longdash, label_left=Linestyle: , set_value=0', $
            '0, integer, 1, label_left=LineThickness: ', $
            minvalstring, $
            maxvalstring, $
            '0, integer, 6, label_left=NLevels: ', $
            '1, base, , row,', $
            '0, button, Cancel, quit', $
            '0, button, DrawContour, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv text label')


if (cform.tag8 EQ 1) then begin

   atv_labelcolor, cform.tag0, labelcolor

   atvcontour, main_image, c_color = labelcolor, $
;      c_charsize = cform.tag1, c_charthick = cform.tag2, $
               c_linestyle = cform.tag1, $
               c_thick = cform.tag2, $
               min_value = cform.tag3, max_value = cform.tag4, $, 
               nlevels = cform.tag5
endif

end

;---------------------------------------------------------------------

pro atv_setcompass

; Routine to prompt user for compass parameters

common atv_state
common atv_images
common atv_pdata

if (state.wcstype NE 'angle') then begin 
    atv_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.15 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=XCenter: ')
yposstring = strcompress('0,integer,'+ypos+',label_left=YCenter: ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, droplist, Vertex of Compass|Center of Compass, label_left = Coordinates Specify:, set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '0, float, 3.5, label_left=ArrowLength: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawCompass, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv compass properties')

if (cform.tag8 EQ 1) then return

cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)

atv_labelcolor, cform.tag3, labelcolor


pstruct = {type: 'compass',  $  ; type of plot
           x: cform.tag0,         $ 
           y: cform.tag1,         $
           notvertex: cform.tag2, $
           color: labelcolor, $
           thick: cform.tag4, $
           charsize: cform.tag5, $
           arrowlen: cform.tag6 $
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1compass, nplot-1

end

;---------------------------------------------------------------------

pro atv_setscalebar

; Routine to prompt user for scalebar parameters

common atv_state
common atv_images
common atv_pdata


if (state.wcstype NE 'angle') then begin 
    atv_message, 'Cannot get coordinate info for this image!', $
      msgtype = 'error', /window
    return
endif

view_min = round(state.centerpix - $
        (0.5 * state.draw_window_size / state.zoom_factor)) 
view_max = round(view_min + state.draw_window_size / state.zoom_factor) - 1

xpos = string(round(view_min[0] + 0.75 * (view_max[0] - view_min[0])))
ypos = string(round(view_min[1] + 0.15 * (view_max[1] - view_min[1])))

xposstring = strcompress('0,integer,'+xpos+',label_left=X (left end of bar): ')
yposstring = strcompress('0,integer,'+ypos+',label_left=Y (center of bar): ')

formdesc = [ $
             xposstring, $
             yposstring, $
             '0, float, 5.0, label_left=BarLength: ', $
             '0, droplist, arcsec|arcmin, label_left=Units:,set_value=0', $
             '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0 ', $
             '0, integer, 1, label_left=LineThickness: ', $
             '0, float, 1, label_left=Charsize: ', $
             '1, base, , row,', $
             '0, button, Cancel, quit', $
             '0, button, DrawScalebar, quit']
            
cform = cw_form(formdesc, /column, $
                   title = 'atv scalebar properties')

if (cform.tag8 EQ 1) then return

atv_labelcolor, cform.tag4, labelcolor

cform.tag0 = 0 > cform.tag0 < (state.image_size[0] - 1)
cform.tag1 = 0 > cform.tag1 < (state.image_size[1] - 1)
cform.tag3 = abs(cform.tag3 - 1)  ; set default to be arcseconds

arclen = cform.tag2
if (float(round(arclen)) EQ arclen) then arclen = round(arclen)

pstruct = {type: 'scalebar',  $  ; type of plot
           arclen: arclen, $
           seconds: cform.tag3, $
           position: [cform.tag0,cform.tag1], $ 
           color: labelcolor, $
           thick: cform.tag5, $
           size: cform.tag6 $
          }

atvplotlist.add, pstruct

atv_plotwindow
nplot = n_elements(atvplotlist)
atv_plot1scalebar, nplot-1

end

;------------------------------------------------------------------


pro atv_loadregion

common atv_state
common atv_pdata

; Routine to read in region filename, store in a heap variable
; structure, and overplot the regions

if (not(xregistered('atv', /noshow))) then begin
    print, 'You need to start ATV first!'
    return
endif

region_file = dialog_pickfile(/read, filter='*.reg')
if (region_file EQ '') then return

options = {color: 'green'}

readfmt, region_file, 'a200', reg_array, /silent

pstruct = {type:'region', $            ; type of plot
           reg_array: reg_array, $     ; array of regions to plot
           options: options $          ; plot keyword options
          }

atvplotlist.add, pstruct

atv_plotwindow
iplot = n_elements(atvplotlist) - 1
atv_plot1region, iplot

end

;----------------------------------------------------------------------

pro atv_saveregion

; Save currently displayed regions to a file

common atv_state
common atv_pdata

reg_savefile = dialog_pickfile(file='atv.reg', filter='*.reg', /write) 

if (reg_savefile ne '') then begin 
  openw, lun, reg_savefile, /get_lun

  nplot = n_elements(atvplotlist)

  for iplot = 0, nplot-1 do begin
     if (atvplotlist[iplot].type eq 'region') then begin
        n_regions = n_elements(atvplotlist[iplot].reg_array)
      for n = 0, n_regions - 1 do begin
        printf, lun, strcompress(atvplotlist[iplot].reg_array[n])
      endfor
    endif
  endfor

  close, lun
  free_lun, lun
endif else begin
  return
endelse

end



;--------------------------------------------------------------------

pro atv_setregion_event, event


; Event handler for atv_setregion.  Region plot structure created from
; information in form widget.  Plotting routine atv_plot1region is
; then called.

common atv_state
common atv_pdata

CASE event.tag OF
    
    'REG_OPT' : BEGIN
        CASE event.value OF
            '0' : BEGIN
                widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
                widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[7],Sensitive=0         
                widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
                widget_control,(*state.reg_ids_ptr)[10],Sensitive=0  
                widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
            END
            '1' : BEGIN
                widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
                widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[7],Sensitive=0         
                widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
                widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[11],Sensitive=1         
            END
            '2' : BEGIN
                widget_control,(*state.reg_ids_ptr)[3],Sensitive=1 
                widget_control,(*state.reg_ids_ptr)[4],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[5],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[6],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[7],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[8],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[9],Sensitive=0         
                widget_control,(*state.reg_ids_ptr)[10],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[11],Sensitive=1
            END
            '3' : BEGIN
                widget_control,(*state.reg_ids_ptr)[3],Sensitive=0 
                widget_control,(*state.reg_ids_ptr)[4],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[5],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[6],Sensitive=0
                widget_control,(*state.reg_ids_ptr)[7],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[8],Sensitive=1
                widget_control,(*state.reg_ids_ptr)[9],Sensitive=1         
                widget_control,(*state.reg_ids_ptr)[10],Sensitive=1  
                widget_control,(*state.reg_ids_ptr)[11],Sensitive=0
            END
            ELSE:
        ENDCASE
        
    END
    
    'QUIT': BEGIN
        if (ptr_valid(state.reg_ids_ptr)) then ptr_free, state.reg_ids_ptr
        widget_control, event.top, /destroy
    END
    
    'DRAW': BEGIN
       
       reg_type = ['circle','box','ellipse','line']
       reg_color = ['red','black','green','blue','cyan','magenta', $
                    'yellow','white']
       coords_type = ['Pixel', 'J2000','B1950', $
                      'Galactic','Ecliptic', 'Native']
       reg_index = widget_info((*state.reg_ids_ptr)[0], /droplist_select)
       color_index = $
          widget_info((*state.reg_ids_ptr)[1], /droplist_select)
       coords_index = $
          widget_info((*state.reg_ids_ptr)[2], /droplist_select) 
       widget_control,(*state.reg_ids_ptr)[3],get_value=xcenter 
       widget_control,(*state.reg_ids_ptr)[4],get_value=ycenter           
       widget_control,(*state.reg_ids_ptr)[5],get_value=xwidth
       widget_control,(*state.reg_ids_ptr)[6],get_value=ywidth
       widget_control,(*state.reg_ids_ptr)[7],get_value=x1            
       widget_control,(*state.reg_ids_ptr)[8],get_value=y1
       widget_control,(*state.reg_ids_ptr)[9],get_value=x2       
       widget_control,(*state.reg_ids_ptr)[10],get_value=y2
       widget_control,(*state.reg_ids_ptr)[11],get_value=angle
       widget_control,(*state.reg_ids_ptr)[12],get_value=thick
       widget_control,(*state.reg_ids_ptr)[13],get_value=text_str
       text_str = strcompress(text_str[0],/remove_all)
       
       CASE reg_type[reg_index] OF 
          
          'circle': BEGIN
             region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
                          ycenter + ', ' + xwidth  
             if (coords_index ne 0 and coords_index ne 5) then $
                region_str = $
                region_str + ', ' + coords_type[coords_index]
             region_str = $
                region_str + ') # color=' + reg_color[color_index]
          END
          
          'box': BEGIN
             region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
                          ycenter + ', ' + xwidth + ', ' + $
                          ywidth + ', ' + angle 
             if (coords_index ne 0 and coords_index ne 5) then $
                region_str = $
                region_str + ', ' + coords_type[coords_index]
             region_str = $
                region_str + ') # color=' + reg_color[color_index]
          END
          
          'ellipse': BEGIN
             region_str = reg_type[reg_index] + '(' + xcenter + ', ' + $
                          ycenter + ', ' + xwidth + ', ' + $
                          ywidth + ', ' + angle
             if (coords_index ne 0 and coords_index ne 5) then $
                region_str = $
                region_str + ', ' + coords_type[coords_index]
             region_str = $
                region_str + ') # color=' + reg_color[color_index]
          END
          
          'line': BEGIN
             region_str = reg_type[reg_index] + '(' + x1 + ', ' + y1 + ', ' + $
                          x2 + ', ' + y2
             if (coords_index ne 0 and coords_index ne 5) then $
                region_str = $
                region_str + ', ' + coords_type[coords_index]
             region_str = $
                region_str + ') # color=' + reg_color[color_index]
          END
          
          ELSE: 
       ENDCASE
       
       if (text_str ne '') then region_str = region_str + $
                                             ' text={' + text_str + '}'
       

       options = {color: reg_color[color_index], $
                  thick:thick}
       
       pstruct = {type:'region', $ ;type of plot
                  reg_array:[region_str], $ ;region array to plot
                  options: options $
                 }

       atvplotlist.add, pstruct
       
       atv_plotwindow
       nplot = n_elements(atvplotlist)
       atv_plot1region, nplot-1
            
        
;       if ptr_valid(state.reg_ids_ptr) then ptr_free, state.reg_ids_ptr
;       widget_control, event.top, /destroy
        
    END
    
    ELSE:
ENDCASE

end

;----------------------------------------------------------------------

pro atv_setregion

; Widget front-end for plotting individual regions on image

common atv_state
common atv_images
common atv_pdata  

if (not(xregistered('atv_setregion', /noshow))) then begin

regionbase = widget_base(/row, group_leader=state.base_id)
  
formdesc = ['0, droplist, circle|box|ellipse|line,label_left=Region:, set_value=0, TAG=reg_opt ', $
            '0, droplist, red|black|green|blue|cyan|magenta|yellow|white,label_left=Color:, set_value=0, TAG=color_opt ', $
            '0, droplist, Pixel|RA Dec (J2000)|RA Dec (B1950)|Galactic|Ecliptic|Native,label_left=Coords:, set_value=0, TAG=coord_opt ', $
            '0, text, 0, label_left=xcenter: , width=15', $
            '0, text, 0, label_left=ycenter: , width=15', $
            '0, text, 0, label_left=xwidth (Pix/ArcMin): , width=15', $
            '0, text, 0, label_left=ywidth (Pix/ArcMin): , width=15', $
            '0, text, 0, label_left=x1: , width=15', $
            '0, text, 0, label_left=y1: , width=15', $
            '0, text, 0, label_left=x2: , width=15', $
            '0, text, 0, label_left=y2: , width=15', $
            '0, text, 0.0, label_left=Angle: ', $
            '0, integer, 1, label_left=Thick: ', $
            '0, text,  , label_left=Text: ', $
            '1, base, , row', $
            '0, button, Done, quit, TAG=quit ', $
            '0, button, DrawRegion, quit, TAG=draw']
  
regionform = cw_form(regionbase, formdesc, /column, title = 'atv region',$
                     IDS=reg_ids_ptr)
state.regionform_id = regionbase

widget_control, regionbase, /REALIZE

xmanager, 'atv_setregion', regionbase, /no_block

reg_ids_ptr = reg_ids_ptr(where(widget_info(reg_ids_ptr,/type) eq 3 OR $
                                widget_info(reg_ids_ptr,/type) eq 8))

if ptr_valid(state.reg_ids_ptr) then ptr_free,state.reg_ids_ptr

state.reg_ids_ptr = ptr_new(reg_ids_ptr)

widget_control,(*state.reg_ids_ptr)[6],sensitive=0
widget_control,(*state.reg_ids_ptr)[7],sensitive=0
widget_control,(*state.reg_ids_ptr)[8],sensitive=0
widget_control,(*state.reg_ids_ptr)[9],sensitive=0
widget_control,(*state.reg_ids_ptr)[10],sensitive=0
widget_control,(*state.reg_ids_ptr)[11],sensitive=0

; still need to check and implement this stuff below.

; Check for WCS.  If WCS exists, then convert to display coordinates.
;if (ptr_valid(state.astr_ptr)) then begin
; Convert to display coordinates and change droplist selection.
    
;    if (state.wcstype EQ 'angle') then begin
;        xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat
;        
;        wcsstring = atv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
;                                  state.equinox, state.display_coord_sys, $
;                                  state.display_equinox, state.display_base60)
;        ;;
;
;        if (strpos(wcsstring, 'J2000') ne -1) then coord_select = 1
;        if (strpos(wcsstring, 'B1950') ne -1) then coord_select = 2
;        if (strpos(wcsstring, 'Galactic') ne -1) then coord_select = 3
;        if (strpos(wcsstring, 'Ecliptic') ne -1) then coord_select = 4
;        
;        if (strpos(wcsstring, 'J2000') eq -1 AND $
;            strpos(wcsstring, 'B1950') eq -1 AND $
;            strpos(wcsstring, 'Galactic') eq -1 AND $
;            strpos(wcsstring, 'Ecliptic') eq -1) then coord_select = 5
;        
;        wcsstring = repstr(wcsstring,'J2000','')
;        wcsstring = repstr(wcsstring,'B1950','')
;        wcsstring = repstr(wcsstring,'Deg','')
;        wcsstring = repstr(wcsstring,'Galactic','')
;        wcsstring = repstr(wcsstring,'Ecliptic','')
;        wcsstring = repstr(wcsstring,'(','')
;        wcsstring = repstr(wcsstring,')','')
;        
;        xcent = strcompress(gettok(wcsstring,','), /remove_all)
;        ycent = strcompress(wcsstring, /remove_all)
;        
;        widget_control,(*state.reg_ids_ptr)[3], Set_Value = xcent
;        widget_control,(*state.reg_ids_ptr)[4], Set_Value = ycent
;        widget_control,(*state.reg_ids_ptr)[7], Set_Value = xcent
;        widget_control,(*state.reg_ids_ptr)[8], Set_Value = ycent
;        widget_control,(*state.reg_ids_ptr)[2], set_droplist_select=coord_select
;    endif    
;    
;endif else begin
;    widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
;      strcompress(string(state.coord[0]), /remove_all)
;    widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
;      strcompress(string(state.coord[1]), /remove_all)
;    widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
;      strcompress(string(state.coord[0]), /remove_all)
;    widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
;      strcompress(string(state.coord[1]), /remove_all)
;endelse

xmanager, 'atv_setregion', regionbase

endif else begin
    
    if (ptr_valid(state.astr_ptr)) then begin
; Convert to display coordinates and change droplist selection.
        
        if (state.wcstype EQ 'angle') then begin
            xy2ad, state.coord[0], state.coord[1], *(state.astr_ptr), lon, lat
            
            wcsstring = atv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
                                      state.equinox, state.display_coord_sys, $
                                      state.display_equinox, state.display_base60)

      if (strpos(wcsstring, 'J2000') ne -1) then coord_select = 1
      if (strpos(wcsstring, 'B1950') ne -1) then coord_select = 2
      if (strpos(wcsstring, 'Galactic') ne -1) then coord_select = 3
      if (strpos(wcsstring, 'Ecliptic') ne -1) then coord_select = 4
      
      if (strpos(wcsstring, 'J2000') eq -1 AND $
          strpos(wcsstring, 'B1950') eq -1 AND $
          strpos(wcsstring, 'Galactic') eq -1 AND $
          strpos(wcsstring, 'Ecliptic') eq -1) then coord_select = 5
      
      wcsstring = repstr(wcsstring,'J2000','')
      wcsstring = repstr(wcsstring,'B1950','')
      wcsstring = repstr(wcsstring,'Deg','')
      wcsstring = repstr(wcsstring,'Galactic','')
      wcsstring = repstr(wcsstring,'Ecliptic','')
      wcsstring = repstr(wcsstring,'(','')
      wcsstring = repstr(wcsstring,')','')

      xcent = strcompress(gettok(wcsstring,','), /remove_all)
      ycent = strcompress(wcsstring, /remove_all)

      widget_control,(*state.reg_ids_ptr)[3], Set_Value = xcent
      widget_control,(*state.reg_ids_ptr)[4], Set_Value = ycent
      widget_control,(*state.reg_ids_ptr)[7], Set_Value = xcent
      widget_control,(*state.reg_ids_ptr)[8], Set_Value = ycent
      widget_control,(*state.reg_ids_ptr)[2], set_droplist_select=coord_select
  endif  
  
endif else begin
    widget_control,(*state.reg_ids_ptr)[3], Set_Value = $
      strcompress(string(state.coord[0]), /remove_all)
    widget_control,(*state.reg_ids_ptr)[4], Set_Value = $
      strcompress(string(state.coord[1]), /remove_all)
    widget_control,(*state.reg_ids_ptr)[7], Set_Value = $
      strcompress(string(state.coord[0]), /remove_all)
    widget_control,(*state.reg_ids_ptr)[8], Set_Value = $
      strcompress(string(state.coord[1]), /remove_all)
endelse

endelse

end



;---------------------------------------------------------------------
;          routines for drawing in the lineplot window
;---------------------------------------------------------------------

pro atv_lineplot_init

; This routine creates the window for line plots

common atv_state

state.lineplot_base_id = $
  widget_base(group_leader = state.base_id, $
              /row, $
              /base_align_right, $
              title = 'atv plot', $
              /tlb_size_events, $
              uvalue = 'lineplot_base')

state.lineplot_widget_id = $
  widget_draw(state.lineplot_base_id, $
              frame = 0, $
              scr_xsize = state.lineplot_size[0], $
              scr_ysize = state.lineplot_size[1], $
              uvalue = 'lineplot_window')

lbutton_base = $
  widget_base(state.lineplot_base_id, $
              /base_align_bottom, $
              /column, frame=2)

state.histbutton_base_id = $
  widget_base(lbutton_base, $
              /base_align_bottom, $
              /column, map=1)

state.x1_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'X1:', $
             uvalue = 'lineplot_newrange', $
             xsize = 12)

state.x2_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'X2:', $
             uvalue = 'lineplot_newrange', $
             xsize = 12)

state.y1_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Y1:', $
             uvalue = 'lineplot_newrange', $
             xsize = 12)

state.y2_pix_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Y2:', $
             uvalue = 'lineplot_newrange', $
             xsize = 12)

state.histplot_binsize_id = $
    cw_field(state.histbutton_base_id, $
             /return_events, $
             /floating, $
             title = 'Bin:', $
             uvalue = 'lineplot_newrange', $
             xsize = 12)

state.lineplot_xmin_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'XMin:', $
           uvalue = 'lineplot_newrange', $
           xsize = 12)

state.lineplot_xmax_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'XMax:', $
           uvalue = 'lineplot_newrange', $
           xsize = 12)

state.lineplot_ymin_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'YMin:', $
           uvalue = 'lineplot_newrange', $
           xsize = 12)

state.lineplot_ymax_id = $
  cw_field(lbutton_base, $
           /return_events, $
           /floating, $
           title = 'YMax:', $
           uvalue = 'lineplot_newrange', $
           xsize = 12)

state.lineplot_charsize_id = $
   cw_field(lbutton_base, $
            /return_events, $
            /floating, $
            title = 'Charsize:', $
            uvalue = 'lineplot_charsize', $
            value = state.plotcharsize, $
            xsize = 7)

state.holdrange_base_id = $
  widget_base(lbutton_base, $
              row = 1, $
              /nonexclusive, frame=1)

state.holdrange_button_id = $
  widget_button(state.holdrange_base_id, $
                value = 'Hold Ranges', $
                uvalue = 'lineplot_holdrange')

lineplot_fullrange = $
  widget_button(lbutton_base, $
                value = 'FullRange', $
                uvalue = 'lineplot_fullrange')

lineplot_ps = $
  widget_button(lbutton_base, $
                value = 'Create PS', $
                uvalue = 'lineplot_ps')

lineplot_done = $
  widget_button(lbutton_base, $
                value = 'Done', $
                uvalue = 'lineplot_done')

widget_control, state.lineplot_base_id, /realize
widget_control, state.holdrange_button_id, set_button=state.holdrange_value

widget_control, state.lineplot_widget_id, get_value = tmp_value
state.lineplot_window_id = tmp_value

lbuttgeom = widget_info(lbutton_base, /geometry)
state.lineplot_min_size[1] = lbuttgeom.ysize

basegeom = widget_info(state.lineplot_base_id, /geometry)
drawgeom = widget_info(state.lineplot_widget_id, /geometry)

state.lineplot_pad[0] = basegeom.xsize - drawgeom.xsize
state.lineplot_pad[1] = basegeom.ysize - drawgeom.ysize
    
xmanager, 'atv_lineplot', state.lineplot_base_id, /no_block

atv_resetwindow
end

;--------------------------------------------------------------------

pro atv_rowplot, ps=ps, fullrange=fullrange, newcoord=newcoord

; draws a new row plot in the plot window or to postscript output

common atv_state
common atv_images

if (keyword_set(ps)) then begin
    thick = 3
    color = 'black'
    background='white'
endif else begin
    thick = 1
    color = 'white'
    background='black'
endelse

if (keyword_set(newcoord)) then state.plot_coord = state.coord

if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif 

    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'rowplot' OR $
        keyword_set(fullrange) OR $
        (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
        xmin = 0.0
        xmax = state.image_size[0]
        ymin = min(main_image[*,state.plot_coord[1]])
        ymax = max(main_image[*,state.plot_coord[1]]) 
    endif
   
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'rowplot'
    atv_setwindow, state.lineplot_window_id
    erase
    
endif

cgplot, main_image[*, state.plot_coord[1]], $
        xst = 3, yst = 3, psym = 10, $
        title = strcompress('Plot of row ' + $
                            string(state.plot_coord[1])), $
        xtitle = 'Column', $
        ytitle = 'Pixel Value', $
        color = color, background = background, $
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end


;--------------------------------------------------------------------

pro atv_colplot, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse

if (keyword_set(newcoord)) then state.plot_coord = state.coord

if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif 

    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'colplot' OR $
        keyword_set(fullrange) OR $
       (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
        xmin = 0.0
        xmax = state.image_size[1]
        ymin = min(main_image[state.plot_coord[0],*])
        ymax = max(main_image[state.plot_coord[0],*]) 
    endif
    
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'colplot'
    atv_setwindow, state.lineplot_window_id
    erase
    
endif


cgplot, main_image[state.plot_coord[0], *], $
        xst = 3, yst = 3, psym = 10, $
        title = strcompress('Plot of column ' + $
                            string(state.plot_coord[0])), $
        xtitle = 'Row', $
        ytitle = 'Pixel Value', $
        color = color, background = background, $
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize


if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end


;----------------------------------------------------------------------

pro atv_vectorplot, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse


d = sqrt((state.vector_coord1[0]-state.vector_coord2[0])^2 + $
         (state.vector_coord1[1]-state.vector_coord2[1])^2)

v_d = fix(d + 1)
dx = (state.vector_coord2[0]-state.vector_coord1[0]) / float(v_d - 1)
dy = (state.vector_coord2[1]-state.vector_coord1[1]) / float(v_d - 1)

x = fltarr(v_d)
y = fltarr(v_d)
vectdist = indgen(v_d)
pixval = fltarr(v_d)

x[0] = state.vector_coord1[0]
y[0] = state.vector_coord1[1]
for i = 1, n_elements(x) - 1 do begin
    x[i] = state.vector_coord1[0] + dx * i
    y[i] = state.vector_coord1[1] + dy * i
endfor



for j = 0, n_elements(x) - 1 do begin
    col = x[j]
    row = y[j]
    floor_col = floor(col)
    ceil_col = ceil(col)
    floor_row = floor(row)
    ceil_row = ceil(row)
    
    pixval[j] = (total([main_image[floor_col,floor_row], $
                        main_image[floor_col,ceil_row], $
                        main_image[ceil_col,floor_row], $
                        main_image[ceil_col,ceil_row]])) / 4.
    
endfor

if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'vectorplot' OR $
        keyword_set(fullrange) OR $
       (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
        xmin = 0.0
        xmax = max(vectdist)
        ymin = min(pixval)
        ymax = max(pixval) 
        
    endif 

    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'vectorplot'
    atv_setwindow, state.lineplot_window_id
    erase

endif
  
vecdistsq = float(state.vector_coord2[0] - state.vector_coord1[0])^2 + $
            float(state.vector_coord2[1] - state.vector_coord1[1])^2
vecdist = sqrt(vecdistsq)

plottitle = strcompress('Plot of vector [' + $
                        strcompress(string(state.vector_coord1[0]) + ',' + $
                                    string(state.vector_coord1[1]), $
                                    /remove_all) + $
                        '] to [' + $
                        strcompress(string(state.vector_coord2[0]) + ',' + $
                                    string(state.vector_coord2[1]), $
                                    /remove_all) + ']')

xtitle = strcompress('Vector Distance (pixels); Total Length = ' $
                     + string(vecdist))

cgplot, vectdist, pixval, $
        xst = 3, yst = 3, psym = 10, $
        title = plottitle, $
        xtitle = xtitle, $
        ytitle = 'Pixel Value', $
        color = color, background = background, $
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize


if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end

;----------------------------------------------------------------------

pro atv_gaussfit, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse


d = sqrt((state.vector_coord1[0]-state.vector_coord2[0])^2 + $
         (state.vector_coord1[1]-state.vector_coord2[1])^2)

v_d = fix(d + 1)
dx = (state.vector_coord2[0]-state.vector_coord1[0]) / float(v_d - 1)
dy = (state.vector_coord2[1]-state.vector_coord1[1]) / float(v_d - 1)

x = fltarr(v_d)
y = fltarr(v_d)
vectdist = indgen(v_d)
pixval = fltarr(v_d)

x[0] = state.vector_coord1[0]
y[0] = state.vector_coord1[1]
for i = 1, n_elements(x) - 1 do begin
    x[i] = state.vector_coord1[0] + dx * i
    y[i] = state.vector_coord1[1] + dy * i
endfor



for j = 0, n_elements(x) - 1 do begin
    col = x[j]
    row = y[j]
    floor_col = floor(col)
    ceil_col = ceil(col)
    floor_row = floor(row)
    ceil_row = ceil(row)
    
    pixval[j] = (total([main_image[floor_col,floor_row], $
                        main_image[floor_col,ceil_row], $
                        main_image[ceil_col,floor_row], $
                        main_image[ceil_col,ceil_row]])) / 4.
    
endfor

if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'gaussplot' OR $
        keyword_set(fullrange) OR $
       (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
        xmin = 0.0
        xmax = max(vectdist)
        ymin = min(pixval)
        ymax = max(pixval) 
        
    endif 

    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'gaussplot'
    atv_setwindow, state.lineplot_window_id
    erase

endif
  

plottitle = strcompress('Gaussfit: vector [' + $
                        strcompress(string(state.vector_coord1[0]) + ',' + $
                                    string(state.vector_coord1[1]), $
                                    /remove_all) + $
                        '] to [' + $
                        strcompress(string(state.vector_coord2[0]) + ',' + $
                                    string(state.vector_coord2[1]), $
                                    /remove_all) + ']')

cgplot, vectdist, pixval, $
        xst = 3, yst = 3, psym = 10, $
        title = plottitle, $
        xtitle = 'Vector Distance', $
        ytitle = 'Pixel Value', $
        color = color, background = background, $ 
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize

; do the fit

if (n_elements(vectdist) GT 10) then begin
   result = gaussfit(vectdist, pixval, a, nterms=5)
   
;   oplot, vectdist, result, color=1
   cgplot, vectdist, result, color='red', /overplot

   amplitude = a[0]
   centroid = a[1]
   fwhm = a[2] * 2.35
   
   fwhmstring = strcompress(string(fwhm, format='("FWHM = ", f7.2)'), $
                            /remove_all)
   
   xyouts, 0.25, 0.85, fwhmstring, /normal, charsize = state.plotcharsize
   
endif

if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end


;--------------------------------------------------------------------

pro atv_depthplot, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images

if (state.cube NE 1) then return

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse

if (ptr_valid(state.head_ptr)) then head = *(state.head_ptr) $
   else head = strarr(1)

cd = float(sxpar(head,'CD1_1', /silent))
if (cd EQ 0.0) then $
   cd = float(sxpar(head,'CDELT1', /silent))
crpix = float(sxpar(head,'CRPIX1', /silent)) - 1
crval = float(sxpar(head,'CRVAL1', /silent))
shifta = float(sxpar(head, 'SHIFTA1', /silent))

wave = (findgen(state.nslices) * cd) + crval
if (max(wave) EQ min(wave)) then begin
   wave = findgen(state.nslices)
endif


x1 = min([state.vector_coord1[0],state.vector_coord2[0]])
x2 = max([state.vector_coord1[0],state.vector_coord2[0]])
y1 = min([state.vector_coord1[1],state.vector_coord2[1]])
y2 = max([state.vector_coord1[1],state.vector_coord2[1]])

pixval = main_image_cube[x1:x2, y1:y2, *]

; collapse to a 1d spectrum:
pixval = total(total(pixval,1),1)

if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'depthplot' OR $
        keyword_set(fullrange) OR $
       (state.holdrange_value EQ 0 AND keyword_set(newcoord))) then begin
        xmin = min(wave)
        xmax = max(wave)
        ymin = min(pixval)
        ymax = max(pixval) 
        
    endif 

    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'depthplot'
    atv_setwindow, state.lineplot_window_id
    erase

endif
  

plottitle = strcompress('Depth plot [' + $
                       string(x1) + ':' + string(x2) + ',' + $
                       string(y1) + ':' + string(y2) + ']')

if (state.cunit NE '') then begin
   xunit = state.cunit
   xunittype = 'Wavelength'
endif else begin
   xunit = 'pixel'
   xunittype = 'Slice'
endelse

cgplot, wave, pixval, $
        xst = 3, yst = 3, psym = 10, $
        title = plottitle, $
        xtitle = strcompress(xunittype + ' (' + xunit + ')') , $
        ytitle = 'Flux', $
        color = color, background = background, $
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize



if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end

;--------------------------------------------------------------------

pro atv_surfplot, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse


if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=0
    
; set new plot coords if passed from a main window keyboard event
    if (keyword_set(newcoord)) then begin
        plotsize = $
          fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
        center = plotsize > state.coord < (state.image_size[0:1] - plotsize) 
        
        shade_image = main_image[center[0]-plotsize:center[0]+plotsize-1, $
                                 center[1]-plotsize:center[1]+plotsize-1]
        
        state.lineplot_xmin = center[0]-plotsize
        state.lineplot_xmax = center[0]+plotsize-1
        state.lineplot_ymin = center[1]-plotsize 
        state.lineplot_ymax = center[1]+plotsize-1
        
        state.plot_coord = state.coord
        
        widget_control, state.lineplot_xmin_id, $
          set_value = state.lineplot_xmin
        widget_control, state.lineplot_xmax_id, $
          set_value = state.lineplot_xmax
        widget_control, state.lineplot_ymin_id, $
          set_value = state.lineplot_ymin
        widget_control, state.lineplot_ymax_id, $
          set_value = state.lineplot_ymax
    endif
    
    if (keyword_set(fullrange)) then begin
        widget_control, state.lineplot_xmin_id, set_value = 0
        widget_control, state.lineplot_xmax_id, $
          set_value = state.image_size[0]-1
        widget_control, state.lineplot_ymin_id, set_value = 0
        widget_control, state.lineplot_ymax_id, $
          set_value = state.image_size[1]-1
    endif

    state.plot_type = 'surfplot'
    atv_setwindow, state.lineplot_window_id
    erase
    
; now get plot coords from the widget box   
    widget_control,state.lineplot_xmin_id, get_value=xmin
    widget_control,state.lineplot_xmax_id, get_value=xmax
    widget_control,state.lineplot_ymin_id, get_value=ymin
    widget_control,state.lineplot_ymax_id, get_value=ymax  

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax
endif


shade_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                          state.lineplot_ymin:state.lineplot_ymax]

plottitle = $
  strcompress('Surface plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))

xdim = state.lineplot_xmax - state.lineplot_xmin + 1
ydim = state.lineplot_ymax - state.lineplot_ymin + 1

xran = lindgen(xdim) + state.lineplot_xmin
yran = lindgen(ydim) + state.lineplot_ymin

; reload the color table of the main window with default brightness
; and contrast, to make the surface plot come out ok
atv_stretchct, 0.5, 0.5

cgloadct, 25, /brewer, /reverse
cgsurf, shade_image, shades=bytscl(shade_image), xran, yran, /noerase, $
        title = plottitle, xtitle = 'X', ytitle = 'Y', $
        ztitle = 'Pixel Value', $
        charsize = state.plotcharsize, $
        background=background, color=color



if (not (keyword_set(ps))) then begin 
    widget_control, state.lineplot_base_id, /clear_events
    atv_resetwindow
endif

end


;--------------------------------------------------------------------

pro atv_contourplot, ps=ps, fullrange=fullrange, newcoord=newcoord

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse

common atv_state
common atv_images

if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=0
    
    if (keyword_set(newcoord)) then begin
        
        plotsize = $
          fix(min([50, state.image_size[0]/2., state.image_size[1]/2.]))
        center = plotsize > state.coord < (state.image_size[0:1] - plotsize) 
        
        contour_image =  main_image[center[0]-plotsize:center[0]+plotsize-1, $
                                    center[1]-plotsize:center[1]+plotsize-1]
        
        state.lineplot_xmin = center[0]-plotsize
        state.lineplot_xmax = center[0]+plotsize-1
        state.lineplot_ymin = center[1]-plotsize
        state.lineplot_ymax = center[1]+plotsize-1
                
        state.plot_coord = state.coord

        widget_control,state.lineplot_xmin_id, $
          set_value=state.lineplot_xmin
        widget_control,state.lineplot_xmax_id, $
          set_value=state.lineplot_xmax
        widget_control,state.lineplot_ymin_id, $
          set_value=state.lineplot_ymin
        widget_control,state.lineplot_ymax_id, $
          set_value=state.lineplot_ymax
    endif
    
    if (keyword_set(fullrange)) then begin
        widget_control, state.lineplot_xmin_id, set_value = 0
        widget_control, state.lineplot_xmax_id, $
          set_value = state.image_size[0]-1
        widget_control, state.lineplot_ymin_id, set_value = 0
        widget_control, state.lineplot_ymax_id, $
          set_value = state.image_size[1]-1
    endif

    state.plot_type = 'contourplot'
    atv_setwindow, state.lineplot_window_id
    erase
    
; now get plot coords from the widget box   
    widget_control,state.lineplot_xmin_id, get_value=xmin
    widget_control,state.lineplot_xmax_id, get_value=xmax
    widget_control,state.lineplot_ymin_id, get_value=ymin
    widget_control,state.lineplot_ymax_id, get_value=ymax  

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax   
endif

contour_image =  main_image[state.lineplot_xmin:state.lineplot_xmax, $
                            state.lineplot_ymin:state.lineplot_ymax]


if (state.scaling EQ 1) then begin
    contour_image = alog10(contour_image)
    logflag = 'Log'
endif else begin
    logflag = ''
endelse

plottitle =  $
  strcompress(logflag + $
              ' Contour plot of ' + $
              strcompress('['+string(round(state.lineplot_xmin))+ $
                          ':'+string(round(state.lineplot_xmax))+ $
                          ','+string(round(state.lineplot_ymin))+ $
                          ':'+string(round(state.lineplot_ymax))+ $
                          ']', /remove_all))


xdim = state.lineplot_xmax - state.lineplot_xmin + 1
ydim = state.lineplot_ymax - state.lineplot_ymin + 1

xran = lindgen(xdim) + state.lineplot_xmin
yran = lindgen(ydim) + state.lineplot_ymin

cgcontour, temporary(contour_image), $
           xran, yran, $
           nlevels = 10, $
           /follow, $
           title = plottitle, $
           xtitle = 'X', ytitle = 'Y', $
           color = color, background = background,  $
           thick = thick, xthick = thick, ythick = thick, charthick = thick, $
           charsize = state.plotcharsize


if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end

;----------------------------------------------------------------------

pro atv_histplot, ps=ps, fullrange=fullrange, newcoord=newcoord

common atv_state
common atv_images


if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse

if (not (keyword_set(ps))) then begin

    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif
    
    widget_control, state.histbutton_base_id, map=1
    widget_control, state.holdrange_button_id, sensitive=0
    
    if (keyword_set(newcoord)) then begin
        
        state.plot_coord = state.coord
        plotsize_x = $
          fix(min([20, state.image_size[0]/2.]))
        plotsize_y = $
          fix(min([20, state.image_size[1]/2.]))
        
; Establish pixel boundaries to histogram
        x1 = (state.plot_coord[0]-plotsize_x) > 0.
        x2 = (state.plot_coord[0]+plotsize_x) < (state.image_size[0]-1)
        y1 = (state.plot_coord[1]-plotsize_y) > 0.
        y2 = (state.plot_coord[1]+plotsize_y) < (state.image_size[1]-1)
        
        widget_control, state.x1_pix_id, set_value=x1
        widget_control, state.x2_pix_id, set_value=x2
        widget_control, state.y1_pix_id, set_value=y1
        widget_control, state.y2_pix_id, set_value=y2
    endif

    state.plot_type = 'histplot'
    atv_setwindow, state.lineplot_window_id
    erase
endif


; get histogram region 
widget_control, state.x1_pix_id, get_value=x1
widget_control, state.x2_pix_id, get_value=x2
widget_control, state.y1_pix_id, get_value=y1
widget_control, state.y2_pix_id, get_value=y2        
hist_image = main_image[x1:x2, y1:y2]

; initialize the binsize if necessary
if (state.binsize EQ 0 OR keyword_set(newcoord)) then begin
    nbins = 50.
    state.binsize = (float(max(hist_image)) - float(min(hist_image)) ) / nbins
    if (abs(state.binsize) GT 10) then $
      state.binsize = fix(state.binsize)
    widget_control, state.histplot_binsize_id, set_value=state.binsize
endif

; Call plothist to create histogram arrays
plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, /noplot
   
; Only initialize plot window and plot ranges to the min/max ranges
; when histplot window is not already present or plot window is present
; but last plot was not a histplot.  Otherwise, use the values
; currently in the min/max boxes

if (keyword_set(newcoord) OR keyword_set(fullrange)) then begin
    state.lineplot_xmin = min(hist_image)
    state.lineplot_xmax = max(hist_image)
    state.lineplot_ymin = 0.
    state.lineplot_ymax = round(max(yhist) * 1.1)
    widget_control, state.lineplot_xmin_id, set_value = state.lineplot_xmin
    widget_control, state.lineplot_xmax_id, set_value = state.lineplot_xmax
    widget_control, state.lineplot_ymin_id, set_value = state.lineplot_ymin
    widget_control, state.lineplot_ymax_id, set_value = state.lineplot_ymax
endif

widget_control, state.histplot_binsize_id, get_value=binsize
widget_control, state.lineplot_xmin_id, get_value=xmin
widget_control, state.lineplot_xmax_id, get_value=xmax
widget_control, state.lineplot_ymin_id, get_value=ymin
widget_control, state.lineplot_ymax_id, get_value=ymax

state.binsize = binsize
state.lineplot_xmin = xmin
state.lineplot_xmax = xmax
state.lineplot_ymin = ymin
state.lineplot_ymax = ymax

plottitle = $
  strcompress('Histogram plot of ' + $
              strcompress('['+string(round(x1))+ $
                          ':'+string(round(x2))+ $
                          ','+string(round(y1))+ $
                          ':'+string(round(y2))+ $
                          ']', /remove_all))

;Plot histogram with proper ranges
plothist, hist_image, xhist, yhist, bin=state.binsize, /NaN, $
          xtitle='Pixel Value', ytitle='Number', title=plottitle, $
          xran=[state.lineplot_xmin,state.lineplot_xmax], $
          yran=[state.lineplot_ymin,state.lineplot_ymax], $
          xstyle=1, ystyle=1, $
          thick = thick, xthick = thick, ythick = thick, charthick = thick, $
          charsize = state.plotcharsize, $
          color = color, background = background


if (not (keyword_set(ps))) then begin 
    widget_control, state.lineplot_base_id, /clear_events
    atv_resetwindow
endif

end


;----------------------------------------------------------------------

pro atv_lineplot_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'lineplot_done': begin
        widget_control, event.top, /destroy
        state.plot_type = ''
    end

    'lineplot_base': begin      ; Resize event
        state.lineplot_size = [event.x, event.y]- state.lineplot_pad
        widget_control, state.lineplot_widget_id, $
          xsize = (state.lineplot_size[0] > state.lineplot_min_size[0]), $
          ysize = (state.lineplot_size[1] > state.lineplot_min_size[1])

        case state.plot_type of
            'rowplot': atv_rowplot
            'colplot': atv_colplot
            'vectorplot': atv_vectorplot
            'gaussplot': atv_gaussfit
            'histplot': atv_histplot
            'surfplot': atv_surfplot
            'contourplot': atv_contourplot
            'specplot': atv_specplot
            'depthplot': atv_depthplot
        endcase
    end

    'lineplot_holdrange': begin
        if (state.holdrange_value eq 1) then state.holdrange_value = 0 $
        else state.holdrange_value = 1
    end
    
    'lineplot_fullrange': begin
        case state.plot_type of
            'rowplot': atv_rowplot, /fullrange
            'colplot': atv_colplot, /fullrange
            'vectorplot': atv_vectorplot, /fullrange
            'gaussplot': atv_gaussfit, /fullrange
            'histplot': atv_histplot, /fullrange
            'surfplot': atv_surfplot, /fullrange
            'contourplot': atv_contourplot, /fullrange
            'specplot': atv_specplot, /fullrange
            'depthplot': atv_depthplot, /fullrange
            else:
        endcase
    end


    'lineplot_ps': begin

       if (state.ispsformon EQ 1) then return
        fname = strcompress(state.current_dir + 'atv_plot.ps', /remove_all)
        state.ispsformon = 1
        lpforminfo = cmps_form(cancel = canceled, create = create, $
                             parent = state.lineplot_base_id, $
                             /preserve_aspect, $
                             /color, $
                             /nocommon, papersize='Letter', $
                             filename = fname, $
                             button_names = ['Create PS File'])
        
        state.ispsformon = 0
        if (canceled) then return
        if (lpforminfo.filename EQ '') then return
        
        tmp_result = findfile(lpforminfo.filename, count = nfiles)
        
        result = ''
        if (nfiles GT 0) then begin
            mesg = strarr(2)
            mesg[0] = 'Overwrite existing file:'
            tmp_string = $
               strmid(lpforminfo.filename, strpos(lpforminfo.filename, $
                                                          '/') + 1)
            mesg[1] = strcompress(tmp_string + '?', /remove_all)
            result =  dialog_message(mesg, $
                                     /default_no, $
                                     dialog_parent = state.base_id, $
                                     /question)                 
        endif
        
        if (strupcase(result) EQ 'NO') then return
        
        widget_control, /hourglass
        
        screen_device = !d.name
        set_plot, 'ps'
        device, _extra = lpforminfo
        
        case (state.plot_type) of
            'rowplot': atv_rowplot, /ps
            'colplot': atv_colplot, /ps
            'vectorplot': atv_vectorplot, /ps
            'gaussplot': atv_gaussfit, /ps
            'histplot': atv_histplot, /ps
            'surfplot': atv_surfplot, /ps
            'contourplot': atv_contourplot, /ps
            'specplot': atv_specplot, /ps
            'depthplot': atv_depthplot, /ps
            else:
        endcase
        
        device, /close
        set_plot, screen_device
        
    end    
    
    'lineplot_charsize': begin
       widget_control, state.lineplot_charsize_id, get_value = newcharsize
       newcharsize = newcharsize > 0.2
       state.plotcharsize = newcharsize
       widget_control, state.lineplot_charsize_id, set_value = newcharsize
       case state.plot_type of
          'rowplot': atv_rowplot
          'colplot': atv_colplot
          'vectorplot': atv_vectorplot
          'gaussplot': atv_gaussfit
          'histplot': atv_histplot
          'surfplot': atv_surfplot
          'contourplot': atv_contourplot
          'specplot': atv_specplot
          'depthplot': atv_depthplot
       endcase

    end

    'lineplot_newrange': begin
        
        widget_control, state.lineplot_xmin_id, get_value = xmin
        widget_control, state.lineplot_xmax_id, get_value = xmax
        widget_control, state.lineplot_ymin_id, get_value = ymin
        widget_control, state.lineplot_ymax_id, get_value = ymax
        
        ; check plot ranges for validity
        if (state.plot_type EQ 'surfplot' OR $
            state.plot_type EQ 'contourplot') then begin
            
            xmin = fix(round(0 > xmin < (state.image_size[0] - 2)))
            xmax = fix(round(1 > xmax < (state.image_size[0] - 1)))
            ymin = fix(round(0 > ymin < (state.image_size[1] - 2)))
            ymax = fix(round(1 > ymax < (state.image_size[1] - 1)))

            if (event.id EQ state.lineplot_xmin_id) then $
              if (xmin GT xmax) then xmin = xmax-1
            if (event.id EQ state.lineplot_xmax_id) then $
              if (xmax LT xmin) then xmax = xmin+1
            if (event.id EQ state.lineplot_ymin_id) then $
              if (ymin GT ymax) then ymin = ymax-1
            if (event.id EQ state.lineplot_xmax_id) then $
              if (ymax LT ymin) then ymax = ymin+1
            
        endif
        
        state.lineplot_xmin = xmin
        state.lineplot_xmax = xmax
        state.lineplot_ymin = ymin
        state.lineplot_ymax = ymax
        
        widget_control, state.lineplot_xmin_id, set_value = xmin
        widget_control, state.lineplot_xmax_id, set_value = xmax
        widget_control, state.lineplot_ymin_id, set_value = ymin
        widget_control, state.lineplot_ymax_id, set_value = ymax

        case state.plot_type of
            'rowplot': atv_rowplot
            'colplot': atv_colplot
            'vectorplot': atv_vectorplot
            'gaussplot': atv_gaussfit
            'surfplot': atv_surfplot
            'contourplot': atv_contourplot
            'specplot': atv_specplot
            'depthplot': atv_depthplot

            'histplot': begin

               ; check requested plot ranges and bin size for validity

                if (event.id EQ state.x1_pix_id) then begin
                    widget_control, state.x1_pix_id, get_value=x1
                    widget_control, state.x2_pix_id, get_value=x2
                    if (x1 GT x2) then x1 = x2 - 1
                    if (x1 LT 0) then x1 = 0
                    widget_control, state.x1_pix_id, set_value=x1
                endif

                if (event.id EQ state.x2_pix_id) then begin
                    widget_control, state.x1_pix_id, get_value=x1
                    widget_control, state.x2_pix_id, get_value=x2
                    if (x1 GT x2) then x2 = x1 + 1
                    if (x2 GT state.image_size[0]-1) then $
                      x2 = state.image_size[0] - 1
                    widget_control, state.x2_pix_id, set_value=x2
                endif

                if (event.id EQ state.y1_pix_id) then begin
                    widget_control, state.y1_pix_id, get_value=y1
                    widget_control, state.y2_pix_id, get_value=y2
                    if (y1 GT y2) then y1 = y2 - 1
                    if (y1 LT 0) then y1 = 0
                    widget_control, state.y1_pix_id, set_value=y1
                endif

                if (event.id EQ state.y2_pix_id) then begin
                    widget_control, state.y1_pix_id, get_value=y1
                    widget_control, state.y2_pix_id, get_value=y2
                    if (y1 GT y2) then y2 = y1 + 1 
                    if (y2 GT state.image_size[1]-1) then $
                      y2 = state.image_size[1]-1
                    widget_control, state.y2_pix_id, set_value=y2
                endif
                
                if (event.id EQ state.histplot_binsize_id) then begin
                    b = event.value
                    if (event.value LE 0) then begin
                        atv_message, 'Bin size must be >0.', $
                          msgtype='error', /window
                        widget_control, state.histplot_binsize_id, $
                          set_value = 1.0
                    endif
                endif
                
                atv_histplot
            end 
             
            else:
        endcase 
    end 
    
else:
endcase

end


;----------------------------------------------------------------------
;                         help window
;---------------------------------------------------------------------

pro atv_help
common atv_state

h = strarr(132)
i = 0
h[i] =  'ATV HELP'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'MENU BAR:'
i = i + 1
h[i] =  'File->ReadFits:         Read in a new fits image from disk'
i = i + 1
h[i] =  'File->WritePS:          Write a PostScript file of the current display'
i = i + 1
h[i] =  'File->WriteImage:       Write an output png, jpg, or tiff image of the current display'
i = i + 1
h[i] =  'File->GetImage:         Download an archival image based on object name or coordinates'  
i = i + 1
h[i] =  'File->Quit:             Quits atv'
i = i + 1
h[i] =  'ColorMap Menu:          Selects color table'
i = i + 1
h[i] =  'ColorMap->Cubehelix Settings:  Brings up interactive cubehelix controls'
i = i + 1
h[i] =  'Scaling Menu:           Selects linear, log, or histogram-equalized scaling'
i = i + 1
h[i] =  'Labels->TextLabel:      Brings up a dialog box for text input'
i = i + 1
h[i] =  'Labels->Contour:        Brings up a dialog box for overplotting contours'
i = i + 1
h[i] =  'Labels->Compass:        Draws a compass (requires WCS info in header)'
i = i + 1
h[i] =  'Labels->Scalebar:       Draws a scale bar (requires WCS info in header)'
i = i + 1
h[i] =  'Labels->EraseLast:      Erases the most recent plot label'
i = i + 1
h[i] =  'Labels->EraseAll:       Erases all plot labels'
i = i + 1
h[i] =  'Blink->SetBlink:        Sets the current display to be the blink image'
i = i + 1
h[i] =  '                             for mouse button 1, 2, or 3'
i = i + 1
h[i] =  'Blink->MakeRGB:         Make an RGB truecolor image from the 3 blink channels'
i = i + 1
h[i] =  'Rotate/Zoom->Rotate:    Rotate image clockwise by an arbitrary angle'
i = i + 1
h[i] =  'Rotate/Zoom->90, 180, or 270 deg: rotates clockwise'
i = i + 1
h[i] =  'Rotate/Zoom->Invert:    Inverts image along x, y, or both axes'
i = i + 1
h[i] =  'Rotate/Zoom->1/16x, etc: Sets zoom factor to selected scaling'
i = i + 1
h[i] =  'ImageInfo->ImageHeader: Display the FITS header, if there is one.'
i = i + 1
h[i] =  'ImageInfo->Photometry:  Brings up photometry window'
i = i + 1
h[i] =  'ImageInfo->Statistics:  Brings up stats window'
i = i + 1
h[i] =  'ImageInfo->PixelTable:  Brings up table window that tracks nearby pixel values'
i = i + 1
h[i] =  'ImageInfo menu also gives a choice of coordinate systems, '
i = i + 1
h[i] =  '    or of native image coordinates (default), for images with a WCS.'
i = i + 1
h[i] =  ''
i = i + 1
h[i] =  'CONTROL PANEL ITEMS:'
i = i + 1
h[i] = 'Min:             shows minimum data value displayed; enter new min value here'
i = i + 1
h[i] = 'Max:             shows maximum data value displayed; enter new max value here'
i = i + 1
h[i] = 'Pan Window:      use mouse to drag the image-view box around'
i = i + 1
h[i] = ''
i = i + 1
h[i] = 'MOUSE MODE SELECTOR:'
i = i + 1
h[i] =  'Color:          sets color-stretch mode:'
i = i + 1
h[i] = '                    With mouse button 1 down, drag mouse to change the color stretch.  '
i = i + 1
h[i] = '                    Move vertically to change contrast, and'
i = i + 1
h[i] = '                         horizontally to change brightness.'
i = i + 1 
h[i] = '                    button 2 or 3: center on current position'
i = i + 1
h[i] = 'Zoom:           sets zoom mode:' 
i = i + 1 
h[i] = '                    button1: zoom in & center on current position'
i = i + 1
h[i] = '                    button2: center on current position'
i = i + 1 
h[i] = '                    button3: zoom out & center on current position'
i = i + 1
h[i] = 'Blink:           sets blink mode:'
i = i + 1
h[i] = '                    press mouse button in main window to show blink image'
i = i + 1
h[i] = 'ImExam:          sets ImageExamine mode:'
i = i + 1
h[i] = '                    button 1: photometry'
i = i + 1
h[i] = '                    button 2: center on current position'
i = i + 1
h[i] = '                    button 3: image statistics'
i = i + 1
h[i] = 'Vector:          sets vector mode: click and drag in main window to select plot region'
i = i + 1
h[i] = '                    button 1: vector plot'
i = i + 1
h[i] = '                    button 2: vector plot with gaussian fit to peak'
i = i + 1
h[i] = '                    button 3: depth plot for 3d data cubes'
i = i + 2
h[i] = 'BUTTONS:'
i = i + 1
h[i] = 'Invert:          inverts the current color table'
i = i + 1
h[i] = 'Restretch:       sets min and max to preserve display colors while linearizing the color table'
i = i + 1
h[i] = 'AutoScale:       sets min and max to show data values around image median'
i = i + 1
h[i] = 'FullRange:       sets min and max to show the full data range of the image'
i = i + 1
h[i] = 'ZoomIn:          zooms in by x2'
i = i + 1
h[i] = 'ZoomOut:         zooms out by x2'
i = i + 1
h[i] = 'Zoom1:           sets zoom level to original scale'
i = i + 1
h[i] = 'Center:          centers image on display window'
i = i + 1
;h[i] = 'Done:            quits atv'
;i = i + 1
h[i] = ''
i = i + 1
h[i] = 'Keyboard commands in display window:'
i = i + 1
h[i] = '    Arrow keys or numeric keypad (with NUM LOCK on) moves cursor'
i = i + 1
h[i] = '    r: row plot'
i = i + 1
h[i] = '    c: column plot'
i = i + 1
h[i] = '    s: surface plot'
i = i + 1
h[i] = '    t: contour plot'
i = i + 1
h[i] = '    h: histogram of pixel values'
i = i + 1
i = i + 1
h[i] = '    p: aperture photometry at current position'
i = i + 1
h[i] = '    i: image statistics at current position'
i = i + 1
h[i] = '    x: extract spectrum at current position'
i = i + 1
h[i] = '    m: cycles through mouse modes'
i = i + 1
h[i] = '    e: erase all overplots'
i = i + 1
h[i] = '    Shift-1,2,3:  sets blink buffer 1, 2, or 3'
i = i + 1
h[i] = '    -: zoom out'
i = i + 1
h[i] = '    + or =: zoom in'
i = i + 1
h[i] = '    q: quits atv'
i = i + 2
h[i] = 'IDL COMMAND LINE HELP:'
i = i + 1
h[i] =  'To pass an array to atv:'
i = i + 1
h[i] =  '   atv, array_name [, options]'
i = i + 1
h[i] = 'To pass a fits filename to atv:'
i = i + 1
h[i] = '    atv, fitsfile_name [, options] (enclose filename in single quotes) '
i = i + 1
h[i] = 'Command-line options are: '
i = i + 1
h[i]  = '   [,min = min_value] [,max=max_value] [,/linear] [,/log] [,/histeq] [,/asinh]'
i = i + 1
h[i]  = '   [,/block] [,/align] [,/stretch] [,header=header]'
i = i + 2
h[i] = 'To overplot a contour plot on the draw window:'
i = i + 1
h[i] = '    atvcontour, array_name [, options...]'
i = i + 1
h[i] = 'To overplot text on the draw window: '
i = i + 1
h[i] = '    atvxyouts, x, y, text_string [, options]  (enclose string in single quotes)'
i = i + 1
h[i] = 'To overplot points or lines on the current plot:'
i = i + 1
h[i] = '    atvplot, xvector, yvector [, options]'
i = i + 2
h[i] = 'The options for atvcontour, atvxyouts, and atvplot are essentially'
i = i + 1
h[i] =  'the same as those for the idl contour, xyouts, and plot commands,'
i = i + 1
h[i] = 'except that data coordinates are always used.' 
i = i + 1
h[i] = 'The default color for overplots is red.'
i = i + 2
h[i] = 'The lowest 8 entries in the color table are:'
i = i + 1
h[i] = '    0 = black'
i = i + 1
h[i] = '    1 = red'
i = i + 1
h[i] = '    2 = green'
i = i + 1
h[i] = '    3 = blue'
i = i + 1
h[i] = '    4 = cyan'
i = i + 1
h[i] = '    5 = magenta'
i = i + 1
h[i] = '    6 = yellow'
i = i + 1
h[i] = '    7 = white'
i = i + 1
h[i] = '    The top entry in the color table is also reserved for white. '
i = i + 2
h[i] = 'Other commands:'
i = i + 1
h[i] = 'atverase [, N]:       erases all (or last N) plots and text'
i = i + 1
h[i] = 'atvclear: displays a small blank image (can be useful to clear memory)'
i = i + 1
h[i] = 'atv_activate: reanimates a frozen atv if another idl program crashes or hits a stop'
i = i + 1
h[i] = 'atv_shutdown:   quits atv'
i = i + 2
h[i] = 'NOTE: If atv should crash, type atv_shutdown at the idl prompt.'
i = i + 3
h[i] = strcompress('ATV.PRO version '+state.version)
i = i + 1
h[i] = 'For full instructions, or to download the most recent version, go to:'
i = i + 1
h[i] = 'http://www.physics.uci.edu/~barth/atv'


if (not (xregistered('atv_help', /noshow))) then begin

helptitle = strcompress('atv v' + state.version + ' help')

    help_base =  widget_base(group_leader = state.base_id, $
                             /column, $
                             /base_align_right, $
                             title = helptitle, $
                             uvalue = 'help_base')

    help_text = widget_text(help_base, $
                            /scroll, $
                            value = h, $
                            xsize = 85, $
                            ysize = 24)
    
    help_done = widget_button(help_base, $
                              value = 'Done', $
                              uvalue = 'help_done')

    widget_control, help_base, /realize
    xmanager, 'atv_help', help_base, /no_block
    
endif

end

;----------------------------------------------------------------------

pro atv_help_event, event

widget_control, event.id, get_uvalue = uvalue

case uvalue of
    'help_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------
;      Routines for displaying image statistics
;----------------------------------------------------------------------

pro atv_stats_refresh

; Calculate box statistics and update the results

common atv_state
common atv_images

b = round((state.statboxsize - 1) / 2)

xmin = 0 > (state.cursorpos[0] - b) < (state.image_size[0] - 1)
xmax = 0 > (state.cursorpos[0] + b) < (state.image_size[0] - 1)
ymin = 0 > (state.cursorpos[1] - b) < (state.image_size[1] - 1)
ymax = 0 > (state.cursorpos[1] + b) < (state.image_size[1] - 1)

xmin = round(xmin)
xmax = round(xmax)
ymin = round(ymin)
ymax = round(ymax)

cut = float(main_image[xmin:xmax, ymin:ymax])
npix = (xmax - xmin + 1) * (ymax - ymin + 1)

cutmin = min(cut, max=maxx, /nan)
cutmax = maxx
cutmean = mean(cut, /nan)
cutmedian = median(cut)
cutstddev = stddev(cut)


widget_control, state.statbox_id, set_value=state.statboxsize
widget_control, state.statxcenter_id, set_value = state.cursorpos[0]
widget_control, state.statycenter_id, set_value = state.cursorpos[1]
tmp_string = strcompress('# Pixels in Box:  ' + string(npix))
widget_control, state.stat_npix_id, set_value = tmp_string
tmp_string = strcompress('Min:  ' + string(cutmin))
widget_control, state.statbox_min_id, set_value = tmp_string
tmp_string = strcompress('Max:  ' + string(cutmax))
widget_control, state.statbox_max_id, set_value = tmp_string
tmp_string = strcompress('Mean:  ' + string(cutmean))
widget_control, state.statbox_mean_id, set_value = tmp_string
tmp_string = strcompress('Median:  ' + string(cutmedian))
widget_control, state.statbox_median_id, set_value = tmp_string
tmp_string = strcompress('StdDev:  ' + string(cutstddev))
widget_control, state.statbox_stdev_id, set_value = tmp_string

atv_tvstats

end

;----------------------------------------------------------------------

pro atv_stats_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue

case uvalue of

    'statbox': begin
        state.statboxsize = long(event.value) > 3
        if ( (state.statboxsize / 2 ) EQ $
             round(state.statboxsize / 2.)) then $
          state.statboxsize = state.statboxsize + 1
        atv_stats_refresh
    end

    'statxcenter': begin
        state.cursorpos[0] = 0 > long(event.value) < (state.image_size[0] - 1)
        atv_stats_refresh
    end

    'statycenter': begin
        state.cursorpos[1] = 0 > long(event.value) < (state.image_size[1] - 1)
        atv_stats_refresh
    end

    'showstatzoom': begin
        widget_control, state.showstatzoom_id, get_value=val
        case val of
            'Show Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=state.statzoom_size, ysize=state.statzoom_size
                widget_control, state.showstatzoom_id, $
                  set_value='Hide Region'
            end
            'Hide Region': begin
                widget_control, state.statzoom_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showstatzoom_id, $
                  set_value='Show Region'
             end
         endcase
         atv_stats_refresh
    end

    'stats_done': widget_control, event.top, /destroy
    else:
endcase


end

;----------------------------------------------------------------------

pro atv_showstats

; Brings up a widget window for displaying image statistics

common atv_state
common atv_images

common atv_state

state.cursorpos = state.coord

if (not (xregistered('atv_stats', /noshow))) then begin

    stats_base = $
      widget_base(group_leader = state.base_id, $
                  /column, $
                  /base_align_center, $
                  title = 'atv image statistics', $
                  uvalue = 'stats_base')
    state.stats_base_id = stats_base
    
    stats_nbase = widget_base(stats_base, /row, /base_align_center)
    stats_base1 = widget_base(stats_nbase, /column, frame=1)
    stats_base2 = widget_base(stats_nbase, /column)
    stats_base2a = widget_base(stats_base2, /column, frame=1)
    stats_zoombase = widget_base(stats_base, /column)

    tmp_string = strcompress('Image size:  ' + $
                             string(state.image_size[0]) + $
                             ' x ' + $
                             string(state.image_size[1]))

    size_label = widget_label(stats_base1, value = tmp_string)

    tmp_string = strcompress('Image Min:  ' + string(state.image_min))
    min_label= widget_label(stats_base1, value = tmp_string)
    tmp_string = strcompress('Image Max:  ' + string(state.image_max))
    max_label= widget_label(stats_base1, value = tmp_string)

    state.statbox_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Size for Stats:', $
               uvalue = 'statbox', $
               value = state.statboxsize, $
               xsize = 5)
    
    state.statxcenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box X Center:', $
               uvalue = 'statxcenter', $
               value = state.cursorpos[0], $ 
               xsize = 5)

    state.statycenter_id = $
      cw_field(stats_base1, $
               /long, $
               /return_events, $
               title = 'Box Y Center:', $
               uvalue = 'statycenter', $
               value = state.cursorpos[1], $ 
               xsize = 5)

    tmp_string = strcompress('# Pixels in Box: ' + string(10000000))
    state.stat_npix_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Min:  ' + '0.00000000000000')
    state.statbox_min_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Max: ' + '0.00000000000000')
    state.statbox_max_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Mean: ' + '0.00000000000000')
    state.statbox_mean_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('Median: ' + '0.00000000000000')
    state.statbox_median_id = widget_label(stats_base2a, value = tmp_string)
    tmp_string = strcompress('StdDev: ' + '0.00000000000000')
    state.statbox_stdev_id = widget_label(stats_base2a, value = tmp_string)
    
    state.showstatzoom_id = widget_button(stats_base2, $
          value = 'Show Region', uvalue = 'showstatzoom')

    stat_done = $
      widget_button(stats_base2, $
                    value = 'Done', $
                    uvalue = 'stats_done')
    
    state.statzoom_widget_id = widget_draw(stats_zoombase, $
       scr_xsize = 1, scr_ysize = 1)

    widget_control, stats_base, /realize
    
    xmanager, 'atv_stats', stats_base, /no_block
    
    widget_control, state.statzoom_widget_id, get_value = tmp_val
    state.statzoom_window_id = tmp_val

    atv_resetwindow

endif

atv_stats_refresh

end

;---------------------------------------------------------------------


pro atv_tvstats

; Routine to display the zoomed region around a stats point

common atv_state
common atv_images

atv_setwindow, state.statzoom_window_id
erase

x = round(state.cursorpos[0])
y = round(state.cursorpos[1])

boxsize = (state.statboxsize - 1) / 2
xsize = state.statboxsize
ysize = state.statboxsize
image = bytarr(xsize,ysize)

xmin = (0 > (x - boxsize))
xmax = ((x + boxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - boxsize) )
ymax = ((y + boxsize) < (state.image_size[1] - 1))

startx = abs( (x - boxsize) < 0 )
starty = abs( (y - boxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.statzoom_size
dev_pos = [0.15 * state.statzoom_size, $
           0.15 * state.statzoom_size, $
           0.95 * state.statzoom_size, $
           0.95 * state.statzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1

cgimage, image,  /axes, xrange = x_ran, yrange = y_ran

atv_resetwindow
end

;----------------------------------------------------------------------
;        aperture photometry and radial profile routines
;---------------------------------------------------------------------

pro atv_imcenterf, xcen, ycen

; program to calculate the center of mass of an image around
; the point (x,y), return the answer in (xcen,ycen).
;
; by M. Liu, adapted for inclusion in ATV by AJB
;
; ALGORITHM:
;   1. first finds max pixel value in
;	   a 'bigbox' box around the cursor
;   2. then calculates centroid around the object 
;   3. iterates, recalculating the center of mass 
;      around centroid until the shifts become smaller 
;      than MINSHIFT (0.3 pixels) 

common atv_images
common atv_state

; iteration controls
MINSHIFT = 0.3

; max possible x or y direction shift
MAXSHIFT = 3

; Bug fix 4/16/2000: added call to round to make sure bigbox is an integer
bigbox=round(1.5*state.centerboxsize)

sz = size(main_image)

; box size must be odd
dc = (state.centerboxsize-1)/2
if ( (bigbox / 2 ) EQ round(bigbox / 2.)) then bigbox = bigbox + 1
db = (bigbox-1)/2

; need to start with integers
xx = state.cursorpos[0]
yy = state.cursorpos[1]

; make sure there aren't NaN values in the apertures.
minx = 0 > (xx - state.outersky)  
maxx = (xx + state.outersky) < (state.image_size[0] - 1)
miny = 0 > (yy - state.outersky)  
maxy = (yy + state.outersky) < (state.image_size[1] - 1)

subimg = main_image[minx:maxx, miny:maxy]
if (finite(mean(subimg)) EQ 0) then begin
    xcen = xx
    ycen = yy
    state.photwarning = 'WARNING: Region contains NaN values.'
    return
endif

; first find max pixel in box around the cursor
x0 = (xx-db) > 0
x1 = (xx+db) < (sz(1)-1)
y0 = (yy-db) > 0
y1 = (yy+db) < (sz(2)-1)
cut = main_image[x0:x1,y0:y1]
cutmax = max(cut)
w=where(cut EQ cutmax)
cutsize = size(cut)
my = (floor(w/cutsize[1]))[0]
mx = (w - my*cutsize[1])[0]

xx = mx + x0
yy = my + y0 
xcen = xx
ycen = yy

; then find centroid 
if  (n_elements(xcen) gt 1) then begin
    xx = round(total(xcen)/n_elements(xcen)) 
    yy = round(total(ycen)/n_elements(ycen)) 
endif

done = 0
niter = 1
    
;	cut out relevant portion
sz = size(main_image)
x0 = round((xx-dc) > 0)		; need the ()'s
x1 = round((xx+dc) < (sz[1]-1))
y0 = round((yy-dc) > 0)
y1 = round((yy+dc) < (sz[2]-1))
xs = x1 - x0 + 1
ys = y1 - y0 + 1
cut = float(main_image[x0:x1, y0:y1])

; sky subtract before centering
; note that this is a quick and dirty solution, and may cause
; centering problems for poorly behaved data  -- AB, 2/28/07
cut = cut - min(cut)
                                ; find x position of center of mass
cenxx = fltarr(xs, ys, /nozero)
for i = 0L, (xs-1) do $         ; column loop
  cenxx[i, *] = cut[i, *] * i
xcen = total(cenxx) / total(cut) + x0

                                ; find y position of center of mass
cenyy = fltarr(xs, ys, /nozero)
for i = 0L, (ys-1) do $         ; row loop
  cenyy[*, i] = cut[*, i] * i
ycen = total(cenyy) / total(cut) + y0

if (abs(xcen-state.cursorpos[0]) gt MAXSHIFT) or $
  (abs(ycen-state.cursorpos[1]) gt MAXSHIFT) then begin
    state.photwarning = 'Warning: Possible mis-centering?'
endif

; add final check for xcen, ycen = NaN: this can happen if the region
; contains all negative values
if (finite(xcen) EQ 0 OR finite(ycen) EQ 0) then begin
    state.photwarning = 'Warning: Unable to center.'
    xcen = state.cursorpos[0]
    ycen = state.cursorpos[1]
endif

end

;----------------------------------------------------------------------

function atv_splinefwhm, rad, prof, splrad, splprof

; given a radial profile (counts vs radius) will use
; a spline to extract the FWHM
;
; ALGORITHM
;   finds peak in radial profile, then marches along until finds
;   where radial profile has dropped to half of that,
;   assumes peak value of radial profile is at minimum radius
;
; original version by M. Liu, adapted for ATV by AJB

common atv_state

nrad = n_elements(rad)

; check the peak
w = where(prof eq max(prof))
if float(rad(w[0])) ne min(rad) then begin
state.photwarning = 'Warning: Profile peak is off-center!'
  return,-1
endif

; interpolate radial profile at 50 times as many points
splrad = min(rad) + findgen(nrad*50+1) * (max(rad)-min(rad)) / (nrad*50)
nspl = n_elements(splrad)

; spline the profile
splprof = spline(rad,prof,splrad)

; march along splined profile until cross 0.5*peak value
found = 0
i = 0
repeat begin
  if splprof(i) lt 0.5*max(splprof) then $
	found = 1 $
  else $
	i = i+1
endrep until ((found) or (i eq nspl))

if (i lt 2) or (i eq nspl) then begin
state.photwarning = 'Warning: Unable to measure FWHM!'
  return,-1
endif

; now interpolate across the 2 points straddling the 0.5*peak
fwhm = splrad(i)+splrad(i-1)

return,fwhm
end

;-----------------------------------------------------------------------

pro atv_radplotf, x, y, fwhm

; Program to calculate radial profile of an image
; given aperture location, range of sizes, and inner and 
; outer radius for sky subtraction annulus.  Calculates sky by
; median.
; 
; original version by M. Liu, adapted for inclusion in ATV by AJB

common atv_state
common atv_images

; set defaults
inrad = 0.5*sqrt(2)
outrad = round(state.outersky * 1.2)
drad=1.
insky = outrad+drad
outsky = insky+drad+20.

; initialize arrays
inrad = float(inrad)
outrad = float(outrad)
drad = float(drad)
nrad = ceil((outrad-inrad)/drad) + 1
out = fltarr(nrad,12)

; extract relevant image subset (may be rectangular), translate coord origin,
;   bounded by edges of image
;   (there must be a cute IDL way to do this neater)
sz = size(main_image)
x0 = floor(x-outsky) 
x1 = ceil(x+outsky)   ; one pixel too many?
y0 = floor(y-outsky) 
y1 = ceil(y+outsky)
x0 = x0 > 0.0
x1 = x1 < (sz[1]-1)
y0 = y0 > 0.0
y1 = y1 < (sz[2]-1)
nx = x1 - x0 + 1
ny = y1 - y0 + 1

; trim the image, translate coords
img = main_image[x0:x1,y0:y1]
xcen = x - x0
ycen = y - y0

; for debugging, can make some masks showing different regions
skyimg = fltarr(nx,ny)			; don't use /nozero!!
photimg = fltarr(nx,ny)			; don't use /nozero!!

; makes an array of (distance)^2 from center of aperture
;   where distance is the radial or the semi-major axis distance.
;   based on DIST_CIRCLE and DIST_ELLIPSE in Goddard IDL package,
;   but deals with rectangular image sections
distsq = fltarr(nx,ny,/nozero)

xx = findgen(nx)
yy = findgen(ny)
x2 = (xx - xcen)^(2.0)
y2 = (yy - ycen)^(2.0)
for i = 0L,(ny-1) do $          ; row loop
  distsq[*,i] = x2 + y2(i)

; get sky level by masking and then medianing remaining pixels
; note use of "gt" to avoid picking same pixels as flux aperture
ns = 0
msky = 0.0
errsky = 0.0

in2 = insky^(2.0)
out2 = outsky^(2.0)
if (in2 LT max(distsq)) then begin
    w = where((distsq gt in2) and (distsq le out2),ns)
    skyann = img[w] 
endif else begin
    w = where(distsq EQ distsq)
    skyann = img[w]
    state.photwarning = 'Not enough pixels in sky!'
endelse

msky = median(skyann)
errsky = stddev(skyann)
skyimg[w] = -5.0
photimg = skyimg

errsky2 = errsky * errsky

out[*,8] = msky
out[*,9] = ns
out[*,10]= errsky

; now loop through photometry radii, finding the total flux, differential
;	flux, and differential average pixel value along with 1 sigma scatter
; 	relies on the fact the output array is full of zeroes
for i = 0,nrad-1 do begin
    
    dr = drad
    if i eq 0 then begin
        rin =  0.0
        rout = inrad
        rin2 = -0.01
    endif else begin
        rin = inrad + drad *(i-1)	
        rout = (rin + drad) < outrad
        rin2 = rin*rin
    endelse
    rout2 = rout*rout
    
; 	get flux and pixel stats in annulus, wary of counting pixels twice
;	checking if necessary if there are pixels in the sector
    w = where(distsq gt rin2 and distsq le rout2,np)
    
    pfrac = 1.0                 ; fraction of pixels in each annulus used
    
    if np gt 0 then begin
        ann = img[w]
        dflux = total(ann) * 1./pfrac
        dnpix = np
        dnet = dflux - (dnpix * msky) * 1./pfrac
        davg = dnet / (dnpix * 1./pfrac)
        if np gt 1 then dsig = stddev(ann) else dsig = 0.00
        
;		std dev in each annulus including sky sub error
        derr = sqrt(dsig*dsig + errsky2)
        
        photimg[w] = rout2
        
        out[i,0] = (rout+rin)/2.0
        out[i,1] = out[i-1>0,1] + dflux
        out[i,2] = out[i-1>0,2] + dnet
        out[i,3] = out[i-1>0,3] + dnpix
        out[i,4] = dflux
        out[i,5] = dnpix
        out[i,6] = davg
        out[i,7] = dsig
        out[i,11] = derr
    endif else if (i ne 0) then begin
        out[i,0]= rout
        out[i,1:3] = out[i-1,1:3]
        out[i, 4:7] = 0.0
        out[i,11] = 0.0
    endif else begin
        out[i, 0] = rout
    endelse
    
endfor

; fill radpts array after done with differential photometry
w = where(distsq ge 0.0 and distsq le outrad*outrad)
radpts = dblarr(2,n_elements(w))
radpts[0,*] = sqrt(distsq[w])
radpts[1,*] = img[w]

; compute FWHM via spline interpolation of radial profile
fwhm = atv_splinefwhm(out[*,0],out[*,6])

; plot the results

if n_elements(radpts(1, *)) gt 100 then pp = 3 else pp = 1

yminpoint = msky
ymaxpoint = max(radpts[1,*])
blankspace=0.08
ymin = yminpoint - blankspace*(ymaxpoint - yminpoint)
ymax = ymaxpoint + blankspace*(ymaxpoint - yminpoint)


cgplot, radpts[0, *], radpts[1, *], /nodata, xtitle = 'Radius (pixels)', $
        ytitle = 'Counts', color='white', background = 'black', $
        charsize=1.2, yrange = [ymin,ymax], yst=1
cgplot, radpts[0, *], radpts[1, *], psym = pp, color='yellow', /overplot
if (finite(mean(out)) EQ 1) then $
  oploterror, out[*, 0], out[*, 6]+out[*, 8], $
  out[*, 11]/sqrt(out[*, 5]), psym=-4, color='white', errcolor='white'

end

;-----------------------------------------------------------------------

pro atv_apphot_refresh

; Do aperture photometry using idlastro daophot routines.

common atv_state
common atv_images

state.photwarning = 'Warnings: None.'

; Center on the object position nearest to the cursor
if (state.centerboxsize GT 0) then begin
    atv_imcenterf, x, y
endif else begin   ; no centering
    x = state.cursorpos[0]
    y = state.cursorpos[1]
endelse

; Make sure that object position is on the image
x = 0 > x < (state.image_size[0] - 1)
y = 0 > y < (state.image_size[1] - 1)

if ((x - state.outersky) LT 0) OR $
  ((x + state.outersky) GT (state.image_size[0] - 1)) OR $
  ((y - state.outersky) LT 0) OR $
  ((y + state.outersky) GT (state.image_size[1] - 1)) then $
  state.photwarning = 'Warning: Sky apertures fall outside image!'

; Condition to test whether phot aperture is off the image
if (x LT state.aprad) OR $
  ((state.image_size[0] - x) LT state.aprad) OR $
  (y LT state.aprad) OR $
  ((state.image_size[1] - y) LT state.aprad) then begin
    flux = -1.
    state.photwarning = 'Warning: Aperture Outside Image Border!'
endif

; make sure there aren't NaN values in the apertures.
minx = 0 > (x - state.outersky)  
maxx = (x + state.outersky) < (state.image_size[0] - 1)
miny = 0 > (y - state.outersky)  
maxy = (y + state.outersky) < (state.image_size[1] - 1)

subimg = main_image[minx:maxx, miny:maxy]
if (finite(mean(subimg)) EQ 0) then begin
    atv_message, $
      'Sorry- ATV can not do photometry on regions containing NaN values.', $
      /window, msgtype = 'error'
    return
endif

    
phpadu = state.ccdgain
apr = [state.aprad]
skyrad = [state.innersky, state.outersky]
; Assume that all pixel values are good data
badpix = [state.image_min-1, state.image_max+1]  

if (state.skytype EQ 1) then begin    ; calculate median sky value

    xmin = (x - state.outersky) > 0
    xmax = (xmin + (2 * state.outersky + 1)) < (state.image_size[0] - 1)
    ymin = (y - state.outersky) > 0
    ymax = (ymin + (2 * state.outersky + 1)) < (state.image_size[1] - 1)
    
    small_image = main_image[xmin:xmax, ymin:ymax]
    nx = (size(small_image))[1]
    ny = (size(small_image))[2]
    i = lindgen(nx)#(lonarr(ny)+1)
    j = (lonarr(nx)+1)#lindgen(ny)
    xc = x - xmin
    yc = y - ymin
    
    w = where( (((i - xc)^2 + (j - yc)^2) GE state.innersky^2) AND $
               (((i - xc)^2 + (j - yc)^2) LE state.outersky^2),  nw)
    
    if ((x - state.outersky) LT 0) OR $
      ((x + state.outersky) GT (state.image_size[0] - 1)) OR $
      ((y - state.outersky) LT 0) OR $
      ((y + state.outersky) GT (state.image_size[1] - 1)) then $
      state.photwarning = 'Warning: Sky apertures fall outside image!'
    
    if (nw GT 0) then  begin
        skyval = median(small_image(w)) 
    endif else begin
        skyval = -1
        state.photwarning = 'Warning: No pixels in sky!'
    endelse
endif

; Do the photometry now
case state.skytype of
    0: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             readnoise = state.ccdrn
    1: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             setskyval = skyval, readnoise = state.ccdrn
    2: aper, main_image, [x], [y], flux, errap, sky, skyerr, phpadu, apr, $
             skyrad, badpix, flux=abs(state.magunits-1), /silent, $
             setskyval = 0, readnoise = state.ccdrn
endcase

flux = flux[0]
sky = sky[0]

if (flux EQ 99.999) then begin
    state.photwarning = 'Warning: Error in computing flux!'
    flux = -1.0
endif

if (state.magunits EQ 1) then begin    ; apply zeropoint
    flux = flux + state.photzpt - 25.0 + (2.5 * alog10(state.exptime))
endif


; Run atv_radplotf and plot the results
atv_setwindow, state.radplot_window_id
atv_radplotf, x, y, fwhm

; overplot the phot apertures on radial plot
cgplots, [state.aprad, state.aprad], !y.crange, line = 1, $
         color='green', thick=2, psym=0

ymin = !y.crange(0)
ymax = !y.crange(1)
ypos = ymin + 0.85*(ymax-ymin)
cgtext, /data, state.aprad, ypos, ' aprad', $
  color='green', charsize=1.5
if (state.skytype NE 2) then begin
    cgplots, [state.innersky,state.innersky], !y.crange, $
      line = 1, color='cyan', thick=2, psym=0
    ypos = ymin + 0.75*(ymax-ymin)
    cgtext, /data, state.innersky, ypos, ' insky', $
      color='cyan', charsize=1.5
    cgplots, [state.outersky,state.outersky], !y.crange, $
      line = 1, color='magenta', thick=2, psym=0
    ypos = ymin + 0.65*(ymax-ymin)
    cgtext, /data, state.outersky * 0.82, ypos, ' outsky', $
      color='magenta', charsize=1.5
endif
cgplots, !x.crange, [sky, sky], color='white', thick=2, psym=0, line = 2
cgtext, /data, state.innersky + (0.1*(state.outersky-state.innersky)), $
  sky+0.07*(!y.crange[1] - sky), 'sky level', color='white', charsize=1.5

atv_resetwindow

; write results to file if requested  
if (state.photprint EQ 1) then begin
   openw, state.photfile, state.photfilename, /append
   if (state.photerrors EQ 0) then errap = 0.0
   formatstring = '(2(f7.1," "),3(f5.1," "),3(g12.6," "),f5.2)'
   printf, state.photfile, x, y, state.aprad, $
           state.innersky, state.outersky, sky, flux, errap, fwhm, $
           format = formatstring
   close, state.photfile
endif

; output the results

case state.magunits of
    0: fluxstr = 'Object counts: '
    1: fluxstr = 'Magnitude: '
endcase

state.centerpos = [x, y]


tmp_string = string(state.cursorpos[0], state.cursorpos[1], $
                    format = '("Cursor position: x=",i5," y=",i5)' )
tmp_string1 = string(state.centerpos[0], state.centerpos[1], $
                    format = '("Centroid:   x=",f7.1," y=",f7.1)' )
tmp_string2 = strcompress(fluxstr+string(flux, format = '(g12.6)' ))
tmp_string3 = string(sky, format = '("Sky level: ",g12.6)' )
tmp_string4 = string(fwhm, format='("FWHM (pix): ",g7.3)' )

if (state.wcstype EQ 'angle') then begin
   xy2ad, x, y, *(state.astr_ptr), lon, lat
   tmp_string5 = atv_wcsstring(lon, lat, (*state.astr_ptr).ctype,  $
                             state.equinox, state.display_coord_sys, $
                             state.display_equinox, state.display_base60)
endif else begin
   tmp_string5 = '            '
endelse

if (state.photerrors EQ 0) then begin
   errstring = 'Photometric error: N/A'
endif else begin
   errstring = strcompress('Uncertainty: '+string(errap, format = '(g12.6)' ))
endelse

widget_control, state.centerbox_id, set_value = state.centerboxsize
widget_control, state.cursorpos_id, set_value = tmp_string
widget_control, state.centerpos_id, set_value = tmp_string1
widget_control, state.radius_id, set_value = state.aprad 
widget_control, state.outersky_id, set_value = state.outersky
widget_control, state.innersky_id, set_value = state.innersky
widget_control, state.skyresult_id, set_value = tmp_string3
widget_control, state.photresult_id, set_value = tmp_string2
widget_control, state.fwhm_id, set_value = tmp_string4
widget_control, state.photwarning_id, set_value=state.photwarning
widget_control, state.photerror_id, set_value = errstring

; Uncomment next lines if you want atv to output the WCS coords of 
; the centroid for the photometry object:
;if (state.wcstype EQ 'angle') then begin
;    xy2ad, state.centerpos[0], state.centerpos[1], *(state.astr_ptr), $
;      clon, clat
;    wcsstring = atv_wcsstring(clon, clat, (*state.astr_ptr).ctype,  $
;                state.equinox, state.display_coord_sys, state.display_equinox)
;    print, 'Centroid WCS coords: ', wcsstring
;endif

atv_tvphot

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_tvphot

; Routine to display the zoomed region around a photometry point,
; with circles showing the photometric apterture and sky radii.

common atv_state
common atv_images

atv_setwindow, state.photzoom_window_id
erase

x = round(state.centerpos[0])
y = round(state.centerpos[1])

boxsize = round(state.outersky * 1.2)
xsize = (2 * boxsize) + 1
ysize = (2 * boxsize) + 1
image = bytarr(xsize,ysize)

; TO DO: future update, can eliminate a lot of this image scaling stuff
; by using a cgimage command instead of tv

xmin = (0 > (x - boxsize))
xmax = ((x + boxsize) < (state.image_size[0] - 1) )
ymin = (0 > (y - boxsize) )
ymax = ((y + boxsize) < (state.image_size[1] - 1))

startx = abs( (x - boxsize) < 0 )
starty = abs( (y - boxsize) < 0 ) 

image[startx, starty] = scaled_image[xmin:xmax, ymin:ymax]
image1 = image

xs = indgen(xsize) + xmin - startx
ys = indgen(ysize) + ymin - starty

xs_delta = (xs[xsize-1] - xs[0]) / float(xsize - 1.0)
ys_delta = (ys[ysize-1] - ys[0]) / float(ysize - 1.0)
x_ran = [xs[0]-xs_delta/2.0,xs[xsize-1]+xs_delta/2.0]
y_ran = [ys[0]-ys_delta/2.0,ys[ysize-1]+ys_delta/2.0]

dev_width = 0.8 * state.photzoom_size
dev_pos = [0.15 * state.photzoom_size, $
           0.15 * state.photzoom_size, $
           0.95 * state.photzoom_size, $
           0.95 * state.photzoom_size]

x_factor = dev_width / xsize
y_factor = dev_width / ysize
x_offset = (x_factor - 1.0) / x_factor / 2.0
y_offset = (y_factor - 1.0) / y_factor / 2.0
xi = findgen(dev_width) / x_factor - x_offset ;x interp index
yi = findgen(dev_width) / y_factor - y_offset ;y interp index

image = Poly_2D(image, [[0,0],[1.0/x_factor,0]], $
             [[0,1.0/y_factor],[0,0]], $
             0, dev_width, dev_width)

xsize = (size(image))[1]
ysize = (size(image))[2]
out_xs = xi * xs_delta + xs[0]
out_ys = yi * ys_delta + ys[0]

sz = size(image)
xsize = Float(sz[1])       ;image width
ysize = Float(sz[2])       ;image height
dev_width = dev_pos[2] - dev_pos[0] + 1
dev_width = dev_pos[3] - dev_pos[1] + 1

tv, image, /device, dev_pos[0], dev_pos[1], $
  xsize=dev_pos[2]-dev_pos[0], $
  ysize=dev_pos[3]-dev_pos[1]

cgplot, [0, 1], /noerase, /nodata, xstyle = 1, ystyle = 1, $
  /device, position = dev_pos, axescolor='white', charsize=1, $
  xrange = x_ran, yrange = y_ran


tvcircle, /data, state.aprad, state.centerpos[0], state.centerpos[1], $
  color='green', thick=2, psym=0
if (state.skytype NE 2) then begin
    tvcircle, /data, state.innersky, state.centerpos[0], state.centerpos[1], $
      color='cyan', thick=2, psym=0
    tvcircle, /data, state.outersky, state.centerpos[0], state.centerpos[1], $
      color='magenta', thick=2, psym=0
endif

atv_resetwindow
end

;----------------------------------------------------------------------

pro atv_apphot_event, event

common atv_state
common atv_images

widget_control, event.id, get_uvalue = uvalue


case uvalue of

    'centerbox': begin
        if (event.value EQ 0) then begin
            state.centerboxsize = 0
        endif else begin
            state.centerboxsize = long(event.value) > 3
            if ( (state.centerboxsize / 2 ) EQ $
                 round(state.centerboxsize / 2.)) then $
              state.centerboxsize = state.centerboxsize + 1
        endelse
        atv_apphot_refresh
    end
        
    'radius': begin
        state.aprad = 1.0 > event.value < state.innersky
        atv_apphot_refresh
    end

    'innersky': begin
        state.innersky = state.aprad > event.value < (state.outersky - 1)
        state.innersky = 2 > state.innersky
        if (state.outersky EQ state.innersky + 1) then $
          state.outersky = state.outersky + 1
        atv_apphot_refresh
    end

    'outersky': begin
        state.outersky = event.value > (state.innersky + 2)
        atv_apphot_refresh
    end

    'showradplot': begin
        widget_control, state.showradplot_id, get_value=val

        case val of
            'Show radial profile': begin
                ysize = 350 < (state.screen_ysize - 350)
                widget_control, state.radplot_widget_id, $
                  xsize=500, ysize=ysize
                widget_control, state.showradplot_id, $
                  set_value='Hide radial profile'
            end
            'Hide radial profile': begin
                widget_control, state.radplot_widget_id, $
                  xsize=1, ysize=1
                widget_control, state.showradplot_id, $
                  set_value='Show radial profile'
             end
         endcase
         atv_apphot_refresh
    end

    'photprint': begin
       if (state.photprint EQ 0) then begin
          
          photfilename = dialog_pickfile(file = state.photfilename, $
                                         dialog_parent =  state.base_id, $
                                         path = state.current_dir, $
                                         get_path = tmp_dir, $
                                         /write)
          
          if (photfilename EQ '') then return

          ; write header to output file
          openw, photfile, photfilename, /get_lun, /append
          state.photfile = photfile
          state.photfilename = photfilename

          if (state.magunits EQ 0) then begin
             photstring1 = '   x        y      r  insky outsky      sky         counts        err     fwhm'
          endif else begin
             photstring1 = '   x        y      r  insky outsky      sky          mag          err     fwhm'
          endelse
          photstring2 = '------------------------------------------------------------------------------'
          printf, state.photfile, ' '
          printf, state.photfile, photstring1
          printf, state.photfile, photstring2
          printf, state.photfile, ' '
          close, state.photfile

          state.photprint = 1
          widget_control, state.photprint_id, $
                          set_value = 'Close photometry file'

       endif else begin
          free_lun, state.photfile
          state.photprint = 0
          widget_control, state.photprint_id, $
                          set_value = 'Write results to file...'   
       endelse
    end 

;    'magunits': begin
;        state.magunits = event.value
;        atv_apphot_refresh
;    end

    'photsettings': atv_apphot_settings

    'apphot_done': widget_control, event.top, /destroy
    else:
endcase

end

;----------------------------------------------------------------------

pro atv_apphot_settings

; Routine to get user input on various photometry settings

common atv_state

skyline = strcompress('0, button, IDLPhot Sky Mode|Median Sky|No Sky Subtraction,'+$
                      'exclusive,' + $
                      'label_left=Select Sky Algorithm: , set_value = ' + $
                      string(state.skytype))

magline = strcompress('0, button, Counts|Magnitudes, exclusive,' + $
                      'label_left = Select Output Units: , set_value =' + $
                      string(state.magunits))

zptline = strcompress('0, float,'+string(state.photzpt) + $
                      ',label_left = Magnitude Zeropoint:,' + $
                      'width = 12')

exptimeline = strcompress('0, float,'+string(state.exptime) + $
                      ',label_left = Exposure Time (s):,' + $
                      'width = 12')

errline = strcompress('0, button, No|Yes, exclusive,' + $
                      'label_left = Calculate photometric errors? ,' + $
                      'set_value =' + $
                      string(state.photerrors))

gainline = strcompress('0, float,'+string(state.ccdgain) + $
                      ',label_left = CCD Gain (e-/DN):,' + $
                      'width = 12')

rnline = strcompress('0, float,'+string(state.ccdrn) + $
                      ',label_left = Readout Noise (e-):,' + $
                      'width = 12')
warningline1 = $
   strcompress('0, label, ' + $
               'WARNING: Photometric errors only make sense if the, left')
warningline2 = $
   strcompress('0, label, ' + $
               'gain and readnoise are given correctly, left ')
warningline3 = $
   strcompress('0, label, ' + $
               'accounting for scaling or co-adding of images., left')
warningline4 = $
   strcompress('0, label, ' + $
               '   , left')

formdesc = [skyline, $
            magline, $
            zptline, $
            exptimeline, $
            '0, label, [ Magnitude = -2.5 log (DN / exptime) + ZPT ]', $
            errline, gainline, rnline, $
            warningline1, warningline2, warningline3, warningline4, $
            '0, button, Apply Settings, quit', $
            '0, button, Cancel, quit']

textform = cw_form(formdesc, /column, $
                   title = 'atv photometry settings')

if (textform.tag13 EQ 1) then return ; cancelled

state.skytype = textform.tag0
state.magunits = textform.tag1
state.photzpt = textform.tag2
state.exptime = textform.tag3
state.photerrors = textform.tag5
state.ccdgain = (1.e-5) > textform.tag6
state.ccdrn = 0 > textform.tag7

if (state.exptime LE 0) then state.exptime = 1.0

atv_apphot_refresh

end

;----------------------------------------------------------------------

pro atv_apphot

; aperture photometry front end

common atv_state

state.cursorpos = state.coord

if (not (xregistered('atv_apphot', /noshow))) then begin

    apphot_base = $
      widget_base(/base_align_center, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv aperture photometry', $
                  uvalue = 'apphot_base')
    
    apphot_top_base = widget_base(apphot_base, /row, /base_align_center)

    apphot_data_base1 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_data_base2 = widget_base( $
            apphot_top_base, /column, frame=0)

    apphot_draw_base = widget_base( $
            apphot_base, /row, /base_align_center, frame=0)

    apphot_data_base1a = widget_base(apphot_data_base1, /column, frame=1)
    tmp_string = $
      string(1000, 1000, $
             format = '("Cursor position: x=",i5," y=",i5)' )

    state.cursorpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string, $
                   uvalue = 'cursorpos')

    state.centerbox_id = $
      cw_field(apphot_data_base1a, $
               /long, $
               /return_events, $
               title = 'Centering box size (pix):', $
               uvalue = 'centerbox', $
               value = state.centerboxsize, $
               xsize = 5)
    
    tmp_string1 = $
      string(99999.0, 99999.0, $
             format = '("Centroid:   x=",f7.1," y=",f7.1)' )
    
    state.centerpos_id = $
      widget_label(apphot_data_base1a, $
                   value = tmp_string1, $
                   uvalue = 'centerpos')
    
    state.radius_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = 'Aperture radius: ', $
               uvalue = 'radius', $
               value = state.aprad, $
               xsize = 8)
    
    state.innersky_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = 'Inner sky radius:', $
               uvalue = 'innersky', $
               value = state.innersky, $
               xsize = 8)
    
    state.outersky_id = $
      cw_field(apphot_data_base1a, $
               /floating, $
               /return_events, $
               title = 'Outer sky radius:', $
               uvalue = 'outersky', $
               value = state.outersky, $
               xsize = 8)
    
    photzoom_widget_id = widget_draw( $
         apphot_data_base2, $
         scr_xsize=state.photzoom_size, scr_ysize=state.photzoom_size)

    tmp_string4 = string(0.0, format='("FWHM (pix): ",g7.3)' )
    state.fwhm_id = widget_label(apphot_data_base2, $
                                 value=tmp_string4, $
                                 uvalue='fwhm')

    tmp_string3 = string(10000000.00, $
                         format = '("Sky level: ",g12.6)' )
    
    state.skyresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string3, $
                   uvalue = 'skyresult')
    
    tmp_string2 = string(1000000000.00, $
                         format = '("Object counts: ",g12.6)' )
    
    state.photresult_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photresult', $
                   /frame)

    tmp_string2 = '                           '

    state.photerror_id = $
      widget_label(apphot_data_base2, $
                   value = tmp_string2, $
                   uvalue = 'photerror', $
                   /frame)

    state.photwarning_id = $
      widget_label(apphot_data_base1, $
                   value='-------------------------', $
                   /dynamic_resize, $
                   frame=1)

    photsettings_id = $
      widget_button(apphot_data_base1, $
                    value = 'Photometry settings...', $
                    uvalue = 'photsettings')

    if (state.photprint EQ 0) then begin
       photstring = 'Write results to file...'
    endif else begin
       photstring = 'Close photometry file'
    endelse
    
    state.photprint_id = $
       widget_button(apphot_data_base1, $
                     value = photstring, $
                     uvalue = 'photprint')

    state.showradplot_id = $
      widget_button(apphot_data_base1, $
                    value = 'Show radial profile', $
                    uvalue = 'showradplot')
    
    state.radplot_widget_id = widget_draw( $
         apphot_draw_base, scr_xsize=1, scr_ysize=1)

    apphot_done = $
      widget_button(apphot_data_base2, $
                    value = 'Done', $
                    uvalue = 'apphot_done')

    widget_control, apphot_base, /realize

    widget_control, photzoom_widget_id, get_value=tmp_value
    state.photzoom_window_id = tmp_value
    widget_control, state.radplot_widget_id, get_value=tmp_value
    state.radplot_window_id = tmp_value

    xmanager, 'atv_apphot', apphot_base, /no_block
    
    atv_resetwindow
endif

atv_apphot_refresh

end

;--------------------------------------------------------------------
;    Spectral extraction routines
;---------------------------------------------------------------------

function atv_get_tracepoint, yslice, traceguess

common atv_state

; find the trace points by simple centroiding after subtracting off
; the background level.  iterate up to maxrep times to fine-tune the
; centroid position.

ysize = n_elements(yslice)
yvec = indgen(ysize)

icounter = 0L
ycen = traceguess
maxrep = 10
; convergence criterion for accepting centroid: change in pixels from
; previous iteration smaller than mindelta
mindelta = 0.2    

repeat begin
   lastycen = ycen
   icounter = icounter + 1

   ylow = round(lastycen - (state.x_traceheight / 2.)) > 0
   yhigh = round(lastycen + (state.x_traceheight / 2.)) < (ysize-1)
  
   smallslice = yslice[ylow:yhigh]   
   minyslice = min(smallslice)
   smallslice = smallslice - minyslice

   ycen = total( float((yvec * (yslice - minyslice))[ylow:yhigh])) / $
          float(total(smallslice))

   ; check for major failures from pathological images
   if (finite(ycen) EQ 0) then ycen = lastycen

   deltat = ycen - lastycen

endrep until ((abs(deltat) LT mindelta) OR (icounter GE maxrep))

; check again for major failures
if (ycen LT ylow OR ycen GT yhigh) then ycen = traceguess
if (finite(ycen) EQ 0) then ycen = traceguess

return, ycen

end

;-----------------------------------------------------------------

pro atv_trace, newcoord

common atv_state
common atv_images
common atv_spectrum, traceinit, tracecenters, tracepoints, $
   xspec, fulltrace, spectrum

if (keyword_set(newcoord) AND state.x_fixed EQ 0) then begin
; get new starting position from cursor
   xstart = state.x_tracestep > state.coord[0] < $
            (state.image_size[0] - state.x_tracestep)
   traceguess = ((state.x_traceheight / 2.)) > state.coord[1] < $
                (state.image_size[1] - (state.x_traceheight / 2.))
   traceinit = [xstart, traceguess]

   state.x_xregion = [0, state.image_size[0]-1]

   widget_control, state.x_xstart_id, $
                   set_value = state.x_xregion[0]
   widget_control, state.x_xend_id, $
                   set_value = state.x_xregion[1]

endif else begin
   xstart = traceinit[0]
   traceguess = traceinit[1]
endelse

xsize = state.x_xregion[1] - state.x_xregion[0] + 1
ysize = state.image_size[1]

twidth = fix(state.x_tracestep / 2)
ntracepoints = fix(xsize / state.x_tracestep)
tracecenters = lindgen(ntracepoints) * state.x_tracestep + $
  fix(state.x_tracestep/2) + state.x_xregion[0]
tracepoints = fltarr(ntracepoints)

; find the array element closest to the starting guess point
m = min(abs(tracecenters-xstart), midtracepoint)

; peak up on the first trace point
xtracestart = xstart - twidth
xtraceend = xstart + twidth
tracecutout = main_image[xtracestart:xtraceend, *]

ymin = 1 > (traceguess - (state.x_traceheight / 2.))
ymax = (traceguess + (state.x_traceheight / 2.)) < (ysize - 2)
yslice = (total(tracecutout,1))[ymin:ymax]
w = where(yslice EQ max(yslice), count)
if (count EQ 1) then traceguess = traceguess - (state.x_traceheight/2.) + w

; trace from initial guess point to higher x
for i = midtracepoint, ntracepoints-1 do begin
   xtracestart = tracecenters[i] - twidth
   xtraceend = tracecenters[i] + twidth
   
   tracecutout = main_image[xtracestart:xtraceend, *]
   yslice = total(tracecutout,1)
   
   ; replace NaNs when tracing to avert disaster
   w = where(finite(yslice) EQ 0, count)
   if (count GT 0) then yslice[w] = 0

   if (min(yslice) EQ max(yslice)) then begin
   ; if slice is blank, don't try to trace-- i.e. STIS image edges
      tracepoints[i] = traceguess
      ycen = traceguess
   endif else begin
      ycen = atv_get_tracepoint(yslice, traceguess)
      tracepoints[i] = ycen
   endelse
   
   ; set next guess, accounting for local slope of trace
   if (i EQ midtracepoint) then begin
      traceguess = ycen
   endif else begin
      traceguess = 1 > (ycen + (tracepoints[i] - tracepoints[i-1])/2) < $
                   (ysize-1)
   endelse
   if (finite(traceguess) EQ 0) then traceguess = tracepoints[i-1]


endfor

traceguess = tracepoints[midtracepoint]

; now trace from initial guess point to lower x
for i = midtracepoint-1, 0, -1 do begin
   xtracestart = tracecenters[i] - twidth
   xtraceend = tracecenters[i] + twidth
   
   tracecutout = main_image[xtracestart:xtraceend, *]
   yslice = total(tracecutout,1)
   
   w = where(finite(yslice) EQ 0, count)
   if (count GT 0) then yslice[w] = 0

   if (min(yslice) EQ max(yslice)) then begin
      tracepoints[i] = traceguess
      ycen = traceguess
   endif else begin
      ycen = atv_get_tracepoint(yslice, traceguess)
      tracepoints[i] = ycen
   endelse
   
   traceguess = 1 > (ycen - (tracepoints[i+1] - tracepoints[i])/2) < $
                (ysize-1)
   if (finite(traceguess) EQ 0) then traceguess = tracepoints[i+1]

endfor

result = poly_fit(double(tracecenters), tracepoints, $
                  state.x_traceorder, yfit, /double)

xspec = lindgen(xsize) + state.x_xregion[0]
fulltrace = dblarr(xsize) 
for i = 0, state.x_traceorder do begin
    fulltrace = fulltrace + (result[i] * (double(xspec))^i)
endfor


end

;------------------------------------------------------------------

pro atvextract, newcoord=newcoord

common atv_state
common atv_images
common atv_spectrum


if (state.image_size[0] LT 50) OR (state.image_size[1]) LT 20 $
   then return

if (state.cube EQ 1) then return

if (not (xregistered('atv_extract', /noshow))) then atvextract_init

atverase

if (state.x_traceheight GT state.image_size[1]) then begin
   state.x_traceheight = state.image_size[1]
   widget_control, state.x_traceheight_id, set_value = state.x_traceheight
endif

if (state.x_fixed EQ 0) then atv_trace, newcoord

atvplot, tracecenters, tracepoints, psym=1
atvplot, xspec, fulltrace, color='blue'

xsize = state.x_xregion[1] - state.x_xregion[0] + 1
ysize = state.image_size[1]

nxpoints = state.x_xupper - state.x_xlower

spectrum = dblarr(xsize)

for i = xspec[0], max(xspec) do begin

   j = i - xspec[0]
   ; error check to see if spectrum runs off the top or bottom of image
   if (((fulltrace[j] + state.x_back1) LT 0) or $
       ((fulltrace[j] + state.x_back4) GT ysize)) then begin
      
      spectrum[j] = 0
      
   endif else begin
   ; extract the spectrum accounting for partial pixels at the
   ; aperture edges.  ybottom and ytop are the upper and lower limits
   ; for full pixels in the extraction aperture.
      ytop = fix(fulltrace[j] + state.x_xupper - 0.5) 
      ybottom = fix(fulltrace[j] + state.x_xlower + 0.5) + 1

      ; these are the fractions of a pixel
      ; at the upper and lower edges of the
      ; extraction aperture
      upperfraction = fulltrace[j] + state.x_xupper - 0.5 - ytop
      lowerfraction = 1.0 - upperfraction

      ; contribution from complete pixels in the extraction window
      signal = total(main_image[i, ybottom:ytop])

      ; add in fractional pixels at aperture edges
      uppersignal = upperfraction * main_image[i, ytop+1]
      lowersignal = lowerfraction * main_image[i, ybottom-1]

      signal = signal + uppersignal + lowersignal

      ; for the background, just use full pixels
      if (state.x_backsub EQ 1) then begin
         lowerback = median( main_image[i, $
                                        fulltrace[j]+state.x_back1: $
                                        fulltrace[j]+state.x_back2])
         upperback = median( main_image[i, $
                                        fulltrace[j]+state.x_back3: $
                                        fulltrace[j]+state.x_back4])
         meanback = mean([lowerback,upperback])
         background = meanback * float(nxpoints)

         signal = signal - background
      endif

      spectrum[j] = signal
      
   endelse
   
endfor

atvplot, xspec, fulltrace + state.x_xupper, color='yellow'
atvplot, xspec, fulltrace + state.x_xlower, color='yellow'

if (state.x_backsub EQ 1) then begin
   atvplot, xspec, fulltrace + state.x_back1, color='magenta'
   atvplot, xspec, fulltrace + state.x_back2, color='magenta'
   atvplot, xspec, fulltrace + state.x_back3, color='magenta'
   atvplot, xspec, fulltrace + state.x_back4, color='magenta'
endif


atv_specplot, /newcoord


end

;-----------------------------------------------------------------

pro atv_specplot, ps=ps, fullrange=fullrange, newcoord=newcoord

; draws a new row plot in the plot window or to postscript output

common atv_state
common atv_images
common atv_spectrum

if (keyword_set(ps)) then begin
   thick = 3
   color = 'black'
   background = 'white'
endif else begin
   thick = 1
   color = 'white'
   background = 'black'
endelse

if (keyword_set(newcoord)) then newcoord = 1 else newcoord = 0

if (not (keyword_set(ps))) then begin
    newplot = 0
    if (not (xregistered('atv_lineplot', /noshow))) then begin
        atv_lineplot_init
        newplot = 1
    endif 

    widget_control, state.histbutton_base_id, map=0
    widget_control, state.holdrange_button_id, sensitive=1

    widget_control, state.lineplot_xmin_id, get_value=xmin
    widget_control, state.lineplot_xmax_id, get_value=xmax
    widget_control, state.lineplot_ymin_id, get_value=ymin
    widget_control, state.lineplot_ymax_id, get_value=ymax

    if (newplot EQ 1 OR state.plot_type NE 'specplot' OR $
        keyword_set(fullrange) OR $
        ((state.holdrange_value EQ 0) AND newcoord EQ 1)) then begin
        xmin = min(xspec)
        xmax = max(xspec)
        ymin = min(spectrum)
        ymax = max(spectrum) 
    endif
   
    widget_control, state.lineplot_xmin_id, set_value=xmin
    widget_control, state.lineplot_xmax_id, set_value=xmax
    widget_control, state.lineplot_ymin_id, set_value=ymin
    widget_control, state.lineplot_ymax_id, set_value=ymax

    state.lineplot_xmin = xmin
    state.lineplot_xmax = xmax
    state.lineplot_ymin = ymin
    state.lineplot_ymax = ymax

    state.plot_type = 'specplot'
    atv_setwindow, state.lineplot_window_id
    erase
    
endif

cgplot, xspec, spectrum, $
        xst = 3, yst = 3, psym = 10, $
        title = strcompress('Extracted Spectrum'), $
        
        xtitle = 'Column', $
        ytitle = 'Counts', $
        color = color, background = background, $
        xmargin=[10,3], $
        xran = [state.lineplot_xmin, state.lineplot_xmax], $
        yran = [state.lineplot_ymin, state.lineplot_ymax], $
        thick = thick, xthick = thick, ythick = thick, charthick = thick, $
        charsize = state.plotcharsize


if (not (keyword_set(ps))) then begin 
  widget_control, state.lineplot_base_id, /clear_events
  atv_resetwindow
endif

end

;-------------------------------------------------------------------

pro atvextract_init

; initialize the extraction widget

common atv_state

; reset the extraction region when starting up
state.x_xregion = [0, state.image_size[0]-1]
state.x_backsub = 1
state.x_fixed = 0

extract_base = widget_base(/base_align_left, $
                  group_leader = state.base_id, $
                  /column, $
                  title = 'atv spectral extraction', $
                  uvalue = 'extract_base')

trace_id = widget_base(extract_base, /row, /base_align_left)

state.x_tracestep_id = cw_field(trace_id, /long, /return_events, $
                          title = 'Trace step:', $
                          uvalue = 'tracestep', $
                          value = state.x_tracestep, $
                          xsize = 5)

state.x_traceheight_id = cw_field(trace_id, /long, /return_events, $
                          title = 'Trace height:', $
                          uvalue = 'traceheight', $
                          value = state.x_traceheight, $
                          xsize = 5)

state.x_traceorder_id = cw_field(extract_base, /long, /return_events, $
                          title = 'Trace fit order:', $
                          uvalue = 'traceorder', $
                          value = state.x_traceorder, $
                          xsize = 5)

xregion_base = widget_base(extract_base, /row, /base_align_left)

state.x_xregion = [0, state.image_size[0]-1]

state.x_xstart_id = cw_field(xregion_base, /long, /return_events, $
                    title = 'Extraction start:', $
                    uvalue = 'xstart', $
                    value = state.x_xregion[0], $
                    xsize = 5)

state.x_xend_id = cw_field(xregion_base, /long, /return_events, $
                    title = 'end:', $
                    uvalue = 'xend', $
                    value = state.x_xregion[1], $
                    xsize = 5)

xwidth_base = widget_base(extract_base, /row, /base_align_left)

state.x_xlower_id = cw_field(xwidth_base, /long, /return_events, $
                    title = 'Extraction width lower:', $
                    uvalue = 'lower', $
                    value = state.x_xlower, $
                    xsize = 5)

state.x_xupper_id = cw_field(xwidth_base, /long, /return_events, $
                    title = 'upper:', $
                    uvalue = 'upper', $
                    value = state.x_xupper, $
                    xsize = 5)

x_backsub = cw_bgroup(extract_base, ['on', 'off'], $\
                      uvalue = 'backsub', $
                      button_uvalue = ['on', 'off'], $
                      /exclusive, set_value = 0, $
                      label_left = 'Background subtraction: ', $
                      /no_release, $
                      /row)

xbacka_base = widget_base(extract_base, /row, /base_align_left)

state.x_back1_id = cw_field(xbacka_base, /long, /return_events, $
                    title = 'Lower background region:', $
                    uvalue = 'back1', $
                    value = state.x_back1, $
                    xsize = 5)

state.x_back2_id = cw_field(xbacka_base, /long, /return_events, $
                    title = 'to', $
                    uvalue = 'back2', $
                    value = state.x_back2, $
                    xsize = 5)

xbackb_base = widget_base(extract_base, /row, /base_align_left)

state.x_back3_id = cw_field(xbackb_base, /long, /return_events, $
                    title = 'Upper background region:', $
                    uvalue = 'back3', $
                    value = state.x_back3, $
                    xsize = 5)

state.x_back4_id = cw_field(xbackb_base, /long, /return_events, $
                    title = 'to', $
                    uvalue = 'back4', $
                    value = state.x_back4, $
                    xsize = 5)

x_fixbutton = cw_bgroup(extract_base, ['Toggle parameter hold'], $\
                      uvalue = 'fixed', $
                      /no_release, $
                      /row)

x_writespectbutton = cw_bgroup(extract_base, $
                               ['Write spectrum as FITS', $
                                'Write spectrum as text'], $
                               uvalue = 'writespect', $
                               button_uvalue = ['fits', 'text'], $
                               /no_release, /row)

extract_done = $
   widget_button(extract_base, $
                 value = 'Done', $
                 uvalue = 'extract_done')
    

widget_control, extract_base, /realize
xmanager, 'atv_extract', extract_base, /no_block
atv_resetwindow

end

;-------------------------------------------------------------------------

pro atv_extract_event, event

common atv_state

widget_control, event.id, get_uvalue = uvalue

case uvalue of
   
   'tracestep': begin
      state.x_tracestep = 1 > event.value < 101
      if NOT(long(state.x_tracestep)/2 ne state.x_tracestep/2.0) then $ 
         state.x_tracestep = state.x_tracestep + 1
      widget_control, state.x_tracestep_id, $
                      set_value = state.x_tracestep
      atvextract
   end
   
   'traceheight': begin
      state.x_traceheight = 3 > event.value < 101
      state.x_traceheight = state.x_traceheight < state.image_size[1]
      widget_control, state.x_traceheight_id, $
                      set_value = state.x_traceheight
      atvextract
   end

   'traceorder': begin
      state.x_traceorder = 0 > event.value < 10
      widget_control, state.x_traceorder_id, $
                      set_value = state.x_traceorder
      atvextract
   end

   'xstart': begin
      state.x_xregion[0] = 0 > event.value < (state.x_xregion[1] - 50)
      widget_control, state.x_xstart_id, $
                      set_value = state.x_xregion[0]
      atvextract
   end

   'xend': begin
      state.x_xregion[1] = (state.x_xregion[0] + 50) > event.value < $ 
                        (state.image_size[0] - 1)
      widget_control, state.x_xend_id, $
                      set_value = state.x_xregion[1]
      atvextract
   end

   'lower': begin
      state.x_xlower = event.value < (state.x_xupper - 2)
      if (state.x_xlower LT state.x_back2) then $
         state.x_xlower = state.x_back2 + 1
      widget_control, state.x_xlower_id, $
                      set_value = state.x_xlower
      atvextract
   end

   'upper': begin
      state.x_xupper = (state.x_xlower + 2) > event.value 
      if (state.x_xupper GT state.x_back3) then $
         state.x_xupper = state.x_back3 - 1
      widget_control, state.x_xupper_id, $
                      set_value = state.x_xupper
      atvextract
   end

   'backsub': begin
      if (event.value EQ 'on') then state.x_backsub = 1 $
      else state.x_backsub = 0
      atvextract
   end
   
   'back1': begin
      state.x_back1 = (-0.5 * state.image_size[1]) > event.value < $
                      (state.x_back2 - 1)
      widget_control, state.x_back1_id, $
                      set_value = state.x_back1
      atvextract
   end

   'back2': begin
      state.x_back2 = (state.x_back1 + 1) > event.value < (state.x_xlower - 1)
      widget_control, state.x_back2_id, $
                      set_value = state.x_back2
      atvextract
   end

   'back3': begin
      state.x_back3 = (state.x_xupper + 1) > event.value < (state.x_back4 - 1)
      widget_control, state.x_back3_id, $
                      set_value = state.x_back3
      atvextract
   end

   'back4': begin
      state.x_back4 = (state.x_back3 + 1) > event.value < $
                      (0.5 * state.image_size[1])
      widget_control, state.x_back4_id, $
                      set_value = state.x_back4
      atvextract
   end

   'fixed': begin
      if (state.x_fixed EQ 1) then begin
         widget_control, state.x_tracestep_id, sensitive=1
         widget_control, state.x_traceheight_id, sensitive=1
         widget_control, state.x_traceorder_id, sensitive=1
         widget_control, state.x_xstart_id, sensitive=1
         widget_control, state.x_xend_id, sensitive=1
         widget_control, state.x_xlower_id, sensitive=1
         widget_control, state.x_xupper_id, sensitive=1
         widget_control, state.x_back1_id, sensitive=1
         widget_control, state.x_back2_id, sensitive=1
         widget_control, state.x_back3_id, sensitive=1
         widget_control, state.x_back4_id, sensitive=1
         state.x_fixed = 0
      endif else begin
         widget_control, state.x_tracestep_id, sensitive=0
         widget_control, state.x_traceheight_id, sensitive=0
         widget_control, state.x_traceorder_id, sensitive=0
         widget_control, state.x_xstart_id, sensitive=0
         widget_control, state.x_xend_id, sensitive=0
         widget_control, state.x_xlower_id, sensitive=0
         widget_control, state.x_xupper_id, sensitive=0
         widget_control, state.x_back1_id, sensitive=0
         widget_control, state.x_back2_id, sensitive=0
         widget_control, state.x_back3_id, sensitive=0
         widget_control, state.x_back4_id, sensitive=0
         state.x_fixed = 1
      endelse
   end

   'writespect': begin
      if (event.value EQ 'fits') then begin
         atv_writespecfits
      endif else begin
         atv_writespectext
      endelse   
   end

   'extract_done': widget_control, event.top, /destroy
   else:
endcase

end

;-----------------------------------------------------------------

pro atv_writespecfits

common atv_state
common atv_spectrum

filename = dialog_pickfile(group=state.base_id, $
                           filter = '*.fits', $
                           file = 'atvspectrum.fits', $
                           default_extension = '.fits', $
                           /write, $
                           /overwrite_prompt, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           title = 'Write FITS Spectrum')
if (tmp_dir NE '') then state.current_dir = tmp_dir
if (filename EQ '') then return


if (ptr_valid(state.head_ptr)) then begin
   outheader = *(state.head_ptr)
; keep wavelength scale from STIS if available
   cd = double(sxpar(*state.head_ptr,'CD1_1', /silent))
   crpix = double(sxpar(*state.head_ptr,'CRPIX1', /silent))
   crval = double(sxpar(*state.head_ptr,'CRVAL1', /silent))
   shifta = double(sxpar(*state.head_ptr, 'SHIFTA1', /silent))
   
   sxdelpar, outheader, 'CD1_1'
   sxdelpar, outheader, 'CRPIX1'
   sxdelpar, outheader, 'CRVAL1'
   sxdelpar, outheader, 'SHIFTA1'
endif else begin
   cd = 0
   crpix = 0
   crval = 0
   shifta = 0
endelse

if (crval NE 0) AND (cd NE 0) then begin
   ; get wavelength scale, accounting for extraction start and end
   wavelength = crval + ((dindgen(state.image_size[0]) - crpix) * cd) + $
                (shifta * cd)
   wavelength = wavelength[state.x_xregion[0]:state.x_xregion[1]]
endif else begin
   wavelength = xspec
endelse

; note, this works for linear wavelength scales only
cd = wavelength[1] - wavelength[0]
crval = wavelength[0]

if (ptr_valid(state.head_ptr)) then begin
   sxaddpar, outheader, 'CRVAL1', crval
   sxaddpar, outheader, 'CD1_1', cd
   writefits, filename, spectrum, outheader
endif else begin
   writefits, filename, spectrum
   spectrum = readfits(filename, outheader)
   sxaddpar, outheader, 'CRVAL1', crval
   sxaddpar, outheader, 'CD1_1', cd
   writefits, filename, spectrum, outheader
endelse

end

;------------------------------------------------------------------

pro atv_writespectext

common atv_state
common atv_spectrum

filename = dialog_pickfile(group=state.base_id, $
                           /write, $
                           file = 'atvspectrum.txt', $
                           /overwrite_prompt, $
                           path = state.current_dir, $
                           get_path = tmp_dir, $
                           title = 'Write Text Spectrum')
if (tmp_dir NE '') then state.current_dir = tmp_dir
if (filename EQ '') then return

if (ptr_valid(state.head_ptr)) then begin
; keep wavelength scale from STIS if available
   cd = double(sxpar(*state.head_ptr,'CD1_1', /silent))
   crpix = double(sxpar(*state.head_ptr,'CRPIX1', /silent))
   crval = double(sxpar(*state.head_ptr,'CRVAL1', /silent))
   shifta = double(sxpar(*state.head_ptr, 'SHIFTA1', /silent))
endif else begin
   cd = 0
   crpix = 0
   crval = 0
   shifta = 0
endelse

if (crval NE 0) AND (cd NE 0) then begin
   ; get wavelength scale, accounting for extraction start and end
   wavelength = crval + ((dindgen(state.image_size[0]) - crpix) * cd) + $
                (shifta * cd)
   wavelength = wavelength[state.x_xregion[0]:state.x_xregion[1]]
endif else begin
   wavelength = xspec
endelse

openw, unit0, filename, /get_lun

for i = 0L, n_elements(xspec)-1 do begin
   printf, unit0, wavelength[i], spectrum[i]
endfor

close, unit0
free_lun, unit0

end


;--------------------------------------------------------------------
;    shutdown routine
;--------------------------------------------------------------------

pro atv_shutdown, windowid

; routine to kill the atv window(s) and clear variables to conserve
; memory when quitting atv.  The windowid parameter is used when
; atv_shutdown is called automatically by the xmanager, if atv is
; killed by the window manager.

common atv_images
common atv_state
common atv_color
common atv_pdata
common atv_spectrum

if (state.photprint EQ 1) then begin
   free_lun, state.photfile
endif

; reset color table and pmulti to user values
tvlct, user_r, user_g, user_b
!p.multi = state.active_window_pmulti

; Kill top-level base if it still exists
if (xregistered ('atv')) then widget_control, state.base_id, /destroy

if (size(state, /tname) EQ 'STRUCT') then begin
    if (!d.name EQ state.graphicsdevice) then wdelete, state.pan_pixmap
    if (ptr_valid(state.head_ptr)) then ptr_free, state.head_ptr
    if (ptr_valid(state.astr_ptr)) then ptr_free, state.astr_ptr
endif

; Clean up saved variables in common blocks to conserve memory.
; Previously this was done using delvarx, but since delvarx uses an
; execute function, it's incompatible with IDL virtual machine.  So,
; just set these variables to zero.

atvplotlist=0
maxplot=0
main_image=0
main_image_cube=0
display_image=0
scaled_image=0
blink_image1=0
blink_image2=0
blink_image3=0
unlink_image=0
pan_image=0
r_vector=0
g_vector=0
b_vector=0
user_r=0
user_g=0
user_b=0
state=0
traceinit=0
tracecenters=0
tracepoints=0
xspec=0
fulltrace=0
spectrum=0

return    
end


;--------------------------------------------------------------------
;    atv main program.  needs to be last in order to compile.
;---------------------------------------------------------------------

; Main program routine for ATV.  If there is no current ATV session,
; then run atv_startup to create the widgets.  If ATV already exists,
; then display the new image to the current ATV window.

pro atv, image, $
         min = minimum, $
         max = maximum, $
         autoscale = autoscale,  $
         linear = linear, $
         log = log, $
         histeq = histeq, $
         asinh = asinh, $
         block = block, $
         align = align, $
         stretch = stretch, $
         header = header

common atv_state
common atv_images

if (long(strmid(!version.release,0,1)) LT 6) then begin
    print, 'ATV requires IDL version 6.0 or greater.'
    retall
endif

if (not(keyword_set(block))) then block = 0 else block = 1

newimage = 0

if ( (n_params() EQ 0) AND (xregistered('atv', /noshow))) then begin
    print, 'USAGE: atv, array_name OR fitsfile'
    print, '         [,min = min_value] [,max=max_value] '
    print, '         [,/linear] [,/log] [,/histeq] [,/block]'
    print, '         [,/align] [,/stretch] [,header=header]'
    return
endif

if (!d.name NE 'X' AND !d.name NE 'WIN' AND !d.name NE 'MAC') then begin
    print, 'Graphics device must be set to X, WIN, or MAC for ATV to work.'
    retall
endif

; Before starting up atv, get the user's external window id.  We can't
; use the atv_getwindow routine yet because we haven't run atv
; startup.  A subtle issue: atv_resetwindow won't work the first time
; through because xmanager doesn't get called until the end of this
; routine.  So we have to deal with the external window explicitly in
; this routine.
if (not (xregistered('atv', /noshow))) then begin
   userwindow = !d.window
   atv_startup
   align = 0B     ; align, stretch keywords make no sense if we are
   stretch = 0B   ; just starting up. 

; Startup message, if desired   
;   print
;   msgstring = strcompress('ATV ' + state.version + ' starting. ')
;   print, msgstring  
;   print

endif


if (n_elements(align) EQ 0) then align = state.default_align
if (n_elements(stretch) EQ 0) then stretch = state.default_stretch

; If image is a filename, read in the file
if ( (n_params() NE 0) AND (size(image, /tname) EQ 'STRING')) then begin
    ifexists = findfile(image, count=count)
    if (count EQ 0) then begin
        print, 'ERROR: File not found!'
    endif else begin
        atv_readfits, fitsfilename=image, newimage=newimage
        if (state.firstimage EQ 1) then begin
            align = 0
            stretch = 0
        endif
    endelse
endif

; Check for existence of array
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
   (size(image, /tname) EQ 'UNDEFINED')) then begin
    print, 'ERROR: Data array does not exist!'
endif

; If user has passed atv a data array, read it into main_image.
if ( (n_params() NE 0) AND (size(image, /tname) NE 'STRING') AND $
     (size(image, /tname) NE 'UNDEFINED')) then begin
; Make sure it's a 2-d array
   if ( ((size(image))[0] GT 3) OR $
        ((size(image))[0] LT 2) OR $
        ((size(image))[1] EQ 1) OR $
        ((size(image))[2] EQ 1)  ) then begin
      print, 'ERROR: Input data must be a 2-d array or 3-d data cube.'    
   endif else begin
      main_image = image
      newimage = 1
      state.imagename = ''
      state.title_extras = ''
      atv_setheader, header
      
      ; check for cube
      if ((size(image))[0] EQ 3) then begin
         main_image_cube = main_image
         main_image = 0
         state.cube = 1
         atv_initcube
      endif else begin   ; plain 2d image
         state.cube = 0
         main_image_cube = 0
         atv_killcube      
      endelse

      if (state.firstimage EQ 1) then begin
         align = 0
         stretch = 0
      endif        
   endelse
endif

;   Define default startup image 
if (n_elements(main_image) LE 1) then begin
    gridsize = 512
    centerpix = 256
    x = ((findgen(gridsize) # replicate(1, gridsize)) - centerpix + 0.001)*0.06
    y = ((replicate(1, gridsize) # findgen(gridsize)) - centerpix + 0.001)*0.06
    r = sqrt(x^2 + y^2)
    main_image = beselj(r, 1) * sin(2*x) * sin(2*y) * r^(-1.5) > (-0.01) 

    stretch = 1
    autoscale = 0
    imagename = ''
    newimage = 2             ; flag for startup image
    atv_setheader, ''
    state.title_extras = 'firstimage'
endif


if (newimage GE 1) then begin  
; skip this part if new image is invalid or if user selected 'cancel'
; in dialog box
    atv_getstats, align=align
    
    display_image = 0

    if n_elements(minimum) GT 0 then begin
        state.min_value = minimum
    endif
    
    if n_elements(maximum) GT 0 then begin 
        state.max_value = maximum
    endif
    
    if state.min_value GE state.max_value then begin
        state.min_value = state.max_value - 1.
    endif
    
    if (keyword_set(linear)) then state.scaling = 0
    if (keyword_set(log))    then state.scaling = 1
    if (keyword_set(histeq)) then state.scaling = 2
    if (keyword_set(asinh))  then state.scaling = 3
    
; Perform autoscale if current stretch invalid or stretch keyword
; not set, or if this is the first image
    IF (state.min_value EQ state.max_value) OR (stretch EQ 0) THEN BEGIN 

       if (keyword_set(autoscale) OR $
           ((state.default_autoscale EQ 1) AND (n_elements(minimum) EQ 0) $
            AND (n_elements(maximum) EQ 0)) ) $
         then atv_autoscale
    ENDIF 

;    if (state.firstimage EQ 1 AND newimage EQ 1) then atv_autoscale
    if (state.firstimage EQ 1) then atv_autoscale
    if (newimage EQ 1) then state.firstimage = 0  ; now have a real image
        
    atv_set_minmax
    
    IF ((NOT keyword_set(align)) AND state.default_align EQ 0) THEN BEGIN 
       state.zoom_level = 0
       state.zoom_factor = 1.0
    ENDIF 

    atv_displayall
    atv_settitle
    
    atv_resetwindow
endif

state.block = block

; Register the widget with xmanager if it's not already registered
if (not(xregistered('atv', /noshow))) then begin
    nb = abs(block - 1)
    xmanager, 'atv', state.base_id, no_block = nb, cleanup = 'atv_shutdown'
    wset, userwindow
    ; if blocking mode is set, then when the procedure reaches this
    ; line atv has already been terminated.  If non-blocking, then
    ; the procedure continues below.  If blocking, then the state
    ; structure doesn't exist any more so don't set active window.
    if (block EQ 0) then state.active_window_id = userwindow
endif




end

