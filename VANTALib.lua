--[[
    VANTALib — macOS Glassmorphic × Fatality/Primordial UI library
    version: 4.0.0

    aesthetic: Frosted dark plum-charcoal glass panels, 1px luminous borders,
               macOS traffic-light window controls, Fatality-inspired top pill
               tabs, dual-column groupboxes, and magenta-to-violet gradients.

    every window is built with a pinned SETTINGS tab:
      · rebind the menu key
      · interface scale, glass opacity, sounds
      · watermark and on-screen keybind list
      · config slots (save / load / delete / reset defaults)
      · hide the menu or unload the whole interface

    widgets:
      Toggle, Slider, Stepper, Segmented, Dropdown, MultiDropdown, ColorPicker,
      Button, TextBox, Keybind, Progress, Label, Separator
]]

local VANTALib = {}
VANTALib.__index = VANTALib
VANTALib.Version = "4.0.0"
local VERSION = VANTALib.Version

-- ───────────────────────────────────────────────────────────────────────────
--  FONT
-- ───────────────────────────────────────────────────────────────────────────
local FONT_UI   = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function loadFont()
    local ok, result = pcall(function()
        if type(isfolder) ~= "function" or type(makefolder) ~= "function"
            or type(isfile) ~= "function" or type(writefile) ~= "function"
            or type(getcustomasset) ~= "function" then
            error("executor filesystem/asset API unavailable")
        end

        if not isfolder("VANTALib") then makefolder("VANTALib") end
        if not isfolder("VANTALib/Assets") then makefolder("VANTALib/Assets") end

        local tf = "VANTALib/Assets/ProggyClean.ttf"
        if not isfile(tf) then
            local data = game:HttpGet(
                "https://raw.githubusercontent.com/bluescan/proggyfonts/master/ProggyOriginal/ProggyClean.ttf"
            )
            assert(data and #data > 10000, "bad font download")
            writefile(tf, data)
        end

        local json = game:GetService("HttpService"):JSONEncode({
            name = "ProggyClean",
            faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(tf) } }
        })
        local jf = "VANTALib/Assets/ProggyClean.json"
        writefile(jf, json)

        return Font.new(getcustomasset(jf), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)

    if ok and typeof(result) == "Font" then return result end
    return Enum.Font.Code
end

local FONT_MONO = loadFont()

-- ───────────────────────────────────────────────────────────────────────────
--  PALETTE — Glassmorphic Plum-Charcoal × Fatality Magenta-Violet
-- ───────────────────────────────────────────────────────────────────────────
local C = {
    window      = Color3.fromRGB(16, 14, 22),
    window_top  = Color3.fromRGB(24, 20, 34),
    header      = Color3.fromRGB(22, 19, 30),
    panel       = Color3.fromRGB(24, 21, 33),
    panel_alt   = Color3.fromRGB(30, 26, 40),
    row_hover   = Color3.fromRGB(36, 31, 48),
    row_active  = Color3.fromRGB(44, 38, 58),
    field       = Color3.fromRGB(14, 12, 20),
    field_hover = Color3.fromRGB(28, 24, 38),
    accent      = Color3.fromRGB(214, 69, 140),   -- Fatality magenta-pink
    accent_hi   = Color3.fromRGB(168, 85, 247),   -- Primordial violet
    accent_soft = Color3.fromRGB(244, 130, 186),
    accent_dim  = Color3.fromRGB(108, 42, 86),
    border      = Color3.fromRGB(68, 60, 92),
    border_hi   = Color3.fromRGB(180, 165, 220),
    text        = Color3.fromRGB(240, 238, 246),
    text_sec    = Color3.fromRGB(172, 166, 192),
    text_dim    = Color3.fromRGB(112, 106, 134),
    success     = Color3.fromRGB(80, 210, 140),
    warn        = Color3.fromRGB(245, 185, 70),
    danger      = Color3.fromRGB(240, 82, 95),
    white       = Color3.fromRGB(255, 255, 255),
}

-- ───────────────────────────────────────────────────────────────────────────
--  SERVICES
-- ───────────────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────────────────
--  GLASS OPACITY
-- ───────────────────────────────────────────────────────────────────────────
local bgObjects = {}
local uiOpacity = 1

local function trackGlass(obj, baseTrans)
    obj.BackgroundTransparency = 1 - (1 - baseTrans) * uiOpacity
    table.insert(bgObjects, { obj = obj, base = baseTrans })
end

local function applyOpacity(a)
    uiOpacity = math.clamp(a, 0.25, 1)
    for _, entry in ipairs(bgObjects) do
        if entry.obj and entry.obj.Parent then
            entry.obj.BackgroundTransparency = 1 - (1 - entry.base) * uiOpacity
        end
    end
end

-- ───────────────────────────────────────────────────────────────────────────
--  UTILITY
-- ───────────────────────────────────────────────────────────────────────────
local function corner(gui, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = gui
    return c
end

local function newFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1, 0, 1, 0)
    f.Position = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = color or C.panel
    f.BorderSizePixel = 0
    f.Name = name or "Frame"
    f.Parent = parent
    return f
end

local function applyFont(obj, font)
    if typeof(font) == "Font" then
        obj.FontFace = font
    else
        obj.Font = font or FONT_UI
    end
end

