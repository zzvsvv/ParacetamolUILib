-- ParacetamolUILib
-- Client-side Roblox Luau UI library. Use from a LocalScript or executor loadstring.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.ParacetamolUILibConfigs = _G.ParacetamolUILibConfigs or {}

local Library = {}
Library.__index = Library

Library.Defaults = {
	AccentColor = Color3.fromRGB(255, 54, 91),
	BackgroundColor = Color3.fromRGB(7, 8, 10),
	ModuleColor = Color3.fromRGB(12, 13, 16),
	PanelColor = Color3.fromRGB(16, 17, 21),
	TextColor = Color3.fromRGB(235, 238, 242),
	MutedTextColor = Color3.fromRGB(132, 137, 146),
	Saveable = true,
	SaveKey = "ParacetamolConfig",
	Blur = true,
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Module = {}
Module.__index = Module

local function cloneTable(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = typeof(value) == "table" and cloneTable(value) or value
	end
	return copy
end

local function merge(base, overrides)
	local result = cloneTable(base)
	for key, value in pairs(overrides or {}) do
		result[key] = value
	end
	return result
end

local function make(className, props, parent)
	local obj = Instance.new(className)
	for key, value in pairs(props or {}) do
		obj[key] = value
	end
	obj.Parent = parent
	return obj
end

local function corner(parent, radius)
	return make("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
	}, parent)
end

local function stroke(parent, color, transparency, thickness)
	return make("UIStroke", {
		Color = color or Color3.fromRGB(65, 67, 74),
		Transparency = transparency or 0.45,
		Thickness = thickness or 1,
	}, parent)
end

local function tween(obj, props, duration)
	local info = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function colorRecord(color)
	return {
		R = math.floor(color.R * 255 + 0.5),
		G = math.floor(color.G * 255 + 0.5),
		B = math.floor(color.B * 255 + 0.5),
	}
end

local function fromRecord(record, fallback)
	if typeof(record) ~= "table" then
		return fallback
	end
	return Color3.fromRGB(
		math.clamp(tonumber(record.R) or 0, 0, 255),
		math.clamp(tonumber(record.G) or 0, 0, 255),
		math.clamp(tonumber(record.B) or 0, 0, 255)
	)
end

local function safeCall(callback, ...)
	if not callback then
		return
	end

	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))
		if not ok then
			warn("[ParacetamolUILib] Callback error:", err)
		end
	end)
end

local function text(parent, value, size, bold)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = value or "",
		TextColor3 = Color3.fromRGB(235, 238, 242),
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
		TextSize = size or 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

function Library:Init(options)
	self.Defaults = merge(self.Defaults, options or {})
	return self
end

function Library:CreateWindow(title, options)
	local settings = merge(self.Defaults, options or {})

	local window = setmetatable({
		Title = title or "Paracetamol",
		Settings = settings,
		Saveable = settings.Saveable == true,
		SaveKey = settings.SaveKey or "ParacetamolConfig",
		Tabs = {},
		Controls = {},
		Connections = {},
		ThemeObjects = {},
		ThemeCallbacks = {},
		ControlValues = {},
		ActiveTab = nil,
		Destroyed = false,
		Minimized = false,
	}, Window)

	window:_readConfig()
	window:_build()
	return window
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.Connections, connection)
	return connection
end

function Window:_theme(obj, property, setting)
	table.insert(self.ThemeObjects, {
		Object = obj,
		Property = property,
		Setting = setting,
	})
	obj[property] = self.Settings[setting]
end

function Window:_onTheme(callback)
	table.insert(self.ThemeCallbacks, callback)
end

function Window:_applyTheme()
	for _, item in ipairs(self.ThemeObjects) do
		if item.Object and item.Object.Parent and self.Settings[item.Setting] then
			item.Object[item.Property] = self.Settings[item.Setting]
		end
	end

	for _, callback in ipairs(self.ThemeCallbacks) do
		callback()
	end

	if self.ActiveTab then
		self:SelectTab(self.ActiveTab)
	end
end

