"""Terrain 2 V3 bathymetry hypothesis: source-derived width and assumed depth.

No physically measured river depths, discharge or cubic meters. Pixel-length and
relative vertical units are explicitly incompatible with georeferenced volumes.
"""
import cv2
import numpy as np
from scipy.ndimage import gaussian_filter1d
from scipy.spatial import cKDTree


def beige_observations(bgr):
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    return ((hsv[:, :, 0] >= 6) & (hsv[:, :, 0] <= 32) &
            (hsv[:, :, 2] >= 151) & (hsv[:, :, 1] >= 12) &
            (hsv[:, :, 1] <= 127))


def widths_from_reference(bgr, route, step=6, max_half=54):
    beige = beige_observations(bgr)
    h, w = beige.shape
    route = np.asarray(route, dtype=float)
    if route.ndim != 2 or route.shape[1] != 2 or len(route) < 5:
        raise ValueError("Invalid source centerline")
    sample = np.unique(np.r_[np.arange(0, len(route), step), len(route) - 1])
    widths, symmetry = [], []
    for i in sample:
        before, after = route[max(0, i - 6)], route[min(len(route) - 1, i + 6)]
        tangent = after - before
        tangent /= max(1e-8, np.linalg.norm(tangent))
        normal = np.array([-tangent[1], tangent[0]])
        halves = []
        for sign in (-1, 1):
            half = 0.
            for d in np.arange(.5, max_half + 1, .5):
                x, y = np.rint(route[i] + sign * normal * d).astype(int)
                if not (0 <= x < w and 0 <= y < h and beige[y, x]):
                    break
                half = d
            halves.append(half)
        widths.append(sum(halves))
        symmetry.append(min(halves) / max(1., max(halves)))
    widths = np.asarray(widths, float)
    good = widths >= 3
    if good.sum() < 3:
        raise ValueError("Insufficient source-bank evidence")
    widths = np.interp(np.arange(len(widths)), np.flatnonzero(good), widths[good])
    widths = np.clip(gaussian_filter1d(widths, 1.2), 4., 100.)
    return np.interp(np.arange(len(route)), sample, widths), {
        "cross_sections": len(sample),
        "minimum_width_original_px": float(widths.min()),
        "median_width_original_px": float(np.median(widths)),
        "maximum_width_original_px": float(widths.max()),
        "mean_bank_symmetry_fraction": float(np.mean(symmetry)),
        "source_pixel_observation_only": True
    }


