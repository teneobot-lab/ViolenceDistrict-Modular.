local Settings = {}
Settings.__index = Settings

function Settings.new(defaults)
    return setmetatable({ values = table.clone(defaults or {}) }, Settings)
end

function Settings:Get(key, fallback)
    local value = self.values[key]
    if value == nil then return fallback end
    return value
end

function Settings:Set(key, value)
    assert(type(key) == "string", "setting key must be a string")
    self.values[key] = value
end

function Settings:Snapshot()
    return table.clone(self.values)
end

return Settings
