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

local function resolveFont(name, fallback)
	local ok, font = pcall(function()
		return Enum.Font[name]
	end)

	return ok and font or fallback
end

if _G.ParacetamolExampleCleanup then
	pcall(_G.ParacetamolExampleCleanup)
	_G.ParacetamolExampleCleanup = nil
end

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
	ToggleKey = Enum.KeyCode.RightShift,
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
local unloaded = false

local state = {
	WalkSpeedEnabled = false,
	WalkSpeed = 16,
	JumpPowerEnabled = false,
	JumpPower = 50,
	InfiniteJump = false,
	NoClip = false,
	ESPEnabled = false,
	ChamsEnabled = false,
	ESPHealth = true,
	TeamCheck = false,
	MaxDistance = 1500,
	ClickTP = false,
	ClickTPKey = "LeftControl",
	ESPStyle = "Clean",
	ESPFilter = "",
	UseCustomESPColor = false,
	ESPColor = Color3.fromRGB(255, 54, 91),
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

local function getKeyCode(name, fallback)
	local ok, keyCode = pcall(function()
		return Enum.KeyCode[tostring(name)]
	end)

	if ok and keyCode then
		return keyCode
	end

	return fallback or Enum.KeyCode.LeftControl
end

local function isBindDown(name, fallback)
	name = tostring(name or "")
	if name == "MB1" or name == "MouseButton1" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	elseif name == "MB2" or name == "MouseButton2" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end

	return UserInputService:IsKeyDown(getKeyCode(name, fallback))
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

table.insert(connections, UserInputService.JumpRequest:Connect(function()
	if not state.InfiniteJump then
		return
	end

	local humanoid = getHumanoid()
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
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

local function cleanupExample()
	if unloaded then
		return
	end

	unloaded = true

	for _, connection in ipairs(connections) do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	for player in pairs(espObjects) do
		cleanupPlayerEsp(player)
	end

	if espFolder and espFolder.Parent then
		espFolder:Destroy()
	end

	if Window and Window.Destroy then
		Window:Destroy()
	end
end

_G.ParacetamolExampleCleanup = cleanupExample

local function shouldShowPlayer(player)
	if player == LocalPlayer then
		return false
	end

	if state.ESPFilter ~= "" and not string.find(string.lower(player.Name), string.lower(state.ESPFilter), 1, true) and not string.find(string.lower(player.DisplayName), string.lower(state.ESPFilter), 1, true) then
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
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
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
		entry.Billboard.Size = UDim2.fromOffset(190, 44)
		entry.Billboard.StudsOffset = Vector3.new(0, 3.2, 0)
		entry.Billboard.Parent = espFolder

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 26)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.35
		label.Font = resolveFont("BuilderSansSemiBold", Enum.Font.GothamSemibold)
		label.TextSize = 13
		label.Parent = entry.Billboard
		entry.Label = label

		local healthBack = Instance.new("Frame")
		healthBack.Name = "HealthBack"
		healthBack.Size = UDim2.new(1, -38, 0, 4)
		healthBack.Position = UDim2.new(0, 19, 0, 30)
		healthBack.BackgroundColor3 = Color3.fromRGB(8, 9, 12)
		healthBack.BorderSizePixel = 0
		healthBack.Parent = entry.Billboard
		entry.HealthBack = healthBack

		local healthFill = Instance.new("Frame")
		healthFill.Name = "HealthFill"
		healthFill.Size = UDim2.fromScale(1, 1)
		healthFill.BackgroundColor3 = Color3.fromRGB(57, 202, 151)
		healthFill.BorderSizePixel = 0
		healthFill.Parent = healthBack
		entry.HealthFill = healthFill

		entry.CharacterConnection = player.CharacterAdded:Connect(function()
			task.wait(0.25)
			cleanupPlayerEsp(player)
			ensurePlayerEsp(player)
		end)
	end

	local localRoot = getRoot()
	local distance = localRoot and math.floor((localRoot.Position - root.Position).Magnitude) or 0
	local health = humanoid and math.max(humanoid.Health, 0) or 0
	local maxHealth = humanoid and math.max(humanoid.MaxHealth, 1) or 100
	local healthPercent = math.clamp(health / maxHealth, 0, 1)
	local teamColor = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 54, 91)
	local color = Color3.fromRGB(255, 255, 255)
	local labelText = player.DisplayName

	if state.ESPStyle == "Team" then
		color = teamColor
		labelText = string.format("%s  [%s]", player.DisplayName, player.Team and player.Team.Name or "No Team")
	elseif state.ESPStyle == "Distance" then
		local alpha = math.clamp(distance / math.max(state.MaxDistance, 1), 0, 1)
		color = Color3.fromRGB(80 + math.floor(175 * alpha), 255 - math.floor(155 * alpha), 120)
		labelText = string.format("%s  [%dm]", player.DisplayName, distance)
	else
		color = Color3.fromRGB(245, 247, 255)
	end

	if state.UseCustomESPColor then
		color = state.ESPColor
	end

	if state.ESPHealth then
		labelText = string.format("%s  [%d HP]", labelText, math.floor(health + 0.5))
	end

	entry.Highlight.Adornee = character
	entry.Highlight.FillColor = color
	entry.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	entry.Highlight.FillTransparency = state.ChamsEnabled and 0.55 or 1
	entry.Highlight.OutlineTransparency = state.ChamsEnabled and 0.1 or 1
	entry.Highlight.Enabled = state.ChamsEnabled

	entry.Billboard.Adornee = head
	entry.Billboard.Enabled = state.ESPEnabled

	entry.Label.Text = labelText
	entry.Label.TextColor3 = color
	entry.HealthBack.Visible = state.ESPEnabled and state.ESPHealth
	entry.HealthFill.Size = UDim2.fromScale(healthPercent, 1)
	entry.HealthFill.BackgroundColor3 = Color3.fromRGB(
		255 - math.floor(198 * healthPercent),
		75 + math.floor(127 * healthPercent),
		91
	)

	if distance > state.MaxDistance then
		entry.Billboard.Enabled = false
		entry.Highlight.Enabled = false
	end
end

local espClock = 0
table.insert(connections, RunService.Heartbeat:Connect(function(delta)
	if state.NoClip then
		local character = LocalPlayer.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end

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

	if not isBindDown(state.ClickTPKey, Enum.KeyCode.LeftControl) then
		return
	end

	local root = getRoot()
	if root and Mouse.Hit then
		root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 4, 0))
		notify("Teleported")
	end
end))

