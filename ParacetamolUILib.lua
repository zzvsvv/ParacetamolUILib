--[[
	ParacetamolUILib — Glassmorphic UI Library for Roblox
	https://raw.githubusercontent.com/zzvsvv/ParacetamolUILib/refs/heads/main/ParacetamolUILib.lua
]]

local ParacetamolUILib = {}
local version = "1.0.0"

-- ── Services ──────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ── Constants ─────────────────────────────────────────────────────────────
local COLORS = {
	Accent = Color3.fromRGB(180, 15, 15),
	AccentDark = Color3.fromRGB(120, 8, 8),
	AccentGlow = Color3.fromRGB(220, 40, 40),
	Background = Color3.fromRGB(6, 6, 10),
	Section = Color3.fromRGB(12, 12, 18),
	Element = Color3.fromRGB(20, 20, 30),
	ElementHover = Color3.fromRGB(30, 30, 42),
	Text = Color3.fromRGB(235, 235, 240),
	TextDim = Color3.fromRGB(130, 130, 140),
	TextDark = Color3.fromRGB(60, 60, 70),
	Border = Color3.fromRGB(25, 25, 35),
	GlassHighlight = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(50, 200, 100),
	Danger = Color3.fromRGB(220, 50, 50),
	Warning = Color3.fromRGB(240, 180, 40),
}

local TRANSPARENCY = {
	Window = 0.35,
	Section = 0.40,
	Element = 0.30,
	ElementHover = 0.20,
	Border = 0.85,
	GlassHighlight = 0.92,
	Shadow = 0.80,
}

local FONTS = {
	Title = Enum.Font.GothamBold,
	Text = Enum.Font.Gotham,
	Monospace = Enum.Font.Code,
}

local CORNERS = {
	Window = 12,
	Section = 10,
	Element = 6,
	Toggle = 4,
	Button = 6,
}

local TWEEN = {
	Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

-- ── Module-level stores ───────────────────────────────────────────────────
local ParacetamolToggles = {}
local ParacetamolOptions = {}
local Elements = {}
local Connections = {}
local Unloaded = false

if getgenv then
	getgenv().ParacetamolToggles = ParacetamolToggles
	getgenv().ParacetamolOptions = ParacetamolOptions
end

-- ── Icon System ───────────────────────────────────────────────────────────
local ICON_CACHE = {}
local function GetIcon(name)
	if ICON_CACHE[name] then return ICON_CACHE[name] end
	local success, id = pcall(GuiService.GetIcon, GuiService, name)
	if success and id and id ~= "" then
		local full = "rbxassetid://" .. tostring(id:match("%d+") or id)
		ICON_CACHE[name] = full
		return full
	end
	return nil
end

local function CreateIcon(iconName, size, color)
	local id = GetIcon(iconName)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(size, size)
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	if color then img.ImageColor3 = color end
	if id then
		img.Image = id
	else
		img.Visible = false
	end
	return img
end

-- ── Utility Functions ─────────────────────────────────────────────────────

local function MakeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			local con
			con = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					con:Disconnect()
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)
end

local function CreateRound(frame, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = frame
	return c
end

local function CreateStroke(frame, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.Border
	s.Transparency = transparency or TRANSPARENCY.Border
	s.Thickness = thickness or 1
	s.Parent = frame
	return s
end

local function CreateShadow(frame, transparency, size)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(size or 20, size or 20)
	shadow.Position = UDim2.fromScale(0.5, 0.5)
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = transparency or 0.75
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(Vector2.new(10, 10), Vector2.new(110, 110))
	shadow.ZIndex = frame.ZIndex - 1
	shadow.Parent = frame
	return shadow
end

local function CreateGradient(frame, color, reverse)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color or Color3.fromRGB(255, 255, 255));
		ColorSequenceKeypoint.new(1, (color or Color3.fromRGB(255, 255, 255)):Lerp(Color3.fromRGB(0, 0, 0), 0.15));
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, reverse and 1 or 0.85);
		NumberSequenceKeypoint.new(1, reverse and 0.85 or 1);
	})
	g.Rotation = 90
	g.Parent = frame
	return g
end

local function CreateGlowOverlay(frame)
	local g = Instance.new("Frame")
	g.Name = "GlowOverlay"
	g.Size = UDim2.fromScale(1, 1)
	g.BackgroundTransparency = 1
	g.BorderSizePixel = 0
	g.ZIndex = frame.ZIndex + 1

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.GlassHighlight);
		ColorSequenceKeypoint.new(0.3, COLORS.GlassHighlight);
		ColorSequenceKeypoint.new(1, COLORS.GlassHighlight);
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92);
		NumberSequenceKeypoint.new(0.5, 1);
		NumberSequenceKeypoint.new(1, 0.95);
	})
	gradient.Rotation = -45
	gradient.Parent = g

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CORNERS.Section)
	corner.Parent = g

	g.Parent = frame
	return g
end

local function SetBackground(frame, color, transparency, radius)
	frame.BackgroundColor3 = color or COLORS.Background
	frame.BackgroundTransparency = transparency or TRANSPARENCY.Window
	frame.BorderSizePixel = 0
	if radius then
		CreateRound(frame, radius)
	end
end

local function CreateTextLabel(text, font, size, color, alignX, alignY)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = font or FONTS.Text
	lbl.TextSize = size or 14
	lbl.TextColor3 = color or COLORS.Text
	lbl.TextXAlignment = alignX or Enum.TextXAlignment.Left
	lbl.TextYAlignment = alignY or Enum.TextYAlignment.Center
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.RichText = true
	return lbl
end

local function TweenObject(obj, props, tweenInfo)
	local info = tweenInfo or TWEEN.Normal
	local tween = TweenService:Create(obj, info, props)
	tween:Play()
	return tween
end

-- ── Loading Screen ────────────────────────────────────────────────────────
local LoadingScreen = {}
local loadingScreenInstance = nil

