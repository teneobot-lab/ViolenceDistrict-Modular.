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

    local ok, instance = pcall(entry.factory)
    if not ok then return nil, "factory failed: " .. tostring(instance) end
    if type(instance) ~= "table" then
        return nil, "factory must return a module table"
    end

    if instance.Init then
        local initOk, initErr = pcall(function() instance:Init(self.Context) end)
        if not initOk then
            if instance.Destroy then pcall(function() instance:Destroy() end) end
            return nil, "initialization failed: " .. tostring(initErr)
        end
    end

    entry.instance = instance
    self.Loaded[name] = instance
    return instance
end

function ModuleLoader:LoadGroup(group)
    local loaded = {}
    for _, name in ipairs(self.Registry:InGroup(group)) do
        local instance, err = self:Load(name)
        if instance then
            loaded[#loaded + 1] = instance
        elseif self.Context.onError then
            pcall(self.Context.onError, name, err)
        end
    end
    return loaded
end

function ModuleLoader:Destroy()
    for name, instance in pairs(self.Loaded) do
        if instance.Destroy then
            local ok, err = pcall(function() instance:Destroy() end)
            if not ok and self.Context.onError then
                pcall(self.Context.onError, name, "destroy failed: " .. tostring(err))
            end
        end
        local entry = self.Registry:Get(name)
        if entry then entry.instance = nil end
    end
    self.Loaded = {}
end

return ModuleLoader
