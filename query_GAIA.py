import sys
import argparse
# Suppress warnings. Comment this out if you wish to see the warning messages
import warnings
warnings.filterwarnings('ignore')


parser = argparse.ArgumentParser()
parser.add_argument('RA', help="RA in degrees")
parser.add_argument('DEC', help="DEC in degrees")
parser.add_argument('radius', help="Search radius in arcmin., default=10archmin",default=10)
args = parser.parse_args()

from astropy.coordinates import SkyCoord
from astroquery.gaia import Gaia
import astropy.units as u


coord = SkyCoord(ra=args.RA, dec=args.DEC, unit=(u.degree, u.degree), frame='icrs')
radius = u.Quantity(args.radius, u.arcmin)

#coord = SkyCoord(ra=280, dec=-60., unit=(u.degree, u.degree), frame='icrs')
#radius = u.Quantity(9, u.arcmin)


gaia_query = Gaia.cone_search(coord, radius)
result = gaia_query.get_results()

result.sort('phot_g_mean_mag')

print(	result[0]['dist'], 
		result[0]['ra'],
		result[0]['dec'],
		result[0]['pmra'],
		result[0]['pmdec'],
		result[0]['phot_g_mean_mag'],
		result[0]['phot_bp_mean_mag'],
		result[0]['phot_rp_mean_mag'],
		result[0]['teff_val'],
		result[0]['lum_val'],
		result[0]['radius_val'],
		result[0]['radial_velocity'],
		result[0]['radial_velocity_error'],
                result[0]['parallax']
		)



