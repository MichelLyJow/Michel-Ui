# Michel UI (MichelScriptXne v3)

A Roblox Lua UI library. One loader line, then you build your menu with plain tables.

```lua
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/MichelLyJow/Michel-Ui/refs/heads/main/MichelScriptXne_v3.lua'))()
```

A full working script is in [`Example.lua`](Example.lua).

---

## 1. How the UI is structured

```
Library
└── Window                      Library:CreateWindow({...})
    ├── Overview tab            Window:CreateOverviewTab({...})   (account, game, server, Discord)
    ├── Tab                     Window:Tab({Name = ..., Icon = ...})
    │   └── Page                Tab:CreatePage("Name")            (optional, shows as a sub-tab on top)
    │       └── Section         Page:CreateSection("Name")        (a card)
    │           └── Elements    Section:Toggle / Slider / Button / ...
    └── Appearance tab          Window:CreateAppearanceTab(...)   (theme, background, size, UI scale)
```

Rules of thumb:

- **Tab** = an entry in the left sidebar.
- **Page** = a sub-tab inside a tab. If you do not need pages, skip them: `Tab:Section("Name")` creates a single hidden "Main" page for you.
- **Section** = a card that holds your controls. Sections fill the two columns automatically.
- **Elements** = the actual controls (toggle, slider, button, ...).

---

## 2. Create the window

```lua
local Window = Library:CreateWindow({
    Title = "Michel Script",                 -- first word gets the accent color
    Subtitle = "v1.0",                       -- optional
    Logo = "rbxassetid://123456789",         -- header logo AND toggle sphere (nil = letter badge)
    Theme = "Mono",
    Accent = Color3.fromRGB(142, 69, 133),   -- optional, overrides the theme accent
    ToggleKey = Enum.KeyCode.RightShift,
    Discord = "yourserver",                  -- invite code or link, adds a Discord button to the sidebar
})
```

All options (everything is optional):

| Option | What it does |
| --- | --- |
| `Title`, `Subtitle`, `SubtitleColor` | Header text |
| `Logo`, `LogoSize` | Header logo (asset id, number, or `Library.Icons` key). Also used by the toggle sphere |
| `SphereImage`, `SphereIconSize` | Use a different image for the toggle sphere |
| `SphereText`, `SphereWords` | Show text on the sphere instead of an image (max 2 words) |
| `Theme` | `Violet, Ocean, Emerald, Rose, Amber, Cyan, Crimson, Lime, Mono` |
| `Accent`, `Background` | `Color3` overrides |
| `Wallpaper` | `Aurora, Sunset, Ocean, Neon, Ember` |
| `BackgroundImage` | Your own background image (asset id) |
| `WindowTransparency`, `PanelTransparency` | `0` to `0.8` / `0` to `0.85` |
| `Size` | `Vector2.new(740, 430)` (min 580x320, max 1000x720) |
| `ToggleKey` | Key that shows or hides the window |
| `ShowStats` | `false` hides the Executor / FPS / ping chips |
| `Discord` | Invite code or link |
| `Folder` | Save folder name |
| `AutoSaveAppearance`, `AutoLoadAppearance` | `false` disables saving or loading the look |

Window methods:

```lua
Window:Show()  Window:Hide()  Window:Toggle()  Window:Destroy()
Window:Notify({...})                 -- same as Library:Notify
Window:Confirm({...})                -- confirmation dialog
Window:SetTheme("Ocean")             Window:SetAccent(Color3.fromRGB(255, 0, 80))
Window:SetBackgroundColor(Color3)    Window:SetWallpaper("Aurora")
Window:SetBackgroundImage("rbxassetid://...")   Window:ClearBackground()
Window:SetTransparency(0.2)          Window:SetPanelTransparency(0.1)
Window:SetScale(1.1)                 Window:SetSize(760, 440)
Window:ResetAppearance()
```

Running the script again closes the previous window first, so you never get two menus.

---

## 3. Add a tab

```lua
local Main = Window:Tab({
    Name = "Main",
    Icon = "sword",          -- see "Icons" below
    Desc = "Main features",  -- subtitle shown under the page title
    Default = false,         -- true = open this tab first
    Locked = false,          -- true = locked (needs Library.WhitelistedUsers)
})
```

The short form also works: `Window:Tab("Main", isDefault, isLocked, icon, desc)`.

## 4. Add sections

```lua
-- Quick way (one hidden page)
local Farm = Main:Section("Auto Farm")

-- With pages (sub-tabs at the top of the tab)
local Combat = Main:CreatePage("Combat")
local Aim    = Combat:CreateSection("Aimbot")
local Visual = Main:CreatePage("Visuals"):CreateSection("ESP")
```

## 5. Add elements

Every element takes one config table. `Flag` stores the live value in `Library.Flags[Flag]`.
`Info` adds a small "?" button with a description.

