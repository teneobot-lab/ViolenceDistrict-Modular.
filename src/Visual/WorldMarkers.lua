-- Visible-only object markers for developer-tagged debug instances in an experience you own.
-- Eligible targets must carry CollectionService tag "VDM_DebugTarget".
-- Optional String attribute "VDM_DebugCategory" selects a developer-defined category.
-- Player characters are always excluded and occluded targets are never revealed.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TAG = "VDM_DebugTarget"
local CATEGORY_ATTRIBUTE = "VDM_DebugCategory"
local CATEGORY_KEYS = { "Environment", "Interactable", "Resource", "Other" }
local COLORS = {
    Blue = Color3.fromRGB(76, 155, 255),
    Green = Color3.fromRGB(83, 210, 145),
    Amber = Color3.fromRGB(255, 184, 77),
    Violet = Color3.fromRGB(177, 133, 255),
    White = Color3.fromRGB(235, 242, 255),
}
local WorldMarkers = {}
WorldMarkers.__index = WorldMarkers

local function getAdornee(target)
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") then
        return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function isPlayerCharacter(target)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and (
            target == character
            or target:IsDescendantOf(character)
            or character:IsDescendantOf(target)
        ) then
            return true
        end
    end
    return false
end

local function normalizeCategories(value)
    local result = {}
    if type(value) == "table" then
        for _, category in ipairs(CATEGORY_KEYS) do
            result[category] = value[category] ~= false
        end
    else
        for _, category in ipairs(CATEGORY_KEYS) do result[category] = true end
    end
    return result
end

function WorldMarkers.new(options)
    options = options or {}
    return setmetatable({
        enabled = false,
        options = {
            maxDistance = math.clamp(tonumber(options.maxDistance) or 250, 25, 1000),
            updateInterval = math.clamp(tonumber(options.updateInterval) or 0.2, 0.1, 1),
            labelSize = math.clamp(tonumber(options.labelSize) or 12, 10, 20),
            markerColor = COLORS[options.markerColor] and options.markerColor or "Blue",
            categories = normalizeCategories(options.categories),
            showDistance = options.showDistance ~= false,
            showHealth = options.showHealth ~= false,
            showBounds = options.showBounds ~= false,
        },
        player = nil,
        folder = nil,
        markers = {},
        heartbeat = nil,
        elapsed = 0,
    }, WorldMarkers)
end

function WorldMarkers:Init(context)
    self.player = context and context.player or Players.LocalPlayer
end

function WorldMarkers:GetOptions()
    local copy = table.clone(self.options)
    copy.categories = table.clone(self.options.categories)
    return copy
end

function WorldMarkers:SetOptions(patch)
    assert(type(patch) == "table", "options patch must be a table")
    local options = self.options
    if patch.maxDistance ~= nil then
        options.maxDistance = math.clamp(tonumber(patch.maxDistance) or options.maxDistance, 25, 1000)
    end
    if patch.updateInterval ~= nil then
        options.updateInterval = math.clamp(tonumber(patch.updateInterval) or options.updateInterval, 0.1, 1)
    end
    if patch.labelSize ~= nil then
        options.labelSize = math.clamp(tonumber(patch.labelSize) or options.labelSize, 10, 20)
    end
    if patch.markerColor ~= nil and COLORS[patch.markerColor] then
        options.markerColor = patch.markerColor
    end
    if patch.categories ~= nil then
        options.categories = normalizeCategories(patch.categories)
    end
    for target, marker in pairs(self.markers) do
        local adornee = getAdornee(target)
        local camera = workspace.CurrentCamera
        if not target:IsDescendantOf(workspace)
            or isPlayerCharacter(target)
            or not self:_categoryAllowed(target)
        then
            self:_clearMarker(target)
        elseif not adornee or not camera then
            marker.gui.Enabled = false
            if marker.highlight then marker.highlight.Enabled = false end
        else
            self:_applyStyle(marker)
            local distance = (camera.CFrame.Position - adornee.Position).Magnitude
            local visible = distance <= options.maxDistance and self:_isVisible(target, adornee.Position)
            marker.gui.Enabled = visible
            if marker.highlight then marker.highlight.Enabled = visible end
        end
    end
    return self:GetOptions()
end

function WorldMarkers:_applyStyle(marker)
    local color = COLORS[self.options.markerColor] or COLORS.Blue
    marker.text.TextColor3 = color
    marker.text.TextSize = self.options.labelSize
    marker.gui.MaxDistance = self.options.maxDistance
    if marker.highlight then marker.highlight.OutlineColor = color end
