"""
Written by Allen B. Davis (c) 2018.
Yale University.

Last update: April 30, 2018.
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import medfilt
import collections
import warnings
import sys

def trace(data,
          n_orders=67, reference_row=3500, reference_column=2000,
          blind_search_column_length=300, guess_percentile=90., column_halfwidth=8, degree=4,
          debug_plot=False, verbose=False):
    """
    Generate polynomial fits for two fibers across each order.

    Parameters
    ----------
    data : 2D array
        Reduced 2D image with two fibers illuminated by tungsten/halogen lamp. It is assumed that higher row indices
        correspond to bluer orders.
    n_orders : int (opt)
        Number of orders to be traced. Effectively controls how far into the red will be traced.
    reference_row : int (opt)
        Central row of the initial columnar slice used to find the first science-order pixel. Must be near the
        blue end of the chip to ensure the orders are well-separated.
    reference_column : int (opt)
        Column index of the initial columnar slice used to find the first science-order pixel. This column must run
        through all valid orders/fibers.
    blind_search_column_length: int (opt)
        Length of the initial cut along the reference_column used to locate a position along the first order.
        Should be long enough to definitely hit a couple orders.
    guess_percentile: float (opt)
        Determines which point within a blind slice is guessed to be on an order. Should be close to 100 to obtain a
        bright pixel, but not quite 100 because then you could get a cosmic ray.
    column_halfwidth: int (opt)
        The halfwidth of targeted sliced through an order. Fullwidth will be 1 + (column_halfwidth * 2).
    degree: int (opt)
        Degree of the polynomial fits to the order centroids.
    debug_plot: (opt) bool
        If true, makes plots useful for debugging.
    verbose: (opt) bool
        If true, reports progress as orders are traced.

    Returns
    -------
    red_fiber_centroids: 1D array
        Sub-pixel row indices for centroids of the red fibers for each order.
    blue_fiber_centroids: 1D array
        Sub-pixel row indices for centroids of the blue fibers for each order.
    red_polynomials: 1D array
        Polynomial functions fitted to red_fiber_centroids(col).
    blue_polynomials: 1D array
        Polynomial functions fitted to blue_fiber_centroids(col).

    Notes
    -----
    Identifies an initial pixel on an order. Follows the centroid of slices through that order along the dispersion
    direction, terminating when it reaches the edge of the chip or gets too faint. Then it searches for neighbor fiber
    to the initial fiber, following it across the dispersion direction. Polynomials are fit to the identified centroids.
    Then the next blueward fiber/order is found and traced, along with its neighbor. This continues until it hits the
    blue edge of the chip. It returns to the first order, and then proceeds redward. Continues until the desired number
    of orders are found.
    """

    # Make initial slice. Near the blue end.
    initial_row_indices, initial_column_intensities = get_slice(data, reference_column, center=reference_row,
                                                                halfwidth=blind_search_column_length // 2, smooth=7)

    # Find a point on an order
    guess_row_indices, guess_column_intensities = guess_point(initial_row_indices, initial_column_intensities,
                                                              percentile=guess_percentile)
    plot_guess(data, initial_row_indices, initial_column_intensities, guess_row_indices, guess_column_intensities,
               reference_column, blind_search_column_length, debug_plot=debug_plot)

    # Make another slice next to chosen pixel and centroid twice.
    row_indices, intensities = get_slice(data, reference_column, center=guess_row_indices, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    # plot_column(row_indices,intensities,centroid,label='')
    if debug_plot:
        plt.figure()
        plt.plot(row_indices, intensities, 'o', color='C0', label='1st pass slice')
        plt.axvline(centroid, color='C2', label='1st pass centroid')
        plt.xlabel('row')
        plt.ylabel('flux')
    row_indices, intensities = get_slice(data, reference_column, center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    if debug_plot:
        #  Heights between points at same column may be different due to bkgd subtraction
        plt.plot(row_indices, intensities, '^', color='C1', label='2nd pass slice')
        plt.axvline(centroid, color='C4', label='2nd pass centroid', linestyle='dashed')
        plt.plot(guess_row_indices, guess_column_intensities, '*', color='C5', label='order guess')
        plt.xlabel('row')
        plt.ylabel('flux')
        plt.legend()
        plt.show()

    # Follow along this order & fiber, saving centroids_init (for the initial fiber).
    centroids_init = follow_fiber(data, centroid, reference_column, column_halfwidth)

    # Fit polynomial to the centroids
    p_init = fit_polynomial(np.arange(data.shape[1]), centroids_init, degree=degree)

    # Hunt for second fiber. Compare two candidate slices above and below this fiber.
    fiber_hunt_offset = 2 + column_halfwidth
    fiber_hunt_column_length = 20
    cent_init = centroids_init[reference_column]
    candidate_1_indices, candidate_1_intensities = get_slice(data, reference_column,  # Blue side
                                                             lower_limit=cent_init + fiber_hunt_offset,
                                                             upper_limit=cent_init + fiber_hunt_offset + fiber_hunt_column_length,
                                                             smooth=7)
    candidate_2_indices, candidate_2_intensities = get_slice(data, reference_column,  # Red side
                                                             lower_limit=cent_init - fiber_hunt_offset - fiber_hunt_column_length,
                                                             upper_limit=cent_init - fiber_hunt_offset, smooth=7)

    flux1 = get_total_flux(candidate_1_intensities, smooth=7, remove_background=True)
    flux2 = get_total_flux(candidate_2_intensities, smooth=7, remove_background=True)

    assert (flux1 > 0 or flux2 > 0) and ((flux1 > flux2 * 2) ^ (flux2 > flux1 * 2)), \
        'The fluxes in the candidate slices while hunting for the neighboring slice were ' \
        '%f and %f after median filtering and background removal. At least one needed to ' \
        'be positive and one should be more than twice the other. This was not the case, ' \
        'so it is unclear which is the real neighbor fiber.'

    if flux1 > flux2:
        neighbor_fiber_row_indices = candidate_1_indices
        neighbor_fiber_intensities = candidate_1_intensities
    else:
        neighbor_fiber_row_indices = candidate_2_indices
        neighbor_fiber_intensities = candidate_2_intensities

    guess_row_indices, guess_column_intensities = guess_point(neighbor_fiber_row_indices,
                                                              neighbor_fiber_intensities, percentile=guess_percentile)
    row_indices, intensities = get_slice(data, reference_column, center=guess_row_indices, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    row_indices, intensities = get_slice(data, reference_column, center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)

    centroids_neighbor = follow_fiber(data, centroid, reference_column, column_halfwidth)
    polynomial_neighbor = fit_polynomial(np.arange(data.shape[1]), centroids_neighbor, degree=degree)

    # Create lists to hold fiber centroids.
    if polynomial_neighbor(reference_column) > p_init(reference_column):
        red_fiber_centroids = collections.deque([centroids_init])
        blue_fiber_centroids = collections.deque([centroids_neighbor])
        red_polynomials = collections.deque([p_init])
        blue_polynomials = collections.deque([polynomial_neighbor])
    else:
        red_fiber_centroids = collections.deque([centroids_neighbor])
        blue_fiber_centroids = collections.deque([centroids_init])
        red_polynomials = collections.deque([polynomial_neighbor])
        blue_polynomials = collections.deque([p_init])

    if debug_plot:
        cols = np.arange(data.shape[1])
        plt.figure()
        plt.imshow(data - np.min(data), vmax=500, origin='lower')
        plt.plot(cols, red_fiber_centroids[0], '-', color='C1', label='red centroids')
        plt.plot(cols, red_polynomials[0](cols), linewidth=1, color='red', linestyle='dashed', label='red poly')
        plt.plot(cols, blue_fiber_centroids[0], '-', color='C2', label='blue centroids')
        plt.plot(cols, blue_polynomials[0](cols), linewidth=1, color='blue', linestyle='dashed', label='blue poly')
        plt.legend()
        plt.xlabel('col')
        plt.ylabel('row')
        plt.colorbar()
        plt.title('Fit along first order')
        plt.show()

        plt.figure()
        plt.plot(cols, red_fiber_centroids[0] - red_polynomials[0](cols), color='C1', linewidth=0.5, label='red')
        plt.plot(cols, blue_fiber_centroids[0] - blue_polynomials[0](cols), color='C0', linewidth=0.5, label='blue')
        plt.legend()
        plt.title('residuals: cent-poly')
        plt.xlabel('col')
        plt.ylabel('residuals')
        plt.legend()
        plt.show()

    # Determine the smoothed peak flux in this red fiber, so that we can set a good
    # threshold for the next red fiber.
    n_slices_peak = 20
    red_vals = np.zeros((n_slices_peak, 2 * column_halfwidth + 1))
    for i in range(n_slices_peak):
        row_indices, intensities = get_slice(data, reference_column + i,
                                             center=red_polynomials[0](reference_column), halfwidth=column_halfwidth,
                                             remove_background=False, smooth=0)
        red_vals[i, :] = intensities
    red_vals = red_vals - np.min(red_vals)
    red_vals = medfilt(red_vals, kernel_size=5)
    red_peak = np.max(red_vals)

    # Determine separation between this order's blue fiber and next order's red fiber.
    order_separation = 2 + column_halfwidth
    order_search_column_length = 100
    lower_limit = blue_polynomials[0](reference_column) + order_separation
    row_indices, intensities = get_slice(data, reference_column,
                                         lower_limit=lower_limit,
                                         upper_limit=lower_limit + order_search_column_length,
                                         remove_background=True, smooth=5)
    order_separation_list = 3
    o_sep_hunt_queue = collections.deque(order_separation_list * [0], maxlen=order_separation_list)
    order_separation_threshold_ratio = 0.3
    threshold = red_peak * order_separation_threshold_ratio
    i = 0
    while np.mean(o_sep_hunt_queue) < threshold:
        assert i < len(intensities), 'Failed to find the red fiber in the next order. ' \
                                     'You could try reducing order_separation_threshold_ratio, currently ' \
                                     '%.f, which corresponds to a threshold flux value of %d.' \
                                     '' % (order_separation_threshold_ratio, threshold)
        o_sep_hunt_queue.append(intensities[i])
        i += 1
    guess_row_indices = row_indices[i]
    row_indices, intensities = get_slice(data, reference_column, center=guess_row_indices, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    row_indices, intensities = get_slice(data, reference_column, center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)

    o_sep_init = int(np.round(centroid - blue_polynomials[0](reference_column)))
    assert o_sep_init > 0, 'o_sep_init must be positive.'

    # Search for other orders
    n_found = 1
    direction = 'blue'
    o_sep = o_sep_init
    last_printed = 0
    switched_direction = False
    while n_found < n_orders:
        if direction == 'blue':
            previous_index = 0
            previous_polynomial = blue_polynomials[previous_index]
        else:
            previous_index = -1
            previous_polynomial = red_polynomials[previous_index]

        f_sep = abs(blue_polynomials[previous_index](reference_column)
                    - red_polynomials[previous_index](reference_column))
        print('f_sep: %d, o_sep: %d'%(f_sep, o_sep))
        cent_red, cent_blue, p_red, p_blue = find_next_order(data, previous_polynomial, direction, reference_column,
                                                             f_sep, o_sep, column_halfwidth, degree)
        if p_red is not None:
            print('p_red: %d'%p_red(2000))
        if p_blue is not None:
            print('p_blue: %d'%p_blue(2000))

        if p_red is None or p_blue is None:
            if not switched_direction:
                # Change direction once we've exhausted the blue orders.
                direction = 'red'
                o_sep = o_sep_init
                switched_direction = True
                continue
            else:
                # Exhausted red orders. End the loop.
                break

        if direction == 'blue':
            red_fiber_centroids.appendleft(cent_red)
            blue_fiber_centroids.appendleft(cent_blue)
            red_polynomials.appendleft(p_red)
            blue_polynomials.appendleft(p_blue)
        else:
            red_fiber_centroids.append(cent_red)
            blue_fiber_centroids.append(cent_blue)
            red_polynomials.append(p_red)
            blue_polynomials.append(p_blue)

        if direction == 'blue':
            o_sep = int(np.round(p_red(reference_column) - previous_polynomial(reference_column)))
        else:
            o_sep = int(np.round(previous_polynomial(reference_column) - p_blue(reference_column)))
        assert o_sep > 0, 'o_sep must be positive.'

        n_found += 1

        if verbose:
            last_printed = print_progress(n_found, last_printed, n_orders, report=1,
                                          msg='Tracing orders... ', verbose=verbose)
            print('{}/{}'.format(n_found, n_orders))
            sys.stdout.flush()

    return red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials


def find_next_order(data, previous_polynomial, direction, init_col, f_sep, o_sep, halfwidth, degree):
    """
    Trace the centroids of the two fibers in an adjacent order.

    Parameters
    ----------
    data: 2D array
        The full frame image.
    previous_polynomial: 1D polynomial
        Polynomial function tracing the fiber on the `direction`-side of the previous order.
    direction: str
        'blue' or 'red' are the acceptable values. Determines in which direction we search for the next order.
    init_col: int
        The column at which the first centroid of the new orders will be determined.
    f_sep: int
        A guess of the pixels between the center of the two fiber in an order.
    o_sep: int
        A guess of the pixels between the center of a previous fiber and the center of the closest fiber in the
        neighboring order.
    halfwidth: int
        The halfwidth of the slices through the next order. Fullwidth will be 1+(halfwidth*2).
    degree: int
        Degree of the polynomial fit.

    Returns
    -------
    centroids_red: 1D array
        Sub-pixel row indices for centroids of the next order's red fiber.
    centroids_blue: 1D array
        Sub-pixel row indices for centroids of the next order's blue fiber.
    poly_red: 1D polynomial
        Polynomial function fitted to centroids_red(col).
    poly_blue: 1D polynomial
        Polynomial function fitted to centroids_red(col).
    """

    centroids_1, polynomial_1 = find_next_fiber(data, previous_polynomial, direction,
                                                init_col, o_sep, halfwidth, degree)
    if polynomial_1 is None:
        return None, None, None, None
        # centroids_red = centroids_blue = poly_red = poly_blue = None
    centroids_2, polynomial_2 = find_next_fiber(data, polynomial_1, direction, init_col, f_sep, halfwidth, degree)
    if polynomial_2 is None:
        return None, None, None, None
        # centroids_red = centroids_blue = poly_red = poly_blue = None

    if direction == 'blue':
        centroids_red = centroids_1
        centroids_blue = centroids_2
        poly_red = polynomial_1
        poly_blue = polynomial_2
    else:
        centroids_red = centroids_2
        centroids_blue = centroids_1
        poly_red = polynomial_2
        poly_blue = polynomial_1

    return centroids_red, centroids_blue, poly_red, poly_blue


def find_next_fiber(data, reference_polynomial, direction, init_col, sep, halfwidth, degree):
    """
    Trace the centroids of one fibers in the adjacent order.

    Parameters
    ----------
    data: 2D array
        The full frame image.
    reference_polynomial: 1D polynomial
        Polynomial function tracing the fiber on the `direction`-side of the previous order.
    direction: str
        'blue' or 'red' are the acceptable values. Determines in which direction we search for the next order.
    init_col: int
        The column at which the first centroid of the new orders will be determined.
    sep: int
        Guess of the pixels between the center of a previous fiber and the center of the next closest fiber in the
        given direction.
    halfwidth: int
        The halfwidth of the slices through the next order. Fullwidth will be 1 + (halfwidth *2).
    degree: int
        Degree of the polynomial fit.

    Returns
    -------
    centroids: 1D array
        Sub-pixel row indices for centroids of the next fiber.
    poly: 1D polynomial
        Polynomial function fitted to centroids(col).
    """

    assert direction == 'blue' or direction == 'red', "Only 'blue' and 'red' are valid inputs for `direction`."

    if direction == 'blue':
        sign = 1
    else:
        sign = -1

    guess = reference_polynomial(init_col) + sep * sign
    idx, slc = get_slice(data, init_col, center=guess, halfwidth=halfwidth)
    centroid = get_centroid(idx, slc)
    idx, slc = get_slice(data, init_col, center=centroid, halfwidth=halfwidth)
    centroid = get_centroid(idx, slc)
    centroids = follow_fiber(data, centroid, init_col, halfwidth)
    poly = fit_polynomial(np.arange(data.shape[1]), centroids, degree=degree)

    return centroids, poly


def guess_point(idx, slc, percentile=90.):
    """
    Identify a point that is on an order within the slice.

    METHODOLOGY:
        Sorts indices and intensities by the intensities, then returns the idx and inten
        at the requested percentile.

    Parameters
    ----------
        idx: 1D array
            Indices for the slice within the original full-frame image.
        slc: 1D array
            Intensity values within the slice.
        percentile: float
            Percentile of the intensities represented in the slice that will be returned as the guess.

    Returns
    -------
    guess_idx: 1D array
        Index of the guess position.
    guess_inten: 1D array
        Intensity of the guessed pixel.
    """

    vals = [[x, y] for y, x in sorted(zip(slc, idx))]
    guess_idx, guess_inten = vals[int(len(vals) * percentile / 100.)]
    return guess_idx, guess_inten


def fit_polynomial(column_indices, row_indices, degree=4):
    """
    Fit a polynomial to the function row(column) for one fiber within an order.

    Parameters
    ----------
    column_indices : 1D array
    row_indices : 1D array
    degree : int (opt)

    Returns
    -------
    poly: 1D polynomial
    """
    try:
        valid_indices = ~np.isnan(row_indices)
        z = np.polyfit(column_indices[valid_indices], row_indices[valid_indices], deg=degree)
        poly = np.poly1d(z)
    except (TypeError, ValueError) as e:
        # Occurs when valid_indices is all False: i.e., no centroids are there to be traced,
        # or when one of the parameters is None.
        poly = None
    return poly


def follow_fiber(data, start_row, start_col, halfwidth,
                 queue_length=20, snr_threshold=20, baffle_clip=150):
    """
    Finds all the centroids of one fiber along an entire order.

    Parameters
    ----------
    data: 2D array
        The full frame image.
    start_col: int or float
        Index of the column for the first starting position along the fiber.
    start_row: int
        Index of the row for the first starting position along the fiber.
    halfwidth: (opt) int
        The halfwidth of the slice. Fullwidth will be 1 + (halfwidth * 2).
    queue_length: int (opt)
        The queue keeps track of the fluxes within the last queue_length fitted centroids. If the median drops before
        a value based on snr_threshold, a stop condition is met.
    snr_threshold: int (opt) = 20
        Threshold SNR value (i.e., sqrt(sum(slice))) which must be met to continue following an order towards on
        edge of the chip.
    baffle_clip: int (opt) = 150
        If the stop condition is that the SNR is too low, this parameter controls how many previously-fit centroids
        will be rejected on that end.

    Returns
    -------
    centroids: 1D array
        List of centroid positions for the fiber and order of length data.shape[1]. Values are np.nan by default.
        Otherwise, values are the fractional row indices of the centroids for each column.

    Notes
    -----
    Starts with a known centroid, and then walks column-by-column to the left, updating the centroids as it goes.
    Stop conditions is hitting the edge of the chip or when the SNR gets too low (in this case, extra pixels are
    removed to account for defects due to the baffle). Then it does the same thing to the right.
    """

    ncols = data.shape[1]
    cols = np.arange(ncols)
    centroids = np.array([np.nan for _ in cols])
    snr_thresh_sq = snr_threshold * snr_threshold
    for sign in np.array([-1, 1]):  # Goes left for -1, right for +1
        col = start_col
        try:
            centroid = int(np.round(start_row))
        except AttributeError:
            centroids = None
            break
        recent_fluxes = collections.deque(queue_length * [np.inf], maxlen=queue_length)
        while (0 <= col < ncols) and (np.mean(recent_fluxes) > snr_thresh_sq):
            idx, slc = get_slice(data, col, center=centroid, halfwidth=halfwidth)
            centroid = get_centroid(idx, slc)
            centroids[col] = centroid
            recent_fluxes.append(get_total_flux(slc))
            col += 1 * sign
        if not (np.mean(recent_fluxes) > snr_thresh_sq):
            # Erase recent saved centroids if the recent flux values have been poor
            if sign == 1:
                centroids[col - queue_length - baffle_clip:col] = np.nan
            else:  # sign==-1
                centroids[col + 1:col + 1 + queue_length + baffle_clip] = np.nan
    return centroids


def get_total_flux(slc, smooth=0, remove_background=False):
    """
    Sums up the flux within a section of a column.

    Parameters
    ----------
    slc: 1D array
        Intensity values within the slice.
    smooth: (opt) int = 0
        Median-smoothing is performed over the slice, with a kernel size of `smooth`. If 0, no smoothing. If not 0,
        `smooth` must be an odd number. Occurs before background removal, if applicable.
    remove_background: (opt) bool = True
        If true, removes the background

    Returns
    -------
    flux: 1D array
        Summed intensity values within the slice.
    """

    if smooth > 0:
        slc = medfilt(slc, kernel_size=smooth)

    if remove_background:
        slc = get_remove_background(slc)

    flux = sum(slc)
    return flux


def get_slice(data, column,
              center=None, halfwidth=None,
              lower_limit=None, upper_limit=None,
              remove_background=True, smooth=0):
    """
    Retrieve a columnar slice from the image.

    Parameters
    ----------
    data: 2D array
        The full frame image
    column: int
        Index of the column that will contain the slice.
    center: (opt) int or float = None
        Index of the central row of the slice. Floats are rounded to the nearest int. Must be provided in conjunction
        with `halfwidth`.
    halfwidth: (opt) int = None
        The halfwidth of the slice. Fullwidth will be 1 + (halfwidth * 2). Must be provided in
        conjunction with `center`.
    lower_limit: (opt) int or float
        The lower row index of the slice (inclusive). Floats are rounded to the nearest int. Must be provided in
        conjunction with `upper_limit`.
    upper_limit: (opt) int or float
        The upper row index of the slice (exclusive). Floats are rounded to the nearest int. Must be provided in
        conjunction with `lower_limit`.
    smooth: (opt) int
        Median-smoothing is performed over the slice, with a kernel size of `smooth`. If 0, no smoothing. If not 0,
        `smooth` must be an odd number. Occurs before background removal, if applicable.
    remove_background: (opt) bool
        If true, removes the background.

    Returns
    -------
    idx: 1D array
        Indices for the slice within the original full-frame image.
    slc: 1D array
        Intensity values within the slice.
    """

    if (smooth > 0 and smooth % 2 == 0):
        smooth += 1
        warnings.warn('`smooth` should be an odd number. Increased value to {}.'.format(smooth))

    if center is not None and halfwidth is not None:
        center = int(np.round(center))
        idx = np.arange(center - halfwidth, center + halfwidth + 1)
    elif lower_limit is not None and upper_limit is not None:
        lower_limit = int(np.round(lower_limit))
        upper_limit = int(np.round(upper_limit))
        idx = np.arange(lower_limit, upper_limit)
    else:
        idx = None

    if idx is not None:
        slc = data[idx[0]:idx[-1] + 1, column]
        if smooth > 0:
            slc = medfilt(slc, kernel_size=smooth)

        if remove_background:
            slc = get_remove_background(slc)
    else:
        slc = None

    return idx, slc


def get_centroid(row_indices, column_intensities):
    """
    Find the centroid of a slice.

    Parameters
    ----------
    row_indices: 1D array
        Indices for the slice within the original full-frame image.
    column_intensities: 1D array
        Intensity values within the slice.

    Returns
    -------
    centroid: float
        Centroid of the slice

    Notes
    -----
    Centroid is determined by Sum[x*g(x)]/Sum[g(x)], where x is the row_indices, and g(x) is the intensities.
    The full formula uses integrals rather than sums, but since all the bin sizes are the same, we can use sums instead.
    Exception handles case for the column running off the bottom/top of the chip.
    """
    try:
        centroid = float(np.sum(column_intensities * row_indices)) / np.sum(column_intensities)
    except (TypeError, ValueError) as e:
        # Occurs when column_intensities and/or row_indices are None.
        centroid = None
    return centroid


def get_remove_background(arr):
    """
    Crudely remove the background from a slice.

    Parameters
    ----------
    arr: numpy array
        The array you want to background-subtract.

    Returns
    -------
    array_no_background: numpy array
        The array after background subtraction.
    """

    min_value = np.min(arr)
    array_no_background = arr - min_value

    return array_no_background


def print_progress(i, last_printed, n_tot, report=10, msg='', verbose=False):
    """
    Prints progress through a loop periodically.

    Parameters
    ----------
    i: int
        The iteration of the loop you just completed.
    last_printed: int
        The iteration of the loop that was last printed out.
    n_tot: int
        Total iterations of the loop.
    report: float (opt) = 10
        The function will print if more than `report` percentage of the loop has completed since the last print.
    msg: str (opt) = ''
        String that will print preceding the percentage.
    verbose: bool
        Flag for printing progress to stdout.

    Returns
    -------
    last_printed: int
        The iteration of the loop that was last printed out, possibly updated by function.
    percent_complete: str -> stdout
        Prints the percentage progress through the loop to stdout when conditions are met.

    Notes
    -----
    Compare the last percentage value printed to the current percentage through the loop. Print the new value and
    update the old if enough progress has been made.
    """
    percent_complete = (100. * i / n_tot)
    if percent_complete - last_printed > report or percent_complete == 100:
        if verbose:
            print('{msg}{percent_complete}%'.format(msg=msg, percent_complete=percent_complete))
        last_printed = percent_complete

    return last_printed


def plot_guess(data, row_indices, initial_column_intensities, guess_row_indices, guess_column_intensities,
               reference_column, blind_search_column_length, debug_plot=False):
    if debug_plot:
        # The order guess should land clearly on an order. Doesn't need to be well-centered.
        plt.figure()
        plt.plot(row_indices, initial_column_intensities, label='slice')
        plt.plot(guess_row_indices, guess_column_intensities, 'o', label='order guess')
        plt.legend()
        plt.xlabel('row')
        plt.ylabel('counts')
        plt.title('slice along column {col_number}'.format(col_number=reference_column))
        plt.show()

        xmin = reference_column - blind_search_column_length // 2 - 50
        xmax = reference_column + blind_search_column_length // 2 + 50
        ymin = np.min(row_indices) - 50
        ymax = np.max(row_indices) + 50
        vmin = np.min(data[ymin:ymax, xmin:xmax])
        vmax = np.max(data[ymin:ymax, xmin:xmax])

        plt.figure()
        plt.imshow(data, origin='lower', vmin=vmin, vmax=vmax)
        plt.plot([reference_column for _ in row_indices], row_indices, color='white')
        plt.plot(reference_column, guess_row_indices, 'o', color='orange')
        plt.xlim(xmin, xmax)
        plt.ylim(ymin, ymax)
        plt.xlabel('col')
        plt.ylabel('row')
        color_bar = plt.colorbar()
        color_bar.set_label('counts')
        plt.title('Initial slice along 2D spectra')
        plt.show()
