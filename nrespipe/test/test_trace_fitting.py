from __future__ import absolute_import, division, print_function, unicode_literals
import numpy as np
from nrespipe.traces import get_log_distances, get_pixel_scale_ratio
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



def test_warping_polynomial_fitting():
    x = np.random.uniform(-100.0, 100.0, size=30)
    y = np.random.uniform(-100.0, 100.0, size=30)
    reference_catalog = Table({'x':x, 'y': y})
    for i in range(10):

