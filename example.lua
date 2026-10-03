local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/MichelScriptXne.lua"))()
Library.WhitelistedUsers = {"YourUsername"}

local Window = Library:CreateWindow({
    Title = "Michel Script Xne",
    Subtitle = "Made By Hypol-X",
    SphereText = true,
    SphereWords = "MX",
    Theme = "Violet"
})

local Main = Window:CreateTab("Main", true)
local Page = Main:CreatePage("General")
local Sec = Page:CreateSection("Player")
Sec:AddToggle("Speed Boost", false, function(v) print("Speed", v) end)
Sec:AddSlider("WalkSpeed", 16, 100, 16, function(v) print(v) end)
Sec:AddDropdown("Mode", {"Legit", "Rage", "Safe"}, false, function(v) print(v) end)
Sec:AddButton("Hello", function() Library:Notify({Title = "Hi", Description = "It works", Type = "success"}) end)

Window:CreateAppearanceTab("Appearance")

local Cfg = Window:CreateTab("Configs")
Cfg:CreatePage("Saves"):CreateSection("Saves"):AddConfigManager()
