# Terrain 2 — V6 Studio integration and V7 playability probes

**Status: isolated engineering prototype.** The Studio session now contains the selected profile-restored V5 candidate with hash `ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`. Its terrain readback, four collision samples, and one-client route runs below are from this candidate. The session is unsaved. V5 absolute visual fidelity remains **NO-GO**; V6/V7 evidence does not approve production use.

## V6 — isolated Studio integration

The selected profile-restored V5 heightfield was written to `Workspace.Terrain` in the isolated `devtest3.rbxl` session under the Terrain 2 test bounds. Its input was `height_relative_v5.npy`, SHA-256 `ba77bef36d7815c564c4ed5c71df746d81235eef2b51630fc7e1001c1ac20a89`.

- Coordinate mapping: image X → Roblox +X; image row increases → Roblox −Z; relative height starts at Y=100. The voxel bounds are `(-512, 80, -512)` to `(516, 208, 516)`, at 4-stud resolution: 257 × 32 × 257 cells. These are assumed relative coordinates.
- The region uses one stud per source-image pixel as a working assumption and four studs per heightfield interval. The source reference bar is 245 pixels per labeled 500 units; neither the label nor mapping is a physical or gameplay scale calibration.
- Terrain conversion quantizes the relative heightfield into 4-stud voxels. Water uses a Y=100 surface and assumed 20-stud depth, with the V5 channel mask joined to surrounding water. No bathymetry was observed.
- Materials: Sand for the V5 beach mask, Rock for higher/steeper/source-rock cells, Grass elsewhere, and Rock below the top surface. Region classes remain heuristic.
- Readback: 370,626 occupied voxels: 146,120 Water, 195,768 Rock, 3,485 Sand, and 25,253 Grass. Top material was read from all 66,049 columns. The combined surrounding-water/channel mask has one connected component across 29,224 water columns.
- Collision spot checks: all four current beach/ridge markers hit Terrain. North beach: Sand at Y=102.00; south beach: Sand at Y=100.40; west ridge: Rock at Y=152.44; east ridge: Rock at Y=192.22. A latest-source-mesh versus voxel deviation comparison remains open.
- A column-top proxy comparison was run against the SHA-256-matched 257×257 source field and the Studio voxel readback, using the resized V2 land mask minus the V5 channel-water mask and the documented image-X→+X / image-row→−Z mapping. The 993 land-mask cells covered by the channel mask were excluded because the source relief there is below the water surface. Across 36,825 dry-land columns, source height (Y=100 + relative field) versus the highest occupied voxel top estimated from occupancy had MAE 0.195 studs, RMSE 0.505 studs, and maximum absolute difference 2.0 studs; 99.4% of columns were within 2 studs. The earlier all-land metric mixed submerged ground with the water surface and is superseded. This remains a quantization/alignment proxy, not an exact adaptive-mesh comparison; direct mesh-to-voxel review remains open.
- The error-guided adaptive mesh was re-exported from that same source field without changing its hash. Its piecewise-linear surface was compared at the 36,821 dry-land grid samples covered by retained triangles against the Studio voxel column-top proxy: MAE 0.196 studs, RMSE 0.513 studs, maximum 3.8 studs; 99.1% were within 2 studs and all were below 4 studs. The mesh-to-field interpolation RMSE at those samples is 0.096 relative height units, maximum 1.994. This directly compares the triangulated mesh to the voxel proxy at grid samples; it does not compare every point of the rendered collision surface. Four dry-land samples have no retained mesh triangle. The mesh itself was re-exported for analysis and was not imported into the unsaved Studio place.

The Studio session remains unsaved. The current voxel candidate is in the test area only; `main` and the production map were not changed.

## V7 — navigation and performance probes

On the earlier V5 voxel candidate, a one-client character used a radius-2, height-5 agent with jumping enabled and 4-stud waypoint spacing. Paths started at `(-2, 106, 2)` after raycasting the center terrain and moving the character from Studio's initial spawn at `(-124, 5.56, 0)`. All four paths and all four `character_navigation` attempts succeeded:

| Destination | Path length | Waypoints | Max vertical waypoint change | Result |
| --- | ---: | ---: | ---: | --- |
| North beach | 117.2 | 31 | 0.00 | Reached, within 3.9 studs |
| South beach | 351.4 | 91 | 0.63 | Reached, within 2.1 studs |
| West ridge | 387.9 | 100 | 4.03 | Reached, within 2.5 studs |
| East ridge | 417.8 | 108 | 10.35 | Reached, within 3.3 studs |

The repeated center-start route run ended within 3.3 studs of the east ridge marker with 100 health; server readback confirmed all four arrivals. Studio initially assigned `Workspace.FrontlineArena.EntryPoints.Spawn_WestEntry` as `RespawnLocation`, and the first character appeared at `(-124, 5.56, 0)` outside the terrain test area. `MatchService` now has an explicit test-only branch: when `Workspace.Terrain2TestMode` is true, it requires `Workspace.V7_TestSpawn`, makes it neutral, and uses it for both teams; when the attribute is false or absent, production team spawns are unchanged. With the test flag set before normal Play startup, the character spawned at `(-5.59, 107.56, -4.14)`, with 100 health and `RespawnLocation` set to `Workspace.V7_TestSpawn`. A control run with the attribute absent kept `Workspace.FrontlineArena.EntryPoints.Spawn_WestEntry` at `(-124, 5.56, 0)`, confirming the normal production spawn path. Earlier navigation from the test spawn reached the north-beach marker within 2.65 studs. The flag and terrain remain in an unsaved Edit session, so this does not yet prove persistence after reopen. These results establish basic one-client traversal only. The largest waypoint change is not a finished slope acceptance test. Multiplayer, combat, beach gameplay, and broader traversal remain open.

