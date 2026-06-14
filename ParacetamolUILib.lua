-- ParacetamolUILib
-- Client-side Roblox Luau UI library. Use from a LocalScript or executor loadstring.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.ParacetamolUILibConfigs = _G.ParacetamolUILibConfigs or {}

local Library = {}
Library.__index = Library

Library.Defaults = {
	AccentColor = Color3.fromRGB(255, 54, 91),
	BackgroundColor = Color3.fromRGB(8, 9, 12),
	ModuleColor = Color3.fromRGB(13, 14, 18),
	PanelColor = Color3.fromRGB(18, 19, 24),
	TextColor = Color3.fromRGB(242, 244, 248),
	MutedTextColor = Color3.fromRGB(150, 155, 166),
	IconColor = Color3.fromRGB(242, 244, 248),
	Saveable = true,
	SaveKey = "ParacetamolConfig",
	Blur = true,
	ToggleKey = Enum.KeyCode.RightShift,
}

Library.Icons = {
	User = "User",
	Home = "Home",
	Gun = "Gun",
	Settings = "Settings",
	Misc = "Misc",
	Code = "Code",
	Terminal = "Terminal",
	Search = "Search",
}

Library.ThemePresets = {
	Paracetamol = {
		AccentColor = Color3.fromRGB(255, 54, 91),
		BackgroundColor = Color3.fromRGB(8, 9, 12),
		ModuleColor = Color3.fromRGB(13, 14, 18),
		PanelColor = Color3.fromRGB(18, 19, 24),
		TextColor = Color3.fromRGB(242, 244, 248),
		MutedTextColor = Color3.fromRGB(150, 155, 166),
		IconColor = Color3.fromRGB(242, 244, 248),
	},
	Tokyo = {
		AccentColor = Color3.fromRGB(122, 101, 255),
		BackgroundColor = Color3.fromRGB(11, 12, 20),
		ModuleColor = Color3.fromRGB(18, 19, 31),
		PanelColor = Color3.fromRGB(25, 26, 42),
		TextColor = Color3.fromRGB(236, 239, 255),
		MutedTextColor = Color3.fromRGB(144, 151, 183),
		IconColor = Color3.fromRGB(226, 229, 255),
	},
	Mint = {
		AccentColor = Color3.fromRGB(57, 202, 151),
		BackgroundColor = Color3.fromRGB(7, 13, 13),
		ModuleColor = Color3.fromRGB(12, 22, 21),
		PanelColor = Color3.fromRGB(18, 32, 30),
		TextColor = Color3.fromRGB(235, 255, 249),
		MutedTextColor = Color3.fromRGB(138, 171, 162),
		IconColor = Color3.fromRGB(228, 255, 246),
	},
	Quartz = {
		AccentColor = Color3.fromRGB(92, 164, 205),
		BackgroundColor = Color3.fromRGB(13, 12, 18),
		ModuleColor = Color3.fromRGB(20, 19, 29),
		PanelColor = Color3.fromRGB(29, 27, 40),
		TextColor = Color3.fromRGB(241, 246, 255),
		MutedTextColor = Color3.fromRGB(151, 159, 179),
		IconColor = Color3.fromRGB(239, 247, 255),
	},
	Fatality = {
		AccentColor = Color3.fromRGB(210, 18, 87),
		BackgroundColor = Color3.fromRGB(13, 8, 19),
		ModuleColor = Color3.fromRGB(21, 13, 31),
		PanelColor = Color3.fromRGB(30, 19, 43),
		TextColor = Color3.fromRGB(255, 239, 247),
		MutedTextColor = Color3.fromRGB(178, 137, 158),
		IconColor = Color3.fromRGB(255, 237, 247),
	},
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
	local info = TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function resolveFont(name, fallback)
	local ok, font = pcall(function()
		return Enum.Font[name]
	end)

	if ok and font then
		return font
	end

	return fallback
end

local Fonts = {
	Regular = resolveFont("BuilderSans", Enum.Font.Gotham),
	Medium = resolveFont("BuilderSansMedium", Enum.Font.GothamMedium),
	SemiBold = resolveFont("BuilderSansSemiBold", Enum.Font.GothamSemibold),
	Bold = resolveFont("BuilderSansBold", Enum.Font.GothamBold),
}

local function iconName(value)
	value = tostring(value or "Misc")
	return Library.Icons[value] or value
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
		Font = bold and Fonts.SemiBold or Fonts.Regular,
		TextSize = size or 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

local function createPrimitiveIcon(parent, name, color, zIndex)
	local icon = {
		Parts = {},
	}

	local root = make("Frame", {
		Name = "PrimitiveIcon",
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = zIndex or 1,
	}, parent)
	icon.Scale = make("UIScale", {
		Scale = 1,
	}, root)

	local function addColorable(instance, property)
		table.insert(icon.Parts, {Instance = instance, Property = property or "BackgroundColor3"})
	end

	local function line(x, y, w, h, rotation)
		local part = make("Frame", {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Rotation = rotation or 0,
			ZIndex = root.ZIndex + 1,
		}, root)
		corner(part, math.max(2, math.floor(h / 2)))
		addColorable(part)
		return part
	end

	local function ring(x, y, w, h, thickness)
		local part = make("Frame", {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			BackgroundTransparency = 1,
			ZIndex = root.ZIndex + 1,
		}, root)
		corner(part, math.floor(math.min(w, h) / 2))
		local outline = stroke(part, color, 0, thickness or 2)
		addColorable(outline, "Color")
		return part
	end

	local function dot(x, y, size)
		local part = make("Frame", {
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = root.ZIndex + 1,
		}, root)
		corner(part, math.floor(size / 2))
		addColorable(part)
		return part
	end

	name = iconName(name)

	if name == "Home" then
		line(4, 8, 10, 2, -38)
		line(9, 8, 10, 2, 38)
		line(6, 11, 2, 8, 0)
		line(15, 11, 2, 8, 0)
		line(6, 18, 11, 2, 0)
	elseif name == "User" then
		ring(7, 2, 8, 8, 2)
		ring(4, 12, 14, 8, 2)
	elseif name == "Gun" then
		line(4, 8, 14, 3, 0)
		line(15, 6, 4, 2, 0)
		line(7, 11, 8, 2, 0)
		line(8, 12, 3, 8, -18)
		line(13, 11, 4, 2, 45)
	elseif name == "Settings" then
		ring(7, 7, 8, 8, 2)
		for _, data in ipairs({
			{10, 1, 2, 5, 0},
			{10, 16, 2, 5, 0},
			{1, 10, 5, 2, 0},
			{16, 10, 5, 2, 0},
			{3, 4, 5, 2, 45},
			{15, 16, 5, 2, 45},
			{15, 4, 5, 2, -45},
			{3, 16, 5, 2, -45},
		}) do
			line(data[1], data[2], data[3], data[4], data[5])
		end
	elseif name == "Code" then
		line(5, 6, 8, 2, -42)
		line(5, 14, 8, 2, 42)
		line(11, 6, 8, 2, 42)
		line(11, 14, 8, 2, -42)
		line(10, 3, 2, 16, 14)
	elseif name == "Terminal" then
		line(5, 7, 7, 2, 35)
		line(5, 13, 7, 2, -35)
		line(12, 17, 8, 2, 0)
	elseif name == "Search" then
		ring(4, 4, 11, 11, 2)
		line(13, 14, 7, 2, 45)
	elseif name == "Misc" then
		for _, pos in ipairs({{4, 4}, {13, 4}, {4, 13}, {13, 13}}) do
			dot(pos[1], pos[2], 5)
		end
	else
		line(4, 5, 14, 2, 0)
		line(4, 10, 14, 2, 0)
		line(4, 15, 14, 2, 0)
	end

	icon.Root = root

	function icon:SetColor(newColor)
		for _, part in ipairs(self.Parts) do
			if part.Instance and part.Instance.Parent then
				part.Instance[part.Property] = newColor
			end
		end
	end

	icon:SetColor(color)
	return icon
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
		Notifications = {},
		KeybindRows = {},
		UnloadCallbacks = {},
		ShowKeybinds = true,
		ActiveTab = nil,
		Destroyed = false,
		Minimized = false,
		Visible = true,
		ToggleKey = settings.ToggleKey,
	}, Window)

	window:_readConfig()
	window:_build()
	window:_createSettingsTab()
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

	self:_refreshTabVisuals()
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
		self.Settings.MutedTextColor = fromRecord(saved.Theme.MutedTextColor, self.Settings.MutedTextColor)
		self.Settings.IconColor = fromRecord(saved.Theme.IconColor, self.Settings.IconColor)
	end
