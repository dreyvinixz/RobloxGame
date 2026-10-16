"""V4 unit tests: image-plane evidence only. No reconstruction-accuracy claim."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from tools.terrain_inverse.topology_v4 import (
    estimate_plane_registration, graph_from_candidates, merge_points, run,
    segment_graph_from_observations,
)


def example_png():
    image = np.full((160, 160, 3), 220, np.uint8)
    cv2.rectangle(image, (30, 30), (55, 55), (75, 75, 75), 1)
    cv2.rectangle(image, (55, 30), (80, 55), (75, 75, 75), 1)
    return cv2.imencode('.png', image)[1].tobytes()


class TestTopologyV4(unittest.TestCase):
    def test_merging_only_close_corners(self):
        points, ids = merge_points([[10, 10], [10.5, 10.5], [20, 20]], 2)
        self.assertEqual(len(points), 2)
        self.assertEqual(ids[0], ids[1])
        self.assertNotEqual(ids[0], ids[2])

    def test_two_adjacent_quads_share_one_edge(self):
        mask = np.zeros((100, 100), np.uint8)
        a = [[10, 10], [35, 10], [35, 35], [10, 35]]
        b = [[35.5, 10.2], [60, 10], [60, 35], [35, 35.4]]
        for poly in [a, b]:
            cv2.polylines(mask, [np.asarray(poly, np.int32)], True, 255, 2)
        obs = [{'vertices_px': a}, {'vertices_px': b}]
        vertices, edges, faces, report = graph_from_candidates(
            obs, mask, (100, 100), [0, 0, 100, 100])
        self.assertEqual(len(faces), 2)
        self.assertEqual(report['quadrilaterals'], 2)
        self.assertEqual(report['components'], 1)
        self.assertEqual(report['boundary_edges'], 6)
        self.assertEqual(report['non_manifold_edges'], 0)

    def test_no_unverified_camera(self):
        self.assertEqual(estimate_plane_registration(None)['status'], 'not_estimated')
        with self.assertRaises(ValueError):
            estimate_plane_registration({'points': []})

    def test_four_verified_planar_controls(self):
        controls = [
            {'world_xy': [0, 0], 'image_xy_px': [30, 40], 'on_same_plane': True},
            {'world_xy': [1, 0], 'image_xy_px': [110, 44], 'on_same_plane': True},
            {'world_xy': [1, 1], 'image_xy_px': [125, 120], 'on_same_plane': True},
            {'world_xy': [0, 1], 'image_xy_px': [20, 115], 'on_same_plane': True},
        ]
        solution = estimate_plane_registration({'points': controls})
        self.assertEqual(solution['status'], 'plane_homography_only')
        self.assertLess(solution['reprojection_rmse_px'], .01)

    def test_cached_data_must_match_original_image_hash(self):
        with tempfile.TemporaryDirectory() as folder:
            src = Path(folder) / 'source.png'
            src.write_bytes(example_png())
            cached = Path(folder) / 'v3.json'
            cached.write_text(json.dumps({'source_sha256': 'wrong',
                                          'roi_xyxy': [0, 0, 160, 160]}))
            with self.assertRaisesRegex(ValueError, 'hash'):
                run(src, Path(folder) / 'out', v3_report=cached)

    def test_direct_raw_image_pipeline(self):
        with tempfile.TemporaryDirectory() as folder:
            src = Path(folder) / 'source.png'
            src.write_bytes(example_png())
            dst = Path(folder) / 'out'
            report = run(src, dst)
            self.assertEqual(report['source_sha256'],
                             hashlib.sha256(src.read_bytes()).hexdigest())
            self.assertEqual(report['3d_status'], 'NOT_RECONSTRUCTED')
            for path in ['vertices.json', 'edges.json', 'faces.json',
                         'camera.json', 'topology_report.json',
                         'screen_space_face_candidates.obj',
                         'observed_segment_graph_overlay.png',
                         'segment_graph.json', 'topology_overlay.png',
                         'image_vs_topology_comparison.png']:
                self.assertTrue((dst / path).is_file(), path)

    def test_segment_network_without_junctions(self):
        v, e, report = segment_graph_from_observations(
            [], [], np.zeros((40, 40), np.uint8), [0, 0, 40, 40])
        self.assertEqual(len(v), 0)
        self.assertEqual(len(e), 0)
        self.assertEqual(report['segments_matched'], 0)


if __name__ == '__main__':
    unittest.main()
