-- ParacetamolUILib
-- Client-side Roblox Luau UI library.
-- Designed for LocalScripts / executors. Persistent test saving uses _G.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.ParacetamolUILibConfigs = _G.ParacetamolUILibConfigs or {}

local Library = {}
Library.__index = Library

Library.Defaults = {
	AccentColor = Color3.fromRGB(0, 170, 255),
	BackgroundColor = Color3.fromRGB(45, 45, 45),
	ModuleColor = Color3.fromRGB(55, 55, 55),
	TextColor = Color3.fromRGB(235, 235, 235),
	Saveable = true,
	SaveKey = "ParacetamolConfig",
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Module = {}
Module.__index = Module

local Control = {}
Control.__index = Control

local function cloneTable(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		copy[key] = typeof(value) == "table" and cloneTable(value) or value
	end
	return copy
end

local function mergeOptions(base, overrides)
	local result = cloneTable(base)
	for key, value in pairs(overrides or {}) do
		result[key] = value
	end
	return result
end

local function make(className, props, parent)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

local function addCorner(parent, radius)
	return make("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
	}, parent)
end

local function addStroke(parent, color, transparency, thickness)
	return make("UIStroke", {
		Color = color or Color3.fromRGB(100, 100, 100),
		Transparency = transparency or 0.45,
		Thickness = thickness or 1,
	}, parent)
end

local function tween(instance, props, duration)
	local info = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenObject = TweenService:Create(instance, info, props)
	tweenObject:Play()
	return tweenObject
end

local function colorToRecord(color)
	return {
		R = math.floor(color.R * 255 + 0.5),
		G = math.floor(color.G * 255 + 0.5),
		B = math.floor(color.B * 255 + 0.5),
	}
end

local function recordToColor(record, fallback)
	if typeof(record) ~= "table" then
		return fallback
	end

	return Color3.fromRGB(
		math.clamp(tonumber(record.R) or 0, 0, 255),
		math.clamp(tonumber(record.G) or 0, 0, 255),
		math.clamp(tonumber(record.B) or 0, 0, 255)
	)
end

local function createText(parent, text, size, bold)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.fromRGB(235, 235, 235),
		Font = bold and Enum.Font.GothamBold or Enum.Font.GothamSemibold,
		TextSize = size or 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
end

local function safeCallback(callback, ...)
	if callback then
		local args = table.pack(...)
		task.spawn(function()
			local ok, err = pcall(callback, table.unpack(args, 1, args.n))
			if not ok then
				warn("[ParacetamolUILib] Callback error:", err)
			end
		end)
	end
end

function Library:Init(options)
	self.Defaults = mergeOptions(self.Defaults, options or {})
	return self
end

function Library:CreateWindow(title, options)
	local settings = mergeOptions(self.Defaults, options or {})

	local window = setmetatable({
		Title = title or "Window",
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
		Minimized = false,
		Destroyed = false,
	}, Window)

	window:_loadRawConfig()
	window:_build()
	return window
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.Connections, connection)
	return connection
end

function Window:_theme(instance, property, settingName)
	table.insert(self.ThemeObjects, {
		Instance = instance,
		Property = property,
		SettingName = settingName,
	})
	instance[property] = self.Settings[settingName]
end

function Window:_applyTheme()
	for _, item in ipairs(self.ThemeObjects) do
		if item.Instance and item.Instance.Parent and self.Settings[item.SettingName] then
			item.Instance[item.Property] = self.Settings[item.SettingName]
		end
	end

	for _, callback in ipairs(self.ThemeCallbacks) do
		callback()
	end

	if self.ActiveTab then
		self:SelectTab(self.ActiveTab)
	end
end

function Window:_onThemeChanged(callback)
	table.insert(self.ThemeCallbacks, callback)
end

function Window:_loadRawConfig()
	local saved = _G.ParacetamolUILibConfigs[self.SaveKey]
	if not saved then
		return
	end

	self.ControlValues = cloneTable(saved.Controls or {})

	if typeof(saved.Theme) == "table" then
		self.Settings.AccentColor = recordToColor(saved.Theme.AccentColor, self.Settings.AccentColor)
		self.Settings.BackgroundColor = recordToColor(saved.Theme.BackgroundColor, self.Settings.BackgroundColor)
		self.Settings.ModuleColor = recordToColor(saved.Theme.ModuleColor, self.Settings.ModuleColor)
		self.Settings.TextColor = recordToColor(saved.Theme.TextColor, self.Settings.TextColor)
	end