end

function Window:_build()
	local oldGui = PlayerGui:FindFirstChild("ParacetamolUILib")
	if oldGui then
		oldGui:Destroy()
	end

	local gui = make("ScreenGui", {
		Name = "ParacetamolUILib",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 999999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, PlayerGui)
	pcall(function()
		gui.DisplayOrder = 2147483647
	end)
	pcall(function()
		gui.OnTopOfCoreBlur = true
	end)

	local main = make("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(760, 520),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = self.Settings.BackgroundColor,
		BackgroundTransparency = self.Settings.Blur and 0.18 or 0.04,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, gui)
	local mainScale = make("UIScale", {
		Scale = 1,
	}, main)
	corner(main, 18)
	stroke(main, Color3.fromRGB(255, 58, 95), 0.68, 1)
	self:_theme(main, "BackgroundColor3", "BackgroundColor")

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 25, 31)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(8, 9, 12)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 10, 14)),
		}),
		Rotation = 35,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.04),
			NumberSequenceKeypoint.new(0.62, 0.16),
			NumberSequenceKeypoint.new(1, 0.08),
		}),
	}, main)

	local glow = make("Frame", {
		Name = "Glow",
		Size = UDim2.new(1, 22, 1, 22),
		Position = UDim2.fromOffset(-11, -11),
		BackgroundColor3 = self.Settings.AccentColor,
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, main)
	corner(glow, 22)
	self:_theme(glow, "BackgroundColor3", "AccentColor")

	main.Size = UDim2.fromOffset(724, 492)
	main.Position = UDim2.new(0.5, 0, 0.5, 14)
	main.BackgroundTransparency = 1
	glow.BackgroundTransparency = 1
	tween(main, {
		Size = UDim2.fromOffset(760, 520),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = self.Settings.Blur and 0.18 or 0.04,
	}, 0.38)
	tween(glow, {BackgroundTransparency = 0.9}, 0.45)

	local side = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 74, 1, 0),
		BackgroundColor3 = Color3.fromRGB(5, 6, 9),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, main)
	corner(side, 18)
	stroke(side, Color3.fromRGB(255, 58, 95), 0.82, 1)

	local logo = createPrimitiveIcon(side, "Home", self.Settings.IconColor, 7)
	logo.Root.Name = "Logo"
	logo.Root.Position = UDim2.fromOffset(37, 39)

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
		BackgroundColor3 = self.Settings.IconColor,
		BackgroundTransparency = 0.82,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, side)
	corner(settingsButton, 10)
	local settingsIcon = createPrimitiveIcon(settingsButton, "Settings", self.Settings.MutedTextColor, 9)

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
		Font = Fonts.Bold,
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
		Font = Fonts.Bold,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = 9,
	}, top)
	corner(close, 8)

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -92, 1, -58),
		Position = UDim2.fromOffset(82, 46),
		BackgroundTransparency = 1,
		ZIndex = 7,
	}, main)

	self.Gui = gui
	self.Glow = glow
	self.Main = main
	self.MainScale = mainScale
	self.Sidebar = side
	self.TabsHolder = tabsHolder
	self.TabContent = content
	self.TabsLayout = tabsLayout
	self.SettingsButton = settingsButton
	self.SettingsIcon = settingsIcon
	self.NotificationHolder = make("Frame", {
		Name = "Notifications",
		Size = UDim2.fromOffset(280, 420),
		Position = UDim2.new(1, -296, 0, 16),
		BackgroundTransparency = 1,
		ZIndex = 100,
	}, gui)
	make("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.NotificationHolder)

	self.Watermark = make("Frame", {
		Name = "Watermark",
		Size = UDim2.fromOffset(0, 28),
		Position = UDim2.fromOffset(16, 16),
		BackgroundColor3 = self.Settings.ModuleColor,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 100,
	}, gui)
	corner(self.Watermark, 9)
	local watermarkStroke = stroke(self.Watermark, self.Settings.AccentColor, 0.55, 1)
	self:_theme(self.Watermark, "BackgroundColor3", "ModuleColor")

	self.WatermarkLabel = text(self.Watermark, "", 12, true)
	self.WatermarkLabel.Size = UDim2.new(1, -18, 1, 0)
	self.WatermarkLabel.Position = UDim2.fromOffset(9, 0)
	self.WatermarkLabel.ZIndex = 101
	self.WatermarkLabel.TextColor3 = self.Settings.TextColor
	self:_theme(self.WatermarkLabel, "TextColor3", "TextColor")

	self.KeybindFrame = make("Frame", {
		Name = "Keybinds",
		Size = UDim2.fromOffset(210, 34),
		Position = UDim2.fromOffset(16, 52),
		BackgroundColor3 = self.Settings.ModuleColor,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		ZIndex = 100,
	}, gui)
	corner(self.KeybindFrame, 9)
	local keybindStroke = stroke(self.KeybindFrame, self.Settings.AccentColor, 0.58, 1)
	self:_theme(self.KeybindFrame, "BackgroundColor3", "ModuleColor")

	local keybindTitle = text(self.KeybindFrame, "Keybinds", 12, true)
	keybindTitle.Size = UDim2.new(1, -18, 0, 28)
	keybindTitle.Position = UDim2.fromOffset(9, 0)
	keybindTitle.TextColor3 = self.Settings.TextColor
	keybindTitle.ZIndex = 101
	self:_theme(keybindTitle, "TextColor3", "TextColor")

	self.KeybindList = make("Frame", {
		Name = "List",
		Size = UDim2.new(1, -14, 1, -32),
		Position = UDim2.fromOffset(7, 29),
		BackgroundTransparency = 1,
		ZIndex = 101,
	}, self.KeybindFrame)

	self.KeybindLayout = make("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, self.KeybindList)

	self.Tooltip = make("Frame", {
		Name = "Tooltip",
		Size = UDim2.fromOffset(220, 34),
		BackgroundColor3 = self.Settings.ModuleColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 200,
	}, gui)
	corner(self.Tooltip, 8)
	local tooltipStroke = stroke(self.Tooltip, self.Settings.AccentColor, 0.6, 1)
	self:_theme(self.Tooltip, "BackgroundColor3", "ModuleColor")

	self.TooltipLabel = text(self.Tooltip, "", 12, false)
	self.TooltipLabel.Size = UDim2.new(1, -16, 1, -8)
	self.TooltipLabel.Position = UDim2.fromOffset(8, 4)
	self.TooltipLabel.TextWrapped = true
	self.TooltipLabel.ZIndex = 201
	self.TooltipLabel.TextColor3 = self.Settings.TextColor
	self:_theme(self.TooltipLabel, "TextColor3", "TextColor")

	self:_connect(settingsButton.MouseButton1Click, function()
		if self.SettingsTab then
			self:SelectTab(self.SettingsTab)
		end
	end)

	self:_connect(minimize.MouseButton1Click, function()
		self.Minimized = not self.Minimized
		content.Visible = not self.Minimized
		tween(main, {
			Size = self.Minimized and UDim2.fromOffset(760, 74) or UDim2.fromOffset(760, 520),
		}, 0.2)
	end)

	self:_connect(close.MouseButton1Click, function()
		self:SetVisible(false)
	end)

	self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed or not self.ToggleKey then
			return
		end

		if input.KeyCode == self.ToggleKey then
			self:SetVisible(not self.Visible)
		end
	end)

	self:_makeDraggable(top)

	self:_onTheme(function()
		logo:SetColor(self.Settings.IconColor)
		settingsIcon:SetColor(self.ActiveTab == self.SettingsTab and self.Settings.IconColor or self.Settings.MutedTextColor)
		watermarkStroke.Color = self.Settings.AccentColor
		keybindStroke.Color = self.Settings.AccentColor
		tooltipStroke.Color = self.Settings.AccentColor
	end)

	logoLine.Active = false

	local function updateScale()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local viewport = camera.ViewportSize
		local scale = math.min((viewport.X - 28) / 760, (viewport.Y - 28) / 520, 1)
		mainScale.Scale = math.clamp(scale, 0.62, 1)
	end

	updateScale()
	if workspace.CurrentCamera then
		self:_connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
	end
	self:_connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		updateScale()
		if workspace.CurrentCamera then
			self:_connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
		end
	end)
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
			MutedTextColor = colorRecord(self.Settings.MutedTextColor),
			IconColor = colorRecord(self.Settings.IconColor),
		},
	}
