# V5 — River continuity fix: lake → valley → harbor

**Status:** experiment validated for **connected geometry**, not a calibrated hydrological/3D reconstruction. This update is a focused correction to the source-image V5 heightfield, and does not change the other mountain landmarks.

## Root cause

V5 interpolated an RBF heightfield from approximate coast and peak landmarks, but did not impose any constraints on a continuous river channel. The RGB water segmentation could also mark intermittent inland blue pixels as sea (-8 relative units), leaving disconnected river/lake cavities and discontinuous banks.

## Implemented

- Editable `hydrology` section in `v5_landmarks.json` contains manually reviewed river centerline waypoints **in pixels of the 906×726 extracted top atlas**. Lake seed is backed by source blue pixels.
- `hydrology_v5.py` uses a shortest path constrained to small intervals around the annotated waypoints; color-based source-blue evidence influences the route but is not assumed perfectly reliable because the art is AI-generated.
- Rasterizes connected line segments at the final terrain grid resolution, not by resizing a thin river mask. This avoids disappearing stretches when changing from 33 to 513 grid points.
- Builds lake bathymetry, an explicitly carved riverbed and narrowly blended banks; near-channel changes are limited and do not re-create mountain peaks.
- Assigns an artificial waterline descending monotonically from the lake level (relative 12) to the port (relative 0). Waterbed is 2.5 units below this conceptual waterline.
- Exports independent `river_water_surface.obj` (to inspect the appearance of water), `river_reference_overlay.png`, water/river/lake masks, `hydrology_report.json`, corrected terrain OBJ/heightmap, and an additional blue river line in `terrain_v5.html`.
- If source landmarks omit `hydrology`, behavior remains backward-compatible: no river correction and report status `NO_SOURCE_HYDROLOGY_ANNOTATIONS`.

## Real-image local results (257 × 257)

| Check | Result |
|---|---:|
| Lake-to-port connected raster water component | Yes |
| Source-image path length (traced pixels) | 400 |
| Source blue support along traced line | 72.5% |
| Riverbed grid cells | ~509 |
| Lake grid cells | ~810 |
| Grid heights changed (lake, river and short bank transition) | ~2,208 of 66,049 |
| Downstream water surface monotone | Yes |
| Terrain maximum before vs. after | Unchanged at ~130.58 arbitrary units |

Figures are from a **local run of the actual 1619×971 source + 1536×1024 atlas**. The GitHub Actions workflow uses synthetic fixtures, not the original user images; CI results must not be represented as direct visual verification of the real map.

## Run

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m unittest discover -s tests -p 'test_*v5.py' -v
python -m tools.terrain_inverse.reconstruct_v5 \
  --top-atlas /path/vistasortograficas.png \
  --clean-oblique /path/clean-oblique.png \
  --original-wireframe /path/original-wireframe.png \
  --landmarks tools/terrain_inverse/v5_landmarks.json \
  --grid 257 --output out/v5-river
```

To inspect the connection, open `river_reference_overlay.png`, `water_connected_grid.png`, `river_water_surface.obj` and `terrain_v5.html`. The water surface is an OBJ mesh and will need Roblox-specific water materials/physics once the model is accepted.

## Not yet established

This fix does not calibrate real-world elevations or water flow, solve the camera, recover true original AI mesh topology, or validate Studio collision/water mechanics. The source river line is manually annotated, so the continuous path is an engineered hypothesis with measurable 2D color support. The camera/peaks remain experimental. **No deployment or merge to `dev` or `main` has occurred.**
