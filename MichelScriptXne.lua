-- // Michel Script Xne Library (Core Engine) v2.0
-- // Event-driven engine: no per-frame loops, live theming, background changer, auto-fit scaling.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local Library = {
    Name = "Michel Script Xne Library",
    Version = "2.0.0",
    WhitelistedUsers = {}
}

-- // Utility: File System / Executor Mock Overrides
local _isfolder = isfolder or function() return true end
local _makefolder = makefolder or function() end
local _writefile = writefile or function(path, data) warn("File saving not supported on this executor.") end
local _readfile = readfile or function() return "{}" end
local _listfiles = listfiles or function() return {} end
local _delfile = delfile or function() warn("File deletion not supported.") end
local _isfile = isfile or function() return false end
local _getasset = getcustomasset or getsynasset
local _request = request or http_request or (syn and syn.request)

-- // Utility: Safe Clipboard Copy
local function SafeCopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    else
        warn("Clipboard copying is not supported on your current executor.")
    end
end

local function GetGuiParent()
    if RunService:IsStudio() then
        return Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return CoreGui
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- // Themes (every surface color is derived from Accent + Background)
local function MakeTheme(accent, bg)
    local white, black = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    return {
        Accent = accent,
        Background = bg,
        Card = bg:Lerp(white, 0.05),
        Input = bg:Lerp(black, 0.35),
        Hover = bg:Lerp(white, 0.11),
        Stroke = bg:Lerp(white, 0.17),
        Text = rgb(240, 240, 244),
        SubText = rgb(150, 150, 162)
    }
end

local Themes = {
    Violet = MakeTheme(rgb(190, 140, 255), rgb(16, 16, 19)),
    Ocean = MakeTheme(rgb(80, 170, 255), rgb(10, 14, 24)),
    Emerald = MakeTheme(rgb(70, 210, 150), rgb(10, 20, 17)),
    Rose = MakeTheme(rgb(255, 110, 150), rgb(24, 13, 17)),
    Amber = MakeTheme(rgb(255, 185, 70), rgb(21, 17, 11)),
    Mono = MakeTheme(rgb(235, 235, 235), rgb(14, 14, 14))
}
local ThemeOrder = {"Violet", "Ocean", "Emerald", "Rose", "Amber", "Mono"}

local BackgroundPresets = {
    ["Midnight"] = rgb(16, 16, 19),
    ["Graphite"] = rgb(27, 27, 31),
    ["Deep Navy"] = rgb(10, 14, 26),
    ["Plum"] = rgb(24, 14, 32),
    ["Forest"] = rgb(10, 22, 18),
    ["Crimson"] = rgb(28, 12, 15),
    ["Pure Black"] = rgb(0, 0, 0)
}
local BackgroundOrder = {"Midnight", "Graphite", "Deep Navy", "Plum", "Forest", "Crimson", "Pure Black"}

local Wallpapers = {
    Aurora = {rgb(20, 205, 165), rgb(95, 70, 215), rgb(18, 20, 44)},
    Sunset = {rgb(255, 125, 90), rgb(205, 60, 145), rgb(38, 20, 72)},
    Ocean = {rgb(35, 130, 230), rgb(24, 64, 150), rgb(8, 14, 32)},
    Neon = {rgb(255, 60, 200), rgb(70, 70, 255), rgb(10, 10, 32)},
    Ember = {rgb(255, 165, 45), rgb(205, 55, 45), rgb(32, 10, 14)}
}
local WallpaperOrder = {"None", "Aurora", "Sunset", "Ocean", "Neon", "Ember"}

Library.Themes = Themes
Library.Wallpapers = Wallpapers

-- Live theme table (mutated in place so every closure sees updates)
local T = {}
for k, v in pairs(Themes.Violet) do T[k] = v end

local GOLD = rgb(255, 215, 0)

-- // Utility: Smooth Tweening
local function Tween(instance, properties, duration, style, direction)
    if not instance then return end
    local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

-- // Utility: Instance Creator (sane defaults, Parent assigned last)
local Defaults = {
    Frame = {BorderSizePixel = 0},
    CanvasGroup = {BorderSizePixel = 0},
    TextLabel = {BorderSizePixel = 0, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12},
    TextButton = {BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 12},
    TextBox = {BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 12, ClearTextOnFocus = false},
    ImageLabel = {BorderSizePixel = 0, BackgroundTransparency = 1},
    ImageButton = {BorderSizePixel = 0, AutoButtonColor = false},
    ScrollingFrame = {BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 2, CanvasSize = UDim2.new(0, 0, 0, 0)}
}

local function Create(className, properties)
    local instance = Instance.new(className)
    if className == "TextBox" then instance.Text = "" end
    local d = Defaults[className]
    if d then
        for k, v in pairs(d) do instance[k] = v end
    end
    local parent
    for k, v in pairs(properties or {}) do
        if k == "Parent" then parent = v else instance[k] = v end
    end
    if parent then instance.Parent = parent end
    return instance
end

local function Corner(parent, radius)
    local r = (radius == "full") and UDim.new(1, 0) or UDim.new(0, radius or 6)
    return Create("UICorner", {Parent = parent, CornerRadius = r})
end

local function Pad(parent, l, t, r, b)
    return Create("UIPadding", {
        Parent = parent,
        PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0)
    })
end

local function ListLayout(parent, padding, direction)
    return Create("UIListLayout", {
        Parent = parent,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 0),
        FillDirection = direction or Enum.FillDirection.Vertical
    })
end

-- // Utility: Micro-Interaction Bounce (small buttons only)
local function AddBounce(button, scaleFactor)
    scaleFactor = scaleFactor or 0.94
    local scaleObj = button:FindFirstChild("UIScale") or Create("UIScale", {Parent = button, Scale = 1})
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = scaleFactor}, 0.12)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Tween(scaleObj, {Scale = 1}, 0.15)
        end
    end)
    button.MouseLeave:Connect(function() Tween(scaleObj, {Scale = 1}, 0.15) end)
end