end

function Window:LoadConfig()
	self:_readConfig()
	for _, control in ipairs(self.Controls) do
		local value = self.ControlValues[control.Key]
		if value ~= nil then
			control:SetValue(value, false)
		end
	end
	self:_applyTheme()
end

function Window:ExportConfig()
	self:SaveConfig()
	local data = _G.ParacetamolUILibConfigs[self.SaveKey] or {
		Controls = cloneTable(self.ControlValues),
	}

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)

	if not ok then
		self:Notify("Failed to export config", 2.5)
		return ""
	end

	if typeof(setclipboard) == "function" then
		pcall(setclipboard, encoded)
		self:Notify("Config copied to clipboard", 2.5)
	else
		self:Notify("Config exported", 2.5)
	end

	return encoded
end

function Window:ImportConfig(encoded)
	if type(encoded) ~= "string" or encoded == "" then
		self:Notify("No config text provided", 2.5)
		return false
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(encoded)
	end)

	if not ok or type(decoded) ~= "table" then
		self:Notify("Invalid config JSON", 2.5)
		return false
	end

	_G.ParacetamolUILibConfigs[self.SaveKey] = decoded
	self:LoadConfig()
	self:Notify("Config imported", 2.5)
	return true
end

function Window:_setControlValue(key, value)
	self.ControlValues[key] = typeof(value) == "table" and cloneTable(value) or value
	self:SaveConfig()

	for _, control in ipairs(self.Controls) do
		if control.Key == key and not control._SuppressChanged then
			local changedValue = typeof(value) == "table" and cloneTable(value) or value
			if control.ChangedCallbacks and #control.ChangedCallbacks > 0 then
				for _, callback in ipairs(control.ChangedCallbacks) do
					safeCall(callback, changedValue)
				end
			elseif control.Changed then
				safeCall(control.Changed, changedValue)
			end
		end
	end
end

