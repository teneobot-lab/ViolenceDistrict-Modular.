local ModuleLoader = require(script.Core.ModuleLoader)
local ModuleAdapter = require(script.Core.ModuleAdapter)
local Registry = require(script.Core.Registry)
local Settings = require(script.Core.Settings)
local UIController = require(script.UI.Controller)
local RobloxRenderer = require(script.UI.RobloxRenderer)

local app = {
    Registry = Registry.new(),
    Loader = nil,
    Settings = Settings.new({
        theme = "Dark",
        enableMovementDiagnostics = true,
        showUI = true,
    }),
    UI = nil,
    Context = nil,
}

local function registerSafeModules()
    app.Registry:Register("MovementDiagnostics", function()
        return ModuleAdapter.new("MovementDiagnostics", require(script.Movement.Diagnostics).new())
    end, "Movement")

    app.Registry:Register("Crosshair", function()
        return ModuleAdapter.new("Crosshair", require(script.Visual.Crosshair).new())
    end, "Visual")

    app.Registry:Register("GraphicsProfile", function()
        return ModuleAdapter.new("GraphicsProfile", require(script.Visual.GraphicsProfile).new())
    end, "Visual")

    app.Registry:Register("VisibleObjectESP", function()
        return ModuleAdapter.new("VisibleObjectESP", require(script.Visual.WorldMarkers).new({
            maxDistance = 250,
            updateInterval = 0.2,
            showDistance = true,
            showHealth = true,
            showBounds = true,
        }))
    end, "Visual")

    app.Registry:Register("RuntimeDiagnostics", function()
        return ModuleAdapter.new("RuntimeDiagnostics", require(script.Diagnostics.Runtime).new())
    end, "Diagnostics")
end

registerSafeModules()

function app:Start(context)
    if self.Loader then return false, "app already started" end
    self.Context = context or {}
    local moduleContext = {
        settings = self.Settings,
        onError = self.Context.onError,
        movementSampler = self.Context.movementSampler,
        player = self.Context.player,
    }
    self.Loader = ModuleLoader.new(self.Registry, moduleContext)
    self.Loader:LoadGroup("Diagnostics")
    self.Loader:LoadGroup("Visual")
    self.Loader:LoadGroup("Movement")

    self.UI = UIController.new(self.Registry, self.Loader, self.Settings)
    self.UI:SetTheme(self.Settings:Get("theme", "Dark"))

    local adapter = self.Context.UIAdapter
    if adapter == nil and self.Settings:Get("showUI", true) then
        adapter = RobloxRenderer.new()
    end
    self.UI:Mount(adapter)

    if self.Settings:Get("enableMovementDiagnostics", true) then
        self.UI:SetFeatureEnabled("MovementDiagnostics", true)
    end
    return true
end

function app:SetFeatureEnabled(name, enabled)
    if not self.Loader or not self.UI then return false, "app is not started" end
    return self.UI:SetFeatureEnabled(name, enabled)
end

function app:SetTheme(name)
    if not self.UI then return false, "app is not started" end
    self.UI:SetTheme(name)
    return true
end

function app:Stop()
    if self.UI then self.UI:Unmount(); self.UI = nil end
    if self.Loader then self.Loader:Destroy(); self.Loader = nil end
    self.Context = nil
end

return app
