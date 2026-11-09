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

## Catalogued but intentionally not implemented
Features that automate competitive actions, alter server-authoritative movement, manipulate remotes, target other players, reveal hidden players/objects, bypass game mechanics, or interfere with objectives are inventory-only. This includes silent aim, aimbots, autofarm, auto-parry, remote pallet actions, trajectory noclip, network desync, speed/vault manipulation, and wall-penetrating ESP.

## Security decisions
The original file contains references to HWID/session/license checks, remote payload loading, external HTTP requests, heartbeat/logging, and webhook integration. This project does not reproduce device fingerprinting, hidden telemetry, remote code execution, or undisclosed webhook transmission. If online services are ever added, they must be documented, opt-in, and use an explicit endpoint configuration.
