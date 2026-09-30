--[[
    MICHEL UI LIBRARY  v1.0.0
    Dark glass UI (Neverlose x WindUI style) for Roblox executors, mobile-first.

    Load:
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/MichelUI.lua"))()

    Hierarchy:
        Library:CreateWindow(cfg)
            Window:CreateCategory(name)
            Window:CreateTab(name, icon)
                Tab:CreateSection(name, side)   -- side: 1 / "Left" or 2 / "Right"
                    Section:AddToggle / AddSlider / AddDropdown / AddButton
                    Section:AddTextbox / AddLabel / AddColorPicker / AddKeybind
        Library:Notify(cfg)
        Library:CreateToggleButton(iconAssetId)

    Full example at the bottom of this file.
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local env = (getgenv and getgenv()) or _G
if env.MichelUILib and type(env.MichelUILib.Destroy) == "function" then
    pcall(function() env.MichelUILib:Destroy() end)
end

local Library = {
    Version = "1.0.0",
    Flags = {},
    _connections = {},
    Theme = {
        Background = Color3.fromRGB(11, 11, 17),
        Sidebar    = Color3.fromRGB(14, 14, 21),
        Section    = Color3.fromRGB(21, 21, 30),
        Element    = Color3.fromRGB(30, 30, 42),
        Stroke     = Color3.fromRGB(58, 58, 78),
        Accent     = Color3.fromRGB(0, 162, 255),
        Text       = Color3.fromRGB(232, 232, 242),
        SubText    = Color3.fromRGB(140, 140, 162),
        Off        = Color3.fromRGB(52, 52, 68),
    },
}
Library.__index = Library
env.MichelUILib = Library

local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

-- ============================================================ helpers

local function New(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function Tween(inst, time, props, style)
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library._connections, c)
    return c
end

local function Fire(cb, ...)
    if type(cb) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(cb, table.unpack(args, 1, args.n))
        if not ok then warn("[MichelUI] callback error: " .. tostring(err)) end
    end)
end

local function Corner(inst, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = inst})
end

local function Stroke(inst, color, transparency, thickness)
    return New("UIStroke", {
        Color = color or Library.Theme.Stroke,
        Transparency = transparency or 0.5,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

local function Pad(inst, t, r, b, l)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0),
        Parent = inst,
    })
end

local function Text(parent, props)
    local d = {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = Library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
    }
    for k, v in pairs(props) do d[k] = v end
    d.Parent = parent
    return New("TextLabel", d)
end

local function Asset(id)
    if id == nil or id == "" then return "" end
    if type(id) == "number" or tostring(id):match("^%d+$") then return "rbxassetid://" .. tostring(id) end
    return tostring(id)
end

local function Round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(n * m + 0.5) / m
end

local function IsPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function MakeDraggable(handle, target, getScale)
    local dragging, dragStart, startPos = false, nil, nil
    Connect(handle.InputBegan, function(input)
        if IsPointer(input) then
            dragging, dragStart, startPos = true, input.Position, target.Position
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    c:Disconnect()
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and IsMove(input) then
            local s = (getScale and getScale()) or 1
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s, startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
        end
    end)
end

local function GetGuiParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    local probe = Instance.new("ScreenGui")
    local okp = pcall(function() probe.Parent = CoreGui end)
    probe:Destroy()
    if okp then return CoreGui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Library:_GetGui()
    if self._gui and self._gui.Parent then return self._gui end
    local gui = Instance.new("ScreenGui")
    gui.Name = "MichelUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false -- keeps input.Position aligned with AbsolutePosition
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = GetGuiParent()
    self._gui = gui
    return gui
end

function Library:Destroy()
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    self._connections = {}
    if self._gui then self._gui:Destroy() end
    self._gui, self._window, self._toggleButton = nil, nil, nil
end

-- ============================================================ notifications

