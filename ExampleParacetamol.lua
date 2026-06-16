--[[
	ParacetamolUILib — Example Script
	Demonstrates ESP, LocalPlayer tweaks, and general UI usage
	Loadstring: https://raw.githubusercontent.com/zzvsvv/ParacetamolUILib/refs/heads/main/ParacetamolUILib.lua
]]

local repo = 'https://raw.githubusercontent.com/zzvsvv/ParacetamolUILib/refs/heads/main/'
local Library = loadstring(game:HttpGet(repo .. 'ParacetamolUILib.lua'))()

local Window = Library:CreateWindow({
	Title = 'Example Paracetamol',
	Center = true,
	AutoShow = true,
})

-- ── Services ──────────────────────────────────────────────────────────────
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ── Tabs ──────────────────────────────────────────────────────────────────
local Tabs = {
	Main = Window:AddTab('Main'),
	Combat = Window:AddTab('Combat'),
	Visuals = Window:AddTab('Visuals'),
	['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ── Main Tab ──────────────────────────────────────────────────────────────
local MainGroup = Tabs.Main:AddLeftSection('Player')

-- Toggle: Infinite Jump
MainGroup:AddToggle('InfiniteJump', {
	Text = 'Infinite Jump',
	Default = false,
	Tooltip = 'Allows you to jump while in mid-air',
})

-- Jump counter display
MainGroup:AddLabel('Hold Space to jump repeatedly while enabled.', true)

-- Slider: WalkSpeed
MainGroup:AddSlider('WalkSpeed', {
	Text = 'WalkSpeed',
	Default = 16,
	Min = 1,
	Max = 120,
	Suffix = ' studs/s',
	Rounding = 0,
})

-- Slider: JumpPower
MainGroup:AddSlider('JumpPower', {
	Text = 'JumpPower',
	Default = 50,
	Min = 10,
	Max = 200,
	Suffix = '',
	Rounding = 0,
})

-- Player info section
local InfoGroup = Tabs.Main:AddRightSection('Info')

InfoGroup:AddLabel('Player: <b>' .. LocalPlayer.Name .. '</b>', true)
InfoGroup:AddLabel('User ID: ' .. LocalPlayer.UserId, false)
InfoGroup:AddLabel('Account Age: ' .. LocalPlayer.AccountAge .. ' days', false)

local playerCountLabel = InfoGroup:AddLabel('Players online: ' .. #Players:GetPlayers(), false)
Players.PlayerAdded:Connect(function()
	playerCountLabel:SetText('Players online: ' .. #Players:GetPlayers())
end)
Players.PlayerRemoving:Connect(function()
	playerCountLabel:SetText('Players online: ' .. #Players:GetPlayers())
end)

-- ── Combat Tab ────────────────────────────────────────────────────────────
local CombatGroup = Tabs.Combat:AddLeftSection('Automation')

CombatGroup:AddToggle('AutoFarm', {
	Text = 'Auto Farm',
	Default = false,
	Tooltip = 'Automatically attacks nearest target',
})

CombatGroup:AddSlider('FarmRange', {
	Text = 'Range',
	Default = 30,
	Min = 5,
	Max = 100,
	Suffix = ' studs',
	Rounding = 0,
})

CombatGroup:AddButton({
	Text = 'Reset Character',
	Func = function()
		if LocalPlayer.Character then
			LocalPlayer.Character:BreakJoints()
		end
	end,
	Tooltip = 'Kills your character (resets position)',
})

local TargetGroup = Tabs.Combat:AddRightSection('Target Selection')

TargetGroup:AddDropdown('TargetMode', {
	Text = 'Target Mode',
	Values = { 'Nearest', 'Lowest HP', 'Highest HP', 'Random' },
	Default = 1,
})

TargetGroup:AddDropdown('TargetPlayer', {
	Text = 'Specific Player',
	SpecialType = 'Player',
	Values = {},
})

-- ── Visuals Tab ───────────────────────────────────────────────────────────
local VisualsGroup = Tabs.Visuals:AddLeftSection('ESP')

-- ESP Toggle
VisualsGroup:AddToggle('ESP', {
	Text = 'Player ESP',
	Default = false,
	Tooltip = 'Shows boxes, names, and health bars on all players',
})

-- Highlight style
VisualsGroup:AddDropdown('ESPStyle', {
	Text = 'ESP Style',
	Values = { 'Box', 'Highlight', 'Both' },
	Default = 2,
})

-- Toggle sub-options
VisualsGroup:AddToggle('ESPBoxes', {
	Text = 'Show Boxes',
	Default = true,
})

VisualsGroup:AddToggle('ESPNames', {
	Text = 'Show Names',
	Default = true,
})

VisualsGroup:AddToggle('ESPHealth', {
	Text = 'Show Health',
	Default = true,
})

VisualsGroup:AddToggle('ESPTracers', {
	Text = 'Show Tracers',
	Default = false,
})

-- ── ESP Implementation ────────────────────────────────────────────────────
-- Uses modern Highlight instances + Drawing for a complete ESP

local ESPObjects = {} -- player -> { highlight, drawing objects }

local function createESPForPlayer(player)
	if player == LocalPlayer then return end
	if ESPObjects[player] then return end

	local esp = { Player = player }

	-- Highlight
	local highlight = Instance.new('Highlight')
	highlight.Name = 'ParacetamolESP'
	highlight.FillColor = Color3.fromRGB(180, 15, 15)
	highlight.FillTransparency = 0.6
	highlight.OutlineColor = Color3.fromRGB(220, 40, 40)
	highlight.OutlineTransparency = 0.3
	highlight.Enabled = false
	highlight.Parent = player.Character or player

	-- Box (Drawing)
	local box = Drawing.new('Square')
	box.Visible = false
	box.Color = Color3.fromRGB(180, 15, 15)
	box.Thickness = 1.5
	box.Filled = false
	box.Transparency = 0.8

	-- Name label (Drawing)
	local nameLabel = Drawing.new('Text')
	nameLabel.Visible = false
	nameLabel.Color = Color3.fromRGB(255, 255, 255)
	nameLabel.Center = true
	nameLabel.Size = 13
	nameLabel.Font = 2 -- monospace
	nameLabel.Outline = true
	nameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)

	-- Health bar background
	local healthBg = Drawing.new('Square')
	healthBg.Visible = false
	healthBg.Color = Color3.fromRGB(30, 30, 30)
	healthBg.Filled = true
	healthBg.Thickness = 0

	-- Health bar fill
	local healthFill = Drawing.new('Square')
	healthFill.Visible = false
	healthFill.Filled = true
	healthFill.Thickness = 0

	-- Tracer line
	local tracer = Drawing.new('Line')
	tracer.Visible = false
	tracer.Color = Color3.fromRGB(180, 15, 15)
	tracer.Thickness = 1
	tracer.Transparency = 0.6

	esp.Highlight = highlight
	esp.Box = box
	esp.NameLabel = nameLabel
	esp.HealthBg = healthBg
	esp.HealthFill = healthFill
	esp.Tracer = tracer

	ESPObjects[player] = esp

	-- Handle character changes
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		highlight.Parent = char
	end)

	return esp
end

-- Rendering loop for ESP
local function updateESP()
	for player, esp in pairs(ESPObjects) do
		if not player or not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') then
			-- Hide all drawing objects if character doesn't exist
			esp.Box.Visible = false
			esp.NameLabel.Visible = false
			esp.HealthBg.Visible = false
			esp.HealthFill.Visible = false
			esp.Tracer.Visible = false
			esp.Highlight.Enabled = false
			continue
		end

		local char = player.Character
		local root = char:FindFirstChild('HumanoidRootPart')
		local humanoid = char:FindFirstChildOfClass('Humanoid')
		if not root or not humanoid then continue end

		-- Position on screen
		local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
		local headScreen, _ = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, 2.5, 0)).Position)
		local footScreen, _ = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -2.5, 0)).Position)

		if not onScreen then
			esp.Box.Visible = false
			esp.NameLabel.Visible = false
			esp.HealthBg.Visible = false
			esp.HealthFill.Visible = false
			esp.Tracer.Visible = false
			esp.Highlight.Enabled = ParacetamolToggles.ESP.Value and (ParacetamolOptions.ESPStyle.Value == 'Highlight' or ParacetamolOptions.ESPStyle.Value == 'Both')
			continue
		end

		local headPos = Vector2.new(headScreen.X, headScreen.Y)
		local footPos = Vector2.new(footScreen.X, footScreen.Y)
		local height = (headPos - footPos).Magnitude
		local width = height * 0.6
		local boxPos = Vector2.new(screenPos.X - width / 2, headPos.Y)
		local centerX = screenPos.X
		local espEnabled = ParacetamolToggles.ESP.Value

		-- Box
		if espEnabled and ParacetamolToggles.ESPBoxes.Value and (ParacetamolOptions.ESPStyle.Value == 'Box' or ParacetamolOptions.ESPStyle.Value == 'Both') then
			esp.Box.Visible = true
			esp.Box.Size = Vector2.new(width, height)
			esp.Box.Position = boxPos
		else
			esp.Box.Visible = false
		end

		-- Name
		if espEnabled and ParacetamolToggles.ESPNames.Value then
			esp.NameLabel.Visible = true
			esp.NameLabel.Position = Vector2.new(centerX, headPos.Y - 16)
			esp.NameLabel.Text = player.Name
		else
			esp.NameLabel.Visible = false
		end

		-- Health bar
		if espEnabled and ParacetamolToggles.ESPHealth.Value then
			local health = humanoid.Health
			local maxHealth = humanoid.MaxHealth
			local healthPct = math.clamp(health / maxHealth, 0, 1)
			local barWidth = width
			local barHeight = 3
			local barY = footPos.Y + 4

			-- Background
			healthBg.Visible = true
			healthBg.Size = Vector2.new(barWidth, barHeight)
			healthBg.Position = Vector2.new(boxPos.X, barY)

			-- Fill
			healthFill.Visible = true
			healthFill.Size = Vector2.new(barWidth * healthPct, barHeight)
			healthFill.Position = Vector2.new(boxPos.X, barY)
			healthFill.Color = Color3.fromHSV(healthPct * 0.35, 1, 1)
		else
			healthBg.Visible = false
			healthFill.Visible = false
		end

		-- Tracer
		if espEnabled and ParacetamolToggles.ESPTracers.Value then
			tracer.Visible = true
			tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			tracer.To = Vector2.new(screenPos.X, screenPos.Y)
		else
			tracer.Visible = false
		end

		-- Highlight
		local style = ParacetamolOptions.ESPStyle.Value
		esp.Highlight.Enabled = espEnabled and (style == 'Highlight' or style == 'Both')
	end
