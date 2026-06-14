-- Example LocalScript / executor file.
-- Loads ParacetamolUILib from GitHub and creates a local-only utility demo.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/zzvsvv/ParacetamolUILib/refs/heads/main/ParacetamolUILib.lua"))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local Window = Library:CreateWindow("Paracetamol", {
	AccentColor = Color3.fromRGB(255, 54, 91),
	BackgroundColor = Color3.fromRGB(8, 9, 12),
	ModuleColor = Color3.fromRGB(13, 14, 18),
	PanelColor = Color3.fromRGB(18, 19, 24),
	TextColor = Color3.fromRGB(242, 244, 248),
	IconColor = Color3.fromRGB(242, 244, 248),
	Saveable = true,
	SaveKey = "ParacetamolExample",
	Blur = true,
})

local HomeTab = Window:CreateTab("Home", "Home")
local PlayerTab = Window:CreateTab("Player", "User")
local VisualTab = Window:CreateTab("Visuals", "Misc")
local WorldTab = Window:CreateTab("World", "Settings")
local MiscTab = Window:CreateTab("Misc", "Terminal")

local espFolder = PlayerGui:FindFirstChild("ParacetamolExampleESP") or Instance.new("Folder")
espFolder.Name = "ParacetamolExampleESP"
espFolder.Parent = PlayerGui

local espObjects = {}
local connections = {}

local state = {
	WalkSpeedEnabled = false,
	WalkSpeed = 16,
	JumpPowerEnabled = false,
	JumpPower = 50,
	ESPEnabled = false,
	ChamsEnabled = false,
	TeamCheck = false,
	MaxDistance = 1500,
	ClickTP = false,
}

local function notify(text)
	if Window.Notify then
		Window:Notify(text, 2.4)
	end
end

local function getCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
	local character = getCharacter()
	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	return character:FindFirstChild("HumanoidRootPart")
end

local function applyMovement()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end

	if state.WalkSpeedEnabled then
		humanoid.WalkSpeed = state.WalkSpeed
	end

	if state.JumpPowerEnabled then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = state.JumpPower
	end
end

table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.4)
	applyMovement()
end))

local function cleanupPlayerEsp(player)
	local entry = espObjects[player]
	if not entry then
		return
	end

	if entry.Highlight then
		entry.Highlight:Destroy()
	end
	if entry.Billboard then
		entry.Billboard:Destroy()
	end
	if entry.CharacterConnection then
		entry.CharacterConnection:Disconnect()
	end

	espObjects[player] = nil
end

local function shouldShowPlayer(player)
	if player == LocalPlayer then
		return false
	end

	if state.TeamCheck and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
		return false
	end

	return player.Character ~= nil
end

local function ensurePlayerEsp(player)
	if not shouldShowPlayer(player) then
		cleanupPlayerEsp(player)
		return
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not head or not root then
		return
	end

	local entry = espObjects[player]
	if not entry then
		entry = {}
		espObjects[player] = entry

		entry.Highlight = Instance.new("Highlight")
		entry.Highlight.Name = "ParacetamolChams"
		entry.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		entry.Highlight.OutlineTransparency = 0
		entry.Highlight.Parent = espFolder

		entry.Billboard = Instance.new("BillboardGui")
		entry.Billboard.Name = "ParacetamolName"
		entry.Billboard.AlwaysOnTop = true
		entry.Billboard.Size = UDim2.fromOffset(180, 34)
		entry.Billboard.StudsOffset = Vector3.new(0, 3.2, 0)
		entry.Billboard.Parent = espFolder

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.35
		label.Font = Enum.Font.GothamSemibold
		label.TextSize = 13
		label.Parent = entry.Billboard
		entry.Label = label

		entry.CharacterConnection = player.CharacterAdded:Connect(function()
			task.wait(0.25)
			cleanupPlayerEsp(player)
			ensurePlayerEsp(player)
		end)
	end

	local color = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 54, 91)
	entry.Highlight.Adornee = character
	entry.Highlight.FillColor = color
	entry.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	entry.Highlight.FillTransparency = state.ChamsEnabled and 0.55 or 1
	entry.Highlight.OutlineTransparency = state.ChamsEnabled and 0.1 or 1
	entry.Highlight.Enabled = state.ChamsEnabled

	entry.Billboard.Adornee = head
	entry.Billboard.Enabled = state.ESPEnabled

	local localRoot = getRoot()
	local distance = localRoot and math.floor((localRoot.Position - root.Position).Magnitude) or 0
	entry.Label.Text = string.format("%s  [%dm]", player.DisplayName, distance)
	entry.Label.TextColor3 = color

	if distance > state.MaxDistance then
		entry.Billboard.Enabled = false
		entry.Highlight.Enabled = false
	end
