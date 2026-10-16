"""V5: independent held-out visual audit of V4 geometry against original source images.

Do not confuse synthetic CI passing with observed visual fidelity.
"""
import argparse
import json
from pathlib import Path
import cv2
import numpy as np
from tools.terrain_2_v3.terrain_v3 import read_image, predict_profile
from tools.terrain_2_v3.isometric_v3 import silhouette_fit


def audit(sources, v2, v3, v4, output):
    src, v2, v3, v4, out = map(Path, (sources, v2, v3, v4, output))
    out.mkdir(parents=True, exist_ok=True)
    report = json.loads((v4 / "final_report_v4.json").read_text())
    source_hashes = report["source_sha256"]
    originals = {}
    for name, expected in source_hashes.items():
        originals[name], actual = read_image(src / name)
        if actual != expected:
            raise ValueError("Original reference hash mismatch: " + name)
    base = np.load(v3 / "height_relative_v3.npy")
    refined = np.load(v4 / "height_refined_v4.npy")
    if base.shape != refined.shape or not np.isfinite(refined).all():
        raise ValueError("Invalid V4 heightfield")
    profiles = json.loads((v2 / "orthographic_profile_constraints.json").read_text())["profiles"]
    comparisons = {}
    for view in ("front", "back", "left", "right"):
        reference = np.asarray(profiles[view]["apparent_height_px"], dtype=float)
        a = predict_profile(base, view)
        b = predict_profile(refined, view)
        if len(a) != len(reference) or len(b) != len(reference):
            raise ValueError("Incompatible observed/predicted profile samples")
        comparisons[view] = {
            "v3_rmse_px_equivalent": float(np.sqrt(np.mean((a-reference)**2))),
            "v4_rmse_px_equivalent": float(np.sqrt(np.mean((b-reference)**2))),
            "v4_mae_px_equivalent": float(np.mean(np.abs(b-reference))),
            "v4_max_abs_px_equivalent": float(np.max(np.abs(b-reference))),
            "v4_better_than_v3": bool(np.mean((b-reference)**2) < np.mean((a-reference)**2))
        }
    flat = cv2.imread(str(v2 / "land_all_components.png"), cv2.IMREAD_GRAYSCALE)
    if flat is None:
        raise ValueError("Missing V2 source land mask")
    land = cv2.resize(flat, refined.shape[::-1], interpolation=cv2.INTER_NEAREST) > 0
    iso = {}
    for key in ("oblique_wireframe_1.jpg", "oblique_wireframe_2.jpg"):
        iso[key] = {
            "v3_normalized_rmse": float(silhouette_fit(originals[key], base, land)["normalized_rmse"]),
            "v4_normalized_rmse": float(silhouette_fit(originals[key], refined, land)["normalized_rmse"]),
            "role": "fit_reference" if key.endswith("_1.jpg") else "held_out"
        }
    water = cv2.imread(str(v4 / "river_ocean_join_v4.png"), cv2.IMREAD_GRAYSCALE)
    if water is None or water.shape != refined.shape:
        raise ValueError("Missing V4 channel")
    n, labels = cv2.connectedComponents((water > 0).astype(np.uint8), 8)
    components = np.bincount(labels.ravel())[1:]
    water_connected = bool(len(components) == 1)
    deltas = refined - base
    result = {
        "source": "original user AI-generated images, verified by SHA-256",
        "status": "AUDITED_NOT_PHYSICALLY_VALIDATED",
        "source_sha256": source_hashes,
        "grid": list(refined.shape),
        "cardinal": comparisons,
        "isometric": iso,
        "water_single_connected_component": water_connected,
        "height_change_mean_absolute_relative": float(np.mean(np.abs(deltas))),
        "height_change_max_absolute_relative": float(np.max(np.abs(deltas))),
        "pass": False,
        "reason": "Manual visual inspection and independently calibrated geometry still required",
        "warnings": [
            "Pixel-equivalent side RMSE is not a physical 3D reprojection error.",
            "Isometric silhouette metrics use uncalibrated view heuristics.",
            "River depth and volume are scenarios, not measured bathymetry.",
            "AI-generated references may be mutually inconsistent."
        ]
    }
    (out / "v5_reference_audit.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    parser = argparse.ArgumentParser()
    for name in ("sources", "v2", "v3", "v4", "output"):
        parser.add_argument("--" + name, required=True)
    a = parser.parse_args()
    print(json.dumps(audit(a.sources, a.v2, a.v3, a.v4, a.output), indent=2))


if __name__ == "__main__":
    main()
