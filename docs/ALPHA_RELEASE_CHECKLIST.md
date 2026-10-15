# Closed alpha release checklist — Project Frontline

**Decision:** NO-GO / internal development only (2026-10-15). This file prepares review; it does not authorize or perform publishing.

## Release gates

| Gate | Current finding | State |
|---|---|---|
| P0 acceptance | FL-023 remains NO-GO: QA-10 has no ten-minute run; integrated cases, latency variation, HUD reset proof, and human MVP acceptance remain open. | BLOCKED |
| Vehicle lifecycle | FL-025 implementation is in draft PR #57; Studio multiplayer damage/destroy/reset proof remains open. | BLOCKED |
| Performance | FL-026 has no comparable S4 sample, MicroProfiler trace, standalone run, or runtime warning/leak assessment. | BLOCKED |
| Asset provenance | Registry audit below: only prototype/approved assets are present; quarantine/discovery entries must stay out of a release build. Destination-experience permission must be rechecked. | PARTIAL |
| Content maturity | The product is a multiplayer shooter with repeated weapon combat. Before a public release, the owner must inspect the final experience and complete Roblox's Maturity & Compliance Questionnaire, including violence intensity/frequency and every other applicable category. No rating is assigned here. | PENDING OWNER |
| Privacy/data | Source scan found no DataStore, HttpService, AnalyticsService, or external collection API under `src/`. This says nothing about Roblox platform processing, dashboard settings, or future code. Review final experience settings and publish a privacy notice if required for the chosen release scope. | PARTIAL |
| Test evidence | See TEST_PLAN and per-issue reports; source/static checks do not replace gameplay, multiplayer, or target-device evidence. | BLOCKED |
| IP/branding | Project is independent; no EA/Battlefield branding or extracted game files. Recheck title, thumbnails, descriptions, and final assets. | OPEN |

## Asset registry audit

`assets/registry.csv` has 10 entries: 3 `APPROVED`, 3 `QUARANTINED`, 3 `DISCOVERED`, and 1 `PROTOTYPE`.

- The approved FL-014 weapon visual, native R15 technical rig, and city prop subset have prior script/content audits. Reconfirm asset permissions in the destination experience and inspect the exact release place before publish.
- The FL-005 jersey barrier, FL-013 apartment, and city-prop research copies are `QUARANTINED`; the two city packs are `DISCOVERED`. Keep all out of release until their documented gates pass.
- The FL-024/025 scout is procedural and remains `PROTOTYPE`; it has no external asset dependency. FL-025 gameplay acceptance is still pending.
- No purchase was made or is authorized by this checklist. Registry evidence and the actual published place must match before release.

## Required manual sign-off

- [ ] Resolve FL-023 P0 gate and receive explicit human acceptance of the MVP.
- [ ] Complete and archive an integrated multiplayer run, including the ten-minute case and all blocking QA scenarios.
- [ ] Complete FL-024/025 vehicle lifecycle playtests with two clients and save logs/video.
- [ ] Complete equivalent S2/S4 performance captures, MicroProfiler investigation, and target-device/multiplayer checks; resolve critical regressions.
- [ ] Inspect every asset in the exact destination place; approve only entries whose status/evidence/permissions support release.
- [ ] Review the final game against current Roblox Community Standards and complete the Creator Dashboard Maturity & Compliance Questionnaire truthfully. The questionnaire asks about violence, intensity and frequency; the final content—not this prototype checklist—determines answers.
- [ ] Review privacy disclosures, data collection, analytics, chat/UGC, monetization, and all experience access settings for the selected audience and regions.
- [ ] Confirm ownership/account eligibility, access controls, group permissions, 2-step verification as required by the chosen audience, and release channel.
- [ ] Review title, icon, thumbnails, description, localization, and content descriptors for original branding and accurate claims.
- [ ] Approve a tagged source commit, archive its Rojo project/build and test evidence, and record the experience/place version.
- [ ] Human owner approves publishing explicitly. No publish action is performed by this checklist or its PR.

## Draft changelog (not a release announcement)

**0.1.0-alpha — unreleased / not accepted**

- Source contains a greybox arena, server-validated combat, team/score prototype, HUD, procedural vehicle prototype, and documentation.
- Known gates: MVP acceptance NO-GO; vehicle lifecycle and final performance evidence partial; exact release configuration and maturity rating unreviewed.

## Rollback runbook (manual)

1. Stop the release and keep the last accepted place/version ID and source tag recorded; do not overwrite the only known-good artifact.
2. If a release has already been authorized and a critical issue appears, use Creator Dashboard's version history to restore the last accepted experience version, then verify the restored place and access settings before reopening access.
3. If rollback is unavailable or content is unsafe, disable access to the experience in the dashboard while investigating; retain logs and the affected commit/version for review.
4. Revert the responsible source commit with a new reviewed PR (no history rewrite), run the relevant test plan, create a new version, and require human approval before re-enabling or republishing.
5. Record incident time, affected version, symptoms, action, verification, and owner in the release log.

## References

- Roblox [Content maturity and compliance](https://create.roblox.com/docs/production/promotion/content-maturity) describes questionnaire disclosures, including violence intensity and frequency.
- Roblox [Configure experiences](https://create.roblox.com/docs/projects/configure-experiences) describes Creator Dashboard access and region settings.
- Project asset policy: [`ASSET_PIPELINE.md`](ASSET_PIPELINE.md); IP statements: [`LICENSING.md`](LICENSING.md); current MVP gate: [`TEST_REPORTS/FL-023.md`](TEST_REPORTS/FL-023.md).