end

local espClock = 0
table.insert(connections, RunService.Heartbeat:Connect(function(delta)
	espClock = espClock + delta
	if espClock < 0.15 then
		return
	end
	espClock = 0

	if not state.ESPEnabled and not state.ChamsEnabled then
		for player in pairs(espObjects) do
			cleanupPlayerEsp(player)
		end
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		ensurePlayerEsp(player)
	end
end))

table.insert(connections, Players.PlayerRemoving:Connect(cleanupPlayerEsp))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not state.ClickTP then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and not UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
		return
	end

	local root = getRoot()
	if root and Mouse.Hit then
		root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 4, 0))
		notify("Teleported")
	end
end))

local homeModule = HomeTab:CreateModule("Status")
homeModule:AddToggle("Enabled", true, function(value)
	notify(value and "Paracetamol enabled" or "Paracetamol disabled")
end)
homeModule:AddButton("Unload Example", function()
	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	for player in pairs(espObjects) do
		cleanupPlayerEsp(player)
	end
	espFolder:Destroy()
	Window:Destroy()
end)

local movementModule = PlayerTab:CreateModule("Movement")
movementModule:AddToggle("Walkspeed", false, function(value)
	state.WalkSpeedEnabled = value
	applyMovement()
end)
movementModule:AddSlider("Walkspeed Value", 16, 140, 24, function(value)
	state.WalkSpeed = value
	applyMovement()
end)
movementModule:AddToggle("Jumppower", false, function(value)
	state.JumpPowerEnabled = value
	applyMovement()
end)
movementModule:AddSlider("Jumppower Value", 50, 220, 80, function(value)
	state.JumpPower = value
	applyMovement()
end)

local teleportModule = PlayerTab:CreateModule("Teleport")
teleportModule:AddToggle("Ctrl + Click TP", false, function(value)
	state.ClickTP = value
	notify(value and "Hold Ctrl and click to teleport" or "Click TP disabled")
end)

local espModule = VisualTab:CreateModule("ESP")
espModule:AddToggle("Name ESP", false, function(value)
	state.ESPEnabled = value
end)
espModule:AddToggle("Chams", false, function(value)
	state.ChamsEnabled = value
end)
espModule:AddToggle("Team Check", false, function(value)
	state.TeamCheck = value
end)
espModule:AddSlider("Max Distance", 100, 5000, 1500, function(value)
	state.MaxDistance = value
end)
espModule:AddDropdown("ESP Style", {"Clean", "Team", "Distance"}, false, function(value)
	notify("ESP style: " .. tostring(value))
end)

local lightingModule = WorldTab:CreateModule("Lighting")
lightingModule:AddToggle("Bright Mode", false, function(value)
	if value then
		Lighting.Brightness = 4
		Lighting.ClockTime = 14
	else
		Lighting.Brightness = 2
	end
end)
lightingModule:AddSlider("Brightness", 0, 10, Lighting.Brightness, function(value)
	Lighting.Brightness = value
end)
lightingModule:AddSlider("Clock Time", 0, 24, Lighting.ClockTime, function(value)
	Lighting.ClockTime = value
end)

local miscModule = MiscTab:CreateModule("Utility")
miscModule:AddButton("Refresh ESP", function()
	for player in pairs(espObjects) do
		cleanupPlayerEsp(player)
	end
	notify("ESP refreshed")
end)
miscModule:AddButton("Reset Character", function()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.Health = 0
	end
end)

Window:LoadConfig()
notify("Paracetamol loaded")
