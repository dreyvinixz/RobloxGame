# FL-029 tactical bot readiness (design only)

**Gate:** Do not add or enable bots while FL-023 is NO-GO. Bots would add server AI work and combat actors before multiplayer stability/performance acceptance.

## Proposed first prototype

- One server-created NPC in a dedicated test place/arena; no client-owned health, target selection, position, or hit claims.
- Finite states: `Spawn`, `Acquire`, `Navigate`, `Aim`, `Attack`, `Recover`, `Dead`. State transitions and a single target per bot run on the server.
- Navigation uses existing arena paths/waypoints first. If pathfinding is introduced, compute paths only on state change or after a blocked result, never every Heartbeat; cap retries and waypoints.
- Aim has a configurable reaction delay and angular error. The server validates line of sight by raycast and routes any damage through existing server-owned combat/match rules. No hitscan damage is accepted from a client.
- Add a configurable maximum bot count, update cadence, per-bot raycast budget, and deterministic test seed. Degrade or pause navigation when the round is not Active.
- No paid or third-party NPC assets are needed for the first behavior test; a native Roblox rig may be used only after its scripts/animations are inspected and logged.

## Acceptance experiment after FL-023

1. Record a player-only 60-second moving/combat baseline on the confirmed target machine.
2. Add exactly one bot, repeat the same route/weapon/camera, then compare FPS p50/p1, server frame time, memory, and raycast/path computation counts.
3. Verify server-created bot state, blocked-path recovery, target change, damage authorization, death cleanup, and player disconnect/reset without orphan connections.
4. Increase bot count one at a time; stop at first critical regression. Choose a limit from measured evidence, not a preset.
5. Repeat with two clients and save server/client logs plus profiler captures.

## Current blocker

FL-023 has not completed the integrated P0 suite or received human MVP acceptance. FL-026 also has no S4 performance profile. This document is a design/test plan; no bot code, NPC, asset, or runtime cost is claimed.
