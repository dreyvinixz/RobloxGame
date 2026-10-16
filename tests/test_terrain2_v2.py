"""Source-image provenance and geometry invariants; synthetic fixtures are NOT 3D truth."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np
from tools.terrain_2_v1.extract_v1 import SOURCES
from tools.terrain_2_v2.reconstruct_v2 import (
    CHANNEL_GUIDE, channel_from_beige, compare_profiles, process,
    rock_evidence, transform_ground_to_flat,
)


def flat_fixture():
    h,w=842,1264
    image=np.full((h,w,3),(115,75,32),np.uint8)
    cv2.ellipse(image,(610,415),(490,349),0,0,360,(90,96,104),-1)
    pts=np.array(CHANNEL_GUIDE,np.int32)
    cv2.polylines(image,[pts],False,(164,191,217),26)
    return image


def renderer_fixture():
    img=np.full((1024,1536,3),(128,122,115),np.uint8)
    cv2.ellipse(img,(740,492),(635,410),0,0,360,(174,178,178),-1)
    rng=np.random.default_rng(8)
    img[160:340,190:440]=np.clip(95+rng.normal(0,36,(180,250,1)),0,255).astype(np.uint8)
    return img


class ImageV2(unittest.TestCase):
    def test_evidence_path_connected_and_observed(self):
        c=channel_from_beige(flat_fixture())
        self.assertGreater(c['centerline_beige_support'],.72)
        self.assertEqual(cv2.connectedComponents(c['thin_mask'].astype(np.uint8),8)[0],2)
        self.assertTrue(len(c['centerline'])>100)
        self.assertLess(c['mean_distance_to_beige_px'],3)

    def test_incomplete_channel_exposes_false_support(self):
        img=flat_fixture()
        img[329:366,630:677]=(90,96,104)
        c=channel_from_beige(img)
        self.assertGreater(c['unsupported_line_pixels'].sum(),0)
        self.assertEqual(cv2.connectedComponents(c['thin_mask'].astype(np.uint8),8)[0],2)

    def test_rock_likelihood_is_not_height(self):
        img=renderer_fixture()
        land=np.ones(img.shape[:2],bool)
        likelihood,regions,std=rock_evidence(img,land)
        self.assertGreater(likelihood[210:300,210:400].mean(),likelihood[600:760,650:950].mean())
        self.assertTrue(np.all((likelihood>=0)&(likelihood<=1)))
        self.assertEqual(regions.shape,land.shape)

    def test_scale_alignment_is_labeled_only_as_pixel_iou(self):
        shape=np.zeros((90,100),bool)
        shape[20:80,25:75]=True
        small=cv2.resize(shape.astype(np.uint8),(200,180),interpolation=cv2.INTER_NEAREST)>0
        projected,iou=transform_ground_to_flat(small,shape)
        self.assertEqual(projected.shape,shape.shape)
        self.assertGreater(iou,.7)

    def test_view_orientation_is_not_coerced(self):
        a={'front':{'apparent_height_px':[0,20,45]},
           'back':{'apparent_height_px':[45,20,0]},
           'left':{'apparent_height_px':[4,14,20]},
           'right':{'apparent_height_px':[1,4,8]}}
        report=compare_profiles(a)
        self.assertEqual(report['front_back_rmse_px'],0.)
        self.assertGreater(report['left_right_rmse_px'],4)
        self.assertTrue(report['no_forced_agreement'])

    def test_src_hash_guard_and_real_pipeline_contract(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);src=root/'references';src.mkdir()
            cv2.imwrite(str(src/'top_flat_semantic.jpg'),flat_fixture())
            cv2.imwrite(str(src/'top_render.png'),renderer_fixture())
            for view in ('front','back','left','right'):
                im=np.full((1151,2048,3),30,np.uint8)
                cv2.fillPoly(im,[np.array([[260,465],[530,270],[840,465]],np.int32)],(200,200,200))
                cv2.imwrite(str(src/SOURCES[view]),im)
                cv2.imwrite(str(src/f'{view}_wireframe.png'),im)
            bad=root/'bad.json'
            bad.write_text(json.dumps({'source_sha256':{
                'top_mask':'bad','top_render':'bad'}}))
            with self.assertRaisesRegex(ValueError,'SHA-256 mismatch'):
                process(src,root/'rejected',bad)
            good=root/'good.json'
            good.write_text(json.dumps({'source_sha256':{
               'top_mask':hashlib.sha256((src/'top_flat_semantic.jpg').read_bytes()).hexdigest(),
               'top_render':hashlib.sha256((src/'top_render.png').read_bytes()).hexdigest()}}))
            out=root/'output'
            data=process(src,out,good)
            self.assertEqual(data['status'],'V2_2D_CONSTRAINTS_ONLY')
            self.assertTrue(data['channel_connected_raster'])
            self.assertTrue(data['channel_centerline_beige_support_fraction']>.6)
            self.assertIn('front_back_rmse_px',data['profile_comparison'])
            for name in ('v2_report.json','channel_polyline_source_pixels.json',
                         'channel_evidence_overlay.png','rock_evidence_overlay.png',
                         'rock_interior_candidate_render.png','rock_coastal_uncertain_render.png',
                         'orthographic_profile_constraints.json','v2_contact_sheet.jpg'):
                self.assertTrue((out/name).exists(),name)


if __name__=='__main__':unittest.main()
