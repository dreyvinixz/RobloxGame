"""Pixel-first extraction tests; synthetic fixtures only, no 3D accuracy claim."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from tools.terrain_inverse.extract_wireframe import analyze, export


def example_png():
    raster=np.full((160,160,3),220,np.uint8)
    cv2.polylines(raster,[np.array([[20,20],[55,20],[36,52]])],
                  True,(90,90,90),1)
    cv2.polylines(raster,[np.array([[90,90],[118,90],
                                   [118,116],[90,116]])],
                  True,(90,90,90),1)
    success,png=cv2.imencode('.png',raster)
    assert success
    return png.tobytes()


class PixelWireframeTests(unittest.TestCase):
    def test_does_not_generate_without_raw_image(self):
        with self.assertRaises(FileNotFoundError):
            export('/file-that-does-not-exist.png','/tmp/unused')

    def test_pixel_lines_and_enclosures(self):
        report,_=analyze(example_png())
        assert report['measurements']['skeleton_pixels']>60
        assert report['measurements']['candidate_line_segments']>2
        assert report['measurements']['candidate_closed_faces']>=1
        self.assertTrue(all(3<=p['sides']<=6 for p in report['faces']))
        self.assertEqual(report['source_sha256'],
                         hashlib.sha256(example_png()).hexdigest())

    def test_invalid_roi(self):
        with self.assertRaises(ValueError):
            analyze(example_png(),roi=(0,0,999,999))

    def test_generated_evidence_is_from_exact_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            image=Path(tmp)/'source.png'
            image.write_bytes(example_png())
            folder=Path(tmp)/'artifacts'
            report=export(image,folder)
            self.assertEqual(report['source_image_size_px'],[160,160])
            stored=json.loads((folder/'wireframe_report.json').read_text())
            self.assertEqual(stored['source_sha256'],report['source_sha256'])
            for name in ('observed_wireframe_overlay.png',
                         'closed_cell_hypotheses_overlay.png',
                         'observed_skeleton.png','observed_line_mask.png'):
                self.assertTrue((folder/name).is_file(),name)


if __name__=='__main__':
    unittest.main()
