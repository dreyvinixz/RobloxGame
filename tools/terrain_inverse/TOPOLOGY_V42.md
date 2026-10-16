# V4.2 — Finish the deferred 2D work before V5

**Status: experimental image-space topology, NOT the user's reconstructed 3D island.** This stage is deliberately restricted to normalization/topology QA, preserving dense original wireframe evidence without claiming original triangle counts or altitudes.

## Source-first execution

Two *actual user-supplied* AI images are inputs: original wireframe screenshot plus AI-cleaned image. A valid V4.1 output directory is mandatory; its `v41_report.json` SHA-256 values are checked against both files, then V4.2 uses V4.1 pixel masks and densely traced lines. It never imports `island.py`, never generates Gaussian mountains, and never hallucinates edges via an inpainting step.

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_inverse.reference_fusion_v41 \
  --original /path/original.png --clean /path/clean.png --output v41-real
python -m tools.terrain_inverse.topology_refinement_v42 \
  --original /path/original.png --clean /path/clean.png \
  --v41 v41-real --output v42-real
```

Optional `--annotation-mask /path/ground_truth_lines.png` accepts a *separately manually labeled* black/white pixel mask at the original resolution. It computes 2px-tolerant precision, recall and F1. Without human-labeled pixels the independent metric status must be `not_available`, not invented.

The original and cleaned user images are not stored in this repository. Therefore the V4.2 GitHub Action checks execution with **synthetic test images**, not the user's imagery. Full user-image analysis was run separately in the working session. The files and their hashes are preserved inside the result reports.

## V4.2 operations

1. Input provenance check and reuse of V4.1 separate observed/water/bright/cliff masks.
2. Filter original-supported segments; keep gaps only with sufficient original pixel evidence. Preserve high-, medium- and hypothesis-class sources.
3. Fill *tiny* 3px image-space gaps for cell hypothesis discovery only. Never treat this as recovered terrain geometry.
4. Recover image-space enclosed 3–6 sided cells. Mark 5–6 sides separately as unclassified, and submit only 3–4 sided candidates for actual face-graph construction.
5. Merge nearby corners and audit shared edges, disconnected components and nonmanifold incidences using the V4 graph checker.
6. Export original/filtered/face overlays and a report distinguishing observed coverage vs topology correctness.

## Outputs

`v42_lines.json`, `v42_vertices.json`, `v42_edges.json`, `v42_faces.json`, `v42_unclassified_cells.json`, `v42_report.json`, `v42_filtered_edges_overlay.png`, `v42_faces_overlay.png`, `v42_comparison.png`, `v42_gap_closures_unverified.png`.

**`v42_vertices.json` and `v42_edges.json` are the proposed face graph**, not a complete triangulated 3D terrain. The dense line graph remains separately in `v42_lines.json`.

## Initial local research prototype diagnostics (original image, not independent GT)

A local broader prototype using the same input and thresholds (but a slightly different face consolidation implementation than the committed script) produced 10,281 retained line segments, 365 provisional closed contours including 60 triangles and 126 quadrilaterals, 17 shared face edges and 358 face components. It also lowered observed-stroke coverage from 0.817 to 0.790 under a shared local test mask (not the earlier 0.891 V4.1 coverage metric, which used a different rasterization protocol). The filter **does not establish better mesh connectivity**.

These are **diagnostics from the local research prototype, not certified results of the version committed here**. Run the committed tool on the exact images and inspect its own `v42_report.json` for comparable numbers.

## Acceptance gate

- Do not select a winner based only on thousands of lines or on in-sample coverage.
- To accept dense topology, provide small manually annotated pixel masks from distinct regions (beach, central plain, left and right cliffs). Assess edge precision/recall/F1 and number of actual shared-face adjacencies.
- Failed correspondence, nontrivial disconnected components, and original-vs-clean inconsistencies must be called out.
- If this fails: improve region-specific segmentation and topology, **not** automatic 3D triangulation.
- **No camera model, depth, physical relief, Roblox Studio QA or publication approval is claimed.**

A future V5 can use these 2D constraints for inverse rendering once the annotated V4.2 gate passes.
