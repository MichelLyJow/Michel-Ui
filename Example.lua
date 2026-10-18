local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/MichelLyJow/Michel-Ui/refs/heads/main/MichelScriptXne_v3.lua'))()

-- // ICONS
-- Built-in icons (no asset needed): user, grid, list, home, bolt, settings, pulse, signal, dot
-- To use your own image, just swap the value:
--   Icon = "rbxassetid://1234567890"      (asset id)
--   Icon = 1234567890                      (number)
--   Icon = false                           (no icon)
-- Or register a name once and reuse it everywhere:
--   Library.Icons.Sword = "rbxassetid://1234567890"   ->   Icon = "Sword"
-- You can also replace the built-in ones, e.g. the search icon:
--   Library.Icons.Search = "rbxassetid://1234567890"
--   Library.Icons.Discord = "rbxassetid://1234567890"   (replaces the built-in Discord mark)

-- // WINDOW
local Window = Library:CreateWindow({
    Title = "Michel Script",            -- first word gets the accent color
    Subtitle = "v3.1 | Example",
    Logo = "rbxassetid://91842012607245", -- header logo + toggle sphere (nil = letter badge)
    Theme = "Mono",                     -- Violet, Ocean, Emerald, Rose, Amber, Cyan, Crimson, Lime, Mono
    Accent = Color3.fromRGB(142, 69, 133), -- plum (remove this line to use the theme's own accent)
    ToggleKey = Enum.KeyCode.RightShift,
    Discord = "yourserver",             -- invite code or link (optional)
})

-- // OVERVIEW TAB (account, game, server, Discord)
Window:CreateOverviewTab({
    Name = "Overview",
    Icon = "user",
    Default = true,
    Discord = "yourserver",
    CommunityName = "Michel Community",
    CommunityLogo = nil,                -- "rbxassetid://..." (optional)
})

-- // FEATURE TABS
local Main = Window:Tab({Name = "Main", Icon = 91842012607245, Desc = "Main features"})
local Player = Main:Section("Player")

Player:Toggle({
    Name = "Auto Farm",
    Default = false,
    Flag = "AutoFarm",
    Interval = 0.2,
    Loop = function()                   -- repeated automatically while the toggle is ON
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

-- A second tab (swap "home" for your own asset id any time)
local World = Window:Tab({Name = "World", Icon = "home", Desc = "World and teleports"})
World:Section("Teleports"):Button({Name = "Teleport to Spawn", Callback = function() print("tp") end})

-- // APPEARANCE TAB (theme, wallpaper, size, scale)
Window:CreateAppearanceTab("Appearance", false, "settings")

Library:Notify({Title = "Loaded", Description = "Press RightShift to show / hide.", Type = "success"})

-- Read values anytime: Library.Flags.WalkSpeed, Library.Flags.AutoFarm, ...