function Window:CreateTab(name, icon)
	local icons = {Library.Icons.Home, Library.Icons.Gun, Library.Icons.User, Library.Icons.Misc, Library.Icons.Code, Library.Icons.Terminal}
	local tab = setmetatable({
		Name = name or "Tab",
		Icon = iconName(icon or icons[(#self.Tabs % #icons) + 1]),
		Window = self,
		Modules = {},
		NextColumn = 1,
	}, Tab)

	local button = make("TextButton", {
		Name = tab.Name .. "Tab",
		Size = UDim2.fromOffset(54, 42),
		BackgroundColor3 = self.Settings.IconColor,
		BackgroundTransparency = 0.84,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, self.TabsHolder)
	corner(button, 10)

	local iconGraphic = createPrimitiveIcon(button, tab.Icon, self.Settings.MutedTextColor, 9)

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

	local page = make("CanvasGroup", {
		Name = tab.Name .. "Page",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 7,
	}, self.TabContent)

	local searchBar = make("Frame", {
		Name = "SearchBar",
		Size = UDim2.new(1, -8, 0, 34),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = self.Settings.ModuleColor,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, page)
	corner(searchBar, 10)
	stroke(searchBar, Color3.fromRGB(68, 70, 78), 0.65, 1)
	self:_theme(searchBar, "BackgroundColor3", "ModuleColor")

	local searchIcon = createPrimitiveIcon(searchBar, "Search", self.Settings.MutedTextColor, 9)
	searchIcon.Root.Position = UDim2.fromOffset(18, 17)

	local searchBox = make("TextBox", {
		Name = "Search",
		Size = UDim2.new(1, -44, 1, 0),
		Position = UDim2.fromOffset(38, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search modules...",
		TextColor3 = self.Settings.TextColor,
		PlaceholderColor3 = self.Settings.MutedTextColor,
		Font = Fonts.Regular,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
		ZIndex = 9,
	}, searchBar)
	self:_theme(searchBox, "TextColor3", "TextColor")
	self:_theme(searchBox, "PlaceholderColor3", "MutedTextColor")
	self:_onTheme(function()
		searchIcon:SetColor(self.Settings.MutedTextColor)
	end)

	local scroll = make("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.new(1, 0, 1, -42),
		Position = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = self.Settings.AccentColor,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		ZIndex = 7,
	}, page)
	self:_theme(scroll, "ScrollBarImageColor3", "AccentColor")

	local columnRow = make("Frame", {
		Name = "Columns",
		Size = UDim2.new(1, -8, 0, 1),
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

	local function applyFilter()
		local query = string.lower(searchBox.Text or "")

		for _, module in ipairs(tab.Modules) do
			local visible = query == "" or string.find(module.SearchText or "", query, 1, true) ~= nil
			if module.Frame then
				module.Frame.Visible = visible
			end
		end

		task.defer(updateCanvas)
	end

	self:_connect(leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	self:_connect(rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	self:_connect(searchBox:GetPropertyChangedSignal("Text"), applyFilter)
	self:_connect(searchBox.Focused, function()
		tween(searchBar, {BackgroundTransparency = 0.1}, 0.12)
	end)
	self:_connect(searchBox.FocusLost, function()
		tween(searchBar, {BackgroundTransparency = 0.2}, 0.12)
	end)
	self:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if self.ActiveTab ~= tab then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape and searchBox.Text ~= "" then
			searchBox.Text = ""
		elseif gameProcessed then
			return
		end
	end)
	task.defer(updateCanvas)
	self:_connect(button.MouseButton1Click, function()
		self:SelectTab(tab)
	end)
	self:_connect(button.MouseEnter, function()
		if self.ActiveTab ~= tab then
			tween(button, {BackgroundTransparency = 0.72}, 0.16)
			iconGraphic:SetColor(self.Settings.IconColor)
		end
	end)
	self:_connect(button.MouseLeave, function()
		if self.ActiveTab ~= tab then
			tween(button, {BackgroundTransparency = 0.84}, 0.16)
			iconGraphic:SetColor(self.Settings.MutedTextColor)
		end
	end)

	tab.Button = button
	tab.IconGraphic = iconGraphic
	tab.ActiveBar = activeBar
	tab.Page = page
	tab.Scroll = scroll
	tab.SearchBox = searchBox
	tab.ApplyFilter = applyFilter
	tab.UpdateCanvas = updateCanvas
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
		if active then
			other.Page.Visible = true
			other.Page.Position = UDim2.fromOffset(14, 0)
		end

		tween(other.Button, {
			BackgroundColor3 = active and self.Settings.AccentColor or self.Settings.IconColor,
			BackgroundTransparency = active and 0.18 or 0.84,
		}, 0.14)
		other.IconGraphic:SetColor(active and self.Settings.IconColor or self.Settings.MutedTextColor)
		tween(other.IconGraphic.Scale, {
			Scale = active and 1.08 or 1,
		}, 0.18)
		tween(other.ActiveBar, {
			BackgroundTransparency = active and 0 or 1,
		}, 0.14)
		tween(other.Page, {
			GroupTransparency = active and 0 or 1,
			Position = active and UDim2.fromOffset(0, 0) or UDim2.fromOffset(-10, 0),
		}, 0.22)

		if not active then
			task.delay(0.23, function()
				if self.ActiveTab ~= other then
					other.Page.Visible = false
				end
			end)
		end
	end

	if self.SettingsButton and self.SettingsTab then
		local settingsActive = tab == self.SettingsTab
		tween(self.SettingsButton, {
			BackgroundTransparency = settingsActive and 0.12 or 0.82,
			BackgroundColor3 = settingsActive and self.Settings.AccentColor or self.Settings.IconColor,
		}, 0.16)
		self.SettingsIcon:SetColor(settingsActive and self.Settings.IconColor or self.Settings.MutedTextColor)
		tween(self.SettingsIcon.Scale, {
			Scale = settingsActive and 1.08 or 1,
		}, 0.16)
	end

	self.ActiveTab = tab
end

function Window:_refreshTabVisuals()
	for _, tab in ipairs(self.Tabs) do
		local active = tab == self.ActiveTab
		if tab.Button and tab.IconGraphic and tab.ActiveBar then
			tab.Button.BackgroundColor3 = active and self.Settings.AccentColor or self.Settings.IconColor
			tab.Button.BackgroundTransparency = active and 0.18 or 0.84
			tab.IconGraphic:SetColor(active and self.Settings.IconColor or self.Settings.MutedTextColor)
			tab.IconGraphic.Scale.Scale = active and 1.08 or 1
			tab.ActiveBar.BackgroundTransparency = active and 0 or 1
		end
	end

	if self.SettingsButton and self.SettingsIcon and self.SettingsTab then
		local settingsActive = self.ActiveTab == self.SettingsTab
		self.SettingsButton.BackgroundColor3 = settingsActive and self.Settings.AccentColor or self.Settings.IconColor
		self.SettingsButton.BackgroundTransparency = settingsActive and 0.12 or 0.82
		self.SettingsIcon:SetColor(settingsActive and self.Settings.IconColor or self.Settings.MutedTextColor)
		self.SettingsIcon.Scale.Scale = settingsActive and 1.08 or 1
	end
end

function Window:_setColorChannel(setting, channel, value)
	local current = self.Settings[setting]
	local r = math.floor(current.R * 255 + 0.5)
	local g = math.floor(current.G * 255 + 0.5)
	local b = math.floor(current.B * 255 + 0.5)

	if channel == "R" then
		r = value
	elseif channel == "G" then
		g = value
	else
		b = value
	end

	self.Settings[setting] = Color3.fromRGB(r, g, b)
	self:_applyTheme()
	self:SaveConfig()
end

function Window:_createSettingsTab()
	local previous = self.ActiveTab
	local tab = self:CreateTab("Settings", Library.Icons.Settings)
	self.SettingsTab = tab
	tab.Button.Visible = false
	tab.Button.Size = UDim2.fromOffset(0, 0)
	tab.Page.Visible = false
	tab.Page.GroupTransparency = 1
	tab.ActiveBar.BackgroundTransparency = 1

	if previous then
		self:SelectTab(previous)
	else
		self.ActiveTab = nil
	end

	local theme = tab:CreateModule("Theme Presets")
	theme:AddDropdown("Preset", {"Custom", "Paracetamol", "Tokyo", "Mint", "Quartz", "Fatality"}, false, function(value)
		if value ~= "Custom" then
			self:ApplyThemePreset(value)
		end
	end)
	theme:AddButton("Open Settings", function()
		self:Notify("Press RightShift to hide/show the UI", 2.5)
	end)

	local config = tab:CreateModule("Config")
	local importText = ""
	config:AddLabel("Autosaves on every control change.")
	config:AddInput("Import JSON", "", function(value)
		importText = value
	end)
	config:AddButton("Import Config", function()
		self:ImportConfig(importText)
	end)
	config:AddButton("Export Config", function()
		self:ExportConfig()
	end)
	config:AddButton("Reload Config", function()
		self:LoadConfig()
		self:Notify("Config reloaded", 2)
	end)

	local function setThemeColor(setting, color)
		self.Settings[setting] = color
		self:_applyTheme()
		self:SaveConfig()
	end

	local appearance = tab:CreateModule("Appearance")
	appearance:AddLabel("Live theme colors.")
	appearance:AddColorPicker("Background", self.Settings.BackgroundColor, function(color)
		setThemeColor("BackgroundColor", color)
	end)
	appearance:AddColorPicker("Panel", self.Settings.PanelColor, function(color)
		setThemeColor("PanelColor", color)
	end)
	appearance:AddColorPicker("Module", self.Settings.ModuleColor, function(color)
		setThemeColor("ModuleColor", color)
	end)
	appearance:AddColorPicker("Text", self.Settings.TextColor, function(color)
		setThemeColor("TextColor", color)
	end)
	appearance:AddColorPicker("Muted Text", self.Settings.MutedTextColor, function(color)
		setThemeColor("MutedTextColor", color)
	end)
	appearance:AddColorPicker("Icons", self.Settings.IconColor, function(color)
		setThemeColor("IconColor", color)
	end)

	local accent = tab:CreateModule("Accent")
	accent:AddSlider("Red", 0, 255, math.floor(self.Settings.AccentColor.R * 255 + 0.5), function(value)
		self:_setColorChannel("AccentColor", "R", value)
	end)
	accent:AddSlider("Green", 0, 255, math.floor(self.Settings.AccentColor.G * 255 + 0.5), function(value)
		self:_setColorChannel("AccentColor", "G", value)
	end)
	accent:AddSlider("Blue", 0, 255, math.floor(self.Settings.AccentColor.B * 255 + 0.5), function(value)
		self:_setColorChannel("AccentColor", "B", value)
	end)

	local icons = tab:CreateModule("Icons")
	icons:AddSlider("Icon Red", 0, 255, math.floor(self.Settings.IconColor.R * 255 + 0.5), function(value)
		self:_setColorChannel("IconColor", "R", value)
	end)
	icons:AddSlider("Icon Green", 0, 255, math.floor(self.Settings.IconColor.G * 255 + 0.5), function(value)
		self:_setColorChannel("IconColor", "G", value)
	end)
	icons:AddSlider("Icon Blue", 0, 255, math.floor(self.Settings.IconColor.B * 255 + 0.5), function(value)
		self:_setColorChannel("IconColor", "B", value)
	end)

	local surface = tab:CreateModule("Surface")
	surface:AddSlider("Glass", 0, 1, self.Settings.Blur and 0.18 or 0.04, function(value)
		self.Main.BackgroundTransparency = value
	end)
	surface:AddToggle("Show Keybinds", true, function(value)
		self:SetKeybindListVisible(value)
	end)
	surface:AddButton("Reset Theme", function()
		self.Settings.AccentColor = Color3.fromRGB(255, 54, 91)
		self.Settings.BackgroundColor = Color3.fromRGB(8, 9, 12)
		self.Settings.ModuleColor = Color3.fromRGB(13, 14, 18)
		self.Settings.PanelColor = Color3.fromRGB(18, 19, 24)
		self.Settings.TextColor = Color3.fromRGB(242, 244, 248)
		self.Settings.MutedTextColor = Color3.fromRGB(150, 155, 166)
		self.Settings.IconColor = Color3.fromRGB(242, 244, 248)
		self:_applyTheme()
		self:SaveConfig()
	end)
end

function Window:OpenSettingsPanel()
	if self.SettingsTab then
		self:SelectTab(self.SettingsTab)
	end
end

function Window:SetVisible(visible)
	self.Visible = visible == true

	if self.Visible then
		self.Gui.Enabled = true
		self.Main.BackgroundTransparency = 1
		self.Main.Position = UDim2.new(0.5, 0, 0.5, 14)
		tween(self.Main, {
			BackgroundTransparency = self.Settings.Blur and 0.18 or 0.04,
			Position = UDim2.fromScale(0.5, 0.5),
		}, 0.22)
	else
		tween(self.Main, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 14),
		}, 0.18)
		task.delay(0.2, function()
			if not self.Visible and self.Gui then
				self.Gui.Enabled = false
			end
		end)
	end
end

function Window:ApplyThemePreset(name)
	local preset = Library.ThemePresets[name]
	if not preset then
		return
	end

	for key, value in pairs(preset) do
		self.Settings[key] = value
	end

	self:_applyTheme()
	self:SaveConfig()
	self:Notify("Applied theme: " .. tostring(name), 2)
end

function Window:SetKeybindListVisible(visible)
	self.ShowKeybinds = visible == true
	if not self.KeybindFrame then
		return
	end

	local hasRows = next(self.KeybindRows) ~= nil
	self.KeybindFrame.Visible = self.ShowKeybinds and hasRows
end

function Window:_updateKeybindOverlay(id, label, keyName, active)
	if not self.KeybindFrame or not self.KeybindList or not self.KeybindLayout or not id then
		return
	end

	local row = self.KeybindRows[id]
	if not row then
		local frame = make("Frame", {
			Name = tostring(id),
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundColor3 = Color3.fromRGB(14, 15, 18),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 102,
		}, self.KeybindList)
		corner(frame, 7)

		local nameLabel = text(frame, tostring(label or id), 11, false)
		nameLabel.Size = UDim2.new(1, -76, 1, 0)
		nameLabel.Position = UDim2.fromOffset(8, 0)
		nameLabel.TextColor3 = self.Settings.MutedTextColor
		nameLabel.ZIndex = 103

		local keyLabel = make("TextLabel", {
			Size = UDim2.fromOffset(62, 18),
			Position = UDim2.new(1, -68, 0.5, -9),
			BackgroundColor3 = self.Settings.AccentColor,
			BackgroundTransparency = 0.72,
			Text = tostring(keyName or ""),
			TextColor3 = self.Settings.TextColor,
			Font = Fonts.SemiBold,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 103,
		}, frame)
		corner(keyLabel, 7)

		row = {
			Frame = frame,
			NameLabel = nameLabel,
			KeyLabel = keyLabel,
		}
		self.KeybindRows[id] = row

		self:_onTheme(function()
			if row.Frame and row.Frame.Parent then
				row.NameLabel.TextColor3 = self.Settings.MutedTextColor
				row.KeyLabel.TextColor3 = self.Settings.TextColor
				row.KeyLabel.BackgroundColor3 = self.Settings.AccentColor
			end
		end)
	end

	row.NameLabel.Text = tostring(label or id)
	row.KeyLabel.Text = tostring(keyName or "")
	row.KeyLabel.BackgroundColor3 = self.Settings.AccentColor
	row.KeyLabel.BackgroundTransparency = active and 0.08 or 0.72
	row.Frame.BackgroundTransparency = active and 0 or 0.1

	local function resize()
		if self.KeybindFrame and self.KeybindLayout then
			local height = math.clamp(34 + self.KeybindLayout.AbsoluteContentSize.Y, 34, 154)
			tween(self.KeybindFrame, {Size = UDim2.fromOffset(210, height)}, 0.14)
		end
	end

	resize()
	task.defer(resize)
	self:SetKeybindListVisible(self.ShowKeybinds)
end

function Window:SetWatermark(textValue)
	if not self.Watermark or not self.WatermarkLabel then
		return
	end

	textValue = tostring(textValue or "")
	self.WatermarkLabel.Text = textValue
	local width = math.clamp(#textValue * 7 + 28, 120, 420)
	tween(self.Watermark, {Size = UDim2.fromOffset(width, 28)}, 0.16)
end

function Window:SetWatermarkVisible(visible)
	if not self.Watermark then
		return
	end

	self.Watermark.Visible = visible == true
end

function Window:StartWatermarkClock(prefix)
	if self.WatermarkConnection and self.WatermarkConnection.Connected then
		self.WatermarkConnection:Disconnect()
	end

	prefix = prefix or self.Title
	local frames = 0
	local elapsed = 0
	local fps = 0

	self:SetWatermarkVisible(true)
	self:SetWatermark(string.format("%s | ... FPS | %s", prefix, LocalPlayer.Name))
	self.WatermarkConnection = self:_connect(RunService.RenderStepped, function(delta)
		frames = frames + 1
		elapsed = elapsed + delta

		if elapsed >= 0.5 then
			fps = math.floor(frames / elapsed + 0.5)
			frames = 0
			elapsed = 0
			self:SetWatermark(string.format("%s | %d FPS | %s", prefix, fps, LocalPlayer.Name))
		end
	end)
end

function Window:BindTooltip(instance, message)
	if not instance or not message or message == "" then
		return
	end

	self:_connect(instance.MouseEnter, function()
		if not self.Tooltip or not self.TooltipLabel then
			return
		end

		self.TooltipLabel.Text = tostring(message)
		local mouse = UserInputService:GetMouseLocation()
		self.Tooltip.Position = UDim2.fromOffset(mouse.X + 14, mouse.Y + 12)
		self.Tooltip.Visible = true
		self.Tooltip.BackgroundTransparency = 1
		tween(self.Tooltip, {BackgroundTransparency = 0.06}, 0.12)
	end)

	self:_connect(instance.MouseMoved, function(x, y)
		if self.Tooltip and self.Tooltip.Visible then
			self.Tooltip.Position = UDim2.fromOffset(x + 14, y + 12)
		end
	end)

	self:_connect(instance.MouseLeave, function()
		if not self.Tooltip then
			return
		end

		tween(self.Tooltip, {BackgroundTransparency = 1}, 0.1)
		task.delay(0.11, function()
			if self.Tooltip then
				self.Tooltip.Visible = false
			end
		end)
	end)
end

function Window:Notify(message, duration)
	duration = duration or 3
	if not self.NotificationHolder then
		return
	end

	local item = make("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(0, 48),
		BackgroundColor3 = self.Settings.ModuleColor,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 101,
	}, self.NotificationHolder)
	corner(item, 10)
	stroke(item, self.Settings.AccentColor, 0.55, 1)

	local accent = make("Frame", {
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.fromOffset(8, 6),
		BackgroundColor3 = self.Settings.AccentColor,
		BorderSizePixel = 0,
		ZIndex = 102,
	}, item)
	corner(accent, 3)

	local label = text(item, tostring(message or ""), 12, false)
	label.Size = UDim2.new(1, -28, 1, -8)
	label.Position = UDim2.fromOffset(20, 4)
	label.TextWrapped = true
	label.TextColor3 = self.Settings.TextColor
	label.ZIndex = 102

	local progress = make("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = self.Settings.AccentColor,
		BorderSizePixel = 0,
		ZIndex = 102,
	}, item)

	tween(item, {Size = UDim2.fromOffset(260, 48)}, 0.28)
	tween(progress, {Size = UDim2.new(0, 0, 0, 2)}, duration)

	task.delay(duration, function()
		if item and item.Parent then
			tween(item, {Size = UDim2.fromOffset(0, 48), BackgroundTransparency = 1}, 0.22)
			task.delay(0.24, function()
				if item and item.Parent then
					item:Destroy()
				end
			end)
		end
	end)
end

function Window:OnUnload(callback)
	if callback then
		table.insert(self.UnloadCallbacks, callback)
	end
	return self
end

function Window:Unload()
	self:Destroy()
end

function Window:Destroy()
	if self.Destroyed then
		return
	end

	self.Destroyed = true
	for _, callback in ipairs(self.UnloadCallbacks) do
		local ok, err = pcall(callback)
		if not ok then
			warn("[ParacetamolUILib] Unload callback error:", err)
		end
	end

	for _, connection in ipairs(self.Connections) do
		if connection.Connected then
			connection:Disconnect()
		end
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
		SearchText = string.lower(title or "Module"),
		Collapsed = false,
	}, Module)

	local frame = make("Frame", {
		Name = module.Title,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = #self.Modules + 1,
		BackgroundColor3 = self.Window.Settings.ModuleColor,
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 10,
	}, column)
	corner(frame, 10)
	local moduleStroke = stroke(frame, Color3.fromRGB(255, 58, 95), 0.78, 1)
	self.Window:_theme(frame, "BackgroundColor3", "ModuleColor")
	self.Window:_onTheme(function()
		if moduleStroke and moduleStroke.Parent then
			moduleStroke.Color = self.Window.Settings.AccentColor
		end
	end)

	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 26, 32)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 14)),
		}),
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(1, 0.34),
		}),
	}, frame)

	local framePadding = make("UIPadding", {
		PaddingTop = UDim.new(0, 9),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, frame)

	local frameLayout = make("UIListLayout", {
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
		Font = Fonts.Bold,
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
		BackgroundTransparency = 1,
		ZIndex = 11,
	}, frame)

	local contentLayout = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)

	local function updateHeight(animated)
		local contentHeight = contentLayout.AbsoluteContentSize.Y
		content.Size = UDim2.new(1, 0, 0, module.Collapsed and 0 or contentHeight)

		local paddingTop = framePadding.PaddingTop.Offset
		local paddingBottom = framePadding.PaddingBottom.Offset
		local height = frameLayout.AbsoluteContentSize.Y + paddingTop + paddingBottom
		local size = UDim2.new(1, 0, 0, height)

		if animated then
			tween(frame, {Size = size}, 0.16)
		else
			frame.Size = size
		end
	end

	self.Window:_connect(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		updateHeight(true)
	end)
	self.Window:_connect(frameLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		updateHeight(true)
	end)
	task.defer(updateHeight)

	self.Window:_connect(frame.MouseEnter, function()
		tween(frame, {BackgroundTransparency = 0.08}, 0.16)
		tween(moduleStroke, {Transparency = 0.48}, 0.16)
	end)

	self.Window:_connect(frame.MouseLeave, function()
		tween(frame, {BackgroundTransparency = 0.14}, 0.16)
		tween(moduleStroke, {Transparency = 0.78}, 0.16)
	end)

	self.Window:_connect(header.MouseButton1Click, function()
		module.Collapsed = not module.Collapsed
		content.Visible = not module.Collapsed
		divider.Visible = not module.Collapsed
		key.Text = module.Collapsed and "+" or "KEY"
		updateHeight(true)
	end)

	module.Frame = frame
	module.Content = content
	module.UpdateHeight = updateHeight
	table.insert(self.Modules, module)
	if self.ApplyFilter then
		self:ApplyFilter()
	end
	return module
