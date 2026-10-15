# ADR-0002 — Cross-process Battlefield/Roblox integration

**Date:** 2026-10-15  
**Status:** No-go for a live Battlefield 6 process bridge; go for isolated, synthetic-data research and documented in-product creator workflows.

## Context

FL-028 asks whether the independent Roblox FPS can exchange live state with another game process. Project scope explicitly excludes an executable Battlefield 6 ↔ Roblox connection, extraction of protected game data, and anticheat bypass. The decision must use supported public extension surfaces and avoid executable or process inspection.

## Official surfaces reviewed

- Roblox officially supports **Studio plugins** as Studio extensions, with toolbar/UI and place-editing APIs. A Studio plugin may communicate with creator-approved web endpoints; Roblox documents that plugins can talk to separately installed local software over `localhost` / `127.0.0.1`, while warning that the separate helper carries security risk and requires careful distribution. This is a creator workstation workflow, not a documented live-game state API. [Roblox Studio plugins](https://create.roblox.com/docs/studio/plugins) · [Roblox HttpService plugin use](https://create.roblox.com/docs/cloud-services/http-service)
- Roblox Studio MCP provides an official way for an authorized client to read/edit/test the open Studio DataModel. It is a development workflow, not an API from an experience server into another game process. [Roblox AI/MCP workflow](https://create.roblox.com/docs/ai/accelerated-workflows)
- EA documents Battlefield Portal creator surfaces: Portal SDK Tool for editing maps, Portal Builder/Rules Editor, and Portal Gadget interactions inside custom Portal experiences. The reviewed guide does not document a supported external process bridge from Portal/Battlefield 6 into a separate Roblox experience. [EA Portal 101](https://www.ea.com/games/battlefield/battlefield-6/news/portal-101-advanced-creations)
- EA’s current User Agreement says EA Services are licensed; access/copy/modification/distribution and source/data extraction are restricted unless expressly authorized or permitted by law. It also states that tampering with technical/content protection measures may terminate the license, and describes anticheat monitoring and unauthorized third-party programs. [EA User Agreement](https://www.ea.com/legal/user-agreement?isLocalized=true&setLocale=en-gb)
- EA identifies Battlefield 6 as requiring Javelin on PC and describes prohibited automation, overlays and tools that circumvent its checks. [Battlefield 6 rules](https://help.ea.com/en/articles/battlefield/battlefield-6/play-by-the-rules/) · [Javelin/Season 4 update](https://www.ea.com/games/battlefield/battlefield-6/news/battlefield-6-anticheat-update-season-4)

## Decision

**No-go** for connecting this Roblox experience to a live Battlefield 6 process or reading its memory, files, window/render output, network traffic, or protected state. No public, documented EA interface for this specific cross-process use was found in the reviewed official sources, and the project scope excludes it. Do not attempt to work around that limitation with injection, scraping, overlays, input automation, packet inspection, or anticheat evasion.

**Go** for these bounded paths:

1. Build and test the Roblox experience independently using original code/assets.
2. Explore Battlefield Portal SDK/Rules Editor only within EA's documented creator workflow and terms; this is separate from Roblox integration.
3. If testing generic interoperability, use a synthetic JSON fixture and a mock local service with no Battlefield process or protected data. Keep any helper opt-in, local, and outside a published Roblox experience.
4. Reconsider a live bridge only if EA publishes an explicit supported API/license for it or provides written authorization, followed by a security and privacy review.

## Obstacles and limits

- The documented Roblox `localhost` plugin capability is scoped to Studio plugins and separately installed helper software; it does not establish permission or support for live game telemetry.
- Portal tools target creator-defined experiences inside the Battlefield Portal ecosystem, not a separate Roblox game.
- Any undocumented process/state access would create licensing, anticheat, privacy, distribution, and maintenance risks. There is no approved telemetry schema or stable interface to version against.
- This is a product/technical go-no-go based on the listed public sources, not a legal interpretation. Local law and any title/platform-specific license can vary.

## Change safety

No game executable, process, memory, packet stream, anti-cheat component, or protected file was inspected or changed. This ADR changes documentation only.
