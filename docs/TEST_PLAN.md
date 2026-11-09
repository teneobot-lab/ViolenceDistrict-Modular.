# Manual Test Plan

Run these checks in a clean Roblox Luau test place with the source folders represented as ModuleScripts.

## Bootstrap and lifecycle
1. Require `src/init.lua`.
2. Call `App:Start({})`; expect `true`.
3. Call `App:Start({})` again; expect `false, "app already started"`.
4. Call `App:SetFeatureEnabled("Crosshair", true)`; expect success.
5. Disable Crosshair; expect success.
6. Call `App:Stop()`; expect no retained UI adapter or loaded module instances.
7. Start again; expect a clean second lifecycle.

## UI adapter
1. Inject an adapter with `Mount(model, controller)`.
2. Confirm the model contains Dashboard, Movement, Visual, Diagnostics, and Config groups.
3. Confirm Visual contains Crosshair and GraphicsProfile.
4. Call `controller:SetTheme("Light")`; expect `Update(model)` if supplied.
5. Stop the app; expect `Unmount()`.

## Passive movement sampler
1. Inject a sampler whose `Subscribe(callback)` stores the callback and returns a disconnect function.
2. Start the app; MovementDiagnostics should be enabled by default.
3. Send a sample with position, velocity, and grounded fields.
4. Inspect the module implementation via the loaded module adapter and confirm the last sample is recorded.
5. Stop the app; confirm the disconnect function was called.
6. Confirm no code path writes character velocity, speed, or server state.

## Failure isolation
1. Register a test factory that throws.
2. Load its group and confirm the configured `onError` callback receives the failure.
3. Confirm other factories in the same group still load.
4. Confirm destroying the loader cleans up successfully initialized modules.

## Not covered by this test plan
A concrete visual renderer, graphics API integration, persistent config backend, and game-specific host sampler must each be tested independently when implemented.