function LoadingScreen:Show()
	if loadingScreenInstance then return end

	local screen = Instance.new("ScreenGui")
	screen.Name = "ParacetamolLoading"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 9999
	screen.IgnoreGuiInset = true

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = screen

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(280, 120)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = screen

	-- Spinner
	local spinner = Instance.new("ImageLabel")
	spinner.Size = UDim2.fromOffset(40, 40)
	spinner.Position = UDim2.fromScale(0.5, 0.3)
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.BackgroundTransparency = 1
	spinner.BorderSizePixel = 0
	spinner.Image = "rbxassetid://6026568198" -- loading circle
	spinner.ImageColor3 = COLORS.Accent
	spinner.Parent = container

	local spinTween = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
	spinTween:Play()

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.35)
	title.Position = UDim2.fromScale(0, 0.55)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.Text = "Paracetamol"
	title.Font = FONTS.Title
	title.TextSize = 28
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = container

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.fromScale(1, 0.2)
	subtitle.Position = UDim2.fromScale(0, 0.78)
	subtitle.BackgroundTransparency = 1
	subtitle.BorderSizePixel = 0
	subtitle.Text = "loading..."
	subtitle.Font = FONTS.Text
	subtitle.TextSize = 12
	subtitle.TextColor3 = COLORS.Accent
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.TextYAlignment = Enum.TextYAlignment.Center
	subtitle.Parent = container

	-- Version
	local ver = Instance.new("TextLabel")
	ver.Size = UDim2.fromScale(1, 0.15)
	ver.Position = UDim2.fromScale(0, 0.92)
	ver.BackgroundTransparency = 1
	ver.BorderSizePixel = 0
	ver.Text = "v" .. version
	ver.Font = FONTS.Text
	ver.TextSize = 10
	ver.TextColor3 = COLORS.TextDim
	ver.TextXAlignment = Enum.TextXAlignment.Center
	ver.Parent = container

	-- Accent line under title
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 0, 0, 2)
	line.Position = UDim2.fromScale(0.5, 0.72)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = COLORS.Accent
	line.BorderSizePixel = 0
	line.Parent = container
	CreateRound(line, 1)

	local lineTween = TweenService:Create(line, TWEEN.Slow, { Size = UDim2.new(0, 120, 0, 2) })
	lineTween:Play()

	screen.Parent = (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or game:GetService("CoreGui")

	loadingScreenInstance = {
		Screen = screen,
		BG = bg,
		Spinner = spinner,
		Title = title,
		Line = line,
		LineTween = lineTween,
		SpinTween = spinTween,
	}
end

function LoadingScreen:Hide()
	if not loadingScreenInstance then return end
	local s = loadingScreenInstance
	s.SpinTween:Cancel()
	TweenObject(s.BG, { BackgroundTransparency = 1 }, TWEEN.Slow)
	TweenObject(s.Title, { TextTransparency = 1 }, TWEEN.Normal)
	TweenObject(s.Line, { Size = UDim2.fromOffset(0, 2) }, TWEEN.Normal)

	task.delay(0.4, function()
		s.Screen:Destroy()
		loadingScreenInstance = nil
	end)
end

LoadingScreen:Show()

-- ── Element Base (mixin) ──────────────────────────────────────────────────

local ElementBase = {}
ElementBase.__index = ElementBase

function ElementBase:SetVisible(visible)
	self.Frame.Visible = visible
end

function ElementBase:GetVisible()
	return self.Frame.Visible
end

function ElementBase:Destroy()
	if self.Frame then
		self.Frame:Destroy()
	end
	if self.Cleanup then
		self.Cleanup()
	end
end

-- ── Window ────────────────────────────────────────────────────────────────

local Window = {}
Window.__index = Window

function Window.new(config)
	config = config or {}

	local self = setmetatable({
		Config = config,
		Tabs = {},
		TabsByName = {},
		Toggles = {},
		Options = {},
		TabButtons = {},
		ActiveTab = nil,
		MinSize = config.MinSize or Vector2.new(600, 400),
	}, Window)

	-- Main ScreenGui
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "ParacetamolUI"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.ScreenGui.DisplayOrder = 100
	self.ScreenGui.IgnoreGuiInset = true

	local target = (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or game:GetService("CoreGui")
	self.ScreenGui.Parent = target

	-- Background (click-to-close overlay)
	self.Overlay = Instance.new("Frame")
	self.Overlay.Size = UDim2.fromScale(1, 1)
	self.Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.Overlay.BackgroundTransparency = 0.5
	self.Overlay.BorderSizePixel = 0
	self.Overlay.Visible = config.AutoShow ~= false
	self.Overlay.Parent = self.ScreenGui

	-- Main Container
	self.Container = Instance.new("Frame")
	self.Container.Size = UDim2.fromOffset(680, 480)
	self.Container.Position = config.Center and UDim2.fromScale(0.5, 0.5) or UDim2.fromOffset(100, 80)
	self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Container.BackgroundColor3 = COLORS.Background
	self.Container.BackgroundTransparency = TRANSPARENCY.Window
	self.Container.BorderSizePixel = 0
	self.Container.ClipsDescendants = true
	self.Container.Visible = config.AutoShow ~= false
	self.Container.Parent = self.ScreenGui

	-- Window shadow
	CreateShadow(self.Container, 0.65, 40)

	-- Window corner / stroke
	CreateRound(self.Container, CORNERS.Window)
	CreateStroke(self.Container, COLORS.GlassHighlight, 0.88, 1)
	CreateGlowOverlay(self.Container)

	-- Titlebar
	self.TitleBar = Instance.new("Frame")
	self.TitleBar.Size = UDim2.fromScale(1, 0)
	self.TitleBar.Size = UDim2.new(1, 0, 0, 42)
	self.TitleBar.BackgroundTransparency = 1
	self.TitleBar.BorderSizePixel = 0
	self.TitleBar.Parent = self.Container
	MakeDraggable(self.Container, self.TitleBar)

	-- Title icon
	self.TitleIcon = CreateIcon("icons/graphic/logo", 20, COLORS.Accent)
	self.TitleIcon.Position = UDim2.fromOffset(16, 11)
	self.TitleIcon.Parent = self.TitleBar

	-- Title text
	self.TitleText = CreateTextLabel(config.Title or "ParacetamolUI", FONTS.Title, 16, COLORS.Text, Enum.TextXAlignment.Left)
	self.TitleText.Position = UDim2.fromOffset(44, 0)
	self.TitleText.Size = UDim2.fromScale(0.4, 1)
	self.TitleText.Parent = self.TitleBar

	-- Version text
	self.VersionText = CreateTextLabel("v" .. version, FONTS.Text, 10, COLORS.TextDim, Enum.TextXAlignment.Left)
	self.VersionText.Position = UDim2.new(0, 44, 0, 22)
	self.VersionText.Size = UDim2.new(0, 60, 0, 14)
	self.VersionText.Parent = self.TitleBar

	-- Tab container
	self.TabContainer = Instance.new("Frame")
	self.TabContainer.Size = UDim2.fromScale(1, 0)
	self.TabContainer.Size = UDim2.new(1, 0, 0, 36)
	self.TabContainer.Position = UDim2.fromOffset(0, 42)
	self.TabContainer.BackgroundTransparency = 1
	self.TabContainer.BorderSizePixel = 0
	self.TabContainer.Parent = self.Container

	local tabBg = Instance.new("Frame")
	tabBg.Size = UDim2.fromScale(1, 1)
	tabBg.BackgroundColor3 = COLORS.Section
	tabBg.BackgroundTransparency = TRANSPARENCY.Section
	tabBg.BorderSizePixel = 0
	tabBg.Parent = self.TabContainer

	-- Content area
	self.ContentArea = Instance.new("Frame")
	self.ContentArea.Size = UDim2.fromScale(1, 1)
	self.ContentArea.Position = UDim2.fromOffset(0, 78)
	self.ContentArea.Size = UDim2.new(1, -20, 1, -90)
	self.ContentArea.Position = UDim2.new(0, 10, 0, 80)
	self.ContentArea.BackgroundTransparency = 1
	self.ContentArea.BorderSizePixel = 0
	self.ContentArea.Parent = self.Container

	-- Resize handle
	local resizeHandle = Instance.new("Frame")
	resizeHandle.Size = UDim2.fromOffset(14, 14)
	resizeHandle.Position = UDim2.fromScale(1, 1)
	resizeHandle.AnchorPoint = Vector2.new(1, 1)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.BorderSizePixel = 0
	resizeHandle.Cursor = "ResizeSouthEast"
	resizeHandle.Parent = self.Container

	local resizeIcon = CreateIcon("icons/editor/resize", 10, COLORS.TextDim)
	resizeIcon.Position = UDim2.fromOffset(2, 2)
	resizeIcon.Size = UDim2.fromOffset(10, 10)
	resizeIcon.Parent = resizeHandle

	-- Resize logic
	local resizing = false
	local resizeStart, resizeSize
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStart = input.Position
			resizeSize = self.Container.Size
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position - resizeStart
		local newSize = Vector2.new(
			math.max(self.MinSize.X, resizeSize.X.Offset + delta.X),
			math.max(self.MinSize.Y, resizeSize.Y.Offset + delta.Y)
		)
		self.Container.Size = UDim2.fromOffset(newSize.X, newSize.Y)
	end)

	-- Separator line under tabs
	local sepLine = Instance.new("Frame")
	sepLine.Size = UDim2.fromScale(1, 0)
	sepLine.Size = UDim2.new(1, -20, 0, 1)
	sepLine.Position = UDim2.new(0, 10, 0, 78)
	sepLine.BackgroundColor3 = COLORS.Accent
	sepLine.BackgroundTransparency = 0.6
	sepLine.BorderSizePixel = 0
	sepLine.Parent = self.Container

	-- Store reference
	self.SeparatorLine = sepLine

	-- Visibility toggle
	self.Visible = config.AutoShow ~= false

	-- Helper to get toggles/options globally
	table.insert(Elements, self)

	return self
end

function Window:AddTab(name)
	local tab = Tab.new(name, self)
	self.Tabs[#self.Tabs + 1] = tab
	self.TabsByName[name] = tab

	-- Create tab button
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 0, 1, -8)
	btn.Position = UDim2.fromOffset(#self.Tabs * 2 - 2, 4)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = self.TabContainer

	local btnSize = TextService:GetTextSize(name, 13, FONTS.Text, Vector2.new(200, 36))
	local padding = 28
	btn.Size = UDim2.new(0, btnSize.X + padding, 1, -8)

	if #self.Tabs > 1 then
		local prev = self.TabButtons[#self.Tabs - 1]
		btn.Position = UDim2.new(0, prev.Position.X.Offset + prev.Size.X.Offset + 2, 0, 4)
	end

	local icon = CreateIcon("icons/navigation/check", 14, COLORS.TextDim)
	icon.Position = UDim2.fromOffset(8, 9)
	icon.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -(icon.Visible and 30 or 10), 1, 0)
	label.Position = UDim2.fromOffset(icon.Visible and 26 or 8, 0)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = name
	label.Font = FONTS.Text
	label.TextSize = 13
	label.TextColor3 = COLORS.TextDim
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = btn

	-- Active indicator
	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.new(1, -8, 0, 2)
	indicator.Position = UDim2.fromOffset(4, 1)
	indicator.BackgroundColor3 = COLORS.Accent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = btn
	CreateRound(indicator, 1)

	self.TabButtons[#self.Tabs] = btn

	-- Hover effect
	btn.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			TweenObject(label, { TextColor3 = COLORS.Text }, TWEEN.Fast)
			TweenObject(icon, { ImageColor3 = COLORS.Text }, TWEEN.Fast)
		end
	end)

	btn.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			TweenObject(label, { TextColor3 = COLORS.TextDim }, TWEEN.Fast)
			TweenObject(icon, { ImageColor3 = COLORS.TextDim }, TWEEN.Fast)
		end
	end)

	btn.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	-- Auto-select first tab
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	if self.ActiveTab == tab then return end
	if self.ActiveTab then
		local prevBtn = self.TabButtons[self.ActiveTab.Index]
		if prevBtn then
			local prevLabel = prevBtn:FindFirstChildOfClass("TextLabel")
			local prevIcon = prevBtn:FindFirstChildOfClass("ImageLabel")
			if prevLabel then
				TweenObject(prevLabel, { TextColor3 = COLORS.TextDim }, TWEEN.Fast)
			end
			if prevIcon then
				TweenObject(prevIcon, { ImageColor3 = COLORS.TextDim }, TWEEN.Fast)
			end
			local ind = prevBtn:FindFirstChild("Frame")
			if ind then
				TweenObject(ind, { BackgroundTransparency = 1 }, TWEEN.Fast)
			end
		end
		self.ActiveTab:Hide()
	end

	self.ActiveTab = tab
	local btn = self.TabButtons[tab.Index]
	if btn then
		local label = btn:FindFirstChildOfClass("TextLabel")
		local icon = btn:FindFirstChildOfClass("ImageLabel")
		if label then
			TweenObject(label, { TextColor3 = COLORS.Text }, TWEEN.Fast)
		end
		if icon then
			TweenObject(icon, { ImageColor3 = COLORS.Accent }, TWEEN.Fast)
		end
		local ind = btn:FindFirstChild("Frame")
		if ind then
			ind.BackgroundTransparency = 0
			TweenObject(ind, { BackgroundTransparency = 0 }, TWEEN.Fast)
		end
	end
	tab:Show()
end

function Window:Toggle()
	self.Visible = not self.Visible
	if self.Visible then
		self.Overlay.Visible = true
		self.Container.Visible = true
		self.Container.Size = UDim2.fromOffset(0, 0)
		self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
		TweenObject(self.Container, { Size = UDim2.fromOffset(680, 480) }, TWEEN.Bounce)
		TweenObject(self.Overlay, { BackgroundTransparency = 0.5 }, TWEEN.Normal)
	else
		TweenObject(self.Overlay, { BackgroundTransparency = 1 }, TWEEN.Fast)
		local close = TweenService:Create(self.Container, TWEEN.Fast, { Size = UDim2.fromOffset(0, 0) })
		close:Play()
		close.Completed:Connect(function()
			self.Overlay.Visible = false
			self.Container.Visible = false
		end)
	end
end

function Window:SetVisible(visible)
	if visible == self.Visible then return end
	self:Toggle()
end

function Window:SetWatermark(text)
	-- placeholder for watermark support
end

function Window:Notify(text, duration)
	duration = duration or 5
	local notifContainer = self.ScreenGui:FindFirstChild("NotificationContainer")
	if not notifContainer then
		notifContainer = Instance.new("Frame")
		notifContainer.Name = "NotificationContainer"
		notifContainer.Size = UDim2.fromOffset(320, 0)
		notifContainer.Position = UDim2.new(1, -340, 1, -80)
		notifContainer.AnchorPoint = Vector2.new(0, 1)
		notifContainer.BackgroundTransparency = 1
		notifContainer.BorderSizePixel = 0
		notifContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		notifContainer.Parent = self.ScreenGui
	end

	local notif = Instance.new("Frame")
	notif.Size = UDim2.fromScale(1, 0)
	notif.Size = UDim2.new(1, 0, 0, 0)
	notif.BackgroundColor3 = COLORS.Section
	notif.BackgroundTransparency = TRANSPARENCY.Section
	notif.BorderSizePixel = 0
	notif.AutomaticSize = Enum.AutomaticSize.Y
	notif.Parent = notifContainer

	CreateRound(notif, CORNERS.Element)
	CreateStroke(notif, COLORS.GlassHighlight, 0.9)
	CreateShadow(notif, 0.7, 20)

	local msg = CreateTextLabel(text, FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	msg.Size = UDim2.new(1, -24, 0, 0)
	msg.Position = UDim2.fromOffset(12, 10)
	msg.TextWrapped = true
	msg.AutomaticSize = Enum.AutomaticSize.Y
	msg.Parent = notif

	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = notifContainer

	-- Animate in
	notif.Size = UDim2.new(1, 0, 0, 0)
	notif.AutomaticSize = Enum.AutomaticSize.Y
	local _, contentH = notif.AbsoluteSize.Y, notif.AutomaticSize
	task.delay(0.05, function()
		local size = msg.TextBounds.Y + 20
		TweenObject(notif, { Size = UDim2.new(1, 0, 0, size) }, TWEEN.Bounce)
	end)

	task.delay(duration, function()
		TweenObject(notif, { Size = UDim2.new(1, 0, 0, 0) }, TWEEN.Normal)
		task.delay(0.3, function()
			notif:Destroy()
		end)
	end)
end

-- ── Tab ───────────────────────────────────────────────────────────────────

local Tab = {}
Tab.__index = Tab

local tabIndexCounter = 0

function Tab.new(name, parentWindow)
	tabIndexCounter = tabIndexCounter + 1

	local self = setmetatable({
		Name = name,
		Window = parentWindow,
		Index = tabIndexCounter,
		Container = nil,
		Sections = {},
		SectionIndex = 0,
		Active = false,
	}, Tab)

	-- Main tab container
	self.Container = Instance.new("ScrollingFrame")
	self.Container.Size = UDim2.fromScale(1, 1)
	self.Container.Position = UDim2.fromOffset(0, 0)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ScrollBarThickness = 3
	self.Container.ScrollBarImageColor3 = COLORS.Accent
	self.Container.ScrollBarImageTransparency = 0.5
	self.Container.CanvasSize = UDim2.fromScale(0, 0)
	self.Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Container.Visible = false
	self.Container.Parent = parentWindow.ContentArea

	return self
end

function Tab:Show()
	self.Container.Visible = true
	self.Active = true
end

function Tab:Hide()
	self.Container.Visible = false
	self.Active = false
end

function Tab:AddSection(name, side)
	side = side or "left"
	self.SectionIndex = self.SectionIndex + 1

	-- If we have a left and right section, split them
	local isLeft = side == "left"
	local containerWidth = self.Window and self.Window.ContentArea.AbsoluteSize.X or 650

	local section = Section.new(name, self, isLeft)
	self.Sections[#self.Sections + 1] = section
	return section
end

function Tab:AddLeftSection(name)
	return self:AddSection(name, "left")
end

function Tab:AddRightSection(name)
	return self:AddSection(name, "right")
end

-- ── Section ───────────────────────────────────────────────────────────────

local Section = {}
Section.__index = Section

function Section.new(name, parentTab, isLeft)
	local self = setmetatable({
		Name = name,
		Tab = parentTab,
		IsLeft = isLeft,
		Container = nil,
		Elements = {},
	}, Section)

	-- Section container
	self.Container = Instance.new("Frame")
	self.Container.Size = UDim2.new(0.5, -6, 0, 0)
	self.Container.Position = isLeft and UDim2.fromOffset(0, 0) or UDim2.new(0.5, 6, 0, 0)
	self.Container.BackgroundColor3 = COLORS.Section
	self.Container.BackgroundTransparency = TRANSPARENCY.Section
	self.Container.BorderSizePixel = 0
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.Parent = parentTab.Container

	CreateRound(self.Container, CORNERS.Section)
	CreateStroke(self.Container, COLORS.GlassHighlight, 0.9)
	CreateGlowOverlay(self.Container)

	-- Section title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(10, 6)
	title.BackgroundTransparency = 1
	title.BorderSizePixel = 0
	title.Text = name or ""
	title.Font = FONTS.Title
	title.TextSize = 13
	title.TextColor3 = COLORS.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = self.Container

	-- Element layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	-- Padding
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 32)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = self.Container

	-- Spacer between sections
	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.fromScale(1, 0)
	spacer.Size = UDim2.new(1, 0, 0, 4)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel = 0
	spacer.LayoutOrder = 9999
	spacer.Parent = self.Container

	-- Store layout for later use
	self.Layout = layout

	return self
end

-- ── Element Creation Helpers ──────────────────────────────────────────────
-- These go on the Section (and also Tab, which delegates)

-- Toggle
function Section:AddToggle(index, opts)
	opts = opts or {}
	local default = opts.Default or false
	local callback = opts.Callback or function() end

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.LayoutOrder = opts.Order or 1
	container.Parent = self.Container

	CreateRound(container, CORNERS.Toggle)
	CreateStroke(container, COLORS.GlassHighlight, 0.93)

	-- Hover effect
	local hover = Instance.new("Frame")
	hover.Size = UDim2.fromScale(1, 1)
	hover.BackgroundColor3 = COLORS.ElementHover
	hover.BackgroundTransparency = 1
	hover.BorderSizePixel = 0
	hover.Parent = container
	CreateRound(hover, CORNERS.Toggle)

	container.MouseEnter:Connect(function()
		TweenObject(hover, { BackgroundTransparency = TRANSPARENCY.ElementHover }, TWEEN.Fast)
	end)
	container.MouseLeave:Connect(function()
		TweenObject(hover, { BackgroundTransparency = 1 }, TWEEN.Fast)
	end)

	-- Toggle icon
	local icon = CreateIcon("icons/navigation/check", 16, COLORS.TextDim)
	icon.Position = UDim2.fromOffset(10, 8)
	icon.Parent = container

	-- Text
	local label = CreateTextLabel(opts.Text or index, FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.fromOffset(34, 0)
	label.Parent = container

	-- Tooltip
	if opts.Tooltip then
		label.Text = opts.Text
		local tooltip = Instance.new("TextLabel")
		tooltip.Size = UDim2.fromScale(1, 1)
		tooltip.BackgroundTransparency = 1
		tooltip.BorderSizePixel = 0
		tooltip.Text = opts.Tooltip
		tooltip.Font = FONTS.Text
		tooltip.TextSize = 13
		tooltip.TextColor3 = COLORS.Text
		tooltip.TextXAlignment = Enum.TextXAlignment.Left
		tooltip.Visible = false
		tooltip.Parent = container
	end

	-- Toggle switch
	local switch = Instance.new("Frame")
	switch.Size = UDim2.fromOffset(32, 18)
	switch.Position = UDim2.new(1, -40, 0.5, -9)
	switch.BackgroundColor3 = COLORS.TextDark
	switch.BackgroundTransparency = 0
	switch.BorderSizePixel = 0
	switch.Parent = container
	CreateRound(switch, 9)

	-- Switch knob
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = UDim2.fromOffset(2, 2)
	knob.BackgroundColor3 = COLORS.Text
	knob.BackgroundTransparency = 0
	knob.BorderSizePixel = 0
	knob.Parent = switch
	CreateRound(knob, 7)

	-- State
	local state = default
	local toggleObj = {
		Type = "Toggle",
		Index = index,
		Frame = container,
		Switch = switch,
		Knob = knob,
		Label = label,
		Icon = icon,
		Value = default,
		Callback = callback,
		OnChangedCallbacks = {},
		SetValue = function(_, new)
			new = not not new
			if new == state then return end
			state = new
			toggleObj.Value = new
			if new then
				TweenObject(switch, { BackgroundColor3 = COLORS.Accent }, TWEEN.Fast)
				TweenObject(knob, { Position = UDim2.fromOffset(16, 2) }, TWEEN.Fast)
				if icon then
					TweenObject(icon, { ImageColor3 = COLORS.Accent }, TWEEN.Fast)
				end
			else
				TweenObject(switch, { BackgroundColor3 = COLORS.TextDark }, TWEEN.Fast)
				TweenObject(knob, { Position = UDim2.fromOffset(2, 2) }, TWEEN.Fast)
				if icon then
					TweenObject(icon, { ImageColor3 = COLORS.TextDim }, TWEEN.Fast)
				end
			end
			callback(new)
			for _, cb in ipairs(toggleObj.OnChangedCallbacks) do
				task.spawn(cb, new)
			end
		end,
		OnChanged = function(_, cb)
			table.insert(toggleObj.OnChangedCallbacks, cb)
		end,
		GetValue = function()
			return state
		end,
	}

	-- Click handler
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggleObj:SetValue(not state)
		end
	end)

	-- Set initial state
	if default then
		switch.BackgroundColor3 = COLORS.Accent
		knob.Position = UDim2.fromOffset(16, 2)
		if icon then
			icon.ImageColor3 = COLORS.Accent
		end
	end

	-- Register
	ParacetamolToggles[index] = toggleObj
	self.Tab.Window.Toggles[index] = toggleObj
	table.insert(Elements, toggleObj)

	return toggleObj
end

-- Button
function Section:AddButton(opts)
	opts = opts or {}
	local callback = opts.Func or opts.Callback or function() end
	local doubleClick = opts.DoubleClick or false

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.LayoutOrder = opts.Order or 1
	container.Parent = self.Container

	CreateRound(container, CORNERS.Button)
	CreateStroke(container, COLORS.GlassHighlight, 0.93)

	-- Hover overlay
	local hover = Instance.new("Frame")
	hover.Size = UDim2.fromScale(1, 1)
	hover.BackgroundColor3 = COLORS.ElementHover
	hover.BackgroundTransparency = 1
	hover.BorderSizePixel = 0
	hover.Parent = container
	CreateRound(hover, CORNERS.Button)

	container.MouseEnter:Connect(function()
		TweenObject(hover, { BackgroundTransparency = TRANSPARENCY.ElementHover }, TWEEN.Fast)
	end)
	container.MouseLeave:Connect(function()
		TweenObject(hover, { BackgroundTransparency = 1 }, TWEEN.Fast)
	end)

	local icon = CreateIcon("icons/action/play_arrow", 16, COLORS.Accent)
	icon.Position = UDim2.fromOffset(10, 8)
	icon.Parent = container

	local label = CreateTextLabel(opts.Text or "Button", FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Position = UDim2.fromOffset(34, 0)
	label.Parent = container

	-- Click feedback tween
	local function onClick()
		TweenObject(container, { BackgroundColor3 = COLORS.AccentDark }, TWEEN.Fast)
		task.delay(0.15, function()
			TweenObject(container, { BackgroundColor3 = COLORS.Element }, TWEEN.Fast)
		end)
		task.spawn(callback)
	end

	local btnObj = {
		Type = "Button",
		Frame = container,
		Label = label,
		SubButtons = {},
		AddButton = function(_, subOpts)
			subOpts = subOpts or {}
			-- Simple sub-button support
			local subBtn = container:FindFirstChild("SubButton")
			if not subBtn then
				container.Size = UDim2.new(1, 0, 0, 50)
			end
			return Section.AddButton(self, subOpts)
		end,
	}

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			onClick()
		end
	end)

	return btnObj
end

-- Slider
function Section:AddSlider(index, opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local default = opts.Default or min
	local rounding = opts.Rounding or 0
	local suffix = opts.Suffix or ""
	local compact = opts.Compact or false
	local callback = opts.Callback or function() end

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, compact and 32 or 44)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.LayoutOrder = opts.Order or 1
	container.Parent = self.Container

	CreateRound(container, CORNERS.Element)
	CreateStroke(container, COLORS.GlassHighlight, 0.93)

	-- Icon
	local icon = CreateIcon("icons/editor/sliders", 14, COLORS.Accent)
	icon.Position = UDim2.fromOffset(10, compact and 9 or 15)
	icon.Parent = container

	-- Label
	local label = CreateTextLabel(opts.Text or index, FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, -70, 0, compact and 32 or 20)
	label.Position = UDim2.fromOffset(30, 0)
	label.Parent = container

	-- Value display
	local valueLabel = CreateTextLabel(tostring(default) .. suffix, FONTS.Text, 12, COLORS.Accent, Enum.TextXAlignment.Right)
	valueLabel.Size = UDim2.new(0, 50, 0, compact and 32 or 20)
	valueLabel.Position = UDim2.new(1, -58, 0, 0)
	valueLabel.Parent = container

	-- Slider track
	local trackY = compact and 20 or 32
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -16, 0, 4)
	track.Position = UDim2.fromOffset(8, trackY)
	track.BackgroundColor3 = COLORS.TextDark
	track.BackgroundTransparency = 0.4
	track.BorderSizePixel = 0
	track.Parent = container
	CreateRound(track, 2)

	-- Slider fill
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = COLORS.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	CreateRound(fill, 2)

	-- Slider knob
	local sliderKnob = Instance.new("Frame")
	sliderKnob.Size = UDim2.fromOffset(12, 12)
	sliderKnob.Position = UDim2.fromScale(0, -4)
	sliderKnob.AnchorPoint = Vector2.new(0, 0.5)
	sliderKnob.BackgroundColor3 = COLORS.Text
	sliderKnob.BorderSizePixel = 0
	sliderKnob.Parent = fill
	CreateRound(sliderKnob, 6)

	local currentValue = default
	local function updateSlider(inputPos)
		local absPos = track.AbsolutePosition
		local absSize = track.AbsoluteSize.X
		local ratio = math.clamp((inputPos - absPos.X) / absSize, 0, 1)
		local val = min + (max - min) * ratio
		local rounded = math.round(val * (10 ^ rounding)) / (10 ^ rounding)
		rounded = math.clamp(rounded, min, max)

		currentValue = rounded
		fill.Size = UDim2.fromScale(ratio, 1)
		valueLabel.Text = tostring(rounded) .. suffix
		callback(rounded)
	end

	-- Set initial
	if default > min then
		local ratio = (default - min) / (max - min)
		fill.Size = UDim2.fromScale(ratio, 1)
		valueLabel.Text = tostring(default) .. suffix
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			updateSlider(input.Position.X)
		end
	end)

	local dragging = false
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	-- Add spacing below track for non-compact
	if not compact then
		local spacer = Instance.new("Frame")
		spacer.Size = UDim2.fromScale(1, 0)
		spacer.Size = UDim2.new(1, 0, 0, 4)
		spacer.BackgroundTransparency = 1
		spacer.BorderSizePixel = 0
		spacer.Parent = container
	end

	local sliderObj = {
		Type = "Slider",
		Index = index,
		Frame = container,
		Label = label,
		Value = currentValue,
		Callback = callback,
		OnChangedCallbacks = {},
		SetValue = function(_, val)
			val = math.clamp(val, min, max)
			local ratio = (val - min) / (max - min)
			currentValue = val
			fill.Size = UDim2.fromScale(ratio, 1)
			valueLabel.Text = tostring(val) .. suffix
			callback(val)
		end,
		OnChanged = function(_, cb)
			table.insert(sliderObj.OnChangedCallbacks, cb)
		end,
		GetValue = function()
			return currentValue
		end,
	}

	ParacetamolOptions[index] = sliderObj
	self.Tab.Window.Options[index] = sliderObj
	table.insert(Elements, sliderObj)

	return sliderObj