end

function Window:_build()
	local old = PlayerGui:FindFirstChild("ParacetamolUILib")
	if old then
		old:Destroy()
	end

	local gui = make("ScreenGui", {
		Name = "ParacetamolUILib",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)

	local main = make("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(710, 520),
		Position = UDim2.new(0.5, -355, 0.5, -260),
		BackgroundColor3 = self.Settings.BackgroundColor,
		BorderSizePixel = 0,
	}, gui)
	addCorner(main, 12)
	addStroke(main, Color3.fromRGB(95, 95, 95), 0.25, 1)
	self:_theme(main, "BackgroundColor3", "BackgroundColor")

	local topBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, main)

	local title = createText(topBar, self.Title, 18, true)
	title.Name = "Title"
	title.Size = UDim2.new(1, -150, 1, 0)
	title.Position = UDim2.fromOffset(14, 0)
	self:_theme(title, "TextColor3", "TextColor")

	local settingsButton = make("TextButton", {
		Name = "SettingsButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -106, 0, 7),
		BackgroundColor3 = self.Settings.ModuleColor,
		Text = "G",
		TextColor3 = self.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
	}, topBar)
	addCorner(settingsButton, 8)
	self:_theme(settingsButton, "BackgroundColor3", "ModuleColor")
	self:_theme(settingsButton, "TextColor3", "TextColor")

	local minimizeButton = make("TextButton", {
		Name = "MinimizeButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -70, 0, 7),
		BackgroundColor3 = self.Settings.ModuleColor,
		Text = "-",
		TextColor3 = self.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
	}, topBar)
	addCorner(minimizeButton, 8)
	self:_theme(minimizeButton, "BackgroundColor3", "ModuleColor")
	self:_theme(minimizeButton, "TextColor3", "TextColor")

	local closeButton = make("TextButton", {
		Name = "CloseButton",
		Size = UDim2.fromOffset(30, 30),
		Position = UDim2.new(1, -34, 0, 7),
		BackgroundColor3 = Color3.fromRGB(185, 55, 70),
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
	}, topBar)
	addCorner(closeButton, 8)

	local tabBar = make("ScrollingFrame", {
		Name = "TabBar",
		Size = UDim2.new(1, -20, 0, 42),
		Position = UDim2.fromOffset(10, 46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.fromOffset(0, 0),
	}, main)

	local tabLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)

	local holder = make("Frame", {
		Name = "TabHolder",
		Size = UDim2.new(1, -20, 1, -100),
		Position = UDim2.fromOffset(10, 90),
		BackgroundTransparency = 1,
	}, main)

	self.Gui = gui
	self.Main = main
	self.TopBar = topBar
	self.TabBar = tabBar
	self.TabHolder = holder

	self:_connect(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		tabBar.CanvasSize = UDim2.fromOffset(tabLayout.AbsoluteContentSize.X + 8, 0)
	end)

	self:_connect(settingsButton.MouseButton1Click, function()
		self:OpenSettingsPanel()
	end)

	self:_connect(minimizeButton.MouseButton1Click, function()
		self.Minimized = not self.Minimized
		tabBar.Visible = not self.Minimized
		holder.Visible = not self.Minimized
		tween(main, {
			Size = self.Minimized and UDim2.fromOffset(710, 44) or UDim2.fromOffset(710, 520),
		}, 0.2)
	end)

	self:_connect(closeButton.MouseButton1Click, function()
		gui.Enabled = false
	end)

	self:_makeDraggable(topBar)
end

function Window:_makeDraggable(handle)
	local dragging = false
	local dragStart = nil
	local startPosition = nil

	self:_connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPosition = self.Main.Position
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
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
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
			AccentColor = colorToRecord(self.Settings.AccentColor),
			BackgroundColor = colorToRecord(self.Settings.BackgroundColor),
			ModuleColor = colorToRecord(self.Settings.ModuleColor),
			TextColor = colorToRecord(self.Settings.TextColor),
		},
	}
