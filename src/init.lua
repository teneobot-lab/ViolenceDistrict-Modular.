local ModuleLoader = require(script.Core.ModuleLoader)
local ModuleAdapter = require(script.Core.ModuleAdapter)
local Registry = require(script.Core.Registry)
local Settings = require(script.Core.Settings)
local UIController = require(script.UI.Controller)

local app = {
    Registry = Registry.new(),
    Loader = nil,
    Settings = Settings.new({
        theme = "Dark",
        enableMovementDiagnostics = true,
    }),
    UI = nil,
    Context = nil,
}

local function registerSafeModules()
    app.Registry:Register("MovementDiagnostics", function()
        local implementation = require(script.Movement.Diagnostics).new()
        return ModuleAdapter.new("MovementDiagnostics", implementation)
    end, "Movement")

    app.Registry:Register("Crosshair", function()
        local implementation = require(script.Visual.Crosshair).new()
        return ModuleAdapter.new("Crosshair", implementation)
    end, "Visual")

    app.Registry:Register("GraphicsProfile", function()
        local implementation = require(script.Visual.GraphicsProfile).new()
        return ModuleAdapter.new("GraphicsProfile", implementation)
    end, "Visual")

    app.Registry:Register("RuntimeDiagnostics", function()
        local implementation = require(script.Diagnostics.Runtime).new()
        return ModuleAdapter.new("RuntimeDiagnostics", implementation)
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
    }

    self.Loader = ModuleLoader.new(self.Registry, moduleContext)
    self.Loader:LoadGroup("Diagnostics")
    self.Loader:LoadGroup("Visual")
    self.Loader:LoadGroup("Movement")

    self.UI = UIController.new(self.Registry, self.Loader, self.Settings)
    self.UI:SetTheme(self.Settings:Get("theme", "Dark"))
    self.UI:Mount(self.Context.UIAdapter)

    if self.Settings:Get("enableMovementDiagnostics", true) then
        self.UI:SetFeatureEnabled("MovementDiagnostics", true)
    end

    return true
end

function app:SetFeatureEnabled(name, enabled)
    if not self.Loader or not self.UI then
        return false, "app is not started"
    end
    return self.UI:SetFeatureEnabled(name, enabled)
end

function app:Stop()
    if self.UI then
        self.UI:Unmount()
        self.UI = nil
    end
    if self.Loader then
        self.Loader:Destroy()
        self.Loader = nil
    end
    self.Context = nil
end

return app
