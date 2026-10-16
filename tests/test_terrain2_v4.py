"""V4 source-image refinement QA with deterministic synthetic images only."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import cv2
import numpy as np
from tools.terrain_2_v3.refine_v4 import (
    join_both_oceans, refine_rock, view_uncertainty, run
)


def reference_scene():
    h,w=260,360
    sea=np.full((h,w,3),(150,92,25),np.uint8)
    sea[12:248,8:352]=(100,106,115)
    river=np.array([[166,15],[173,55],[183,110],[205,152],
                    [218,192],[211,231],[195,246]],np.int32)
    cv2.polylines(sea,[river],False,(158,185,216),23)
    coast=np.full((320,480,3),165,np.uint8)
    rng=np.random.default_rng(8)
    coast[20:210,30:170]=np.clip(rng.normal(110,30,(190,140,1)),0,255).astype(np.uint8)
    return sea,coast,river


def setup_inputs(path):
    src=path/"references";v2=path/"v2";v3=path/"v3"
    for folder in (src,v2,v3):folder.mkdir()
    top,render,river=reference_scene()
    iso=np.full((280,450,3),(40,36,30),np.uint8)
    cv2.fillPoly(iso,[np.array([[8,220],[95,165],[173,70],
                                [245,180],[310,115],[440,230]])],(140,140,140))
    originals={"top_flat_semantic.jpg":top,"top_render.png":render,
        "oblique_wireframe_1.jpg":iso,"oblique_wireframe_2.jpg":iso,
        "oblique_side_render.jpg":iso}
    for view in ("front","back","left","right"):
        originals[f"{view}_render.png"]=np.full((1151,2048,3),155,np.uint8)
    hashes={}
    for name,image in originals.items():
        cv2.imwrite(str(src/name),image)
        hashes[name]=hashlib.sha256((src/name).read_bytes()).hexdigest()
    n=65
    z=np.full((n,n),30.,np.float32)
    z[:3,:]=-8
    np.save(v3/"height_relative_v3.npy",z)
    water=np.zeros((n,n),np.uint8)
    scaled=np.rint(river*np.array([(n-1)/(top.shape[1]-1),
                                 (n-1)/(top.shape[0]-1)])).astype(np.int32)
    cv2.polylines(water,[scaled],False,255,2)
    cv2.imwrite(str(v3/"river_mask_v3.png"),water)
    (v3/"river_centerline_v3.json").write_text(json.dumps(
        {"centerline_xy":river.tolist()}))
    (v3/"v3_report.json").write_text(json.dumps({"source_sha256":hashes}))
    for name in ("river_width_profile_v3.json","river_depth_profile_v3.json",
                 "river_volume_report_v3.json"):
        (v3/name).write_text("{}")
    land=np.full(top.shape[:2],255,np.uint8)
    rock=np.zeros(render.shape[:2],np.uint8)
    rock[40:200,25:175]=240
    cv2.imwrite(str(v2/"land_all_components.png"),land)
    cv2.imwrite(str(v2/"rock_likelihood.png"),rock)
    x=np.linspace(0,1,129)
    rise=(75*np.exp(-((x-.45)/.2)**2)).tolist()
    y=(80*np.exp(-((x-.57)/.18)**2)).tolist()
    profiles={"profiles":{
        "front":{"apparent_height_px":rise},"back":{"apparent_height_px":rise[::-1]},
        "left":{"apparent_height_px":y},"right":{"apparent_height_px":y[::-1]}
    }}
    (v2/"orthographic_profile_constraints.json").write_text(json.dumps(profiles))
    return src,v2,v3,river,top,profiles


class TerrainV4Tests(unittest.TestCase):
    def test_ocean_ends_use_source_pixels_and_remain_connected(self):
        top,_,route=reference_scene()
        field=np.full((65,65),30,np.float32)
        wet=np.zeros((65,65),bool)
        pts=np.rint(route*np.array([64/(top.shape[1]-1),
                                   64/(top.shape[0]-1)])).astype(np.int32)
        for p,q in zip(pts[:-1],pts[1:]):
            cv2.line(wet.view(np.uint8),tuple(p),tuple(q),1,2)
        new,extra,total,report=join_both_oceans(top,route,wet,field)
        self.assertTrue(report["north_south_connected"])
        self.assertLess(report["ocean_endpoints"][0]["distance_to_ocean_source_px"],35)
        self.assertTrue(np.isfinite(new).all())

    def test_view_conflict_report_is_not_suppressed(self):
        classes=np.ones((17,17),np.uint8)*5
        p={"profiles":{k:{"apparent_height_px":[0.]*129}
                       for k in ("front","back","left","right")}}
        p["profiles"]["right"]["apparent_height_px"]=[25.]*129
        unc=view_uncertainty(classes,p,17)
        self.assertGreater(float(unc.max()),10)

    def test_rock_refinement_tracks_source_and_limits_profile_degradation(self):
        _,render,_=reference_scene()
        z=np.ones((65,65),np.float32)*30
        classes=np.ones((65,65),np.uint8)*5
        arr=[30.]*129
        p={"profiles":{k:{"apparent_height_px":arr}
                       for k in ("front","back","left","right")}}
        refined,report=refine_rock(z,render,classes,p)
        self.assertTrue(np.isfinite(refined).all())
        self.assertLessEqual(report["chosen"]["mean_silhouette_rmse"],
                             report["base_mean_rmse"]*1.03+1e-8)

    def test_sha_guard(self):
        with tempfile.TemporaryDirectory() as tmp:
            src,v2,v3,route,top,p=setup_inputs(Path(tmp))
            (src/"top_render.png").write_bytes((src/"top_render.png").read_bytes()+b"x")
            with self.assertRaisesRegex(ValueError,"SHA-256 mismatch"):
                run(src,v2,v3,Path(tmp)/"output")

    def test_full_synthetic_export_and_no_mesh_truth_claim(self):
        with tempfile.TemporaryDirectory() as tmp:
            src,v2,v3,route,top,p=setup_inputs(Path(tmp))
            output=Path(tmp)/"out"
            result=run(src,v2,v3,output)
            self.assertEqual(result["status"],"V4_REFINED_RELATIVE_2_5D_NOT_VALIDATED")
            self.assertTrue(result["river_ocean"]["north_south_connected"])
            self.assertTrue(result["not_recovered_geometry"])
            self.assertEqual(result["vertices"],65*65)
            for name in ("mesh_refined_v4.obj","heightmap_refined_v4.png",
                         "river_ocean_join_v4.png","uncertainty_v4.png",
                         "final_report_v4.json","terrain_v4.html",
                         "multiview_comparison_v4.png"):
                self.assertTrue((output/name).is_file(),name)


if __name__=="__main__":
    unittest.main()