end

function Module:_addSearchText(value)
	value = tostring(value or "")
	if value ~= "" then
		self.SearchText = (self.SearchText or "") .. " " .. string.lower(value)
		if self.Tab and self.Tab.ApplyFilter then
			self.Tab:ApplyFilter()
		end
	end
end

function Module:_key(label)
	self.ControlNameCounts[label] = (self.ControlNameCounts[label] or 0) + 1
	local suffix = self.ControlNameCounts[label] > 1 and "_" .. tostring(self.ControlNameCounts[label]) or ""
	return self.Title .. "." .. label .. suffix
end

function Module:_register(label, defaultValue, setter, getter)
	local key = self:_key(label)
	self:_addSearchText(label)
	local control = {
		Key = key,
		Label = label,
		GetValue = getter,
		Changed = nil,
		ChangedCallbacks = {},
		Module = self,
	}

	function control.SetValue(selfOrValue, maybeValue, maybeSilent)
		local newValue = maybeValue
		local silent = maybeSilent

		if selfOrValue ~= control then
			newValue = selfOrValue
			silent = maybeValue
		end

		control._SuppressChanged = silent == true
		setter(newValue, silent == true)
		control._SuppressChanged = false
		return control
	end

	function control.OnChanged(selfOrCallback, maybeCallback)
		local callback = selfOrCallback == control and maybeCallback or selfOrCallback
		if callback then
			table.insert(control.ChangedCallbacks, callback)
			control.Changed = callback
			safeCall(callback, getter())
		end
		return control
	end

	function control:SetTooltip(message)
		if self.HoverInstance then
			self.Window:BindTooltip(self.HoverInstance, message)
		end
		return self
	end

	function control:SetVisible(visible)
		if self.Container then
			self.Container.Visible = visible == true
			if self.Module and self.Module.UpdateHeight then
				task.defer(function()
					self.Module.UpdateHeight(true)
				end)
			end
		end
		return self
	end

	function control:DependsOn(otherControl, expectedValue)
		if not otherControl or not otherControl.OnChanged then
			return self
		end

		local function update(value)
			local shouldShow

			if type(expectedValue) == "function" then
				shouldShow = expectedValue(value) == true
			elseif expectedValue == nil then
				shouldShow = value == true
			else
				shouldShow = value == expectedValue
			end

			self:SetVisible(shouldShow)
		end

		otherControl:OnChanged(update)
		update(otherControl.GetValue())
		return self
	end

	control.Window = self.Window

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

