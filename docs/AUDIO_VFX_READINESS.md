# FL-031 audio and feedback readiness (design only)

**Gate:** FL-027 remains NO-GO. No sound IDs, Creator Store effects, or purchased assets are added by this plan.

## Asset and runtime design

- Use only original/permission-verified audio with a registry row, source/owner/terms, and exact-content review. Keep candidates quarantined until asset audit and destination-place permission check pass. Never use Battlefield audio or extracted game files.
- Keep gameplay truth on the server. Client muzzle/hit feedback may be cosmetic and triggered only by existing accepted-shot/hit confirmations; it must not report damage, score, or hit validity.
- Reuse a bounded local particle pool; cap emitters/particles per event, auto-expire them, and return instances to pool. Do not create one server physics object or long-lived connection per effect.
- Use a small SoundGroup tree (Master, SFX, UI) with normalized gain controls. Per weapon, define an event matrix for fire/reload/hit/vehicle impact; avoid overlapping reload/fire spam and clean all transient sounds at character/round teardown.
- If no licensed sound is ready, retain silence/native UI feedback. Do not introduce a dependency solely to fill the prototype.

## A/B acceptance after FL-027

1. Capture identical 60-second movement/combat runs with effects off and on, at the target device's fixed quality/viewport.
2. Compare FPS p50/p1, CPU/GPU frame time, draw calls, memory, active emitter/sound counts, and server frame time; repeat three times.
3. Confirm audio levels have no clipping/overlap under rapid-fire, reload, hit, and vehicle events; test user volume controls and muted audio.
4. Run two clients and late join; confirm only cosmetic events replicate, both clients see bounded effects, and neither client can forge authoritative damage.
5. Audit every sound/texture effect in the exact place and add registry evidence before approval.

## Current blocker

FL-027 release acceptance is open. There is no effects implementation, license evidence, A/B measurement, or multiplayer test in this PR.
