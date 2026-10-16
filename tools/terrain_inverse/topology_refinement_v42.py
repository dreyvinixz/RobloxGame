"""V4.2: conservative polygon reconstruction from TWO source images + V4.1 evidence.

Only observed 2D lines and candidate faces; NEVER a true reconstructed 3D mesh.
The AI-cleaned image is weak guidance; the original's pixels remain authoritative.
"""
import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path

import cv2
import numpy as np

from .topology_v4 import graph_from_candidates


def load_pair(original, clean, previous):
    original, clean, previous = Path(original), Path(clean), Path(previous)
    originals = [p.read_bytes() for p in (original, clean)]
    pictures = [cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
                for raw in originals]
    if any(p is None for p in pictures) or pictures[0].shape != pictures[1].shape:
        raise ValueError("Missing/invalid reference or inconsistent image shape")
    record = json.loads((previous / 'v41_report.json').read_text())
    sha = [hashlib.sha256(raw).hexdigest() for raw in originals]
    if sha != [record['source_original_sha256'], record['source_clean_sha256']]:
        raise ValueError("Source SHA-256 mismatch with V4.1 input")
    masks = {}
    for key, filename in {'original': 'original_observed_strokes.png',
                          'water': 'water_mask.png',
                          'bright': 'terrain_confident_mask.png',
                          'cliff': 'cliff_candidate_mask.png',
                          'fused': 'fused_stroke_mask.png'}.items():
        mask = cv2.imread(str(previous / filename), cv2.IMREAD_GRAYSCALE)
        if mask is None or mask.shape != pictures[0].shape[:2]:
            raise ValueError(f"Invalid or missing V4.1 mask: {filename}")
        masks[key] = mask > 0
    lines = json.loads((previous / 'v41_edges.json').read_text())
    return pictures[0], pictures[1], masks, lines, sha


def edge_fraction(mask, p, q, tolerance=2):
    p, q = np.asarray(p, float), np.asarray(q, float)
    t = np.linspace(0, 1, max(5, int(np.linalg.norm(q - p) * 2)))
    xy = p[None] * (1 - t[:, None]) + q[None] * t[:, None]
    x = np.rint(xy[:, 0]).astype(int)
    y = np.rint(xy[:, 1]).astype(int)
    h, w = mask.shape
    valid = (x >= 0) & (x < w) & (y >= 0) & (y < h)
    if valid.sum() < 5:
        return 0.
    expanded = cv2.dilate(mask.astype('uint8'),
                          np.ones((2 * tolerance + 1,) * 2, np.uint8))
    return float(np.mean(expanded[y[valid], x[valid]] > 0))


def filter_lines(lines, masks):
    retained, rejected = [], Counter()
    for src in lines:
        p, q = src['p0'], src['p1']
        length = np.linalg.norm(np.asarray(p, float) - q)
        if length < 7:
            rejected['short'] += 1
            continue
        if edge_fraction(masks['water'], p, q, 0) > .10:
            rejected['water'] += 1
            continue
        real = edge_fraction(masks['original'], p, q)
        corroborated = edge_fraction(masks['fused'], p, q)
        if src.get('type') == 'gap_bridge':
            if real < .42 or corroborated < .45:
                rejected['unsupported_bridge'] += 1
                continue
            grade = 'gap_hypothesis'
        elif real >= .73 and corroborated >= .52:
            grade = 'high_confidence_observed'
        elif real >= .55 and corroborated >= .34:
            grade = 'medium_confidence_observed'
        else:
            rejected['unsupported'] += 1
            continue
        retained.append({**src, 'pixel_support': round(real, 3),
                         'v42_class': grade})
    return retained, dict(rejected)


