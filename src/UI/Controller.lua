-- UI state/controller. A renderer can be injected by the host via context.UIAdapter.
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
        groups[#groups + 1] = {
            id = group.id,
            label = group.label,
            items = entries,
        }
    end

    return {
        title = "ViolenceDistrict Modular",
        theme = Theme.Get(self.ThemeName),
        groups = groups,
        themeName = self.ThemeName,
    }
end

function Controller:Mount(adapter)
    self.Adapter = adapter
    self.Mounted = true
    if adapter and adapter.Mount then
        adapter:Mount(self:BuildModel(), self)
    end
end

function Controller:Unmount()
    if self.Adapter and self.Adapter.Unmount then
        self.Adapter:Unmount()
    end
    self.Adapter = nil
    self.Mounted = false
end

function Controller:SetTheme(name)
    Theme.Get(name) -- validates the requested preset
    self.ThemeName = name
    if self.Mounted and self.Adapter and self.Adapter.Update then
        self.Adapter:Update(self:BuildModel())
    end
end

function Controller:SetFeatureEnabled(name, enabled)
    local instance, err = self.Loader:Load(name)
    if not instance then return false, err end

    local ok, result
    if enabled then
        ok, result = pcall(function() return instance:Enable() end)
    else
        ok, result = pcall(function() return instance:Disable() end)
    end
    if not ok then return false, result end
    return true
end

return Controller
