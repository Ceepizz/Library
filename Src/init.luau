local function Clone<Original>(ToClone: any & Original): (Original, boolean)
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

	Theme = "Dark",
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

	if Config.Theme == "Default" then
		Config.Theme = "Royal_Purple"
	end

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
	Library.Theme = if typeof(Config.Theme) == "string" then Config.Theme else "Vynixu"

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