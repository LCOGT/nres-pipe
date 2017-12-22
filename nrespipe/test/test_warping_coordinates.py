from __future__ import absolute_import, division, print_function, unicode_literals
import numpy as np
from nrespipe.utils import evaluate_poly_coords, warp_coordinates

def test_shift_in_x():
    x = np.arange(100)
    y = np.arange(-100, 0)

    for shift in np.arange(-100, 100):
        expected = x + shift

        actual = evaluate_poly_coords(x, y, [shift, 1.0, 0.0], 1)

        np.testing.assert_allclose(actual, expected, atol=1e-5)


def test_shift_in_y():
    x = np.arange(100)
    y = np.arange(-100, 0)

    for shift in np.arange(-100, 100):
        expected = y + shift

        actual = evaluate_poly_coords(x, y, [shift, 0.0, 1.0], 1)

        np.testing.assert_allclose(actual, expected, atol=1e-5)


def test_x_poly():
    x = np.arange(100)
    y = np.arange(-100, 0)

    shift = 3.3
    xscale = 1.05
    yscale = 0.05
    crossterm = 2e-4
    y2coeff = 3e-4
    x2coeff = 1e-4
    expected = shift + x * xscale + y * yscale + y * x * crossterm + y * y * y2coeff + x * x * x2coeff
    actual = evaluate_poly_coords(x, y, [shift, xscale, x2coeff, yscale, crossterm, y2coeff], 2)
    np.testing.assert_allclose(actual, expected, atol=1e-5)

def test_y_poly():
    x = np.arange(100)
    y = np.arange(-100, 0)
    shift = 4.3
    xscale = 0.03
    yscale = 1.10
    crossterm = 5e-4
    y2coeff = 5e-5
    x2coeff = 6e-4
    expected = shift + x * xscale + y * yscale + y * x * crossterm + y * y * y2coeff + x * x * x2coeff
    actual = evaluate_poly_coords(x, y, [shift, xscale, x2coeff, yscale, crossterm, y2coeff], 2)
    np.testing.assert_allclose(actual, expected, atol=1e-5)


def test_warping_coordiantes():
    x = np.arange(100)
    y = np.arange(-100, 0)
    x_shift = 3.3
    x_xscale = 1.05
    x_yscale = 0.05
    x_crossterm = 2e-4
    x_y2coeff = 3e-4
    x_x2coeff = 1e-4
    y_shift = 4.3
    y_xscale = 0.03
    y_yscale = 1.10
    y_crossterm = 5e-4
    y_y2coeff = 5e-5
    y_x2coeff = 6e-4

    expected_x = x_shift + x * x_xscale + y * x_yscale + y * x * x_crossterm + y * y * x_y2coeff + x * x * x_x2coeff
    expected_y = y_shift + x * y_xscale + y * y_yscale + y * x * y_crossterm + y * y * y_y2coeff + x * x * y_x2coeff
    actual_x, actual_y = warp_coordinates(x, y, [x_shift, x_xscale, x_x2coeff, x_yscale, x_crossterm, x_y2coeff,
                                                 y_shift, y_xscale, y_x2coeff, y_yscale, y_crossterm, y_y2coeff], 2)
    np.testing.assert_allclose(actual_x, expected_x, atol=1e-5)
    np.testing.assert_allclose(actual_y, expected_y, atol=1e-5)
