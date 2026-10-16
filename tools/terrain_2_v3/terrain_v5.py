"""V5 experiments: feature-adaptive triangulation, relative water scenarios and view gates.

All elevations and bathymetry remain relative. A successful export is not a
fidelity or Roblox acceptance result; the report keeps those gates explicit.
"""
import argparse
import json
from pathlib import Path

import cv2
import numpy as np
from scipy.spatial import Delaunay
from scipy.ndimage import distance_transform_edt, gaussian_filter

from .isometric_v3 import _project_skyline, observed_skyline, silhouette_fit
from .river_v3 import model_river
from .terrain_v3 import observed_profiles, predict_profile, read_image


def extract_side_render_skyline(image, bins=112):
    """Extract the terrain/sky edge from the low-angle reference render.

    This image has a low-saturation sky, so the generic wireframe foreground
    threshold mistakes the sky for terrain. Use the top border as a local sky
    color reference, then retain low-saturation, brighter terrain pixels.
    """
    if image is None or image.ndim != 3 or image.shape[2] != 3:
        raise ValueError("Expected a color side-render image")
    h, w = image.shape[:2]
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    sky_roi = image[int(.02*h):int(.18*h), int(.05*w):int(.95*w)]
    sky_bgr = np.median(sky_roi.reshape(-1, 3), axis=0)
    distance = np.linalg.norm(image.astype(np.float32) - sky_bgr, axis=2)
    rows = np.arange(h)[:, None]
    mask = ((distance > 14.) & (hsv[:, :, 1] < 95) & (hsv[:, :, 2] > 55) &
            (rows > .20*h) & (rows < .75*h))
    mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE,
                            np.ones((5, 5), np.uint8)) > 0
    skyline = np.full(w, np.nan, dtype=np.float32)
    margin = max(1, int(.02*w))
    for x in range(margin, w-margin):
        candidates = np.flatnonzero(mask[:, x])
        if candidates.size:
            skyline[x] = candidates[0]
    good = np.flatnonzero(np.isfinite(skyline))
    if good.size < int(.80*w):
        raise ValueError("Unreliable side-render skyline segmentation")
    skyline = np.interp(np.arange(w), good, skyline[good])
    skyline = np.interp(np.linspace(0, w-1, bins), np.arange(w), skyline)
    metadata = {
        "method": "top-border sky color distance >14 BGR; saturation <95; value >55",
        "valid_columns_fraction": float(good.size / w),
        "sky_reference_bgr": sky_bgr.round(2).tolist(),
        "not_metric_camera_calibration": True,
    }
    return skyline.astype(np.float32), metadata


def side_render_silhouette_fit(image, field, land, bins=112):
    """Fit a projected terrain skyline to the independently segmented side render."""
    skyline, segmentation = extract_side_render_skyline(image, bins)
    observed = (skyline - skyline.mean()) / max(1., float(skyline.std()))
    best = None
    for yaw in np.linspace(-82, 82, 17):
        for pitch in (.22, .42, .62):
            for height_scale in (.6, 1.3, 2.2):
                candidate = _project_skyline(field, land, yaw, pitch,
                                            height_scale, bins)
                if not np.isfinite(candidate).all():
                    continue
                candidate = (candidate-candidate.mean()) / max(.00001, candidate.std())
                residual = float(np.sqrt(np.mean((observed-candidate)**2)))
                if best is None or residual < best["normalized_rmse"]:
                    best = {"normalized_rmse": residual,
                            "yaw_degrees": float(yaw),
                            "pitch_relative": float(pitch),
                            "vertical_scale_relative": float(height_scale),
                            "observed": observed, "predicted": candidate}
    if best is None:
        raise ValueError("Cannot evaluate side-render skyline")
    best["segmentation"] = segmentation
    return best


def extract_atlas_isometric_skyline(image, bins=112):
    """Extract the right-hand isometric panel from the orthographic atlas.

    The left-hand atlas panel is a plan view and is deliberately excluded from
    skyline scoring. This crop uses the separately rendered isometric panel.
    """
    if image is None or image.ndim != 3 or image.shape[2] != 3:
        raise ValueError("Expected a color orthographic atlas image")
    h, w = image.shape[:2]
    x0, x1 = int(round(.565*w)), int(round(.938*w))
    y0, y1 = int(round(.026*h)), int(round(.579*h))
    crop = image[y0:y1, x0:x1]
    ch, cw = crop.shape[:2]
    hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    rows = np.arange(ch)[:, None]
    mask = ((hsv[:, :, 1] < 100) & (hsv[:, :, 2] > 85) &
            (hsv[:, :, 2] < 220) & (rows < .78*ch))
    # The panel title sits above the far-right terrain. A left-edge drafting
    # guide is cleared before interpolation; blue guide lines elsewhere fail
    # the low-saturation terrain test.
    mask[:int(.12*ch), int(.80*cw):] = False
    mask[:, :int(.02*cw)] = False
    skyline = np.full(cw, np.nan, dtype=np.float32)
    for col in range(cw):
        y = np.flatnonzero(mask[:, col])
        if y.size:
            skyline[col] = y[0]
    good = np.flatnonzero(np.isfinite(skyline))
    if good.size < int(.80*cw):
        raise ValueError("Unreliable isometric-atlas skyline segmentation")
    skyline = np.interp(np.arange(cw), good, skyline[good])
    skyline = np.interp(np.linspace(0, cw-1, bins), np.arange(cw), skyline)
    metadata = {
        "panel": "right-hand isometric view; top-left plan view excluded",
        "crop_rect_px_xyxy": [x0, y0, x1, y1],
        "method": "low-saturation gray terrain; value 85..219; title and left-edge guide excluded",
        "valid_columns_fraction": float(good.size/cw),
        "excluded_left_guide_columns": int(.02*cw),
        "not_metric_camera_calibration": True,
    }
    return skyline.astype(np.float32), metadata


