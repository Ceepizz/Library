local ImportGlobals

local ClosureBindings = {
    function()local wax,script,require=ImportGlobals(1)local ImportGlobals return (function(...)local function Clone<Original>(ToClone: any & Original): (Original, boolean)
	local Type = typeof(ToClone)

	if Type == "function" and (clonefunc or clonefunction) then
		return (clonefunc or clonefunction)(ToClone), true
	elseif Type == "Instance" and (cloneref or clonereference) then
		return (cloneref or clonereference)(ToClone), true
	elseif Type == "table" then
		local function deepcopy(orig, copies: { [any]: any }?)
			local Copies = copies or {}
			local orig_type, copy = typeof(orig), nil

			if orig_type == 'table' then
				if Copies[orig] then
					copy = Copies[orig]
				else
					copy = {}

					Copies[orig] = copy

					for orig_key, orig_value in next, orig, nil do
						copy[deepcopy(orig_key, Copies)] = deepcopy(orig_value, Copies)
					end

					(setrawmetatable or setmetatable)(copy, deepcopy((getrawmetatable or getmetatable)(orig), Copies))
				end
			elseif orig_type == 'Instance' or orig_type == 'function' then
				copy = Clone(orig)
			else
				copy = orig
			end

			return copy
		end

		return deepcopy(ToClone), true
	else
		return ToClone, false
	end
end

local MarketplaceService = Clone(game:GetService("MarketplaceService"))
local TweenService = Clone(game:GetService("TweenService"))
local Camera = Clone(game:GetService("Workspace")).CurrentCamera
local UserInputService = Clone(game:GetService("UserInputService"))
local GuiService = Clone(game:GetService("GuiService"))

local Root = script
local Components = Root.Components

local Creator = require(Root.Modules.Creator)
local ElementsTable = require(Root.Elements)
local Acrylic = require(Root.Modules.Acrylic)
local Icons = require(Root.Modules.Icons)
local Themes = require(Root.Themes)
local Signal = require(Root.Packages.Signal)

local NotificationModule = require(Components.Notification)

local SharedTable = shared or _G or (getgenv and getgenv()) or getfenv(1)
local New = Creator.New

local CoreGui = game:GetService("CoreGui")

local ExistingProgress = CoreGui:FindFirstChild("Progress")
if ExistingProgress then
	ExistingProgress:Destroy()
end

local BaseContainer = New("ScreenGui", {
	Name = "Progress",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999
})

BaseContainer.Parent = CoreGui

SharedTable.FluentRenewed = SharedTable.FluentRenewed or {}

NotificationModule:Init(BaseContainer)

local Library = {
	Version = "1.0",

	OpenFrames = {},
	Options = {},
	Themes = Themes.Names,

	OnUnload = Signal.new(),
	PostUnload = Signal.new(),
	ThemeChanged = Signal.new(),
	WindowSizeChanged = Signal.new(),
	CreatedWindow = nil,
	WindowFrame = nil,
	UIContainer = BaseContainer.Parent,
	Utilities = {
		Themes = Themes,
		Shared = SharedTable,
		Creator = Creator,
		Icons = Icons
	},
	Connections = Creator.Signals,
	Unloaded = false,
	Loaded = true,

	Theme = "Royal_Purple",
	DialogOpen = false,
	UseAcrylic = false,
	Acrylic = false,
	Transparency = true,
	MinimizeKey = Enum.KeyCode.LeftControl,

	GUI = BaseContainer
}

function Library:SafeCallback(Function, ...)
	assert(typeof(Function) == "function", debug.traceback(`Library:SafeCallback expects type 'function' at Argument #1, got '{typeof(Function)}'`, 2))

	task.spawn(function(...)
		local Success, Event = pcall(Function, ...)

		if not Success then
			local _, i = Event:find(":%d+: ")

			task.defer(error, debug.traceback(Event, 2))

			Library:Notify({
				Title = "Interface",
				Content = "Callback error",
				SubContent = if typeof(i) == "number" then Event:sub(i + 1) else Event,
				Duration = 5,
			})
		end
	end, ...)
end

function Library.Utilities:Resize(X: number, Y: number): (number, number)
    local x, y, CurrentSize = X / 1920, Y / 1080, Camera.ViewportSize
    return CurrentSize.X * x, CurrentSize.Y * y
end

function Library.Utilities:Truncate(number: number, decimals: number, round: boolean): number
	local shift = 10 ^ (typeof(decimals) == "number" and math.max(decimals, 0) or 0)

	if round then
		return math.round(number * shift) // 1 / shift
	else
		return number * shift // 1 / shift
	end
end

function Library.Utilities:Round(Number: number, Factor: number): number
	return Library.Utilities:Truncate(Number, Factor, true)
end

function Library.Utilities:GetIcon(Name: string): { Image: string, ImageRectSize: Vector2, ImageRectOffset: Vector2 }
	return Name ~= "SetIcon" and Icons[Name] or nil
end

function Library.Utilities:Prettify(ToPrettify: EnumItem & string & number): string | number

	if typeof(ToPrettify) == "EnumItem" then
		return ({ToPrettify.Name:gsub("(%l)(%u)", "%1 %2")})[1]
	elseif typeof(ToPrettify) == "string" then
		return ({ToPrettify:gsub("(%l)(%u)", "%1 %2")})[1]
	elseif typeof(ToPrettify) == "number" then
		return Library.Utilities:Round(ToPrettify, 2)
	else
		return tostring(ToPrettify)
	end
end

function Library.Utilities:Clone<Original>(ToClone: {[any]: any} & (...any) -> (...any) & Object & Original): (Original, boolean)
	return Clone(ToClone)
end

function Library.Utilities:GetOS()
	local OSName = "Unknown"

	if GuiService:IsTenFootInterface() then
		local L2Button_Name = UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonL2)

		OSName = if L2Button_Name == "ButtonLT" then "Xbox" elseif L2Button_Name == "ButtonL2" then "PlayStation" else "Console"
	elseif GuiService.IsWindows then
		OSName = "Windows"
	elseif version():find("^0.") == 1 then
		OSName = "macOS"
	elseif version():find("^2.") == 1 then
		OSName = UserInputService.VREnabled and "MetaHorizon" or "Mobile"
	end

	return OSName
end

local Elements = {}
Elements.__index = Elements
Elements.__namecall = function(Table, Key, ...)
	return Elements[Key](...)
end

for _, ElementComponent in next, ElementsTable do
	Elements[`Create{ElementComponent.__type}`] = function(self, Idx, Config)
		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library

		return ElementComponent:New(Idx, Config)
	end

	Elements[`Add{ElementComponent.__type}`] = Elements[`Create{ElementComponent.__type}`]
	Elements[ElementComponent.__type] = Elements[`Create{ElementComponent.__type}`]
end

local LegacyElementCounter = 0

local function LegacyId(Prefix)
	LegacyElementCounter += 1
	return `__ProgressLegacy_{Prefix}_{LegacyElementCounter}`
end

local function LegacyConfig(Config)
	local Result = {}

	for Key, Value in next, Config or {} do
		Result[Key] = Value
	end

	if Result.Description == nil then
		Result.Description = Result.Desc
	end

	if Result.Default == nil then
		Result.Default = Result.Value
	end

	return Result
end

local NativeToggle = Elements.CreateToggle
local NativeDropdown = Elements.CreateDropdown
local NativeParagraph = Elements.CreateParagraph
local NativeInput = Elements.CreateInput
local NativeButton = Elements.CreateButton

function Elements:Toggle(Idx, Config)
	if Config ~= nil then
		return NativeToggle(self, Idx, Config)
	end

	local Legacy = LegacyConfig(Idx)
	return NativeToggle(self, LegacyId("Toggle"), Legacy)
end

function Elements:Dropdown(Idx, Config)
	if Config ~= nil then
		return NativeDropdown(self, Idx, Config)
	end

	local Legacy = LegacyConfig(Idx)
	Legacy.Values = Legacy.Values or Legacy.List or {}
	return NativeDropdown(self, LegacyId("Dropdown"), Legacy)
end

function Elements:Label(Idx, Config)
	if Config ~= nil then
		return NativeParagraph(self, Idx, Config)
	end

	local Legacy = LegacyConfig(Idx)
	Legacy.Content = if Legacy.Content ~= nil then Legacy.Content else Legacy.Desc or ""
	return NativeParagraph(self, LegacyId("Label"), Legacy)
end

function Elements:Textbox(Idx, Config)
	if Config ~= nil then
		return NativeInput(self, Idx, Config)
	end

	local Legacy = LegacyConfig(Idx)
	Legacy.ClearOnFocusLost = Legacy.ClearOnFocusLost == true
	return NativeInput(self, LegacyId("Textbox"), Legacy)
end

function Elements:Button(Config)
	local Legacy = LegacyConfig(Config)
	return NativeButton(self, Legacy)
end

Library.Elements = Elements

function Library:Window(Config: {
		Title: string?,
		SubTitle: string?,
		TabWidth: number?,
		MinSize: Vector2?,
		Size: UDim2?,
		Resize: boolean?,
		MinimizeKey: Enum.KeyCode?,
		Acrylic: boolean?,
		Theme: string?,
		Mobile: {
			GetIcon: (IsMinimized: boolean) -> { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 },
			Size: UDim2,
			WindowSize: UDim2?
		}?
	})
	assert(Library.CreatedWindow == nil, debug.traceback("You cannot create more than one window.", 2))

	Config = Config or {}

	if Config.SubTitle == nil and Config.Desc ~= nil then
		Config.SubTitle = Config.Desc
	end

	if typeof(Config.Config) == "table" then
		if Config.Size == nil and typeof(Config.Config.Size) == "UDim2" then
			Config.Size = Config.Config.Size
		end

		if Config.MinimizeKey == nil and Config.Config.Keybind ~= nil then
			Config.MinimizeKey = Config.Config.Keybind
		end
	end

	Config.Theme = "Royal_Purple"

	if not Config.Title then
		local Success, Game_Info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)

		Config.Title = Success and Game_Info.Name or "Fluent Renewed"
	end

	Config.MinSize = if typeof(Config.MinSize) == "Vector2" then Config.MinSize else Vector2.new(470, 380)

	Config.Size = if Config.Resize ~= true then Config.Size else UDim2.fromOffset(Library.Utilities:Resize((Config.Size and Config.Size.X.Offset) or 470, (Config.Size and Config.Size.Y.Offset) or 380))
	Config.MinSize = if Config.Resize ~= true then Config.MinSize else Vector2.new(Library.Utilities:Resize((Config.MinSize and Config.MinSize.X) or 470, (Config.MinSize and Config.MinSize.Y) or 380))

	if typeof(Config.Mobile) == "table" and typeof(Config.Mobile.WindowSize) == "UDim2" and Config.Resize == true then
		Config.Mobile.WindowSize = UDim2.fromOffset(Library.Utilities:Resize(Config.Mobile.WindowSize.X.Offset, Config.Mobile.WindowSize.Y.Offset))
	end

	Library.MinimizeKey = if typeof(Config.MinimizeKey) == "string" or typeof(Config.MinimizeKey) == "EnumItem" and Config.MinimizeKey.EnumType == Enum.KeyCode then Config.MinimizeKey else Enum.KeyCode.LeftControl
	Library.UseAcrylic = if typeof(Config.Acrylic) == "boolean" then Config.Acrylic else false
	Library.Acrylic = if typeof(Config.Acrylic) == "boolean" then Config.Acrylic else false
	Library.Theme = "Royal_Purple"

	if Config.Acrylic then
		Acrylic.init()
	end

	local Window = require(Components.Window){
		Config = Config,
		Parent = BaseContainer,

		Size = Config.Size,
		MinSize = Config.MinSize,

		Title = Config.Title,
		SubTitle = Config.SubTitle or "Made with Fluent Renewed",

		TabWidth = Config.TabWidth or 160,
		Alignment = Config.Alignment,
		Mobile = {
			GetIcon = (Config.Mobile and Config.Mobile.GetIcon) or function(IsMinimized: boolean): { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 }
				return Library.Utilities:GetIcon(IsMinimized and "phosphor-eye" or "phosphor-eye-slash")
			end,
			Size = (Config.Mobile and Config.Mobile.Size) or UDim2.fromOffset(30, 30),
			WindowSize = Config.Mobile and Config.Mobile.WindowSize
		}
	}

	BaseContainer.Name = "Progress"

	Library.CreatedWindow = Window
	Library:SetTheme(Library.Theme)

	return Window
end

function Library:AddWindow(Config)
	return Library:Window(Config)
end

function Library:CreateWindow(Config)
	return Library:Window(Config)
end

function Library:SetTheme(Name: string)
	if Library.CreatedWindow and table.find(Library.Themes, Name) then
		Library.Theme = Name
		Creator.UpdateTheme()
		Library.ThemeChanged:Fire(Name)
	end
end

function Library:Destroy()
	if Library.CreatedWindow then
		Library.Unloaded = true
		Library.Loaded = false

		Library.OnUnload:Fire(tick())

		if Library.UseAcrylic then
			Library.CreatedWindow.AcrylicPaint.Model:Destroy()
		end

		Creator.Disconnect()

		for i,v in next, Library.Connections do
			local type = typeof(v)

			if type == "RBXScriptConnection" and v.Connected then
				v:Disconnect()
			end
		end

		local info, tweenProps, doTween = TweenInfo.new(2 / 3, Enum.EasingStyle.Quint), {}, false

		local function IsA(obj: Object, class: string)
			local isClass = obj:IsA(class)

			if isClass then
				doTween = true
			end

			return isClass
		end

		for i,v in next, Library.GUI:GetDescendants() do
			table.clear(tweenProps)

			if IsA(v, "GuiObject") then
				tweenProps.BackgroundTransparency = 1
			end

			if IsA(v, "ScrollingFrame") then
				tweenProps.ScrollBarImageTransparency = 1
			end

			if IsA(v, "TextLabel") or IsA(v, "TextBox") then
				tweenProps.TextStrokeTransparency = 1
				tweenProps.TextTransparency = 1
			end

			if IsA(v, "UIStroke") then
				tweenProps.Transparency = 1
			end

			if IsA(v, "ImageLabel") or IsA(v, "ImageButton") then
				tweenProps.ImageTransparency = 1
			end

			if doTween then
				doTween = false
				TweenService:Create(v, info, tweenProps):Play()
			end
		end

		task.delay(info.Time, function()
			Library.GUI:Destroy()

			Library.PostUnload:Fire(tick())
		end)
	end
end

function Library:ToggleAcrylic(Value: boolean)
	if Library.CreatedWindow then
		if Library.UseAcrylic then
			Library.Acrylic = Value
			Library.CreatedWindow.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
			if Value then
				Acrylic.Enable()
			else
				Acrylic.Disable()
			end
		end
	end
end

function Library:ToggleTransparency(Value: boolean)
	if Library.CreatedWindow then
		Library.CreatedWindow.AcrylicPaint.Frame.Background.BackgroundTransparency = Value and 0.35 or 0
	end
end

function Library:Notify(Config)
	return NotificationModule:New(Config)
end

return Library
end)() end,
    [3] = function()local wax,script,require=ImportGlobals(3)local ImportGlobals return (function(...)return {
	Close = "rbxassetid://9886659671",
	Min = "rbxassetid://9886659276",
	Max = "rbxassetid://9886659406",
	Restore = "rbxassetid://9886659001",
}

end)() end,
    [4] = function()local wax,script,require=ImportGlobals(4)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local New = Creator.New

local Spring = Flipper.Spring.new

return function(Theme, Parent, DialogCheck)
	local Button = {}

	DialogCheck = DialogCheck or false

	Button.Title = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Button.HoverFrame = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ThemeTag = {
			BackgroundColor3 = "Hover",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})

	Button.Frame = New("TextButton", {
		Size = UDim2.new(0, 0, 0, 32),
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "DialogButton",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = 0.65,
			ThemeTag = {
				Color = "DialogButtonBorder",
			},
		}),
		Button.HoverFrame,
		Button.Title,
	})

	local Motor, SetTransparency = Creator.SpringMotor(1, Button.HoverFrame, "BackgroundTransparency", DialogCheck)
	Creator.AddSignal(Button.Frame.MouseEnter, function()
		SetTransparency(0.97)
	end)
	Creator.AddSignal(Button.Frame.MouseLeave, function()
		SetTransparency(1)
	end)
	Creator.AddSignal(Button.Frame.MouseButton1Down, function()
		SetTransparency(1)
	end)
	Creator.AddSignal(Button.Frame.MouseButton1Up, function()
		SetTransparency(0.97)
	end)

	return Button
end

end)() end,
    [5] = function()local wax,script,require=ImportGlobals(5)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
local Button_Component = require(Root.Components.Button)
local Signal = require(Root.Packages.Signal)

local New = Creator.New

local Dialog = {
	Window = nil,
}

function Dialog:Init(Window)
	Dialog.Window = Window
	return Dialog
end

function Dialog:Create()
	local NewDialog, Library = {
		Buttons = 0,
		Closing = Signal.new(),
		Closed = Signal.new()
	}, require(Root)

	NewDialog.TintFrame = New("TextButton", {
		Text = "",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Parent = Dialog.Window.Root,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
	})

	local TintMotor, TintTransparency = Creator.SpringMotor(1, NewDialog.TintFrame, "BackgroundTransparency", true)

	NewDialog.ButtonHolder = New("Frame", {
		Size = UDim2.new(1, -40, 1, -40),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 10),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	NewDialog.ButtonHolderFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 70),
		Position = UDim2.new(0, 0, 1, -70),
		ThemeTag = {
			BackgroundColor3 = "DialogHolder",
		},
	}, {
		New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			ThemeTag = {
				BackgroundColor3 = "DialogHolderLine",
			},
		}),
		NewDialog.ButtonHolder,
	})

	NewDialog.Title = New("TextLabel", {
		FontFace = Font.new(
			"rbxasset://fonts/families/GothamSSm.json",
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		),
		Text = "Dialog",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.fromOffset(20, 25),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	NewDialog.Scale = New("UIScale", {
		Scale = 1,
	})

	local ScaleMotor, Scale = Creator.SpringMotor(1.1, NewDialog.Scale, "Scale")

	NewDialog.Root = New("CanvasGroup", {
		Size = UDim2.fromOffset(300, 165),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		GroupTransparency = 1,
		Parent = NewDialog.TintFrame,
		ThemeTag = {
			BackgroundColor3 = "Dialog",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ThemeTag = {
				Color = "DialogBorder",
			},
		}),
		NewDialog.Scale,
		NewDialog.Title,
		NewDialog.ButtonHolderFrame,
	})

	local RootMotor, RootTransparency = Creator.SpringMotor(1, NewDialog.Root, "GroupTransparency")

	function NewDialog:Open()
		Library.DialogOpen = true
		NewDialog.Scale.Scale = 1.1
		TintTransparency(0.75)
		RootTransparency(0)
		Scale(1)
	end

	function NewDialog:Close()
		NewDialog.Closing:Fire()
		Library.DialogOpen = false
		TintTransparency(1)
		RootTransparency(1)
		Scale(1.1)
		NewDialog.Root.UIStroke:Destroy()
		task.wait(0.15)
		NewDialog.TintFrame:Destroy()
		NewDialog.Closed:Fire()
	end

	function NewDialog:Button(Title, Callback)
		NewDialog.Buttons = NewDialog.Buttons + 1
		Title = Title or "Button"
		Callback = Callback or function() end

		local Button = Button_Component("", NewDialog.ButtonHolder, true)
		Button.Title.Text = Title

		for _, Btn in next, NewDialog.ButtonHolder:GetChildren() do
			if Btn:IsA("TextButton") then
				Btn.Size = UDim2.new(1 / NewDialog.Buttons, -((NewDialog.Buttons - 1) * 10 / NewDialog.Buttons), 0, 32)
			end
		end

		Creator.AddSignal(Button.Frame.MouseButton1Click, function()
			Library:SafeCallback(Callback)
			pcall(function()
				NewDialog:Close()
			end)
		end)

		return Button
	end

	return NewDialog
end

return Dialog

end)() end,
    [6] = function()local wax,script,require=ImportGlobals(6)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
