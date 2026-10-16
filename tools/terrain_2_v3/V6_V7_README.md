# Terrain 2 — V6 Studio integration and V7 playability probes

**Status: isolated engineering prototype.** The current V5 candidate, `37cd79eb4c0bbeb35e6b52a3803a5bcef9ba5279402ce4117107185297e24948`, is imported into `Workspace.Terrain` in the `devtest3.rbxl` Studio session. V6 readback and V7 one-client route checks below were repeated against this candidate on 2026-10-16. The Studio session remains unsaved and has not been reopened from a persisted file. V5 absolute visual fidelity remains **NO-GO**; this work does not approve production use.

## V6 — isolated Studio integration

- Coordinate mapping: source-image X → Roblox +X; source-image row → Roblox −Z. Height is `Y=100+relative_height`; the V5 field is quantized to 0.5-stud increments for a 4-stud voxel grid. Bounds are `(-512, 80, -512)` to `(516, 208, 516)`, or 257 × 32 × 257 cells. These are working assumptions, not a calibrated physical or gameplay scale.
- Materials: preserve the existing per-column top classification (Sand, Rock, or Grass), use Rock under the top surface, and retain the existing V5 water mask. The water surface/depth are relative assumptions, not observed bathymetry.
- Latest `ReadVoxels` readback: 377,149 occupied cells — Water 146,120; Rock 202,290; Sand 3,485; Grass 25,254. Water remained in one connected component across 29,224 columns.
- Across all 36,825 dry columns, voxel top height matched the 0.5-stud-quantized target: MAE 0.000 studs, maximum 0.000 studs. This compares voxel column tops with the input field; it does not verify every point on the adaptive mesh or collision surface.
- Current terrain raycasts hit all four test anchors: north beach `(-10, -110)` Sand at Y=102; south beach `(-54, -326)` Sand at Y=100.40; west ridge `(-294, 10)` Rock at Y=152.21; east ridge `(258, -30)` Rock at Y=192.11.
- The adaptive mesh was not imported. Direct latest-mesh-to-voxel/collision comparison remains open.
- The test bounds were cleared only for a matched CPU baseline capture, then restored from an in-memory TerrainRegion snapshot and re-imported from the hash-verified V5 artifact. Final Edit and Server readbacks agreed on the 377,149 cells and material counts above.
- The Studio session is unsaved. Persisting and reopening the isolated place with the same readback is still required for V6 completion.

## V7 — navigation, sightlines, and performance

### Navigation

`Workspace.Terrain2TestMode=true` used `Workspace.V7_TestSpawn` on normal Play startup. The character appeared at `(-6.94, 107.56, 1.53)` with 100 health. From that spawn, jump-enabled one-client navigation returned `Success` at all four current-field targets:

| Target | Surface material and height | Character arrival | Horizontal offset | Health |
| --- | --- | --- | ---: | ---: |
| North beach | Sand, Y=102.00 | `(-10.63, 106.56, -109.85)` | 0.66 studs | 100 |
| South beach | Sand, Y=100.40 | `(-54.82, 104.32, -325.35)` | 1.05 studs | 100 |
| West ridge | Rock, Y=152.21 | `(-294.83, 156.50, 10.05)` | 0.84 studs | 100 |
| East ridge | Rock, Y=192.11 | `(257.50, 196.98, -29.38)` | 0.80 studs | 100 |

A separate `PathfindingService` query from `(-10, 107.5, -2)` with `AgentRadius=2`, `AgentHeight=5`, `AgentCanJump=false`, and 4-stud waypoint spacing found paths to north beach (30 waypoints, 112.57 studs) and south beach (89 waypoints, 343.85 studs). It returned `NoPath` to the west and east ridges. Jump-enabled traversal works for this one client, but no-jump ridge access and gameplay slope criteria remain open. This is not multiplayer acceptance.

### Heightfield slope diagnostic

I computed finite-difference slopes from the latest hash-verified 257×257 field over the 36,825 dry-land samples, using 4 studs per horizontal grid cell and the current assumed vertical mapping of 1 stud per relative height unit. This is a scale-dependent heightfield diagnostic; it does not reproduce Roblox Humanoid or PathfindingService traversal.