function Library:Notify(cfg)
    if type(cfg) ~= "table" then cfg = {Content = tostring(cfg)} end
    local T = self.Theme
    local gui = self:_GetGui()
    local holder = gui:FindFirstChild("Notifications")
    if not holder then
        holder = New("Frame", {
            Name = "Notifications", BackgroundTransparency = 1, ZIndex = 100,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.new(0, 230, 1, -20), Parent = gui,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = holder,
        })
    end

    local duration = cfg.Duration or 4
    local hasIcon = cfg.Icon ~= nil and cfg.Icon ~= ""

    local wrapper = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = holder,
    })
    local toast = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1.3, 0, 0, 0), BackgroundColor3 = T.Background,
        BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true, Parent = wrapper,
    })
    Corner(toast, 8)
    Stroke(toast, T.Stroke, 0.4)

    local body = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = toast,
    })
    Pad(body, 8, 10, 11, hasIcon and 40 or 10)
    New("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body})

    Text(body, {
        Size = UDim2.new(1, 0, 0, 16), Text = cfg.Title or "Notification",
        Font = Enum.Font.GothamBold, TextSize = 13, LayoutOrder = 1,
    })
    if cfg.Content and cfg.Content ~= "" then
        Text(body, {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Text = cfg.Content, TextColor3 = T.SubText, TextSize = 12,
            TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
        })
    end
    if hasIcon then
        New("ImageLabel", {
            BackgroundTransparency = 1, Image = Asset(cfg.Icon), ImageColor3 = T.Accent,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(20, 20), Parent = toast,
        })
    end
    local bar = New("Frame", {
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 2,
        Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), Parent = toast,
    })

    Tween(toast, 0.35, {Position = UDim2.new(0, 0, 0, 0)})
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    task.delay(duration, function()
        if not toast.Parent then return end
        Tween(toast, 0.3, {Position = UDim2.new(1.3, 0, 0, 0)})
        task.wait(0.3)
        wrapper:Destroy()
    end)
end

