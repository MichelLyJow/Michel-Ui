local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/MichelScriptXne.lua"))()

Library.WhitelistedUsers = {"UsernameKamu"}

local Window = Library:CreateWindow({
    Title = "Michel Script Xne",
    Subtitle = "Made By Hypol-X",
    Theme = "Violet",
    SphereText = true,
    SphereWords = "MX",
    ToggleKey = Enum.KeyCode.RightShift
})

local Main = Window:CreateTab("Main", true)
local General = Main:CreatePage("General")

local Player = General:CreateSection("Player")

Player:AddToggle("Speed Boost", false, function(on)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = on and 50 or 16 end
end)

Player:AddSlider("Jump Power", 50, 200, 50, function(v)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end)

Player:AddDropdown("Mode", {"Legit", "Rage", "Safe"}, false, function(v)
    print(v)
end)

Player:AddTextbox("Name", "Type here...", function(text)
    print(text)
end)

Player:AddColorPicker("ESP Color", Color3.fromRGB(255, 0, 0), function(color)
    print(color)
end)

Player:AddKeybind("Quick Action", Enum.KeyCode.F, function()
    print("F pressed")
end)

local Misc = General:CreateSection("Misc")

Misc:AddButton("Notify", function()
    Library:Notify({Title = "Success", Description = "It works!", Type = "success", Duration = 3})
end, {
    Title = "Notify",
    Description = "Shows a notification in the corner.",
    Example = 'Library:Notify({Title = "Hello", Description = "Text"})'
})

Misc:AddButton("Confirm", function()
    Window:Confirm({
        Title = "Are you sure?",
        Text = "This is a confirm popup.",
        Danger = true,
        ConfirmText = "Continue",
        OnConfirm = function() print("Confirmed") end
    })
end)

Misc:AddCopyButton("Copy Discord", "https://discord.gg/example")
Misc:AddLabel("Plain text label.")

local VIP = Window:CreateTab("VIP", false, true)
VIP:CreatePage("Premium"):CreateSection("VIP Features"):AddButton("Secret", function()
    print("VIP")
end)

Window:CreateAppearanceTab("Appearance")

local Cfg = Window:CreateTab("Configs")
Cfg:CreatePage("Saves"):CreateSection("Saves"):AddConfigManager()

Library:Notify({Title = "Michel Script Xne", Description = "Loaded!", Type = "success"})