end

function Window:LoadConfig()
	self:_loadRawConfig()

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

function Window:CreateTab(name)
	local tab = setmetatable({
		Name = name or "Tab",
		Window = self,
		Modules = {},
	}, Tab)

	local button = make("TextButton", {
		Name = tab.Name .. "Button",
		Size = UDim2.fromOffset(120, 32),
		BackgroundColor3 = self.Settings.ModuleColor,
		Text = tab.Name,
		TextColor3 = self.Settings.TextColor,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		AutoButtonColor = false,
	}, self.TabBar)
	addCorner(button, 8)
	self:_theme(button, "TextColor3", "TextColor")

	local frame = make("ScrollingFrame", {
		Name = tab.Name .. "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.fromOffset(0, 0),
		Visible = false,
	}, self.TabHolder)

	make("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 8),
	}, frame)

	local layout = make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)

	self:_connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		frame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 18)
	end)

	self:_connect(button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)

	tab.Button = button
	tab.Frame = frame
	tab.Layout = layout

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self:SelectTab(tab)
	else
		button.BackgroundColor3 = self.Settings.ModuleColor
	end

	return tab
end

function Window:SelectTab(tab)
	for _, other in ipairs(self.Tabs) do
		local active = other == tab
		other.Frame.Visible = active
		tween(other.Button, {
			BackgroundColor3 = active and self.Settings.AccentColor or self.Settings.ModuleColor,
		}, 0.16)
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
		Size = UDim2.fromOffset(320, 350),
		Position = UDim2.new(1, -340, 0, 56),
		BackgroundColor3 = self.Settings.BackgroundColor,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, self.Main)
	addCorner(panel, 10)
	addStroke(panel, Color3.fromRGB(105, 105, 105), 0.25, 1)
	self:_theme(panel, "BackgroundColor3", "BackgroundColor")
	self.SettingsPanel = panel

	local header = createText(panel, "Settings", 16, true)
	header.Size = UDim2.new(1, -20, 0, 34)
	header.Position = UDim2.fromOffset(10, 6)
	header.ZIndex = 21
	self:_theme(header, "TextColor3", "TextColor")

	local list = make("Frame", {
		Size = UDim2.new(1, -20, 1, -50),
		Position = UDim2.fromOffset(10, 44),
		BackgroundTransparency = 1,
		ZIndex = 21,
	}, panel)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	local function colorEditor(label, settingName)
		local block = make("Frame", {
			Size = UDim2.new(1, 0, 0, 68),
			BackgroundColor3 = self.Settings.ModuleColor,
			BorderSizePixel = 0,
			ZIndex = 21,
		}, list)
		addCorner(block, 8)
		self:_theme(block, "BackgroundColor3", "ModuleColor")

		local text = createText(block, label, 12, true)
		text.Size = UDim2.new(1, -12, 0, 22)
		text.Position = UDim2.fromOffset(8, 4)
		text.ZIndex = 22
		self:_theme(text, "TextColor3", "TextColor")

		local color = self.Settings[settingName]
		local values = {
			R = math.floor(color.R * 255 + 0.5),
			G = math.floor(color.G * 255 + 0.5),
			B = math.floor(color.B * 255 + 0.5),
		}

		local row = make("Frame", {
			Size = UDim2.new(1, -12, 0, 30),
			Position = UDim2.fromOffset(6, 30),
			BackgroundTransparency = 1,
			ZIndex = 22,
		}, block)

		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)

		for _, channel in ipairs({"R", "G", "B"}) do
			local box = make("TextBox", {
				Size = UDim2.new(0.333, -4, 1, 0),
				BackgroundColor3 = Color3.fromRGB(38, 38, 38),
				Text = tostring(values[channel]),
				TextColor3 = self.Settings.TextColor,
				PlaceholderText = channel,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				ClearTextOnFocus = false,
				ZIndex = 23,
			}, row)
			addCorner(box, 6)
			self:_theme(box, "TextColor3", "TextColor")

			self:_connect(box.FocusLost, function()
				local number = tonumber(box.Text)
				number = math.clamp(number or values[channel], 0, 255)
				values[channel] = number
				box.Text = tostring(number)
				self.Settings[settingName] = Color3.fromRGB(values.R, values.G, values.B)
				self:_applyTheme()
				self:SaveConfig()
			end)
		end
	end

	colorEditor("Accent Color", "AccentColor")
	colorEditor("Background Color", "BackgroundColor")
	colorEditor("Module Color", "ModuleColor")
	colorEditor("Text Color", "TextColor")
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

	table.clear(self.Connections)

	if self.Gui then
		self.Gui:Destroy()
	end