local New = Creator.New

return function(Title, Desc, Parent, Hover, Config)
	local Element = {
		CreatedAt = tick()
	}

	Config = typeof(Config) == "table" and Config or {}

	Element.TitleLabel = New("TextLabel", {
		Name = "ElementTitleLabel",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = Title,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
	 	TextXAlignment = Config.TitleAlignment or Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	}) :: TextLabel

	Element.DescLabel = New("TextLabel", {
		Name = "ElementDescLabel",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Desc,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Config.DescriptionAlignment or Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		ThemeTag = {
			TextColor3 = "SubText",
		},
	}) :: TextLabel

	Element.LabelHolder = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -28, 0, 0),
		ZIndex = 2,
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 13),
			PaddingTop = UDim.new(0, 13),
		}),
		Element.TitleLabel,
		Element.DescLabel,
	}) :: Frame

	Element.Border = New("UIStroke", {
		Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(0, 0, 0),
		ThemeTag = {
			Color = "ElementBorder",
		},
	}) :: UIStroke

	Element.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 0.89,
		BackgroundColor3 = Color3.fromRGB(130, 130, 130),
		Parent = Parent,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		LayoutOrder = 7,
		ThemeTag = {
			BackgroundColor3 = "Element",
			BackgroundTransparency = "ElementTransparency",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		Element.Border,
		Element.LabelHolder,
	}) :: TextButton

	function Element:SetTitle(Set)
		Element.TitleLabel.Text = Set
	end

	function Element:SetDesc(Set)
		if Set == nil then
			Set = ""
		end
		if Set == "" then
			Element.DescLabel.Visible = false
		else
			Element.DescLabel.Visible = true
		end
		Element.DescLabel.Text = Set
	end

	function Element:Destroy()
		Element.Frame:Destroy()
	end

	Element:SetTitle(Title)
	Element:SetDesc(Desc)

	if Hover then
		local Themes = Root.Themes
		local Motor, SetTransparency = Creator.SpringMotor(
			Creator.GetThemeProperty("ElementTransparency"),
			Element.Frame,
			"BackgroundTransparency",
			false,
			true
		)

		Creator.AddSignal(Element.Frame.MouseEnter, function()
			SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
		end)
		Creator.AddSignal(Element.Frame.MouseLeave, function()
			SetTransparency(Creator.GetThemeProperty("ElementTransparency"))
		end)
		Creator.AddSignal(Element.Frame.MouseButton1Down, function()
			SetTransparency(Creator.GetThemeProperty("ElementTransparency") + Creator.GetThemeProperty("HoverChange"))
		end)
		Creator.AddSignal(Element.Frame.MouseButton1Up, function()
			SetTransparency(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
		end)
	end

	return setmetatable(Element, {
		__newindex =  function(self, index, newvalue)
			if index == "Title" then
				Element:SetTitle(newvalue)
			elseif index == "Description" or index == "Desc" then
				Element:SetDesc(newvalue)
			end
			return rawset(self, index, newvalue)
		end
	})
end

end)() end,
    [7] = function()local wax,script,require=ImportGlobals(7)local ImportGlobals return (function(...)local Root = script.Parent.Parent

local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

local SoundService = game:GetService("SoundService")

local Notification = {}

function Notification:Init(GUI)
	Notification.Holder = New("Frame", {
		Position = UDim2.new(1, -30, 1, -30),
		Size = UDim2.new(0, 310, 1, -30),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Parent = GUI,
	}, {
		New("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 20),
		}),
	})
end

function Notification:New(Config)
	local NewNotification = {
		Closed = false,
	}

	Config.Title = Config.Title or "Title"
	Config.Content = Config.Content or "Content"
	Config.SubContent = Config.SubContent or ""
	Config.Duration = Config.Duration or nil
	Config.Buttons = Config.Buttons or {}
	Config.Sound = Config.Sound or {}

	Config.Sound.Parent = SoundService
	Config.Sound.PlayOnRemove = true

	NewNotification.AcrylicPaint = Acrylic.AcrylicPaint()

	NewNotification.Title = New("TextLabel", {
		Position = UDim2.new(0, 14, 0, 17),
		Text = Config.Title,
		RichText = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 13,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -12, 0, 12),
		TextWrapped = true,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	NewNotification.ContentLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Config.Content,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		TextWrapped = true,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	NewNotification.SubContentLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Config.SubContent,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextWrapped = true,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	NewNotification.LabelHolder = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 40),
		Size = UDim2.new(1, -28, 0, 0),
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
		}),
		NewNotification.ContentLabel,
		NewNotification.SubContentLabel,
	})

	NewNotification.CloseButton = New("TextButton", {
		Text = "",
		Position = UDim2.new(1, -14, 0, 13),
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
	}, {
		New("ImageLabel", {
			Image = require(script.Parent.Assets).Close,
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
	})

	NewNotification.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(1, 0),
	}, {
		NewNotification.AcrylicPaint.Frame,
		NewNotification.Title,
		NewNotification.CloseButton,
		NewNotification.LabelHolder,
	})

	if Config.Content == "" then
		NewNotification.ContentLabel.Visible = false
	end

	if Config.SubContent == "" then
		NewNotification.SubContentLabel.Visible = false
	end

	NewNotification.Holder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 200),
		Parent = Notification.Holder,
	}, {
		NewNotification.Root,
	})

	local RootMotor = Flipper.GroupMotor.new({
		Scale = 1,
		Offset = 60,
	})

	RootMotor:onStep(function(Values)
		NewNotification.Root.Position = UDim2.new(Values.Scale, Values.Offset, 0, 0)
	end)

	Creator.AddSignal(NewNotification.CloseButton.MouseButton1Click, function()
		NewNotification:Close()
	end)

	function NewNotification:Open()
		local ContentSize = NewNotification.LabelHolder.AbsoluteSize.Y
		NewNotification.Holder.Size = UDim2.new(1, 0, 0, 58 + ContentSize)

		if Config.Sound.SoundId then
			NewNotification.Sound = New("Sound", Config.Sound)

			if not NewNotification.Sound.IsLoaded then
				NewNotification.Sound.Loaded:Wait()
			end

			NewNotification.Sound:Destroy()
			NewNotification.Sound = nil
		end

		RootMotor:setGoal({
			Scale = Spring(0, { frequency = 5 }),
			Offset = Spring(0, { frequency = 5 }),
		})
	end

	function NewNotification:Close()
		if not NewNotification.Closed then
			NewNotification.Closed = true
			task.spawn(function()
				RootMotor:setGoal({
					Scale = Spring(1, { frequency = 5 }),
					Offset = Spring(60, { frequency = 5 }),
				})
				task.wait(0.4)
				if require(Root).UseAcrylic then
					NewNotification.AcrylicPaint.Model:Destroy()
				end
				NewNotification.Holder:Destroy()
			end)
		end
	end

	NewNotification:Open()
	if Config.Duration then
		task.delay(Config.Duration, function()
			NewNotification:Close()
		end)
	end
	return NewNotification
end

return Notification

end)() end,
    [8] = function()local wax,script,require=ImportGlobals(8)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New

return function(Title, Parent)
	local Section = {}

	Section.Layout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
	})

	Section.Container = New("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1,
	}, {
		Section.Layout,
	})

	Section.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 7,
		Parent = Parent,
	}, {
		New("TextLabel", {
			Name = "SectionTitleLabel",
			RichText = true,
			Text = Title,
			TextTransparency = 0,
			FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			TextSize = 18,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -16, 0, 18),
			Position = UDim2.fromOffset(0, 2),
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		Section.Container,
	})

	Creator.AddSignal(Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Section.Container.Size ~= UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y) or Section.Root.Size ~= UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y + 25) then
			Section.Container.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y)
			Section.Root.Size = UDim2.new(1, 0, 0, Section.Layout.AbsoluteContentSize.Y + 25)
		end
	end)

	return Section
end
end)() end,
    [9] = function()local wax,script,require=ImportGlobals(9)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local Components = Root.Components

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = 0,
	TabCount = 0,
}

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:IsHorizontal()
	local Alignment = TabModule.Window.Alignment
	return Alignment == "Top" or Alignment == "Bottom"
end

function TabModule:GetCurrentTabPos()
	local ItemPadding = 4
	local Horizontal = TabModule:IsHorizontal()

	local Position = 0
	for TabIndex = 1, TabModule.TabCount do
		if TabIndex == TabModule.SelectedTab then
			break
		end

		local TabObject = TabModule.Tabs[TabIndex]
		if TabObject and TabObject.Frame.Visible then
			Position += (Horizontal and TabObject.Frame.AbsoluteSize.X or 34) + ItemPadding
		end
	end

	return Position
end

function TabModule:GetCurrentTabSize()
	local Horizontal = TabModule:IsHorizontal()
	local TabObject = TabModule.Tabs[TabModule.SelectedTab]

	if not TabObject then
		return Horizontal and 40 or 34
	end

	return Horizontal and TabObject.Frame.AbsoluteSize.X or 34
end

function TabModule:ApplyPillShape(Tab, Alignment)
	local Horizontal = Alignment == "Top" or Alignment == "Bottom"

	local TextLabel = Tab.Frame:FindFirstChild("TabTitleLabel")
	local IconLabel = Tab.Frame:FindFirstChild("IconLabel")

	if Horizontal then
		TextLabel.Position = UDim2.new(0, 28, 0.5, 0)
		TextLabel.Size = UDim2.new(0, 0, 1, 0)
		TextLabel.AutomaticSize = Enum.AutomaticSize.X
		TextLabel.TextXAlignment = "Left"

		IconLabel.Position = UDim2.new(0, 10, 0.5, 0)

		Tab.Frame.Size = UDim2.new(0, 40, 1, 0)
		Tab.Frame.AutomaticSize = Enum.AutomaticSize.X

		if not Tab.Frame:FindFirstChild("UIPadding") then
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 16),
				Parent = Tab.Frame,
			})
		end
	else
		TextLabel.Position = UDim2.new(0, 30, 0.5, 0)
		TextLabel.Size = UDim2.new(1, -38, 1, 0)
		TextLabel.AutomaticSize = Enum.AutomaticSize.None
		TextLabel.TextXAlignment = "Left"

		IconLabel.Position = UDim2.new(0, 8, 0.5, 0)

		Tab.Frame.Size = UDim2.new(1, 0, 0, 34)
		Tab.Frame.AutomaticSize = Enum.AutomaticSize.None

		local ExistingPadding = Tab.Frame:FindFirstChild("UIPadding")
		if ExistingPadding then
			ExistingPadding:Destroy()
		end
	end
end

function TabModule:RebuildForAlignment()
	local Alignment = TabModule.Window.Alignment

	for _, Tab in next, TabModule.Tabs do
		TabModule:ApplyPillShape(Tab, Alignment)
	end
end

function TabModule:New(Title, Icon, Parent)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
	}

	Icon = Icon:find("^rbxasset[://|id://]") == nil and Library.Utilities:GetIcon(Icon) or {
		Image = Icon,
		ImageRectOffset = Vector2.zero,
		ImageRectSize = Vector2.zero
	}

	local Alignment = Window.Alignment
	local Horizontal = Alignment == "Top" or Alignment == "Bottom"

	local TextLabel = New("TextLabel", {
		Name = "TabTitleLabel",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 30, 0.5, 0),
		Text = Title,
		RichText = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0,
		FontFace = Font.new(
			"rbxasset://fonts/families/GothamSSm.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),
		TextSize = 12,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -38, 1, 0),
		AutomaticSize = Horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local IconLabel = New("ImageLabel", {
		Name = "IconLabel",
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 8, 0.5, 0),
		BackgroundTransparency = 1,
		ImageRectOffset = Icon and Icon.ImageRectOffset or Vector2.zero,
		ImageRectSize = Icon and Icon.ImageRectSize or Vector2.zero,
		Image = Icon and Icon.Image or nil,
		ThemeTag = {
			ImageColor3 = "Text",
		},
	})

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		TextLabel,
		IconLabel,
	})

	TabModule:ApplyPillShape(Tab, Alignment)

	local ContainerLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.ContainerFrame = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Window.ContainerHolder,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		ContainerLayout,
		New("UIPadding", {
			PaddingRight = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
		}),
	})

	Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Tab.ContainerFrame.CanvasSize ~= UDim2.fromOffset(0, ContainerLayout.AbsoluteContentSize.Y + 2) then
			Tab.ContainerFrame.CanvasSize = UDim2.fromOffset(0, ContainerLayout.AbsoluteContentSize.Y + 2)
		end
	end)

	Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(1, Tab.Frame, "BackgroundTransparency")

	Creator.AddSignal(Tab.Frame.MouseEnter, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseLeave, function()
		Tab.SetTransparency(Tab.Selected and 0.89 or 1)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
		Tab.SetTransparency(0.92)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	Tab.Container = Tab.ContainerFrame
	Tab.ScrollFrame = Tab.Container

	function Tab:Section(SectionTitle)
		if typeof(SectionTitle) == "table" then
			SectionTitle = SectionTitle.Title or SectionTitle.Name or "Section"
		end

		local Section = {
			Type = "Section"
		}

		local SectionFrame = require(Components.Section)(SectionTitle, Tab.Container)
		Section.Container = SectionFrame.Container
		Section.ScrollFrame = Tab.Container

		setmetatable(Section, Elements)
		return Section
	end

	Tab.CreateSection = Tab.Section
	Tab.AddSection = Tab.Section

	setmetatable(Tab, Elements)
	return Tab
end

function TabModule:SelectTab(Tab)
	local Window = TabModule.Window

	TabModule.SelectedTab = Tab

	for _, TabObject in next, TabModule.Tabs do
		TabObject.SetTransparency(1)
		TabObject.Selected = false
	end

	TabModule.Tabs[Tab].SetTransparency(0.89)
	TabModule.Tabs[Tab].Selected = true

	Window.TabDisplay.Text = TabModule.Tabs[Tab].Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	if TabModule:IsHorizontal() then
		Window.SelectorSizeMotor:setGoal(Spring(TabModule:GetCurrentTabSize(), { frequency = 6 }))
	end

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim

		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))

		task.wait(0.12)

		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end

		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))

		task.wait(0.12)

		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

return TabModule
end)() end,
    [10] = function()local wax,script,require=ImportGlobals(10)local ImportGlobals return (function(...)local TextService = game:GetService("TextService")
local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local New = Creator.New

return function(Parent, Acrylic)
	local Textbox = {}

	Acrylic = Acrylic or false

	Textbox.Input = New("TextBox", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(10, 0),
		ThemeTag = {
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
	})

	Textbox.Container = New("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -12, 1, 0),
	}, {
		Textbox.Input,
	})

	Textbox.Indicator = New("Frame", {
		Size = UDim2.new(1, -4, 0, 1),
		Position = UDim2.new(0, 2, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = Acrylic and 0.5 or 0,
		ThemeTag = {
			BackgroundColor3 = Acrylic and "InputIndicator" or "DialogInputLine",
		},
	})

	Textbox.Frame = New("Frame", {
		Size = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = Acrylic and 0.9 or 0,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = Acrylic and "Input" or "DialogInput",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = Acrylic and 0.5 or 0.65,
			ThemeTag = {
				Color = Acrylic and "InElementBorder" or "DialogButtonBorder",
			},
		}),
		Textbox.Indicator,
		Textbox.Container,
	})

	local function Update()
		local PADDING = 2
		local Reveal = Textbox.Container.AbsoluteSize.X

		if not Textbox.Input:IsFocused() or Textbox.Input.TextBounds.X <= Reveal - 2 * PADDING then
			Textbox.Input.Position = UDim2.new(0, PADDING, 0, 0)
		else
			local Cursor = Textbox.Input.CursorPosition
			if Cursor ~= -1 then
				local subtext = string.sub(Textbox.Input.Text, 1, Cursor - 1)
				local width = TextService:GetTextSize(
					subtext,
					Textbox.Input.TextSize,
					Textbox.Input.Font,
					Vector2.new(math.huge, math.huge)
				).X

				local CurrentCursorPos = Textbox.Input.Position.X.Offset + width
				if CurrentCursorPos < PADDING then
					Textbox.Input.Position = UDim2.fromOffset(PADDING - width, 0)
				elseif CurrentCursorPos > Reveal - PADDING - 1 then
					Textbox.Input.Position = UDim2.fromOffset(Reveal - width - PADDING - 1, 0)
				end
			end
		end
	end

	task.spawn(Update)

	Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("Text"), Update)
	Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("CursorPosition"), Update)

	Creator.AddSignal(Textbox.Input.Focused, function()
		Update()
		Textbox.Indicator.Size = UDim2.new(1, -2, 0, 2)
		Textbox.Indicator.Position = UDim2.new(0, 1, 1, 0)
		Textbox.Indicator.BackgroundTransparency = 0
		Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = Acrylic and "InputFocused" or "DialogHolder" })
		Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = "Accent" })
	end)

	Creator.AddSignal(Textbox.Input.FocusLost, function()
		Update()
		Textbox.Indicator.Size = UDim2.new(1, -4, 0, 1)
		Textbox.Indicator.Position = UDim2.new(0, 2, 1, 0)
		Textbox.Indicator.BackgroundTransparency = 0.5
		Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = Acrylic and "Input" or "DialogInput" })
		Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = Acrylic and "InputIndicator" or "DialogInputLine" })
	end)

	return Textbox
