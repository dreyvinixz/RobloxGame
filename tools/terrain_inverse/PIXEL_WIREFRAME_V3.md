# V3 experimental: extract polygons from actual AI-art image pixels

**This is a new input-driven 2D CV stage, not a recovered original 3D mesh.** The prior `island.py` output is a procedural baseline and is never loaded by `extract_wireframe.py`.

## Run with the user-supplied original wireframe screenshot

The screenshot received in chat was 1619 × 971 pixels, SHA-256:
`c166e9d711cb70b09feeee5652f2db82a587675ae0124c762532f54846b5d575`.

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m tools.terrain_inverse.extract_wireframe \
  --image /path/to/image-original.png \
  --output wireframe-original
# Recommended diagnostic region, at original image coordinates:
python -m tools.terrain_inverse.extract_wireframe \
  --image /path/to/image-original.png \
  --roi 700 300 1080 570 \
  --output wireframe-central
```

Unlike the original generator, missing raw image input is an error. The GitHub Actions CI validates the algorithm with **synthetic tests only** because the source image has not been committed to the repository. The full screenshot was analyzed locally; resulting overlays and JSON report were made available in the conversation as `wireframe_pixel_extraction_v3.zip`. To make CI analyze the real source, the image must be supplied as a GitHub Actions-accessible input in an additional step. Do not claim the synthetic workflow processed the reference screenshot.

## Method

1. Convert the original color raster to luminance.
2. Estimate local background via 11px median filter; detect locally dark 1–3px strokes.
3. Remove isolated connected components, skeletonize observed line evidence.
4. Extract Hough line segments and candidate skeleton junction clusters in **original image pixel coordinates**.
5. Close tiny gaps; identify closed light regions, approximate boundaries to 3–6 vertices and score edge support against the observed dark raster. **These faces are only 2D hypotheses**; no arbitrary Delaunay diagonals are added.
6. Export overlays, masks, pixel coordinates, source SHA-256, parameters and warnings.

## Local first-pass measurements (not verified polygon counts)

| Region | Line segment candidates | Junction candidates | Closed face candidates | 3-sided | 4-sided |
|---|---:|---:|---:|---:|---:|
| Whole 1619x971 screenshot | 2,009 | 3,595 | 331 | 87 | 159 |
| Crop x700:1080, y300:570 | 295 | 518 | 34 | 14 | 13 |

The overlays reveal **numerous false positives** from trees, roads, shadows, rocky textures and other 2D line work. It is incorrect to conclude that the original terrain had 87 triangle faces, or 331 mesh polygons. On the center plains, many of the true-looking cells are quadrilaterals; near cliffs, triangular facets are more plausible.

## Outputs

- `observed_wireframe_overlay.png`: cyan pixels = observed centerlines; magenta dots = possible intersections.
- `closed_cell_hypotheses_overlay.png`: green = 3-sided, orange = 4-sided, magenta = 5–6 sided **pixel hypotheses**.
- `observed_line_mask.png`, `observed_skeleton.png`: raw 2D analysis intermediates.
- `wireframe_report.json`: source hash, dimensions, pixel-space line segments, intersections, closed cells and caveats.

## Correct next steps

- Cleanly segment trees, terrain, rock, roads and water, with a human-inspectable confidence map, before reconstructing topology.
- Group approximately parallel/converging projected grid families and solve a camera model using only consistent line observations.
- Match image-space corners to corresponding points in orthographic references with ambiguity flags.
- Solve **3D vertex coordinates** under image reprojection constraints; report pixel-space re-render error against the input screenshot. Do not claim geometry identity: AI illustrations may contain inconsistent 2D crossings and impossible 3D vertices.
- Decide where quads, triangulated irregular meshes, separate cliff meshes and non-heightfield structures are necessary.
