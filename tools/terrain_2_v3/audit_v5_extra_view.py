"""Post-selection skyline audit against an unused raster terrain reference."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import cv2
import numpy as np

from .isometric_v3 import silhouette_fit
from .terrain_v5 import fixed_projection_silhouette_fit


def evaluate(sources: Path, v2_dir: Path, v4_dir: Path, v5_dir: Path,
             output: Path) -> dict:
    """Fit the extra-view camera on V4, freeze it, then score one selected V5.

    This deliberately audits only the selected field. It does not take part in
    V5 candidate generation, ranking, or the existing independent holdouts.
    """
    source = sources / "top_sparse_mesh.jpg"
    image = cv2.imread(str(source))
    if image is None:
        raise ValueError(f"Cannot read extra reference: {source}")
    land_image = cv2.imread(str(v2_dir / "land_all_components.png"),
                             cv2.IMREAD_GRAYSCALE)
    if land_image is None:
        raise ValueError("V2 land_all_components.png is required")
    v4 = np.load(v4_dir / "height_refined_v4.npy").astype(np.float32)
    v5 = np.load(v5_dir / "height_relative_v5.npy").astype(np.float32)
    if v4.shape != v5.shape or v4.ndim != 2 or v4.shape[0] != v4.shape[1]:
        raise ValueError("V4 and selected V5 must be square, matching heightfields")
    land = cv2.resize((land_image > 0).astype(np.uint8), v4.shape[::-1],
                      interpolation=cv2.INTER_NEAREST) > 0

    fit = silhouette_fit(image, v4, land)
    camera = {key: float(fit[key]) for key in
              ("yaw_degrees", "pitch_relative", "vertical_scale_relative")}
    baseline = fixed_projection_silhouette_fit(image, v4, land, camera)
    candidate = fixed_projection_silhouette_fit(image, v5, land, camera)
    report = {
        "status": "POST_SELECTION_EXTRA_VIEW_DIAGNOSTIC",
        "source": source.name,
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "source_shape_height_width": list(image.shape[:2]),
        "heightfield_shape": list(v5.shape),
        "selected_v5_field_sha256": hashlib.sha256(
            (v5_dir / "height_relative_v5.npy").read_bytes()).hexdigest(),
        "camera_fit_on_v4_then_fixed": camera,
        "v4_baseline_normalized_rmse": baseline["normalized_rmse"],
        "selected_v5_normalized_rmse": candidate["normalized_rmse"],
        "v5_minus_v4_rmse": candidate["normalized_rmse"] -
                            baseline["normalized_rmse"],
        "camera_is_metric_calibration": False,
        "used_for_v5_candidate_selection": False,
        "holdout_scope": "additional post-selection image-relative check only",
        "limitations": [
            "top_sparse_mesh.jpg is a raster reference, not a native mesh or heightmap",
            "skyline segmentation and projection are uncalibrated image-relative heuristics",
            "this audit does not establish absolute visual fidelity or physical scale",
        ],
    }
    output.mkdir(parents=True, exist_ok=True)
    (output / "v5_extra_view_report.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8")

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(10, 4), constrained_layout=True)
    ax.plot(baseline["observed"], label="top_sparse_mesh reference")
    ax.plot(baseline["predicted"],
            label=f"V4 baseline {baseline['normalized_rmse']:.3f}")
    ax.plot(candidate["predicted"],
            label=f"selected V5 {candidate['normalized_rmse']:.3f}")
    ax.set_title("V4 camera fit, frozen for the selected V5 field")
    ax.set_xlabel("normalized horizontal position")
    ax.set_ylabel("normalized skyline")
    ax.legend()
    fig.savefig(output / "v5_extra_view_skyline.png", dpi=140)
    plt.close(fig)
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sources", type=Path, required=True)
    parser.add_argument("--v2", type=Path, required=True)
    parser.add_argument("--v4", type=Path, required=True)
    parser.add_argument("--v5", type=Path, required=True,
                        help="directory containing the already-selected V5 field")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = evaluate(args.sources, args.v2, args.v4, args.v5, args.output)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
