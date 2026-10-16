"""V4.2: checks independent pixel evidence and synthetic face topology; NOT 3D."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np
from tools.terrain_inverse import topology_refinement_v42 as v42


class Tests(unittest.TestCase):
    def test_observed_line_support(self):
        image=np.zeros((80,80),np.uint8)
        cv2.line(image,(10,10),(60,10),255,1)
        self.assertGreater(v42.edge_fraction(image>0,[10,10],[60,10]),.98)
        self.assertLess(v42.edge_fraction(image>0,[10,30],[60,30]),.05)

    def test_cannot_upgrade_unsupported_clean_only_edge(self):
        masks={'original':np.zeros((80,80),bool),
               'fused':np.ones((80,80),bool),
               'water':np.zeros((80,80),bool)}
        lines,rejected=v42.filter_lines(
            [{'p0':[10,10],'p1':[60,10],'type':'gap_bridge'}],masks)
        self.assertEqual(lines,[])
        self.assertEqual(rejected.get('unsupported_bridge'),1)

    def test_annotation_evaluation(self):
        with tempfile.TemporaryDirectory() as d:
            label=np.zeros((80,80),np.uint8)
            cv2.line(label,(10,25),(60,25),255,1)
            path=Path(d)/'annotated.png'
            cv2.imwrite(str(path),label)
            metric=v42.annotated_precision_recall(
                [{'p0':[10,25],'p1':[60,25]}],path,(80,80))
            self.assertEqual(metric['f1'],1.)
            self.assertEqual(metric['status'],'independent_manually_labeled_2D_pixels')

    def test_no_fake_sources(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)
            a=np.zeros((80,80,3),np.uint8)
            cv2.imwrite(str(p/'a.png'),a)
            cv2.imwrite(str(p/'b.png'),a)
            (p/'previous').mkdir()
            (p/'previous/v41_report.json').write_text(json.dumps({
                'source_original_sha256':'wrong',
                'source_clean_sha256':'wrong'}))
            with self.assertRaisesRegex(ValueError,'SHA-256 mismatch'):
                v42.load_pair(p/'a.png',p/'b.png',p/'previous')

    def test_raster_metrics(self):
        area=np.zeros((80,80),bool)
        cv2.line(area.view(np.uint8),(10,10),(60,10),1,1)
        _,metrics=v42.score_pixel_coverage(
            [{'p0':[10,10],'p1':[60,10]}],area,area.shape)
        self.assertAlmostEqual(metrics['observed_pixel_coverage_2px'],1.)
        self.assertFalse(metrics['independent_ground_truth'])


if __name__=='__main__':
    unittest.main()