function Module:AddLabel(label)
	self:_addSearchText(label)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(row, label or "Label", 12, false)
	labelText.Size = UDim2.fromScale(1, 1)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 13
	return labelText
end

function Module:AddDivider()
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local line = make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = self.Window.Settings.AccentColor,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 13,
	}, row)
	self.Window:_theme(line, "BackgroundColor3", "AccentColor")
	return line
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
	control.HoverInstance = row
	control.Container = row
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
	local pendingSave = false

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

	local function persistValue(deferSave)
		if not key then
			return
		end

		if deferSave then
			self.Window.ControlValues[key] = value
			pendingSave = true
		else
			self.Window:_setControlValue(key, value)
			pendingSave = false
		end
	end

	local function setValue(newValue, silent, deferSave)
		value = math.clamp(tonumber(newValue) or min, min, max)
		local p = percent()
		valueText.Text = string.format("%.2f", value)

		if dragging and not silent then
			fill.Size = UDim2.fromScale(p, 1)
			knob.Position = UDim2.new(p, -7, 0.5, -7)
		else
			tween(fill, {Size = UDim2.fromScale(p, 1)}, 0.08)
			tween(knob, {Position = UDim2.new(p, -7, 0.5, -7)}, 0.08)
		end

		persistValue(deferSave == true)
		if not silent then
			safeCall(callback, value)
		end
	end

	local function setFromX(x)
		local p = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		setValue(min + ((max - min) * p), false, true)
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
			if dragging and pendingSave then
				self.Window:_setControlValue(key, value)
				pendingSave = false
			end
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
	control.HoverInstance = row
	control.Container = row
	setValue(value, true)
	return control
end

function Module:AddButton(label, callback)
	self:_addSearchText(label)
	local button = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(18, 19, 23),
		Text = label or "Button",
		TextColor3 = self.Window.Settings.TextColor,
		Font = Fonts.Bold,
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

	local wrapper = {
		Instance = button,
		Button = button,
		Container = button,
		Window = self.Window,
		Module = self,
	}

	function wrapper:SetTooltip(message)
		self.Window:BindTooltip(button, message)
		return self
	end

	function wrapper:SetVisible(visible)
		button.Visible = visible == true
		if self.Module and self.Module.UpdateHeight then
			task.defer(function()
				self.Module.UpdateHeight(true)
			end)
		end
		return self
	end

	function wrapper:SetText(newText)
		button.Text = tostring(newText or "")
		return self
	end

	function wrapper:DependsOn(otherControl, expectedValue)
		if not otherControl or not otherControl.OnChanged then
			return self
		end

		local function update(value)
			local shouldShow

			if type(expectedValue) == "function" then
				shouldShow = expectedValue(value) == true
			elseif expectedValue == nil then
				shouldShow = value == true
			else
				shouldShow = value == expectedValue
			end

			self:SetVisible(shouldShow)
		end

		otherControl:OnChanged(update)
		update(otherControl.GetValue())
		return self
	end

	function wrapper:OnClick(newCallback)
		callback = newCallback
		return self
	end

	return setmetatable(wrapper, {
		__index = function(_, key)
			return button[key]
		end,
		__newindex = function(_, key, value)
			button[key] = value
		end,
	})
end

