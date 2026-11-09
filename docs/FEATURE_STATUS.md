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
- The experience developer must tag eligible BasePart or Model instances with CollectionService tag `VDM_DebugTarget`.
- Optional String attribute `VDM_DebugCategory` supports `Environment`, `Interactable`, `Resource`, or `Other`; missing/unknown values are treated as `Other`.
- The Visual settings panel can cycle marker color, label size, maximum distance, and update interval, and toggle each supported category. Defaults are Blue, 12 px, 250 studs, and 0.2 seconds.
- Player characters are excluded.
- Targets behind geometry are hidden using a camera raycast.
- BillboardGui uses `AlwaysOnTop = false`; Highlight uses `DepthMode = Occluded`.
- This is a debugging aid for a place the developer owns, not a hidden-player/object scanner. It will not discover untagged game entities in third-party experiences.

## Catalogued but intentionally not implemented
Features that automate competitive actions, alter server-authoritative movement, manipulate remotes, target other players, reveal hidden players/objects, bypass game mechanics, or interfere with objectives are inventory-only. This includes silent aim, aimbots, autofarm, auto-parry, remote pallet actions, trajectory noclip, network desync, speed/vault manipulation, and wall-penetrating ESP.

## Security decisions
The original file contains references to HWID/session/license checks, remote payload loading, external HTTP requests, heartbeat/logging, and webhook integration. This project does not reproduce device fingerprinting, hidden telemetry, remote code execution, or undisclosed webhook transmission. If online services are ever added, they must be documented, opt-in, and use an explicit endpoint configuration.
