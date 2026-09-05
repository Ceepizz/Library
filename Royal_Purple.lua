--[[
    RoyalPurple.luau
    Royal Purple-only compatibility UI library for Auto Progress.

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
    Version = "RoyalPurple-5K-3.1.0",
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
    HoverChange = 0.06,

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

local IconData = {
    bot = {
        Image = "rbxassetid://124334518624683",
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(192, 832)
    },
    settings = {
        Image = "rbxassetid://83798598825627",
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(384, 128)
    },
    ["settings-2"] = {
        Image = "rbxassetid://83798598825627",
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(320, 128)
    }
}

local function applyIcon(image, icon)
    if typeof(icon) == "string" and IconData[icon] then
        local data = IconData[icon]
        image.Image = data.Image
        image.ImageRectOffset = data.ImageRectOffset
        image.ImageRectSize = data.ImageRectSize
        return true
    end

    local direct = asset(icon)
    if direct then
        image.Image = direct
        image.ImageRectOffset = Vector2.zero
        image.ImageRectSize = Vector2.zero
        return true
    end

    return false
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

Library.Utilities = {
    Icons = IconData,
    Themes = {
        Names = {"Royal_Purple"},
        Royal_Purple = Theme
    }
}

function Library.Utilities:GetIcon(name)
    return IconData[tostring(name or "")]
end

local function destroyOld()
    local parent = getGuiParent()
    local old = parent:FindFirstChild("Progress")

    if old then
        old:Destroy()
    end

    local oldCore = CoreGui:FindFirstChild("Progress")
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


----------------------------------------------------------------
-- Royal Purple 5K compatibility layer
--
-- The original Ceepizz build is a WAX bundle. This file keeps the
-- behavior Auto Progress actually relies on while rebuilding the
-- window, tabs, elements, overlays, mobile controls, dialog system,
-- resize handling, option registry, and account footer in one file.
----------------------------------------------------------------

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local Camera = Workspace.CurrentCamera

local ConnectionBag = {}
local LegacyElementCounter = 0
local OpenOverlays = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(ConnectionBag, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(ConnectionBag) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(ConnectionBag)
end

local function legacyId(prefix)
    LegacyElementCounter = LegacyElementCounter + 1
    return "__ProgressLegacy_" .. tostring(prefix) .. "_" .. tostring(LegacyElementCounter)
end

local function shallowCopy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function normalizeLegacyConfig(config)
    local result = shallowCopy(config)

    if result.Description == nil then
        result.Description = result.Desc
    end

    if result.Default == nil then
        result.Default = result.Value
    end

    if result.Values == nil and result.List ~= nil then
        result.Values = result.List
    end

    return result
end

local function normalizeElementArgs(prefix, idxOrConfig, maybeConfig)
    if maybeConfig ~= nil then
        return tostring(idxOrConfig), normalizeLegacyConfig(maybeConfig)
    end

    return legacyId(prefix), normalizeLegacyConfig(idxOrConfig)
end

local function registerOption(idx, object)
    if idx then
        Library.Options[idx] = object
    end
    return object
end

local function unregisterOption(idx)
    if idx then
        Library.Options[idx] = nil
    end
end

local function roundNumber(value, decimals)
    decimals = tonumber(decimals) or 0
    local power = 10 ^ decimals
    return math.floor(value * power + 0.5) / power
end

local function prettify(value)
    local text = tostring(value or "")
    text = text:gsub("_", " ")
    text = text:gsub("(%l)(%u)", "%1 %2")
    return text
end

Library.Utilities.Round = roundNumber
Library.Utilities.Prettify = prettify

function Library.Utilities:Resize(x, y)
    return x, y
end

function Library.Utilities:GetOS()
    local platform = UserInputService:GetPlatform()

    if platform == Enum.Platform.IOS or platform == Enum.Platform.Android then
        return "Mobile"
    end

    if GuiService:IsTenFootInterface() then
        return "Console"
    end

    return "Windows"
end

local function isMobile()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return true
    end

    local platform = UserInputService:GetPlatform()
    return platform == Enum.Platform.IOS or platform == Enum.Platform.Android
end

local function closeOverlay(frame)
    if not frame then
        return
    end

    for index = #OpenOverlays, 1, -1 do
        if OpenOverlays[index] == frame then
            table.remove(OpenOverlays, index)
        end
    end

    pcall(function()
        frame:Destroy()
    end)
end

local function closeAllOverlays()
    for index = #OpenOverlays, 1, -1 do
        local frame = OpenOverlays[index]
        pcall(function()
            frame:Destroy()
        end)
        OpenOverlays[index] = nil
    end
end

local function trackOverlay(frame)
    closeAllOverlays()
    table.insert(OpenOverlays, frame)
    return frame
end

local function safeSet(object, property, value)
    pcall(function()
        object[property] = value
    end)
end

local GothamRegular = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)

local GothamMedium = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Medium,
    Enum.FontStyle.Normal
)

local GothamSemiBold = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.SemiBold,
    Enum.FontStyle.Normal
)

local GothamBold = Font.new(
    "rbxasset://fonts/families/GothamSSm.json",
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)

local function textLabel(parent, properties)
    properties = properties or {}

    local label = new("TextLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(properties.Text or ""),
        TextColor3 = properties.TextColor3 or Theme.Text,
        TextTransparency = properties.TextTransparency or 0,
        TextSize = properties.TextSize or 13,
        FontFace = properties.FontFace or GothamRegular,
        RichText = properties.RichText == true,
        TextWrapped = properties.TextWrapped == true,
        TextTruncate = properties.TextTruncate or Enum.TextTruncate.None,
        TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = properties.TextYAlignment or Enum.TextYAlignment.Center,
        Size = properties.Size or UDim2.new(1, 0, 0, 14),
        Position = properties.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = properties.AnchorPoint or Vector2.zero,
        AutomaticSize = properties.AutomaticSize or Enum.AutomaticSize.None,
        ZIndex = properties.ZIndex or 1,
        Visible = properties.Visible == nil and true or properties.Visible
    })

    return label
end

local function imageLabel(parent, properties)
    properties = properties or {}

    return new("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = properties.Image or "",
        ImageColor3 = properties.ImageColor3 or Theme.Text,
        ImageTransparency = properties.ImageTransparency or 0,
        ImageRectOffset = properties.ImageRectOffset or Vector2.zero,
        ImageRectSize = properties.ImageRectSize or Vector2.zero,
        ScaleType = properties.ScaleType or Enum.ScaleType.Stretch,
        Size = properties.Size or UDim2.fromOffset(16, 16),
        Position = properties.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = properties.AnchorPoint or Vector2.zero,
        ZIndex = properties.ZIndex or 1,
        Visible = properties.Visible == nil and true or properties.Visible
    })
end

local function applyNamedOrDirectIcon(target, icon)
    if typeof(icon) == "string" then
        local named = IconData[icon]
        if named then
            target.Image = named.Image
            target.ImageRectOffset = named.ImageRectOffset or Vector2.zero
            target.ImageRectSize = named.ImageRectSize or Vector2.zero
            return true
        end
    end

    local direct = asset(icon)
    if direct then
        target.Image = direct
        target.ImageRectOffset = Vector2.zero
        target.ImageRectSize = Vector2.zero
        return true
    end

    return false
end

local function makeSignal()
    local signal = {
        listeners = {}
    }

    function signal:Connect(callback)
        local listener = {
            callback = callback,
            connected = true
        }

        table.insert(self.listeners, listener)

        return {
            Disconnect = function()
                listener.connected = false
            end
        }
    end

    function signal:Fire(...)
        local args = table.pack(...)

        for _, listener in ipairs(self.listeners) do
            if listener.connected and typeof(listener.callback) == "function" then
                task.spawn(function()
                    listener.callback(table.unpack(args, 1, args.n))
                end)
            end
        end
    end

    function signal:Destroy()
        table.clear(self.listeners)
    end

    return signal
end

local function addSoftShadow(parent, zIndex)
    local shadow = imageLabel(parent, {
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.35,
        ScaleType = Enum.ScaleType.Slice,
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.fromOffset(-15, -15),
        ZIndex = zIndex or 0
    })

    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    return shadow
end

local function viewportSize()
    Camera = Workspace.CurrentCamera or Camera

    if Camera then
        return Camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function clampWindowPosition(root)
    local view = viewportSize()
    local absolute = root.AbsoluteSize
    local pos = root.AbsolutePosition

    local minX = -absolute.X + 70
    local maxX = view.X - 70
    local minY = 0
    local maxY = view.Y - 40

    local x = math.clamp(pos.X, minX, maxX)
    local y = math.clamp(pos.Y, minY, maxY)

    root.Position = UDim2.fromOffset(x, y)
end

----------------------------------------------------------------
-- Override Destroy so every new compatibility connection/overlay
-- is cleaned up as well.
----------------------------------------------------------------

function Library:Destroy()
    if self.Unloaded then
        return
    end

    self.Unloaded = true

    closeAllOverlays()
    disconnectAll()

    for key in pairs(self.Options) do
        self.Options[key] = nil
    end

    if self.GUI then
        pcall(function()
            self.GUI:Destroy()
        end)
    end

    self.GUI = nil
    self.CreatedWindow = nil
end

Library.Unload = Library.Destroy

----------------------------------------------------------------
-- Window implementation
----------------------------------------------------------------