function Module:AddKeybind(label, defaultKey, callback, mode)
	local keyName = typeof(defaultKey) == "EnumItem" and defaultKey.Name or tostring(defaultKey or "RightShift")
	local modeName = tostring(mode or "Press")
	local listening = false
	local toggled = false
	local holding = false
	local controlKey
	local clickCallback

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(row, label or "Keybind", 12, false)
	labelText.Size = UDim2.new(1, -178, 1, 0)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 13

	local modeButton = make("TextButton", {
		Size = UDim2.fromOffset(70, 28),
		Position = UDim2.new(1, -170, 0.5, -14),
		BackgroundColor3 = Color3.fromRGB(18, 19, 23),
		Text = modeName,
		TextColor3 = self.Window.Settings.MutedTextColor,
		Font = Fonts.SemiBold,
		TextSize = 10,
		AutoButtonColor = false,
		ZIndex = 13,
	}, row)
	corner(modeButton, 8)
	stroke(modeButton, Color3.fromRGB(68, 70, 78), 0.55, 1)
	self.Window:_theme(modeButton, "TextColor3", "MutedTextColor")

	local keyButton = make("TextButton", {
		Size = UDim2.fromOffset(92, 28),
		Position = UDim2.new(1, -92, 0.5, -14),
		BackgroundColor3 = Color3.fromRGB(18, 19, 23),
		Text = keyName,
		TextColor3 = self.Window.Settings.TextColor,
		Font = Fonts.SemiBold,
		TextSize = 11,
		AutoButtonColor = false,
		ZIndex = 13,
	}, row)
	corner(keyButton, 8)
	stroke(keyButton, Color3.fromRGB(68, 70, 78), 0.55, 1)
	self.Window:_theme(keyButton, "TextColor3", "TextColor")

	local function normalizeMode(newMode)
		newMode = tostring(newMode or modeName)
		if newMode == "Toggle" or newMode == "Hold" or newMode == "Always" or newMode == "Press" then
			return newMode
		end
		return "Press"
	end

	local function normalize(newKey)
		if typeof(newKey) == "table" then
			modeName = normalizeMode(newKey.Mode)
			newKey = newKey.Key
		end

		if typeof(newKey) == "EnumItem" then
			if newKey == Enum.UserInputType.MouseButton1 then
				return "MB1"
			elseif newKey == Enum.UserInputType.MouseButton2 then
				return "MB2"
			end

			return newKey.Name
		end

		newKey = tostring(newKey or keyName)
		if newKey == "MouseButton1" then
			return "MB1"
		elseif newKey == "MouseButton2" then
			return "MB2"
		elseif newKey == "MB1" or newKey == "MB2" then
			return newKey
		end

		local ok, enumValue = pcall(function()
			return Enum.KeyCode[newKey]
		end)
		if ok and enumValue then
			return newKey
		end

		return keyName
	end

	local function inputMatches(input)
		if keyName == "MB1" then
			return input.UserInputType == Enum.UserInputType.MouseButton1
		elseif keyName == "MB2" then
			return input.UserInputType == Enum.UserInputType.MouseButton2
		end

		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == keyName
	end

	local function currentValue()
		return {
			Key = keyName,
			Mode = modeName,
		}
	end

	local function getState()
		if modeName == "Always" then
			return true
		elseif modeName == "Toggle" then
			return toggled
		elseif modeName == "Hold" then
			if keyName == "MB1" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			elseif keyName == "MB2" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			end

			return holding
		end

		return false
	end

	local function updateVisual(active)
		keyButton.Text = listening and "..." or keyName
		modeButton.Text = modeName

		if modeName == "Always" then
			active = true
		end

		if controlKey then
			self.Window:_updateKeybindOverlay(controlKey, label or "Keybind", keyName .. " / " .. modeName, active == true)
		end
	end

	local function setValue(newKey, silent)
		keyName = normalize(newKey)
		modeName = normalizeMode(modeName)
		updateVisual(getState())

		if controlKey then
			self.Window:_setControlValue(controlKey, currentValue())
		end

		if not silent then
			safeCall(callback, keyName, getState(), modeName)
		end
	end

	local function cycleMode()
		local modes = {"Press", "Toggle", "Hold", "Always"}
		local index = table.find(modes, modeName) or 1
		modeName = modes[(index % #modes) + 1]
		if modeName ~= "Toggle" then
			toggled = false
		end
		if modeName ~= "Hold" then
			holding = false
		end
		setValue({Key = keyName, Mode = modeName}, false)
	end

	self.Window:_connect(keyButton.MouseButton1Click, function()
		listening = true
		keyButton.Text = "..."
		tween(keyButton, {BackgroundColor3 = self.Window.Settings.AccentColor}, 0.12)
	end)

	self.Window:_connect(modeButton.MouseButton1Click, cycleMode)

	self.Window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				tween(keyButton, {BackgroundColor3 = Color3.fromRGB(18, 19, 23)}, 0.12)
				setValue(input.KeyCode.Name, false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
				listening = false
				tween(keyButton, {BackgroundColor3 = Color3.fromRGB(18, 19, 23)}, 0.12)
				setValue(input.UserInputType == Enum.UserInputType.MouseButton1 and "MB1" or "MB2", false)
			end
			return
		end

		if inputMatches(input) then
			local active = true

			if modeName == "Toggle" then
				toggled = not toggled
				active = toggled
			elseif modeName == "Hold" then
				holding = true
				active = true
			elseif modeName == "Always" then
				active = true
			end

			updateVisual(active)
			tween(keyButton, {BackgroundColor3 = self.Window.Settings.AccentColor}, 0.08)
			task.delay(0.1, function()
				if keyButton and keyButton.Parent then
					tween(keyButton, {BackgroundColor3 = Color3.fromRGB(18, 19, 23)}, 0.12)
				end
				if modeName == "Press" then
					updateVisual(false)
				end
			end)
			safeCall(callback, keyName, modeName == "Press" and true or getState(), modeName)
			safeCall(clickCallback, getState(), keyName, modeName)
		end
	end)

	self.Window:_connect(UserInputService.InputEnded, function(input)
		if modeName == "Hold" and inputMatches(input) then
			holding = false
			updateVisual(false)
			safeCall(callback, keyName, false, modeName)
			safeCall(clickCallback, false, keyName, modeName)
		end
	end)

	local control = self:_register(label or "Keybind", keyName, setValue, function()
		return currentValue()
	end)
	controlKey = control.Key
	control.HoverInstance = row
	control.Container = row

	function control:GetState()
		return getState()
	end

	function control:SetMode(newMode)
		modeName = normalizeMode(newMode)
		setValue({Key = keyName, Mode = modeName}, false)
		return self
	end

	function control:OnClick(callbackValue)
		clickCallback = callbackValue
		return self
	end

	setValue(keyName, true)
	self.Window:_updateKeybindOverlay(controlKey, label or "Keybind", keyName .. " / " .. modeName, getState())
	return control
end

function Module:AddInput(label, defaultText, callback)
	local value = tostring(defaultText or "")
	local controlKey

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, self.Content)

	local labelText = text(row, label or "Input", 12, false)
	labelText.Size = UDim2.new(1, 0, 0, 18)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 13

	local box = make("TextBox", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 22),
		BackgroundColor3 = Color3.fromRGB(18, 19, 23),
		Text = value,
		PlaceholderText = "Type...",
		TextColor3 = self.Window.Settings.TextColor,
		PlaceholderColor3 = self.Window.Settings.MutedTextColor,
		Font = Fonts.Regular,
		TextSize = 12,
		ClearTextOnFocus = false,
		ZIndex = 13,
	}, row)
	corner(box, 8)
	stroke(box, Color3.fromRGB(68, 70, 78), 0.55, 1)
	self.Window:_theme(box, "TextColor3", "TextColor")

	local function setValue(newValue, silent)
		value = tostring(newValue or "")
		box.Text = value

		if controlKey then
			self.Window:_setControlValue(controlKey, value)
		end

		if not silent then
			safeCall(callback, value)
		end
	end

	self.Window:_connect(box.Focused, function()
		tween(box, {BackgroundColor3 = Color3.fromRGB(24, 25, 30)}, 0.12)
	end)

	self.Window:_connect(box.FocusLost, function()
		tween(box, {BackgroundColor3 = Color3.fromRGB(18, 19, 23)}, 0.12)
		setValue(box.Text, false)
	end)

	local control = self:_register(label or "Input", value, setValue, function()
		return value
	end)
	controlKey = control.Key
	control.HoverInstance = row
	control.Container = row
	setValue(value, true)
	return control
end

