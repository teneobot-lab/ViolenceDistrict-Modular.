-- Native Roblox UI renderer. No executor APIs or game-state manipulation.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Renderer = {}
Renderer.__index = Renderer

local GROUPS = {
    { id = "Dashboard", label = "Dashboard", icon = "◆" },
    { id = "Movement", label = "Movement", icon = "↗" },
    { id = "Visual", label = "Visual", icon = "◈" },
    { id = "Diagnostics", label = "Diagnostics", icon = "⌁" },
    { id = "Config", label = "Config", icon = "⚙" },
}

local DESCRIPTIONS = {
    MovementDiagnostics = "Merekam sampel posisi, kecepatan, dan status grounded secara pasif.",
    Crosshair = "Model status crosshair lokal. Renderer crosshair khusus belum disertakan.",
    GraphicsProfile = "Menyimpan preset preferensi grafis lokal tanpa memaksa efek game.",
    RuntimeDiagnostics = "Menampilkan uptime dan snapshot diagnostik runtime.",
}

local function create(className, props, parent)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function stroke(parent, color, transparency)
    create("UIStroke", {
        Color = color or Color3.fromRGB(65, 91, 124),
        Transparency = transparency or 0.55,
        Thickness = 1,
    }, parent)
end

local function label(parent, text, size, color, font)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

function Renderer.new(options)
    return setmetatable({
        Options = options or {},
        ScreenGui = nil,
        Controller = nil,
        Model = nil,
        ActivePage = "Dashboard",
        Connections = {},
        Cards = {},
        Palette = nil,
    }, Renderer)
end

function Renderer:_disconnect()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
end

function Renderer:_palette(theme)
    local function hex(value)
        local raw = tostring(value or "#000000"):gsub("#", "")
        local r = tonumber(raw:sub(1, 2), 16) or 0
        local g = tonumber(raw:sub(3, 4), 16) or 0
        local b = tonumber(raw:sub(5, 6), 16) or 0
        return Color3.fromRGB(r, g, b)
    end
    return {
        background = hex(theme.background),
        surface = hex(theme.surface),
        surfaceAlt = hex(theme.surfaceAlt),
        text = hex(theme.text),
        muted = hex(theme.muted),
        accent = hex(theme.accent),
        danger = hex(theme.danger),
    }
end

function Renderer:_button(parent, text, size, color)
    local button = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = color or self.Palette.surfaceAlt,
        BorderSizePixel = 0,
        Size = size,
        Text = text,
        TextColor3 = self.Palette.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
    }, parent)
    corner(button, 9)
    return button
end

function Renderer:_refresh()
    if not self.ScreenGui or not self.Model then return end
    self.Palette = self:_palette(self.Model.theme)
    local palette = self.Palette
    self.Root.BackgroundColor3 = palette.background
    self.Topbar.BackgroundColor3 = palette.surface
    self.Sidebar.BackgroundColor3 = palette.surface
    self.Content.BackgroundColor3 = palette.background
    self.Title.TextColor3 = palette.text
    self.PageTitle.TextColor3 = palette.text
    self.PageHint.TextColor3 = palette.muted
    for _, item in ipairs(self.NavButtons) do
        local selected = item.id == self.ActivePage
        item.button.BackgroundColor3 = selected and palette.accent or palette.surfaceAlt
        item.button.TextColor3 = selected and Color3.new(1, 1, 1) or palette.muted
    end
    self:_renderPage()
end

