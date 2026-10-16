# Inverse terrain from AI-generated island concept imagery

**EXPERIMENTAL APPROXIMATION — not recovered original geometry or a Roblox production map.** See issue #67.

## Reference and method

The user supplied AI-generated rendered, wireframe and orthographic illustrations. We digitized the shoreline from the top panel of `vistasortograficas.png` (crop x=14..618, y=33..518 pixels) using blue-water RGB segmentation, morphology, an outer-contour trace and manual correction. The polygon is committed as `COAST` within `island.py`; the original raster images are not checked in. The other views were used to *qualitatively* identify relative mountain positions; they are not guaranteed mutually consistent projections of one underlying 3D scene.

The model represents altitude h(x,y) as an elevation matrix under normalized horizontal coordinates [0,1]^2. Shoreline is a polygon mask. The elevation is a sum of anisotropic Gaussian ridges, smooth basin attenuation, seeded multiscale filtered stochastic perturbations, a signed-distance coastal taper and explicit river/lake cuts. The heightmap is an **inverse-design hypothesis constrained by visual landmarks**, *not* a camera-calibrated pixel-to-depth reconstruction, hydraulic simulation or physical erosion solver.

Landmark targets: mountains west/east, north beach, traversable central valley with occasional hills, a central-east lake and river, and a sheltered southern harbor. Trees, streets, buildings, quays and docks are not reconstructed as 3D structures; we export categorical surface materials only.

## Reproduce (Python 3.11 or newer)

```bash
python -m pip install -r tools/terrain_inverse/requirements.txt
python -m unittest discover -s tests -p 'test_terrain_inverse.py' -v
python -m tools.terrain_inverse.island --grid 257 --seed 20261015 --output terrain-output
```

In GitHub Actions select the **Experimental inverse terrain reconstruction** workflow, or push commits to this experimental branch. Ubuntu runs the tests and generator, then uploads a 30-day ZIP artifact. By default, it generates a 257x257 elevation array and OBJ mesh.

## Artifacts

| File | Purpose |
|---|---|
| `heightmap_16bit.png` | 16-bit grayscale elevation candidate for Studio Terrain Editor |
| `height_m.npy` | Exact generated relative-height matrix |
| `land_mask.png` | Rasterized reference coastline |
| `material_classes.npy`, `material_colormap.png` | Heuristic material zones |
| `terrain.obj` | 3D triangle mesh for Blender/other programs; X east, Y up, Z north; 1000 units width |
| `topographic_preview.png`, `diagnostics.png` | Top-down and side-profile images |
| `terrain_3d.html` | Interactive self-contained Plotly 3D viewer |
| `report.json` | Input provenance, seed and altitude normalization |

PNG 16-bit encoding is linear: relative elevation -24 maps to 0, +260 maps to 65535. Numerical elevations are not known meters. No absolute pixel/height fidelity is claimed.

## Roblox Studio (separate unpublished place only)

Download Actions artifact and inspect the 3D viewer/diagnostics. In Terrain Editor use the PNG as a heightmap with **manually chosen** height/size settings; interpret vertical mapping deliberately. The material-colormap PNG is only visual diagnostic data, not a validated Studio import palette. Ocean water, rivers, trees, roads, docks and the port need separate manual or scripted work. Check collisions, player scale, terrain walkability, memory and performance in Studio; do **not** replace current arena or pass the project's NO-GO publication gate on numerical unit tests alone.

## Scientific caveats and next step

The polygon was itself used as an input constraint, so perfect coastline correspondence is not independent reconstruction accuracy. There is no known geometry ground truth, camera intrinsic/extrinsic matrix, survey elevation or physically consistent cross-view matching. To evaluate 3D similarity with measurable reprojection error, gather independent real renders from the same actual mesh, register cameras and optimize explicit surface vertices. The synthetic AI side views alone cannot prove the recovered height field.
