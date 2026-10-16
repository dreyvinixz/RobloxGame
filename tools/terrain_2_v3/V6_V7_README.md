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
- The Studio session is unsaved. A filename search found no `devtest3.rbxl*` on disk in the repository, temporary artifact folder, user Documents, or Roblox Studio cache paths checked. Studio MCP exposes no save action; the only engine method found is the deprecated [DataModel:SavePlace](https://create.roblox.com/docs/reference/engine/classes/DataModel#SavePlace). The desktop-control helper failed to initialize (`failed to write kernel assets: The system cannot find the path specified`), so save/reopen remains a concrete V6 blocker. Persisting and reopening the isolated place with the same readback is still required for V6 completion.

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

I rechecked the live Studio session against the current field hash on 2026-10-16. The start was `(-9.15, 107.56, -3.49)`, with 100 health. Fresh `PathfindingService` results at 4-stud waypoint spacing were: north beach Success (30 points, 111.12 studs, no jump action); south beach Success (88, 342.74, no jump action); west ridge Success with jumping (95, 347.23, five jump actions); east ridge Success with jumping (111, 418.38, four jump actions). With jumping disabled, both beaches and the central pad succeeded, while both ridges returned `NoPath`. Raycasts at the anchor X/Z positions hit Sand at Y=102.00/100.40, Rock at Y=152.21/192.11, and Grass at Y=102.00 on the central pad. One-client character navigation reached the north beach, south beach, and west ridge with 100 health; the east ridge was reached from the test spawn after retry. An attempt to traverse from the west ridge to the east ridge ended in sea and is not accepted as a route. These checks refine access evidence but do not establish multiplayer acceptance or a slope standard.

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

Five terrain anchors were raycast at eye level (5 studs above the surface): central plain `(-2, 2)` Grass Y=102; north beach `(-10, -110)` Sand Y=102; south beach `(-54, -326)` Sand Y=100.40; west ridge `(-294, 10)` Rock Y=152.21; east ridge `(258, -30)` Rock Y=192.11. All 10 pairwise terrain rays were unobstructed, at ranges from 112.28 to 554.88 studs. This is a placement study only; it indicates that terrain alone offers limited hard cover. No combat assets were placed, and weapon ranges, cover standards, and actual asset footprints remain unreviewed.

### Future asset footprint screen

An exploratory flat-pad screen used the current field hash `37cd79eb4c0bbeb35e6b52a3803a5bcef9ba5279402ce4117107185297e24948`, the V5 water mask `width=1.0/depth=1.0/bank=0.10`, and the current assumed scale (4 studs per horizontal cell, 1 stud per relative height unit). It searched square footprints of 32×32 and 64×64 studs, requiring every cell to be dry, height range no more than 2 relative units, and maximum derived slope no more than 20°. The central-plain hypothesis contains 5,413 and 4,034 candidate centers respectively; these centers overlap heavily and are not counts of distinct, non-overlapping placements.

One 64×64 candidate at `X/Z=(-102, 26)` passed the screen with zero relative-height range and zero derived slope. Studio `ReadVoxels` over its aligned 16×16 horizontal cells confirmed 256 dry Grass tops at the same voxel layer and no water. From the test spawn, PathfindingService reached the center at `(-102,102,26)` with `AgentCanJump=false` in 27 waypoints / 98.97 studs. No asset or terrain edit was made. This validates one generic flat pad under the current assumed scale; final asset bounds, collision, lines of sight, combat balance, and calibrated scale still require object-specific review.

### CPU capture

I repeated CPU profiling on the current field in a controlled one-client A/B/A: fixed camera `(-6,113,12)` looking at `(-6,106,-95)`, anchored character, and three 6-second capture windows per condition with the LibMP limit explicitly set to 256. The captures yielded 329 unique candidate frames, 328 empty-bounds frames, and 329 candidate-repeat frames. Candidate A mean/median/p95/p99/max frame intervals were 16.660/16.688/17.779/18.387/18.714 ms; empty bounds were 16.670/16.655/17.737/18.109/18.892 ms; candidate repeat was 16.663/16.669/17.708/18.007/18.162 ms. The small, inconsistent differences show no measurable terrain CPU delta in this sample. These separated static windows do not establish sustained gameplay performance.

For the empty condition, I copied the exact 257×32×257 test region to a temporary `TerrainRegion` backup, cleared only that region, and restored it before the candidate repeat. Approximate global `Terrain:CountCells()` changed from 12,946,430 to 12,575,170 and returned to 12,946,430; the backup was removed. The live terrain attributes still report the current field hash and the prior exact 377,149-voxel material/top-height readback. No terrain modification remains from the A/B test.

In the earlier 27-second A/B capture, LibMP found GPU thread ID 1 in both 109-frame samples. Candidate/empty samples each contained 12,754 GPU log entries and 2,834 completed scopes; summed inclusive scope times were 22.524/22.596 ms (0.2066/0.2073 ms per sampled frame). The largest inclusive timers were `Scene` (7.86/7.89 ms), `Scene2D` (7.42/7.45 ms), and `Id_Screen` (7.24/7.24 ms). These are nested scope totals, not end-to-end GPU frame latency. SceneAnalysisService reported the same 480,234 triangles and 923 draws with terrain present and with a client readback of zero occupied terrain, so that counter was rejected as nonresponsive for this A/B. Terrain-specific memory attribution, longer active gameplay captures, and multiplayer performance remain open.

I added an exploratory LibMP capture while navigating from the south beach to the west ridge in Play. The live `Workspace.Terrain` attributes identified the field as `37cd79eb4c0bbeb35e6b52a3803a5bcef9ba5279402ce4117107185297e24948`, and the character completed the route at 100 HP. Although the capture task waited 12 seconds after movement began and set the LibMP limit to 256, the snapshot contained only 84 valid frame records (IDs 20120–20203). CPU mean/median/p95/p99/max were 16.670/16.666/17.707/18.061/18.061 ms, with 42 frames above 16.67 ms and none above 33.33 ms. The capture window is too short and its frame coverage does not match the requested wait, so it is preliminary movement evidence only; it does not close sustained-performance acceptance.

The exact rollback check succeeded: after clearing only the test bounds, the `TerrainRegion` snapshot restored server and client readbacks to 377,149 occupied voxels (Water 146,120; Rock 202,290; Sand 3,485; Grass 25,254). The snapshot was removed and Studio returned to Edit. The place remains unsaved and has not been reopened from disk.

The live `Workspace.Terrain` attributes still confirm the current `37cd79eb…` field and 377,149-cell readback. On a later Edit-mode inspection, the separate `Terrain2_V6_Prototype` annotation model still contained old `ba77bef3…` status text; its V6/V7 hash, readback, and route annotations were synchronized in the current in-memory session after the recheck above. This metadata edit is also unsaved and is not persistence evidence.

## Remaining gates

- Manually accept or revise V5 contour fidelity. The relative multiview holdouts pass, but cardinal residuals remain material and absolute visual fidelity is **NO-GO**.
- Persist the isolated Studio place and verify that it reopens with the same heightfield and readback.
- Decide whether ridge access requires jumps or needs a walkable route; define and verify slope criteria and horizontal/vertical scale against gameplay needs.
- Run sustained CPU/GPU/memory captures, multiplayer navigation, combat-zone/cover review, and future asset-footprint review.

Current handoff: **V4 closed as visual NO-GO; V5 relative holdouts pass but absolute visual acceptance remains open; V6 latest candidate imported and voxel readback verified in the unsaved isolated session; V7 one-client jump-enabled routes and static/moving CPU samples are recorded, while persistence, no-jump ridge access, slope criteria, sustained performance, multiplayer, combat, and asset-footprint gates remain open. `main` and the production place are untouched.**
