"""V5 adaptive mesh invariants on a deterministic synthetic relief."""
import unittest

import numpy as np

from tools.terrain_2_v3.terrain_v5 import (
    detect_source_scale_bar, extract_side_render_skyline, feature_adaptive_mesh,
    opposing_profile_conflicts,
)


class TerrainV5MeshTests(unittest.TestCase):
    def test_adaptive_mesh_is_finite_and_densifies_a_feature_edge(self):
        n = 65
        y, x = np.mgrid[0:n, 0:n]
        field = (22 * np.exp(-((x - 32) ** 2 + (y - 32) ** 2) / 115.)).astype(np.float32)
        land = np.ones((n, n), dtype=bool)
        water = np.zeros((n, n), dtype=bool)
        water[30:35, 8:57] = True
        points, heights, faces, report = feature_adaptive_mesh(field, land, water)

        self.assertGreater(len(points), 0)
        self.assertGreater(len(faces), 0)
        self.assertTrue(np.isfinite(heights).all())
        self.assertLess(report["vertices"], report["uniform_grid_vertices"])
        self.assertEqual(faces.shape[1], 3)
        self.assertGreater(report["feature_edge_vertices"], 0)

    def test_opposing_profile_conflict_reports_nonzero_fit_floor(self):
        profiles = {"profiles": {
            "front": {"apparent_height_px": [0., 4., 8.]},
            "back": {"apparent_height_px": [0., 2., 10.]},
            "left": {"apparent_height_px": [1., 3., 5.]},
            "right": {"apparent_height_px": [5., 3., 1.]},
        }}
        result = opposing_profile_conflicts(profiles)
        self.assertGreater(result["front_back"]["best_possible_equal_profile_rmse_floor"], 0.)
        self.assertAlmostEqual(result["left_right"]["best_possible_equal_profile_rmse_floor"], 0.)

    def test_scale_bar_is_reported_without_claiming_physical_calibration(self):
        import cv2

        image = np.zeros((200, 400, 3), dtype=np.uint8)
        cv2.line(image, (280, 25), (379, 25), (255, 255, 255), 1)
        result = detect_source_scale_bar(image)
        self.assertEqual(result["bar_pixels"], 100)
        self.assertFalse(result["unit_label_visually_confirmed"])
        self.assertFalse(result["physical_or_Roblox_scale_confirmed"])

    def test_side_render_skyline_uses_sky_color_reference(self):
        import cv2

        image = np.full((120, 240, 3), (126, 114, 100), dtype=np.uint8)
        polygon = np.asarray([[0, 72], [60, 39], [120, 44],
                              [180, 53], [239, 75], [239, 108], [0, 108]])
        cv2.fillPoly(image, [polygon], (150, 135, 120))
        skyline, report = extract_side_render_skyline(image, bins=80)

        self.assertEqual(skyline.shape, (80,))
        self.assertTrue(np.isfinite(skyline).all())
        self.assertGreater(report["valid_columns_fraction"], .95)
        self.assertGreaterEqual(float(skyline.min()), 35.)
        self.assertLessEqual(float(skyline.max()), 80.)


if __name__ == "__main__":
    unittest.main()