def create_faces(lines, masks):
    """Tiny pixel-gap closure plus original-evidence verification of every side."""
    h, w = masks['original'].shape
    canvas = np.zeros((h, w), np.uint8)
    for e in lines:
        cv2.line(canvas, tuple(e['p0']), tuple(e['p1']), 255, 1)
    closed = cv2.morphologyEx(canvas, cv2.MORPH_CLOSE,
                              np.ones((3, 3), np.uint8))
    gap = (closed > 0) & (canvas == 0)
    wall = cv2.dilate(closed, np.ones((2, 2), np.uint8))
    n, labels, stats, _ = cv2.connectedComponentsWithStats(255-wall, 8)
    candidates, extra = [], []
    for i in range(1, n):
        x, y, ww, hh, area = map(int, stats[i])
        if not 45 <= area <= 2600 or min(ww, hh) < 5 or max(ww, hh) > 100:
            continue
        if min(x, y) < 3 or x+ww >= w-3 or y+hh >= h-3:
            continue
        cropped = (labels[y:y+hh, x:x+ww] == i).astype('uint8') * 255
        contours, _ = cv2.findContours(cropped, cv2.RETR_EXTERNAL,
                                        cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            continue
        polygon = cv2.approxPolyDP(max(contours, key=cv2.contourArea),
                                    1.9, True)[:, 0, :] + [x, y]
        if not 3 <= len(polygon) <= 6 or max(ww, hh)/min(ww, hh) > 4:
            continue
        center = polygon.mean(axis=0).astype(int)
        if masks['water'][center[1],center[0]]:
            continue
        zone = ('bright' if masks['bright'][center[1],center[0]] else
                'cliff' if masks['cliff'][center[1],center[0]] else 'unknown')
        if zone == 'unknown':
            continue
        pairs = zip(polygon, np.roll(polygon, -1, axis=0))
        supports = [edge_fraction(masks['original'], a, b)
                    for a, b in pairs]
        if min(supports) < .40 or np.mean(supports) < .60:
            continue
        item = {'vertices_px': polygon.tolist(), 'sides': len(polygon),
                'zone': zone, 'pixel_area': area,
                'source_support': round(float(np.mean(supports)), 3),
                'status': 'UNVERIFIED_2D_FACE'}
        (candidates if len(polygon) in (3,4) else extra).append(item)
    return candidates, extra, canvas, gap


def score_pixel_coverage(lines, source, shape):
    render = np.zeros(shape, np.uint8)
    for e in lines:
        cv2.line(render, tuple(e['p0']), tuple(e['p1']), 255, 1)
    observed = source > 0
    recall = (cv2.dilate(render, np.ones((5, 5), np.uint8))>0) & observed
    comps, _, _, _ = cv2.connectedComponentsWithStats((render>0).astype('uint8'),8)
    return render, {'observed_pixel_coverage_2px':
                    round(float(recall.sum()/max(1,observed.sum())),5),
                    'raster_connected_components': comps-1,
                    'independent_ground_truth': False}


def annotated_precision_recall(lines, annotations, shape):
    """Independent manual pixel labels, if provided by the researcher."""
    ground = cv2.imread(str(annotations), cv2.IMREAD_GRAYSCALE)
    if ground is None or ground.shape != shape:
        raise ValueError("Independent annotation mask must match original image size")
    pred, _ = score_pixel_coverage(lines, ground>127, shape)
    target = ground>127
    tp_p = ((pred>0) &
            (cv2.dilate(target.astype('uint8'),
                        np.ones((5,5),np.uint8))>0)).sum()
    tp_r = (target &
            (cv2.dilate(pred,np.ones((5,5),np.uint8))>0)).sum()
    precision = float(tp_p/max(1,(pred>0).sum()))
    recall = float(tp_r/max(1,target.sum()))
    return {'status':'independent_manually_labeled_2D_pixels',
            'precision':round(precision,5),'recall':round(recall,5),
            'f1':round(2*precision*recall/max(1e-12,precision+recall),5)}


def run(original, clean, previous, output, annotations=None):
    source, clean_img, masks, v41_lines, sha = load_pair(original,clean,previous)
    new_lines, rejection = filter_lines(v41_lines,masks)
    candidates, other_cells, strokes, gap = create_faces(new_lines,masks)
    # Shared vertices and incident faces: no Delaunay or fabricated diagonals.
    h,w=source.shape[:2]
    vertices, edges, faces, topology = graph_from_candidates(
        candidates, masks['original'].astype('uint8'), (w,h),
        (0,0,w,h), min_edge_support=.42)
    for f in faces:
        f['status'] = 'UNVERIFIED_2D_TOPOLOGY'
    a,v41metrics=score_pixel_coverage(v41_lines,masks['original'],(h,w))
    b,v42metrics=score_pixel_coverage(new_lines,masks['original'],(h,w))
    out=Path(output);out.mkdir(parents=True,exist_ok=True)
    overlay=source.copy()
    for e in new_lines:
        color={'high_confidence_observed':(0,210,60),
               'medium_confidence_observed':(235,170,30),
               'gap_hypothesis':(0,75,230)}[e['v42_class']]
        cv2.line(overlay,tuple(e['p0']),tuple(e['p1']),color,1,cv2.LINE_AA)
    face_overlay=source.copy()
    for f in faces:
        pts=np.asarray([vertices[v]['xy_image_px'] for v in f['vertex_ids']],
                       dtype=np.int32)
        cv2.polylines(face_overlay,[pts],True,
                      (20,220,20) if len(pts)==3 else (255,120,0),1)
    comparison=cv2.resize(np.concatenate([source,overlay,face_overlay],axis=1),
                         (int(w*1.5),int(h*.5)))
    for name,img in {
        'v42_filtered_edges_overlay.png':overlay,
        'v42_faces_overlay.png':face_overlay,
        'v42_comparison.png':comparison,
        'v42_line_mask.png':strokes,
        'v42_gap_closures_unverified.png':gap.astype('uint8')*255
    }.items():
        if not cv2.imwrite(str(out/name),img):
            raise IOError(f'Failed to write {name}')
    report={'stage':'V4.2_2D_ONLY','original_sha256':sha[0],
            'clean_sha256':sha[1],'original_dimensions_px':[w,h],
            'v41':v41metrics,'v42':v42metrics,
            'line_count_before':len(v41_lines),'line_count_after':len(new_lines),
            'line_rejections':rejection,
            'two_d_face_candidate_count':len(faces),
            'discarded_or_unclassified_closed_cells':len(other_cells),
            'face_topology':topology,
            'independent_evaluation':
                annotated_precision_recall(new_lines,annotations,(h,w))
                if annotations else {'status':'not_available',
                                     'reason':'no manually labeled mask supplied'},
            'limitations':['Neither image is original 3D geometry.',
                           'Candidate faces are only observed 2D pixel closures.',
                           'In-sample coverage is not geometric reconstruction accuracy.',
                           'No 3D heights, camera calibration, or continuous mesh recovery.']}
    for name,data in {
        'v42_lines.json':new_lines,'v42_vertices.json':vertices,
        'v42_edges.json':edges,'v42_faces.json':faces,
        'v42_unclassified_cells.json':other_cells,
        'v42_report.json':report
    }.items():
        (out/name).write_text(json.dumps(data,indent=2)+'\n',encoding='utf8')
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--original',required=True,type=Path)
    p.add_argument('--clean',required=True,type=Path)
    p.add_argument('--v41',required=True,type=Path)
    p.add_argument('--output',required=True,type=Path)
    p.add_argument('--annotation-mask',type=Path)
    a=p.parse_args()
    print(json.dumps(run(a.original,a.clean,a.v41,a.output,a.annotation_mask),
                     indent=2))


if __name__=='__main__':
    main()