| Region hypothesis | Cells | P90 slope | At or below 20° | At or below 30° | At or below 35° |
| --- | ---: | ---: | ---: | ---: | ---: |
| All dry land | 36,825 | 45.00° | 78.63% | 81.62% | 83.80% |
| Beaches | 3,485 | 54.74° | 65.25% | 65.37% | 65.42% |
| Central plain | 6,285 | 0.00° | 99.87% | 100.00% | 100.00% |
| West mountain | 2,818 | 48.47° | 78.53% | 81.69% | 84.21% |
| East mountain | 2,729 | 53.19° | 74.90% | 77.87% | 79.77% |
| Cliffs | 842 | 65.42° | 1.90% | 5.23% | 7.48% |
| Plateau | 1,357 | 33.79° | 50.18% | 81.80% | 91.23% |

The uncalibrated vertical scale materially changes the result: all-land P90 is 26.57° at 0.5 stud per relative unit and 63.43° at 2 studs per relative unit; beach P90 ranges from 35.26° to 70.53°. These values help set up gameplay criteria, but no threshold has been approved and the runtime routes remain the authoritative playability probes.

### Combat-zone sightlines

Five terrain anchors were raycast at eye level (5 studs above the surface): central plain `(-2, 2)` Grass Y=102; north beach `(-10, -110)` Sand Y=102; south beach `(-54, -326)` Sand Y=100.40; west ridge `(-294, 10)` Rock Y=152.21; east ridge `(258, -30)` Rock Y=192.11. All 10 pairwise terrain rays were unobstructed, at ranges from 112.28 to 554.88 studs. This is a placement study only; it indicates that terrain alone offers limited hard cover. No combat assets were placed, and weapon ranges, cover standards, and future asset footprints remain unreviewed.

### CPU capture

The latest matched one-client A/B used camera position `(-6,113,12)` looking at `(-6,106,-95)`, a 256-frame limit, 2-second settle, 9-second collection, and an anchored test character. The candidate sample had 110 complete frames (absolute IDs 899421–899530), CPU frame interval median 16.699 ms, p95 17.474 ms, max 18.189 ms. The empty-bounds sample had 109 complete frames (absolute IDs 900987–901095), median 16.680 ms, p95 17.308 ms, max 17.707 ms. Candidate-minus-empty deltas were +0.019/+0.166/+0.482 ms for median/p95/max. This short one-client capture does not establish a sustained terrain cost.

LibMP found GPU thread ID 1 in both captures. Candidate/empty samples contained 12,871/12,754 GPU log entries and 2,860/2,834 completed scopes; summed inclusive scope times were 22.809/22.597 ms (about 0.207 ms per sampled frame in each sample). The largest inclusive timers were `Scene` (7.95/7.87 ms), `Scene2D` (7.52/7.45 ms), and `Id_Screen` (7.32/7.27 ms). These are nested scope totals across each capture, not end-to-end GPU frame latency; they show no measurable terrain delta in this sample. SceneAnalysisService reported the same 480,234 triangles and 923 draws with terrain present and with a client readback of zero occupied terrain, so that counter was rejected as nonresponsive for this A/B. LibMP memory counters were not attributable to this terrain region. Sustained performance and terrain-specific memory attribution remain open.

The exact rollback check succeeded: after clearing only the test bounds, the `TerrainRegion` snapshot restored server and client readbacks to 377,149 occupied voxels (Water 146,120; Rock 202,290; Sand 3,485; Grass 25,254). The snapshot was removed and Studio returned to Edit. The place remains unsaved and has not been reopened from disk.

## Remaining gates

- Manually accept or revise V5 contour fidelity. The relative multiview holdouts pass, but cardinal residuals remain material and absolute visual fidelity is **NO-GO**.
- Persist the isolated Studio place and verify that it reopens with the same heightfield and readback.
- Decide whether ridge access requires jumps or needs a walkable route; define and verify slope criteria and horizontal/vertical scale against gameplay needs.
- Run sustained CPU/GPU/memory captures, multiplayer navigation, combat-zone/cover review, and future asset-footprint review.

Current handoff: **V4 closed as visual NO-GO; V5 relative holdouts pass but absolute visual acceptance remains open; V6 latest candidate imported and voxel readback verified in the unsaved isolated session; V7 one-client jump-enabled routes and a short CPU A/B are recorded, while persistence, no-jump ridge access, slope criteria, sustained performance, multiplayer, combat, and asset-footprint gates remain open. `main` and the production place are untouched.**
