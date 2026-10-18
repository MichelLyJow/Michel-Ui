local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/MichelLyJow/Michel-Ui/refs/heads/main/cs.lua'))()

local Window = Library:CreateWindow({
    Title = "Cortex Site",
    Subtitle = "MichelLyJow",
    Logo = "rbxassetid://91842012607245",
    Theme = "Mono",
    Accent = Color3.fromRGB(142, 69, 133),
    ToggleKey = Enum.KeyCode.RightShift,
    Discord = "https://discord.gg/6B36mdd6cJ",
})

Window:CreateOverviewTab({
    Name = "Overview",
    Icon = "user",
    Default = true,
    Discord = "https://discord.gg/6B36mdd6cJ",
    CommunityName = "Cortex Site",
    CommunityLogo = "rbxassetid://91842012607245",
})

local Main = Window:Tab({Name = "Main", Icon = 91842012607245, Desc = "Main features"})
local Player = Main:Section("Player")

Player:Toggle({
    Name = "Auto Farm",
    Default = false,
    Flag = "AutoFarm",
    Interval = 0.2,
    Loop = function()
        print("farming...")
    end,
    Info = "Runs auto farm while enabled.",
})

Player:Slider({
    Name = "Walk Speed",
    Min = 16, Max = 100, Default = 16, Step = 1,
    Flag = "WalkSpeed",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Player:Dropdown({
    Name = "Target",
    Options = {"Nearest", "Lowest HP", "Random"},
    Default = "Nearest",
    Flag = "Target",
})

Player:Keybind({
    Name = "Quick Action",
    Default = "F",
    Callback = function()
        Library:Notify({Title = "Keybind", Description = "F was pressed", Type = "success"})
    end,
})

local Misc = Main:Section("Misc")

Misc:Textbox({Name = "Name", Placeholder = "Type here...", Flag = "Name"})
Misc:ColorPicker({Name = "ESP Color", Default = Color3.fromRGB(255, 80, 80), Flag = "EspColor"})
Misc:Button({
    Name = "Reset Character",
    Confirm = "Are you sure you want to reset your character?",
    Danger = true,
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then char:BreakJoints() end
    end,
})

local World = Window:Tab({Name = "World", Icon = "home", Desc = "World and teleports"})
World:Section("Teleports"):Button({Name = "Teleport to Spawn", Callback = function() print("tp") end})

Window:CreateAppearanceTab("Appearance", false, "settings")

Library:Notify({Title = "Loaded", Description = "Press RightShift to show / hide.", Type = "success"})
