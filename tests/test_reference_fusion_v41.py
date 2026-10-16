"""Input/provenance and graph tests for pixel-first V4.1; synthetic images only."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import cv2
import numpy as np
from tools.terrain_inverse.reference_fusion_v41 import read,align,masks,graph,run

def synthetic():
    source=np.full((400,480,3),(75,75,75),np.uint8)
    source[180:380,45:435]=(204,204,204)
    for x in range(65,426,28):
        cv2.line(source,(x,190),(x,370),(87,87,87),1)
    for y in range(195,370,24):
        cv2.line(source,(65,y),(420,y),(87,87,87),1)
    source[220:270,15:43]=(150,100,56) # blue water in BGR
    auxiliary=source.copy()
    cv2.rectangle(source,(180,265),(192,302),(26,26,26),-1) # nonterrain occluder
    return source,auxiliary

class PixelFusionTests(unittest.TestCase):
    def test_no_source_no_result(self):
        with self.assertRaises(FileNotFoundError):
            run('/no-original-image.png','/no-clean-image.png','/tmp/not-generated')

    def test_nonmatching_images_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)
            original,clean=synthetic()
            cv2.imwrite(str(path/'original.png'),original)
            cv2.imwrite(str(path/'clean.png'),clean[:200])
            with self.assertRaisesRegex(ValueError,'dimensions'):
                run(path/'original.png',path/'clean.png',path/'out')

    def test_graph_keeps_isolated_lines_distinct(self):
        edges=[{'p0':[10,10],'p1':[30,10]},
               {'p0':[31,10],'p1':[45,10]},
               {'p0':[100,100],'p1':[120,120]}]
        v,m=graph(edges)
        self.assertEqual(m['components'],2)
        self.assertEqual(m['edges'],3)
        self.assertEqual(len(v),5)

    def test_output_is_original_pixel_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)
            original,clean=synthetic()
            cv2.imwrite(str(path/'original.png'),original)
            cv2.imwrite(str(path/'clean.png'),clean)
            result=run(path/'original.png',path/'clean.png',path/'out')
            self.assertEqual(result['source_original_sha256'],
                             hashlib.sha256((path/'original.png').read_bytes()).hexdigest())
            self.assertEqual(result['status'],'2D_LINE_HYPOTHESES_ONLY')
            self.assertTrue(result['v41']['observed_segments']>0)
            self.assertEqual(json.loads((path/'out/v41_faces_candidates.json').read_text()),[])
            for name in ['water_mask.png','terrain_confident_mask.png','cliff_candidate_mask.png',
                         'uncertain_mask.png','normalized_observation.png','v41_edges.json',
                         'v41_vertices.json','grid_families_light.json',
                         'grid_families_cliff.json','comparison_original_clean_v41.png',
                         'v41_report.json']:
                self.assertTrue((path/'out'/name).is_file(),name)

    def test_identical_clean_input_is_not_ground_truth(self):
        image,_=synthetic()
        aligned,report,used=align(image,image)
        self.assertEqual(aligned.shape,image.shape)
        self.assertIn(report['status'],['accepted','rejected'])

if __name__=='__main__':
    unittest.main()
