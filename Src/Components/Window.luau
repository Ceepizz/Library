local Root = script.Parent.Parent
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
			TabFrameSize = UDim2.new(0, Window.TabWidth, 1, -66)
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