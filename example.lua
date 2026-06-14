-- Example LocalScript / executor file.
-- Loads ParacetamolUILib from GitHub and creates a small test window.

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/zzvsvv/ParacetamolUILib/refs/heads/main/ParacetamolUILib.lua"))()

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local Window = Library:CreateWindow("Paracetamol", {
	AccentColor = Color3.fromRGB(255, 54, 91),
	BackgroundColor = Color3.fromRGB(7, 8, 10),
	ModuleColor = Color3.fromRGB(12, 13, 16),
	PanelColor = Color3.fromRGB(16, 17, 21),
	TextColor = Color3.fromRGB(235, 238, 242),
	Saveable = true,
	SaveKey = "ParacetamolExample",
	Blur = true,
})

local MainTab = Window:CreateTab("Main", "MAIN")
local PlayerTab = Window:CreateTab("Player", "P")
local VisualTab = Window:CreateTab("Visuals", "X")

local espModule = VisualTab:CreateModule("ESP")
espModule:AddToggle("Enabled", false, function(value)
	print("ESP:", value)
end)
espModule:AddDropdown("Mode", {"Box", "Name", "Full"}, true, function(values)
	print("ESP modes:", table.concat(values, ", "))
end)
espModule:AddSlider("Distance", 100, 5000, 1200, function(value)
	print("ESP distance:", value)
end)

local brightnessModule = VisualTab:CreateModule("Brightness")
brightnessModule:AddToggle("Enabled", false, function(value)
	if value then
		Lighting.Brightness = 4
	end
end)
brightnessModule:AddSlider("Change Brightness", 0, 10, Lighting.Brightness, function(value)
	Lighting.Brightness = value
end)
brightnessModule:AddButton("Reset Brightness", function()
	Lighting.Brightness = 2
end)

local movementModule = PlayerTab:CreateModule("Movement")
movementModule:AddToggle("Enabled", true, function(value)
	print("Movement controls:", value)
end)
movementModule:AddSlider("Walkspeed", 16, 100, 16, function(value)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = value
	end
end)
movementModule:AddSlider("Jumppower", 50, 200, 50, function(value)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = value
	end
end)

local testModule = MainTab:CreateModule("Module")
testModule:AddToggle("Enabled", true, function(value)
	print("Test module:", value)
end)
testModule:AddSlider("Slider", 0, 1, 0.35, function(value)
	print("Slider:", value)
end)
testModule:AddDropdown("Enum", {"Enum", "Enum2", "Enum3"}, false, function(value)
	print("Enum:", value)
end)

Window:LoadConfig()