end

function Tab:CreateModule(title)
	local module = setmetatable({
		Title = title or "Module",
		Tab = self,
		Window = self.Window,
		Controls = {},
		ControlNameCounts = {},
		Collapsed = false,
	}, Module)

	local frame = make("Frame", {
		Name = module.Title,
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Window.Settings.ModuleColor,
		BorderSizePixel = 0,
	}, self.Frame)
	addCorner(frame, 10)
	addStroke(frame, Color3.fromRGB(120, 120, 120), 0.55, 1)
	self.Window:_theme(frame, "BackgroundColor3", "ModuleColor")

	make("UIPadding", {
		PaddingTop = UDim.new(0, 10),
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
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}, frame)

	local titleLabel = createText(header, module.Title, 20, true)
	titleLabel.Size = UDim2.new(1, -54, 1, 0)
	self.Window:_theme(titleLabel, "TextColor3", "TextColor")

	local collapseLabel = make("TextLabel", {
		Size = UDim2.fromOffset(42, 24),
		Position = UDim2.new(1, -42, 0, 5),
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		Text = "key",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
	}, header)
	addCorner(collapseLabel, 8)
	self.Window:_theme(collapseLabel, "TextColor3", "TextColor")

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, frame)

	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)

	self.Window:_connect(header.MouseButton1Click, function()
		module.Collapsed = not module.Collapsed
		content.Visible = not module.Collapsed
		collapseLabel.Text = module.Collapsed and "+" or "key"
	end)

	module.Frame = frame
	module.Content = content
	table.insert(self.Modules, module)
	return module
end

function Module:_nextKey(label)
	self.ControlNameCounts[label] = (self.ControlNameCounts[label] or 0) + 1
	local suffix = self.ControlNameCounts[label] > 1 and "_" .. tostring(self.ControlNameCounts[label]) or ""
	return self.Title .. "." .. label .. suffix
end

function Module:_registerControl(label, defaultValue, setValue, getValue)
	local key = self:_nextKey(label)
	local control = setmetatable({
		Key = key,
		Label = label,
		SetValue = setValue,
		GetValue = getValue,
	}, Control)

	table.insert(self.Controls, control)
	table.insert(self.Window.Controls, control)

	local loaded = self.Window.ControlValues[key]
	if loaded ~= nil then
		control:SetValue(loaded, true)
	else
		self.Window:_setControlValue(key, defaultValue)
	end

	return control
end

function Module:AddToggle(label, defaultValue, callback)
	local value = defaultValue == true
	local controlKey = nil

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
	}, self.Content)

	local text = createText(row, label or "Enabled", 15, true)
	text.Size = UDim2.new(1, -64, 1, 0)
	self.Window:_theme(text, "TextColor3", "TextColor")

	local switch = make("TextButton", {
		Size = UDim2.fromOffset(48, 24),
		Position = UDim2.new(1, -48, 0.5, -12),
		BackgroundColor3 = Color3.fromRGB(92, 92, 92),
		Text = "",
		AutoButtonColor = false,
	}, row)
	addCorner(switch, 12)

	local knob = make("Frame", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Color3.fromRGB(245, 245, 245),
		BorderSizePixel = 0,
	}, switch)
	addCorner(knob, 10)

	local function setValue(newValue, silent)
		value = newValue == true
		tween(switch, {
			BackgroundColor3 = value and self.Window.Settings.AccentColor or Color3.fromRGB(92, 92, 92),
		}, 0.16)
		tween(knob, {
			Position = value and UDim2.fromOffset(26, 2) or UDim2.fromOffset(2, 2),
		}, 0.16)

		if controlKey then
			self.Window:_setControlValue(controlKey, value)
		end

		if not silent then
			safeCallback(callback, value)
		end
	end

	self.Window:_onThemeChanged(function()
		switch.BackgroundColor3 = value and self.Window.Settings.AccentColor or Color3.fromRGB(92, 92, 92)
	end)

	self.Window:_connect(switch.MouseButton1Click, function()
		setValue(not value)
	end)

	local control = self:_registerControl(label or "Toggle", value, setValue, function()
		return value
	end)
	controlKey = control.Key
	setValue(value, true)
	return control
