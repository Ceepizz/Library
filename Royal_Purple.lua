--[[
    RoyalPurple.luau
    Lightweight single-theme UI library for Auto Progress.

    Designed around the legacy API used by the Auto Progress script:
        Library:Window()
        Library:ToggleTransparency()
        Window:Tab()
        Window:SelectTab()
        Tab:Section()
        Tab:Label()
        Tab:Button()
        Tab:Toggle()
        Tab:Dropdown()
        Tab:Textbox()

    Royal_Purple is permanently built in.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Library = {
    Version = "RoyalPurple-1.0.0",
    Theme = "Royal_Purple",
    Themes = {"Royal_Purple"},
    Options = {},
    CreatedWindow = nil,
    Transparency = false,
    Unloaded = false
}

-- Exact Royal_Purple values taken from the supplied Ceepizz/Fluent bundle.
local Theme = {
    Accent = Color3.fromRGB(140, 60, 220),

    AcrylicMain = Color3.fromRGB(14, 10, 22),
    AcrylicBorder = Color3.fromRGB(107, 79, 155),
    AcrylicGradientTop = Color3.fromRGB(58, 27, 91),
    AcrylicGradientBottom = Color3.fromRGB(9, 6, 14),

    TitleBarLine = Color3.fromRGB(69, 49, 105),
    Tab = Color3.fromRGB(118, 92, 162),

    Element = Color3.fromRGB(100, 70, 150),
    ElementBorder = Color3.fromRGB(11, 8, 18),
    InElementBorder = Color3.fromRGB(107, 79, 155),
    ElementTransparency = 0.87,

    ToggleSlider = Color3.fromRGB(100, 70, 150),
    ToggleToggled = Color3.fromRGB(0, 0, 0),

    DropdownFrame = Color3.fromRGB(131, 107, 171),
    DropdownHolder = Color3.fromRGB(13, 9, 20),
    DropdownBorder = Color3.fromRGB(11, 8, 17),
    DropdownOption = Color3.fromRGB(100, 70, 150),

    Input = Color3.fromRGB(123, 97, 165),
    InputFocused = Color3.fromRGB(9, 6, 14),
    InputIndicator = Color3.fromRGB(138, 116, 176),

    Dialog = Color3.fromRGB(13, 9, 20),
    DialogHolder = Color3.fromRGB(11, 8, 18),
    DialogHolderLine = Color3.fromRGB(10, 7, 16),

    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(170, 170, 170),
    Hover = Color3.fromRGB(100, 70, 150),

    White = Color3.fromRGB(255, 255, 255)
}

Library.ThemeData = Theme

local function safeCallback(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    local args = table.pack(...)

    task.spawn(function()
        local ok, err = pcall(function()
            callback(table.unpack(args, 1, args.n))
        end)

        if not ok then
            warn("[RoyalPurple] Callback error:", err)
        end
    end)
end

local function new(className, properties, children)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    return object
end

local function corner(parent, radius)
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent
    })
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Theme.ElementBorder,
        Transparency = transparency == nil and 0.5 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function padding(parent, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent
    })
end

local function tween(object, time, properties)
    TweenService:Create(
        object,
        TweenInfo.new(time or 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    ):Play()
end

local function asset(value)
    if typeof(value) == "number" then
        return "rbxassetid://" .. tostring(value)
    end

    if typeof(value) == "string" then
        if value:match("^rbxasset") then
            return value
        end

        if value:match("^%d+$") then
            return "rbxassetid://" .. value
        end
    end

    return nil
end

local Glyphs = {
    bot = "◆",
    settings = "⚙",
    search = "⌕",
    home = "⌂",
    user = "●",
    link = "↗",
    info = "i",
    key = "◆",
    close = "×",
    minimize = "−"
}

local function glyphFor(icon)
    if typeof(icon) ~= "string" then
        return "•"
    end

    return Glyphs[string.lower(icon)] or "•"
end

local function getGuiParent()
    local ok, parent = pcall(function()
        if gethui then
            return gethui()
        end

        return CoreGui
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        elseif protectgui then
            protectgui(gui)
        end
    end)
end

local function destroyOld()
    local parent = getGuiParent()
    local old = parent:FindFirstChild("RoyalPurpleUI")

    if old then
        old:Destroy()
    end

    local oldCore = CoreGui:FindFirstChild("RoyalPurpleUI")
    if oldCore and oldCore ~= old then
        oldCore:Destroy()
    end
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    local dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPosition = target.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart and startPosition then
            local delta = input.Position - dragStart

            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

local function createText(parent, text, size, color, weight)
    local fontWeight = weight or Enum.FontWeight.Regular

    return new("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color or Theme.Text,
        TextSize = size or 13,
        FontFace = Font.new(
            "rbxasset://fonts/families/GothamSSm.json",
            fontWeight,
            Enum.FontStyle.Normal
        ),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    })