local homeModule = HomeTab:CreateModule("Status")
homeModule:AddLabel("RightShift hides or shows the menu.")
homeModule:AddDivider()
homeModule:AddToggle("Enabled", true, function(value)
	notify(value and "Paracetamol enabled" or "Paracetamol disabled")
end)
homeModule:AddButton("Unload Example", function()
	cleanupExample()
end):SetTooltip("Disconnects demo events, removes ESP objects, and destroys the UI.")

local movementModule = PlayerTab:CreateModule("Movement")
movementModule:AddLabel("Local humanoid movement values.")
movementModule:AddDivider()
local walkspeedToggle = movementModule:AddToggle("Walkspeed", false, function(value)
	state.WalkSpeedEnabled = value
	applyMovement()
end):SetTooltip("Applies the selected WalkSpeed to your local Humanoid.")
movementModule:AddSlider("Walkspeed Value", 16, 140, 24, function(value)
	state.WalkSpeed = value
	applyMovement()
end):SetTooltip("Higher values make your character move faster locally."):DependsOn(walkspeedToggle, true)
local jumpPowerToggle = movementModule:AddToggle("Jumppower", false, function(value)
	state.JumpPowerEnabled = value
	applyMovement()
end):SetTooltip("Applies custom JumpPower to your local Humanoid.")
movementModule:AddSlider("Jumppower Value", 50, 220, 80, function(value)
	state.JumpPower = value
	applyMovement()
end):SetTooltip("Controls how high your character jumps locally."):DependsOn(jumpPowerToggle, true)
movementModule:AddToggle("Infinite Jump", false, function(value)
	state.InfiniteJump = value
	notify(value and "Infinite jump enabled" or "Infinite jump disabled")
end):SetTooltip("Lets JumpRequest force another jump while enabled.")
movementModule:AddToggle("NoClip", false, function(value)
	state.NoClip = value
	notify(value and "NoClip enabled" or "NoClip disabled")
end):SetTooltip("Disables local character collisions every frame while enabled.")

