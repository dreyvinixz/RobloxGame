"""V4: pixel-derived candidate polygon topology. NOT 3D terrain reconstruction."""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

import cv2
import numpy as np
from scipy.spatial import cKDTree


def polygon_area(points):
    p = np.asarray(points, dtype=float)
    return float(.5 * np.sum(p[:, 0] * np.roll(p[:, 1], -1) -
                              p[:, 1] * np.roll(p[:, 0], -1)))


def edge_support(mask, a, b, radius=2):
    h, w = mask.shape
    expanded = cv2.dilate(mask.astype(np.uint8),
                          np.ones((radius * 2 + 1, radius * 2 + 1), np.uint8))
    a, b = np.asarray(a, float), np.asarray(b, float)
    n = max(3, int(np.linalg.norm(a - b) * 2))
    t = np.linspace(0, 1, n)
    points = a[None, :] * (1 - t[:, None]) + b[None, :] * t[:, None]
    valid = ((points[:, 0] >= 0) & (points[:, 0] < w) &
             (points[:, 1] >= 0) & (points[:, 1] < h))
    if valid.sum() < 3:
        return 0.
    x = np.clip(np.rint(points[:, 0]).astype(int), 0, w - 1)
    y = np.clip(np.rint(points[:, 1]).astype(int), 0, h - 1)
    return float(expanded[y[valid], x[valid]].mean())


def merge_points(points, tolerance=3.):
    points = np.asarray(points, float).reshape(-1, 2)
    if not len(points):
        return [], []
    parent = list(range(len(points)))
    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for a, b in sorted(cKDTree(points).query_pairs(tolerance)):
        a, b = root(a), root(b)
        if a != b:
            parent[max(a, b)] = min(a, b)
    groups = defaultdict(list)
    for i in range(len(points)):
        groups[root(i)].append(i)
    nodes, ids = [], np.zeros(len(points), dtype=int)
    groups = sorted(groups.values(), key=lambda g: tuple(points[g].mean(axis=0)))
    for i, members in enumerate(groups):
        point = points[members].mean(axis=0)
        nodes.append(np.round(point, 2).tolist())
        ids[members] = i
    return nodes, ids.tolist()


