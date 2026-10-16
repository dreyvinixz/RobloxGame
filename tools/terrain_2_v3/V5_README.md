# Terreno 2 — V5: audit before geometry refinement

V5 starts from V4 on a **single branch**. This first stage is an **original-image fidelity audit**, not a claim that V4 reproduces the inaccessible original 3D mesh.

## Inputs
Extract the 16 user images from `RobloxGame_Terreno2_V2_analise_referencias.zip`, keeping their original bytes and names. V2/V3/V4 output directories must be generated from these images, not synthetic CI fixtures.

```bash
python -m tools.terrain_2_v2.reconstruct_v2 --sources references --output output_v2
python -m tools.terrain_2_v3.terrain_v3 --sources references --v2 output_v2 --output output_v3 --grid 257
python -m tools.terrain_2_v3.refine_v4 --sources references --v2 output_v2 --v3 output_v3 --output output_v4
python -m tools.terrain_2_v3.audit_v5 --sources references --v2 output_v2 --v3 output_v3 --v4 output_v4 --output output_v5
```

## Acceptance gates
- Original-image SHA-256 checks must pass.
- Report V3 and V4 errors **separately** for front/back/left/right and both isometrics. Isometric 2 is held out.
- Water must form a single connected raster component; manually inspect both sea mouths and any uncertain bridge.
- Check top-view island contour, coastline, river-bank width, mountain ridges, and cliff silhouette by overlay with source.
- Do not treat water depth/volume as observed truth.
- Mark visual review **NO-GO** until reviewed; tests on synthetic fixtures are only code correctness.
- Only after evidence review proceed to V5 adaptive mesh, feature-edge constraints and optimization of side/isometric views; evaluate changes on held-out imagery.
- Do not modify playable Roblox Studio place or `main`.

The audit script intentionally sets `pass: false` until manual and independent 3D geometry validation are completed.
