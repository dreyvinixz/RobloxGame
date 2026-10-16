"""V1 tests use synthetic fixtures; they cannot establish AI-reference fidelity."""
import tempfile
import unittest
import json
from pathlib import Path
import cv2
import numpy as np
from tools.terrain_2_v1 import extract_v1


def make_plan(w=1264,h=842):
    image=np.full((h,w,3),(118,76,34),np.uint8)
    cv2.ellipse(image,(600,415),(490,355),0,0,360,(88,95,104),-1)
    cv2.polylines(image,[np.array([(530,96),(558,185),(610,272),(635,390),(718,495),(677,610)],np.int32)],False,(162,192,221),19)
    return image


class SourceV1Tests(unittest.TestCase):
    def test_land_from_original_colors(self):
        m=extract_v1.segment_plan_mask(make_plan())
        self.assertFalse(bool(m['mainland'][20,20]))
        self.assertTrue(bool(m['mainland'][415,600]))
        self.assertTrue(m['sand'].sum()>100)
        self.assertTrue(m['sea'].sum()>100)

    def test_channel_candidate_requires_original_beige_pixels(self):
        src=make_plan()
        masks=extract_v1.segment_plan_mask(src)
        candidate,guide,zone=extract_v1.trace_inland_channel(src,masks)
        self.assertTrue(np.all(candidate<=masks['sand']))
        self.assertTrue(np.all(candidate<=zone))
        self.assertEqual(guide.shape[1],2)

    def test_profile_detects_synthetic_mountain(self):
        im=np.full((1151,2048,3),35,dtype=np.uint8)
        cv2.fillPoly(im,[np.asarray([[320,465],[590,270],[850,465]],np.int32)],(190,190,190))
        _,_,z=extract_v1.side_silhouette(im)
        self.assertGreater(z.max(),170)
        self.assertLess(z[0],3)

    def test_reversed_orientation_consistency(self):
        a=np.array([0,20,50,120,140])
        self.assertEqual(extract_v1.scaled_profile_diff(a,a[::-1]),0)
        self.assertGreater(extract_v1.scaled_profile_diff(a,a),50)

    def test_missing_input_fails_not_procedural(self):
        with self.assertRaises(FileNotFoundError):
            extract_v1.load('/definitely-missing-reference.png')

    def test_pipeline_binary_outputs_and_sha(self):
        with tempfile.TemporaryDirectory() as work:
            root=Path(work);sources=root/'references';sources.mkdir()
            cv2.imwrite(str(sources/'top_flat_semantic.jpg'),make_plan())
            for key,name in extract_v1.SOURCES.items():
                path=sources/name
                if path.exists():continue
                if key.startswith('top'):cv2.imwrite(str(path),make_plan())
                else:
                    im=np.full((1151,2048,3),35,np.uint8)
                    cv2.fillPoly(im,[np.asarray([[300,465],[580,285],[780,465]])],(190,190,190))
                    cv2.imwrite(str(path),im)
            report=extract_v1.export(sources,root/'out')
            self.assertEqual(report['status'],'V1_SOURCE_PIXEL_2D_FEATURES_ONLY')
            self.assertGreater(report['shoreline_vertices_screen'],100)
            self.assertTrue((root/'out'/'reference_segmentation_overlay.png').is_file())
            self.assertTrue((root/'out'/'orthographic_profiles.json').is_file())
            self.assertTrue((root/'out'/'v1_report.json').is_file())
            self.assertEqual(json.loads((root/'out'/'v1_report.json').read_text())['source_sha256'],report['source_sha256'])


if __name__=='__main__':unittest.main()