def graph_from_candidates(candidates, stroke_mask, image_size, roi,
                          merge_radius=3., min_edge_support=.42):
    width, height = image_size
    x0, y0, x1, y1 = roi
    if stroke_mask.shape != (y1 - y0, x1 - x0):
        raise ValueError('Stroke image dimensions disagree with selected ROI')
    raw_points, ranges = [], []
    for face in candidates:
        poly = face['vertices_px']
        if not 3 <= len(poly) <= 6:
            continue
        ranges.append((len(raw_points), len(poly)))
        raw_points.extend(poly)
    nodes, merged = merge_points(raw_points, merge_radius)
    accepted, rejected, seen = [], Counter(), set()
    for (start, size), source in zip(ranges, [f for f in candidates
                                              if 3 <= len(f['vertices_px']) <= 6]):
        ids = merged[start:start + size]
        if len(set(ids)) != len(ids):
            rejected['merged_distinct_corners'] += 1
            continue
        pts = np.asarray([nodes[i] for i in ids], float)
        area = abs(polygon_area(pts))
        if area < 30:
            rejected['degenerate_area'] += 1
            continue
        lengths = np.linalg.norm(pts - np.roll(pts, -1, axis=0), axis=1)
        if lengths.min() < 4:
            rejected['too_short_edge'] += 1
            continue
        key = tuple(sorted(ids))
        if key in seen:
            rejected['duplicate_face'] += 1
            continue
        support = [edge_support(stroke_mask, a - [x0, y0], b - [x0, y0])
                   for a, b in zip(pts, np.roll(pts, -1, axis=0))]
        if min(support) < .32 or np.mean(support) < min_edge_support:
            rejected['unsupported_edges'] += 1
            continue
        if not cv2.isContourConvex(pts.astype(np.float32).reshape(-1, 1, 2)):
            rejected['nonconvex'] += 1
            continue
        seen.add(key)
        accepted.append({'vertex_ids': ids, 'sides': len(ids),
                         'area_image_px2': round(area, 2),
                         'observed_edge_support': round(float(np.mean(support)), 3),
                         'source': 'Unverified 2D pixel-enclosed cell'})
    used = sorted({j for face in accepted for j in face['vertex_ids']})
    relabel = {j: i for i, j in enumerate(used)}
    vertices = [{'id': i, 'xy_image_px': nodes[j], 'world_xyz': None,
                 'confidence': 'unverified'} for i, j in enumerate(used)]
    edges = {}
    for f_id, face in enumerate(accepted):
        ids = [relabel[i] for i in face['vertex_ids']]
        face['vertex_ids'] = ids
        face['id'] = f_id
        for a, b in zip(ids, ids[1:] + ids[:1]):
            edges.setdefault(tuple(sorted((a, b))), []).append(f_id)
    edge_records = [
        {'id': k, 'vertex_ids': list(edge),
         'face_ids': owners, 'incident_face_count': len(owners),
         'non_manifold': len(owners) > 2}
        for k, (edge, owners) in enumerate(sorted(edges.items()))]
    neighbors = defaultdict(list)
    for a, b in edges:
        neighbors[a].append(b)
        neighbors[b].append(a)
    visited, sizes = set(), []
    for node in range(len(vertices)):
        if node in visited:
            continue
        stack, length = [node], 0
        visited.add(node)
        while stack:
            current = stack.pop()
            length += 1
            for adjacent in neighbors[current]:
                if adjacent not in visited:
                    visited.add(adjacent)
                    stack.append(adjacent)
        sizes.append(length)
    metrics = {
        'raw_face_candidates': len(candidates),
        'vertices': len(vertices), 'edges': len(edges),
        'accepted_2d_faces': len(accepted),
        'triangles': sum(f['sides'] == 3 for f in accepted),
        'quadrilaterals': sum(f['sides'] == 4 for f in accepted),
        'components': len(sizes), 'largest_component': max(sizes, default=0),
        'non_manifold_edges': sum(e['non_manifold'] for e in edge_records),
        'boundary_edges': sum(e['incident_face_count'] == 1 for e in edge_records),
        'euler_characteristic': len(vertices) - len(edges) + len(accepted),
        'rejections': dict(rejected)
    }
    return vertices, edge_records, accepted, metrics


def segment_graph_from_observations(junctions, segments, mask, roi,
                                    snap_radius=9, minimum_length=12):
    """Independent line evidence graph. Edges do NOT imply recovered polygons."""
    x0, y0, _, _ = roi
    if not junctions:
        return [], [], {'segments_matched': 0, 'components': 0}
    nodes = np.asarray(junctions, dtype=float).reshape(-1, 2)
    tree = cKDTree(nodes)
    matched = {}
    for segment in segments:
        start = np.asarray(segment.get('p0_px', segment.get('p0')), float)
        end = np.asarray(segment.get('p1_px', segment.get('p1')), float)
        if np.linalg.norm(end - start) < minimum_length:
            continue
        distance, index = tree.query([start, end], distance_upper_bound=snap_radius)
        if max(distance) > snap_radius or any(k >= len(nodes) for k in index):
            continue
        a, b = map(int, index)
        if a == b:
            continue
        key = tuple(sorted((a, b)))
        score = edge_support(mask, start - [x0, y0], end - [x0, y0])
        if score >= .45:
            matched[key] = max(score, matched.get(key, 0.))
    selected = sorted({k for edge in matched for k in edge})
    relabel = {j: i for i, j in enumerate(selected)}
    vertices = [{'id': relabel[j], 'xy_image_px': nodes[j].round(2).tolist(),
                 'world_xyz': None} for j in selected]
    edges = [{'vertex_ids': [relabel[a], relabel[b]],
              'source_segment_support': round(score, 3)}
             for (a, b), score in sorted(matched.items())]
    parent = list(range(len(vertices)))
    def root(j):
        while parent[j] != j:
            parent[j] = parent[parent[j]]
            j = parent[j]
        return j
    for edge in edges:
        a, b = edge['vertex_ids']
        parent[root(a)] = root(b)
    sizes = Counter(root(i) for i in range(len(vertices)))
    return vertices, edges, {
        'segments_matched': len(edges), 'vertices': len(vertices),
        'components': len(sizes), 'largest_component': max(sizes.values(), default=0)}


