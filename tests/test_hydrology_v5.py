"""Regression tests for source-guided lake-to-harbor river connectivity."""
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from tools.terrain_inverse.hydrology_v5 import (
    blue_evidence, build_hydrology, labeled_lake, save_hydrology, trace_river
)


def synthetic_valley():
    """Blue stream and lake on non-blue land, not a procedural mountain reference."""
    h, w = 260, 260
    image = np.full((h,w,3),(78,131,107),np.uint8)
    blue=(155,105,18)
    cv2.circle(image,(173,48),23,blue,-1)
    waypoints=[[173,48],[167,68],[150,91],[132,108],[115,127],
               [113,154],[89,178],[64,210],[44,244]]
    cv2.polylines(image,[np.asarray(waypoints,np.int32)],False,blue,9)
    cv2.circle(image,(44,244),18,blue,-1)
    annotation={
        'lake_seed_px':[173,48],
        'lake_to_port_waypoints_px':waypoints,
        'routing_corridor_px':16,
        'river_half_width_px':5,
        'bank_blend_px':13,
        'lake_surface_relative':12.,
        'port_surface_relative':0.,
        'water_depth_relative':2.5,
        'bank_rise_relative':5.
    }
    field = np.full((129,129),32.,np.float32)
    return image,field,annotation


class RiverConnectivityTests(unittest.TestCase):
    def test_lake_is_identified_from_raw_colors(self):
        image,_,info=synthetic_valley()
        blue=blue_evidence(image)
        lake=labeled_lake(blue,info['lake_seed_px'])
        self.assertTrue(lake[48,173])
        self.assertFalse(lake[155,20])

    def test_winding_original_blue_stream_is_traced(self):
        image,_,info=synthetic_valley()
        route,blue=trace_river(image,info['lake_to_port_waypoints_px'],16)
        self.assertGreater(len(route),100)
        self.assertGreater(float(blue[route[:,1],route[:,0]].mean()),.5)

    def test_all_water_sections_connected_and_downhill(self):
        image,field,info=synthetic_valley()
        output=build_hydrology(image,field,info)
        self.assertTrue(output['report']['lake_to_harbor_connected'])
        self.assertTrue(output['report']['monotone_surface_downstream'])
        self.assertTrue(np.all(np.diff(output['river_level'])<=1e-6))
        self.assertAlmostEqual(float(output['river_level'][0]),12.)
        self.assertAlmostEqual(float(output['river_level'][-1]),0.)
        self.assertTrue((output['water_mask'] & output['river_mask']).any())
        self.assertTrue(np.isfinite(output['height']).all())
        # Unrelated terrain outside the source water and margins must not change.
        self.assertAlmostEqual(float(output['height'][105,220//2]),32.)
        self.assertLess(int((output['height']!=field).sum()),int(field.size*.25))

    def test_different_grids_do_not_break_the_river(self):
        image,_,info=synthetic_valley()
        for grid in (33,65,129,257):
            out=build_hydrology(image,np.full((grid,grid),32,np.float32),info)
            self.assertTrue(out['report']['lake_to_harbor_connected'],grid)

    def test_bad_source_and_uphill_annotations_are_rejected(self):
        image,field,info=synthetic_valley()
        blank=np.full_like(image,(82,140,100))
        with self.assertRaisesRegex(ValueError,'Lake'):
            build_hydrology(blank,field,info)
        wrong=dict(info,port_surface_relative=18.)
        with self.assertRaisesRegex(ValueError,'descend'):
            build_hydrology(image,field,wrong)

    def test_outputs_reference_overlay_masks_and_water_obj(self):
        image,field,info=synthetic_valley()
        output=build_hydrology(image,field,info)
        with tempfile.TemporaryDirectory() as tmp:
            save_hydrology(tmp,image,output,info)
            for filename in ('river_reference_overlay.png','river_mask_grid.png',
                             'lake_mask_grid.png','water_connected_grid.png',
                             'river_water_surface.obj','hydrology_report.json'):
                self.assertTrue((Path(tmp)/filename).is_file(),filename)
            obj=(Path(tmp)/'river_water_surface.obj').read_text()
            self.assertIn('\nv ',obj)
            self.assertIn('\nf ',obj)


if __name__=='__main__':
    unittest.main()
