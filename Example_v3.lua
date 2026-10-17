-- Contoh pemakaian Michel Script Xne v3 (Easy API)
local Library = loadstring(readfile("MichelScriptXne_v3.lua"))() -- atau loadstring(game:HttpGet("LINK_RAW"))()

local Window = Library:CreateWindow({
    Title = "Michel Community",           -- kata pertama otomatis berwarna accent
    Discord = "https://discord.gg/XXXX",  -- opsional: tombol Discord di sidebar
})

-- Tab Overview ala Fyy (akun, game, server, info Discord)
Window:CreateOverviewTab({
    Discord = "https://discord.gg/XXXX",
    CommunityName = "Michel Community",
})

local Steal = Window:Tab({Name = "Steal", Desc = "Auto steal tools"})
local Farm = Steal:Section("Auto Farm")

-- Toggle + Loop: jalan otomatis selama ON, berhenti sendiri saat OFF
Farm:Toggle({
    Name = "Auto Collect", Flag = "AutoCollect", Interval = 0.5,
    Loop = function()
        -- isi aksi di sini; error tidak bikin script mati
    end,
})
Farm:Slider({Name = "Speed", Min = 1, Max = 10, Default = 3, Flag = "Speed"})
Farm:Dropdown({Name = "Target", Options = {"Common", "Rare", "Epic"}, Default = "Rare", Flag = "Target"})
Farm:Button({Name = "Reset Data", Confirm = "Yakin reset?", Danger = true, Callback = function()
    Library:Notify("Reset", "Data direset", 3, "success")
end})

-- Baca nilai kapan saja tanpa simpan state sendiri:
-- Library.Flags.AutoCollect, Library.Flags.Speed, Library.Flags.Target

Window:CreateAppearanceTab("Settings")
