local Module = {}
Module.__index = Module

function Module.new(name, dependencies)
    return setmetatable({
        Name = name,
        Dependencies = dependencies or {},
        State = "new",
    }, Module)
end

function Module:Init(context)
    self.Context = context
    self.State = "initialized"
end

function Module:Enable()
    if self.State == "destroyed" then
        return false, "module destroyed"
    end
    self.State = "enabled"
    return true
end

function Module:Disable()
    if self.State == "enabled" then
        self.State = "initialized"
    end
end

function Module:Destroy()
    self:Disable()
    self.Context = nil
    self.State = "destroyed"
end

return Module