end

-- Dropdown
function Section:AddDropdown(index, opts)
	opts = opts or {}
	local values = opts.Values or {}
	local default = opts.Default or (type(values[1]) == "string" and values[1] or nil)
	local multi = opts.Multi or false
	local specialType = opts.SpecialType or nil
	local callback = opts.Callback or function() end

	-- Resolve default
	local defaultStr = default
	if type(default) == "number" then
		defaultStr = values[default]
	end

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.LayoutOrder = opts.Order or 1
	container.Parent = self.Container

	CreateRound(container, CORNERS.Element)
	CreateStroke(container, COLORS.GlassHighlight, 0.93)

	-- Icon
	local icon = CreateIcon("icons/navigation/unfold_more", 16, COLORS.Accent)
	icon.Position = UDim2.fromOffset(10, 8)
	icon.Parent = container

	-- Label
	local label = CreateTextLabel(opts.Text or index, FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(0.5, -34, 1, 0)
	label.Position = UDim2.fromOffset(30, 0)
	label.Parent = container

	-- Selected value display
	local selLabel = CreateTextLabel(defaultStr or "Select...", FONTS.Text, 12, COLORS.TextDim, Enum.TextXAlignment.Right)
	selLabel.Size = UDim2.new(0.5, -34, 1, 0)
	selLabel.Position = UDim2.new(0.5, 0, 0, 0)
	selLabel.Parent = container

	-- Arrow
	local arrow = CreateIcon("icons/navigation/expand_more", 14, COLORS.TextDim)
	arrow.Position = UDim2.new(1, -22, 0.5, -7)
	arrow.Parent = container

	-- Dropdown expand container
	local dropContainer = Instance.new("Frame")
	dropContainer.Size = UDim2.new(1, -4, 0, 0)
	dropContainer.Position = UDim2.fromOffset(2, 34)
	dropContainer.BackgroundColor3 = COLORS.Section
	dropContainer.BackgroundTransparency = 0.3
	dropContainer.BorderSizePixel = 0
	dropContainer.ClipsDescendants = true
	dropContainer.Visible = false
	dropContainer.Parent = container

	CreateRound(dropContainer, CORNERS.Element - 2)
	CreateStroke(dropContainer, COLORS.GlassHighlight, 0.92)

	local selected = {}
	if default then
		if multi then
			selected[defaultStr] = true
		else
			selected[defaultStr] = true
		end
	end

	-- Build dropdown items
	local itemHeight = 26
	local items = {}
	local maxVisible = math.min(#values, 6)
	for i, val in ipairs(values) do
		local item = Instance.new("Frame")
		item.Size = UDim2.fromScale(1, 0)
		item.Size = UDim2.new(1, 0, 0, itemHeight)
		item.BackgroundColor3 = COLORS.Element
		item.BackgroundTransparency = 1
		item.BorderSizePixel = 0
		item.Parent = dropContainer

		local itemLabel = CreateTextLabel(tostring(val), FONTS.Text, 12, COLORS.Text, Enum.TextXAlignment.Left)
		itemLabel.Size = UDim2.new(1, -24, 1, 0)
		itemLabel.Position = UDim2.fromOffset(12, 0)
		itemLabel.Parent = item

		-- Checkmark for multi
		local checkIcon = nil
		if multi then
			checkIcon = CreateIcon("icons/navigation/check", 12, COLORS.Accent)
			checkIcon.Position = UDim2.new(1, -20, 0.5, -6)
			checkIcon.Visible = selected[val]
			checkIcon.Parent = item
		end

		item.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if multi then
					selected[val] = not selected[val]
					if checkIcon then
						checkIcon.Visible = selected[val]
					end
					selLabel.Text = "Multiple"
					callback(selected)
				else
					selected = { [val] = true }
					selLabel.Text = tostring(val)
					callback(val)
					closeDropdown()
				end
			end
		end)

		item.MouseEnter:Connect(function()
			TweenObject(item, { BackgroundTransparency = 0.7 }, TWEEN.Fast)
		end)
		item.MouseLeave:Connect(function()
			TweenObject(item, { BackgroundTransparency = 1 }, TWEEN.Fast)
		end)

		table.insert(items, item)
	end

	local isOpen = false
	local function openDropdown()
		if isOpen then return end
		isOpen = true
		local totalHeight = #values * itemHeight + 4
		local displayHeight = math.min(maxVisible, #values) * itemHeight + 4
		dropContainer.Visible = true
		TweenObject(dropContainer, { Size = UDim2.new(1, -4, 0, displayHeight) }, TWEEN.Normal)
		TweenObject(arrow, { Rotation = 180 }, TWEEN.Fast)

		-- Auto-expand container
		TweenObject(container, { Size = UDim2.new(1, 0, 0, 34 + displayHeight + 4) }, TWEEN.Normal)
	end

	local function closeDropdown()
		if not isOpen then return end
		isOpen = false
		TweenObject(dropContainer, { Size = UDim2.new(1, -4, 0, 0) }, TWEEN.Fast)
		TweenObject(arrow, { Rotation = 0 }, TWEEN.Fast)
		TweenObject(container, { Size = UDim2.new(1, 0, 0, 32) }, TWEEN.Normal)
		task.delay(0.2, function()
			if not isOpen then dropContainer.Visible = false end
		end)
	end

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if isOpen then closeDropdown() else openDropdown() end
		end
	end)

	local dropdownObj = {
		Type = "Dropdown",
		Index = index,
		Frame = container,
		Label = label,
		Value = selected,
		Callback = callback,
		OnChangedCallbacks = {},
		SetValue = function(_, val)
			if type(val) == "table" then
				selected = val
			else
				selected = { [tostring(val)] = true }
				selLabel.Text = tostring(val)
			end
			callback(val)
		end,
		OnChanged = function(_, cb)
			table.insert(dropdownObj.OnChangedCallbacks, cb)
		end,
		GetValue = function()
			return selected
		end,
	}

	ParacetamolOptions[index] = dropdownObj
	self.Tab.Window.Options[index] = dropdownObj
	table.insert(Elements, dropdownObj)

	return dropdownObj
end

-- TextBox / Input
function Section:AddInput(index, opts)
	opts = opts or {}
	local default = opts.Default or ""
	local placeholder = opts.Placeholder or ""
	local numeric = opts.Numeric or false
	local finished = opts.Finished or false
	local maxLength = opts.MaxLength or 0
	local callback = opts.Callback or function() end

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 38)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.LayoutOrder = opts.Order or 1
	container.Parent = self.Container

	CreateRound(container, CORNERS.Element)
	CreateStroke(container, COLORS.GlassHighlight, 0.93)

	local icon = CreateIcon("icons/action/edit", 14, COLORS.Accent)
	icon.Position = UDim2.fromOffset(10, 12)
	icon.Parent = container

	local label = CreateTextLabel(opts.Text or index, FONTS.Text, 13, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(0.4, -34, 0, 18)
	label.Position = UDim2.fromOffset(30, 2)
	label.Parent = container

	local boxContainer = Instance.new("Frame")
	boxContainer.Size = UDim2.new(0.6, -12, 0, 22)
	boxContainer.Position = UDim2.new(0.4, 0, 0, 20)
	boxContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
	boxContainer.BackgroundTransparency = 0.3
	boxContainer.BorderSizePixel = 0
	boxContainer.Parent = container

	CreateRound(boxContainer, 4)
	CreateStroke(boxContainer, COLORS.GlassHighlight, 0.94)

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -8, 1, 0)
	box.Position = UDim2.fromOffset(4, 0)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Text = default
	box.Font = FONTS.Text
	box.TextSize = 12
	box.TextColor3 = COLORS.Text
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = COLORS.TextDim
	box.ClearTextOnFocus = false
	box.Parent = boxContainer

	if numeric then
		box.Text = tostring(default)
	end

	box.FocusLost:Connect(function(enter)
		if numeric then
			local num = tonumber(box.Text)
			if num then
				box.Text = tostring(num)
			else
				box.Text = tostring(default)
			end
		end
		if not finished or enter then
			callback(box.Text)
		end
	end)

	local inputObj = {
		Type = "Input",
		Index = index,
		Frame = container,
		Label = label,
		Box = box,
		Value = default,
		Callback = callback,
		OnChangedCallbacks = {},
		SetValue = function(_, val)
			box.Text = tostring(val)
		end,
		OnChanged = function(_, cb)
			table.insert(inputObj.OnChangedCallbacks, cb)
		end,
		GetValue = function()
			return box.Text
		end,
	}

	ParacetamolOptions[index] = inputObj
	self.Tab.Window.Options[index] = inputObj
	table.insert(Elements, inputObj)

	return inputObj
