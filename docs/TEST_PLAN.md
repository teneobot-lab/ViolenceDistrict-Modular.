# Manual Test Plan

Run these checks in a clean Roblox Luau test place with the source folders represented as ModuleScripts.

## Bootstrap and lifecycle
1. Require `src/init.lua`.
2. Call `App:Start({})`; expect `true` and a ScreenGui under the local player's PlayerGui.
3. Call `App:Start({})` again; expect `false, "app already started"`.
4. Call `App:SetFeatureEnabled("Crosshair", true)`; expect success and the Visual card to show ON.
5. Disable Crosshair; expect success and the card to show OFF.
6. Call `App:SetTheme("Light")`; expect the visible UI to switch to the Light palette.
7. Call `App:Stop()`; expect ScreenGui destruction, input connection cleanup, and no retained loaded module instances.
8. Start again; expect a clean second lifecycle.

## VisibleObjectESP
1. In a test place you own, create a Part named `DebugCrate` and tag it with CollectionService tag `VDM_DebugTarget`.
2. Start the app and enable `VisibleObjectESP`; expect a marker with the object name.
3. Move closer/farther; expect distance text to update and the marker to disappear beyond 250 studs.
4. Place a wall between the camera and the tagged part; expect the marker and outline to hide.
5. Remove the wall; expect the marker to return.
6. Tag a Model containing a Humanoid; expect health text to appear when enabled.
7. Tag a player character; expect it to be excluded.
8. Remove the tag or destroy the target; expect marker and Highlight instances to be cleaned up.
9. Disable the module and stop the app; expect the Heartbeat connection and marker folder to be removed.
10. Confirm untagged objects and objects in third-party experiences are not discovered.
11. In the Visual page, cycle marker color and label size; verify existing and newly created markers update immediately.
12. Cycle maximum distance and update interval; verify the distance cutoff, outline visibility, and refresh cadence follow the selected values immediately after each change.
13. Tag owned test objects with `VDM_DebugTarget` and set `VDM_DebugCategory` to each supported value (`Environment`, `Interactable`, `Resource`, `Other`); verify category toggles include/exclude only the selected categories.
14. Set a missing or unknown category attribute; verify the object is classified as `Other` and follows that filter.
15. Disable all category filters; verify no tagged debug markers remain visible. Re-enable one category and verify only its tagged targets return.
16. Add the debug tag to an instance outside `Workspace`; verify it never receives a marker.
17. Set a tagged target's parts to `CanQuery = false`; verify a raycast miss does not make it appear visible.
18. Tag a model nested inside a player character, and a model that contains a player character; verify both are excluded.
19. Toggle each category button independently; verify only the selected category changes and the other three retain their previous states.
20. Change several ESP settings repeatedly while remaining on Visual; verify each new control works once, with no duplicate callbacks or stale page connections.

## Native Roblox renderer
1. Start with no injected `UIAdapter`; expect the built-in renderer to mount.
2. Confirm Dashboard, Movement, Visual, Diagnostics, and Config navigation buttons switch pages.
3. Confirm Dashboard module and active counters reflect registered and enabled modules.
4. Confirm feature cards display the current lifecycle state and toggles update it.
5. Switch between Dark and Light in Config; verify surfaces, text, and navigation update.
6. Drag the title bar with mouse and touch; verify the window follows the pointer.
7. Minimize and restore the window; use the close control to hide it.
8. Resize the viewport and test desktop, tablet, and narrow mobile dimensions; verify content remains reachable by scrolling.
9. Stop and restart repeatedly; verify no duplicate ScreenGui or stale input handlers.

## Custom UI adapter
1. Inject an adapter with `Mount(model, controller)`.
2. Confirm the model contains Dashboard, Movement, Visual, Diagnostics, and Config groups.
3. Confirm Visual contains Crosshair, GraphicsProfile, and VisibleObjectESP.
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

## Verification status
The native renderer and VisibleObjectESP are implemented but have not been executed in Roblox Studio in this environment. Complete the manual checks above before treating them as runtime-verified.
