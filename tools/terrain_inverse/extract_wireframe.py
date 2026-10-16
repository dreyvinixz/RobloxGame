"""Experimental extraction of wireframe evidence DIRECTLY FROM SOURCE IMAGE PIXELS.

Image-space segments, junctions and candidate closed polygons ARE NOT a recovered
3D mesh. AI-generated wireframe topology can be impossible or inconsistent.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np
from scipy.ndimage import convolve
from skimage.morphology import skeletonize


def extract_strokes(bgr: np.ndarray, contrast: int = 5, min_background: int = 112):
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    median = cv2.medianBlur(gray, 11)
    darkness = median.astype(np.int16) - gray.astype(np.int16)
    mask = ((darkness >= contrast) & (median >= min_background)).astype(np.uint8)
    count, ids, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    valid = np.zeros(count, dtype=bool)
    valid[1:] = stats[1:, cv2.CC_STAT_AREA] >= 3
    return valid[ids]


def detect_junctions(skeleton: np.ndarray):
    neighbors = convolve(skeleton.astype(np.uint8),
                         np.ones((3, 3), dtype=np.uint8), mode='constant') - skeleton
    nodes = ((neighbors >= 4) & skeleton).astype(np.uint8)
    nodes = cv2.dilate(nodes, np.ones((3, 3), np.uint8))
    count, ids, stats, centers = cv2.connectedComponentsWithStats(nodes, 8)
    kept = []
    for idx in np.argsort(stats[1:, cv2.CC_STAT_AREA])[::-1] + 1:
        if stats[idx, cv2.CC_STAT_AREA] < 2:
            continue
        xy = centers[idx]
        if all(np.linalg.norm(xy - p) >= 6 for p in kept):
            kept.append(xy)
    return np.asarray(kept, dtype=float).reshape(-1, 2)


def detect_closed_cells(mask: np.ndarray):
    """Trace source-pixel enclosed regions; never add arbitrary Delaunay diagonals."""
    wall = cv2.morphologyEx(mask.astype(np.uint8) * 255,
                            cv2.MORPH_CLOSE, np.ones((2, 2), np.uint8))
    wall = cv2.dilate(wall, np.ones((2, 2), np.uint8))
    count, labels, stats, _ = cv2.connectedComponentsWithStats(255 - wall, 8)
    expanded = cv2.dilate(mask.astype(np.uint8), np.ones((7, 7), np.uint8)).astype(bool)
    height, width = mask.shape
    faces = []
    for index in range(1, count):
        x, y, w, h, area = [int(v) for v in stats[index]]
        if (not 40 <= area <= 1400 or min(w, h) < 5 or x < 3 or y < 3
                or x + w >= width - 3 or y + h >= height - 3):
            continue
        region = (labels[y:y + h, x:x + w] == index).astype(np.uint8) * 255
        contours, _ = cv2.findContours(region, cv2.RETR_EXTERNAL,
                                       cv2.CHAIN_APPROX_SIMPLE)
        if not contours:
            continue
        path = max(contours, key=cv2.contourArea) + np.array([[[x, y]]])
        polygon = cv2.approxPolyDP(path, .052 * cv2.arcLength(path, True),
                                   True)[:, 0, :].astype(float)
        if not 3 <= len(polygon) <= 6:
            continue
        evidence = []
        for a, b in zip(polygon, np.roll(polygon, -1, axis=0)):
            d = np.linalg.norm(b - a)
            t = np.linspace(.08, .92, max(5, int(2 * d)))
            pts = a[None, :] * (1 - t[:, None]) + b[None, :] * t[:, None]
            xx = np.clip(np.rint(pts[:, 0]).astype(int), 0, width - 1)
            yy = np.clip(np.rint(pts[:, 1]).astype(int), 0, height - 1)
            evidence.append(float(expanded[yy, xx].mean()))
        if min(evidence) < .27 or np.mean(evidence) < .46:
            continue
        faces.append({
            'vertices_px': polygon.round(2).tolist(),
            'sides': len(polygon),
            'area_px2': area,
            'edge_support': np.round(evidence, 3).tolist(),
            'status': 'unverified 2D closed-cell hypothesis'
        })
    return faces


def analyze(raw: bytes, roi=None, contrast=5, min_background=112):
    bgr = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError('Missing or invalid source image')
    height, width = bgr.shape[:2]
    if roi is None:
        roi = (0, 0, width, height)
    x0, y0, x1, y1 = roi
    if not 0 <= x0 < x1 <= width or not 0 <= y0 < y1 <= height:
        raise ValueError('ROI outside image')
    patch = bgr[y0:y1, x0:x1]
    mask = extract_strokes(patch, contrast, min_background)
    skel = skeletonize(mask)
    nodes = detect_junctions(skel)
    candidates = detect_closed_cells(mask)
    detected = cv2.HoughLinesP(skel.astype(np.uint8) * 255, 1, np.pi / 360,
                                threshold=10, minLineLength=10, maxLineGap=3)
    segments = []
    if detected is not None:
        for x, y, xx, yy in detected[:, 0]:
            segments.append({
                'p0_px': [int(x + x0), int(y + y0)],
                'p1_px': [int(xx + x0), int(yy + y0)]
            })
    for face in candidates:
        face['vertices_px'] = [
            [round(float(p[0]) + x0, 2), round(float(p[1]) + y0, 2)]
            for p in face['vertices_px']
        ]
    report = {
        'source_sha256': hashlib.sha256(raw).hexdigest(),
        'source_image_size_px': [width, height],
        'roi_xyxy_px': list(roi),
        'parameters': {'contrast': contrast, 'min_background': min_background},
        'measurements': {
            'observed_mask_pixels': int(mask.sum()),
            'skeleton_pixels': int(skel.sum()),
            'candidate_line_segments': len(segments),
            'candidate_junctions': len(nodes),
            'candidate_closed_faces': len(candidates),
            'candidate_triangles': sum(p['sides'] == 3 for p in candidates),
            'candidate_quads': sum(p['sides'] == 4 for p in candidates)
        },
        'segments': segments,
        'junctions_px': [[round(float(p[0]) + x0, 2),
                          round(float(p[1]) + y0, 2)] for p in nodes],
        'faces': candidates,
        'limitations': [
            '2D geometry only. No original 3D vertices or topology recovered.',
            'False edges from trees, shadows, roads, cliffs and ocean possible.',
            'Closed-cell candidates are hypotheses; open or obscured faces are missed.',
            'AI-generated wireframes need not be topologically consistent.'
        ]
    }
    return report, (patch, mask, skel, nodes, candidates, roi)


def export(input_path, output, roi=None, contrast=5, min_background=112):
    input_path = Path(input_path)
    raw = input_path.read_bytes()
    report, data = analyze(raw, roi, contrast, min_background)
    patch, mask, skel, nodes, faces, (x0, y0, _, _) = data
    target = Path(output)
    target.mkdir(parents=True, exist_ok=True)
    overlay = patch.copy()
    overlay[skel] = (20, 205, 245)
    for xy in nodes:
        cv2.circle(overlay, tuple(np.rint(xy).astype(int)),
                   2, (180, 0, 255), -1)
    cv2.imwrite(str(target / 'observed_wireframe_overlay.png'), overlay)
    face_view = patch.copy()
    for face in faces:
        poly = np.rint(np.asarray(face['vertices_px'])
                        - [x0, y0]).astype(np.int32)
        color = (0, 255, 80) if face['sides'] == 3 else (
            (240, 160, 0) if face['sides'] == 4 else (240, 0, 220))
        cv2.polylines(face_view, [poly], True, color, 1, cv2.LINE_AA)
    cv2.imwrite(str(target / 'closed_cell_hypotheses_overlay.png'), face_view)
    cv2.imwrite(str(target / 'observed_line_mask.png'), mask.astype(np.uint8) * 255)
    cv2.imwrite(str(target / 'observed_skeleton.png'), skel.astype(np.uint8) * 255)
    report['source_filename'] = input_path.name
    (target / 'wireframe_report.json').write_text(
        json.dumps(report, indent=2) + '\n', encoding='utf8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, required=True,
                        help='Mandatory source PNG; no procedural fallback')
    parser.add_argument('--output', type=Path, default=Path('wireframe-output'))
    parser.add_argument('--roi', type=int, nargs=4,
                        metavar=('X0', 'Y0', 'X1', 'Y1'))
    parser.add_argument('--contrast', type=int, default=5)
    parser.add_argument('--min-background', type=int, default=112)
    args = parser.parse_args()
    result = export(args.image, args.output,
                    tuple(args.roi) if args.roi else None,
                    args.contrast, args.min_background)
    print(json.dumps(result['measurements'], indent=2))


if __name__ == '__main__':
    main()
