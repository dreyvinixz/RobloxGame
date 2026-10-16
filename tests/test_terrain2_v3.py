"""V3 synthetic regression: source provenance, connected water, assumptions, multiview.
Do not mistake a passing test for fidelity to the user's original AI images.
"""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import cv2
import numpy as np

from tools.terrain_2_v3.terrain_v3 import fit_heightfield, predict_profile, run
from tools.terrain_2_v3.river_v3 import model_river, widths_from_reference
from tools.terrain_2_v3.isometric_v3 import silhouette_fit


def make_channel():
    image = np.full((260,360,3),(100,107,117),dtype=np.uint8)
    path = np.array([[160,20],[170,65],[182,110],[204,150],
                     [215,190],[212,225],[195,250]],np.int32)
    cv2.polylines(image,[path],False,(157,181,213),25)
    points = []
    for a,b in zip(path[:-1],path[1:]):
        for t in np.linspace(0,1,15):
            points.append((a*(1-t)+b*t).tolist())
    return image,np.asarray(points)


def synthetic_profiles():
    x = np.linspace(0,1,129)
    p = 100*np.exp(-((x-.27)/.12)**2)+90*np.exp(-((x-.78)/.10)**2)
    q = 85*np.exp(-((x-.53)/.16)**2)
    return {"profiles": {
        "front":{"apparent_height_px":p.tolist()},
        "back":{"apparent_height_px":p[::-1].tolist()},
        "left":{"apparent_height_px":q.tolist()},
        "right":{"apparent_height_px":q[::-1].tolist()}
    }}


def create_sources(root):
    root = Path(root)
    original = root/"references"
    v2 = root/"v2"
    original.mkdir()
    v2.mkdir()
    flat, route = make_channel()
    render = np.full((320,480,3),(155,163,166),np.uint8)
    rng = np.random.default_rng(7)
    render[30:160,25:200] = np.clip(rng.normal(100,35,(130,175,1)),0,255).astype(np.uint8)
    files = {"top_flat_semantic.jpg":flat,"top_render.png":render}
    oblique = np.full((280,450,3),(40,36,30),np.uint8)
    cv2.fillPoly(oblique,[np.array([[10,225],[90,160],[170,70],
                                  [250,175],[310,100],[440,230]])],(150,150,150))
    for name in ["oblique_wireframe_1.jpg","oblique_wireframe_2.jpg",
                 "oblique_side_render.jpg"]:
        files[name] = oblique
    for view in ["front","back","left","right"]:
        files[f"{view}_render.png"] = np.full((1151,2048,3),150,np.uint8)
    sha = {}
    for name, image in files.items():
        path = original/name
        cv2.imwrite(str(path),image)
        sha[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    land = np.zeros(flat.shape[:2],np.uint8)
    land[10:255,5:355] = 255
    rock = np.zeros(render.shape[:2],np.uint8)
    rock[40:190,50:140] = 240
    rock[50:210,270:430] = 210
    cv2.imwrite(str(v2/"land_all_components.png"),land)
    cv2.imwrite(str(v2/"rock_likelihood.png"),rock)
    (v2/"v2_report.json").write_text(json.dumps({"source_sha256":sha}))
    (v2/"channel_polyline_source_pixels.json").write_text(json.dumps(
        {"centerline_xy":route.tolist()}))
    (v2/"orthographic_profile_constraints.json").write_text(json.dumps(synthetic_profiles()))
    return original,v2


class TerrainV3(unittest.TestCase):
    def test_width_is_from_source_pixels(self):
        source,route = make_channel()
        _,metrics = widths_from_reference(source,route)
        self.assertGreater(metrics["median_width_original_px"],10)
        self.assertLess(metrics["median_width_original_px"],40)
        self.assertTrue(metrics["source_pixel_observation_only"])

    def test_depth_scenarios_change_relative_volume_not_observed_width(self):
        source,route = make_channel()
        field = np.full((65,65),30,dtype=np.float32)
        shallow,low,geometry = model_river(source,field,
            {"centerline_xy":route.tolist()},{"depth_multiplier":.5})
        deep,high,_ = model_river(source,field,
            {"centerline_xy":route.tolist()},{"depth_multiplier":1.5})
        self.assertAlmostEqual(high["summary"]["water_volume_relative_cubic_units"]/
                               low["summary"]["water_volume_relative_cubic_units"],3)
        self.assertTrue(high["summary"]["north_to_south_sea_channel_connected"])
        self.assertTrue((np.diff(geometry["surface_levels"])<=1e-7).all())
        self.assertTrue(np.isfinite(shallow).all())
        self.assertTrue(np.isfinite(deep).all())
        self.assertFalse(low["summary"]["ABSOLUTE_CUBIC_METERS_AVAILABLE"])

    def test_orthographic_mirroring(self):
        height = np.zeros((33,33),np.float32)
        height[11,5] = 40
        height[21,29] = 21
        self.assertTrue(np.allclose(predict_profile(height,"front"),
                                    predict_profile(height,"back")[::-1]))
        self.assertTrue(np.allclose(predict_profile(height,"left"),
                                    predict_profile(height,"right")[::-1]))

    def test_terrain_uses_source_rock_distribution(self):
        land = np.ones((260,360),bool)
        rock = np.zeros((150,200),np.float32)
        rock[20:85,20:70] = .8
        rock[30:100,120:175] = .95
        height,mask,info = fit_heightfield(rock,land,synthetic_profiles(),65,14)
        self.assertEqual(height.shape,(65,65))
        self.assertGreater(height.max(),15)
        self.assertTrue(mask.all())
        self.assertTrue(info["incompatible_views_regularized"])

    def test_real_isometric_pixels_are_required(self):
        image = np.full((280,450,3),(40,36,30),np.uint8)
        cv2.fillPoly(image,[np.array([[10,220],[100,160],[170,70],
                                     [250,175],[310,100],[440,230]])],(150,150,150))
        field = np.zeros((49,49),np.float32)
        field[13:35,12:22] = 50
        m = silhouette_fit(image,field,np.ones((49,49),bool),bins=64)
        self.assertTrue(np.isfinite(m["normalized_rmse"]))
        self.assertGreater(m["normalized_rmse"],0)

    def test_invalid_source_fails_without_procedural_fallback(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            with self.assertRaises(FileNotFoundError):
                run(root/"missing",root/"missing",root/"out",33)

    def test_full_pipeline_synthetic_and_source_hash(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            src,v2 = create_sources(root)
            output = root/"output"
            result = run(src,v2,output,33)
            self.assertEqual(result["status"],"V3_IMAGE_CONSTRAINED_2_5D_HYPOTHESIS")
            self.assertEqual(result["vertices"],1089)
            self.assertEqual(result["triangles"],2048)
            self.assertTrue(result["river"]["north_to_south_sea_channel_connected"])
            self.assertTrue(result["river"]["equal_sea_surface_elevation_at_both_ends"])
            self.assertEqual(result["source_sha256"]["top_flat_semantic.jpg"],
                hashlib.sha256((src/"top_flat_semantic.jpg").read_bytes()).hexdigest())
            for path in ["mesh_v3.obj","river_water_surface_v3.obj",
                         "heightmap_relative_v3_16bit.png","river_volume_report_v3.json",
                         "multiview_profiles_v3.png","isometric_silhouette_diagnostics.png",
                         "terrain_v3.html","v3_report.json"]:
                self.assertTrue((output/path).is_file(),path)


if __name__=="__main__":
    unittest.main()