end

local function getConfiguredSize(config)
    if typeof(config.Size) == "UDim2" then
        return config.Size
    end

    if typeof(config.Config) == "table"
        and typeof(config.Config.Size) == "UDim2" then

        return config.Config.Size
    end

    return UDim2.fromOffset(500, 400)
end

local function getConfiguredKey(config)
    if typeof(config.MinimizeKey) == "EnumItem" then
        return config.MinimizeKey
    end

    if typeof(config.Config) == "table"
        and typeof(config.Config.Keybind) == "EnumItem" then

        return config.Config.Keybind
    end

    return Enum.KeyCode.LeftControl
end

local function formatExpiration()
    local expiresAt = nil

    pcall(function()
        local env = getgenv and getgenv() or _G
        expiresAt = env.JD_EXPIRES_AT or shared.JD_EXPIRES_AT
    end)

    if not expiresAt then
        return "--"
    end

    local timestamp = tonumber(expiresAt)
    if not timestamp then
        return tostring(expiresAt)
    end

    local remaining = math.max(timestamp - os.time(), 0)

    if remaining <= 0 then
        return "Expired"
    end

    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end

    return string.format("%dm", minutes)
end

local function isPremium()
    local premium = false

    pcall(function()
        local env = getgenv and getgenv() or _G
        premium = env.JD_IS_PREMIUM == true or shared.JD_IS_PREMIUM == true
    end)

    return premium
end

function Library:SetTheme(_)
    self.Theme = "Royal_Purple"
end

function Library:ToggleTransparency(value)
    self.Transparency = value == true

    local window = self.CreatedWindow
    if not window then
        return
    end

    local transparency = self.Transparency and 0.18 or 0

    tween(window.Root, 0.15, {
        BackgroundTransparency = transparency
    })

    tween(window.Sidebar, 0.15, {
        BackgroundTransparency = self.Transparency and 0.12 or 0
    })

    tween(window.ContentPanel, 0.15, {
        BackgroundTransparency = self.Transparency and 0.12 or 0
    })
end

function Library:Destroy()
    if self.GUI then
        self.GUI:Destroy()
    end

    self.CreatedWindow = nil
    self.Unloaded = true
end

Library.Unload = Library.Destroy