end

end)() end,
    [11] = function()local wax,script,require=ImportGlobals(11)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local AddSignal = Creator.AddSignal

return function(Config)
	local TitleBar = {}

	local Library = require(Root)

	local function BarButton(Icon, Pos, Parent, Debounce, Callback)
		local Button = {
			Callback = Callback or function() end,
			OnDebounce = false
		}

		Button.Frame = New("TextButton", {
			Size = UDim2.new(0, 34, 1, -8),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Parent = Parent,
			Position = Pos,
			Text = "",
			ThemeTag = {
				BackgroundColor3 = "Text",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 7),
			}),
			New("ImageLabel", {
				Image = Icon,
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Name = "Icon",
				ThemeTag = {
					ImageColor3 = "Text",
				},
			}),
		})

		local Motor, SetTransparency = Creator.SpringMotor(1, Button.Frame, "BackgroundTransparency")

		AddSignal(Button.Frame.MouseEnter, function()
			SetTransparency(0.94)
		end)

		AddSignal(Button.Frame.MouseLeave, function()
			SetTransparency(1, true)
		end)

		AddSignal(Button.Frame.MouseButton1Down, function()
			SetTransparency(0.96)
		end)

		AddSignal(Button.Frame.MouseButton1Up, function()
			SetTransparency(0.94)
		end)

		AddSignal(Button.Frame.MouseButton1Click, function(...)
			if not Button.OnDebounce then
				Button.OnDebounce = true
				task.delay(Debounce, rawset, Button, "OnDebounce", false)
				Button.Callback(...)
			end
		end)

		return Button
	end

	TitleBar.Frame = New("Frame", {
		Active = true,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Parent = Config.Parent
	}, {
		New("Frame", {
			BackgroundTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			ThemeTag = {
				BackgroundColor3 = "TitleBarLine",
			}
		})
	})

	TitleBar.TitleHolder = New("Frame", {
		Size = UDim2.new(1, -16, 1, 0),
		Parent = TitleBar.Frame,
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	})

	TitleBar.Title = New("TextLabel", {
		RichText = true,
		Text = Config.Title,
		Parent = TitleBar.TitleHolder,
		FontFace = Font.new(
			"rbxasset://fonts/families/GothamSSm.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),
		TextSize = 12,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		}
	})

	TitleBar.SubTitle = New("TextLabel", {
		RichText = true,
		Text = Config.SubTitle,
		Parent = TitleBar.TitleHolder,
		TextTransparency = 0.4,
		FontFace = Font.new(
			"rbxasset://fonts/families/GothamSSm.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),
		TextSize = 12,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		}
	})

	TitleBar.CloseButton = BarButton(Library.Utilities:GetIcon("Close"), UDim2.new(1, -4, 0, 4), TitleBar.Frame, 0, function()
		Library.CreatedWindow:Dialog{
			Title = "Close",
			Content = "Are you sure you want to unload the interface?",
			Buttons = {
				{
					Title = "Yes",
					Callback = Library.Destroy,
				},
				{
					Title = "No",
				}
			}
		}
	end)

	TitleBar.MaxButton = BarButton(Library.Utilities:GetIcon("Max"), UDim2.new(1, -40, 0, 4), TitleBar.Frame, 0, function()
		Config.Window.Maximize(not Config.Window.Maximized)
	end)

	TitleBar.MinButton = BarButton(Library.Utilities:GetIcon("Min"), UDim2.new(1, -80, 0, 4), TitleBar.Frame, 0, function()
		Config.Window:Minimize()
	end)

	return TitleBar
end
end)() end,
    [12] = function()local wax,script,require=ImportGlobals(12)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)
local Signal = require(Root.Packages.Signal)
local Assets = require(script.Parent.Assets)
local Components = script.Parent

local Library = require(Root)

local UserInputService = Library.Utilities:Clone(game:GetService("UserInputService"))
local Mouse = Library.Utilities:Clone(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = Library.Utilities:Clone(game:GetService("Workspace")).CurrentCamera

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

return function(Config)
	assert(typeof(Config.Mobile) == "table", "Config key 'Mobile' must be a table!")
	assert(typeof(Config.Mobile.GetIcon) == "function", "Mobile Config key 'GetIcon' must be a function!")
	assert(typeof(Config.Mobile.Size) == "UDim2", "Mobile Config key 'Size' must be a UDim2!")

	local ValidAlignments = { Left = true, Right = true, Top = true, Bottom = true }

	local Window = {
		Minimized = false,
		OnMinimized = Signal.new(),
		PostMinimized = Signal.new(),
		Maximized = false,
		OnMaximized = Signal.new(),
		PostMaximized = Signal.new(),
		Size = Config.Size,
		MinSize = Config.MinSize,
		CurrentPos = 0,
		TabWidth = 0,
		Alignment = ValidAlignments[Config.Alignment] and Config.Alignment or "Left",
		Position = UDim2.fromOffset(
			Camera.ViewportSize.X / 2 - Config.Size.X.Offset / 2,
			Camera.ViewportSize.Y / 2 - Config.Size.Y.Offset / 2
		),
	}

	local Dragging, DragInput, MousePos, StartPos = false
	local Resizing, ResizePos = false
	local MinimizeNotif = false
	local IsDraggingHideButton, DragInputHideButton, DragStart, DragStartPos = false

	Window.AcrylicPaint = Acrylic.AcrylicPaint()
	Window.AcrylicPaint.Frame.AnchorPoint = Vector2.new(0, 0)
	Window.AcrylicPaint.Frame.Position = UDim2.fromScale(0, 0)
	Window.AcrylicPaint.Frame.Size = UDim2.fromScale(1, 1)
	Window.TabWidth = Config.TabWidth

	local Alignment = Window.Alignment
	local Horizontal = Alignment == "Top" or Alignment == "Bottom"
	local Reversed = Alignment == "Right" or Alignment == "Bottom"

	local TitleBarHeight = 42
	local OuterPadding = 12
	local EdgeInset = 6
	local LeftInset = 14
	local RowHeight = 44
	local SearchBoxSize = Horizontal and 34 or 28
	local SearchRowWidth = 170

	local function ComputeLayout(ForAlignment)
		local IsHorizontal = ForAlignment == "Top" or ForAlignment == "Bottom"
		local IsReversed = ForAlignment == "Right" or ForAlignment == "Bottom"
		local BoxSize = IsHorizontal and 34 or 28

		local TabFramePos, TabFrameSize
		if IsHorizontal then
			TabFrameSize = UDim2.new(1, -OuterPadding * 2, 0, RowHeight)
			TabFramePos = IsReversed and UDim2.new(0, OuterPadding, 1, -RowHeight - 8) or UDim2.new(0, OuterPadding, 0, TitleBarHeight + 12)
		else
			TabFrameSize = UDim2.new(0, Window.TabWidth, 1, -145)
			TabFramePos = ForAlignment == "Right" and UDim2.new(1, -OuterPadding - EdgeInset - Window.TabWidth, 0, 54) or UDim2.new(0, OuterPadding, 0, 54)
		end

		local TabDisplayPos, TabDisplaySize, ContainerPos, ContainerSize

		if ForAlignment == "Left" then
			TabDisplayPos = UDim2.fromOffset(Window.TabWidth + 26, 56)
			TabDisplaySize = UDim2.new(1, -Window.TabWidth - 42, 0, 28)
			ContainerPos = UDim2.fromOffset(Window.TabWidth + 26, 90)
			ContainerSize = UDim2.new(1, -Window.TabWidth - 32, 1, -102)
		elseif ForAlignment == "Right" then
			TabDisplayPos = UDim2.fromOffset(26, 56)
			TabDisplaySize = UDim2.new(1, -Window.TabWidth - 42 - EdgeInset, 0, 28)
			ContainerPos = UDim2.fromOffset(26, 90)
			ContainerSize = UDim2.new(1, -Window.TabWidth - 32 - EdgeInset, 1, -102)
		elseif ForAlignment == "Top" then
			TabDisplayPos = UDim2.fromOffset(26, TitleBarHeight + RowHeight + 24)
			TabDisplaySize = UDim2.new(1, -42, 0, 28)
			ContainerPos = UDim2.fromOffset(26, TitleBarHeight + RowHeight + 58)
			ContainerSize = UDim2.new(1, -42, 1, -(TitleBarHeight + RowHeight + 70))
		else
			TabDisplayPos = UDim2.fromOffset(26, TitleBarHeight + 22)
			TabDisplaySize = UDim2.new(1, -42, 0, 28)
			ContainerPos = UDim2.fromOffset(26, TitleBarHeight + 56)
			ContainerSize = UDim2.new(1, -42, 1, -(TitleBarHeight + RowHeight + 68))
		end

		return {
			Horizontal = IsHorizontal,
			Reversed = IsReversed,
			SearchBoxSize = BoxSize,
			TabFramePos = TabFramePos,
			TabFrameSize = TabFrameSize,
			TabDisplayPos = TabDisplayPos,
			TabDisplaySize = TabDisplaySize,
			ContainerPos = ContainerPos,
			ContainerSize = ContainerSize,
			SelectorInset = IsHorizontal and (SearchRowWidth + 10 + LeftInset) or (BoxSize + 4 + 17),
		}
	end

	local Layout = ComputeLayout(Alignment)

	local Selector = New("Frame", {
		Size = Horizontal and UDim2.fromOffset(0, 3) or UDim2.fromOffset(3, 0),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		AnchorPoint = Horizontal and Vector2.new(0.5, Reversed and 0 or 1) or Vector2.new(Reversed and 1 or 0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	})

	local ResizeStartFrame = New("Frame", {
		Active = true,
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
	})

	Window.TabSearchBox = New("TextBox", {
		Size = Horizontal and UDim2.new(0, SearchRowWidth, 1, 0) or UDim2.new(1, -LeftInset, 0, Layout.SearchBoxSize),
		AnchorPoint = Horizontal and Vector2.new(0, 0.5) or Vector2.new(0, 0),
		Position = Horizontal and UDim2.new(0, LeftInset, 0.5, 0) or UDim2.fromOffset(LeftInset, 0),
		BackgroundTransparency = 0.89,
		BackgroundColor3 = Color3.fromRGB(130, 130, 130),
		PlaceholderText = "Search",
		ClearTextOnFocus = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 12,
		TextXAlignment = "Left",
		ClipsDescendants = true,
		ThemeTag = {
			BackgroundColor3 = "Element",
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "ElementBorder",
			},
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})

	Window.NoResultsLabel = New("TextLabel", {
		Text = "No results found",
		Visible = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 12,
		TextTransparency = 0.4,
		TextXAlignment = "Center",
		TextYAlignment = "Center",
		Size = Horizontal and UDim2.new(0, 160, 1, 0) or UDim2.new(1, 0, 0, 28),
		Position = Horizontal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(0, 4),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	Window.TabHolder = New("ScrollingFrame", {
		Size = Horizontal and UDim2.new(1, -SearchRowWidth - 10 - EdgeInset - LeftInset, 1, 0) or UDim2.new(1, -LeftInset, 1, -(Layout.SearchBoxSize + 4)),
		Position = Horizontal and UDim2.fromOffset(SearchRowWidth + 10 + LeftInset, 0) or UDim2.fromOffset(LeftInset, Layout.SearchBoxSize + 4),
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			FillDirection = Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			VerticalAlignment = Horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
		}),
		Window.NoResultsLabel,
	})

	local TabFrame = New("Frame", {
		Size = Layout.TabFrameSize,
		Position = Layout.TabFramePos,
		BackgroundTransparency = 1,
		ClipsDescendants = not Horizontal,
	}, {
		Window.TabSearchBox,
		Window.TabHolder,
		Selector,
	})

	Window.TabDisplay = New("TextLabel", {
		RichText = true,
		Text = "Tab",
		TextTransparency = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 28,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = Layout.TabDisplaySize,
		Position = Layout.TabDisplayPos,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Window.ContainerHolder = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerAnim = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerCanvas = New("Frame", {
		Size = Layout.ContainerSize,
		Position = Layout.ContainerPos,
		BackgroundTransparency = 1,
	}, {
		Window.ContainerAnim,
		Window.ContainerHolder
	})

	Window.Root = New("Frame", {
		Active = true,
		BackgroundTransparency = 1,
		Size = Window.Size,
		Position = Window.Position,
		Parent = Config.Parent,
	}, {
		Window.AcrylicPaint.Frame,
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
		ResizeStartFrame,
	})

local AccountInfo = Instance.new("Frame")
local AvatarFrame = Instance.new("Frame")
local AvatarImage = Instance.new("ImageLabel")
local InfoFrame = Instance.new("Frame")
local UsernameLabel = Instance.new("TextLabel")
local TypeLabel = Instance.new("TextLabel")
local ExpiryLabel = Instance.new("TextLabel")

local LocalPlayer = game:GetService("Players").LocalPlayer

AccountInfo.Name = "AccountInfo"
AccountInfo.Parent = Window.Root
AccountInfo.BackgroundTransparency = 1
AccountInfo.BorderSizePixel = 0
AccountInfo.AnchorPoint = Vector2.new(0, 1)
AccountInfo.Position = UDim2.new(0, 16, 1, -11)
AccountInfo.Size = UDim2.new(0, 150, 0, 66)

AvatarFrame.Name = "AvatarFrame"
AvatarFrame.Parent = AccountInfo
AvatarFrame.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
AvatarFrame.BorderSizePixel = 0
AvatarFrame.AnchorPoint = Vector2.new(0, 0.5)
AvatarFrame.Position = UDim2.new(0, 0, 0.5, 0)
AvatarFrame.Size = UDim2.new(0, 40, 0, 40)

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarFrame

AvatarImage.Name = "AvatarImage"
AvatarImage.Parent = AvatarFrame
AvatarImage.BackgroundTransparency = 1
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.Position = UDim2.new(0, 0, 0, 0)

pcall(function()
    if LocalPlayer then
        AvatarImage.Image =
            "rbxthumb://type=AvatarHeadShot&id="
            .. LocalPlayer.UserId
            .. "&w=48&h=48"
    end
end)

InfoFrame.Name = "Info"
InfoFrame.Parent = AccountInfo
InfoFrame.BackgroundTransparency = 1
InfoFrame.AnchorPoint = Vector2.new(0, 0.5)
InfoFrame.Position = UDim2.new(0, 48, 0.5, 0)
InfoFrame.Size = UDim2.new(1, -52, 1, 0)

UsernameLabel.Name = "Username"
UsernameLabel.Parent = InfoFrame
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Position = UDim2.new(0, 0, 0, 0)
UsernameLabel.Size = UDim2.new(1, 0, 0, 18)
UsernameLabel.Font = Enum.Font.GothamBold
UsernameLabel.TextSize = 14
UsernameLabel.TextScaled = true
UsernameLabel.Text =
    LocalPlayer
    and LocalPlayer.Name
    or "Player"

UsernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.TextWrapped = true

TypeLabel.Name = "Type"
TypeLabel.Parent = InfoFrame
TypeLabel.BackgroundTransparency = 1
TypeLabel.Position = UDim2.new(0, 0, 0, 18)
TypeLabel.Size = UDim2.new(1, 0, 0, 12)
TypeLabel.Font = Enum.Font.Gotham
TypeLabel.TextSize = 12
TypeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TypeLabel.TextXAlignment = Enum.TextXAlignment.Left
TypeLabel.TextWrapped = true

ExpiryLabel.Name = "Expiry"
ExpiryLabel.Parent = InfoFrame
ExpiryLabel.BackgroundTransparency = 1
ExpiryLabel.Position = UDim2.new(0, 0, 0, 33)
ExpiryLabel.Size = UDim2.new(1, 0, 0, 30)
ExpiryLabel.Font = Enum.Font.Gotham
ExpiryLabel.TextSize = 12
ExpiryLabel.Text = "Key expires: --"
ExpiryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ExpiryLabel.TextXAlignment = Enum.TextXAlignment.Left
ExpiryLabel.TextWrapped = true
ExpiryLabel.TextYAlignment = Enum.TextYAlignment.Top

local function IsPremium()
    return shared.JD_IS_PREMIUM == true
end

local function GetExpiresAt()
    return tonumber(shared.JD_EXPIRES_AT)
end

local function FormatDuration(sec)
    if not sec or sec <= 0 then
        return "Expired"
    end

    local days = math.floor(sec / 86400)
    sec = sec - days * 86400

    local hours = math.floor(sec / 3600)
    sec = sec - hours * 3600

    local mins = math.floor(sec / 60)
    local secs = math.floor(sec - mins * 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

task.spawn(function()
    while AccountInfo.Parent do
        TypeLabel.Text =
            "Type: "
            .. (IsPremium() and "Premium" or "Standard")

        local expires = GetExpiresAt()
        local remaining

        if type(expires) == "number" then
            remaining = expires - os.time()
        end

        if remaining and remaining > 0 then
            ExpiryLabel.Text =
                "Key expires in: "
                .. FormatDuration(remaining)
        else
            ExpiryLabel.Text = "Key expires in: --"
        end

        task.wait(1)
    end
end)

	Window.HideButton = New("ImageButton", {
		Visible = Library.Utilities:GetOS() == "Mobile",
		Size = Config.Mobile.Size,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -Config.Mobile.Size.X.Offset - 25, 0.5, -Config.Mobile.Size.Y.Offset / 2),
		Parent = Config.Parent,
		Image = Config.Mobile.GetIcon(false).Image,
		ImageRectOffset = Config.Mobile.GetIcon(false).ImageRectOffset,
		ImageRectSize = Config.Mobile.GetIcon(false).ImageRectSize
	})

	Window.TitleBar = require(script.Parent.TitleBar)({
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	if Library.UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.Root)
	end

	local SizeMotor = Flipper.GroupMotor.new({
		X = Window.Size.X.Offset,
		Y = Window.Size.Y.Offset,
	})

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(0)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	SizeMotor:onStep(function(values)
		Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
	end)

	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
	end)

	local SelectorInset = Layout.SelectorInset

	local LastValue = 0
	local LastTime = 0
	Window.SelectorPosMotor:onStep(function(Value)
		if Horizontal then
			Selector.Position = UDim2.new(0, Value + SelectorInset + Window.SelectorSizeMotor:getValue() / 2, Reversed and 0 or 1, 0)
		else
			Selector.Position = UDim2.new(Reversed and 1 or 0, 0, 0, Value + SelectorInset)
		end

		local Now = tick()
		local DeltaTime = Now - LastTime

		if not Horizontal and LastValue ~= nil then
			Window.SelectorSizeMotor:setGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 16))
			LastValue = Value
		end
		LastTime = Now
	end)

	Window.SelectorSizeMotor:onStep(function(Value)
		if Horizontal then
			Selector.Size = UDim2.new(0, Value, 0, 3)
			Selector.Position = UDim2.new(0, Window.SelectorPosMotor:getValue() + SelectorInset + Value / 2, Reversed and 0 or 1, 0)
		else
			Selector.Size = UDim2.new(0, 3, 0, Value)
		end
	end)

	Window.ContainerBackMotor:onStep(function(Value)
		Window.ContainerAnim.GroupTransparency = Value
	end)

	Window.ContainerPosMotor:onStep(function(Value)
		Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
	end)

	local OldSizeX
	local OldSizeY
	Window.Maximize = function(Value, NoPos, Instant)
		Window.OnMaximized:Fire(tick())

		Window.Maximized = Value
		Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Assets.Restore or Assets.Max

		if Value then
			OldSizeX = Window.Size.X.Offset
			OldSizeY = Window.Size.Y.Offset
		end
		local SizeX = Value and Camera.ViewportSize.X or OldSizeX
		local SizeY = Value and Camera.ViewportSize.Y or OldSizeY
		SizeMotor:setGoal({
			X = Flipper[Instant and "Instant" or "Spring"].new(SizeX, { frequency = 6 }),
			Y = Flipper[Instant and "Instant" or "Spring"].new(SizeY, { frequency = 6 }),
		})
		Window.Size = UDim2.fromOffset(SizeX, SizeY)

		if not NoPos then
			PosMotor:setGoal({
				X = Spring(Value and 0 or Window.Position.X.Offset, { frequency = 6 }),
				Y = Spring(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }),
			})
		end

		Window.PostMaximized:Fire(tick())
	end

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Dragging = true
			MousePos = Input.Position
			StartPos = Window.Root.Position

			if Window.Maximized then
				StartPos = UDim2.fromOffset(
					Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
					Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
				)
			end

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInput = Input
		end
	end)

	Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Resizing = true
			ResizePos = Input.Position
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			Window.Position = UDim2.fromOffset(StartPos.X.Offset + Delta.X, StartPos.Y.Offset + Delta.Y)
			PosMotor:setGoal({
				X = Instant(Window.Position.X.Offset),
				Y = Instant(Window.Position.Y.Offset),
			})

			if Window.Maximized then
				Window.Maximize(false, true, true)
			end
		end

		if
			(Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			and Resizing
		then
			local Delta = Input.Position - ResizePos
			local StartSize = Window.Size

			local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0) + Vector3.new(1, 1, 0) * Delta
			local TargetSizeClamped =
				Vector2.new(math.clamp(TargetSize.X, Window.MinSize.X, 2048), math.clamp(TargetSize.Y, Window.MinSize.Y, 2048))

			SizeMotor:setGoal({
				X = Flipper.Instant.new(TargetSizeClamped.X),
				Y = Flipper.Instant.new(TargetSizeClamped.Y),
			})
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
			if Library and Library.WindowSizeChanged then
				Library.WindowSizeChanged:Fire(Window.Size)
			end
		end
	end)

	Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		local NewCanvasSize = Horizontal
			and UDim2.fromOffset(Window.TabHolder.UIListLayout.AbsoluteContentSize.X, 0)
			or UDim2.fromOffset(0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)

		if Window.TabHolder.CanvasSize ~= NewCanvasSize then
			Window.TabHolder.CanvasSize = NewCanvasSize
		end
	end)

	function Window:Minimize()
		Window.Minimized = not Window.Minimized
		Window.Root.Visible = not Window.Minimized

		Window.OnMinimized:Fire(tick(), Window.Root.Visible)

		if not MinimizeNotif then
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or typeof(Library.MinimizeKey) == "string" and Library.MinimizeKey or Library.MinimizeKey.Name

			MinimizeNotif = true

			Library:Notify({
				Title = "Interface",
				Content = `Press {Library.Utilities:Prettify(Key)} to toggle the interface.`,
				Duration = 6
			})
		end
		if Library.Utilities:GetOS() == "Mobile" then
			local Icon = Config.Mobile.GetIcon(Window.Minimized)
			Window.HideButton.Image = Icon.Image
			Window.HideButton.ImageRectOffset = Icon.ImageRectOffset
			Window.HideButton.ImageRectSize = Icon.ImageRectSiz
		end
		Window.PostMinimized:Fire(tick(), Window.Root.Visible)
	end

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			type(Library.MinimizeKeybind) == "table"
			and Library.MinimizeKeybind.Type == "Keybind"
			and not UserInputService:GetFocusedTextBox()
		then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value or Input.KeyCode.Name == Library.MinimizeKeybind.Value.Name then
				Window:Minimize()
			end
		elseif (Input.KeyCode == Library.MinimizeKey or Input.KeyCode.Name == Library.MinimizeKey) and not UserInputService:GetFocusedTextBox() then
			Window:Minimize()
		end
	end)

	Creator.AddSignal(Window.HideButton.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			IsDraggingHideButton = true
			DragStart = Input.Position
			DragStartPos = Window.HideButton.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					IsDraggingHideButton = false
				end
			end)
		end
	end)

	Creator.AddSignal(Window.HideButton.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInputHideButton = Input
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Input == DragInputHideButton and IsDraggingHideButton then
		        local delta = Input.Position - DragStart
			Window.HideButton.Position = UDim2.new(DragStartPos.X.Scale, DragStartPos.X.Offset + delta.X, DragStartPos.Y.Scale, DragStartPos.Y.Offset + delta.Y)
		end
	end)

	if Library.Utilities:GetOS() == "Mobile" then
		Creator.AddSignal(Window.HideButton.TouchTap, function()
			Window.Minimized = not Window.Minimized
       			Window.Root.Visible = not Window.Minimized
			local Icon = Config.Mobile.GetIcon(Window.Minimized)
			Window.HideButton.Image = Icon.Image
			Window.HideButton.ImageRectOffset = Icon.ImageRectOffset
			Window.HideButton.ImageRectSize = Icon.ImageRectSize
		end)
	else
		Creator.AddSignal(Window.HideButton.MouseButton1Click, function()
			Window.Minimized = not Window.Minimized
       			Window.Root.Visible = not Window.Minimized
		end)
	end

	function Window:Destroy()
		if Library.UseAcrylic then
			Window.AcrylicPaint.Model:Destroy()
		end
		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()
		Dialog.Title.Text = Config.Title

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 60),
			BackgroundTransparency = 1,
			Parent = Dialog.Root,
			ClipsDescendants = false,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(300, 165),
			MaxSize = Vector2.new(620, math.huge),
			Parent = Dialog.Root,
		})

		Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
		if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
			Content.TextWrapped = true
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
		end

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()

		if Config.Yield then
			Dialog.Closed:Wait()
		end

		return Dialog
	end

	local TabModule = require(Components.Tab):Init(Window)

	function Window:SetAlignment(NewAlignment)
		if not ValidAlignments[NewAlignment] or NewAlignment == Window.Alignment then
			return
		end

		Window.Alignment = NewAlignment
		Alignment = NewAlignment
		Layout = ComputeLayout(NewAlignment)

		Horizontal = Layout.Horizontal
		Reversed = Layout.Reversed
		SelectorInset = Layout.SelectorInset

		Window.TabSearchBox.Size = Horizontal and UDim2.new(0, SearchRowWidth, 1, 0) or UDim2.new(1, -LeftInset, 0, Layout.SearchBoxSize)
		Window.TabSearchBox.AnchorPoint = Horizontal and Vector2.new(0, 0.5) or Vector2.new(0, 0)
		Window.TabSearchBox.Position = Horizontal and UDim2.new(0, LeftInset, 0.5, 0) or UDim2.fromOffset(LeftInset, 0)

		Window.NoResultsLabel.Size = Horizontal and UDim2.new(0, 160, 1, 0) or UDim2.new(1, 0, 0, 28)
		Window.NoResultsLabel.Position = Horizontal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(0, 4)

		Window.TabHolder.Size = Horizontal and UDim2.new(1, -SearchRowWidth - 10 - EdgeInset - LeftInset, 1, 0) or UDim2.new(1, -LeftInset, 1, -(Layout.SearchBoxSize + 4))
		Window.TabHolder.Position = Horizontal and UDim2.fromOffset(SearchRowWidth + 10 + LeftInset, 0) or UDim2.fromOffset(LeftInset, Layout.SearchBoxSize + 4)
		Window.TabHolder.ScrollingDirection = Horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
		Window.TabHolder.CanvasPosition = Vector2.new(0, 0)

		Window.TabHolder.UIListLayout.FillDirection = Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
		Window.TabHolder.UIListLayout.VerticalAlignment = Horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top

		TabFrame.Size = Layout.TabFrameSize
		TabFrame.Position = Layout.TabFramePos
		TabFrame.ClipsDescendants = not Horizontal

		Window.TabDisplay.Size = Layout.TabDisplaySize
		Window.TabDisplay.Position = Layout.TabDisplayPos

		Window.ContainerCanvas.Size = Layout.ContainerSize
		Window.ContainerCanvas.Position = Layout.ContainerPos

		Selector.Size = Horizontal and UDim2.fromOffset(0, 3) or UDim2.fromOffset(3, 0)
		Selector.AnchorPoint = Horizontal and Vector2.new(0.5, Reversed and 0 or 1) or Vector2.new(Reversed and 1 or 0, 0.5)

		TabModule:RebuildForAlignment()

		task.defer(function()
			local CurrentPos = TabModule:GetCurrentTabPos()
			local CurrentSize = TabModule:GetCurrentTabSize()

			LastValue = CurrentPos + 16
			LastTime = 0

			Window.SelectorPosMotor:setGoal(Instant(CurrentPos))
			Window.SelectorSizeMotor:setGoal(Instant(Horizontal and CurrentSize or 34))
		end)
	end

	function Window:GetAlignment()
		return Window.Alignment
	end

	local function TabMatchesQuery(Tab, Query)
		for _, Descendant in next, Tab.ContainerFrame:GetDescendants() do
			if
				(Descendant.Name == "ElementTitleLabel"
					or Descendant.Name == "ElementDescLabel"
					or Descendant.Name == "SectionTitleLabel")
				and string.find(string.lower(Descendant.Text), Query, 1, true)
			then
				return true
			end
		end
		return false
	end

	local function FilterTabs(Query)
		Query = string.lower(Query)

		if Query == "" then
			for _, Tab in next, TabModule.Tabs do
				Tab.Frame.Visible = true
			end
			Selector.Visible = true
			Window.NoResultsLabel.Visible = false
			return
		end

		local FirstMatch
		for TabIndex, Tab in next, TabModule.Tabs do
			local Matches = TabMatchesQuery(Tab, Query)
			Tab.Frame.Visible = Matches

			if Matches and not FirstMatch then
				FirstMatch = TabIndex
			end
		end

		Selector.Visible = FirstMatch ~= nil
		Window.NoResultsLabel.Visible = FirstMatch == nil

		if FirstMatch and not (TabModule.Tabs[TabModule.SelectedTab] and TabModule.Tabs[TabModule.SelectedTab].Frame.Visible) then
			TabModule:SelectTab(FirstMatch)
		end
	end

	Creator.AddSignal(Window.TabSearchBox:GetPropertyChangedSignal("Text"), function()
		FilterTabs(Window.TabSearchBox.Text)
	end)

	function Window:Tab(TabConfig)
		return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
	end

	function Window:AddTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:CreateTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 16
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end