end

function Module:AddSlider(label, min, max, defaultValue, callback)
	min = tonumber(min) or 0
	max = tonumber(max) or 1
	if max <= min then
		max = min + 1
	end

	local value = math.clamp(tonumber(defaultValue) or min, min, max)
	local dragging = false
	local controlKey = nil

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
	}, self.Content)

	local text = createText(row, label or "Slider", 15, true)
	text.Size = UDim2.new(1, -86, 0, 22)
	self.Window:_theme(text, "TextColor3", "TextColor")

	local valueLabel = createText(row, "0.00", 15, true)
	valueLabel.Size = UDim2.fromOffset(82, 22)
	valueLabel.Position = UDim2.new(1, -82, 0, 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.Window:_theme(valueLabel, "TextColor3", "TextColor")

	local track = make("Frame", {
		Size = UDim2.new(1, -8, 0, 5),
		Position = UDim2.fromOffset(4, 38),
		BackgroundColor3 = Color3.fromRGB(32, 32, 32),
		BorderSizePixel = 0,
	}, row)
	addCorner(track, 4)

	local fill = make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = self.Window.Settings.AccentColor,
		BorderSizePixel = 0,
	}, track)
	addCorner(fill, 4)
	self.Window:_theme(fill, "BackgroundColor3", "AccentColor")

	local knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, -8, 0.5, -8),
		BackgroundColor3 = self.Window.Settings.AccentColor,
		BorderSizePixel = 0,
	}, track)
	addCorner(knob, 8)
	self.Window:_theme(knob, "BackgroundColor3", "AccentColor")

	local function percentFromValue(newValue)
		return math.clamp((newValue - min) / (max - min), 0, 1)
	end

	local function setValue(newValue, silent)
		value = math.clamp(tonumber(newValue) or min, min, max)
		local percent = percentFromValue(value)
		valueLabel.Text = string.format("%.2f", value)
		tween(fill, {Size = UDim2.fromScale(percent, 1)}, 0.08)
		tween(knob, {Position = UDim2.new(percent, -8, 0.5, -8)}, 0.08)

		if controlKey then
			self.Window:_setControlValue(controlKey, value)
		end

		if not silent then
			safeCallback(callback, value)
		end
	end

	local function setFromX(x)
		local percent = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + ((max - min) * percent), false)
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

	local control = self:_registerControl(label or "Slider", value, setValue, function()
		return value
	end)
	controlKey = control.Key
	setValue(value, true)
	return control
end

function Module:AddButton(label, callback)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(66, 66, 66),
		Text = label or "Button",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		AutoButtonColor = false,
	}, self.Content)
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(120, 120, 120), 0.65, 1)
	self.Window:_theme(button, "TextColor3", "TextColor")

	self.Window:_connect(button.MouseEnter, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(78, 78, 78)}, 0.12)
	end)

	self.Window:_connect(button.MouseLeave, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(66, 66, 66)}, 0.12)
	end)

	self.Window:_connect(button.MouseButton1Down, function()
		tween(button, {BackgroundColor3 = self.Window.Settings.AccentColor}, 0.08)
	end)

	self.Window:_connect(button.MouseButton1Up, function()
		tween(button, {BackgroundColor3 = Color3.fromRGB(78, 78, 78)}, 0.08)
	end)

	self.Window:_connect(button.MouseButton1Click, function()
		safeCallback(callback)
	end)

	return button
end

