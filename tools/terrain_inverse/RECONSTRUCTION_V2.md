# V2: inverse reconstruction from AI-generated island views

**Status:** experimental, not a production Roblox game map. Reference: [issue #67](https://github.com/dreyvinixz/RobloxGame/issues/67).

## Inputs, method, honesty about limitations

The user-supplied 1536x1024 AI atlas `vistasortograficas.png` is a composition of independent-looking concept views, **not calibrated photographs**. We cannot recover a unique original 3D terrain. The upper-left panel was manually traced into the `COAST` coordinates in `island.py`. Other views are **uncertain** silhouettes, not known heights.

`extract_reference.py` uses image RGB blue-sky chromatic differences, pixel-column upper-envelope detection and median filtering to digitize four cardinal profiles. The processed 33-point skyline vectors are preserved as `reference_constraints.json`. The full source image is not committed; reproduce its extraction with the image provided in chat.

An ideal orthographic landscape has the same north/south skyline (and an east/west skyline mirrored in the appropriate direction). The **AI-generated atlas violates these geometric constraints**. V2 measures the contradiction and fits the average rather than claiming impossible exact agreement.

## Mathematical reconstruction

The initial deterministic synthetic terrain comes from `island.py`: vector coast, Gaussian ridge constraints, central basin, river, lake and port with seeded multi-scale noise. V2 fixes a relative scale for the positive baseline, then fits 15 spatial Gaussian correction functions (12 mountain ridges and 3 broad terrain corrections):

```text
H(x,y) = clip(positive_part(0.72 H0) + sum(theta_i * B_i) ,0,255)
        with original sea bathymetry maintained separately
S_NS(x) = max_y H(x,y) / 230
S_EW(y) = max_x H(x,y) / 230
targets = (north + south)/2 and (east + reverse(west))/2
theta* = argmin [sum_even_samples (S(theta)-targets)^2
                 + (0.065)^2 * sum_i (theta_i/65)^2]
subject to theta_i in [-68,68]
```

The coefficients are estimated with **SciPy bounded least-squares on Ubuntu CPU**; a 129x129 fit grid is exported to 257x257 resolution with fixed seed. Coast, waterways and harbor zones attenuate fitting corrections. This is **not yet differentiable image rendering, neural depth estimation, camera bundle adjustment, photogrammetry or erosion simulation**. Those are future research stages.

## Reproduce

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m unittest discover -s tests -p 'test_terrain_inverse*.py' -v
python -m tools.terrain_inverse.inverse_fit --grid 129 --export-grid 257 --seed 20261015 --output terrain-v2-output
```

Optional: reproduce the image-to-skyline feature extraction using the *exact original image dimensions*:

```bash
python -m tools.terrain_inverse.extract_reference --atlas /path/to/vistasortograficas.png --output /tmp/reference.json
```

Run the [v2 GitHub Actions workflow](https://github.com/dreyvinixz/RobloxGame/actions/workflows/terrain-inverse-v2.yml) on the experimental branch. The downloadable ZIP includes a 16-bit heightmap, high-resolution OBJ, NumPy array, material masks, elevation preview, interactive 3D HTML, diagnostics, comparison plot and JSON fit report.

## Local benchmark (Python 3.13, fit grid 129, fixed seed)

| Normalized skyline RMSE | Before | After |
|---|---:|---:|
| Training (even-profile samples) | 0.24723 | 0.14379 |
| Held-out (odd-profile samples) | 0.25732 | 0.13949 |

The latter represents **45.8% less error** relative to the v1 generated terrain **on the same concept images**. It is **not** a measure of recovered true 3D similarity. These odd samples are held out from fitting but still belong to the same images.

AI cross-view conflict floor: north/south RMSE 0.11603; east/reversed-west RMSE 0.17891, showing why no exact multi-view consistency should be asserted. Actual results/coefficients and errors are saved into `inverse_fit_report.json`.

## Artifacts and validation

- `height_m.npy`, `terrain.obj` (1000-unit normalized width; X east, Y elevation, Z north)
- `heightmap_16bit.png` (nominal -24 to 260 output range, 16-bit linear grayscale)
- `material_classes.npy`, `land_mask.png`, `material_colormap.png`
- `terrain_3d.html` (self-contained rotatable 3D WebGL canvas)
- `topographic_preview.png`, `diagnostics.png`, `silhouette_comparison.png`
- `report.json`, `inverse_fit_report.json`, `reconstruction.log`

Roblox Terrain Editor heightmap import needs user-chosen dimensions and material assignments. Trees, streets, lake water, port structures, bridges and docks **are not** in the exported heightfield; Blender/Studio work is required. Do not merge into playable arena or change current NO-GO launch gate without Studio playtesting and asset review.

## Next research stages

1. Add RGB segmentation masks and top-view IoU measured against independent source pixel annotations.
2. Calibrate approximate cameras and optimize **rendered image** and silhouette losses with a differentiable renderer; down-weight inconsistent AI views.
3. Add relative-depth estimates, smoothing/slope constraints, hydrology checks, uncertainty visualization and Roblox terrain-scale testing.
