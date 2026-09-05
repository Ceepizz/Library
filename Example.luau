local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Ceepizz/Library/refs/heads/main/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Ceepizz/Library/refs/heads/main/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Ceepizz/Library/refs/heads/main/Addons/InterfaceManager.luau"))()

InterfaceManager:SetFolder("FluentScriptHub")
InterfaceManager:LoadSettings()

local Window = Library:CreateWindow{
    Title = `Fluent Renewed {Library.Version}`,
    SubTitle = "by Soluna Development",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true, -- Resize this ^ Size according to a 1920x1080 screen, good for mobile users but may look weird on some devices
    MinSize = Vector2.new(470, 380),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftShift, -- Used when theres no MinimizeKeybind
    Alignment = InterfaceManager.Settings.Alignment,
    Mobile = {
        WindowSize = UDim2.fromOffset(1920, 1080), -- Optional, overrides ^ Size only for Mobile users, omit to keep the same Size on Mobile
    },
}

-- Fluent Renewed provides ALL 1544 Lucide 0.469.0 https://lucide.dev/icons/ Icons and ALL 9072 Phosphor 2.1.0 https://phosphoricons.com/ Icons for the tabs, icons are optional
local Tabs = {
    Main = Window:CreateTab{
        Title = "Main",
        Icon = "phosphor-users-bold"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

local Options = Library.Options

Library:Notify{
    Title = "Notification",
    Content = "This is a notification",
    SubContent = "SubContent", -- Optional
    Duration = 5 -- Set to nil to make the notification not disappear
}

local Paragraph = Tabs.Main:CreateParagraph("Paragraph", {
    Title = "Paragraph",
    Content = "This is a paragraph.\nSecond line!"
})

print(Paragraph.Value)

Paragraph:SetValue("This paragraph text is changed!")

print(Paragraph.Value)

Tabs.Main:CreateParagraph("Aligned Paragraph", {
    Title = "Paragraph",
    Content = "This is a paragraph with a center alignment!",
    TitleAlignment = "Middle",
    ContentAlignment = Enum.TextXAlignment.Center
})

Tabs.Main:CreateButton{
    Title = "Button",
    Description = "Very important button",
    Callback = function()
        Window:Dialog{
            Title = "Title",
            Content = "This is a dialog",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        print("Confirmed the dialog.")
                    end
                },
                {
                    Title = "Cancel",
                    Callback = function()
                        print("Cancelled the dialog.")
                    end
                }
            }
        }
    end
}

local Toggle = Tabs.Main:CreateToggle("MyToggle", {Title = "Toggle", Default = false })

Toggle:OnChanged(function()
    print("Toggle changed:", Options.MyToggle.Value)
end)

Options.MyToggle:SetValue(false)

local Slider = Tabs.Main:CreateSlider("Slider", {
    Title = "Slider",
    Description = "This is a slider",
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        print("Slider was changed:", Value)
    end
})

Slider:OnChanged(function(Value)
    print("Slider changed:", Value)
end)

Slider:SetValue(3)

local Dropdown = Tabs.Main:CreateDropdown("Dropdown", {
    Title = "Dropdown",
    Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
    Multi = false,
    Default = 1,
})

Dropdown:SetValue("four")

Dropdown:OnChanged(function(Value)
    print("Dropdown changed:", Value)
end)

local MultiDropdown = Tabs.Main:CreateDropdown("MultiDropdown", {
    Title = "Dropdown",
    Description = "You can select multiple values.",
    Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
    Multi = true,
    Default = {"seven", "twelve"},
})

MultiDropdown:SetValue{
    three = true,
    five = true,
    seven = false
}

MultiDropdown:SetValues{"fifteen", "sixteen", "seventeen"}