function Window:_readConfig()
	local saved = _G.ParacetamolUILibConfigs[self.SaveKey]
	if not saved then
		return
	end

	self.ControlValues = cloneTable(saved.Controls or {})
	if typeof(saved.Theme) == "table" then
		self.Settings.AccentColor = fromRecord(saved.Theme.AccentColor, self.Settings.AccentColor)
		self.Settings.BackgroundColor = fromRecord(saved.Theme.BackgroundColor, self.Settings.BackgroundColor)
		self.Settings.ModuleColor = fromRecord(saved.Theme.ModuleColor, self.Settings.ModuleColor)
		self.Settings.PanelColor = fromRecord(saved.Theme.PanelColor, self.Settings.PanelColor)
		self.Settings.TextColor = fromRecord(saved.Theme.TextColor, self.Settings.TextColor)
	end
end

function Window:_build()
	local oldGui = PlayerGui:FindFirstChild("ParacetamolUILib")
	if oldGui then
		oldGui:Destroy()
	end

	local oldBlur = Lighting:FindFirstChild("ParacetamolUILibBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	local blur
	if self.Settings.Blur then
		blur = make("BlurEffect", {
			Name = "ParacetamolUILibBlur",
			Size = 0,
		}, Lighting)
		tween(blur, {Size = 14}, 0.25)
	end

	local gui = make("ScreenGui", {
		Name = "ParacetamolUILib",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	local dim = make("Frame", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.32,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, gui)

	local main = make("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(760, 520),
		Position = UDim2.new(0.5, -380, 0.5, -260),
		BackgroundColor3 = self.Settings.BackgroundColor,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, gui)
	corner(main, 18)
	stroke(main, Color3.fromRGB(65, 24, 34), 0.15, 1)
	self:_theme(main, "BackgroundColor3", "BackgroundColor")

	local side = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 74, 1, 0),
		BackgroundColor3 = Color3.fromRGB(5, 6, 8),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, main)
	corner(side, 18)
	stroke(side, Color3.fromRGB(50, 18, 26), 0.35, 1)

	local logo = make("TextLabel", {
		Name = "Logo",
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.fromOffset(10, 12),
		BackgroundTransparency = 1,
		Text = "S",
		TextColor3 = Color3.fromRGB(245, 246, 248),
		Font = Enum.Font.GothamBlack,
		TextSize = 32,
		ZIndex = 7,
	}, side)

	local logoLine = make("Frame", {
		Size = UDim2.fromOffset(52, 1),
		Position = UDim2.fromOffset(11, 84),
		BackgroundColor3 = Color3.fromRGB(57, 24, 31),
		BorderSizePixel = 0,
		ZIndex = 7,
	}, side)

	local tabsHolder = make("Frame", {
		Name = "Tabs",
		Size = UDim2.new(1, 0, 1, -130),
		Position = UDim2.fromOffset(0, 102),
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, side)

	local tabsLayout = make("UIListLayout", {
		Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabsHolder)

	local settingsButton = make("TextButton", {
		Name = "Settings",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(0.5, -21, 1, -54),
		BackgroundColor3 = Color3.fromRGB(11, 12, 15),
		Text = "O",
		TextColor3 = self.Settings.MutedTextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
		ZIndex = 8,
	}, side)
	corner(settingsButton, 10)

	local top = make("Frame", {
		Name = "TopDrag",
		Size = UDim2.new(1, -88, 0, 40),
		Position = UDim2.fromOffset(82, 0),
		BackgroundTransparency = 1,
		ZIndex = 8,
	}, main)

	local titleLabel = text(top, self.Title, 13, true)
	titleLabel.Size = UDim2.new(1, -82, 1, 0)
	titleLabel.TextColor3 = self.Settings.MutedTextColor
	titleLabel.ZIndex = 9

	local minimize = make("TextButton", {
		Size = UDim2.fromOffset(30, 26),
		Position = UDim2.new(1, -66, 0, 8),
		BackgroundColor3 = Color3.fromRGB(14, 15, 18),
		Text = "-",
		TextColor3 = self.Settings.MutedTextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		AutoButtonColor = false,
		ZIndex = 9,
	}, top)
	corner(minimize, 8)

	local close = make("TextButton", {
		Size = UDim2.fromOffset(30, 26),
		Position = UDim2.new(1, -32, 0, 8),
		BackgroundColor3 = Color3.fromRGB(14, 15, 18),
		Text = "X",
		TextColor3 = self.Settings.MutedTextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 9,
	}, top)
	corner(close, 8)

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -92, 1, -24),
		Position = UDim2.fromOffset(82, 12),
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, main)

	self.Gui = gui
	self.Blur = blur
	self.Dim = dim
	self.Main = main
	self.Sidebar = side
	self.TabsHolder = tabsHolder
	self.TabContent = content
	self.TabsLayout = tabsLayout

	self:_connect(settingsButton.MouseButton1Click, function()
		self:OpenSettingsPanel()
	end)

	self:_connect(minimize.MouseButton1Click, function()
		self.Minimized = not self.Minimized
		content.Visible = not self.Minimized
		tween(main, {
			Size = self.Minimized and UDim2.fromOffset(760, 74) or UDim2.fromOffset(760, 520),
		}, 0.2)
	end)

	self:_connect(close.MouseButton1Click, function()
		self.Gui.Enabled = false
		if self.Blur then
			tween(self.Blur, {Size = 0}, 0.18)
		end
	end)

	self:_makeDraggable(top)

	self:_onTheme(function()
		logo.TextColor3 = self.Settings.TextColor
		settingsButton.TextColor3 = self.Settings.MutedTextColor
	end)

	dim.Active = false
	logoLine.Active = false
end

function Window:_makeDraggable(handle)
	local dragging = false
	local dragStart
	local startPos

	self:_connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self.Main.Position
		end
	end)

	self:_connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	self:_connect(UserInputService.InputChanged, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			self.Main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Window:SaveConfig()
	if not self.Saveable then
		return
	end

	_G.ParacetamolUILibConfigs[self.SaveKey] = {
		Controls = cloneTable(self.ControlValues),
		Theme = {
			AccentColor = colorRecord(self.Settings.AccentColor),
			BackgroundColor = colorRecord(self.Settings.BackgroundColor),
			ModuleColor = colorRecord(self.Settings.ModuleColor),
			PanelColor = colorRecord(self.Settings.PanelColor),
			TextColor = colorRecord(self.Settings.TextColor),
		},
	}
end

function Window:LoadConfig()
	self:_readConfig()
	for _, control in ipairs(self.Controls) do
		local value = self.ControlValues[control.Key]
		if value ~= nil then
			control:SetValue(value, true)
		end
	end
	self:_applyTheme()
end

function Window:_setControlValue(key, value)
	self.ControlValues[key] = typeof(value) == "table" and cloneTable(value) or value
	self:SaveConfig()
end

function Window:CreateTab(name, icon)
	local icons = {"MAIN", "X", "->", "[]", "P", "K", "SET", "()", "O"}
	local tab = setmetatable({
		Name = name or "Tab",
		Icon = icon or icons[(#self.Tabs % #icons) + 1],
		Window = self,
		Modules = {},
		NextColumn = 1,
	}, Tab)

	local button = make("TextButton", {
		Name = tab.Name .. "Tab",
		Size = UDim2.fromOffset(54, 42),
		BackgroundColor3 = Color3.fromRGB(9, 10, 13),
		BackgroundTransparency = 1,
		Text = tab.Icon,
		TextColor3 = self.Settings.MutedTextColor,
		Font = Enum.Font.GothamBold,
		TextSize = tab.Icon == "MAIN" and 9 or 15,
		AutoButtonColor = false,
		ZIndex = 8,
	}, self.TabsHolder)
	corner(button, 10)

	local activeBar = make("Frame", {
		Size = UDim2.fromOffset(3, 30),
		Position = UDim2.fromOffset(-1, 6),
		BackgroundColor3 = self.Settings.AccentColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 9,
	}, button)
	corner(activeBar, 3)
	self:_theme(activeBar, "BackgroundColor3", "AccentColor")

	local page = make("Frame", {
		Name = tab.Name .. "Page",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 7,
	}, self.TabContent)

	local scroll = make("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self.Settings.AccentColor,
		CanvasSize = UDim2.fromOffset(0, 0),
		ZIndex = 7,
	}, page)
	self:_theme(scroll, "ScrollBarImageColor3", "AccentColor")

	local columnRow = make("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, scroll)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, columnRow)

	local left = make("Frame", {
		Name = "Left",
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, columnRow)

	local right = make("Frame", {
		Name = "Right",
		Size = UDim2.new(0.5, -5, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, columnRow)

	local leftLayout = make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, left)

	local rightLayout = make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, right)

	local function updateCanvas()
		local height = math.max(leftLayout.AbsoluteContentSize.Y, rightLayout.AbsoluteContentSize.Y) + 18
		scroll.CanvasSize = UDim2.fromOffset(0, height)
		columnRow.Size = UDim2.new(1, -8, 0, height)
	end

	self:_connect(leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	self:_connect(rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	self:_connect(button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)

	tab.Button = button
	tab.ActiveBar = activeBar
	tab.Page = page
	tab.Scroll = scroll
	tab.Columns = {left, right}

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	for _, other in ipairs(self.Tabs) do
		local active = other == tab
		other.Page.Visible = active
		tween(other.Button, {
			BackgroundTransparency = active and 0 or 1,
			TextColor3 = active and self.Settings.TextColor or self.Settings.MutedTextColor,
		}, 0.14)
		tween(other.ActiveBar, {
			BackgroundTransparency = active and 0 or 1,
		}, 0.14)
	end
	self.ActiveTab = tab
end

function Window:OpenSettingsPanel()
	if self.SettingsPanel and self.SettingsPanel.Parent then
		self.SettingsPanel.Visible = not self.SettingsPanel.Visible
		return
	end

	local panel = make("Frame", {
		Name = "SettingsPanel",
		Size = UDim2.fromOffset(300, 286),
		Position = UDim2.new(1, -312, 0, 52),
		BackgroundColor3 = self.Settings.ModuleColor,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, self.Main)
	corner(panel, 12)
	stroke(panel, Color3.fromRGB(86, 31, 44), 0.22, 1)
	self:_theme(panel, "BackgroundColor3", "ModuleColor")
	self.SettingsPanel = panel

	local title = text(panel, "Settings", 16, true)
	title.Size = UDim2.new(1, -20, 0, 34)
	title.Position = UDim2.fromOffset(10, 8)
	title.ZIndex = 51
	self:_theme(title, "TextColor3", "TextColor")

	local list = make("Frame", {
		Size = UDim2.new(1, -20, 1, -54),
		Position = UDim2.fromOffset(10, 46),
		BackgroundTransparency = 1,
		ZIndex = 51,
	}, panel)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	local function editor(label, setting)
		local row = make("Frame", {
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = self.Settings.PanelColor,
			BorderSizePixel = 0,
			ZIndex = 52,
		}, list)
		corner(row, 8)
		self:_theme(row, "BackgroundColor3", "PanelColor")

		local name = text(row, label, 12, true)
		name.Size = UDim2.fromOffset(92, 1)
		name.Position = UDim2.fromOffset(9, 0)
		name.ZIndex = 53
		self:_theme(name, "TextColor3", "TextColor")

		local c = self.Settings[setting]
		local values = {
			R = math.floor(c.R * 255 + 0.5),
			G = math.floor(c.G * 255 + 0.5),
			B = math.floor(c.B * 255 + 0.5),
		}

		local boxes = make("Frame", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.fromOffset(102, 9),
			BackgroundTransparency = 1,
			ZIndex = 53,
		}, row)

		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, boxes)

		for _, channel in ipairs({"R", "G", "B"}) do
			local box = make("TextBox", {
				Size = UDim2.new(0.333, -4, 1, 0),
				BackgroundColor3 = Color3.fromRGB(9, 10, 12),
				Text = tostring(values[channel]),
				TextColor3 = self.Settings.TextColor,
				PlaceholderText = channel,
				Font = Enum.Font.GothamMedium,
				TextSize = 11,
				ClearTextOnFocus = false,
				ZIndex = 54,
			}, boxes)
			corner(box, 7)
			self:_theme(box, "TextColor3", "TextColor")

			self:_connect(box.FocusLost, function()
				local number = math.clamp(tonumber(box.Text) or values[channel], 0, 255)
				values[channel] = number
				box.Text = tostring(number)
				self.Settings[setting] = Color3.fromRGB(values.R, values.G, values.B)
				self:_applyTheme()
				self:SaveConfig()
			end)
		end
	end

	editor("Accent", "AccentColor")
	editor("Background", "BackgroundColor")
	editor("Module", "ModuleColor")
	editor("Text", "TextColor")
end

function Window:Destroy()
	if self.Destroyed then
		return
	end

	self.Destroyed = true
	for _, connection in ipairs(self.Connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	if self.Blur then
		self.Blur:Destroy()
	end
	if self.Gui then
		self.Gui:Destroy()
	end
end

function Tab:CreateModule(title)
	local column = self.Columns[self.NextColumn]
	self.NextColumn = self.NextColumn == 1 and 2 or 1

	local module = setmetatable({
		Title = title or "Module",
		Tab = self,
		Window = self.Window,
		ControlNameCounts = {},
		Controls = {},
		Collapsed = false,
	}, Module)

	local frame = make("Frame", {
		Name = module.Title,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Window.Settings.ModuleColor,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 10,
	}, column)
	corner(frame, 10)
	stroke(frame, Color3.fromRGB(67, 24, 34), 0.2, 1)
	self.Window:_theme(frame, "BackgroundColor3", "ModuleColor")

	make("UIPadding", {
		PaddingTop = UDim.new(0, 9),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, frame)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)

	local header = make("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 11,
	}, frame)

	local titleText = text(header, module.Title, 16, true)
	titleText.Size = UDim2.new(1, -46, 1, 0)
	titleText.ZIndex = 12
	self.Window:_theme(titleText, "TextColor3", "TextColor")

	local key = make("TextLabel", {
		Size = UDim2.fromOffset(34, 20),
		Position = UDim2.new(1, -34, 0.5, -10),
		BackgroundColor3 = Color3.fromRGB(9, 10, 12),
		Text = "KEY",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 8,
		ZIndex = 12,
	}, header)
	corner(key, 8)
	stroke(key, Color3.fromRGB(65, 67, 74), 0.65, 1)
	self.Window:_theme(key, "TextColor3", "TextColor")

	local divider = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(48, 23, 30),
		BorderSizePixel = 0,
		ZIndex = 11,
	}, frame)

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 11,
	}, frame)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)

	self.Window:_connect(header.MouseButton1Click, function()
		module.Collapsed = not module.Collapsed
		content.Visible = not module.Collapsed
		divider.Visible = not module.Collapsed
		key.Text = module.Collapsed and "+" or "KEY"
	end)

	module.Frame = frame
	module.Content = content
	table.insert(self.Modules, module)
	return module
