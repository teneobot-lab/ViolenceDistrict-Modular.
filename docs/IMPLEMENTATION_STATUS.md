# Implementation Status

## Wired into the runtime
- Module adapter: common lifecycle around small feature models.
- Bootstrap: registers safe feature factories and starts selected groups.
- UI controller: renderer-independent navigation model, theme tokens, and feature toggles.
- Movement diagnostics: passive sample storage only; it never writes movement values.
- Crosshair: local state model; actual drawing requires a host UI adapter.
- Graphics profile: stores preferences; it does not inject post-processing.
- Runtime diagnostics: uptime and explicitly submitted samples.

## Host integration still required
- A concrete UI renderer implementing `Mount(model, controller)`, optional `Update(model)`, and optional `Unmount()`.
- A trusted movement sampler that submits only data from the user's own experience.
- A storage backend for persistent configuration.
- Runtime testing in the intended Lua host.

## Not implemented
Competitive-impact automation, aim assistance, wall-penetrating ESP, noclip, remote-event manipulation, objective automation, hidden telemetry, HWID fingerprinting, and remote code execution are not implemented.
