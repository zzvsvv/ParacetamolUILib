-- Example LocalScript / executor file.
-- In Roblox Studio, paste this into a LocalScript after loading the library however your workflow prefers.
-- In most executors, this file can be executed directly if readfile/loadstring are available.

local libraryPath = "D:\\ParacetamolUILib\\ParacetamolUILib.lua"
local Library

if typeof(readfile) == "function" and typeof(loadstring) == "function" then
	Library = loadstring(readfile(libraryPath))()
elseif getgenv and getgenv().ParacetamolUILib then
	Library = getgenv().ParacetamolUILib
else
	error("Load ParacetamolUILib.lua first, or use an executor with readfile/loadstring.")
end

local Window = Library:CreateWindow("Paracetamol UI Example", {
	AccentColor = Color3.fromRGB(0, 170, 255),
	BackgroundColor = Color3.fromRGB(45, 45, 45),
	ModuleColor = Color3.fromRGB(55, 55, 55),
	TextColor = Color3.fromRGB(235, 235, 235),
	Saveable = true,
	SaveKey = "ParacetamolExample",
})

local CombatTab = Window:CreateTab("Combat")
local GeneralTab = Window:CreateTab("General")
local VisualTab = Window:CreateTab("Visuals")

local combatModule = CombatTab:CreateModule("Combat Settings")
combatModule:AddToggle("Enabled", true, function(value)
	print("Combat enabled:", value)
end)
combatModule:AddSlider("Damage", 0, 100, 50, function(value)
	print("Damage:", value)
end)
combatModule:AddDropdown("Weapon", {"Sword", "Bow", "Staff"}, false, function(value)
	print("Weapon:", value)
end)
combatModule:AddButton("Reset", function()
	print("Reset clicked")
end)

local aimModule = CombatTab:CreateModule("Aim Assist")
aimModule:AddToggle("Enabled", false, function(value)
	print("Aim assist:", value)
end)
aimModule:AddSlider("Smoothness", 0, 1, 0.35, function(value)
	print("Smoothness:", value)
end)
aimModule:AddDropdown("Target Part", {"Head", "Torso", "Closest"}, false, function(value)
	print("Target part:", value)
end)

local filterModule = GeneralTab:CreateModule("Filters")
filterModule:AddToggle("Enabled", true, function(value)
	print("Filters enabled:", value)
end)
filterModule:AddDropdown("Teams", {"Red", "Blue", "Green"}, true, function(selected)
	print("Teams:", table.concat(selected, ", "))
end)
filterModule:AddSlider("Opacity", 0, 1, 0.5, function(value)
	print("Opacity:", value)
end)

local visualsModule = VisualTab:CreateModule("Visual Settings")
visualsModule:AddToggle("Enabled", true, function(value)
	print("Visuals enabled:", value)
end)
visualsModule:AddDropdown("Style", {"Default", "Soft", "Sharp"}, false, function(value)
	print("Style:", value)
end)
visualsModule:AddSlider("Brightness", 0, 10, 4, function(value)
	print("Brightness:", value)
end)

Window:LoadConfig()