-- ============================================================ window

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local T = self.Theme
    local gui = self:_GetGui()
    local size = cfg.Size or UDim2.fromOffset(500, 340)

    local window = setmetatable({}, Window)
    window.Gui = gui
    window.Tabs = {}
    window.Visible = true
    window._userScale = cfg.Scale or 1
    window._autoScale = 1
    window._order = 0
    window._size = size

    local function computeAuto()
        if cfg.AutoScale == false then return 1 end
        local a = gui.AbsoluteSize
        if a.X <= 0 or a.Y <= 0 then return 1 end
        return math.min(1, (a.X - 24) / size.X.Offset, (a.Y - 24) / size.Y.Offset)
    end
    window._autoScale = computeAuto()

    local main = New("CanvasGroup", {
        Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = size, BackgroundColor3 = T.Background, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, Parent = gui,
    })
    Corner(main, 12)
    Stroke(main, T.Stroke, 0.35)
    local uiScale = New("UIScale", {Scale = window._userScale * window._autoScale, Parent = main})
    window.Main, window.UIScale = main, uiScale

    -- topbar
    local topbar = New("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = main})
    Text(topbar, {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -60, 1, 0),
        Text = cfg.Title or "Michel UI", Font = Enum.Font.GothamBold, TextSize = 14,
    })
    local close = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.Element, BackgroundTransparency = 0.3,
        Text = "X", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.SubText,
        AutoButtonColor = false, Parent = topbar,
    })
    Corner(close, 7)
    Connect(close.MouseButton1Click, function() window:Toggle(false) end)
    Connect(close.MouseEnter, function() Tween(close, 0.15, {TextColor3 = Color3.fromRGB(255, 90, 90)}) end)
    Connect(close.MouseLeave, function() Tween(close, 0.15, {TextColor3 = T.SubText}) end)
    New("Frame", {
        Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = topbar,
    })
    MakeDraggable(topbar, main, function() return uiScale.Scale end)

    -- sidebar
    local sidebar = New("Frame", {
        Position = UDim2.fromOffset(0, 36), Size = UDim2.new(0, 122, 1, -36),
        BackgroundColor3 = T.Sidebar, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = main,
    })
    local tabList = New("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0, Parent = sidebar,
    })
    Pad(tabList, 8, 8, 8, 8)
    New("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList})
    window.TabList = tabList

    -- content
    local content = New("Frame", {
        Position = UDim2.fromOffset(122, 36), Size = UDim2.new(1, -122, 1, -36),
        BackgroundTransparency = 1, Parent = main,
    })
    Pad(content, 8, 8, 8, 8)
    window.Content = content

    if window._userScale then
        Connect(gui:GetPropertyChangedSignal("AbsoluteSize"), function()
            window._autoScale = computeAuto()
            window:_ApplyScale()
        end)
    end

    if cfg.ToggleKey then
        Connect(UserInputService.InputBegan, function(input, gpe)
            if not gpe and input.KeyCode == cfg.ToggleKey then window:Toggle() end
        end)
    end

    self._window = window
    if cfg.MobileButton == true or (cfg.MobileButton ~= false and UserInputService.TouchEnabled) then
        self:CreateToggleButton(cfg.Icon)
    end

    window:Toggle(true)
    return window
end

function Window:_ApplyScale()
    self.Scale = self._userScale * self._autoScale
    if self.Visible then Tween(self.UIScale, 0.2, {Scale = self.Scale}) end
end

function Window:SetScale(n)
    self._userScale = math.clamp(tonumber(n) or 1, 0.4, 2)
    self:_ApplyScale()
end

function Window:Toggle(state)
    if state == nil then state = not self.Visible end
    self.Visible = state
    self.Scale = self._userScale * self._autoScale
    local main, scale = self.Main, self.UIScale
    if state then
        main.Visible = true
        scale.Scale = self.Scale * 0.85
        main.GroupTransparency = 1
        Tween(main, 0.28, {GroupTransparency = 0})
        Tween(scale, 0.28, {Scale = self.Scale}, Enum.EasingStyle.Back)
    else
        Tween(main, 0.2, {GroupTransparency = 1})
        Tween(scale, 0.2, {Scale = self.Scale * 0.85})
        task.delay(0.21, function()
            if not self.Visible then main.Visible = false end
        end)
    end
end

function Window:SetTitle(t) end -- kept minimal; title set at CreateWindow

function Window:Destroy() Library:Destroy() end

function Window:CreateCategory(name)
    self._order += 1
    Text(self.TabList, {
        Size = UDim2.new(1, 0, 0, 18), Text = string.upper(name or "CATEGORY"),
        TextColor3 = self.Gui and Library.Theme.SubText, TextSize = 10,
        Font = Enum.Font.GothamBold, LayoutOrder = self._order,
    })
end

function Window:_Select(tab)
    local T = Library.Theme
    local cur = self.Current
    if cur == tab then return end
    if cur then
        cur.Page.Visible = false
        Tween(cur.Button, 0.2, {BackgroundTransparency = 1})
        Tween(cur.Label, 0.2, {TextColor3 = T.SubText})
        Tween(cur.Indicator, 0.2, {Size = UDim2.new(0, 3, 0, 0)})
    end
    self.Current = tab
    tab.Page.Visible = true
    Tween(tab.Button, 0.2, {BackgroundTransparency = 0.6})
    Tween(tab.Label, 0.2, {TextColor3 = T.Text})
    Tween(tab.Indicator, 0.2, {Size = UDim2.new(0, 3, 0.6, 0)})
end

-- ============================================================ tab

function Window:CreateTab(name, icon)
    local T = Library.Theme
    self._order += 1
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab._sections = 0

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = T.Element, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = self._order, Parent = self.TabList,
    })
    Corner(button, 7)
    local hasIcon = icon ~= nil and icon ~= ""
    if hasIcon then
        New("ImageLabel", {
            BackgroundTransparency = 1, Image = Asset(icon), ImageColor3 = T.SubText,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(16, 16), Parent = button,
        })
    end
    local label = Text(button, {
        Position = UDim2.fromOffset(hasIcon and 32 or 12, 0), Size = UDim2.new(1, -(hasIcon and 36 or 16), 1, 0),
        Text = name or "Tab", TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local indicator = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0, 0), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = button,
    })
    Corner(indicator, 2)

    local page = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Content})
    local function column(x, w)
        local col = New("ScrollingFrame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.new(x, x == 0 and 0 or 3, 0, 0), Size = UDim2.new(w, -3, 1, 0),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent, Parent = page,
        })
        Pad(col, 0, 3, 0, 0)
        New("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col})
        return col
    end
    tab.Left, tab.Right = column(0, 0.5), column(0.5, 0.5)
    tab.Page, tab.Button, tab.Label, tab.Indicator = page, button, label, indicator

    Connect(button.MouseButton1Click, function() self:_Select(tab) end)
    table.insert(self.Tabs, tab)
    if not self.Current then self:_Select(tab) end
    return tab
end

function Tab:CreateSection(cfg, side)
    if type(cfg) == "string" then cfg = {Name = cfg, Side = side} end
    cfg = cfg or {}
    local T = Library.Theme
    local s = cfg.Side or side or 1
    local right = (s == 2) or (tostring(s):lower() == "right")
    local column = right and self.Right or self.Left
    self._sections += 1

    local frame = New("Frame", {
        Name = "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Section, BackgroundTransparency = 0.3, BorderSizePixel = 0,
        LayoutOrder = self._sections, Parent = column,
    })
    Corner(frame, 8)
    Stroke(frame, T.Stroke, 0.55)
    Pad(frame, 6, 6, 6, 6)
    New("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = frame})
    Text(frame, {
        Size = UDim2.new(1, 0, 0, 18), Text = cfg.Name or "Section",
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Accent, LayoutOrder = 0,
    })

    local sec = setmetatable({}, Section)
    sec.Frame, sec.Scroller, sec._order = frame, column, 0
    return sec
end

-- ============================================================ elements

function Section:_Element(height)
    self._order += 1
    local T = Library.Theme
    local f = New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 32), BackgroundColor3 = T.Element,
        BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = self._order, Parent = self.Frame,
    })
    Corner(f, 7)
    return f
