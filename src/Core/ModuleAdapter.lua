-- Adapts small feature models to the common module lifecycle.
local ModuleAdapter = {}
ModuleAdapter.__index = ModuleAdapter

function ModuleAdapter.new(name, implementation)
    assert(type(implementation) == "table", "implementation required")
    return setmetatable({
        Name = name,
        Implementation = implementation,
        State = "new",
        Context = nil,
    }, ModuleAdapter)
end

function ModuleAdapter:Init(context)
    self.Context = context or {}
    self.State = "initialized"
    if self.Implementation.Init then
        self.Implementation:Init(self.Context)
    end
end

function ModuleAdapter:Enable()
    if self.State == "destroyed" then return false, "module destroyed" end
    if self.State == "enabled" then return true end
    if self.Implementation.Enable then self.Implementation:Enable() end
    self.State = "enabled"
    return true
end

function ModuleAdapter:Disable()
    if self.State ~= "enabled" then return end
    if self.Implementation.Disable then self.Implementation:Disable() end
    self.State = "initialized"
end

function ModuleAdapter:Destroy()
    if self.State == "destroyed" then return end
    self:Disable()
    if self.Implementation.Destroy then self.Implementation:Destroy() end
    self.Context = nil
    self.State = "destroyed"
end

function ModuleAdapter:GetImplementation()
    return self.Implementation
end

return ModuleAdapter
