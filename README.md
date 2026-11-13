# ViolenceDistrict Modular

A modular Luau project scaffold based on the recovered feature inventory from the reference source.

## Goals
- Small core with lazy feature loading.
- Independent module lifecycle: `Init`, `Enable`, `Disable`, and `Destroy`.
- Native Roblox UI with an injectable renderer adapter.
- Explicit dependency injection for host-specific integrations.
- No automatic network telemetry, HWID collection, remote payload execution, or hidden webhooks.
- Competitive-impact features are catalogued but deliberately disabled; no exploit or unfair-play implementation is included.

## Layout
- `src/Core`: module lifecycle, registry, adapters, loader, event bus, and settings.
- `src/UI`: navigation controller, theme presets, and native Roblox ScreenGui renderer.
- `src/Visual`: local crosshair state, graphics preferences, and visible-only tagged debug object markers.
- `src/Movement`: passive movement diagnostics and local profile preferences.
- `src/Diagnostics`: runtime uptime and sample snapshots.
- `src/Config`: config validation and storage adapter interface.
- `src/Catalog` and `src/Modules`: recovered feature inventory and safe runtime manifest.
- `docs`: architecture, feature status, and implementation notes.

## Bootstrap

Place the folders under one Roblox ModuleScript hierarchy with `init.lua` as the entry point:

```lua
local App = require(path.to.src.init)

App:Start({
    -- Optional: replace the built-in native Roblox renderer.
    UIAdapter = customRenderer,
    -- Optional passive sampler; no movement values are modified.
    movementSampler = myMovementSampler,
    onError = function(moduleName, message)
        warn(moduleName .. ": " .. message)
    end,
})

App:SetFeatureEnabled("Crosshair", true)
App:SetTheme("Light")
App:Stop()
```

If `UIAdapter` is omitted, the built-in `RobloxRenderer` mounts a ScreenGui under the local player's PlayerGui. It includes Dashboard, Movement, Visual, Diagnostics, and Config navigation; feature toggles; Dark/Light themes; draggable, minimize, and hide controls; and viewport-aware scaling. The close control hides the panel; call `App:Stop()` to destroy it and release connections.

Custom UI adapter contract:
- `Mount(model, controller)` — required to display a UI.
- `Update(model)` — optional, called when the model or theme changes.
- `Unmount()` — optional cleanup.

Visible object marker setup (for a place you own):
- Add the CollectionService tag `VDM_DebugTarget` to a `BasePart` or `Model` you want to inspect.
- Optionally set the String attribute `VDM_DebugCategory` to `Environment`, `Interactable`, `Resource`, or `Other`. Missing or unrecognized values are grouped as `Other`.
- Open the Visual page settings panel to cycle marker color (Blue/Green/Amber/Violet/White), label size (10–20 px), maximum distance (100–1000 studs), update interval (0.1–1 s), and category filters. `WorldMarkers:GetOptionSchema()` is the source of truth for the panel's available values and category list.
- Enable `VisibleObjectESP` from the Visual page or with `App:SetFeatureEnabled("VisibleObjectESP", true)`.
- Markers show the object name, distance, and Humanoid health when available. Bounding outlines are occlusion-aware; player characters are excluded.
- Untagged instances and objects hidden behind geometry are not shown. This module is not a scanner for third-party game entities.

Movement sampler contract:
- `Subscribe(callback)` returns either a disconnect function or a connection object with `Disconnect()`.
- The callback receives a sample table containing optional `position`, `velocity`, and `grounded` fields.
- The sampler is supplied by the host; this project does not alter movement or server state.

## Runtime status

The native renderer is implemented against Roblox Instance APIs. It has not yet been executed in Roblox Studio in this environment. Crosshair drawing, actual graphics application, persistent config storage, and host sampling still require explicit implementations/adapters.

## Safety boundary

Aim assistance, wall-penetrating ESP, noclip, remote-event manipulation, objective automation, hidden telemetry, HWID fingerprinting, and remote code execution are not implemented. Their recovered names remain inventory-only for audit purposes.
