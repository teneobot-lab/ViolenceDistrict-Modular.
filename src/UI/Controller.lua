-- UI state/controller. The renderer is injected by the host via context.UIAdapter.
local Theme = require(script.Parent.Theme)

local Controller = {}
Controller.__index = Controller

local GROUPS = {
    { id = "Dashboard", label = "Dashboard" },
    { id = "Movement", label = "Movement" },
    { id = "Visual", label = "Visual" },
    { id = "Diagnostics", label = "Diagnostics" },
    { id = "Config", label = "Config" },
}

function Controller.new(registry, loader, settings)
    return setmetatable({
        Registry = registry,
        Loader = loader,
        Settings = settings,
        Adapter = nil,
        Mounted = false,
        ThemeName = "Dark",
    }, Controller)
end

function Controller:BuildModel()
    local groups = {}
    for _, group in ipairs(GROUPS) do
        local entries = {}
        for _, name in ipairs(self.Registry:InGroup(group.id)) do
            entries[#entries + 1] = { id = name, label = name }
        end
        groups[#groups + 1] = { id = group.id, label = group.label, items = entries }
    end
    local espInstance = self.Loader.Loaded.VisibleObjectESP
    local espImplementation = espInstance and espInstance.GetImplementation and espInstance:GetImplementation()
    local espOptions = espImplementation and espImplementation.GetOptions and espImplementation:GetOptions() or nil
    local espSchema = espImplementation and espImplementation.GetOptionSchema and espImplementation:GetOptionSchema() or nil

    return {
        title = "ViolenceDistrict Modular",
        theme = Theme.Get(self.ThemeName),
        groups = groups,
        themeName = self.ThemeName,
        visibleObjectESP = espOptions,
        visibleObjectESPSchema = espSchema,
    }
end

function Controller:Refresh()
    if self.Mounted and self.Adapter and self.Adapter.Update then
        self.Adapter:Update(self:BuildModel())
    end
end

function Controller:Mount(adapter)
    self.Adapter = adapter
    self.Mounted = true
    if adapter and adapter.Mount then adapter:Mount(self:BuildModel(), self) end
end

function Controller:Unmount()
    if self.Adapter and self.Adapter.Unmount then self.Adapter:Unmount() end
    self.Adapter = nil
    self.Mounted = false
end

function Controller:SetTheme(name)
    Theme.Get(name)
    self.ThemeName = name
    self.Settings:Set("theme", name)
    self:Refresh()
end

function Controller:SetModuleOption(name, key, value)
    local instance = self.Loader.Loaded[name]
    local implementation = instance and instance.GetImplementation and instance:GetImplementation()
    if not implementation or not implementation.SetOptions then
        return false, "module does not expose configurable options"
    end
    local patch = {}
    patch[key] = value
    local ok, result = pcall(function() return implementation:SetOptions(patch) end)
    if not ok then return false, result end
    self:Refresh()
    return true, result
end

function Controller:SetFeatureEnabled(name, enabled)
    local instance, err = self.Loader:Load(name)
    if not instance then return false, err end
    local ok, result = pcall(function()
        if enabled then return instance:Enable() end
        return instance:Disable()
    end)
    if not ok then return false, result end
    self:Refresh()
    return true
end

return Controller
