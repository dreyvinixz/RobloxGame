# BR Peninsula — macro layout draft

**Status:** first terrain and asset pass is staged in Roblox Studio Edit at `Workspace.BR_Peninsula_Draft`; not integrated into active gameplay.
**Scope:** shape the landform, regions, and route logic before collision and gameplay assembly.
**Style:** contemporary coastal battle zone, original composition; no copied Battlefield map.

## Visual reference from the owner

The supplied image is the primary composition reference: a lush tropical peninsula surrounded by sea, a broad curved beach at the outer tip, a dense coastal city rising inland, roads that follow the shoreline and climb through neighborhoods, and a working harbor/industrial edge on one side. Keep the overall read bright, green, and coastal; concentrate visible battle damage around the military compound, port, and selected urban blocks so the entire peninsula does not read as uniformly ruined. Use the image for silhouette, zoning, and mood, not as a literal 1:1 copy.

The main beach should read as one continuous, gently sloped sandy crescent with a clear waterline, rocky headlands at its ends, and a planted green transition inland. The current southwest beach is an initial terrain sample; extend or reshape it toward the peninsula tip during the next terrain pass. Preserve a winding coastal route and several inland connections between the beach, neighborhoods, military area, and port.

## Core read

The island is a long peninsula with the sea defining its west, south, and east edges. The northern neck and connected mountain chain form the far backdrop. The military compound occupies the west side of the middle peninsula; the city sits in the center; industry and the port use the east side, with the port farther south. Dunes and one broad beach crescent close the southern tip. A broken ridge divides the natural high ground from the city without making the whole map mountainous.

Three routes cross the peninsula:

1. **Northern approach:** a winding route below the mountain chain, descending from the north into the western military area and the city.
2. **Central avenue:** the most direct route through the urban center, with the most building cover and intersections.
3. **Eastern logistics route:** connects the city, industrial zone, and southeast port, with a southern coastal return route behind the dunes.

Short alleys, drainage cuts, footpaths, and service roads connect the three routes. They provide flanking choices but should not create a fourth uninterrupted highway.

## Region plan

Coordinates are a planning grid in studs, centered on the playable area. They are not final asset placement coordinates. North is positive Z.

| Region | Approx. center (X, Z) | Relative height | Role and visual identity |
|---|---:|---:|---|
| Northern arrival and mountain backdrop | (0, 1,200) | +20 to +220 | Broad connected ridge behind the playable lowlands; the entry road winds below the foothills. |
| Military compound | (-510, 80) | +55 to +90 | West-side secured zone with airfield/yard space and two road connections to the city. |
| City center | (20, 240) | +18 to +45 | Densest combat district, street grid, landmark, plazas, and multiple entries. |
| Industrial quarter | (500, 470) | +20 to +60 | East-side service yards and industrial silhouettes; avoid the two rejected power-plant assets. |
| Port and logistics | (700, 30) | +4 to +20 | Southeast harbor, container lanes, cranes/warehouse candidates, and water approaches. |
| Natural ridge | (390, 720) | +40 to +110 | Broken elevated ground and saddles between the north foothills and industrial side. |
| Southern dunes | (0, -735) | +8 to +30 | Low rolling sand mounds behind the road; keep the main route on the inland edge. |
| Southern beach | (0, -900) | 0 to +12 | Continuous curved shoreline with rocky headlands and a planted green transition inland. |

Heights express desired play space, not a mandate to make vertical cliffs. Slopes need traversable benches and at least two paths between high ground and the low city. Avoid uninterrupted long-range views from the ridge into every spawn and loot area.

## BR movement and combat rules

- Keep the playable land continuous. Coast and water bound the island; hills and structures guide movement without sealing it into corridors.
- Make all three main routes reconnect at multiple points so a squad can rotate after a fight.
- Each region needs at least two entrances and one alternate exit. Interior buildings cannot be the sole route through a region.
- Give the center the most loot and combat pressure; give the coast and ridge safer rotations with longer travel time.
- Use height for information and route choices, not permanent dominance: break ridge sightlines with saddles, structures, and vegetation.
- Keep a readable skyline landmark in the port, city center, and industrial quarter so players can orient themselves while dropping in.
- Add cover in clusters with gaps for movement. Do not recreate the rejected grey wall or test-block layout.

## Layout schematic

See [BR peninsula macro layout.svg](BR%20peninsula%20macro%20layout.svg) for the top-down region and route sketch. It is conceptual and not to scale.

## Studio first pass — 2026-10-15

- Sculpted a grass peninsula with a gradual sandy coast, a broken eastern ridge, low saddles, and three connected asphalt terrain routes. Land, road surface, and water use Roblox Terrain; no scenery Parts were generated.
- Placed 20 owner-selected (`USAR`) sanitized visual previews into region folders for the coast, port, west quarter, center, industrial quarter, ridge, and south coast. Rejected items remain in the selection queue and were not copied.
- Draft copies are anchored, with collision, touch, and query disabled. They are visual composition only; original Creator Store packages remain quarantined, and this pass does not prove that building interiors or collisions work.
- Studio Edit inspection found 20 draft asset models and zero scripts, remotes, or sounds under the draft. A small asphalt junction was added where a sampled central route segment had a terrain-material gap.
- Sculpted a broad southwest beach in native Terrain, about 200 studs along the coast and 160 studs inland. Its shoreline begins near sea level (Y=3) and rises gradually toward the peninsula (about Y=12); the existing coastal asphalt route remains visible through the area. Studio raycasts confirmed Sand across sampled shoreline points. The beach is a first pass for visual review, not a final shoreline polish.

