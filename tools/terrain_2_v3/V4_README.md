# Terrain 2 V4 — Ridge and Sea-to-Sea Corridor Refinement

**Status: reproducible against the original images; fidelity review NO-GO.** The output is a relative 2.5D hypothesis, not recovered geometry.

This V4 is a follow-up to V3 in the **same development branch**, not the original island V4 work. PR #73 already landed the V3 code in `dev`; PR #74, targeting `dev`, contains the V4-only refinement.

## Run on the user's original images

The source image folder `references/` must be extracted from the exact-image bundle supplied to the user in the conversation. They are **not checked into GitHub**.

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_2_v2.reconstruct_v2 \
    --sources references --output output_v2
python -m tools.terrain_2_v3.terrain_v3 \
    --sources references --v2 output_v2 --output output_v3 --grid 257
python -m tools.terrain_2_v3.refine_v4 \
    --sources references --v2 output_v2 --v3 output_v3 --output output_v4
```

The V4 reader checks all original input SHA-256 values against `output_v3/v3_report.json`, and fails instead of substituting generated mountains.

## V4 operations

- Extract weak rock-surface high-frequency residual from the actual top render, in the V3 mountain/rock candidate regions.
- Test controlled smoothing of the V3 field plus source-derived ridge residuals, restore all four cardinal skyline maxima, and select from the first isometric reference only. Keep the second isometric as a held-out check.
- Connect the **northern sea** and **southern bay** ends of the source-based waterway using short source-supported or flagged uncertain additions; do not impose an artificial downhill lake-to-sea profile, as both ends meet sea level.
- Carry ambiguous front/back/left/right disagreements as a *heuristic relative mismatch map* (not a measured confidence interval).
- Generate the refined relative heightmap and OBJ and side/isometric comparisons; copy the assumed V3 bathymetry width/depth/volume scenario files unchanged instead of pretending better measured depths.

## Output / inspection

- `height_refined_v4.npy`, `heightmap_refined_v4.png`, `mesh_refined_v4.obj`, `terrain_v4.html`.
- `river_ocean_join_v4.png`, `ocean_extension_uncertain_v4.png`, `uncertainty_v4.png`.
- `multiview_comparison_v4.png` shows reference, V3, and V4 in all four cardinal profiles; `isometric_comparison_v4.png` shows both isometric references with V3 and V4; `render_isometric_v4.png`, `isometric_reference_vs_model_v4.jpg`.
- `final_report_v4.json`: source hashes, per-view before/after pixel-equivalent RMSE, normalized isometric fit, upstream/downstream water connection and changed regions.

## CI and acceptance

The V4 workflow runs `python -m unittest discover -s tests -p 'test_terrain2_v4.py' -v` with synthetic fixtures; [workflow success](https://github.com/dreyvinixz/RobloxGame/actions/runs/38866481017). It does **not** download or assess the user's original 16 images. Results from synthetic tests must not be described as visual accuracy.

**Original-image review result:** V4 preserves the V3 cardinal predictions exactly. Errors are 7.27 / 7.34 / 17.61 / 20.17 px-equivalent (front/back/left/right). The chosen field uses smoothing sigma 2, full blend, and ridge residual amplitude 6. The normalized, uncalibrated fit-isometric diagnostic improves from 0.56848 to 0.55741; the held-out view improves from 0.92841 to 0.91699. Both remain visibly misaligned, and the cardinal errors remain. Visual review is **NO-GO for fidelity**. Do not describe V4 as a validated reconstruction or move to Roblox acceptance. V5 must address the remaining shape mismatch and keep its second isometric held out. Do not modify `main` or the production place.
