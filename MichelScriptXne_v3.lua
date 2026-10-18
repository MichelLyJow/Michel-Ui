-- // Michel Script Xne Library (Core Engine) v3.1
-- // Fyy-style UI (header chips, sidebar search, tab headers, Overview tab) + Easy API (config tables, Flags, Loop, Confirm).

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
    Version = "3.1.0",
    WhitelistedUsers = {},
    Flags = {}
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
        Card = bg:Lerp(white, 0.045),
        Input = bg:Lerp(white, 0.085),
        Hover = bg:Lerp(white, 0.12),
        Stroke = bg:Lerp(white, 0.19),
        Text = rgb(240, 240, 244),
        SubText = rgb(150, 150, 162)
    }
end

local Themes = {
    Violet = MakeTheme(rgb(145, 98, 255), rgb(5, 5, 8)),
    Ocean = MakeTheme(rgb(80, 170, 255), rgb(10, 14, 24)),
    Emerald = MakeTheme(rgb(70, 210, 150), rgb(10, 20, 17)),
    Rose = MakeTheme(rgb(255, 110, 150), rgb(24, 13, 17)),
    Amber = MakeTheme(rgb(255, 185, 70), rgb(21, 17, 11)),
    Mono = MakeTheme(rgb(235, 235, 235), rgb(14, 14, 14)),
    Cyan = MakeTheme(rgb(40, 205, 225), rgb(8, 13, 15)),
    Crimson = MakeTheme(rgb(235, 60, 70), rgb(14, 8, 9)),
    Lime = MakeTheme(rgb(150, 230, 70), rgb(10, 14, 8))
}
local ThemeOrder = {"Violet", "Ocean", "Emerald", "Rose", "Amber", "Cyan", "Crimson", "Lime", "Mono"}