local teleportModule = PlayerTab:CreateModule("Teleport")
teleportModule:AddLabel("Hold your selected key and click a point.")
teleportModule:AddDivider()
teleportModule:AddToggle("Ctrl + Click TP", false, function(value)
	state.ClickTP = value
	notify(value and ("Hold " .. state.ClickTPKey .. " and click to teleport") or "Click TP disabled")
end):SetTooltip("Hold the selected key and click in the world to teleport.")
teleportModule:AddKeybind("Click TP Key", Enum.KeyCode.LeftControl, function(keyName, pressed)
	state.ClickTPKey = keyName
	if not pressed and state.ClickTP then
		notify("Click TP key set to " .. keyName)
	end
end):SetTooltip("Click this control, then press any keyboard key to rebind.")

local espModule = VisualTab:CreateModule("ESP")
espModule:AddLabel("Client-side BillboardGui and Highlight ESP.")
espModule:AddDivider()
local nameEspToggle = espModule:AddToggle("Name ESP", false, function(value)
	state.ESPEnabled = value
end):SetTooltip("Shows a BillboardGui name tag above other players.")
espModule:AddToggle("Chams", false, function(value)
	state.ChamsEnabled = value
end):SetTooltip("Uses Highlight objects for client-side chams.")
espModule:AddToggle("Health Bar", true, function(value)
	state.ESPHealth = value
end):SetTooltip("Shows a small health bar and HP value on name ESP."):DependsOn(nameEspToggle, true)
espModule:AddToggle("Team Check", false, function(value)
	state.TeamCheck = value
end):SetTooltip("Hides players on your current team.")
local customColorToggle = espModule:AddToggle("Custom Color", false, function(value)
	state.UseCustomESPColor = value
end):SetTooltip("Overrides team/distance colors with the selected ESP color.")
espModule:AddColorPicker("ESP Color", Color3.fromRGB(255, 54, 91), function(value)
	state.ESPColor = value
end):SetTooltip("RGB color used when Custom Color is enabled."):DependsOn(customColorToggle, true)
espModule:AddSlider("Max Distance", 100, 5000, 1500, function(value)
	state.MaxDistance = value
end):SetTooltip("Hides ESP farther than this distance.")
espModule:AddInput("Name Filter", "", function(value)
	state.ESPFilter = tostring(value or "")
end):SetTooltip("Only shows players whose username or display name contains this text."):DependsOn(nameEspToggle, true)
espModule:AddDropdown("ESP Style", {"Clean", "Team", "Distance"}, false, function(value)
	state.ESPStyle = tostring(value)
	notify("ESP style: " .. state.ESPStyle)
end):SetTooltip("Changes the name tag text and color behavior."):DependsOn(nameEspToggle, true)

local lightingModule = WorldTab:CreateModule("Lighting")
lightingModule:AddLabel("Client-side lighting adjustments.")
lightingModule:AddDivider()
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
lightingModule:AddSlider("Camera FOV", 40, 120, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, function(value)
	local camera = workspace.CurrentCamera
	if camera then
		camera.FieldOfView = value
	end
end)

local miscModule = MiscTab:CreateModule("Utility")
miscModule:AddLabel("Runtime helpers for the demo script.")
miscModule:AddDivider()
miscModule:AddButton("Refresh ESP", function()
	for player in pairs(espObjects) do
		cleanupPlayerEsp(player)
	end
	notify("ESP refreshed")
end):SetTooltip("Rebuilds all current ESP objects.")
miscModule:AddButton("Reset Character", function()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.Health = 0
	end
end):SetTooltip("Sets your local Humanoid health to zero.")

Window:LoadConfig()
Window:StartWatermarkClock("Paracetamol")
notify("Paracetamol loaded")
