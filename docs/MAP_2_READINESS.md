# FL-030 second-map readiness (design only)

**Gate:** FL-027 is NO-GO. Do not add a map or assets to the active experience until the alpha gates and map-rotation test harness are accepted.

## Reuse boundary

- Treat the current `ArenaBuilder` as a reference for modular folders, semantic roles, spawn markers, collision cores, and non-colliding visual props.
- Put the second map in a separate builder/module and keep match, combat, team, objective, and vehicle services map-agnostic. Do not copy service logic into the new map.
- Define stable required markers for team spawns, boundaries, routes, and objective/test positions. Fail fast if a required marker is absent or overlapping invalid geometry.
- Keep blockers/queryable cover separate from visual facades and props. Use approved registry entries only; prototype imports stay out.
- Select a map identifier from a server-owned allowlist at round setup. Do not accept map names or CFrames from clients. Rotation occurs only between rounds after all players leave seats and round state is reset.

## Acceptance after FL-027

1. Run existing MVP suite on map one, rotate to map two, then run the same suite without service restarts.
2. Test spawn fairness, route connectivity, cover raycasts, out-of-bounds bounds, vehicle limits/collisions, and respawn/team assignment on both maps.
3. Repeat map-one → map-two → map-one across three rounds and two clients; assert exactly one active arena and no stale map objects, occupants, prompts, event connections, or match attributes.
4. Capture identical 60-second movement/combat performance samples and compare frame/server costs. Keep both maps only if critical budgets hold on target hardware.
5. Record visual screenshots and an asset-registry diff for the exact content added.

## Current blocker

The release prerequisite FL-027 is partial / NO-GO; MVP acceptance and S4 performance gates also remain unresolved. This plan adds no map content, assets, or runtime behavior.
