"""
Written by Allen B. Davis (c) 2018.
Yale University.

Last update: May 2, 2018.
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import medfilt
import collections
import warnings
import sys
import datetime
from astropy.io import fits


@app.task
def trace(in_file, out_file, n_orders=67, reference_row=3500, reference_column=2000, blind_search_column_length=300,
          guess_percentile=90., column_halfwidth=8, baffle_clip=150, degree=4, every=16,
          return_objects=False, debug_plots=False, verbose=False):
    """
    Generate polynomial fits for two fibers across each order.

    Parameters
    ----------
    in_file : str
        Full file path and name for the image fits file you want to trace. Image should have its higher row indices
        corresponding to bluer orders.
    out_file : str
        Full file path and name of the output ascii file.
    n_orders : int (opt)
        Number of orders to be traced. Effectively controls how far into the red will be traced.
    reference_row : int (opt)
        Central row of the initial columnar slice used to find the first science-order pixel. Must be near the
        blue end of the chip to ensure the orders are well-separated.
    reference_column : int (opt)
        Column index of the initial columnar slice used to find the first science-order pixel. This column must run
        through all valid orders/fibers.
    blind_search_column_length : int (opt)
        Length of the initial cut along the reference_column used to locate a position along the first order.
        Should be long enough to definitely hit a couple orders.
    guess_percentile : float (opt)
        Determines which point within a blind slice is guessed to be on an order. Should be close to 100 to obtain a
        bright pixel, but not quite 100 because then you could get a cosmic ray.
    column_halfwidth : int (opt)
        The halfwidth of targeted sliced through an order. Fullwidth will be 1 + (column_halfwidth * 2).
    baffle_clip : int (opt)
        If the stop condition is that the SNR is too low, this parameter controls how many previously-fit centroids
        will be rejected on that end.
    degree : int (opt)
        Degree of the polynomial fits to the order centroids.
    every : int (opt)
        In the ascii file, positions are output every `every` columns.
    return_objects : bool (opt)
        If true, returns the centroids and polynomial fits.
    debug_plots: bool or list (opt)
        If true, makes all plots useful for debugging. If False, none are made. If list, elements should be the
        numbers of the desired plots. E.g., [1,4,5] would create plots 1, 4, and 5.
        1 : plot_guess: position of the guess on the 1D column, and in the 2D image
        2 : plot_column: shows the column centered on the initial and second centroid.
        3 : plot_first_polynomial: shows first polynomial fit on top of the 2D image
        4 : plot_first_polynomial_residuals: shows residuals for the first fit's centroids-polynomial
        5 : plot_all_polynomials: shows all polynomial fits on top of the 2D image
        6 : plot_all_polynomial_residuals: shows residuals for the each fit's centroids-polynomial
    verbose: bool (opt)
        If true, reports progress as orders are traced.

    Returns
    -------
    red_fiber_centroids: 1D array (opt)
        Sub-pixel row indices for centroids of the red fibers for each order.
    blue_fiber_centroids: 1D array (opt)
        Sub-pixel row indices for centroids of the blue fibers for each order.
    red_polynomials: 1D array (opt)
        Polynomial functions fitted to red_fiber_centroids(col).
    blue_polynomials: 1D array (opt)
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

    image, header = get_data(in_file)

    initial_row_indices, initial_column_intensities = get_column(
        image, reference_column, center=reference_row, halfwidth=blind_search_column_length // 2, smooth=7)
    guess_row_index, guess_column_intensity = guess_point(initial_row_indices, initial_column_intensities,
                                                          percentile=guess_percentile)
    plot_guess(image, initial_row_indices, initial_column_intensities, guess_row_index, guess_column_intensity,
               reference_column, blind_search_column_length, debug_plots=debug_plots)

    row_indices, intensities = get_column(image, reference_column, center=guess_row_index,
                                          halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    fig, ax = plot_column(row_indices, intensities, guess_row_index, guess_column_intensity, centroid,
                          debug_plots=debug_plots)
    row_indices, intensities = get_column(image, reference_column, center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    plot_column(row_indices, intensities, guess_row_index, guess_column_intensity, centroid, fig=fig, ax=ax,
                debug_plots=debug_plots)

    centroids_initial = follow_fiber(image, centroid, reference_column, column_halfwidth, baffle_clip)
    polynomial_initial = fit_polynomial(np.arange(image.shape[1]), centroids_initial, degree=degree)

    neighbor_fiber_row_indices, neighbor_fiber_intensities = find_first_neighbor_fiber(
        image, centroids_initial, reference_column, column_halfwidth)
    guess_row_index, guess_column_intensity = guess_point(neighbor_fiber_row_indices, neighbor_fiber_intensities,
                                                          percentile=guess_percentile)

    row_indices, intensities = get_column(image, reference_column,
                                          center=guess_row_index, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    row_indices, intensities = get_column(image, reference_column,
                                          center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)

    centroids_neighbor = follow_fiber(image, centroid, reference_column, column_halfwidth, baffle_clip=baffle_clip)
    polynomial_neighbor = fit_polynomial(np.arange(image.shape[1]), centroids_neighbor, degree=degree)

    red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials = assign_fiber_colors(
        polynomial_initial, polynomial_neighbor, centroids_initial, centroids_neighbor, reference_column)

    plot_first_polynomial(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                          debug_plots=debug_plots)
    plot_first_polynomial_residuals(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                                    debug_plots=debug_plots)

    red_peak = get_peak_flux(image, red_polynomials, reference_column, column_halfwidth)
    order_separation_initial = get_initial_order_separation(image, red_peak, blue_polynomials, reference_column,
                                                            column_halfwidth)

    red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials = find_other_orders(
        image, order_separation_initial, red_fiber_centroids, blue_fiber_centroids, red_polynomials,
        blue_polynomials, reference_column, column_halfwidth, baffle_clip, degree, n_orders, verbose)

    plot_all_polynomials(image, red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials,
                         debug_plots=debug_plots)
    plot_all_polynomial_residuals(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                                  debug_plots=debug_plots)

    make_ascii(out_file, in_file, header, red_polynomials, blue_polynomials, every)

    if return_objects:
        return red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials


def find_first_neighbor_fiber(image, centroids_initial, reference_column, column_halfwidth):
    """
    Executes a blind searches for the neighbor fiber (i.e., within the same order) to the initial fiber.

    Parameters
    ----------
    image : 2D array
    centroids_initial : 1D array
    reference_column : int
    column_halfwidth : int

    Returns
    -------
    neighbor_fiber_row_indices : 1D array
    neighbor_fiber_intensities : 1D array
    """
    fiber_hunt_offset = 2 + column_halfwidth
    fiber_hunt_column_length = 20
    centroid_initial = centroids_initial[reference_column]

    candidate_1_indices, candidate_1_intensities = get_column(
        image, reference_column, lower_limit=centroid_initial + fiber_hunt_offset,
        upper_limit=centroid_initial + fiber_hunt_offset + fiber_hunt_column_length, smooth=7)

    candidate_2_indices, candidate_2_intensities = get_column(
        image, reference_column, lower_limit=centroid_initial - fiber_hunt_offset - fiber_hunt_column_length,
        upper_limit=centroid_initial - fiber_hunt_offset, smooth=7)

    flux1 = get_total_flux(candidate_1_intensities, smooth=7, remove_background=True)
    flux2 = get_total_flux(candidate_2_intensities, smooth=7, remove_background=True)

    if not (flux1 > 0 or flux2 > 0) and ((flux1 > flux2 * 2) ^ (flux2 > flux1 * 2)):
        warnings.warn('The fluxes in the candidate slices while hunting for the neighboring slice were '
                      '{flux1} and {flux2} after median filtering and background removal. At least one needed to '
                      'be positive and one should be more than twice the other. This was not the case, '
                      'so it is not fully clear which is the real neighbor fiber.'.format(flux1=flux1, flux2=flux2))

    if flux1 >= flux2:
        neighbor_fiber_row_indices = candidate_1_indices
        neighbor_fiber_intensities = candidate_1_intensities
    else:
        neighbor_fiber_row_indices = candidate_2_indices
        neighbor_fiber_intensities = candidate_2_intensities

    return neighbor_fiber_row_indices, neighbor_fiber_intensities


def find_other_orders(image, order_separation_initial, red_fiber_centroids, blue_fiber_centroids, red_polynomials,
                      blue_polynomials, reference_column, column_halfwidth, baffle_clip, degree, n_orders, verbose):
    """
    Starting with a known pair of fibers, this function locates and traces other pairs of fibers throughout the image.

    Parameters
    ----------
    image : 2D array
    order_separation_initial: int
        First guess at the distance between the nearest two fibers in a pair of adjacent orders.
    red_fiber_centroids : list of 1D arrays
    blue_fiber_centroids : list of 1D arrays
    red_polynomials : list of 1D polynomials
    blue_polynomials : list of 1D polynomials
    reference_column : int
    column_halfwidth : int
    baffle_clip : int
    degree : int
    n_orders : int
    verbose : bool

    Returns
    -------
    red_fiber_centroids : list of 1D arrays
    blue_fiber_centroids : list of 1D arrays
    red_polynomials : list of 1D polynomials
    blue_polynomials : list of 1D polynomials
    """
    n_found = 1
    direction = 'blue'
    order_separation = order_separation_initial
    last_printed = 0
    switched_direction = False
    while n_found < n_orders:
        if direction == 'blue':
            previous_index = 0
            previous_polynomial = blue_polynomials[previous_index]
        else:
            previous_index = -1
            previous_polynomial = red_polynomials[previous_index]

        fiber_separation = abs(blue_polynomials[previous_index](reference_column)
                               - red_polynomials[previous_index](reference_column))

        cent_red, cent_blue, p_red, p_blue = find_next_order(
            image, previous_polynomial, direction, reference_column, fiber_separation, order_separation,
            column_halfwidth, baffle_clip, degree)

        if p_red is None or p_blue is None:
            if not switched_direction:
                # Change direction once we've exhausted the blue orders.
                direction = 'red'
                order_separation = order_separation_initial
                switched_direction = True
                continue
            else:
                # Exhausted red orders. End the loop.
                break

        if direction == 'blue':
            red_fiber_centroids.insert(0, cent_red)
            blue_fiber_centroids.insert(0, cent_blue)
            red_polynomials.insert(0, p_red)
            blue_polynomials.insert(0, p_blue)
        else:
            red_fiber_centroids.append(cent_red)
            blue_fiber_centroids.append(cent_blue)
            red_polynomials.append(p_red)
            blue_polynomials.append(p_blue)

        if direction == 'blue':
            order_separation = int(np.round(p_red(reference_column) - previous_polynomial(reference_column)))
        else:
            order_separation = int(np.round(previous_polynomial(reference_column) - p_blue(reference_column)))
        # assert order_separation > 0, 'order_separation must be positive.' ### MOVE TO UNIT TEST

        n_found += 1

        last_printed = print_progress(n_found, last_printed, n_orders, report=10,
                                      msg='Tracing orders... ', verbose=verbose)

    return red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials


def find_next_order(image, previous_polynomial, direction, reference_column, fiber_separation, order_separation,
                    halfwidth, baffle_clip, degree):
    """
    Trace the centroids of the two fibers in an adjacent order.

    Parameters
    ----------
    image : 2D array
    previous_polynomial : 1D polynomial
        Polynomial function tracing the fiber on the `direction`-side of the previous order.
    direction : str
        'blue' or 'red' are the acceptable values. Determines in which direction we search for the next order.
    reference_column : int
    fiber_separation : int
        A guess of the pixels between the center of the two fiber in an order.
    order_separation : int
        A guess of the pixels between the center of a previous fiber and the center of the closest fiber in the
        neighboring order.
    halfwidth : int
    baffle_clip : int
    degree : int

    Returns
    -------
    centroids_red : 1D array
        Sub-pixel row indices for centroids of the next order's red fiber.
    centroids_blue : 1D array
        Sub-pixel row indices for centroids of the next order's blue fiber.
    poly_red : 1D polynomial
        Polynomial function fitted to centroids_red(col).
    poly_blue : 1D polynomial
        Polynomial function fitted to centroids_red(col).
    """

    centroids_1, polynomial_1 = find_next_fiber(image, previous_polynomial, direction, reference_column,
                                                order_separation, halfwidth, baffle_clip, degree)
    centroids_2, polynomial_2 = find_next_fiber(image, polynomial_1, direction, reference_column,
                                                fiber_separation, halfwidth, baffle_clip, degree)
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


def find_next_fiber(image, reference_polynomial, direction, reference_column, separation, halfwidth, baffle_clip,
                    degree):
    """
    Trace the centroids of one fibers in the adjacent order.

    Parameters
    ----------
    image : 2D array
    reference_polynomial : 1D polynomial
        Polynomial function tracing the fiber on the `direction`-side of the previous order.
    direction : str
        'blue' or 'red' are the acceptable values. Determines in which direction we search for the next order.
    reference_column : int
    separation : int
        Guess of the pixels between the center of a previous fiber and the center of the next closest fiber in the
        given direction. Could be the separation between fibers or orders, depending on context.
    halfwidth : int
    baffle_clip : int
    degree : int

    Returns
    -------
    centroids : 1D array
        Sub-pixel row indices for centroids of the next fiber.
    poly : 1D polynomial
        Polynomial function fitted to centroids(col).
    """

    if direction == 'blue':
        sign = 1
    else:
        sign = -1

    try:
        guess = reference_polynomial(reference_column) + separation * sign
        indices, intensities = get_column(image, reference_column, center=guess, halfwidth=halfwidth)
        centroid = get_centroid(indices, intensities)
        indices, intensities = get_column(image, reference_column, center=centroid, halfwidth=halfwidth)
        centroid = get_centroid(indices, intensities)
        centroids = follow_fiber(image, centroid, reference_column, halfwidth, baffle_clip=baffle_clip)
        poly = fit_polynomial(np.arange(image.shape[1]), centroids, degree=degree)
    except TypeError:
        centroids = poly = None

    return centroids, poly


def assign_fiber_colors(polynomial_initial, polynomial_neighbor, centroids_initial, centroids_neighbor,
                        reference_column):
    """
    Initializes a list for the red and blue fiber centroids and polynomials.

    Parameters
    ----------
    polynomial_initial : 1D polynomial
    polynomial_neighbor : 1D polynomial
    centroids_initial : 1D array
    centroids_neighbor : 1D array
    reference_column : int

    Returns
    -------
    red_fiber_centroids : list of 1D arrays
    blue_fiber_centroids : list of 1D arrays
    red_polynomials : list of 1D polynomials
    blue_polynomials : list of 1D polynomials
    """

    if polynomial_neighbor(reference_column) > polynomial_initial(reference_column):
        red_fiber_centroids = [centroids_initial]
        blue_fiber_centroids = [centroids_neighbor]
        red_polynomials = [polynomial_initial]
        blue_polynomials = [polynomial_neighbor]
    else:
        red_fiber_centroids = [centroids_neighbor]
        blue_fiber_centroids = [centroids_initial]
        red_polynomials = [polynomial_neighbor]
        blue_polynomials = [polynomial_initial]

    return red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials


def guess_point(indices, intensities, percentile=90.):
    """
    Identify a point that is on an order within the column slice.

    Parameters
    ----------
    indices : 1D array
        Row indices for the column within the original full-frame image.
    intensities : 1D array
        Intensity values within the slice.
    percentile : float
        Percentile of the intensities represented in the slice that will be returned as the guess.

    Returns
    -------
    guess_row_index : 1D array
        Index of the guess position.
    guess_intensity : 1D array
        Intensity of the guessed pixel.

    Notes
    -----
    Sorts indices and intensities by the intensities, then returns the index and intensity at the requested percentile.
    """

    values = [[x, y] for y, x in sorted(zip(intensities, indices))]
    guess_row_index, guess_intensity = values[int(len(values) * percentile / 100.)]
    return guess_row_index, guess_intensity


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
    poly : 1D polynomial
    """
    try:
        valid_indices = ~np.isnan(row_indices)
        z = np.polyfit(column_indices[valid_indices], row_indices[valid_indices], deg=degree)
        poly = np.poly1d(z)
    except (TypeError, ValueError):
        # Occurs when valid_indices is all False: i.e., no centroids are there to be traced,
        # or when one of the parameters is None.
        poly = None
    return poly


def follow_fiber(image, start_row, start_column, halfwidth,
                 queue_length=20, snr_threshold=20, baffle_clip=150):
    """
    Finds all the centroids of one fiber along an entire order.

    Parameters
    ----------
    image : 2D array
    start_column : int or float
        Index of the column for the first starting position along the fiber.
    start_row : int or float
        Index of the row for the first starting position along the fiber.
    halfwidth : (opt) int
        The halfwidth of the column slice. Fullwidth will be 1 + (halfwidth * 2).
    queue_length : int (opt)
        The queue keeps track of the fluxes within the last queue_length fitted centroids. If the median drops before
        a value based on snr_threshold, a stop condition is met.
    snr_threshold : int (opt)
        Threshold SNR value (i.e., sqrt(sum(slice))) which must be met to continue following an order towards on
        edge of the chip.
    baffle_clip : int (opt)
        If the stop condition is that the SNR is too low, this parameter controls how many previously-fit centroids
        will be rejected on that end.

    Returns
    -------
    centroids : 1D array
        List of centroid positions for the fiber and order of length image.shape[1]. Values are np.nan by default.
        Otherwise, values are the fractional row indices of the centroids for each column.

    Notes
    -----
    Starts with a known centroid, and then walks column-by-column to the left, updating the centroids as it goes.
    Stop conditions is hitting the edge of the chip or when the SNR gets too low (in this case, extra pixels are
    removed to account for defects due to the baffle). Then it does the same thing to the right.
    """

    n_columns = image.shape[1]
    cols = np.arange(n_columns)
    centroids = np.array([np.nan for _ in cols])
    snr_thresh_sq = snr_threshold * snr_threshold
    for sign in np.array([-1, 1]):  # Goes left for -1, right for +1
        column = start_column
        try:
            centroid = int(np.round(start_row))
        except AttributeError:
            centroids = None
            break
        recent_fluxes = collections.deque(queue_length * [np.inf], maxlen=queue_length)
        while (0 <= column < n_columns) and (np.mean(recent_fluxes) > snr_thresh_sq):
            indices, intensities = get_column(image, column, center=centroid, halfwidth=halfwidth)
            centroid = get_centroid(indices, intensities)
            centroids[column] = centroid
            recent_fluxes.append(get_total_flux(intensities))
            column += 1 * sign

        # Erase recent saved centroids to avoid the baffle
        if sign == 1:
            centroids[column - queue_length - baffle_clip:column] = np.nan
        else:  # sign==-1
            centroids[column + 1:column + 1 + queue_length + baffle_clip] = np.nan
    return centroids


def get_total_flux(intensities, smooth=0, remove_background=False):
    """
    Sums up the flux within a section of a column.

    Parameters
    ----------
    intensities : 1D array
    smooth : (opt) int
        Median-smoothing is performed over the column slice, with a kernel size of `smooth`. If 0, no smoothing.
        If not 0, `smooth` must be an odd number. Occurs before background removal, if applicable.
    remove_background : (opt) bool
        If true, removes the background

    Returns
    -------
    flux: 1D array
        Summed intensity values within the column slice.
    """

    if smooth > 0:
        intensities = medfilt(intensities, kernel_size=smooth)

    if remove_background:
        intensities = get_remove_background(intensities)

    flux = sum(intensities)
    return flux


def get_column(image, column,
               center=None, halfwidth=None,
               lower_limit=None, upper_limit=None,
               remove_background=True, smooth=0):
    """
    Retrieve a columnar slice from the image.

    Parameters
    ----------
    image : 2D array
    column : int
        Index of the column that will contain the slice.
    center : (opt) int or float = None
        Index of the central row of the slice. Floats are rounded to the nearest int. Must be provided in conjunction
        with `halfwidth`.
    halfwidth : (opt) int = None
        The halfwidth of the slice. Fullwidth will be 1 + (halfwidth * 2). Must be provided in
        conjunction with `center`.
    lower_limit : (opt) int or float
        The lower row index of the slice (inclusive). Floats are rounded to the nearest int. Must be provided in
        conjunction with `upper_limit`.
    upper_limit : (opt) int or float
        The upper row index of the slice (exclusive). Floats are rounded to the nearest int. Must be provided in
        conjunction with `lower_limit`.
    smooth : (opt) int
        Median-smoothing is performed over the slice, with a kernel size of `smooth`. If 0, no smoothing. If not 0,
        `smooth` must be an odd number. Occurs before background removal, if applicable.
    remove_background : (opt) bool

    Returns
    -------
    indices : 1D array
        Indices for the slice within the original full-frame image.
    intensities : 1D array
        Intensity values within the slice.
    """

    if smooth > 0 and smooth % 2 == 0:
        smooth += 1
        warnings.warn('`smooth` should be an odd number. Increased value to {}.'.format(smooth))

    if center is not None and halfwidth is not None:
        center = int(np.round(center))
        indices = np.arange(center - halfwidth, center + halfwidth + 1)
    elif lower_limit is not None and upper_limit is not None:
        lower_limit = int(np.round(lower_limit))
        upper_limit = int(np.round(upper_limit))
        indices = np.arange(lower_limit, upper_limit)
    else:
        indices = None

    if indices is not None:
        intensities = image[indices[0]:indices[-1] + 1, column]
        if smooth > 0:
            intensities = medfilt(intensities, kernel_size=smooth)

        if remove_background:
            intensities = get_remove_background(intensities)
    else:
        intensities = None

    return indices, intensities


def get_centroid(row_indices, column_intensities):
    """
    Find the centroid of a columnar slice.

    Parameters
    ----------
    row_indices : 1D array
        Indices for the slice within the original full-frame image.
    column_intensities : 1D array
        Intensity values within the slice.

    Returns
    -------
    centroid : float
        Centroid of the slice

    Notes
    -----
    Centroid is determined by Sum[x*g(x)]/Sum[g(x)], where x is the row_indices, and g(x) is the intensities.
    The full formula uses integrals rather than sums, but since all the bin sizes are the same, we can use sums instead.
    Exception handles case for the column running off the bottom/top of the chip.
    """
    try:
        centroid = float(np.sum(column_intensities * row_indices)) / np.sum(column_intensities)
    except (TypeError, ValueError):
        # Occurs when column_intensities and/or row_indices are None.
        centroid = None
    return centroid


def get_remove_background(arr):
    """
    Crudely remove the background from a slice.

    Parameters
    ----------
    arr : numpy array
        The array you want to background-subtract.

    Returns
    -------
    array_no_background : numpy array
        The array after background subtraction.
    """

    try:
        min_value = np.min(arr)
        array_no_background = arr - min_value
    except ValueError:
        array_no_background = None

    return array_no_background


def get_peak_flux(image, polynomial, reference_column, column_halfwidth, n_columns=20):
    """
    Determine the smoothed peak flux of a fiber within a small chunk.
    This is used to set a threshold for the next fiber of this color.

    Parameters
    ---------
    image : 2D array
    polynomial : 1D polynomial
    reference_column : int
    column_halfwidth : int
    n_columns : int (opt)
        How many columns will be used to determine the peak flux. Use value > 1 to ensure 2D median smoothing beats down
        cosmic rays.

    Returns
    -------
    peak : float
        Peak value of the median-smoothed chunk.
    """

    chunk_intensities = np.zeros((n_columns, 2 * column_halfwidth + 1))
    for i in range(n_columns):
        row_indices, intensities = get_column(image, reference_column + i,
                                              center=polynomial[0](reference_column), halfwidth=column_halfwidth,
                                              remove_background=False, smooth=0)
        chunk_intensities[i, :] = intensities
    chunk_intensities = chunk_intensities - np.min(chunk_intensities)
    chunk_intensities = medfilt(chunk_intensities, kernel_size=5)
    peak = np.max(chunk_intensities)
    return peak


def get_initial_order_separation(image, red_peak, blue_polynomials, reference_column, column_halfwidth):
    """
    Determine the initial distance between a red fiber and the blue fiber in the next adjacent order to its blue side.

    Parameters
    ----------
    image : 2D array
    red_peak : float
        Peak flux value within a chunk of the red fiber.
    blue_polynomials : list of 1D polynomials
    reference_column : int
    column_halfwidth : int

    Returns
    -------
    order_separation_initial : int
        Distance between the nearest two fibers in adjacent orders.
    """

    order_separation = 2 + column_halfwidth
    order_search_column_length = 100
    lower_limit = blue_polynomials[0](reference_column) + order_separation
    row_indices, intensities = get_column(image, reference_column,
                                          lower_limit=lower_limit,
                                          upper_limit=lower_limit + order_search_column_length,
                                          remove_background=True, smooth=5)
    order_separation_list = 3
    recent_intensities = collections.deque(order_separation_list * [0], maxlen=order_separation_list)
    order_separation_threshold_ratio = 0.3
    threshold = red_peak * order_separation_threshold_ratio
    i = 0
    while np.mean(recent_intensities) < threshold:
        # assert i < len(intensities), 'Failed to find the red fiber in the next order. ' \
        #                              'You could try reducing order_separation_threshold_ratio, currently ' \
        #                              '%.f, which corresponds to a threshold flux value of %d.' \
        #                              '' % (order_separation_threshold_ratio, threshold)   ### MOVE TO UNIT TEST
        recent_intensities.append(intensities[i])
        i += 1
    guess_row_indices = row_indices[i]
    row_indices, intensities = get_column(image, reference_column, center=guess_row_indices,
                                          halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)
    row_indices, intensities = get_column(image, reference_column, center=centroid, halfwidth=column_halfwidth)
    centroid = get_centroid(row_indices, intensities)

    order_separation_initial = int(np.round(centroid - blue_polynomials[0](reference_column)))
    # assert order_separation_initial > 0, 'order_separation_initial must be positive.'   ### MOVE TO UNIT TEST

    return order_separation_initial


def print_progress(i, last_printed, n_tot, report=10, msg='', verbose=False):
    """
    Prints progress through a loop periodically.

    Parameters
    ----------
    i : int
        The iteration of the loop you just completed.
    last_printed : int
        The iteration of the loop that was last printed out.
    n_tot : int
        Total iterations of the loop.
    report : float (opt) = 10
        The function will print if more than `report` percentage of the loop has completed since the last print.
    msg : str (opt) = ''
        String that will print preceding the percentage.
    verbose : bool
        Flag for printing progress to stdout.

    Returns
    -------
    last_printed : int
        The iteration of the loop that was last printed out, possibly updated by function.

    Notes
    -----
    Compare the last percentage value printed to the current percentage through the loop. Print the new value and
    update the old if enough progress has been made.
    """
    percent_complete = (100. * i / n_tot)
    if percent_complete - last_printed > report or percent_complete == 100:
        if verbose:
            print('{msg}{percent_complete:.1f}%'.format(msg=msg, percent_complete=percent_complete))
            sys.stdout.flush()
        last_printed = percent_complete

    return last_printed


def which_fibers(header):
    """
    Determines which fibers were illuminated based on the fits header's OBJECT field.

    Parameters
    ----------
    header: fits header

    Returns
    -------
    fibers_illuminated: list
        List containing the indices of the fibers illuminated by tungsten ('tung'). E.g., [0,1]
    """
    if header is not None:
        objects = header['OBJECTS'].split('&')
        fibers_illuminated = []
        for i, obj in enumerate(objects):
            if not obj == 'none':
                fibers_illuminated.append(i)
    else:
        fibers_illuminated = ['?', '?']
    return fibers_illuminated


def get_image_name(file_name):
    """
    Strips directory from file path/name.
    """
    slash_index = file_name.rfind('/') + 1
    image_name = file_name[slash_index:]
    return image_name


def get_date(header):
    """
    Get the date from the header and formatted it for the ascii file.

    Parameters
    ----------
    header : fits header

    Returns
    -------
    date_formatted : str
        Date string formatted to the form: 01 Jan 2001. Or else 'unknown' if no header provided.
    """
    if header is not None:
        date_str = header['DAY-OBS']
        date_formatted = datetime.date(int(date_str[0:4]), int(date_str[4:6]), int(date_str[6:8])).strftime('%d %b %Y')
    else:
        date_formatted = 'unknown date'
    return date_formatted


def get_data(file_name):
    """
    Gets data and header objects from a fits file.

    Parameters
    ----------
    file_name : str

    Returns
    -------
    data : 2D array
    header : header object

    Notes
    -----
    Does not work on raw (fits.fz) images, which store the relevant data in hdulist[1], not [0].
    """

    hdulist = fits.open(file_name)
    data = hdulist[0].data
    header = hdulist[0].header
    return data, header


def make_ascii(out_file, in_file, header, red_polynomials, blue_polynomials, every):
    """
    Generates ascii output giving the row index positions of each fiber and order at many columns.
    All values are zero-indexed.

    Parameters
    ----------
    out_file : str
    in_file : str
    header : fits header
    red_polynomials : 1D polynomial
    blue_polynomials : 1D polynomial
    every : int
        Positions are output every `every` columns.

    Returns
    -------
    output_text : file -> hard drive
    """

    image_name = get_image_name(in_file)

    fibers_illuminated = which_fibers(header)
    date = get_date(header)
    start_column = 0  # 0-indexed
    end_column = 4096  # exclusive
    columns = np.arange(start_column, end_column + every, every)

    output_text = 'trace_order.py order positions at every {every} columns from x={start_column} to {end_column} ' \
                  'for iord=0,{n_order}, ifib='.format(every=every, start_column=start_column, end_column=end_column,
                                                       n_order=len(red_polynomials))
    for fib in fibers_illuminated:
        output_text += '{},'.format(fib)
    output_text += ' {date} {file_name}\nnfib {nfib}'.format(date=date, file_name=image_name,
                                                             nfib=len(fibers_illuminated))
    for fib in fibers_illuminated:
        output_text += ' {}'.format(fib)
    output_text += '\niord '

    for c in columns:
        output_text += '{:.0f}'.format(c).rjust(4) + '     '

    for iord, (p_blue, p_red) in enumerate(zip(blue_polynomials, red_polynomials)):
        output_text += '\n{}'.format(iord).ljust(6)
        for c in columns:
            output_text += '{row:.1f}'.format(row=p_blue(c)).rjust(6) + '   '
        output_text += '\n{}'.format(iord).ljust(6)
        for c in columns:
            output_text += '{row:.1f}'.format(row=p_red(c)).rjust(6) + '   '

    out_file_object = open(out_file, 'w')
    out_file_object.write(output_text)
    out_file_object.close()


def plot_guess(image, row_indices, initial_column_intensities, guess_row_indices, guess_column_intensities,
               reference_column, blind_search_column_length, debug_plots=False):
    """
    Plots the position of the initial guess on the 1D column, and in the 2D image. This should land within an order,
    or else nothing may work!
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 1 in debug_plots):
        # The order guess should land clearly on an order. Doesn't need to be well-centered.
        plt.figure()
        plt.plot(row_indices, initial_column_intensities, label='slice')
        plt.plot(guess_row_indices, guess_column_intensities, 'o', label='order guess')
        plt.legend()
        plt.xlabel('Row')
        plt.ylabel('Counts')
        plt.title('Column {col_number}'.format(col_number=reference_column))
        plt.show()

        x_min = reference_column - blind_search_column_length // 2 - 50
        x_max = reference_column + blind_search_column_length // 2 + 50
        y_min = np.min(row_indices) - 50
        y_max = np.max(row_indices) + 50
        v_min = np.min(image[y_min:y_max, x_min:x_max])
        v_max = np.max(image[y_min:y_max, x_min:x_max])

        plt.figure()
        plt.imshow(image, vmin=v_min, vmax=v_max, origin='lower')
        plt.plot([reference_column for _ in row_indices], row_indices, color='white')
        plt.plot(reference_column, guess_row_indices, 'o', color='orange')
        plt.xlim(x_min, x_max)
        plt.ylim(y_min, y_max)
        plt.xlabel('Column')
        plt.ylabel('Row')
        color_bar = plt.colorbar()
        color_bar.set_label('Counts')
        plt.title('Initial slice along 2D spectra')
        plt.show()


def plot_column(row_indices, intensities, guess_row_index, guess_column_intensity, centroid,
                fig=None, ax=None, debug_plots=False):
    """
    Plots the columnar slice centered on the initial and second centroid. This will show how much the centroid moved on
    the refined (second) guess.
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 2 in debug_plots):
        if fig is ax is None:
            fig, ax = plt.subplots(1)
            ax.plot(row_indices, intensities, 'o', color='C0', label='1st pass slice')
            ax.axvline(centroid, color='C2', label='1st pass centroid')
            ax.set_xlabel('Row')
            ax.set_ylabel('Flux')
        else:
            ax.plot(row_indices, intensities, '^', color='C1', label='2nd pass slice')
            ax.axvline(centroid, color='C4', label='2nd pass centroid', linestyle='dashed')
            ax.plot(guess_row_index, guess_column_intensity, '*', color='C5', label='order guess')
            ax.set_xlabel('Row')
            ax.set_ylabel('Flux')
            ax.legend()
            fig.show()
    else:
        fig, ax = None, None

    return fig, ax


def plot_first_polynomial(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                          debug_plots=False):
    """
    Plots the trace of the first polynomial fit on top of the 2D image for the red and blue fiber.
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 3 in debug_plots):
        cols = np.arange(image.shape[1])
        plt.figure()
        plt.imshow(image - np.min(image), vmax=500, origin='lower')
        plt.plot(cols, red_fiber_centroids[0], '-', color='C1', label='red centroids')
        plt.plot(cols, red_polynomials[0](cols), linewidth=1, color='red', linestyle='dashed', label='red poly')
        plt.plot(cols, blue_fiber_centroids[0], '-', color='C2', label='blue centroids')
        plt.plot(cols, blue_polynomials[0](cols), linewidth=1, color='blue', linestyle='dashed', label='blue poly')
        plt.legend()
        plt.xlabel('Column')
        plt.ylabel('Row')
        plt.colorbar()
        plt.title('Fit along first order')
        plt.show()


def plot_first_polynomial_residuals(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                                    debug_plots=False):
    """
    Plots the residuals of centroid - polynomial for the red and blue fibers in the first order found.
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 4 in debug_plots):
        cols = np.arange(image.shape[1])
        plt.figure()
        plt.plot(cols, red_fiber_centroids[0] - red_polynomials[0](cols), color='C1', linewidth=0.5, label='red')
        plt.plot(cols, blue_fiber_centroids[0] - blue_polynomials[0](cols), color='C0', linewidth=0.5, label='blue')
        plt.legend()
        plt.title('Residuals: centroid - polynomial')
        plt.xlabel('Col')
        plt.ylabel('Residuals')
        plt.legend()
        plt.show()


def plot_all_polynomials(image, red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials,
                         debug_plots=False):
    """
    Plots the traces of every fiber and order over the 2D image.
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 5 in debug_plots):
        plt.figure()
        plt.imshow(np.log10(image - np.min(image) + 0.01), origin='lower')
        cols = np.arange(image.shape[1])
        for c_r, c_b, p_r, p_b in zip(red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials):
            plt.plot(cols, c_r, color='white')
            plt.plot(cols, p_r(cols), color='red', linestyle='dashed')
            plt.plot(cols, c_b, color='white')
            plt.plot(cols, p_b(cols), color='blue', linestyle='dashed')


def plot_all_polynomial_residuals(image, red_fiber_centroids, red_polynomials, blue_fiber_centroids, blue_polynomials,
                                  debug_plots=False):
    """
    Plots the residuals of centroid - polynomial for every fiber and order found. Each set of residuals is offset from
    the last order by +1. So the blue orders are on the bottom and red are on the top.
    """
    if (type(debug_plots) is bool and debug_plots) or (type(debug_plots) is list and 6 in debug_plots):
        plt.figure()
        cols = np.arange(image.shape[1])
        i = 0
        for c_r, c_b, p_r, p_b in zip(red_fiber_centroids, blue_fiber_centroids, red_polynomials, blue_polynomials):
            plt.axhline(i, color='k', linewidth=0.7, linestyle='dashed')
            plt.plot(cols, (c_r-p_r(cols))+i, color='C1', linewidth=0.7)
            plt.plot(cols, (c_b-p_b(cols))+i, color='C0', linewidth=0.7)
            plt.xlabel('Column')
            plt.ylabel('Residuals (offset by 1 for each order)')
            plt.title('All residuals: centroids-poly')
            i += 1
