"""Iso silhouette shape comparison against user-generated reference imagery.

A fitted viewing direction is *not* metric camera calibration. Each source
is independently compared by its normalized skyline, without invented pixels.
"""
import cv2
import numpy as np


def observed_skyline(image, bins=112):
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    h, w = hsv.shape[:2]
    y = np.indices((h, w))[0]
    terrain = (hsv[:, :, 1] < 100) & (hsv[:, :, 2] > 85) & (y < h * .74)
    skyline = np.where(terrain, y, np.inf).min(axis=0)
    good = np.isfinite(skyline)
    if good.sum() < w * .45:
        raise ValueError("Unreliable isometric foreground segmentation")
    skyline = np.interp(np.arange(w), np.flatnonzero(good), skyline[good])
    return np.interp(np.linspace(0, w-1, bins), np.arange(w), skyline)


def _project_skyline(field, mask, theta, pitch, zfactor, bins):
    n = field.shape[0]
    step = max(1, n // 135)
    rows, cols = np.mgrid[0:n:step, 0:n:step]
    selected = mask[::step, ::step].ravel()
    x = cols.ravel()[selected] / (n-1) - .5
    y = rows.ravel()[selected] / (n-1) - .5
    z = np.maximum(0, field[::step, ::step].ravel()[selected]) / 125.
    if not len(x):
        return np.full(bins, np.nan)
    t = np.deg2rad(theta)
    horizontal = np.cos(t) * x + np.sin(t) * y
    depth = -np.sin(t) * x + np.cos(t) * y
    q = (horizontal - horizontal.min()) / max(1e-8, np.ptp(horizontal))
    indices = np.clip(np.rint(q * (bins - 1)).astype(int), 0, bins-1)
    screen_y = pitch * depth - zfactor * z
    skyline = np.full(bins, np.inf)
    np.minimum.at(skyline, indices, screen_y)
    good = np.isfinite(skyline)
    if good.sum() < bins * .7:
        return np.full(bins, np.nan)
    return np.interp(np.arange(bins), np.flatnonzero(good), skyline[good])


def silhouette_fit(image, field, mask, bins=112):
    observed = observed_skyline(image, bins)
    observed = (observed - observed.mean()) / max(1., observed.std())
    best = None
    for yaw in np.linspace(-82, 82, 17):
        for pitch in (.22, .42, .62):
            for height_scale in (.6, 1.3, 2.2):
                candidate = _project_skyline(field, mask, yaw, pitch, height_scale, bins)
                if not np.isfinite(candidate).all():
                    continue
                candidate = (candidate-candidate.mean()) / max(.00001, candidate.std())
                residual = float(np.sqrt(np.mean((observed-candidate)**2)))
                if best is None or residual < best["normalized_rmse"]:
                    best = {"normalized_rmse": residual, "yaw_degrees": float(yaw),
                            "pitch_relative": float(pitch),
                            "vertical_scale_relative": float(height_scale),
                            "observed": observed, "predicted": candidate}
    if best is None:
        raise ValueError("Cannot evaluate original isometric skyline")
    return best


def evaluate(images, field, mask, output):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(2, 1, figsize=(10,6), constrained_layout=True)
    report = {}
    for ax, name in zip(axes, ("oblique_wireframe_1.jpg", "oblique_wireframe_2.jpg")):
        metric = silhouette_fit(images[name], field, mask)
        truth = metric.pop("observed")
        predicted = metric.pop("predicted")
        report[name] = {**metric,
                        "status": "UNCALIBRATED_ISOMETRIC_SKYLINE_SHAPE_FIT",
                        "not_pixel_reprojection": True}
        ax.plot(truth, label="Referência AI normalizada")
        ax.plot(predicted, label="Hipótese V3 normalizada")
        ax.set_title(f"{name}: RMSE normalizada = {metric['normalized_rmse']:.3f}")
        ax.set_xlabel("Posição horizontal relativa")
        ax.set_ylabel("Silhueta sem escala física")
        ax.legend(fontsize=8)
    fig.savefig(output / "isometric_silhouette_diagnostics.png", dpi=140)
    plt.close(fig)
    return report