end

local function SetFlag(cfg, value)
    if cfg.Flag then Library.Flags[cfg.Flag] = value end
end

-- Toggle -------------------------------------------------------
function Section:AddToggle(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local state = cfg.Default == true
    local frame = self:_Element(32)
    Text(frame, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0), Text = cfg.Name or "Toggle"})

    local checkbox = cfg.Style == "Checkbox"
    local track = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = checkbox and UDim2.fromOffset(18, 18) or UDim2.fromOffset(36, 18),
        BackgroundColor3 = T.Off, BorderSizePixel = 0, Parent = frame,
    })
    Corner(track, checkbox and 5 or 9)
    local knob = New("Frame", {
        AnchorPoint = checkbox and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5),
        Position = checkbox and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 2, 0.5, 0),
        Size = checkbox and UDim2.fromOffset(0, 0) or UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track,
    })
    Corner(knob, checkbox and 3 or 7)
    local hit = New("TextButton", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", Parent = frame})

    local obj = {}
    local function render()
        Tween(track, 0.2, {BackgroundColor3 = state and T.Accent or T.Off})
        if checkbox then
            Tween(knob, 0.2, {Size = state and UDim2.fromOffset(10, 10) or UDim2.fromOffset(0, 0)})
        else
            Tween(knob, 0.2, {Position = state and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)})
        end
    end
    function obj:Set(v, silent)
        state = v and true or false
        render()
        SetFlag(cfg, state)
        if not silent then Fire(cfg.Callback, state) end
    end
    function obj:Get() return state end
    Connect(hit.MouseButton1Click, function() obj:Set(not state) end)

    state = state and true or false
    render()
    SetFlag(cfg, state)
    if cfg.Default == true then Fire(cfg.Callback, state) end
    return obj
end