function Renderer:_renderPage()
    for _, child in ipairs(self.Content:GetChildren()) do
        if child ~= self.PageTitle and child ~= self.PageHint and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    self.Cards = {}
    local palette = self.Palette
    local group
    for _, candidate in ipairs(self.Model.groups or {}) do
        if candidate.id == self.ActivePage then group = candidate break end
    end

    if self.ActivePage == "Dashboard" then
        local panel = create("Frame", {
            BackgroundColor3 = palette.surface, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 116),
        }, self.Content)
        corner(panel, 14); stroke(panel)
        label(panel, "WELCOME BACK", 11, palette.accent, Enum.Font.GothamBold).Position = UDim2.fromOffset(18, 15)
        local heading = label(panel, "ViolenceDistrict Modular", 21, palette.text, Enum.Font.GothamBold)
        heading.Position = UDim2.fromOffset(18, 37); heading.Size = UDim2.new(1, -36, 0, 30)
        local sub = label(panel, "Modular control center • safe local modules", 12, palette.muted)
        sub.Position = UDim2.fromOffset(18, 72); sub.Size = UDim2.new(1, -36, 0, 24)

        local stats = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 84) }, self.Content)
        local grid = create("UIGridLayout", {
            CellPadding = UDim2.fromOffset(10, 0),
            CellSize = UDim2.new(0.333, -7, 1, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, stats)
        local count = 0
        for _, entry in ipairs(self.Model.groups or {}) do
            count += #(entry.items or {})
        end
        local enabled = 0
        for name in pairs(self.Controller.Loader.Loaded) do
            local instance = self.Controller.Loader.Loaded[name]
            if instance.State == "enabled" then enabled += 1 end
        end
        for index, pair in ipairs({ {"MODULES", tostring(count)}, {"ACTIVE", tostring(enabled)}, {"THEME", self.Model.themeName} }) do
            local tile = create("Frame", { BackgroundColor3 = palette.surface, BorderSizePixel = 0, LayoutOrder = index }, stats)
            corner(tile, 12); stroke(tile)
            local t = label(tile, pair[1], 10, palette.muted, Enum.Font.GothamBold)
            t.Position = UDim2.fromOffset(12, 12); t.Size = UDim2.new(1, -24, 0, 18)
            local v = label(tile, pair[2], 17, palette.text, Enum.Font.GothamBold)
            v.Position = UDim2.fromOffset(12, 34); v.Size = UDim2.new(1, -24, 0, 28)
        end
        local note = create("Frame", { BackgroundColor3 = palette.surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 88) }, self.Content)
        corner(note, 12); stroke(note)
        local n = label(note, "SAFE MODE", 11, palette.accent, Enum.Font.GothamBold)
        n.Position = UDim2.fromOffset(16, 12); n.Size = UDim2.new(1, -32, 0, 18)
        local d = label(note, "Panel ini hanya mengelola modul lokal dan diagnostik pasif. Fitur exploit/cheat multiplayer tidak tersedia.", 12, palette.muted)
        d.Position = UDim2.fromOffset(16, 34); d.Size = UDim2.new(1, -32, 0, 42)
        return
    end

    if self.ActivePage == "Config" then
        local panel = create("Frame", { BackgroundColor3 = palette.surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 112) }, self.Content)
        corner(panel, 12); stroke(panel)
        label(panel, "APPEARANCE", 11, palette.accent, Enum.Font.GothamBold).Position = UDim2.fromOffset(16, 12)
        local desc = label(panel, "Pilih tema tampilan panel.", 12, palette.muted)
        desc.Position = UDim2.fromOffset(16, 34); desc.Size = UDim2.new(1, -32, 0, 20)
        local dark = self:_button(panel, "Dark", UDim2.fromOffset(104, 34), self.Model.themeName == "Dark" and palette.accent or palette.surfaceAlt)
        dark.Position = UDim2.fromOffset(16, 66)
        local light = self:_button(panel, "Light", UDim2.fromOffset(104, 34), self.Model.themeName == "Light" and palette.accent or palette.surfaceAlt)
        light.Position = UDim2.fromOffset(130, 66)
        table.insert(self.Connections, dark.Activated:Connect(function() self.Controller:SetTheme("Dark") end))
        table.insert(self.Connections, light.Activated:Connect(function() self.Controller:SetTheme("Light") end))
        return
    end

    local items = group and group.items or {}
    if #items == 0 then
        local empty = label(self.Content, "Belum ada modul pada bagian ini.", 13, palette.muted)
        empty.Size = UDim2.new(1, 0, 0, 44)
        return
    end
    for _, item in ipairs(items) do
        local instance = self.Controller.Loader.Loaded[item.id]
        local isEnabled = instance ~= nil and instance.State == "enabled"
        local card = create("Frame", {
            BackgroundColor3 = palette.surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 88),
        }, self.Content)
        corner(card, 12); stroke(card)
        local title = label(card, item.label, 14, palette.text, Enum.Font.GothamBold)
        title.Position = UDim2.fromOffset(15, 13); title.Size = UDim2.new(1, -112, 0, 22)
        local detail = label(card, DESCRIPTIONS[item.id] or "Modul lokal.", 11, palette.muted)
        detail.Position = UDim2.fromOffset(15, 39); detail.Size = UDim2.new(1, -112, 0, 36)
        local toggle = self:_button(card, isEnabled and "ON" or "OFF", UDim2.fromOffset(62, 30), isEnabled and palette.accent or palette.surfaceAlt)
        toggle.Position = UDim2.new(1, -77, 0.5, -15)
        self.Cards[item.id] = toggle
        table.insert(self.Connections, toggle.Activated:Connect(function()
            local ok, err = self.Controller:SetFeatureEnabled(item.id, not isEnabled)
            if not ok then
                warn("[VDM UI] " .. tostring(err))
            end
            self:Update(self.Controller:BuildModel())
        end))
    end