end)() end,
    [13] = function()local wax,script,require=ImportGlobals(13)local ImportGlobals return (function(...)local Elements = {}

for _, Element in next, script:GetChildren() do
	Elements[#Elements + 1] = require(Element)
end

return Elements

end)() end,
    [14] = function()local wax,script,require=ImportGlobals(14)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Button"

function Element:New(Config)
	assert(Config.Title, "Button - Missing Title")
	Config.Callback = Config.Callback or function() end

	local ButtonFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)

	local ButtonIco = New("ImageLabel", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = ButtonFrame.Frame,
		ThemeTag = {
			ImageColor3 = "Text",
		}
	}) :: ImageLabel

	self.Library.Utilities.Icons:SetIcon(ButtonIco, "chevron-right")

	Creator.AddSignal(ButtonFrame.Frame.MouseButton1Click, function()
		if typeof(Config.Callback) == "function" then
			self.Library:SafeCallback(Config.Callback, Config.Value)
		end
	end)

	ButtonFrame.Instance = ButtonFrame

	return ButtonFrame
end

return Element

end)() end,
    [16] = function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)local UserInputService = game:GetService("UserInputService")
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
local Camera = game:GetService("Workspace").CurrentCamera

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Dropdown"

function Element:New(Idx, Config)
	local Library = self.Library

	local Dropdown = {
		Values = (function()
			local Idxes = {}

			for i,v in next, Config.Values or {} do
				Idxes[#Idxes + 1] = v
			end

			return Idxes
		end)(),
		Value = Config.Default or Config.Value,
		Multi = Config.Multi or false,
		AutoDeselect = Config.AutoDeselect or false,
		Searchable = Config.Searchable == nil or Config.Searchable,
		FocusSearch = Config.FocusSearch or true,
		SearchPlaceholder = Config.SearchPlaceholder or "Search...",
		Displayer = typeof(Config.Displayer) == "function" and Config.Displayer or function(Value)
			return typeof(Value) ~= "number" and tostring(Library.Utilities:Prettify(Value)) or Value
		end,
		CustomDisplayer = (typeof(Config.Displayer) == "function" and Config.Displayer and true) or false,
		Buttons = {},
		Opened = false,
		Type = "Dropdown",
		Callback = Config.Callback or function() end,
		Changed = Config.Changed or function() end
	}

	local DropdownFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Dropdown.SetTitle = DropdownFrame.SetTitle
	Dropdown.SetDesc = DropdownFrame.SetDesc

	local DropdownDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "Value",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local DropdownIco = New("ImageLabel", {
		Image = "rbxassetid://10709790948",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		}
	})

	local DropdownInner = New("TextButton", {
		Size = UDim2.fromOffset(160, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = DropdownFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "DropdownFrame"
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		DropdownIco,
		DropdownDisplay,
	})

	local DropdownListLayout = New("UIListLayout", {
		Padding = UDim.new(0, 3),
	})

	local DropdownNoResultsLabel = New("TextLabel", {
		Name = "DropdownNoResultsLabel",
		Text = "No results found",
		Visible = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextSize = 12,
		TextTransparency = 0.4,
		TextXAlignment = "Center",
		TextYAlignment = "Center",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	local DropdownScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -5, 1, Dropdown.Searchable and -40 or -10),
		Position = UDim2.fromOffset(5, Dropdown.Searchable and 40 or 5),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
	}, {
		DropdownListLayout,
		DropdownNoResultsLabel,
	})

	local DropdownHolderFrame = New("Frame", {
		Size = UDim2.fromScale(1, 0.6),
		ThemeTag = {
			BackgroundColor3 = "DropdownHolder",
		},
	}, {
		DropdownScrollFrame,
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "DropdownBorder",
			},
		}),
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.1,
		}),
	}) :: Frame

	local SearchableTextbox = require(Components.Textbox)(DropdownHolderFrame, true)
	SearchableTextbox.Frame.Visible = Dropdown.Searchable
	SearchableTextbox.Frame.AnchorPoint = Vector2.new(0.5, 0)
	SearchableTextbox.Frame.Position = UDim2.new(0.5, 0, 0, 5)
	SearchableTextbox.Frame.Size = UDim2.new(1, -5, 0, 32)
	SearchableTextbox.Input.PlaceholderText = Dropdown.SearchPlaceholder
	SearchableTextbox.Input.Text = ""

	local SearchBox = SearchableTextbox.Input

	local ButtonSelector_BuildList = New("Frame", {
		Size = UDim2.fromOffset(4, 14),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		Position = UDim2.fromOffset(-1, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		}
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	}) :: Frame

	local ButtonLabel_BuildList = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(10, 0),
		Name = "ButtonLabel",
		ThemeTag = {
			TextColor3 = "Text"
		}
	}) :: TextLabel

	local Button_BuildList = New("TextButton", {
		Size = UDim2.new(1, -5, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 23,
		Text = "",
		ThemeTag = {
			BackgroundColor3 = "DropdownOption"
		}
	}, {
		ButtonSelector_BuildList,
		ButtonLabel_BuildList,
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		})
	}) :: TextButton

	local DropdownHolderCanvas = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 300),
		Parent = self.Library.GUI,
		Visible = false,
	}, {
		DropdownHolderFrame,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
		}),
	})

	Library.OpenFrames[#Library.OpenFrames + 1] = DropdownHolderCanvas

	local function RecalculateListPosition()
		local Add = 0
		if Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y < DropdownHolderCanvas.AbsoluteSize.Y - 5 then
			Add = DropdownHolderCanvas.AbsoluteSize.Y
				- 5
				- (Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y)
				+ 40
		end
		DropdownHolderCanvas.Position =
			UDim2.fromOffset(DropdownInner.AbsolutePosition.X - 1, DropdownInner.AbsolutePosition.Y - 5 - Add)
	end

	local ListSizeX = 0
	local function RecalculateListSize()
		local Subtract = Dropdown.Searchable and 42 or 0
		local Add = Dropdown.Searchable and 35 or 0

		DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, math.min(392 - Subtract, DropdownListLayout.AbsoluteContentSize.Y + 10 + Add))
	end

	local function RecalculateCanvasSize()
		DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
	end

	local function RepopulateDropdownList()
		Dropdown:BuildDropdownList()
	end

	RecalculateListPosition()
	RecalculateListSize()

	Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPosition)
	Creator.AddSignal(SearchBox:GetPropertyChangedSignal("Text"), RepopulateDropdownList)

	local ScrollFrame = self.ScrollFrame
	function Dropdown:Open()
		Dropdown.Opened = true
		Dropdown.HighlightedIndex = nil
		ScrollFrame.ScrollingEnabled = false
		DropdownHolderCanvas.Visible = true
		DropdownHolderFrame:TweenSize(
			UDim2.fromScale(1, 1),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quart,
			.2
		)

		if Dropdown.Searchable then
			SearchBox.Text = ""

			if Dropdown.FocusSearch then
				SearchBox:CaptureFocus()
			end
		end
	end

	function Dropdown:Close()
		Dropdown.Opened = false
		Dropdown.HighlightedIndex = nil
		ScrollFrame.ScrollingEnabled = true
		DropdownHolderFrame.Size = UDim2.fromScale(1, 0.6)
		DropdownHolderCanvas.Visible = false

		if Dropdown.Searchable then
			SearchBox.Text = ""
			SearchBox:ReleaseFocus()
		end
	end

	Creator.AddSignal(DropdownInner.MouseButton1Click, function()
		Dropdown:Open()
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
			if
				Mouse.X < AbsPos.X
				or Mouse.X > AbsPos.X + AbsSize.X
				or Mouse.Y < (AbsPos.Y - 20 - 1)
				or Mouse.Y > AbsPos.Y + AbsSize.Y
			then
				Dropdown:Close()
			end
		end
	end)

	local function SetHighlightedIndex(NewIndex)
		local OrderedButtons = Dropdown.OrderedButtons or {}

		if Dropdown.HighlightedIndex and OrderedButtons[Dropdown.HighlightedIndex] then
			OrderedButtons[Dropdown.HighlightedIndex].Table:SetHighlight(false)
		end

		Dropdown.HighlightedIndex = NewIndex

		local Entry = NewIndex and OrderedButtons[NewIndex]
		if Entry then
			Entry.Table:SetHighlight(true)

			local ButtonPos = Entry.Button.Position.Y.Offset
			local ButtonSize = Entry.Button.AbsoluteSize.Y
			local ViewTop = DropdownScrollFrame.CanvasPosition.Y
			local ViewBottom = ViewTop + DropdownScrollFrame.AbsoluteSize.Y

			if ButtonPos < ViewTop then
				DropdownScrollFrame.CanvasPosition = Vector2.new(0, ButtonPos)
			elseif ButtonPos + ButtonSize > ViewBottom then
				DropdownScrollFrame.CanvasPosition = Vector2.new(0, ButtonPos + ButtonSize - DropdownScrollFrame.AbsoluteSize.Y)
			end
		end
	end

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if not Dropdown.Opened or Input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		local OrderedButtons = Dropdown.OrderedButtons or {}
		if #OrderedButtons == 0 then
			return
		end

		if Input.KeyCode == Enum.KeyCode.Down then
			local NewIndex = Dropdown.HighlightedIndex and math.min(Dropdown.HighlightedIndex + 1, #OrderedButtons) or 1
			SetHighlightedIndex(NewIndex)
		elseif Input.KeyCode == Enum.KeyCode.Up then
			local NewIndex = Dropdown.HighlightedIndex and math.max(Dropdown.HighlightedIndex - 1, 1) or #OrderedButtons
			SetHighlightedIndex(NewIndex)
		elseif Input.KeyCode == Enum.KeyCode.Return or Input.KeyCode == Enum.KeyCode.KeypadEnter then
			if Dropdown.HighlightedIndex and OrderedButtons[Dropdown.HighlightedIndex] then
				OrderedButtons[Dropdown.HighlightedIndex].Table:Select()

				if not Config.Multi then
					Dropdown:Close()
				end
			end
		end
	end)

	function Dropdown:Display()
		local Values = Dropdown.Values
		local Str = ""

		if Config.Multi then
			for Idx, Value in next, Values do
				if Dropdown.Value[Value] then
					Str = `{Str}{Dropdown.Displayer(Value)}, `
				end
			end
			Str = Str:sub(1, #Str - 2)
		else
			Str = Dropdown.Value and Dropdown.Displayer(Dropdown.Value) or ""
		end

		DropdownDisplay.Text = (Str == "" and "--" or Str)
	end

	function Dropdown:GetActiveValues()
		if Config.Multi then
			local Values = {}

			for Value, Bool in next, Dropdown.Value do
				Values[#Values + 1] = Value
			end

			return Values
		else
			return Dropdown.Value and 1 or 0
		end
	end

	local BuildGeneration = 0

	function Dropdown:BuildDropdownList()
		BuildGeneration += 1
		local ThisGeneration = BuildGeneration

		local Values = Dropdown.Values
		local Buttons = {}
		local OrderedButtons = {}

		Dropdown.HighlightedIndex = nil

		for _, Element in next, DropdownScrollFrame:GetChildren() do
			if not Element:IsA("UIListLayout") and Element ~= DropdownNoResultsLabel then
				Element:Destroy()
			end
		end

		local Count = 0

		for Idx, Value in next, Values do
			if ThisGeneration ~= BuildGeneration then
				return
			end

			Count += 1

			if Count % 30 == 0 then
				task.wait()

				if ThisGeneration ~= BuildGeneration then
					return
				end
			end

			if Dropdown.Searchable and SearchBox.Text ~= "" and not string.find(string.lower(Dropdown.Displayer(Value)), string.lower(SearchBox.Text), 1, true) then
				continue
			end

			local Table = {}
			local Selected

			local Button = Button_BuildList:Clone()
			local ButtonSelector, ButtonLabel = Button.Frame, Button.ButtonLabel

			Creator.AddThemeObject(Button, {
				BackgroundColor3 = "DropdownOption"
			})

			Creator.AddThemeObject(ButtonSelector, {
				BackgroundColor3 = "Accent",
			})

			Creator.AddThemeObject(ButtonLabel, {
				TextColor3 = "Text"
			})

			if Config.Multi then
				Selected = Dropdown.Value[Value]
			else
				Selected = Dropdown.Value == Value
			end

			local BackMotor, SetBackTransparency = Creator.SpringMotor(1, Button, "BackgroundTransparency")
			local SelMotor, SetSelTransparency = Creator.SpringMotor(1, ButtonSelector, "BackgroundTransparency")
			local SelectorSizeMotor = Flipper.SingleMotor.new(6)

			SelectorSizeMotor:onStep(function(value)
				ButtonSelector.Size = UDim2.new(0, 4, 0, value)
			end)

			Creator.AddSignal(Button.MouseEnter, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)

			Creator.AddSignal(Button.MouseLeave, function()
				SetBackTransparency(Selected and 0.89 or 1)
			end)

			Creator.AddSignal(Button.MouseButton1Down, function()
				SetBackTransparency(0.92)
			end)

			Creator.AddSignal(Button.MouseButton1Up, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)

			function Table:UpdateButton()
				if Config.Multi then
					Selected = Dropdown.Value[Value]
					if Selected then
						SetBackTransparency(0.89)
					end
				else
					Selected = Dropdown.Value == Value
					SetBackTransparency(Selected and 0.89 or 1)
				end

				SelectorSizeMotor:setGoal(Flipper.Spring.new(Selected and 14 or 6, { frequency = 6 }))
				SetSelTransparency(Selected and 0 or 1)
			end

			function Table:SetHighlight(Highlighted)
				if Highlighted then
					SetBackTransparency(0.85)
				else
					SetBackTransparency(Selected and 0.89 or 1)
				end
			end

			function Table:Select()
				local Try = not Selected

				if Dropdown:GetActiveValues() == 1 and not Try and not Config.AllowNull then
					return
				end

				if Config.Multi then
					Selected = Try
					Dropdown.Value[Value] = Selected and true or nil

					if typeof(Dropdown.Callback) == "function" then
						Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
					end
					if typeof(Dropdown.Changed) == "function" then
						Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
					end
				else
					Selected = Try
					Dropdown:SetValue(Selected and Value or nil)

					for _, OtherButton in next, Buttons do
						OtherButton:UpdateButton()
					end
				end

				Table:UpdateButton()
				Dropdown:Display()
			end

			ButtonLabel.InputBegan:Connect(function(Input)
				if
					Input.UserInputType == Enum.UserInputType.MouseButton1
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					Table:Select()
				end
			end)

			ButtonLabel.Text = Dropdown.Displayer(Value)
			Button.Parent = DropdownScrollFrame

			Table:UpdateButton()
			Dropdown:Display()

			Buttons[Button] = Table
			OrderedButtons[#OrderedButtons + 1] = { Button = Button, Table = Table, Value = Value }
		end

		if ThisGeneration ~= BuildGeneration then
			return
		end

		Dropdown.OrderedButtons = OrderedButtons
		DropdownNoResultsLabel.Visible = #OrderedButtons == 0

		ListSizeX = 0

		for Button, Table in next, Buttons do
			if Button.ButtonLabel then
				if Button.ButtonLabel.TextBounds.X > ListSizeX then
					ListSizeX = Button.ButtonLabel.TextBounds.X
				end
			end
		end

		ListSizeX = ListSizeX + 30

		RecalculateCanvasSize()
		RecalculateListSize()
	end

	function Dropdown:SetValues(NewValues)
		if NewValues then
			rawset(Dropdown, "Values", NewValues)
		end

		Dropdown:BuildDropdownList()
	end

	function Dropdown:OnChanged(Func)
		Dropdown.Changed = Func
		Library:SafeCallback(Func, Dropdown.Value, Dropdown.Value)
	end

	function Dropdown:SetValue(Val)
		if Dropdown.Multi then
			local nTable = {}

			for Value, Bool in next, Val do
				if table.find(Dropdown.Values, Value) then
					nTable[Value] = true
				end
			end

			rawset(Dropdown, "Value", nTable)
		else
			if not Val then
				rawset(Dropdown, "Value", nil)
			elseif table.find(Dropdown.Values, Val) then
				rawset(Dropdown, "Value", Val)
			end
		end

		Dropdown:BuildDropdownList()

		if typeof(Dropdown.Callback) == "function" then
			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
		end
		if typeof(Dropdown.Changed) == "function" then
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end
	end

	function Dropdown:Destroy()
		DropdownFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Dropdown:BuildDropdownList()
	Dropdown:Display()

	local Defaults = {}

	if type(Config.Default) == "table" then
		for _, Value in next, Config.Default do
			local Indx = table.find(Dropdown.Values, Value)

			if Indx then
				Defaults[#Defaults + 1] = Indx
			end
		end
		table.clear(Config.Default)
	elseif type(Config.Default) == "number" and Dropdown.Values[Config.Default] ~= nil then
		Defaults[#Defaults + 1] = Config.Default
	else
		local Indx = table.find(Dropdown.Values, Config.Default)
		if Indx then
			Defaults[#Defaults + 1] = Indx
		end
	end

	if next(Defaults) then
		for i = 1, #Defaults do
			local Index = Defaults[i]

			if Config.Multi then
				Dropdown.Value[Dropdown.Values[Index]] = true
			else
				Dropdown.Value = Dropdown.Values[Index]
				break
			end
		end

		Dropdown:BuildDropdownList()
		Dropdown:Display()
	end

	Library.Options[Idx] = Dropdown

	Dropdown.Instance = DropdownFrame

	return setmetatable(Dropdown, {
		__newindex = function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Dropdown.SetValue, Dropdown, newvalue)
			elseif index == "Values" or index == "List" then
				task.spawn(Dropdown.SetValues, Dropdown, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
end)() end,
    [18] = function()local wax,script,require=ImportGlobals(18)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local AddSignal = Creator.AddSignal
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Input"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Input - Missing Title")
	Config.Callback = Config.Callback or function() end

	local Input = {
		Value = Config.Default or Config.Value or "",
		Numeric = Config.Numeric or false,
		Finished = Config.Finished or false,
		Callback = Config.Callback or function(Value) end,
		ClearOnFocusLost = Config.ClearOnFocusLost or false,
		Type = "Input",
	}

	local InputFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)

	Input.SetTitle = InputFrame.SetTitle
	Input.SetDesc = InputFrame.SetDesc

	local Textbox = require(Components.Textbox)(InputFrame.Frame, true)
	Textbox.Frame.Position = UDim2.new(1, -10, 0.5, 0)
	Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
	Textbox.Frame.Size = UDim2.fromOffset(160, 30)
	Textbox.Input.Text = Config.Default or ""
	Textbox.Input.PlaceholderText = Config.Placeholder or ""

	local Box = Textbox.Input

	function Input:SetValue(Text)
		if Config.MaxLength and #Text > Config.MaxLength then
			Text = Text:sub(1, Config.MaxLength)
		end

		if Input.Numeric then
			if (not tonumber(Text)) and Text:len() > 0 then
				Text = Input.Value
			end
		end

		rawset(Input, "Value", Text)
		Box.Text = Text

		if typeof(Input.Callback) == "function" then
			Library:SafeCallback(Input.Callback, Input.Value)
		end
		if typeof(Input.Changed) == "function" then
			Library:SafeCallback(Input.Changed, Input.Value)
		end
	end

	if Input.Finished then
		AddSignal(Box.FocusLost, function(enter: boolean, input: InputObject)
			if not enter then
				return
			end

			Input:SetValue(Box.Text)

			if Config.ClearOnFocusLost then
				Box.Text = ""
			end
		end)
	else
		AddSignal(Box:GetPropertyChangedSignal("Text"), function()
			Input:SetValue(Box.Text)
		end)
	end

	function Input:OnChanged(Func)
		Input.Changed = Func
		Library:SafeCallback(Func, Input.Value, Input.Value)
	end

	function Input:Destroy()
		InputFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Library.Options[Idx] = Input

	Input.Instance = InputFrame

	return setmetatable(Input, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Input.SetValue, Input, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element

end)() end,
    [20] = function()local wax,script,require=ImportGlobals(20)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Paragraph"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Paragraph - Missing Title")
	Config.Content = Config.Content or ""

	local Paragraph = {
		Value = Config.Content,
		Callback = Config.Callback or function(Value: string) end,
		Type = "Paragraph",
	}

	local ParagraphFrame = require(Components.Element)(Config.Title, Paragraph.Value, self.Container, false, {
		TitleAlignment = Config.TitleAlignment == "Middle" and "Center" or Config.TitleAlignment,
		DescriptionAlignment = Config.ContentAlignment == "Middle" and "Center" or Config.ContentAlignment
	})

	ParagraphFrame.Frame.BackgroundTransparency = 0.92
	ParagraphFrame.Border.Transparency = 0.6

	function Paragraph:OnChanged(Func)
		Paragraph.Changed = Func
		Library:SafeCallback(Func, Paragraph.Value, Paragraph.Value)
	end

	function Paragraph:SetTitle(Value)
		ParagraphFrame:SetTitle(tostring(Value or ""))
	end

	function Paragraph:SetDesc(Value)
		Paragraph:SetContent(Value)
	end

	function Paragraph:Set(Config)
		if typeof(Config) ~= "table" then
			return
		end

		if Config.Title ~= nil then
			Paragraph:SetTitle(Config.Title)
		end

		local Desc = Config.Desc
		if Desc == nil then
			Desc = Config.Content
		end

		if Desc ~= nil then
			Paragraph:SetDesc(Desc)
		end
	end

	function Paragraph:SetContent(Value)
		Value = Value or ""
		rawset(Paragraph, "Value", Value)

		ParagraphFrame:SetDesc(Value)

		ParagraphFrame.Frame.BackgroundTransparency = 0.92
		ParagraphFrame.Border.Transparency = 0.6

		if typeof(Paragraph.Callback) == "function" then
			Library:SafeCallback(Paragraph.Callback, Paragraph.Value)
		end
		if typeof(Paragraph.Changed) == "function" then
			Library:SafeCallback(Paragraph.Changed, Paragraph.Value)
		end
	end

	function Paragraph:SetValue(Value)
		Paragraph:SetContent(Value)
	end

	function Paragraph:Destroy()
		ParagraphFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Paragraph:SetValue(Paragraph.Value)

	Library.Options[Idx] = Paragraph

	Paragraph.Instance = ParagraphFrame

	return setmetatable(Paragraph, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Paragraph.SetValue, Paragraph, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})

end

return Element

end)() end,
    [22] = function()local wax,script,require=ImportGlobals(22)local ImportGlobals return (function(...)local TweenService, UserInputService = game:GetService("TweenService"), game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Toggle"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Toggle - Missing Title")

	local Toggle = {
		Value = Config.Default or Config.Value or false,
		Callback = Config.Callback or function(Value) end,
		Type = "Toggle",
	}

local ToggleFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)

ToggleFrame.TitleLabel.Size = UDim2.new(1, -54, 0, 14)
ToggleFrame.DescLabel.Size = UDim2.new(1, -54, 0, 14)

	Toggle.SetTitle = ToggleFrame.SetTitle
	Toggle.SetDesc = ToggleFrame.SetDesc

	local ToggleCircle = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 2, 0.5, 0),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ImageTransparency = 0.5,
		ThemeTag = {
			ImageColor3 = "ToggleSlider",
		},
	}) :: ImageLabel

	local ToggleBorder = New("UIStroke", {
		Transparency = 0.5,
		ThemeTag = {
			Color = "ToggleSlider",
		},
	})

	local ToggleSlider = New("Frame", {
		Size = UDim2.fromOffset(36, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = ToggleFrame.Frame,
		BackgroundTransparency = 1,
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 9),
		}),
		ToggleBorder,
		ToggleCircle,
	}) :: Frame

	function Toggle:OnChanged(Func)
		Toggle.Changed = Func
		Library:SafeCallback(Func, Toggle.Value, Toggle.Value)
	end

	function Toggle:SetValue(Value)
		Value = not not Value

		rawset(Toggle, "Value", Value)

		Creator.OverrideTag(ToggleBorder, { Color = Toggle.Value and "Accent" or "ToggleSlider" })
		Creator.OverrideTag(ToggleCircle, { ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider" })

		ToggleCircle:TweenPosition(
			UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			.25,
			true
		)

		TweenService:Create(
			ToggleSlider,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundTransparency = Toggle.Value and 0 or 1 }
		):Play()

		ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5

		if typeof(Toggle.Callback) == "function" then
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
		end
		if typeof(Toggle.Changed) == "function" then
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end
	end

	function Toggle:Destroy()
		ToggleFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
		Toggle:SetValue(not Toggle.Value)
	end)

	Toggle.Keybind = setmetatable({}, {
		__call = function(_, self, Idx, Config)
			local Keybind = {
				Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
				Toggled = false,
				Mode = Config.Mode or "Toggle",
				Type = "Keybind",
				Callback = Config.Callback or function(Value) end,
				ChangedCallback = Config.ChangedCallback or function(New) end,
				Instance = nil
			}

			local Picking = false

			local KeybindDisplayLabel = New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = Library.Utilities:Prettify(Keybind.Value),
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(0, 0, 0, 14),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			})

			local KeybindDisplayFrame: TextButton = New("TextButton", {
				Size = UDim2.fromOffset(0, 30),
				Position = UDim2.new(1, -10, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 0.9,
				Parent = ToggleFrame.Frame,
				AutomaticSize = Enum.AutomaticSize.X,
				ThemeTag = {
					BackgroundColor3 = "Keybind",
				},
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, 5),
				}),
				New("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
				New("UIStroke", {
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					ThemeTag = {
						Color = "InElementBorder",
					},
				}),
				KeybindDisplayLabel
			})

			Keybind.Instance = setmetatable({
				CreatedAt = tick()
			}, {
				__index = function(self, idx)
					if rawget(self, idx) then
						return rawget(self, idx)
					else
						return KeybindDisplayFrame[idx]
					end
				end
			})

			local function UpdateTogglePosition()
				ToggleSlider.Position = UDim2.new(1, KeybindDisplayFrame.Position.X.Offset - KeybindDisplayFrame.AbsoluteSize.X - 10, 0.5, 0)
			end

			function Keybind:GetState()
				if UserInputService:GetFocusedTextBox() and self.Mode ~= "Always" then
					return false
				end

				if self.Mode == "Always" then
					return true
				elseif self.Mode == "Hold" then
					if self.Value == "None" then
						return false
					end

					local Key = self.Value

					if Key == "LeftMousebutton" or Key == "RightMousebutton" then
						return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
							or Key == "RightMousebutton"
								and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					else
						return UserInputService:IsKeyDown(Enum.KeyCode[self.Value])
					end
				else
					return self.Toggled
				end
			end

			function Keybind:SetValue(Key, Mode)
				Key = Key or self.Value
				Mode = Mode or self.Mode

				self.Value = Key
				self.Mode = Mode

				KeybindDisplayLabel.Text = Library.Utilities:Prettify(self.Value)
			end

			function Keybind:OnClick(Callback)
				self.Clicked = Callback
			end

			function Keybind:OnChanged(Callback)
				self.Changed = Callback
				Library:SafeCallback(Callback, self.Value, self.Value)
			end

			function Keybind:DoClick()
				Toggle:SetValue(not Toggle.Value)

				if typeof(self.Callback) == "function" then
					Library:SafeCallback(self.Callback, self.Value)
				end
				if typeof(self.Clicked) == "function" then
					Library:SafeCallback(self.Clicked, self.Value)
				end
			end

			function Keybind:Destroy()
				KeybindDisplayFrame.Size = UDim2.new()
				KeybindDisplayFrame.Position = UDim2.new()
				KeybindDisplayFrame:Destroy()
				Library.Options[Idx] = nil
			end

			Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
				if
					Input.UserInputType == Enum.UserInputType.MouseButton1
					or Input.UserInputType == Enum.UserInputType.Touch
				then
					Picking = true
					local PreviousLabel = KeybindDisplayLabel.Text
					KeybindDisplayLabel.Text = "..."

					task.wait(0.2)

					UserInputService.InputBegan:Once(function(Input)
						local Key

						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Key = Input.KeyCode.Name
						elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
							Key = "LeftMousebutton"
						elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
							Key = "RightMousebutton"
						end

						if Key == "Escape" then
							Picking = false
							KeybindDisplayLabel.Text = PreviousLabel
							return
						end

						UserInputService.InputEnded:Once(function(Input)
							if (Input.KeyCode.Name == Key
								or Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2)
								and not Library.Unloaded
							then
								Picking = false

								Keybind:SetValue(Key)

								Library:SafeCallback(self.ChangedCallback, Input.KeyCode or Input.UserInputType)
								Library:SafeCallback(self.Changed, Input.KeyCode or Input.UserInputType)
							end
						end)
					end)
				end
			end)

			Creator.AddSignal(UserInputService.InputBegan, function(Input)
				if not Picking and not UserInputService:GetFocusedTextBox() then
					if Keybind.Mode == "Toggle" then
						local Key = Keybind.Value

						if Key == "LeftMousebutton" or Key == "RightMousebutton" then
							if
								Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
								or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
							then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						elseif Input.UserInputType == Enum.UserInputType.Keyboard then
							if Input.KeyCode.Name == Key or Input.KeyCode == Key then
								Keybind.Toggled = not Keybind.Toggled
								Keybind:DoClick()
							end
						end
					end
				end
			end)

			Creator.AddSignal(KeybindDisplayFrame:GetPropertyChangedSignal("AbsoluteSize"), UpdateTogglePosition)

			Library.Options[Idx] = Keybind

			Toggle.Keybind = Keybind

			return setmetatable(Toggle.Keybind, {
				__newindex =  function(self, index, newvalue)
					if index == "Value" then
						task.spawn(Keybind.SetValue, Keybind, newvalue)
					end
					rawset(self, index, newvalue)
				end
			})
		end
	})

	Toggle:SetValue(Toggle.Value)

	Library.Options[Idx] = Toggle

	Toggle.Instance = ToggleFrame

	return setmetatable(Toggle, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Toggle.SetValue, Toggle, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element

end)() end,
    [24] = function()local wax,script,require=ImportGlobals(24)local ImportGlobals return (function(...)local Acrylic = {
	AcrylicBlur = require(script.AcrylicBlur),
	CreateAcrylic = require(script.CreateAcrylic),
	AcrylicPaint = require(script.AcrylicPaint),
}

function Acrylic.init()
	local baseEffect = Instance.new("DepthOfFieldEffect")
	baseEffect.FarIntensity = 0
	baseEffect.InFocusRadius = 0.1
	baseEffect.NearIntensity = 1

	local depthOfFieldDefaults = {}

	function Acrylic.Enable()
		for _, effect in next, depthOfFieldDefaults do
			effect.Enabled = false
		end
		baseEffect.Parent = game:GetService("Lighting")
	end

	function Acrylic.Disable()
		for _, effect in next, depthOfFieldDefaults do
			effect.Enabled = effect.enabled
		end
		baseEffect.Parent = nil
	end

	local function registerDefaults()
		local function register(object)
			if object:IsA("DepthOfFieldEffect") then
				depthOfFieldDefaults[object] = { enabled = object.Enabled }
			end
		end

		for _, child in next, game:GetService("Lighting"):GetChildren() do
			register(child)
		end

		if game:GetService("Workspace").CurrentCamera then
			for _, child in next, game:GetService("Workspace").CurrentCamera:GetChildren() do
				register(child)
			end
		end
	end

	registerDefaults()
	Acrylic.Enable()
end

return Acrylic

end)() end,
    [25] = function()local wax,script,require=ImportGlobals(25)local ImportGlobals return (function(...)local Root = script.Parent.Parent.Parent
local Creator = require(Root.Modules.Creator)
local createAcrylic = require(script.Parent.CreateAcrylic)
local viewportPointToWorld, getOffset = unpack(require(script.Parent.Utils))

local BlurFolder = Instance.new("Folder", game:GetService("Workspace").CurrentCamera)

local function createAcrylicBlur(distance)
	local cleanups = {}

	distance = distance or 0.001
	local positions = {
		topLeft = Vector2.new(),
		topRight = Vector2.new(),
		bottomRight = Vector2.new(),
	}
	local model = createAcrylic()
	local mesh = model:FindFirstChildWhichIsA("SpecialMesh")

	model.Parent = BlurFolder

	local function updatePositions(size, position)
		positions.topLeft = position
		positions.topRight = position + Vector2.new(size.X, 0)
		positions.bottomRight = position + size
	end

	local function render()
		local camera = game:GetService("Workspace").CurrentCamera
		local cameraTransform = if camera then camera.CFrame else CFrame.identity

		local topLeft = positions.topLeft
		local topRight = positions.topRight
		local bottomRight = positions.bottomRight

		local topLeft3D = viewportPointToWorld(topLeft, distance)
		local topRight3D = viewportPointToWorld(topRight, distance)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance)

		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude

		model.CFrame =
			CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, cameraTransform.XVector, cameraTransform.YVector, cameraTransform.ZVector)

		if mesh then
			mesh.Scale = Vector3.new(width, height, 0)
		end
	end

	local function onChange(rbx)
		local offset = getOffset()
		local size = rbx.AbsoluteSize - Vector2.new(offset, offset)
		local position = rbx.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

		updatePositions(size, position)
		task.spawn(render)
	end

	local function renderOnChange()
		local camera = game:GetService("Workspace").CurrentCamera
		if not camera then
			return
		end

		cleanups[#cleanups + 1] = camera:GetPropertyChangedSignal("CFrame"):Connect(render)
		cleanups[#cleanups + 1] = camera:GetPropertyChangedSignal("ViewportSize"):Connect(render)
		cleanups[#cleanups + 1] = camera:GetPropertyChangedSignal("FieldOfView"):Connect(render)
		task.spawn(render)
	end

	model.Destroying:Connect(function()
		for _, item in cleanups do
			pcall(function()
				item:Disconnect()
			end)
		end
	end)

	renderOnChange()

	return onChange, model
end

return function(distance)
	local Blur = {}
	local onChange, model = createAcrylicBlur(distance)

	local comp = Creator.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	Creator.AddSignal(comp:GetPropertyChangedSignal("AbsolutePosition"), function()
		onChange(comp)
	end)

	Creator.AddSignal(comp:GetPropertyChangedSignal("AbsoluteSize"), function()
		onChange(comp)
	end)

	Blur.AddParent = function(Parent)
		Creator.AddSignal(Parent:GetPropertyChangedSignal("Visible"), function()
			Blur.SetVisibility(Parent.Visible)
		end)
	end

	Blur.SetVisibility = function(Value)
		model.Transparency = Value and 0.98 or 1
	end

	Blur.Frame = comp
	Blur.Model = model

	return Blur
end

end)() end,
    [26] = function()local wax,script,require=ImportGlobals(26)local ImportGlobals return (function(...)local Root = script.Parent.Parent.Parent
local Creator = require(Root.Modules.Creator)
local AcrylicBlur = require(script.Parent.AcrylicBlur)

local New = Creator.New

return function(props)
	local AcrylicPaint = {}

	AcrylicPaint.Frame = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.9,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
	}, {
		New("ImageLabel", {
			Image = "rbxassetid://8992230677",
			ScaleType = "Slice",
			SliceCenter = Rect.new(Vector2.new(99, 99), Vector2.new(99, 99)),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(1, 120, 1, 116),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.7,
		}),

		New("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),

		New("Frame", {
			BackgroundTransparency = 0.45,
			Size = UDim2.fromScale(1, 1),
			Name = "Background",
			ThemeTag = {
				BackgroundColor3 = "AcrylicMain",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),

		New("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.4,
			Size = UDim2.fromScale(1, 1),
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),

			New("UIGradient", {
				Rotation = 90,
				ThemeTag = {
					Color = "AcrylicGradient",
				},
			}),
		}),

		New("ImageLabel", {
			Image = "rbxassetid://9968344105",
			ImageTransparency = 0.98,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 128, 0, 128),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),

		New("ImageLabel", {
			Image = "rbxassetid://9968344227",
			ImageTransparency = 0.9,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 128, 0, 128),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ThemeTag = {
				ImageTransparency = "AcrylicNoise",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),

		New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			New("UIStroke", {
				Transparency = 0.5,
				Thickness = 1,
				ThemeTag = {
					Color = "AcrylicBorder",
				},
			}),
		}),
	})

	local Blur

	if require(Root).UseAcrylic then
		Blur = AcrylicBlur()
		Blur.Frame.Parent = AcrylicPaint.Frame
		AcrylicPaint.Model = Blur.Model
		AcrylicPaint.AddParent = Blur.AddParent
		AcrylicPaint.SetVisibility = Blur.SetVisibility
	end

	return AcrylicPaint
end

end)() end,
    [27] = function()local wax,script,require=ImportGlobals(27)local ImportGlobals return (function(...)local Root = script.Parent.Parent.Parent
local Creator = require(Root.Modules.Creator)

local function createAcrylic()
	local Part = Creator.New("Part", {
		Name = "Body",
		Color = Color3.new(0, 0, 0),
		Material = Enum.Material.Glass,
		Size = Vector3.new(1, 1, 0),
		Anchored = true,
		CanCollide = false,
		Locked = true,
		CastShadow = false,
		Transparency = 0.98,
	}, {
		Creator.New("SpecialMesh", {
			MeshType = Enum.MeshType.Brick,
			Offset = Vector3.new(0, 0, -0.000001),
		})
	})

	return Part
end

return createAcrylic

end)() end,
    [28] = function()local wax,script,require=ImportGlobals(28)local ImportGlobals return (function(...)local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function viewportPointToWorld(location, distance)
	local unitRay = game:GetService("Workspace").CurrentCamera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

local function getOffset()
	local viewportSizeY = game:GetService("Workspace").CurrentCamera.ViewportSize.Y
	return map(viewportSizeY, 0, 2560, 8, 56)
end

return { viewportPointToWorld, getOffset }

end)() end,
    [29] = function()local wax,script,require=ImportGlobals(29)local ImportGlobals return (function(...)local Root = script.Parent.Parent
local Themes = require(Root.Themes)
local Flipper = require(Root.Packages.Flipper)
local Signal = require(Root.Packages.Signal)

local Creator = {
	Registry = {},
	Signals = {},
	TransparencyMotors = {},
	DefaultProperties = {
		ScreenGui = {
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		},
		Frame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ScrollingFrame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ScrollBarImageColor3 = Color3.new(0, 0, 0),
		},
		TextLabel = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			TextSize = 14,
			RichText = true,
		},
		TextButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
			RichText = true,
		},
		TextBox = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ClearTextOnFocus = false,
			Font = Enum.Font.SourceSans,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
			RichText = true,
		},
		ImageLabel = {
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ImageButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
		},
		CanvasGroup = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		}
	},
	Theme = {
		Updating = false,
		Updated = Signal.new()
	}
}

