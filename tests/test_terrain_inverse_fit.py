"""Accuracy claims are limited to pixel-derived 2D skyline fits, not 3D truth."""
import unittest

import numpy as np
from PIL import Image

from tools.terrain_inverse.extract_reference import digitize
from tools.terrain_inverse.inverse_fit import (
    fit, load_reference, opposite_conflicts, projected_profiles
)


class InverseFitTests(unittest.TestCase):
    def test_reference_schema_and_conflicts(self):
        ref=load_reference()
        self.assertEqual({k:len(v) for k,v in ref.items()},dict.fromkeys(ref,33))
        gaps=opposite_conflicts(ref)
        self.assertGreater(gaps['north_vs_south_rmse'],0.05)
        self.assertGreater(gaps['east_vs_west_reversed_rmse'],0.05)

    def test_projection_is_geometrically_consistent(self):
        z=np.zeros((33,33))
        land=np.ones_like(z,dtype=bool)
        z[5,6]=115.
        projected=projected_profiles(z,land,33)
        self.assertAlmostEqual(float(projected[6]),.5)
        self.assertAlmostEqual(float(projected[33+5]),.5)
        self.assertEqual(float(projected[0]),0.)

    def test_fit_reduces_training_and_held_out_pixel_errors(self):
        terrain,report,*_=fit(grid=65,max_nfev=45)
        self.assertLess(report['optimized']['train_rmse'],report['baseline']['train_rmse'])
        self.assertLess(report['optimized']['holdout_rmse'],report['baseline']['holdout_rmse'])
        self.assertLess(float(terrain['height'].max()),260)
        self.assertEqual(terrain['height'].shape,(65,65))

    def test_expected_atlas_dimensions(self):
        with self.assertRaises(ValueError):
            digitize(Image.new('RGB',(100,100)))

    def test_fit_grid_guard(self):
        with self.assertRaises(ValueError):
            fit(grid=17)


if __name__=='__main__':
    unittest.main()