end

-- Create ESP for all existing players
for _, player in ipairs(Players:GetPlayers()) do
	createESPForPlayer(player)
end

-- ESP for new players
Players.PlayerAdded:Connect(function(player)
	createESPForPlayer(player)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(player)
	local esp = ESPObjects[player]
	if esp then
		esp.Box:Remove()
		esp.NameLabel:Remove()
		esp.HealthBg:Remove()
		esp.HealthFill:Remove()
		esp.Tracer:Remove()
		if esp.Highlight then esp.Highlight:Destroy() end
		ESPObjects[player] = nil
	end
end)

-- Main render loop
RunService.RenderStepped:Connect(function()
	updateESP()
end)

-- ── Visuals - Right Side ──────────────────────────────────────────────────
local WorldGroup = Tabs.Visuals:AddRightSection('World')

WorldGroup:AddToggle('FullBright', {
	Text = 'Full Bright',
	Default = false,
	Tooltip = 'Makes the world fully bright',
})

WorldGroup:AddToggle('NoFog', {
	Text = 'Remove Fog',
	Default = false,
	Tooltip = 'Removes all fog from the world',
})

WorldGroup:AddDropdown('TimeOfDay', {
	Text = 'Set Time',
	Values = { 'Default', 'Dawn', 'Noon', 'Dusk', 'Midnight' },
	Default = 1,
})