local function ApplyCustomProps(Object, Props: { [string]: any }?)
	if typeof(Props) == "table" and Props.ThemeTag then
		Creator.AddThemeObject(Object, Props.ThemeTag)
	end
end

function Creator.AddSignal(Signal: RBXScriptSignal, Function)
	Creator.Signals[#Creator.Signals+1] = Signal:Connect(Function)
end

function Creator.Disconnect()
	for Idx = #Creator.Signals, 1, -1 do
		local Connection = table.remove(Creator.Signals, Idx)

		if Connection then
			Connection:Disconnect()
		end
	end
end

function Creator.GetThemeProperty(Property)
	if Themes[require(Root).Theme][Property] then
		return Themes[require(Root).Theme][Property]
	end

	return Themes["Royal_Purple"][Property]
end

function Creator.UpdateTheme(RegistryIndex: Instance?)
	if Creator.Theme.Updating then
		Creator.Theme.Updated:Wait()
	end

	Creator.Theme.Updating = true

	local Count = 0

	if typeof(RegistryIndex) == "Instance" and Creator.Registry[RegistryIndex] then
		for Property, ColorIdx in next, Creator.Registry[RegistryIndex].Properties do
			Count += 1

			if Count % 135 == 0 then
				task.wait()
			end

			RegistryIndex[Property] = Creator.GetThemeProperty(ColorIdx)
		end
	else
		for _, Object in next, Creator.Registry do
			Count += 1

			if Count % 135 == 0 then
				task.wait()
			end

			for Property, ColorIdx in next, Object.Properties do
				Count += 1

				if Count % 135 == 0 then
					task.wait()
				end

				Object.Object[Property] = Creator.GetThemeProperty(ColorIdx)
			end
		end
	end

	for Idx: number, Motor in next, Creator.TransparencyMotors do
		if Idx % 135 == 0 then
			task.wait()
		end

		Motor:setGoal(Flipper.Instant.new(Creator.GetThemeProperty("ElementTransparency")))
	end

	Creator.Theme.Updating = false
	Creator.Theme.Updated:Fire()
end

function Creator.AddThemeObject(Object: Instance, Properties:{ [string]: any })
	local Idx = #Creator.Registry + 1
	local Data = {
		Object = Object,
		Properties = Properties,
		Idx = Idx,
	}

	Creator.Registry[Object] = Data
	Creator.UpdateTheme(Object)

	return Object
end

function Creator.OverrideTag(Object, Properties)
	Creator.Registry[Object].Properties = Properties
	Creator.UpdateTheme(Object)
end

function Creator.New(Name, Properties: { [string]: any }?, Children: { [number]: Instance }?): Instance
	local Object = Instance.new(Name)

	for Name, Value in next, Creator.DefaultProperties[Name] or {} do
		Object[Name] = Value
	end

	for Name, Value in next, Properties or {} do
		if Name ~= "ThemeTag" then
			Object[Name] = Value
		end
	end

	for _, Child in next, Children or {} do
		Child.Parent = Object
	end

	ApplyCustomProps(Object, Properties)

	return Object
end

function Creator.SpringMotor(Initial: any, Instance: Object, Prop: string, IgnoreDialogCheck: boolean?, ResetOnThemeChange: boolean?)
	IgnoreDialogCheck = IgnoreDialogCheck or false
	ResetOnThemeChange = ResetOnThemeChange or false
	local Motor = Flipper.SingleMotor.new(Initial)
	Motor:onStep(function(value)
		Instance[Prop] = value
	end)

	if ResetOnThemeChange then
		Creator.TransparencyMotors[#Creator.TransparencyMotors + 1] = Motor
	end

	local function SetValue(Value, Ignore: boolean?)
		Ignore = Ignore or false
		if not IgnoreDialogCheck then
			if not Ignore then
				if Prop == "BackgroundTransparency" and require(Root).DialogOpen then
					return
				end
			end
		end
		Motor:setGoal(Flipper.Spring.new(Value, { frequency = 8 }))
	end

	return Motor, SetValue
end

return Creator

end)() end,
    [30] = function()local wax,script,require=ImportGlobals(30)local ImportGlobals return (function(...)
local icons_1 = 'rbxassetid://124334518624683'
local icons_2 = 'rbxassetid://113826256227095'
local icons_17 = 'rbxassetid://115396960406352'
local icons_41 = 'rbxassetid://83798598825627'

game:GetService'ContentProvider':PreloadAsync{
    icons_1,
    icons_2,
    icons_17,
    icons_41,
    "rbxassetid://9886659671",
    "rbxassetid://9886659276",
    "rbxassetid://9886659406",
    "rbxassetid://9886659001"
}

return {
    SetIcon = function(self, Image: ImageLabel & ImageButton, IconName: string)
        local IconData = self[IconName]

        if typeof(IconData) ~= 'table' then
            local nearestName = nil
            local nearestDistance = math.huge

            for name, _ in next, self do
                local s, t = name, IconName
                local m, n = #s, #t
                local d = {}

                for i = 0, m do
                    d[i] = {}
                    d[i][0] = i
                end

                for j = 0, n do
                    d[0][j] = j
                end

                for i = 1, m do
                    for j = 1, n do
                        local cost = (s:sub(i, i) == t:sub(j, j)) and 0 or 1
                        d[i][j] = math.min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + cost)
                    end
                end

                local distance = d[m][n]

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestName = name
                end
            end

            if nearestName then
                IconData = self[nearestName]
                if typeof(IconData) ~= 'table' then
                    return error(debug.traceback(`Argument #2 '{IconName}' is not a valid Icon. Did you mean '{nearestName}'?`))
                end
            else
                return error(debug.traceback(`Argument #2 '{IconName}' is not a valid Icon. No similar names found.`))
            end
        end

        Image.ImageRectSize = IconData.ImageRectSize
        Image.ImageRectOffset = IconData.ImageRectOffset
        Image.Image = IconData.Image

        return nil :: never
    end,

    ['Close'] = "rbxassetid://9886659671",
    ['Min'] = "rbxassetid://9886659276",
    ['Max'] = "rbxassetid://9886659406",
    ['Restore'] = "rbxassetid://9886659001",

    ['chevron-right'] = {
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(448, 192),
        Image = icons_2
    },

    ['phosphor-eye-slash'] = {
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(576, 960),
        Image = icons_17
    },
    ['phosphor-eye'] = {
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(704, 960),
        Image = icons_17
    },

    ['bot'] = {
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(192, 832),
        Image = icons_1
    },
    ['settings'] = {
        ImageRectSize = Vector2.new(64, 64),
        ImageRectOffset = Vector2.new(384, 128),
        Image = icons_41
    }
}
end)() end,
    [31] = function()local wax,script,require=ImportGlobals(31)local ImportGlobals return (function(...)
local Themes = {
    Names = {
        "Royal_Purple"
    }
}

for _, Theme in next, script:GetChildren() do
    Themes[Theme.Name] = require(Theme)
end

return Themes
end)() end,
    [109] = function()local wax,script,require=ImportGlobals(109)local ImportGlobals return (function(...)return {
	Accent = Color3.fromRGB(140, 60, 220),

	AcrylicMain = Color3.fromRGB(14, 10, 22),
	AcrylicBorder = Color3.fromRGB(107, 79, 155),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(58, 27, 91), Color3.fromRGB(9, 6, 14)),
	AcrylicNoise = 0.9,

	TitleBarLine = Color3.fromRGB(69, 49, 105),
	Tab = Color3.fromRGB(118, 92, 162),

	Element = Color3.fromRGB(100, 70, 150),
	ElementBorder = Color3.fromRGB(11, 8, 18),
	InElementBorder = Color3.fromRGB(107, 79, 155),
	ElementTransparency = 0.87,

	ToggleSlider = Color3.fromRGB(100, 70, 150),
	ToggleToggled = Color3.fromRGB(0, 0, 0),

	SliderRail = Color3.fromRGB(100, 70, 150),

	DropdownFrame = Color3.fromRGB(131, 107, 171),
	DropdownHolder = Color3.fromRGB(13, 9, 20),
	DropdownBorder = Color3.fromRGB(11, 8, 17),
	DropdownOption = Color3.fromRGB(100, 70, 150),

	Keybind = Color3.fromRGB(100, 70, 150),

	Input = Color3.fromRGB(123, 97, 165),
	InputFocused = Color3.fromRGB(9, 6, 14),
	InputIndicator = Color3.fromRGB(138, 116, 176),

	Dialog = Color3.fromRGB(13, 9, 20),
	DialogHolder = Color3.fromRGB(11, 8, 18),
	DialogHolderLine = Color3.fromRGB(10, 7, 16),
	DialogButton = Color3.fromRGB(13, 9, 20),
	DialogButtonBorder = Color3.fromRGB(112, 84, 158),
	DialogBorder = Color3.fromRGB(100, 70, 150),
	DialogInput = Color3.fromRGB(32, 28, 38),
	DialogInputLine = Color3.fromRGB(138, 116, 176),

	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Hover = Color3.fromRGB(100, 70, 150),
	HoverChange = 0.06
}

