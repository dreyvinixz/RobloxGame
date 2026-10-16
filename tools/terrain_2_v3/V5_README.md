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
- The selected profile-restored candidate uses rock-weight floor 0.20, envelope blend 1.0, local peak restoration spread 4 grid cells for 4 rounds, and final smoothing sigma 0.50. Selection uses cardinal constraints and training views only; among candidates within 0.005 mean normalized RMSE of the best training fit, it minimizes field deviation from V4. Both independent isometric views are evaluated after selection.
- Cardinal profile RMSEs are 7.50/7.42/16.47/19.17 px-equivalent. Their mean improves from 13.10 to 12.64; front/back regress by 0.23/0.08 while left/right improve. Training errors are 0.53832 (`oblique_wireframe_1.jpg`) and 0.61366 (`oblique_side_render.jpg`), down from V4's 0.55741 and 0.68018. The combined training score improves from 0.59155 for the previous V5 candidate to 0.57599.
- The independent `oblique_wireframe_2.jpg` error improves from 0.91699 to 0.91294; the maximum permitted value is 0.92199. The atlas isometric error improves from 0.57967 to 0.53143. Both image-relative holdout gates pass.
- A separate candidate selected using cardinal RMSE and training scores (global blend 0.80, no smoothing) reduced mean cardinal RMSE to 11.98, but its independent wireframe-2 score was 0.93526 and failed the 0.92199 gate. It was rejected after holdout scoring; the passing candidate above remains selected. This records the orthographic/isometric trade-off without tuning to a holdout.
- A source-rock-weighted candidate (rock-weight floor 0.0, envelope blend 1.0, smoothing 1.0) fit the training views better (0.52453 / 0.62070), but its front/back profile errors rose to 9.57 / 9.58 px-equivalent from V4's 7.27 / 7.34, so it fails the per-view profile gate. The current selected field remains the best candidate under the declared joint constraints.
- A separate 513×513 resolution trial was reconstructed from the same SHA-256-verified references and evaluated against a V4 baseline generated at the same resolution. Its selected V5 field had 75,248 adaptive-mesh vertices and 148,797 triangles (versus 18,925/36,977 for the selected 257×257 field). Mean cardinal RMSE improved from 13.41 to 12.96 px-equivalent, and the atlas isometric score improved; however, the wireframe-2 holdout regressed from 0.87909 to 0.89932, exceeding the allowed V4+0.005 limit (0.88409). The run status was `V5_NO_GO_MULTIVIEW_GEOMETRY`, so the higher-resolution field is rejected and does not replace the 257×257 selected candidate. This shows that increasing grid density alone does not resolve the view conflict.
- Absolute visual fidelity remains **NO-GO**. Cardinal residuals remain material and require manual contour review. Opposing left/right references disagree by 34.33 px-equivalent, giving a 17.16 px best-case RMSE floor for one shared orthographic 2.5D projection.
- Water remains one connected component. Nine width/depth scenarios are exported (width multipliers 0.8/1.0/1.2 crossed with depth multipliers 0.5/1.0/1.5). All depth and volume values are relative assumptions, not observed bathymetry.
- The selected 257×257 field is SHA-256 `ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`. The original artifact mesh had 18,925 vertices and 36,977 triangles. An error-guided re-export of that exact field now has 19,070 vertices and 37,266 triangles; only 145 vertices were added. On 36,821 covered dry-land grid samples, piecewise-linear mesh-to-field RMSE is 0.096 relative height units, maximum 1.994, with four dry-land samples not covered by a retained triangle. This refinement changes the mesh sampling only; the selected heightfield and its multiview scores remain unchanged. The four source orthographic views each show a labeled 500-u scale bar of 245 pixels; this verifies only an image-relative unit, not meters or Roblox studs.

## Region hypotheses and open review

The V5 preview exports west/east mountain, cliff, plateau, central plain, and beach masks. The current counts are 2,818/2,729 mountain cells, 862 cliff cells, 1,431 plateau cells, 6,282 central-plain cells, and 3,540 beach cells. Region hypotheses now use source rock evidence and smoothed V5 relief; they remain heuristics, not physical classifications. Manual contour review remains open because the heightfield still shows block-like ridge patches that do not fully follow the source render.

An inventory of the extracted original reference package found no native terrain file (`.rbx*`, `.obj`, `.fbx`, `.glb`, `.gltf`, `.blend`, or `.stl`); `top_sparse_mesh.jpg` is a raster reference only. Recovering the original 3D shape therefore requires a new multi-view reconstruction or a separate source asset.

`terrain_regions_v5.png`, `adaptive_mesh_preview_v5.png`, `multiview_comparison_v5.png`, `isometric_comparison_v5.png`, `side_render_training_v5.png`, and `atlas_isometric_holdout_v5.png` are the principal review artifacts. The latest original-reference reconstruction is [GitHub Actions run 38904150817](https://github.com/dreyvinixz/RobloxGame/actions/runs/38904150817); its JSON report records source hashes, candidate scores, holdouts, relative water scenarios, and the error-guided mesh counts.

## Roadmap after V4

1. **V5 geometry/hydrology:** retain the adaptive mesh and relative water scenarios as candidates. Manually review or improve ridge, cliff, plateau, beach, and channel boundaries against the original views. Preserve source hashes.
2. **V5 acceptance:** the relative multiview gate passes. Complete manual overlay review before accepting absolute visual fidelity or using the relief as final geometry.
3. **V6 Studio test place:** the selected profile-restored field (`ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`) is imported in the isolated `devtest3.rbxl` session and its voxel/material/water readback matches the recorded candidate. The session is still unsaved; persist and reopen it after the visual review and scale decision.
4. **V7 playability:** all four jump-enabled one-client routes were repeated on the latest field and reached their markers with 100 health. Server-controlled `Humanoid:MoveTo()` with auto-jump disabled reached both beaches and the west ridge; the east ridge returns `NoPath` without jumps. `MatchService` now supports an opt-in test spawn (`Workspace.Terrain2TestMode=true` plus `Workspace.V7_TestSpawn`); default Play startup used it and placed the character in the test area at 100 health. A control run with the flag absent preserved `FrontlineArena.EntryPoints.Spawn_WestEntry`. The test flag is in the unsaved Studio session, and persistence remains open. Ten candidate-anchor sightline checks were unobstructed, so terrain alone offers limited cover. The steepest jump-enabled waypoint transition is 10.35 studs, the short paired CPU A/B capture was inconclusive, and multiplayer navigation, cover, combat criteria, and future asset footprints remain open.

Current handoff: **V4 closed as visual NO-GO; the latest V5 improves the joint training score and both independent holdouts but remains absolute visual NO-GO; V6 has the latest V5 candidate imported and read back in an unsaved test session; V7 has four one-client route arrivals but remains unaccepted for spawn, slope, sustained performance, multiplayer, and combat gates.** Production place and `main` remain untouched.