end

function Module:_key(label)
	self.ControlNameCounts[label] = (self.ControlNameCounts[label] or 0) + 1
	local suffix = self.ControlNameCounts[label] > 1 and "_" .. tostring(self.ControlNameCounts[label]) or ""
	return self.Title .. "." .. label .. suffix
end

function Module:_register(label, defaultValue, setter, getter)
	local key = self:_key(label)
	local control = {
		Key = key,
		Label = label,
		SetValue = setter,
		GetValue = getter,
	}

	table.insert(self.Controls, control)
	table.insert(self.Window.Controls, control)

	local loaded = self.Window.ControlValues[key]
	if loaded ~= nil then
		setter(loaded, true)
	else
		self.Window:_setControlValue(key, defaultValue)
	end

	return control
end

function Module:AddToggle(label, defaultValue, callback)
	local value = defaultValue == true
	local key

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(row, label or "Enabled", 12, false)
	labelText.Size = UDim2.new(1, -48, 1, 0)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 13

	local switch = make("TextButton", {
		Size = UDim2.fromOffset(34, 17),
		Position = UDim2.new(1, -34, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(104, 107, 114),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
	}, row)
	corner(switch, 9)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(13, 13),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(245, 247, 250),
		BorderSizePixel = 0,
		ZIndex = 14,
	}, switch)
	corner(knob, 7)

	local function redraw()
		switch.BackgroundColor3 = value and self.Window.Settings.AccentColor or Color3.fromRGB(104, 107, 114)
		knob.Position = value and UDim2.fromOffset(19, 2) or UDim2.fromOffset(2, 2)
	end

	local function setValue(newValue, silent)
		value = newValue == true
		tween(switch, {
			BackgroundColor3 = value and self.Window.Settings.AccentColor or Color3.fromRGB(104, 107, 114),
		}, 0.14)
		tween(knob, {
			Position = value and UDim2.fromOffset(19, 2) or UDim2.fromOffset(2, 2),
		}, 0.14)

		if key then
			self.Window:_setControlValue(key, value)
		end
		if not silent then
			safeCall(callback, value)
		end
	end

	self.Window:_connect(switch.MouseButton1Click, function()
		setValue(not value, false)
	end)
	self.Window:_onTheme(redraw)

	local control = self:_register(label or "Toggle", value, setValue, function()
		return value
	end)
	key = control.Key
	redraw()
	return control