end)() end,
    [153] = function()local wax,script,require=ImportGlobals(153)local ImportGlobals return (function(...)return require(script.Parent._Index["reselim_flipper@2.0.0"]["flipper"])

end)() end,
    [155] = function()local wax,script,require=ImportGlobals(155)local ImportGlobals return (function(...)return require(script.Parent._Index["lucasmzreal_fastsignal@10.4.0"]["fastsignal"])

end)() end,
    [183] = function()local wax,script,require=ImportGlobals(183)local ImportGlobals return (function(...)

local IsDeferred: boolean do
	IsDeferred = false

	local bindable = Instance.new("BindableEvent")

	local handlerRun = false
	bindable.Event:Connect(function()
		handlerRun = true
	end)

	bindable:Fire()
	bindable:Destroy()

	if handlerRun == false then

		IsDeferred = true
	end
end

export type ScriptSignal<T...> = {
	IsActive: (self: ScriptSignal<T...>) -> boolean,
	Fire: (self: ScriptSignal<T...>, T...) -> (),
	Connect: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	Once: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	DisconnectAll: (self: ScriptSignal<T...>) -> (),
	Destroy: (self: ScriptSignal<T...>) -> (),
	Wait: (self: ScriptSignal<T...>) -> T...,
}
export type ScriptConnection = {
	Disconnect: (self: ScriptConnection) -> (),
	Connected: boolean,
}

export type Class = ScriptSignal<...any>

local ChosenSignal: typeof( require(script.Docs) ) = IsDeferred
	and require(script.Deferred)
	or require(script.Immediate)

return ChosenSignal
end)() end,
    [184] = function()local wax,script,require=ImportGlobals(184)local ImportGlobals return (function(...)

export type ScriptSignal<T...> = {
	IsActive: (self: ScriptSignal<T...>) -> boolean,
	Fire: (self: ScriptSignal<T...>, T...) -> (),
	Connect: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	Once: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	DisconnectAll: (self: ScriptSignal<T...>) -> (),
	Destroy: (self: ScriptSignal<T...>) -> (),
	Wait: (self: ScriptSignal<T...>) -> T...,
}
export type ScriptConnection = {
	Disconnect: (self: ScriptConnection) -> (),
	Connected: boolean,
}

export type Class = ScriptSignal<...any>

local ScriptSignal = {}
ScriptSignal.__index = ScriptSignal

local ScriptConnection = {}
ScriptConnection.__index = ScriptConnection

function ScriptSignal.new()
	return setmetatable({
		_active = true,
		_head = nil
	}, ScriptSignal)
end

function ScriptSignal.Is(object)
	return typeof(object) == 'table'
		and getmetatable(object) == ScriptSignal
end

function ScriptSignal:IsActive()
	return self._active == true
end

function ScriptSignal:Connect(handler)
	assert(
		typeof(handler) == 'function',
		"Must be function"
	)

	if self._active ~= true then
		return setmetatable({
			Connected = false,
			_node = nil
		}, ScriptConnection)
	end

	local _head = self._head

	local node = {
		_signal = self,
		_connection = nil,
		_handler = handler,

		_next = _head,
		_prev = nil
	}

	if _head ~= nil then
		_head._prev = node
	end

	self._head = node

	local connection = setmetatable({
		Connected = true,
		_node = node
	}, ScriptConnection)

	node._connection = connection

	return connection
end

function ScriptSignal:Once(handler)
	assert(
		typeof(handler) == 'function',
		"Must be function"
	)

	local connection
	connection = self:Connect(function(...)
		if connection == nil then
			return
		end

		connection:Disconnect()
		connection = nil

		handler(...)
	end)

	return connection
end
ScriptSignal.ConnectOnce = ScriptSignal.Once

function ScriptSignal:Wait()
	local thread do
		thread = coroutine.running()

		local connection
		connection = self:Connect(function(...)
			if connection == nil then
				return
			end

			connection:Disconnect()
			connection = nil
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread, ...)
			end
		end)
	end

	return coroutine.yield()
