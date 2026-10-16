# Codex handoff — exact input reference images and V5.1 status

## Repo state (verified 2026-10-16)

- **`dev` includes PR #68 (V5 baseline) and PR #69 (the V5 lake→river→harbor fix).**
- `tools/terrain_inverse/reconstruct_v5.py` loads the optional `hydrology` landmark data.
- `tools/terrain_inverse/hydrology_v5.py` traces the lake/river/harbor waypoint path, carves a continuous rasterized channel and exports a separate water surface.
- `tools/terrain_inverse/v5_landmarks.json` contains the river hypotheses.
- `tests/test_hydrology_v5.py` checks connected water masks and downstream nonincreasing waterline.
- `tools/terrain_inverse/RIVER_FIX_V5.md` documents the **experimental** correction and uncertainties.
- The earlier `RECONSTRUCTION_V5.md` roadmap continues to call for real camera calibration and image-based fidelity work. **A connected river is not a complete calibrated V5.1**.

## Original imagery is not in GitHub

The three source images used in local experiments were user-provided AI-generated raster images. Supply the **original binary files**, not screenshots of screenshots, to the Codex workspace:

| Proposed workspace filename | Original dimensions | SHA-256 |
|---|---:|---|
| `terrain_sources/atlas_ortografico.png` | 1536×1024 | `f6fb7a272b3f640ca93141f00288823c45b4d419ddd98518e78bcc6313fb4061` |
| `terrain_sources/wireframe_original.png` | 1619×971 | `c166e9d711cb70b09feeee5652f2db82a587675ae0124c762532f54846b5d575` |
| `terrain_sources/wireframe_limpo.png` | 1619×971 | `e46042200149813df961bfed8c2b9366079d70f526f09ed4775b7d096b3c8240` |

The user has a separate archive containing these original images. **This document does not imply the images are part of this GitHub repository or accessible to any agent**.

Run from the root of a workspace where those three images have actually been extracted:

```bash
cd terrain_sources && sha256sum -c SHA256SUMS && cd ..
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m unittest discover -s tests -p 'test_*v5.py' -v
python -m tools.terrain_inverse.reconstruct_v5 \
  --top-atlas terrain_sources/atlas_ortografico.png \
  --clean-oblique terrain_sources/wireframe_limpo.png \
  --original-wireframe terrain_sources/wireframe_original.png \
  --landmarks tools/terrain_inverse/v5_landmarks.json \
  --grid 257 --output out/terrain_v5_1
```

Then inspect `out/terrain_v5_1/terrain_v5.html`, `river_reference_overlay.png`, `water_connected_grid.png`, `terrain_hypothesis.obj`, `river_water_surface.obj` and `v5_report.json`.

## Roblox Studio boundary

`Place1` is not a safe automatic destination if it holds the user's current work. Do not replace it. If `Place2` or another sandbox place is inaccessible, request the user to open or create a separate test place and grant Codex access. There is no verified automated Roblox Studio import/QA in this repository.

## No overclaiming

- The V5 model remains a 2.5D **inference with arbitrary relative altitudes**. It does not recover a unique original mesh from AI-generated views.
- Source annotations are manually specified, and AI-generated multiview references may be inconsistent.
- GitHub Actions passing synthetic-image tests proves CI execution and invariants, **not** original-image fidelity.
- Remain on `dev` for integration and create separate work branches / PRs targeting `dev`, not `main`.