MultiDropdown:OnChanged(function(Value)
    local Values = {}
    for Value, State in next, Value do
        Values[#Values + 1] = Value
    end
    print("Mutlidropdown changed:", table.concat(Values, ", "))
end)

local MultiInstanceDropdown = Tabs.Main:CreateDropdown("MultiInstanceDropdown", {
    Title = "Instance Dropdown",
    Description = "You can select multiple values and any instance or any other value!",
    Values = {workspace, 5, Enum.JoinSource, Enum.MarketplaceBulkPurchasePromptStatus.Error},
    Multi = true,
    Default = {workspace},
})

MultiInstanceDropdown:OnChanged(function(Value)
    local Values = {}
    for Value, State in next, Value do
        Values[#Values + 1] = typeof(Value)
    end
    print("Mutlidropdown with instance selection changed:", table.concat(Values, ", "))
end)

local Colorpicker = Tabs.Main:CreateColorpicker("Colorpicker", {
    Title = "Colorpicker",
    Default = Color3.fromRGB(96, 205, 255)
})

Colorpicker:OnChanged(function()
    print("Colorpicker changed:", Colorpicker.Value)
end)

Colorpicker:SetValueRGB(Color3.fromRGB(0, 255, 140))

local TColorpicker = Tabs.Main:CreateColorpicker("TransparencyColorpicker", {
    Title = "Colorpicker",
    Description = "but you can change the transparency.",
    Transparency = 0,
    Default = Color3.fromRGB(96, 205, 255)
})

TColorpicker:OnChanged(function()
    print(
        "TColorpicker changed:", TColorpicker.Value,
        "Transparency:", TColorpicker.Transparency
    )
end)

local Keybind = Tabs.Main:CreateKeybind("Keybind", {
    Title = "KeyBind",
    Mode = "Toggle", -- Always, Toggle, Hold
    Default = "LeftControl", -- String as the name of the keybind (MB1, MB2 for mouse buttons)

    -- Occurs when the keybind is clicked, Value is `true`/`false`
    Callback = function(Value)
        print("Keybind clicked!", Value)
    end,

    -- Occurs when the keybind itself is changed, `New` is a KeyCode Enum OR a UserInputType Enum
    ChangedCallback = function(New)
        print("Keybind changed!", New)
    end
})

-- OnClick is only fired when you press the keybind and the mode is Toggle
-- Otherwise, you will have to use Keybind:GetState()
Keybind:OnClick(function()
    print("Keybind clicked:", Keybind:GetState())
end)

Keybind:OnChanged(function()
    print("Keybind changed:", Keybind.Value)
end)

task.spawn(function()
    while true do
        wait(1)

        -- example for checking if a keybind is being pressed
        local state = Keybind:GetState()
        if state then
            print("Keybind is being held down")
        end

        if Library.Unloaded then break end
    end
end)

Keybind:SetValue("MB2", "Toggle") -- Sets keybind to MB2, mode to Hold

-- ImagePicker Examples
local SingleImagePicker = Tabs.Main:CreateImagePicker("SingleImagePicker", {
	Title = "Single Image Picker",
	Description = "Select one image from the grid",
	Images = {
		"rbxassetid://113440921474935",
		"rbxassetid://110703867969634",
		"rbxassetid://87701424695968",
	},
	Columns = 3,
	ImageSize = UDim2.fromOffset(80, 0), -- Height 0 = auto (1:1 ratio)
	SelectText = "Choose",
	SelectedText = "Chosen",
	MultiSelect = false,
	Default = "",
	Callback = function(Selected)
		print("Single image selected:", Selected[1])
	end
})

SingleImagePicker:OnChanged(function(Selected)
	print("Single image changed:", Selected[1])
end)

local MultiImagePicker = Tabs.Main:CreateImagePicker("MultiImagePicker", {
	Title = "Multi Image Picker",
	Description = "Select multiple images from the grid",
	Images = {
		"rbxassetid://113440921474935",
		"rbxassetid://110703867969634",
		"rbxassetid://87701424695968",
		"rbxassetid://117705810423288",
		"rbxassetid://126634184099271",
		"rbxassetid://107086864267243",
		"rbxassetid://99471830947082",
		"rbxassetid://77515296067644",
		"rbxassetid://116418392062460",
	},
	Columns = 4,
	ImageSize = UDim2.fromOffset(70, 0), -- Height 0 = auto (1:1 ratio)
	SelectText = "Pick",
	SelectedText = "Picked",
	MultiSelect = true,
	Default = {"", ""},
	Callback = function(Selected)
		print("Multiple images selected:", #Selected)
	end
})

MultiImagePicker:OnChanged(function(Selected)
	print("Multi image changed:", #Selected, "images selected")
end)

-- Advanced ImagePicker with custom image data
-- ScaleType controls how a non-square image fills its box: Fit (letterbox, no crop), Crop (fills box, crops overflow), Stretch (fills box, ignores aspect), Tile (repeats image)
local AdvancedImagePicker = Tabs.Main:CreateImagePicker("AdvancedImagePicker", {
	Title = "Advanced Image Picker",
	Description = "Custom image sizes and properties",
	Images = {
		{
			Id = "rbxassetid://113440921474935",
			ScaleType = Enum.ScaleType.Fit,
		},
		{
			Id = "rbxassetid://110703867969634",
			ScaleType = Enum.ScaleType.Crop,
		},
		{
			Id = "rbxassetid://87701424695968",
			ScaleType = Enum.ScaleType.Stretch,
		},
		{
			Id = "rbxassetid://117705810423288",
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromScale(0.5, 0.5),
		},
	},
	Columns = 2,
	ImageSize = UDim2.fromOffset(170, 0), -- Height 0 = auto (1:1 ratio), set a non-zero Y for a rectangular image
	SelectText = "Select",
	SelectedText = "Active",
	MultiSelect = true,
	Callback = function(Selected)
		print("Advanced image selection changed")
	end
})

-- Access the value via Options
print("Default selected images:", Options.SingleImagePicker.Value)

local Input = Tabs.Main:CreateInput("Input", {
    Title = "Input",
    Default = "Default",
    Placeholder = "Placeholder",
    Numeric = false, -- Only allows numbers
    Finished = false, -- Only calls callback when you press enter
    Callback = function(Value)
        print("Input changed:", Value)
    end
})

Input:OnChanged(function()
    print("Input updated:", Input.Value)
end)

Tabs.Main:CreateButton{
    Title = "Really Really big Dropdown",
    Description = "",
    Callback = function()
        local Values = {}

        for i = 1, 1000 do
            Values[i] = i
        end

        Tabs.Main:AddDropdown("BIGDropdown", {
            Title = "Big Dropdown",
            Values = Values,
            Multi = false,
            Default = 1,
        })
    end
}

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?, but honestly i prefer to save it )
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes{}

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Library:Notify{
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
}

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()