```lua
Farm:Toggle({
    Name = "Auto Farm", Default = false, Flag = "AutoFarm",
    Interval = 0.2,                          -- seconds between loop runs
    Loop = function() print("tick") end,     -- runs repeatedly while ON, stops by itself when OFF
    Callback = function(state) end,          -- optional, runs on every change
    Info = "Farms automatically.",
})

Farm:Slider({ Name = "Speed", Min = 16, Max = 100, Default = 16, Step = 1, Flag = "Speed",
    Callback = function(v) end })

Farm:Dropdown({ Name = "Target", Options = {"Nearest", "Lowest HP"}, Default = "Nearest",
    Multi = false, Flag = "Target", Callback = function(v) end })

Farm:Button({ Name = "Reset", Callback = function() end,
    Confirm = "Are you sure?",   -- optional confirmation dialog (or true)
    Danger = true })             -- red confirm button

Farm:Textbox({ Name = "Name", Placeholder = "Type...", Default = "", Flag = "Name", Callback = function(text) end })
Farm:ColorPicker({ Name = "ESP Color", Default = Color3.fromRGB(255, 80, 80), Flag = "Esp", Callback = function(c) end })
Farm:Keybind({ Name = "Quick Action", Default = "F", Callback = function() end })  -- Callback runs when the key is pressed

Farm:Label("Some text")
Farm:Copy("Discord", "discord.gg/yourserver")    -- button that copies text
Farm:Divider()
Farm:AddConfigManager()                          -- save / load / rename / delete configs
```

Read values anywhere:

```lua
if Library.Flags.AutoFarm then ... end
print(Library.Flags.Speed)
```

Errors inside callbacks never crash the UI. They are caught and shown as a notification.

---

## 6. Icons

The library ships with the full **Lucide** set (800+ icons, `Library.Lucide`). Anywhere an `Icon` is accepted you can pass:

| Value | Result |
| --- | --- |
| `"sword"` or `"lucide-sword"` | A Lucide icon |
| `"rbxassetid://123456789"` or `123456789` | Your own image |
| `"MyIcon"` | A name you registered in `Library.Icons` |
| `false` | No icon |
| `nil` | Default icon (`layout-grid`; Overview uses `user`, Appearance uses `sliders-horizontal`) |

Print every available Lucide name:

```lua
for name in pairs(Library.Lucide) do print(name) end
```

Register your own names once, then use them everywhere:

```lua
Library.Icons.Sword = "rbxassetid://123456789"
Window:Tab({Name = "Combat", Icon = "Sword"})
```

You can also replace the built-in images (do this **before** `CreateWindow`):

```lua
Library.Icons.Search  = "rbxassetid://123456789"
Library.Icons.Lock    = "rbxassetid://123456789"
Library.Icons.Discord = "rbxassetid://123456789"   -- replaces the default Discord logo
```

Lookup order: `Library.Icons` key, then Lucide, then a small built-in vector fallback (`bolt, pulse, signal, dot, ...`), then a plain asset id.

---

## 7. Overview and Appearance tabs

```lua
Window:CreateOverviewTab({
    Name = "Overview", Icon = "user", Default = true,
    Discord = "yourserver",              -- invite code or link
    CommunityName = "My Community",
    CommunityLogo = "rbxassetid://...",  -- optional
    HideName = true,                     -- masks your username (Mic***)
})

Window:CreateAppearanceTab("Appearance", false, "settings")
```

The Appearance tab lets players change theme, accent, background, wallpaper, transparency, window size and UI scale. Their choices are saved automatically.

---

## 8. Notifications and dialogs

```lua
Library:Notify({
    Title = "Loaded", Description = "Press RightShift to hide.",
    Type = "success",        -- success, warning, error (or Color = Color3)
    Duration = 3,
})

Window:Confirm({
    Title = "Delete?", Text = "This cannot be undone.",
    ConfirmText = "Delete", CancelText = "Cancel", Danger = true,
    OnConfirm = function() print("deleted") end,
})
```

---

## 9. Minimal template

```lua
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/MichelLyJow/Michel-Ui/refs/heads/main/MichelScriptXne_v3.lua'))()

local Window = Library:CreateWindow({ Title = "My Script", Logo = "rbxassetid://123456789" })
Window:CreateOverviewTab({ Default = true })

local Tab = Window:Tab({ Name = "Main", Icon = "sword" })
local Sec = Tab:Section("Features")
Sec:Toggle({ Name = "Example Toggle", Flag = "Example", Callback = function(v) print(v) end })

Window:CreateAppearanceTab("Appearance")
```

## 10. Adding more to your menu (checklist)

1. New feature group: add a `Tab:Section("Name")` and put elements in it.
2. New menu category: add `Window:Tab({Name = "...", Icon = "..."})`.
3. Too many sections in one tab: split them with `Tab:CreatePage("Name")`.
4. Need the value somewhere else: give the element a `Flag` and read `Library.Flags.YourFlag`.
5. Need a repeating action: use `Loop` on a Toggle instead of writing your own `while` loop.
