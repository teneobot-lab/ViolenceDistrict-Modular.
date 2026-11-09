local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({ modules = {} }, Registry)
end

function Registry:Register(name, factory, group)
    assert(type(name) == "string" and type(factory) == "function")
    assert(not self.modules[name], "duplicate module: " .. name)
    self.modules[name] = { factory = factory, group = group or "Other", instance = nil }
end

function Registry:Get(name)
    return self.modules[name]
end

function Registry:InGroup(group)
    local result = {}
    for name, entry in pairs(self.modules) do
        if entry.group == group then result[#result + 1] = name end
    end
    table.sort(result)
    return result
end

return Registry