end

-- Label
function Section:AddLabel(text, doesWrap)
	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.LayoutOrder = 999
	container.Parent = self.Container

	local label = CreateTextLabel(text or "", FONTS.Text, 12, COLORS.Text, Enum.TextXAlignment.Left)
	label.Size = UDim2.new(1, -4, 0, 0)
	label.Position = UDim2.fromOffset(2, 0)
	label.TextWrapped = doesWrap or false
	label.RichText = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = container

	-- Wait for size then set container height
	task.delay(0.05, function()
		container.Size = UDim2.new(1, 0, 0, label.TextBounds.Y + 4)
	end)

	local labelObj = {
		Type = "Label",
		Frame = container,
		Label = label,
		Text = text,
		SetText = function(_, newText)
			label.Text = newText
			container.Size = UDim2.new(1, 0, 0, label.TextBounds.Y + 4)
		end,
		AddColorPicker = function(_, idx, opts)
			return Section.AddColorPicker(self, idx, opts)
		end,
		AddKeyPicker = function(_, idx, opts)
			return Section.AddKeyPicker(self, idx, opts)
		end,
	}

	return labelObj
end

-- Divider
function Section:AddDivider()
	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 12)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.LayoutOrder = 9999
	container.Parent = self.Container

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -8, 0, 1)
	line.Position = UDim2.fromOffset(4, 6)
	line.BackgroundColor3 = COLORS.TextDark
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel = 0
	line.Parent = container

	CreateRound(line, 1)

	return { Type = "Divider", Frame = container }