-- Slider -------------------------------------------------------
function Section:AddSlider(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local min, max = cfg.Min or 0, cfg.Max or 100
    if max <= min then max = min + 1 end
    local decimals, suffix = cfg.Decimals or 0, cfg.Suffix or ""
    local value = math.clamp(cfg.Default or min, min, max)

    local frame = self:_Element(44)
    Text(frame, {Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -96, 0, 18), Text = cfg.Name or "Slider"})
    local valueLabel = Text(frame, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.fromOffset(80, 18),
        TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.SubText, TextSize = 12,
    })
    local bar = New("Frame", {
        Position = UDim2.new(0, 10, 1, -14), Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = T.Off, BorderSizePixel = 0, Parent = frame,
    })
    Corner(bar, 3)
    local fill = New("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = bar})
    Corner(fill, 3)
    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = fill,
    })
    Corner(knob, 6)
    local hit = New("TextButton", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", Parent = frame})

    local function fmt(v)
        if decimals > 0 then return string.format("%." .. decimals .. "f", v) .. suffix end
        return tostring(v) .. suffix
    end
    local obj = {}
    local function set(v, silent)
        v = Round(math.clamp(v, min, max), decimals)
        local changed = v ~= value
        value = v
        Tween(fill, 0.08, {Size = UDim2.fromScale((v - min) / (max - min), 1)})
        valueLabel.Text = fmt(v)
        SetFlag(cfg, v)
        if changed and not silent then Fire(cfg.Callback, v) end
    end
    function obj:Set(v, silent) set(tonumber(v) or min, silent) end
    function obj:Get() return value end

    local dragging = false
    local function fromInput(input)
        local a = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        set(min + (max - min) * a)
    end
    Connect(hit.InputBegan, function(input)
        if IsPointer(input) then
            dragging = true
            self.Scroller.ScrollingEnabled = false
            fromInput(input)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and IsMove(input) then fromInput(input) end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if dragging and IsPointer(input) then
            dragging = false
            self.Scroller.ScrollingEnabled = true
        end
    end)

    fill.Size = UDim2.fromScale((value - min) / (max - min), 1)
    valueLabel.Text = fmt(Round(value, decimals))
    value = Round(value, decimals)
    SetFlag(cfg, value)
    return obj
end

-- Dropdown (single / multi) -----------------------------------
function Section:AddDropdown(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local multi = cfg.Multi == true
    local options = {}
    for _, o in ipairs(cfg.Options or {}) do table.insert(options, tostring(o)) end
    local selected, open = {}, false

    local frame = self:_Element(32)
    frame.ClipsDescendants = true
    Text(frame, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.42, -10, 0, 32), Text = cfg.Name or "Dropdown", TextTruncate = Enum.TextTruncate.AtEnd})
    local value = Text(frame, {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0.58, -34, 0, 32),
        TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.SubText, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
    })
    local arrow = Text(frame, {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 16), Size = UDim2.fromOffset(12, 12),
        Text = ">", TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 12,
    })
    local header = New("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Text = "", Parent = frame})
    local list = New("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 0, 0), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.Accent, Parent = frame,
    })
    New("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list})

    local buttons = {}
    local obj = {}

    local function collect()
        local out = {}
        for _, o in ipairs(options) do if selected[o] then table.insert(out, o) end end
        return out
    end
    local function current()
        if multi then return collect() end
        return collect()[1]
    end
    local function refreshText()
        local l = collect()
        if multi then value.Text = #l > 0 and table.concat(l, ", ") or "None" else value.Text = l[1] or "None" end
    end
    local function paint()
        for opt, b in pairs(buttons) do
            local on = selected[opt] == true
            Tween(b, 0.15, {BackgroundTransparency = on and 0.65 or 1, TextColor3 = on and T.Accent or T.SubText})
        end
    end
    local function listHeight() return math.min(#options, 5) * 26 end
    local function setOpen(state)
        open = state
        list.Size = UDim2.new(1, -12, 0, listHeight())
        Tween(frame, 0.22, {Size = UDim2.new(1, 0, 0, open and (38 + listHeight() + 6) or 32)})
        Tween(arrow, 0.22, {Rotation = open and 90 or 0})
    end
    local function commit(silent)
        refreshText()
        paint()
        SetFlag(cfg, current())
        if not silent then Fire(cfg.Callback, current()) end
    end
    local function rebuild()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        for i, opt in ipairs(options) do
            local b = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
                Text = opt, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.SubText,
                AutoButtonColor = false, LayoutOrder = i, Parent = list,
            })
            Corner(b, 5)
            buttons[opt] = b
            Connect(b.MouseButton1Click, function()
                if multi then
                    selected[opt] = (not selected[opt]) or nil
                else
                    selected = {[opt] = true}
                    setOpen(false)
                end
                commit()
            end)
        end
        if open then setOpen(true) end
    end

    function obj:Get() return current() end
    function obj:Set(v, silent)
        selected = {}
        if multi and type(v) == "table" then
            for _, o in ipairs(v) do selected[tostring(o)] = true end
        elseif v ~= nil then
            selected[tostring(v)] = true
        end
        commit(silent)
    end
    function obj:Refresh(newOptions, keep)
        local prev = selected
        options = {}
        for _, o in ipairs(newOptions or {}) do table.insert(options, tostring(o)) end
        selected = {}
        if keep then for _, o in ipairs(options) do if prev[o] then selected[o] = true end end end
        rebuild()
        commit(true)
    end

    Connect(header.MouseButton1Click, function() setOpen(not open) end)

    rebuild()
    local d = cfg.Default
    if multi and type(d) == "table" then
        for _, o in ipairs(d) do selected[tostring(o)] = true end
    elseif d ~= nil and not multi then
        selected[tostring(d)] = true
    end
    commit(true)
    return obj