function Module:AddDropdown(label, options, multipleOptions, callback)
	options = options or {}
	multipleOptions = multipleOptions == true

	local selected = multipleOptions and {} or tostring(options[1] or "")
	local optionButtons = {}
	local opened = false
	local controlKey = nil

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, self.Content)

	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(66, 66, 66),
		Text = "",
		AutoButtonColor = false,
	}, container)
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(120, 120, 120), 0.65, 1)

	local display = createText(button, label or "Dropdown", 14, true)
	display.Size = UDim2.new(1, -44, 1, 0)
	display.Position = UDim2.fromOffset(10, 0)
	self.Window:_theme(display, "TextColor3", "TextColor")

	local arrow = make("TextLabel", {
		Size = UDim2.fromOffset(28, 34),
		Position = UDim2.new(1, -32, 0, 0),
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
	}, button)
	self.Window:_theme(arrow, "TextColor3", "TextColor")

	local optionsFrame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, container)
	addCorner(optionsFrame, 8)
	addStroke(optionsFrame, Color3.fromRGB(95, 95, 95), 0.6, 1)

	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, optionsFrame)

	make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, optionsFrame)

	local function currentValue()
		if not multipleOptions then
			return selected
		end

		local result = {}
		for _, option in ipairs(options) do
			local textOption = tostring(option)
			if selected[textOption] then
				table.insert(result, textOption)
			end
		end
		return result
	end

	local function displayText()
		if not multipleOptions then
			return tostring(label or "Dropdown") .. "  |  " .. tostring(selected)
		end

		local count = 0
		for _, isSelected in pairs(selected) do
			if isSelected then
				count += 1
			end
		end

		if count == 0 then
			return tostring(label or "Dropdown")
		end

		return tostring(label or "Dropdown") .. "  |  " .. tostring(count) .. " selected"
	end

	local function refresh()
		display.Text = displayText()
		for option, optionButton in pairs(optionButtons) do
			local active = multipleOptions and selected[option] == true or selected == option
			optionButton.BackgroundColor3 = active and self.Window.Settings.AccentColor or Color3.fromRGB(58, 58, 58)
		end
	end

	self.Window:_onThemeChanged(refresh)

	local function persistAndCallback(silent)
		if controlKey then
			self.Window:_setControlValue(controlKey, currentValue())
		end

		if not silent then
			safeCallback(callback, currentValue())
		end
	end

	local function setOpened(state)
		opened = state
		local optionsHeight = (#options * 30) + 12
		local containerHeight = opened and (44 + optionsHeight) or 38
		arrow.Text = opened and "^" or "v"
		tween(container, {Size = UDim2.new(1, 0, 0, containerHeight)}, 0.18)
		tween(optionsFrame, {Size = UDim2.new(1, 0, 0, opened and optionsHeight or 0)}, 0.18)
	end

	local function setValue(newValue, silent)
		if multipleOptions then
			selected = {}
			if typeof(newValue) == "table" then
				for _, option in ipairs(newValue) do
					selected[tostring(option)] = true
				end
			end
		else
			selected = tostring(newValue or options[1] or "")
		end

		refresh()
		persistAndCallback(silent)
	end

	self.Window:_connect(button.MouseButton1Click, function()
		setOpened(not opened)
	end)

	for _, option in ipairs(options) do
		local optionText = tostring(option)
		local optionButton = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(58, 58, 58),
			Text = optionText,
			TextColor3 = self.Window.Settings.TextColor,
			Font = Enum.Font.GothamSemibold,
			TextSize = 13,
			AutoButtonColor = false,
		}, optionsFrame)
		addCorner(optionButton, 7)
		self.Window:_theme(optionButton, "TextColor3", "TextColor")
		optionButtons[optionText] = optionButton

		self.Window:_connect(optionButton.MouseButton1Click, function()
			if multipleOptions then
				selected[optionText] = not selected[optionText]
			else
				selected = optionText
				setOpened(false)
			end

			refresh()
			persistAndCallback(false)
		end)
	end

	local control = self:_registerControl(label or "Dropdown", currentValue(), setValue, currentValue)
	controlKey = control.Key
	refresh()
	return control
end

Library.Window = Window
Library.Tab = Tab
Library.Module = Module

return Library