end

-- Dependency Box
function Section:AddDependencyBox()
	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 0)
	container.Size = UDim2.new(1, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.ClipsDescendants = true
	container.Visible = true
	container.LayoutOrder = 1
	container.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.PaddingTop = UDim.new(0, 0)
	pad.PaddingBottom = UDim.new(0, 0)
	pad.Parent = container

	local depBox = {
		Type = "DependencyBox",
		Frame = container,
		Layout = layout,
		Dependencies = {},
		VisibleCache = true,
		-- Mirror section methods
		AddToggle = function(_, ...) return Section.AddToggle(self, ...) end,
		AddButton = function(_, ...) return Section.AddButton(self, ...) end,
		AddSlider = function(_, ...) return Section.AddSlider(self, ...) end,
		AddDropdown = function(_, ...) return Section.AddDropdown(self, ...) end,
		AddInput = function(_, ...) return Section.AddInput(self, ...) end,
		AddLabel = function(_, ...) return Section.AddLabel(self, ...) end,
		AddDivider = function(_, ...) return Section.AddDivider(self, ...) end,
		AddDependencyBox = function(_, ...) return Section.AddDependencyBox(self, ...) end,
		SetupDependencies = function(_, deps)
			depBox.Dependencies = deps
		end,
	}

	-- Override element parent to dependency box
	-- Actually, the elements will just be children of container
	-- They'll be added to the section's parent directly, not nested

	return depBox
end

-- ── Label.AddColorPicker passthrough ──────────────────────────────────────

local ColorPickerActive = false

function Section:AddColorPicker(index, opts)
	opts = opts or {}
	local default = opts.Default or Color3.fromRGB(255, 255, 255)
	local callback = opts.Callback or function() end

	-- ColorPreview mini element (used inline on labels)
	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(20, 20)
	container.BackgroundColor3 = default
	container.BorderSizePixel = 0
	container.Parent = self.Container

	CreateRound(container, 4)
	CreateStroke(container, COLORS.GlassHighlight, 0.9)

	-- Click to open color picker
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			ColorPickerActive = not ColorPickerActive
		end
	end)

	return {
		Type = "ColorPicker",
		Frame = container,
		Value = default,
		SetValueRGB = function(_, color)
			container.BackgroundColor3 = color
			callback(color)
		end,
		OnChanged = function(_, cb)
			-- Placeholder
		end,
	}