function Library:Notify(config)
    config = config or {}

    if not self.GUI then
        return
    end

    local holder = self.GUI:FindFirstChild("Notifications")
    if not holder then
        holder = new("Frame", {
            Name = "Notifications",
            Parent = self.GUI,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(290, 320),
            BackgroundTransparency = 1
        })

        new("UIListLayout", {
            Parent = holder,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8)
        })
    end

    local card = new("Frame", {
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.DropdownHolder,
        BackgroundTransparency = 0.04
    })

    corner(card, 7)
    stroke(card, Theme.AcrylicBorder, 0.5)
    padding(card, 12, 12, 10, 10)

    local layout = new("UIListLayout", {
        Parent = card,
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local title = createText(
        card,
        config.Title or "Royal Purple",
        13,
        Theme.Text,
        Enum.FontWeight.SemiBold
    )
    title.Size = UDim2.new(1, 0, 0, 18)

    if config.Content and config.Content ~= "" then
        local content = createText(card, config.Content, 12, Theme.SubText)
        content.Size = UDim2.new(1, 0, 0, 16)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.TextWrapped = true
    end

    task.delay(tonumber(config.Duration) or 4, function()
        if card and card.Parent then
            tween(card, 0.18, {BackgroundTransparency = 1})
            task.wait(0.2)
            card:Destroy()
        end
    end)

    return {
        Close = function()
            if card and card.Parent then
                card:Destroy()
            end
        end
    }
end

function Library:Window(config)
    assert(self.CreatedWindow == nil, "RoyalPurple only supports one window at a time.")

    destroyOld()

    config = config or {}
    config.Theme = "Royal_Purple"

    local gui = new("ScreenGui", {
        Name = "RoyalPurpleUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })

    protect(gui)
    gui.Parent = getGuiParent()

    self.GUI = gui
    self.Unloaded = false

    local window = {
        Tabs = {},
        SelectedTab = 0,
        Minimized = false,
        Visible = true,
        Config = config
    }

    self.CreatedWindow = window

    local requestedSize = getConfiguredSize(config)

    local root = new("Frame", {
        Name = "Window",
        Parent = gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = requestedSize,
        BackgroundColor3 = Theme.AcrylicMain,
        BackgroundTransparency = 0,
        ClipsDescendants = true
    })

    window.Root = root

    corner(root, 9)
    stroke(root, Theme.AcrylicBorder, 0.45)

    local gradient = new("UIGradient", {
        Parent = root,
        Color = ColorSequence.new(
            Theme.AcrylicGradientTop,
            Theme.AcrylicGradientBottom
        ),
        Rotation = 125
    })

    local titleBar = new("Frame", {
        Name = "TitleBar",
        Parent = root,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1
    })

    window.TitleBar = titleBar

    local titleIconAsset = asset(config.Icon)

    local titleOffset = 14

    if titleIconAsset then
        local image = new("ImageLabel", {
            Parent = titleBar,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.fromOffset(18, 18),
            Image = titleIconAsset,
            ImageColor3 = Theme.Text
        })

        titleOffset = 38
    end

    local titleLabel = createText(
        titleBar,
        config.Title or "Royal Purple",
        14,
        Theme.Text,
        Enum.FontWeight.SemiBold
    )

    titleLabel.Position = UDim2.fromOffset(titleOffset, 0)
    titleLabel.Size = UDim2.new(1, -100, 1, 0)

    local minimizeButton = new("TextButton", {
        Parent = titleBar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 1,
        Text = "−",
        TextColor3 = Theme.SubText,
        TextSize = 18,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false
    })

    corner(minimizeButton, 6)

    minimizeButton.MouseEnter:Connect(function()
        tween(minimizeButton, 0.12, {
            BackgroundTransparency = 0.82,
            TextColor3 = Theme.Text
        })
    end)

    minimizeButton.MouseLeave:Connect(function()
        tween(minimizeButton, 0.12, {
            BackgroundTransparency = 1,
            TextColor3 = Theme.SubText
        })
    end)

    local titleLine = new("Frame", {
        Parent = root,
        Position = UDim2.fromOffset(0, 38),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.TitleBarLine,
        BorderSizePixel = 0
    })

    local sidebarWidth = 154

    local sidebar = new("Frame", {
        Name = "Sidebar",
        Parent = root,
        Position = UDim2.fromOffset(0, 39),
        Size = UDim2.new(0, sidebarWidth, 1, -39),
        BackgroundColor3 = Theme.DialogHolder,
        BackgroundTransparency = 0,
        BorderSizePixel = 0
    })

    window.Sidebar = sidebar

    local sidebarLine = new("Frame", {
        Parent = sidebar,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme.TitleBarLine,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0
    })

    local searchBox = new("TextBox", {
        Name = "Search",
        Parent = sidebar,
        Position = UDim2.fromOffset(9, 10),
        Size = UDim2.new(1, -18, 0, 30),
        BackgroundColor3 = Theme.InputFocused,
        BackgroundTransparency = 0.05,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.SubText,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false
    })

    corner(searchBox, 6)
    stroke(searchBox, Theme.InElementBorder, 0.58)
    padding(searchBox, 10, 8, 0, 0)

    window.TabSearchBox = searchBox

    local tabHolder = new("ScrollingFrame", {
        Name = "Tabs",
        Parent = sidebar,
        Position = UDim2.fromOffset(7, 48),
        Size = UDim2.new(1, -14, 1, -142),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.AcrylicBorder,
        ScrollBarImageTransparency = 0.5
    })

    window.TabHolder = tabHolder

    new("UIListLayout", {
        Parent = tabHolder,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- Profile footer
    local profile = new("Frame", {
        Parent = sidebar,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 7, 1, -8),
        Size = UDim2.new(1, -14, 0, 82),
        BackgroundColor3 = Theme.AcrylicMain,
        BackgroundTransparency = 0.14
    })

    corner(profile, 7)
    stroke(profile, Theme.AcrylicBorder, 0.62)

    local avatar = new("ImageLabel", {
        Parent = profile,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 0.3,
        Image = "rbxthumb://type=AvatarHeadShot&id="
            .. tostring(LocalPlayer.UserId)
            .. "&w=100&h=100"
    })

    corner(avatar, 16)

    local username = createText(
        profile,
        string.upper(LocalPlayer.Name),
        10,
        Theme.Text,
        Enum.FontWeight.SemiBold
    )
    username.Position = UDim2.fromOffset(47, 6)
    username.Size = UDim2.new(1, -53, 0, 22)
    username.TextTruncate = Enum.TextTruncate.AtEnd

    local typeLabel = createText(
        profile,
        "Type: " .. (isPremium() and "Premium" or "Standard"),
        10,
        Theme.SubText
    )
    typeLabel.Position = UDim2.fromOffset(47, 25)
    typeLabel.Size = UDim2.new(1, -53, 0, 18)

    local expiryLabel = createText(
        profile,
        "Key expires in: " .. formatExpiration(),
        9,
        Theme.SubText
    )
    expiryLabel.Position = UDim2.fromOffset(8, 51)
    expiryLabel.Size = UDim2.new(1, -16, 0, 18)

    window.Profile = profile
    window.ProfileType = typeLabel
    window.ProfileExpiry = expiryLabel

    -- Main content panel
    local contentPanel = new("Frame", {
        Name = "ContentPanel",
        Parent = root,
        Position = UDim2.fromOffset(sidebarWidth + 1, 39),
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, -39),
        BackgroundColor3 = Theme.AcrylicMain,
        BackgroundTransparency = 0
    })

    window.ContentPanel = contentPanel

    local tabDisplay = createText(
        contentPanel,
        "Tab",
        18,
        Theme.Text,
        Enum.FontWeight.SemiBold
    )
    tabDisplay.Position = UDim2.fromOffset(18, 12)
    tabDisplay.Size = UDim2.new(1, -36, 0, 26)

    window.TabDisplay = tabDisplay

    local descLabel = createText(
        contentPanel,
        config.Desc or config.SubTitle or "",
        11,
        Theme.SubText
    )
    descLabel.Position = UDim2.fromOffset(18, 36)
    descLabel.Size = UDim2.new(1, -36, 0, 18)
    descLabel.Visible = descLabel.Text ~= ""

    local containerHolder = new("Frame", {
        Name = "ContainerHolder",
        Parent = contentPanel,
        Position = UDim2.fromOffset(16, descLabel.Visible and 58 or 48),
        Size = UDim2.new(
            1,
            -32,
            1,
            -(descLabel.Visible and 68 or 58)
        ),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })

    window.ContainerHolder = containerHolder

    local reopen = new("TextButton", {
        Name = "Reopen",
        Parent = gui,
        Visible = false,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 16, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.08,
        Text = "R",
        TextColor3 = Theme.White,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    })

    corner(reopen, 22)
    stroke(reopen, Theme.AcrylicBorder, 0.25, 1.2)

    window.ReopenButton = reopen

    local function setVisible(value)
        window.Visible = value == true
        root.Visible = window.Visible
        reopen.Visible = not window.Visible
    end

    function window:Minimize()
        self.Minimized = true
        setVisible(false)
    end

    function window:Restore()
        self.Minimized = false
        setVisible(true)
    end

    function window:Toggle()
        if self.Visible then
            self:Minimize()
        else
            self:Restore()
        end
    end

    minimizeButton.MouseButton1Click:Connect(function()
        window:Minimize()
    end)

    reopen.MouseButton1Click:Connect(function()
        window:Restore()
    end)

    makeDraggable(titleBar, root)

    local minimizeKey = getConfiguredKey(config)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == minimizeKey then
            window:Toggle()
        end
    end)

    local function updateSearch()
        local query = string.lower(searchBox.Text or "")

        for _, tab in ipairs(window.Tabs) do
            local visible = query == ""
                or string.find(string.lower(tab.Name), query, 1, true) ~= nil

            tab.Button.Visible = visible
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(updateSearch)

    local function selectTab(index)
        local tab = window.Tabs[index]
        if not tab then
            return
        end

        window.SelectedTab = index

        for i, other in ipairs(window.Tabs) do
            local selected = i == index

            other.Selected = selected
            other.Container.Visible = selected

            if selected then
                tween(other.Button, 0.14, {
                    BackgroundTransparency = 0.82,
                    BackgroundColor3 = Theme.Tab
                })
                other.TitleLabel.TextColor3 = Theme.Text
                other.IconLabel.TextColor3 = Theme.Accent
            else
                tween(other.Button, 0.14, {
                    BackgroundTransparency = 1,
                    BackgroundColor3 = Theme.Tab
                })
                other.TitleLabel.TextColor3 = Theme.SubText
                other.IconLabel.TextColor3 = Theme.SubText
            end
        end

        tabDisplay.Text = tab.Name
    end

    function window:SelectTab(index)
        selectTab(tonumber(index) or 1)
    end

    local function createRow(tab, config, height)
        config = config or {}

        local row = new("Frame", {
            Parent = tab.Container,
            Size = UDim2.new(1, 0, 0, height or 52),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = Theme.ElementTransparency,
            BorderSizePixel = 0
        })

        corner(row, 6)
        stroke(row, Theme.ElementBorder, 0.48)

        local title = createText(
            row,
            config.Title or "Element",
            13,
            Theme.Text,
            Enum.FontWeight.Medium
        )

        title.Position = UDim2.fromOffset(11, 7)
        title.Size = UDim2.new(1, -118, 0, 18)

        local desc = createText(
            row,
            config.Desc or config.Description or "",
            11,
            Theme.SubText
        )

        desc.Position = UDim2.fromOffset(11, 25)
        desc.Size = UDim2.new(1, -118, 0, 18)
        desc.TextWrapped = true
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.Visible = desc.Text ~= ""

        local object = {
            Frame = row,
            TitleLabel = title,
            DescLabel = desc
        }

        function object:SetTitle(value)
            title.Text = tostring(value or "")
        end

        function object:SetDesc(value)
            desc.Text = tostring(value or "")
            desc.Visible = desc.Text ~= ""
        end

        function object:Destroy()
            row:Destroy()
        end

        return object
    end

    local function installHover(button, normalTransparency, hoverTransparency)
        normalTransparency = normalTransparency or 1
        hoverTransparency = hoverTransparency or 0.88

        button.MouseEnter:Connect(function()
            tween(button, 0.1, {
                BackgroundTransparency = hoverTransparency
            })
        end)

        button.MouseLeave:Connect(function()
            tween(button, 0.1, {
                BackgroundTransparency = normalTransparency
            })
        end)
    end

    local function addSection(tab, config)
        local titleText

        if typeof(config) == "table" then
            titleText = config.Title or config.Name or "Section"
        else
            titleText = config or "Section"
        end

        local holder = new("Frame", {
            Parent = tab.Container,
            Size = UDim2.new(1, 0, 0, 29),
            BackgroundTransparency = 1
        })

        local label = createText(
            holder,
            titleText,
            15,
            Theme.Text,
            Enum.FontWeight.SemiBold
        )
        label.Position = UDim2.fromOffset(2, 4)
        label.Size = UDim2.new(1, -4, 0, 21)

        local section = {
            Frame = holder,
            Container = tab.Container
        }

        function section:SetTitle(value)
            label.Text = tostring(value or "")
        end

        function section:Destroy()
            holder:Destroy()
        end

        -- Allow Section:Button(), Section:Toggle(), etc. without changing
        -- the visual grouping model used by Auto Progress.
        setmetatable(section, {
            __index = function(_, key)
                local fn = tab[key]

                if typeof(fn) == "function" then
                    return function(_, ...)
                        return fn(tab, ...)
                    end
                end
            end
        })

        return section
    end

    local function addLabel(tab, config)
        local object = createRow(tab, config, 48)
        object.Frame.BackgroundTransparency = 0.93
        object.TitleLabel.Size = UDim2.new(1, -20, 0, 18)
        object.DescLabel.Size = UDim2.new(1, -20, 0, 18)

        function object:Set(value)
            if typeof(value) == "table" then
                if value.Title ~= nil then
                    object:SetTitle(value.Title)
                end

                if value.Desc ~= nil or value.Description ~= nil then
                    object:SetDesc(value.Desc or value.Description)
                end
            else
                object:SetTitle(value)
            end
        end

        return object
    end

    local function addButton(tab, config)
        local object = createRow(tab, config, 52)

        local click = new("TextButton", {
            Parent = object.Frame,
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 3
        })

        corner(click, 6)
        installHover(click, 1, 0.92)

        local arrow = createText(click, "›", 21, Theme.SubText)
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -11, 0.5, 0)
        arrow.Size = UDim2.fromOffset(18, 24)
        arrow.TextXAlignment = Enum.TextXAlignment.Center

        click.MouseButton1Click:Connect(function()
            safeCallback(config.Callback)
        end)

        object.Button = click

        function object:Fire()
            safeCallback(config.Callback)
        end

        return object
    end

    local function addToggle(tab, config)
        local object = createRow(tab, config, 52)
        local value = config.Value

        if value == nil then
            value = config.Default
        end

        value = value == true

        local toggle = new("TextButton", {
            Parent = object.Frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(36, 20),
            BackgroundColor3 = Theme.ToggleSlider,
            BackgroundTransparency = 0.25,
            Text = "",
            AutoButtonColor = false
        })

        corner(toggle, 10)
        stroke(toggle, Theme.InElementBorder, 0.5)

        local knob = new("Frame", {
            Parent = toggle,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = Theme.Text,
            BorderSizePixel = 0
        })

        corner(knob, 7)

        local function render(animated)
            local duration = animated and 0.13 or 0

            tween(toggle, duration, {
                BackgroundColor3 = value and Theme.Accent or Theme.ToggleSlider,
                BackgroundTransparency = value and 0.04 or 0.25
            })

            tween(knob, duration, {
                Position = value
                    and UDim2.new(1, -10, 0.5, 0)
                    or UDim2.new(0, 10, 0.5, 0)
            })
        end

        local function setValue(newValue, fireCallback)
            value = newValue == true
            render(true)

            if fireCallback ~= false then
                safeCallback(config.Callback, value)
            end
        end

        toggle.MouseButton1Click:Connect(function()
            setValue(not value, true)
        end)

        render(false)

        object.Toggle = toggle

        function object:SetValue(newValue)
            setValue(newValue, false)
        end

        function object:Set(newValue)
            object:SetValue(newValue)
        end

        function object:GetValue()
            return value
        end

        return object
    end

    local function addDropdown(tab, config)
        local object = createRow(tab, config, 54)

        local values = config.Values or config.List or {}
        local selected = config.Value

        if selected == nil then
            selected = config.Default
        end

        if typeof(selected) == "table" then
            selected = selected[1]
        end

        if selected == nil and #values > 0 then
            selected = values[1]
        end

        local button = new("TextButton", {
            Parent = object.Frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(104, 30),
            BackgroundColor3 = Theme.DropdownFrame,
            BackgroundTransparency = 0.18,
            Text = tostring(selected or "Select"),
            TextColor3 = Theme.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false
        })

        corner(button, 5)
        stroke(button, Theme.DropdownBorder, 0.35)
        padding(button, 7, 20, 0, 0)

        local arrow = createText(button, "⌄", 13, Theme.SubText)
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -5, 0.5, 0)
        arrow.Size = UDim2.fromOffset(14, 20)
        arrow.TextXAlignment = Enum.TextXAlignment.Center

        local popup

        local function closePopup()
            if popup then
                popup:Destroy()
                popup = nil
            end
        end

        local function setValue(newValue, fireCallback)
            selected = newValue
            button.Text = tostring(selected or "Select")

            if fireCallback ~= false then
                safeCallback(config.Callback, selected)
            end
        end

        local function openPopup()
            closePopup()

            local absolute = button.AbsolutePosition
            local size = button.AbsoluteSize
            local maxVisible = math.min(#values, 6)
            local popupHeight = math.max(maxVisible * 30 + 8, 38)

            popup = new("Frame", {
                Parent = gui,
                Position = UDim2.fromOffset(
                    absolute.X,
                    absolute.Y + size.Y + 4
                ),
                Size = UDim2.fromOffset(
                    math.max(size.X, 130),
                    popupHeight
                ),
                BackgroundColor3 = Theme.DropdownHolder,
                BackgroundTransparency = 0.02,
                ZIndex = 100
            })

            corner(popup, 6)
            stroke(popup, Theme.AcrylicBorder, 0.35)

            local scroll = new("ScrollingFrame", {
                Parent = popup,
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.new(1, -8, 1, -8),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Theme.AcrylicBorder,
                ZIndex = 101
            })

            new("UIListLayout", {
                Parent = scroll,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            for _, option in ipairs(values) do
                local optionButton = new("TextButton", {
                    Parent = scroll,
                    Size = UDim2.new(1, -2, 0, 27),
                    BackgroundColor3 = Theme.DropdownOption,
                    BackgroundTransparency = option == selected and 0.78 or 0.94,
                    Text = tostring(option),
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    AutoButtonColor = false,
                    ZIndex = 102
                })

                corner(optionButton, 4)

                optionButton.MouseEnter:Connect(function()
                    tween(optionButton, 0.08, {
                        BackgroundTransparency = 0.82
                    })
                end)

                optionButton.MouseLeave:Connect(function()
                    tween(optionButton, 0.08, {
                        BackgroundTransparency = option == selected and 0.78 or 0.94
                    })
                end)

                optionButton.MouseButton1Click:Connect(function()
                    setValue(option, true)
                    closePopup()
                end)
            end
        end

        button.MouseButton1Click:Connect(openPopup)

        object.Dropdown = button

        function object:SetValue(newValue)
            setValue(newValue, false)
        end

        function object:Set(newValue)
            object:SetValue(newValue)
        end

        function object:GetValue()
            return selected
        end

        function object:SetValues(newValues)
            values = newValues or {}
            closePopup()

            local found = false
            for _, option in ipairs(values) do
                if option == selected then
                    found = true
                    break
                end
            end

            if not found then
                selected = values[1]
                button.Text = tostring(selected or "Select")
            end
        end

        return object
    end

    local function addTextbox(tab, config)
        local object = createRow(tab, config, 54)

        local box = new("TextBox", {
            Parent = object.Frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(132, 30),
            BackgroundColor3 = Theme.DialogInput,
            BackgroundTransparency = 0,
            Text = tostring(config.Value or config.Default or ""),
            PlaceholderText = tostring(config.Placeholder or ""),
            PlaceholderColor3 = Theme.SubText,
            TextColor3 = Theme.Text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = config.ClearTextOnFocus == true
        })

        corner(box, 5)
        stroke(box, Theme.InElementBorder, 0.45)
        padding(box, 8, 8, 0, 0)

        box.Focused:Connect(function()
            tween(box, 0.12, {
                BackgroundColor3 = Theme.InputFocused
            })
        end)

        box.FocusLost:Connect(function(enterPressed)
            tween(box, 0.12, {
                BackgroundColor3 = Theme.DialogInput
            })

            safeCallback(config.Callback, box.Text, enterPressed)
        end)

        object.Textbox = box

        function object:SetValue(value)
            box.Text = tostring(value or "")
        end

        function object:Set(value)
            object:SetValue(value)
        end

        function object:GetValue()
            return box.Text
        end

        return object
    end

    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}

        local index = #self.Tabs + 1
        local tab = {
            Name = tabConfig.Title or ("Tab " .. tostring(index)),
            Icon = tabConfig.Icon,
            Selected = false,
            Index = index
        }

        local tabButton = new("TextButton", {
            Parent = tabHolder,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Tab,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false
        })

        corner(tabButton, 6)

        local iconLabel = createText(
            tabButton,
            glyphFor(tabConfig.Icon),
            13,
            Theme.SubText,
            Enum.FontWeight.SemiBold
        )
        iconLabel.Position = UDim2.fromOffset(9, 0)
        iconLabel.Size = UDim2.fromOffset(18, 34)
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center

        local tabTitle = createText(
            tabButton,
            tab.Name,
            11,
            Theme.SubText,
            Enum.FontWeight.Medium
        )
        tabTitle.Position = UDim2.fromOffset(31, 0)
        tabTitle.Size = UDim2.new(1, -37, 1, 0)

        local container = new("ScrollingFrame", {
            Name = tab.Name,
            Parent = containerHolder,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.AcrylicBorder,
            ScrollBarImageTransparency = 0.3
        })

        local list = new("UIListLayout", {
            Parent = container,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        padding(container, 1, 7, 1, 6)

        tab.Button = tabButton
        tab.IconLabel = iconLabel
        tab.TitleLabel = tabTitle
        tab.Container = container
        tab.ScrollFrame = container

        function tab:Section(sectionConfig)
            return addSection(self, sectionConfig)
        end

        tab.CreateSection = tab.Section
        tab.AddSection = tab.Section

        function tab:Label(elementConfig)
            return addLabel(self, elementConfig)
        end

        function tab:Button(elementConfig)
            return addButton(self, elementConfig)
        end

        function tab:Toggle(elementConfig)
            return addToggle(self, elementConfig)
        end

        function tab:Dropdown(elementConfig)
            return addDropdown(self, elementConfig)
        end

        function tab:Textbox(elementConfig)
            return addTextbox(self, elementConfig)
        end

        -- Common aliases.
        tab.Paragraph = tab.Label
        tab.Input = tab.Textbox

        tabButton.MouseEnter:Connect(function()
            if not tab.Selected then
                tween(tabButton, 0.1, {
                    BackgroundTransparency = 0.9
                })
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if not tab.Selected then
                tween(tabButton, 0.1, {
                    BackgroundTransparency = 1
                })
            end
        end)

        tabButton.MouseButton1Click:Connect(function()
            selectTab(index)
        end)

        self.Tabs[index] = tab

        if #self.Tabs == 1 then
            selectTab(1)
        end

        return tab
    end

    window.AddTab = window.Tab
    window.CreateTab = window.Tab

    function window:SetTitle(value)
        titleLabel.Text = tostring(value or "")
    end

    function window:SetDesc(value)
        descLabel.Text = tostring(value or "")
        descLabel.Visible = descLabel.Text ~= ""
    end

    function window:Destroy()
        Library:Destroy()
    end

    Library:ToggleTransparency(false)

    return window
end

Library.AddWindow = Library.Window
Library.CreateWindow = Library.Window

return Library
