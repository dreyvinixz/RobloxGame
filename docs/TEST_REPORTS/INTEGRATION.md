# Integration review — issues #13–#32

**Date:** 2026-10-15  
**Branch:** `docs/integration-issues-13-32`, stacked after per-issue draft PRs  
**Decision:** **NO-GO for alpha/publication.**

## Current stack

| Issues | PRs | State at integration review |
|---|---|---|
| #13–#22 | #43–#53 | Partial; targeted reports exist, several video/standalone/latency/integrated acceptance details remain open. |
| #23 | #54 | NO-GO. Integrated QA-01–QA-11, QA-10's ten-minute run, latency variation, HUD reset proof, zero P0 blockers, and human MVP acceptance are not demonstrated. |
| #28 | #55 | Research partial; recommends no-go for live cross-process BF6 integration and documents safe official alternatives. |
| #24 | #56 | Partial; player driving route and observer/video checks remain open. A valid rifle request exposed `Street_EW_0` occluding the vehicle ray; the scout pivot was raised to Y=3.15. Post-fix Play verification remains open. |
| #25 | #57 | Partial; single-client Studio confirmed valid shot damage, destruction/ejection/seat lockout, rejected re-entry, and nearby reset to one healthy scout. Two-client replication, collision damage, spam/cooldown, and late-join checks remain open. |
| #26 | #58 | Partial; only an S2 idle baseline is numeric. Comparable S4/MicroProfiler/standalone and leak/warning evidence absent. |
| #27 | #59 | NO-GO; checklist/changelog/rollback prepared, owner content/privacy/settings review and upstream P0 gates remain open. No publication occurred. |
| #29–#32 | #60–#63 | Planning-only drafts; blocked/deferred until stability/release gates, suitable assets, and physical-device evidence are available. |

The stack preserves one issue branch/PR and `Closes #N` per issue. The latest metadata check showed PRs #54–#63 open, draft where acceptance is incomplete, and mergeable. No branch was force-pushed and `main` was not modified.

## Validation executed

- `python scripts/validate_project.py` — passed (32 issue/dependency/path/doc/asset checks).
- `python -m unittest discover -s tests -v` — 9 passed, including the vehicle road-raycast spawn contract.
- `git diff --check` — passed.
- Official Rojo 7.7.1 Windows x86_64 release zip digest matched the published GitHub SHA-256. `rojo build <branch> --output <temp>.rbxlx` passed on the branch heads for PRs #54–#63 (issues #23–#27 and #28–#32). Builds are serialization checks, not gameplay tests.
- Selene and StyLua are unavailable. No Luau lint or format pass is claimed.

## Integrated runtime test not completed

No full logical playtest was completed for the exact stacked artifact. The StudioTestService previously refused a new multiplayer run because a previous test was still in progress. The full stacked integration artifact has not been loaded for QA-01–QA-11, and QA-10's ten-minute observation is still required.

A follow-up probe temporarily synchronized the four FL-025 source files into the Studio Edit DataModel and attempted to start Play. The start call stalled; `execute_luau` reported the Server DataModel unavailable because Studio remained in Edit. After stopping the attempt, I restored the previous source for all four scripts and verified that `VehicleService` again begins with the FL-024 implementation and has no `VehicleHealth` attribute code. No runtime pass was claimed for that earlier attempt. The later bounded single-client Studio Play probe loaded the exact FL-025 source after the FL-024 Y=3.15 fix. Server raycast found the scout chassis first; one valid shot changed health 300→275. Eleven rate-spaced shots produced health 0 and `Destroyed`, driver 0, speed 0, no occupant, and disabled seat. An `Enter` request was rejected; nearby `Reset` produced exactly one active vehicle with health 300 and pivot Y=3.15. Play was stopped and the four Studio Edit scripts were restored exactly to their pre-probe source snapshot; Studio is in Edit. This is targeted single-client evidence only, not multiplayer/integrated acceptance. The final integration branch passes the validator, 9 Python tests, diff check, and Rojo 7.7.1 serialization build.

## Required next actions

1. Load one exact stacked build into a clean Studio test session, then complete QA-01–QA-11 with two clients (third client for late-join QA-09), including explicit network-latency variation.
2. Run a full ten-minute session and record server/client logs, HUD/screenshots, and gameplay video.
3. Complete FL-024/025 vehicle route and damage lifecycle tests with an observer; complete comparable S4 performance/MicroProfiler sampling.
4. Resolve P0 findings and request human acceptance. Then finish FL-027 owner review, mobile physical-device work, and the deferred feature gates before changing README status or preparing a release.
