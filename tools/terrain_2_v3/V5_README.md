# Terrain 2 — V5 geometry and hydrology

V5 builds an adaptive heightfield from V4, explores image-relative water width/depth scenarios, and compares candidate silhouettes against the original reference images. It does not recover the inaccessible original 3D mesh or establish physical scale.

## Inputs and reproduction

Use the original images from `RobloxGame_Terreno2_V2_analise_referencias.zip`, preserving their bytes and names. Generate V2/V3/V4 from those files, then run the audit and V5 pipelines:

```bash
python -m tools.terrain_2_v2.reconstruct_v2 --sources references --output output_v2
python -m tools.terrain_2_v3.terrain_v3 --sources references --v2 output_v2 --output output_v3 --grid 257
python -m tools.terrain_2_v3.refine_v4 --sources references --v2 output_v2 --v3 output_v3 --output output_v4
python -m tools.terrain_2_v3.audit_v5 --sources references --v2 output_v2 --v3 output_v3 --v4 output_v4 --output output_v5
python -m tools.terrain_2_v3.terrain_v5 --sources references --v2 output_v2 --v3 output_v3 --v4 output_v4 --output output_v5
```

## Current validation

- Original reference SHA-256 checks pass, including `orthographic_atlas.jpg` (`c43bd976a24e5fd8f3340fad325cb7db65da7ac3bddfbeaeedc53ed6ce3a52ee`). The atlas's right panel is the isometric view; its upper-left plan view is excluded from skyline scoring.
- V4 remains a reproducible visual **NO-GO** baseline. Its cardinal profile RMSEs are 7.27/7.34/17.61/20.17 px-equivalent; its isometric fit/holdout errors are 0.55741/0.91699.
- The current 257×257 candidate uses rock-weight floor 0.40, envelope blend 1.0, local peak restoration spread 4 grid cells for 4 rounds, and final smoothing sigma 0.50. Selection uses cardinal constraints and training views only; among candidates within 0.005 mean normalized RMSE of the best training fit, it selects the lowest mean cardinal profile RMSE, breaking ties by smallest field deviation from V4. The independent isometric views are scored after selection.
- Cardinal profile RMSEs are 7.44/7.39/16.65/18.71 px-equivalent. Their mean is 12.55, down from V4's 13.10 and the previous V5 candidate's 12.64; front/back change by +0.17/+0.05 while left/right improve by 0.96/1.46. Training errors are 0.54178 (`oblique_wireframe_1.jpg`) and 0.62015 (`oblique_side_render.jpg`), compared with V4's 0.55741 and 0.68018. The combined training score is 0.58096, within 0.00498 of the best accepted candidate's 0.57599.
- The independent `oblique_wireframe_2.jpg` error is 0.91643 against the V4 baseline 0.91699 (limit 0.92199). The atlas isometric error is 0.52574 against 0.57967. Both image-relative holdout gates pass.
- A separate candidate selected using cardinal RMSE and training scores (global blend 0.80, no smoothing) reduced mean cardinal RMSE to 11.98, but its independent wireframe-2 score was 0.93526 and failed the 0.92199 gate. It was rejected after holdout scoring; the passing candidate above remains selected. This records the orthographic/isometric trade-off without tuning to a holdout.
- A source-rock-weighted candidate (rock-weight floor 0.0, envelope blend 1.0, smoothing 1.0) fit the training views better (0.52453 / 0.62070), but its front/back profile errors rose to 9.57 / 9.58 px-equivalent from V4's 7.27 / 7.34, so it fails the per-view profile gate. The current selected field remains the best candidate under the declared joint constraints.
- A separate 513×513 resolution trial was reconstructed from the same SHA-256-verified references and evaluated against a V4 baseline generated at the same resolution. Its selected V5 field had 75,248 adaptive-mesh vertices and 148,797 triangles (versus 18,925/36,977 for the selected 257×257 field). Mean cardinal RMSE improved from 13.41 to 12.96 px-equivalent, and the atlas isometric score improved; however, the wireframe-2 holdout regressed from 0.87909 to 0.89932, exceeding the allowed V4+0.005 limit (0.88409). The run status was `V5_NO_GO_MULTIVIEW_GEOMETRY`, so the higher-resolution field is rejected and does not replace the 257×257 selected candidate. This shows that increasing grid density alone does not resolve the view conflict.
- Absolute visual fidelity remains **NO-GO**. Cardinal residuals remain material and require manual contour review. Opposing left/right references disagree by 34.33 px-equivalent, giving a 17.16 px best-case RMSE floor for one shared orthographic 2.5D projection.
- Water remains one connected component. Twenty-seven hydrology scenarios are exported: width multipliers 0.8/1.0/1.2 × relative depth multipliers 0.5/1.0/1.5 × bank-margin fractions 0.05/0.10/0.15 of local channel width. V5 bank widths are bounded to 0.5–3.0 grid cells. Depth, volume, and bank-margin values are relative assumptions, not observed bathymetry.
- The selected 257×257 field is SHA-256 `37cd79eb4c0bbeb35e6b52a3803a5bcef9ba5279402ce4117107185297e24948`. Its adaptive mesh has 19,136 vertices and 37,399 triangles. Error-guided refinement added 77 vertices over three rounds. On 36,821 covered dry-land grid samples, mesh-to-field RMSE is 0.095 relative height units, maximum 1.991, with four dry-land samples not covered by a retained triangle. The source views' 500-u scale bar remains image-relative, not meters or Roblox studs.

