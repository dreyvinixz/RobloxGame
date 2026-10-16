"""V5 reproducibility and numerical-contract tests on SYNTHETIC reference inputs.

These tests do NOT establish 3D accuracy on the actual AI-generated island.
"""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from tools.terrain_inverse.reconstruct_v5 import (
    estimate_peak_heights, estimate_plane_camera, land_mask_from_pixels,
    read, run,
)


def make_fixture(folder):
    p=Path(folder)
    atlas=np.full((1024,1536,3),(140,81,5),np.uint8)
    cv2.ellipse(atlas,(316,276),(245,180),0,0,360,(120,160,130),-1)
    clean=np.full((971,1619,3),125,np.uint8)
    for x in range(0,1619,30):
        cv2.line(clean,(x,0),(x,970),(70,70,70),1)
    original=clean.copy()
    src=np.array([[175,170],[325,135],[510,120],[700,165],
                  [775,385],[580,570],[300,550],[140,330]],float)
    matrix=np.array([[1.45,.07,75],[-.09,.72,215]],float)
    def projection(v):
        return np.rint(matrix[:,:2]@v+matrix[:,2]).astype(int).tolist()
    coast=[{"id":str(i),"top":v.tolist(),"oblique":projection(v)}
           for i,v in enumerate(src)]
    targets=[[190,240],[300,270],[650,200],[720,310],[620,485],[300,480]]
    peaks=[]
    for i,v in enumerate(targets):
        p2=np.asarray(projection(np.asarray(v,float)))-[0,60+i*5]
        peaks.append({"id":str(i),"top":v,"oblique":p2.tolist()})
    for name,im in [("atlas",atlas),("clean",clean),("wireframe",original)]:
        cv2.imwrite(str(p/(name+".png")),im)
    labels={"atlas_top_crop_xyxy":[14,34,618,518],
            "coast":coast,"peaks":peaks}
    (p/"landmarks.json").write_text(json.dumps(labels),encoding="utf-8")
    return p,labels


class V5Tests(unittest.TestCase):
    def test_missing_image_does_not_fall_back_to_procedural(self):
        with self.assertRaises(FileNotFoundError):
            read("/no-such-V5-source-image.png")

    def test_sea_plane_affine_determined_on_synthetic_pairs(self):
        with tempfile.TemporaryDirectory() as tmp:
            _,reference=make_fixture(tmp)
            affine,report=estimate_plane_camera(reference)
            self.assertGreaterEqual(report["inlier_count"],7)
            self.assertLess(report["median_inlier_error_px"],1.)
            accepted,rejected=estimate_peak_heights(reference,affine)
            self.assertEqual(len(accepted),6)
            self.assertEqual(len(rejected),0)

    def test_color_segmentation_retains_synthetic_land(self):
        raster=np.full((96,96,3),(140,81,5),np.uint8)
        cv2.circle(raster,(48,48),27,(120,160,130),-1)
        land,water=land_mask_from_pixels(raster)
        self.assertTrue(land[48,48])
        self.assertTrue(water[0,0])
        self.assertFalse(land[0,0])

    def test_source_hash_and_binary_outputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            p,_=make_fixture(tmp)
            report=run(p/"atlas.png",p/"clean.png",p/"wireframe.png",
                       p/"landmarks.json",p/"out",grid=65,viewer=False)
            self.assertEqual(report["status"],
                             "EXPERIMENTAL_2_5D_HYPOTHESIS_NOT_VALIDATED")
            self.assertEqual(report["grid"],65)
            self.assertEqual(report["vertices"],4225)
            self.assertEqual(report["triangles"],8192)
            self.assertEqual(report["inputs_sha256"]["top_atlas"],
                             hashlib.sha256((p/"atlas.png").read_bytes()).hexdigest())
            height=np.load(p/"out/height_relative.npy")
            self.assertTrue(np.isfinite(height).all())
            self.assertTrue((height.max()>40) and (height.min()<0))
            for filename in ["heightmap_16bit.png","terrain_hypothesis.obj",
                             "camera_registration_overlay.png","topview_annotated.png",
                             "wireframe_reprojection_candidate.png",
                             "v5_report.json","top_land_source_segmentation.png"]:
                self.assertTrue((p/"out"/filename).is_file(),filename)
            self.assertEqual(report["camera"]["intrinsics_extrinsics"],"UNKNOWN")

    def test_requires_all_three_source_dimensions(self):
        with tempfile.TemporaryDirectory() as tmp:
            p,_=make_fixture(tmp)
            cv2.imwrite(str(p/"clean.png"),np.zeros((60,60,3),np.uint8))
            with self.assertRaisesRegex(ValueError,"Reference shape mismatch"):
                run(p/"atlas.png",p/"clean.png",p/"wireframe.png",
                    p/"landmarks.json",p/"out",grid=65,viewer=False)


if __name__=="__main__":
    unittest.main()
