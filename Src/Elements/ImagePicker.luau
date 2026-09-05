local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "ImagePicker"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "ImagePicker - Missing Title")
	assert(Config.Images, "ImagePicker - Missing Images table")

	local function ResolveImageId(ImageEntry)
		if typeof(ImageEntry) == "table" then
			return ImageEntry.Id
		end
		return ImageEntry
	end

	local function IsValidId(Id)
		return Id ~= nil and Id ~= ""
	end

	local ImagePicker = {
		Images = Config.Images or {},
		SelectedImages = {},
		SelectedIndexes = {},
		Columns = Config.Columns or 3,
		MultiSelect = Config.MultiSelect or false,
		ImageSize = Config.ImageSize or UDim2.fromOffset(100, 0),
		SelectText = Config.SelectText or "Select",
		SelectedText = Config.SelectedText or "Selected",
		Callback = Config.Callback or function(Selected) end,
		Changed = Config.Changed or function(Selected) end,
		Type = "ImagePicker",
		ImageButtons = {},
	}

	local function FindIndexesForIds(Ids)
		local Indexes = {}
		for _, WantedId in next, Ids do
			for Index, ImageEntry in next, ImagePicker.Images do
				if ResolveImageId(ImageEntry) == WantedId and not table.find(Indexes, Index) then
					table.insert(Indexes, Index)
					break
				end
			end
		end
		return Indexes
	end

	if IsValidId(Config.Default) or typeof(Config.Default) == "table" then
		local RawDefaults = ImagePicker.MultiSelect and (typeof(Config.Default) == "table" and Config.Default or {Config.Default}) or {Config.Default}
		local ResolvedIds = {}
		for _, Entry in next, RawDefaults do
			local ResolvedId = ResolveImageId(Entry)
			if IsValidId(ResolvedId) then
				table.insert(ResolvedIds, ResolvedId)
			end
		end
		local Indexes = FindIndexesForIds(ResolvedIds)
		if not ImagePicker.MultiSelect and #Indexes > 1 then
			Indexes = {Indexes[1]}
		end
		ImagePicker.SelectedIndexes = Indexes
	end

	local ImagePickerFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)

	ImagePicker.SetTitle = ImagePickerFrame.SetTitle
	ImagePicker.SetDesc = ImagePickerFrame.SetDesc

	local ImagePickerSize = ImagePicker.ImageSize
	local SelectButtonHeight = 30
	local ContainerPadding = 8
	local ImageVerticalPadding = 8

	local CellPaddingOffset = 10

	local function RecalculateCellSize()
		local ImageWidth = ImagePickerSize.X.Offset
		local ImageHeight = ImagePickerSize.Y.Offset

		if ImageHeight <= 0 then
			ImageHeight = ImageWidth
		end

		ImagePicker.ImageAreaWidth = ImageWidth
		ImagePicker.ImageAreaHeight = ImageHeight

		local CellWidth = ImageWidth
		local CellHeight = ImageHeight + ImageVerticalPadding + SelectButtonHeight + ContainerPadding

		return CellWidth, CellHeight
	end

	local InitialCellWidth, InitialCellHeight = RecalculateCellSize()

	local GridLayout = New("UIGridLayout", {
		CellSize = UDim2.fromOffset(InitialCellWidth, InitialCellHeight),
		CellPadding = UDim2.fromOffset(CellPaddingOffset, CellPaddingOffset),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = ImagePicker.Columns,
		StartCorner = Enum.StartCorner.TopLeft,
	})

	local GridFrame = New("Frame", {
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Parent = ImagePickerFrame.Frame,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 1,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 12),
		}),
		GridLayout,
	})

	local function RepositionGrid()
		GridFrame.Position = UDim2.fromOffset(10, ImagePickerFrame.LabelHolder.AbsoluteSize.Y)
	end

	local function RecalculateGridSize()
		RepositionGrid()
		ImagePickerFrame.Frame.Size = UDim2.new(1, 0, 0, ImagePickerFrame.LabelHolder.AbsoluteSize.Y + GridFrame.AbsoluteSize.Y)
	end

	Creator.AddSignal(ImagePickerFrame.LabelHolder:GetPropertyChangedSignal("AbsoluteSize"), RecalculateGridSize)

	local function IsImageIndexSelected(Index)
		for _, SelectedIndex in next, ImagePicker.SelectedIndexes do
			if SelectedIndex == Index then
				return true
			end
		end
		return false
	end

	local function SyncSelectedImages()
		local Ids = {}
		for _, Index in next, ImagePicker.SelectedIndexes do
			local ButtonData = ImagePicker.ImageButtons[Index]
			if ButtonData then
				table.insert(Ids, ButtonData.ImageId)
			end
		end
		ImagePicker.SelectedImages = Ids
		ImagePicker.Value = Ids
	end

	local function SetButtonSelected(Data, IsSelected)
		Data.SetSelected(IsSelected)
	end

	local function RefreshAllButtons()
		for Index, ButtonData in next, ImagePicker.ImageButtons do
			SetButtonSelected(ButtonData, IsImageIndexSelected(Index))
		end
	end

	local function CreateImageButton(ImageId, Index)
		local ImageData = typeof(ImageId) == "table" and ImageId or {Id = ImageId}
		local ImageUrl = ImageData.Id
		assert(ImageUrl ~= nil, "ImagePicker - Image entry missing Id")

		local EntrySize = ImageData.Size
		local SourceWidth = ImagePicker.ImageAreaWidth
		local SourceHeight = (EntrySize and EntrySize.Y.Offset > 0 and EntrySize.Y.Offset) or ImagePicker.ImageAreaHeight
		local ImageAspectRatio = SourceWidth / SourceHeight

		local Container = New("Frame", {
			Size = UDim2.fromOffset(SourceWidth, 0),
			BackgroundTransparency = 1,
		}, {
			New("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})

		local ImageContainer = New("Frame", {
			Size = UDim2.new(1, 0, 0, SourceHeight),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			New("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = ImageUrl,
				ScaleType = ImageData.ScaleType or Enum.ScaleType.Stretch,
				TileSize = ImageData.TileSize or UDim2.fromScale(1, 1),
				ImageRectOffset = ImageData.ImageRectOffset or Vector2.zero,
				ImageRectSize = ImageData.ImageRectSize or Vector2.zero,
			}, {
				New("UIAspectRatioConstraint", {
					AspectRatio = ImageAspectRatio,
					AspectType = Enum.AspectType.FitWithinMaxSize,
					DominantAxis = Enum.DominantAxis.Width,
				}),
				New("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
				New("UIStroke", {
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					ThemeTag = {
						Color = "InElementBorder",
					},
				}),
			}),
		})

		local SelectLabel = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
			Text = "Select",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			ZIndex = 4,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		local SelectIcon = New("ImageLabel", {
			Size = UDim2.fromOffset(14, 14),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 4,
			ThemeTag = {
				ImageColor3 = "Accent",
			},
		})

		local SelectBack = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			ThemeTag = {
				BackgroundColor3 = "Accent",
			},
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),
		})

		local SelectButton = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "",
			LayoutOrder = 2,
			ZIndex = 3,
			ThemeTag = {
				BackgroundColor3 = "DropdownFrame",
			},
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
			SelectBack,
			SelectLabel,
			SelectIcon,
		})

		Creator.AddThemeObject(SelectLabel, {
			TextColor3 = "Text",
		})

		local BackMotor, SetBackTransparency = Creator.SpringMotor(1, SelectButton, "BackgroundTransparency")
		local AccentMotor, SetAccentTransparency = Creator.SpringMotor(1, SelectBack, "BackgroundTransparency")

		local IsSelected = false

		local function SetSelected(Value)
			IsSelected = Value
			SelectLabel.Text = IsSelected and ImagePicker.SelectedText or ImagePicker.SelectText
			SelectIcon.Visible = IsSelected
			SetBackTransparency(IsSelected and 1 or 0.9)
			SetAccentTransparency(IsSelected and 0.8 or 1)
			SelectLabel.TextColor3 = Creator.GetThemeProperty(IsSelected and "Accent" or "Text")
		end

		Creator.AddSignal(SelectButton.MouseEnter, function()
			SetBackTransparency(IsSelected and 1 or 0.85)
			SetAccentTransparency(IsSelected and 0.7 or 1)
		end)

		Creator.AddSignal(SelectButton.MouseLeave, function()
			SetBackTransparency(IsSelected and 1 or 0.9)
			SetAccentTransparency(IsSelected and 0.8 or 1)
		end)

		Creator.AddSignal(SelectButton.MouseButton1Down, function()
			SetBackTransparency(IsSelected and 1 or 0.8)
			SetAccentTransparency(IsSelected and 0.65 or 1)
		end)

		Creator.AddSignal(SelectButton.MouseButton1Up, function()
			SetBackTransparency(IsSelected and 1 or 0.85)
			SetAccentTransparency(IsSelected and 0.7 or 1)
		end)

		ImageContainer.Parent = Container
		SelectButton.Parent = Container

		local ButtonData = {
			Button = SelectButton,
			ImageId = ImageUrl,
			Container = Container,
			SetSelected = SetSelected,
		}

		ImagePicker.ImageButtons[Index] = ButtonData

		Creator.AddSignal(SelectButton.MouseButton1Click, function()
			if ImagePicker.MultiSelect then
				if IsImageIndexSelected(Index) then
					for i, SelectedIndex in next, ImagePicker.SelectedIndexes do
						if SelectedIndex == Index then
							table.remove(ImagePicker.SelectedIndexes, i)
							break
						end
					end
				else
					table.insert(ImagePicker.SelectedIndexes, Index)
				end
			else
				ImagePicker.SelectedIndexes = {Index}
			end

			RefreshAllButtons()
			SyncSelectedImages()

			ImagePicker.Value = ImagePicker.SelectedImages

			if typeof(ImagePicker.Callback) == "function" then
				Library:SafeCallback(ImagePicker.Callback, ImagePicker.SelectedImages)
			end
			if typeof(ImagePicker.Changed) == "function" then
				Library:SafeCallback(ImagePicker.Changed, ImagePicker.SelectedImages)
			end
		end)

		return Container
	end

	function ImagePicker:BuildImageList()
		for _, ButtonData in next, ImagePicker.ImageButtons do
			ButtonData.Container:Destroy()
		end
		ImagePicker.ImageButtons = {}

		for Index, ImageId in next, ImagePicker.Images do
			local ImageButton = CreateImageButton(ImageId, Index)
			ImageButton.Parent = GridFrame
		end

		RecalculateGridSize()
	end

	function ImagePicker:SetValue(Images)
		local RawList = typeof(Images) == "table" and Images or {Images}
		local ResolvedIds = {}
		for _, Entry in next, RawList do
			local ResolvedId = ResolveImageId(Entry)
			if IsValidId(ResolvedId) then
				table.insert(ResolvedIds, ResolvedId)
			end
		end

		local Indexes = FindIndexesForIds(ResolvedIds)
		if not ImagePicker.MultiSelect and #Indexes > 1 then
			Indexes = {Indexes[1]}
		end
		ImagePicker.SelectedIndexes = Indexes

		RefreshAllButtons()
		SyncSelectedImages()

		ImagePicker.Value = ImagePicker.SelectedImages

		if typeof(ImagePicker.Callback) == "function" then
			Library:SafeCallback(ImagePicker.Callback, ImagePicker.SelectedImages)
		end
		if typeof(ImagePicker.Changed) == "function" then
			Library:SafeCallback(ImagePicker.Changed, ImagePicker.SelectedImages)
		end
	end

	function ImagePicker:SetImages(NewImages)
		ImagePicker.Images = NewImages
		ImagePicker.SelectedIndexes = {}
		ImagePicker.SelectedImages = {}
		local NewCellWidth, NewCellHeight = RecalculateCellSize()
		GridLayout.CellSize = UDim2.fromOffset(NewCellWidth, NewCellHeight)
		ImagePicker:BuildImageList()
	end

	function ImagePicker:OnChanged(Func)
		ImagePicker.Changed = Func
		Library:SafeCallback(Func, ImagePicker.SelectedImages)
	end

	function ImagePicker:Destroy()
		ImagePickerFrame:Destroy()
		Library.Options[Idx] = nil
	end

	ImagePicker:BuildImageList()
	SyncSelectedImages()
	RefreshAllButtons()

	ImagePicker.Value = ImagePicker.SelectedImages

	Library.Options[Idx] = ImagePicker
	ImagePicker.Instance = ImagePickerFrame

	return setmetatable(ImagePicker, {
		__index = function(self, key)
			return rawget(ImagePicker, key) or Element[key]
		end
	})
end

return Element