def model_river(flat, field, previous, config=None):
    config = config or {}
    route = np.asarray(previous["centerline_xy"], float)
    h, w = flat.shape[:2]
    n = field.shape[0]
    widths, width_stats = widths_from_reference(flat, route)
    s = np.r_[0, np.cumsum(np.linalg.norm(np.diff(route, axis=0), axis=1))]
    progress = s / max(1, float(s[-1]))
    multiplier = float(config.get("depth_multiplier", 1.))
    if not .1 <= multiplier <= 6:
        raise ValueError("Invalid relative depth multiplier")
    # Scenario assumption, not recovered bathymetry.
    depth = (3. + 2.5 * np.clip(widths / 30, .3, 2.2) ** .7 + 1.2 * progress) * multiplier
    surface = 5. * (1 - progress)
    if np.any(np.diff(surface) > 1e-9):
        raise ValueError("Water surface is not monotone downstream")
    scale = np.asarray([(n - 1) / (w - 1), (n - 1) / (h - 1)])
    coordinates = route * scale
    rows, cols = np.indices((n, n))
    tree = cKDTree(coordinates)
    _, near = tree.query(np.stack([cols.ravel(), rows.ravel()], axis=-1), workers=-1)
    near = near.reshape(n, n)
    distance = np.hypot(cols - coordinates[near, 0], rows - coordinates[near, 1])
    half_width = np.maximum(widths[near] / 2 * scale[0], .8)
    wet = distance <= half_width
    connected_centerline = np.zeros((n, n), np.uint8)
    for a, b in zip(coordinates[:-1], coordinates[1:]):
        cv2.line(connected_centerline, tuple(np.rint(a).astype(int)),
                 tuple(np.rint(b).astype(int)), 255, 1)
    wet |= connected_centerline > 0
    _, components = cv2.connectedComponents(wet.astype(np.uint8), 8)
    start, end = np.rint(coordinates[[0, -1]]).astype(int)
    connected = bool(components[start[1], start[0]] and
                     components[start[1], start[0]] == components[end[1], end[0]])
    if not connected:
        raise ValueError("Lake-to-harbor corridor disconnected")
    water = surface[near]
    section_depth = depth[near] * (1 - np.clip(distance / half_width, 0, 1) ** 2)
    carved = field.astype(np.float32).copy()
    carved[wet] = (water - section_depth)[wet]
    margin = (distance > half_width) & (distance < half_width + 1.5)
    bank_goal = water + 1.2 * np.clip((distance - half_width) / 1.5, 0, 1)
    carved[margin] = np.maximum(carved[margin], bank_goal[margin])
    cross_area = (2. / 3.) * widths * depth
    volume = float(np.trapz(cross_area, s))
    summary = {
        "length_source_pixels": float(s[-1]),
        "water_surface_upstream_relative": float(surface[0]),
        "water_surface_seaward_relative": float(surface[-1]),
        "center_depth_min_relative": float(depth.min()),
        "center_depth_median_relative": float(np.median(depth)),
        "center_depth_max_relative": float(depth.max()),
        "wet_cross_section_area_median_relative_square": float(np.median(cross_area)),
        "water_volume_relative_cubic_units": volume,
        "volume_low_depth_scenario": volume * .5,
        "volume_high_depth_scenario": volume * 1.5,
        "volume_scenario_basis": "same source-pixel widths, half to one-and-half assumed depths",
        "geometry_scale": "source horizontal pixels and arbitrary relative vertical units",
        "ABSOLUTE_CUBIC_METERS_AVAILABLE": False,
        "wet_mask_lake_to_harbor_8connected": connected,
        "raster_wet_pixels": int(wet.sum()),
        "bank_pixels": int(margin.sum()),
        "monotonic_downstream_surface": True,
        "no_original_bathymetry": True
    }
    k = max(1, len(s) // 100)
    hydro = {
        "status": "PARAMETRIC_RIVER_BATHYMETRY_HYPOTHESIS",
        "width_statistics": width_stats,
        "summary": summary,
        "distance_s_px": s[::k].round(2).tolist(),
        "width_profile_px": widths[::k].round(2).tolist(),
        "assumed_depth_profile_relative": depth[::k].round(2).tolist(),
        "surface_profile_relative": surface[::k].round(2).tolist(),
        "limitations": [
            "The beige source artwork is not a surveyed water polygon.",
            "Width is an image observation. Depth, cross-sections and volume are assumptions.",
            "Pixel and vertical units are uncalibrated; this is not cubic meters or flow simulation."
        ]
    }
    geo = {
        "centerline_xy": route, "width_px": widths, "depth": depth,
        "surface_levels": surface, "river_water_mask": wet,
        "river_bank_mask": margin,
        "depth_grid": np.where(wet, section_depth, 0).astype(np.float32)
    }
    return carved, hydro, geo


def export_water_surface(path, geo, source_size, n, cell_scale=4.):
    route = geo["centerline_xy"]
    widths = geo["width_px"]
    levels = geo["surface_levels"]
    h, w = source_size
    sample = np.unique(np.r_[np.arange(0, len(route), max(1, len(route) // 350)), len(route) - 1])
    with open(path, "w") as stream:
        stream.write("# Separate V3 water ribbon: relative surface levels, measured width pixels\n")
        for i in sample:
            p = route[i]
            tangent = route[min(len(route)-1, i+4)] - route[max(0, i-4)]
            tangent /= max(1e-8, np.linalg.norm(tangent))
            normal = np.array([-tangent[1], tangent[0]])
            for sign in (-1, 1):
                x, y = p + sign * normal * widths[i] / 2
                vx = x * (n-1)/(w-1) * cell_scale
                vz = (n-1-y*(n-1)/(h-1)) * cell_scale
                stream.write(f"v {vx:.5f} {levels[i]:.5f} {vz:.5f}\n")
        for j in range(len(sample)-1):
            a = 2*j+1
            stream.write(f"f {a} {a+2} {a+1}\nf {a+1} {a+2} {a+3}\n")