end

-- Button -------------------------------------------------------
function Section:AddButton(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local frame = self:_Element(32)
    local btn = New("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Button",
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, AutoButtonColor = false, Parent = frame,
    })
    local stroke = Stroke(frame, T.Accent, 0.75)
    Connect(btn.MouseButton1Click, function()
        Tween(frame, 0.08, {BackgroundColor3 = T.Accent})
        task.delay(0.1, function() Tween(frame, 0.25, {BackgroundColor3 = T.Element}) end)
        Fire(cfg.Callback)
    end)
    Connect(btn.MouseEnter, function() Tween(stroke, 0.15, {Transparency = 0.2}) end)
    Connect(btn.MouseLeave, function() Tween(stroke, 0.15, {Transparency = 0.75}) end)
    local obj = {}
    function obj:SetText(t) btn.Text = t end
    return obj
end

-- Textbox ------------------------------------------------------
function Section:AddTextbox(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local frame = self:_Element(32)
    Text(frame, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.4, -10, 1, 0), Text = cfg.Name or "Textbox", TextTruncate = Enum.TextTruncate.AtEnd})
    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.6, -10, 0, 22),
        BackgroundColor3 = T.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "Type here...",
        PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = cfg.ClearOnFocus == true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
    })
    Corner(box, 5)
    local stroke = Stroke(box, T.Stroke, 0.5)
    Connect(box.Focused, function() Tween(stroke, 0.15, {Color = T.Accent, Transparency = 0.1}) end)
    Connect(box.FocusLost, function(enter)
        Tween(stroke, 0.15, {Color = T.Stroke, Transparency = 0.5})
        SetFlag(cfg, box.Text)
        if enter or cfg.CallbackOnBlur ~= false then Fire(cfg.Callback, box.Text) end
    end)
    SetFlag(cfg, box.Text)
    local obj = {}
    function obj:Set(t, silent)
        box.Text = tostring(t)
        SetFlag(cfg, box.Text)
        if not silent then Fire(cfg.Callback, box.Text) end
    end
    function obj:Get() return box.Text end
    return obj
end

-- Label --------------------------------------------------------
function Section:AddLabel(text)
    local T = Library.Theme
    local frame = self:_Element(0)
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundTransparency = 0.6
    Pad(frame, 5, 10, 5, 10)
    local label = Text(frame, {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(text or "Label"),
        TextColor3 = T.SubText, TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
    })
    local obj = {}
    function obj:Set(t) label.Text = tostring(t) end
    function obj:Get() return label.Text end
    return obj
end