end

-- ── Label.AddKeyPicker passthrough ────────────────────────────────────────

function Section:AddKeyPicker(index, opts)
	opts = opts or {}
	local default = opts.Default or ""
	local mode = opts.Mode or "Toggle"
	local callback = opts.Callback or function() end
	local changedCallback = opts.ChangedCallback or function() end
	local syncToggleState = opts.SyncToggleState or false
	local noUI = opts.NoUI or false

	local container = Instance.new("Frame")
	container.Size = UDim2.fromOffset(80, 24)
	container.BackgroundColor3 = COLORS.Element
	container.BackgroundTransparency = TRANSPARENCY.Element
	container.BorderSizePixel = 0
	container.Parent = self.Container

	CreateRound(container, 4)
	CreateStroke(container, COLORS.GlassHighlight, 0.9)

	local label = CreateTextLabel(default or "None", FONTS.Text, 11, COLORS.Text, Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = container

	local listening = false
	local keybindObj = {
		Type = "Keybind",
		Index = index,
		Frame = container,
		Label = label,
		Value = default,
		Key = nil,
		Mode = mode,
		Holding = false,
		Listen = function()
			listening = true
			label.Text = "..."
			label.TextColor3 = COLORS.Accent
		end,
		GetState = function()
			if mode == "Always" then return true end
			if mode == "Toggle" then return keybindObj.Holding end
			if mode == "Hold" then return keybindObj.Holding end
			return false
		end,
		OnClick = function(_, cb)
			keybindObj.OnClickCallback = cb
		end,
		OnChanged = function(_, cb)
			keybindObj.OnChangedCallback = cb
		end,
		SetValue = function(_, val)
			if type(val) == "table" then
				keybindObj.Value = val[1] or default
				label.Text = val[1] or default
				keybindObj.Mode = val[2] or mode
			else
				keybindObj.Value = val
				label.Text = val
			end
		end,
	}

	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			keybindObj:Listen()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				local key = input.KeyCode.Name
				label.Text = key
				label.TextColor3 = COLORS.Text
				keybindObj.Value = key
				listening = false
				keybindObj.Key = input.KeyCode
				changedCallback(key, keybindObj)
			end
			return
		end

		if keybindObj.Key and input.KeyCode == keybindObj.Key then
			if mode == "Toggle" then
				keybindObj.Holding = not keybindObj.Holding
				if keybindObj.OnClickCallback then
					keybindObj.OnClickCallback(keybindObj.Holding)
				end
			elseif mode == "Hold" then
				keybindObj.Holding = true
				if keybindObj.OnClickCallback then
					keybindObj.OnClickCallback(true)
				end
			end
			callback(keybindObj.Holding)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end
		if keybindObj.Key and input.KeyCode == keybindObj.Key then
			if mode == "Hold" then
				keybindObj.Holding = false
				if keybindObj.OnClickCallback then
					keybindObj.OnClickCallback(false)
				end
				callback(false)
			end
		end
	end)

	ParacetamolOptions[index] = keybindObj
	self.Tab.Window.Options[index] = keybindObj
	table.insert(Elements, keybindObj)

	return keybindObj
