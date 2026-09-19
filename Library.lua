-- Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Cleanup Existing UI
if CoreGui:FindFirstChild("MichelModernLibraryUI") then
    CoreGui.MichelModernLibraryUI:Destroy()
end

-- Color Palette
local Theme = {
    BG = Color3.fromRGB(15, 17, 23),
    SidebarBG = Color3.fromRGB(20, 23, 31),
    CardBG = Color3.fromRGB(27, 31, 43),
    CardHoverBG = Color3.fromRGB(34, 39, 54),
    Accent = Color3.fromRGB(56, 189, 248),
    Border = Color3.fromRGB(255, 255, 255),
    TextPrimary = Color3.fromRGB(240, 243, 248),
    TextSecondary = Color3.fromRGB(140, 150, 175)
}

local Library = {}

local MinSize = Vector2.new(420, 260)
local MaxSize = Vector2.new(900, 600)
local SizePresets = {
    Vector2.new(420, 260),
    Vector2.new(560, 360),
    Vector2.new(760, 480)
}

local function CreateCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function CreateStroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Transparency = transparency or 0.88
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local DummySelection = Instance.new("Frame")
DummySelection.BackgroundTransparency = 1
DummySelection.Size = UDim2.new(0, 0, 0, 0)

function Library:CreateWindow(options)
    options = options or {}
    local titleText = options.Title or "Michel Script x Library"
    local authorText = options.Author or "MichelLyJow"
    local iconId = options.Icon or "rbxthumb://type=Asset&id=102030546943731&w=420&h=420"

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MichelModernLibraryUI"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    if syn and syn.protect_gui then syn.protect_gui(ScreenGui)
    elseif protectgui then protectgui(ScreenGui) end

    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(0, 560, 0, 360)
    Shadow.Position = UDim2.new(0.5, -280, 0.5, -180)
    Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.BackgroundTransparency = 0.4
    Shadow.ZIndex = 1
    Shadow.Parent = ScreenGui
    CreateCorner(Shadow, 16)

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 560, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -180)
    MainFrame.BackgroundColor3 = Theme.BG
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 2
    MainFrame.Parent = ScreenGui
    CreateCorner(MainFrame, 16)
    CreateStroke(MainFrame, Theme.Border, 0.82, 1.2)

    -- Dragging Logic
    local dragging, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            MainFrame.Position = newPos
            Shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset, newPos.Y.Scale, newPos.Y.Offset + 4)
        end
    end)

    -- Resize: mengatur ulang ukuran MainFrame + Shadow sekaligus
    local function ResizeAll(newSize, tween)
        local target = UDim2.new(0, newSize.X, 0, newSize.Y)
        if tween then
            TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target}):Play()
            TweenService:Create(Shadow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target}):Play()
        else
            MainFrame.Size = target
            Shadow.Size = target
        end
    end

    -- Drag-resize bebas dari sudut kanan-bawah
    local ResizeHandle = Instance.new("TextButton", MainFrame)
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, 22, 0, 22)
    ResizeHandle.Position = UDim2.new(1, -24, 1, -24)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Text = "⤡"
    ResizeHandle.Rotation = 0
    ResizeHandle.TextColor3 = Theme.TextSecondary
    ResizeHandle.Font = Enum.Font.GothamBold
    ResizeHandle.TextSize = 16
    ResizeHandle.AutoButtonColor = false
    ResizeHandle.SelectionImageObject = DummySelection
    ResizeHandle.ZIndex = 6

    ResizeHandle.MouseEnter:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.15), {TextColor3 = Theme.Accent}):Play()
    end)
    ResizeHandle.MouseLeave:Connect(function()
        TweenService:Create(ResizeHandle, TweenInfo.new(0.15), {TextColor3 = Theme.TextSecondary}):Play()
    end)

    local resizing, resizeStart, startSize
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.Size
        end
    end)
    ResizeHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newWidth = math.clamp(startSize.X.Offset + delta.X, MinSize.X, MaxSize.X)
            local newHeight = math.clamp(startSize.Y.Offset + delta.Y, MinSize.Y, MaxSize.Y)
            ResizeAll(Vector2.new(newWidth, newHeight), false)
        end
    end)

    -- Sidebar Area
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.Size = UDim2.new(0, 165, 1, 0)
    Sidebar.BackgroundColor3 = Theme.SidebarBG
    Sidebar.BackgroundTransparency = 0.2
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 3

    local SidebarDivider = Instance.new("Frame", Sidebar)
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BackgroundColor3 = Theme.Border
    SidebarDivider.BackgroundTransparency = 0.9
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.ZIndex = 4

    local BrandFrame = Instance.new("Frame", Sidebar)
    BrandFrame.Size = UDim2.new(1, -20, 0, 40)
    BrandFrame.Position = UDim2.new(0, 12, 0, 14)
    BrandFrame.BackgroundTransparency = 1
    BrandFrame.ZIndex = 4

    local IconImg = Instance.new("ImageLabel", BrandFrame)
    IconImg.Size = UDim2.new(0, 28, 0, 28)
    IconImg.Position = UDim2.new(0, 0, 0.5, -14)
    IconImg.Image = iconId
    IconImg.BackgroundTransparency = 1
    IconImg.ZIndex = 4
    CreateCorner(IconImg, 8)

    local TitleLbl = Instance.new("TextLabel", BrandFrame)
    TitleLbl.Size = UDim2.new(1, -36, 0, 16)
    TitleLbl.Position = UDim2.new(0, 34, 0, 2)
    TitleLbl.Text = titleText
    TitleLbl.TextColor3 = Theme.TextPrimary
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.ZIndex = 4

    local AuthorLbl = Instance.new("TextLabel", BrandFrame)
    AuthorLbl.Size = UDim2.new(1, -36, 0, 14)
    AuthorLbl.Position = UDim2.new(0, 34, 0, 18)
    AuthorLbl.RichText = true
    AuthorLbl.Text = authorText .. " <font color=\"rgb(56, 189, 248)\">✓</font>"
    AuthorLbl.TextColor3 = Theme.TextSecondary
    AuthorLbl.Font = Enum.Font.Gotham
    AuthorLbl.TextSize = 10
    AuthorLbl.TextXAlignment = Enum.TextXAlignment.Left
    AuthorLbl.BackgroundTransparency = 1
    AuthorLbl.ZIndex = 4

    local TabScroll = Instance.new("ScrollingFrame", Sidebar)
    TabScroll.Size = UDim2.new(1, -16, 1, -125)
    TabScroll.Position = UDim2.new(0, 8, 0, 64)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 0
    TabScroll.ZIndex = 4

    local TabList = Instance.new("UIListLayout", TabScroll)
    TabList.Padding = UDim.new(0, 4)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder

    local UserBox = Instance.new("Frame", Sidebar)
    UserBox.Size = UDim2.new(1, -16, 0, 42)
    UserBox.Position = UDim2.new(0, 8, 1, -50)
    UserBox.BackgroundColor3 = Theme.CardBG
    UserBox.BackgroundTransparency = 0.5
    UserBox.ZIndex = 4
    CreateCorner(UserBox, 10)
    CreateStroke(UserBox, Theme.Border, 0.9, 1)

    local UserAvatar = Instance.new("ImageLabel", UserBox)
    UserAvatar.Size = UDim2.new(0, 26, 0, 26)
    UserAvatar.Position = UDim2.new(0, 8, 0.5, -13)
    UserAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    UserAvatar.BackgroundTransparency = 1
    UserAvatar.ZIndex = 4
    CreateCorner(UserAvatar, 13)

    local UserName = Instance.new("TextLabel", UserBox)
    UserName.Size = UDim2.new(1, -42, 0, 14)
    UserName.Position = UDim2.new(0, 40, 0, 7)
    UserName.Text = LocalPlayer.DisplayName
    UserName.TextColor3 = Theme.TextPrimary
    UserName.Font = Enum.Font.GothamBold
    UserName.TextSize = 10
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.TextTruncate = Enum.TextTruncate.AtEnd
    UserName.BackgroundTransparency = 1
    UserName.ZIndex = 4

    local UserHandle = Instance.new("TextLabel", UserBox)
    UserHandle.Size = UDim2.new(1, -42, 0, 12)
    UserHandle.Position = UDim2.new(0, 40, 0, 21)
    UserHandle.Text = "@" .. LocalPlayer.Name
    UserHandle.TextColor3 = Theme.TextSecondary
    UserHandle.Font = Enum.Font.Gotham
    UserHandle.TextSize = 9
    UserHandle.TextXAlignment = Enum.TextXAlignment.Left
    UserHandle.TextTruncate = Enum.TextTruncate.AtEnd
    UserHandle.BackgroundTransparency = 1
    UserHandle.ZIndex = 4

  -- Top Controls
    local HeaderBar = Instance.new("Frame", MainFrame)
    HeaderBar.Size = UDim2.new(1, -165, 0, 36)
    HeaderBar.Position = UDim2.new(0, 165, 0, 0)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 5

    local CloseBtn = Instance.new("TextButton", HeaderBar)
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    CloseBtn.BackgroundColor3 = Theme.CardBG
    CloseBtn.BackgroundTransparency = 0.5
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Theme.TextSecondary
    CloseBtn.Font = Enum.Font.GothamMedium
    CloseBtn.TextSize = 11
    CloseBtn.AutoButtonColor = false
    CloseBtn.SelectionImageObject = DummySelection
    CloseBtn.ZIndex = 5
    CreateCorner(CloseBtn, 7)
    CreateStroke(CloseBtn, Theme.Border, 0.88, 1)

    local ExpandBtn = Instance.new("TextButton", HeaderBar)
    ExpandBtn.Size = UDim2.new(0, 26, 0, 26)
    ExpandBtn.Position = UDim2.new(1, -98, 0.5, -13)
    ExpandBtn.BackgroundColor3 = Theme.CardBG
    ExpandBtn.BackgroundTransparency = 0.5
    ExpandBtn.Text = "⤢"
    ExpandBtn.TextColor3 = Theme.TextSecondary
    ExpandBtn.Font = Enum.Font.GothamBold
    ExpandBtn.TextSize = 13
    ExpandBtn.AutoButtonColor = false
    ExpandBtn.SelectionImageObject = DummySelection
    ExpandBtn.ZIndex = 5
    CreateCorner(ExpandBtn, 7)
    CreateStroke(ExpandBtn, Theme.Border, 0.88, 1)

    local presetIndex = 2 -- mulai dari ukuran default (560x360)
    ExpandBtn.MouseButton1Click:Connect(function()
        presetIndex = (presetIndex % #SizePresets) + 1
        ResizeAll(SizePresets[presetIndex], true)
    end)

    local MinimizeBtn = Instance.new("TextButton", HeaderBar)
    MinimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    MinimizeBtn.Position = UDim2.new(1, -66, 0.5, -13)
    MinimizeBtn.BackgroundColor3 = Theme.CardBG
    MinimizeBtn.BackgroundTransparency = 0.5
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Theme.TextSecondary
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 16
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.SelectionImageObject = DummySelection
    MinimizeBtn.ZIndex = 5
    CreateCorner(MinimizeBtn, 7)
    CreateStroke(MinimizeBtn, Theme.Border, 0.88, 1)

    local function AddBtnHover(btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2, TextColor3 = Theme.TextPrimary}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, TextColor3 = Theme.TextSecondary}):Play()
        end)
    end
    AddBtnHover(CloseBtn)
    AddBtnHover(MinimizeBtn)
    AddBtnHover(ExpandBtn)

    local ContentArea = Instance.new("Frame", MainFrame)
    ContentArea.Size = UDim2.new(1, -181, 1, -44)
    ContentArea.Position = UDim2.new(0, 173, 0, 36)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ZIndex = 3

    -- Floating Button
    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Name = "ToggleButton"
    ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
    ToggleBtn.Position = UDim2.new(0, 20, 0.45, 0)
    ToggleBtn.BackgroundColor3 = Theme.BG
    ToggleBtn.BackgroundTransparency = 0.2
    ToggleBtn.Image = iconId
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.SelectionImageObject = DummySelection
    ToggleBtn.ZIndex = 10
    ToggleBtn.Parent = ScreenGui
    CreateCorner(ToggleBtn, 12)
    local ToggleStroke = CreateStroke(ToggleBtn, Theme.Border, 0.7, 1.2)

    ToggleBtn.MouseEnter:Connect(function()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 50, 0, 50)}):Play()
        TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Transparency = 0.3, Color = Theme.Accent}):Play()
    end)
    ToggleBtn.MouseLeave:Connect(function()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {Size = UDim2.new(0, 46, 0, 46)}):Play()
        TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Transparency = 0.7, Color = Theme.Border}):Play()
    end)

    local windowObj = {
        MainFrame = MainFrame,
        Shadow = Shadow,
        Tabs = {}
    }

    local function ToggleUI()
        local newState = not MainFrame.Visible
        MainFrame.Visible = newState
        Shadow.Visible = newState
    end

    ToggleBtn.MouseButton1Click:Connect(ToggleUI)
    MinimizeBtn.MouseButton1Click:Connect(ToggleUI)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    function windowObj:Destroy() ScreenGui:Destroy() end

    function windowObj:Tab(tabOptions)
        tabOptions = tabOptions or {}
        local tabTitle = tabOptions.Title or "Tab"

        local TabBtn = Instance.new("TextButton", TabScroll)
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = Theme.CardBG
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.SelectionImageObject = DummySelection
        TabBtn.ZIndex = 4
        CreateCorner(TabBtn, 8)

        local TabIndicator = Instance.new("Frame", TabBtn)
        TabIndicator.Size = UDim2.new(0, 3, 0, 16)
        TabIndicator.Position = UDim2.new(0, 4, 0.5, -8)
        TabIndicator.BackgroundColor3 = Theme.Accent
        TabIndicator.BackgroundTransparency = 1
        TabIndicator.ZIndex = 4
        CreateCorner(TabIndicator, 2)

        local TabLbl = Instance.new("TextLabel", TabBtn)
        TabLbl.Size = UDim2.new(1, -20, 1, 0)
        TabLbl.Position = UDim2.new(0, 14, 0, 0)
        TabLbl.Text = tabTitle
        TabLbl.TextColor3 = Theme.TextSecondary
        TabLbl.Font = Enum.Font.GothamMedium
        TabLbl.TextSize = 11
        TabLbl.TextXAlignment = Enum.TextXAlignment.Left
        TabLbl.BackgroundTransparency = 1
        TabLbl.ZIndex = 4

        local TabContent = Instance.new("ScrollingFrame", ContentArea)
        TabContent.Size = UDim2.new(1, -6, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 2
        TabContent.ScrollBarImageColor3 = Theme.Accent
        TabContent.Visible = false
        TabContent.ZIndex = 3

        local ContentList = Instance.new("UIListLayout", TabContent)
        ContentList.Padding = UDim.new(0, 6)
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder

        ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 8)
        end)

        local tabObj = { Button = TabBtn, Container = TabContent, Indicator = TabIndicator, Label = TabLbl }

        local function ActivateTab()
            for _, t in pairs(windowObj.Tabs) do
                t.Container.Visible = false
                TweenService:Create(t.Button, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                TweenService:Create(t.Label, TweenInfo.new(0.15), {TextColor3 = Theme.TextSecondary}):Play()
                TweenService:Create(t.Indicator, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            end
            TabContent.Visible = true
            TweenService:Create(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.6}):Play()
            TweenService:Create(TabLbl, TweenInfo.new(0.15), {TextColor3 = Theme.TextPrimary}):Play()
            TweenService:Create(TabIndicator, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end

        TabBtn.MouseButton1Click:Connect(ActivateTab)
        table.insert(windowObj.Tabs, tabObj)
        if #windowObj.Tabs == 1 then ActivateTab() end

        function tabObj:Button(btnOptions)
            btnOptions = btnOptions or {}
            local btnTitle = btnOptions.Title or "Button"
            local callback = btnOptions.Callback or function() end

            local BtnCard = Instance.new("Frame", TabContent)
            BtnCard.Size = UDim2.new(1, -6, 0, 40)
            BtnCard.BackgroundColor3 = Theme.CardBG
            BtnCard.BackgroundTransparency = 0.4
            BtnCard.ZIndex = 3
            CreateCorner(BtnCard, 10)
            local CardStroke = CreateStroke(BtnCard, Theme.Border, 0.9, 1)

            local ActionBtn = Instance.new("TextButton", BtnCard)
            ActionBtn.Size = UDim2.new(1, 0, 1, 0)
            ActionBtn.BackgroundTransparency = 1
            ActionBtn.Text = ""
            ActionBtn.AutoButtonColor = false
            ActionBtn.SelectionImageObject = DummySelection
            ActionBtn.ZIndex = 4

            local Title = Instance.new("TextLabel", BtnCard)
            Title.Size = UDim2.new(1, -40, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Text = btnTitle
            Title.TextColor3 = Theme.TextPrimary
            Title.Font = Enum.Font.GothamMedium
            Title.TextSize = 11
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.BackgroundTransparency = 1
            Title.ZIndex = 4

            local ArrowIcon = Instance.new("TextLabel", BtnCard)
            ArrowIcon.Size = UDim2.new(0, 24, 0, 24)
            ArrowIcon.Position = UDim2.new(1, -28, 0.5, -12)
            ArrowIcon.Text = "›"
            ArrowIcon.TextColor3 = Theme.Accent
            ArrowIcon.Font = Enum.Font.GothamBold
            ArrowIcon.TextSize = 18
            ArrowIcon.BackgroundTransparency = 1
            ArrowIcon.ZIndex = 4

            ActionBtn.MouseEnter:Connect(function()
                TweenService:Create(BtnCard, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardHoverBG, BackgroundTransparency = 0.2}):Play()
                TweenService:Create(CardStroke, TweenInfo.new(0.15), {Color = Theme.Accent, Transparency = 0.4}):Play()
                TweenService:Create(ArrowIcon, TweenInfo.new(0.15), {Position = UDim2.new(1, -25, 0.5, -12)}):Play()
            end)

            ActionBtn.MouseLeave:Connect(function()
                TweenService:Create(BtnCard, TweenInfo.new(0.15), {BackgroundColor3 = Theme.CardBG, BackgroundTransparency = 0.4}):Play()
                TweenService:Create(CardStroke, TweenInfo.new(0.15), {Color = Theme.Border, Transparency = 0.9}):Play()
                TweenService:Create(ArrowIcon, TweenInfo.new(0.15), {Position = UDim2.new(1, -28, 0.5, -12)}):Play()
            end)

            ActionBtn.MouseButton1Click:Connect(callback)
        end

        return tabObj
    end

    return windowObj
end

-- Eksekusi Menu
local Window = Library:CreateWindow({
    Title = "Michel Script x Library",
    Author = "MichelLyJow",
    Icon = "rbxthumb://type=Asset&id=102030546943731&w=420&h=420"
})

local Tabs = { Main = Window:Tab({ Title = "Main" }) }
local function CloseAllGUI() Window:Destroy() end

Tabs.Main:Button({
    Title = "Michel x Fire a Lucky Block",
    Callback = function() CloseAllGUI() loadstring(game:HttpGet('https://pastefy.app/xee7Iw0f/raw'))() end
})

Tabs.Main:Button({
    Title = "Michel x +1 Strength to Grow Your Arm",
    Callback = function() CloseAllGUI() loadstring(game:HttpGet('https://pastefy.app/iSmErYrK/raw'))() end
})

Tabs.Main:Button({
    Title = "Michel x Ride A Pet",
    Callback = function() CloseAllGUI() loadstring(game:HttpGet('https://pastefy.app/t5jqhh5a/raw'))() end
})

Tabs.Main:Button({
    Title = "Michel x Climb and Drop a Lucky Block",
    Callback = function() CloseAllGUI() loadstring(game:HttpGet('https://pastefy.app/1DVBWRVr/raw'))() end
})