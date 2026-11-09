# ViolenceDistrict Modular

Modular Lua project scaffold based on the feature inventory recovered from the reference file.

## Goals
- Small core with lazy feature loading.
- Independent modules with Init/Enable/Disable/Destroy lifecycle.
- Central settings and event bus.
- No automatic network telemetry, HWID collection, remote payload execution, or hidden webhooks.
- Competitive-impact features are catalogued but deliberately disabled; no exploit or unfair-play implementation is included.

## Layout
- `src/Core`: module lifecycle, registry, event bus, settings.
- `src/Visual`: local-only crosshair and graphics preference module.
- `src/Movement`: safe movement diagnostics and configurable local profile (does not alter server-authoritative movement).
- `src/Diagnostics`: performance and runtime diagnostics.
- `src/Config`: config validation and storage adapter interface.
- `src/Catalog`: complete recovered feature inventory and disabled-feature reasons.

## Runtime
Designed for a standard Lua environment with adapters supplied by the host. Roblox-specific integrations should be implemented only for permitted local UI/diagnostics. The scaffold does not assume executor APIs.

## Status
Scaffold / early development. Feature names in Catalog are inventory entries, not claims of implemented functionality.
