# FL-018 — Multiplayer acceptance procedure (NOT YET EXECUTED)

**Status:** awaiting Roblox Studio 2-client test. Static source-contract checks do not establish gameplay correctness.

## Setup
1. Sync the PR branch through Rojo, start a local server with **2 players** in Roblox Studio.
2. Inspect Server Output for the FL-018 initialization message and inspect ReplicatedStorage.MatchState attributes.
3. Record Studio/Rojo versions, commit SHA, console logs, screenshots or video and FPS observations.

## Expected results
- **Team balance:** one player on Blue at Spawn_WestEntry, one on Red at Spawn_EastEntry; no neutral spawns.
- **Spawn shield:** first 3 seconds of each life have a ForceField; damage is blocked, then normal damage resumes.
- **Round lifecycle:** WAITING_FOR_PLAYERS until 2 clients, INTERMISSION (10s), ACTIVE (300s or score 20), ENDED (8s), then new intermission. Score resets on next ACTIVE.
- **Enemy elimination:** a lethal server-confirmed shot during ACTIVE credits exactly one kill to attacker, one death to victim and one point to attacker's team; verify both clients see MatchState score.
- **Friendly fire / waiting:** allied shots, spawn-shielded targets and player shots outside ACTIVE cannot damage or score.
- **Environment death:** increments victim Deaths during ACTIVE without awarding team score when no recent valid hit.
- **Respawn:** player returns to their team's SpawnLocation, keeps team assignment, rifle ammo resets.
- **Leave/rejoin:** when player count falls below 2, match goes to WAITING_FOR_PLAYERS and resumes with 2 players; no stale killer credit.

## Limits and follow-ups
No Studio, Rojo, Luau runtime or two-client evidence was available in this automation environment. A green GitHub Actions workflow validates planning and static source contracts only. Do not close FL-018 before executing and attaching this QA evidence.