A separate walkability-only query started at the test spawn area (`(-10, 107.5, -2)`) with `AgentRadius=2`, `AgentHeight=5`, `AgentCanJump=false`, and 4-stud waypoint spacing:

| Destination | Pathfinding status | Waypoints | Path length |
| --- | --- | ---: | ---: |
| North beach | Success | 30 | 112.6 studs |
| South beach | Success | 89 | 343.8 studs |
| West ridge | Success | 97 | 373.9 studs |
| East ridge | NoPath | — | — |

This is a PathfindingService walkability query, not a completed human playtest. Server-controlled `Humanoid:MoveTo()` traversal was also run with `AutoJumpEnabled=false`: the character reached north beach (2.71 studs from the marker), continued to south beach (2.15 studs), then reached the west ridge (about 3.0 studs), staying at 100 health with no jump waypoints. The first west-ridge attempt timed out with only 4 seconds allowed per waypoint; retrying from the same intermediate position with a 10-second waypoint timeout completed the remaining route. The east ridge still has no path without jumping and needs a walkable route or a deliberately jump-required gameplay decision.

### Combat-zone and future-asset study

Five candidate anchors were raycast to the V5 Terrain surface: central plain `(-2, 102, 2)` Grass, north beach `(-10, 102, -110)` Sand, south beach `(-54, 100.4, -326)` Sand, west ridge `(-294, 152.4, 10)` Rock, and east ridge `(258, 192.2, -30)` Rock. Ten pairwise eye-level rays (5 studs above the surface) were unobstructed, across ranges of about 112–555 studs. This suggests the current terrain provides open firing lanes and little hard cover between these candidate anchors. It is a placement study only: no combat assets were placed, no weapon ranges or cover standards were supplied, and combat-zone acceptance remains open. Future cover needs a separate footprint and line-of-sight review after V5 geometry and scale are accepted.

Performance remains **unaccepted**. A matched LibMP client CPU A/B used the same fixed camera, client, frame limit (256), 2-second warm-up, and 9-second collection interval. The terrain candidate capture contained 110 complete frames (regular IDs 2202–2311; absolute IDs 491968–492077), with median CPU frame interval 16.749 ms and p95 17.635 ms. The empty test-bounds capture contained 85 complete frames (regular IDs 2888–2972; absolute IDs 493053–493137), with median 16.699 ms and p95 17.750 ms. The differences are within sample noise; these short captures do not establish a terrain performance cost or sustained performance. GPU frame timing was not compared.

A later candidate-only repeat used the same client, fixed camera, frame limit (256), and 2-second warm-up, with a 30-second requested collection interval. It yielded 109 complete frames (regular IDs 4787–4895; absolute IDs 563201–563309), median CPU frame interval 16.688 ms, p95 18.114 ms, and maximum 18.760 ms. This repeat has no matching empty-bounds capture, so it does not change the inconclusive A/B result or establish sustained performance. After clearing the test bounds for a planned baseline, the server readback confirmed zero occupied voxels and the in-memory `CopyRegion` backup existed. The backup was pasted back before leaving Play; server and Edit-mode readback both confirmed exactly 370,626 occupied voxels (146,120 Water, 195,768 Rock, 3,485 Sand, 25,253 Grass). The Studio place remains unsaved.

`Stats.MemoryTrackingEnabled` was true. Five one-second samples after a 5-second settling interval reported the terrain candidate at 961.88 MB `TerrainVoxels`, 36.07 MB `GraphicsTerrain`, 0.043 MB `PhysicsCollision`, and about 3,805.6 MB total client memory. After clearing only the test bounds and waiting another 5 seconds, `TerrainVoxels` was 963.28 MB and `GraphicsTerrain` remained 36.07 MB; total client memory was about 3,888.9 MB. The TerrainVoxels allocation did not release, and total process memory shifted, so this A/B cannot attribute the roughly 962 MB category to the candidate. It also includes the Studio client and the rest of the place. Memory and sustained performance remain open gates.

## Remaining gates

- Manually accept or revise latest V5 contour fidelity; its two relative isometric holdouts pass, but cardinal residuals and region-mask artifacts remain.
- Compare the latest voxel surface to a synchronized latest V5 source mesh; current archived MeshParts are from the earlier candidate.
- Persist the isolated Studio place and verify the saved file can be reopened with the same terrain readback.
- Calibrate horizontal/vertical scale against a real Roblox gameplay requirement.
- Fix deterministic spawn selection, then validate slopes, multiplayer navigation, combat zones, future asset footprints, memory, and sustained performance with repeated baseline captures.

Current handoff: **V4 closed as visual NO-GO; latest V5 relative multiview gates pass but absolute visual review remains NO-GO; V6 contains the latest candidate in an unsaved isolated session; V7 has one-client route and open-sightline evidence, with deterministic default spawn, east-ridge no-jump access, sustained performance, multiplayer, cover, and combat acceptance still open.**
