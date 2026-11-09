# Architecture

Feature modules are independent and loaded by group on demand. Core owns lifecycle and shared services; feature modules should not require each other directly. Inject dependencies through the loader context.

## Module contract
- `Init(context)`: validate dependencies and prepare state.
- `Enable()`: start optional behavior.
- `Disable()`: stop behavior and release active connections.
- `Destroy()`: permanently release references.

Keep per-frame work out of core. Prefer event-driven updates, bounded buffers, cached lookups, and explicit cleanup.