function Module:AddColorPicker(label, defaultColor, callback)
	local color = defaultColor or self.Window.Settings.AccentColor
	local open = false
	local controlKey
	local boxes = {}
	local bars = {}
	local colorDragging = false
	local pendingColorSave = false

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 12,
	}, self.Content)

	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		ZIndex = 13,
	}, container)

	local labelText = text(row, label or "Color", 12, false)
	labelText.Size = UDim2.new(1, -48, 1, 0)
	labelText.TextColor3 = self.Window.Settings.MutedTextColor
	labelText.ZIndex = 14

	local swatch = make("TextButton", {
		Size = UDim2.fromOffset(38, 24),
		Position = UDim2.new(1, -38, 0.5, -12),
		BackgroundColor3 = color,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 14,
	}, row)
	corner(swatch, 8)
	stroke(swatch, Color3.fromRGB(235, 238, 242), 0.45, 1)

	local editor = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 38),
		BackgroundColor3 = Color3.fromRGB(14, 15, 18),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 13,
	}, container)
	corner(editor, 8)
	stroke(editor, Color3.fromRGB(68, 70, 78), 0.6, 1)

	make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, editor)

	make("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, editor)

	local function toRecord(value)
		return {
			R = math.floor(value.R * 255 + 0.5),
			G = math.floor(value.G * 255 + 0.5),
			B = math.floor(value.B * 255 + 0.5),
		}
	end

	local function fromValue(value)
		if typeof(value) == "Color3" then
			return value
		end

		if typeof(value) == "table" then
			return Color3.fromRGB(
				math.clamp(tonumber(value.R) or 255, 0, 255),
				math.clamp(tonumber(value.G) or 255, 0, 255),
				math.clamp(tonumber(value.B) or 255, 0, 255)
			)
		end

		return color
	end

	local function updateBoxes()
		local values = toRecord(color)
		for channel, box in pairs(boxes) do
			box.Text = tostring(values[channel])
		end
		for channel, data in pairs(bars) do
			local percent = math.clamp((values[channel] or 0) / 255, 0, 1)
			data.Fill.Size = UDim2.fromScale(percent, 1)
			data.Knob.Position = UDim2.new(percent, -5, 0.5, -5)
		end
		swatch.BackgroundColor3 = color
	end

	local function setValue(newValue, silent)
		color = fromValue(newValue)
		updateBoxes()

		if controlKey then
			local record = toRecord(color)
			if colorDragging then
				self.Window.ControlValues[controlKey] = record
				pendingColorSave = true
			else
				self.Window:_setControlValue(controlKey, record)
				pendingColorSave = false
			end
		end

		if not silent then
			safeCall(callback, color)
		end
	end

	local function setOpen(state)
		open = state
		tween(container, {Size = UDim2.new(1, 0, 0, open and 192 or 36)}, 0.18)
		tween(editor, {Size = UDim2.new(1, 0, 0, open and 148 or 0)}, 0.18)
	end

	local function makeChannel(channel, channelColor)
		local channelRow = make("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			ZIndex = 14,
		}, editor)

		local channelLabel = text(channelRow, channel, 11, true)
		channelLabel.Size = UDim2.fromOffset(24, 18)
		channelLabel.TextColor3 = channelColor
		channelLabel.ZIndex = 15

		local box = make("TextBox", {
			Size = UDim2.fromOffset(42, 22),
			Position = UDim2.new(1, -42, 0, 0),
			BackgroundColor3 = Color3.fromRGB(18, 19, 23),
			Text = "0",
			TextColor3 = self.Window.Settings.TextColor,
			Font = Fonts.Regular,
			TextSize = 11,
			ClearTextOnFocus = false,
			ZIndex = 15,
		}, channelRow)
		corner(box, 7)
		self.Window:_theme(box, "TextColor3", "TextColor")
		boxes[channel] = box

		local track = make("Frame", {
			Size = UDim2.new(1, -78, 0, 5),
			Position = UDim2.fromOffset(30, 24),
			BackgroundColor3 = Color3.fromRGB(28, 29, 34),
			BorderSizePixel = 0,
			ZIndex = 15,
		}, channelRow)
		corner(track, 5)

		local fill = make("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = channelColor,
			BorderSizePixel = 0,
			ZIndex = 16,
		}, track)
		corner(fill, 5)

		local knob = make("Frame", {
			Size = UDim2.fromOffset(10, 10),
			Position = UDim2.new(0, -5, 0.5, -5),
			BackgroundColor3 = Color3.fromRGB(246, 248, 252),
			BorderSizePixel = 0,
			ZIndex = 17,
		}, track)
		corner(knob, 5)
		bars[channel] = {
			Fill = fill,
			Knob = knob,
			Track = track,
		}

		local dragging = false
		local function setFromX(x)
			local values = toRecord(color)
			local percent = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			values[channel] = math.floor(percent * 255 + 0.5)
			setValue(values, false)
		end

		self.Window:_connect(track.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				colorDragging = true
				setFromX(input.Position.X)
			end
		end)

		self.Window:_connect(knob.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				colorDragging = true
			end
		end)

		self.Window:_connect(UserInputService.InputChanged, function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				setFromX(input.Position.X)
			end
		end)

		self.Window:_connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if dragging and pendingColorSave and controlKey then
					self.Window:_setControlValue(controlKey, toRecord(color))
					pendingColorSave = false
				end
				dragging = false
				colorDragging = false
			end
		end)

		self.Window:_connect(box.FocusLost, function()
			local values = toRecord(color)
			values[channel] = math.clamp(tonumber(box.Text) or values[channel], 0, 255)
			setValue(values, false)
		end)
	end

	makeChannel("R", Color3.fromRGB(255, 96, 120))
	makeChannel("G", Color3.fromRGB(88, 230, 159))
	makeChannel("B", Color3.fromRGB(98, 166, 255))

	local presets = make("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		ZIndex = 14,
	}, editor)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, presets)

	for _, presetColor in ipairs({
		Color3.fromRGB(255, 54, 91),
		Color3.fromRGB(122, 101, 255),
		Color3.fromRGB(57, 202, 151),
		Color3.fromRGB(92, 164, 205),
		Color3.fromRGB(242, 244, 248),
		Color3.fromRGB(18, 19, 24),
	}) do
		local preset = make("TextButton", {
			Size = UDim2.fromOffset(24, 22),
			BackgroundColor3 = presetColor,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 15,
		}, presets)
		corner(preset, 7)
		stroke(preset, Color3.fromRGB(255, 255, 255), 0.72, 1)

		self.Window:_connect(preset.MouseButton1Click, function()
			setValue(presetColor, false)
		end)
	end

	self.Window:_connect(swatch.MouseButton1Click, function()
		setOpen(not open)
	end)

	local control = self:_register(label or "Color", toRecord(color), setValue, function()
		return color
	end)
	controlKey = control.Key
	control.HoverInstance = container
	control.Container = container
	setValue(color, true)
	return control
end

function Module:AddDropdown(label, options, multipleOptions, callback)
	options = options or {}
	multipleOptions = multipleOptions == true
	for _, option in ipairs(options) do
		self:_addSearchText(option)
	end

	local selected = multipleOptions and {} or tostring(options[1] or "")
	local key
	local open = false
	local optionButtons = {}
	local optionChips = {}

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
		Font = Fonts.Bold,
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
		for index, option in ipairs(options) do
			local opt = tostring(option)
			local active = multipleOptions and selected[opt] == true or selected == opt
			local chipData = optionChips[opt]

			if not chipData then
				local chip = make("TextButton", {
					Size = UDim2.fromOffset(index == 1 and 66 or 72, 28),
					BackgroundColor3 = Color3.fromRGB(16, 17, 21),
					Text = opt,
					TextColor3 = self.Window.Settings.MutedTextColor,
					Font = Fonts.Bold,
					TextSize = 12,
					AutoButtonColor = false,
					ZIndex = 15,
				}, chips)
				corner(chip, 8)
				local chipStroke = stroke(chip, Color3.fromRGB(64, 65, 72), 0.65, 1)

				self.Window:_connect(chip.MouseButton1Click, function()
					if multipleOptions then
						selected[opt] = not selected[opt]
					else
						selected = opt
					end
					refresh()
					persist(false)
				end)

				chipData = {
					Button = chip,
					Stroke = chipStroke,
				}
				optionChips[opt] = chipData
			end

			chipData.Button.BackgroundColor3 = active and Color3.fromRGB(24, 25, 30) or Color3.fromRGB(16, 17, 21)
			chipData.Button.TextColor3 = active and self.Window.Settings.TextColor or self.Window.Settings.MutedTextColor
			chipData.Stroke.Color = active and self.Window.Settings.AccentColor or Color3.fromRGB(64, 65, 72)
			chipData.Stroke.Transparency = active and 0.25 or 0.65
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

	local function isPointInside(frame, point)
		local position = frame.AbsolutePosition
		local size = frame.AbsoluteSize
		return point.X >= position.X
			and point.X <= position.X + size.X
			and point.Y >= position.Y
			and point.Y <= position.Y + size.Y
	end

	self.Window:_connect(openButton.MouseButton1Click, function()
		setOpen(not open)
	end)

	self.Window:_connect(labelText.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			setOpen(not open)
		end
	end)

	self.Window:_connect(UserInputService.InputBegan, function(input)
		if not open or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local mouse = UserInputService:GetMouseLocation()
		if not isPointInside(container, mouse) then
			setOpen(false)
		end
	end)

	for _, option in ipairs(options) do
		local opt = tostring(option)
		local optionButton = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Color3.fromRGB(20, 21, 25),
			Text = opt,
			TextColor3 = self.Window.Settings.TextColor,
			Font = Fonts.Medium,
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
	control.HoverInstance = container
	control.Container = container
	refresh()
	return control
end

Library.Window = Window
Library.Tab = Tab
Library.Module = Module

return Library