def estimate_plane_registration(controls=None):
    """Optional planar homography, not calibrated 3D camera extrinsics."""
    if controls is None:
        return {'status': 'not_estimated', 'camera_model': None,
                'reason': 'No independently verified coplanar image-to-map correspondences'}
    points = controls.get('points', [])
    if len(points) < 4:
        raise ValueError('At least four verified point correspondences are needed')
    if any(p.get('on_same_plane') is not True for p in points):
        raise ValueError('All control points must certify on_same_plane=true')
    world = np.asarray([p['world_xy'] for p in points], np.float64)
    image = np.asarray([p['image_xy_px'] for p in points], np.float64)
    if np.linalg.matrix_rank(np.c_[world, np.ones(len(world))]) < 3:
        raise ValueError('World-plane points are collinear')
    homography, inlier = cv2.findHomography(world, image, cv2.RANSAC, 3.)
    if homography is None:
        raise ValueError('Planar homography could not be estimated')
    projected = cv2.perspectiveTransform(world.astype(np.float32)[None, ...],
                                         homography.astype(np.float32))[0]
    error = np.linalg.norm(projected - image, axis=1)
    return {'status': 'plane_homography_only',
            'camera_model': 'uncalibrated planar projection',
            'planar_homography_world_to_image': homography.tolist(),
            'inliers': int(inlier.sum()), 'controls': len(points),
            'reprojection_rmse_px': float(np.sqrt(np.mean(error ** 2))),
            'warning': 'A planar H is not a 3D camera or an elevation estimate'}


def compare_image_edges(image, mask, roi, vertices, edges):
    x0, y0, x1, y1 = roi
    reference = image[y0:y1, x0:x1]
    overlay = reference.copy()
    predicted = np.zeros(mask.shape, np.uint8)
    for edge in edges:
        a, b = [tuple(np.rint(np.asarray(vertices[i]['xy_image_px']) -
                                  [x0, y0]).astype(int)) for i in edge['vertex_ids']]
        cv2.line(predicted, a, b, 255, 1)
        cv2.line(overlay, a, b, (0, 220, 255), 1, cv2.LINE_AA)
    for vertex in vertices:
        point = tuple(np.rint(np.asarray(vertex['xy_image_px']) -
                               [x0, y0]).astype(int))
        cv2.circle(overlay, point, 2, (210, 0, 255), -1)
    accepted = cv2.dilate(mask.astype(np.uint8), np.ones((7, 7), np.uint8))
    registered = predicted > 0
    pixel_support = float(np.count_nonzero(registered & (accepted > 0)) /
                          max(1, np.count_nonzero(registered)))
    coverage = float(np.count_nonzero(cv2.dilate(predicted, np.ones((5, 5), np.uint8))
                                      & mask.astype(np.uint8)) /
                     max(1, np.count_nonzero(mask)))
    difference = cv2.cvtColor(cv2.cvtColor(reference, cv2.COLOR_BGR2GRAY),
                              cv2.COLOR_GRAY2BGR)
    difference[mask.astype(bool)] = (100, 140, 55)
    difference[registered] = (0, 225, 255)
    difference[registered & (accepted == 0)] = (0, 0, 240)
    comparison = np.concatenate([reference, overlay, difference], axis=1)
    return overlay, comparison, {'2d_predicted_edge_support_3px': pixel_support,
                                  '2d_observed_stroke_coverage_2px': coverage}


def write_image_plane_obj(path, vertices, faces, size):
    """Planar OBJ for visualizing candidate topology ONLY: all heights zero."""
    width, height = size
    with Path(path).open('w', encoding='utf8') as stream:
        stream.write('# IMAGE-PLANE ONLY, Y=0, NOT recovered 3D terrain\n')
        for vertex in vertices:
            x, y = vertex['xy_image_px']
            stream.write(f'v {x / width * 1000:.5f} 0 {(height - y) / height * 1000:.5f}\n')
        for face in faces:
            stream.write('f ' + ' '.join(str(v + 1) for v in face['vertex_ids']) + '\n')


