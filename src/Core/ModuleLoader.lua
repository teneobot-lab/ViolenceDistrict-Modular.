local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

function ModuleLoader.new(registry, context)
    return setmetatable({
        Registry = registry,
        Context = context or {},
        Loaded = {},
    }, ModuleLoader)
end

function ModuleLoader:Load(name)
    if self.Loaded[name] then return self.Loaded[name] end
    local entry = self.Registry:Get(name)
    if not entry then return nil, "unknown module: " .. name end
    local instance = entry.factory()
    if instance.Init then instance:Init(self.Context) end
    entry.instance = instance
    self.Loaded[name] = instance
    return instance
end

function ModuleLoader:LoadGroup(group)
    local loaded = {}
    for _, name in ipairs(self.Registry:InGroup(group)) do
        local instance, err = self:Load(name)
        if instance then loaded[#loaded + 1] = instance
        elseif self.Context.onError then self.Context.onError(name, err) end
    end
    return loaded
end

function ModuleLoader:Destroy()
    for _, instance in pairs(self.Loaded) do
        if instance.Destroy then pcall(function() instance:Destroy() end) end
    end
    self.Loaded = {}
end

return ModuleLoader
