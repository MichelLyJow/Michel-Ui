local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/MichelLyJow/Michel-Ui/refs/heads/main/MichelScriptXne_v3.lua'))()

-- Window
local Window = Library:CreateWindow({
    Title = "Michel Script",
    Subtitle = "v3.1 | Example",
    Theme = "Violet",          -- Violet, Ocean, Emerald, Rose, Amber, Cyan, Crimson, Lime, Mono
    ToggleKey = Enum.KeyCode.RightShift,
    Discord = "namaserver",    -- opsional: kode / link invite
})

-- Tab Overview (akun, game, server, Discord)
Window:CreateOverviewTab({
    Name = "Overview",
    Default = true,
    Discord = "namaserver",
    CommunityName = "Michel Community",
})

-- Tab fitur
local Main = Window:Tab({Name = "Main", Desc = "Fitur utama"})
local Combat = Main:Section("Player")

Combat:Toggle({
    Name = "Auto Farm",
    Default = false,
    Flag = "AutoFarm",
    Interval = 0.2,
    Loop = function()          -- diulang otomatis selama toggle ON
        print("farming...")
    end,
    Info = "Menjalankan auto farm selama aktif.",
})

Combat:Slider({
    Name = "Walk Speed",
    Min = 16, Max = 100, Default = 16, Step = 1,
    Flag = "WalkSpeed",
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Combat:Dropdown({
    Name = "Target",
    Options = {"Nearest", "Lowest HP", "Random"},
    Default = "Nearest",
    Flag = "Target",
})

Combat:Keybind({
    Name = "Quick Action",
    Default = "F",
    Callback = function() Library:Notify({Title = "Keybind", Description = "F ditekan", Type = "success"}) end,
})

local Misc = Main:Section("Misc")

Misc:Textbox({Name = "Nama", Placeholder = "Ketik di sini...", Flag = "Nama"})
Misc:ColorPicker({Name = "Warna ESP", Default = Color3.fromRGB(255, 80, 80), Flag = "EspColor"})
Misc:Button({
    Name = "Reset Karakter",
    Confirm = "Yakin reset karakter?",
    Danger = true,
    Callback = function()
        local c = game.Players.LocalPlayer.Character
        if c then c:BreakJoints() end
    end,
})

-- Tab pengaturan tampilan (tema, wallpaper, ukuran) otomatis
Window:CreateAppearanceTab("Appearance")

Library:Notify({Title = "Loaded", Description = "Tekan RightShift untuk buka/tutup.", Type = "success"})

-- Baca nilai kapan saja: Library.Flags.WalkSpeed, Library.Flags.AutoFarm, dst.
