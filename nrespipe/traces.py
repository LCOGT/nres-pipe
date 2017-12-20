import numpy as np
from astropy.io import fits
from nrespipe import utils
from nrespipe.utils import warp_coordinates, square_offset, n_poly_coefficients
from scipy import optimize


def overlay_traces(trace_file, fibers, output_region_filename, pixel_sampling=20):
    # TODO: Good metrics could be total flux in extraction region for the flat after subtracting the bias.
    # TODO: Average S/N per x-pixel (summing over the profile doing an optimal extraction)

    # read in the trace file
    trace = fits.open(trace_file)

    n_polynomial_coefficients = int(trace[0].header['NPOLY'])

    # Choose pixel spacing of 20 for now
    x = np.arange(0, int(trace[0].header['NX']), pixel_sampling)

    # Apparently the Lengendre polynomials need to be evaluated -1 to 1
    normalized_x = (0.5 + x) / int(trace[0].header['NX']) - 0.5
    normalized_x *= 2.0

    # Make ds9 region file with the traces
    # Don't forget the ds9 is one indexed for pixel positions
    ds9_lines = ""
    for fiber in fibers:
        for order in range(int(trace[0].header['NORD'])):
            coefficients = trace[0].data[0, fiber, order, :n_polynomial_coefficients]
            polynomial = np.polynomial.legendre.Legendre(coefficients)
            trace_center_positions = polynomial(normalized_x)
            # Make ds9 lines between each pair of points
            for i in range(1, len(x)):
                ds9_lines += 'line({x1} {y1} {x2} {y2})\n'.format(x1=x[i - 1] + 1, y1=trace_center_positions[i - 1] + 1,
                                                                  x2=x[i], y2=trace_center_positions[i] + 1)

    with open(output_region_filename, 'w') as output_region_file:
        output_region_file.write(ds9_lines)


def get_pixel_scale_ratio(sources, reference_catalog):
    """

    :param sources:
    :param reference_catalog:
    :return:

    Notes
    -----
    This roughly follows what scamp does which follows Kaiser+ 1999 https://arxiv.org/abs/astro-ph/9907229.
    This calculates the scale to convert the reference to input.
    """
    # Calculate the log distance between every pair of sources
    input_log_distances = get_log_distances(sources)
    reference_log_distances = get_log_distances(reference_catalog)

    # The maximum offset in the catalog is sqrt(2) * 4096
    # Use a single pixel as the minimum offset bin
    # Use bins of 1 / 4096 ~ 0.0002 so that we can account for scales down to a pixel
    bins = np.arange(0.0, np.log(np.sqrt(2.0) * 4096) + 0.0002, 0.0002)
    # Make a histogram of the values

    input_histogram = np.histogram(input_log_distances, bins)[0]
    reference_histogram = np.histogram(reference_log_distances, bins)[0]

    # Cross correlate the two histograms
    correlation = np.correlate(input_histogram, reference_histogram, mode='full')

    scale_offsets = np.arange(-max(bins) + 0.0002, max(bins) , 0.0002)
    return np.exp(scale_offsets[np.argmax(correlation)])


def get_log_distances(sources):
    n_sources =len(sources)
    log_distances = np.zeros(utils.choose_2(n_sources))
    # Go through every pair of sources, not double counting
    start_index = 0
    stop_index = n_sources - 1
    for i, source in enumerate(sources[:-1]):
        log_distances[start_index:stop_index] = np.log(utils.offset(source, sources[i+1:]))
        start_index = stop_index
        stop_index += n_sources - i - 2
    return log_distances


def fit_warping_polynomial(input_sources, reference_sources, scale_guess, polynomial_order=3, matching_threshold=25):
    # Warp the coordinates using a polynomial to figure out what the shifts are

    def model_function(params):
        model_x, model_y = warp_coordinates(reference_sources['x'], reference_sources['y'], params, polynomial_order)
        square_distances = square_offset(input_sources['x'], input_sources['y'], model_x, model_y, [0,1])
        matches = square_distances[0] ** 0.5 <= matching_threshold
        if matches.sum() == 0:
            metric = 1e10
        else:
           # Take the ratio of sum of squared distances between the best and second best match
           metric = square_distances[0][matches].sum() / square_distances[1][matches].sum()
        return metric

    # Run a grid of -25 to 25 pixels and find the best initial guess
    X, Y = np.meshgrid(np.arange(-25, 26), np.arange(-25, 26))
    X = X.ravel()
    Y = Y.ravel()
    fit_metrics = np.zeros(51 * 51)
    n_coefficients = n_poly_coefficients(polynomial_order)
    for i, (x, y) in enumerate(zip(X, Y)):
        # Start with just the linear component
        params = np.zeros(2 * n_coefficients)
        params[0] = x
        params[n_coefficients] = y
        params[1] = scale_guess
        params[n_coefficients + polynomial_order + 1] = scale_guess
        fit_metrics[i] = model_function(params)

    initial_x, initial_y = X[np.argmin(fit_metrics)], Y[np.argmin(fit_metrics)]

    params = np.zeros(2 * n_poly_coefficients(polynomial_order))
    params[0] = initial_x
    params[n_coefficients] = initial_y
    params[1] = scale_guess
    params[n_coefficients + polynomial_order + 1] = scale_guess

    # Run Nelder-Mead to find the initial shifts between the input catalog and the new files
    return optimize.minimize(model_function, params, method='Nelder-Mead')['x']
