# Feature status

## Implemented scaffold
- Module registry and lazy loader.
- Module lifecycle.
- Event bus.
- Settings container.
- Config validation and injected storage interface.
- Passive movement sample collector.
- Crosshair state model.
- Local graphics preference model.
- Runtime diagnostics.
- Visible-only debug object markers for explicitly tagged objects in an experience the developer owns. Includes name, distance, optional Humanoid health, occluded bounding outline, range limit, and automatic cleanup.

## VisibleObjectESP scope
- The module requires an explicit numeric PlaceId allowlist supplied as `allowedPlaceIds` in the `VisibleObjectESP` constructor in `src/init.lua`. The default list is empty and `Enable()` fails closed until the current PlaceId is listed. Only positive integer IDs are accepted; malformed entries are ignored. Only add places the user owns; this is an additional guard, not a substitute for developer-controlled tags.
- The experience developer must tag eligible BasePart or Model instances with CollectionService tag `VDM_DebugTarget`.
- Optional String attribute `VDM_DebugCategory` supports `Environment`, `Interactable`, `Resource`, or `Other`; missing/unknown values are treated as `Other`. A known category that is disabled stays excluded and is never remapped to `Other`.
- The Visual settings panel can cycle marker color, label size, maximum distance, and update interval, and toggle each supported category. Defaults are Blue, 12 px, 250 studs, and 0.2 seconds. Available values, labels, suffixes, and category names are exposed by `WorldMarkers:GetOptionSchema()`; the renderer consumes this schema instead of maintaining a duplicate list. `SetOptions` validates the full patch before changing state: unsupported keys/values, non-table category maps, unknown categories, and non-boolean category values are rejected atomically. Partial category maps update only the named categories. `Controller:SetModuleOption` forwards validation failures instead of reporting them as successful UI updates. Constructor-supplied scalar values are also normalized against the schema, falling back to Blue/12 px/250 studs/0.2 seconds when unsupported; malformed initial category values default to enabled rather than being treated as truthy.
- Player characters are excluded.
- Targets must be descendants of `Workspace`; targets outside the rendered world are ignored.
- A camera raycast must hit the tagged target (or one of its descendants) before a marker is shown; a raycast miss or near-zero ray direction is treated as not visible. If `CurrentCamera` is unavailable, existing markers are hidden rather than left stale. Reusable RaycastParams exclude the local character and refresh their filter when that character changes.
- Disabling the module disconnects Heartbeat, destroys marker instances, resets the update accumulator, and clears the cached character exclusion from RaycastParams.
- Player characters are excluded even when a tagged object is nested inside or wraps a character model.
- BillboardGui uses `AlwaysOnTop = false`; Highlight uses `DepthMode = Occluded`.
- This is a debugging aid for a place the developer owns, not a hidden-player/object scanner. It will not discover untagged game entities in third-party experiences.

## Catalogued but intentionally not implemented
Features that automate competitive actions, alter server-authoritative movement, manipulate remotes, target other players, reveal hidden players/objects, bypass game mechanics, or interfere with objectives are inventory-only. This includes silent aim, aimbots, autofarm, auto-parry, remote pallet actions, trajectory noclip, network desync, speed/vault manipulation, and wall-penetrating ESP.

## Security decisions
The original file contains references to HWID/session/license checks, remote payload loading, external HTTP requests, heartbeat/logging, and webhook integration. This project does not reproduce device fingerprinting, hidden telemetry, remote code execution, or undisclosed webhook transmission. If online services are ever added, they must be documented, opt-in, and use an explicit endpoint configuration.
