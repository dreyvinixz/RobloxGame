# V5 — First source-image anchored 2.5D terrain reconstruction

**Status: initial experimental estimate, not an accepted 3D reconstruction.**

The project has reached its first 3D export based on actual source images and explicitly annotated correspondences, rather than the old synthetic Gaussian ridge generator. **The shape is still not faithful enough for the Roblox game.** See issue #67 and draft PR #68.

## Inputs and provenance

Mandatory:

1. `--top-atlas`: full 1536x1024 user-created AI atlas containing the top-view image.
2. `--clean-oblique`: 1619x971 AI-cleaned isometric reference.
3. `--original-wireframe`: 1619x971 original wireframe reference.
4. `--landmarks`: editable JSON of personally identified corresponding shore points and mountain peaks (the repository includes initial, uncertain candidate matches).

No imagery is silently replaced with a procedural generator. The source files are not currently checked into the Git repository; **GitHub Actions uses clearly labeled synthetic input fixtures only**. The full-reference local run and its report, viewer, heightmap and OBJ were made available separately in the chat.

### Reproduce with the actual reference images

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt

python -m tools.terrain_inverse.reconstruct_v5 \
  --top-atlas /path/to/vistasortograficas.png \
  --clean-oblique /path/to/clean_wireframe.png \
  --original-wireframe /path/to/original_wireframe.png \
  --landmarks tools/terrain_inverse/v5_landmarks.json \
  --grid 257 --output terrain-v5-real
```

Then open `terrain-v5-real/terrain_v5.html` for interactive 3D inspection and compare `wireframe_reprojection_candidate.png` against the source. Altering any pixel source changes its SHA-256 and is recorded in `v5_report.json`.

## Engineering method and explicit assumptions

- Segment water/land **directly from the top RGB image**. The segmentation can still confuse dark blue cliff shadows; inspect `top_land_source_segmentation.png`.
- Initial coastal registration uses an **affine ground-plane transform** fitted via RANSAC from manually matched shoreline points. It is *not* a solved camera matrix with intrinsics/extrinsics.
- Each matched mountain peak has a proposed top-view xy position and a screen position in the cleaned oblique image. A provisional altitude in arbitrary units is inferred from the **vertical difference** between its screen position and the affine zero-height ground-plane projection. Reject matches with large horizontal discrepancies.
- Thin-plate RBF interpolation of shoreline zero-height anchors, accepted mountain peak estimates and marked central lowland anchors creates a full heightfield. High-frequency image-derived luminance and rock color contribute weak texture detail; **no random Gaussian mountain generator is used**.
- Export is a **regular-grid triangulation** of this heightfield, not the triangular face topology that V4.2 tried to observe. The previous 2D graph remains separate because its connectivity has not been validated.
- A synthetic wireframe preview is projected back into the original image using the approximate affine transform plus assumed vertical screen displacement. This is a **debugging picture, not calibrated inverse rendering**.

## Actual first-pass source-image run (2026-10-16)

| Diagnostic | First-pass result |
|---|---:|
| Grid | 257x257 |
| OBJ vertices | 66,049 |
| OBJ triangles | 131,072 |
| Manually marked shoreline correspondences | 13 |
| RANSAC shoreline inliers | 7 |
| Median reprojection error on accepted coast points | 15.38 px |
| Median error across all coast points | 33.91 px |
| Accepted mountain hypotheses | 10 |
| Rejected inconsistent mountain hypotheses | 4 |
| Relative height maximum | 130.58 (arbitrary units) |
| Closest original Canny edge to candidate wireframe | 5.11 px mean (very weak diagnostic) |

**Interpretation:** the estimated camera is substantially inconsistent with the source at some coastlines. A 5.11 px mean distance to the nearest generic Canny edge is not proof of terrain accuracy: Canny sees terrain texture, objects, rock contours and UI grid. The projected wireframe is visibly misaligned. **No 3D or topological fidelity percentage is justified.**

Hashes of real input files used locally:

- Atlas: `f6fb7a272b3f640ca93141f00288823c45b4d419ddd98518e78bcc6313fb4061`
- AI-clean oblique: `e46042200149813df961bfed8c2b9366079d70f526f09ed4775b7d096b3c8240`
- Original wireframe: `c166e9d711cb70b09feeee5652f2db82a587675ae0124c762532f54846b5d575`

## Outputs

`height_relative.npy`, `heightmap_16bit.png`, `terrain_hypothesis.obj`, `terrain_v5.html`, `top_land_source_segmentation.png`, `top_water_source_segmentation.png`, `terrain_mask.png`, `height_preview.png`, `topview_annotated.png`, `camera_registration_overlay.png`, `wireframe_reprojection_candidate.png`, `reprojected_wireframe_line_mask.png`, `camera.json`, `v5_report.json`.

The PNG 16-bit heightmap linearly encodes **relative altitude -8..205** and is not a georeferenced DEM. Roblox Studio scale and material import are intentionally not automated.

## V5.1 priorities, before claiming any reconstruction success

1. Fix the inconsistent shoreline and peak correspondences using manually reviewed top/oblique landmark overlays. Reduce coastal reprojection error and report geographically stratified residuals, not only accepted-inlier median.
2. Estimate a physically plausible camera (orthographic/weak perspective or constrained perspective) with explicit scale and uncertainty. Do not optimize unknown camera and unknown height without additional constraints.
3. Use the observed V4.2 line graph only after mapping its 2D vertices consistently into 3D; align a set of corresponding grid points and measure edges against the original wireframe.
4. Improve rugged rock relief: the current RBF creates broad hills and misses detailed crags, ridges and cliffs; optionally incorporate depth priors after benchmarking.
5. Compare actual rendered 3D with the original screenshot using mask-aware metrics and manually validated landmark matches; avoid texture-driven Canny similarity.
6. Import to a SEPARATE Roblox Studio test place only after a human-reviewed comparison. The production NO-GO status remains unchanged.

## GitHub Actions test scope

`.github/workflows/terrain-image-v5.yml` runs five unit tests on deterministic **synthetic source images** and creates a synthetic demo artifact; it does not download photos from this chat, and it does not establish reconstruction fidelity.