def atlas_isometric_silhouette_fit(image, field, land, bins=112):
    skyline, segmentation = extract_atlas_isometric_skyline(image, bins)
    observed = (skyline - skyline.mean()) / max(1., float(skyline.std()))
    best = None
    for yaw in np.linspace(-82, 82, 17):
        for pitch in (.22, .42, .62):
            for height_scale in (.6, 1.3, 2.2):
                candidate = _project_skyline(field, land, yaw, pitch,
                                             height_scale, bins)
                if not np.isfinite(candidate).all():
                    continue
                candidate = (candidate-candidate.mean()) / max(.00001, candidate.std())
                residual = float(np.sqrt(np.mean((observed-candidate)**2)))
                if best is None or residual < best["normalized_rmse"]:
                    best = {"normalized_rmse": residual,
                            "yaw_degrees": float(yaw),
                            "pitch_relative": float(pitch),
                            "vertical_scale_relative": float(height_scale),
                            "observed": observed, "predicted": candidate}
    if best is None:
        raise ValueError("Cannot evaluate isometric-atlas skyline")
    best["segmentation"] = segmentation
    return best


def fixed_projection_silhouette_fit(image, field, land, camera, side_render=False,
                                    atlas_isometric=False, bins=112):
    """Compare a candidate under a camera fit once on the V4 baseline.

    Re-optimizing yaw/pitch/height for every candidate can hide geometry
    changes behind camera changes. V5 therefore fixes each reference's
    best-fit relative projection to the V4 field before candidate selection.
    These values remain image-relative and are not metric camera calibration.
    """
    if atlas_isometric:
        skyline, segmentation = extract_atlas_isometric_skyline(image, bins)
    elif side_render:
        skyline, segmentation = extract_side_render_skyline(image, bins)
    else:
        skyline = observed_skyline(image, bins)
        segmentation = None
    observed = (skyline - skyline.mean()) / max(1., float(skyline.std()))
    candidate = _project_skyline(
        field, land, camera["yaw_degrees"], camera["pitch_relative"],
        camera["vertical_scale_relative"], bins)
    if not np.isfinite(candidate).all():
        raise ValueError("Fixed projection produced an incomplete skyline")
    candidate = (candidate - candidate.mean()) / max(.00001, float(candidate.std()))
    result = {"normalized_rmse": float(np.sqrt(np.mean((observed-candidate)**2))),
              "camera": dict(camera),
              "observed": observed,
              "predicted": candidate,
              "not_metric_camera_calibration": True}
    if segmentation is not None:
        result["segmentation"] = segmentation
    return result


def profile_scores(field, profiles):
    values = {}
    for view in ("front", "back", "left", "right"):
        observed = np.asarray(profiles["profiles"][view]["apparent_height_px"], float)
        predicted = predict_profile(field, view)
        values[view] = float(np.sqrt(np.mean((predicted - observed) ** 2)))
    return values


def restore_profile_peaks(field, envelope, land, rock_weight, target_x, target_y,
                          spread=4., rounds=4):
    """Restore orthographic maxima locally after source-weighted relief blending.

    The envelope is a hard upper bound. Deficits are added near source rock
    evidence, so profile constraints do not flatten the entire terrain toward
    the envelope. Opposing view conflicts remain visible in the resulting
    per-view scores; this does not claim a unique reconstruction.
    """
    if spread <= 0 or rounds < 1:
        raise ValueError("Profile restoration needs positive spread and rounds")
    f = np.asarray(field, dtype=np.float32).copy()
    if any(array.shape != f.shape for array in
           (envelope, land, rock_weight)):
        raise ValueError("Profile restoration arrays must match the field")
    if len(target_x) != f.shape[1] or len(target_y) != f.shape[0]:
        raise ValueError("Profile targets must match field axes")

    for _ in range(rounds):
        # Column maxima encode the front/back source profiles.
        for col in range(f.shape[1]):
            line_land = land[:, col]
            if not line_land.any():
                continue
            missing = float(target_x[col] - np.max(f[line_land, col]))
            if missing <= .05:
                continue
            eligible = line_land & (envelope[:, col] > f[:, col] + .1)
            if not eligible.any():
                continue
            distance = distance_transform_edt(line_land)
            scores = rock_weight[:, col] ** 2.3 * distance
            center = int(np.argmax(np.where(eligible, scores, -1.)))
            radius = int(3 * spread)
            rows = np.arange(max(0, center-radius),
                             min(f.shape[0], center+radius+1))
            bump = missing * np.exp(-.5 * ((rows-center)/spread)**2)
            f[rows, col] = np.maximum(f[rows, col], f[center, col] + bump)

        # Row maxima encode the left/right source profiles.
        for row in range(f.shape[0]):
            line_land = land[row, :]
            if not line_land.any():
                continue
            missing = float(target_y[row] - np.max(f[row, line_land]))
            if missing <= .05:
                continue
            eligible = line_land & (envelope[row, :] > f[row, :] + .1)
            if not eligible.any():
                continue
            distance = distance_transform_edt(line_land)
            scores = rock_weight[row, :] ** 2.3 * distance
            center = int(np.argmax(np.where(eligible, scores, -1.)))
            radius = int(3 * spread)
            cols = np.arange(max(0, center-radius),
                             min(f.shape[1], center+radius+1))
            bump = missing * np.exp(-.5 * ((cols-center)/spread)**2)
            f[row, cols] = np.maximum(f[row, cols], f[row, center] + bump)

        f = np.minimum(f, envelope)
        f = np.where(land, f, 0.)
    return f


def opposing_profile_conflicts(profiles):
    values = {}
    for first, second in (("front", "back"), ("left", "right")):
        a = np.asarray(profiles["profiles"][first]["apparent_height_px"], float)
        b = np.asarray(profiles["profiles"][second]["apparent_height_px"], float)[::-1]
        if a.shape != b.shape:
            raise ValueError("Opposing orthographic profiles have different sample counts")
        values[f"{first}_{second}"] = {
            "opposing_view_disagreement_rmse_px_equivalent": float(np.sqrt(np.mean((a-b)**2))),
            "best_possible_equal_profile_rmse_floor": float(np.sqrt(np.mean(((a-b)/2)**2))),
            "interpretation": "irreducible if both views are treated as one orthographic 2.5D projection",
        }
    return values


