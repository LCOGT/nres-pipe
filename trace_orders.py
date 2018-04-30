'''
Written by Allen B. Davis (c) 2018.
Yale University.

Last update: April 26, 2018.
'''

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import medfilt
import collections

def trace(data,
          N_ORDERS=67, MAIN_ROW=3500, MAIN_COL=2000,
          INIT_SLICE_WIDTH=300, PERCENTILE=90.,O_HALFWIDTH=8, DEGREE=4,
          debug_plot=False, verbose=False):
    '''
    PURPOSE:
        With no manual intervention, return polynomial fits for two fibers across each 
        order.
    METHODOLOGY:
        Identifies an initial pixel on an order. Follows the centroid of slices through 
        that order along the dispersion direction, terminating when it reaches the edge 
        of the chip or gets too faint. Then it searches for neighbor fiber to the initial 
        fiber, following it across the dispersion direction. Polynomials are fit to the 
        identified centroids. Then the next blueward fiber/order is found and traced, 
        along with its neighbor. This continues until it hits the blue edge of the chip. 
        It returns to the first order, and then proceeds redward. Continues until the 
        desired number of orders are found.
    INPUTS:
        data: 2D array
            Reduced 2D image with two fibers illuminated by tungsten/halogen lamp.
            It is assumed that higher row indices correspond to bluer orders.
        N_ORDERS: int (opt) = 67
            Number of orders to be traced. Effectively controls how far into the red 
            will be traced. 
        MAIN_ROW: int (opt) = 3500
            Central row of the initial columnar slice used to find the first 
            science-order pixel. Must be near the blue end of the chip to ensure the 
            orders are well-separated.
        MAIN_COL: int (opt) = 2000
            Column index of the initial columnar slice used to find the first 
            science-order pixel. This column must run through all valid orders/fibers.
        INIT_SLICE_WIDTH: int (opt) = 300
            Length of the initial cut along the MAIN_COL used to locate a position along 
            the first order. Should be long enough to definitely hit a couple orders.
        PERCENTILE: float (opt) = 90.
            Determines which point within a blind slice is guessed to be on an order. 
            Should be close to 100 to obtain a bright pixel, but not quite 100 because 
            then you could get a cosmic ray.
        O_HALFWIDTH: int (opt) = 8
            The halfwidth of targetted sliced through an order.
            Fullwidth will be 1+(O_HALFWIDTH*2).
        DEGREE: int (opt) = 4
            Degree of the polynomial fits to the order centroids.
        debug_plot: (opt) bool = False
            If true, makes plots useful for debugging.
        verbose: (opt) bool = False
            If true, reports progress as orders are traced.
    OUTPUTS:
        fibers_red: 1D array
            Subpixel row indices for centroids of the red fibers for each order.
        fibers_blue: 1D array
            Subpixel row indices for centroids of the blue fibers for each order.
        polys_red: 1D array
            Polynomial functions fitted to fibers_red(col).
        polys_blue: 1D array
            Polynomial functions fitted to fibers_blue(col).
    '''
    
    # Make initial slice. Near the blue end.
    init_idx, init_slc = get_slice(data,MAIN_COL,center=MAIN_ROW,
                                   halfwidth=INIT_SLICE_WIDTH//2,smooth=7)
    
    # Find a point on an order
    guess_idx, guess_inten = guess_point(init_idx,init_slc,percentile=PERCENTILE)
    if debug_plot:
        # The order guess should land clearly on an order. Doesn't need to be well-centered.
        plt.figure()
        plt.plot(init_idx,init_slc,label='slice')
        plt.plot(guess_idx,guess_inten,'o',label='order guess')
        plt.legend()
        plt.xlabel('row')
        plt.ylabel('counts')
        plt.title('slice along column %d'%MAIN_COL)
        plt.show()
        
        xmin, xmax = MAIN_COL-INIT_SLICE_WIDTH//2-50, MAIN_COL+INIT_SLICE_WIDTH//2+50
        ymin, ymax = np.min(init_idx)-50, np.max(init_idx)+50 # rows
        vmin, vmax= np.min(data[ymin:ymax,xmin:xmax]), np.max(data[ymin:ymax,xmin:xmax])
        plt.figure()
        plt.imshow(data,origin='lower',vmin=vmin,vmax=vmax)
        plt.plot([MAIN_COL for _ in init_idx],init_idx,color='white')
        plt.plot(MAIN_COL,guess_idx,'o',color='orange')
        plt.xlim(xmin,xmax)
        plt.ylim(ymin,ymax)
        plt.xlabel('col')
        plt.ylabel('row')
        cbar = plt.colorbar()
        cbar.set_label('counts')
        plt.title('Initial slice along 2D spectra')
        plt.show()

    # Reslice next to chosen pixel and centroid twice.
    idx, slc = get_slice(data,MAIN_COL,center=guess_idx,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    if debug_plot:
        plt.figure()
        plt.plot(idx, slc, 'o',color='C0',label='1st pass slice')
        plt.axvline(centroid,color='C2',label='1st pass centroid')
        plt.xlabel('row')
        plt.ylabel('flux')
    idx, slc = get_slice(data,MAIN_COL,center=centroid,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    if debug_plot:
        #  Heights between points at same column may be different due to bkgd subtraction
        plt.plot(idx, slc, '^',color='C1',label='2nd pass slice')
        plt.axvline(centroid,color='C4',label='2nd pass centroid',linestyle='dashed')
        plt.plot(guess_idx,guess_inten,'*',color='C5',label='order guess')
        plt.xlabel('row')
        plt.ylabel('flux')
        plt.legend()
        plt.show()
        
    # Follow along this order & fiber, saving centroids_init (for the initial fiber).
    centroids_init = follow_fiber(data,centroid,MAIN_COL,O_HALFWIDTH)
    
    # Fit polynomial to the centroids
    p_init = fit_polynomial(np.arange(data.shape[1]),centroids_init,DEGREE=DEGREE)
    
    # Hunt for second fiber. Compare two candidate slices above and below this fiber.
    FIBER_HUNT_OFFSET = 2 + O_HALFWIDTH
    FIBER_HUNT_LENGTH = 20
    cent_init = centroids_init[MAIN_COL]
    cand1_idx, cand1_slc = get_slice(data,MAIN_COL,       # Blue side
                                     lower_limit=cent_init+FIBER_HUNT_OFFSET,
                                     upper_limit=cent_init+FIBER_HUNT_OFFSET+FIBER_HUNT_LENGTH,
                                     smooth=7)
    cand2_idx, cand2_slc = get_slice(data,MAIN_COL,       # Red side
                                     lower_limit=cent_init-FIBER_HUNT_OFFSET-FIBER_HUNT_LENGTH,
                                     upper_limit=cent_init-FIBER_HUNT_OFFSET,smooth=7)
                                     
    flux1 = get_flux(cand1_slc,smooth=7,remove_bkgd=True)
    flux2 = get_flux(cand2_slc,smooth=7,remove_bkgd=True)
    
    assert (flux1 > 0 or flux2 > 0) and ((flux1 > flux2*2) ^ (flux2 > flux1*2)),\
    'The fluxes in the candidate slices while hunting for the neighboring slice were '\
    '%f and %f after median filtering and background removal. At least one needed to '\
    'be positive and one should be more than twice the other. This was not the case, '\
    'so it is unclear which is the real neighbor fiber.'
    
    if flux1 > flux2:
        neigh_fiber_idx = cand1_idx
        neigh_fiber_slc = cand1_slc
    else:
        neigh_fiber_idx = cand2_idx
        neigh_fiber_slc = cand2_slc
        
    guess_idx, guess_inten = guess_point(neigh_fiber_idx,
                                         neigh_fiber_slc,percentile=PERCENTILE)
    idx, slc = get_slice(data,MAIN_COL,center=guess_idx,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    idx, slc = get_slice(data,MAIN_COL,center=centroid,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    
    centroids_neigh = follow_fiber(data,centroid,MAIN_COL,O_HALFWIDTH)
    p_neigh = fit_polynomial(np.arange(data.shape[1]),centroids_neigh,DEGREE=DEGREE)
    
    # Create lists to hold fiber centroids.
    if p_neigh(MAIN_COL) > p_init(MAIN_COL):
        fibers_red = collections.deque([centroids_init])
        fibers_blue = collections.deque([centroids_neigh])
        polys_red = collections.deque([p_init])
        polys_blue = collections.deque([p_neigh])
    else:
        fibers_red = collections.deque([centroids_neigh])
        fibers_blue = collections.deque([centroids_init])
        polys_red = collections.deque([p_neigh])
        polys_blue = collections.deque([p_init])
        
    if debug_plot:
        cols = np.arange(data.shape[1])
        plt.figure()
        plt.imshow(data-np.min(data),vmax=500,origin='lower')
        plt.plot(cols,fibers_red[0],'-',color='C1',label='red centroids')
        plt.plot(cols,polys_red[0](cols),linewidth=1,color='red',linestyle='dashed',
                 label='red poly')
        plt.plot(cols,fibers_blue[0],'-',color='C2',label='blue centroids')
        plt.plot(cols,polys_blue[0](cols),linewidth=1,color='blue',linestyle='dashed',
                 label='blue poly')
        plt.legend()
        plt.xlabel('col')
        plt.ylabel('row')
        plt.colorbar()
        plt.title('Fit along first order')
        plt.show()
        
        plt.figure()
        plt.plot(cols,fibers_red[0]-polys_red[0](cols),color='C1',linewidth=0.5,label='red')
        plt.plot(cols,fibers_blue[0]-polys_blue[0](cols),color='C0',linewidth=0.5,label='blue')
        plt.legend()
        plt.title('resids: cent-poly')
        plt.xlabel('col')
        plt.ylabel('resids')
        plt.legend()
        plt.show()
        
    # Determine the smoothed peak flux in this red fiber, so that we can set a good 
    # threshold for the next red fiber.
    N_SLICES_PEAK = 20
    red_vals = np.zeros((N_SLICES_PEAK,2*O_HALFWIDTH+1))
    for i in range(N_SLICES_PEAK):
        idx, slc = get_slice(data,MAIN_COL+i,
                             center=polys_red[0](MAIN_COL),halfwidth=O_HALFWIDTH,
                             remove_bkgd=False,smooth=0)
        red_vals[i,:]= slc
    red_vals = red_vals - np.min(red_vals)
    red_vals = medfilt(red_vals,kernel_size=5)
    red_peak = np.max(red_vals)
    
    # Determine separation between this order's blue fiber and next order's red fiber.    
    O_SEP_HUNT_OFFSET = 2 + O_HALFWIDTH
    O_SEP_HUNT_LENGTH = 100
    lower_limit = polys_blue[0](MAIN_COL)+O_SEP_HUNT_OFFSET
    idx, slc = get_slice(data,MAIN_COL,
                         lower_limit=lower_limit,
                         upper_limit=lower_limit+O_SEP_HUNT_LENGTH,
                         remove_bkgd=True, smooth=5)
    O_SEP_QUEUE_LENGTH = 3
    o_sep_hunt_queue = collections.deque(O_SEP_QUEUE_LENGTH*[0], maxlen=O_SEP_QUEUE_LENGTH)
    O_SEP_THRESHOLD_RATIO = 0.3
    threshold = red_peak * O_SEP_THRESHOLD_RATIO
    i = 0
    while np.mean(o_sep_hunt_queue) < threshold:
        assert i < len(slc),'Failed to find the red fiber in the next order. '\
                            'You could try reducing O_SEP_THRESHOLD_RATIO, currently '\
                            '%.f, which corresponds to a threshold flux value of %d.'\
                            ''%(O_SEP_THRESHOLD_RATIO,threshold)
        o_sep_hunt_queue.append(slc[i])
        i += 1
    guess_idx = idx[i]
    idx, slc = get_slice(data,MAIN_COL,center=guess_idx,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    idx, slc = get_slice(data,MAIN_COL,center=centroid,halfwidth=O_HALFWIDTH)
    centroid = get_centroid(idx, slc)
    
    o_sep_init = int(np.round(centroid - polys_blue[0](MAIN_COL)))
    assert o_sep_init > 0,'o_sep_init must be positive.'
    
    # Search for other orders
    nfound = 1
    direction = 'blue'
    o_sep = o_sep_init
    last_printed = 0
    MAX_ORDERS = 67
    while nfound < MAX_ORDERS:
        if direction=='blue':
            prev_poly = polys_blue[0]
        else:
            prev_poly = polys_red[-1]
        
        f_sep = abs(polys_blue[0](MAIN_COL) - polys_red[0](MAIN_COL))
        cent_red, cent_blue,\
        p_red, p_blue = find_next_order(data,prev_poly,direction,
                                        MAIN_COL,f_sep,o_sep,O_HALFWIDTH,DEGREE)
        
        if p_red is None or p_blue is None:
            # Change direction once we've exhausted the blue orders.
            direction = 'red'
            o_sep = o_sep_init
            continue
        
        if direction == 'blue':
            fibers_red.appendleft(cent_red)
            fibers_blue.appendleft(cent_blue)
            polys_red.appendleft(p_red)
            polys_blue.appendleft(p_blue)
        else:
            fibers_red.append(cent_red)
            fibers_blue.append(cent_blue)
            polys_red.append(p_red)
            polys_blue.append(p_blue)
        
        if direction=='blue':
            o_sep = int(np.round(p_red(MAIN_COL) - prev_poly(MAIN_COL)))
        else:
            o_sep = int(np.round(prev_poly(MAIN_COL) - p_blue(MAIN_COL)))
        assert o_sep > 0,'o_sep must be positive.'
        
        nfound += 1
        last_printed = print_progress(nfound,last_printed,MAX_ORDERS,report=10,
                                      msg='Tracing orders... ')
        
    return fibers_red, fibers_blue, polys_red, polys_blue

def find_next_order(data,prev_poly,direction,init_col,f_sep,o_sep,halfwidth,DEGREE):
    '''
    PURPOSE:
        Trace the centroids of the two fibers in an adjacent order.
    METHODOLOGY:
        asdf
    INPUTS:
        data: 2D array
            The full frame image.
        prev_poly: 1D polynomial
            Polynomial function tracing the fiber on the `direction`-side of the 
            previous order.
        direction: str
            'blue' or 'red' are the acceptable values. Determines in which direction we 
            search for the next order.
        init_col: int
            The column at which the first centroid of the new orders will be determined.
        f_sep: int
            A guess of the pixels between the center of the two fiber in an order.
        o_sep: int
            A guess of the pixels between the center of a previous fiber and the center 
            of the closest fiber in the neighboring order.
        halfwidth: int
            The halfwidth of the slices through the next order.
            Fullwidth will be 1+(halfwidth*2).
        DEGREE: int
            Degree of the polynomial fit.
    OUTPUTS:
        centroids_red: 1D array
            Subpixel row indices for centroids of the next order's red fiber.
        centroids_blue: 1D array
            Subpixel row indices for centroids of the next order's blue fiber.
        poly_red: 1D polynomial
            Polynomial function fitted to centroids_red(col).
        poly_blue: 1D polynomial
            Polynomial function fitted to centroids_red(col).
    '''
    
    centroids_1, p_1 = find_next_fiber(data,prev_poly,direction,init_col,o_sep,halfwidth,DEGREE)
    if p_1 is None:
        return None, None, None, None
    centroids_2, p_2 = find_next_fiber(data,p_1,direction,init_col,f_sep,halfwidth,DEGREE)
    if p_2 is None:
        return None, None, None, None
    
    if direction == 'blue':
        centroids_red = centroids_1
        centroids_blue = centroids_2
        poly_red = p_1
        poly_blue = p_2
    else:
        centroids_red = centroids_2
        centroids_blue = centroids_1
        poly_red = p_2
        poly_blue = p_1
    
    return centroids_red, centroids_blue, poly_red, poly_blue
    
def find_next_fiber(data,ref_poly,direction,init_col,sep,halfwidth,DEGREE):
    '''
    PURPOSE:
        Trace the centroids of one fibers in the adjacent order.
    METHODOLOGY:
        asdf
    INPUTS:
        data: 2D array
            The full frame image.
        prev_poly: 1D polynomial
            Polynomial function tracing the fiber on the `direction`-side of the 
            previous order.
        direction: str
            'blue' or 'red' are the acceptable values. Determines in which direction we 
            search for the next order.
        init_col: int
            The column at which the first centroid of the new orders will be determined.
        sep: int
            Guess of the pixels between the center of a previous fiber and the center 
            of the next closest fiber in the given direction.
        halfwidth: int
            The halfwidth of the slices through the next order.
            Fullwidth will be 1+(halfwidth*2).
        DEGREE: int
            Degree of the polynomial fit.
    OUTPUTS:
        centroids: 1D array
            Subpixel row indices for centroids of the next fiber.
        poly: 1D polynomial
            Polynomial function fitted to centroids(col).
    '''
    
    assert direction=='blue' or direction=='red',"Only 'blue' and 'red' are valid "\
    "inputs for `direction`."
    
    if direction=='blue':
        sign = 1
    else:   # direction == 'red'
        sign = -1
    
    guess = ref_poly(init_col)+(sep)*sign
    idx, slc = get_slice(data,init_col,center=guess,halfwidth=halfwidth)
    centroid = get_centroid(idx, slc)
    idx, slc = get_slice(data,init_col,center=centroid,halfwidth=halfwidth)
    centroid = get_centroid(idx, slc)
    centroids = follow_fiber(data,centroid,init_col,halfwidth)
    poly = fit_polynomial(np.arange(data.shape[1]),centroids,DEGREE=DEGREE)
    
    return centroids, poly
    
def guess_point(idx, slc, percentile=90.):
    '''
    PURPOSE:
        Identify a point that is on an order within the slice.
    METHODOLOGY:
        Sorts indices and intensities by the intensities, then returns the idx and inten
        at the requested percentile.
    INPUTS:
        idx: 1D array
            Indices for the slice within the original full-frame image.
        slc: 1D array
            Intensity values within the slice.
        percentile: float
            Percentile of the intensities represented in the slice that will be returned as the guess.
    OUTPUTS:
        guess_idx: 1D array
            Index of the guess position.
        guess_inten: 1D array
            Intensity of the guessed pixel.
    '''
    
    vals = [[x,y] for y,x in sorted(zip(slc,idx))]
    guess_idx, guess_inten = vals[int(len(vals)*percentile/100.)]
    return guess_idx, guess_inten

def fit_polynomial(cols,rows,DEGREE=4):
    '''
    PURPOSE:
        Fit a polynomial to the function row(col) for one fiber within an order.
    METHODOLOGY:

    INPUTS:
        cols: 1D array
            Column indices to fit.
        rows: 1D array
            Row indices to fit. Probably based on the centroids of columnar slices.
        DEGREE: int (opt)
            Degree of the polynomial fit.
    OUTPUTS:
        poly: 1D polynomial
            Polynomial function fitted to row(col).
    '''
    
    locs = ~np.isnan(rows)
    try:
        z = np.polyfit(cols[locs],rows[locs],deg=DEGREE)
    except TypeError:
        # Occurs when locs is all False: i.e., no centroids are there to be traced
        return None
    poly = np.poly1d(z)  
    return poly

def follow_fiber(data,start_row,start_col,halfwidth,
                 QUEUE_LENGTH=20,SNR_THRESHOLD=20,BAFFLE_CLIP=150):
    '''
    PURPOSE:
        Finds all the centroids of one fiber along an entire order.
    METHODOLOGY:
        Starts with a known centroid, and then walks column-by-column to the left, 
        updating the centroids as it goes. Stop conditions is hitting the edge of the 
        chip or when the SNR gets too low (in this case, extra pixels are removed to 
        account for defects due to the baffle). Then it does the same thing to the right.
    INPUTS:
        data: 2D array
            The full frame image.
        start_col: int or float
            Index of the column for the first starting position along the fiber.
        start_row: int
            Index of the row for the first starting position along the fiber.
        halfwidth: (opt) int = None
            The halfwidth of the slice. Fullwidth will be 1+(halfwidth*2).
        QUEUE_LENGTH: int (opt) = 20
            The queue keeps track of the fluxes within the last QUEUE_LENGTH fitted 
            centroids. If the median drops before a value based on SNR_THRESHOLD, a stop 
            condition is met.
        SNR_THRESHOLD: int (opt) = 20
            Threshold SNR value (i.e., sqrt(sum(slice))) which must be met to continue 
            following an order towards on edge of the chip.
        BAFFLE_CLIP: int (opt) = 150
            If the stop condition is that the SNR is too low, this parameter controls 
            how many previously-fit centroids will be rejected on that end.
    OUTPUTS:
        centroids: 1D array
            List of centroid positions for the fiber and order of length data.shape[1].
            Values are np.nan by default. Otherwise, values are the fractional row
            indices of the centroids for each column.
    '''
    
    ncols = data.shape[1]
    cols = np.arange(ncols)
    centroids = np.array([np.nan for _ in cols])
    snr_thresh_sq = SNR_THRESHOLD*SNR_THRESHOLD
    for sign in np.array([-1,1]):  # Goes left for -1, right for +1
        col = start_col
        centroid = int(np.round(start_row))
        recent_fluxes = collections.deque(QUEUE_LENGTH*[np.inf], maxlen=QUEUE_LENGTH) 
        while (0<=col<ncols) and (np.mean(recent_fluxes) > snr_thresh_sq):
            idx, slc = get_slice(data,col,center=centroid,halfwidth=halfwidth)
            centroid = get_centroid(idx,slc)
            centroids[col] = centroid
            recent_fluxes.append(get_flux(slc))
            col += 1*sign
        if not (np.mean(recent_fluxes) > snr_thresh_sq):
            # Erase recent saved centroids if the recent flux values have been poor
            if sign==1:
                centroids[col-QUEUE_LENGTH-BAFFLE_CLIP:col] = np.nan
            else:   # sign==-1
                centroids[col+1:col+1+QUEUE_LENGTH+BAFFLE_CLIP] = np.nan
    return centroids

def get_flux(slc,smooth=0,remove_bkgd=False):
    '''
    PURPOSE:
        Super crude measure of the flux in a one-column slice.
    METHODOLOGY:
        Sum up the flux within the slice.
    INPUTS:
        slc: 1D array
            Intensity values within the slice.
        smooth: (opt) int = 0
            Median-smoothing is performed over the slice, with a kernel size of `smooth`.
            If 0, no smoothing. If not 0, `smooth` must be an odd number. Occurs before background
            removal, if applicable.
        remove_bkgd: (opt) bool = True
            If true, removes the background
    OUTPUTS:
        flux: 1D array
            Summed intensity values within the slice.
    '''
        
    if smooth > 0:
        slc = medfilt(slc,kernel_size=smooth)
        
    if remove_bkgd:
        slc = get_remove_bkgd(slc)
        
    flux = sum(slc)
    return flux

def get_slice(data,column,
              center=None,halfwidth=None,
              lower_limit=None,upper_limit=None,
              remove_bkgd=True,smooth=0):
    '''
    PURPOSE:
        Retrieve a columnar slice from the image.
    METHODOLOGY:
        Simple array slicing.
    INPUTS:
        data: 2D array
            The full frame image
        column: int
            Index of the column that will contain the slice.
        center: (opt) int or float = None
            Index of the central row of the slice. Floats are rounded to the nearest int.
            Must be provided in conjunction with `halfwidth`.
        halfwidth: (opt) int = None
            The halfwidth of the slice. Fullwidth will be 1+(halfwidth*2).
            Must be provided in conjunction with `center`.
        lower_limit: (opt) int or float = None
            The lower row index of the slice (inclusive). Floats are rounded to the nearest int.
            Must be provided in conjunction with `upper_limit`.
        upper_limit: (opt) int or float = None
            The upper row index of the slice (exclusive). Floats are rounded to the nearest int.
            Must be provided in conjunction with `lower_limit`.
        smooth: (opt) int = 0
            Median-smoothing is performed over the slice, with a kernel size of `smooth`.
            If 0, no smoothing. If not 0, `smooth` must be an odd number. Occurs before background
            removal, if applicable.
        remove_bkgd: (opt) bool = True
            If true, removes the background
        
    OUTPUTS:
        idx: 1D array
            Indices for the slice within the original full-frame image.
 
        slc: 1D array
            Intensity values within the slice.
    '''
    
    assert smooth==0 or (smooth > 0 and type(smooth) is int and smooth%2==1),\
    '`smooth` must be 0 or an odd int.'
    
    assert (center==halfwidth==None) ^ (lower_limit==upper_limit==None),\
    'Must set `center` and `halfwidth` xor `lower_limit` and `upper_limit`.'

    if not center==None:
        center = int(np.round(center))
        idx = np.arange(center-halfwidth,center+halfwidth+1)
    else:
        lower_limit = int(np.round(lower_limit))
        upper_limit = int(np.round(upper_limit))
        idx = np.arange(lower_limit,upper_limit)
    slc = data[idx[0]:idx[-1]+1,column]
    
    if smooth > 0:
        slc = medfilt(slc,kernel_size=smooth)
        
    if remove_bkgd:
        slc = get_remove_bkgd(slc)
    
    return idx,slc
    
def get_centroid(idx,slc):
    '''
    PURPOSE:
        Find the centroid of a slice.
    METHODOLOGY:
        centroid = Sum[x*g(x)]/Sum[g(x)],
        where x is the indices, idx, and g(x) is the intensities, slc.
        The full formula uses integrals rather than sums, but since all the bin sizes are the same,
        we can use sums instead.
    INPUTS:
        idx: 1D array
            Indices for the slice within the original full-frame image.
        slc: 1D array
            Intensity values within the slice.
    OUTPUTS:
        centroid: float
            Centroid of the slice
    '''
        
    centroid = float(np.sum(slc*idx))/np.sum(slc)
    return centroid
    
def get_remove_bkgd(arr):
    '''
    PURPOSE:
        Crudely remove the background from a slice.
    METHODOLOGY:
        Subtract the minimum value in the array from all values.
    INPUTS:
        arr: numpy array
            The array you want to background-subtract.
    OUTPUTS:
        arr_no_bkgd: numpy array
            The array after background subtraction.
    '''
    
    min_val = np.min(arr)
    arr_no_bkgd = arr - min_val
    
    return arr_no_bkgd
    
def print_progress(i,last_printed,ntot,report=10,msg=''):
    '''
    PURPOSE:
        Print progress through a loop periodically.
    METHODOLOGY:
        Compare the last percentage value printed to the current percentage through the 
        loop. Print the new value and update the old if enough progress has been made.
    INPUTS:
        i: int
            The iteration of the loop you just completed.
        last_printed: int
            The iteration of the loop that was last printed out.
        ntot: int
            Total iterations of the loop.
        report: float (opt) = 10
            The function will print if more than `report` percentage of the loop has 
            completed since the last print.
        msg: str (opt) = ''
            String that will print preceding the percentage.
    OUTPUTS:
        last_printed: int
            The iteration of the loop that was last printed out, possibly updated by 
            function.
        perc_comp: str -> stdout
            Prints the percentage progress through the loop to stdout when conditions 
            are met.
    '''
    perc_comp = (100.*i/ntot)
    if (perc_comp - last_printed > report):
        print ('%s%d%%'%(msg,perc_comp))
        return perc_comp
    elif (perc_comp == 100):
        print ('%s100%%'%(msg))
        return perc_comp
    else:
        return last_printed