local BackgroundPresets = {
    ["Midnight"] = rgb(5, 5, 8),
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
    TextLabel = {BorderSizePixel = 0, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13},
    TextButton = {BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 13},
    TextBox = {BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 13, ClearTextOnFocus = false},
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

-- // Lucide icon set (name -> asset). Use as Icon = "sword" or Icon = "lucide-sword"
local Lucide = {
  ["lucide-accessibility"] = "rbxassetid://10709751939",
  ["lucide-activity"] = "rbxassetid://10709752035",
  ["lucide-air-vent"] = "rbxassetid://10709752131",
  ["lucide-airplay"] = "rbxassetid://10709752254",
  ["lucide-alarm-check"] = "rbxassetid://10709752405",
  ["lucide-alarm-clock"] = "rbxassetid://10709752630",
  ["lucide-alarm-clock-off"] = "rbxassetid://10709752508",
  ["lucide-alarm-minus"] = "rbxassetid://10709752732",
  ["lucide-alarm-plus"] = "rbxassetid://10709752825",
  ["lucide-album"] = "rbxassetid://10709752906",
  ["lucide-alert-circle"] = "rbxassetid://10709752996",
  ["lucide-alert-octagon"] = "rbxassetid://10709753064",
  ["lucide-alert-triangle"] = "rbxassetid://10709753149",
  ["lucide-align-center"] = "rbxassetid://10709753570",
  ["lucide-align-center-horizontal"] = "rbxassetid://10709753272",
  ["lucide-align-center-vertical"] = "rbxassetid://10709753421",
  ["lucide-align-end-horizontal"] = "rbxassetid://10709753692",
  ["lucide-align-end-vertical"] = "rbxassetid://10709753808",
  ["lucide-align-horizontal-distribute-center"] = "rbxassetid://10747779791",
  ["lucide-align-horizontal-distribute-end"] = "rbxassetid://10747784534",
  ["lucide-align-horizontal-distribute-start"] = "rbxassetid://10709754118",
  ["lucide-align-horizontal-justify-center"] = "rbxassetid://10709754204",
  ["lucide-align-horizontal-justify-end"] = "rbxassetid://10709754317",
  ["lucide-align-horizontal-justify-start"] = "rbxassetid://10709754436",
  ["lucide-align-horizontal-space-around"] = "rbxassetid://10709754590",
  ["lucide-align-horizontal-space-between"] = "rbxassetid://10709754749",
  ["lucide-align-justify"] = "rbxassetid://10709759610",
  ["lucide-align-left"] = "rbxassetid://10709759764",
  ["lucide-align-right"] = "rbxassetid://10709759895",
  ["lucide-align-start-horizontal"] = "rbxassetid://10709760051",
  ["lucide-align-start-vertical"] = "rbxassetid://10709760244",
  ["lucide-align-vertical-distribute-center"] = "rbxassetid://10709760351",
  ["lucide-align-vertical-distribute-end"] = "rbxassetid://10709760434",
  ["lucide-align-vertical-distribute-start"] = "rbxassetid://10709760612",
  ["lucide-align-vertical-justify-center"] = "rbxassetid://10709760814",
  ["lucide-align-vertical-justify-end"] = "rbxassetid://10709761003",
  ["lucide-align-vertical-justify-start"] = "rbxassetid://10709761176",
  ["lucide-align-vertical-space-around"] = "rbxassetid://10709761324",
  ["lucide-align-vertical-space-between"] = "rbxassetid://10709761434",
  ["lucide-anchor"] = "rbxassetid://10709761530",
  ["lucide-angry"] = "rbxassetid://10709761629",
  ["lucide-annoyed"] = "rbxassetid://10709761722",
  ["lucide-aperture"] = "rbxassetid://10709761813",
  ["lucide-apple"] = "rbxassetid://10709761889",
  ["lucide-archive"] = "rbxassetid://10709762233",
  ["lucide-archive-restore"] = "rbxassetid://10709762058",
  ["lucide-armchair"] = "rbxassetid://10709762327",
  ["lucide-arrow-big-down"] = "rbxassetid://10747796644",
  ["lucide-arrow-big-left"] = "rbxassetid://10709762574",
  ["lucide-arrow-big-right"] = "rbxassetid://10709762727",
  ["lucide-arrow-big-up"] = "rbxassetid://10709762879",
  ["lucide-arrow-down"] = "rbxassetid://10709767827",
  ["lucide-arrow-down-circle"] = "rbxassetid://10709763034",
  ["lucide-arrow-down-left"] = "rbxassetid://10709767656",
  ["lucide-arrow-down-right"] = "rbxassetid://10709767750",
  ["lucide-arrow-left"] = "rbxassetid://10709768114",
  ["lucide-arrow-left-circle"] = "rbxassetid://10709767936",
  ["lucide-arrow-left-right"] = "rbxassetid://10709768019",
  ["lucide-arrow-right"] = "rbxassetid://10709768347",
  ["lucide-arrow-right-circle"] = "rbxassetid://10709768226",
  ["lucide-arrow-up"] = "rbxassetid://10709768939",
  ["lucide-arrow-up-circle"] = "rbxassetid://10709768432",
  ["lucide-arrow-up-down"] = "rbxassetid://10709768538",
  ["lucide-arrow-up-left"] = "rbxassetid://10709768661",
  ["lucide-arrow-up-right"] = "rbxassetid://10709768787",
  ["lucide-asterisk"] = "rbxassetid://10709769095",
  ["lucide-at-sign"] = "rbxassetid://10709769286",
  ["lucide-award"] = "rbxassetid://10709769406",
  ["lucide-axe"] = "rbxassetid://10709769508",
  ["lucide-axis-3d"] = "rbxassetid://10709769598",
  ["lucide-baby"] = "rbxassetid://10709769732",
  ["lucide-backpack"] = "rbxassetid://10709769841",
  ["lucide-baggage-claim"] = "rbxassetid://10709769935",
  ["lucide-banana"] = "rbxassetid://10709770005",
  ["lucide-banknote"] = "rbxassetid://10709770178",
  ["lucide-bar-chart"] = "rbxassetid://10709773755",
  ["lucide-bar-chart-2"] = "rbxassetid://10709770317",
  ["lucide-bar-chart-3"] = "rbxassetid://10709770431",
  ["lucide-bar-chart-4"] = "rbxassetid://10709770560",
  ["lucide-bar-chart-horizontal"] = "rbxassetid://10709773669",
  ["lucide-barcode"] = "rbxassetid://10747360675",
  ["lucide-baseline"] = "rbxassetid://10709773863",
  ["lucide-bath"] = "rbxassetid://10709773963",
  ["lucide-battery"] = "rbxassetid://10709774640",
  ["lucide-battery-charging"] = "rbxassetid://10709774068",
  ["lucide-battery-full"] = "rbxassetid://10709774206",
  ["lucide-battery-low"] = "rbxassetid://10709774370",
  ["lucide-battery-medium"] = "rbxassetid://10709774513",
  ["lucide-beaker"] = "rbxassetid://10709774756",
  ["lucide-bed"] = "rbxassetid://10709775036",
  ["lucide-bed-double"] = "rbxassetid://10709774864",
  ["lucide-bed-single"] = "rbxassetid://10709774968",
  ["lucide-beer"] = "rbxassetid://10709775167",
  ["lucide-bell"] = "rbxassetid://10709775704",
  ["lucide-bell-minus"] = "rbxassetid://10709775241",
  ["lucide-bell-off"] = "rbxassetid://10709775320",
  ["lucide-bell-plus"] = "rbxassetid://10709775448",
  ["lucide-bell-ring"] = "rbxassetid://10709775560",
  ["lucide-bike"] = "rbxassetid://10709775894",
  ["lucide-binary"] = "rbxassetid://10709776050",
  ["lucide-bitcoin"] = "rbxassetid://10709776126",
  ["lucide-bluetooth"] = "rbxassetid://10709776655",
  ["lucide-bluetooth-connected"] = "rbxassetid://10709776240",
  ["lucide-bluetooth-off"] = "rbxassetid://10709776344",
  ["lucide-bluetooth-searching"] = "rbxassetid://10709776501",
  ["lucide-bold"] = "rbxassetid://10747813908",
  ["lucide-bomb"] = "rbxassetid://10709781460",
  ["lucide-bone"] = "rbxassetid://10709781605",
  ["lucide-book"] = "rbxassetid://10709781824",
  ["lucide-book-open"] = "rbxassetid://10709781717",
  ["lucide-bookmark"] = "rbxassetid://10709782154",
  ["lucide-bookmark-minus"] = "rbxassetid://10709781919",
  ["lucide-bookmark-plus"] = "rbxassetid://10709782044",
  ["lucide-bot"] = "rbxassetid://10709782230",
  ["lucide-box"] = "rbxassetid://10709782497",
  ["lucide-box-select"] = "rbxassetid://10709782342",
  ["lucide-boxes"] = "rbxassetid://10709782582",
  ["lucide-briefcase"] = "rbxassetid://10709782662",
  ["lucide-brush"] = "rbxassetid://10709782758",
  ["lucide-bug"] = "rbxassetid://10709782845",
  ["lucide-building"] = "rbxassetid://10709783051",
  ["lucide-building-2"] = "rbxassetid://10709782939",
  ["lucide-bus"] = "rbxassetid://10709783137",
  ["lucide-cake"] = "rbxassetid://10709783217",
  ["lucide-calculator"] = "rbxassetid://10709783311",
  ["lucide-calendar"] = "rbxassetid://10709789505",
  ["lucide-calendar-check"] = "rbxassetid://10709783474",
  ["lucide-calendar-check-2"] = "rbxassetid://10709783392",
  ["lucide-calendar-clock"] = "rbxassetid://10709783577",
  ["lucide-calendar-days"] = "rbxassetid://10709783673",
  ["lucide-calendar-heart"] = "rbxassetid://10709783835",
  ["lucide-calendar-minus"] = "rbxassetid://10709783959",
  ["lucide-calendar-off"] = "rbxassetid://10709788784",
  ["lucide-calendar-plus"] = "rbxassetid://10709788937",
  ["lucide-calendar-range"] = "rbxassetid://10709789053",
  ["lucide-calendar-search"] = "rbxassetid://10709789200",
  ["lucide-calendar-x"] = "rbxassetid://10709789407",
  ["lucide-calendar-x-2"] = "rbxassetid://10709789329",
  ["lucide-camera"] = "rbxassetid://10709789686",
  ["lucide-camera-off"] = "rbxassetid://10747822677",
  ["lucide-car"] = "rbxassetid://10709789810",
  ["lucide-carrot"] = "rbxassetid://10709789960",
  ["lucide-cast"] = "rbxassetid://10709790097",
  ["lucide-charge"] = "rbxassetid://10709790202",
  ["lucide-check"] = "rbxassetid://10709790644",
  ["lucide-check-circle"] = "rbxassetid://10709790387",
  ["lucide-check-circle-2"] = "rbxassetid://10709790298",
  ["lucide-check-square"] = "rbxassetid://10709790537",
  ["lucide-chef-hat"] = "rbxassetid://10709790757",
  ["lucide-cherry"] = "rbxassetid://10709790875",
  ["lucide-chevron-down"] = "rbxassetid://10709790948",
  ["lucide-chevron-first"] = "rbxassetid://10709791015",
  ["lucide-chevron-last"] = "rbxassetid://10709791130",
  ["lucide-chevron-left"] = "rbxassetid://10709791281",
  ["lucide-chevron-right"] = "rbxassetid://10709791437",
  ["lucide-chevron-up"] = "rbxassetid://10709791523",
  ["lucide-chevrons-down"] = "rbxassetid://10709796864",
  ["lucide-chevrons-down-up"] = "rbxassetid://10709791632",
  ["lucide-chevrons-left"] = "rbxassetid://10709797151",
  ["lucide-chevrons-left-right"] = "rbxassetid://10709797006",
  ["lucide-chevrons-right"] = "rbxassetid://10709797382",
  ["lucide-chevrons-right-left"] = "rbxassetid://10709797274",
  ["lucide-chevrons-up"] = "rbxassetid://10709797622",
  ["lucide-chevrons-up-down"] = "rbxassetid://10709797508",
  ["lucide-chrome"] = "rbxassetid://10709797725",
  ["lucide-circle"] = "rbxassetid://10709798174",
  ["lucide-circle-dot"] = "rbxassetid://10709797837",
  ["lucide-circle-ellipsis"] = "rbxassetid://10709797985",
  ["lucide-circle-slashed"] = "rbxassetid://10709798100",
  ["lucide-citrus"] = "rbxassetid://10709798276",
  ["lucide-clapperboard"] = "rbxassetid://10709798350",
  ["lucide-clipboard"] = "rbxassetid://10709799288",
  ["lucide-clipboard-check"] = "rbxassetid://10709798443",
  ["lucide-clipboard-copy"] = "rbxassetid://10709798574",
  ["lucide-clipboard-edit"] = "rbxassetid://10709798682",
  ["lucide-clipboard-list"] = "rbxassetid://10709798792",
  ["lucide-clipboard-signature"] = "rbxassetid://10709798890",
  ["lucide-clipboard-type"] = "rbxassetid://10709798999",
  ["lucide-clipboard-x"] = "rbxassetid://10709799124",
  ["lucide-clock"] = "rbxassetid://10709805144",
  ["lucide-clock-1"] = "rbxassetid://10709799535",
  ["lucide-clock-10"] = "rbxassetid://10709799718",
  ["lucide-clock-11"] = "rbxassetid://10709799818",
  ["lucide-clock-12"] = "rbxassetid://10709799962",
  ["lucide-clock-2"] = "rbxassetid://10709803876",
  ["lucide-clock-3"] = "rbxassetid://10709803989",
  ["lucide-clock-4"] = "rbxassetid://10709804164",
  ["lucide-clock-5"] = "rbxassetid://10709804291",
  ["lucide-clock-6"] = "rbxassetid://10709804435",
  ["lucide-clock-7"] = "rbxassetid://10709804599",
  ["lucide-clock-8"] = "rbxassetid://10709804784",
  ["lucide-clock-9"] = "rbxassetid://10709804996",
  ["lucide-cloud"] = "rbxassetid://10709806740",
  ["lucide-cloud-cog"] = "rbxassetid://10709805262",
  ["lucide-cloud-drizzle"] = "rbxassetid://10709805371",
  ["lucide-cloud-fog"] = "rbxassetid://10709805477",
  ["lucide-cloud-hail"] = "rbxassetid://10709805596",
  ["lucide-cloud-lightning"] = "rbxassetid://10709805727",
  ["lucide-cloud-moon"] = "rbxassetid://10709805942",
  ["lucide-cloud-moon-rain"] = "rbxassetid://10709805838",
  ["lucide-cloud-off"] = "rbxassetid://10709806060",
  ["lucide-cloud-rain"] = "rbxassetid://10709806277",
  ["lucide-cloud-rain-wind"] = "rbxassetid://10709806166",
  ["lucide-cloud-snow"] = "rbxassetid://10709806374",
  ["lucide-cloud-sun"] = "rbxassetid://10709806631",
  ["lucide-cloud-sun-rain"] = "rbxassetid://10709806475",
  ["lucide-cloudy"] = "rbxassetid://10709806859",
  ["lucide-clover"] = "rbxassetid://10709806995",
  ["lucide-code"] = "rbxassetid://10709810463",
  ["lucide-code-2"] = "rbxassetid://10709807111",
  ["lucide-codepen"] = "rbxassetid://10709810534",
  ["lucide-codesandbox"] = "rbxassetid://10709810676",
  ["lucide-coffee"] = "rbxassetid://10709810814",
  ["lucide-cog"] = "rbxassetid://10709810948",
  ["lucide-coins"] = "rbxassetid://10709811110",
  ["lucide-columns"] = "rbxassetid://10709811261",
  ["lucide-command"] = "rbxassetid://10709811365",
  ["lucide-compass"] = "rbxassetid://10709811445",
  ["lucide-component"] = "rbxassetid://10709811595",
  ["lucide-concierge-bell"] = "rbxassetid://10709811706",
  ["lucide-connection"] = "rbxassetid://10747361219",
  ["lucide-contact"] = "rbxassetid://10709811834",
  ["lucide-contrast"] = "rbxassetid://10709811939",
  ["lucide-cookie"] = "rbxassetid://10709812067",
  ["lucide-copy"] = "rbxassetid://10709812159",
  ["lucide-copyleft"] = "rbxassetid://10709812251",
  ["lucide-copyright"] = "rbxassetid://10709812311",
  ["lucide-corner-down-left"] = "rbxassetid://10709812396",
  ["lucide-corner-down-right"] = "rbxassetid://10709812485",
  ["lucide-corner-left-down"] = "rbxassetid://10709812632",
  ["lucide-corner-left-up"] = "rbxassetid://10709812784",
  ["lucide-corner-right-down"] = "rbxassetid://10709812939",
  ["lucide-corner-right-up"] = "rbxassetid://10709813094",
  ["lucide-corner-up-left"] = "rbxassetid://10709813185",
  ["lucide-corner-up-right"] = "rbxassetid://10709813281",
  ["lucide-cpu"] = "rbxassetid://10709813383",
  ["lucide-croissant"] = "rbxassetid://10709818125",
  ["lucide-crop"] = "rbxassetid://10709818245",
  ["lucide-cross"] = "rbxassetid://10709818399",
  ["lucide-crosshair"] = "rbxassetid://10709818534",
  ["lucide-crown"] = "rbxassetid://10709818626",
  ["lucide-cup-soda"] = "rbxassetid://10709818763",
  ["lucide-curly-braces"] = "rbxassetid://10709818847",
  ["lucide-currency"] = "rbxassetid://10709818931",
  ["lucide-database"] = "rbxassetid://10709818996",
  ["lucide-delete"] = "rbxassetid://10709819059",
  ["lucide-diamond"] = "rbxassetid://10709819149",
  ["lucide-dice-1"] = "rbxassetid://10709819266",
  ["lucide-dice-2"] = "rbxassetid://10709819361",
  ["lucide-dice-3"] = "rbxassetid://10709819508",
  ["lucide-dice-4"] = "rbxassetid://10709819670",
  ["lucide-dice-5"] = "rbxassetid://10709819801",
  ["lucide-dice-6"] = "rbxassetid://10709819896",
  ["lucide-dices"] = "rbxassetid://10723343321",
  ["lucide-diff"] = "rbxassetid://10723343416",
  ["lucide-disc"] = "rbxassetid://10723343537",
  ["lucide-divide"] = "rbxassetid://10723343805",
  ["lucide-divide-circle"] = "rbxassetid://10723343636",
  ["lucide-divide-square"] = "rbxassetid://10723343737",
  ["lucide-dollar-sign"] = "rbxassetid://10723343958",
  ["lucide-download"] = "rbxassetid://10723344270",
  ["lucide-download-cloud"] = "rbxassetid://10723344088",
  ["lucide-droplet"] = "rbxassetid://10723344432",
  ["lucide-droplets"] = "rbxassetid://10734883356",
  ["lucide-drumstick"] = "rbxassetid://10723344737",
  ["lucide-edit"] = "rbxassetid://10734883598",
  ["lucide-edit-2"] = "rbxassetid://10723344885",
  ["lucide-edit-3"] = "rbxassetid://10723345088",
  ["lucide-egg"] = "rbxassetid://10723345518",
  ["lucide-egg-fried"] = "rbxassetid://10723345347",
  ["lucide-electricity"] = "rbxassetid://10723345749",
  ["lucide-electricity-off"] = "rbxassetid://10723345643",
  ["lucide-equal"] = "rbxassetid://10723345990",
  ["lucide-equal-not"] = "rbxassetid://10723345866",
  ["lucide-eraser"] = "rbxassetid://10723346158",
  ["lucide-euro"] = "rbxassetid://10723346372",
  ["lucide-expand"] = "rbxassetid://10723346553",
  ["lucide-external-link"] = "rbxassetid://10723346684",
  ["lucide-eye"] = "rbxassetid://10723346959",
  ["lucide-eye-off"] = "rbxassetid://10723346871",
  ["lucide-factory"] = "rbxassetid://10723347051",
  ["lucide-fan"] = "rbxassetid://10723354359",
  ["lucide-fast-forward"] = "rbxassetid://10723354521",
  ["lucide-feather"] = "rbxassetid://10723354671",
  ["lucide-figma"] = "rbxassetid://10723354801",
  ["lucide-file"] = "rbxassetid://10723374641",
  ["lucide-file-archive"] = "rbxassetid://10723354921",
  ["lucide-file-audio"] = "rbxassetid://10723355148",
  ["lucide-file-audio-2"] = "rbxassetid://10723355026",
  ["lucide-file-axis-3d"] = "rbxassetid://10723355272",
  ["lucide-file-badge"] = "rbxassetid://10723355622",
  ["lucide-file-badge-2"] = "rbxassetid://10723355451",
  ["lucide-file-bar-chart"] = "rbxassetid://10723355887",
  ["lucide-file-bar-chart-2"] = "rbxassetid://10723355746",
  ["lucide-file-box"] = "rbxassetid://10723355989",
  ["lucide-file-check"] = "rbxassetid://10723356210",
  ["lucide-file-check-2"] = "rbxassetid://10723356100",
  ["lucide-file-clock"] = "rbxassetid://10723356329",
  ["lucide-file-code"] = "rbxassetid://10723356507",
  ["lucide-file-cog"] = "rbxassetid://10723356830",
  ["lucide-file-cog-2"] = "rbxassetid://10723356676",
  ["lucide-file-diff"] = "rbxassetid://10723357039",
  ["lucide-file-digit"] = "rbxassetid://10723357151",
  ["lucide-file-down"] = "rbxassetid://10723357322",
  ["lucide-file-edit"] = "rbxassetid://10723357495",
  ["lucide-file-heart"] = "rbxassetid://10723357637",
  ["lucide-file-image"] = "rbxassetid://10723357790",
  ["lucide-file-input"] = "rbxassetid://10723357933",
  ["lucide-file-json"] = "rbxassetid://10723364435",
  ["lucide-file-json-2"] = "rbxassetid://10723364361",
  ["lucide-file-key"] = "rbxassetid://10723364605",
  ["lucide-file-key-2"] = "rbxassetid://10723364515",
  ["lucide-file-line-chart"] = "rbxassetid://10723364725",
  ["lucide-file-lock"] = "rbxassetid://10723364957",
  ["lucide-file-lock-2"] = "rbxassetid://10723364861",
  ["lucide-file-minus"] = "rbxassetid://10723365254",
  ["lucide-file-minus-2"] = "rbxassetid://10723365086",
  ["lucide-file-output"] = "rbxassetid://10723365457",
  ["lucide-file-pie-chart"] = "rbxassetid://10723365598",
  ["lucide-file-plus"] = "rbxassetid://10723365877",
  ["lucide-file-plus-2"] = "rbxassetid://10723365766",
  ["lucide-file-question"] = "rbxassetid://10723365987",
  ["lucide-file-scan"] = "rbxassetid://10723366167",
  ["lucide-file-search"] = "rbxassetid://10723366550",
  ["lucide-file-search-2"] = "rbxassetid://10723366340",
  ["lucide-file-signature"] = "rbxassetid://10723366741",
  ["lucide-file-spreadsheet"] = "rbxassetid://10723366962",
  ["lucide-file-symlink"] = "rbxassetid://10723367098",
  ["lucide-file-terminal"] = "rbxassetid://10723367244",
  ["lucide-file-text"] = "rbxassetid://10723367380",
  ["lucide-file-type"] = "rbxassetid://10723367606",
  ["lucide-file-type-2"] = "rbxassetid://10723367509",
  ["lucide-file-up"] = "rbxassetid://10723367734",
  ["lucide-file-video"] = "rbxassetid://10723373884",
  ["lucide-file-video-2"] = "rbxassetid://10723367834",
  ["lucide-file-volume"] = "rbxassetid://10723374172",
  ["lucide-file-volume-2"] = "rbxassetid://10723374030",
  ["lucide-file-warning"] = "rbxassetid://10723374276",
  ["lucide-file-x"] = "rbxassetid://10723374544",
  ["lucide-file-x-2"] = "rbxassetid://10723374378",
  ["lucide-files"] = "rbxassetid://10723374759",
  ["lucide-film"] = "rbxassetid://10723374981",
  ["lucide-filter"] = "rbxassetid://10723375128",
  ["lucide-fingerprint"] = "rbxassetid://10723375250",
  ["lucide-flag"] = "rbxassetid://10723375890",
  ["lucide-flag-off"] = "rbxassetid://10723375443",
  ["lucide-flag-triangle-left"] = "rbxassetid://10723375608",
  ["lucide-flag-triangle-right"] = "rbxassetid://10723375727",
  ["lucide-flame"] = "rbxassetid://10723376114",
  ["lucide-flashlight"] = "rbxassetid://10723376471",
  ["lucide-flashlight-off"] = "rbxassetid://10723376365",
  ["lucide-flask-conical"] = "rbxassetid://10734883986",
  ["lucide-flask-round"] = "rbxassetid://10723376614",
  ["lucide-flip-horizontal"] = "rbxassetid://10723376884",
  ["lucide-flip-horizontal-2"] = "rbxassetid://10723376745",
  ["lucide-flip-vertical"] = "rbxassetid://10723377138",
  ["lucide-flip-vertical-2"] = "rbxassetid://10723377026",
  ["lucide-flower"] = "rbxassetid://10747830374",
  ["lucide-flower-2"] = "rbxassetid://10723377305",
  ["lucide-focus"] = "rbxassetid://10723377537",
  ["lucide-folder"] = "rbxassetid://10723387563",
  ["lucide-folder-archive"] = "rbxassetid://10723384478",
  ["lucide-folder-check"] = "rbxassetid://10723384605",
  ["lucide-folder-clock"] = "rbxassetid://10723384731",
  ["lucide-folder-closed"] = "rbxassetid://10723384893",
  ["lucide-folder-cog"] = "rbxassetid://10723385213",
  ["lucide-folder-cog-2"] = "rbxassetid://10723385036",
  ["lucide-folder-down"] = "rbxassetid://10723385338",
  ["lucide-folder-edit"] = "rbxassetid://10723385445",
  ["lucide-folder-heart"] = "rbxassetid://10723385545",
  ["lucide-folder-input"] = "rbxassetid://10723385721",
  ["lucide-folder-key"] = "rbxassetid://10723385848",
  ["lucide-folder-lock"] = "rbxassetid://10723386005",
  ["lucide-folder-minus"] = "rbxassetid://10723386127",
  ["lucide-folder-open"] = "rbxassetid://10723386277",
  ["lucide-folder-output"] = "rbxassetid://10723386386",
  ["lucide-folder-plus"] = "rbxassetid://10723386531",
  ["lucide-folder-search"] = "rbxassetid://10723386787",
  ["lucide-folder-search-2"] = "rbxassetid://10723386674",
  ["lucide-folder-symlink"] = "rbxassetid://10723386930",
  ["lucide-folder-tree"] = "rbxassetid://10723387085",
  ["lucide-folder-up"] = "rbxassetid://10723387265",
  ["lucide-folder-x"] = "rbxassetid://10723387448",
  ["lucide-folders"] = "rbxassetid://10723387721",
  ["lucide-form-input"] = "rbxassetid://10723387841",
  ["lucide-forward"] = "rbxassetid://10723388016",
  ["lucide-frame"] = "rbxassetid://10723394389",
  ["lucide-framer"] = "rbxassetid://10723394565",
  ["lucide-frown"] = "rbxassetid://10723394681",
  ["lucide-fuel"] = "rbxassetid://10723394846",
  ["lucide-function-square"] = "rbxassetid://10723395041",
  ["lucide-gamepad"] = "rbxassetid://10723395457",
  ["lucide-gamepad-2"] = "rbxassetid://10723395215",
  ["lucide-gauge"] = "rbxassetid://10723395708",
  ["lucide-gavel"] = "rbxassetid://10723395896",
  ["lucide-gem"] = "rbxassetid://10723396000",
  ["lucide-ghost"] = "rbxassetid://10723396107",
  ["lucide-gift"] = "rbxassetid://10723396402",
  ["lucide-gift-card"] = "rbxassetid://10723396225",
  ["lucide-git-branch"] = "rbxassetid://10723396676",
  ["lucide-git-branch-plus"] = "rbxassetid://10723396542",
  ["lucide-git-commit"] = "rbxassetid://10723396812",
  ["lucide-git-compare"] = "rbxassetid://10723396954",
  ["lucide-git-fork"] = "rbxassetid://10723397049",
  ["lucide-git-merge"] = "rbxassetid://10723397165",
  ["lucide-git-pull-request"] = "rbxassetid://10723397431",
  ["lucide-git-pull-request-closed"] = "rbxassetid://10723397268",
  ["lucide-git-pull-request-draft"] = "rbxassetid://10734884302",
  ["lucide-glass"] = "rbxassetid://10723397788",
  ["lucide-glass-2"] = "rbxassetid://10723397529",
  ["lucide-glass-water"] = "rbxassetid://10723397678",
  ["lucide-glasses"] = "rbxassetid://10723397895",
  ["lucide-globe"] = "rbxassetid://10723404337",
  ["lucide-globe-2"] = "rbxassetid://10723398002",
  ["lucide-grab"] = "rbxassetid://10723404472",
  ["lucide-graduation-cap"] = "rbxassetid://10723404691",
  ["lucide-grape"] = "rbxassetid://10723404822",
  ["lucide-grid"] = "rbxassetid://10723404936",
  ["lucide-grip-horizontal"] = "rbxassetid://10723405089",
  ["lucide-grip-vertical"] = "rbxassetid://10723405236",
  ["lucide-hammer"] = "rbxassetid://10723405360",
  ["lucide-hand"] = "rbxassetid://10723405649",
  ["lucide-hand-metal"] = "rbxassetid://10723405508",
  ["lucide-hard-drive"] = "rbxassetid://10723405749",
  ["lucide-hard-hat"] = "rbxassetid://10723405859",
  ["lucide-hash"] = "rbxassetid://10723405975",
  ["lucide-haze"] = "rbxassetid://10723406078",
  ["lucide-headphones"] = "rbxassetid://10723406165",
  ["lucide-heart"] = "rbxassetid://10723406885",
  ["lucide-heart-crack"] = "rbxassetid://10723406299",
  ["lucide-heart-handshake"] = "rbxassetid://10723406480",
  ["lucide-heart-off"] = "rbxassetid://10723406662",
  ["lucide-heart-pulse"] = "rbxassetid://10723406795",
  ["lucide-help-circle"] = "rbxassetid://10723406988",
  ["lucide-hexagon"] = "rbxassetid://10723407092",
  ["lucide-highlighter"] = "rbxassetid://10723407192",
  ["lucide-history"] = "rbxassetid://10723407335",
  ["lucide-home"] = "rbxassetid://10723407389",
  ["lucide-hourglass"] = "rbxassetid://10723407498",
  ["lucide-ice-cream"] = "rbxassetid://10723414308",
  ["lucide-image"] = "rbxassetid://10723415040",
  ["lucide-image-minus"] = "rbxassetid://10723414487",
  ["lucide-image-off"] = "rbxassetid://10723414677",
  ["lucide-image-plus"] = "rbxassetid://10723414827",
  ["lucide-import"] = "rbxassetid://10723415205",
  ["lucide-inbox"] = "rbxassetid://10723415335",
  ["lucide-indent"] = "rbxassetid://10723415494",
  ["lucide-indian-rupee"] = "rbxassetid://10723415642",
  ["lucide-infinity"] = "rbxassetid://10723415766",
  ["lucide-info"] = "rbxassetid://10723415903",
  ["lucide-inspect"] = "rbxassetid://10723416057",
  ["lucide-italic"] = "rbxassetid://10723416195",
  ["lucide-japanese-yen"] = "rbxassetid://10723416363",
  ["lucide-joystick"] = "rbxassetid://10723416527",
  ["lucide-key"] = "rbxassetid://10723416652",
  ["lucide-keyboard"] = "rbxassetid://10723416765",
  ["lucide-lamp"] = "rbxassetid://10723417513",
  ["lucide-lamp-ceiling"] = "rbxassetid://10723416922",
  ["lucide-lamp-desk"] = "rbxassetid://10723417016",
  ["lucide-lamp-floor"] = "rbxassetid://10723417131",
  ["lucide-lamp-wall-down"] = "rbxassetid://10723417240",
  ["lucide-lamp-wall-up"] = "rbxassetid://10723417356",
  ["lucide-landmark"] = "rbxassetid://10723417608",
  ["lucide-languages"] = "rbxassetid://10723417703",
  ["lucide-laptop"] = "rbxassetid://10723423881",
  ["lucide-laptop-2"] = "rbxassetid://10723417797",
  ["lucide-lasso"] = "rbxassetid://10723424235",
  ["lucide-lasso-select"] = "rbxassetid://10723424058",
  ["lucide-laugh"] = "rbxassetid://10723424372",
  ["lucide-layers"] = "rbxassetid://10723424505",
  ["lucide-layout"] = "rbxassetid://10723425376",
  ["lucide-layout-dashboard"] = "rbxassetid://10723424646",
  ["lucide-layout-grid"] = "rbxassetid://10723424838",
  ["lucide-layout-list"] = "rbxassetid://10723424963",
  ["lucide-layout-template"] = "rbxassetid://10723425187",
  ["lucide-leaf"] = "rbxassetid://10723425539",
  ["lucide-library"] = "rbxassetid://10723425615",
  ["lucide-life-buoy"] = "rbxassetid://10723425685",
  ["lucide-lightbulb"] = "rbxassetid://10723425852",
  ["lucide-lightbulb-off"] = "rbxassetid://10723425762",
  ["lucide-line-chart"] = "rbxassetid://10723426393",
  ["lucide-link"] = "rbxassetid://10723426722",
  ["lucide-link-2"] = "rbxassetid://10723426595",
  ["lucide-link-2-off"] = "rbxassetid://10723426513",
  ["lucide-list"] = "rbxassetid://10723433811",
  ["lucide-list-checks"] = "rbxassetid://10734884548",
  ["lucide-list-end"] = "rbxassetid://10723426886",
  ["lucide-list-minus"] = "rbxassetid://10723426986",
  ["lucide-list-music"] = "rbxassetid://10723427081",
  ["lucide-list-ordered"] = "rbxassetid://10723427199",
  ["lucide-list-plus"] = "rbxassetid://10723427334",
  ["lucide-list-start"] = "rbxassetid://10723427494",
  ["lucide-list-video"] = "rbxassetid://10723427619",
  ["lucide-list-x"] = "rbxassetid://10723433655",
  ["lucide-loader"] = "rbxassetid://10723434070",
  ["lucide-loader-2"] = "rbxassetid://10723433935",
  ["lucide-locate"] = "rbxassetid://10723434557",
  ["lucide-locate-fixed"] = "rbxassetid://10723434236",
  ["lucide-locate-off"] = "rbxassetid://10723434379",
  ["lucide-lock"] = "rbxassetid://10723434711",
  ["lucide-log-in"] = "rbxassetid://10723434830",
  ["lucide-log-out"] = "rbxassetid://10723434906",
  ["lucide-luggage"] = "rbxassetid://10723434993",
  ["lucide-magnet"] = "rbxassetid://10723435069",
  ["lucide-mail"] = "rbxassetid://10734885430",
  ["lucide-mail-check"] = "rbxassetid://10723435182",
  ["lucide-mail-minus"] = "rbxassetid://10723435261",
  ["lucide-mail-open"] = "rbxassetid://10723435342",
  ["lucide-mail-plus"] = "rbxassetid://10723435443",
  ["lucide-mail-question"] = "rbxassetid://10723435515",
  ["lucide-mail-search"] = "rbxassetid://10734884739",
  ["lucide-mail-warning"] = "rbxassetid://10734885015",
  ["lucide-mail-x"] = "rbxassetid://10734885247",
  ["lucide-mails"] = "rbxassetid://10734885614",
  ["lucide-map"] = "rbxassetid://10734886202",
  ["lucide-map-pin"] = "rbxassetid://10734886004",
  ["lucide-map-pin-off"] = "rbxassetid://10734885803",
  ["lucide-maximize"] = "rbxassetid://10734886735",
  ["lucide-maximize-2"] = "rbxassetid://10734886496",
  ["lucide-medal"] = "rbxassetid://10734887072",
  ["lucide-megaphone"] = "rbxassetid://10734887454",
  ["lucide-megaphone-off"] = "rbxassetid://10734887311",
  ["lucide-meh"] = "rbxassetid://10734887603",
  ["lucide-menu"] = "rbxassetid://10734887784",
  ["lucide-message-circle"] = "rbxassetid://10734888000",
  ["lucide-message-square"] = "rbxassetid://10734888228",
  ["lucide-mic"] = "rbxassetid://10734888864",
  ["lucide-mic-2"] = "rbxassetid://10734888430",
  ["lucide-mic-off"] = "rbxassetid://10734888646",
  ["lucide-microscope"] = "rbxassetid://10734889106",
  ["lucide-microwave"] = "rbxassetid://10734895076",
  ["lucide-milestone"] = "rbxassetid://10734895310",
  ["lucide-minimize"] = "rbxassetid://10734895698",
  ["lucide-minimize-2"] = "rbxassetid://10734895530",
  ["lucide-minus"] = "rbxassetid://10734896206",
  ["lucide-minus-circle"] = "rbxassetid://10734895856",
  ["lucide-minus-square"] = "rbxassetid://10734896029",
  ["lucide-monitor"] = "rbxassetid://10734896881",
  ["lucide-monitor-off"] = "rbxassetid://10734896360",
  ["lucide-monitor-speaker"] = "rbxassetid://10734896512",
  ["lucide-moon"] = "rbxassetid://10734897102",
  ["lucide-more-horizontal"] = "rbxassetid://10734897250",
  ["lucide-more-vertical"] = "rbxassetid://10734897387",
  ["lucide-mountain"] = "rbxassetid://10734897956",
  ["lucide-mountain-snow"] = "rbxassetid://10734897665",
  ["lucide-mouse"] = "rbxassetid://10734898592",
  ["lucide-mouse-pointer"] = "rbxassetid://10734898476",
  ["lucide-mouse-pointer-2"] = "rbxassetid://10734898194",
  ["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
  ["lucide-move"] = "rbxassetid://10734900011",
  ["lucide-move-3d"] = "rbxassetid://10734898756",
  ["lucide-move-diagonal"] = "rbxassetid://10734899164",
  ["lucide-move-diagonal-2"] = "rbxassetid://10734898934",
  ["lucide-move-horizontal"] = "rbxassetid://10734899414",
  ["lucide-move-vertical"] = "rbxassetid://10734899821",
  ["lucide-music"] = "rbxassetid://10734905958",
  ["lucide-music-2"] = "rbxassetid://10734900215",
  ["lucide-music-3"] = "rbxassetid://10734905665",
  ["lucide-music-4"] = "rbxassetid://10734905823",
  ["lucide-navigation"] = "rbxassetid://10734906744",
  ["lucide-navigation-2"] = "rbxassetid://10734906332",
  ["lucide-navigation-2-off"] = "rbxassetid://10734906144",
  ["lucide-navigation-off"] = "rbxassetid://10734906580",
  ["lucide-network"] = "rbxassetid://10734906975",
  ["lucide-newspaper"] = "rbxassetid://10734907168",
  ["lucide-octagon"] = "rbxassetid://10734907361",
  ["lucide-option"] = "rbxassetid://10734907649",
  ["lucide-outdent"] = "rbxassetid://10734907933",
  ["lucide-package"] = "rbxassetid://10734909540",
  ["lucide-package-2"] = "rbxassetid://10734908151",
  ["lucide-package-check"] = "rbxassetid://10734908384",
  ["lucide-package-minus"] = "rbxassetid://10734908626",
  ["lucide-package-open"] = "rbxassetid://10734908793",
  ["lucide-package-plus"] = "rbxassetid://10734909016",
  ["lucide-package-search"] = "rbxassetid://10734909196",
  ["lucide-package-x"] = "rbxassetid://10734909375",
  ["lucide-paint-bucket"] = "rbxassetid://10734909847",
  ["lucide-paintbrush"] = "rbxassetid://10734910187",
  ["lucide-paintbrush-2"] = "rbxassetid://10734910030",
  ["lucide-palette"] = "rbxassetid://10734910430",
  ["lucide-palmtree"] = "rbxassetid://10734910680",
  ["lucide-paperclip"] = "rbxassetid://10734910927",
  ["lucide-party-popper"] = "rbxassetid://10734918735",
  ["lucide-pause"] = "rbxassetid://10734919336",
  ["lucide-pause-circle"] = "rbxassetid://10735024209",
  ["lucide-pause-octagon"] = "rbxassetid://10734919143",
  ["lucide-pen-tool"] = "rbxassetid://10734919503",
  ["lucide-pencil"] = "rbxassetid://10734919691",
  ["lucide-percent"] = "rbxassetid://10734919919",
  ["lucide-person-standing"] = "rbxassetid://10734920149",
  ["lucide-phone"] = "rbxassetid://10734921524",
  ["lucide-phone-call"] = "rbxassetid://10734920305",
  ["lucide-phone-forwarded"] = "rbxassetid://10734920508",
  ["lucide-phone-incoming"] = "rbxassetid://10734920694",
  ["lucide-phone-missed"] = "rbxassetid://10734920845",
  ["lucide-phone-off"] = "rbxassetid://10734921077",
  ["lucide-phone-outgoing"] = "rbxassetid://10734921288",
  ["lucide-pie-chart"] = "rbxassetid://10734921727",
  ["lucide-piggy-bank"] = "rbxassetid://10734921935",
  ["lucide-pin"] = "rbxassetid://10734922324",
  ["lucide-pin-off"] = "rbxassetid://10734922180",
  ["lucide-pipette"] = "rbxassetid://10734922497",
  ["lucide-pizza"] = "rbxassetid://10734922774",
  ["lucide-plane"] = "rbxassetid://10734922971",
  ["lucide-play"] = "rbxassetid://10734923549",
  ["lucide-play-circle"] = "rbxassetid://10734923214",
  ["lucide-plus"] = "rbxassetid://10734924532",
  ["lucide-plus-circle"] = "rbxassetid://10734923868",
  ["lucide-plus-square"] = "rbxassetid://10734924219",
  ["lucide-podcast"] = "rbxassetid://10734929553",
  ["lucide-pointer"] = "rbxassetid://10734929723",
  ["lucide-pound-sterling"] = "rbxassetid://10734929981",
  ["lucide-power"] = "rbxassetid://10734930466",
  ["lucide-power-off"] = "rbxassetid://10734930257",
  ["lucide-printer"] = "rbxassetid://10734930632",
  ["lucide-puzzle"] = "rbxassetid://10734930886",
  ["lucide-quote"] = "rbxassetid://10734931234",
  ["lucide-radio"] = "rbxassetid://10734931596",
  ["lucide-radio-receiver"] = "rbxassetid://10734931402",
  ["lucide-rectangle-horizontal"] = "rbxassetid://10734931777",
  ["lucide-rectangle-vertical"] = "rbxassetid://10734932081",
  ["lucide-recycle"] = "rbxassetid://10734932295",
  ["lucide-redo"] = "rbxassetid://10734932822",
  ["lucide-redo-2"] = "rbxassetid://10734932586",
  ["lucide-refresh-ccw"] = "rbxassetid://10734933056",
  ["lucide-refresh-cw"] = "rbxassetid://10734933222",
  ["lucide-refrigerator"] = "rbxassetid://10734933465",
  ["lucide-regex"] = "rbxassetid://10734933655",
  ["lucide-repeat"] = "rbxassetid://10734933966",
  ["lucide-repeat-1"] = "rbxassetid://10734933826",
  ["lucide-reply"] = "rbxassetid://10734934252",
  ["lucide-reply-all"] = "rbxassetid://10734934132",
  ["lucide-rewind"] = "rbxassetid://10734934347",
  ["lucide-rocket"] = "rbxassetid://10734934585",
  ["lucide-rocking-chair"] = "rbxassetid://10734939942",
  ["lucide-rotate-3d"] = "rbxassetid://10734940107",
  ["lucide-rotate-ccw"] = "rbxassetid://10734940376",
  ["lucide-rotate-cw"] = "rbxassetid://10734940654",
  ["lucide-rss"] = "rbxassetid://10734940825",
  ["lucide-ruler"] = "rbxassetid://10734941018",
  ["lucide-russian-ruble"] = "rbxassetid://10734941199",
  ["lucide-sailboat"] = "rbxassetid://10734941354",
  ["lucide-save"] = "rbxassetid://10734941499",
  ["lucide-scale"] = "rbxassetid://10734941912",
  ["lucide-scale-3d"] = "rbxassetid://10734941739",
  ["lucide-scaling"] = "rbxassetid://10734942072",
  ["lucide-scan"] = "rbxassetid://10734942565",
  ["lucide-scan-face"] = "rbxassetid://10734942198",
  ["lucide-scan-line"] = "rbxassetid://10734942351",
  ["lucide-scissors"] = "rbxassetid://10734942778",
  ["lucide-screen-share"] = "rbxassetid://10734943193",
  ["lucide-screen-share-off"] = "rbxassetid://10734942967",
  ["lucide-scroll"] = "rbxassetid://10734943448",
  ["lucide-search"] = "rbxassetid://10734943674",
  ["lucide-send"] = "rbxassetid://10734943902",
  ["lucide-separator-horizontal"] = "rbxassetid://10734944115",
  ["lucide-separator-vertical"] = "rbxassetid://10734944326",
  ["lucide-server"] = "rbxassetid://10734949856",
  ["lucide-server-cog"] = "rbxassetid://10734944444",
  ["lucide-server-crash"] = "rbxassetid://10734944554",
  ["lucide-server-off"] = "rbxassetid://10734944668",
  ["lucide-settings"] = "rbxassetid://10734950309",
  ["lucide-settings-2"] = "rbxassetid://10734950020",
  ["lucide-share"] = "rbxassetid://10734950813",
  ["lucide-share-2"] = "rbxassetid://10734950553",
  ["lucide-sheet"] = "rbxassetid://10734951038",
  ["lucide-shield"] = "rbxassetid://10734951847",
  ["lucide-shield-alert"] = "rbxassetid://10734951173",
  ["lucide-shield-check"] = "rbxassetid://10734951367",
  ["lucide-shield-close"] = "rbxassetid://10734951535",
  ["lucide-shield-off"] = "rbxassetid://10734951684",
  ["lucide-shirt"] = "rbxassetid://10734952036",
  ["lucide-shopping-bag"] = "rbxassetid://10734952273",
  ["lucide-shopping-cart"] = "rbxassetid://10734952479",
  ["lucide-shovel"] = "rbxassetid://10734952773",
  ["lucide-shower-head"] = "rbxassetid://10734952942",
  ["lucide-shrink"] = "rbxassetid://10734953073",
  ["lucide-shrub"] = "rbxassetid://10734953241",
  ["lucide-shuffle"] = "rbxassetid://10734953451",
  ["lucide-sidebar"] = "rbxassetid://10734954301",
  ["lucide-sidebar-close"] = "rbxassetid://10734953715",
  ["lucide-sidebar-open"] = "rbxassetid://10734954000",
  ["lucide-sigma"] = "rbxassetid://10734954538",
  ["lucide-signal"] = "rbxassetid://10734961133",
  ["lucide-signal-high"] = "rbxassetid://10734954807",
  ["lucide-signal-low"] = "rbxassetid://10734955080",
  ["lucide-signal-medium"] = "rbxassetid://10734955336",
  ["lucide-signal-zero"] = "rbxassetid://10734960878",
  ["lucide-siren"] = "rbxassetid://10734961284",
  ["lucide-skip-back"] = "rbxassetid://10734961526",
  ["lucide-skip-forward"] = "rbxassetid://10734961809",
  ["lucide-skull"] = "rbxassetid://10734962068",
  ["lucide-slack"] = "rbxassetid://10734962339",
  ["lucide-slash"] = "rbxassetid://10734962600",
  ["lucide-slice"] = "rbxassetid://10734963024",
  ["lucide-sliders"] = "rbxassetid://10734963400",
  ["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
  ["lucide-smartphone"] = "rbxassetid://10734963940",
  ["lucide-smartphone-charging"] = "rbxassetid://10734963671",
  ["lucide-smile"] = "rbxassetid://10734964441",
  ["lucide-smile-plus"] = "rbxassetid://10734964188",
  ["lucide-snowflake"] = "rbxassetid://10734964600",
  ["lucide-sofa"] = "rbxassetid://10734964852",
  ["lucide-sort-asc"] = "rbxassetid://10734965115",
  ["lucide-sort-desc"] = "rbxassetid://10734965287",
  ["lucide-speaker"] = "rbxassetid://10734965419",
  ["lucide-sprout"] = "rbxassetid://10734965572",
  ["lucide-square"] = "rbxassetid://10734965702",
  ["lucide-star"] = "rbxassetid://10734966248",
  ["lucide-star-half"] = "rbxassetid://10734965897",
  ["lucide-star-off"] = "rbxassetid://10734966097",
  ["lucide-stethoscope"] = "rbxassetid://10734966384",
  ["lucide-sticker"] = "rbxassetid://10734972234",
  ["lucide-sticky-note"] = "rbxassetid://10734972463",
  ["lucide-stop-circle"] = "rbxassetid://10734972621",
  ["lucide-stretch-horizontal"] = "rbxassetid://10734972862",
  ["lucide-stretch-vertical"] = "rbxassetid://10734973130",
  ["lucide-strikethrough"] = "rbxassetid://10734973290",
  ["lucide-subscript"] = "rbxassetid://10734973457",
  ["lucide-sun"] = "rbxassetid://10734974297",
  ["lucide-sun-dim"] = "rbxassetid://10734973645",
  ["lucide-sun-medium"] = "rbxassetid://10734973778",
  ["lucide-sun-moon"] = "rbxassetid://10734973999",
  ["lucide-sun-snow"] = "rbxassetid://10734974130",
  ["lucide-sunrise"] = "rbxassetid://10734974522",
  ["lucide-sunset"] = "rbxassetid://10734974689",
  ["lucide-superscript"] = "rbxassetid://10734974850",
  ["lucide-swiss-franc"] = "rbxassetid://10734975024",
  ["lucide-switch-camera"] = "rbxassetid://10734975214",
  ["lucide-sword"] = "rbxassetid://10734975486",
  ["lucide-swords"] = "rbxassetid://10734975692",
  ["lucide-syringe"] = "rbxassetid://10734975932",
  ["lucide-table"] = "rbxassetid://10734976230",
  ["lucide-table-2"] = "rbxassetid://10734976097",
  ["lucide-tablet"] = "rbxassetid://10734976394",
  ["lucide-tag"] = "rbxassetid://10734976528",
  ["lucide-tags"] = "rbxassetid://10734976739",
  ["lucide-target"] = "rbxassetid://10734977012",
  ["lucide-tent"] = "rbxassetid://10734981750",
  ["lucide-terminal"] = "rbxassetid://10734982144",
  ["lucide-terminal-square"] = "rbxassetid://10734981995",
  ["lucide-text-cursor"] = "rbxassetid://10734982395",
  ["lucide-text-cursor-input"] = "rbxassetid://10734982297",
  ["lucide-thermometer"] = "rbxassetid://10734983134",
  ["lucide-thermometer-snowflake"] = "rbxassetid://10734982571",
  ["lucide-thermometer-sun"] = "rbxassetid://10734982771",
  ["lucide-thumbs-down"] = "rbxassetid://10734983359",
  ["lucide-thumbs-up"] = "rbxassetid://10734983629",
  ["lucide-ticket"] = "rbxassetid://10734983868",
  ["lucide-timer"] = "rbxassetid://10734984606",
  ["lucide-timer-off"] = "rbxassetid://10734984138",
  ["lucide-timer-reset"] = "rbxassetid://10734984355",
  ["lucide-toggle-left"] = "rbxassetid://10734984834",
  ["lucide-toggle-right"] = "rbxassetid://10734985040",
  ["lucide-tornado"] = "rbxassetid://10734985247",
  ["lucide-toy-brick"] = "rbxassetid://10747361919",
  ["lucide-train"] = "rbxassetid://10747362105",
  ["lucide-trash"] = "rbxassetid://10747362393",
  ["lucide-trash-2"] = "rbxassetid://10747362241",
  ["lucide-tree-deciduous"] = "rbxassetid://10747362534",
  ["lucide-tree-pine"] = "rbxassetid://10747362748",
  ["lucide-trees"] = "rbxassetid://10747363016",
  ["lucide-trending-down"] = "rbxassetid://10747363205",
  ["lucide-trending-up"] = "rbxassetid://10747363465",
  ["lucide-triangle"] = "rbxassetid://10747363621",
  ["lucide-trophy"] = "rbxassetid://10747363809",
  ["lucide-truck"] = "rbxassetid://10747364031",
  ["lucide-tv"] = "rbxassetid://10747364593",
  ["lucide-tv-2"] = "rbxassetid://10747364302",
  ["lucide-type"] = "rbxassetid://10747364761",
  ["lucide-umbrella"] = "rbxassetid://10747364971",
  ["lucide-underline"] = "rbxassetid://10747365191",
  ["lucide-undo"] = "rbxassetid://10747365484",
  ["lucide-undo-2"] = "rbxassetid://10747365359",
  ["lucide-unlink"] = "rbxassetid://10747365771",
  ["lucide-unlink-2"] = "rbxassetid://10747397871",
  ["lucide-unlock"] = "rbxassetid://10747366027",
  ["lucide-upload"] = "rbxassetid://10747366434",
  ["lucide-upload-cloud"] = "rbxassetid://10747366266",
  ["lucide-usb"] = "rbxassetid://10747366606",
  ["lucide-user"] = "rbxassetid://10747373176",
  ["lucide-user-check"] = "rbxassetid://10747371901",
  ["lucide-user-cog"] = "rbxassetid://10747372167",
  ["lucide-user-minus"] = "rbxassetid://10747372346",
  ["lucide-user-plus"] = "rbxassetid://10747372702",
  ["lucide-user-x"] = "rbxassetid://10747372992",
  ["lucide-users"] = "rbxassetid://10747373426",
  ["lucide-utensils"] = "rbxassetid://10747373821",
  ["lucide-utensils-crossed"] = "rbxassetid://10747373629",
  ["lucide-venetian-mask"] = "rbxassetid://10747374003",
  ["lucide-verified"] = "rbxassetid://10747374131",
  ["lucide-vibrate"] = "rbxassetid://10747374489",
  ["lucide-vibrate-off"] = "rbxassetid://10747374269",
  ["lucide-video"] = "rbxassetid://10747374938",
  ["lucide-video-off"] = "rbxassetid://10747374721",
  ["lucide-view"] = "rbxassetid://10747375132",
  ["lucide-voicemail"] = "rbxassetid://10747375281",
  ["lucide-volume"] = "rbxassetid://10747376008",
  ["lucide-volume-1"] = "rbxassetid://10747375450",
  ["lucide-volume-2"] = "rbxassetid://10747375679",
  ["lucide-volume-x"] = "rbxassetid://10747375880",
  ["lucide-wallet"] = "rbxassetid://10747376205",
  ["lucide-wand"] = "rbxassetid://10747376565",
  ["lucide-wand-2"] = "rbxassetid://10747376349",
  ["lucide-watch"] = "rbxassetid://10747376722",
  ["lucide-waves"] = "rbxassetid://10747376931",
  ["lucide-webcam"] = "rbxassetid://10747381992",
  ["lucide-wifi"] = "rbxassetid://10747382504",
  ["lucide-wifi-off"] = "rbxassetid://10747382268",
  ["lucide-wind"] = "rbxassetid://10747382750",
  ["lucide-wrap-text"] = "rbxassetid://10747383065",
  ["lucide-wrench"] = "rbxassetid://10747383470",
  ["lucide-x"] = "rbxassetid://10747384394",
  ["lucide-x-circle"] = "rbxassetid://10747383819",
  ["lucide-x-octagon"] = "rbxassetid://10747384037",
  ["lucide-x-square"] = "rbxassetid://10747384217",
  ["lucide-zoom-in"] = "rbxassetid://10747384552",
  ["lucide-zoom-out"] = "rbxassetid://10747384679"
}
Library.Lucide = Lucide

-- // Icons
-- // Library.Icons maps a name to an image asset. Replace or add entries to change any icon:
-- //   Library.Icons.Search = "rbxassetid://123"      Library.Icons.MyIcon = "rbxassetid://456"
-- // Icon lookup order: Library.Icons key -> Lucide name ("sword" or "lucide-sword") -> built-in vector icon -> asset id / "rbxassetid://..."
-- // Built-in vector icons are only a fallback when a name is not in Lucide (for example "bolt")
Library.Icons = {
    Search = Lucide["lucide-search"] or "rbxassetid://6031154871",
    Lock = Lucide["lucide-lock"] or "rbxassetid://6031082533",
    Discord = "rbxassetid://10367063073"
}

-- Names used internally that are called differently in Lucide
local IconAlias = {grid = "layout-grid", pulse = "activity", settings = "sliders-horizontal", dot = "circle"}

local function Seg(add, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    add(math.sqrt(dx * dx + dy * dy) + 1.2, 2, (x1 + x2) / 2, (y1 + y2) / 2, math.deg(math.atan2(dy, dx)), "full")
end

local DrawnIcons = {
    user = function(add) add(6, 6, 8, 5, 0, "full") add(12, 6, 8, 12, 0, 3) end,
    grid = function(add)
        for _, c in ipairs({{4.5, 4.5}, {11.5, 4.5}, {4.5, 11.5}, {11.5, 11.5}}) do add(5, 5, c[1], c[2], 0, 1.5) end
    end,
    list = function(add) for _, y in ipairs({3.5, 8, 12.5}) do add(12, 2, 8, y, 0, "full") end end,
    home = function(add) Seg(add, 2, 8, 8, 2.5) Seg(add, 8, 2.5, 14, 8) add(9, 6, 8, 11.5, 0, 1.5) end,
    bolt = function(add) Seg(add, 10, 1.5, 4, 9) Seg(add, 4, 9, 9.5, 9) Seg(add, 9.5, 9, 6, 14.5) end,
    settings = function(add)
        for i, y in ipairs({3.5, 8, 12.5}) do
            add(12, 2, 8, y, 0, "full")
            add(4.5, 4.5, ({10.5, 5, 9})[i], y, 0, "full")
        end
    end,
    pulse = function(add)
        Seg(add, 1, 8, 4.5, 8) Seg(add, 4.5, 8, 7, 2.5) Seg(add, 7, 2.5, 10, 13.5) Seg(add, 10, 13.5, 12, 8) Seg(add, 12, 8, 15, 8)
    end,
    signal = function(add) add(3, 5, 3, 12.5, 0, 1) add(3, 9, 8, 10.5, 0, 1) add(3, 13, 13, 8.5, 0, 1) end,
    dot = function(add) add(6, 6, 8, 8, 0, "full") end
}
Library.DrawnIcons = DrawnIcons

local function ResolveIcon(icon)
    if icon == nil or icon == false then return nil end
    if type(icon) == "number" then return {Image = "rbxassetid://" .. icon} end
    icon = tostring(icon)
    local mapped = Library.Icons[icon]
    if mapped then
        mapped = tostring(mapped)
        if mapped:match("^%d+$") then mapped = "rbxassetid://" .. mapped end
        return {Image = mapped}
    end
    local key = icon:lower()
    local lu = Lucide[key] or Lucide["lucide-" .. key] or (IconAlias[key] and Lucide["lucide-" .. IconAlias[key]])
    if lu then return {Image = lu} end
    local drawn = DrawnIcons[key]
    if drawn then return {Drawn = drawn} end
    if icon:match("^%d+$") then return {Image = "rbxassetid://" .. icon} end
    return {Image = icon}
end

-- Returns {Root = instance, SetColor = function(color, duration)} or nil
local function MakeIcon(parent, icon, size, position, colorKey)
    local r = ResolveIcon(icon)
    if not r then return nil end
    local color = (typeof(colorKey) == "Color3") and colorKey or T[colorKey or "SubText"]
    if r.Image then
        local Img = Create("ImageLabel", {Parent = parent, Image = r.Image, Size = UDim2.fromOffset(size, size), Position = position, ImageColor3 = color})
        return {Root = Img, SetColor = function(c, d) Tween(Img, {ImageColor3 = c}, d or 0.2) end}
    end
    local Root = Create("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = position})
    local k, parts = size / 16, {}
    r.Drawn(function(w, h, cx, cy, rot, rad)
        local part = Create("Frame", {
            Parent = Root, Size = UDim2.fromOffset(w * k, h * k), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(cx * k, cy * k), Rotation = rot, BackgroundColor3 = color
        })
        Corner(part, rad == "full" and "full" or rad * k)
        table.insert(parts, part)
    end)
    return {Root = Root, SetColor = function(c, d) for _, part in ipairs(parts) do Tween(part, {BackgroundColor3 = c}, d or 0.2) end end}
end

-- // Global Notification API
local GlobalNotifContainer
local NotifColors = {
    success = rgb(80, 205, 125),
    warning = rgb(255, 190, 70),
    error = rgb(240, 85, 95)
}

function Library:Notify(options, a2, a3, a4)
    if not GlobalNotifContainer then return end
    if type(options) ~= "table" then
        options = {Title = tostring(options or "Notification"), Description = a2, Duration = a3, Type = a4}
    end
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
        local nIcon = MakeIcon(Card, options.Icon, 24, UDim2.fromOffset(16, 14), color)
        if nIcon then nIcon.Root.ZIndex = 3 end
    end

    local Content = Create("Frame", {Parent = Card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
    Pad(Content, leftPad, 12, 14, 10)
    ListLayout(Content, 4)
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
    local BarTrack = Create("Frame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 8), LayoutOrder = 3})
    local Bar = Create("Frame", {Parent = BarTrack, BackgroundColor3 = color, BackgroundTransparency = 0.35, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromOffset(0, 6)})
    Corner(Bar, "full")

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

    local W, H = 740, 430
    if typeof(options.Size) == "Vector2" then
        W, H = options.Size.X, options.Size.Y
    elseif typeof(options.Size) == "UDim2" then
        W, H = options.Size.X.Offset, options.Size.Y.Offset
    end
    local MIN_W, MIN_H, MAX_W, MAX_H = 580, 320, 1000, 720
    W = math.clamp(W, MIN_W, MAX_W)
    H = math.clamp(H, MIN_H, MAX_H)

    local hubName = options.Title or Library.Name
    local subText = options.Subtitle
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
    -- Images accept "rbxassetid://123", a bare number or a Library.Icons key
    local function AssetUrl(v)
        if v == nil or v == false then return nil end
        local mapped = Library.Icons[tostring(v)]
        v = tostring(mapped or v)
        if v:match("^%d+$") then return "rbxassetid://" .. v end
        return v
    end
    local topbarLogo = AssetUrl(options.Logo)
    local sphImage = AssetUrl(options.SphereImage) or topbarLogo   -- the toggle sphere uses the logo by default
    local logoSize = options.LogoSize or 30
    local sphIconSize = options.SphereIconSize or 34
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

    -- Safe re-execute: the previous UI is closed before a new one is built
    local genv = (getgenv and getgenv()) or _G
    local prev = genv.__MichelXneWindow
    if prev and prev.ScreenGui and prev.ScreenGui.Parent then
        pcall(function() prev:Destroy() end)
    end

    local Window = {CurrentTab = nil, Tabs = {}, AllCards = {}, ConfigElements = {}, Flags = Library.Flags, Folder = folder, UserScale = State.Scale, CurrentTransparency = State.WindowTransparency}

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

    local function IconButton(parent, position, kind, plain)
        local box = plain and 34 or 30
        local k = plain and 1.3 or 1
        local B = New("TextButton", {Parent = parent, Text = "", Size = UDim2.fromOffset(box, box), Position = position, BackgroundTransparency = plain and 1 or 0}, {BackgroundColor3 = "Input"})
        Corner(B, plain and 10 or 8)
        local BSt = New("UIStroke", {Parent = B, Thickness = 1, Transparency = plain and 1 or 0}, {Color = "Stroke"})
        local parts = {}
        local function Bar(w, h, ox, oy, rot)
            table.insert(parts, Create("Frame", {Parent = B, Size = UDim2.fromOffset(w * k, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, ox * k, 0.5, oy * k), Rotation = rot or 0}))
        end
        if kind == "min" or kind == "minus" then
            Bar(10, 2, 0, 0)
        elseif kind == "plus" then
            Bar(10, 2, 0, 0) Bar(10, 2, 0, 0, 90)
        elseif kind == "max" then
            Bar(10, 2, 0, -4) Bar(10, 2, 0, 4) Bar(10, 2, -4, 0, 90) Bar(10, 2, 4, 0, 90)
        else
            Bar(12, 2, 0, 0, 45) Bar(12, 2, 0, 0, -45)
        end
        for _, part in ipairs(parts) do
            Bind(part, "BackgroundColor3", "SubText")
            Corner(part, "full")
        end
        local danger = (kind == "close")
        B.MouseEnter:Connect(function()
            Tween(B, {BackgroundColor3 = danger and rgb(205, 60, 72) or T.Hover, BackgroundTransparency = 0}, 0.15)
            Tween(BSt, {Color = danger and rgb(205, 60, 72) or T.Accent}, 0.15)
            for _, part in ipairs(parts) do Tween(part, {BackgroundColor3 = danger and rgb(255, 255, 255) or T.Text}, 0.15) end
        end)
        B.MouseLeave:Connect(function()
            Tween(B, {BackgroundColor3 = T.Input, BackgroundTransparency = plain and 1 or 0}, 0.15)
            Tween(BSt, {Color = T.Stroke}, 0.15)
            for _, part in ipairs(parts) do Tween(part, {BackgroundColor3 = T.SubText}, 0.15) end
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
            RichText = true, Color = GOLD, Icon = Library.Icons.Lock, Duration = 4
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
    Corner(MainFrame, 14)
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Color = Color3.new(1, 1, 1), Thickness = 1.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local StrokeGrad = Create("UIGradient", {Parent = MainStroke, Rotation = 45, Color = ColorSequence.new(T.Accent, T.Stroke)})
    OnTheme(function() StrokeGrad.Color = ColorSequence.new(T.Accent, T.Stroke) end)

    -- Background layers (wallpaper gradient + custom image), sit behind everything
    local BgGrad = Create("Frame", {Parent = MainFrame, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
    Corner(BgGrad, 14)
    local BgGradUI = Create("UIGradient", {Parent = BgGrad, Rotation = 35})
    local BgImage = Create("ImageLabel", {Parent = MainFrame, ScaleType = Enum.ScaleType.Crop, ImageTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
    Corner(BgImage, 14)

    -- Top bar (gaya Fyy: logo + judul dua warna, chip executor/FPS, min / max / close)
    local HEADER_H, SIDE_W = 52, 180
    local TOP = HEADER_H + 1
    local TopBar = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEADER_H), Active = true})
    MakeDraggable(TopBar, Shell)
    local TopLine = New("Frame", {Parent = MainFrame, Position = UDim2.fromOffset(16, HEADER_H - 2), Size = UDim2.new(1, -32, 0, 2)}, {BackgroundColor3 = "Accent"})
    Corner(TopLine, "full")
    Create("UIGradient", {Parent = TopLine, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0.1), NumberSequenceKeypoint.new(1, 0.5)})})

    -- Logo: your own image (Logo = "rbxassetid://...") or a default letter badge
    local logoY = math.floor((HEADER_H - 2 - logoSize) / 2)
    if topbarLogo then
        Create("ImageLabel", {Parent = TopBar, Size = UDim2.fromOffset(logoSize, logoSize), Position = UDim2.fromOffset(14, logoY), Image = tostring(topbarLogo), ScaleType = Enum.ScaleType.Fit})
    else
        local Badge = New("Frame", {Parent = TopBar, Size = UDim2.fromOffset(logoSize, logoSize), Position = UDim2.fromOffset(14, logoY)}, {BackgroundColor3 = "Accent"})
        Corner(Badge, 9)
        local BadgeTxt = Create("TextLabel", {Parent = Badge, Text = string.upper(string.sub(tostring(hubName), 1, 1)), Font = Enum.Font.GothamBold, TextSize = 17, Size = UDim2.fromScale(1, 1), TextColor3 = ContrastText(T.Accent)})
        OnTheme(function() BadgeTxt.TextColor3 = ContrastText(T.Accent) end)
    end
    local titleOffsetX = 14 + logoSize + 10
    local hasSub = subText ~= nil and subText ~= ""
    local TitleBlock = Create("Frame", {Parent = TopBar, BackgroundTransparency = 1, Size = UDim2.new(1, -(titleOffsetX + (showStats and 416 or 134)), 1, 0), Position = UDim2.fromOffset(titleOffsetX, 0)})
    local function TitleMarkup()
        local safe = tostring(hubName):gsub("&", "&amp;"):gsub("<", "&lt;")
        local first, rest = safe:match("^(%S+)%s+(.+)$")
        if not first then
            return string.format('<font color="#%s">%s</font>', T.Accent:ToHex(), safe)
        end
        return string.format('<font color="#%s">%s</font> %s', T.Accent:ToHex(), first, rest)
    end
    local Title = New("TextLabel", {
        Parent = TitleBlock, Text = TitleMarkup(), RichText = true, Font = Enum.Font.GothamBold, TextSize = 17,
        Position = hasSub and UDim2.fromOffset(0, 8) or UDim2.fromOffset(0, 0),
        Size = hasSub and UDim2.new(1, 0, 0, 20) or UDim2.new(1, 0, 1, -2),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
    }, {TextColor3 = "Text"})
    OnTheme(function() Title.Text = TitleMarkup() end)
    local Subtitle = Create("TextLabel", {Parent = TitleBlock, Text = subText or "", Visible = hasSub, TextSize = 11, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    if subColor then Subtitle.TextColor3 = subColor else Bind(Subtitle, "TextColor3", "Accent") end
    Window.Title = Title

    local MinBtn = IconButton(TopBar, UDim2.new(1, -122, 0, 8), "min", true)
    local MaxBtn = IconButton(TopBar, UDim2.new(1, -84, 0, 8), "max", true)
    local CloseBtn = IconButton(TopBar, UDim2.new(1, -46, 0, 8), "close", true)

    -- Sidebar (search on top, tabs, optional Discord button)
    local discordLink = options.Discord
    local hideNameDefault = options.HideName ~= false
    local function MaskName(s)
        s = tostring(s)
        if hideNameDefault and #s > 3 then return string.sub(s, 1, 3) .. "***" end
        return s
    end
    local footerH = discordLink and 44 or 0
    -- The sidebar has no background of its own, so the window's rounded corners stay clean
    local Sidebar = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(0, SIDE_W, 1, -TOP), Position = UDim2.fromOffset(0, TOP), Active = true})
    local SearchBar = New("Frame", {Parent = Sidebar, Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 10)}, {BackgroundColor3 = "Card"})
    Corner(SearchBar, 10)
    local SearchStroke = New("UIStroke", {Parent = SearchBar, Thickness = 1}, {Color = "Stroke"})
    local SearchIcon = MakeIcon(SearchBar, "Search", 16, UDim2.new(0, 12, 0.5, -8), "SubText")
    local SearchInput = New("TextBox", {Parent = SearchBar, BackgroundTransparency = 1, Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(36, 0), PlaceholderText = "Search...", TextXAlignment = Enum.TextXAlignment.Left}, {TextColor3 = "Text", PlaceholderColor3 = "SubText"})
    FocusFx(SearchInput, SearchStroke)

    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, Size = UDim2.new(1, -16, 1, -(56 + footerH + 4)), Position = UDim2.fromOffset(8, 56), ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y})
    ListLayout(TabContainer, 4)

    if discordLink then
        local DBtn = New("TextButton", {Parent = Sidebar, Text = "", Size = UDim2.new(1, -16, 0, 38), Position = UDim2.new(0, 8, 1, -46)}, {BackgroundColor3 = "Card"})
        Corner(DBtn, 10)
        local DSt = New("UIStroke", {Parent = DBtn, Thickness = 1, Transparency = 0.4}, {Color = "Stroke"})
        local DBadge = Create("Frame", {Parent = DBtn, Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0, 10, 0.5, -12), BackgroundColor3 = rgb(88, 101, 242)})
        Corner(DBadge, 7)
        -- Vector Discord mark underneath (fallback if the image cannot load)
        local white, blurple = Color3.new(1, 1, 1), rgb(88, 101, 242)
        local function Part(w, h, cx, cy, rot, rad, col)
            local f = Create("Frame", {Parent = DBadge, Size = UDim2.fromOffset(w, h), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy), Rotation = rot, BackgroundColor3 = col})
            Corner(f, rad)
        end
        Part(16, 11, 12, 12.5, 0, 5, white)
        Part(5, 5, 6.5, 7, 35, 2, white)
        Part(5, 5, 17.5, 7, -35, 2, white)
        Part(3, 4.5, 5.5, 18.5, 20, 1.5, white)
        Part(3, 4.5, 18.5, 18.5, -20, 1.5, white)
        Part(3, 3.8, 8.8, 12.5, 0, "full", blurple)
        Part(3, 3.8, 15.2, 12.5, 0, "full", blurple)
        -- Real Discord logo on top: Library.Icons.Discord (set it to nil to use only the vector mark)
        local custom = Library.Icons.Discord and ResolveIcon(Library.Icons.Discord)
        if custom and custom.Image then
            local DImg = Create("ImageLabel", {Parent = DBadge, Size = UDim2.fromScale(1, 1), Image = custom.Image, ZIndex = 5})
            Corner(DImg, 7)
        end
        New("TextLabel", {Parent = DBtn, Text = "Discord", Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -52, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, {TextColor3 = "Text"})
        DBtn.MouseEnter:Connect(function() Tween(DBtn, {BackgroundColor3 = T.Hover}, 0.15) Tween(DSt, {Color = T.Accent}, 0.15) end)
        DBtn.MouseLeave:Connect(function() Tween(DBtn, {BackgroundColor3 = T.Card}, 0.15) Tween(DSt, {Color = T.Stroke}, 0.15) end)
        AddBounce(DBtn, 0.97)
        DBtn.MouseButton1Click:Connect(function()
            local link = tostring(discordLink)
            if not link:match("^https?://") then link = "https://discord.gg/" .. link end
            SafeCopyToClipboard(link)
            Library:Notify({Title = "Discord", Description = "Invite link copied to clipboard.", Type = "success"})
        end)
    end

    New("Frame", {Parent = MainFrame, Position = UDim2.fromOffset(SIDE_W, TOP + 6), Size = UDim2.new(0, 1, 1, -(TOP + 22)), BackgroundTransparency = 0.35}, {BackgroundColor3 = "Stroke"})
    local ContentArea = Create("Frame", {Parent = MainFrame, BackgroundTransparency = 1, Size = UDim2.new(1, -(SIDE_W + 1), 1, -TOP), Position = UDim2.fromOffset(SIDE_W + 1, TOP), Active = true})

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

    -- // Header chips: executor + FPS + ping
    if showStats then
        local function Chip(width, x, iconName, glyph)
            local Box = New("TextButton", {Parent = TopBar, Text = "", Size = UDim2.fromOffset(width, 32), Position = UDim2.new(1, x, 0, 9)}, {BackgroundColor3 = "Card"})
            Corner(Box, 10)
            local St = New("UIStroke", {Parent = Box, Thickness = 1}, {Color = "Stroke"})
            local Mark
            if glyph then
                local L = New("TextLabel", {Parent = Box, Text = glyph, Font = Enum.Font.Code, TextSize = 14, Size = UDim2.fromOffset(18, 32), Position = UDim2.fromOffset(10, 0)}, {TextColor3 = "Accent"})
                Mark = {SetColor = function(c, d) Tween(L, {TextColor3 = c}, d or 0.2) end}
            else
                Mark = MakeIcon(Box, iconName, 16, UDim2.fromOffset(10, 8), "SubText")
            end
            local Txt = New("TextLabel", {Parent = Box, Text = "--", Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(32, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
            Box.MouseEnter:Connect(function() Tween(St, {Color = T.Accent}, 0.15) end)
            Box.MouseLeave:Connect(function() Tween(St, {Color = T.Stroke}, 0.15) end)
            AddBounce(Box, 0.96)
            return Mark, Txt
        end
        local _, ExecTxt = Chip(100, -406, nil, ">_")
        local okExec, execName = pcall(function() return identifyexecutor and identifyexecutor() end)
        ExecTxt.Text = (okExec and type(execName) == "string" and execName ~= "") and execName or "Executor"
        local FpsDot, FpsTxt = Chip(84, -298, "pulse")
        local MsDot, MsTxt = Chip(76, -206, "signal")
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
                    FpsDot.SetColor(Rate(fps, 50, 30, false), 0.2)
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
                        MsDot.SetColor(Rate(ms, 80, 160, true), 0.2)
                    else
                        MsTxt.Text = "-- ms"
                        MsDot.SetColor(T.SubText, 0.2)
                    end
                end
                task.wait(1)
            end
        end)
    end

    function Window:Show() SetVisible(true) end
    function Window:Hide() SetVisible(false) end
    function Window:Toggle() SetVisible(not visible) end
    function Window:Notify(...) Library:Notify(...) end
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
            Text = "Are you sure you want to close " .. tostring(hubName) .. "? Unsaved configurations might be lost.",
            ConfirmText = "Close", Danger = true,
            OnConfirm = function() Window:Destroy() end
        })
    end)

    Window.MainFrame = MainFrame
    Window.Shell = Shell
    Window.ScreenGui = ScreenGui
    genv.__MichelXneWindow = Window

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

    -- Maximize button: toggles between the normal size and the maximum size (not saved)
    local maximized, restoreW, restoreH = false, W, H
    MaxBtn.MouseButton1Click:Connect(function()
        maximized = not maximized
        if maximized then
            restoreW, restoreH = W, H
            W, H = MAX_W, MAX_H
        else
            W, H = restoreW, restoreH
        end
        Shell.Size = UDim2.fromOffset(W, H)
        if visible then Tween(ShellScale, {Scale = TargetScale()}, 0.3) end
    end)

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

    -- // UI scale handle: a small corner bracket in the bottom-right corner. Drag to resize the whole UI
    -- //   right / down = bigger, left / up = smaller
    local ScaleBtn = Create("Frame", {Parent = MainFrame, Size = UDim2.fromOffset(32, 32), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), BackgroundTransparency = 1, Active = true, ZIndex = 20})
    local ScaleArc = Create("Frame", {Parent = ScaleBtn, Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), BackgroundTransparency = 1, ZIndex = 21})
    Corner(ScaleArc, "full")
    local ScaleStroke = New("UIStroke", {Parent = ScaleArc, Thickness = 2.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, {Color = "SubText"})
    Create("UIGradient", {Parent = ScaleStroke, Rotation = 45, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(0.68, 0.1), NumberSequenceKeypoint.new(1, 0.1)
    })})
    local scaleActive = false
    local function ScaleHot(hot)
        Tween(ScaleStroke, {Color = hot and T.Accent or T.SubText}, 0.15)
    end
    ScaleBtn.MouseEnter:Connect(function() ScaleHot(true) end)
    ScaleBtn.MouseLeave:Connect(function() if not scaleActive then ScaleHot(false) end end)
    ScaleBtn.InputBegan:Connect(function(input)
        if not IsPress(input) then return end
        scaleActive = true
        ScaleHot(true)
        local startMouse, startPos = input.Position, Shell.Position
        local t0 = math.max(ShellScale.Scale, 0.2)
        local fit = FitScale()
        local W0, H0 = W, H
        local denom = W0 * W0 + H0 * H0
        local minT, maxT = 0.6 * fit, 1.5 * fit
        local target, current = t0, t0
        local conn

        -- Apply one scale step. The top-left corner stays put and positions are snapped to whole pixels (no shimmer)
        local function Step(t)
            local user = math.clamp(t / fit, 0.6, 1.5)
            Window:SetScale(user, true)
            local shift = (fit * user - t0) / 2
            Shell.Position = UDim2.new(
                startPos.X.Scale, math.floor(startPos.X.Offset + W0 * shift + 0.5),
                startPos.Y.Scale, math.floor(startPos.Y.Offset + H0 * shift + 0.5)
            )
        end

        -- The finger only sets a target; the window eases toward it once per frame
        conn = RunService.RenderStepped:Connect(function(dt)
            if not ScreenGui.Parent then conn:Disconnect() return end
            current = current + (target - current) * (1 - math.exp(-dt * 18))
            if math.abs(target - current) < 0.0008 then current = target end
            Step(current)
        end)

        BeginDrag(input, function(i)
            local d = i.Position - startMouse
            -- project the finger movement on the window diagonal so the corner follows the finger
            target = math.clamp(t0 + (d.X * W0 + d.Y * H0) / denom, minT, maxT)
        end, function()
            conn:Disconnect()
            Step(target)
            scaleActive = false
            ScaleHot(false)
            SyncAppearance()
        end)
    end)

    -- // Search (global + tabs)

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

    function Window:CreateTab(tabName, isDefault, isLocked, icon, tabDesc)
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

        local TabBtn = New("TextButton", {Parent = TabContainer, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42), LayoutOrder = tabOrder}, {BackgroundColor3 = "Input"})
        Corner(TabBtn, 10)
        AddBounce(TabBtn, 0.98)
        local Indicator = Create("Frame", {Parent = TabBtn, Name = "Indicator", Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = isLocked and GOLD or T.Accent})
        if not isLocked then Bind(Indicator, "BackgroundColor3", "Accent") end
        Corner(Indicator, "full")
        -- Icon: nil = default "grid" icon, false = no icon, or a built-in name / Library.Icons key / asset id
        local IconObj
        if icon ~= false then
            IconObj = MakeIcon(TabBtn, icon == nil and "grid" or icon, 20, UDim2.new(0, 14, 0.5, -10), "SubText")
        end
        local textX = IconObj and 44 or 16
        local Txt = Create("TextLabel", {Parent = TabBtn, Text = tabName, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = T.SubText, Size = UDim2.new(1, -(textX + (isLocked and 26 or 8)), 1, 0), Position = UDim2.new(0, textX, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
        if isLocked then
            Create("ImageLabel", {Parent = TabBtn, Image = Library.Icons.Lock, ImageColor3 = GOLD, Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -22, 0.5, -7)})
        end

        local TabContent = Create("Frame", {Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false})
        local HEAD_H = 56
        local HeadTitle = New("TextLabel", {Parent = TabContent, Text = string.upper(tostring(tabName)), Font = Enum.Font.GothamBold, TextSize = 18, Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -36, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
        local HeadSub = New("TextLabel", {Parent = TabContent, Text = tabDesc or "", TextSize = 12, Position = UDim2.fromOffset(18, 32), Size = UDim2.new(1, -36, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "SubText"})
        local PageNav = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, HEAD_H), Size = UDim2.new(1, 0, 0, 36), Visible = false})
        Create("UIListLayout", {Parent = PageNav, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder})
        Pad(PageNav, 12, 0, 0, 0)
        local NavLine = New("Frame", {Parent = TabContent, Position = UDim2.fromOffset(12, HEAD_H + 35), Size = UDim2.new(1, -24, 0, 1), BackgroundTransparency = 0.5, Visible = false}, {BackgroundColor3 = "Stroke"})
        local PageContainer = Create("Frame", {Parent = TabContent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -HEAD_H), Position = UDim2.fromOffset(0, HEAD_H)})
        local function Relayout(multi)
            PageNav.Visible = multi
            NavLine.Visible = multi
            local off = multi and (HEAD_H + 37) or HEAD_H
            PageContainer.Position = UDim2.fromOffset(0, off)
            PageContainer.Size = UDim2.new(1, 0, 1, -off)
        end

        local TabConfig = {Button = TabBtn, Content = TabContent, Container = PageContainer, Indicator = Indicator, Txt = Txt, Pages = {}, CurrentPage = nil}
        function TabConfig:SetDescription(t) HeadSub.Text = tostring(t or "") end
        table.insert(Window.Tabs, TabConfig)

        function TabConfig.Style(active, instant)
            local d = instant and 0 or 0.2
            Tween(TabBtn, {BackgroundTransparency = active and 0 or 1}, d)
            Tween(Indicator, {Size = UDim2.new(0, 3, 0, active and 22 or 0)}, d + 0.05)
            Tween(Txt, {TextColor3 = active and T.Text or T.SubText}, d)
            if IconObj then IconObj.SetColor(active and T.Accent or T.SubText, d) end
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
            Pad(PageScroll, 2, 6, 8, 44)
            local LeftColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
            local RightColumn = Create("Frame", {Parent = PageScroll, BackgroundTransparency = 1, Size = UDim2.new(0.5, -5, 0, 0), Position = UDim2.new(0.5, 5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
            ListLayout(LeftColumn, 10)
            ListLayout(RightColumn, 10)

            local PageObj = {Scroll = PageScroll, Btn = PageBtn, Highlight = PageHighlight, Left = true, LeftCol = LeftColumn, RightCol = RightColumn}
            table.insert(TabConfig.Pages, PageObj)
            Relayout(#TabConfig.Pages > 1)

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
                Corner(SectionContainer, 12)
                New("UIStroke", {Parent = SectionContainer, Thickness = 1, Transparency = 0.35}, {Color = "Stroke"})

                table.insert(Window.AllCards, {Card = SectionContainer, OrigParent = targetColumn, Tab = TabConfig, Page = PageObj, SearchIndex = nil})

                local Dot = New("Frame", {Parent = SectionContainer, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(3, 12)}, {BackgroundColor3 = "Accent"})
                Corner(Dot, "full")
                New("TextLabel", {Parent = SectionContainer, Text = string.upper(tostring(sectionName)), Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -34, 0, 36), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
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

                -- // ===== Easy API: one config table is enough. Safe callbacks (errors never crash), automatic Flags, automatic Loop =====
                local function InfoOf(name, i)
                    if type(i) == "string" then return {Title = name, Description = i} end
                    return i
                end
                local function Safe(name, fn)
                    if type(fn) ~= "function" then return nil end
                    return function(...)
                        local ok, err = pcall(fn, ...)
                        if not ok then
                            warn("[Michel] " .. tostring(name) .. ": " .. tostring(err))
                            Library:Notify({Title = tostring(name), Description = string.sub(tostring(err), 1, 140), Type = "error"})
                        end
                    end
                end
                local function Prep(cfg, fallbackName)
                    local name = cfg.Name or fallbackName
                    local cb = Safe(name, cfg.Callback or cfg.OnChange)
                    local flag = cfg.Flag
                    if flag then
                        local inner = cb
                        cb = function(v, ...)
                            Library.Flags[flag] = v
                            if inner then inner(v, ...) end
                        end
                    end
                    return name, cb
                end

                -- Section:Button("Name", fn)  or  Section:Button({Name=, Callback=, Confirm=true|"text", Danger=true, Info="text"})
                function Elements:Button(cfg, cb)
                    if type(cfg) ~= "table" then cfg = {Name = cfg, Callback = cb} end
                    local name, fn = Prep({Name = cfg.Name, Callback = cfg.Callback}, "Button")
                    if cfg.Confirm then
                        local run = fn
                        fn = function()
                            Confirm({
                                Title = name,
                                Text = (type(cfg.Confirm) == "string") and cfg.Confirm or "Are you sure?",
                                Danger = cfg.Danger == true,
                                OnConfirm = run
                            })
                        end
                    end
                    return Elements:AddButton(name, fn, InfoOf(name, cfg.Info))
                end

                -- Section:Toggle("Name", false, fn)  or  Section:Toggle({Name=, Default=, Callback=, Flag=, Loop=fn, Interval=0.1, Info=})
                -- Loop = a function repeated automatically while the toggle is ON (stops by itself when OFF / window closed)
                function Elements:Toggle(cfg, default, cb)
                    if type(cfg) ~= "table" then cfg = {Name = cfg, Default = default, Callback = cb} end
                    local name, fn = Prep(cfg, "Toggle")
                    local loopFn = cfg.Loop
                    local interval = math.max(tonumber(cfg.Interval) or 0.1, 0.03)
                    local runId = 0
                    local function Apply(state)
                        runId = runId + 1
                        local id = runId
                        if fn then fn(state) end
                        if loopFn and state then
                            task.spawn(function()
                                local errored = false
                                while runId == id and ScreenGui.Parent do
                                    local ok, err = pcall(loopFn)
                                    if not ok and not errored then
                                        errored = true
                                        warn("[Michel] " .. tostring(name) .. " loop: " .. tostring(err))
                                        Library:Notify({Title = tostring(name), Description = string.sub(tostring(err), 1, 140), Type = "error"})
                                    end
                                    task.wait(interval)
                                end
                            end)
                        end
                    end
                    local obj = Elements:AddToggle(name, cfg.Default, Apply, InfoOf(name, cfg.Info))
                    if cfg.Flag then Library.Flags[cfg.Flag] = obj.Get() end
                    if cfg.Default then task.spawn(Apply, true) end
                    return obj
                end

                -- Section:Slider({Name=, Min=, Max=, Default=, Step=, Callback=, Flag=, Info=})
                function Elements:Slider(cfg)
                    local name, fn = Prep(cfg, "Slider")
                    local obj = Elements:AddSlider(name, cfg.Min or 0, cfg.Max or 100, cfg.Default, fn, InfoOf(name, cfg.Info), cfg.Step)
                    if cfg.Flag then Library.Flags[cfg.Flag] = obj.Get() end
                    return obj
                end

                -- Section:Dropdown({Name=, Options={...}, Multi=false, Default=, Callback=, Flag=, Info=})
                function Elements:Dropdown(cfg)
                    local name, fn = Prep(cfg, "Dropdown")
                    local obj = Elements:AddDropdown(name, cfg.Options or cfg.Values or {}, cfg.Multi == true, fn, InfoOf(name, cfg.Info), cfg.Default)
                    if cfg.Flag then Library.Flags[cfg.Flag] = obj.Get() end
                    return obj
                end

                -- Section:Textbox({Name=, Placeholder=, Default=, Callback=, Flag=, Info=})
                function Elements:Textbox(cfg)
                    local name, fn = Prep(cfg, "Textbox")
                    local obj = Elements:AddTextbox(name, cfg.Placeholder, fn, InfoOf(name, cfg.Info))
                    if cfg.Default ~= nil then obj.Box.Text = tostring(cfg.Default) end
                    if cfg.Flag then Library.Flags[cfg.Flag] = obj.Get() end
                    return obj
                end

                -- Section:ColorPicker({Name=, Default=Color3, Callback=, Flag=, Info=})
                function Elements:ColorPicker(cfg)
                    local name, fn = Prep(cfg, "Color")
                    local obj = Elements:AddColorPicker(name, cfg.Default, fn, InfoOf(name, cfg.Info))
                    if cfg.Flag then Library.Flags[cfg.Flag] = cfg.Default or Color3.new(1, 1, 1) end
                    return obj
                end

                -- Section:Keybind({Name=, Default=Enum.KeyCode.F or "F", Callback=(called when the key is pressed), OnBind=, Flag=, Info=})
                function Elements:Keybind(cfg)
                    local name = cfg.Name or "Keybind"
                    local def = cfg.Default
                    if type(def) == "string" then
                        local ok, kc = pcall(function() return Enum.KeyCode[def] end)
                        def = ok and kc or nil
                    end
                    local function OnBind(k)
                        if cfg.Flag then Library.Flags[cfg.Flag] = k and k.Name or "None" end
                        if cfg.OnBind then cfg.OnBind(k) end
                    end
                    local obj = Elements:AddKeybind(name, def, Safe(name, cfg.Callback), InfoOf(name, cfg.Info), OnBind)
                    if cfg.Flag then Library.Flags[cfg.Flag] = def and def.Name or "None" end
                    return obj
                end

                function Elements:Label(text) return Elements:AddLabel(text) end
                function Elements:Copy(name, text, info) return Elements:AddCopyButton(name, text, InfoOf(name, info)) end
                function Elements:Divider()
                    return New("Frame", {Parent = ItemContainer, Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.4}, {BackgroundColor3 = "Stroke"})
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
                    AppEls.ImageBox = Elements:AddTextbox("Custom Image", "rbxassetid://123456 / numeric ID / direct link", function(t) imageText = t end, {
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
                    end, {Title = "Window Size", Description = "Stretch the window wider or narrower."}, 10)
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
                    end, {Title = "UI Scale", Description = "Resize the whole window. Zooms the whole UI bigger or smaller. You can also drag the black button at the bottom-right corner. It auto-shrinks on small phone screens."}, 5)
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
            PageObj.Section = PageObj.CreateSection
            return PageObj
        end

        -- Shortcut: Tab:Section("Name") automatically creates a single "Main" page
        function TabConfig:Section(sectionName)
            if not TabConfig.AutoPage then TabConfig.AutoPage = TabConfig:CreatePage("Main") end
            return TabConfig.AutoPage:CreateSection(sectionName)
        end

        if isDefault then
            TabConfig.Style(true, true)
            TabContent.Visible = true
            Window.CurrentTab = TabConfig
        end
        return TabConfig
    end

    -- // One-call appearance tab: theme, background changer, interface settings
    function Window:CreateAppearanceTab(tabName, isDefault, icon)
        local tab = Window:CreateTab(tabName or "Appearance", isDefault, false, icon or "settings", "Theme, background and interface")
        local page = tab:CreatePage("Look")
        local themeSec = page:CreateSection("Theme")
        themeSec:AddThemeControls()
        local bgSec = page:CreateSection("Background")
        bgSec:AddBackgroundControls()
        local uiSec = page:CreateSection("Interface")
        uiSec:AddInterfaceControls()
        return tab
    end

    -- // Window:Tab({Name=, Icon=, Desc=, Default=, Locked=}) or Window:Tab("Name", isDefault, isLocked, icon, desc)
    function Window:Tab(cfg, ...)
        if type(cfg) == "table" then
            return Window:CreateTab(cfg.Name or "Tab", cfg.Default, cfg.Locked, cfg.Icon, cfg.Desc or cfg.Description)
        end
        return Window:CreateTab(cfg, ...)
    end

    -- // Ready-made Overview tab (account, game, server, Discord community)
    -- // opts: Name, Description, Icon, Default, HideName (true), Status, Discord (link/code), CommunityName, CommunityLogo, CommunityTitle
    function Window:CreateOverviewTab(opts)
        opts = (type(opts) == "table") and opts or {}
        local lp = Players.LocalPlayer
        local hideName = hideNameDefault
        if opts.HideName ~= nil then hideName = opts.HideName == true end
        local tab = Window:CreateTab(opts.Name or "Overview", opts.Default ~= false, false, opts.Icon or "user", opts.Description or "Your account and current session")

        local Scroll = New("ScrollingFrame", {Parent = tab.Container, Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, {ScrollBarImageColor3 = "Stroke"})
        Pad(Scroll, 4, 4, 8, 34)
        ListLayout(Scroll, 10)

        local function Card(parent, size, pos, order)
            local C = New("Frame", {Parent = parent, Size = size, Position = pos or UDim2.new(), LayoutOrder = order or 0}, {BackgroundColor3 = "Card"})
            BindPanel(C)
            Corner(C, 12)
            New("UIStroke", {Parent = C, Thickness = 1, Transparency = 0.35}, {Color = "Stroke"})
            return C
        end
        local function Tx(parent, text, x, y, rightMargin, size, colorKey, bold)
            return New("TextLabel", {
                Parent = parent, Text = text, Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium, TextSize = size,
                Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -(x + rightMargin), 0, size + 6),
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
            }, {TextColor3 = colorKey})
        end

        -- Account card
        local Acc = Card(Scroll, UDim2.new(1, 0, 0, 84), nil, 1)
        local AccBar = New("Frame", {Parent = Acc, Size = UDim2.new(0, 3, 1, -24), Position = UDim2.fromOffset(0, 12)}, {BackgroundColor3 = "Accent"})
        Corner(AccBar, "full")
        local Av = New("ImageLabel", {Parent = Acc, BackgroundTransparency = 0, Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(16, 14)}, {BackgroundColor3 = "Hover"})
        Corner(Av, 14)
        New("UIStroke", {Parent = Av, Thickness = 1.5, Transparency = 0.3}, {Color = "Accent"})
        local function Mask(s) return hideName and (string.sub(s, 1, 3) .. "***") or s end
        Tx(Acc, Mask(lp and lp.DisplayName or "Player"), 84, 12, 110, 15, "Text", true)
        Tx(Acc, "@" .. Mask(lp and lp.Name or "player"), 84, 34, 110, 13, "SubText")
        Tx(Acc, string.format("%d days · ID %s", lp and lp.AccountAge or 0, lp and tostring(lp.UserId) or "-"), 84, 54, 14, 12, "SubText")
        if lp then
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                end)
                if ok and Av.Parent then Av.Image = img end
            end)
        end
        local StatusWrap = Create("Frame", {Parent = Acc, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X})
        Create("UIListLayout", {Parent = StatusWrap, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        local StatusDot = Create("Frame", {Parent = StatusWrap, Size = UDim2.fromOffset(8, 8), BackgroundColor3 = NotifColors.success, LayoutOrder = 1})
        Corner(StatusDot, "full")
        local StatusTxt = Create("TextLabel", {Parent = StatusWrap, Text = opts.Status or "Ready", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = NotifColors.success, Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2})

        -- Game + server card
        local Row = Create("Frame", {Parent = Scroll, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 76), LayoutOrder = 2})
        local GameCard = Card(Row, UDim2.new(0.5, -5, 1, 0), UDim2.new(0, 0, 0, 0))
        local SrvCard = Card(Row, UDim2.new(0.5, -5, 1, 0), UDim2.new(0.5, 5, 0, 0))
        MakeIcon(GameCard, "gamepad-2", 20, UDim2.new(1, -34, 0, 10), "SubText")
        Tx(GameCard, "GAME", 14, 8, 14, 11, "SubText", true)
        local GameName = Tx(GameCard, "Loading...", 14, 26, 14, 15, "Text", true)
        Tx(GameCard, "Place " .. tostring(game.PlaceId), 14, 48, 14, 12, "SubText")
        MakeIcon(SrvCard, "server", 20, UDim2.new(1, -34, 0, 10), "SubText")
        Tx(SrvCard, "SERVER", 14, 8, 14, 11, "SubText", true)
        local SrvCount = Tx(SrvCard, "-- / -- Players", 14, 26, 14, 15, "Text", true)
        local SrvDot = Create("Frame", {Parent = SrvCard, Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(14, 56), BackgroundColor3 = NotifColors.success})
        Corner(SrvDot, "full")
        Create("TextLabel", {Parent = SrvCard, Text = "Connected", TextSize = 12, TextColor3 = NotifColors.success, Position = UDim2.fromOffset(26, 48), Size = UDim2.new(1, -40, 0, 20), TextXAlignment = Enum.TextXAlignment.Left})

        task.spawn(function()
            local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
            if GameName.Parent then GameName.Text = (ok and info and info.Name) or game.Name end
        end)
        local function RefreshServer()
            if SrvCount.Parent then
                SrvCount.Text = string.format("%d / %d Players", #Players:GetPlayers(), Players.MaxPlayers)
            end
        end
        RefreshServer()
        Conn(Players.PlayerAdded, RefreshServer)
        Conn(Players.PlayerRemoving, function() task.defer(RefreshServer) end)

        local Overview = {Tab = tab}
        function Overview.SetStatus(text, color)
            local c = color or NotifColors.success
            StatusTxt.Text = tostring(text)
            StatusTxt.TextColor3 = c
            StatusDot.BackgroundColor3 = c
        end

        -- Discord community card
        if opts.Discord then
            local link = tostring(opts.Discord)
            local code = link:match("discord%.gg/([%w%-_]+)") or link:match("discord%.com/invite/([%w%-_]+)") or link:match("^([%w%-_]+)$")
            if not link:match("^https?://") then link = "https://discord.gg/" .. link end

            local Com = Card(Scroll, UDim2.new(1, 0, 0, 112), nil, 3)
            New("TextLabel", {Parent = Com, Text = opts.CommunityTitle or "Have Problem / Need Help? Join Server Now", Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd}, {TextColor3 = "Text"})
            local Logo = New("ImageLabel", {Parent = Com, BackgroundTransparency = 0, Image = opts.CommunityLogo and ((tostring(opts.CommunityLogo):match("^%d+$") and "rbxassetid://" or "") .. tostring(opts.CommunityLogo)) or "", Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(16, 40)}, {BackgroundColor3 = "Hover"})
            Corner(Logo, 12)
            New("UIStroke", {Parent = Logo, Thickness = 1}, {Color = "Stroke"})
            if not opts.CommunityLogo then
                New("TextLabel", {Parent = Logo, Text = string.upper(string.sub(opts.CommunityName or "D", 1, 1)), Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.fromScale(1, 1)}, {TextColor3 = "Accent"})
            end
            local ComName = Tx(Com, opts.CommunityName or "Discord Community", 80, 40, 142, 14, "Text", true)
            local ComMembers = Tx(Com, "• Member Count: --", 80, 60, 142, 12, "SubText")
            local ComOnline = Tx(Com, "• Online Count: --", 80, 77, 142, 12, "SubText")

            local function SmallBtn(text, y, icon)
                local B = New("TextButton", {Parent = Com, Text = text, Font = Enum.Font.GothamBold, TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, y), Size = UDim2.fromOffset(132, 32)}, {BackgroundColor3 = "Input", TextColor3 = "Text"})
                Corner(B, 9)
                if icon then
                    MakeIcon(B, icon, 16, UDim2.new(0, 14, 0.5, -8), "Text")
                    B.TextXAlignment = Enum.TextXAlignment.Left
                    Pad(B, 38, 0, 0, 0)
                end
                local St = New("UIStroke", {Parent = B, Thickness = 1}, {Color = "Stroke"})
                B.MouseEnter:Connect(function() Tween(B, {BackgroundColor3 = T.Hover}, 0.15) Tween(St, {Color = T.Accent}, 0.15) end)
                B.MouseLeave:Connect(function() Tween(B, {BackgroundColor3 = T.Input}, 0.15) Tween(St, {Color = T.Stroke}, 0.15) end)
                AddBounce(B, 0.96)
                return B
            end
            local CopyB = SmallBtn("Copy Invite", 50)

            local copyBusy = false
            CopyB.MouseButton1Click:Connect(function()
                SafeCopyToClipboard(link)
                if copyBusy then return end
                copyBusy = true
                CopyB.Text = "Copied!"
                task.wait(1.5)
                if CopyB.Parent then CopyB.Text = "Copy Invite" end
                copyBusy = false
            end)

            local function Fetch()
                if not code then return end
                task.spawn(function()
                    local url = "https://discord.com/api/v10/invites/" .. code .. "?with_counts=true"
                    local ok, body = pcall(function()
                        if _request then
                            local res = _request({Url = url, Method = "GET"})
                            return res and res.Body
                        end
                        return game:HttpGet(url)
                    end)
                    local data
                    if ok and type(body) == "string" then
                        local ok2, decoded = pcall(function() return HttpService:JSONDecode(body) end)
                        if ok2 then data = decoded end
                    end
                    if type(data) == "table" and type(data.guild) == "table" then
                        if ComName.Parent then
                            if not opts.CommunityName and data.guild.name then ComName.Text = data.guild.name end
                            ComMembers.Text = "• Member Count: " .. tostring(data.approximate_member_count or "--")
                            ComOnline.Text = "• Online Count: " .. tostring(data.approximate_presence_count or "--")
                        end
                    else
                        Library:Notify({Title = "Community", Description = "Could not load server info.", Type = "warning"})
                    end
                end)
            end
            Fetch()
            Overview.Refresh = Fetch
        end

        return Overview
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
