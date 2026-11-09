-- Visible-only object markers for debugging tagged instances in an experience you own.
-- Targets must be explicitly tagged "VDM_DebugTarget" by the experience developer.
-- Player characters are excluded. Occluded targets are hidden; nothing is revealed through walls.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TAG = "VDM_DebugTarget"
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
    local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
    return model ~= nil and Players:GetPlayerFromCharacter(model) ~= nil
end

function WorldMarkers.new(options)
    options = options or {}
    return setmetatable({
        enabled = false,
        options = {
            maxDistance = math.clamp(tonumber(options.maxDistance) or 250, 25, 1000),
            updateInterval = math.clamp(tonumber(options.updateInterval) or 0.2, 0.1, 1),
            showDistance = options.showDistance ~= false,
            showHealth = options.showHealth ~= false,
            showBounds = options.showBounds ~= false,
        },
        player = nil,
        camera = nil,
        folder = nil,
        markers = {},
        heartbeat = nil,
        elapsed = 0,
    }, WorldMarkers)
end

function WorldMarkers:Init(context)
    self.player = context and context.player or Players.LocalPlayer
end

function WorldMarkers:_clearMarker(target)
    local marker = self.markers[target]
    if not marker then return end
    if marker.gui then marker.gui:Destroy() end
    if marker.highlight then marker.highlight:Destroy() end
    self.markers[target] = nil
end

function WorldMarkers:_clearAll()
    for target in pairs(self.markers) do
        self:_clearMarker(target)
    end
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
    text.TextColor3 = Color3.fromRGB(226, 239, 255)
    text.TextSize = 12
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
        highlight.OutlineColor = Color3.fromRGB(76, 155, 255)
        highlight.OutlineTransparency = 0.08
        highlight.Enabled = false
        highlight.Parent = self.folder
    end

    gui.Parent = self.folder
    self.markers[target] = { gui = gui, text = text, highlight = highlight }
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
    return result == nil or result.Instance:IsDescendantOf(target)
end

function WorldMarkers:_updateTarget(target)
    if not target.Parent or isPlayerCharacter(target) then
        self:_clearMarker(target)
        return
    end

    local adornee = getAdornee(target)
    if not adornee then
        self:_clearMarker(target)
        return
    end

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
    if self.options.showDistance then
        lines[#lines + 1] = string.format("%.0f studs", distance)
    end
    if self.options.showHealth then
        local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            lines[#lines + 1] = string.format("HP %.0f / %.0f", humanoid.Health, humanoid.MaxHealth)
        end
    end

    marker.text.Text = table.concat(lines, "  •  ")
    marker.gui.Enabled = true
    if marker.highlight then marker.highlight.Enabled = true end
end

function WorldMarkers:Enable()
    if self.enabled then return end
    self.enabled = true
    self.player = self.player or Players.LocalPlayer

    local playerGui = self.player and self.player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        self.enabled = false
        error("PlayerGui is unavailable")
    end

    self.folder = Instance.new("Folder")
    self.folder.Name = "VDM_VisibleObjectMarkers"
    self.folder.Parent = playerGui

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
    if self.heartbeat then
        self.heartbeat:Disconnect()
        self.heartbeat = nil
    end
    self:_clearAll()
    if self.folder then
        self.folder:Destroy()
        self.folder = nil
    end
end

function WorldMarkers:Destroy()
    self:Disable()
    self.player = nil
end

return WorldMarkers
