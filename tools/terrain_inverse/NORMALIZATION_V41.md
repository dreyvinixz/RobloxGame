# V4.1 — Fast-track normalization and traced grid families

**Status: implemented as a 2D evidence experiment. NOT yet a continuous 3D mesh.** The original AI screenshot and independently AI-cleaned screenshot are **mandatory** inputs. V1/V2 procedural terrain generation is **not imported or invoked**.

## What changed

1. The original wireframe is the only authoritative source of visible lines and vertices.
2. The AI-cleaned drawing is **weak auxiliary evidence**, geometrically registered to the original using ORB matches and a robust RANSAC homography. If registration fails, the algorithm falls back to **original-only** evidence and records rejection; it never trusts unaligned pixels.
3. Creates heuristic water, bright-terrain, cliff-candidate, changed-content and uncertain masks. These are **not** independently validated semantic segmentations. No inpainting is used for evidence.
4. Dark line observations are extracted separately from light terrain and dark cliffs with local black-hat filtering, skeletonization and Hough line recovery. Clean-only lines are not promoted to trusted observations without supporting gradients/lines on the original.
5. Clusters directions into two **approximate angular line families** using doubled-angle k-means. This is an initial local orientation prior, not the recovered projected terrain grid.
6. Bridging of small endpoint gaps (3–10 px) requires near-collinearity and some original pixel evidence; weak hypotheses remain flagged.
7. Exports JSON line/vertex graphs, disjoint zone overlays, masks, a side-by-side screenshot and image-space diagnostics; faces are deliberately left empty because they have not been recovered.

## Reproduce on the actual two images

From project root:

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_inverse.reference_fusion_v41 \
  --original '/path/to/original-wireframe.png' \
  --clean '/path/to/cleaned-wireframe.png' \
  --output v41-real \
  --baseline-report '/path/to/V4/topology_report.json'
```

The images supplied in this chat are both 1619x971 pixels. SHA-256 values of the **exact locally analyzed files**:

- Original: `c166e9d711cb70b09feeee5652f2db82a587675ae0124c762532f54846b5d575`
- AI-cleaned: `e46042200149813df961bfed8c2b9366079d70f526f09ed4775b7d096b3c8240`

**Important:** Original images are **not committed** to GitHub. The Actions workflow uses explicit synthetic test images and does **not** claim to process the original reference. A separately shared local experimental result ZIP contains masks, overlays, JSON outputs and its runnable implementation.

## First local image benchmark (prototype, subject to independent replication)

| Diagnostic | V4 | V4.1 |
|---|---:|---:|
| Candidate line-graph components | 618 | 2,261 |
| Original-stroke coverage using the SAME V4.1 original-stroke mask with 2px tolerance | 14.8% | 89.1% |
| Original image to auxiliary clean registration | — | 209 inliers, 0.922px median error |
| Observed Hough segments after zoning | — | 10,101 |
| Gap bridges proposed | — | 2,304 |

**Interpretation:** the new pipeline observes substantially more of the drawn wireframe, but it also extracts far more fragments, and the absolute number of disconnected components **increases**, not decreases. The graph objects and thresholds are also not identical to V4. Hence **connectivity has NOT passed acceptance**. Do not treat 89.1% in-sample stroke coverage as geometric correctness; detected foliage, contours, shadows and port lines may contribute false positives. Comparing V4 to V4.1 on the same mask only controls the denominator, not the detector bias.

## Outputs

- `water_mask.png`, `terrain_confident_mask.png`, `cliff_candidate_mask.png`, `uncertain_mask.png`, `changed_content_mask.png`.
- `original_observed_strokes.png`, `original_withheld_strokes.png`, `fused_stroke_mask.png`, `normalized_observation.png`.
- `grid_light_overlay.png`, `grid_cliff_overlay.png`, `grid_families_light.json`, `grid_families_cliff.json`.
- `v41_vertices.json`, `v41_edges.json`, `v41_faces_candidates.json` (empty by design).
- `v41_topology_overlay.png`, `comparison_original_clean_v41.png`, `v41_report.json` (source hashes and detailed caveats).

Note: `terrain_confident_mask.png` means **high-contrast candidate ground**, not verified actual ground.

## Acceptance gate before adding camera, altitudes or polygons

1. Manually label several small terrain patches with actual drawn grid lines, rock edges and false-object lines.
2. Compute edge precision, recall and F1 versus those **independent** labels, plus whole-image coverage. Improve graph continuity on actual terrain segments; avoid blindly adding paths.
3. Retain distinctions: original observed, AI-clean corroborated and weak gap hypothesis.
4. Require a connected local grid in selected bright patches before extrapolating to cliffs. Report performance by spatial patch, not only global counts.
5. Only then estimate 3D coordinates/camera and report reprojection against the source render.

No Blender/Roblox Studio playtest, heightfield recovery or production map import is claimed.