end

function ScriptSignal:Fire(...)
	local node = self._head
	while node ~= nil do
		task.defer(node._handler, ...)

		node = node._next
	end
end

function ScriptSignal:DisconnectAll()
	local node = self._head
	while node ~= nil do
		local _connection = node._connection

		if _connection ~= nil then
			_connection.Connected = false
			_connection._node = nil
			node._connection = nil
		end

		node = node._next
	end

	self._head = nil
end

function ScriptSignal:Destroy()
	if self._active ~= true then
		return
	end

	self:DisconnectAll()
	self._active = false
end

function ScriptConnection:Disconnect()
	if self.Connected ~= true then
		return
	end

	self.Connected = false

	local _node = self._node
	local _prev = _node._prev
	local _next = _node._next

	if _next ~= nil then
		_next._prev = _prev
	end

	if _prev ~= nil then
		_prev._next = _next
	else

		_node._signal._head = _next
	end

	_node._connection = nil
	self._node = nil
end
ScriptConnection.Destroy = ScriptConnection.Disconnect

return ScriptSignal :: typeof( require(script.Parent.Docs) )
end)() end,
    [185] = function()local wax,script,require=ImportGlobals(185)local ImportGlobals return (function(...)

if true then
	error("This is not supposed to run!")
end

export type ScriptSignal<T...> = {
	IsActive: (self: ScriptSignal<T...>) -> boolean,
	Fire: (self: ScriptSignal<T...>, T...) -> (),
	Connect: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	Once: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	DisconnectAll: (self: ScriptSignal<T...>) -> (),
	Destroy: (self: ScriptSignal<T...>) -> (),
	Wait: (self: ScriptSignal<T...>) -> T...,
}
export type ScriptConnection = {
	Disconnect: (self: ScriptConnection) -> (),
	Connected: boolean,
}

export type Class = ScriptSignal<...any>

local ScriptSignal = {}
ScriptSignal.__index = ScriptSignal

local ScriptConnection = {}
ScriptConnection.__index = ScriptConnection

function ScriptSignal.new()
	return {}
end

function ScriptSignal.Is(object)
	return true
end

function ScriptSignal:IsActive()
	return true
end

function ScriptSignal:Connect(handler)

end

function ScriptSignal:Once(handler)

end

function ScriptSignal:Wait()

end

function ScriptSignal:Fire(...)

end

function ScriptSignal:DisconnectAll()

end

function ScriptSignal:Destroy()

end

function ScriptConnection:Disconnect()

end

local returnType = {}

function returnType.new<T...>(): ScriptSignal<T...>
	return ScriptSignal.new()
end

function returnType.Is(any): boolean
	return true
end

return returnType
end)() end,
    [186] = function()local wax,script,require=ImportGlobals(186)local ImportGlobals return (function(...)

export type ScriptSignal<T...> = {
	IsActive: (self: ScriptSignal<T...>) -> boolean,
	Fire: (self: ScriptSignal<T...>, T...) -> (),
	Connect: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	Once: (self: ScriptSignal<T...>, callback: (T...) -> ()) -> ScriptConnection,
	DisconnectAll: (self: ScriptSignal<T...>) -> (),
	Destroy: (self: ScriptSignal<T...>) -> (),
	Wait: (self: ScriptSignal<T...>) -> T...,
}
export type ScriptConnection = {
	Disconnect: (self: ScriptConnection) -> (),
	Connected: boolean,
}

export type Class = ScriptSignal<...any>

local MainScriptSignal = require(script.Parent.Deferred)

local ScriptSignal = {} do
	for methodName, method in pairs(MainScriptSignal) do
		ScriptSignal[methodName] = method
	end
	ScriptSignal.__index = ScriptSignal
end

local FreeThread: thread? = nil
local function RunHandlerInFreeThread(handler, ...)
	local thread = FreeThread :: thread
	FreeThread = nil

	handler(...)

	FreeThread = thread
end

local function CreateFreeThread()
	FreeThread = coroutine.running()

	while true do
		RunHandlerInFreeThread( coroutine.yield() )
	end
end

function ScriptSignal.new()
	return setmetatable({
		_active = true,
		_head = nil
	}, ScriptSignal)
end

function ScriptSignal.Is(object)
	return typeof(object) == 'table'
		and getmetatable(object) == ScriptSignal
end

function ScriptSignal:Fire(...)
	local node = self._head
	while node ~= nil do
		if node._connection ~= nil then
			if FreeThread == nil then
				task.spawn(CreateFreeThread)
			end

			task.spawn(
				FreeThread :: thread,
				node._handler, ...
			)
		end

		node = node._next
	end
end

return ScriptSignal :: typeof( require(script.Parent.Docs) )
end)() end,
    [190] = function()local wax,script,require=ImportGlobals(190)local ImportGlobals return (function(...)local Flipper = {
	SingleMotor = require(script.SingleMotor),
	GroupMotor = require(script.GroupMotor),

	Instant = require(script.Instant),
	Linear = require(script.Linear),
	Spring = require(script.Spring),

	isMotor = require(script.isMotor),
}

return Flipper
end)() end,
    [191] = function()local wax,script,require=ImportGlobals(191)local ImportGlobals return (function(...)local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

local noop = function() end

local BaseMotor = {}
BaseMotor.__index = BaseMotor

function BaseMotor.new()
	return setmetatable({
		_onStep = Signal.new(),
		_onStart = Signal.new(),
		_onComplete = Signal.new(),
	}, BaseMotor)
end

function BaseMotor:onStep(handler)
	return self._onStep:connect(handler)
end

function BaseMotor:onStart(handler)
	return self._onStart:connect(handler)
end

function BaseMotor:onComplete(handler)
	return self._onComplete:connect(handler)
end

function BaseMotor:start()
	if not self._connection then
		self._connection = RunService.RenderStepped:Connect(function(deltaTime)
			self:step(deltaTime)
		end)
	end
end

function BaseMotor:stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

BaseMotor.destroy = BaseMotor.stop

BaseMotor.step = noop
BaseMotor.getValue = noop
BaseMotor.setGoal = noop

function BaseMotor:__tostring()
	return "Motor"
end

return BaseMotor

end)() end,
    [193] = function()local wax,script,require=ImportGlobals(193)local ImportGlobals return (function(...)local BaseMotor = require(script.Parent.BaseMotor)
local SingleMotor = require(script.Parent.SingleMotor)

local isMotor = require(script.Parent.isMotor)

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

local function toMotor(value)
	if isMotor(value) then
		return value
	end

	local valueType = typeof(value)

	if valueType == "number" then
		return SingleMotor.new(value, false)
	elseif valueType == "table" then
		return GroupMotor.new(value, false)
	end

	error(("Unable to convert %q to motor; type %s is unsupported"):format(value, valueType), 2)
end

function GroupMotor.new(initialValues, useImplicitConnections)
	assert(initialValues, "Missing argument #1: initialValues")
	assert(typeof(initialValues) == "table", "initialValues must be a table!")
	assert(not initialValues.step, "initialValues contains disallowed property \"step\". Did you mean to put a table of values here?")

	local self = setmetatable(BaseMotor.new(), GroupMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._complete = true
	self._motors = {}

	for key, value in pairs(initialValues) do
		self._motors[key] = toMotor(value)
	end

	return self
end

function GroupMotor:step(deltaTime)
	if self._complete then
		return true
	end

	local allMotorsComplete = true

	for _, motor in pairs(self._motors) do
		local complete = motor:step(deltaTime)
		if not complete then

			allMotorsComplete = false
		end
	end

	self._onStep:fire(self:getValue())

	if allMotorsComplete then
		if self._useImplicitConnections then
			self:stop()
		end

		self._complete = true
		self._onComplete:fire()
	end

	return allMotorsComplete
end

function GroupMotor:setGoal(goals)
	assert(not goals.step, "goals contains disallowed property \"step\". Did you mean to put a table of goals here?")

	self._complete = false
	self._onStart:fire()

	for key, goal in pairs(goals) do
		local motor = assert(self._motors[key], ("Unknown motor for key %s"):format(key))
		motor:setGoal(goal)
	end

	if self._useImplicitConnections then
		self:start()
	end
end

function GroupMotor:getValue()
	local values = {}

	for key, motor in pairs(self._motors) do
		values[key] = motor:getValue()
	end

	return values
end

function GroupMotor:__tostring()
	return "Motor(Group)"
end

return GroupMotor

end)() end,
    [195] = function()local wax,script,require=ImportGlobals(195)local ImportGlobals return (function(...)local Instant = {}
Instant.__index = Instant

function Instant.new(targetValue)
	return setmetatable({
		_targetValue = targetValue,
	}, Instant)
end

function Instant:step()
	return {
		complete = true,
		value = self._targetValue,
	}
end

return Instant
end)() end,
    [197] = function()local wax,script,require=ImportGlobals(197)local ImportGlobals return (function(...)local Linear = {}
Linear.__index = Linear

function Linear.new(targetValue, options)
	assert(targetValue, "Missing argument #1: targetValue")

	options = options or {}

	return setmetatable({
		_targetValue = targetValue,
		_velocity = options.velocity or 1,
	}, Linear)
end

function Linear:step(state, dt)
	local position = state.value
	local velocity = self._velocity
	local goal = self._targetValue

	local dPos = dt * velocity

	local complete = dPos >= math.abs(goal - position)
	position = position + dPos * (goal > position and 1 or -1)
	if complete then
		position = self._targetValue
		velocity = 0
	end

	return {
		complete = complete,
		value = position,
		velocity = velocity,
	}
end

return Linear
end)() end,
    [199] = function()local wax,script,require=ImportGlobals(199)local ImportGlobals return (function(...)local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler)
	return setmetatable({
		signal = signal,
		connected = true,
		_handler = handler,
	}, Connection)
end

function Connection:disconnect()
	if self.connected then
		self.connected = false

		for index, connection in pairs(self.signal._connections) do
			if connection == self then
				table.remove(self.signal._connections, index)
				return
			end
		end
	end
end

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_connections = {},
		_threads = {},
	}, Signal)
end

function Signal:fire(...)
	for _, connection in pairs(self._connections) do
		connection._handler(...)
	end

	for _, thread in pairs(self._threads) do
		coroutine.resume(thread, ...)
	end

	self._threads = {}
end

function Signal:connect(handler)
	local connection = Connection.new(self, handler)
	table.insert(self._connections, connection)
	return connection
end

function Signal:wait()
	table.insert(self._threads, coroutine.running())
	return coroutine.yield()
end