end

function WorldMarkers:_clearMarker(target)
    local marker = self.markers[target]
    if not marker then return end
    if marker.gui then marker.gui:Destroy() end
    if marker.highlight then marker.highlight:Destroy() end
    self.markers[target] = nil
end

function WorldMarkers:_clearAll()
    for target in pairs(self.markers) do self:_clearMarker(target) end
end

function WorldMarkers:_makeMarker(target, adornee)
    local gui = Instance.new("BillboardGui")
    gui.Name = "VDM_VisibleObjectMarker"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(180, 48)
    gui.StudsOffset = Vector3.new(0, 2.8, 0)
    gui.AlwaysOnTop = false
    gui.MaxDistance = self.options.maxDistance
    gui.Enabled = false

    local text = Instance.new("TextLabel")
    text.Name = "Info"
    text.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
    text.BackgroundTransparency = 0.18
    text.BorderSizePixel = 0
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamSemibold
    text.TextStrokeTransparency = 0.65
    text.TextWrapped = true
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text

    local highlight
    if self.options.showBounds then
        highlight = Instance.new("Highlight")
        highlight.Name = "VDM_VisibleObjectBounds"
        highlight.Adornee = target
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 0.08
        highlight.Enabled = false
        highlight.Parent = workspace
    end

    gui.Parent = self.folder
    local marker = { gui = gui, text = text, highlight = highlight }
    self:_applyStyle(marker)
    self.markers[target] = marker
end

function WorldMarkers:_isVisible(target, position)
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local origin = camera.CFrame.Position
    local direction = position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = self.player and self.player.Character and { self.player.Character } or {}
    local result = workspace:Raycast(origin, direction, params)
    return result ~= nil and (result.Instance == target or result.Instance:IsDescendantOf(target))
end

function WorldMarkers:_categoryAllowed(target)
    local category = target:GetAttribute(CATEGORY_ATTRIBUTE)
    if type(category) ~= "string" or not self.options.categories[category] then
        category = "Other"
    end
    return self.options.categories[category] == true
end

function WorldMarkers:_updateTarget(target)
    if not target:IsDescendantOf(workspace) or isPlayerCharacter(target) or not self:_categoryAllowed(target) then
        self:_clearMarker(target)
        return
    end
    local adornee = getAdornee(target)
    if not adornee then self:_clearMarker(target); return end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local distance = (camera.CFrame.Position - adornee.Position).Magnitude
    if distance > self.options.maxDistance or not self:_isVisible(target, adornee.Position) then
        local old = self.markers[target]
        if old then
            old.gui.Enabled = false
            if old.highlight then old.highlight.Enabled = false end
        end
        return
    end

    local marker = self.markers[target]
    if not marker then
        self:_makeMarker(target, adornee)
        marker = self.markers[target]
    elseif marker.gui.Adornee ~= adornee then
        marker.gui.Adornee = adornee
    end

    local lines = { target.Name }
    if self.options.showDistance then lines[#lines + 1] = string.format("%.0f studs", distance) end
    if self.options.showHealth then
        local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if humanoid then lines[#lines + 1] = string.format("HP %.0f / %.0f", humanoid.Health, humanoid.MaxHealth) end
    end
    marker.text.Text = table.concat(lines, "  •  ")
    marker.gui.Enabled = true
    if marker.highlight then marker.highlight.Enabled = true end
end

function WorldMarkers:Enable()
    if self.enabled then return end
    self.player = self.player or Players.LocalPlayer
    local playerGui = self.player and self.player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then error("PlayerGui is unavailable") end

    self.folder = Instance.new("Folder")
    self.folder.Name = "VDM_VisibleObjectMarkers"
    self.folder.Parent = playerGui
    self.enabled = true
    self.elapsed = 0
    self.heartbeat = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.enabled then return end
        self.elapsed += deltaTime
        if self.elapsed < self.options.updateInterval then return end
        self.elapsed = 0
        local current = {}
        for _, target in ipairs(CollectionService:GetTagged(TAG)) do
            current[target] = true
            self:_updateTarget(target)
        end
        for target in pairs(self.markers) do
            if not current[target] then self:_clearMarker(target) end
        end
    end)
end

function WorldMarkers:Disable()
    self.enabled = false
    if self.heartbeat then self.heartbeat:Disconnect(); self.heartbeat = nil end
    self:_clearAll()
    if self.folder then self.folder:Destroy(); self.folder = nil end
end

function WorldMarkers:Destroy()
    self:Disable()
    self.player = nil
end

return WorldMarkers
