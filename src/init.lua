local ModuleLoader = require(script.Core.ModuleLoader)
local Registry = require(script.Core.Registry)

local app = {
    Registry = Registry.new(),
    Loader = nil,
}

function app:Start()
    self.Loader = ModuleLoader.new(self.Registry)
    self.Loader:LoadGroup("Diagnostics")
    self.Loader:LoadGroup("Visual")
    self.Loader:LoadGroup("Movement")
end

function app:Stop()
    if self.Loader then
        self.Loader:Destroy()
        self.Loader = nil
    end
end

return app