function Library:Window(config)
    assert(
        self.CreatedWindow == nil,
        "Royal_Purple: You cannot create more than one window."
    )

    destroyOld()

    config = normalizeLegacyConfig(config or {})
    config.Theme = "Royal_Purple"

    if config.SubTitle == nil and config.Desc ~= nil then
        config.SubTitle = config.Desc
    end

    if typeof(config.Config) == "table" then
        if config.Size == nil and typeof(config.Config.Size) == "UDim2" then
            config.Size = config.Config.Size
        end

        if config.MinimizeKey == nil and config.Config.Keybind ~= nil then
            config.MinimizeKey = config.Config.Keybind
        end
    end

    if typeof(config.Size) ~= "UDim2" then
        config.Size = UDim2.fromOffset(500, 400)
    end

    if typeof(config.MinSize) ~= "Vector2" then
        config.MinSize = Vector2.new(470, 380)
    end

    if typeof(config.TabWidth) ~= "number" then
        config.TabWidth = 160
    end

    if typeof(config.MinimizeKey) ~= "EnumItem" then
        config.MinimizeKey = Enum.KeyCode.LeftControl
    end

    if config.Title == nil then
        config.Title = "Auto Progress"
    end

    if config.SubTitle == nil then
        config.SubTitle = ""
    end

    local mobile = isMobile()
    local view = viewportSize()

    local gui = new("ScreenGui", {
        Name = "Progress",
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999999
    })

    protect(gui)
    gui.Parent = getGuiParent()

    self.GUI = gui
    self.Unloaded = false
    self.MinimizeKey = config.MinimizeKey

    local shadowRoot = new("Frame", {
        Name = "Shadow",
        Parent = gui,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1
    })

    local window = {
        Tabs = {},
        Containers = {},
        TabCount = 0,
        SelectedTab = 0,
        Minimized = false,
        Maximized = false,
        Alignment = "Left",
        TabWidth = config.TabWidth,
        Config = config,
        Shadow = shadowRoot,
        OnMinimized = makeSignal(),
        PostMinimized = makeSignal(),
        OnMaximized = makeSignal(),
        PostMaximized = makeSignal()
    }

    self.CreatedWindow = window

    local root = new("Frame", {
        Name = "Window",
        Parent = shadowRoot,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = config.Size,
        BackgroundColor3 = Theme.AcrylicMain,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        ZIndex = 5
    })

    window.Root = root

    corner(root, 8)
    stroke(root, Theme.AcrylicBorder, 0.46, 1)
    addSoftShadow(root, 4)

    local acrylicGradient = new("UIGradient", {
        Parent = root,
        Color = ColorSequence.new(
            Theme.AcrylicGradientTop,
            Theme.AcrylicGradientBottom
        ),
        Rotation = 118
    })

    window.AcrylicGradient = acrylicGradient

    local uiScale = new("UIScale", {
        Name = "MobileScale",
        Parent = root,
        Scale = 1
    })

    window.UIScale = uiScale

    local function updateMobileScale()
        if not mobile then
            uiScale.Scale = 1
            return
        end

        local currentView = viewportSize()
        local targetWidth = math.max(1, config.Size.X.Offset)
        local targetHeight = math.max(1, config.Size.Y.Offset)

        local scaleX = (currentView.X - 18) / targetWidth
        local scaleY = (currentView.Y - 18) / targetHeight
        uiScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.62, 1)
    end

    updateMobileScale()

    connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        Camera = Workspace.CurrentCamera
        updateMobileScale()
    end)

    if Camera then
        connect(Camera:GetPropertyChangedSignal("ViewportSize"), function()
            updateMobileScale()
        end)
    end

    ----------------------------------------------------------------
    -- Title bar
    ----------------------------------------------------------------

    local titleBar = new("Frame", {
        Name = "TitleBar",
        Parent = root,
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 7
    })

    window.TitleBar = titleBar

    local titleIcon = imageLabel(titleBar, {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(14, 12),
        ImageColor3 = Theme.Text,
        ZIndex = 8,
        Visible = false
    })

    if applyNamedOrDirectIcon(titleIcon, config.Icon) then
        titleIcon.Visible = true
    end

    local titleLeft = titleIcon.Visible and 40 or 16

    local titleLabel = textLabel(titleBar, {
        Text = config.Title,
        TextSize = 14,
        TextColor3 = Theme.Text,
        FontFace = GothamSemiBold,
        Position = UDim2.fromOffset(titleLeft, 0),
        Size = UDim2.new(1, -titleLeft - 130, 1, 0),
        ZIndex = 8
    })

    titleLabel.Name = "Title"

    local subtitleLabel = textLabel(titleBar, {
        Text = config.SubTitle,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        FontFace = GothamRegular,
        Position = UDim2.fromOffset(titleLeft, 20),
        Size = UDim2.new(1, -titleLeft - 130, 0, 16),
        ZIndex = 8,
        Visible = config.SubTitle ~= ""
    })

    subtitleLabel.Name = "SubTitle"

    if subtitleLabel.Visible then
        titleLabel.Position = UDim2.fromOffset(titleLeft, -4)
        titleLabel.Size = UDim2.new(1, -titleLeft - 130, 0, 26)
    end

    local titleLine = new("Frame", {
        Name = "TitleBarLine",
        Parent = root,
        Position = UDim2.fromOffset(0, 41),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.TitleBarLine,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = 6
    })

    window.TitleBarLine = titleLine

    local function barButton(name, imageAsset, rightOffset, callback)
        local button = new("TextButton", {
            Name = name,
            Parent = titleBar,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, rightOffset, 0, 4),
            Size = UDim2.fromOffset(36, 34),
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9
        })

        corner(button, 4)

        local image = imageLabel(button, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            Image = imageAsset,
            ImageColor3 = Theme.SubText,
            ZIndex = 10
        })

        connect(button.MouseEnter, function()
            tween(button, 0.1, {
                BackgroundTransparency = 0.88
            })
            image.ImageColor3 = Theme.Text
        end)

        connect(button.MouseLeave, function()
            tween(button, 0.1, {
                BackgroundTransparency = 1
            })
            image.ImageColor3 = Theme.SubText
        end)

        connect(button.MouseButton1Down, function()
            tween(button, 0.06, {
                BackgroundTransparency = 0.92
            })
        end)

        connect(button.MouseButton1Click, callback)

        return button
    end

    ----------------------------------------------------------------
    -- Left tab frame - original proportions
    ----------------------------------------------------------------

    local titleBarHeight = 42
    local outerPadding = 12
    local leftInset = 14
    local searchHeight = 28

    local tabFrame = new("Frame", {
        Name = "TabFrame",
        Parent = root,
        Position = UDim2.fromOffset(outerPadding, 54),
        Size = UDim2.new(0, window.TabWidth, 1, -145),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7
    })

    window.TabFrame = tabFrame

    local searchBox = new("TextBox", {
        Name = "TabSearchBox",
        Parent = tabFrame,
        Position = UDim2.fromOffset(leftInset, 0),
        Size = UDim2.new(1, -leftInset, 0, searchHeight),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 0.89,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.SubText,
        TextSize = 12,
        FontFace = GothamRegular,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        ZIndex = 8
    })

    corner(searchBox, 6)
    stroke(searchBox, Theme.ElementBorder, 0.5)
    padding(searchBox, 10, 10, 0, 0)

    window.TabSearchBox = searchBox

    local tabHolder = new("ScrollingFrame", {
        Name = "TabHolder",
        Parent = tabFrame,
        Position = UDim2.fromOffset(leftInset, searchHeight + 4),
        Size = UDim2.new(1, -leftInset, 1, -(searchHeight + 4)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarImageTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 8
    })

    window.TabHolder = tabHolder

    local tabList = new("UIListLayout", {
        Parent = tabHolder,
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local noResults = textLabel(tabHolder, {
        Text = "No results found",
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextTransparency = 0.4,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 0, 28),
        Visible = false,
        ZIndex = 9
    })

    noResults.Name = "NoResultsLabel"
    noResults.LayoutOrder = 999999
    window.NoResultsLabel = noResults

    local selector = new("Frame", {
        Name = "Selector",
        Parent = tabFrame,
        Size = UDim2.fromOffset(3, 14),
        Position = UDim2.fromOffset(0, searchHeight + 14),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10
    })

    corner(selector, 2)
    window.Selector = selector

    ----------------------------------------------------------------
    -- Main tab title and container - exact left layout offsets
    ----------------------------------------------------------------

    local tabDisplay = textLabel(root, {
        Text = "Tab",
        TextSize = 28,
        TextColor3 = Theme.Text,
        FontFace = GothamSemiBold,
        Position = UDim2.fromOffset(window.TabWidth + 26, 56),
        Size = UDim2.new(1, -window.TabWidth - 42, 0, 28),
        RichText = true,
        ZIndex = 7
    })

    tabDisplay.Name = "TabDisplay"
    window.TabDisplay = tabDisplay

    local containerCanvas = new("Frame", {
        Name = "ContainerCanvas",
        Parent = root,
        Position = UDim2.fromOffset(window.TabWidth + 26, 90),
        Size = UDim2.new(1, -window.TabWidth - 32, 1, -102),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7
    })

    window.ContainerCanvas = containerCanvas

    local containerHolder = new("Frame", {
        Name = "ContainerHolder",
        Parent = containerCanvas,
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7
    })

    window.ContainerHolder = containerHolder

    ----------------------------------------------------------------
    -- Account footer copied from the original visual structure
    ----------------------------------------------------------------

    local accountInfo = new("Frame", {
        Name = "AccountInfo",
        Parent = root,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -11),
        Size = UDim2.new(0, 150, 0, 66),
        ZIndex = 8
    })

    local avatarFrame = new("Frame", {
        Name = "AvatarFrame",
        Parent = accountInfo,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(40, 40),
        ZIndex = 9
    })

    corner(avatarFrame, 20)

    local avatarImage = imageLabel(avatarFrame, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48",
        ZIndex = 10
    })

    avatarImage.Name = "AvatarImage"
    corner(avatarImage, 20)

    local infoFrame = new("Frame", {
        Name = "Info",
        Parent = accountInfo,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 48, 0.5, 0),
        Size = UDim2.new(1, -52, 1, 0),
        ZIndex = 9
    })

    local usernameLabel = textLabel(infoFrame, {
        Text = LocalPlayer and LocalPlayer.Name or "Player",
        TextSize = 14,
        TextColor3 = Theme.White,
        FontFace = GothamBold,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 18),
        TextWrapped = true,
        ZIndex = 10
    })

    usernameLabel.Name = "Username"
    usernameLabel.TextScaled = true

    local typeLabel = textLabel(infoFrame, {
        Text = "Type: " .. (isPremium() and "Premium" or "Standard"),
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(1, 0, 0, 12),
        TextWrapped = true,
        ZIndex = 10
    })

    typeLabel.Name = "Type"

    local expiryLabel = textLabel(infoFrame, {
        Text = "Key expires in: --",
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Position = UDim2.fromOffset(0, 33),
        Size = UDim2.new(1, 0, 0, 30),
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 10
    })

    expiryLabel.Name = "Expiry"

    window.AccountInfo = accountInfo
    window.AvatarImage = avatarImage
    window.UsernameLabel = usernameLabel
    window.TypeLabel = typeLabel
    window.ExpiryLabel = expiryLabel

    task.spawn(function()
        while accountInfo.Parent and not Library.Unloaded do
            typeLabel.Text = "Type: " .. (isPremium() and "Premium" or "Standard")
            expiryLabel.Text = "Key expires in: " .. formatExpiration()
            task.wait(1)
        end
    end)

    ----------------------------------------------------------------
    -- Floating reopen button. Keep the exact name because existing
    -- Auto Progress/Aether integration code may search for it.
    ----------------------------------------------------------------

    local closeUIShadow = new("TextButton", {
        Name = "CloseUIShadow",
        Parent = gui,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 18, 0.5, 0),
        Size = UDim2.fromOffset(44, 44),
        BackgroundColor3 = Theme.AcrylicMain,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        Active = true,
        ZIndex = 100
    })

    corner(closeUIShadow, 22)
    stroke(closeUIShadow, Theme.AcrylicBorder, 0.25, 1.2)
    addSoftShadow(closeUIShadow, 99)

    local reopenIcon = imageLabel(closeUIShadow, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(22, 22),
        ImageColor3 = Theme.Accent,
        ZIndex = 101
    })

    if not applyNamedOrDirectIcon(reopenIcon, config.Icon) then
        applyNamedOrDirectIcon(reopenIcon, "bot")
    end

    window.CloseUIShadow = closeUIShadow

    ----------------------------------------------------------------
    -- Window state and controls
    ----------------------------------------------------------------

    local normalSize = root.Size
    local normalPosition = root.Position

    function window:Minimize()
        if self.Minimized then
            return
        end

        self.OnMinimized:Fire()
        self.Minimized = true
        shadowRoot.Visible = false
        closeUIShadow.Visible = true
        self.PostMinimized:Fire()
    end

    function window:Restore()
        self.Minimized = false
        shadowRoot.Visible = true
        closeUIShadow.Visible = false
    end

    function window:Toggle()
        if shadowRoot.Visible then
            self:Minimize()
        else
            self:Restore()
        end
    end

    function window:Maximize(value)
        if value == nil then
            value = not self.Maximized
        end

        value = value == true

        if value == self.Maximized then
            return
        end

        self.OnMaximized:Fire(value)

        if value then
            normalSize = root.Size
            normalPosition = root.Position

            local currentView = viewportSize()
            root.AnchorPoint = Vector2.new(0, 0)
            root.Position = UDim2.fromOffset(8, 8)
            root.Size = UDim2.fromOffset(
                math.max(config.MinSize.X, currentView.X - 16),
                math.max(config.MinSize.Y, currentView.Y - 16)
            )
        else
            root.AnchorPoint = Vector2.new(0.5, 0.5)
            root.Position = normalPosition
            root.Size = normalSize
        end

        self.Maximized = value
        self.PostMaximized:Fire(value)
    end

    connect(closeUIShadow.MouseButton1Click, function()
        window:Restore()
    end)

    local minButton = barButton(
        "MinButton",
        "rbxassetid://9886659276",
        -76,
        function()
            window:Minimize()
        end
    )

    local maxButton = barButton(
        "MaxButton",
        "rbxassetid://9886659406",
        -40,
        function()
            window:Maximize()
        end
    )

    local closeButton = barButton(
        "CloseButton",
        "rbxassetid://9886659671",
        -4,
        function()
            Library:Destroy()
        end
    )

    window.MinButton = minButton
    window.MaxButton = maxButton
    window.CloseButton = closeButton

    makeDraggable(titleBar, root)

    connect(UserInputService.InputBegan, function(input, processed)
        if processed then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if input.KeyCode == config.MinimizeKey then
            window:Toggle()
        end
    end)

    ----------------------------------------------------------------
    -- Resize support
    ----------------------------------------------------------------

    local resizeHandle = new("Frame", {
        Name = "ResizeStartFrame",
        Parent = root,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 30
    })

    window.ResizeStartFrame = resizeHandle

    local resizing = false
    local resizeStart = nil
    local resizeBaseSize = nil

    connect(resizeHandle.InputBegan, function(input)
        if config.Resize == false then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            resizing = true
            resizeStart = input.Position
            resizeBaseSize = root.AbsoluteSize
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not resizing or not resizeStart or not resizeBaseSize then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then

            return
        end

        local delta = input.Position - resizeStart
        local currentView = viewportSize()

        local width = math.clamp(
            resizeBaseSize.X + delta.X,
            config.MinSize.X,
            math.max(config.MinSize.X, currentView.X - 16)
        )

        local height = math.clamp(
            resizeBaseSize.Y + delta.Y,
            config.MinSize.Y,
            math.max(config.MinSize.Y, currentView.Y - 16)
        )

        root.Size = UDim2.fromOffset(width, height)
        window.Size = root.Size
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            resizing = false
            resizeStart = nil
            resizeBaseSize = nil
        end
    end)

    ----------------------------------------------------------------
    -- Tab selection helpers
    ----------------------------------------------------------------

    local function currentVisibleTabOffset(index)
        local offset = 0

        for tabIndex, tab in ipairs(window.Tabs) do
            if tabIndex == index then
                break
            end

            if tab.Button.Visible then
                offset = offset + 38
            end
        end

        return offset
    end

    local function updateSelector(index, instant)
        local tab = window.Tabs[index]
        if not tab or not tab.Button.Visible then
            selector.Visible = false
            return
        end

        selector.Visible = true

        local offset = currentVisibleTabOffset(index)
        local target = UDim2.fromOffset(
            0,
            searchHeight + 4 + offset + 17
        )

        if instant then
            selector.Position = target
        else
            tween(selector, 0.15, {
                Position = target
            })
        end
    end

    local function selectTab(index, instant)
        index = tonumber(index)
        local selected = index and window.Tabs[index]

        if not selected then
            return false
        end

        window.SelectedTab = index

        for tabIndex, tab in ipairs(window.Tabs) do
            local active = tabIndex == index
            tab.Selected = active
            tab.Container.Visible = active

            if active then
                if instant then
                    tab.Button.BackgroundTransparency = 0.89
                else
                    tween(tab.Button, 0.12, {
                        BackgroundTransparency = 0.89
                    })
                end

                tab.TitleLabel.TextColor3 = Theme.Text
                tab.IconLabel.ImageColor3 = Theme.Text
            else
                if instant then
                    tab.Button.BackgroundTransparency = 1
                else
                    tween(tab.Button, 0.12, {
                        BackgroundTransparency = 1
                    })
                end

                tab.TitleLabel.TextColor3 = Theme.SubText
                tab.IconLabel.ImageColor3 = Theme.SubText
            end
        end

        tabDisplay.Text = selected.Name
        updateSelector(index, instant)

        return true
    end

    function window:SelectTab(index)
        local ok, result = pcall(function()
            return selectTab(index, false)
        end)

        if not ok then
            warn("[RoyalPurple] SelectTab error:", result)

            local fallback = tonumber(index)
            local selected = fallback and self.Tabs[fallback]

            if selected then
                self.SelectedTab = fallback

                for tabIndex, tab in ipairs(self.Tabs) do
                    local active = tabIndex == fallback
                    tab.Selected = active
                    tab.Container.Visible = active
                    tab.Button.BackgroundTransparency = active and 0.89 or 1
                    tab.TitleLabel.TextColor3 = active and Theme.Text or Theme.SubText

                    if tab.IconLabel then
                        tab.IconLabel.ImageColor3 = active and Theme.Text or Theme.SubText
                    end
                end

                tabDisplay.Text = selected.Name
                return true
            end

            return false
        end

        return result
    end

    ----------------------------------------------------------------
    -- Tab search
    ----------------------------------------------------------------

    local function textContains(text, query)
        return string.find(
            string.lower(tostring(text or "")),
            query,
            1,
            true
        ) ~= nil
    end

    local function tabMatches(tab, query)
        if query == "" then
            return true
        end

        if textContains(tab.Name, query) then
            return true
        end

        for _, descendant in ipairs(tab.Container:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                if descendant.Name == "ElementTitleLabel"
                    or descendant.Name == "ElementDescLabel"
                    or descendant.Name == "SectionTitleLabel" then

                    if textContains(descendant.Text, query) then
                        return true
                    end
                end
            end
        end

        return false
    end

    local function filterTabs()
        local query = string.lower(searchBox.Text or "")
        local firstVisible = nil

        for index, tab in ipairs(window.Tabs) do
            local visible = tabMatches(tab, query)
            tab.Button.Visible = visible

            if visible and firstVisible == nil then
                firstVisible = index
            end
        end

        noResults.Visible = firstVisible == nil and #window.Tabs > 0

        if firstVisible == nil then
            selector.Visible = false
            return
        end

        local selected = window.Tabs[window.SelectedTab]

        if not selected or not selected.Button.Visible then
            selectTab(firstVisible, true)
        else
            updateSelector(window.SelectedTab, true)
        end
    end

    connect(searchBox:GetPropertyChangedSignal("Text"), filterTabs)

    ----------------------------------------------------------------
    -- Window title/description/alignment compatibility
    ----------------------------------------------------------------

    function window:SetTitle(value)
        titleLabel.Text = tostring(value or "")
    end

    function window:SetDesc(value)
        value = tostring(value or "")
        subtitleLabel.Text = value
        subtitleLabel.Visible = value ~= ""

        if subtitleLabel.Visible then
            titleLabel.Position = UDim2.fromOffset(titleLeft, -4)
            titleLabel.Size = UDim2.new(1, -titleLeft - 130, 0, 26)
        else
            titleLabel.Position = UDim2.fromOffset(titleLeft, 0)
            titleLabel.Size = UDim2.new(1, -titleLeft - 130, 1, 0)
        end
    end

    function window:SetAlignment(alignment)
        local valid = {
            Left = true,
            Right = true,
            Top = true,
            Bottom = true
        }

        if not valid[alignment] then
            return false
        end

        -- Auto Progress uses Left. We keep the setter for API compatibility,
        -- but intentionally retain the proven left layout to avoid reflow bugs.
        self.Alignment = alignment
        return true
    end

    function window:GetAlignment()
        return self.Alignment
    end

    ----------------------------------------------------------------
    -- Dialog system
    ----------------------------------------------------------------

    function window:Dialog(dialogConfig)
        dialogConfig = dialogConfig or {}
        closeAllOverlays()

        local overlay = new("TextButton", {
            Name = "DialogOverlay",
            Parent = root,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 200
        })

        trackOverlay(overlay)

        local dialog = new("Frame", {
            Name = "Dialog",
            Parent = overlay,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = dialogConfig.Size or UDim2.fromOffset(340, 185),
            BackgroundColor3 = Theme.Dialog,
            BackgroundTransparency = 0.01,
            BorderSizePixel = 0,
            ZIndex = 201
        })

        corner(dialog, 8)
        stroke(dialog, Theme.DialogBorder, 0.35)
        addSoftShadow(dialog, 200)

        local dialogTitle = textLabel(dialog, {
            Text = dialogConfig.Title or "Dialog",
            TextSize = 20,
            TextColor3 = Theme.Text,
            FontFace = GothamSemiBold,
            Position = UDim2.fromOffset(20, 14),
            Size = UDim2.new(1, -40, 0, 30),
            ZIndex = 202
        })

        local dialogContent = textLabel(dialog, {
            Text = dialogConfig.Content or "",
            TextSize = 13,
            TextColor3 = Theme.Text,
            FontFace = GothamRegular,
            Position = UDim2.fromOffset(20, 50),
            Size = UDim2.new(1, -40, 1, -112),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 202
        })

        local buttonArea = new("Frame", {
            Name = "ButtonArea",
            Parent = dialog,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = Theme.DialogHolder,
            BorderSizePixel = 0,
            ZIndex = 202
        })

        local separator = new("Frame", {
            Parent = buttonArea,
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme.DialogHolderLine,
            BorderSizePixel = 0,
            ZIndex = 203
        })

        local buttonHolder = new("Frame", {
            Parent = buttonArea,
            Position = UDim2.fromOffset(14, 11),
            Size = UDim2.new(1, -28, 1, -22),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 203
        })

        local buttons = dialogConfig.Buttons

        if typeof(buttons) ~= "table" or #buttons == 0 then
            buttons = {
                {
                    Title = "Okay"
                }
            }
        end

        local buttonLayout = new("UIListLayout", {
            Parent = buttonHolder,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        local dialogObject = {
            Root = dialog,
            Overlay = overlay,
            Closed = makeSignal()
        }

        function dialogObject:Close()
            if not self.Overlay then
                return
            end

            local target = self.Overlay
            self.Overlay = nil
            closeOverlay(target)
            self.Closed:Fire()
        end

        for index, buttonConfig in ipairs(buttons) do
            local button = new("TextButton", {
                Parent = buttonHolder,
                Size = UDim2.new(1 / #buttons, -4, 1, 0),
                BackgroundColor3 = Theme.DialogButton,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Text = tostring(buttonConfig.Title or ("Button " .. index)),
                TextColor3 = Theme.Text,
                TextSize = 13,
                FontFace = GothamRegular,
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 204
            })

            corner(button, 4)
            stroke(button, Theme.DialogButtonBorder, 0.65)

            connect(button.MouseEnter, function()
                tween(button, 0.1, {
                    BackgroundColor3 = Theme.Element
                })
            end)

            connect(button.MouseLeave, function()
                tween(button, 0.1, {
                    BackgroundColor3 = Theme.DialogButton
                })
            end)

            connect(button.MouseButton1Click, function()
                safeCallback(buttonConfig.Callback)
                dialogObject:Close()
            end)
        end

        return dialogObject
    end

    ----------------------------------------------------------------
    -- Element base
    ----------------------------------------------------------------

    local function createElementBase(parent, config, hover)
        config = config or {}

        local element = {
            Type = "Element",
            Disabled = false
        }

        local titleText = tostring(config.Title or "Element")
        local descText = tostring(config.Description or "")

        local frame = new(hover and "TextButton" or "Frame", {
            Name = "Element",
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = Theme.ElementTransparency,
            BorderSizePixel = 0,
            LayoutOrder = config.LayoutOrder or 7,
            ZIndex = 10
        })

        if frame:IsA("TextButton") then
            frame.Text = ""
            frame.AutoButtonColor = false
        end

        corner(frame, 4)

        local border = stroke(
            frame,
            Theme.ElementBorder,
            0.5,
            1
        )

        local labelHolder = new("Frame", {
            Name = "LabelHolder",
            Parent = frame,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -28, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 11
        })

        local labelLayout = new("UIListLayout", {
            Parent = labelHolder,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center
        })

        padding(labelHolder, 0, 0, 13, 13)

        local title = textLabel(labelHolder, {
            Text = titleText,
            TextSize = 13,
            TextColor3 = Theme.Text,
            FontFace = GothamMedium,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextXAlignment = config.TitleAlignment or Enum.TextXAlignment.Left,
            ZIndex = 12
        })

        title.Name = "ElementTitleLabel"
        title.LayoutOrder = 1

        local desc = textLabel(labelHolder, {
            Text = descText,
            TextSize = 12,
            TextColor3 = Theme.SubText,
            FontFace = GothamRegular,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            TextXAlignment = config.DescriptionAlignment or Enum.TextXAlignment.Left,
            ZIndex = 12,
            Visible = descText ~= ""
        })

        desc.Name = "ElementDescLabel"
        desc.LayoutOrder = 2

        element.Frame = frame
        element.Border = border
        element.LabelHolder = labelHolder
        element.TitleLabel = title
        element.DescLabel = desc
        element.Instance = element

        function element:SetTitle(value)
            title.Text = tostring(value or "")
        end

        function element:SetDesc(value)
            value = tostring(value or "")
            desc.Text = value
            desc.Visible = value ~= ""
        end

        function element:SetDescription(value)
            self:SetDesc(value)
        end

        function element:SetDisabled(value)
            self.Disabled = value == true

            if frame:IsA("GuiButton") then
                frame.Active = not self.Disabled
                frame.Selectable = not self.Disabled
            end

            title.TextTransparency = self.Disabled and 0.45 or 0
            desc.TextTransparency = self.Disabled and 0.55 or 0

            tween(frame, 0.1, {
                BackgroundTransparency = self.Disabled and 0.95 or Theme.ElementTransparency
            })
        end

        function element:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function element:SetLocked(value)
            self:SetDisabled(value)
        end

        function element:Destroy()
            frame:Destroy()
        end

        if hover and frame:IsA("TextButton") then
            connect(frame.MouseEnter, function()
                if element.Disabled then
                    return
                end

                tween(frame, 0.1, {
                    BackgroundTransparency = Theme.ElementTransparency - Theme.HoverChange
                })
            end)

            connect(frame.MouseLeave, function()
                tween(frame, 0.1, {
                    BackgroundTransparency = element.Disabled and 0.95 or Theme.ElementTransparency
                })
            end)

            connect(frame.MouseButton1Down, function()
                if element.Disabled then
                    return
                end

                tween(frame, 0.06, {
                    BackgroundTransparency = Theme.ElementTransparency + Theme.HoverChange
                })
            end)

            connect(frame.MouseButton1Up, function()
                if element.Disabled then
                    return
                end

                tween(frame, 0.06, {
                    BackgroundTransparency = Theme.ElementTransparency - Theme.HoverChange
                })
            end)
        end

        return element
    end

    ----------------------------------------------------------------
    -- Section
    ----------------------------------------------------------------

    local function createSection(owner, config)
        local titleText

        if typeof(config) == "table" then
            titleText = config.Title or config.Name or "Section"
        else
            titleText = tostring(config or "Section")
        end

        local section = {
            Type = "Section"
        }

        local rootFrame = new("Frame", {
            Name = "Section",
            Parent = owner.Container,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = 7,
            ZIndex = 9
        })

        local sectionTitle = textLabel(rootFrame, {
            Text = titleText,
            TextSize = 18,
            TextColor3 = Theme.Text,
            FontFace = GothamSemiBold,
            Position = UDim2.fromOffset(0, 2),
            Size = UDim2.new(1, -16, 0, 18),
            RichText = true,
            ZIndex = 10
        })

        sectionTitle.Name = "SectionTitleLabel"

        local sectionContainer = new("Frame", {
            Name = "SectionContainer",
            Parent = rootFrame,
            Position = UDim2.fromOffset(0, 24),
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 9
        })

        local sectionLayout = new("UIListLayout", {
            Parent = sectionContainer,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        connect(sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            local contentHeight = sectionLayout.AbsoluteContentSize.Y
            sectionContainer.Size = UDim2.new(1, 0, 0, contentHeight)
            rootFrame.Size = UDim2.new(1, 0, 0, contentHeight + 25)
        end)

        section.Root = rootFrame
        section.Frame = rootFrame
        section.Container = sectionContainer
        section.ScrollFrame = owner.ScrollFrame or owner.Container
        section.TitleLabel = sectionTitle

        function section:SetTitle(value)
            sectionTitle.Text = tostring(value or "")
        end

        function section:Destroy()
            rootFrame:Destroy()
        end

        return section
    end

    ----------------------------------------------------------------
    -- Paragraph / Label
    ----------------------------------------------------------------

    local function createParagraph(owner, idx, config)
        config = config or {}

        local paragraph = {
            Value = config.Content or config.Description or "",
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Paragraph"
        }

        local frame = createElementBase(
            owner.Container,
            config,
            false
        )

        frame.Frame.BackgroundTransparency = 0.92
        frame.Border.Transparency = 0.6

        paragraph.Instance = frame
        paragraph.Frame = frame.Frame
        paragraph.SetTitle = frame.SetTitle
        paragraph.SetDesc = frame.SetDesc

        function paragraph:SetTitle(value)
            frame:SetTitle(tostring(value or ""))
        end

        function paragraph:SetDesc(value)
            self:SetContent(value)
        end

        function paragraph:SetContent(value)
            value = value or ""
            self.Value = value
            frame:SetDesc(value)
            frame.Frame.BackgroundTransparency = 0.92
            frame.Border.Transparency = 0.6

            if typeof(self.Callback) == "function" then
                safeCallback(self.Callback, self.Value)
            end

            if typeof(self.Changed) == "function" then
                safeCallback(self.Changed, self.Value)
            end
        end

        function paragraph:SetValue(value)
            self:SetContent(value)
        end

        function paragraph:Set(value)
            if typeof(value) == "table" then
                if value.Title ~= nil then
                    self:SetTitle(value.Title)
                end

                local descValue = value.Desc
                if descValue == nil then
                    descValue = value.Content
                end

                if descValue ~= nil then
                    self:SetContent(descValue)
                end

                return
            end

            self:SetTitle(value)
        end

        function paragraph:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function paragraph:SetDisabled(value)
            frame:SetDisabled(value)
        end

        function paragraph:SetEnabled(value)
            frame:SetEnabled(value)
        end

        function paragraph:Destroy()
            frame:Destroy()
            unregisterOption(idx)
        end

        frame:SetTitle(config.Title or "Label")
        paragraph:SetContent(paragraph.Value)

        return registerOption(idx, paragraph)
    end

    ----------------------------------------------------------------
    -- Button
    ----------------------------------------------------------------

    local function createButton(owner, config)
        config = config or {}

        local buttonObject = createElementBase(
            owner.Container,
            config,
            true
        )

        buttonObject.Type = "Button"

        buttonObject.LabelHolder.Size = UDim2.new(1, -46, 0, 0)

        local arrow = imageLabel(buttonObject.Frame, {
            Image = "rbxassetid://10709791437",
            ImageColor3 = Theme.Text,
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            ZIndex = 13
        })

        buttonObject.Icon = arrow

        connect(buttonObject.Frame.MouseButton1Click, function()
            if buttonObject.Disabled then
                return
            end

            safeCallback(config.Callback, config.Value)
        end)

        function buttonObject:Fire()
            if self.Disabled then
                return
            end

            safeCallback(config.Callback, config.Value)
        end

        buttonObject.Instance = buttonObject
        return buttonObject
    end

    ----------------------------------------------------------------
    -- Toggle
    ----------------------------------------------------------------

    local function createToggle(owner, idx, config)
        config = config or {}

        local toggleObject = {
            Value = not not (config.Default or false),
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Toggle",
            Disabled = false
        }

        if config.Default == nil and config.Value ~= nil then
            toggleObject.Value = not not config.Value
        end

        local frame = createElementBase(
            owner.Container,
            config,
            true
        )

        frame.TitleLabel.Size = UDim2.new(1, -54, 0, 14)
        frame.DescLabel.Size = UDim2.new(1, -54, 0, 14)
        frame.LabelHolder.Size = UDim2.new(1, -64, 0, 0)

        local toggleCircle = imageLabel(frame.Frame, {
            Image = "rbxassetid://12266946128",
            ImageColor3 = Theme.ToggleSlider,
            ImageTransparency = 0.5,
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -44, 0.5, 0),
            ZIndex = 14
        })

        local toggleSlider = new("Frame", {
            Name = "ToggleSlider",
            Parent = frame.Frame,
            Size = UDim2.fromOffset(36, 18),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 13
        })

        corner(toggleSlider, 9)

        local toggleBorder = stroke(
            toggleSlider,
            Theme.ToggleSlider,
            0.5,
            1
        )

        toggleCircle.Parent = toggleSlider
        toggleCircle.Position = UDim2.new(0, 2, 0.5, 0)

        local function renderToggle(animated)
            local duration = animated and 0.25 or 0

            toggleBorder.Color = toggleObject.Value and Theme.Accent or Theme.ToggleSlider
            toggleCircle.ImageColor3 = toggleObject.Value and Theme.ToggleToggled or Theme.ToggleSlider
            toggleCircle.ImageTransparency = toggleObject.Value and 0 or 0.5

            tween(toggleCircle, duration, {
                Position = UDim2.new(
                    0,
                    toggleObject.Value and 19 or 2,
                    0.5,
                    0
                )
            })

            tween(toggleSlider, duration, {
                BackgroundTransparency = toggleObject.Value and 0 or 1
            })
        end

        function toggleObject:SetValue(value)
            value = not not value
            self.Value = value
            renderToggle(true)

            if typeof(self.Callback) == "function" then
                safeCallback(self.Callback, self.Value)
            end

            if typeof(self.Changed) == "function" then
                safeCallback(self.Changed, self.Value)
            end
        end

        function toggleObject:Set(value)
            self:SetValue(value)
        end

        function toggleObject:GetValue()
            return self.Value
        end

        function toggleObject:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function toggleObject:SetTitle(value)
            frame:SetTitle(value)
        end

        function toggleObject:SetDesc(value)
            frame:SetDesc(value)
        end

        function toggleObject:SetDisabled(value)
            self.Disabled = value == true
            frame:SetDisabled(self.Disabled)
            toggleSlider.BackgroundTransparency = self.Disabled and 0.75 or (self.Value and 0 or 1)
            toggleCircle.ImageTransparency = self.Disabled and 0.65 or (self.Value and 0 or 0.5)
        end

        function toggleObject:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function toggleObject:SetLocked(value)
            self:SetDisabled(value)
        end

        function toggleObject:Destroy()
            frame:Destroy()
            unregisterOption(idx)
        end

        connect(frame.Frame.MouseButton1Click, function()
            if toggleObject.Disabled then
                return
            end

            toggleObject:SetValue(not toggleObject.Value)
        end)

        toggleObject.Instance = frame
        toggleObject.Frame = frame.Frame
        toggleObject.ToggleSlider = toggleSlider
        toggleObject.ToggleCircle = toggleCircle

        renderToggle(false)

        return registerOption(idx, toggleObject)
    end

    ----------------------------------------------------------------
    -- Dropdown
    ----------------------------------------------------------------

    local function createDropdown(owner, idx, config)
        config = config or {}

        local dropdown = {
            Values = {},
            Value = config.Default,
            Multi = config.Multi == true,
            AllowNull = config.AllowNull == true,
            Searchable = config.Searchable == nil and true or config.Searchable == true,
            SearchPlaceholder = config.SearchPlaceholder or "Search...",
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Dropdown",
            Opened = false,
            Disabled = false
        }

        if dropdown.Value == nil then
            dropdown.Value = config.Value
        end

        for _, value in ipairs(config.Values or {}) do
            table.insert(dropdown.Values, value)
        end

        if dropdown.Multi then
            if typeof(dropdown.Value) ~= "table" then
                dropdown.Value = {}
            end
        elseif dropdown.Value == nil and #dropdown.Values > 0 then
            dropdown.Value = dropdown.Values[1]
        end

        local frame = createElementBase(
            owner.Container,
            config,
            false
        )

        frame.DescLabel.Size = UDim2.new(1, -170, 0, 14)
        frame.LabelHolder.Size = UDim2.new(1, -190, 0, 0)

        local inner = new("TextButton", {
            Name = "DropdownInner",
            Parent = frame.Frame,
            Size = UDim2.fromOffset(160, 30),
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Theme.DropdownFrame,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 14
        })

        corner(inner, 5)
        stroke(inner, Theme.InElementBorder, 0.5)

        local display = textLabel(inner, {
            Text = "Value",
            TextSize = 13,
            TextColor3 = Theme.Text,
            FontFace = GothamRegular,
            Position = UDim2.new(0, 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -30, 0, 14),
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 15
        })

        local icon = imageLabel(inner, {
            Image = "rbxassetid://10709790948",
            ImageColor3 = Theme.SubText,
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            ZIndex = 15
        })

        local popup = nil
        local popupSearch = nil
        local popupScroll = nil
        local popupList = nil
        local popupNoResults = nil

        local function displayValue(value)
            if typeof(config.Displayer) == "function" then
                local ok, result = pcall(config.Displayer, value)
                if ok then
                    return tostring(result)
                end
            end

            if typeof(value) == "number" then
                return tostring(value)
            end

            return prettify(value)
        end

        function dropdown:GetActiveValues()
            if self.Multi then
                local count = 0
                for _, selected in pairs(self.Value) do
                    if selected then
                        count = count + 1
                    end
                end
                return count
            end

            return self.Value == nil and 0 or 1
        end

        function dropdown:Display()
            if self.Multi then
                local chosen = {}

                for _, value in ipairs(self.Values) do
                    if self.Value[value] then
                        table.insert(chosen, displayValue(value))
                    end
                end

                if #chosen == 0 then
                    display.Text = "None"
                else
                    display.Text = table.concat(chosen, ", ")
                end
            else
                if self.Value == nil then
                    display.Text = "None"
                else
                    display.Text = displayValue(self.Value)
                end
            end
        end

        local function isSelected(value)
            if dropdown.Multi then
                return dropdown.Value[value] == true
            end

            return dropdown.Value == value
        end

        local function destroyPopup()
            dropdown.Opened = false
            icon.Rotation = 0

            if popup then
                local target = popup
                popup = nil
                popupSearch = nil
                popupScroll = nil
                popupList = nil
                popupNoResults = nil
                closeOverlay(target)
            end
        end

        function dropdown:Close()
            destroyPopup()
        end

        local function popupDimensions()
            local count = #dropdown.Values
            local listRows = math.min(math.max(count, 1), 7)
            local searchSpace = dropdown.Searchable and 42 or 8
            local height = searchSpace + listRows * 35 + 5
            return 185, math.clamp(height, 75, 300)
        end

        local function popupPosition(width, height)
            local absolute = inner.AbsolutePosition
            local size = inner.AbsoluteSize
            local viewNow = viewportSize()

            local x = absolute.X + size.X - width
            local y = absolute.Y + size.Y + 5

            if y + height > viewNow.Y - 6 then
                y = absolute.Y - height - 5
            end

            if x + width > viewNow.X - 6 then
                x = viewNow.X - width - 6
            end

            if x < 6 then
                x = 6
            end

            if y < 6 then
                y = 6
            end

            return x, y
        end

        local function buildOptions(filterText)
            if not popupScroll or not popupScroll.Parent then
                return
            end

            for _, child in ipairs(popupScroll:GetChildren()) do
                if child:IsA("GuiButton") then
                    child:Destroy()
                end
            end

            filterText = string.lower(tostring(filterText or ""))
            local shown = 0

            for order, value in ipairs(dropdown.Values) do
                local shownText = displayValue(value)
                local matches = filterText == ""
                    or string.find(
                        string.lower(shownText),
                        filterText,
                        1,
                        true
                    ) ~= nil

                if matches then
                    shown = shown + 1
                    local selected = isSelected(value)

                    local option = new("TextButton", {
                        Name = "DropdownOption",
                        Parent = popupScroll,
                        Size = UDim2.new(1, -5, 0, 32),
                        BackgroundColor3 = Theme.DropdownOption,
                        BackgroundTransparency = selected and 0.89 or 1,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        LayoutOrder = order,
                        ZIndex = 304
                    })

                    corner(option, 6)

                    local optionLabel = textLabel(option, {
                        Text = shownText,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        FontFace = GothamRegular,
                        Position = UDim2.fromOffset(12, 0),
                        Size = UDim2.new(1, -20, 1, 0),
                        ZIndex = 305
                    })

                    local optionSelector = new("Frame", {
                        Parent = option,
                        Size = UDim2.fromOffset(4, selected and 14 or 6),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundColor3 = Theme.Accent,
                        BackgroundTransparency = selected and 0 or 1,
                        BorderSizePixel = 0,
                        ZIndex = 306
                    })

                    corner(optionSelector, 2)

                    connect(option.MouseEnter, function()
                        tween(option, 0.08, {
                            BackgroundTransparency = selected and 0.85 or 0.89
                        })
                    end)

                    connect(option.MouseLeave, function()
                        tween(option, 0.08, {
                            BackgroundTransparency = isSelected(value) and 0.89 or 1
                        })
                    end)

                    connect(option.MouseButton1Down, function()
                        tween(option, 0.05, {
                            BackgroundTransparency = 0.92
                        })
                    end)

                    connect(option.MouseButton1Click, function()
                        if dropdown.Disabled then
                            return
                        end

                        if dropdown.Multi then
                            local currentlySelected = dropdown.Value[value] == true
                            local trySelect = not currentlySelected

                            if currentlySelected
                                and dropdown:GetActiveValues() == 1
                                and not dropdown.AllowNull then

                                return
                            end

                            if trySelect then
                                dropdown.Value[value] = true
                            else
                                dropdown.Value[value] = nil
                            end

                            dropdown:Display()

                            if typeof(dropdown.Callback) == "function" then
                                safeCallback(dropdown.Callback, dropdown.Value)
                            end

                            if typeof(dropdown.Changed) == "function" then
                                safeCallback(dropdown.Changed, dropdown.Value)
                            end

                            buildOptions(popupSearch and popupSearch.Text or "")
                            return
                        end

                        local tryValue = value

                        if dropdown.Value == value and dropdown.AllowNull then
                            tryValue = nil
                        end

                        dropdown:SetValue(tryValue)
                        destroyPopup()
                    end)
                end
            end

            if popupNoResults then
                popupNoResults.Visible = shown == 0
            end
        end

        function dropdown:Open()
            if self.Disabled then
                return
            end

            destroyPopup()

            local width, height = popupDimensions()
            local x, y = popupPosition(width, height)

            popup = new("Frame", {
                Name = "DropdownHolder",
                Parent = gui,
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(width, height),
                BackgroundColor3 = Theme.DropdownHolder,
                BackgroundTransparency = 0.01,
                BorderSizePixel = 0,
                ZIndex = 300
            })

            corner(popup, 7)
            stroke(popup, Theme.DropdownBorder, 0, 1)
            addSoftShadow(popup, 299)
            trackOverlay(popup)

            self.Opened = true
            icon.Rotation = 180

            if self.Searchable then
                popupSearch = new("TextBox", {
                    Name = "Search",
                    Parent = popup,
                    Position = UDim2.fromOffset(8, 7),
                    Size = UDim2.new(1, -16, 0, 28),
                    BackgroundColor3 = Theme.Input,
                    BackgroundTransparency = 0.9,
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    Text = "",
                    PlaceholderText = self.SearchPlaceholder,
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.SubText,
                    TextSize = 12,
                    FontFace = GothamRegular,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 303
                })

                corner(popupSearch, 5)
                stroke(popupSearch, Theme.InElementBorder, 0.5)
                padding(popupSearch, 9, 9, 0, 0)
            end

            popupScroll = new("ScrollingFrame", {
                Name = "DropdownScrollFrame",
                Parent = popup,
                Position = UDim2.fromOffset(5, self.Searchable and 40 or 5),
                Size = UDim2.new(1, -5, 1, self.Searchable and -40 or -10),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                BottomImage = "rbxassetid://6889812791",
                MidImage = "rbxassetid://6889812721",
                TopImage = "rbxassetid://6276641225",
                ScrollBarImageColor3 = Theme.White,
                ScrollBarImageTransparency = 0.95,
                ScrollBarThickness = 4,
                CanvasSize = UDim2.fromScale(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 302
            })

            popupList = new("UIListLayout", {
                Parent = popupScroll,
                Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            popupNoResults = textLabel(popupScroll, {
                Text = "No results found",
                TextSize = 12,
                TextColor3 = Theme.SubText,
                TextTransparency = 0.4,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.new(1, 0, 0, 28),
                Visible = false,
                ZIndex = 304
            })

            popupNoResults.Name = "DropdownNoResultsLabel"
            popupNoResults.LayoutOrder = 999999

            if popupSearch then
                connect(popupSearch:GetPropertyChangedSignal("Text"), function()
                    buildOptions(popupSearch.Text)
                end)
            end

            buildOptions("")

            if popupSearch and config.FocusSearch ~= false then
                task.defer(function()
                    if popupSearch and popupSearch.Parent then
                        popupSearch:CaptureFocus()
                    end
                end)
            end
        end

        connect(inner.MouseEnter, function()
            if dropdown.Disabled then
                return
            end

            tween(inner, 0.1, {
                BackgroundTransparency = 0.84
            })
        end)

        connect(inner.MouseLeave, function()
            tween(inner, 0.1, {
                BackgroundTransparency = 0.9
            })
        end)

        connect(inner.MouseButton1Click, function()
            if dropdown.Disabled then
                return
            end

            if dropdown.Opened then
                dropdown:Close()
            else
                dropdown:Open()
            end
        end)

        function dropdown:SetValues(newValues)
            self.Values = {}

            for _, value in ipairs(newValues or {}) do
                table.insert(self.Values, value)
            end

            if not self.Multi then
                local found = false

                for _, value in ipairs(self.Values) do
                    if value == self.Value then
                        found = true
                        break
                    end
                end

                if not found then
                    self.Value = self.Values[1]
                end
            else
                local filtered = {}

                for selectedValue, selectedState in pairs(self.Value) do
                    if selectedState then
                        for _, validValue in ipairs(self.Values) do
                            if selectedValue == validValue then
                                filtered[selectedValue] = true
                                break
                            end
                        end
                    end
                end

                self.Value = filtered
            end

            self:Display()

            if self.Opened then
                self:Open()
            end
        end

        function dropdown:SetValue(value)
            if self.Multi then
                local nextValue = {}

                if typeof(value) == "table" then
                    for candidate, selected in pairs(value) do
                        if selected then
                            for _, validValue in ipairs(self.Values) do
                                if candidate == validValue then
                                    nextValue[candidate] = true
                                    break
                                end
                            end
                        end
                    end
                end

                self.Value = nextValue
            else
                if value == nil then
                    if self.AllowNull then
                        self.Value = nil
                    elseif #self.Values > 0 then
                        self.Value = self.Values[1]
                    end
                else
                    for _, validValue in ipairs(self.Values) do
                        if validValue == value then
                            self.Value = value
                            break
                        end
                    end
                end
            end

            self:Display()

            if typeof(self.Callback) == "function" then
                safeCallback(self.Callback, self.Value)
            end

            if typeof(self.Changed) == "function" then
                safeCallback(self.Changed, self.Value)
            end
        end

        function dropdown:Set(value)
            self:SetValue(value)
        end

        function dropdown:GetValue()
            return self.Value
        end

        function dropdown:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function dropdown:SetTitle(value)
            frame:SetTitle(value)
        end

        function dropdown:SetDesc(value)
            frame:SetDesc(value)
        end

        function dropdown:SetDisabled(value)
            self.Disabled = value == true
            frame:SetDisabled(self.Disabled)
            inner.Active = not self.Disabled
            inner.BackgroundTransparency = self.Disabled and 0.96 or 0.9

            if self.Disabled then
                self:Close()
            end
        end

        function dropdown:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function dropdown:SetLocked(value)
            self:SetDisabled(value)
        end

        function dropdown:Destroy()
            self:Close()
            frame:Destroy()
            unregisterOption(idx)
        end

        dropdown.Instance = frame
        dropdown.Frame = frame.Frame
        dropdown.Inner = inner
        dropdown.DisplayLabel = display

        dropdown:Display()
        return registerOption(idx, dropdown)
    end

    ----------------------------------------------------------------
    -- Textbox / Input
    ----------------------------------------------------------------

    local function createTextbox(owner, idx, config)
        config = config or {}

        local inputObject = {
            Value = tostring(config.Default or ""),
            Numeric = config.Numeric == true,
            Finished = config.Finished == true,
            ClearOnFocusLost = config.ClearOnFocusLost == true,
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Input",
            Disabled = false
        }

        if config.Default == nil and config.Value ~= nil then
            inputObject.Value = tostring(config.Value)
        end

        local frame = createElementBase(
            owner.Container,
            config,
            false
        )

        frame.LabelHolder.Size = UDim2.new(1, -190, 0, 0)

        local inputFrame = new("Frame", {
            Name = "InputFrame",
            Parent = frame.Frame,
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.fromOffset(160, 30),
            BackgroundColor3 = Theme.Input,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ZIndex = 14
        })

        corner(inputFrame, 4)
        stroke(inputFrame, Theme.InElementBorder, 0.5)

        local boxContainer = new("Frame", {
            Name = "InputContainer",
            Parent = inputFrame,
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(1, -12, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 15
        })

        local box = new("TextBox", {
            Name = "Input",
            Parent = boxContainer,
            Position = UDim2.fromOffset(2, 0),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = inputObject.Value,
            PlaceholderText = tostring(config.Placeholder or ""),
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.SubText,
            TextSize = 13,
            FontFace = GothamRegular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ClearTextOnFocus = false,
            MultiLine = config.MultiLine == true,
            TextEditable = true,
            ZIndex = 16
        })

        local indicator = new("Frame", {
            Name = "Indicator",
            Parent = inputFrame,
            Position = UDim2.new(0, 2, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(1, -4, 0, 1),
            BackgroundColor3 = Theme.InputIndicator,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 16
        })

        local applyingText = false

        local function sanitize(text)
            text = tostring(text or "")

            if config.MaxLength and #text > config.MaxLength then
                text = text:sub(1, config.MaxLength)
            end

            if inputObject.Numeric and text ~= "" and tonumber(text) == nil then
                return inputObject.Value
            end

            return text
        end

        local function repositionForCursor()
            local reveal = boxContainer.AbsoluteSize.X
            if reveal <= 0 then
                return
            end

            local paddingPixels = 2

            if not box:IsFocused() then
                box.Position = UDim2.fromOffset(paddingPixels, 0)
                return
            end

            local cursor = box.CursorPosition
            if cursor == -1 then
                return
            end

            local beforeCursor = string.sub(box.Text, 1, math.max(0, cursor - 1))
            local width = TextService:GetTextSize(
                beforeCursor,
                box.TextSize,
                Enum.Font.Gotham,
                Vector2.new(math.huge, math.huge)
            ).X

            local currentCursor = box.Position.X.Offset + width

            if currentCursor < paddingPixels then
                box.Position = UDim2.fromOffset(paddingPixels - width, 0)
            elseif currentCursor > reveal - paddingPixels - 1 then
                box.Position = UDim2.fromOffset(reveal - width - paddingPixels - 1, 0)
            end
        end

        local function commitValue(text, fireCallback)
            text = sanitize(text)
            inputObject.Value = text

            if box.Text ~= text then
                applyingText = true
                box.Text = text
                applyingText = false
            end

            if fireCallback then
                if typeof(inputObject.Callback) == "function" then
                    safeCallback(inputObject.Callback, inputObject.Value)
                end

                if typeof(inputObject.Changed) == "function" then
                    safeCallback(inputObject.Changed, inputObject.Value)
                end
            end
        end

        connect(box.Focused, function()
            if inputObject.Disabled then
                box:ReleaseFocus()
                return
            end

            tween(inputFrame, 0.12, {
                BackgroundColor3 = Theme.InputFocused,
                BackgroundTransparency = 0
            })

            indicator.Size = UDim2.new(1, -2, 0, 2)
            indicator.Position = UDim2.new(0, 1, 1, 0)
            indicator.BackgroundColor3 = Theme.Accent
            indicator.BackgroundTransparency = 0
            repositionForCursor()
        end)

        connect(box:GetPropertyChangedSignal("CursorPosition"), repositionForCursor)

        connect(box:GetPropertyChangedSignal("Text"), function()
            if applyingText then
                return
            end

            repositionForCursor()

            if not inputObject.Finished then
                commitValue(box.Text, true)
            end
        end)

        connect(box.FocusLost, function(enterPressed)
            tween(inputFrame, 0.12, {
                BackgroundColor3 = Theme.Input,
                BackgroundTransparency = 0.9
            })

            indicator.Size = UDim2.new(1, -4, 0, 1)
            indicator.Position = UDim2.new(0, 2, 1, 0)
            indicator.BackgroundColor3 = Theme.InputIndicator
            indicator.BackgroundTransparency = 0.5

            if inputObject.Finished then
                if enterPressed then
                    commitValue(box.Text, true)
                else
                    commitValue(box.Text, false)
                end
            end

            if inputObject.ClearOnFocusLost then
                box.Text = ""
            end

            repositionForCursor()
        end)

        function inputObject:SetValue(text)
            commitValue(text, true)
        end

        function inputObject:Set(text)
            self:SetValue(text)
        end

        function inputObject:GetValue()
            return self.Value
        end

        function inputObject:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function inputObject:SetTitle(value)
            frame:SetTitle(value)
        end

        function inputObject:SetDesc(value)
            frame:SetDesc(value)
        end

        function inputObject:SetDisabled(value)
            self.Disabled = value == true
            frame:SetDisabled(self.Disabled)
            box.TextEditable = not self.Disabled
            inputFrame.BackgroundTransparency = self.Disabled and 0.96 or 0.9
        end

        function inputObject:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function inputObject:SetLocked(value)
            self:SetDisabled(value)
        end

        function inputObject:Destroy()
            frame:Destroy()
            unregisterOption(idx)
        end

        inputObject.Instance = frame
        inputObject.Frame = frame.Frame
        inputObject.InputFrame = inputFrame
        inputObject.Input = box
        inputObject.Textbox = box
        inputObject.Indicator = indicator

        return registerOption(idx, inputObject)
    end

    ----------------------------------------------------------------
    -- Slider
    ----------------------------------------------------------------

    local function createSlider(owner, idx, config)
        config = config or {}

        local slider = {
            Min = tonumber(config.Min) or 0,
            Max = tonumber(config.Max) or 100,
            Rounding = tonumber(config.Rounding) or 0,
            Value = nil,
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Slider",
            Disabled = false
        }

        if slider.Max < slider.Min then
            slider.Min, slider.Max = slider.Max, slider.Min
        end

        local defaultValue = tonumber(config.Default)
        if defaultValue == nil then
            defaultValue = tonumber(config.Value)
        end
        if defaultValue == nil then
            defaultValue = slider.Min
        end

        local frame = createElementBase(
            owner.Container,
            config,
            false
        )

        frame.DescLabel.Size = UDim2.new(1, -170, 0, 14)
        frame.LabelHolder.Size = UDim2.new(1, -190, 0, 0)

        local sliderInner = new("Frame", {
            Name = "SliderInner",
            Parent = frame.Frame,
            Size = UDim2.new(0, 150, 0, 4),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            BackgroundColor3 = Theme.SliderRail or Theme.Element,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 14
        })

        corner(sliderInner, 2)

        local sliderFill = new("Frame", {
            Name = "SliderFill",
            Parent = sliderInner,
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 15
        })

        corner(sliderFill, 2)

        local railInput = new("Frame", {
            Name = "SliderRailInput",
            Parent = sliderInner,
            Position = UDim2.fromOffset(0, -7),
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 16
        })

        local sliderDot = imageLabel(sliderInner, {
            Image = "rbxassetid://12266946128",
            ImageColor3 = Theme.Accent,
            Size = UDim2.fromOffset(14, 14),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            ZIndex = 17
        })

        local sliderDisplay = new("TextBox", {
            Name = "SliderDisplay",
            Parent = frame.Frame,
            Position = UDim2.new(1, -166, 0.5, -7),
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.fromOffset(70, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = tostring(defaultValue),
            TextColor3 = Theme.SubText,
            TextSize = 12,
            FontFace = GothamRegular,
            TextXAlignment = Enum.TextXAlignment.Right,
            ClearTextOnFocus = true,
            ZIndex = 15
        })

        local dragging = false

        local function alphaForValue(value)
            if slider.Max == slider.Min then
                return 0
            end

            return math.clamp(
                (value - slider.Min) / (slider.Max - slider.Min),
                0,
                1
            )
        end

        local function renderSlider()
            local alpha = alphaForValue(slider.Value or slider.Min)
            sliderFill.Size = UDim2.fromScale(alpha, 1)
            sliderDot.Position = UDim2.fromScale(alpha, 0.5)
            sliderDisplay.Text = tostring(slider.Value)
        end

        function slider:SetValue(value)
            value = tonumber(value) or self.Min
            local oldValue = self.Value or value

            self.Value = roundNumber(
                math.clamp(value, self.Min, self.Max),
                self.Rounding
            )

            renderSlider()

            if typeof(self.Callback) == "function" then
                safeCallback(self.Callback, self.Value, oldValue)
            end

            if typeof(self.Changed) == "function" then
                safeCallback(self.Changed, self.Value, oldValue)
            end
        end

        function slider:Set(value)
            self:SetValue(value)
        end

        function slider:GetValue()
            return self.Value
        end

        function slider:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function slider:SetTitle(value)
            frame:SetTitle(value)
        end

        function slider:SetDesc(value)
            frame:SetDesc(value)
        end

        function slider:SetDisabled(value)
            self.Disabled = value == true
            frame:SetDisabled(self.Disabled)
            sliderInner.BackgroundTransparency = self.Disabled and 0.75 or 0.4
            sliderDisplay.TextEditable = not self.Disabled
        end

        function slider:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function slider:SetLocked(value)
            self:SetDisabled(value)
        end

        function slider:Destroy()
            frame:Destroy()
            unregisterOption(idx)
        end

        local function updateFromInput(input)
            if slider.Disabled then
                return
            end

            local width = sliderInner.AbsoluteSize.X
            if width <= 0 then
                return
            end

            local alpha = math.clamp(
                (input.Position.X - sliderInner.AbsolutePosition.X) / width,
                0,
                1
            )

            slider:SetValue(
                slider.Min + ((slider.Max - slider.Min) * alpha)
            )
        end

        connect(railInput.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                if slider.Disabled then
                    return
                end

                dragging = true
                updateFromInput(input)
            end
        end)

        connect(UserInputService.InputChanged, function(input)
            if not dragging then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then

                updateFromInput(input)
            end
        end)

        connect(UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                dragging = false
            end
        end)

        connect(sliderDisplay.FocusLost, function()
            slider:SetValue(tonumber(sliderDisplay.Text) or slider.Value)
        end)

        slider.Instance = frame
        slider.Frame = frame.Frame
        slider.SliderInner = sliderInner
        slider.SliderFill = sliderFill
        slider.SliderDot = sliderDot
        slider.SliderDisplay = sliderDisplay

        slider:SetValue(defaultValue)
        return registerOption(idx, slider)
    end

    ----------------------------------------------------------------
    -- Keybind
    ----------------------------------------------------------------

    local function createKeybind(owner, idx, config)
        config = config or {}

        local keybind = {
            Value = config.Default or config.Value or Enum.KeyCode.Unknown,
            Mode = config.Mode or "Toggle",
            Toggled = false,
            Callback = config.Callback,
            ChangedCallback = config.ChangedCallback,
            Changed = config.Changed,
            Type = "Keybind",
            Disabled = false
        }

        local frame = createElementBase(
            owner.Container,
            config,
            true
        )

        frame.LabelHolder.Size = UDim2.new(1, -145, 0, 0)

        local displayFrame = new("TextButton", {
            Name = "KeybindDisplayFrame",
            Parent = frame.Frame,
            Position = UDim2.new(1, -10, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Size = UDim2.fromOffset(115, 30),
            BackgroundColor3 = Theme.Keybind or Theme.Element,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 14
        })

        corner(displayFrame, 5)
        stroke(displayFrame, Theme.InElementBorder, 0.5)
        padding(displayFrame, 8, 8, 0, 0)

        local displayLabel = textLabel(displayFrame, {
            Text = prettify(keybind.Value.Name or keybind.Value),
            TextSize = 13,
            TextColor3 = Theme.Text,
            FontFace = GothamRegular,
            Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 15
        })

        local picking = false

        local function keyName(value)
            if typeof(value) == "EnumItem" then
                return value.Name
            end

            return tostring(value or "None")
        end

        local function renderKey()
            displayLabel.Text = prettify(keyName(keybind.Value))
        end

        function keybind:GetState()
            if UserInputService:GetFocusedTextBox() and self.Mode ~= "Always" then
                return false
            end

            if self.Mode == "Always" then
                return true
            end

            if self.Mode == "Hold" then
                if typeof(self.Value) == "EnumItem" then
                    return UserInputService:IsKeyDown(self.Value)
                end

                return false
            end

            return self.Toggled
        end

        function keybind:SetValue(value, mode)
            if value ~= nil then
                self.Value = value
            end

            if mode ~= nil then
                self.Mode = mode
            end

            renderKey()

            if typeof(self.ChangedCallback) == "function" then
                safeCallback(self.ChangedCallback, self.Value)
            end

            if typeof(self.Changed) == "function" then
                safeCallback(self.Changed, self.Value)
            end
        end

        function keybind:Set(value)
            self:SetValue(value)
        end

        function keybind:GetValue()
            return self.Value
        end

        function keybind:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Value)
            return self
        end

        function keybind:SetTitle(value)
            frame:SetTitle(value)
        end

        function keybind:SetDesc(value)
            frame:SetDesc(value)
        end

        function keybind:SetDisabled(value)
            self.Disabled = value == true
            frame:SetDisabled(self.Disabled)
            displayFrame.BackgroundTransparency = self.Disabled and 0.96 or 0.9
        end

        function keybind:SetEnabled(value)
            self:SetDisabled(not value)
        end

        function keybind:SetLocked(value)
            self:SetDisabled(value)
        end

        function keybind:Destroy()
            frame:Destroy()
            unregisterOption(idx)
        end

        connect(displayFrame.MouseButton1Click, function()
            if keybind.Disabled then
                return
            end

            picking = true
            displayLabel.Text = "..."
        end)

        connect(UserInputService.InputBegan, function(input, processed)
            if picking then
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    picking = false
                    keybind:SetValue(input.KeyCode)
                    return
                end
            end

            if processed or keybind.Disabled then
                return
            end

            if typeof(keybind.Value) ~= "EnumItem" then
                return
            end

            if input.KeyCode ~= keybind.Value then
                return
            end

            if keybind.Mode == "Toggle" then
                keybind.Toggled = not keybind.Toggled
                safeCallback(keybind.Callback, keybind.Toggled)
            elseif keybind.Mode == "Hold" then
                safeCallback(keybind.Callback, true)
            elseif keybind.Mode == "Always" then
                safeCallback(keybind.Callback, true)
            else
                safeCallback(keybind.Callback, true)
            end
        end)

        connect(UserInputService.InputEnded, function(input)
            if keybind.Disabled then
                return
            end

            if keybind.Mode ~= "Hold" then
                return
            end

            if typeof(keybind.Value) == "EnumItem" and input.KeyCode == keybind.Value then
                safeCallback(keybind.Callback, false)
            end
        end)

        keybind.Instance = frame
        keybind.Frame = frame.Frame
        keybind.DisplayFrame = displayFrame
        keybind.DisplayLabel = displayLabel

        renderKey()
        return registerOption(idx, keybind)
    end

    ----------------------------------------------------------------
    -- Colorpicker
    --
    -- Auto Progress does not currently use it, but the original Fluent
    -- element set exposes it. Keeping a compact implementation here makes
    -- this library useful for future Auto Progress settings without pulling
    -- the original WAX colorpicker module back in.
    ----------------------------------------------------------------

    local function createColorpicker(owner, idx, config)
        config = config or {}

        local colorpicker = {
            Value = config.Default or config.Value or Theme.Accent,
            Transparency = tonumber(config.Transparency) or 0,
            Callback = config.Callback,
            Changed = config.Changed,
            Type = "Colorpicker",
            Disabled = false
        }

        local frame = createElementBase(
            owner.Container,
            config,
            false
        )

        frame.LabelHolder.Size = UDim2.new(1, -90, 0, 0)

        local previewButton = new("TextButton", {
            Name = "ColorPreview",
            Parent = frame.Frame,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(58, 26),
            BackgroundColor3 = colorpicker.Value,
            BackgroundTransparency = colorpicker.Transparency,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 14
        })

        corner(previewButton, 5)
        stroke(previewButton, Theme.InElementBorder, 0.35)

        local popup = nil
        local hue = 0
        local saturation = 1
        local value = 1

        pcall(function()
            hue, saturation, value = colorpicker.Value:ToHSV()
        end)

        local function emit(oldColor)
            previewButton.BackgroundColor3 = colorpicker.Value
            previewButton.BackgroundTransparency = colorpicker.Transparency

            if typeof(colorpicker.Callback) == "function" then
                safeCallback(
                    colorpicker.Callback,
                    colorpicker.Value,
                    colorpicker.Transparency,
                    oldColor
                )
            end

            if typeof(colorpicker.Changed) == "function" then
                safeCallback(
                    colorpicker.Changed,
                    colorpicker.Value,
                    colorpicker.Transparency,
                    oldColor
                )
            end
        end

        local function closeColorPopup()
            if popup then
                local target = popup
                popup = nil
                closeOverlay(target)
            end
        end

        function colorpicker:Close()
            closeColorPopup()
        end

        function colorpicker:SetValue(newColor, transparency)
            if typeof(newColor) ~= "Color3" then
                return
            end

            local oldColor = self.Value
            self.Value = newColor

            if transparency ~= nil then
                self.Transparency = math.clamp(tonumber(transparency) or 0, 0, 1)
            end

            hue, saturation, value = self.Value:ToHSV()
            emit(oldColor)
        end

        function colorpicker:SetValueRGB(newColor, transparency)
            self:SetValue(newColor, transparency)
        end

        function colorpicker:Set(valueToSet)
            if typeof(valueToSet) == "Color3" then
                self:SetValue(valueToSet)
            elseif typeof(valueToSet) == "table" then
                if typeof(valueToSet.Color) == "Color3" then
                    self:SetValue(valueToSet.Color, valueToSet.Transparency)
                end
            end
        end

        function colorpicker:GetValue()
            return self.Value
        end

        function colorpicker:OnChanged(callback)
            self.Changed = callback
            safeCallback(callback, self.Value, self.Transparency, self.Value)
            return self
        end

        function colorpicker:SetTitle(valueToSet)
            frame:SetTitle(valueToSet)
        end

        function colorpicker:SetDesc(valueToSet)
            frame:SetDesc(valueToSet)
        end

        function colorpicker:SetDisabled(disabled)
            self.Disabled = disabled == true
            frame:SetDisabled(self.Disabled)
            previewButton.Active = not self.Disabled
            previewButton.BackgroundTransparency = self.Disabled and 0.75 or self.Transparency

            if self.Disabled then
                self:Close()
            end
        end

        function colorpicker:SetEnabled(enabled)
            self:SetDisabled(not enabled)
        end

        function colorpicker:SetLocked(locked)
            self:SetDisabled(locked)
        end

        function colorpicker:Destroy()
            self:Close()
            frame:Destroy()
            unregisterOption(idx)
        end

        function colorpicker:Open()
            if self.Disabled then
                return
            end

            closeColorPopup()

            local absolute = previewButton.AbsolutePosition
            local currentView = viewportSize()
            local popupWidth = 230
            local popupHeight = 185
            local x = math.clamp(absolute.X - popupWidth + 58, 6, currentView.X - popupWidth - 6)
            local y = absolute.Y + 32

            if y + popupHeight > currentView.Y - 6 then
                y = absolute.Y - popupHeight - 6
            end

            popup = new("Frame", {
                Name = "ColorpickerPopup",
                Parent = gui,
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(popupWidth, popupHeight),
                BackgroundColor3 = Theme.DropdownHolder,
                BackgroundTransparency = 0.01,
                BorderSizePixel = 0,
                ZIndex = 350
            })

            corner(popup, 7)
            stroke(popup, Theme.DropdownBorder, 0)
            addSoftShadow(popup, 349)
            trackOverlay(popup)

            local saturationValue = new("ImageButton", {
                Name = "SaturationValue",
                Parent = popup,
                Position = UDim2.fromOffset(10, 10),
                Size = UDim2.new(1, -42, 0, 115),
                BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Image = "rbxassetid://4155801252",
                ZIndex = 352
            })

            corner(saturationValue, 5)

            local svCursor = new("Frame", {
                Parent = saturationValue,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(saturation, 1 - value),
                Size = UDim2.fromOffset(10, 10),
                BackgroundColor3 = Theme.White,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 354
            })

            corner(svCursor, 5)
            stroke(svCursor, Color3.new(0, 0, 0), 0.2, 1)

            local hueBar = new("ImageButton", {
                Name = "HueBar",
                Parent = popup,
                Position = UDim2.new(1, -24, 0, 10),
                Size = UDim2.fromOffset(14, 115),
                BackgroundColor3 = Theme.White,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Image = "rbxassetid://3641079629",
                ZIndex = 352
            })

            corner(hueBar, 4)

            local hueCursor = new("Frame", {
                Parent = hueBar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, hue),
                Size = UDim2.new(1, 6, 0, 4),
                BackgroundColor3 = Theme.White,
                BorderSizePixel = 0,
                ZIndex = 354
            })

            corner(hueCursor, 2)
            stroke(hueCursor, Color3.new(0, 0, 0), 0.25, 1)

            local hexBox = new("TextBox", {
                Name = "Hex",
                Parent = popup,
                Position = UDim2.fromOffset(10, 136),
                Size = UDim2.new(1, -20, 0, 32),
                BackgroundColor3 = Theme.Input,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                Text = colorpicker.Value:ToHex(),
                PlaceholderText = "Hex",
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.SubText,
                TextSize = 12,
                FontFace = GothamRegular,
                ClearTextOnFocus = false,
                ZIndex = 352
            })

            corner(hexBox, 5)
            stroke(hexBox, Theme.InElementBorder, 0.5)
            padding(hexBox, 9, 9, 0, 0)

            local draggingSV = false
            local draggingHue = false

            local function updateSV(input)
                local size = saturationValue.AbsoluteSize
                if size.X <= 0 or size.Y <= 0 then
                    return
                end

                saturation = math.clamp(
                    (input.Position.X - saturationValue.AbsolutePosition.X) / size.X,
                    0,
                    1
                )

                value = 1 - math.clamp(
                    (input.Position.Y - saturationValue.AbsolutePosition.Y) / size.Y,
                    0,
                    1
                )

                svCursor.Position = UDim2.fromScale(saturation, 1 - value)
                local oldColor = colorpicker.Value
                colorpicker.Value = Color3.fromHSV(hue, saturation, value)
                hexBox.Text = colorpicker.Value:ToHex()
                emit(oldColor)
            end

            local function updateHue(input)
                local size = hueBar.AbsoluteSize
                if size.Y <= 0 then
                    return
                end

                hue = math.clamp(
                    (input.Position.Y - hueBar.AbsolutePosition.Y) / size.Y,
                    0,
                    1
                )

                hueCursor.Position = UDim2.fromScale(0.5, hue)
                saturationValue.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                local oldColor = colorpicker.Value
                colorpicker.Value = Color3.fromHSV(hue, saturation, value)
                hexBox.Text = colorpicker.Value:ToHex()
                emit(oldColor)
            end

            connect(saturationValue.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then

                    draggingSV = true
                    updateSV(input)
                end
            end)

            connect(hueBar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then

                    draggingHue = true
                    updateHue(input)
                end
            end)

            connect(UserInputService.InputChanged, function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then

                    return
                end

                if draggingSV then
                    updateSV(input)
                elseif draggingHue then
                    updateHue(input)
                end
            end)

            connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then

                    draggingSV = false
                    draggingHue = false
                end
            end)

            connect(hexBox.FocusLost, function()
                local text = hexBox.Text:gsub("#", "")
                local ok, parsed = pcall(Color3.fromHex, text)

                if ok and typeof(parsed) == "Color3" then
                    colorpicker:SetValue(parsed)
                    hue, saturation, value = colorpicker.Value:ToHSV()
                    saturationValue.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                    svCursor.Position = UDim2.fromScale(saturation, 1 - value)
                    hueCursor.Position = UDim2.fromScale(0.5, hue)
                else
                    hexBox.Text = colorpicker.Value:ToHex()
                end
            end)
        end

        connect(previewButton.MouseButton1Click, function()
            if colorpicker.Disabled then
                return
            end

            if popup then
                colorpicker:Close()
            else
                colorpicker:Open()
            end
        end)

        colorpicker.Instance = frame
        colorpicker.Frame = frame.Frame
        colorpicker.PreviewButton = previewButton

        return registerOption(idx, colorpicker)
    end

    ----------------------------------------------------------------
    -- Shared element method attachment for Tabs and Sections
    ----------------------------------------------------------------

    local function attachElementMethods(owner)
        function owner:Section(sectionConfig)
            local section = createSection(self, sectionConfig)
            attachElementMethods(section)
            return section
        end

        owner.CreateSection = owner.Section
        owner.AddSection = owner.Section

        function owner:Label(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Label",
                idxOrConfig,
                maybeConfig
            )

            if elementConfig.Content == nil then
                elementConfig.Content = elementConfig.Description or ""
            end

            return createParagraph(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Paragraph(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Paragraph",
                idxOrConfig,
                maybeConfig
            )

            if elementConfig.Content == nil then
                elementConfig.Content = elementConfig.Description or ""
            end

            return createParagraph(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Button(configOrIdx, maybeConfig)
            local configValue

            if maybeConfig ~= nil then
                configValue = normalizeLegacyConfig(maybeConfig)
            else
                configValue = normalizeLegacyConfig(configOrIdx)
            end

            return createButton(
                self,
                configValue
            )
        end

        function owner:Toggle(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Toggle",
                idxOrConfig,
                maybeConfig
            )

            return createToggle(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Dropdown(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Dropdown",
                idxOrConfig,
                maybeConfig
            )

            return createDropdown(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Textbox(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Textbox",
                idxOrConfig,
                maybeConfig
            )

            elementConfig.ClearOnFocusLost = elementConfig.ClearOnFocusLost == true

            return createTextbox(
                self,
                idx,
                elementConfig
            )
        end

        owner.Input = owner.Textbox

        function owner:Slider(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Slider",
                idxOrConfig,
                maybeConfig
            )

            return createSlider(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Keybind(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Keybind",
                idxOrConfig,
                maybeConfig
            )

            return createKeybind(
                self,
                idx,
                elementConfig
            )
        end

        function owner:Colorpicker(idxOrConfig, maybeConfig)
            local idx, elementConfig = normalizeElementArgs(
                "Colorpicker",
                idxOrConfig,
                maybeConfig
            )

            return createColorpicker(
                self,
                idx,
                elementConfig
            )
        end

        owner.ColorPicker = owner.Colorpicker

        return owner
    end

    ----------------------------------------------------------------
    -- Tab creation
    ----------------------------------------------------------------

    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}

        self.TabCount = self.TabCount + 1
        local index = self.TabCount

        local tab = {
            Index = index,
            Name = tostring(tabConfig.Title or ("Tab " .. tostring(index))),
            Type = "Tab",
            Selected = false
        }

        local tabButton = new("TextButton", {
            Name = "TabButton",
            Parent = tabHolder,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Tab,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = index,
            ZIndex = 9
        })

        corner(tabButton, 6)

        local tabIcon = imageLabel(tabButton, {
            Name = "",
            Position = UDim2.new(0, 8, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.fromOffset(16, 16),
            ImageColor3 = Theme.SubText,
            ZIndex = 10,
            Visible = false
        })

        tabIcon.Name = "IconLabel"

        if applyNamedOrDirectIcon(tabIcon, tabConfig.Icon) then
            tabIcon.Visible = true
        end

        local titleX = tabIcon.Visible and 30 or 10

        local tabTitle = textLabel(tabButton, {
            Text = tab.Name,
            TextSize = 12,
            TextColor3 = Theme.SubText,
            FontFace = GothamRegular,
            Position = UDim2.new(0, titleX, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, tabIcon.Visible and -38 or -18, 1, 0),
            RichText = true,
            ZIndex = 10
        })

        tabTitle.Name = "TabTitleLabel"

        local container = new("ScrollingFrame", {
            Name = tab.Name,
            Parent = containerHolder,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromScale(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            BottomImage = "rbxassetid://6889812791",
            MidImage = "rbxassetid://6889812721",
            TopImage = "rbxassetid://6276641225",
            ScrollBarImageColor3 = Theme.White,
            ScrollBarImageTransparency = 0.95,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 8
        })

        local containerLayout = new("UIListLayout", {
            Parent = container,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        padding(container, 1, 10, 1, 1)

        connect(containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            local target = UDim2.fromOffset(
                0,
                containerLayout.AbsoluteContentSize.Y + 2
            )

            if container.CanvasSize ~= target then
                container.CanvasSize = target
            end
        end)

        tab.Button = tabButton
        tab.Frame = tabButton
        tab.IconLabel = tabIcon
        tab.TitleLabel = tabTitle
        tab.Container = container
        tab.ContainerFrame = container
        tab.ScrollFrame = container
        tab.Layout = containerLayout

        attachElementMethods(tab)

        connect(tabButton.MouseEnter, function()
            tween(tabButton, 0.1, {
                BackgroundTransparency = tab.Selected and 0.85 or 0.89
            })
        end)

        connect(tabButton.MouseLeave, function()
            tween(tabButton, 0.1, {
                BackgroundTransparency = tab.Selected and 0.89 or 1
            })
        end)

        connect(tabButton.MouseButton1Down, function()
            tween(tabButton, 0.06, {
                BackgroundTransparency = 0.92
            })
        end)

        connect(tabButton.MouseButton1Up, function()
            tween(tabButton, 0.06, {
                BackgroundTransparency = tab.Selected and 0.85 or 0.89
            })
        end)

        connect(tabButton.MouseButton1Click, function()
            selectTab(index, false)
        end)

        self.Tabs[index] = tab
        self.Containers[index] = container

        -- First tab must become usable before Window:Tab() returns.
        -- Do the essential state directly instead of relying on selector
        -- animation/layout code. This prevents a selector failure from
        -- leaving the UI stuck on the literal heading "Tab".
        if self.TabCount == 1 then
            self.SelectedTab = 1

            tab.Selected = true
            tab.Container.Visible = true
            tab.Button.BackgroundTransparency = 0.89
            tab.TitleLabel.TextColor3 = Theme.Text

            if tab.IconLabel then
                tab.IconLabel.ImageColor3 = Theme.Text
            end

            tabDisplay.Text = tab.Name
            selector.Visible = true

            local selectorOk, selectorErr = pcall(function()
                updateSelector(1, true)
            end)

            if not selectorOk then
                warn("[RoyalPurple] First-tab selector error:", selectorErr)
            end

            task.defer(function()
                local selectOk, selectErr = pcall(function()
                    selectTab(1, true)
                end)

                if not selectOk then
                    warn("[RoyalPurple] Deferred first-tab select error:", selectErr)
                end
            end)
        end

        local filterOk, filterErr = pcall(filterTabs)

        if not filterOk then
            warn("[RoyalPurple] Tab filter error:", filterErr)
        end

        return tab
    end

    function window:AddTab(tabConfig)
        return self:Tab(tabConfig)
    end

    function window:CreateTab(tabConfig)
        return self:Tab(tabConfig)
    end

    function window:Destroy()
        Library:Destroy()
    end

    ----------------------------------------------------------------
    -- Exposed references used by compatibility/debug code
    ----------------------------------------------------------------

    window.GUI = gui
    window.SearchBox = searchBox
    window.RootFrame = root
    window.Mobile = mobile
    window.Size = root.Size
    window.MinSize = config.MinSize

    ----------------------------------------------------------------
    -- Apply requested transparency after every child exists.
    ----------------------------------------------------------------

    Library:ToggleTransparency(false)

    return window
end

function Library:AddWindow(config)
    return self:Window(config)
end

function Library:CreateWindow(config)
    return self:Window(config)
end

----------------------------------------------------------------
-- Complete the exact Royal_Purple property set from the source.
-- These are assigned here as well as the compact table near the top so
-- every extended component has the same values as the bundled theme.
----------------------------------------------------------------

Theme.SliderRail = Color3.fromRGB(100, 70, 150)
Theme.Keybind = Color3.fromRGB(100, 70, 150)
Theme.DialogButton = Color3.fromRGB(13, 9, 20)
Theme.DialogButtonBorder = Color3.fromRGB(112, 84, 158)
Theme.DialogBorder = Color3.fromRGB(100, 70, 150)
Theme.DialogInput = Color3.fromRGB(32, 28, 38)
Theme.DialogInputLine = Color3.fromRGB(138, 116, 176)

----------------------------------------------------------------
-- Icon utility compatibility
----------------------------------------------------------------

function Library.Utilities.Icons:SetIcon(target, iconName)
    local data = self[tostring(iconName or "")]

    if typeof(data) == "table" then
        target.Image = data.Image
        target.ImageRectOffset = data.ImageRectOffset or Vector2.zero
        target.ImageRectSize = data.ImageRectSize or Vector2.zero
        return target
    end

    if typeof(data) == "string" then
        target.Image = data
        target.ImageRectOffset = Vector2.zero
        target.ImageRectSize = Vector2.zero
        return target
    end

    return nil
end

----------------------------------------------------------------
-- Royal Purple is the only theme. Keep SetTheme callable so scripts that
-- still pass a theme do not break, but never switch away from it.
----------------------------------------------------------------

function Library:SetTheme(_name)
    self.Theme = "Royal_Purple"
    return "Royal_Purple"
end

----------------------------------------------------------------
-- Transparency compatible with the rebuilt window hierarchy.
----------------------------------------------------------------

function Library:ToggleTransparency(value)
    self.Transparency = value == true

    local window = self.CreatedWindow
    if not window or not window.Root then
        return
    end

    local target = self.Transparency and 0.14 or 0

    tween(window.Root, 0.15, {
        BackgroundTransparency = target
    })
end

----------------------------------------------------------------
-- Notification implementation
----------------------------------------------------------------

function Library:Notify(config)
    config = config or {}

    if not self.GUI then
        return nil
    end

    local holder = self.GUI:FindFirstChild("Notifications")

    if not holder then
        holder = new("Frame", {
            Name = "Notifications",
            Parent = self.GUI,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -30, 1, -30),
            Size = UDim2.new(0, 310, 1, -30),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 500
        })

        new("UIListLayout", {
            Parent = holder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12)
        })
    end

    local notification = {
        Closed = false
    }

    local card = new("Frame", {
        Name = "Notification",
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.DropdownHolder,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = 501
    })

    corner(card, 7)
    stroke(card, Theme.AcrylicBorder, 0.45)
    addSoftShadow(card, 500)
    padding(card, 14, 14, 12, 12)

    local cardLayout = new("UIListLayout", {
        Parent = card,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local title = textLabel(card, {
        Text = config.Title or "Notification",
        TextSize = 13,
        TextColor3 = Theme.Text,
        FontFace = GothamSemiBold,
        Size = UDim2.new(1, 0, 0, 17),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        ZIndex = 502
    })

    local content = textLabel(card, {
        Text = config.Content or "",
        TextSize = 13,
        TextColor3 = Theme.Text,
        FontFace = GothamRegular,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        ZIndex = 502,
        Visible = tostring(config.Content or "") ~= ""
    })

    local subContent = textLabel(card, {
        Text = config.SubContent or "",
        TextSize = 12,
        TextColor3 = Theme.SubText,
        FontFace = GothamRegular,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        ZIndex = 502,
        Visible = tostring(config.SubContent or "") ~= ""
    })

    local buttons = config.Buttons or {}

    if #buttons > 0 then
        local buttonRow = new("Frame", {
            Parent = card,
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 502
        })

        local buttonLayout = new("UIListLayout", {
            Parent = buttonRow,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        for index, buttonConfig in ipairs(buttons) do
            local button = new("TextButton", {
                Parent = buttonRow,
                Size = UDim2.fromOffset(82, 28),
                BackgroundColor3 = Theme.DialogButton,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Text = tostring(buttonConfig.Title or ("Button " .. index)),
                TextColor3 = Theme.Text,
                TextSize = 12,
                FontFace = GothamRegular,
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 503
            })

            corner(button, 4)
            stroke(button, Theme.DialogButtonBorder, 0.6)

            connect(button.MouseButton1Click, function()
                safeCallback(buttonConfig.Callback)
            end)
        end
    end

    function notification:Close()
        if self.Closed then
            return
        end

        self.Closed = true

        tween(card, 0.15, {
            BackgroundTransparency = 1
        })

        task.delay(0.17, function()
            if card and card.Parent then
                card:Destroy()
            end
        end)
    end

    if config.Duration ~= nil then
        task.delay(tonumber(config.Duration) or 5, function()
            notification:Close()
        end)
    end

    notification.Root = card
    notification.TitleLabel = title
    notification.ContentLabel = content
    notification.SubContentLabel = subContent

    return notification
end

----------------------------------------------------------------
-- Public API notes / compatibility guarantees
--
-- The following calls are intentionally maintained because Auto Progress
-- already uses them in its publish build. They are listed here beside the
-- implementation to make future editing safer:
--
--   Library:Window({
--       Title = "Auto Progress",
--       Desc = "",
--       Icon = 99432006374500,
--       Config = {
--           Keybind = Enum.KeyCode.LeftControl,
--           Size = UDim2.new(0, 500, 0, 400)
--       }
--   })
--
--   Library:ToggleTransparency(false)
--
--   local Automation = Window:Tab({
--       Title = "Automation",
--       Icon = "bot"
--   })
--
--   local Settings = Window:Tab({
--       Title = "Settings",
--       Icon = "settings"
--   })
--
--   Window:SelectTab(1)
--
-- Element calls support both modern indexed style and the older single
-- config-table style. That means both of these are valid:
--
--   Automation:Toggle("AutoFarm", {
--       Title = "Auto Farm",
--       Default = false,
--       Callback = function(value) end
--   })
--
--   Automation:Toggle({
--       Title = "Auto Farm",
--       Value = false,
--       Callback = function(value) end
--   })
--
-- The same compatibility rule applies to Dropdown, Label/Paragraph,
-- Textbox/Input, Slider, Keybind, and Colorpicker.
--
-- Every stateful option is also placed in Library.Options under its index.
-- Legacy one-table calls receive an internal __ProgressLegacy_* id so they
-- can still use the same registry without forcing Auto Progress to change.
----------------------------------------------------------------

return Library