end

function Module:AddSlider(label, min, max, defaultValue, callback)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	if max <= min then
		max = min + 1
	end

	local value = math.clamp(tonumber(defaultValue) or min, min, max)
	local key
	local dragging = false

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 45),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(row, label or "Slider", 12, false)
	labelText.Size = UDim2.new(1, -70, 0, 18)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 13

	local valueText = text(row, "0.00", 13, true)
	valueText.Size = UDim2.fromOffset(66, 18)
	valueText.Position = UDim2.new(1, -66, 0, 0)
	valueText.TextXAlignment = Enum.TextXAlignment.Right
	valueText.ZIndex = 13
	self.Window:_theme(valueText, "TextColor3", "TextColor")

	local track = make("Frame", {
		Size = UDim2.new(1, -4, 0, 3),
		Position = UDim2.fromOffset(2, 31),
		BackgroundColor3 = Color3.fromRGB(31, 32, 36),
		BorderSizePixel = 0,
		ZIndex = 13,
	}, row)
	corner(track, 3)

	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = self.Window.Settings.AccentColor,
		BorderSizePixel = 0,
		ZIndex = 14,
	}, track)
	corner(fill, 3)
	self.Window:_theme(fill, "BackgroundColor3", "AccentColor")

	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, -7, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(245, 247, 250),
		BorderSizePixel = 0,
		ZIndex = 15,
	}, track)
	corner(knob, 7)

	local function percent()
		return math.clamp((value - min) / (max - min), 0, 1)
	end

	local function setValue(newValue, silent)
		value = math.clamp(tonumber(newValue) or min, min, max)
		local p = percent()
		valueText.Text = string.format("%.2f", value)
		tween(fill, {Size = UDim2.fromScale(p, 1)}, 0.08)
		tween(knob, {Position = UDim2.new(p, -7, 0.5, -7)}, 0.08)

		if key then
			self.Window:_setControlValue(key, value)
		end
		if not silent then
			safeCall(callback, value)
		end
	end

	local function setFromX(x)
		local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + ((max - min) * p), false)
	end

	self.Window:_connect(track.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	self.Window:_connect(knob.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)
	self.Window:_connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	self.Window:_connect(UserInputService.InputChanged, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
		end
	end)

	local control = self:_register(label or "Slider", value, setValue, function()
		return value
	end)
	key = control.Key
	setValue(value, true)
	return control
end

function Module:AddButton(label, callback)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(18, 19, 23),
		Text = label or "Button",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 12,
	}, self.Content)
	corner(button, 7)
	stroke(button, Color3.fromRGB(68, 70, 78), 0.55, 1)
	self.Window:_theme(button, "TextColor3", "TextColor")

	self.Window:_connect(button.MouseEnter, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(24, 25, 30)}, 0.1)
	end)
	self.Window:_connect(button.MouseLeave, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(18, 19, 23)}, 0.1)
	end)
	self.Window:_connect(button.MouseButton1Down, function()
		tween(button, {BackgroundColor3 = self.Window.Settings.AccentColor}, 0.08)
	end)
	self.Window:_connect(button.MouseButton1Up, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(24, 25, 30)}, 0.08)
	end)
	self.Window:_connect(button.MouseButton1Click, function()
		safeCall(callback)
	end)

	return button