-- ── Logic ─────────────────────────────────────────────────────────────────

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') and ParacetamolToggles.InfiniteJump.Value then
		LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- WalkSpeed & JumpPower
local speedConnection = RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass('Humanoid')
	if not hum then return end

	hum.WalkSpeed = ParacetamolOptions.WalkSpeed and ParacetamolOptions.WalkSpeed.Value or 16
	hum.JumpPower = ParacetamolOptions.JumpPower and ParacetamolOptions.JumpPower.Value or 50
end)

-- FullBright
local function updateLighting()
	local light = game:GetService('Lighting')
	if ParacetamolToggles.FullBright.Value then
		light.Ambient = Color3.fromRGB(255, 255, 255)
		light.Brightness = 3
		light.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		light.ShadowSoftness = 0
	else
		light.Ambient = Color3.fromRGB(128, 128, 128)
		light.Brightness = 1
		light.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		light.ShadowSoftness = 0.5
	end
end

ParacetamolToggles.FullBright:OnChanged(updateLighting)
updateLighting()

-- ── UI Settings ───────────────────────────────────────────────────────────
Library.ThemeManager:SetLibrary(Library)
Library.SaveManager:SetLibrary(Library)
Library.SaveManager:IgnoreThemeSettings()
Library.SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
Library.ThemeManager:SetFolder('ParacetamolExample')
Library.SaveManager:SetFolder('ParacetamolExample')

Library.SaveManager:BuildConfigSection(Tabs['UI Settings'])
Library.ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Unload handler
Library:OnUnload(function()
	Library.Unloaded = true
	speedConnection:Disconnect()
	-- Clean up ESP
	for player, esp in pairs(ESPObjects) do
		esp.Box:Remove()
		esp.NameLabel:Remove()
		esp.HealthBg:Remove()
		esp.HealthFill:Remove()
		esp.Tracer:Remove()
		if esp.Highlight then esp.Highlight:Destroy() end
	end
	ESPObjects = {}
	-- Notify
	print('Paracetamol Example unloaded.')
end)