-- // Utility: Build search index for a card (cached)
local function BuildSearchIndex(card)
    local parts = {}
    for _, desc in ipairs(card:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            if desc.Text and desc.Text ~= "" then
                table.insert(parts, desc.Text:lower())
            end
        end
    end
    return table.concat(parts, " ")
end

local function Hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return tostring(h)
end

-- // Global Notification API
local GlobalNotifContainer
local NotifColors = {
    success = rgb(80, 205, 125),
    warning = rgb(255, 190, 70),
    error = rgb(240, 85, 95)
}

function Library:Notify(options)
    if not GlobalNotifContainer then return end
    options = options or {}
    local title = options.Title or "Notification"
    local desc = options.Description or "Information updated."
    local duration = options.Duration or 3
    local color = options.Color or NotifColors[options.Type or ""] or T.Accent
    local leftPad = options.Icon and 52 or 16

    local Wrap = Create("Frame", {Parent = GlobalNotifContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
    local Card = Create("CanvasGroup", {
        Parent = Wrap, BackgroundColor3 = T.Card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1.15, 0, 0, 0), GroupTransparency = 1
    })
    Corner(Card, 10)
    Create("UIStroke", {Parent = Card, Color = T.Stroke, Thickness = 1})
    Create("Frame", {Parent = Card, BackgroundColor3 = color, Size = UDim2.new(0, 3, 1, 0), ZIndex = 3})

    if options.Icon then
        Create("ImageLabel", {Parent = Card, Image = tostring(options.Icon), ImageColor3 = color, Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(16, 14), ZIndex = 3})
    end

    local Content = Create("Frame", {Parent = Card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
    Pad(Content, leftPad, 12, 14, 0)
    ListLayout(Content, 3)
    Create("TextLabel", {
        Parent = Content, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Text,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, RichText = options.RichText == true, LayoutOrder = 1
    })
    Create("TextLabel", {
        Parent = Content, Text = desc, TextSize = 12, TextColor3 = T.SubText,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, RichText = options.RichText == true, LayoutOrder = 2
    })
    local Bar = Create("Frame", {Parent = Content, BackgroundColor3 = color, BackgroundTransparency = 0.35, Size = UDim2.new(1, 0, 0, 2), LayoutOrder = 3})
    local BarSpacer = Create("Frame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 7), LayoutOrder = 2})
    BarSpacer.LayoutOrder = 3
    Bar.LayoutOrder = 4

    Tween(Card, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}, 0.45, Enum.EasingStyle.Quint)
    Tween(Bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(Card, {Position = UDim2.new(1.15, 0, 0, 0), GroupTransparency = 1}, 0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.42)
        Wrap:Destroy()
    end)
end

function Library:CreateWindow(options)
    options = (type(options) == "string") and {Title = options} or (options or {})

    local W, H = 680, 430
    if typeof(options.Size) == "Vector2" then
        W, H = options.Size.X, options.Size.Y
    elseif typeof(options.Size) == "UDim2" then
        W, H = options.Size.X.Offset, options.Size.Y.Offset
    end
    local MIN_W, MIN_H, MAX_W, MAX_H = 580, 320, 1000, 720
    W = math.clamp(W, MIN_W, MAX_W)
    H = math.clamp(H, MIN_H, MAX_H)

    local hubName = options.Title or Library.Name
    local subText = options.Subtitle or "Made By Hypol-X"
    local subColor = options.SubtitleColor
    local sphTextToggle = options.SphereText == true
    local sphWords = "MX"
    if options.SphereWords ~= nil then
        -- Enforce 2-word limit logic
        local wordList = string.split(tostring(options.SphereWords), " ")
        if #wordList > 2 then
            sphWords = wordList[1] .. " " .. wordList[2]
        else
            sphWords = tostring(options.SphereWords)
        end
    end
    local sphImage = options.SphereImage
    local topbarLogo = options.Logo
    local logoSize = options.LogoSize or 30
    local sphIconSize = options.SphereIconSize or 26
    local folder = options.Folder or "MichelScriptXne"
    local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
    local showStats = options.ShowStats ~= false

    -- // Appearance state (saved/loaded automatically)
    local State = {
        Theme = "Violet", Accent = Themes.Violet.Accent, Background = Themes.Violet.Background,
        Wallpaper = nil, Image = nil, BgOpacity = 0.6, WindowTransparency = 0, PanelTransparency = 0, Scale = 1, Width = W, Height = H
    }
    if options.Theme and Themes[options.Theme] then
        State.Theme = options.Theme
        State.Accent = Themes[options.Theme].Accent
        State.Background = Themes[options.Theme].Background
    end
    if typeof(options.Accent) == "Color3" then State.Accent = options.Accent State.Theme = "Custom" end
    if typeof(options.Background) == "Color3" then State.Background = options.Background State.Theme = "Custom" end

    if type(options.Wallpaper) == "string" and Wallpapers[options.Wallpaper] then State.Wallpaper = options.Wallpaper end
    if options.BackgroundImage then State.Image = tostring(options.BackgroundImage) end

    if type(options.WindowTransparency) == "number" then State.WindowTransparency = math.clamp(options.WindowTransparency, 0, 0.8) end
    if type(options.PanelTransparency) == "number" then State.PanelTransparency = math.clamp(options.PanelTransparency, 0, 0.85) end

    -- AppDefaults = the look this window was configured with (used by Reset Appearance).
    local AppDefaults = {
        Theme = State.Theme, Accent = State.Accent, Background = State.Background,
        Wallpaper = State.Wallpaper, Image = State.Image,
        WindowTransparency = State.WindowTransparency, PanelTransparency = State.PanelTransparency,
        Width = W, Height = H
    }
    -- If the script's defaults change, an older saved look is ignored once so the new defaults show.
    local DefaultSig = Hash(table.concat({
        tostring(AppDefaults.Theme), AppDefaults.Accent:ToHex(), AppDefaults.Background:ToHex(), tostring(AppDefaults.Wallpaper),
        tostring(AppDefaults.Image), tostring(AppDefaults.WindowTransparency), tostring(AppDefaults.PanelTransparency), tostring(W), tostring(H)
    }, "|"))

    local savedPath = folder .. "/appearance.json"
    if options.AutoLoadAppearance ~= false and _isfile(savedPath) then
        local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(savedPath)) end)
        if ok and type(data) == "table" and data.Sig == DefaultSig then
            State.Wallpaper, State.Image = nil, nil
            local function hex(v, fallback)
                local s, c = pcall(Color3.fromHex, v)
                return s and c or fallback
            end
            if type(data.Accent) == "string" then State.Accent = hex(data.Accent, State.Accent) end
            if type(data.Background) == "string" then State.Background = hex(data.Background, State.Background) end
            if type(data.Theme) == "string" then State.Theme = data.Theme end
            if type(data.Wallpaper) == "string" and Wallpapers[data.Wallpaper] then State.Wallpaper = data.Wallpaper end
            if type(data.Image) == "string" and data.Image ~= "" then State.Image = data.Image end
            if type(data.BgOpacity) == "number" then State.BgOpacity = math.clamp(data.BgOpacity, 0, 1) end
            if type(data.WindowTransparency) == "number" then State.WindowTransparency = math.clamp(data.WindowTransparency, 0, 0.8) end
            if type(data.PanelTransparency) == "number" then State.PanelTransparency = math.clamp(data.PanelTransparency, 0, 0.8) end
            if type(data.Scale) == "number" then State.Scale = math.clamp(data.Scale, 0.6, 1.5) end
            if type(data.Width) == "number" then State.Width = math.clamp(data.Width, MIN_W, MAX_W) end
            if type(data.Height) == "number" then State.Height = math.clamp(data.Height, MIN_H, MAX_H) end
        end
    end
    W, H = State.Width, State.Height
    for k, v in pairs(MakeTheme(State.Accent, State.Background)) do T[k] = v end

    local Window = {CurrentTab = nil, Tabs = {}, AllCards = {}, ConfigElements = {}, Folder = folder, UserScale = State.Scale, CurrentTransparency = State.WindowTransparency}

    local ScreenGui = Create("ScreenGui", {
        Name = "MichelScriptXne_UI_" .. HttpService:GenerateGUID(false),
        Parent = GetGuiParent(),
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    })
    local InsetY = GuiService:GetGuiInset().Y

    -- // Connection store (global-service listeners must be cleaned on destroy)
    local Connections = {}
    local function Conn(signal, fn)
        local c = signal:Connect(fn)
        table.insert(Connections, c)
        return c
    end

    -- // Live theme registry
    local Bound, ThemeCallbacks = {}, {}
    local function Bind(obj, prop, key)
        obj[prop] = T[key]
        table.insert(Bound, {obj, prop, key})
    end
    local function New(class, props, binds)
        local o = Create(class, props)
        if binds then
            for p, k in pairs(binds) do Bind(o, p, k) end
        end
        return o
    end
    local function OnTheme(fn) table.insert(ThemeCallbacks, fn) end
    local function ApplyTheme(instant)
        for i = #Bound, 1, -1 do
            local b = Bound[i]
            if b[1].Parent then
                if instant then b[1][b[2]] = T[b[3]] else Tween(b[1], {[b[2]] = T[b[3]]}, 0.25) end
            else
                table.remove(Bound, i)
            end
        end
        for _, fn in ipairs(ThemeCallbacks) do pcall(fn) end
    end

    local function ContrastText(c)
        local l = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
        return l > 0.62 and rgb(20, 20, 24) or rgb(255, 255, 255)
    end
    local function AccentFill(btn, animate)
        local danger = btn:GetAttribute("Danger")
        local c = danger and rgb(205, 60, 72) or T.Accent
        local tc = danger and rgb(255, 255, 255) or ContrastText(c)
        if animate then
            Tween(btn, {BackgroundColor3 = c, TextColor3 = tc}, 0.25)
        else
            btn.BackgroundColor3 = c
            btn.TextColor3 = tc
        end
    end
    local function RegAccent(btn)
        AccentFill(btn)
        OnTheme(function() AccentFill(btn, true) end)
    end

    -- // Panel transparency registry (cards / sidebar follow one value)
    local Panel = {Transparency = State.PanelTransparency}
    local PanelObjs = {}
    local function BindPanel(o)
        o.BackgroundTransparency = Panel.Transparency
        table.insert(PanelObjs, o)
    end
    local function ApplyPanel()
        for i = #PanelObjs, 1, -1 do
            local o = PanelObjs[i]
            if o.Parent then Tween(o, {BackgroundTransparency = Panel.Transparency}, 0.25) else table.remove(PanelObjs, i) end
        end
    end

    -- // Appearance persistence (debounced)
    local savePending = false
    local function QueueSave()
        if options.AutoSaveAppearance == false or savePending then return end
        savePending = true
        task.delay(0.6, function()
            savePending = false
            pcall(function()
                if not _isfolder(folder) then _makefolder(folder) end
                _writefile(savedPath, HttpService:JSONEncode({
                    Theme = State.Theme, Accent = State.Accent:ToHex(), Background = State.Background:ToHex(),
                    Wallpaper = State.Wallpaper, Image = State.Image, BgOpacity = State.BgOpacity,
                    WindowTransparency = State.WindowTransparency, PanelTransparency = State.PanelTransparency, Scale = State.Scale,
                    Width = State.Width, Height = State.Height, Sig = DefaultSig
                }))
            end)
        end)
    end

    -- // Shared drag engine (one listener pair for window, sphere, sliders, color picker)
    local ActiveDrag
    local function BeginDrag(startInput, move, finish)
        ActiveDrag = {Input = startInput, Move = move, Finish = finish}
    end
    Conn(UserInputService.InputChanged, function(input)
        local d = ActiveDrag
        if not d then return end
        local isTouch = d.Input.UserInputType == Enum.UserInputType.Touch
        if (isTouch and input.UserInputType == Enum.UserInputType.Touch) or (not isTouch and input.UserInputType == Enum.UserInputType.MouseMovement) then
            d.Move(input)
        end
    end)
    Conn(UserInputService.InputEnded, function(input)
        local d = ActiveDrag
        if not d then return end
        local isTouch = d.Input.UserInputType == Enum.UserInputType.Touch
        if (isTouch and input.UserInputType == Enum.UserInputType.Touch) or (not isTouch and input.UserInputType == Enum.UserInputType.MouseButton1) then
            ActiveDrag = nil
            if d.Finish then d.Finish() end
        end
    end)

    local function IsPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    local function MakeDraggable(handle, target)
        handle.Active = true
        handle.InputBegan:Connect(function(input)
            if IsPress(input) then
                local startPos, startMouse = target.Position, input.Position
                BeginDrag(input, function(i)
                    local d = i.Position - startMouse
                    target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end)
            end
        end)
    end

    local function FocusFx(box, stroke)
        box.Focused:Connect(function() Tween(stroke, {Color = T.Accent}, 0.2) end)
        box.FocusLost:Connect(function() Tween(stroke, {Color = T.Stroke}, 0.2) end)
    end

    local function IconButton(parent, position, kind)
        local B = New("TextButton", {Parent = parent, Text = "", Size = UDim2.fromOffset(30, 30), Position = position}, {BackgroundColor3 = "Input"})
        Corner(B, 8)
        local BSt = New("UIStroke", {Parent = B, Thickness = 1}, {Color = "Stroke"})
        local parts = {}
        if kind == "min" or kind == "minus" then
            table.insert(parts, Create("Frame", {Parent = B, Size = UDim2.fromOffset(10, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)}))
        elseif kind == "plus" then
            for _, r in ipairs({0, 90}) do
                table.insert(parts, Create("Frame", {Parent = B, Size = UDim2.fromOffset(10, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Rotation = r}))
            end
        else
            for _, r in ipairs({45, -45}) do
                table.insert(parts, Create("Frame", {Parent = B, Size = UDim2.fromOffset(12, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Rotation = r}))
            end
        end
        for _, p in ipairs(parts) do
            Bind(p, "BackgroundColor3", "SubText")
            Corner(p, "full")
        end
        local danger = (kind == "close")
        B.MouseEnter:Connect(function()
            Tween(B, {BackgroundColor3 = danger and rgb(205, 60, 72) or T.Hover}, 0.15)
            Tween(BSt, {Color = danger and rgb(205, 60, 72) or T.Accent}, 0.15)
            for _, p in ipairs(parts) do Tween(p, {BackgroundColor3 = danger and rgb(255, 255, 255) or T.Text}, 0.15) end
        end)
        B.MouseLeave:Connect(function()
            Tween(B, {BackgroundColor3 = T.Input}, 0.15)
            Tween(BSt, {Color = T.Stroke}, 0.15)
            for _, p in ipairs(parts) do Tween(p, {BackgroundColor3 = T.SubText}, 0.15) end
        end)
        AddBounce(B)
        return B
    end

    -- // Notifications container
    local NotifContainer = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 320, 1, -20), Position = UDim2.new(1, -336, 0, 10), ZIndex = 200})
    Create("UIListLayout", {Parent = NotifContainer, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
    GlobalNotifContainer = NotifContainer

    local function SendPremiumNotification()
        Library:Notify({
            Title = "ACCESS DENIED",
            Description = 'This Is For <font color="#FFD700"><b>Whitelisted Users</b></font>',
            RichText = true, Color = GOLD, Icon = "rbxassetid://6031082533", Duration = 4
        })
    end

    -- // Modals (feature info + confirm) built on CanvasGroup so they fade cleanly
    local function MakeModal(width, height)
        local Overlay = Create("TextButton", {
            Parent = ScreenGui, Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, -InsetY), Size = UDim2.new(1, 0, 1, InsetY), ZIndex = 150, Visible = false
        })
        local Card = New("CanvasGroup", {
            Parent = Overlay, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(width, height), GroupTransparency = 1, Active = true
        }, {BackgroundColor3 = "Card"})
        Corner(Card, 12)
        New("UIStroke", {Parent = Card, Thickness = 1}, {Color = "Stroke"})
        local Sc = Create("UIScale", {Parent = Card, Scale = 0.9})
        local M = {Overlay = Overlay, Card = Card, IsOpen = false}
        function M.Open()
            M.IsOpen = true
            Overlay.Visible = true
            Tween(Overlay, {BackgroundTransparency = 0.5}, 0.25)
            Tween(Card, {GroupTransparency = 0}, 0.25)
            Tween(Sc, {Scale = 1}, 0.35, Enum.EasingStyle.Back)
        end
        function M.Close()
            M.IsOpen = false
            Tween(Overlay, {BackgroundTransparency = 1}, 0.2)
            Tween(Card, {GroupTransparency = 1}, 0.2)
            Tween(Sc, {Scale = 0.92}, 0.2)
            task.delay(0.22, function() if not M.IsOpen then Overlay.Visible = false end end)
        end
        return M
    end

    local InfoModal = MakeModal(380, 300)
    local InfoTitle = New("TextLabel", {Parent = InfoModal.Card, Text = "Feature Info", Font = Enum.Font.GothamBold, TextSize = 15, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -64, 0, 46), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
    local InfoClose = IconButton(InfoModal.Card, UDim2.new(1, -42, 0, 8), "close")
    New("Frame", {Parent = InfoModal.Card, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1)}, {BackgroundColor3 = "Stroke"})
    local InfoScroll = Create("ScrollingFrame", {Parent = InfoModal.Card, Position = UDim2.fromOffset(18, 58), Size = UDim2.new(1, -36, 1, -72), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = T.Stroke})
    ListLayout(InfoScroll, 10)
    local InfoDesc = New("TextLabel", {Parent = InfoScroll, Text = "", TextSize = 13, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, LayoutOrder = 1}, {TextColor3 = "SubText"})
    local InfoExampleBox = New("Frame", {Parent = InfoScroll, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2}, {BackgroundColor3 = "Input"})
    Corner(InfoExampleBox, 8)
    Pad(InfoExampleBox, 10, 10, 10, 10)
    local InfoExampleText = New("TextLabel", {Parent = InfoExampleBox, Text = "", Font = Enum.Font.Code, TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true}, {TextColor3 = "Accent"})

    local function OpenInfo(data)
        InfoTitle.Text = data.Title or "Information"
        InfoDesc.Text = data.Description or "No description provided."
        if data.Example then
            InfoExampleText.Text = data.Example
            InfoExampleBox.Visible = true
        else
            InfoExampleBox.Visible = false
        end
        InfoModal.Open()
    end
    InfoClose.MouseButton1Click:Connect(InfoModal.Close)
    InfoModal.Overlay.MouseButton1Click:Connect(InfoModal.Close)

    local ConfirmModal = MakeModal(340, 178)
    local CTitle = New("TextLabel", {Parent = ConfirmModal.Card, Text = "", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 22), TextXAlignment = Enum.TextXAlignment.Left}, {TextColor3 = "Text"})
    local CText = New("TextLabel", {Parent = ConfirmModal.Card, Text = "", TextSize = 13, Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -40, 0, 64), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true}, {TextColor3 = "SubText"})
    local CNo = New("TextButton", {Parent = ConfirmModal.Card, Text = "Cancel", Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(0.5, -26, 0, 36), Position = UDim2.new(0, 20, 1, -52)}, {BackgroundColor3 = "Hover", TextColor3 = "Text"})
    local CYes = Create("TextButton", {Parent = ConfirmModal.Card, Text = "Confirm", Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(0.5, -26, 0, 36), Position = UDim2.new(0.5, 6, 1, -52)})
    Corner(CNo, 8)
    Corner(CYes, 8)
    RegAccent(CYes)
    AddBounce(CNo, 0.96)
    AddBounce(CYes, 0.96)
    local confirmCallback
    local function Confirm(opts)
        opts = opts or {}
        CTitle.Text = opts.Title or "Are you sure?"
        CText.Text = opts.Text or ""
        CYes.Text = opts.ConfirmText or "Confirm"
        CNo.Text = opts.CancelText or "Cancel"
        CYes:SetAttribute("Danger", opts.Danger == true)
        AccentFill(CYes)
        confirmCallback = opts.OnConfirm
        ConfirmModal.Open()
    end
    CYes.MouseButton1Click:Connect(function()
        ConfirmModal.Close()
        local cb = confirmCallback
        confirmCallback = nil
        if cb then task.spawn(cb) end
    end)
    CNo.MouseButton1Click:Connect(function()
        confirmCallback = nil
        ConfirmModal.Close()
    end)

    local function AddInfoIcon(parent, position, data)
        if not data then return end
        local Btn = New("TextButton", {Parent = parent, Text = "?", Font = Enum.Font.GothamBold, TextSize = 10, Size = UDim2.fromOffset(16, 16), Position = position, AnchorPoint = Vector2.new(1, 0.5), ZIndex = 5}, {BackgroundColor3 = "Hover", TextColor3 = "SubText"})
        Corner(Btn, "full")
        AddBounce(Btn)
        Btn.MouseEnter:Connect(function() Tween(Btn, {TextColor3 = ContrastText(T.Accent), BackgroundColor3 = T.Accent}, 0.2) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {TextColor3 = T.SubText, BackgroundColor3 = T.Hover}, 0.2) end)
        Btn.MouseButton1Click:Connect(function() OpenInfo(data) end)
        return Btn
    end

    -- // Shell (holds window + floating drag pill, scaled as one unit)
    local Shell = Create("Frame", {Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.fromOffset(W, H), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5)})
    local ShellScale = Create("UIScale", {Parent = Shell, Scale = 0})

    local MainFrame = New("Frame", {Parent = Shell, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Active = true, BackgroundTransparency = State.WindowTransparency}, {BackgroundColor3 = "Background"})
    Corner(MainFrame, 12)
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = Color3.new(1, 1, 1), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local StrokeGrad = Create("UIGradient", {Parent = MainStroke, Rotation = 45, Color = ColorSequence.new(T.Accent, T.Stroke)})
    OnTheme(function() StrokeGrad.Color = ColorSequence.new(T.Accent, T.Stroke) end)

    -- Background layers (wallpaper gradient + custom image), sit behind everything
    local BgGrad = Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
    Corner(BgGrad, 12)
    local BgGradUI = Create("UIGradient", {Parent = BgGrad, Rotation = 35})
    local BgImage = Create("ImageLabel", {Parent = MainFrame, ScaleType = Enum.ScaleType.Crop, ImageTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
    Corner(BgImage, 12)

    -- Top bar
    local TopBar = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Active = true})
    MakeDraggable(TopBar, Shell)
    local TopLine = New("Frame", {Parent = MainFrame, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 1)}, {BackgroundColor3 = "Accent"})
    Create("UIGradient", {Parent = TopLine, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.6, 0.85), NumberSequenceKeypoint.new(1, 1)})})

    local titleOffsetX = 16
    if topbarLogo then
        Create("ImageLabel", {Parent = TopBar, Size = UDim2.fromOffset(logoSize, logoSize), Position = UDim2.new(0, 10, 0.5, -(logoSize / 2)), Image = topbarLogo, ScaleType = Enum.ScaleType.Fit})
        titleOffsetX = 10 + logoSize + 8
    end
    local TitleBlock = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1, -(titleOffsetX + (showStats and 462 or 304)), 1, 0), Position = UDim2.fromOffset(titleOffsetX, 0)})
    local Title = New("TextLabel", {Parent = TitleBlock, Text = hubName, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(0, 7), Size = UDim2.new(1, 0, 0, 17), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
    local Subtitle = Create("TextLabel", {Parent = TitleBlock, Text = subText, TextSize = 10, Position = UDim2.fromOffset(0, 25), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    if subColor then Subtitle.TextColor3 = subColor else Bind(Subtitle, "TextColor3", "Accent") end
    Window.Title = Title

    local SearchBar = New("Frame", {Parent = TopBar, Size = UDim2.fromOffset(214, 30), Position = UDim2.new(1, -298, 0.5, -15)}, {BackgroundColor3 = "Input"})
    Corner(SearchBar, 8)
    local SearchStroke = New("UIStroke", {Parent = SearchBar, Thickness = 1}, {Color = "Stroke"})
    New("ImageLabel", {Parent = SearchBar, Image = "rbxassetid://6031154871", Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 10, 0.5, -7)}, {ImageColor3 = "SubText"})
    local SearchInput = New("TextBox", {Parent = SearchBar, BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(32, 0), PlaceholderText = "Search..", TextXAlignment = Enum.TextXAlignment.Left}, {TextColor3 = "Text", PlaceholderColor3 = "SubText"})
    FocusFx(SearchInput, SearchStroke)

    local MinBtn = IconButton(TopBar, UDim2.new(1, -78, 0.5, -15), "min")
    local CloseBtn = IconButton(TopBar, UDim2.new(1, -42, 0.5, -15), "close")

    -- Sidebar
    local Sidebar = New("Frame", {Parent = MainFrame, Size = UDim2.new(0, 170, 1, -47), Position = UDim2.fromOffset(0, 47), Active = true}, {BackgroundColor3 = "Input"})
    BindPanel(Sidebar)
    local TabSearchBox = New("TextBox", {Parent = Sidebar, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 10), PlaceholderText = "Search tabs...", TextXAlignment = Enum.TextXAlignment.Left}, {BackgroundColor3 = "Card", TextColor3 = "Text", PlaceholderColor3 = "SubText"})
    Pad(TabSearchBox, 10, 0, 8, 0)
    Corner(TabSearchBox, 8)
    local TabSearchStroke = New("UIStroke", {Parent = TabSearchBox, Thickness = 1}, {Color = "Stroke"})
    FocusFx(TabSearchBox, TabSearchStroke)

    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, Size = UDim2.new(1, -16, 1, -112), Position = UDim2.fromOffset(8, 48), ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y})
    ListLayout(TabContainer, 4)

    do -- profile card (footer)
        local lp = Players.LocalPlayer
        local Card = New("Frame", {Parent = Sidebar, Size = UDim2.new(1, -16, 0, 48), Position = UDim2.new(0, 8, 1, -56)}, {BackgroundColor3 = "Card"})
        Corner(Card, 10)
        New("UIStroke", {Parent = Card, Thickness = 1, Transparency = 0.4}, {Color = "Stroke"})
        local Avatar = New("ImageLabel", {Parent = Card, Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 8, 0.5, -16), BackgroundTransparency = 0}, {BackgroundColor3 = "Hover"})
        Corner(Avatar, "full")
        New("TextLabel", {Parent = Card, Text = lp and lp.DisplayName or "Player", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.fromOffset(48, 8), Size = UDim2.new(1, -56, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
        New("TextLabel", {Parent = Card, Text = lp and ("@" .. lp.Name) or "", TextSize = 10, Position = UDim2.fromOffset(48, 25), Size = UDim2.new(1, -56, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "SubText"})
        if lp then
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and Avatar.Parent then Avatar.Image = img end
            end)
        end
    end

    New("Frame", {Parent = MainFrame, Position = UDim2.fromOffset(170, 47), Size = UDim2.new(0, 1, 1, -47)}, {BackgroundColor3 = "Stroke"})
    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -171, 1, -47), Position = UDim2.fromOffset(171, 47), Active = true})

    -- Floating drag pill below the window (child of Shell => moves/scales with it, zero polling)
    local PillHit = Create("Frame", {Parent = Shell, BackgroundTransparency = 1, Size = UDim2.fromOffset(220, 26), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 6), Active = true})
    local Pill = New("Frame", {Parent = PillHit, Size = UDim2.fromOffset(120, 5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)}, {BackgroundColor3 = "Card"})
    Corner(Pill, "full")
    New("UIStroke", {Parent = Pill, Thickness = 1.2}, {Color = "Stroke"})
    MakeDraggable(PillHit, Shell)

    -- // Floating toggle sphere (shown while minimized)
    local Sphere = New("ImageButton", {Parent = ScreenGui, Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 46, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 120}, {BackgroundColor3 = "Card"})
    Corner(Sphere, 14)
    New("UIStroke", {Parent = Sphere, Thickness = 2}, {Color = "Accent"})
    local SphereScale = Create("UIScale", {Parent = Sphere, Scale = 0})
    if sphImage and not sphTextToggle then
        Create("ImageLabel", {Parent = Sphere, Size = UDim2.fromOffset(sphIconSize, sphIconSize), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Image = sphImage})
    else
        New("TextLabel", {Parent = Sphere, Text = sphWords, Font = Enum.Font.GothamBold, TextSize = 16, Size = UDim2.fromScale(1, 1)}, {TextColor3 = "Accent"})
    end

    local visible = true
    local function FitScale()
        local cam = workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        return math.clamp(math.min((vp.X - 24) / W, (vp.Y - InsetY - 56) / H), 0.4, 1)
    end
    local function TargetScale() return FitScale() * Window.UserScale end

    local function SetVisible(v)
        if v == visible then return end
        visible = v
        if v then
            Tween(SphereScale, {Scale = 0}, 0.2)
            task.delay(0.2, function() if visible then Sphere.Visible = false end end)
            Shell.Visible = true
            Tween(ShellScale, {Scale = TargetScale()}, 0.45, Enum.EasingStyle.Back)
        else
            Tween(ShellScale, {Scale = 0}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.3, function()
                if not visible then
                    Shell.Visible = false
                    Sphere.Visible = true
                    Tween(SphereScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back)
                end
            end)
        end
    end

    local sphereMoved = false
    Sphere.InputBegan:Connect(function(input)
        if IsPress(input) then
            sphereMoved = false
            local sp, sm = Sphere.Position, input.Position
            BeginDrag(input, function(i)
                local d = i.Position - sm
                if d.Magnitude > 6 then sphereMoved = true end
                if sphereMoved then
                    Sphere.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
                end
            end)
        end
    end)
    Sphere.MouseButton1Click:Connect(function() if not sphereMoved then SetVisible(true) end end)
    MinBtn.MouseButton1Click:Connect(function() SetVisible(false) end)

    local cam = workspace.CurrentCamera
    if cam then
        Conn(cam:GetPropertyChangedSignal("ViewportSize"), function()
            if visible then Tween(ShellScale, {Scale = TargetScale()}, 0.2) end
        end)
    end
    Conn(UserInputService.InputBegan, function(input, processed)
        if not processed and input.KeyCode == toggleKey then SetVisible(not visible) end
    end)
    Tween(ShellScale, {Scale = TargetScale()}, 0.55, Enum.EasingStyle.Back)

    -- // FPS + ping boxes (same look as the search bar, between title and search)
    if showStats then
        local function StatBox(width, x)
            local Box = New("TextButton", {Parent = TopBar, Text = "", Size = UDim2.fromOffset(width, 30), Position = UDim2.new(1, x, 0.5, -15)}, {BackgroundColor3 = "Input"})
            Corner(Box, 8)
            local St = New("UIStroke", {Parent = Box, Thickness = 1}, {Color = "Stroke"})
            local Dot = New("Frame", {Parent = Box, Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0, 10, 0.5, -3)}, {BackgroundColor3 = "SubText"})
            Corner(Dot, "full")
            local Txt = New("TextLabel", {Parent = Box, Text = "--", Font = Enum.Font.GothamBold, TextSize = 11, Size = UDim2.new(1, -24, 1, 0), Position = UDim2.fromOffset(22, 0), TextXAlignment = Enum.TextXAlignment.Left}, {TextColor3 = "Text"})
            Box.MouseEnter:Connect(function() Tween(St, {Color = T.Accent}, 0.15) end)
            Box.MouseLeave:Connect(function() Tween(St, {Color = T.Stroke}, 0.15) end)
            AddBounce(Box, 0.96)
            return Dot, Txt
        end
        local FpsDot, FpsTxt = StatBox(76, -454)
        local MsDot, MsTxt = StatBox(66, -372)
        FpsTxt.Text = "-- FPS"
        MsTxt.Text = "-- ms"
        local function Rate(v, good, mid, invert)
            if invert then
                return v <= good and NotifColors.success or (v <= mid and NotifColors.warning or NotifColors.error)
            end
            return v >= good and NotifColors.success or (v >= mid and NotifColors.warning or NotifColors.error)
        end
        local frames, acc = 0, 0
        Conn(RunService.Heartbeat, function(dt)
            frames = frames + 1
            acc = acc + dt
            if acc >= 0.5 then
                local fps = math.floor(frames / acc + 0.5)
                frames, acc = 0, 0
                if visible then
                    FpsTxt.Text = fps .. " FPS"
                    FpsDot.BackgroundColor3 = Rate(fps, 50, 30, false)
                end
            end
        end)
        task.spawn(function()
            while ScreenGui.Parent do
                local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                if visible then
                    if ok and ping then
                        local ms = math.floor(ping + 0.5)
                        MsTxt.Text = ms .. " ms"
                        MsDot.BackgroundColor3 = Rate(ms, 80, 160, true)
                    else
                        MsTxt.Text = "-- ms"
                        MsDot.BackgroundColor3 = T.SubText
                    end
                end
                task.wait(1)
            end
        end)
    end

    function Window:Show() SetVisible(true) end
    function Window:Hide() SetVisible(false) end
    function Window:Toggle() SetVisible(not visible) end
    function Window:Notify(opts) Library:Notify(opts) end
    function Window:Confirm(opts) Confirm(opts) end
    function Window:Destroy()
        Tween(ShellScale, {Scale = 0}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.32, function()
            for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
            if GlobalNotifContainer == NotifContainer then GlobalNotifContainer = nil end
            ScreenGui:Destroy()
        end)
    end

    CloseBtn.MouseButton1Click:Connect(function()
        Confirm({
            Title = "Exit Application",
            Text = "Are you sure you want to close Michel Script Xne? Unsaved configurations might be lost.",
            ConfirmText = "Confirm", Danger = false,
            OnConfirm = function() Window:Destroy() end
        })
    end)

    Window.MainFrame = MainFrame
    Window.Shell = Shell
    Window.ScreenGui = ScreenGui

    -- // Appearance API (theme, wallpaper, custom image, glass, scale)
    local AppEls = {}
    local syncing = false
    local SyncAppearance = function() end

    local themePending = false
    local function RefreshTheme(animate)
        for k, v in pairs(MakeTheme(State.Accent, State.Background)) do T[k] = v end
        if animate then
            ApplyTheme(false)
        elseif not themePending then
            themePending = true
            task.defer(function()
                themePending = false
                ApplyTheme(true)
            end)
        end
        QueueSave()
    end

    function Window:SetTheme(name)
        local th = Themes[name]
        if not th then return end
        State.Theme = name
        State.Accent = th.Accent
        State.Background = th.Background
        RefreshTheme(true)
        SyncAppearance()
    end
    function Window:SetAccent(c)
        State.Accent = c
        State.Theme = "Custom"
        RefreshTheme(false)
    end
    function Window:SetBackgroundColor(c)
        State.Background = c
        State.Theme = "Custom"
        RefreshTheme(false)
    end
    function Window:SetTransparency(val)
        val = math.clamp(val, 0, 0.8)
        Window.CurrentTransparency = val
        State.WindowTransparency = val
        Tween(MainFrame, {BackgroundTransparency = val}, 0.3)
        QueueSave()
    end
    function Window:SetPanelTransparency(val)
        Panel.Transparency = math.clamp(val, 0, 0.85)
        State.PanelTransparency = Panel.Transparency
        ApplyPanel()
        QueueSave()
    end
    function Window:SetScale(v, instant)
        Window.UserScale = math.clamp(v, 0.6, 1.5)
        State.Scale = Window.UserScale
        if visible then
            if instant then ShellScale.Scale = TargetScale() else Tween(ShellScale, {Scale = TargetScale()}, 0.25) end
        end
        QueueSave()
    end
    function Window:SetSize(w, h, instant)
        W = math.clamp(math.floor(w + 0.5), MIN_W, MAX_W)
        H = math.clamp(math.floor(h + 0.5), MIN_H, MAX_H)
        State.Width, State.Height = W, H
        Shell.Size = UDim2.fromOffset(W, H)
        if visible and not instant then Tween(ShellScale, {Scale = TargetScale()}, 0.25) end
        QueueSave()
    end

    local bumped, prePanel = false, 0
    local function SeeThrough()
        if Panel.Transparency < 0.3 then
            prePanel = Panel.Transparency
            bumped = true
            Window:SetPanelTransparency(0.35)
        end
    end
    local function ApplyBgOpacity()
        if BgGrad.Visible then Tween(BgGrad, {BackgroundTransparency = 1 - State.BgOpacity}, 0.2) end
        if BgImage.Visible then Tween(BgImage, {ImageTransparency = 1 - State.BgOpacity}, 0.2) end
    end

    function Window:SetBackgroundOpacity(v)
        State.BgOpacity = math.clamp(v, 0, 1)
        ApplyBgOpacity()
        QueueSave()
    end
    function Window:ClearBackground()
        BgGrad.Visible = false
        BgImage.Visible = false
        BgImage.Image = ""
        State.Wallpaper = nil
        State.Image = nil
        if bumped then
            bumped = false
            if math.abs(Panel.Transparency - 0.35) < 0.001 then Window:SetPanelTransparency(prePanel) end
        end
        QueueSave()
        SyncAppearance()
    end
    function Window:SetWallpaper(name)
        local wp = Wallpapers[name]
        if not wp then
            Window:ClearBackground()
            return
        end
        BgImage.Visible = false
        BgImage.Image = ""
        BgGradUI.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, wp[1]), ColorSequenceKeypoint.new(0.5, wp[2]), ColorSequenceKeypoint.new(1, wp[3])
        })
        BgGrad.BackgroundTransparency = 1
        BgGrad.Visible = true
        Tween(BgGrad, {BackgroundTransparency = 1 - State.BgOpacity}, 0.5)
        State.Wallpaper = name
        State.Image = nil
        SeeThrough()
        QueueSave()
        SyncAppearance()
    end

    local function ResolveImage(src)
        src = tostring(src or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if src == "" then return nil, "Empty image source." end
        if src:match("^%d+$") then return "rbxassetid://" .. src end
        if src:match("^rbxassetid://") or src:match("^rbxasset://") or src:match("^rbxthumb://") then return src end
        if src:match("^https?://") then
            if not (_getasset and writefile) then return nil, "Image links need an executor with getcustomasset." end
            if not _isfolder(folder) then _makefolder(folder) end
            local path = folder .. "/bg_" .. Hash(src) .. ".png"
            if not _isfile(path) then
                local ok, data = pcall(function()
                    if _request then
                        local res = _request({Url = src, Method = "GET"})
                        return res and res.Body
                    end
                    return game:HttpGet(src)
                end)
                if not ok or type(data) ~= "string" or #data < 100 then return nil, "Could not download that image." end
                _writefile(path, data)
            end
            local ok2, asset = pcall(_getasset, path)
            if ok2 and asset then return asset end
            return nil, "Executor could not load the image."
        end
        return nil, "Use an Image ID or a direct image link."
    end

    function Window:SetBackgroundImage(src, silent)
        task.spawn(function()
            local asset, err = ResolveImage(src)
            if not asset then
                if not silent then Library:Notify({Title = "Background", Description = err or "Invalid image.", Type = "error"}) end
                return
            end
            BgGrad.Visible = false
            BgImage.Image = asset
            BgImage.ImageTransparency = 1
            BgImage.Visible = true
            Tween(BgImage, {ImageTransparency = 1 - State.BgOpacity}, 0.5)
            State.Image = tostring(src)
            State.Wallpaper = nil
            SeeThrough()
            QueueSave()
            SyncAppearance()
            if not silent then Library:Notify({Title = "Background", Description = "Image applied.", Type = "success"}) end
        end)
    end

    function Window:ResetAppearance()
        Window:ClearBackground()
        State.BgOpacity = 0.6
        if Themes[AppDefaults.Theme] then
            Window:SetTheme(AppDefaults.Theme)
        else
            Window:SetAccent(AppDefaults.Accent)
            Window:SetBackgroundColor(AppDefaults.Background)
        end
        Window:SetTransparency(AppDefaults.WindowTransparency)
        Window:SetPanelTransparency(AppDefaults.PanelTransparency)
        Window:SetScale(1)
        Window:SetSize(AppDefaults.Width, AppDefaults.Height)
        if AppDefaults.Image then
            Window:SetBackgroundImage(AppDefaults.Image, true)
        elseif AppDefaults.Wallpaper then
            Window:SetWallpaper(AppDefaults.Wallpaper)
        end
        SyncAppearance()
        Library:Notify({Title = "Appearance", Description = "Everything was reset to default."})
    end

    -- // Satu handle hitam di pojok kanan bawah. Arah geser menentukan fungsinya:
    -- //   kiri / kanan                     = lebar window
    -- //   atas / bawah                     = tinggi window
    -- //   miring (kanan-bawah / kiri-atas) = UI scale (zoom besar / kecil)
    local function Caps(t0)
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        return math.max(W, math.min(MAX_W, (vp.X - 24) / t0)), math.max(H, math.min(MAX_H, (vp.Y - InsetY - 56) / t0))
    end

    local Handle = Create("Frame", {Parent = Shell, BackgroundTransparency = 1, Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 18, 1, 18), Active = true, ZIndex = 5})
    local HandleOutlines = {}
    local function HandleBar(w, h)
        local o = New("Frame", {Parent = Handle, Size = UDim2.fromOffset(w + 4, h + 4), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), ZIndex = 4}, {BackgroundColor3 = "Stroke"})
        Corner(o, "full")
        table.insert(HandleOutlines, o)
        local b2 = Create("Frame", {Parent = Handle, Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 5})
        Corner(b2, "full")
    end
    HandleBar(20, 3)
    HandleBar(3, 20)
    local handleActive = false
    local function HandleHot(hot)
        for _, o in ipairs(HandleOutlines) do Tween(o, {BackgroundColor3 = hot and T.Accent or T.Stroke}, 0.15) end
    end
    Handle.MouseEnter:Connect(function() HandleHot(true) end)
    Handle.MouseLeave:Connect(function() if not handleActive then HandleHot(false) end end)
    Handle.InputBegan:Connect(function(input)
        if not IsPress(input) then return end
        handleActive = true
        HandleHot(true)
        local startMouse, startPos = input.Position, Shell.Position
        local t0 = math.max(ShellScale.Scale, 0.2)
        local fit = FitScale()
        local W0, H0 = W, H
        local capW, capH = Caps(t0)
        local mode
        BeginDrag(input, function(i)
            local d = i.Position - startMouse
            if not mode then
                local ax, ay = math.abs(d.X), math.abs(d.Y)
                if ax + ay < 10 then return end
                local r = ay / (ax + ay)
                mode = (r < 0.33) and "width" or ((r > 0.67) and "height" or "scale")
            end
            local sx, sy = 0, 0
            if mode == "width" then
                Window:SetSize(math.clamp(W0 + d.X / t0, MIN_W, capW), H0, true)
                sx, sy = (W - W0) * t0 / 2, 0
            elseif mode == "height" then
                Window:SetSize(W0, math.clamp(H0 + d.Y / t0, MIN_H, capH), true)
                sx, sy = 0, (H - H0) * t0 / 2
            else
                local proj = (d.X * W0 + d.Y * H0) / (W0 * W0 + H0 * H0)
                local user = math.clamp((t0 + proj) / fit, 0.6, 1.5)
                Window:SetScale(user, true)
                local shift = (fit * user - t0) / 2
                sx, sy = W0 * shift, H0 * shift
            end
            -- pojok kiri-atas window tetap di tempat
            Shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + sx, startPos.Y.Scale, startPos.Y.Offset + sy)
        end, function()
            handleActive = false
            HandleHot(false)
            if visible then Tween(ShellScale, {Scale = TargetScale()}, 0.25) end
            SyncAppearance()
        end)
    end)

    -- // Search (global + tabs)
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = TabSearchBox.Text:lower()
        for _, tabInfo in ipairs(Window.Tabs) do
            tabInfo.Button.Visible = (query == "" or string.find(tabInfo.Txt.Text:lower(), query, 1, true) ~= nil)
        end
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        if query == "" then
            for _, data in ipairs(Window.AllCards) do
                data.Card.Parent = data.OrigParent
                data.Card.Visible = true
            end
        else
            if not Window.CurrentTab or not Window.CurrentTab.CurrentPage then return end
            local activeLeft = Window.CurrentTab.CurrentPage.LeftCol
            local activeRight = Window.CurrentTab.CurrentPage.RightCol
            local placeLeft = true
            for _, data in ipairs(Window.AllCards) do
                local card = data.Card
                if data.Tab == Window.CurrentTab and data.Page == Window.CurrentTab.CurrentPage then
                    if not data.SearchIndex then data.SearchIndex = BuildSearchIndex(card) end
                    if string.find(data.SearchIndex, query, 1, true) then
                        card.Parent = placeLeft and activeLeft or activeRight
                        placeLeft = not placeLeft
                        card.Visible = true
                    else
                        card.Visible = false
                    end
                else
                    card.Parent = data.OrigParent
                    card.Visible = true
                end
            end
        end
    end)

    function Window:SelectTab(tab)
        if Window.CurrentTab == tab then return end
        local prev = Window.CurrentTab
        if prev then
            prev.Content.Visible = false
            prev.Style(false)
        end
        Window.CurrentTab = tab
        tab.Content.Visible = true
        tab.Content.Position = UDim2.fromOffset(0, 12)
        Tween(tab.Content, {Position = UDim2.fromOffset(0, 0)}, 0.35)
        tab.Style(true)
        if not tab.CurrentPage and tab.Pages[1] then tab:SelectPage(tab.Pages[1], true) end
    end

    -- // Tabs
    local tabOrder = 0
    local skipRegister = false

    function Window:CreateTab(tabName, isDefault, isLocked, icon)
        local isWhitelisted = false
        local player = Players.LocalPlayer
        if player then
            for _, allowedUser in ipairs(Library.WhitelistedUsers) do
                if player.Name == allowedUser or player.DisplayName == allowedUser then
                    isWhitelisted = true
                    break
                end
            end
        end
        tabOrder = tabOrder + 1

        local TabBtn = New("TextButton", {Parent = TabContainer, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = tabOrder}, {BackgroundColor3 = "Hover"})
        Corner(TabBtn, 8)
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {Parent = TabBtn, Name = "Indicator", Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = isLocked and GOLD or T.Accent})
        if not isLocked then Bind(Indicator, "BackgroundColor3", "Accent") end
        Corner(Indicator, "full")
        local textX = 14
        local IconImg
        if icon then
            IconImg = Create("ImageLabel", {Parent = TabBtn, Image = (type(icon) == "number") and ("rbxassetid://" .. icon) or tostring(icon), Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 12, 0.5, -8), ImageColor3 = T.SubText})
            textX = 36
        end
        local Txt = Create("TextLabel", {Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.SubText, Size = UDim2.new(1, -(textX + (isLocked and 26 or 8)), 1, 0), Position = UDim2.new(0, textX, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
        if isLocked then
            Create("ImageLabel", {Parent = TabBtn, Image = "rbxassetid://6031082533", ImageColor3 = GOLD, Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -22, 0.5, -7)})
        end

        local TabContent = Create("Frame", {Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
        local PageNav = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36)})
        Create("UIListLayout", {Parent = PageNav, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})
        Pad(PageNav, 12, 0, 0, 0)
        New("Frame", {Parent = TabContent, Position = UDim2.fromOffset(12, 35), Size = UDim2.new(1, -24, 0, 1), BackgroundTransparency = 0.5}, {BackgroundColor3 = "Stroke"})
        local PageContainer = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -37), Position = UDim2.fromOffset(0, 37)})

        local TabConfig = {Button = TabBtn, Content = TabContent, Indicator = Indicator, Txt = Txt, Pages = {}, CurrentPage = nil}
        table.insert(Window.Tabs, TabConfig)

        function TabConfig.Style(active, instant)
            local d = instant and 0 or 0.2
            Tween(TabBtn, {BackgroundTransparency = active and 0 or 1}, d)
            Tween(Indicator, {Size = UDim2.new(0, 3, 0, active and 18 or 0)}, d + 0.05)
            Tween(Txt, {TextColor3 = active and T.Text or T.SubText}, d)
            if IconImg then Tween(IconImg, {ImageColor3 = active and T.Accent or T.SubText}, d) end
        end
        OnTheme(function() TabConfig.Style(Window.CurrentTab == TabConfig) end)

        function TabConfig:SelectPage(page, instant)
            if TabConfig.CurrentPage == page then return end
            local cur = TabConfig.CurrentPage
            if cur then
                cur.Style(false, instant)
                cur.Scroll.Visible = false
            end
            TabConfig.CurrentPage = page
            page.Scroll.Visible = true
            page.Style(true, instant)
            if not instant then
                page.Scroll.Position = UDim2.new(0, 6, 0, 18)
                Tween(page.Scroll, {Position = UDim2.new(0, 6, 0, 4)}, 0.35)
            end
        end

        TabBtn.MouseButton1Click:Connect(function()
            if isLocked and not isWhitelisted then
                SendPremiumNotification()
                return
            end
            Window:SelectTab(TabConfig)
        end)

        function TabConfig:CreatePage(pageName)
            local PageBtn = New("TextButton", {Parent = PageNav, Text = pageName, Font = Enum.Font.GothamBold, TextSize = 13, BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = #TabConfig.Pages + 1}, {TextColor3 = "SubText"})
            Pad(PageBtn, 6, 0, 6, 0)
            local PageHighlight = New("Frame", {Parent = PageBtn, Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 1, -3), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1}, {BackgroundColor3 = "Accent"})
            Corner(PageHighlight, "full")

            local PageScroll = New("ScrollingFrame", {Parent = PageContainer, Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4), Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, {ScrollBarImageColor3 = "Stroke"})
            Pad(PageScroll, 2, 6, 8, 14)
            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
            local RightColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), Position = UDim2.new(0.5, 5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
            ListLayout(LeftColumn, 10)
            ListLayout(RightColumn, 10)

            local PageObj = {Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight, Left = true, LeftCol = LeftColumn, RightCol = RightColumn}
            table.insert(TabConfig.Pages, PageObj)

            function PageObj.Style(active, instant)
                local d = instant and 0 or 0.2
                Tween(PageBtn, {TextColor3 = active and T.Text or T.SubText}, d)
                Tween(PageHighlight, {Size = UDim2.new(active and 1 or 0, 0, 0, 2), BackgroundTransparency = active and 0 or 1}, d + 0.05)
            end
            OnTheme(function() PageObj.Style(TabConfig.CurrentPage == PageObj) end)

            PageBtn.MouseButton1Click:Connect(function() TabConfig:SelectPage(PageObj) end)

            if #TabConfig.Pages == 1 and not isLocked then
                TabConfig.CurrentPage = PageObj
                PageScroll.Visible = true
                PageObj.Style(true, true)
            end

            function PageObj:CreateSection(sectionName)
                local targetColumn = PageObj.Left and LeftColumn or RightColumn
                PageObj.Left = not PageObj.Left

                local SectionContainer = New("Frame", {Parent = targetColumn, Size = UDim2.new(1, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true}, {BackgroundColor3 = "Card"})
                BindPanel(SectionContainer)
                Corner(SectionContainer, 10)
                New("UIStroke", {Parent = SectionContainer, Thickness = 1, Transparency = 0.35}, {Color = "Stroke"})

                table.insert(Window.AllCards, {Card = SectionContainer, OrigParent = targetColumn, Tab = TabConfig, Page = PageObj, SearchIndex = nil})

                local Dot = New("Frame", {Parent = SectionContainer, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(3, 12)}, {BackgroundColor3 = "Accent"})
                Corner(Dot, "full")
                New("TextLabel", {Parent = SectionContainer, Text = sectionName, Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -34, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
                New("Frame", {Parent = SectionContainer, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5}, {BackgroundColor3 = "Stroke"})
                local ItemContainer = Create("Frame", {Parent = SectionContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 37), AutomaticSize = Enum.AutomaticSize.Y})
                Pad(ItemContainer, 12, 10, 12, 12)
                ListLayout(ItemContainer, 9)

                local Elements = {}

                local function Register(name, obj)
                    if not skipRegister then Window.ConfigElements[name] = {Set = obj.Set, Get = obj.Get} end
                    return obj
                end

                local function Label(parent, text, size, pos)
                    return New("TextLabel", {Parent = parent, Text = text, Size = size, Position = pos or UDim2.new(), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "SubText"})
                end

                function Elements:AddCopyButton(name, copyText, infoData)
                    local Btn = New("TextButton", {Parent = ItemContainer, Text = name, Size = UDim2.new(1, 0, 0, 32), TextTruncate = Enum.TextTruncate.AtEnd}, {BackgroundColor3 = "Input", TextColor3 = "Text"})
                    Corner(Btn, 8)
                    local St = New("UIStroke", {Parent = Btn, Thickness = 1}, {Color = "Stroke"})
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = T.Hover}, 0.15) Tween(St, {Color = T.Accent}, 0.15) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = T.Input}, 0.15) Tween(St, {Color = T.Stroke}, 0.15) end)
                    local busy = false
                    Btn.MouseButton1Click:Connect(function()
                        SafeCopyToClipboard(copyText)
                        if busy then return end
                        busy = true
                        local oldText = Btn.Text
                        Btn.Text = "Copied to Clipboard!"
                        Tween(Btn, {TextColor3 = T.Accent}, 0.2)
                        task.wait(1.5)
                        if Btn.Parent then
                            Btn.Text = oldText
                            Tween(Btn, {TextColor3 = T.Text}, 0.2)
                        end
                        busy = false
                    end)
                    AddInfoIcon(Btn, UDim2.new(1, -8, 0.5, 0), infoData)
                    return {Button = Btn}
                end

                function Elements:AddButton(name, callback, infoData)
                    local Btn = New("TextButton", {Parent = ItemContainer, Text = name, Size = UDim2.new(1, 0, 0, 32), TextTruncate = Enum.TextTruncate.AtEnd}, {BackgroundColor3 = "Input", TextColor3 = "Text"})
                    Corner(Btn, 8)
                    local St = New("UIStroke", {Parent = Btn, Thickness = 1}, {Color = "Stroke"})
                    Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = T.Hover}, 0.15) Tween(St, {Color = T.Accent}, 0.15) end)
                    Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = T.Input}, 0.15) Tween(St, {Color = T.Stroke}, 0.15) end)
                    Btn.MouseButton1Down:Connect(function() Tween(Btn, {BackgroundColor3 = T.Card}, 0.08) end)
                    Btn.MouseButton1Up:Connect(function() Tween(Btn, {BackgroundColor3 = T.Hover}, 0.12) end)
                    Btn.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
                    AddInfoIcon(Btn, UDim2.new(1, -8, 0.5, 0), infoData)
                    local obj = {Button = Btn}
                    function obj:SetText(t) Btn.Text = tostring(t) end
                    return obj
                end

                function Elements:AddLabel(text)
                    local L = New("TextLabel", {Parent = ItemContainer, Text = text or "", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, {TextColor3 = "SubText"})
                    local obj = {Label = L}
                    function obj:SetText(t) L.Text = tostring(t) end
                    return obj
                end

                function Elements:AddToggle(name, default, callback, infoData)
                    local state = default and true or false
                    local Row = Create("TextButton", {Parent = ItemContainer, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26)})
                    local Lbl = Create("TextLabel", {Parent = Row, Text = name, Size = UDim2.new(1, -(infoData and 84 or 56), 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = T.SubText})
                    local Lever = Create("Frame", {Parent = Row, Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = T.Stroke})
                    Corner(Lever, "full")
                    local Knob = Create("Frame", {Parent = Lever, Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1)})
                    Corner(Knob, "full")

                    local function Render(animate)
                        local d = animate and 0.25 or 0
                        Tween(Lever, {BackgroundColor3 = state and T.Accent or T.Stroke}, d)
                        Tween(Knob, {Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}, d, Enum.EasingStyle.Back)
                        Tween(Lbl, {TextColor3 = state and T.Text or T.SubText}, d)
                    end
                    Render(false)
                    OnTheme(function() Render(true) end)

                    local function internalSet(val)
                        state = val and true or false
                        Render(true)
                        if callback then task.spawn(callback, state) end
                    end
                    Row.MouseButton1Click:Connect(function() internalSet(not state) end)
                    AddInfoIcon(Row, UDim2.new(1, -48, 0.5, 0), infoData)

                    return Register(name, {Set = internalSet, Get = function() return state end})
                end

                function Elements:AddSlider(name, min, max, default, callback, infoData, step)
                    step = (step and step > 0) and step or 1
                    local decimals = 0
                    local sStr = tostring(step)
                    local dot = sStr:find("%.")
                    if dot then decimals = #sStr - dot end
                    local range = math.max(max - min, 1e-9)
                    local function Snap(v)
                        v = min + math.floor((v - min) / step + 0.5) * step
                        v = math.clamp(v, min, max)
                        return tonumber(string.format("%." .. decimals .. "f", v))
                    end
                    local function Fmt(v) return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(v) end
                    local val = Snap(default or min)

                    local Row = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44)})
                    Label(Row, name, UDim2.new(1, -90, 0, 16))
                    local ValTxt = New("TextLabel", {Parent = Row, Text = Fmt(val), Font = Enum.Font.GothamBold, Size = UDim2.fromOffset(60, 16), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextXAlignment = Enum.TextXAlignment.Right}, {TextColor3 = "Text"})
                    local Track = New("Frame", {Parent = Row, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 28)}, {BackgroundColor3 = "Input"})
                    Corner(Track, "full")
                    New("UIStroke", {Parent = Track, Thickness = 1}, {Color = "Stroke"})
                    local Fill = New("Frame", {Parent = Track, Size = UDim2.new((val - min) / range, 0, 1, 0)}, {BackgroundColor3 = "Accent"})
                    Corner(Fill, "full")
                    local Knob = Create("Frame", {Parent = Fill, Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2})
                    Corner(Knob, "full")
                    Create("UIStroke", {Parent = Knob, Color = Color3.new(0, 0, 0), Transparency = 0.7, Thickness = 1})
                    local Hit = Create("TextButton", {Parent = Row, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 18), ZIndex = 3})

                    local function Apply(v, force)
                        local nv = Snap(v)
                        local changed = nv ~= val
                        val = nv
                        ValTxt.Text = Fmt(val)
                        Tween(Fill, {Size = UDim2.new((val - min) / range, 0, 1, 0)}, 0.08)
                        if (changed or force) and callback then task.spawn(callback, val) end
                    end
                    local function Update(input)
                        local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
                        Apply(min + (max - min) * pct, false)
                    end
                    Hit.InputBegan:Connect(function(input)
                        if IsPress(input) then
                            PageObj.Scroll.ScrollingEnabled = false
                            Update(input)
                            BeginDrag(input, Update, function() PageObj.Scroll.ScrollingEnabled = true end)
                        end
                    end)
                    AddInfoIcon(Row, UDim2.new(1, -66, 0, 8), infoData)

                    return Register(name, {Set = function(v) Apply(v, true) end, Get = function() return val end})
                end

                function Elements:AddDropdown(name, options, isMulti, callback, infoData, default)
                    options = options or {}
                    local selected
                    if isMulti then
                        selected = {}
                        if type(default) == "table" then
                            for _, v in ipairs(default) do table.insert(selected, v) end
                        end
                    else
                        selected = (default ~= nil) and default or options[1]
                    end
                    local dropped = false
                    local ROW_H, MAXV = 26, 5
                    local showSearch = #options > 6
                    local listY = 56 + (showSearch and 32 or 0)
                    local optionButtons = {}

                    local DropFrame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), ClipsDescendants = true})
                    Label(DropFrame, name, UDim2.new(1, -30, 0, 16))
                    local MainBtn = New("TextButton", {Parent = DropFrame, Text = "", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 20)}, {BackgroundColor3 = "Input"})
                    Corner(MainBtn, 8)
                    local MainStroke2 = New("UIStroke", {Parent = MainBtn, Thickness = 1}, {Color = "Stroke"})
                    local Current = New("TextLabel", {Parent = MainBtn, Text = "", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -38, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
                    local Chev = Create("Frame", {Parent = MainBtn, BackgroundTransparency = 1, Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -22, 0.5, -6)})
                    for _, d in ipairs({{-2.5, 45}, {2.5, -45}}) do
                        local bar = Create("Frame", {Parent = Chev, Size = UDim2.fromOffset(7, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, d[1], 0.5, 0), Rotation = d[2]})
                        Bind(bar, "BackgroundColor3", "SubText")
                        Corner(bar, "full")
                    end
                    MainBtn.MouseEnter:Connect(function() Tween(MainStroke2, {Color = T.Accent}, 0.15) end)
                    MainBtn.MouseLeave:Connect(function() Tween(MainStroke2, {Color = T.Stroke}, 0.15) end)

                    local SearchBox
                    if showSearch then
                        SearchBox = New("TextBox", {Parent = DropFrame, PlaceholderText = "Search...", Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 56), TextXAlignment = Enum.TextXAlignment.Left}, {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText"})
                        Pad(SearchBox, 10, 0, 8, 0)
                        Corner(SearchBox, 8)
                        local sst = New("UIStroke", {Parent = SearchBox, Thickness = 1}, {Color = "Stroke"})
                        FocusFx(SearchBox, sst)
                    end
                    local ListFrame = New("ScrollingFrame", {Parent = DropFrame, BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, ROW_H), Position = UDim2.fromOffset(0, listY), AutomaticCanvasSize = Enum.AutomaticSize.Y}, {BackgroundColor3 = "Input", ScrollBarImageColor3 = "Stroke"})
                    Corner(ListFrame, 8)
                    ListLayout(ListFrame, 0)

                    local function ListHeight()
                        local n = 0
                        for _, ob in ipairs(optionButtons) do
                            if ob.Btn.Visible then n = n + 1 end
                        end
                        return math.max(math.min(n, MAXV), 1) * ROW_H
                    end
                    local function OpenSize()
                        local h = ListHeight()
                        ListFrame.Size = UDim2.new(1, 0, 0, h)
                        Tween(DropFrame, {Size = UDim2.new(1, 0, 0, listY + h + 2)}, 0.2)
                    end
                    local function SetDropped(v)
                        dropped = v
                        Tween(Chev, {Rotation = v and 180 or 0}, 0.25)
                        if v then
                            if SearchBox then SearchBox.Text = "" end
                            OpenSize()
                        else
                            Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 52)}, 0.2)
                        end
                    end
                    MainBtn.MouseButton1Click:Connect(function() SetDropped(not dropped) end)

                    local function IsSelected(opt)
                        if isMulti then return table.find(selected, opt) ~= nil end
                        return selected == opt
                    end
                    local function Restyle(animate)
                        local d = animate and 0.18 or 0
                        for _, ob in ipairs(optionButtons) do
                            local sel = IsSelected(ob.Opt)
                            Tween(ob.Btn, {TextColor3 = sel and T.Text or T.SubText}, d)
                            Tween(ob.Mark, {BackgroundTransparency = sel and 0 or 1}, d)
                        end
                    end
                    local function UpdateText()
                        if isMulti then
                            Current.Text = (#selected == 0) and "Select Options..." or table.concat(selected, ", ")
                        else
                            Current.Text = (selected ~= nil and selected ~= "") and tostring(selected) or "Select..."
                        end
                    end
                    OnTheme(function() Restyle(true) end)

                    local function Build()
                        for _, ob in ipairs(optionButtons) do ob.Btn:Destroy() end
                        optionButtons = {}
                        for _, opt in ipairs(options) do
                            local OptBtn = New("TextButton", {Parent = ListFrame, Text = tostring(opt), Size = UDim2.new(1, 0, 0, ROW_H), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left}, {BackgroundColor3 = "Hover", TextColor3 = "SubText"})
                            Pad(OptBtn, 14, 0, 6, 0)
                            local Mark = New("Frame", {Parent = OptBtn, Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, -9, 0.5, -7), BackgroundTransparency = 1}, {BackgroundColor3 = "Accent"})
                            Corner(Mark, "full")
                            table.insert(optionButtons, {Btn = OptBtn, Opt = opt, Mark = Mark})
                            OptBtn.MouseEnter:Connect(function() Tween(OptBtn, {BackgroundTransparency = 0.6}, 0.12) end)
                            OptBtn.MouseLeave:Connect(function() Tween(OptBtn, {BackgroundTransparency = 1}, 0.12) end)
                            OptBtn.MouseButton1Click:Connect(function()
                                if isMulti then
                                    local idx = table.find(selected, opt)
                                    if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                                else
                                    selected = opt
                                    SetDropped(false)
                                end
                                UpdateText()
                                Restyle(true)
                                if callback then task.spawn(callback, selected) end
                            end)
                        end
                        Restyle(false)
                    end
                    Build()
                    UpdateText()

                    if SearchBox then
                        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                            local q = SearchBox.Text:lower()
                            for _, ob in ipairs(optionButtons) do
                                ob.Btn.Visible = (q == "" or string.find(tostring(ob.Opt):lower(), q, 1, true) ~= nil)
                            end
                            if dropped then OpenSize() end
                        end)
                    end
                    AddInfoIcon(DropFrame, UDim2.new(1, 0, 0, 8), infoData)

                    local function internalSet(v)
                        if isMulti then
                            selected = {}
                            if type(v) == "table" then
                                for _, x in ipairs(v) do table.insert(selected, x) end
                            end
                        else
                            selected = v
                        end
                        UpdateText()
                        Restyle(true)
                        if callback then task.spawn(callback, selected) end
                    end

                    local obj = {Set = internalSet, Get = function() return selected end}
                    function obj.Refresh(newOptions)
                        options = newOptions or {}
                        if not isMulti and table.find(options, selected) == nil then selected = options[1] end
                        Build()
                        UpdateText()
                        if dropped then OpenSize() end
                    end
                    return Register(name, obj)
                end

                function Elements:AddTextbox(name, placeholder, callback, infoData)
                    local Row = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52)})
                    Label(Row, name, UDim2.new(1, -30, 0, 16))
                    local Input = New("TextBox", {Parent = Row, PlaceholderText = placeholder or "Type here...", Text = "", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 20), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText"})
                    Pad(Input, 10, 0, 10, 0)
                    Corner(Input, 8)
                    local St = New("UIStroke", {Parent = Input, Thickness = 1}, {Color = "Stroke"})
                    FocusFx(Input, St)

                    local function internalSet(v)
                        Input.Text = tostring(v)
                        if callback then task.spawn(callback, Input.Text) end
                    end
                    Input.FocusLost:Connect(function() if callback then task.spawn(callback, Input.Text) end end)
                    AddInfoIcon(Row, UDim2.new(1, 0, 0, 8), infoData)

                    local obj = {Set = internalSet, Get = function() return Input.Text end, Box = Input}
                    return Register(name, obj)
                end

                function Elements:AddColorPicker(name, defaultColor, callback, infoData)
                    local color = defaultColor or Color3.fromRGB(255, 255, 255)
                    local h, s, v = color:ToHSV()
                    local dropped = false

                    local Frame = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ClipsDescendants = true})
                    Label(Frame, name, UDim2.new(1, -90, 0, 30))
                    local Swatch = Create("TextButton", {Parent = Frame, Text = "", BackgroundColor3 = color, Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, 0, 0, 5), AnchorPoint = Vector2.new(1, 0)})
                    Corner(Swatch, 6)
                    New("UIStroke", {Parent = Swatch, Thickness = 1}, {Color = "Stroke"})

                    local Area = New("Frame", {Parent = Frame, Size = UDim2.new(1, 0, 0, 160), Position = UDim2.fromOffset(0, 36)}, {BackgroundColor3 = "Input"})
                    Corner(Area, 8)
                    local SVMap = Create("Frame", {Parent = Area, BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.new(1, -16, 0, 90), Position = UDim2.fromOffset(8, 8)})
                    Corner(SVMap, 6)
                    local White = Create("Frame", {Parent = SVMap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2})
                    Create("UIGradient", {Parent = White, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})})
                    Corner(White, 6)
                    local Black = Create("Frame", {Parent = SVMap, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 3})
                    Create("UIGradient", {Parent = Black, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})})
                    Corner(Black, 6)
                    local SVHit = Create("TextButton", {Parent = SVMap, Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5})
                    local SVRing = Create("Frame", {Parent = SVMap, Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6})
                    Corner(SVRing, "full")
                    Create("UIStroke", {Parent = SVRing, Color = Color3.new(0, 0, 0), Thickness = 1.5})

                    local HueBar = Create("TextButton", {Parent = Area, Text = "", Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 106), BackgroundColor3 = Color3.new(1, 1, 1)})
                    Corner(HueBar, 7)
                    Create("UIGradient", {Parent = HueBar, Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                    })})
                    local HueRing = Create("Frame", {Parent = HueBar, Size = UDim2.fromOffset(6, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1)})
                    Corner(HueRing, 3)
                    Create("UIStroke", {Parent = HueRing, Color = Color3.new(0, 0, 0), Thickness = 1.5})

                    local Hex = New("TextBox", {Parent = Area, Text = "", Font = Enum.Font.Code, Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 128)}, {BackgroundColor3 = "Card", TextColor3 = "Text"})
                    Corner(Hex, 6)
                    local HexStroke = New("UIStroke", {Parent = Hex, Thickness = 1}, {Color = "Stroke"})
                    FocusFx(Hex, HexStroke)

                    local function Refresh(fire)
                        color = Color3.fromHSV(h, s, v)
                        Swatch.BackgroundColor3 = color
                        SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        SVRing.Position = UDim2.fromScale(s, 1 - v)
                        HueRing.Position = UDim2.new(h, 0, 0.5, 0)
                        Hex.Text = "#" .. color:ToHex():upper()
                        if fire and callback then task.spawn(callback, color) end
                    end
                    Refresh(false)

                    local function internalSet(val)
                        local c
                        if typeof(val) == "Color3" then
                            c = val
                        else
                            local ok, r = pcall(Color3.fromHex, tostring(val))
                            if ok then c = r end
                        end
                        if c then
                            h, s, v = c:ToHSV()
                            Refresh(true)
                        end
                    end
                    Hex.FocusLost:Connect(function() internalSet(Hex.Text) end)

                    local function DragSV(input)
                        s = math.clamp((input.Position.X - SVMap.AbsolutePosition.X) / math.max(SVMap.AbsoluteSize.X, 1), 0, 1)
                        v = 1 - math.clamp((input.Position.Y - SVMap.AbsolutePosition.Y) / math.max(SVMap.AbsoluteSize.Y, 1), 0, 1)
                        Refresh(true)
                    end
                    local function DragHue(input)
                        h = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / math.max(HueBar.AbsoluteSize.X, 1), 0, 1)
                        Refresh(true)
                    end
                    local function StartDrag(input, fn)
                        PageObj.Scroll.ScrollingEnabled = false
                        fn(input)
                        BeginDrag(input, fn, function() PageObj.Scroll.ScrollingEnabled = true end)
                    end
                    SVHit.InputBegan:Connect(function(input) if IsPress(input) then StartDrag(input, DragSV) end end)
                    HueBar.InputBegan:Connect(function(input) if IsPress(input) then StartDrag(input, DragHue) end end)

                    Swatch.MouseButton1Click:Connect(function()
                        dropped = not dropped
                        Tween(Frame, {Size = UDim2.new(1, 0, 0, dropped and 202 or 30)}, 0.25)
                    end)
                    AddInfoIcon(Frame, UDim2.new(1, -48, 0, 15), infoData)

                    return Register(name, {Set = internalSet, Get = function() return color:ToHex() end})
                end

                function Elements:AddKeybind(name, default, callback, infoData, onChange)
                    local key = default
                    local listening = false
                    local Row = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28)})
                    Label(Row, name, UDim2.new(1, -(infoData and 124 or 96), 1, 0))
                    local Btn = New("TextButton", {Parent = Row, Text = key and key.Name or "None", Font = Enum.Font.GothamBold, TextSize = 11, Size = UDim2.fromOffset(86, 24), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), TextTruncate = Enum.TextTruncate.AtEnd}, {BackgroundColor3 = "Input", TextColor3 = "Text"})
                    Corner(Btn, 6)
                    local St = New("UIStroke", {Parent = Btn, Thickness = 1}, {Color = "Stroke"})
                    Btn.MouseButton1Click:Connect(function()
                        listening = true
                        Btn.Text = "..."
                        Tween(St, {Color = T.Accent}, 0.15)
                    end)
                    Conn(UserInputService.InputBegan, function(input, gp)
                        if listening then
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                listening = false
                                key = (input.KeyCode ~= Enum.KeyCode.Escape) and input.KeyCode or nil
                                Btn.Text = key and key.Name or "None"
                                Tween(St, {Color = T.Stroke}, 0.15)
                                if onChange then task.spawn(onChange, key) end
                            end
                        elseif key and not gp and input.KeyCode == key then
                            if callback then task.spawn(callback, key) end
                        end
                    end)
                    AddInfoIcon(Row, UDim2.new(1, -96, 0.5, 0), infoData)

                    local function internalSet(v)
                        if typeof(v) == "EnumItem" then
                            key = v
                        else
                            local ok, kc = pcall(function() return Enum.KeyCode[tostring(v)] end)
                            key = ok and kc or nil
                        end
                        Btn.Text = key and key.Name or "None"
                    end
                    return Register(name, {Set = internalSet, Get = function() return key and key.Name or "None" end})
                end

                function Elements:AddConfigManager(folderName)
                    folderName = folderName or (Window.Folder .. "/configs")
                    if not _isfolder(Window.Folder) then _makefolder(Window.Folder) end
                    if not _isfolder(folderName) then _makefolder(folderName) end

                    local Wrap = Create("Frame", {Parent = ItemContainer, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
                    ListLayout(Wrap, 8)

                    local Search = New("TextBox", {Parent = Wrap, PlaceholderText = "Search saves...", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1}, {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText"})
                    Pad(Search, 10, 0, 8, 0)
                    Corner(Search, 8)
                    FocusFx(Search, New("UIStroke", {Parent = Search, Thickness = 1}, {Color = "Stroke"}))

                    local Monitor = New("ScrollingFrame", {Parent = Wrap, BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 120), AutomaticCanvasSize = Enum.AutomaticSize.Y, LayoutOrder = 2}, {BackgroundColor3 = "Input", ScrollBarImageColor3 = "Stroke"})
                    Corner(Monitor, 8)
                    Pad(Monitor, 5, 5, 5, 5)
                    ListLayout(Monitor, 4)
                    local Empty = New("TextLabel", {Parent = Monitor, Text = "No saves yet.", TextSize = 11, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 0}, {TextColor3 = "SubText"})

                    local NameBox = New("TextBox", {Parent = Wrap, PlaceholderText = "Enter save name...", Size = UDim2.new(1, 0, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 3}, {BackgroundColor3 = "Input", TextColor3 = "Text", PlaceholderColor3 = "SubText"})
                    Pad(NameBox, 10, 0, 8, 0)
                    Corner(NameBox, 8)
                    FocusFx(NameBox, New("UIStroke", {Parent = NameBox, Thickness = 1}, {Color = "Stroke"}))

                    local BtnRow = Create("Frame", {Parent = Wrap, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 4})
                    local PrimaryBtn = Create("TextButton", {Parent = BtnRow, Text = "Create Save", Font = Enum.Font.GothamBold, Size = UDim2.new(0.5, -4, 1, 0)})
                    Corner(PrimaryBtn, 8)
                    RegAccent(PrimaryBtn)
                    AddBounce(PrimaryBtn, 0.96)
                    local SecondaryBtn = New("TextButton", {Parent = BtnRow, Text = "Refresh", Font = Enum.Font.GothamBold, Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0)}, {BackgroundColor3 = "Hover", TextColor3 = "Text"})
                    Corner(SecondaryBtn, 8)
                    AddBounce(SecondaryBtn, 0.96)

                    local editTarget
                    local Refresh

                    local function SetEditing(path, displayName)
                        editTarget = path
                        PrimaryBtn.Text = path and "Save Edit" or "Create Save"
                        SecondaryBtn.Text = path and "Cancel" or "Refresh"
                        NameBox.Text = path and displayName or ""
                    end

                    local function Clean(n)
                        n = tostring(n):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                        return n
                    end

                    local function ExecuteSave(saveName)
                        local payload = {}
                        for k, el in pairs(Window.ConfigElements) do
                            if el.Get then payload[k] = el.Get() end
                        end
                        local finalPath = folderName .. "/" .. saveName .. "_" .. tostring(math.floor(tick())) .. ".json"
                        _writefile(finalPath, HttpService:JSONEncode(payload))
                        Refresh()
                        Library:Notify({Title = "Saved Successfully", Description = "Config [" .. saveName .. "] secured.", Type = "success"})
                    end

                    function Refresh()
                        for _, c in ipairs(Monitor:GetChildren()) do
                            if c:IsA("Frame") then c:Destroy() end
                        end
                        local count = 0
                        local okList, files = pcall(_listfiles, folderName)
                        for _, filepath in ipairs(okList and files or {}) do
                            local rawName = filepath:match("([^/\\]+)%.json$")
                            if rawName then
                                count = count + 1
                                local displayName = (rawName:gsub("_%d+%.%d+$", ""):gsub("_%d+$", ""))
                                local Row = New("Frame", {Parent = Monitor, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = count}, {BackgroundColor3 = "Card"})
                                Corner(Row, 6)
                                New("TextLabel", {Parent = Row, Text = displayName, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -118, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})

                                local function RowBtn(text, x, w, color)
                                    local b = Create("TextButton", {Parent = Row, Text = text, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = color, Size = UDim2.fromOffset(w, 20), Position = UDim2.new(1, x, 0.5, -10)})
                                    Corner(b, 5)
                                    AddBounce(b, 0.92)
                                    return b
                                end
                                local LoadBtn = RowBtn("Load", -108, 38, rgb(48, 130, 80))
                                local EditBtn = RowBtn("Edit", -66, 34, rgb(160, 110, 50))
                                local DelBtn = RowBtn("Del", -28, 24, rgb(190, 60, 70))

                                LoadBtn.MouseButton1Click:Connect(function()
                                    local ok, data = pcall(function() return HttpService:JSONDecode(_readfile(filepath)) end)
                                    if ok and type(data) == "table" then
                                        for k, val in pairs(data) do
                                            local el = Window.ConfigElements[k]
                                            if el and el.Set then pcall(el.Set, val) end
                                        end
                                        Library:Notify({Title = "Saves Loader", Description = "Successfully loaded " .. displayName, Type = "success"})
                                    else
                                        Library:Notify({Title = "Saves Loader", Description = "Could not read " .. displayName, Type = "error"})
                                    end
                                end)
                                EditBtn.MouseButton1Click:Connect(function() SetEditing(filepath, displayName) end)
                                DelBtn.MouseButton1Click:Connect(function()
                                    Confirm({
                                        Title = "Delete save?",
                                        Text = "\"" .. displayName .. "\" will be permanently erased.",
                                        ConfirmText = "Delete", Danger = true,
                                        OnConfirm = function()
                                            pcall(_delfile, filepath)
                                            if editTarget == filepath then SetEditing(nil) end
                                            Refresh()
                                            Library:Notify({Title = "Deleted", Description = displayName .. " was erased.", Type = "warning"})
                                        end
                                    })
                                end)
                            end
                        end
                        Empty.Visible = (count == 0)
                    end

                    PrimaryBtn.MouseButton1Click:Connect(function()
                        local name = Clean(NameBox.Text)
                        if name == "" then
                            Library:Notify({Title = "Saves Loader", Description = "Type a save name first.", Type = "warning"})
                            return
                        end
                        if editTarget then
                            -- rename: keep the file's content, only change its name
                            local ok, content = pcall(_readfile, editTarget)
                            if ok and content then
                                _writefile(folderName .. "/" .. name .. "_" .. tostring(math.floor(tick())) .. ".json", content)
                                pcall(_delfile, editTarget)
                            end
                            SetEditing(nil)
                            Refresh()
                        else
                            ExecuteSave(name)
                            NameBox.Text = ""
                        end
                    end)
                    SecondaryBtn.MouseButton1Click:Connect(function()
                        if editTarget then SetEditing(nil) else Refresh() end
                    end)
                    Search:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = Search.Text:lower()
                        for _, c in ipairs(Monitor:GetChildren()) do
                            local lbl = c:IsA("Frame") and c:FindFirstChildOfClass("TextLabel")
                            if lbl then c.Visible = (q == "" or string.find(lbl.Text:lower(), q, 1, true) ~= nil) end
                        end
                    end)
                    Refresh()
                    return {Refresh = Refresh}
                end

                -- // Appearance controls (theme / background / interface). Not part of config saves:
                -- // appearance has its own auto-save file.
                local function Near(a, b)
                    return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.03
                end
                local function MatchBackground()
                    for name, c in pairs(BackgroundPresets) do
                        if Near(c, State.Background) then return name end
                    end
                    return "Custom"
                end
                local function Opts(order)
                    local o = {}
                    for _, n in ipairs(order) do table.insert(o, n) end
                    return o
                end

                function Elements:AddThemeControls()
                    skipRegister = true
                    local themeOpts = Opts(ThemeOrder)
                    table.insert(themeOpts, "Custom")
                    AppEls.Theme = Elements:AddDropdown("Theme Preset", themeOpts, false, function(n)
                        if Themes[n] and State.Theme ~= n then Window:SetTheme(n) end
                    end, {Title = "Theme Preset", Description = "Pick a ready-made color scheme. Accent and background update everywhere instantly."}, State.Theme)
                    AppEls.Accent = Elements:AddColorPicker("Accent Color", State.Accent, function(c)
                        if not Near(c, State.Accent) then Window:SetAccent(c) end
                    end)
                    local bgOpts = Opts(BackgroundOrder)
                    table.insert(bgOpts, "Custom")
                    AppEls.BgPreset = Elements:AddDropdown("Window Color", bgOpts, false, function(n)
                        local c = BackgroundPresets[n]
                        if c and not Near(c, State.Background) then Window:SetBackgroundColor(c) end
                    end, {Title = "Window Color", Description = "The base color of the window. Cards, sidebar and inputs are derived from it automatically."}, MatchBackground())
                    AppEls.BgPicker = Elements:AddColorPicker("Custom Window Color", State.Background, function(c)
                        if not Near(c, State.Background) then Window:SetBackgroundColor(c) end
                    end)
                    skipRegister = false
                end

                function Elements:AddBackgroundControls()
                    skipRegister = true
                    local imageText = State.Image or ""
                    AppEls.Wallpaper = Elements:AddDropdown("Wallpaper", Opts(WallpaperOrder), false, function(n)
                        if n == "None" then
                            if State.Wallpaper ~= nil then Window:ClearBackground() end
                        elseif State.Wallpaper ~= n then
                            Window:SetWallpaper(n)
                        end
                    end, {Title = "Wallpaper", Description = "Gradient wallpapers drawn behind the whole window. Panels turn slightly see-through so it shows."}, State.Wallpaper or "None")
                    AppEls.ImageBox = Elements:AddTextbox("Custom Image", "rbxassetid://123456 / angka ID / link", function(t) imageText = t end, {
                        Title = "Custom Image Background",
                        Description = "Paste a Roblox image ID (decal/image asset) or a direct image link (.png / .jpg). Links need an executor that supports getcustomasset and writefile.",
                        Example = "rbxassetid://1234567890\nhttps://example.com/wallpaper.png"
                    })
                    Elements:AddButton("Apply Image", function()
                        if imageText == "" then imageText = AppEls.ImageBox.Get() end
                        Window:SetBackgroundImage(imageText)
                    end)
                    Elements:AddButton("Clear Background", function()
                        Window:ClearBackground()
                        Library:Notify({Title = "Background", Description = "Background cleared."})
                    end)
                    AppEls.BgOpacity = Elements:AddSlider("Background Strength", 0, 100, math.floor(State.BgOpacity * 100 + 0.5), function(v)
                        if math.abs(State.BgOpacity - v / 100) > 0.004 then Window:SetBackgroundOpacity(v / 100) end
                    end, nil, 5)
                    skipRegister = false
                end

                function Elements:AddInterfaceControls()
                    skipRegister = true
                    AppEls.Width = Elements:AddSlider("Window Width", MIN_W, MAX_W, W, function(v)
                        if math.abs(W - v) > 5 then Window:SetSize(v, H) end
                    end, {Title = "Window Size", Description = "Stretch the window wider or narrower. You can also hold the black bracket at the bottom-right corner and drag left/right (width) or up/down (height)."}, 10)
                    AppEls.Height = Elements:AddSlider("Window Height", MIN_H, MAX_H, H, function(v)
                        if math.abs(H - v) > 5 then Window:SetSize(W, v) end
                    end, nil, 10)
                    AppEls.WinT = Elements:AddSlider("Window Transparency", 0, 80, math.floor(State.WindowTransparency * 100 + 0.5), function(v)
                        if math.abs(State.WindowTransparency - v / 100) > 0.004 then Window:SetTransparency(v / 100) end
                    end, nil, 5)
                    AppEls.PanelT = Elements:AddSlider("Panel Transparency", 0, 85, math.floor(State.PanelTransparency * 100 + 0.5), function(v)
                        if math.abs(State.PanelTransparency - v / 100) > 0.004 then Window:SetPanelTransparency(v / 100) end
                    end, nil, 5)
                    AppEls.Scale = Elements:AddSlider("UI Scale (%)", 60, 150, math.floor(State.Scale * 100 + 0.5), function(v)
                        if math.abs(State.Scale - v / 100) > 0.004 then Window:SetScale(v / 100) end
                    end, {Title = "UI Scale", Description = "Resize the whole window. Zooms the whole UI bigger or smaller. You can also hold the black bracket at the bottom-right corner and drag diagonally. It auto-shrinks on small phone screens."}, 5)
                    Elements:AddKeybind("Menu Key", toggleKey, nil, {Title = "Menu Key", Description = "Press this key to hide or show the window. Press Escape while binding to keep the current key."}, function(k)
                        if k then toggleKey = k end
                    end)
                    Elements:AddButton("Reset Appearance", function()
                        Confirm({
                            Title = "Reset appearance?",
                            Text = "Theme, background, transparency and scale go back to default.",
                            ConfirmText = "Reset", Danger = true,
                            OnConfirm = function() Window:ResetAppearance() end
                        })
                    end)
                    skipRegister = false
                end

                SyncAppearance = function()
                    local function S(el, v) if el then el.Set(v) end end
                    S(AppEls.Theme, State.Theme)
                    S(AppEls.Accent, State.Accent)
                    S(AppEls.BgPreset, MatchBackground())
                    S(AppEls.BgPicker, State.Background)
                    S(AppEls.Wallpaper, State.Wallpaper or "None")
                    S(AppEls.BgOpacity, math.floor(State.BgOpacity * 100 + 0.5))
                    S(AppEls.WinT, math.floor(State.WindowTransparency * 100 + 0.5))
                    S(AppEls.PanelT, math.floor(State.PanelTransparency * 100 + 0.5))
                    S(AppEls.Scale, math.floor(State.Scale * 100 + 0.5))
                    S(AppEls.Width, W)
                    S(AppEls.Height, H)
                end

                return Elements
            end
            return PageObj
        end

        if isDefault then
            TabConfig.Style(true, true)
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end

    -- // One-call appearance tab: theme, background changer, interface settings
    function Window:CreateAppearanceTab(tabName, isDefault)
        local tab = Window:CreateTab(tabName or "Appearance", isDefault, false)
        local page = tab:CreatePage("Look")
        local themeSec = page:CreateSection("Theme")
        themeSec:AddThemeControls()
        local bgSec = page:CreateSection("Background")
        bgSec:AddBackgroundControls()
        local uiSec = page:CreateSection("Interface")
        uiSec:AddInterfaceControls()
        return tab
    end

    -- // Restore saved background on startup
    if State.Wallpaper then
        Window:SetWallpaper(State.Wallpaper)
    elseif State.Image then
        Window:SetBackgroundImage(State.Image, true)
    end

    return Window
end

return Library