end

function Module:AddDropdown(label, options, multipleOptions, callback)
	options = options or {}
	multipleOptions = multipleOptions == true

	local selected = multipleOptions and {} or tostring(options[1] or "")
	local key
	local open = false
	local optionButtons = {}

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(container, label or "Enum", 12, false)
	labelText.Size = UDim2.new(1, 0, 0, 18)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.Active = true
	labelText.ZIndex = 13

	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 22),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 13,
	}, container)

	local chips = make("Frame", {
		Size = UDim2.new(1, -34, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 14,
	}, button)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 7),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, chips)

	local openButton = make("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -28, 0, 0),
		BackgroundColor3 = Color3.fromRGB(16, 17, 21),
		Text = "v",
		TextColor3 = self.Window.Settings.MutedTextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 15,
	}, button)
	corner(openButton, 8)
	stroke(openButton, Color3.fromRGB(64, 65, 72), 0.65, 1)

	local dropdown = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 56),
		BackgroundColor3 = Color3.fromRGB(10, 11, 14),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 16,
	}, container)
	corner(dropdown, 8)
	stroke(dropdown, Color3.fromRGB(64, 65, 72), 0.5, 1)

	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, dropdown)

	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, dropdown)

	local function currentValue()
		if not multipleOptions then
			return selected
		end

		local result = {}
		for _, option in ipairs(options) do
			local opt = tostring(option)
			if selected[opt] then
				table.insert(result, opt)
			end
		end
		return result
	end

	local function persist(silent)
		if key then
			self.Window:_setControlValue(key, currentValue())
		end
		if not silent then
			safeCall(callback, currentValue())
		end
	end

	local function refresh()
		for _, child in ipairs(chips:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for index, option in ipairs(options) do
			local opt = tostring(option)
			local active = multipleOptions and selected[opt] == true or selected == opt
			local chip = make("TextButton", {
				Size = UDim2.fromOffset(index == 1 and 66 or 72, 28),
				BackgroundColor3 = active and Color3.fromRGB(24, 25, 30) or Color3.fromRGB(16, 17, 21),
				Text = opt,
				TextColor3 = active and self.Window.Settings.TextColor or self.Window.Settings.MutedTextColor,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				AutoButtonColor = false,
				ZIndex = 15,
			}, chips)
			corner(chip, 8)
			stroke(chip, active and self.Window.Settings.AccentColor or Color3.fromRGB(64, 65, 72), active and 0.25 or 0.65, 1)

			self.Window:_connect(chip.MouseButton1Click, function()
				if multipleOptions then
					selected[opt] = not selected[opt]
				else
					selected = opt
				end
				refresh()
				persist(false)
			end)
		end

		for option, optionButton in pairs(optionButtons) do
			local active = multipleOptions and selected[option] == true or selected == option
			optionButton.BackgroundColor3 = active and self.Window.Settings.AccentColor or Color3.fromRGB(20, 21, 25)
		end
	end

	local function setOpen(state)
		open = state
		openButton.Text = open and "^" or "v"
		local height = open and (62 + (#options * 30) + 12) or 54
		tween(container, {Size = UDim2.new(1, 0, 0, height)}, 0.18)
		tween(dropdown, {Size = UDim2.new(1, 0, 0, open and ((#options * 30) + 12) or 0)}, 0.18)
	end

	self.Window:_connect(openButton.MouseButton1Click, function()
		setOpen(not open)
	end)

	self.Window:_connect(labelText.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			setOpen(not open)
		end
	end)

	for _, option in ipairs(options) do
		local opt = tostring(option)
		local optionButton = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(20, 21, 25),
			Text = opt,
			TextColor3 = self.Window.Settings.TextColor,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			AutoButtonColor = false,
			ZIndex = 17,
		}, dropdown)
		corner(optionButton, 7)
		optionButtons[opt] = optionButton

		self.Window:_connect(optionButton.MouseButton1Click, function()
			if multipleOptions then
				selected[opt] = not selected[opt]
			else
				selected = opt
				setOpen(false)
			end
			refresh()
			persist(false)
		end)
	end

	local function setValue(newValue, silent)
		if multipleOptions then
			selected = {}
			if typeof(newValue) == "table" then
				for _, item in ipairs(newValue) do
					selected[tostring(item)] = true
				end
			end
		else
			selected = tostring(newValue or options[1] or "")
		end
		refresh()
		persist(silent)
	end

	self.Window:_onTheme(refresh)

	local control = self:_register(label or "Dropdown", currentValue(), setValue, currentValue)
	key = control.Key
	refresh()
	return control
end

Library.Window = Window
Library.Tab = Tab
Library.Module = Module

return Library
