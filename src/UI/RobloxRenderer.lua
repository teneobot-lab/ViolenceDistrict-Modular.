-- Native Roblox UI renderer. No executor APIs or game-state manipulation.
local Players = game:GetService("Players")
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
    VisibleObjectESP = "Penanda objek debug yang diberi tag, hanya saat terlihat; pemain dikecualikan.",
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
        PageConnections = {},
        Cards = {},
        Palette = nil,
    }, Renderer)
end

function Renderer:_disconnect()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    for _, connection in ipairs(self.PageConnections) do connection:Disconnect() end
    table.clear(self.PageConnections)
end

function Renderer:_disconnectPage()
    for _, connection in ipairs(self.PageConnections) do connection:Disconnect() end
    table.clear(self.PageConnections)
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
    self.PageTitle.Text = self.ActivePage
    self.PageHint.Text = self.ActivePage == "Dashboard" and "Overview and module controls" or "Manage local modules and preferences"
    for _, item in ipairs(self.NavButtons) do
        local selected = item.id == self.ActivePage
        item.button.BackgroundColor3 = selected and palette.accent or palette.surfaceAlt
        item.button.TextColor3 = selected and Color3.new(1, 1, 1) or palette.muted
    end
    self:_renderPage()
end

function Renderer:_renderPage()
    self:_disconnectPage()
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
        panel.LayoutOrder = 2
        corner(panel, 14); stroke(panel)
        label(panel, "WELCOME BACK", 11, palette.accent, Enum.Font.GothamBold).Position = UDim2.fromOffset(18, 15)
        local heading = label(panel, "ViolenceDistrict Modular", 21, palette.text, Enum.Font.GothamBold)
        heading.Position = UDim2.fromOffset(18, 37); heading.Size = UDim2.new(1, -36, 0, 30)
        local sub = label(panel, "Modular control center • safe local modules", 12, palette.muted)
        sub.Position = UDim2.fromOffset(18, 72); sub.Size = UDim2.new(1, -36, 0, 24)

        local stats = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 84), LayoutOrder = 3 }, self.Content)
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
        local note = create("Frame", { BackgroundColor3 = palette.surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 88), LayoutOrder = 4 }, self.Content)
        corner(note, 12); stroke(note)
        local n = label(note, "SAFE MODE", 11, palette.accent, Enum.Font.GothamBold)
        n.Position = UDim2.fromOffset(16, 12); n.Size = UDim2.new(1, -32, 0, 18)
        local d = label(note, "Panel ini hanya mengelola modul lokal dan diagnostik pasif. Fitur exploit/cheat multiplayer tidak tersedia.", 12, palette.muted)
        d.Position = UDim2.fromOffset(16, 34); d.Size = UDim2.new(1, -32, 0, 42)
        return
    end

    if self.ActivePage == "Config" then
        local panel = create("Frame", { BackgroundColor3 = palette.surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 112), LayoutOrder = 2 }, self.Content)
        corner(panel, 12); stroke(panel)
        label(panel, "APPEARANCE", 11, palette.accent, Enum.Font.GothamBold).Position = UDim2.fromOffset(16, 12)
        local desc = label(panel, "Pilih tema tampilan panel.", 12, palette.muted)
        desc.Position = UDim2.fromOffset(16, 34); desc.Size = UDim2.new(1, -32, 0, 20)
        local dark = self:_button(panel, "Dark", UDim2.fromOffset(104, 34), self.Model.themeName == "Dark" and palette.accent or palette.surfaceAlt)
        dark.Position = UDim2.fromOffset(16, 66)
        local light = self:_button(panel, "Light", UDim2.fromOffset(104, 34), self.Model.themeName == "Light" and palette.accent or palette.surfaceAlt)
        light.Position = UDim2.fromOffset(130, 66)
        table.insert(self.PageConnections, dark.Activated:Connect(function() self.Controller:SetTheme("Dark") end))
        table.insert(self.PageConnections, light.Activated:Connect(function() self.Controller:SetTheme("Light") end))
        return
    end

    local items = group and group.items or {}
    if #items == 0 then
        local empty = label(self.Content, "Belum ada modul pada bagian ini.", 13, palette.muted)
        empty.LayoutOrder = 2
        empty.Size = UDim2.new(1, 0, 0, 44)
        return
    end
    for index, item in ipairs(items) do
        local instance = self.Controller.Loader.Loaded[item.id]
        local isEnabled = instance ~= nil and instance.State == "enabled"
        local card = create("Frame", {
            BackgroundColor3 = palette.surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 88),
            LayoutOrder = index + 1,
        }, self.Content)
        corner(card, 12); stroke(card)
        local title = label(card, item.label, 14, palette.text, Enum.Font.GothamBold)
        title.Position = UDim2.fromOffset(15, 13); title.Size = UDim2.new(1, -112, 0, 22)
        local detail = label(card, DESCRIPTIONS[item.id] or "Modul lokal.", 11, palette.muted)
        detail.Position = UDim2.fromOffset(15, 39); detail.Size = UDim2.new(1, -112, 0, 36)
        local toggle = self:_button(card, isEnabled and "ON" or "OFF", UDim2.fromOffset(62, 30), isEnabled and palette.accent or palette.surfaceAlt)
        toggle.Position = UDim2.new(1, -77, 0.5, -15)
        local moduleId = item.id
        local wasEnabled = isEnabled
        self.Cards[moduleId] = toggle
        table.insert(self.PageConnections, toggle.Activated:Connect(function()
            local ok, err = self.Controller:SetFeatureEnabled(moduleId, not wasEnabled)
            if not ok then
                warn("[VDM UI] " .. tostring(err))
            end
            self:Update(self.Controller:BuildModel())
        end))
    end

    if self.ActivePage == "Visual" and self.Model.visibleObjectESP then
        local options = self.Model.visibleObjectESP
        local panel = create("Frame", {
            BackgroundColor3 = palette.surface, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 296), LayoutOrder = #items + 2,
        }, self.Content)
        corner(panel, 12); stroke(panel)
        local heading = label(panel, "VISIBLE OBJECT ESP SETTINGS", 11, palette.accent, Enum.Font.GothamBold)
        heading.Position = UDim2.fromOffset(15, 10); heading.Size = UDim2.new(1, -30, 0, 20)
        local hint = label(panel, "Hanya tag VDM_DebugTarget • occlusion aktif • karakter pemain dikecualikan", 10, palette.muted)
        hint.Position = UDim2.fromOffset(15, 31); hint.Size = UDim2.new(1, -30, 0, 28)

        local function settingRow(y, titleText, valueText, key, nextValue)
            local rowTitle = label(panel, titleText, 11, palette.text)
            rowTitle.Position = UDim2.fromOffset(15, y); rowTitle.Size = UDim2.new(0.48, -15, 0, 30)
            local button = self:_button(panel, valueText, UDim2.new(0.48, -15, 0, 30), palette.surfaceAlt)
            button.Position = UDim2.new(0.52, 0, 0, y)
            table.insert(self.PageConnections, button.Activated:Connect(function()
                local ok, err = self.Controller:SetModuleOption("VisibleObjectESP", key, nextValue())
                if not ok then warn("[VDM UI] " .. tostring(err)) end
            end))
        end

        local distances = { 100, 250, 400, 600, 1000 }
        local intervals = { 0.1, 0.2, 0.35, 0.5, 1 }
        local sizes = { 10, 12, 14, 16, 18, 20 }
        local colors = { "Blue", "Green", "Amber", "Violet", "White" }
        local function nextIn(list, current)
            for index, value in ipairs(list) do
                if value == current then return list[index % #list + 1] end
            end
            return list[1]
        end
        settingRow(64, "Warna marker", options.markerColor, "markerColor", function() return nextIn(colors, options.markerColor) end)
        settingRow(99, "Ukuran label", tostring(options.labelSize) .. " px", "labelSize", function() return nextIn(sizes, options.labelSize) end)
        settingRow(134, "Jarak maksimum", tostring(options.maxDistance) .. " studs", "maxDistance", function() return nextIn(distances, options.maxDistance) end)
        settingRow(169, "Interval update", string.format("%.2f s", options.updateInterval), "updateInterval", function() return nextIn(intervals, options.updateInterval) end)

        local categoryTitle = label(panel, "FILTER KATEGORI (atribut VDM_DebugCategory)", 10, palette.muted, Enum.Font.GothamBold)
        categoryTitle.Position = UDim2.fromOffset(15, 205); categoryTitle.Size = UDim2.new(1, -30, 0, 18)
        local categories = { "Environment", "Interactable", "Resource", "Other" }
        for index, category in ipairs(categories) do
            local categoryKey = category
            local enabled = options.categories and options.categories[categoryKey] ~= false
            local categoryEnabled = enabled
            local button = self:_button(panel, categoryKey .. (categoryEnabled and "  ✓" or "  ×"), UDim2.new(0.48, -8, 0, 28), categoryEnabled and palette.accent or palette.surfaceAlt)
            local column = (index - 1) % 2
            local row = math.floor((index - 1) / 2)
            button.Position = UDim2.new(column == 0 and 0 or 0.52, column == 0 and 15 or 0, 0, 228 + row * 32)
            table.insert(self.PageConnections, button.Activated:Connect(function()
                local nextCategories = table.clone(options.categories or {})
                nextCategories[categoryKey] = not categoryEnabled
                self.Controller:SetModuleOption("VisibleObjectESP", "categories", nextCategories)
            end))
        end
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
    create("UISizeConstraint", { MinSize = Vector2.new(280, 320), MaxSize = Vector2.new(900, 650) }, root)

    local function resize()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local width = math.min(760, math.max(280, viewport.X - 24))
        local height = math.min(500, math.max(320, viewport.Y - 24))
        local mobile = viewport.X < 520
        root.Size = UDim2.fromOffset(width, height)
        if self.Sidebar then
            local sidebarWidth = mobile and 104 or 174
            self.Sidebar.Size = UDim2.new(0, sidebarWidth, 1, 0)
            self.Content.Position = UDim2.new(0, sidebarWidth, 0, 0)
            self.Content.Size = UDim2.new(1, -sidebarWidth, 1, 0)
            for _, item in ipairs(self.NavButtons or {}) do
                item.button.Text = mobile and item.icon or (item.icon .. "   " .. item.label)
                item.button.TextXAlignment = mobile and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            end
        end
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
        table.insert(navButtons, { id = entry.id, label = entry.label, icon = entry.icon, button = button })
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

    resize()
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
