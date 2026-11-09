# ViolenceDistrict Modular

A modular Luau project scaffold based on the recovered feature inventory from the reference source.

## Goals
- Small core with lazy feature loading.
- Independent module lifecycle: `Init`, `Enable`, `Disable`, and `Destroy`.
- Renderer-independent UI model and theme tokens.
- Explicit dependency injection for host-specific integrations.
- No automatic network telemetry, HWID collection, remote payload execution, or hidden webhooks.
- Competitive-impact features are catalogued but deliberately disabled; no exploit or unfair-play implementation is included.

## Layout
- `src/Core`: module lifecycle, registry, adapters, loader, event bus, and settings.
- `src/UI`: navigation model, theme presets, and host-renderer contract.
- `src/Visual`: local crosshair state and graphics preference profile.
- `src/Movement`: passive movement diagnostics and local profile preferences.
- `src/Diagnostics`: runtime uptime and sample snapshots.
- `src/Config`: config validation and storage adapter interface.
- `src/Catalog` and `src/Modules`: recovered feature inventory and safe runtime manifest.
- `docs`: architecture, feature status, and implementation notes.

## Bootstrap

The entry point is `src/init.lua`. Place the folders under a Roblox ModuleScript hierarchy, require the entry point, and call:

```lua
local App = require(path.to.init)

App:Start({
    UIAdapter = myUIRenderer, -- optional
    movementSampler = myMovementSampler, -- optional, passive data only
    onError = function(moduleName, message)
        warn(moduleName .. ": " .. message)
    end,
})

App:SetFeatureEnabled("Crosshair", true)
App:SetFeatureEnabled("Crosshair", false)
App:Stop()
```

The UI adapter contract is:
- `Mount(model, controller)` — required to display a UI.
- `Update(model)` — optional, called when the theme changes.
- `Unmount()` — optional cleanup.

The movement sampler contract is:
- `Subscribe(callback)` returns either a disconnect function or a connection object with `Disconnect()`.
- The callback receives a sample table containing optional `position`, `velocity`, and `grounded` fields.
- The sampler is supplied by the host; this project does not alter movement or server state.

## Runtime status

The safe feature factories are registered by the bootstrap and loaded independently. The UI controller produces a model and does not assume a particular UI library. Crosshair rendering, actual graphics application, persistent storage, and host sampling still require explicit adapters.

This project currently targets Roblox Luau ModuleScripts. It does not assume executor APIs.

## Safety boundary

Aim assistance, wall-penetrating ESP, noclip, remote-event manipulation, objective automation, hidden telemetry, HWID fingerprinting, and remote code execution are not implemented. Their recovered names remain inventory-only for audit purposes.
