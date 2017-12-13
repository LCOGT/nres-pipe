import numpy as np
from astropy.io import fits
from nrespipe import utils


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
    This roughly follows what scamp does which follows Kaiser+ 1999 https://arxiv.org/abs/astro-ph/9907229
    """
    # Calculate the log distance between every pair of sources
    input_log_distances = get_log_distances(sources)
    reference_log_distances = get_log_distances(reference_catalog)

    # The maximum offset in the catalog is sqrt(2) * 4096
    # Use a single pixel as the minimum offset bin
    # Use bins of 1 / 4096 ~ 0.0002 so that we can account for scales down to a pixel
    bins = np.arange(0.0, np.log(np.sqrt(2.0) * 4096) + 0.0002, 0.0002)
    # Make a histogram of the values

    input_histogram = np.histogram(input_log_distances, bins)
    reference_histogram = np.histogram(reference_log_distances, bins)

    # Cross correlate the two histograms
    correlation = np.correlate(input_histogram, reference_histogram, mode='full')

    bin_centers = np.arange(bins[0] + 0.0001, max(bins), 0.0002)
    return np.exp(bin_centers[np.argmax(correlation)])


def get_log_distances(sources):
    n_sources =len(sources)
    log_distances = np.zeros(utils.choose_k(n_sources, 2))
    # Go through every pair of sources, not double counting
    start_index = 0
    stop_index = n_sources
    for i, source in sources[:-1]:
        log_distances[start_index:stop_index] = np.log(utils.offset(source, sources[i+1:]))
        start_index = stop_index
        stop_index += n_sources - i - 1
    return log_distances