-- ColorPicker --------------------------------------------------
function Section:AddColorPicker(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local color = cfg.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = Color3.toHSV(color)
    local open = false

    local frame = self:_Element(32)
    frame.ClipsDescendants = true
    Text(frame, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 0, 32), Text = cfg.Name or "Color"})
    local preview = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, 16), Size = UDim2.fromOffset(28, 16),
        BackgroundColor3 = color, BorderSizePixel = 0, Parent = frame,
    })
    Corner(preview, 5)
    Stroke(preview, Color3.new(1, 1, 1), 0.7)
    local header = New("TextButton", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Text = "", Parent = frame})

    local sv = New("Frame", {
        Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 0, 84),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
    })
    Corner(sv, 5)
    local white = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv})
    New("UIGradient", {Transparency = NumberSequence.new(0, 1), Parent = white})
    local black = New("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv})
    New("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black})
    local svCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 3, Parent = sv,
    })
    Corner(svCursor, 5)
    Stroke(svCursor, Color3.new(1, 1, 1), 0, 2)

    local hue = New("Frame", {
        Position = UDim2.fromOffset(8, 128), Size = UDim2.new(1, -16, 0, 12),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = frame,
    })
    Corner(hue, 5)
    New("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    }), Parent = hue})
    local hueCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 16), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 3, Parent = hue,
    })
    Corner(hueCursor, 2)
    Stroke(hueCursor, Color3.new(0, 0, 0), 0.4)

    local obj = {}
    local function update(silent)
        color = Color3.fromHSV(math.clamp(h, 0, 0.9999), s, v)
        preview.BackgroundColor3 = color
        sv.BackgroundColor3 = Color3.fromHSV(math.clamp(h, 0, 0.9999), 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(h, 0.5)
        SetFlag(cfg, color)
        if not silent then Fire(cfg.Callback, color) end
    end
    function obj:Set(c, silent) h, s, v = Color3.toHSV(c); update(silent) end
    function obj:Get() return color end

    local mode
    local function apply(input)
        if mode == "sv" then
            s = math.clamp((input.Position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
            v = 1 - math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        elseif mode == "hue" then
            h = math.clamp((input.Position.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 1)
        end
        update()
    end
    local function begin(m, input)
        mode = m
        self.Scroller.ScrollingEnabled = false
        apply(input)
    end
    Connect(sv.InputBegan, function(i) if IsPointer(i) then begin("sv", i) end end)
    Connect(hue.InputBegan, function(i) if IsPointer(i) then begin("hue", i) end end)
    Connect(UserInputService.InputChanged, function(i) if mode and IsMove(i) then apply(i) end end)
    Connect(UserInputService.InputEnded, function(i)
        if mode and IsPointer(i) then
            mode = nil
            self.Scroller.ScrollingEnabled = true
        end
    end)
    Connect(header.MouseButton1Click, function()
        open = not open
        Tween(frame, 0.22, {Size = UDim2.new(1, 0, 0, open and 148 or 32)})
    end)

    update(true)
    return obj
end

-- Keybind ------------------------------------------------------
function Section:AddKeybind(cfg)
    cfg = cfg or {}
    local T = Library.Theme
    local key = cfg.Default
    local listening = false

    local frame = self:_Element(32)
    Text(frame, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -90, 1, 0), Text = cfg.Name or "Keybind", TextTruncate = Enum.TextTruncate.AtEnd})
    local btn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(72, 22),
        BackgroundColor3 = T.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.SubText, AutoButtonColor = false, Parent = frame,
    })
    Corner(btn, 5)
    Stroke(btn, T.Stroke, 0.5)

    local obj = {}
    local function render() btn.Text = listening and "..." or (key and key.Name or "None") end
    function obj:Get() return key end
    function obj:Set(k, silent)
        key = k
        listening = false
        render()
        SetFlag(cfg, key)
        if not silent then Fire(cfg.ChangedCallback, key) end
    end

    Connect(btn.MouseButton1Click, function()
        listening = true
        render()
        Tween(btn, 0.15, {TextColor3 = T.Accent})
    end)
    Connect(UserInputService.InputBegan, function(input, gpe)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Tween(btn, 0.15, {TextColor3 = T.SubText})
                obj:Set(input.KeyCode == Enum.KeyCode.Escape and nil or input.KeyCode)
            end
        elseif key and not gpe and input.KeyCode == key then
            Fire(cfg.Callback, key)
        end
    end)

    render()
    SetFlag(cfg, key)
    return obj
end

-- ============================================================ mobile toggle button