end

-- ── Tab element delegation ────────────────────────────────────────────────
-- So users can call tab:AddToggle() directly (auto-creates a section)

function Tab:AddToggle(index, opts)
	local sec = self:GetOrCreateSection()
	return sec:AddToggle(index, opts)
end

function Tab:AddButton(opts)
	local sec = self:GetOrCreateSection()
	return sec:AddButton(opts)
end

function Tab:AddSlider(index, opts)
	local sec = self:GetOrCreateSection()
	return sec:AddSlider(index, opts)
end

function Tab:AddDropdown(index, opts)
	local sec = self:GetOrCreateSection()
	return sec:AddDropdown(index, opts)
end

function Tab:AddInput(index, opts)
	local sec = self:GetOrCreateSection()
	return sec:AddInput(index, opts)
end

function Tab:AddLabel(text, doesWrap)
	local sec = self:GetOrCreateSection()
	return sec:AddLabel(text, doesWrap)
end

function Tab:AddDivider()
	local sec = self:GetOrCreateSection()
	return sec:AddDivider()
end

function Tab:GetOrCreateSection()
	local lastSection = self.Sections[#self.Sections]
	if lastSection then
		return lastSection
	end
	-- Create default section
	local mainSection = Section.new("", self, true)
	mainSection.Container.Size = UDim2.new(1, -6, 0, 0)
	table.insert(self.Sections, mainSection)

	-- Update title label to be hidden
	local title = mainSection.Container:FindFirstChildOfClass("TextLabel")
	if title then title.Visible = false end

	return mainSection
end

-- ── Theme Manager ─────────────────────────────────────────────────────────

local ThemeManager = {}
ThemeManager.__index = ThemeManager

function ThemeManager:SetLibrary(lib)
	self.Library = lib
end

function ThemeManager:SetFolder(folder)
	self.Folder = folder
end

function ThemeManager:ApplyToTab(tab)
	local sec = tab:AddLeftSection("Theme")

	sec:AddLabel("Accent Color")
		:AddColorPicker("ThemeAccent", {
			Default = COLORS.Accent,
			Callback = function(color)
				COLORS.Accent = color
				-- Update all accent elements
				for _, elem in ipairs(Elements) do
					if elem.Type == "Toggle" and elem.Value then
						if elem.Switch then elem.Switch.BackgroundColor3 = color end
					end
					if elem.Type == "Slider" then
						-- Find fill
					end
				end
			end
		})
end

function ThemeManager:ApplyToGroupbox(groupbox)
	-- Compatibility alias
	return self:ApplyToTab(groupbox)
end

-- ── Save Manager ──────────────────────────────────────────────────────────

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager:SetLibrary(lib)
	self.Library = lib
end

function SaveManager:SetFolder(folder)
	self.Folder = folder
end

function SaveManager:IgnoreThemeSettings()
	-- Placeholder
end

function SaveManager:SetIgnoreIndexes(indexes)
	self.IgnoreIndexes = indexes or {}
end

function SaveManager:BuildConfigSection(tab)
	local sec = tab:AddRightSection("Configuration")

	sec:AddButton({
		Text = "Save Config",
		Func = function()
			print("Config saved (placeholder)")
		end,
	})

	sec:AddButton({
		Text = "Load Config",
		Func = function()
			print("Config loaded (placeholder)")
		end,
	})
end

function SaveManager:LoadAutoloadConfig()
	-- Placeholder
end

-- ── Library Export ────────────────────────────────────────────────────────

function ParacetamolUILib:CreateWindow(config)
	config = config or {}
	local win = Window.new(config)
	self.Window = win

	-- Hide loading screen
	task.delay(0.1, function()
		LoadingScreen:Hide()
	end)

	return win
end

function ParacetamolUILib:SetWatermark(text)
	if self.Window then
		self.Window:SetWatermark(text)
	end
end

function ParacetamolUILib:Notify(text, duration)
	if self.Window then
		self.Window:Notify(text, duration)
	end
end

function ParacetamolUILib:OnUnload(callback)
	self.UnloadCallback = callback
end

function ParacetamolUILib:Unload()
	self.Unloaded = true
	if self.UnloadCallback then
		task.spawn(self.UnloadCallback)
	end
	if self.Window and self.Window.ScreenGui then
		self.Window.ScreenGui:Destroy()
	end
end

ParacetamolUILib.ThemeManager = ThemeManager
ParacetamolUILib.SaveManager = SaveManager
ParacetamolUILib.Version = version
ParacetamolUILib.Unloaded = false

-- Keyboard toggle (End key by default)
local toggleBound = false
local function setupToggle()
	if toggleBound then return end
	toggleBound = true
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.End and ParacetamolUILib.Window then
			ParacetamolUILib.Window:Toggle()
		end
	end)
end

setupToggle()

-- Return the library
return ParacetamolUILib