end

function Renderer:Mount(model, controller)
    self:Unmount()
    self.Model = model
    self.Controller = controller
    self.Palette = self:_palette(model.theme)

    local player = Players.LocalPlayer
    assert(player, "Roblox LocalPlayer is unavailable")
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = create("ScreenGui", {
        Name = "VDM_ModularUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 30,
    }, playerGui)
    self.ScreenGui = gui

    local root = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(760, 500),
        BackgroundColor3 = self.Palette.background,
        BorderSizePixel = 0,
    }, gui)
    self.Root = root
    corner(root, 16); stroke(root, self.Palette.accent, 0.35)
    create("UISizeConstraint", { MinSize = Vector2.new(320, 360), MaxSize = Vector2.new(900, 650) }, root)

    local scale = create("UIScale", { Scale = 1 }, root)
    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        scale.Scale = math.min(1, (viewport.X - 24) / 760, (viewport.Y - 24) / 500)
    end
    resize()
    if workspace.CurrentCamera then
        table.insert(self.Connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize))
    end

    local topbar = create("Frame", {
        Name = "Topbar", BackgroundColor3 = self.Palette.surface,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 48),
    }, root)
    self.Topbar = topbar
    corner(topbar, 16)
    local title = label(topbar, "VD  /  MODULAR", 13, self.Palette.text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(17, 0); title.Size = UDim2.new(1, -100, 1, 0)
    self.Title = title
    local close = self:_button(topbar, "×", UDim2.fromOffset(32, 30), self.Palette.surfaceAlt)
    close.Position = UDim2.new(1, -42, 0, 9)
    table.insert(self.Connections, close.Activated:Connect(function() gui.Enabled = false end))
    local minimize = self:_button(topbar, "–", UDim2.fromOffset(32, 30), self.Palette.surfaceAlt)
    minimize.Position = UDim2.new(1, -80, 0, 9)
    table.insert(self.Connections, minimize.Activated:Connect(function()
        self.Body.Visible = not self.Body.Visible
        root.Size = self.Body.Visible and UDim2.fromOffset(760, 500) or UDim2.fromOffset(760, 48)
    end))

    local dragging, dragStart, startPosition
    table.insert(self.Connections, topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = root.Position
        end
    end))
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))

    local body = create("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48) }, root)
    self.Body = body
    local sidebar = create("Frame", { Name = "Sidebar", BackgroundColor3 = self.Palette.surface, BorderSizePixel = 0, Size = UDim2.new(0, 174, 1, 0) }, body)
    self.Sidebar = sidebar
    create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
    local navButtons = {}
    self.NavButtons = navButtons
    for index, entry in ipairs(GROUPS) do
        local button = self:_button(sidebar, entry.icon .. "   " .. entry.label, UDim2.new(1, 0, 0, 38), self.Palette.surfaceAlt)
        button.LayoutOrder = index
        button.TextXAlignment = Enum.TextXAlignment.Left
        local pad = create("UIPadding", { PaddingLeft = UDim.new(0, 12) }, button)
        table.insert(navButtons, { id = entry.id, button = button })
        table.insert(self.Connections, button.Activated:Connect(function()
            self.ActivePage = entry.id
            self:_refresh()
        end))
    end

    local content = create("ScrollingFrame", {
        Name = "Content", BackgroundColor3 = self.Palette.background,
        BorderSizePixel = 0, Position = UDim2.new(0, 174, 0, 0),
        Size = UDim2.new(1, -174, 1, 0), ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Palette.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, body)
    self.Content = content
    create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18) }, content)
    create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, content)
    local pageTitle = label(content, "Dashboard", 20, self.Palette.text, Enum.Font.GothamBold)
    pageTitle.Size = UDim2.new(1, 0, 0, 28); pageTitle.LayoutOrder = 0
    self.PageTitle = pageTitle
    local pageHint = label(content, "Overview and module controls", 11, self.Palette.muted)
    pageHint.Size = UDim2.new(1, 0, 0, 20); pageHint.LayoutOrder = 1
    self.PageHint = pageHint

    self:_refresh()
end

function Renderer:Update(model)
    self.Model = model
    if self.ScreenGui then self:_refresh() end
end

function Renderer:Unmount()
    self:_disconnect()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    self.ScreenGui = nil
    self.Controller = nil
    self.Model = nil
end

return Renderer