function Library:CreateToggleButton(iconAssetId)
    local window = self._window
    assert(window, "[MichelUI] Create a window before CreateToggleButton")
    local T = self.Theme
    local gui = self:_GetGui()
    if self._toggleButton then self._toggleButton:Destroy() end

    local a = gui.AbsoluteSize
    local btn = New("ImageButton", {
        Name = "MichelToggle", Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(16, math.max(a.Y / 2 - 24, 0)),
        BackgroundColor3 = T.Background, BackgroundTransparency = 0.12, AutoButtonColor = false, ZIndex = 50, Parent = gui,
    })
    Corner(btn, 24)
    Stroke(btn, T.Accent, 0.35, 1.5)
    local scale = New("UIScale", {Scale = 1, Parent = btn})
    if iconAssetId ~= nil and iconAssetId ~= "" then
        New("ImageLabel", {
            BackgroundTransparency = 1, Image = Asset(iconAssetId), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.58, 0.58), ZIndex = 51, Parent = btn,
        })
    else
        Text(btn, {
            Size = UDim2.fromScale(1, 1), Text = "M", Font = Enum.Font.GothamBlack, TextSize = 20,
            TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 51,
        })
    end

    local dragging, moved, dragStart, startPos = false, false, nil, nil
    Connect(btn.InputBegan, function(input)
        if IsPointer(input) then
            dragging, moved = true, false
            dragStart, startPos = input.Position, btn.Position
            Tween(scale, 0.12, {Scale = 0.9})
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    c:Disconnect()
                    dragging = false
                    Tween(scale, 0.18, {Scale = 1}, Enum.EasingStyle.Back)
                    if not moved then window:Toggle() end
                end
            end)
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and IsMove(input) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            if moved then
                local bounds = gui.AbsoluteSize
                btn.Position = UDim2.fromOffset(
                    math.clamp(startPos.X.Offset + d.X, 0, math.max(bounds.X - 48, 0)),
                    math.clamp(startPos.Y.Offset + d.Y, 0, math.max(bounds.Y - 48, 0))
                )
            end
        end
    end)

    self._toggleButton = btn
    return btn
end

return Library

--[==[
================================================================
 EXAMPLE USAGE
================================================================

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/MichelUI.lua"))()

local Window = Library:CreateWindow({
    Title = "Michel Hub | v1.0",
    Size = UDim2.fromOffset(500, 340),
    Scale = 1,                          -- manual scale multiplier (also Window:SetScale(n))
    AutoScale = true,                   -- shrinks automatically on small screens
    Icon = "rbxassetid://7733954760",   -- icon for the floating mobile toggle button
    ToggleKey = Enum.KeyCode.RightShift -- optional keyboard toggle (PC)
})

Window:CreateCategory("Main")
local Combat = Window:CreateTab("Combat")
local Visual = Window:CreateTab("Visual")
Window:CreateCategory("Config")
local Settings = Window:CreateTab("Settings")

local Aim = Combat:CreateSection("Aimbot", 1)
Aim:AddToggle({Name = "Enabled", Default = false, Flag = "AimEnabled", Callback = function(v)
    print("Aimbot:", v)
end})
Aim:AddToggle({Name = "Team Check", Style = "Checkbox", Default = true, Callback = function(v) print(v) end})
Aim:AddSlider({Name = "FOV", Min = 10, Max = 360, Default = 90, Suffix = "°", Decimals = 0, Callback = function(v)
    print("FOV", v)
end})
Aim:AddSlider({Name = "Smoothness", Min = 0, Max = 1, Default = 0.35, Decimals = 2, Callback = print})
Aim:AddKeybind({Name = "Aim Key", Default = Enum.KeyCode.E, Callback = function(k) print("Pressed", k.Name) end})

local Target = Combat:CreateSection("Target", 2)
Target:AddDropdown({Name = "Part", Options = {"Head", "Torso", "HumanoidRootPart"}, Default = "Head", Callback = print})
Target:AddDropdown({Name = "Filters", Options = {"Players", "NPCs", "Bosses", "Items"}, Multi = true,
    Default = {"Players"}, Callback = function(list) print(table.concat(list, ", ")) end})
Target:AddButton({Name = "Notify Me", Callback = function()
    Library:Notify({Title = "Michel Hub", Content = "Button clicked!", Duration = 4, Icon = "rbxassetid://7733954760"})
end})

local Esp = Visual:CreateSection("ESP", 1)
Esp:AddColorPicker({Name = "Box Color", Default = Color3.fromRGB(0, 162, 255), Callback = function(c) print(c) end})
Esp:AddLabel("Colors update in real time.")

local Cfg = Settings:CreateSection("Interface", 1)
Cfg:AddSlider({Name = "UI Scale", Min = 0.6, Max = 1.4, Default = 1, Decimals = 2, Callback = function(v)
    Window:SetScale(v)
end})
Cfg:AddTextbox({Name = "Player Name", Placeholder = "Enter name...", Default = "", Callback = function(t)
    print("Name:", t)
end})
Cfg:AddButton({Name = "Unload UI", Callback = function() Window:Destroy() end})

Library:Notify({Title = "Michel Hub", Content = "Loaded successfully.", Duration = 5})
-- Read any value later: Library.Flags.AimEnabled
]==]