## Terrain reference review — 2026-10-15

- Compared `tests/relevoatual.png` with `tests/relevoalvo.png`. The Studio terrain had a detached, narrow northern mountain island, a thin inland neck, and too little relief across the central green area. The target shows one broad peninsula, a continuous mountain skyline across the far edge, rolling lowlands, and a wide curved south beach.
- Reworked the manual Terrain generator and applied the reference pass in Studio Edit. The northern coast is wider, the mountain chain is connected and spans most of the back edge, the central hills are distributed across the land, and dune shaping follows the full southern crescent.
- Studio holds the previous V3 terrain in `ServerStorage.BR_TerrainWorkshop.TerrainBeforeReferencePass` and the intermediate V4 terrain in `TerrainBeforeMountainWideningV4`. Twenty visual models remain in `AssetsAwaitingTerrain`; the terrain draft remains separate from the active arena.
- The resulting shape is still a terrain-only draft. Roads, region buildings, vegetation placement, route clearance, and Play collision validation remain open; the photoreal reference is being used for composition, not as a literal asset target.

## Zones and asphalt route pass — 2026-10-15

- Added `Workspace.BR_Peninsula_Draft.Reference_Zones` with ten named zones, labels, centers, approximate bounds, and display colors. The values follow the supplied map: military west, city center, industry east, port southeast, dunes/beach south, and mountains north. These are planning bounds for composition, not gameplay boundaries.
- Added `Workspace.BR_Peninsula_Draft.Road_Network` with 11 named routes and waypoint metadata: northern entry, military access/perimeter, city avenues, industry-to-port connection, and a southern coastal arc.
- The first two native Terrain passes read visually as thin lines at map scale. Replaced them with a vehicle-scale bed: main asphalt lanes are 42–48 studs wide, secondary streets are 30–34 studs, and each has a 6-stud flush concrete shoulder. The top is graded at 4-stud voxel resolution; no geometry Parts were used.
- Studio Edit reports 22,971 asphalt cells, 6,059 shoulder cells, 9,407 graded cells, and 2,175 water cells skipped. Asphalt color was darkened to charcoal so the carriageway reads as a continuous paved surface. Rollback snapshots V1–V3 are in `ServerStorage.BR_TerrainWorkshop`.
- The road bed is physically part of Terrain and raycasts return `Enum.Material.Asphalt` along the urban lanes. Close-up view still shows voxel-stepped boundaries; vehicle playability and collision remain untested. The draft is separate from `FrontlineArena`, and the place has not been saved.

## Asset and construction constraints

- The owner marked the non-rejected entries in the selection grid as **USAR** by inference. That records preference; it does not replace the source audit required before a model enters the active arena.
- Do not use the explicitly rejected IDs. The current selection log lists 15 rejected candidates, including the named hill/pine assets and the recent palms, ruins, burning building, and power plants.
- Candidate terrain and building packs with unexpected scripts/remotes remain quarantined. Use only sanitized, individually reviewed assets in the final place.
- The owner chose to shape the terrain directly. Native Roblox Terrain forms land, shoreline, elevation, and road surfaces; all buildings, vegetation, and props remain assets. No environmental scene geometry is made from scripted Parts.
- Assets in the draft are sanitized matrix previews. Audit their original sources, provenance, scale, and collision before promoting replacements from quarantine into the final map.
- Keep the current arena playable until the replacement content, spawn points, boundaries, and route connections are ready for Studio review.

## Next design gate

Before final assembly, convert each region into an asset manifest with source ID, audit result, scale, and collision behavior. Refine the voxel-stepped route edges, place reviewed assets into their region folders, then validate interiors, traversability, spawns, and sightlines in Studio Play. This draft does not claim that assets are approved, interiors are enterable, or gameplay has been tested.

## Terrain V6 — scale, river, and buildable pads — 2026-10-15

- Expanded the world grid from the compressed V5 scale (0.8) to 1.0 so the military, city, industry, port, ridge, and mountain coordinates match this layout. Terrain bounds are X `-1280..1280`, Z `-1280..1792`, and Y `-80..768` studs.
- Added a connected multi-ridge northern mountain wall and two broken midland ridges. Exposed rock now follows steeper slopes; the generated north peak sample reached Y `641.16` studs.
- Carved a 68-stud nominal river from the northern foothills through the two city districts, then east past logistics and out to sea. Studio raycasts returned Water at five samples along the course, including the center city.
- Reserved 11 `Buildable_Pads` footprints: beach, dunes, military compound, two city districts separated by the river, industry, port, natural ridge, mountain overlook, and two team staging areas. The flat interior is 78% of each footprint radius; markers are folders with placement metadata and do not add geometry.
- Rebuilt the asphalt route pass over V6. Studio reports 23,610 asphalt cells and 6,272 shoulder cells. Terrain voxel resolution is 4 studs; road intersections can cause small surface-height/material changes inside a pad, so asset pivots still need a final raycast placement check.
- Updated team staging locations to `(-700, 99, 400)` and `(760, 79, 390)`. In Play, the assigned player spawned at `(-700, 104.06, 400)` on the west flat pad. The session returned to Edit afterward.
- Rollback snapshots are held at `ServerStorage.BR_TerrainWorkshop.TerrainBeforeIslandV6`, `TerrainBeforeIslandV6Refinement`, `TerrainBeforeRoadNetworkV6`, and `TerrainBeforeRoadNetworkV6Refinement`. The draft remains unsaved and separate from final map acceptance; vehicle crossings of the river still need an audited bridge solution.