def detect_source_scale_bar(image, label_units=500., label_verified=False):
    """Read the rendered scale-bar pixels; unit label is verified by visual review."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    roi = gray[:int(h * .20), int(w * .62):]
    counts = (roi >= 190).sum(axis=1)
    y = int(np.argmax(counts))
    xs = np.flatnonzero(roi[y] >= 190)
    if len(xs) < 30:
        raise ValueError("Could not locate source scale bar")
    groups = np.split(xs, np.where(np.diff(xs) > 2)[0] + 1)
    segment = max(groups, key=len)
    pixels = int(segment[-1] - segment[0] + 1)
    if not 80 <= pixels <= 700:
        raise ValueError("Source scale-bar segment outside expected bounds")
    return {"bar_pixels": pixels, "bar_label_source_units": float(label_units),
            "source_pixels_per_unit": float(pixels / label_units),
            "unit_label_visually_confirmed": bool(label_verified),
            "physical_or_Roblox_scale_confirmed": False}


def classify_regions(field, land, water, rock_likelihood):
    """Create explicit, inspectable source-derived region hypotheses."""
    field = field.astype(np.float32)
    valid = land & ~water
    smoothed = gaussian_filter(field, 1.5, mode="nearest")
    gy, gx = np.gradient(smoothed)
    slope = np.hypot(gx, gy)
    valid_height = field[valid]
    valid_rock = rock_likelihood[valid]
    valid_slope = slope[valid]
    shore_dist = cv2.distanceTransform(land.astype(np.uint8), cv2.DIST_L2, 5)
    rows, cols = np.indices(field.shape)
    mid = (field.shape[1] - 1) / 2
    interior = valid & (shore_dist > 6.)
    interior_rock = rock_likelihood[interior]
    ridge_cut = float(np.percentile(interior_rock, 82)) \
        if interior_rock.size else 1.
    rock_cut = float(np.percentile(valid_rock, 65)) if valid_rock.size else 1.
    plain_rock_cut = float(np.percentile(valid_rock, 55)) \
        if valid_rock.size else 0.
    high_cut = float(np.percentile(valid_height, 80)) \
        if valid_height.size else 0.
    plateau_cut = float(np.percentile(valid_height, 85)) \
        if valid_height.size else 0.
    cliff_slope_cut = float(np.percentile(valid_slope, 90)) \
        if valid_slope.size else 0.
    plateau_slope_cut = float(np.percentile(valid_slope, 85)) \
        if valid_slope.size else 0.
    plain_slope_cut = float(np.percentile(valid_slope, 75)) \
        if valid_slope.size else 0.
    highland = interior & (rock_likelihood >= ridge_cut)
    cliffs = (valid & (shore_dist > 3.5) & (slope >= cliff_slope_cut)
              & (rock_likelihood >= rock_cut) & ~highland)
    plateau = (valid & (shore_dist > 6.) & (field >= plateau_cut)
               & (slope <= plateau_slope_cut)
               & (rock_likelihood <= float(np.percentile(valid_rock, 75))
                  if valid_rock.size else False)
               & ~highland & ~cliffs)
    central_plain = (valid & (shore_dist > 3.5)
                     & (np.abs(cols-mid) <= field.shape[1]*.15)
                     & (field <= high_cut) & (slope <= plain_slope_cut)
                     & (rock_likelihood <= plain_rock_cut)
                     & ~highland & ~cliffs & ~plateau)
    features = {
        "west_mountain_hypothesis": highland & (cols < mid),
        "east_mountain_hypothesis": highland & (cols >= mid),
        "cliff_hypothesis": cliffs,
        "plateau_hypothesis": plateau,
        "central_plain_hypothesis": central_plain,
        "beach_hypothesis": land & (shore_dist <= 3.5),
    }
    details = {name: {"grid_cells": int(mask.sum()),
                      "fraction_of_land": float(mask.sum() / max(1, land.sum())),
                      "source": "heuristic from V2 land/rock evidence and V5 relative relief",
                      "physical_classification": False}
               for name, mask in features.items()}
    return features, details


def feature_adaptive_mesh(field, land, water, coarse_step=8, fine_step=2,
                          semantic_features=None):
    """Triangulate a heightfield densely near curvature and observed feature edges."""
    if field.ndim != 2 or field.shape[0] != field.shape[1]:
        raise ValueError("V5 requires a square heightfield")
    if land.shape != field.shape or water.shape != field.shape:
        raise ValueError("V5 masks must match the heightfield")
    f = field.astype(np.float32)
    gy, gx = np.gradient(f)
    lap = cv2.Laplacian(f, cv2.CV_32F, ksize=3)
    complexity = np.abs(lap) + .35 * np.hypot(gx, gy)
    candidates = complexity[land & np.isfinite(complexity)]
    threshold = float(np.percentile(candidates, 72)) if candidates.size else 0.
    complex_area = land & (complexity >= threshold)
    land_edge = land ^ np.roll(land, 1, axis=0)
    land_edge |= land ^ np.roll(land, 1, axis=1)
    water_edge = water ^ np.roll(water, 1, axis=0)
    water_edge |= water ^ np.roll(water, 1, axis=1)
    feature_edge = cv2.dilate((land_edge | water_edge).astype(np.uint8),
                              np.ones((3, 3), np.uint8)) > 0
    semantic_edge = np.zeros_like(land)
    for mask in (semantic_features or {}).values():
        semantic_edge |= mask ^ np.roll(mask, 1, axis=0)
        semantic_edge |= mask ^ np.roll(mask, 1, axis=1)
    semantic_edge = cv2.dilate(semantic_edge.astype(np.uint8),
                               np.ones((3, 3), np.uint8)) > 0
    dense = complex_area | feature_edge | semantic_edge
    rows, cols = np.mgrid[0:f.shape[0], 0:f.shape[1]]
    coarse = ((rows % coarse_step == 0) & (cols % coarse_step == 0))
    fine = ((rows % fine_step == 0) & (cols % fine_step == 0) & dense)
    selected = (coarse | fine) & land & ~water
    selected[[0, -1], :] = True
    selected[:, [0, -1]] = True
    selected &= land & ~water
    points = np.column_stack((rows[selected], cols[selected])).astype(np.int32)
    # Preserve the complete source-grid shoreline and channel boundaries.
    boundary_points = (feature_edge | semantic_edge) & land & ~water
    edge_points = np.column_stack(np.where(boundary_points)).astype(np.int32)
    points = np.unique(np.vstack((points, edge_points)), axis=0)
    target_rows, target_cols = np.where(land & ~water)
    target_points = np.column_stack((target_rows, target_cols))
    query_xy = target_points[:, ::-1].astype(np.float64)
    mesh_error_tolerance = 2.0  # relative height units, not studs or meters
    max_refinement_rounds = 6
    added_vertices = 0
    refinement_rounds = 0

    def triangulate_and_filter(vertex_points):
        triangulation = Delaunay(vertex_points[:, ::-1].astype(np.float64))
        raw_faces = triangulation.simplices.astype(np.int32)
        centroids = np.rint(vertex_points[raw_faces].mean(axis=1)).astype(int)
        valid_faces = (land[centroids[:, 0], centroids[:, 1]] &
                       ~water[centroids[:, 0], centroids[:, 1]])
        valid_faces &= land[vertex_points[raw_faces, 0],
                            vertex_points[raw_faces, 1]].all(axis=1)
        valid_faces &= ~water[vertex_points[raw_faces, 0],
                              vertex_points[raw_faces, 1]].any(axis=1)
        return triangulation, raw_faces[valid_faces], valid_faces

    def interpolate_targets(triangulation, valid_faces, vertex_points):
        from matplotlib.tri import LinearTriInterpolator, Triangulation

        mesh_triangles = triangulation.simplices[valid_faces]
        mesh = Triangulation(
            vertex_points[:, 1].astype(np.float64),
            vertex_points[:, 0].astype(np.float64),
            triangles=mesh_triangles)
        interpolator = LinearTriInterpolator(
            mesh, field[vertex_points[:, 0], vertex_points[:, 1]])
        predicted = np.asarray(interpolator(
            query_xy[:, 0], query_xy[:, 1]).filled(np.nan), dtype=np.float32)
        covered = np.isfinite(predicted)
        errors = np.full(len(query_xy), np.nan, dtype=np.float32)
        errors[covered] = np.abs(
            predicted[covered] - field[target_rows[covered], target_cols[covered]])
        return covered, errors

    for iteration in range(max_refinement_rounds + 1):
        triangulation, faces, valid_faces = triangulate_and_filter(points)
        covered, interpolation_errors = interpolate_targets(
            triangulation, valid_faces, points)
        refine = (~covered) | (interpolation_errors > mesh_error_tolerance)
        if not refine.any() or iteration == max_refinement_rounds:
            break
        refine_points = target_points[refine]
        point_keys = points[:, 0] * field.shape[1] + points[:, 1]
        refine_keys = refine_points[:, 0] * field.shape[1] + refine_points[:, 1]
        refine_points = refine_points[~np.isin(refine_keys, point_keys)]
        if not len(refine_points):
            break
        updated_points = np.unique(np.vstack((points, refine_points)), axis=0)
        added_vertices += len(updated_points) - len(points)
        points = updated_points
        refinement_rounds += 1

    # Rebuild after the final point update so exported faces and reported error
    # metrics refer to the same exact mesh.
    triangulation, faces, valid_faces = triangulate_and_filter(points)
    covered, interpolation_errors = interpolate_targets(
        triangulation, valid_faces, points)
    if not len(faces):
        raise ValueError("Adaptive V5 triangulation produced no land faces")
    sampled_heights = f[points[:, 0], points[:, 1]]
    if not np.isfinite(sampled_heights).all():
        raise ValueError("Non-finite adaptive mesh vertices")
    return points, sampled_heights, faces, {
        "grid_resolution": list(f.shape),
        "vertices": int(len(points)),
        "triangles": int(len(faces)),
        "triangles_retained_on_land": int(len(faces)),
        "uniform_grid_vertices": int(f.size),
        "vertex_reduction_fraction": float(1 - len(points) / f.size),
        "dense_feature_grid_fraction": float(dense.mean()),
        "curvature_threshold_relative": threshold,
        "feature_edge_vertices": int(len(edge_points)),
        "semantic_feature_boundary_vertices": int(semantic_edge.sum()),
        "mesh_interpolation_refinement_rounds": refinement_rounds,
        "mesh_interpolation_vertices_added": added_vertices,
        "mesh_interpolation_error_tolerance_relative": mesh_error_tolerance,
        "mesh_interpolation_sample_columns": int(covered.sum()),
        "mesh_interpolation_uncovered_land_columns": int((~covered).sum()),
        "mesh_interpolation_rmse_relative": float(
            np.sqrt(np.mean(interpolation_errors[covered] ** 2))),
        "mesh_interpolation_max_error_relative": float(
            np.max(interpolation_errors[covered])),
        "mesh_interpolation_error_semantics":
            "piecewise-linear mesh versus source field at covered land-grid samples; relative units, not physical scale",
        "method": "Delaunay over coarse grid plus dense curvature/coast/water-edge samples, iteratively inserting covered land samples with interpolation error above two relative height units",
        "physical_scale": False,
    }


def write_adaptive_obj(path, points, heights, faces, cell_size=4., grid_size=None):
    path = Path(path)
    with path.open("w", encoding="utf-8", newline="\n") as out:
        out.write("# Terrain 2 V5 relative adaptive mesh; not surveyed geometry.\n")
        n = int(grid_size or (points[:, 0].max() + 1))
        for (row, col), height in zip(points, heights):
            out.write(f"v {col*cell_size:.4f} {height:.4f} {(n-1-row)*cell_size:.4f}\n")
        # Delaunay's XY winding is converted to the OBJ X/Z convention.
        for a, b, c in faces + 1:
            out.write(f"f {a} {c} {b}\n")


def write_previews(output, source_top, land, features, points, faces):
    h, w = source_top.shape[:2]
    preview_w, preview_h = 900, max(1, int(round(900 * h / w)))
    top = cv2.resize(source_top, (preview_w, preview_h))
    overlay = top.copy()
    palette = {
        "west_mountain_hypothesis": (50, 60, 230),
        "east_mountain_hypothesis": (40, 180, 240),
        "cliff_hypothesis": (220, 40, 220),
        "plateau_hypothesis": (30, 190, 90),
        "central_plain_hypothesis": (240, 190, 40),
        "beach_hypothesis": (0, 230, 255),
    }
    for name, mask in features.items():
        resized = cv2.resize(mask.astype(np.uint8), (preview_w, preview_h),
                             interpolation=cv2.INTER_NEAREST) > 0
        color = np.asarray(palette[name], dtype=np.uint8)
        overlay[resized] = ((.55 * overlay[resized] + .45 * color).astype(np.uint8))
    if not cv2.imwrite(str(output / "terrain_regions_v5.png"), overlay):
        raise OSError("Failed to write V5 region preview")

    mesh = np.zeros((preview_h, preview_w, 3), dtype=np.uint8)
    land_small = cv2.resize(land.astype(np.uint8), (preview_w, preview_h),
                            interpolation=cv2.INTER_NEAREST)
    mesh[land_small > 0] = (60, 85, 70)
    n = land.shape[0]
    scale_x = (preview_w - 1) / (n - 1)
    scale_y = (preview_h - 1) / (n - 1)
    # Draw each unique mesh edge once, preserving the actual adaptive topology.
    edges = np.vstack((faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]))
    edges = np.unique(np.sort(edges, axis=1), axis=0)
    for a, b in edges:
        ra, ca = points[a]
        rb, cb = points[b]
        pa = (int(round(ca * scale_x)), int(round(ra * scale_y)))
        pb = (int(round(cb * scale_x)), int(round(rb * scale_y)))
        cv2.line(mesh, pa, pb, (190, 205, 185), 1, cv2.LINE_AA)
    cv2.putText(mesh, "V5 adaptive triangulation (relative relief)", (18, 34),
                cv2.FONT_HERSHEY_SIMPLEX, .8, (255, 255, 255), 2, cv2.LINE_AA)
    if not cv2.imwrite(str(output / "adaptive_mesh_preview_v5.png"), mesh):
        raise OSError("Failed to write V5 adaptive mesh preview")


def write_view_comparisons(output, base, candidate, profiles, images, land,
                           cameras):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(2, 2, figsize=(13, 7), constrained_layout=True)
    for ax, view in zip(axes.ravel(), ("front", "back", "left", "right")):
        obs = np.asarray(profiles["profiles"][view]["apparent_height_px"], float)
        x = np.linspace(0, 1, len(obs))
        ax.plot(x, obs, color="#222", label="Referência")
        ax.plot(x, predict_profile(base, view), color="#e28b31", label="V4")
        ax.plot(x, predict_profile(candidate, view), color="#277da1", linestyle="--", label="V5")
        ax.set_title(view.title() + " — perfil pixel-equivalente")
        ax.set_xlabel("posição normalizada")
        ax.set_ylabel("altura relativa")
        ax.legend(fontsize=8)
    fig.savefig(output / "multiview_comparison_v5.png", dpi=145)
    plt.close(fig)

    fig, axes = plt.subplots(2, 1, figsize=(10, 6), constrained_layout=True)
    for ax, name, role in ((axes[0], "oblique_wireframe_1.jpg", "ajuste"),
                           (axes[1], "oblique_wireframe_2.jpg", "holdout independente")):
        old = fixed_projection_silhouette_fit(
            images[name], base, land, cameras[name])
        new = fixed_projection_silhouette_fit(
            images[name], candidate, land, cameras[name])
        ax.plot(old["observed"], color="#222", label="Referência normalizada")
        ax.plot(old["predicted"], color="#e28b31", label="V4")
        ax.plot(new["predicted"], color="#277da1", linestyle="--", label="V5")
        ax.set_title(f"{name} — {role}; V4 {old['normalized_rmse']:.3f}, V5 {new['normalized_rmse']:.3f}")
        ax.set_xlabel("posição relativa")
        ax.set_ylabel("silhueta sem escala física")
        ax.legend(fontsize=8)
    fig.savefig(output / "isometric_comparison_v5.png", dpi=145)
    plt.close(fig)


def write_side_render_training_comparison(output, image, base, candidate, land,
                                          camera):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    skyline, _ = extract_side_render_skyline(image)
    old = fixed_projection_silhouette_fit(
        image, base, land, camera, side_render=True)
    new = fixed_projection_silhouette_fit(
        image, candidate, land, camera, side_render=True)
    overlay = image.copy()
    x = np.linspace(0, image.shape[1] - 1, len(skyline)).round().astype(int)
    y = skyline.round().astype(int)
    cv2.polylines(overlay, [np.column_stack((x, y)).reshape(-1, 1, 2)],
                  False, (0, 0, 255), 3, cv2.LINE_AA)

    fig, axes = plt.subplots(1, 2, figsize=(13, 5), constrained_layout=True)
    axes[0].imshow(cv2.cvtColor(overlay, cv2.COLOR_BGR2RGB))
    axes[0].set_title("oblique_side_render.jpg — contorno extraído para ajuste")
    axes[0].axis("off")
    axes[1].plot(old["observed"], color="#222", label="Referência")
    axes[1].plot(old["predicted"], color="#e28b31", label="V4")
    axes[1].plot(new["predicted"], color="#277da1", linestyle="--", label="V5")
    axes[1].set_title(f"V4 {old['normalized_rmse']:.3f}; V5 {new['normalized_rmse']:.3f}")
    axes[1].set_xlabel("posição relativa")
    axes[1].set_ylabel("silhueta normalizada sem escala")
    axes[1].legend(fontsize=8)
    fig.savefig(output / "side_render_training_v5.png", dpi=145)
    plt.close(fig)


def write_atlas_isometric_holdout_comparison(output, image, base, candidate,
                                             land, camera, old_score,
                                             new_score):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    skyline, segmentation = extract_atlas_isometric_skyline(image)
    x0, y0, x1, y1 = segmentation["crop_rect_px_xyxy"]
    crop = image[y0:y1, x0:x1].copy()
    x = np.linspace(0, crop.shape[1] - 1, len(skyline)).round().astype(int)
    y = skyline.round().astype(int)
    cv2.polylines(crop, [np.column_stack((x, y)).reshape(-1, 1, 2)],
                  False, (0, 0, 255), 3, cv2.LINE_AA)
    old = fixed_projection_silhouette_fit(
        image, base, land, camera, atlas_isometric=True)
    new = fixed_projection_silhouette_fit(
        image, candidate, land, camera, atlas_isometric=True)
    fig, axes = plt.subplots(1, 2, figsize=(13, 5), constrained_layout=True)
    axes[0].imshow(cv2.cvtColor(crop, cv2.COLOR_BGR2RGB))
    axes[0].set_title("Atlas — painel isométrico direito; contorno extraído")
    axes[0].axis("off")
    skyline_norm = (skyline-skyline.mean()) / max(1., float(skyline.std()))
    axes[1].plot(skyline_norm, color="#222", label="Referência")
    axes[1].plot(old["predicted"], color="#e28b31", label="V4")
    axes[1].plot(new["predicted"], color="#277da1", linestyle="--", label="V5")
    axes[1].set_title(f"V4 {old_score:.3f}; V5 {new_score:.3f} — holdout adicional")
    axes[1].set_xlabel("posição relativa")
    axes[1].set_ylabel("silhueta normalizada sem escala")
    axes[1].legend(fontsize=8)
    fig.savefig(output / "atlas_isometric_holdout_v5.png", dpi=145)
    plt.close(fig)


def _image_metrics(images, field, land, cameras):
    return {name: float(fixed_projection_silhouette_fit(
                images[name], field, land, cameras[name])["normalized_rmse"])
            for name in ("oblique_wireframe_1.jpg", "oblique_wireframe_2.jpg")}


def run(sources, v2_dir, v3_dir, v4_dir, output):
    sources, v2_dir, v3_dir, v4_dir, output = map(
        Path, (sources, v2_dir, v3_dir, v4_dir, output))
    output.mkdir(parents=True, exist_ok=True)
    v4_report = json.loads((v4_dir / "final_report_v4.json").read_text())
    images = {}
    for name, expected in v4_report["source_sha256"].items():
        images[name], actual = read_image(sources / name)
        if actual != expected:
            raise ValueError("V5 source SHA-256 mismatch: " + name)
    atlas_key = "orthographic_atlas.jpg"
    images[atlas_key], atlas_hash = read_image(sources / atlas_key)
    base = np.load(v4_dir / "height_refined_v4.npy").astype(np.float32)
    if not np.isfinite(base).all():
        raise ValueError("Non-finite V4 heightfield")
    land_img = cv2.imread(str(v2_dir / "land_all_components.png"), cv2.IMREAD_GRAYSCALE)
    water_img = cv2.imread(str(v4_dir / "river_ocean_join_v4.png"), cv2.IMREAD_GRAYSCALE)
    if land_img is None or water_img is None:
        raise ValueError("V5 requires V2 land and V4 water masks")
    land = cv2.resize((land_img > 0).astype(np.uint8), base.shape[::-1],
                      interpolation=cv2.INTER_NEAREST) > 0
    water = water_img > 0
    rock_img = cv2.imread(str(v2_dir / "rock_likelihood.png"), cv2.IMREAD_GRAYSCALE)
    if rock_img is None:
        raise ValueError("V5 requires V2 rock likelihood")
    rock_likelihood = cv2.resize(rock_img.astype(np.float32) / 255., base.shape[::-1],
                                 interpolation=cv2.INTER_AREA)
    profiles = json.loads((v2_dir / "orthographic_profile_constraints.json").read_text())
    channel = json.loads((v3_dir / "river_centerline_v3.json").read_text())
    reference = images["top_flat_semantic.jpg"]
    scale_bars = {name: detect_source_scale_bar(images[name], label_verified=True) for name in
                  ("front_render.png", "back_render.png", "left_render.png", "right_render.png")}
    scale_px = [x["bar_pixels"] for x in scale_bars.values()]
    scale_consistent = max(scale_px) - min(scale_px) <= 2

    # Fit a shared orthographic profile envelope with bounded global and
    # rock-weighted blending. A land-normalized Gaussian pass tests modest
    # high-frequency relief changes. Wireframe-1 and the side render train
    # selection; wireframe-2 and the atlas isometric remain independent.
    candidates = []
    fit_key, heldout_key = "oblique_wireframe_1.jpg", "oblique_wireframe_2.jpg"
    side_render_key = "oblique_side_render.jpg"
    fitted_cameras = {}
    for name in (fit_key, heldout_key):
        fitted = silhouette_fit(images[name], base, land)
        fitted_cameras[name] = {key: float(fitted[key]) for key in
                                ("yaw_degrees", "pitch_relative",
                                 "vertical_scale_relative")}
    side_camera_fit = side_render_silhouette_fit(
        images[side_render_key], base, land)
    fitted_cameras[side_render_key] = {key: float(side_camera_fit[key]) for key in
                                       ("yaw_degrees", "pitch_relative",
                                        "vertical_scale_relative")}
    atlas_camera_fit = atlas_isometric_silhouette_fit(
        images[atlas_key], base, land)
    atlas_camera = {key: float(atlas_camera_fit[key]) for key in
                    ("yaw_degrees", "pitch_relative",
                     "vertical_scale_relative")}
    target_x, target_y, profile_metadata = observed_profiles(profiles, base.shape[0])
    envelope = np.minimum(target_x[None, :], target_y[:, None])
    base_positive = np.maximum(base, 0)
    rock_values = rock_likelihood[land]
    rock_low, rock_high = np.percentile(rock_values, (40, 95))
    rock_weight = np.clip((rock_likelihood - rock_low) /
                          max(float(rock_high-rock_low), 1e-5), 0, 1)
    land_weights = gaussian_filter(land.astype(np.float32), sigma=2., mode="nearest")
    rock_weight = gaussian_filter(rock_weight * land, sigma=2., mode="nearest") / \
        np.maximum(land_weights, 1e-5)
    rock_weight = np.clip(rock_weight, 0, 1)
    candidate_specs = [(1., blend, sigma) for blend in
                       (0., .5, .6, .65, .7, .75, .8, 1.)
                       for sigma in (0., .5, .75, 1., 1.25)]
    candidate_specs += [(alpha, blend, sigma) for alpha in
                        (0., .2, .4, .6, .8)
                        for blend in (.5, .65, .8, 1.)
                        for sigma in (.5, .75, 1.)]
    for rock_weight_floor, blend, sigma in candidate_specs:
        regional_weight = np.where(
            land, rock_weight_floor + (1-rock_weight_floor)*rock_weight, 0.)
        blended = np.where(
            land, base_positive + blend*regional_weight*(envelope-base_positive), base)
        blended[base < 0] = base[base < 0]
        if sigma:
            weights = gaussian_filter(land.astype(np.float32), sigma=sigma,
                                      mode="nearest")
            heights = gaussian_filter(blended * land, sigma=sigma,
                                      mode="nearest") / np.maximum(weights, 1e-5)
            candidate = np.where(land, heights, blended).astype(np.float32)
            candidate[base < 0] = base[base < 0]
        else:
            candidate = blended.astype(np.float32)
        sides = profile_scores(candidate, profiles)
        fit = fixed_projection_silhouette_fit(
            images[fit_key], candidate, land, fitted_cameras[fit_key])[
                "normalized_rmse"]
        side_fit = fixed_projection_silhouette_fit(
            images[side_render_key], candidate, land,
            fitted_cameras[side_render_key], side_render=True)["normalized_rmse"]
        candidates.append({"rock_weight_floor": float(rock_weight_floor),
                           "profile_envelope_blend": float(blend),
                           "relief_smoothing_sigma_grid_cells": float(sigma),
                           "profile_restoration_spread_grid_cells": None,
                           "profile_restoration_rounds": 0,
                           "cardinal_rmse_px_equivalent": sides,
                           "fit_isometric_1_normalized_rmse": fit,
                           "fit_side_render_normalized_rmse": side_fit,
                           "training_fit_mean_normalized_rmse": float(.5*(fit+side_fit)),
                           "field_deviation_rmse_from_v4": float(np.sqrt(np.mean(
                               (candidate[land]-base[land])**2))),
                           "field": candidate})

    # A second family keeps spatially weighted ridge detail, then restores only
    # missing row/column maxima near the source rock evidence. Selection still
    # uses the same two training views and cardinal constraints as above.
    for rock_weight_floor in (0., .2, .4):
        regional_weight = np.where(
            land, rock_weight_floor +
            (1-rock_weight_floor)*rock_weight, 0.)
        for blend in (.8, 1.):
            blended = np.where(
                land, base_positive + blend*regional_weight*
                (envelope-base_positive), base).astype(np.float32)
            blended[base < 0] = base[base < 0]
            for spread in (4., 5., 6.):
                for rounds in (2, 4, 6):
                    restored = restore_profile_peaks(
                        blended, envelope, land, rock_weight,
                        target_x, target_y, spread=spread, rounds=rounds)
                    restored[base < 0] = base[base < 0]
                    sigma = .5
                    weights = gaussian_filter(
                        land.astype(np.float32), sigma=sigma,
                        mode="nearest")
                    heights = gaussian_filter(
                        restored*land, sigma=sigma, mode="nearest") / \
                        np.maximum(weights, 1e-5)
                    candidate = np.where(
                        land, np.minimum(heights, envelope), restored
                    ).astype(np.float32)
                    candidate[base < 0] = base[base < 0]
                    sides = profile_scores(candidate, profiles)
                    fit = fixed_projection_silhouette_fit(
                        images[fit_key], candidate, land,
                        fitted_cameras[fit_key])["normalized_rmse"]
                    side_fit = fixed_projection_silhouette_fit(
                        images[side_render_key], candidate, land,
                        fitted_cameras[side_render_key], side_render=True)[
                            "normalized_rmse"]
                    candidates.append({
                        "rock_weight_floor": float(rock_weight_floor),
                        "profile_envelope_blend": float(blend),
                        "relief_smoothing_sigma_grid_cells": sigma,
                        "profile_restoration_spread_grid_cells": float(spread),
                        "profile_restoration_rounds": int(rounds),
                        "cardinal_rmse_px_equivalent": sides,
                        "fit_isometric_1_normalized_rmse": fit,
                        "fit_side_render_normalized_rmse": side_fit,
                        "training_fit_mean_normalized_rmse": float(
                            .5*(fit+side_fit)),
                        "field_deviation_rmse_from_v4": float(np.sqrt(np.mean(
                            (candidate[land]-base[land])**2))),
                        "field": candidate})
    base_sides = profile_scores(base, profiles)
    base_iso = _image_metrics(images, base, land, fitted_cameras)
    base_side_render = fixed_projection_silhouette_fit(
        images[side_render_key], base, land, fitted_cameras[side_render_key],
        side_render=True)
    base_side_mean = float(np.mean(list(base_sides.values())))
    acceptable = [c for c in candidates if
        all(c["cardinal_rmse_px_equivalent"][v] <= base_sides[v] + .25
            for v in base_sides) and
        float(np.mean(list(c["cardinal_rmse_px_equivalent"].values()))) <= base_side_mean - .05 and
        c["fit_isometric_1_normalized_rmse"] < base_iso[fit_key] - .003 and
        c["fit_side_render_normalized_rmse"] < base_side_render["normalized_rmse"] - .002]
    training_min = min(c["training_fit_mean_normalized_rmse"] for c in acceptable) \
        if acceptable else None
    training_selection_slack = .005
    if acceptable:
        near_optimal = [c for c in acceptable if c["training_fit_mean_normalized_rmse"]
                        <= training_min + training_selection_slack]
        selected = min(near_optimal,
                       key=lambda c: c["field_deviation_rmse_from_v4"])
        selected_field = selected["field"]
        relative_geometry_gate = True
    else:
        selected = next(c for c in candidates if c["rock_weight_floor"] == 1. and
                        c["profile_envelope_blend"] == 0. and
                        c["relief_smoothing_sigma_grid_cells"] == 0.)
        selected_field = selected["field"]
        relative_geometry_gate = False
    heldout_score = _image_metrics(
        images, selected_field, land, fitted_cameras)[heldout_key]
    heldout_base = base_iso[heldout_key]
    heldout_gate = heldout_score <= heldout_base + .005
    atlas_base = fixed_projection_silhouette_fit(
        images[atlas_key], base, land, atlas_camera, atlas_isometric=True)
    atlas_score = fixed_projection_silhouette_fit(
        images[atlas_key], selected_field, land, atlas_camera,
        atlas_isometric=True)
    atlas_gate = atlas_score["normalized_rmse"] <= atlas_base["normalized_rmse"] + .005
    selected_side_render = fixed_projection_silhouette_fit(
        images[side_render_key], selected_field, land,
        fitted_cameras[side_render_key], side_render=True)
    absolute_visual_fidelity_gate = False

    # Relative hydrology scenarios keep source-derived width and assumed depth
    # separate. Their names and report never imply physical units.
    hydro_scenarios = []
    for width_factor in (.8, 1., 1.2):
        for depth_factor in (.5, 1., 1.5):
            carved, hydro, geo = model_river(reference, selected_field, channel,
                {"width_multiplier": width_factor, "depth_multiplier": depth_factor})
            mask_name = f"water_width_{width_factor:.1f}_depth_{depth_factor:.1f}.png"
            if not cv2.imwrite(str(output / mask_name),
                               geo["river_water_mask"].astype(np.uint8) * 255):
                raise OSError("Failed to write water scenario " + mask_name)
            hydro_scenarios.append({
                "width_multiplier_relative": width_factor,
                "depth_multiplier_relative": depth_factor,
                "water_mask": mask_name,
                "summary": hydro["summary"],
                "width_profile_source_pixels": hydro["width_profile_px"],
                "depth_profile_relative_only": hydro["assumed_depth_profile_relative"],
                "relative_volume_scenario_low": hydro["summary"]["volume_low_depth_scenario"],
                "relative_volume_scenario_base": hydro["summary"]["water_volume_relative_cubic_units"],
                "relative_volume_scenario_high": hydro["summary"]["volume_high_depth_scenario"],
                "not_physical_bathymetry": True,
            })

    features, feature_reports = classify_regions(
        selected_field, land, water, rock_likelihood)
    for name, mask in features.items():
        if not cv2.imwrite(str(output / f"{name}.png"), mask.astype(np.uint8) * 255):
            raise OSError("Failed to write feature mask " + name)
    points, heights, faces, mesh_report = feature_adaptive_mesh(
        selected_field, land, water, semantic_features=features)
    write_adaptive_obj(output / "terrain_adaptive_v5.obj", points, heights, faces,
                       grid_size=selected_field.shape[0])
    write_previews(output, reference, land, features, points, faces)
    write_view_comparisons(output, base, selected_field, profiles, images, land,
                           fitted_cameras)
    write_side_render_training_comparison(output, images[side_render_key], base,
                                          selected_field, land,
                                          fitted_cameras[side_render_key])
    write_atlas_isometric_holdout_comparison(
        output, images[atlas_key], base, selected_field, land, atlas_camera,
        atlas_base["normalized_rmse"], atlas_score["normalized_rmse"])
    np.save(output / "height_relative_v5.npy", selected_field)
    after_sides = profile_scores(selected_field, profiles)
    _, components = cv2.connectedComponents(water.astype(np.uint8), 8)
    water_connected = bool(components.max() == 1)
    report = {
        "source_sha256": {**v4_report["source_sha256"], atlas_key: atlas_hash},
        "status": "V5_RELATIVE_GEOMETRY_IMPROVED_VISUAL_NO_GO"
                 if relative_geometry_gate and heldout_gate and atlas_gate and water_connected
                 else "V5_NO_GO_MULTIVIEW_GEOMETRY",
        "candidate_geometry_accepted_for_relative_review": relative_geometry_gate,
        "absolute_visual_fidelity_gate": absolute_visual_fidelity_gate,
        "absolute_visual_fidelity_reason": "Cardinal residuals and uncalibrated held-out skyline remain visibly material",
        "heldout_isometric_2_gate_pass": heldout_gate,
        "atlas_isometric_holdout_gate_pass": atlas_gate,
        "all_independent_view_gates_pass": bool(heldout_gate and atlas_gate),
        "selected_profile_envelope_blend": float(selected["profile_envelope_blend"]),
        "selected_rock_weight_floor": float(selected["rock_weight_floor"]),
        "selected_relief_smoothing_sigma_grid_cells": float(
            selected["relief_smoothing_sigma_grid_cells"]),
        "selected_profile_restoration_spread_grid_cells": selected[
            "profile_restoration_spread_grid_cells"],
        "selected_profile_restoration_rounds": int(
            selected["profile_restoration_rounds"]),
        "training_fit_minimum_mean_rmse": float(training_min) if training_min is not None else None,
        "training_fit_selected_mean_rmse": float(
            selected["training_fit_mean_normalized_rmse"]),
        "training_fit_near_optimal_slack": training_selection_slack,
        "selected_field_deviation_rmse_from_v4": float(
            selected["field_deviation_rmse_from_v4"]),
        "selection_rule": "cardinal constraints plus training-view fit; source-weighted candidates may restore missing profile maxima locally near rock evidence; among candidates within 0.005 mean normalized RMSE of the best training score, select the smallest field deviation from V4; wireframe-2 and the right atlas isometric panel are independent holdouts",
        "water_connected": water_connected,
        "source_scale_bar": {
            "per_view": scale_bars,
            "median_pixels_per_500_source_units": float(np.median(scale_px)),
            "view_to_view_bar_consistent": scale_consistent,
            "use_for_absolute_bathymetry": False,
            "use_for_Roblox_studs": False,
        },
        "profile_rmse_v4": base_sides,
        "profile_rmse_v5": after_sides,
        "source_opposing_profile_compatibility": opposing_profile_conflicts(profiles),
        "profile_envelope_metadata": profile_metadata,
        "isometric_rmse_v4": base_iso,
        "isometric_rmse_v5_fit_and_heldout": {
            fit_key: selected["fit_isometric_1_normalized_rmse"],
            heldout_key: heldout_score,
        },
        "atlas_isometric_holdout": {
            "source_sha256": atlas_hash,
            "baseline_rmse_v4": atlas_base["normalized_rmse"],
            "candidate_rmse_v5": atlas_score["normalized_rmse"],
            "gate_pass": atlas_gate,
            "segmentation": atlas_score["segmentation"],
            "camera_fit_on_v4_then_fixed": atlas_camera,
            "not_metric_camera_calibration": True,
        },
        "relative_projection_cameras_fitted_on_v4_and_fixed": fitted_cameras,
        "side_render_training_rmse_v4": float(base_side_render["normalized_rmse"]),
        "side_render_training_rmse_v5": float(selected_side_render["normalized_rmse"]),
        "side_render_training_segmentation": selected_side_render["segmentation"],
        "candidate_results": [
            {k: v for k, v in c.items() if k != "field"} for c in candidates],
        "adaptive_mesh": mesh_report,
        "visual_artifacts": ["terrain_regions_v5.png", "adaptive_mesh_preview_v5.png",
                             "multiview_comparison_v5.png", "isometric_comparison_v5.png",
                             "side_render_training_v5.png",
                             "atlas_isometric_holdout_v5.png"],
        "terrain_region_hypotheses": feature_reports,
        "water_scenarios": hydro_scenarios,
        "limitations": [
            "The isometric projection remains an uncalibrated silhouette heuristic.",
            "Water depths and volumes are relative scenarios; source scale is not physically confirmed.",
            "No original 3D mesh, collision evidence, Studio playtest or gameplay validation is available in this stage.",
        ],
    }
    (output / "terrain_v5_report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("sources", "v2", "v3", "v4", "output"):
        parser.add_argument("--" + name, required=True, type=Path)
    args = parser.parse_args()
    result = run(args.sources, args.v2, args.v3, args.v4, args.output)
    printable = {k: v for k, v in result.items() if k != "water_scenarios"}
    printable["water_scenario_count"] = len(result["water_scenarios"])
    print(json.dumps(printable, indent=2))


if __name__ == "__main__":
    main()