def run(image_path, output, roi=None, v3_report=None, plane_anchors=None):
    image_path = Path(image_path)
    raw = image_path.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    image = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError('Invalid source raster')
    height, width = image.shape[:2]
    if roi is None:
        roi = (0, 0, width, height)
    x0, y0, x1, y1 = roi
    if not (0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height):
        raise ValueError('Invalid ROI')
    if v3_report:
        observed = json.loads(Path(v3_report).read_text(encoding='utf8'))
        if observed['source_sha256'] != sha:
            raise ValueError('Source image hash differs from cached V3 report')
        if observed.get('roi_xyxy_px', observed.get('roi_xyxy')) != list(roi):
            raise ValueError('ROI differs from cached V3 report')
    else:
        from .extract_wireframe import analyze
        observed, _ = analyze(raw, roi)
    gray = cv2.cvtColor(image[y0:y1, x0:x1], cv2.COLOR_BGR2GRAY)
    local = cv2.medianBlur(gray, 11).astype(np.int16)
    params = observed['parameters']
    dark = ((local - gray.astype(np.int16) >= int(params['contrast'])) &
            (local >= int(params['min_background'])))
    n, labels, stats, _ = cv2.connectedComponentsWithStats(dark.astype(np.uint8), 8)
    keep = np.zeros(n, dtype=bool)
    keep[1:] = stats[1:, cv2.CC_STAT_AREA] >= 3
    stroke = keep[labels]
    faces_input = observed.get('faces', observed.get('closed_cell_candidates', []))
    vertices, edges, faces, topology = graph_from_candidates(
        faces_input, stroke, (width, height), roi)
    line_vertices, line_edges, line_info = segment_graph_from_observations(
        observed.get('junctions_px', observed.get('junction_candidates_px', [])),
        observed.get('segments', observed.get('line_segments', [])), stroke, roi)
    anchor_data = json.loads(Path(plane_anchors).read_text(encoding='utf8')) if plane_anchors else None
    camera = estimate_plane_registration(anchor_data)
    overlay, comparison, pixel_info = compare_image_edges(
        image, stroke, roi, vertices, edges)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    segment_overlay = image[y0:y1, x0:x1].copy()
    for item in line_edges:
        a, b = [tuple(np.rint(np.asarray(line_vertices[i]['xy_image_px']) -
                                  [x0, y0]).astype(int)) for i in item['vertex_ids']]
        cv2.line(segment_overlay, a, b, (0, 180, 255), 1, cv2.LINE_AA)
    cv2.imwrite(str(output / 'observed_segment_graph_overlay.png'), segment_overlay)
    for name, value in [('vertices.json', vertices), ('edges.json', edges),
                        ('faces.json', faces), ('camera.json', camera),
                        ('segment_graph.json', {'vertices': line_vertices, 'edges': line_edges})]:
        (output / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf8')
    cv2.imwrite(str(output / 'topology_overlay.png'), overlay)
    cv2.imwrite(str(output / 'image_vs_topology_comparison.png'), comparison)
    write_image_plane_obj(output / 'screen_space_face_candidates.obj',
                          vertices, faces, (width, height))
    summary = {
        'source_sha256': sha, 'source_image': image_path.name,
        'source_size_px': [width, height], 'roi_xyxy_px': list(roi),
        'topology': topology, 'segment_graph': line_info,
        'image_space_evaluation': pixel_info, 'camera_status': camera['status'],
        '3d_status': 'NOT_RECONSTRUCTED',
        'limitations': [
            'OBJ is a flat image-plane representation. All Y heights are zero.',
            'Closed 2D regions can be false faces caused by trees, rocks and roads.',
            'An AI-generated wireframe may lack consistent 3D connectivity.',
            '3D camera calibration and absolute depth require additional trusted control points.',
            'The edge overlay compares 2D observations, not 3D terrain reprojection.',
            'The procedural island generator is not imported or used.'
        ]
    }
    (output / 'topology_report.json').write_text(
        json.dumps(summary, indent=2) + '\n', encoding='utf8')
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=Path('topology-v4-output'))
    parser.add_argument('--roi', nargs=4, type=int)
    parser.add_argument('--v3-report', type=Path)
    parser.add_argument('--plane-anchors', type=Path)
    args = parser.parse_args()
    print(json.dumps(run(args.image, args.output,
                         tuple(args.roi) if args.roi else None,
                         args.v3_report, args.plane_anchors), indent=2))


if __name__ == '__main__':
    main()
