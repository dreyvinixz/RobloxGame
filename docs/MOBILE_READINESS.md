# FL-032 mobile readiness (design and known gaps)

**Gate:** FL-027 remains NO-GO; no mobile release claim is made. The FL-022 Studio Device Simulator screenshots cover HUD layout only, not touch gameplay or a physical device.

## Current source audit

- `PlayerController` sprint is LeftShift-only; walking relies on Roblox default character controls.
- `WeaponController` has no dedicated touch-fire/reload buttons in its source path; desktop mouse/keyboard drives fire/reload/equip.
- `VehicleController` accepts WASD and E only.
- `HudController` uses proportional panels and has iPhone 7 / iPhone 17 Pro Device Simulator captures from FL-022. This is not smartphone runtime acceptance.

## Proposed input design after release gate

- Retain Roblox's default mobile movement thumbstick. Add contextual touch actions for fire, reload, sprint, weapon switch, vehicle accelerate/reverse/steer/exit using `ContextActionService` or an accessible touch HUD; show vehicle controls only while the server confirms Enter.
- Use the same validated intent remotes and server cooldowns as desktop. Touch buttons must never carry client damage, HP, position, or target identity.
- Do not add aim assistance without a separate balance/security review. If later approved, keep it a bounded client camera convenience; the server raycast remains the sole authority.
- Respect `GuiService:GetGuiInset()`, small viewports, orientation changes, safe areas, and thumb reach. Provide large, separated controls with visible pressed states and text/icon labels; allow mute and no forced camera lock on touch.
- Do not add purchases, telemetry, or touch permission prompts as part of the control work.

## Physical-device acceptance

1. Use one confirmed low/mid-tier iOS and one Android phone; record model, OS, Roblox app version, display resolution, quality setting, and network conditions.
2. On both devices, run spawn/move/crouch-or-sprint/aim/fire/reload/equip/respawn/HUD/vehicle enter-drive-exit flows with one and two clients.
3. Rotate orientation and open chat/menu; verify input stops safely, UI remains reachable, and no HUD/control overlaps or screen cutouts occur.
4. Capture performance and battery/thermal context after a 10-minute session; retain server/client logs for validated combat and vehicle behavior.
5. Compare against desktop behavior and retain the test place/build hash. Device Simulator is supplementary only.

## Current blocker

FL-027 has not reached alpha approval; physical-device test hardware/results are unavailable in this task. No runtime controls or aim assist were added.
