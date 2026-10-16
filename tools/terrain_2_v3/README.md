# Terreno 2 — V3: Multiview Heightfield and Coastal Channel Geometry

**Status: complete as an experimental image-constrained 2.5D HYPOTHESIS, not an authenticated original AI mesh.** Development continues on the SAME `experiment/terrain-2-image-v3-v4` branch through V4. Never target `main`.

## Original image inputs are mandatory

The user provided 16 original AI-generated images. They are **not checked into this GitHub repository**; find them in the accompanying ChatGPT ZIP (with `reference_manifest.json`). An executor must copy the `references/` folder and first generate the V2 output, then:

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_2_v3.terrain_v3 \
    --sources references \
    --v2 output_v2 \
    --grid 257 \
    --output output_v3
```

V3 refuses mismatched images via exact SHA-256 verification against `v2_report.json`; no procedural map fallback exists. The GitHub Action tests **synthetic source images only**, not real terrain fidelity.

## Actual source-image processing and model assumptions

- Front/back and left/right orthographic silhouettes provide source-pixel **upper envelopes**. Opposing viewpoints are horizontally mirrored and regularized; their conflict is reported instead of hidden.
- The actual `top_render.png` supplies rocky-relief placement as a texture prior, the original flat semantic reference supplies observed island footprint and channel. Iterative constrained envelope fitting produces a regular-grid 2.5D **nonunique** heightfield.
- Both AI isometric wireframes are used. `oblique_wireframe_1.jpg` contributes a weak **normalized skyline-shape** term in the joint choice of vertical amplitude; `oblique_wireframe_2.jpg` is held out for diagnostics. Their camera estimates are uncalibrated viewing heuristics, **not real reprojection errors**.
- Original apparent canal width is sampled across perpendicular cross sections of beige source pixels. **Depth is not visually measurable** in these references; the script explicitly assumes a width-dependent parabolic bed and reports half/one-and-half-depth sensitivity.
- Because the NEW map appears to have openings to the **northern sea and southern bay**, both water ends are held at the same relative sea level = 0. The model does **not** assume a river descending from an elevated lake. Tidal/current behavior remains unmodeled.
- Exports independent water ribbon OBJ, 16-bit relative heightmap, regular-grid OBJ, terrain classes, banks/depth masks, interactive HTML preview, all cross-section data and profile overlays.

## Local evaluation on the user's original 16 images (257×257, not GitHub Action)

| Measure | Result |
|---|---:|
| Terrain vertices / triangles | 66,049 / 131,072 |
| Estimated highest elevation | ~100.25 relative, not meters |
| Front / Back source-profile RMSE | 7.46 / 7.53 pixel-equivalent |
| Left / Right source-profile RMSE | 17.72 / 20.27 pixel-equivalent |
| Isometric 1 normalized skyline-shape RMSE | 0.568 |
| Isometric 2 held-out normalized skyline-shape RMSE | 0.928 |
| Channel centerline source length | ~578.48 original-image pixels |
| Water corridor path connected on grid | Yes (8-connected) |
| Center depth **assumption** | ~4.75–8.28 relative units |
| Sea surface at both ends | 0 relative |
| Volume **relative, physically uncalibrated** | ~88,063 mixed units |
| Alternative depth scenarios | ~44,031–132,094 mixed units |

**Warning:** because apparent horizontal dimensions are in source raster pixels and vertical values are inferred relative heights, even the "relative cubic" volume is a **mixed-scale numerical scenario**, **not physical m³**. Do not confuse normalized isometric errors with pixel errors or calibration accuracy.

## Outputs from original-image run

`height_relative_v3.npy`, `heightmap_relative_v3_16bit.png`, `mesh_v3.obj`, `river_water_surface_v3.obj`, `terrain_v3.html`, `terrain_classes_v3.png`, `river_bed_depth_v3.png`, `river_mask_v3.png`, `river_bank_v3.png`, `river_width_profile_v3.json`, `river_depth_profile_v3.json`, `river_volume_report_v3.json`, `river_centerline_v3.json`, `multiview_profiles_v3.png`, `isometric_silhouette_diagnostics.png`, `isometric_reference_vs_model_v3.jpg`, `terrain_constraints_v3.json`, `v3_report.json`.

## Remaining gate / V4 continuation on the SAME branch

Priorities: review distorted lateral silhouettes, preserve detailed cliffs rather than smoothing, refine branching estuary and banks without pretending the physical depth is known, carry uncertainty maps, and compare render orientation against both isometrics. A Studio import should occur in a SEPARATE test place only after human geometry review. Keep the PR **draft** and do not modify the playable map.

No external commercial models, paid services or GPU needed.