## Region hypotheses and open review

The V5 preview exports west/east mountain, cliff, plateau, central plain, and beach masks. The current counts are 2,818/2,729 mountain cells, 862 cliff cells, 1,431 plateau cells, 6,282 central-plain cells, and 3,540 beach cells. Region hypotheses now use source rock evidence and smoothed V5 relief; they remain heuristics, not physical classifications. Manual contour review remains open because the heightfield still shows block-like ridge patches that do not fully follow the source render.

Manual review of `orthographic_atlas.jpg` and `left_wireframe.png` confirms a visible shape gap: the source shows broad connected mountain slopes, while the current candidate has several sharp, isolated ridge peaks. The absolute-visual gate stays NO-GO. The source plan-view land silhouette has an approximate image-space bounding-box ratio of 1.696 (width/height), while the current reconstruction and Studio mapping use a square X/Z extent. This image ratio is a hypothesis only; the references do not establish a calibrated world aspect ratio.

An exploratory aspect sweep compared ratios from 0.6 to 2.0, including the same views currently labeled as multiview holdouts. Because those holdouts were inspected during the sweep, their scores are no longer independent evidence for choosing an aspect ratio. No swept ratio was selected and the 1.0 square field remains the current candidate. A future aspect-aware V5 revision must fit camera/aspect parameters on training views only, then validate on a genuinely untouched reference or a newly acquired calibrated view before updating the candidate or Studio bounds.

The V5 hydrology run now also exports proportional bank-margin masks and compares each channel-width hypothesis with the V2 `channel_corridor_observed` mask after resizing it to the 257×257 V5 grid. The diagnostic IoUs are 0.4244/0.4812/0.5126 for width multipliers 0.8/1.0/1.2 (precision 0.7238/0.6969/0.6634; recall 0.5064/0.6085/0.6928). This mask comes from the same original plan artwork used to estimate channel width, so the overlap is an internal consistency check, not independent validation; no width scenario is selected from it. The source land mask has two exterior-sea components before adding the channel and one after each generated channel mask is unioned with the sea mask; both centerline endpoints share the resulting component. This confirms raster connectivity under the source-mask hypothesis, not real-world hydrology.

An inventory of the extracted original reference package found no native terrain file (`.rbx*`, `.obj`, `.fbx`, `.glb`, `.gltf`, `.blend`, or `.stl`); `top_sparse_mesh.jpg` is a raster reference only. Recovering the original 3D shape therefore requires a new multi-view reconstruction or a separate source asset.

`terrain_regions_v5.png`, `adaptive_mesh_preview_v5.png`, `multiview_comparison_v5.png`, `isometric_comparison_v5.png`, `side_render_training_v5.png`, and `atlas_isometric_holdout_v5.png` are the principal review artifacts. The latest original-reference reconstruction is [GitHub Actions run 38906611785](https://github.com/dreyvinixz/RobloxGame/actions/runs/38906611785); its JSON report records source hashes, candidate scores, holdouts, relative water scenarios, and the error-guided mesh counts.

## Roadmap after V4

1. **V5 geometry/hydrology:** retain the adaptive mesh and relative water scenarios as candidates. Manually review or improve ridge, cliff, plateau, beach, and channel boundaries against the original views. Preserve source hashes.
2. **V5 acceptance:** the relative multiview gate passes. Complete manual overlay review before accepting absolute visual fidelity or using the relief as final geometry.
3. **V6 Studio test place:** the latest candidate (`37cd79eb4c0bbeb35e6b52a3803a5bcef9ba5279402ce4117107185297e24948`) is imported in the isolated `devtest3.rbxl` session. Readback confirms 377,149 occupied voxels, exact 0.5-stud-quantized heights across 36,825 dry columns, and one connected water component. Save/reopen and adaptive-mesh-to-collision comparison remain open.
4. **V7 playability:** on the latest candidate, all four jump-enabled one-client routes from the opt-in spawn reached the beach/ridge targets with 100 health. No-jump pathfinding succeeds to both beaches but returns `NoPath` to both ridges. Ten current-field sightline checks are unobstructed, so terrain alone offers limited cover. The 9-second CPU A/B is inconclusive; GPU/memory, sustained performance, multiplayer, slope criteria, combat, and future asset footprints remain open.

Current handoff: **V4 closed as visual NO-GO; latest V5 cardinal mean improves to 12.55 and both independent holdouts pass, but absolute visual fidelity remains NO-GO; V6 latest candidate is imported and readback-verified in the unsaved Studio session; V7 jump-enabled routes pass for one client, while save/reopen, ridge access without jumps, slope criteria, sustained performance, multiplayer, and combat gates remain open.** Production place and `main` remain untouched.