return Signal
end)() end,
    [201] = function()local wax,script,require=ImportGlobals(201)local ImportGlobals return (function(...)local BaseMotor = require(script.Parent.BaseMotor)

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
	assert(initialValue, "Missing argument #1: initialValue")
	assert(typeof(initialValue) == "number", "initialValue must be a number!")

	local self = setmetatable(BaseMotor.new(), SingleMotor)

	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end

	self._goal = nil
	self._state = {
		complete = true,
		value = initialValue,
	}

	return self
end

function SingleMotor:step(deltaTime)
	if self._state.complete then
		return true
	end

	local newState = self._goal:step(self._state, deltaTime)

	self._state = newState
	self._onStep:fire(newState.value)

	if newState.complete then
		if self._useImplicitConnections then
			self:stop()
		end

		self._onComplete:fire()
	end

	return newState.complete
end

function SingleMotor:getValue()
	return self._state.value
end

function SingleMotor:setGoal(goal)
	self._state.complete = false
	self._goal = goal

	self._onStart:fire()

	if self._useImplicitConnections then
		self:start()
	end
end

function SingleMotor:__tostring()
	return "Motor(Single)"
end

return SingleMotor

end)() end,
    [203] = function()local wax,script,require=ImportGlobals(203)local ImportGlobals return (function(...)local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001

local EPS = 0.0001

local Spring = {}
Spring.__index = Spring

function Spring.new(targetValue, options)
	assert(targetValue, "Missing argument #1: targetValue")
	options = options or {}

	return setmetatable({
		_targetValue = targetValue,
		_frequency = options.frequency or 4,
		_dampingRatio = options.dampingRatio or 1,
	}, Spring)
end

function Spring:step(state, dt)

	local d = self._dampingRatio
	local f = self._frequency*2*math.pi
	local g = self._targetValue
	local p0 = state.value
	local v0 = state.velocity or 0

	local offset = p0 - g
	local decay = math.exp(-d*f*dt)

	local p1, v1

	if d == 1 then
		p1 = (offset*(1 + f*dt) + v0*dt)*decay + g
		v1 = (v0*(1 - f*dt) - offset*(f*f*dt))*decay
	elseif d < 1 then
		local c = math.sqrt(1 - d*d)

		local i = math.cos(f*c*dt)
		local j = math.sin(f*c*dt)

		local z
		if c > EPS then
			z = j/c
		else
			local a = dt*f
			z = a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6
		end

		local y
		if f*c > EPS then
			y = j/(f*c)
		else
			local b = f*c
			y = dt + ((dt*dt)*(b*b)*(b*b)/20 - b*b)*(dt*dt*dt)/6
		end

		p1 = (offset*(i + d*z) + v0*y)*decay + g
		v1 = (v0*(i - z*d) - offset*(z*f))*decay

	else
		local c = math.sqrt(d*d - 1)

		local r1 = -f*(d - c)
		local r2 = -f*(d + c)

		local co2 = (v0 - offset*r1)/(2*f*c)
		local co1 = offset - co2

		local e1 = co1*math.exp(r1*dt)
		local e2 = co2*math.exp(r2*dt)

		p1 = e1 + e2 + g
		v1 = e1*r1 + e2*r2
	end

	local complete = math.abs(v1) < VELOCITY_THRESHOLD and math.abs(p1 - g) < POSITION_THRESHOLD

	return {
		complete = complete,
		value = complete and g or p1,
		velocity = v1,
	}
end

return Spring
end)() end,
    [205] = function()local wax,script,require=ImportGlobals(205)local ImportGlobals return (function(...)local function isMotor(value)
	local motorType = tostring(value):match("^Motor%((.+)%)$")

	if motorType then
		return true, motorType
	else
		return false
	end
end

return isMotor
end)() end,
}

local ObjectTree = {
    {
            1,
            2,
            {
                        "Fluent Renewed"
                    },
            {
                        {
                                        152,
                                        1,
                                        {
                                                            "Packages"
                                                        },
                                        {
                                                            {
                                                                                    156,
                                                                                    1,
                                                                                    {
                                                                                                                "_Index"
                                                                                                            },
                                                                                    {
                                                                                                                {
                                                                                                                                                189,
                                                                                                                                                1,
                                                                                                                                                {
                                                                                                                                                                                    "reselim_flipper@2.0.0"
                                                                                                                                                                                },
                                                                                                                                                {
                                                                                                                                                                                    {
                                                                                                                                                                                                                            190,
                                                                                                                                                                                                                            2,
                                                                                                                                                                                                                            {
                                                                                                                                                                                                                                                                        "flipper"
                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                            {
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        199,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Signal"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        195,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Instant"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        205,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "isMotor"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        191,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "BaseMotor"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        203,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Spring"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        201,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "SingleMotor"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        197,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Linear"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        193,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "GroupMotor"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                        }
                                                                                                                                                                                }
                                                                                                                                            },
                                                                                                                {
                                                                                                                                                182,
                                                                                                                                                1,
                                                                                                                                                {
                                                                                                                                                                                    "lucasmzreal_fastsignal@10.4.0"
                                                                                                                                                                                },
                                                                                                                                                {
                                                                                                                                                                                    {
                                                                                                                                                                                                                            183,
                                                                                                                                                                                                                            2,
                                                                                                                                                                                                                            {
                                                                                                                                                                                                                                                                        "fastsignal"
                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                            {
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        185,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Docs"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        184,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Deferred"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    },
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                        186,
                                                                                                                                                                                                                                                                                                                        2,
                                                                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                                                                                                                            "Immediate"
                                                                                                                                                                                                                                                                                                                                                                        }
                                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                        }
                                                                                                                                                                                }
                                                                                                                                            }
                                                                                                            }
                                                                                },
                                                            {
                                                                                    153,
                                                                                    2,
                                                                                    {
                                                                                                                "Flipper"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    155,
                                                                                    2,
                                                                                    {
                                                                                                                "Signal"
                                                                                                            }
                                                                                }
                                                        }
                                    },
                        {
                                        2,
                                        1,
                                        {
                                                            "Components"
                                                        },
                                        {
                                                            {
                                                                                    7,
                                                                                    2,
                                                                                    {
                                                                                                                "Notification"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    12,
                                                                                    2,
                                                                                    {
                                                                                                                "Window"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    5,
                                                                                    2,
                                                                                    {
                                                                                                                "Dialog"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    4,
                                                                                    2,
                                                                                    {
                                                                                                                "Button"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    9,
                                                                                    2,
                                                                                    {
                                                                                                                "Tab"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    3,
                                                                                    2,
                                                                                    {
                                                                                                                "Assets"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    8,
                                                                                    2,
                                                                                    {
                                                                                                                "Section"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    6,
                                                                                    2,
                                                                                    {
                                                                                                                "Element"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    11,
                                                                                    2,
                                                                                    {
                                                                                                                "TitleBar"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    10,
                                                                                    2,
                                                                                    {
                                                                                                                "Textbox"
                                                                                                            }
                                                                                }
                                                        }
                                    },
                        {
                                        31,
                                        2,
                                        {
                                                            "Themes"
                                                        },
                                        {
                                                            {
                                                                                    109,
                                                                                    2,
                                                                                    {
                                                                                                                "Royal_Purple"
                                                                                                            }
                                                                                }
                                                        }
                                    },
                        {
                                        23,
                                        1,
                                        {
                                                            "Modules"
                                                        },
                                        {
                                                            {
                                                                                    29,
                                                                                    2,
                                                                                    {
                                                                                                                "Creator"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    30,
                                                                                    2,
                                                                                    {
                                                                                                                "Icons"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    24,
                                                                                    2,
                                                                                    {
                                                                                                                "Acrylic"
                                                                                                            },
                                                                                    {
                                                                                                                {
                                                                                                                                                28,
                                                                                                                                                2,
                                                                                                                                                {
                                                                                                                                                                                    "Utils"
                                                                                                                                                                                }
                                                                                                                                            },
                                                                                                                {
                                                                                                                                                26,
                                                                                                                                                2,
                                                                                                                                                {
                                                                                                                                                                                    "AcrylicPaint"
                                                                                                                                                                                }
                                                                                                                                            },
                                                                                                                {
                                                                                                                                                27,
                                                                                                                                                2,
                                                                                                                                                {
                                                                                                                                                                                    "CreateAcrylic"
                                                                                                                                                                                }
                                                                                                                                            },
                                                                                                                {
                                                                                                                                                25,
                                                                                                                                                2,
                                                                                                                                                {
                                                                                                                                                                                    "AcrylicBlur"
                                                                                                                                                                                }
                                                                                                                                            }
                                                                                                            }
                                                                                }
                                                        }
                                    },
                        {
                                        13,
                                        2,
                                        {
                                                            "Elements"
                                                        },
                                        {
                                                            {
                                                                                    18,
                                                                                    2,
                                                                                    {
                                                                                                                "Input"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    14,
                                                                                    2,
                                                                                    {
                                                                                                                "Button"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    20,
                                                                                    2,
                                                                                    {
                                                                                                                "Paragraph"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    22,
                                                                                    2,
                                                                                    {
                                                                                                                "Toggle"
                                                                                                            }
                                                                                },
                                                            {
                                                                                    16,
                                                                                    2,
                                                                                    {
                                                                                                                "Dropdown"
                                                                                                            }
                                                                                }
                                                        }
                                    }
                    }
        }
}

local LineOffsets = {
    [1] = 8,
    [3] = 504,
    [4] = 512,
    [5] = 591,
    [6] = 759,
    [7] = 913,
    [8] = 1135,
    [9] = 1189,
    [10] = 1501,
    [11] = 1624,
    [12] = 1794,
    [13] = 2700,
    [14] = 2709,
    [16] = 2752,
    [18] = 3455,
    [20] = 3560,
    [22] = 3665,
    [24] = 4018,
    [25] = 4071,
    [26] = 4189,
    [27] = 4311,
    [28] = 4338,
    [29] = 4355,
    [30] = 4582,
    [31] = 4690,
    [109] = 4703,
    [153] = 4751,
    [155] = 4754,
    [183] = 4757,
    [184] = 4811,
    [185] = 5001,
    [186] = 5236,
    [190] = 5315,
    [191] = 5328,
    [193] = 5385,
    [195] = 5494,
    [197] = 5512,
    [199] = 5549,
    [201] = 5608,
    [203] = 5677,
    [205] = 5786
}

local WaxVersion = "0.4.1"
local EnvName = "Fluent Renewed"

local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, xpcall, tostring, tonumber, _VERSION =
      string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, xpcall, tostring, tonumber, _VERSION

local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t) return t end

local coroutine_wrap = coroutine.wrap

local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch

if _VERSION and string_sub(_VERSION, 1, 4) == "Lune" then
    local RequireSuccess, LuneTaskLib = pcall(require, "@lune/task")
    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer

local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end

local ClassNameIdBindings = {
    [1] = "Folder",
    [2] = "ModuleScript",
    [3] = "Script",
    [4] = "LocalScript",
    [5] = "StringValue",
}

local RefBindings = {}

local ScriptClosures = {}
local ScriptClosureRefIds = {}
local StoredModuleValues = {}
local ScriptsToRun = {}

local SharedEnvironment = {}

local RefChildren = {}

local InstanceMethods = {
    GetFullName = { {}, function(self)
        local Path = self.Name
        local ObjectPointer = self.Parent

        while ObjectPointer do
            Path = ObjectPointer.Name .. "." .. Path

            ObjectPointer = ObjectPointer.Parent
        end

        return Path
    end},

    GetChildren = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)
        end

        return ReturnArray
    end},

    GetDescendants = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)

            for _, Descendant in next, Child:GetDescendants() do
                table_insert(ReturnArray, Descendant)
            end
        end

        return ReturnArray
    end},

    FindFirstChild = { {"string", "boolean?"}, function(self, name, recursive)
        local Children = RefChildren[self]

        for Child in next, Children do
            if Child.Name == name then
                return Child
            end
        end

        if recursive then
            for Child in next, Children do

                return Child:FindFirstChild(name, true)
            end
        end
    end},

    FindFirstAncestor = { {"string"}, function(self, name)
        local RefPointer = self.Parent
        while RefPointer do
            if RefPointer.Name == name then
                return RefPointer
            end

            RefPointer = RefPointer.Parent
        end
    end},

    WaitForChild = { {"string", "number?"}, function(self, name)
        return self:FindFirstChild(name)
    end},
}

local InstanceMethodProxies = {}
for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]

    local EvaluatedTypeInfo = {}
    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, "^([^%?]+)(%??)")
        EvaluatedTypeInfo[ArgIndex] = {ExpectedType, IsOptional}
    end

    InstanceMethodProxies[MethodName] = function(self, ...)
        if not RefChildren[self] then
            error("Expected ':' not '.' calling member function " .. MethodName, 2)
        end

        local Args = {...}
        for ArgIndex, TypeInfo in next, EvaluatedTypeInfo do
            local RealArg = Args[ArgIndex]
            local RealArgType = type(RealArg)
            local ExpectedType, IsOptional = TypeInfo[1], TypeInfo[2]

            if RealArg == nil and not IsOptional then
                error("Argument " .. RealArg .. " missing or nil", 3)
            end

            if ExpectedType ~= "any" and RealArgType ~= ExpectedType and not (RealArgType == "nil" and IsOptional) then
                error("Argument " .. ArgIndex .. " expects type \"" .. ExpectedType .. "\", got \"" .. RealArgType .. "\"", 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)

    local StringValue_Value

    local Children = setmetatable({}, {__mode = "k"})

    local function InvalidMember(member)
        error(member .. " is not a valid (virtual) member of " .. className .. " \"" .. name .. "\"", 3)
    end
    local function ReadOnlyProperty(property)
        error("Unable to assign (virtual) property " .. property .. ". Property is read only", 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false

    RefMetatable.__index = function(_, index)
        if index == "ClassName" then
            return className
        elseif index == "Name" then
            return name
        elseif index == "Parent" then
            return parent
        elseif className == "StringValue" and index == "Value" then

            return StringValue_Value
        else
            local InstanceMethod = InstanceMethodProxies[index]

            if InstanceMethod then
                return InstanceMethod
            end
        end

        for Child in next, Children do
            if Child.Name == index then
                return Child
            end
        end

        InvalidMember(index)
    end

    RefMetatable.__newindex = function(_, index, value)

        if index == "ClassName" then
            ReadOnlyProperty(index)
        elseif index == "Name" then
            name = value
        elseif index == "Parent" then

            if value == Ref then
                return
            end

            if parent ~= nil then

                RefChildren[parent][Ref] = nil
            end

            parent = value

            if value ~= nil then

                RefChildren[value][Ref] = true
            end
        elseif className == "StringValue" and index == "Value" then

            StringValue_Value = value
        else

            InvalidMember(index)
        end
    end

    RefMetatable.__tostring = function()
        return name
    end

    setmetatable(Ref, RefMetatable)

    RefChildren[Ref] = Children

    if parent ~= nil then
        RefChildren[parent][Ref] = true
    end

    return Ref
end

local function CreateRefFromObject(object, parent)
    local RefId = object[1]
    local ClassNameId = object[2]
    local Properties = object[3]
    local Children = object[4]

    local ClassName = ClassNameIdBindings[ClassNameId]

    local Name = Properties and table_remove(Properties, 1) or ClassName

    local Ref = CreateRef(ClassName, Name, parent)
    RefBindings[RefId] = Ref

    if Properties then
        for PropertyName, PropertyValue in next, Properties do
            Ref[PropertyName] = PropertyValue
        end
    end

    if Children then
        for _, ChildObject in next, Children do
            CreateRefFromObject(ChildObject, Ref)
        end
    end

    return Ref
end

local RealObjectRoot = CreateRef("Folder", "[" .. EnvName .. "]")
for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end

for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName
    if ClassName == "LocalScript" or ClassName == "Script" then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName

    local StoredModuleValue = StoredModuleValues[scriptRef]
    if StoredModuleValue and ScriptClassName == "ModuleScript" then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()

        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, "[^:]+:(%d+): (.+)")

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ":*: " .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]

        local RealErrorLine = OriginalErrorLine - LineOffset + 1
        if RealErrorLine < 0 then
            RealErrorLine = "?"
        end

        return VirtualFullName .. ":" .. RealErrorLine .. ": " .. BaseErrorMessage
    end

    if ScriptClassName == "LocalScript" or ScriptClassName == "Script" then
        local RunSuccess, ErrorMessage = xpcall(Closure, function(msg)
            return debug.traceback(msg, 2)
        end)
        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {xpcall(Closure, function(msg)
            return debug.traceback(msg, 2)
        end)}

        local RunSuccess = table_remove(PCallReturn, 1)
        if not RunSuccess then
            local ErrorMessage = table_remove(PCallReturn, 1)
            error(FormatError(ErrorMessage), 0)
        end

        StoredModuleValues[scriptRef] = PCallReturn
        return unpack(PCallReturn)
    end
end

function ImportGlobals(refId)
    local ScriptRef = RefBindings[refId]

    local function RealCall(f, ...)
        local PCallReturn = {xpcall(f, function(msg)
            return debug.traceback(msg, 2)
        end, ...)}

        local CallSuccess = table_remove(PCallReturn, 1)
        if not CallSuccess then
            error(PCallReturn[1], 3)
        end

        return unpack(PCallReturn)
    end

    local WaxShared = table_freeze(setmetatable({}, {
        __index = SharedEnvironment,
        __newindex = function(_, index, value)
            SharedEnvironment[index] = value
        end,
        __len = function()
            return #SharedEnvironment
        end,
        __iter = function()
            return next, SharedEnvironment
        end,
    }))

    local Global_wax = table_freeze({

        version = WaxVersion,
        envname = EnvName,

        shared = WaxShared,

        script = script,
        require = require,
    })

    local Global_script = ScriptRef

    local function Global_require(module, ...)
        local ModuleArgType = type(module)

        local ErrorNonModuleScript = "Attempted to call require with a non-ModuleScript"
        local ErrorSelfRequire = "Attempted to call require with self"

        if ModuleArgType == "table" and RefChildren[module]  then
            if module.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == "string" and string_sub(module, 1, 1) ~= "@" then

            if #module == 0 then
                error("Attempted to call require with empty string", 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == "/" then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == "./" then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch
            for PathMatch in string_gmatch(module, "([^/]*)/?") do
                local RealIndex = PathMatch
                if PathMatch == ".." then
                    RealIndex = "Parent"
                end

                if RealIndex ~= "" then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)
                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent
                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end

                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= "init" and PathMatch ~= "init.server" and PathMatch ~= "init.client" then
                        error("Virtual script path \"" .. module .. "\" not found", 2)
                    end
                end

                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif CurrentRefPointer == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(CurrentRefPointer)
        end

        return RealCall(require, module, ...)
    end

    return Global_wax, Global_script, Global_require
end

for _, ScriptRef in next, ScriptsToRun do
    Defer(LoadScript, ScriptRef)
end

return LoadScript(RealObjectRoot:GetChildren()[1])
