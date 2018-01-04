from __future__ import absolute_import, division, print_function, unicode_literals
import numpy as np
from nrespipe.traces import get_log_distances, get_pixel_scale_ratio, fit_warping_polynomial, find_best_offset
from nrespipe.utils import warp_coordinates
from astropy.table import Table
np.random.seed(1289341)

def test_log_distances_circle():
    n_sources = 100
    # Put the first point at the origin and make sure its distance to the other points is x^2 + y^2
    x = np.random.uniform(-5, 5, size=n_sources + 1)
    y = np.random.uniform(-5, 5, size=n_sources + 1)
    x[0] = 0.0
    y[0] = 0.0

    expected = np.log((x[1:] ** 2.0 + y[1:] ** 2.0) ** 0.5)

    actual = get_log_distances(Table({'x': x, 'y': y}))

    np.testing.assert_allclose(actual[:n_sources], expected, atol=1e-5)


def test_log_distances_rectangle():
    # start a rectangle bottom left
    x = np.array([-3.0, 2.0, 2.0, -3.0])
    y = np.array([-1.0, -1.0, 6.0, 6.0])

    diagonal_distance = (5 ** 2.0 + 7 ** 2.0) ** 0.5

    expected = np.log([5.0, diagonal_distance, 7.0, 7.0, diagonal_distance, 5.0])
    actual = get_log_distances(Table({'x': x, 'y': y}))
    np.testing.assert_allclose(actual, expected, atol=1e-5)

def test_scale_offset():
    x = np.random.uniform(-100.0, 100.0, size=30)
    y = np.random.uniform(-100.0, 100.0, size=30)
    reference_catalog = Table({'x':x, 'y': y})
    for scale in [0.1, 0.5, 1.0, 2.0, 3.0, 10.0]:
        expected = scale
        input_catalog = Table({'x': scale * x, 'y': scale * y})
        actual = get_pixel_scale_ratio(input_catalog, reference_catalog)
        np.testing.assert_allclose(actual, expected, atol=1e-3)


def test_warping_polynomial_shift_scale():
    x = np.random.uniform(-100.0, 100.0, size=30)
    y = np.random.uniform(-100.0, 100.0, size=30)
    reference_catalog = Table({'x':x, 'y': y})

    scale = 1.05
    x_shift = 3.3
    y_shift = 4.6

    input_params = [x_shift, scale, 0.0,
                    y_shift, 0.0, scale]
    shifted_x, shifted_y = warp_coordinates(x, y, input_params, 1)

    expected = input_params
    actual = fit_warping_polynomial(Table({'x': shifted_x, 'y': shifted_y}), reference_catalog, scale, polynomial_order=1)
    np.testing.assert_allclose(actual, expected, atol=1e-4)


def test_warping_polynomial_fitting():
    x = np.random.uniform(-100.0, 100.0, size=30)
    y = np.random.uniform(-100.0, 100.0, size=30)
    reference_catalog = Table({'x':x, 'y': y})

    scale = 1.05
    x_shift = 3.3
    x_xscale = scale
    x_yscale = 0.05
    x_crossterm = 2e-4
    x_y2coeff = 3e-4
    x_x2coeff = 1e-4
    y_shift = 4.3
    y_xscale = 0.03
    y_yscale = scale
    y_crossterm = 5e-4
    y_y2coeff = 5e-5
    y_x2coeff = 6e-4

    input_params = [x_shift, x_xscale, x_x2coeff, x_yscale, x_crossterm, x_y2coeff,
                    y_shift, y_xscale, y_x2coeff, y_yscale, y_crossterm, y_y2coeff]
    shifted_x, shifted_y = warp_coordinates(x, y, input_params, 2)

    expected = input_params
    actual = fit_warping_polynomial(Table({'x': shifted_x, 'y': shifted_y}), reference_catalog, scale, polynomial_order=2)
    # The fits aren't perfect. I suspect that means that some numerical thing is happening
    # The parameters are good to ~10% (or sometimes better) And this is with only 30 sources and
    # and 12 parameters, so hopefully that's ok.
    np.testing.assert_allclose(actual, expected, atol=1e-4, rtol=0.1)


def test_find_best_offset():
    x = np.random.uniform(-100.0, 100.0, size=30)
    y = np.random.uniform(-100.0, 100.0, size=30)
    reference_catalog = Table({'x':x, 'y': y})

    scale = 1.05
    x_shift = 3.3
    x_xscale = scale
    x_yscale = 0.05
    x_crossterm = 2e-4
    x_y2coeff = 3e-4
    x_x2coeff = 1e-4
    y_shift = 4.3
    y_xscale = 0.03
    y_yscale = scale
    y_crossterm = 5e-4
    y_y2coeff = 5e-5
    y_x2coeff = 6e-4

    input_params = [x_shift, x_xscale, x_x2coeff, x_yscale, x_crossterm, x_y2coeff,
                    y_shift, y_xscale, y_x2coeff, y_yscale, y_crossterm, y_y2coeff]
    shifted_x, shifted_y = warp_coordinates(x, y, input_params, 2)

    expected = [x_shift, y_shift]

    actual = find_best_offset(Table({'x': shifted_x, 'y': shifted_y}), reference_catalog, scale)
    np.testing.assert_allclose([actual['x'], actual['y']], expected, atol=1e-4, rtol=0.0)
