"""Checks determinism and export; not visual identity with AI source images."""
import tempfile
import unittest
from pathlib import Path
import numpy as np
from tools.terrain_inverse.island import generate,save,rasterize_coast

class TerrainInverseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.a=generate(65,seed=42)

    def test_reference_coast_and_land_water(self):
        a=self.a
        np.testing.assert_array_equal(a['land'],rasterize_coast(65))
        self.assertTrue(a['land'][32,32]);self.assertFalse(a['land'][0,0])
        self.assertGreater(float(a['land'].mean()),.35)

    def test_heights_and_landmark_materials(self):
        a=self.a;z=a['height'];mat=a['material']
        self.assertTrue(np.isfinite(z).all())
        self.assertGreater(float(z.max()),100)
        self.assertLess(float(z.min()),0)
        self.assertGreater(int((mat==1).sum()),3)
        self.assertGreater(int((mat==3).sum()),3)
        self.assertGreater(int((mat==5).sum()),3)
        self.assertGreater(int((mat==6).sum()),3)

    def test_fixed_seed_reproducibility(self):
        np.testing.assert_array_equal(self.a['height'],generate(65,seed=42)['height'])
        self.assertFalse(np.array_equal(self.a['height'],generate(65,seed=43)['height']))

    def test_shape_is_normalized_and_exportable(self):
        with tempfile.TemporaryDirectory() as folder:
            metrics=save(self.a,folder,interactive=False)
            for name in ['height_m.npy','terrain.obj','heightmap_16bit.png','land_mask.png','material_colormap.png','topographic_preview.png','diagnostics.png','report.json']:
                self.assertTrue((Path(folder)/name).is_file(),name)
            self.assertEqual(metrics['grid'],65)
            self.assertEqual(len(np.load(Path(folder)/'height_m.npy')),65)

    def test_invalid_grid(self):
        with self.assertRaises(ValueError):generate(16)

if __name__=='__main__':unittest.main()
