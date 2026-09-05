local Root = script.Parent.Parent
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