local function newLabel(parent, text, textSize, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = textSize or 12
    l.TextColor3 = color or C.text
    applyFont(l, font)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function newButton(parent, size, pos, color)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(1, 0, 1, 0)
    b.Position = pos or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = color or C.field
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Text = ""
    b.TextSize = 1
    b.Parent = parent
    return b
end

local function stroke(gui, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Thickness = thickness or 1
    s.Transparency = trans or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = gui
    return s
end

local function gradient(gui, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    g.Parent = gui
    return g
end

local function fmtNumber(v, step, suffix)
    local s
    if step >= 1 then
        s = tostring(math.floor(v + 0.5))
    elseif step >= 0.1 then
        s = string.format("%.1f", v)
    elseif step >= 0.01 then
        s = string.format("%.2f", v)
    else
        s = string.format("%.3f", v)
    end
    return s .. (suffix or "")
end

local function toHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(math.clamp(c.R, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.G, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.B, 0, 1) * 255 + 0.5))
end

local function fromHex(raw)
    raw = tostring(raw or ""):gsub("#", "")
    if #raw ~= 6 then return nil end
    local r = tonumber(raw:sub(1, 2), 16)
    local g = tonumber(raw:sub(3, 4), 16)
    local b = tonumber(raw:sub(5, 6), 16)
    if r and g and b then return Color3.fromRGB(r, g, b) end
    return nil
end

function VANTALib.encodeValue(v)
    local t = typeof(v)
    if t == "Color3" then
        return { ["$c"] = toHex(v) }
    elseif t == "EnumItem" then
        return { ["$k"] = v.Name }
    elseif t == "table" then
        local out = {}
        for i, item in ipairs(v) do
            out[i] = VANTALib.encodeValue(item)
        end
        return out
    end
    return v
end

function VANTALib.decodeValue(v)
    if type(v) == "table" then
        if v["$c"] then
            return fromHex(v["$c"])
        end
        if v["$k"] then
            local ok, key = pcall(function() return Enum.KeyCode[v["$k"]] end)
            if ok then return key end
            return nil
        end
        local list = {}
        for i = 1, #v do
            list[i] = v[i]
        end
        return list
    end
    return v
end

-- ───────────────────────────────────────────────────────────────────────────
--  FEED (top-right frosted notices)
-- ───────────────────────────────────────────────────────────────────────────
local notifGui, notifHolder, notifSeq = nil, nil, 0
local notifCards = {}
local MAX_NOTICES = 5

local function ensureNotifs()
    if notifGui and notifGui.Parent then return notifHolder end
    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "_VANTAFeed"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder = 10
    notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    notifHolder = newFrame(notifGui, UDim2.new(0, 290, 1, 0), UDim2.new(1, -304, 0, 14))
    notifHolder.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = notifHolder
    return notifHolder
end

function VANTALib:Notify(title, body, duration)
    local holder = ensureNotifs()
    duration = duration or 4
    notifSeq = notifSeq + 1

    while #notifCards >= MAX_NOTICES do
        local old = table.remove(notifCards, 1)
        if old and old.Parent then old:Destroy() end
    end

    local card = newFrame(holder, UDim2.new(1, 0, 0, 58), nil, C.panel, "Notice")
    card.LayoutOrder = notifSeq
    card.BackgroundTransparency = 0.16
    card.ClipsDescendants = true
    corner(card, 10)
    stroke(card, C.border_hi, 1, 0.55)

    local bar = newFrame(card, UDim2.new(0, 3, 1, -12), UDim2.new(0, 6, 0, 6), C.accent, "Bar")
    corner(bar, 2)
    gradient(bar, C.accent, C.accent_hi, 90)

    local t = newLabel(card, string.upper(tostring(title or "")), 10, C.accent_soft, FONT_BOLD)
    t.Position = UDim2.new(0, 18, 0, 9)
    t.Size = UDim2.new(1, -26, 0, 14)

    local b = newLabel(card, tostring(body or ""), 10, C.text_sec, FONT_UI)
    b.Position = UDim2.new(0, 18, 0, 25)
    b.Size = UDim2.new(1, -26, 0, 26)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top

    local prog = newFrame(card, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2), C.accent, "Progress")
    gradient(prog, C.accent, C.accent_hi, 0)
    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 2) }):Play()

    table.insert(notifCards, card)
    task.delay(duration, function()
        if card and card.Parent then card:Destroy() end
        for i = #notifCards, 1, -1 do
            if notifCards[i] == card then table.remove(notifCards, i) end
        end
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
--  WINDOW
-- ───────────────────────────────────────────────────────────────────────────
local TOP_H = 44
local TAB_H = 38

function VANTALib:CreateWindow(config)
    config = config or {}
    local title = tostring(config.Title or "VANTA")
    local width = math.max(540, config.Width or 660)
    local height = math.max(400, config.Height or 490)
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local soundsEnabled = config.Sounds == true
    local scale = math.clamp(config.Scale or 1, 0.5, 2)

    local connections = {}
    local inputCtx = { listening = false }
    local openPopups = {}
    local registry = {}

    local function register(flag, default, setFn, getFn, fireFn)
        if flag and flag ~= "" then
            registry[flag] = {
                default = default,
                set = setFn,
                get = getFn,
                fire = fireFn,
            }
        end
    end

    local function claim(event, fn)
        local conn = UserInputService[event]:Connect(fn)
        table.insert(connections, conn)
        return conn
    end

    local function click()
        if not soundsEnabled then return end
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6895079853"
        s.Volume = 0.25
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(1, function()
            if s and s.Parent then s:Destroy() end
        end)
    end

    local function viewportSize()
        local cam = workspace.CurrentCamera
        if cam then return cam.ViewportSize end
        return Vector2.new(1280, 720)
    end

    -- screen gui
    local sg = Instance.new("ScreenGui")
    sg.Name = "VANTA_" .. title
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 5
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local holder = newFrame(sg, UDim2.new(1, 0, 1, 0), nil, C.window, "Holder")
    holder.BackgroundTransparency = 1

    local vp = viewportSize()
    local root = newFrame(holder, UDim2.new(0, width, 0, height),
        UDim2.new(0, (vp.X - width) / 2, 0, (vp.Y - height) / 2),
        C.window, "Window")
    root.ClipsDescendants = true
    corner(root, 12)
    trackGlass(root, 0.16)
    gradient(root, C.window_top, C.window, 135)
    local rootStroke = stroke(root, C.border_hi, 1, 0.55)
    gradient(rootStroke, C.accent, C.border_hi, 45)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale
    uiScale.Parent = root

    local function setScale(v)
        scale = math.clamp(v or 1, 0.5, 2)
        uiScale.Scale = scale
    end

    -- Fatality top luminous 2px accent strip
    local topGlow = newFrame(root, UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0), C.accent, "TopGlow")
    topGlow.ZIndex = 10
    gradient(topGlow, C.accent, C.accent_hi, 0)

    -- macOS-style titlebar
    local titlebar = newFrame(root, UDim2.new(1, 0, 0, TOP_H), UDim2.new(0, 0, 0, 2), C.header, "Titlebar")
    trackGlass(titlebar, 0.28)

    -- draggable window via titlebar
    do
        local dragging, dragStart, startPos = false, nil, nil
        titlebar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = root.Position
            end
        end)
        claim("InputChanged", function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        claim("InputEnded", function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- macOS traffic-light dots (Unload, Hide, Toggle Watermark)
    local Window = {}
    Window._tabs = {}
    Window._active = nil
    Window._gui = sg
    Window._win = root
    Window._unloaded = false

    local function makeTrafficDot(xOff, color, tip, onClick)
        local d = newButton(titlebar, UDim2.new(0, 11, 0, 11), UDim2.new(0, xOff, 0.5, 0), color)
        d.AnchorPoint = Vector2.new(0, 0.5)
        d.ZIndex = 8
        corner(d, 6)
        d.MouseButton1Click:Connect(function()
            onClick()
            click()
        end)
        return d
    end

    local setVisible -- forward declare

    makeTrafficDot(14, C.danger, "Unload", function() Window:Unload() end)
    makeTrafficDot(31, C.warn, "Hide", function() setVisible(false) end)
    makeTrafficDot(48, C.success, "Reset Pos", function()
        local curVp = viewportSize()
        root.Position = UDim2.new(0, (curVp.X - width) / 2, 0, (curVp.Y - height) / 2)
    end)

    -- Brand badge
    local titleLbl = newLabel(titlebar, string.upper(title):sub(1, 20), 13, C.text, FONT_BOLD)
    titleLbl.Position = UDim2.new(0, 72, 0, 7)
    titleLbl.Size = UDim2.new(0, 180, 0, 16)

    local subLbl = newLabel(titlebar, "GLASS × FATALITY  ·  v" .. VERSION, 8, C.text_dim, FONT_MONO)
    subLbl.Position = UDim2.new(0, 72, 0, 24)
    subLbl.Size = UDim2.new(0, 220, 0, 11)

    -- Right-side avatar + key hint pill
    local userPill = newFrame(titlebar, UDim2.new(0, 170, 0, 26), UDim2.new(1, -12, 0.5, 0), C.field, "UserPill")
    userPill.AnchorPoint = Vector2.new(1, 0.5)
    corner(userPill, 13)
    trackGlass(userPill, 0.35)
    stroke(userPill, C.border, 1, 0.45)

    local avatarBox = newFrame(userPill, UDim2.new(0, 20, 0, 20), UDim2.new(0, 3, 0.5, 0), C.panel_alt, "Avatar")
    avatarBox.AnchorPoint = Vector2.new(0, 0.5)
    corner(avatarBox, 10)
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Parent = avatarBox
    corner(avatarImg, 10)

    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and thumb and avatarImg.Parent then
            avatarImg.Image = thumb
        end
    end)

    local keyHintLbl = newLabel(userPill, string.upper(toggleKey.Name) .. "  ·  MENU", 8, C.accent_soft, FONT_MONO)
    keyHintLbl.Position = UDim2.new(0, 28, 0, 0)
    keyHintLbl.Size = UDim2.new(1, -36, 1, 0)
    keyHintLbl.TextXAlignment = Enum.TextXAlignment.Right

    -- Divider under titlebar
    local div1 = newFrame(root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TOP_H + 2), C.border, "Div1")
    div1.BackgroundTransparency = 0.5

    -- Fatality-style horizontal top tab bar + search pill
    local tabBar = newFrame(root, UDim2.new(1, 0, 0, TAB_H), UDim2.new(0, 0, 0, TOP_H + 3), C.header, "TabBar")
    trackGlass(tabBar, 0.38)

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, -182, 1, 0)
    tabScroll.Position = UDim2.new(0, 10, 0, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
    tabScroll.Parent = tabBar

    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Padding = UDim.new(0, 6)
    tabList.Parent = tabScroll

    -- Global filter box in tabBar right
    local searchFrame = newFrame(tabBar, UDim2.new(0, 156, 0, 24), UDim2.new(1, -12, 0.5, 0), C.field, "Search")
    searchFrame.AnchorPoint = Vector2.new(1, 0.5)
    corner(searchFrame, 12)
    trackGlass(searchFrame, 0.35)
    local searchStroke = stroke(searchFrame, C.border, 1, 0.45)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search features..."
    searchBox.TextColor3 = C.text
    searchBox.PlaceholderColor3 = C.text_dim
    applyFont(searchBox, FONT_UI)
    searchBox.TextSize = 10
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    searchBox.Focused:Connect(function() searchStroke.Color = C.accent; searchStroke.Transparency = 0.1 end)
    searchBox.FocusLost:Connect(function() searchStroke.Color = C.border; searchStroke.Transparency = 0.45 end)

    local div2 = newFrame(root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TOP_H + TAB_H + 3), C.border, "Div2")
    div2.BackgroundTransparency = 0.5

    -- Content container
    local contentY = TOP_H + TAB_H + 4
    local content = newFrame(root, UDim2.new(1, 0, 1, -contentY), UDim2.new(0, 0, 0, contentY), C.window, "Content")
    content.BackgroundTransparency = 1

    -- Tooltip
    local tooltip = newFrame(root, UDim2.new(0, 0, 0, 0), nil, C.panel_alt, "Tooltip")
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.Visible = false
    tooltip.ZIndex = 300
    tooltip.BackgroundTransparency = 0.1
    corner(tooltip, 8)
    stroke(tooltip, C.accent, 1, 0.35)
    local ttpPad = Instance.new("UIPadding")
    ttpPad.PaddingLeft = UDim.new(0, 10)
    ttpPad.PaddingRight = UDim.new(0, 10)
    ttpPad.PaddingTop = UDim.new(0, 6)
    ttpPad.PaddingBottom = UDim.new(0, 6)
    ttpPad.Parent = tooltip
    local ttpLbl = newLabel(tooltip, "", 10, C.text, FONT_UI)
    ttpLbl.Size = UDim2.new(0, 210, 0, 0)
    ttpLbl.TextWrapped = true
    ttpLbl.TextYAlignment = Enum.TextYAlignment.Top
    ttpLbl.AutomaticSize = Enum.AutomaticSize.Y
    ttpLbl.ZIndex = 301

    local function positionTooltip()
        if not tooltip.Visible then return end
        local mouse = UserInputService:GetMouseLocation()
        local relX = (mouse.X - root.AbsolutePosition.X) / scale
        local relY = (mouse.Y - root.AbsolutePosition.Y) / scale
        local maxX = (root.AbsoluteSize.X / scale) - (tooltip.AbsoluteSize.X / scale) - 6
        local maxY = (root.AbsoluteSize.Y / scale) - (tooltip.AbsoluteSize.Y / scale) - 6
        tooltip.Position = UDim2.fromOffset(
            math.clamp(relX + 14, 6, math.max(6, maxX)),
            math.clamp(relY + 18, 6, math.max(6, maxY))
        )
    end

    local function showTooltip(text)
        ttpLbl.Text = tostring(text)
        tooltip.Visible = true
        task.defer(positionTooltip)
    end

    local function hideTooltip()
        tooltip.Visible = false
    end

    claim("InputChanged", function(input)
        if tooltip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
            positionTooltip()
        end
    end)

    -- Popups
    local function registerPopup(closeFn)
        table.insert(openPopups, closeFn)
        return closeFn
    end

    local function closePopups(except)
        for i = #openPopups, 1, -1 do
            local fn = openPopups[i]
            if fn ~= except then
                pcall(fn)
            end
        end
    end

    -- Keybind overlay (frosted bottom-left card)
    local keyHolder = newFrame(sg, UDim2.new(0, 200, 0, 0), UDim2.new(0, 14, 1, -14), C.panel, "KeyList")
    keyHolder.BackgroundTransparency = 0.2
    keyHolder.AutomaticSize = Enum.AutomaticSize.Y
    keyHolder.AnchorPoint = Vector2.new(0, 1)
    keyHolder.Visible = false
    corner(keyHolder, 10)
    stroke(keyHolder, C.border_hi, 1, 0.55)
    local keyPad = Instance.new("UIPadding")
    keyPad.PaddingTop = UDim.new(0, 6)
    keyPad.PaddingBottom = UDim.new(0, 6)
    keyPad.PaddingLeft = UDim.new(0, 8)
    keyPad.PaddingRight = UDim.new(0, 8)
    keyPad.Parent = keyHolder
    local keyLayout = Instance.new("UIListLayout")
    keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keyLayout.Padding = UDim.new(0, 3)
    keyLayout.Parent = keyHolder

    local keyHead = newFrame(keyHolder, UDim2.new(1, 0, 0, 16), nil, nil, "Head")
    keyHead.BackgroundTransparency = 1
    keyHead.LayoutOrder = 0
    local keyHeadLbl = newLabel(keyHead, "KEYBINDS", 9, C.accent_soft, FONT_BOLD)
    keyHeadLbl.Size = UDim2.new(1, 0, 1, 0)

    local keyEntries = {}
    local keyListVisible = false

    local function refreshKeyList()
        keyHolder.Visible = keyListVisible and (#keyEntries > 0)
    end

    local function addKeyEntry(name, getKey)
        local row = newFrame(keyHolder, UDim2.new(1, 0, 0, 20), nil, C.field, "KeyEntry")
        row.LayoutOrder = #keyEntries + 1
        row.BackgroundTransparency = 0.3
        corner(row, 6)
        local lbl = newLabel(row, tostring(name), 9, C.text_sec, FONT_UI)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.Size = UDim2.new(1, -74, 1, 0)
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        local kl = newLabel(row, "", 8, C.accent_soft, FONT_MONO)
        kl.Position = UDim2.new(0, 0, 0, 0)
        kl.Size = UDim2.new(1, -8, 1, 0)
        kl.TextXAlignment = Enum.TextXAlignment.Right
        local handle = {
            row = row,
            label = kl,
            refresh = function()
                local key = getKey()
                kl.Text = key and ("[" .. string.upper(key.Name) .. "]") or "[NONE]"
            end,
        }
        table.insert(keyEntries, row)
        handle.refresh()
        refreshKeyList()
        return handle
    end

    -- Watermark (frosted top-left pill)
    local wm = newFrame(sg, UDim2.new(0, 240, 0, 26), UDim2.new(0, 14, 0, 14), C.panel, "Watermark")
    wm.BackgroundTransparency = 0.18
    corner(wm, 13)
    local wmStroke = stroke(wm, C.border_hi, 1, 0.5)
    gradient(wmStroke, C.accent, C.accent_hi, 0)

    local wmDot = newFrame(wm, UDim2.new(0, 6, 0, 6), UDim2.new(0, 10, 0.5, 0), C.accent, "Dot")
    wmDot.AnchorPoint = Vector2.new(0, 0.5)
    corner(wmDot, 3)

    local wmTitle = newLabel(wm, string.upper(title), 10, C.text, FONT_BOLD)
    wmTitle.Position = UDim2.new(0, 22, 0, 0)
    wmTitle.Size = UDim2.new(0, 64, 1, 0)

    local wmStats = newLabel(wm, "— FPS  ·  — MS", 8, C.text_sec, FONT_MONO)
    wmStats.AnchorPoint = Vector2.new(1, 0.5)
    wmStats.Position = UDim2.new(1, -12, 0.5, 0)
    wmStats.Size = UDim2.new(0, 140, 1, 0)
    wmStats.TextXAlignment = Enum.TextXAlignment.Right

    -- Show / hide
    setVisible = function(v)
        if v == root.Visible then return end
        if v then
            root.Visible = true
            root.Active = true
            root.Selectable = true
        else
            root.Visible = false
            closePopups()
            hideTooltip()
        end
    end

    Window.Toggle = function() setVisible(not root.Visible) end
    Window.Show = function() setVisible(true) end
    Window.Hide = function() setVisible(false) end

    -- Config storage
    local cfgFileName = "VANTA_" .. title:gsub("[^%w_%-]", "_") .. ".json"

    local function readStore()
        if type(readfile) == "function" and type(isfile) == "function" and isfile(cfgFileName) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(cfgFileName))
            end)
            if ok and type(data) == "table" then return data end
        end
        return {}
    end

    local function writeStore(store)
        if type(writefile) == "function" then
            pcall(function()
                writefile(cfgFileName, HttpService:JSONEncode(store))
            end)
        end
    end

    local refreshConfigLabel

    function Window:SaveConfig(name)
        name = tostring(name or "default")
        if name == "" then name = "default" end
        local data = {}
        for flag, item in pairs(registry) do
            local ok, value = pcall(item.get)
            if ok then data[flag] = VANTALib.encodeValue(value) end
        end
        local store = readStore()
        store[name] = data
        writeStore(store)
        if refreshConfigLabel then refreshConfigLabel() end
        VANTALib:Notify("Config", "Saved \"" .. name .. "\"", 2)
        return true
    end

    function Window:LoadConfig(name)
        name = tostring(name or "default")
        local store = readStore()
        local data = store[name]
        if type(data) ~= "table" then
            VANTALib:Notify("Config", "No config named \"" .. name .. "\"", 2)
            return false
        end
        for flag, raw in pairs(data) do
            local item = registry[flag]
            if item then
                local value = VANTALib.decodeValue(raw)
                if value ~= nil then
                    pcall(item.set, value)
                    if item.fire then pcall(item.fire, value) end
                end
            end
        end
        VANTALib:Notify("Config", "Loaded \"" .. name .. "\"", 2)
        return true
    end

    function Window:DeleteConfig(name)
        name = tostring(name or "default")
        local store = readStore()
        if store[name] == nil then
            VANTALib:Notify("Config", "Nothing to delete", 2)
            return false
        end
        store[name] = nil
        writeStore(store)
        if refreshConfigLabel then refreshConfigLabel() end
        VANTALib:Notify("Config", "Deleted \"" .. name .. "\"", 2)
        return true
    end

    function Window:ListConfigs()
        local names = {}
        for name in pairs(readStore()) do
            table.insert(names, name)
        end
        table.sort(names)
        return names
    end

    function Window:ResetDefaults()
        for _, item in pairs(registry) do
            pcall(item.set, item.default)
            if item.fire then pcall(item.fire, item.default) end
        end
        VANTALib:Notify("Config", "Defaults restored", 2)
    end

    -- Menu key
    claim("InputBegan", function(input, processed)
        if processed then return end
        if inputCtx.listening then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == toggleKey then
            setVisible(not root.Visible)
        end
    end)

    -- ── WIDGET API ──────────────────────────────────────────────────────
    local settingsTab

    local function makeItemAPI(items, sectionRef, tabData)
        local Section = {}
        Section._order = 0

        local function trackRow(row, labelText)
            table.insert(sectionRef.rows, row)
            if labelText then
                table.insert(tabData.filters, { row = row, text = string.lower(tostring(labelText)) })
                tabData.count = tabData.count + 1
            end
        end

        function Section:Toggle(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Toggle")
            local default = cfg.Default == true
            local flag = cfg.Flag
            local callback = cfg.Callback
            local desc = cfg.Description

            local row = newFrame(items, UDim2.new(1, 0, 0, 30), nil, C.panel, "ToggleRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local checked = default

            -- macOS pill switch
            local pill = newFrame(row, UDim2.new(0, 32, 0, 16), UDim2.new(1, -10, 0.5, 0),
                checked and C.accent or C.field, "Switch")
            pill.AnchorPoint = Vector2.new(1, 0.5)
            pill.ZIndex = 4
            corner(pill, 8)
            local pillStroke = stroke(pill, checked and C.accent_hi or C.border, 1, 0.35)
            local pillGrad = gradient(pill, C.accent, C.accent_hi, 0)
            pillGrad.Enabled = checked

            local knob = newFrame(pill, UDim2.new(0, 12, 0, 12),
                checked and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                C.white, "Knob")
            knob.AnchorPoint = Vector2.new(0, 0.5)
            knob.ZIndex = 5
            corner(knob, 6)

            local lbl = newLabel(row, name, 11, checked and C.text or C.text_sec, FONT_UI)
            lbl.AnchorPoint = Vector2.new(0, 0.5)
            lbl.Position = UDim2.new(0, 10, 0.5, 0)
            lbl.Size = UDim2.new(1, cfg.Settings and -78 or -52, 0, 15)
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = 3

            local hit = newButton(row, UDim2.new(1, cfg.Settings and -34 or 0, 1, 0), nil, C.panel)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 5

            local function render()
                pillGrad.Enabled = checked
                pill.BackgroundColor3 = checked and C.accent or C.field
                pillStroke.Color = checked and C.accent_hi or C.border
                lbl.TextColor3 = checked and C.text or C.text_sec
                TweenService:Create(knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = checked and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                }):Play()
            end

            hit.MouseEnter:Connect(function()
                row.BackgroundTransparency = 0.65
                row.BackgroundColor3 = C.row_hover
                if desc then showTooltip(desc) end
            end)
            hit.MouseLeave:Connect(function()
                row.BackgroundTransparency = 1
                if desc then hideTooltip() end
            end)
            hit.MouseButton1Click:Connect(function()
                checked = not checked
                render()
                if callback then callback(checked) end
                click()
            end)

            local function setState(v)
                checked = v == true
                render()
            end

            register(flag, default, function(v)
                setState(v)
            end, function()
                return checked
            end, function()
                if callback then callback(checked) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1

            if type(cfg.Settings) == "function" then
                local gearBtn = newButton(row, UDim2.new(0, 20, 0, 20), UDim2.new(1, -48, 0.5, 0), C.field)
                gearBtn.AnchorPoint = Vector2.new(1, 0.5)
                gearBtn.ZIndex = 5
                corner(gearBtn, 6)
                stroke(gearBtn, C.border, 1, 0.45)
                local gearLbl = newLabel(gearBtn, "⚙", 10, C.text_sec, FONT_UI)
                gearLbl.Size = UDim2.new(1, 0, 1, 0)
                gearLbl.TextXAlignment = Enum.TextXAlignment.Center
                gearLbl.ZIndex = 6

                local subBody = newFrame(items, UDim2.new(1, -12, 0, 0), nil, C.field, "ToggleSettings")
                subBody.AutomaticSize = Enum.AutomaticSize.Y
                subBody.Visible = false
                subBody.BackgroundTransparency = 0.35
                subBody.LayoutOrder = Section._order - 0.5
                corner(subBody, 8)
                stroke(subBody, C.accent_dim, 1, 0.35)
                local subLayout = Instance.new("UIListLayout")
                subLayout.SortOrder = Enum.SortOrder.LayoutOrder
                subLayout.Parent = subBody

                local subAPI = makeItemAPI(subBody, sectionRef, tabData)
                pcall(cfg.Settings, settingsTab, subAPI)

                gearBtn.MouseButton1Click:Connect(function()
                    subBody.Visible = not subBody.Visible
                    gearLbl.TextColor3 = subBody.Visible and C.accent_soft or C.text_sec
                    click()
                end)
            end

            local obj = {}
            function obj:Set(v) setState(v) end
            function obj:Get() return checked end
            return obj
        end

        function Section:Slider(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Slider")
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            if max <= min then max = min + 1 end
            local step = cfg.Step or 1
            if step <= 0 then step = 1 end
            local suffix = tostring(cfg.Suffix or "")
            local default = cfg.Default or (min + max) / 2
            local flag = cfg.Flag
            local callback = cfg.Callback

            local value = math.clamp(default, min, max)

            local row = newFrame(items, UDim2.new(1, 0, 0, 42), nil, C.panel, "SliderRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.Position = UDim2.new(0, 10, 0, 6)
            nameLbl.Size = UDim2.new(1, -90, 0, 14)
            nameLbl.ZIndex = 3

            local pct = newLabel(row, fmtNumber(value, step, suffix), 9, C.accent_soft, FONT_MONO)
            pct.AnchorPoint = Vector2.new(1, 0)
            pct.Position = UDim2.new(1, -10, 0, 6)
            pct.Size = UDim2.new(0, 76, 0, 14)
            pct.TextXAlignment = Enum.TextXAlignment.Right
            pct.ZIndex = 3

            local track = newFrame(row, UDim2.new(1, -20, 0, 6), UDim2.new(0, 10, 1, -14), C.field, "Track")
            track.ZIndex = 3
            corner(track, 3)
            stroke(track, C.border, 1, 0.5)

            local fill = newFrame(track, UDim2.new((value - min) / (max - min), 0, 1, 0), nil, C.accent, "Fill")
            fill.ZIndex = 4
            corner(fill, 3)
            gradient(fill, C.accent, C.accent_hi, 0)

            local function render(newVal, fire)
                local raw = math.clamp(newVal or value, min, max)
                local snapped = math.clamp(math.floor((raw - min) / step + 0.5) * step + min, min, max)
                value = snapped
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                pct.Text = fmtNumber(value, step, suffix)
                if fire and callback then callback(value) end
            end

            local dragging = false
            local function updateFromX(mouseX)
                local sz = math.max(1, track.AbsoluteSize.X)
                local x = math.clamp(mouseX - track.AbsolutePosition.X, 0, sz)
                render(min + (x / sz) * (max - min), true)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                dragging = true
                updateFromX(input.Position.X)
            end)

            claim("InputChanged", function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromX(input.Position.X)
                end
            end)

            claim("InputEnded", function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            local function setVal(v) render(v, false) end

            register(flag, default, function(v)
                setVal(v)
            end, function()
                return value
            end, function()
                if callback then callback(value) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return { Set = setVal, Get = function() return value end }
        end

        function Section:Stepper(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Value")
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            if max <= min then max = min + 1 end
            local step = cfg.Step or 1
            if step <= 0 then step = 1 end
            local suffix = tostring(cfg.Suffix or "")
            local default = cfg.Default or min
            local flag = cfg.Flag
            local callback = cfg.Callback

            local value = math.clamp(default, min, max)

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "StepperRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -120, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local plus = newButton(row, UDim2.new(0, 20, 0, 20), UDim2.new(1, -10, 0.5, 0), C.field)
            plus.AnchorPoint = Vector2.new(1, 0.5)
            plus.ZIndex = 4
            corner(plus, 6)
            stroke(plus, C.border, 1, 0.45)
            local plusLbl = newLabel(plus, "+", 12, C.text_sec, FONT_MONO)
            plusLbl.Size = UDim2.new(1, 0, 1, 0)
            plusLbl.TextXAlignment = Enum.TextXAlignment.Center

            local minus = newButton(row, UDim2.new(0, 20, 0, 20), UDim2.new(1, -86, 0.5, 0), C.field)
            minus.AnchorPoint = Vector2.new(1, 0.5)
            minus.ZIndex = 4
            corner(minus, 6)
            stroke(minus, C.border, 1, 0.45)
            local minusLbl = newLabel(minus, "-", 12, C.text_sec, FONT_MONO)
            minusLbl.Size = UDim2.new(1, 0, 1, 0)
            minusLbl.TextXAlignment = Enum.TextXAlignment.Center

            local field = newFrame(row, UDim2.new(0, 50, 0, 20), UDim2.new(1, -33, 0.5, 0), C.field, "Field")
            field.AnchorPoint = Vector2.new(1, 0.5)
            field.ZIndex = 3
            corner(field, 6)
            stroke(field, C.border, 1, 0.45)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -6, 1, 0)
            box.Position = UDim2.new(0, 3, 0, 0)
            box.BackgroundTransparency = 1
            box.Text = fmtNumber(value, step, suffix)
            box.TextColor3 = C.text
            applyFont(box, FONT_MONO)
            box.TextSize = 10
            box.ClearTextOnFocus = false
            box.Parent = field
            box.ZIndex = 5

            box.Focused:Connect(function() field.BackgroundColor3 = C.field_hover end)
            box.FocusLost:Connect(function()
                field.BackgroundColor3 = C.field
                local n = tonumber(box.Text:gsub("[^%d%.%-]", ""))
                if n then
                    value = math.clamp(math.floor(n / step + 0.5) * step, min, max)
                else
                    value = math.clamp(value, min, max)
                end
                box.Text = fmtNumber(value, step, suffix)
                if callback then callback(value) end
            end)

            plus.MouseButton1Click:Connect(function()
                value = math.clamp(value + step, min, max)
                box.Text = fmtNumber(value, step, suffix)
                if callback then callback(value) end
                click()
            end)

            minus.MouseButton1Click:Connect(function()
                value = math.clamp(value - step, min, max)
                box.Text = fmtNumber(value, step, suffix)
                if callback then callback(value) end
                click()
            end)

            register(flag, default, function(v)
                value = math.clamp(v, min, max)
                box.Text = fmtNumber(value, step, suffix)
            end, function()
                return value
            end, function()
                if callback then callback(value) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return {
                Set = function(_, v)
                    value = math.clamp(v, min, max)
                    box.Text = fmtNumber(value, step, suffix)
                end,
                Get = function() return value end
            }
        end

        function Section:Segmented(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Choice")
            local options = cfg.Options or {}
            local default = cfg.Default or options[1] or ""
            local flag = cfg.Flag
            local callback = cfg.Callback
            local selected = default

            local row = newFrame(items, UDim2.new(1, 0, 0, 52), nil, C.panel, "SegmentedRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.Position = UDim2.new(0, 10, 0, 5)
            nameLbl.Size = UDim2.new(1, -20, 0, 14)
            nameLbl.ZIndex = 3

            local strips = newFrame(row, UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 24), C.field, "Strips")
            strips.BackgroundTransparency = 0.2
            corner(strips, 7)
            stroke(strips, C.border, 1, 0.5)
            local stripsLayout = Instance.new("UIListLayout")
            stripsLayout.FillDirection = Enum.FillDirection.Horizontal
            stripsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            stripsLayout.Padding = UDim.new(0, 2)
            stripsLayout.Parent = strips

            local cells = {}

            local function render()
                for _, cell in ipairs(cells) do
                    local active = cell.value == selected
                    cell.btn.BackgroundColor3 = active and C.accent or C.field
                    cell.btn.BackgroundTransparency = active and 0 or 0.6
                    cell.grad.Enabled = active
                    cell.lbl.TextColor3 = active and C.white or C.text_dim
                end
            end

            for i, opt in ipairs(options) do
                local cell = newButton(strips, UDim2.new(1 / math.max(1, #options), -2, 1, 0), nil, C.field)
                cell.LayoutOrder = i
                cell.ZIndex = 4
                corner(cell, 6)
                local grad = gradient(cell, C.accent, C.accent_hi, 0)
                local lbl = newLabel(cell, string.upper(tostring(opt)), 8, C.text_dim, FONT_BOLD)
                lbl.Size = UDim2.new(1, -4, 1, 0)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.ZIndex = 5

                cell.MouseEnter:Connect(function()
                    if selected ~= opt then cell.BackgroundColor3 = C.field_hover end
                end)
                cell.MouseLeave:Connect(function()
                    if selected ~= opt then cell.BackgroundColor3 = C.field end
                end)
                cell.MouseButton1Click:Connect(function()
                    selected = opt
                    render()
                    if callback then callback(selected) end
                    click()
                end)

                cells[#cells + 1] = { btn = cell, lbl = lbl, grad = grad, value = opt }
            end
            render()

            local obj = {}
            function obj:Get() return selected end
            function obj:Set(v)
                selected = v
                render()
            end

            register(flag, default, function(v)
                selected = v
                render()
            end, function()
                return selected
            end, function()
                if callback then callback(selected) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:Dropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Dropdown")
            local options = cfg.Options or {}
            local default = cfg.Default or options[1] or ""
            local selected = default
            local flag = cfg.Flag
            local callback = cfg.Callback

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "DropdownRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(0.45, -10, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(0.55, -10, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 4
            corner(dropBtn, 6)
            stroke(dropBtn, C.border, 1, 0.45)

            local selLbl = newLabel(dropBtn, tostring(selected), 10, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 8, 0, 0)
            selLbl.Size = UDim2.new(1, -24, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "v", 8, C.text_dim, FONT_MONO)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, -16, 0, 0), nil, C.field, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.BackgroundTransparency = 0.1
            listHolder.LayoutOrder = Section._order + 0.5
            corner(listHolder, 8)
            stroke(listHolder, C.accent, 1, 0.4)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v2)
                listHolder.Visible = v2
                arrow.Text = v2 and "^" or "v"
                arrow.TextColor3 = v2 and C.accent_soft or C.text_dim
            end

            local myClose = function() setOpen(false) end
            registerPopup(myClose)

            local function renderList()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child.Name ~= "UIListLayout" and child:IsA("GuiObject") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = opt == selected
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 24), nil,
                        isSel and C.row_active or C.field)
                    optBtn.BackgroundTransparency = isSel and 0.2 or 0.6
                    optBtn.LayoutOrder = i
                    if isSel then
                        local mark = newFrame(optBtn, UDim2.new(0, 3, 1, -6), UDim2.new(0, 4, 0, 3), C.accent, "Mark")
                        corner(mark, 2)
                    end
                    local optLbl = newLabel(optBtn, tostring(opt), 10,
                        isSel and C.accent_soft or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 14, 0, 0)
                    optLbl.Size = UDim2.new(1, -18, 1, 0)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                        optBtn.BackgroundTransparency = 0.2
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.field
                        optBtn.BackgroundTransparency = isSel and 0.2 or 0.6
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        selLbl.Text = tostring(opt)
                        setOpen(false)
                        renderList()
                        if callback then callback(selected) end
                        click()
                    end)
                end
            end
            renderList()

            dropBtn.MouseEnter:Connect(function() dropBtn.BackgroundColor3 = C.field_hover end)
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.field end)
            dropBtn.MouseButton1Click:Connect(function()
                local want = not listHolder.Visible
                closePopups(myClose)
                setOpen(want)
                click()
            end)

            local obj = {}
            function obj:Get() return selected end
            function obj:Set(v)
                selected = v
                selLbl.Text = tostring(v)
                renderList()
            end

            register(flag, default, function(v)
                selected = v
                selLbl.Text = tostring(v)
                renderList()
            end, function()
                return selected
            end, function()
                if callback then callback(selected) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:MultiDropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Multi Select")
            local options = cfg.Options or {}
            local selected = {}
            for _, v in ipairs(cfg.Default or {}) do selected[v] = true end
            local flag = cfg.Flag
            local callback = cfg.Callback

            local function selectionList()
                local t = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then table.insert(t, opt) end
                end
                return t
            end

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "MultiDropdownRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(0.45, -10, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(0.55, -10, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 4
            corner(dropBtn, 6)
            stroke(dropBtn, C.border, 1, 0.45)

            local function summary()
                local t = selectionList()
                if #t == 0 then return "None"
                elseif #t == 1 then return t[1] end
                return t[1] .. " +" .. tostring(#t - 1)
            end

            local selLbl = newLabel(dropBtn, summary(), 10, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 8, 0, 0)
            selLbl.Size = UDim2.new(1, -24, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "v", 8, C.text_dim, FONT_MONO)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, -16, 0, 0), nil, C.field, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.BackgroundTransparency = 0.1
            listHolder.LayoutOrder = Section._order + 0.5
            corner(listHolder, 8)
            stroke(listHolder, C.accent, 1, 0.4)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v2)
                listHolder.Visible = v2
                arrow.Text = v2 and "^" or "v"
                arrow.TextColor3 = v2 and C.accent_soft or C.text_dim
            end

            local myClose = function() setOpen(false) end
            registerPopup(myClose)

            local function renderList()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child.Name ~= "UIListLayout" and child:IsA("GuiObject") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = selected[opt] == true
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 24), nil,
                        isSel and C.row_active or C.field)
                    optBtn.BackgroundTransparency = isSel and 0.2 or 0.6
                    optBtn.LayoutOrder = i
                    local box = newFrame(optBtn, UDim2.new(0, 12, 0, 12), UDim2.new(0, 10, 0.5, 0),
                        isSel and C.accent or C.field, "Check")
                    box.AnchorPoint = Vector2.new(0, 0.5)
                    corner(box, 3)
                    stroke(box, isSel and C.accent_hi or C.border, 1, 0.35)
                    if isSel then
                        local chkLbl = newLabel(box, "✓", 8, C.white, FONT_BOLD)
                        chkLbl.Size = UDim2.new(1, 0, 1, 0)
                        chkLbl.TextXAlignment = Enum.TextXAlignment.Center
                    end
                    local optLbl = newLabel(optBtn, tostring(opt), 10,
                        isSel and C.text or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 28, 0, 0)
                    optLbl.Size = UDim2.new(1, -32, 1, 0)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                        optBtn.BackgroundTransparency = 0.2
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.field
                        optBtn.BackgroundTransparency = isSel and 0.2 or 0.6
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        if selected[opt] then
                            selected[opt] = nil
                        else
                            selected[opt] = true
                        end
                        selLbl.Text = summary()
                        renderList()
                        if callback then callback(selectionList()) end
                        click()
                    end)
                end
            end
            renderList()

            dropBtn.MouseEnter:Connect(function() dropBtn.BackgroundColor3 = C.field_hover end)
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.field end)
            dropBtn.MouseButton1Click:Connect(function()
                local want = not listHolder.Visible
                closePopups(myClose)
                setOpen(want)
                click()
            end)

            local obj = {}
            function obj:Get() return selectionList() end
            function obj:Set(list)
                for _, opt in ipairs(options) do selected[opt] = false end
                for _, v in ipairs(list or {}) do selected[v] = true end
                selLbl.Text = summary()
                renderList()
            end
            function obj:SetOptions(opts)
                options = opts
                selLbl.Text = summary()
                renderList()
            end

            register(flag, cfg.Default or {}, function(list)
                for _, opt in ipairs(options) do selected[opt] = false end
                for _, v in ipairs(list or {}) do selected[v] = true end
                selLbl.Text = summary()
                renderList()
            end, function()
                return selectionList()
            end, function()
                if callback then callback(selectionList()) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:ColorPicker(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Color")
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local h, s, v = Color3.toHSV(default)
            local flag = cfg.Flag
            local callback = cfg.Callback

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "ColorPickerRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -90, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local swatch = newButton(row, UDim2.new(0, 68, 0, 18), UDim2.new(1, -10, 0.5, 0), default)
            swatch.AnchorPoint = Vector2.new(1, 0.5)
            swatch.ZIndex = 4
            corner(swatch, 6)
            local swatchStroke = stroke(swatch, C.border_hi, 1, 0.35)

            local hexLbl = newLabel(swatch, toHex(default), 8, C.white, FONT_MONO)
            hexLbl.Size = UDim2.new(1, 0, 1, 0)
            hexLbl.TextXAlignment = Enum.TextXAlignment.Center
            hexLbl.TextStrokeTransparency = 0.35
            hexLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            hexLbl.ZIndex = 5

            local panel = newFrame(items, UDim2.new(1, -16, 0, 0), nil, C.field, "Picker")
            panel.AutomaticSize = Enum.AutomaticSize.Y
            panel.Visible = false
            panel.BackgroundTransparency = 0.1
            panel.LayoutOrder = Section._order + 0.5
            corner(panel, 8)
            stroke(panel, C.accent, 1, 0.4)
            local pPad = Instance.new("UIPadding")
            pPad.PaddingTop = UDim.new(0, 8)
            pPad.PaddingBottom = UDim.new(0, 8)
            pPad.PaddingLeft = UDim.new(0, 8)
            pPad.PaddingRight = UDim.new(0, 8)
            pPad.Parent = panel
            local pLayout = Instance.new("UIListLayout")
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pLayout.Padding = UDim.new(0, 6)
            pLayout.Parent = panel

            local sv = newFrame(panel, UDim2.new(1, 0, 0, 96), nil, Color3.fromHSV(h, 1, 1), "SV")
            sv.LayoutOrder = 1
            corner(sv, 6)

            local wGrad = newFrame(sv, UDim2.new(1, 0, 1, 0), nil, C.white, "White")
            corner(wGrad, 6)
            local wGradObj = Instance.new("UIGradient")
            wGradObj.Color = ColorSequence.new(Color3.new(1, 1, 1))
            wGradObj.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            wGradObj.Parent = wGrad

            local bGrad = newFrame(sv, UDim2.new(1, 0, 1, 0), nil, Color3.new(0, 0, 0), "Black")
            corner(bGrad, 6)
            local bGradObj = Instance.new("UIGradient")
            bGradObj.Rotation = 90
            bGradObj.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            bGradObj.Parent = bGrad

            local cursor = newFrame(sv, UDim2.new(0, 8, 0, 8), UDim2.new(s, 0, 1 - v, 0), C.white, "Cursor")
            cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cursor.ZIndex = 5
            corner(cursor, 4)
            stroke(cursor, Color3.new(0, 0, 0), 1, 0)

            local hue = newFrame(panel, UDim2.new(1, 0, 0, 10), nil, C.white, "Hue")
            hue.LayoutOrder = 2
            corner(hue, 5)
            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
            })
            hueGrad.Parent = hue

            local hueCursor = newFrame(hue, UDim2.new(0, 6, 0, 12), UDim2.new(h, 0, 0.5, 0), C.white, "HueCursor")
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.ZIndex = 5
            corner(hueCursor, 3)
            stroke(hueCursor, Color3.new(0, 0, 0), 1, 0)

            local hexFrame = newFrame(panel, UDim2.new(1, 0, 0, 22), nil, C.panel, "HexFrame")
            hexFrame.LayoutOrder = 3
            corner(hexFrame, 6)
            stroke(hexFrame, C.border, 1, 0.45)

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -12, 1, 0)
            hexBox.Position = UDim2.new(0, 6, 0, 0)
            hexBox.BackgroundTransparency = 1
            hexBox.Text = toHex(default)
            hexBox.TextColor3 = C.text
            applyFont(hexBox, FONT_MONO)
            hexBox.TextSize = 10
            hexBox.ClearTextOnFocus = false
            hexBox.Parent = hexFrame

            local hexFocused = false

            local function render(call)
                local color = Color3.fromHSV(h, s, v)
                sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                cursor.BackgroundColor3 = color
                hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                hueCursor.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                swatch.BackgroundColor3 = color
                swatchStroke.Color = panel.Visible and C.accent or C.border_hi
                hexLbl.Text = toHex(color)
                if not hexFocused then
                    hexBox.Text = toHex(color)
                end
                if call and callback then callback(color) end
            end

            local draggingSV, draggingHue = false, false

            sv.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = true
                    local sz = sv.AbsoluteSize
                    s = math.clamp((input.Position.X - sv.AbsolutePosition.X) / math.max(1, sz.X), 0, 1)
                    v = 1 - math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / math.max(1, sz.Y), 0, 1)
                    render(true)
                end
            end)

            hue.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingHue = true
                    local sz = hue.AbsoluteSize.X
                    h = math.clamp((input.Position.X - hue.AbsolutePosition.X) / math.max(1, sz), 0, 1)
                    render(true)
                end
            end)

            claim("InputChanged", function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if draggingSV then
                    local sz = sv.AbsoluteSize
                    s = math.clamp((input.Position.X - sv.AbsolutePosition.X) / math.max(1, sz.X), 0, 1)
                    v = 1 - math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / math.max(1, sz.Y), 0, 1)
                    render(true)
                elseif draggingHue then
                    local sz = hue.AbsoluteSize.X
                    h = math.clamp((input.Position.X - hue.AbsolutePosition.X) / math.max(1, sz), 0, 1)
                    render(true)
                end
            end)

            claim("InputEnded", function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = false
                    draggingHue = false
                end
            end)

            local function setOpen(v2)
                panel.Visible = v2
                swatchStroke.Color = v2 and C.accent or C.border_hi
            end

            local myClose = function() setOpen(false) end
            registerPopup(myClose)

            swatch.MouseButton1Click:Connect(function()
                local want = not panel.Visible
                closePopups(myClose)
                setOpen(want)
                click()
            end)

            hexBox.Focused:Connect(function() hexFocused = true end)
            hexBox.FocusLost:Connect(function()
                hexFocused = false
                local parsed = fromHex(hexBox.Text)
                if parsed then
                    h, s, v = Color3.toHSV(parsed)
                end
                render(true)
            end)

            local obj = {}
            function obj:Get() return Color3.fromHSV(h, s, v) end
            function obj:Set(color)
                h, s, v = Color3.toHSV(color)
                render(false)
            end

            register(flag, default, function(color)
                h, s, v = Color3.toHSV(color)
                render(false)
            end, function()
                return Color3.fromHSV(h, s, v)
            end, function()
                if callback then callback(Color3.fromHSV(h, s, v)) end
            end)

            render(false)
            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:Button(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Button")
            local desc = cfg.Description
            local label = tostring(cfg.Text or "RUN")

            local row = newFrame(items, UDim2.new(1, 0, 0, (desc and 44 or 34)), nil, C.panel, "ButtonRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text, FONT_UI)
            if desc then
                nameLbl.Position = UDim2.new(0, 10, 0, 7)
            else
                nameLbl.AnchorPoint = Vector2.new(0, 0.5)
                nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            end
            nameLbl.Size = UDim2.new(1, -86, 0, 14)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            if desc then
                local descLbl = newLabel(row, tostring(desc), 9, C.text_dim, FONT_UI)
                descLbl.Position = UDim2.new(0, 10, 0, 23)
                descLbl.Size = UDim2.new(1, -86, 0, 12)
                descLbl.TextTruncate = Enum.TextTruncate.AtEnd
                descLbl.ZIndex = 3
            end

            local runBtn = newButton(row, UDim2.new(0, 58, 0, 22), UDim2.new(1, -10, 0.5, 0), C.field)
            runBtn.AnchorPoint = Vector2.new(1, 0.5)
            runBtn.ZIndex = 4
            corner(runBtn, 6)
            stroke(runBtn, C.border, 1, 0.4)
            local btnGrad = gradient(runBtn, C.accent, C.accent_hi, 0)
            btnGrad.Enabled = false

            local runLbl = newLabel(runBtn, label, 9, C.accent_soft, FONT_BOLD)
            runLbl.Size = UDim2.new(1, 0, 1, 0)
            runLbl.TextXAlignment = Enum.TextXAlignment.Center
            runLbl.ZIndex = 5

            runBtn.MouseEnter:Connect(function()
                btnGrad.Enabled = true
                runBtn.BackgroundColor3 = C.accent
                runLbl.TextColor3 = C.white
            end)
            runBtn.MouseLeave:Connect(function()
                btnGrad.Enabled = false
                runBtn.BackgroundColor3 = C.field
                runLbl.TextColor3 = C.accent_soft
            end)
            runBtn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
                click()
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return {}
        end

        function Section:TextBox(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Input")
            local placeholder = tostring(cfg.Placeholder or "...")
            local flag = cfg.Flag

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "TextBoxRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(0.42, -10, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local inputFrame = newFrame(row, UDim2.new(0.58, -10, 0, 22), UDim2.new(0.42, 0, 0.5, 0), C.field)
            inputFrame.AnchorPoint = Vector2.new(0, 0.5)
            inputFrame.ZIndex = 3
            corner(inputFrame, 6)
            local inputStroke = stroke(inputFrame, C.border, 1, 0.45)

            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, -12, 1, 0)
            inputBox.Position = UDim2.new(0, 6, 0, 0)
            inputBox.BackgroundTransparency = 1
            inputBox.Text = tostring(cfg.Default or "")
            inputBox.PlaceholderText = placeholder
            inputBox.TextColor3 = C.text
            inputBox.PlaceholderColor3 = C.text_dim
            applyFont(inputBox, FONT_UI)
            inputBox.TextSize = 10
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = inputFrame
            inputBox.ZIndex = 5

            inputBox.Focused:Connect(function()
                inputFrame.BackgroundColor3 = C.field_hover
                inputStroke.Color = C.accent
            end)
            inputBox.FocusLost:Connect(function(enterPressed)
                inputFrame.BackgroundColor3 = C.field
                inputStroke.Color = C.border
                if cfg.Callback then cfg.Callback(inputBox.Text) end
                if enterPressed and cfg.OnEnter then cfg.OnEnter(inputBox.Text) end
            end)

            local obj = {}
            function obj:Get() return inputBox.Text end
            function obj:Set(v) inputBox.Text = tostring(v) end

            register(flag, tostring(cfg.Default or ""), function(v)
                inputBox.Text = tostring(v)
            end, function()
                return inputBox.Text
            end, function()
                if cfg.Callback then cfg.Callback(inputBox.Text) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:Keybind(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Keybind")
            local bound = cfg.Default or Enum.KeyCode.Unknown
            local flag = cfg.Flag
            local listening = false

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "KeybindRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 10, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -110, 0, 15)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local kbBtn = newButton(row, UDim2.new(0, 84, 0, 20), UDim2.new(1, -10, 0.5, 0), C.field)
            kbBtn.AnchorPoint = Vector2.new(1, 0.5)
            kbBtn.ZIndex = 4
            corner(kbBtn, 6)
            local kbStroke = stroke(kbBtn, C.border, 1, 0.45)

            local kbLbl = newLabel(kbBtn, "[" .. bound.Name:upper() .. "]", 8, C.accent_soft, FONT_MONO)
            kbLbl.Size = UDim2.new(1, 0, 1, 0)
            kbLbl.TextXAlignment = Enum.TextXAlignment.Center
            kbLbl.ZIndex = 5

            local keyEntry = addKeyEntry(name, function() return bound end)

            kbBtn.MouseEnter:Connect(function() if not listening then kbBtn.BackgroundColor3 = C.field_hover end end)
            kbBtn.MouseLeave:Connect(function() if not listening then kbBtn.BackgroundColor3 = C.field end end)
            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                inputCtx.listening = true
                kbLbl.Text = "[...]"
                kbLbl.TextColor3 = C.white
                kbStroke.Color = C.accent
                kbBtn.BackgroundColor3 = C.row_active
                click()
            end)

            claim("InputBegan", function(input, processed)
                if not listening or processed then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                bound = input.KeyCode
                listening = false
                inputCtx.listening = false
                kbLbl.Text = "[" .. bound.Name:upper() .. "]"
                kbLbl.TextColor3 = C.accent_soft
                kbStroke.Color = C.border
                kbBtn.BackgroundColor3 = C.field
                keyEntry.refresh()
                if cfg.Callback then cfg.Callback(bound) end
            end)

            local obj = {}
            function obj:Get() return bound end
            function obj:Set(key)
                bound = key
                kbLbl.Text = "[" .. key.Name:upper() .. "]"
                keyEntry.refresh()
            end

            register(flag, cfg.Default or Enum.KeyCode.Unknown, function(key)
                bound = key
                kbLbl.Text = "[" .. key.Name:upper() .. "]"
                keyEntry.refresh()
            end, function()
                return bound
            end, function()
                if cfg.Callback then cfg.Callback(bound) end
            end)

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:Progress(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Progress")
            local value = math.clamp(cfg.Default or 0, 0, 1)

            local row = newFrame(items, UDim2.new(1, 0, 0, 40), nil, C.panel, "ProgressRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 11, C.text_sec, FONT_UI)
            nameLbl.Position = UDim2.new(0, 10, 0, 6)
            nameLbl.Size = UDim2.new(1, -80, 0, 14)
            nameLbl.ZIndex = 3

            local pctLbl = newLabel(row, tostring(math.floor(value * 100 + 0.5)) .. "%", 9, C.accent_soft, FONT_MONO)
            pctLbl.AnchorPoint = Vector2.new(1, 0)
            pctLbl.Position = UDim2.new(1, -10, 0, 6)
            pctLbl.Size = UDim2.new(0, 66, 0, 14)
            pctLbl.TextXAlignment = Enum.TextXAlignment.Right
            pctLbl.ZIndex = 3

            local track = newFrame(row, UDim2.new(1, -20, 0, 5), UDim2.new(0, 10, 1, -13), C.field, "Track")
            track.ZIndex = 2
            corner(track, 3)

            local fill = newFrame(track, UDim2.new(value, 0, 1, 0), nil, C.accent, "Fill")
            corner(fill, 3)
            gradient(fill, C.accent, C.accent_hi, 0)
            fill.ZIndex = 3

            local function render(text)
                fill.Size = UDim2.new(value, 0, 1, 0)
                pctLbl.Text = text or tostring(math.floor(value * 100 + 0.5)) .. "%"
            end

            local obj = {}
            function obj:Set(v, text)
                value = math.clamp(v or 0, 0, 1)
                render(text)
            end
            function obj:Get() return value end

            trackRow(row, name)
            Section._order = Section._order + 1
            return obj
        end

        function Section:Label(cfg)
            cfg = cfg or {}
            local text = tostring(cfg.Text or "")
            local row = newFrame(items, UDim2.new(1, 0, 0, 22), nil, C.panel, "LabelRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local lbl = newLabel(row, text, 9, cfg.Color or C.text_dim, FONT_MONO)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.Size = UDim2.new(1, -20, 1, 0)
            lbl.ZIndex = 4

            trackRow(row, nil)
            Section._order = Section._order + 1
            return {
                Set = function(_, t) lbl.Text = tostring(t) end,
                Get = function() return lbl.Text end,
            }
        end

        function Section:Separator()
            Section._order = Section._order + 1
            local sepRow = newFrame(items, UDim2.new(1, 0, 0, 9), nil, C.panel, "SeparatorRow")
            sepRow.BackgroundTransparency = 1
            sepRow.LayoutOrder = Section._order
            local line = newFrame(sepRow, UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 0.5, 0), C.border, "Separator")
            line.AnchorPoint = Vector2.new(0, 0.5)
            line.BackgroundTransparency = 0.5
            trackRow(sepRow, nil)
            Section._order = Section._order + 1
        end

        return Section
    end

    -- ── TAB (Fatality Top Pill + Dual-Column Frosted Groupboxes) ──────────
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tostring(tabConfig.Name or ("TAB " .. (#Window._tabs + 1)))
        local pinned = tabConfig.Pinned == true
        local tabData = { filters = {}, sections = {}, count = 0 }

        local tabBtn = newButton(tabScroll, UDim2.new(0, 0, 0, 24), nil, C.field)
        tabBtn.AutomaticSize = Enum.AutomaticSize.X
        tabBtn.LayoutOrder = pinned and 900 or (#Window._tabs + 1)
        tabBtn.BackgroundTransparency = 0.6
        corner(tabBtn, 7)
        local tabStroke = stroke(tabBtn, C.border, 1, 0.65)
        local tabGrad = gradient(tabBtn, C.accent, C.accent_hi, 0)
        tabGrad.Enabled = false

        local tPad = Instance.new("UIPadding")
        tPad.PaddingLeft = UDim.new(0, 12)
        tPad.PaddingRight = UDim.new(0, 12)
        tPad.Parent = tabBtn

        local tabLbl = newLabel(tabBtn, string.upper(tabName), 9, C.text_dim, FONT_BOLD)
        tabLbl.AutomaticSize = Enum.AutomaticSize.X
        tabLbl.Size = UDim2.new(0, 0, 1, 0)
        tabLbl.TextXAlignment = Enum.TextXAlignment.Center

        local page = newFrame(content, UDim2.new(1, 0, 1, 0), nil, C.window, tabName .. "Page")
        page.BackgroundTransparency = 1
        page.Visible = false

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = C.accent
        scroll.ScrollBarImageTransparency = 0.35
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop = UDim.new(0, 10)
        pagePad.PaddingLeft = UDim.new(0, 12)
        pagePad.PaddingRight = UDim.new(0, 12)
        pagePad.PaddingBottom = UDim.new(0, 12)
        pagePad.Parent = scroll

        -- Dual-column container (Fatality style)
        local columns = newFrame(scroll, UDim2.new(1, 0, 0, 0), nil, C.window, "Columns")
        columns.BackgroundTransparency = 1
        columns.AutomaticSize = Enum.AutomaticSize.Y

        local leftCol = newFrame(columns, UDim2.new(0.5, -5, 0, 0), UDim2.new(0, 0, 0, 0), C.window, "LeftCol")
        leftCol.BackgroundTransparency = 1
        leftCol.AutomaticSize = Enum.AutomaticSize.Y
        local leftLayout = Instance.new("UIListLayout")
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Padding = UDim.new(0, 10)
        leftLayout.Parent = leftCol

        local rightCol = newFrame(columns, UDim2.new(0.5, -5, 0, 0), UDim2.new(0.5, 5, 0, 0), C.window, "RightCol")
        rightCol.BackgroundTransparency = 1
        rightCol.AutomaticSize = Enum.AutomaticSize.Y
        local rightLayout = Instance.new("UIListLayout")
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Padding = UDim.new(0, 10)
        rightLayout.Parent = rightCol

        local emptyLbl = newLabel(page, "NO MATCHING FEATURES", 10, C.text_dim, FONT_MONO)
        emptyLbl.Size = UDim2.new(1, 0, 1, 0)
        emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
        emptyLbl.Visible = false
        emptyLbl.ZIndex = 5

        local function recompute()
            for _, s in ipairs(tabData.sections) do
                local any = false
                for _, row in ipairs(s.rows) do
                    if row.Visible then
                        any = true
                        break
                    end
                end
                s.frame.Visible = any
            end
            if tabData.count > 0 then
                local q = searchBox.Text or ""
                local visible = 0
                for _, entry in ipairs(tabData.filters) do
                    if entry.row.Visible then visible = visible + 1 end
                end
                emptyLbl.Visible = (visible == 0 and q ~= "")
            else
                emptyLbl.Visible = false
            end
        end

        local function applyFilter(q)
            q = string.lower(q or "")
            for _, entry in ipairs(tabData.filters) do
                entry.row.Visible = (q == "" or string.find(entry.text, q, 1, true) ~= nil)
            end
            recompute()
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if Window._active and Window._active.page == page then
                applyFilter(searchBox.Text)
            end
        end)

        local entry = { page = page, btn = tabBtn, lbl = tabLbl, grad = tabGrad, stroke = tabStroke, applyFilter = applyFilter }
        table.insert(Window._tabs, entry)

        local function activate()
            closePopups()
            hideTooltip()
            for _, e in ipairs(Window._tabs) do
                e.page.Visible = false
                e.btn.BackgroundColor3 = C.field
                e.btn.BackgroundTransparency = 0.6
                e.grad.Enabled = false
                e.stroke.Color = C.border
                e.lbl.TextColor3 = C.text_dim
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = C.accent
            tabBtn.BackgroundTransparency = 0.1
            tabGrad.Enabled = true
            tabStroke.Color = C.accent_soft
            tabLbl.TextColor3 = C.white
            Window._active = entry
            applyFilter(searchBox.Text)
        end

        tabBtn.MouseButton1Click:Connect(function()
            if Window._active ~= entry then
                activate()
                click()
            end
        end)
        tabBtn.MouseEnter:Connect(function()
            if Window._active ~= entry then
                tabBtn.BackgroundColor3 = C.row_hover
                tabBtn.BackgroundTransparency = 0.25
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active ~= entry then
                tabBtn.BackgroundColor3 = C.field
                tabBtn.BackgroundTransparency = 0.6
            end
        end)

        if not pinned and Window._active == nil then activate() end

        local Tab = {}
        Tab._page = page
        Tab._scroll = scroll
        Tab._order = 0

        function Tab:Section(sectionName)
            sectionName = tostring(sectionName or "SECTION")
            Tab._order = Tab._order + 1

            -- Alternate left / right columns automatically
            local targetCol = (Tab._order % 2 == 1) and leftCol or rightCol

            local sec = newFrame(targetCol, UDim2.new(1, 0, 0, 0), nil, C.panel, sectionName .. "Section")
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.LayoutOrder = Tab._order
            sec.ClipsDescendants = true
            corner(sec, 10)
            trackGlass(sec, 0.24)
            stroke(sec, C.border_hi, 1, 0.6)

            -- Top accent hairline inside card
            local secLine = newFrame(sec, UDim2.new(1, 0, 0, 2), nil, C.accent, "AccentLine")
            gradient(secLine, C.accent, C.accent_hi, 0)

            local hdr = newFrame(sec, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 2), C.header, "Header")
            hdr.BackgroundTransparency = 0.5

            local hdrDot = newFrame(hdr, UDim2.new(0, 6, 0, 6), UDim2.new(0, 10, 0.5, 0), C.accent, "Dot")
            hdrDot.AnchorPoint = Vector2.new(0, 0.5)
            corner(hdrDot, 3)

            local hdrLbl = newLabel(hdr, string.upper(sectionName), 10, C.text, FONT_BOLD)
            hdrLbl.Position = UDim2.new(0, 22, 0, 0)
            hdrLbl.Size = UDim2.new(1, -50, 1, 0)

            local chev = newLabel(hdr, "-", 11, C.text_dim, FONT_MONO)
            chev.AnchorPoint = Vector2.new(1, 0.5)
            chev.Position = UDim2.new(1, -10, 0.5, 0)
            chev.Size = UDim2.new(0, 14, 1, 0)
            chev.TextXAlignment = Enum.TextXAlignment.Right

            local body = newFrame(sec, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 30), C.panel, "Body")
            body.BackgroundTransparency = 1
            body.AutomaticSize = Enum.AutomaticSize.Y
            local bodyPad = Instance.new("UIPadding")
            bodyPad.PaddingBottom = UDim.new(0, 4)
            bodyPad.Parent = body
            local bodyList = Instance.new("UIListLayout")
            bodyList.SortOrder = Enum.SortOrder.LayoutOrder
            bodyList.Parent = body

            local hdrHit = newButton(hdr, UDim2.new(1, 0, 1, 0), nil, C.header)
            hdrHit.BackgroundTransparency = 1
            hdrHit.ZIndex = 4

            local collapsed = false
            hdrHit.MouseButton1Click:Connect(function()
                collapsed = not collapsed
                body.Visible = not collapsed
                chev.Text = collapsed and "+" or "-"
                hdrLbl.TextColor3 = collapsed and C.text_dim or C.text
                click()
            end)
            hdrHit.MouseEnter:Connect(function() hdr.BackgroundTransparency = 0.25 end)
            hdrHit.MouseLeave:Connect(function() hdr.BackgroundTransparency = 0.5 end)

            local sectionRef = { frame = sec, rows = {} }
            table.insert(tabData.sections, sectionRef)

            return makeItemAPI(body, sectionRef, tabData)
        end

        return Tab
    end

    -- ── SETTINGS TAB ──────────────────────────────────────────────────────
    settingsTab = Window:Tab({ Name = "Settings", Pinned = true })

    local interfaceSec = settingsTab:Section("Interface")
    interfaceSec:Label({ Text = "MENU KEY   " .. string.upper(toggleKey.Name), Color = C.text_sec })

    interfaceSec:Keybind({
        Name = "Menu Keybind",
        Default = toggleKey,
        Flag = "menuKey",
        Callback = function(key)
            toggleKey = key
            keyHintLbl.Text = string.upper(key.Name) .. "  ·  MENU"
            click()
        end,
    })

    interfaceSec:Button({
        Name = "Hide Menu",
        Description = "Collapse UI, keep hotkeys active",
        Callback = function() setVisible(false) end,
    })

    interfaceSec:Button({
        Name = "Unload UI",
        Description = "Remove menu and hooks from memory",
        Callback = function() Window:Unload() end,
    })

    local appearanceSec = settingsTab:Section("Appearance")

    appearanceSec:Stepper({
        Name = "Interface Scale",
        Min = 0.8,
        Max = 1.3,
        Step = 0.05,
        Default = scale,
        Suffix = "x",
        Flag = "guiScale",
        Callback = function(v) setScale(v) end,
    })

    appearanceSec:Stepper({
        Name = "Glass Opacity",
        Min = 35,
        Max = 100,
        Step = 5,
        Default = 100,
        Suffix = "%",
        Flag = "opacity",
        Callback = function(v) applyOpacity(v / 100) end,
    })

    appearanceSec:Toggle({
        Name = "Interface Sounds",
        Description = "Short click on interaction",
        Default = soundsEnabled,
        Flag = "sounds",
        Callback = function(v) soundsEnabled = v end,
    })

    appearanceSec:Toggle({
        Name = "Watermark",
        Description = "Floating performance pill",
        Default = true,
        Flag = "watermark",
        Callback = function(v) wm.Visible = v end,
    })

    appearanceSec:Toggle({
        Name = "Keybind List",
        Description = "Show active hotkeys on screen",
        Default = false,
        Flag = "keylist",
        Callback = function(v)
            keyListVisible = v
            refreshKeyList()
        end,
    })

    local configSec = settingsTab:Section("Configuration")
    local cfgName = configSec:TextBox({
        Name = "Config Name",
        Placeholder = "default",
        Default = "default",
    })

    local cfgList = configSec:Label({ Text = "CONFIGS   NONE" })

    configSec:Button({
        Name = "Save Config",
        Description = "Write current values to a slot",
        Callback = function()
            Window:SaveConfig(cfgName:Get())
            refreshConfigLabel()
        end,
    })

    configSec:Button({
        Name = "Load Config",
        Description = "Apply a saved slot",
        Callback = function() Window:LoadConfig(cfgName:Get()) end,
    })

    configSec:Button({
        Name = "Delete Config",
        Description = "Remove a saved slot",
        Callback = function()
            Window:DeleteConfig(cfgName:Get())
            refreshConfigLabel()
        end,
    })

    configSec:Button({
        Name = "Reset Defaults",
        Description = "Restore every widget to default",
        Callback = function() Window:ResetDefaults() end,
    })

    refreshConfigLabel = function()
        local names = Window:ListConfigs()
        cfgList:Set("CONFIGS   " .. (#names > 0 and table.concat(names, "   ") or "NONE"))
    end
    refreshConfigLabel()

    local buildSec = settingsTab:Section("Build")
    buildSec:Label({ Text = "VANTA  v" .. VERSION .. "   GLASS × FATALITY" })
    buildSec:Label({ Text = "TOGGLE   " .. string.upper(toggleKey.Name) .. "   /   RED DOT TO UNLOAD", Color = C.text_dim })

    -- ── PERFORMANCE LOOP ──────────────────────────────────────────────────
    task.spawn(function()
        local frames = 0
        local conn = RunService.RenderStepped:Connect(function()
            frames = frames + 1
        end)
        while true do
            task.wait(1)
            if Window._unloaded or not root.Parent then break end
            local ping = 0
            local ok = pcall(function()
                local stats = game:GetService("Stats")
                ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            subLbl.Text = LocalPlayer.DisplayName .. "  ·  " .. (ok and (tostring(ping) .. " MS") or "--- MS")
            wmStats.Text = tostring(frames) .. " FPS  ·  " .. (ok and tostring(ping) or "---") .. " MS"
            frames = 0
        end
        if conn then conn:Disconnect() end
    end)

    -- ── UNLOAD ────────────────────────────────────────────────────────────
    function Window:Unload()
        if Window._unloaded then return end
        Window._unloaded = true
        root.Visible = false
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        openPopups = {}
        sg:Destroy()
        if notifGui then
            notifGui:Destroy()
            notifGui = nil
            notifHolder = nil
        end
    end

    return Window
end

return VANTALib
