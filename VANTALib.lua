--[[
    VANTALib — Source-engine / CS:GO (Panorama) styled Roblox UI library
    version: 3.0.0

    aesthetic: flat square panels, hairline separators, monospace readouts,
               weathered gold accents, no rounded corners, no window close button.

    load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/VANTALib.lua"))()

    every window is built with a pinned SETTINGS tab:
      · rebind the menu key
      · interface scale, background opacity, interface sounds
      · watermark and on-screen keybind list
      · config slots (save / load / delete / reset defaults)
      · hide the menu or unload the whole interface

    widgets:
      Toggle, Slider, Stepper, Segmented, Dropdown, MultiDropdown, ColorPicker,
      Button, TextBox, Keybind, Progress, Label, Separator
]]

local VANTALib = {}
VANTALib.__index = VANTALib
VANTALib.Version = "3.0.0"
local VERSION = VANTALib.Version

-- ───────────────────────────────────────────────────────────────────────────
--  PALETTE — Source / CS:GO panorama
-- ───────────────────────────────────────────────────────────────────────────
local C = {
    window      = Color3.fromRGB(17, 18, 20),
    window_top  = Color3.fromRGB(24, 25, 28),
    rail        = Color3.fromRGB(12, 13, 15),
    rail_top    = Color3.fromRGB(18, 19, 22),
    panel       = Color3.fromRGB(21, 22, 25),
    panel_alt   = Color3.fromRGB(24, 25, 29),
    header      = Color3.fromRGB(28, 29, 34),
    row_hover   = Color3.fromRGB(33, 35, 40),
    row_active  = Color3.fromRGB(40, 42, 48),
    field       = Color3.fromRGB(13, 14, 16),
    field_hover = Color3.fromRGB(30, 32, 37),
    accent      = Color3.fromRGB(200, 154, 62),
    accent_hi   = Color3.fromRGB(238, 196, 110),
    accent_dim  = Color3.fromRGB(104, 80, 34),
    border      = Color3.fromRGB(38, 40, 46),
    border_hi   = Color3.fromRGB(62, 65, 73),
    text        = Color3.fromRGB(232, 233, 236),
    text_sec    = Color3.fromRGB(162, 165, 172),
    text_dim    = Color3.fromRGB(104, 108, 116),
    success     = Color3.fromRGB(126, 178, 96),
    danger      = Color3.fromRGB(198, 76, 62),
    white       = Color3.fromRGB(255, 255, 255),
}

local FONT_UI   = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_MONO = Enum.Font.Code

-- ───────────────────────────────────────────────────────────────────────────
--  SERVICES
-- ───────────────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────────────────
--  BACKGROUND OPACITY (text stays readable)
-- ───────────────────────────────────────────────────────────────────────────
local bgObjects = {}
local bgBase = {}
local uiOpacity = 1

local function trackBg(obj)
    bgObjects[#bgObjects + 1] = obj
end

local function applyOpacity(a)
    uiOpacity = math.clamp(a, 0.15, 1)
    for i = 1, #bgObjects do
        local obj = bgObjects[i]
        if obj and obj.Parent then
            if bgBase[obj] == nil then bgBase[obj] = obj.BackgroundTransparency end
            obj.BackgroundTransparency = 1 - (1 - bgBase[obj]) * uiOpacity
        end
    end
end

-- ───────────────────────────────────────────────────────────────────────────
--  UTILITY
-- ───────────────────────────────────────────────────────────────────────────
local function newFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1, 0, 1, 0)
    f.Position = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = color or C.panel
    f.BorderSizePixel = 0
    f.Name = name or "Frame"
    f.Parent = parent
    trackBg(f)
    return f
end

local function newLabel(parent, text, textSize, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = textSize or 12
    l.TextColor3 = color or C.text
    l.Font = font or FONT_UI
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
    trackBg(b)
    return b
end

local function stroke(gui, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = gui
    return s
end

local function gradient(gui, from, to, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(from, to)
    g.Rotation = rotation or 90
    g.Parent = gui
    return g
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

local function playClick(enabled)
    if not enabled then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        s.Volume = 0.3
        SoundService:PlayLocalSound(s)
        task.delay(0.3, function()
            if s then s:Destroy() end
        end)
    end)
end

local function encodeValue(v)
    local t = typeof(v)
    if t == "Color3" then
        return { ["$c"] = toHex(v) }
    elseif t == "EnumItem" then
        return { ["$k"] = v.Name }
    elseif t == "table" then
        local out = {}
        for i, item in ipairs(v) do
            out[i] = encodeValue(item)
        end
        return out
    end
    return v
end

local function decodeValue(v)
    if type(v) == "table" then
        if v["$c"] then return fromHex(v["$c"]) end
        if v["$k"] then
            local ok, key = pcall(function() return Enum.KeyCode[v["$k"]] end)
            if ok then return key end
            return nil
        end
        local list = {}
        for i = 1, #v do list[i] = v[i] end
        return list
    end
    return v
end

-- ───────────────────────────────────────────────────────────────────────────
--  FEED (top-right notices)
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

    notifHolder = newFrame(notifGui, UDim2.new(0, 286, 1, 0), UDim2.new(1, -298, 0, 14))
    notifHolder.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
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

    local card = newFrame(holder, UDim2.new(1, 0, 0, 56), nil, C.panel, "Notice")
    card.LayoutOrder = notifSeq
    stroke(card, C.border, 1)
    newFrame(card, UDim2.new(0, 2, 1, 0), nil, C.accent, "Bar")

    local t = newLabel(card, string.upper(tostring(title or "")), 10, C.accent_hi, FONT_BOLD)
    t.Position = UDim2.new(0, 12, 0, 8)
    t.Size = UDim2.new(1, -20, 0, 14)

    local b = newLabel(card, tostring(body or ""), 10, C.text_sec, FONT_UI)
    b.Position = UDim2.new(0, 12, 0, 24)
    b.Size = UDim2.new(1, -20, 0, 26)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top

    local prog = newFrame(card, UDim2.new(1, -2, 0, 1), UDim2.new(0, 2, 1, -1), C.accent_dim, "Progress")
    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 1) }):Play()

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
local TITLE_H = 38
local CRUMB_H = 22
local RAIL_W  = 136
local HDR_H   = 32

function VANTALib:CreateWindow(config)
    config = config or {}
    local title = tostring(config.Title or "VANTA")
    local width = config.Width or 600
    local height = config.Height or 470
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    local scale = config.Scale or 1
    local soundsEnabled = config.Sounds == true

    local connections = {}
    local inputCtx = { listening = false }
    local openPopups = {}
    local keyEntries = {}
    local keyListVisible = false
    local registry = {}

    local function claim(event, fn)
        local conn = UserInputService[event]:Connect(fn)
        table.insert(connections, conn)
        return conn
    end

    local function click()
        playClick(soundsEnabled)
    end

    local function viewportSize()
        local cam = workspace.CurrentCamera
        if cam then return cam.ViewportSize end
        return Vector2.new(1280, 720)
    end

    -- screen gui + scaling holder
    local sg = Instance.new("ScreenGui")
    sg.Name = "VANTA_" .. title
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 5
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local holder = newFrame(sg, UDim2.new(1, 0, 1, 0), nil, C.window, "Holder")
    holder.BackgroundTransparency = 1
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale
    uiScale.Parent = holder

    local vp = viewportSize()
    local root = newFrame(holder, UDim2.new(0, width, 0, height),
        UDim2.new(0, (vp.X - width * scale) / 2 / scale, 0, (vp.Y - height * scale) / 2 / scale),
        C.window, "Window")
    gradient(root, C.window_top, C.window, 90)
    stroke(root, C.border_hi, 1)

    -- fade veil
    local fade = Instance.new("Frame")
    fade.Name = "Fade"
    fade.Size = UDim2.new(1, 0, 1, 0)
    fade.BackgroundColor3 = C.window
    fade.BackgroundTransparency = 1
    fade.BorderSizePixel = 0
    fade.ZIndex = 400
    fade.Active = false
    fade.Parent = root

    newFrame(root, UDim2.new(1, 0, 0, 2), nil, C.accent, "TopAccent")

    -- ── TITLE BAR ─────────────────────────────────────────────────────────
    local titlebar = newFrame(root, UDim2.new(1, 0, 0, TITLE_H), UDim2.new(0, 0, 0, 2), C.header, "Titlebar")
    gradient(titlebar, C.header, C.panel, 90)

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.new(0, 26, 0, 26)
    avatar.Position = UDim2.new(0, 12, 0, 6)
    avatar.BackgroundColor3 = C.field
    avatar.BorderSizePixel = 0
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Parent = titlebar
    stroke(avatar, C.border_hi, 1)

    local avatarFallback = newLabel(avatar, "?", 12, C.text_dim, FONT_BOLD)
    avatarFallback.Size = UDim2.new(1, 0, 1, 0)
    avatarFallback.TextXAlignment = Enum.TextXAlignment.Center

    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and thumb and avatar.Parent then
            avatar.Image = thumb
            avatarFallback.Visible = false
        end
    end)

    local titleLbl = newLabel(titlebar, string.upper(title):sub(1, 26), 12, C.text, FONT_BOLD)
    titleLbl.Position = UDim2.new(0, 48, 0, 5)
    titleLbl.Size = UDim2.new(1, -260, 0, 15)

    local subLbl = newLabel(titlebar, "CONNECTING", 8, C.text_dim, FONT_MONO)
    subLbl.Position = UDim2.new(0, 48, 0, 20)
    subLbl.Size = UDim2.new(1, -260, 0, 11)

    local verLbl = newLabel(titlebar, "VANTA  v" .. VERSION, 8, C.text_dim, FONT_MONO)
    verLbl.AnchorPoint = Vector2.new(1, 0)
    verLbl.Position = UDim2.new(1, -12, 0, 7)
    verLbl.Size = UDim2.new(0, 200, 0, 11)
    verLbl.TextXAlignment = Enum.TextXAlignment.Right

    local keyHintLbl = newLabel(titlebar, string.upper(toggleKey.Name) .. "  :  MENU", 8, C.accent_dim, FONT_MONO)
    keyHintLbl.AnchorPoint = Vector2.new(1, 0)
    keyHintLbl.Position = UDim2.new(1, -12, 0, 21)
    keyHintLbl.Size = UDim2.new(0, 200, 0, 11)
    keyHintLbl.TextXAlignment = Enum.TextXAlignment.Right

    newFrame(root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TITLE_H + 2), C.border, "BAR_LINE")

    -- ── BREADCRUMB ────────────────────────────────────────────────────────
    local crumb = newFrame(root, UDim2.new(1, 0, 0, CRUMB_H), UDim2.new(0, 0, 0, TITLE_H + 3), C.rail, "Crumb")
    gradient(crumb, C.rail_top, C.rail, 90)

    local crumbRoot = newLabel(crumb, "VANTA", 8, C.accent, FONT_BOLD)
    crumbRoot.Position = UDim2.new(0, 12, 0, 0)
    crumbRoot.Size = UDim2.new(0, 48, 1, 0)

    local crumbTab = newLabel(crumb, "", 8, C.text_sec, FONT_MONO)
    crumbTab.Position = UDim2.new(0, 64, 0, 0)
    crumbTab.Size = UDim2.new(0, 200, 1, 0)

    local crumbSection = newLabel(crumb, "", 8, C.text_dim, FONT_MONO)
    crumbSection.Position = UDim2.new(0, 170, 0, 0)
    crumbSection.Size = UDim2.new(1, -320, 1, 0)

    local dot = newFrame(crumb, UDim2.new(0, 4, 0, 4), UDim2.new(1, -60, 0.5, 0), C.success, "Dot")
    dot.AnchorPoint = Vector2.new(0, 0.5)

    local readyLbl = newLabel(crumb, "READY", 8, C.text_dim, FONT_MONO)
    readyLbl.AnchorPoint = Vector2.new(1, 0.5)
    readyLbl.Position = UDim2.new(1, -12, 0.5, 0)
    readyLbl.Size = UDim2.new(0, 44, 0, 11)
    readyLbl.TextXAlignment = Enum.TextXAlignment.Right

    local function setCrumbSection(name)
        if name and name ~= "" then
            crumbSection.Text = "/  " .. string.upper(name)
        else
            crumbSection.Text = ""
        end
    end

    -- ── RAIL ──────────────────────────────────────────────────────────────
    local rail = newFrame(root, UDim2.new(0, RAIL_W, 1, -(TITLE_H + CRUMB_H + 4)),
        UDim2.new(0, 0, 0, TITLE_H + CRUMB_H + 4), C.rail, "Rail")
    gradient(rail, C.rail_top, C.rail, 90)
    newFrame(root, UDim2.new(0, 1, 1, -(TITLE_H + CRUMB_H + 4)),
        UDim2.new(0, RAIL_W, 0, TITLE_H + CRUMB_H + 4), C.border, "RailLine")

    local railInner = newFrame(rail, UDim2.new(1, 0, 1, -26), nil, C.rail, "RailTabs")
    railInner.BackgroundTransparency = 1
    local railList = Instance.new("UIListLayout")
    railList.SortOrder = Enum.SortOrder.LayoutOrder
    railList.Padding = UDim.new(0, 1)
    railList.Parent = railInner
    local railPad = Instance.new("UIPadding")
    railPad.PaddingTop = UDim.new(0, 6)
    railPad.Parent = railInner

    local railFoot = newFrame(rail, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 1, -25), C.rail, "Foot")
    newFrame(railFoot, UDim2.new(1, 0, 0, 1), nil, C.border, "Line")
    local footLbl = newLabel(railFoot, "BUILD " .. VERSION, 8, C.text_dim, FONT_MONO)
    footLbl.Position = UDim2.new(0, 12, 0, 0)
    footLbl.Size = UDim2.new(1, -16, 1, 0)

    -- ── CONTENT ───────────────────────────────────────────────────────────
    local content = newFrame(root, UDim2.new(1, -(RAIL_W + 1), 1, -(TITLE_H + CRUMB_H + 4)),
        UDim2.new(0, RAIL_W + 1, 0, TITLE_H + CRUMB_H + 4), C.window, "Content")

    -- ── TOOLTIP ───────────────────────────────────────────────────────────
    local tooltip = newFrame(root, UDim2.new(0, 0, 0, 0), nil, C.header, "Tooltip")
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.Visible = false
    tooltip.ZIndex = 300
    stroke(tooltip, C.border_hi, 1)
    local ttpPad = Instance.new("UIPadding")
    ttpPad.PaddingLeft = UDim.new(0, 8)
    ttpPad.PaddingRight = UDim.new(0, 8)
    ttpPad.PaddingTop = UDim.new(0, 6)
    ttpPad.PaddingBottom = UDim.new(0, 6)
    ttpPad.Parent = tooltip
    local ttpLbl = newLabel(tooltip, "", 10, C.text_sec, FONT_UI)
    ttpLbl.Size = UDim2.new(0, 220, 0, 0)
    ttpLbl.TextWrapped = true
    ttpLbl.TextYAlignment = Enum.TextYAlignment.Top
    ttpLbl.AutomaticSize = Enum.AutomaticSize.Y
    ttpLbl.ZIndex = 301

    local function positionTooltip()
        if not tooltip.Visible then return end
        local mouse = UserInputService:GetMouseLocation()
        local relX = (mouse.X - root.AbsolutePosition.X) / scale
        local relY = (mouse.Y - root.AbsolutePosition.Y) / scale
        local maxX = (root.AbsoluteSize.X / scale) - (tooltip.AbsoluteSize.X / scale) - 4
        local maxY = (root.AbsoluteSize.Y / scale) - (tooltip.AbsoluteSize.Y / scale) - 4
        tooltip.Position = UDim2.fromOffset(
            math.clamp(relX + 14, 4, math.max(4, maxX)),
            math.clamp(relY + 18, 4, math.max(4, maxY))
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

    -- ── POPUPS ────────────────────────────────────────────────────────────
    local function registerPopup(closeFn)
        table.insert(openPopups, closeFn)
        return closeFn
    end

    local function closePopups(except)
        for i = #openPopups, 1, -1 do
            local fn = openPopups[i]
            if fn ~= except then
                pcall(fn)
                table.remove(openPopups, i)
            end
        end
    end

    -- ── WINDOW OBJECT ─────────────────────────────────────────────────────
    local Window = {}
    Window._tabs = {}
    Window._active = nil
    Window._gui = sg
    Window._win = root
    Window._unloaded = false

    -- ── KEYBIND OVERLAY ───────────────────────────────────────────────────
    local keyHolder = newFrame(sg, UDim2.new(0, 196, 0, 0), UDim2.new(0, 12, 1, -12), nil, "KeyList")
    keyHolder.BackgroundTransparency = 1
    keyHolder.AutomaticSize = Enum.AutomaticSize.Y
    keyHolder.AnchorPoint = Vector2.new(0, 1)
    keyHolder.Visible = false
    local keyLayout = Instance.new("UIListLayout")
    keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keyLayout.Padding = UDim.new(0, 2)
    keyLayout.Parent = keyHolder

    local keyHead = newFrame(keyHolder, UDim2.new(1, 0, 0, 18), nil, nil, "Head")
    keyHead.BackgroundTransparency = 1
    keyHead.LayoutOrder = 0
    local keyHeadLbl = newLabel(keyHead, "KEYBINDS", 8, C.text_dim, FONT_BOLD)
    keyHeadLbl.Size = UDim2.new(1, 0, 1, 0)

    local function refreshKeyList()
        keyHolder.Visible = keyListVisible and (#keyEntries > 0)
    end

    local function addKeyEntry(name, getKey)
        local row = newFrame(keyHolder, UDim2.new(1, 0, 0, 22), nil, C.panel, "KeyEntry")
        row.LayoutOrder = #keyEntries + 1
        stroke(row, C.border, 1)
        newFrame(row, UDim2.new(0, 2, 1, 0), nil, C.accent, "Bar")
        local nl = newLabel(row, string.upper(tostring(name)), 8, C.text_sec, FONT_MONO)
        nl.Position = UDim2.new(0, 10, 0, 0)
        nl.Size = UDim2.new(1, -80, 1, 0)
        nl.TextTruncate = Enum.TextTruncate.AtEnd
        local kl = newLabel(row, "", 8, C.accent_hi, FONT_MONO)
        kl.Position = UDim2.new(0, 0, 0, 0)
        kl.Size = UDim2.new(1, -10, 1, 0)
        kl.TextXAlignment = Enum.TextXAlignment.Right
        local handle = {
            row = row,
            label = kl,
            refresh = function()
                local key = getKey()
                kl.Text = key and string.upper(key.Name) or "NONE"
            end,
        }
        table.insert(keyEntries, row)
        handle.refresh()
        refreshKeyList()
        return handle
    end

    -- ── WATERMARK ─────────────────────────────────────────────────────────
    local wm = newFrame(sg, UDim2.new(0, 200, 0, 24), UDim2.new(0, 12, 0, 12), C.panel, "Watermark")
    stroke(wm, C.border, 1)
    newFrame(wm, UDim2.new(0, 2, 1, 0), nil, C.accent, "Bar")
    local wmTitle = newLabel(wm, "VANTA", 10, C.accent_hi, FONT_BOLD)
    wmTitle.Position = UDim2.new(0, 10, 0, 0)
    wmTitle.Size = UDim2.new(0, 50, 1, 0)
    local wmVer = newLabel(wm, "v" .. VERSION, 8, C.text_dim, FONT_MONO)
    wmVer.Position = UDim2.new(0, 60, 0, 0)
    wmVer.Size = UDim2.new(0, 50, 1, 0)
    local wmStats = newLabel(wm, "— FPS", 8, C.text_sec, FONT_MONO)
    wmStats.AnchorPoint = Vector2.new(1, 0.5)
    wmStats.Position = UDim2.new(1, -10, 0.5, 0)
    wmStats.Size = UDim2.new(0, 110, 1, 0)
    wmStats.TextXAlignment = Enum.TextXAlignment.Right

    -- ── SHOW / HIDE ───────────────────────────────────────────────────────
    local function setVisible(v)
        if v == root.Visible then return end
        if v then
            root.Visible = true
            fade.BackgroundTransparency = 0.55
            TweenService:Create(fade, TweenInfo.new(0.14), { BackgroundTransparency = 1 }):Play()
            hideTooltip()
        else
            hideTooltip()
            local tw = TweenService:Create(fade, TweenInfo.new(0.1), { BackgroundTransparency = 0.55 })
            tw.Completed:Connect(function()
                if not root.Visible then return end
                root.Visible = false
                fade.BackgroundTransparency = 1
            end)
            tw:Play()
        end
    end

    Window.Toggle = function()
        setVisible(not root.Visible)
    end
    Window.Show = function() setVisible(true) end
    Window.Hide = function() setVisible(false) end

    local function setScale(v)
        scale = math.clamp(v, 0.5, 1.6)
        uiScale.Scale = scale
        local vp2 = viewportSize()
        root.Position = UDim2.new(0, (vp2.X - width * scale) / 2 / scale, 0, (vp2.Y - height * scale) / 2 / scale)
        hideTooltip()
    end

    -- ── CONFIG STORAGE ────────────────────────────────────────────────────
    local safeTitle = tostring(title):gsub("[^%w_%-]", "_")
    local configFile = "VANTA_" .. safeTitle .. ".json"
    local memoryStore = {}

    local function readStore()
        if type(readfile) == "function" and type(isfile) == "function" and isfile(configFile) then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(readfile(configFile))
            end)
            if ok and type(data) == "table" then return data end
        end
        return memoryStore
    end

    local function writeStore(store)
        memoryStore = store
        if type(writefile) == "function" then
            pcall(function()
                writefile(configFile, HttpService:JSONEncode(store))
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
            if ok then data[flag] = encodeValue(value) end
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
                local value = decodeValue(raw)
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

    -- ── MENU KEY ──────────────────────────────────────────────────────────
    claim("InputBegan", function(input, processed)
        if processed then return end
        if inputCtx.listening then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == toggleKey then
            setVisible(not root.Visible)
        end
    end)

    -- ── ITEM API ──────────────────────────────────────────────────────────
    local function makeItemAPI(items, sectionRef, tabData)
        local Section = { _order = 0 }
        local stripe = 0

        local function newRow(h, text, tip)
            Section._order = Section._order + 1
            stripe = stripe + 1
            local baseColor = (stripe % 2 == 0) and C.panel_alt or C.panel
            local row = newFrame(items, UDim2.new(1, 0, 0, h), nil, baseColor, "Row")
            row.LayoutOrder = Section._order

            local sep = newFrame(row, UDim2.new(1, -24, 0, 1), UDim2.new(0, 12, 1, -1), C.border, "Sep")
            sep.ZIndex = 2

            local hoverBar = newFrame(row, UDim2.new(0, 2, 1, 0), nil, C.accent, "HoverBar")
            hoverBar.Visible = false
            hoverBar.ZIndex = 2

            row.MouseEnter:Connect(function()
                row.BackgroundColor3 = C.row_hover
                hoverBar.Visible = true
                if tip then showTooltip(tip) end
            end)
            row.MouseLeave:Connect(function()
                row.BackgroundColor3 = baseColor
                hoverBar.Visible = false
                hideTooltip()
            end)

            table.insert(sectionRef.rows, row)
            if text and text ~= "" then
                table.insert(tabData.filters, { row = row, text = string.lower(text), section = sectionRef })
            end
            tabData.count = tabData.count + 1
            if tabData.refreshCount then tabData.refreshCount() end
            return row
        end

        local function register(flag, default, setter, getter, fire)
            if not flag then return end
            registry[flag] = {
                default = default,
                set = setter,
                get = getter,
                fire = fire,
            }
        end

        -- ── TOGGLE ────────────────────────────────────────────────────────
        function Section:Toggle(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Toggle")
            local desc = cfg.Description
            local hasSettings = cfg.Settings ~= nil
            local state = cfg.Default == true

            local row = newRow(desc and 50 or 38, name .. " " .. tostring(desc or ""), cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            if desc then
                nameLbl.Position = UDim2.new(0, 12, 0, 9)
            else
                nameLbl.AnchorPoint = Vector2.new(0, 0.5)
                nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            end
            nameLbl.Size = UDim2.new(1, -170, 0, 15)
            nameLbl.ZIndex = 3

            if desc then
                local d = newLabel(row, tostring(desc), 10, C.text_dim, FONT_UI)
                d.Position = UDim2.new(0, 12, 0, 27)
                d.Size = UDim2.new(1, -170, 0, 13)
                d.ZIndex = 3
            end

            local stateLbl = newLabel(row, state and "ON" or "OFF", 9,
                state and C.accent_hi or C.text_dim, FONT_MONO)
            stateLbl.AnchorPoint = Vector2.new(1, 0.5)
            stateLbl.Position = UDim2.new(1, -38, 0.5, 0)
            stateLbl.Size = UDim2.new(0, 34, 0, 12)
            stateLbl.TextXAlignment = Enum.TextXAlignment.Right
            stateLbl.ZIndex = 3

            local box = newButton(row, UDim2.new(0, 18, 0, 18), UDim2.new(1, -12, 0.5, 0),
                state and C.accent or C.field)
            box.AnchorPoint = Vector2.new(1, 0.5)
            box.ZIndex = 4
            local boxStroke = stroke(box, state and C.accent_hi or C.border, 1)

            local check = newLabel(box, "✓", 10, C.window, FONT_BOLD)
            check.Size = UDim2.new(1, 0, 1, 0)
            check.TextXAlignment = Enum.TextXAlignment.Center
            check.Visible = state
            check.ZIndex = 5

            local panel, gearBtn, gearGlyph

            local function render()
                if state then
                    box.BackgroundColor3 = C.accent
                    boxStroke.Color = C.accent_hi
                    check.Visible = true
                    stateLbl.Text = "ON"
                    stateLbl.TextColor3 = C.accent_hi
                else
                    box.BackgroundColor3 = C.field
                    boxStroke.Color = C.border
                    check.Visible = false
                    stateLbl.Text = "OFF"
                    stateLbl.TextColor3 = C.text_dim
                end
            end

            local function setState(v, silent)
                state = v and true or false
                render()
                if not silent and cfg.Callback then cfg.Callback(state) end
            end

            if hasSettings then
                panel = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.field, "Settings")
                panel.AutomaticSize = Enum.AutomaticSize.Y
                panel.Visible = false
                panel.LayoutOrder = Section._order + 0.5
                newFrame(panel, UDim2.new(0, 2, 1, 0), nil, C.accent_dim, "Edge")

                local cfgItems = newFrame(panel, UDim2.new(1, 0, 0, 0), nil, C.field, "SettingsBody")
                cfgItems.BackgroundTransparency = 1
                cfgItems.AutomaticSize = Enum.AutomaticSize.Y
                local cfgLayout = Instance.new("UIListLayout")
                cfgLayout.SortOrder = Enum.SortOrder.LayoutOrder
                cfgLayout.Parent = cfgItems

                local cfgSection = { rows = sectionRef.rows }
                local cfgAPI = makeItemAPI(cfgItems, cfgSection, tabData)
                cfg.Settings(cfgAPI, cfgAPI)

                gearBtn = newButton(row, UDim2.new(0, 22, 0, 18), UDim2.new(1, -92, 0.5, 0), C.field)
                gearBtn.AnchorPoint = Vector2.new(1, 0.5)
                gearBtn.ZIndex = 4
                stroke(gearBtn, C.border, 1)

                gearGlyph = newLabel(gearBtn, "•••", 9, C.text_sec, FONT_MONO)
                gearGlyph.Size = UDim2.new(1, 0, 1, 0)
                gearGlyph.TextXAlignment = Enum.TextXAlignment.Center
                gearGlyph.ZIndex = 5

                gearBtn.MouseEnter:Connect(function()
                    gearBtn.BackgroundColor3 = C.field_hover
                end)
                gearBtn.MouseLeave:Connect(function()
                    gearBtn.BackgroundColor3 = panel.Visible and C.accent_dim or C.field
                end)
                gearBtn.MouseButton1Click:Connect(function()
                    panel.Visible = not panel.Visible
                    gearGlyph.TextColor3 = panel.Visible and C.accent_hi or C.text_sec
                    gearBtn.BackgroundColor3 = panel.Visible and C.accent_dim or C.field
                    click()
                end)
            end

            local hit = newButton(row, UDim2.new(1, 0, 1, 0), nil, C.panel)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 2
            hit.MouseButton1Click:Connect(function()
                setState(not state)
                click()
            end)

            local obj = {}
            function obj:Set(v) setState(v, true) end
            function obj:Get() return state end
            function obj:ToggleState() setState(not state) end

            register(cfg.Flag, cfg.Default == true,
                function(v) setState(v, true) end,
                function() return state end,
                function() if cfg.Callback then cfg.Callback(state) end end)

            render()
            return obj
        end

        -- ── SLIDER ────────────────────────────────────────────────────────
        function Section:Slider(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Slider")
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            if max <= min then max = min + 1 end
            local step = cfg.Step or 1
            if step <= 0 then step = 1 end
            local suffix = tostring(cfg.Suffix or "")
            local value = math.clamp(cfg.Default or min, min, max)

            local row = newRow(48, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 12, 0, 7)
            nameLbl.Size = UDim2.new(1, -170, 0, 15)
            nameLbl.ZIndex = 3

            local valLbl = newLabel(row, fmtNumber(value, step, suffix), 11, C.accent_hi, FONT_MONO)
            valLbl.AnchorPoint = Vector2.new(1, 0)
            valLbl.Position = UDim2.new(1, -12, 0, 7)
            valLbl.Size = UDim2.new(0, 140, 0, 14)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.ZIndex = 3

            local track = newFrame(row, UDim2.new(1, -24, 0, 3), UDim2.new(0, 12, 1, -14), C.field, "Track")
            track.ZIndex = 2

            local fill = newFrame(track, UDim2.new(0, 0, 1, 0), nil, C.accent, "Fill")
            gradient(fill, C.accent_dim, C.accent, 0)
            fill.ZIndex = 3

            for i = 0, 10 do
                local tick = newFrame(track, UDim2.new(0, 1, 0, 3), UDim2.new(i / 10, 0, 0, 0), C.field, "Tick")
                tick.AnchorPoint = Vector2.new(0.5, 0)
                tick.ZIndex = 4
            end

            local knob = newFrame(track, UDim2.new(0, 7, 0, 14),
                UDim2.new(0, 0, 0.5, 0), C.accent_hi, "Knob")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            stroke(knob, C.window, 1)
            knob.ZIndex = 5

            local hit = newButton(row, UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 1, -22), C.field)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 6

            local function render()
                local pct = (value - min) / (max - min)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text = fmtNumber(value, step, suffix)
            end

            local dragging = false
            local function setFromX(x)
                local abs = hit.AbsolutePosition
                local w = math.max(hit.AbsoluteSize.X, 1)
                local rel = math.clamp((x - abs.X) / w, 0, 1)
                local snapped = math.floor((min + (max - min) * rel) / step + 0.5) * step
                value = math.clamp(snapped, min, max)
                render()
                if cfg.Callback then cfg.Callback(value) end
            end

            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)
            claim("InputChanged", function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                setFromX(input.Position.X)
            end)
            claim("InputEnded", function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            local obj = {}
            function obj:Set(v)
                value = math.clamp(v, min, max)
                render()
            end
            function obj:Get() return value end

            register(cfg.Flag, cfg.Default or min, function(v)
                value = math.clamp(v, min, max)
                render()
            end, function() return value end, function()
                if cfg.Callback then cfg.Callback(value) end
            end)

            render()
            return obj
        end

        -- ── STEPPER ───────────────────────────────────────────────────────
        function Section:Stepper(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Value")
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            if max <= min then max = min + 1 end
            local step = cfg.Step or 1
            if step <= 0 then step = 1 end
            local suffix = tostring(cfg.Suffix or "")
            local value = math.clamp(cfg.Default or min, min, max)

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -200, 0, 15)
            nameLbl.ZIndex = 3

            local plus = newButton(row, UDim2.new(0, 20, 0, 22), UDim2.new(1, -12, 0.5, 0), C.field)
            plus.AnchorPoint = Vector2.new(1, 0.5)
            plus.ZIndex = 4
            stroke(plus, C.border, 1)
            local plusLbl = newLabel(plus, "+", 13, C.text_sec, FONT_MONO)
            plusLbl.Size = UDim2.new(1, 0, 1, 0)
            plusLbl.TextXAlignment = Enum.TextXAlignment.Center
            plusLbl.ZIndex = 5

            local minus = newButton(row, UDim2.new(0, 20, 0, 22), UDim2.new(1, -88, 0.5, 0), C.field)
            minus.AnchorPoint = Vector2.new(1, 0.5)
            minus.ZIndex = 4
            stroke(minus, C.border, 1)
            local minusLbl = newLabel(minus, "-", 13, C.text_sec, FONT_MONO)
            minusLbl.Size = UDim2.new(1, 0, 1, 0)
            minusLbl.TextXAlignment = Enum.TextXAlignment.Center
            minusLbl.ZIndex = 5

            local field = newFrame(row, UDim2.new(0, 54, 0, 22), UDim2.new(1, -36, 0.5, 0), C.field, "Field")
            field.AnchorPoint = Vector2.new(1, 0.5)
            field.ZIndex = 3
            local fieldStroke = stroke(field, C.border, 1)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -8, 1, 0)
            box.Position = UDim2.new(0, 4, 0, 0)
            box.BackgroundTransparency = 1
            box.Text = fmtNumber(value, step, suffix)
            box.TextColor3 = C.text
            box.Font = FONT_MONO
            box.TextSize = 11
            box.ClearTextOnFocus = false
            box.Parent = field
            box.ZIndex = 5

            local function render()
                box.Text = fmtNumber(value, step, suffix)
            end

            local function commit(v, call)
                value = math.clamp(math.floor(v / step + 0.5) * step, min, max)
                render()
                if call and cfg.Callback then cfg.Callback(value) end
            end

            plus.MouseEnter:Connect(function() plus.BackgroundColor3 = C.field_hover end)
            plus.MouseLeave:Connect(function() plus.BackgroundColor3 = C.field end)
            minus.MouseEnter:Connect(function() minus.BackgroundColor3 = C.field_hover end)
            minus.MouseLeave:Connect(function() minus.BackgroundColor3 = C.field end)

            plus.MouseButton1Click:Connect(function() commit(value + step, true); click() end)
            minus.MouseButton1Click:Connect(function() commit(value - step, true); click() end)

            box.Focused:Connect(function() fieldStroke.Color = C.accent end)
            box.FocusLost:Connect(function()
                fieldStroke.Color = C.border
                local n = tonumber(box.Text:gsub("[^%d%.%-]", ""))
                if n then commit(n, true) else render() end
            end)

            local obj = {}
            function obj:Set(v) commit(v, false) end
            function obj:Get() return value end

            register(cfg.Flag, cfg.Default or min, function(v) commit(v, false) end,
                function() return value end, function()
                    if cfg.Callback then cfg.Callback(value) end
                end)

            return obj
        end

        -- ── SEGMENTED ─────────────────────────────────────────────────────
        function Section:Segmented(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Choice")
            local options = cfg.Options or {}
            local selected = cfg.Default or options[1] or ""

            local row = newRow(62, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 12, 0, 8)
            nameLbl.Size = UDim2.new(1, -24, 0, 15)
            nameLbl.ZIndex = 3

            local strips = newFrame(row, UDim2.new(1, -24, 0, 22), UDim2.new(0, 12, 0, 30), C.panel, "Strips")
            strips.BackgroundTransparency = 1
            strips.ZIndex = 3

            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            layout.Parent = strips

            local cells = {}

            local function render()
                for _, cell in ipairs(cells) do
                    local active = cell.value == selected
                    cell.btn.BackgroundColor3 = active and C.accent or C.field
                    cell.stroke.Color = active and C.accent_hi or C.border
                    cell.lbl.TextColor3 = active and C.window or C.text_sec
                end
            end

            for i, opt in ipairs(options) do
                local cell = newButton(strips, UDim2.new(1 / #options, -2, 1, 0), nil, C.field)
                cell.LayoutOrder = i
                cell.ZIndex = 4
                local st = stroke(cell, C.border, 1)
                local lbl = newLabel(cell, string.upper(tostring(opt)), 9, C.text_sec, FONT_BOLD)
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
                    if cfg.Callback then cfg.Callback(selected) end
                    click()
                end)

                cells[#cells + 1] = { btn = cell, lbl = lbl, stroke = st, value = opt }
            end
            render()

            local obj = {}
            function obj:Get() return selected end
            function obj:Set(v)
                selected = v
                render()
            end

            register(cfg.Flag, cfg.Default or options[1], function(v)
                selected = v
                render()
            end, function() return selected end, function()
                if cfg.Callback then cfg.Callback(selected) end
            end)

            return obj
        end

        -- ── DROPDOWN ──────────────────────────────────────────────────────
        function Section:Dropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Dropdown")
            local options = cfg.Options or {}
            local selected = cfg.Default or options[1] or ""

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(0.42, 0, 0, 15)
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(0.55, -12, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 4
            stroke(dropBtn, C.border, 1)

            local selLbl = newLabel(dropBtn, tostring(selected), 10, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 9, 0, 0)
            selLbl.Size = UDim2.new(1, -30, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "v", 9, C.text_dim, FONT_MONO)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.rail, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.accent_dim, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v)
                listHolder.Visible = v
                arrow.Text = v and "^" or "v"
                arrow.TextColor3 = v and C.accent_hi or C.text_dim
            end

            local myClose = function() setOpen(false) end
            registerPopup(myClose)

            local renderList
            renderList = function()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = opt == selected
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 26), nil,
                        isSel and C.row_active or C.rail)
                    optBtn.LayoutOrder = i
                    if isSel then
                        newFrame(optBtn, UDim2.new(0, 2, 1, 0), nil, C.accent, "Mark")
                    end
                    local optLbl = newLabel(optBtn, tostring(opt), 10,
                        isSel and C.accent_hi or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 12, 0, 0)
                    optLbl.Size = UDim2.new(1, -16, 1, 0)
                    optLbl.ZIndex = 2
                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.rail
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        selLbl.Text = tostring(opt)
                        setOpen(false)
                        renderList()
                        if cfg.Callback then cfg.Callback(selected) end
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
            function obj:SetOptions(opts)
                options = opts
                renderList()
            end

            register(cfg.Flag, cfg.Default or options[1], function(v)
                selected = v
                selLbl.Text = tostring(v)
                renderList()
            end, function() return selected end, function()
                if cfg.Callback then cfg.Callback(selected) end
            end)

            return obj
        end

        -- ── MULTI DROPDOWN ────────────────────────────────────────────────
        function Section:MultiDropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Multi Select")
            local options = cfg.Options or {}
            local selected = {}
            for _, v in ipairs(cfg.Default or {}) do selected[v] = true end

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(0.42, 0, 0, 15)
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(0.55, -12, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 4
            stroke(dropBtn, C.border, 1)

            local function selectionList()
                local t = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then table.insert(t, opt) end
                end
                return t
            end

            local function summary()
                local t = selectionList()
                if #t == 0 then return "NONE" end
                if #t == 1 then return t[1] end
                return t[1] .. "  +" .. tostring(#t - 1)
            end

            local selLbl = newLabel(dropBtn, summary(), 10, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 9, 0, 0)
            selLbl.Size = UDim2.new(1, -30, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "v", 9, C.text_dim, FONT_MONO)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.Size = UDim2.new(0, 16, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.rail, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.accent_dim, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v)
                listHolder.Visible = v
                arrow.Text = v and "^" or "v"
                arrow.TextColor3 = v and C.accent_hi or C.text_dim
            end

            local myClose = function() setOpen(false) end
            registerPopup(myClose)

            local renderList
            renderList = function()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = selected[opt] == true
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 26), nil,
                        isSel and C.row_active or C.rail)
                    optBtn.LayoutOrder = i

                    local box = newFrame(optBtn, UDim2.new(0, 12, 0, 12), UDim2.new(0, 10, 0.5, 0),
                        isSel and C.accent or C.field, "Check")
                    box.AnchorPoint = Vector2.new(0, 0.5)
                    stroke(box, isSel and C.accent_hi or C.border, 1)
                    if isSel then
                        local mark = newLabel(box, "✓", 8, C.window, FONT_BOLD)
                        mark.Size = UDim2.new(1, 0, 1, 0)
                        mark.TextXAlignment = Enum.TextXAlignment.Center
                    end

                    local optLbl = newLabel(optBtn, tostring(opt), 10,
                        isSel and C.text or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 30, 0, 0)
                    optLbl.Size = UDim2.new(1, -34, 1, 0)
                    optLbl.ZIndex = 2

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.rail
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        if selected[opt] then
                            selected[opt] = nil
                        else
                            selected[opt] = true
                        end
                        selLbl.Text = summary()
                        renderList()
                        if cfg.Callback then cfg.Callback(selectionList()) end
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
                selected = {}
                for _, v in ipairs(list) do selected[v] = true end
                selLbl.Text = summary()
                renderList()
            end
            function obj:SetOptions(opts)
                options = opts
                selLbl.Text = summary()
                renderList()
            end

            register(cfg.Flag, cfg.Default or {}, function(list)
                selected = {}
                for _, v in ipairs(list) do selected[v] = true end
                selLbl.Text = summary()
                renderList()
            end, function() return selectionList() end, function()
                if cfg.Callback then cfg.Callback(selectionList()) end
            end)

            return obj
        end

        -- ── COLOR PICKER ──────────────────────────────────────────────────
        function Section:ColorPicker(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Color")
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local h, s, v = Color3.toHSV(default)
            local hexFocused = false

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -120, 0, 15)
            nameLbl.ZIndex = 3

            local swatch = newButton(row, UDim2.new(0, 84, 0, 20), UDim2.new(1, -12, 0.5, 0), default)
            swatch.AnchorPoint = Vector2.new(1, 0.5)
            swatch.ZIndex = 4
            local swatchStroke = stroke(swatch, C.border_hi, 1)

            local hexLbl = newLabel(swatch, toHex(default), 9, C.white, FONT_MONO)
            hexLbl.Size = UDim2.new(1, 0, 1, 0)
            hexLbl.TextXAlignment = Enum.TextXAlignment.Center
            hexLbl.TextStrokeTransparency = 0.4
            hexLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            hexLbl.ZIndex = 5

            local panel = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.rail, "Picker")
            panel.AutomaticSize = Enum.AutomaticSize.Y
            panel.Visible = false
            panel.LayoutOrder = Section._order + 0.5
            stroke(panel, C.accent_dim, 1)
            local pPad = Instance.new("UIPadding")
            pPad.PaddingAll = UDim.new(0, 10)
            pPad.Parent = panel
            local pLayout = Instance.new("UIListLayout")
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pLayout.Padding = UDim.new(0, 8)
            pLayout.Parent = panel

            local sv = newFrame(panel, UDim2.new(1, 0, 0, 110), nil, Color3.fromHSV(h, 1, 1), "SV")
            sv.LayoutOrder = 1

            local wGrad = newFrame(sv, UDim2.new(1, 0, 1, 0), nil, C.white, "White")
            local wGradObj = Instance.new("UIGradient")
            wGradObj.Color = ColorSequence.new(Color3.new(1, 1, 1))
            wGradObj.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            wGradObj.Parent = wGrad

            local bGrad = newFrame(sv, UDim2.new(1, 0, 1, 0), nil, Color3.new(0, 0, 0), "Black")
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
            stroke(cursor, C.white, 1)

            local hue = newFrame(panel, UDim2.new(1, 0, 0, 10), nil, C.white, "Hue")
            hue.LayoutOrder = 2
            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,     Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5, 1, 1)),
                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                ColorSequenceKeypoint.new(1,     Color3.fromHSV(1, 1, 1)),
            })
            hueGrad.Parent = hue

            local hueCursor = newFrame(hue, UDim2.new(0, 6, 0, 12), UDim2.new(h, 0, 0.5, 0),
                Color3.fromHSV(h, 1, 1), "HueCursor")
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.ZIndex = 5
            stroke(hueCursor, C.white, 1)

            local presets = newFrame(panel, UDim2.new(1, 0, 0, 18), nil, C.rail, "Presets")
            presets.LayoutOrder = 3
            local presetList = newFrame(presets, UDim2.new(1, 0, 1, 0), nil, C.rail, "PresetList")
            presetList.BackgroundTransparency = 1
            local presetLayout = Instance.new("UIListLayout")
            presetLayout.FillDirection = Enum.FillDirection.Horizontal
            presetLayout.Padding = UDim.new(0, 4)
            presetLayout.Parent = presetList

            local presetColors = {
                Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 22),
                Color3.fromRGB(230, 66, 60), Color3.fromRGB(236, 190, 70),
                Color3.fromRGB(110, 200, 110), Color3.fromRGB(70, 170, 235),
                Color3.fromRGB(180, 110, 235), Color3.fromRGB(70, 220, 210),
            }

            local hexRow = newFrame(panel, UDim2.new(1, 0, 0, 24), nil, C.field, "HexRow")
            hexRow.LayoutOrder = 4

            local hash = newLabel(hexRow, "#", 11, C.text_sec, FONT_MONO)
            hash.Position = UDim2.new(0, 8, 0, 0)
            hash.Size = UDim2.new(0, 12, 1, 0)

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -26, 1, 0)
            hexBox.Position = UDim2.new(0, 24, 0, 0)
            hexBox.BackgroundTransparency = 1
            hexBox.Text = toHex(default):sub(2)
            hexBox.TextColor3 = C.text
            hexBox.PlaceholderText = "RRGGBB"
            hexBox.PlaceholderColor3 = C.text_dim
            hexBox.Font = FONT_MONO
            hexBox.TextSize = 11
            hexBox.ClearTextOnFocus = false
            hexBox.Parent = hexRow

            local function render(call)
                local color = Color3.fromHSV(h, s, v)
                sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                cursor.BackgroundColor3 = color
                hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                hueCursor.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                swatch.BackgroundColor3 = color
                swatchStroke.Color = C.border_hi
                hexLbl.Text = toHex(color)
                if not hexFocused then hexBox.Text = toHex(color):sub(2) end
                if call and cfg.Callback then cfg.Callback(color) end
            end

            for _, preset in ipairs(presetColors) do
                local pBtn = newButton(presetList, UDim2.new(0, 18, 1, 0), nil, preset)
                pBtn.ZIndex = 4
                stroke(pBtn, C.border, 1)
                pBtn.MouseButton1Click:Connect(function()
                    h, s, v = Color3.toHSV(preset)
                    render(true)
                    click()
                end)
            end

            local svDrag = false
            sv.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    svDrag = true
                end
            end)
            claim("InputChanged", function(input)
                if not svDrag then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local abs, sz = sv.AbsolutePosition, sv.AbsoluteSize
                s = math.clamp((input.Position.X - abs.X) / math.max(sz.X, 1), 0, 1)
                v = 1 - math.clamp((input.Position.Y - abs.Y) / math.max(sz.Y, 1), 0, 1)
                render(true)
            end)

            local hueDrag = false
            hue.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    hueDrag = true
                end
            end)
            claim("InputChanged", function(input)
                if not hueDrag then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local abs, sz = hue.AbsolutePosition, hue.AbsoluteSize
                h = math.clamp((input.Position.X - abs.X) / math.max(sz.X, 1), 0, 1)
                render(true)
            end)
            claim("InputEnded", function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    svDrag = false
                    hueDrag = false
                end
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

            local obj = {}
            function obj:Get() return Color3.fromHSV(h, s, v) end
            function obj:Set(color)
                h, s, v = Color3.toHSV(color)
                render(false)
            end

            register(cfg.Flag, cfg.Default or Color3.new(1, 1, 1), function(color)
                h, s, v = Color3.toHSV(color)
                render(false)
            end, function() return Color3.fromHSV(h, s, v) end, function()
                if cfg.Callback then cfg.Callback(Color3.fromHSV(h, s, v)) end
            end)

            render(false)
            return obj
        end

        -- ── BUTTON ────────────────────────────────────────────────────────
        function Section:Button(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Button")
            local desc = cfg.Description
            local label = tostring(cfg.Text or "RUN")

            local row = newRow(desc and 50 or 38, name .. " " .. tostring(desc or ""), cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            if desc then
                nameLbl.Position = UDim2.new(0, 12, 0, 9)
            else
                nameLbl.AnchorPoint = Vector2.new(0, 0.5)
                nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            end
            nameLbl.Size = UDim2.new(1, -130, 0, 15)
            nameLbl.ZIndex = 3

            if desc then
                local d = newLabel(row, tostring(desc), 10, C.text_dim, FONT_UI)
                d.Position = UDim2.new(0, 12, 0, 27)
                d.Size = UDim2.new(1, -130, 0, 13)
                d.ZIndex = 3
            end

            local runBtn = newButton(row, UDim2.new(0, 66, 0, 22), UDim2.new(1, -12, 0.5, 0), C.field)
            runBtn.AnchorPoint = Vector2.new(1, 0.5)
            runBtn.ZIndex = 4
            local runStroke = stroke(runBtn, C.border, 1)

            local runLbl = newLabel(runBtn, label, 9, C.accent_hi, FONT_BOLD)
            runLbl.Size = UDim2.new(1, 0, 1, 0)
            runLbl.TextXAlignment = Enum.TextXAlignment.Center
            runLbl.ZIndex = 5

            runBtn.MouseEnter:Connect(function()
                runBtn.BackgroundColor3 = C.accent
                runStroke.Color = C.accent_hi
                runLbl.TextColor3 = C.window
            end)
            runBtn.MouseLeave:Connect(function()
                runBtn.BackgroundColor3 = C.field
                runStroke.Color = C.border
                runLbl.TextColor3 = C.accent_hi
            end)
            runBtn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
                click()
            end)

            return {}
        end

        -- ── TEXTBOX ───────────────────────────────────────────────────────
        function Section:TextBox(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Input")
            local placeholder = tostring(cfg.Placeholder or "...")

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(0.38, 0, 0, 15)
            nameLbl.ZIndex = 3

            local inputFrame = newFrame(row, UDim2.new(0.55, -12, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            inputFrame.AnchorPoint = Vector2.new(0, 0.5)
            inputFrame.ZIndex = 3
            local inputStroke = stroke(inputFrame, C.border, 1)

            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, -14, 1, 0)
            inputBox.Position = UDim2.new(0, 7, 0, 0)
            inputBox.BackgroundTransparency = 1
            inputBox.Text = tostring(cfg.Default or "")
            inputBox.PlaceholderText = placeholder
            inputBox.TextColor3 = C.text
            inputBox.PlaceholderColor3 = C.text_dim
            inputBox.Font = FONT_UI
            inputBox.TextSize = 10
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = inputFrame
            inputBox.ZIndex = 5

            inputBox.Focused:Connect(function()
                inputStroke.Color = C.accent
            end)
            inputBox.FocusLost:Connect(function(enterPressed)
                inputStroke.Color = C.border
                if cfg.Callback then cfg.Callback(inputBox.Text) end
                if enterPressed and cfg.OnEnter then cfg.OnEnter(inputBox.Text) end
            end)

            local obj = {}
            function obj:Get() return inputBox.Text end
            function obj:Set(v) inputBox.Text = tostring(v) end

            register(cfg.Flag, tostring(cfg.Default or ""), function(v)
                inputBox.Text = tostring(v)
            end, function() return inputBox.Text end, function()
                if cfg.Callback then cfg.Callback(inputBox.Text) end
            end)

            return obj
        end

        -- ── KEYBIND ───────────────────────────────────────────────────────
        function Section:Keybind(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Keybind")
            local bound = cfg.Default or Enum.KeyCode.Unknown
            local listening = false

            local row = newRow(38, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 12, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -150, 0, 15)
            nameLbl.ZIndex = 3

            local kbBtn = newButton(row, UDim2.new(0, 110, 0, 22), UDim2.new(1, -12, 0.5, 0), C.field)
            kbBtn.AnchorPoint = Vector2.new(1, 0.5)
            kbBtn.ZIndex = 4
            local kbStroke = stroke(kbBtn, C.border, 1)

            local kbLbl = newLabel(kbBtn, bound.Name:upper(), 9, C.text, FONT_MONO)
            kbLbl.Size = UDim2.new(1, 0, 1, 0)
            kbLbl.TextXAlignment = Enum.TextXAlignment.Center
            kbLbl.ZIndex = 5

            local entry
            local function refreshEntry()
                if entry then entry.refresh() end
            end

            local function stopListening()
                listening = false
                inputCtx.listening = false
                kbLbl.Text = bound.Name:upper()
                kbLbl.TextColor3 = C.text
                kbStroke.Color = C.border
                kbBtn.BackgroundColor3 = C.field
                refreshEntry()
            end

            kbBtn.MouseEnter:Connect(function()
                if not listening then kbBtn.BackgroundColor3 = C.field_hover end
            end)
            kbBtn.MouseLeave:Connect(function()
                if not listening then kbBtn.BackgroundColor3 = C.field end
            end)
            kbBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                inputCtx.listening = true
                kbLbl.Text = "PRESS KEY"
                kbLbl.TextColor3 = C.accent_hi
                kbStroke.Color = C.accent
                kbBtn.BackgroundColor3 = C.row_active
                click()
            end)

            claim("InputBegan", function(input, processed)
                if not listening or processed then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                bound = input.KeyCode
                stopListening()
                if cfg.Callback then cfg.Callback(bound) end
            end)

            if cfg.ShowInList ~= false then
                entry = addKeyEntry(name, function() return bound end)
            end

            local obj = {}
            function obj:Get() return bound end
            function obj:Set(key)
                bound = key
                kbLbl.Text = key.Name:upper()
                refreshEntry()
            end

            register(cfg.Flag, cfg.Default or Enum.KeyCode.Unknown, function(key)
                bound = key
                kbLbl.Text = key.Name:upper()
                refreshEntry()
            end, function() return bound end, function()
                if cfg.Callback then cfg.Callback(bound) end
            end)

            return obj
        end

        -- ── PROGRESS ──────────────────────────────────────────────────────
        function Section:Progress(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Progress")
            local value = math.clamp(cfg.Default or 0, 0, 1)

            local row = newRow(44, name, cfg.Tooltip)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 12, 0, 7)
            nameLbl.Size = UDim2.new(1, -170, 0, 15)
            nameLbl.ZIndex = 3

            local pctLbl = newLabel(row, tostring(math.floor(value * 100 + 0.5)) .. "%",
                10, C.accent_hi, FONT_MONO)
            pctLbl.AnchorPoint = Vector2.new(1, 0)
            pctLbl.Position = UDim2.new(1, -12, 0, 7)
            pctLbl.Size = UDim2.new(0, 140, 0, 14)
            pctLbl.TextXAlignment = Enum.TextXAlignment.Right
            pctLbl.ZIndex = 3

            local track = newFrame(row, UDim2.new(1, -24, 0, 4), UDim2.new(0, 12, 1, -12), C.field, "Track")
            track.ZIndex = 2

            local fill = newFrame(track, UDim2.new(value, 0, 1, 0), nil, C.accent, "Fill")
            gradient(fill, C.accent_dim, C.accent, 0)
            fill.ZIndex = 3

            local function render(text)
                fill.Size = UDim2.new(value, 0, 1, 0)
                pctLbl.Text = text or (tostring(math.floor(value * 100 + 0.5)) .. "%")
            end

            local obj = {}
            function obj:Set(v, text)
                value = math.clamp(v or 0, 0, 1)
                render(text)
            end
            function obj:Get() return value end

            return obj
        end

        -- ── LABEL ─────────────────────────────────────────────────────────
        function Section:Label(cfg)
            cfg = cfg or {}
            local text = tostring(cfg.Text or "")
            local row = newRow(24, text, nil)

            local lbl = newLabel(row, text, 9, cfg.Color or C.text_dim, FONT_MONO)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.Size = UDim2.new(1, -24, 1, 0)
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = 3

            local obj = {}
            function obj:Set(t) lbl.Text = tostring(t) end
            return obj
        end

        -- ── SEPARATOR ─────────────────────────────────────────────────────
        function Section:Separator()
            Section._order = Section._order + 1
            local holder = newFrame(items, UDim2.new(1, 0, 0, 9), nil, C.panel, "SeparatorRow")
            holder.BackgroundTransparency = 1
            holder.LayoutOrder = Section._order
            local sep = newFrame(holder, UDim2.new(1, -24, 0, 1), UDim2.new(0, 12, 0.5, 0), C.border, "Separator")
            sep.AnchorPoint = Vector2.new(0, 0.5)
        end

        return Section
    end

    -- ── DRAG ──────────────────────────────────────────────────────────────
    local dragging, dragStart, startPos

    local function clampRoot()
        local vp3 = viewportSize()
        local abs = root.AbsolutePosition
        local sz = root.AbsoluteSize
        local x = math.clamp(abs.X, 0, math.max(0, vp3.X - sz.X))
        local y = math.clamp(abs.Y, 0, math.max(0, vp3.Y - sz.Y))
        if x ~= abs.X or y ~= abs.Y then
            root.Position = UDim2.new(0, x / scale, 0, y / scale)
        end
    end

    titlebar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
            hideTooltip()
        end
    end)
    claim("InputEnded", function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    claim("InputChanged", function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        root.Position = UDim2.new(0,
            startPos.X.Offset + delta.X / scale,
            0,
            startPos.Y.Offset + delta.Y / scale)
        clampRoot()
    end)

    -- ── TAB ───────────────────────────────────────────────────────────────
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tostring(tabConfig.Name or ("TAB " .. (#Window._tabs + 1)))
        local pinned = tabConfig.Pinned == true
        local tabData = { filters = {}, sections = {}, count = 0 }

        local tabBtn = newButton(railInner, UDim2.new(1, 0, 0, 30), nil, C.rail)
        tabBtn.LayoutOrder = pinned and 900 or (#Window._tabs + 1)

        local indicator = newFrame(tabBtn, UDim2.new(0, 2, 1, 0), nil, C.accent, "Ind")
        indicator.Visible = false

        local tabLbl = newLabel(tabBtn, string.upper(tabName):sub(1, 18), 10, C.text_dim, FONT_BOLD)
        tabLbl.Position = UDim2.new(0, 14, 0, 0)
        tabLbl.Size = UDim2.new(1, -18, 1, 0)

        local page = newFrame(content, UDim2.new(1, 0, 1, 0), nil, C.window, tabName .. "Page")
        page.Visible = false

        local phead = newFrame(page, UDim2.new(1, 0, 0, HDR_H), nil, C.panel, "Header")
        newFrame(page, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, HDR_H), C.border, "HeaderLine")

        local pageTitle = newLabel(phead, string.upper(tabName), 12, C.text, FONT_BOLD)
        pageTitle.Position = UDim2.new(0, 14, 0, 0)
        pageTitle.Size = UDim2.new(1, -320, 1, 0)

        local countLbl = newLabel(phead, "0 ITEMS", 8, C.text_dim, FONT_MONO)
        countLbl.AnchorPoint = Vector2.new(1, 0.5)
        countLbl.Position = UDim2.new(1, -174, 0.5, 0)
        countLbl.Size = UDim2.new(0, 100, 1, 0)
        countLbl.TextXAlignment = Enum.TextXAlignment.Right

        local searchFrame = newFrame(phead, UDim2.new(0, 150, 0, 20), UDim2.new(1, -12, 0.5, 0), C.field)
        searchFrame.AnchorPoint = Vector2.new(1, 0.5)
        local searchStroke = stroke(searchFrame, C.border, 1)

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -18, 1, 0)
        searchBox.Position = UDim2.new(0, 9, 0, 0)
        searchBox.BackgroundTransparency = 1
        searchBox.Text = ""
        searchBox.PlaceholderText = "FILTER"
        searchBox.TextColor3 = C.text
        searchBox.PlaceholderColor3 = C.text_dim
        searchBox.Font = FONT_MONO
        searchBox.TextSize = 9
        searchBox.ClearTextOnFocus = false
        searchBox.Parent = searchFrame

        searchBox.Focused:Connect(function() searchStroke.Color = C.accent end)
        searchBox.FocusLost:Connect(function() searchStroke.Color = C.border end)

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, -HDR_H)
        scroll.Position = UDim2.new(0, 0, 0, HDR_H)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = C.border_hi
        scroll.ScrollBarImageTransparency = 0.2
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = page

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = scroll

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop = UDim.new(0, 10)
        pagePad.PaddingLeft = UDim.new(0, 10)
        pagePad.PaddingRight = UDim.new(0, 10)
        pagePad.PaddingBottom = UDim.new(0, 10)
        pagePad.Parent = scroll

        local emptyLbl = newLabel(page, "NO MATCHING ITEMS", 9, C.text_dim, FONT_MONO)
        emptyLbl.Size = UDim2.new(1, 0, 1, -HDR_H)
        emptyLbl.Position = UDim2.new(0, 0, 0, HDR_H)
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

        tabData.refreshCount = function()
            countLbl.Text = tostring(tabData.count) .. " ITEMS"
        end

        local function applyFilter(q)
            q = string.lower(q or "")
            for _, entry in ipairs(tabData.filters) do
                entry.row.Visible = (q == "" or string.find(entry.text, q, 1, true) ~= nil)
            end
            recompute()
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            applyFilter(searchBox.Text)
        end)

        local entry = { page = page, btn = tabBtn, lbl = tabLbl, ind = indicator }
        table.insert(Window._tabs, entry)

        local function activate()
            closePopups()
            hideTooltip()
            for _, e in ipairs(Window._tabs) do
                e.page.Visible = false
                e.btn.BackgroundColor3 = C.rail
                e.lbl.TextColor3 = C.text_dim
                e.ind.Visible = false
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = C.row_active
            tabLbl.TextColor3 = C.text
            indicator.Visible = true
            crumbTab.Text = string.upper(tabName)
            setCrumbSection("")
            Window._active = entry
        end

        tabBtn.MouseButton1Click:Connect(function()
            if Window._active ~= entry then
                activate()
                click()
            end
        end)
        tabBtn.MouseEnter:Connect(function()
            if Window._active ~= entry then tabBtn.BackgroundColor3 = C.panel end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active ~= entry then tabBtn.BackgroundColor3 = C.rail end
        end)

        if not pinned and Window._active == nil then activate() end

        local Tab = {}
        Tab._page = page
        Tab._scroll = scroll
        Tab._order = 0

        function Tab:Section(sectionName)
            sectionName = tostring(sectionName or "SECTION")
            Tab._order = Tab._order + 1

            local sec = newFrame(scroll, UDim2.new(1, 0, 0, 0), nil, C.panel, sectionName .. "Section")
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.LayoutOrder = Tab._order
            stroke(sec, C.border, 1)

            local hdr = newFrame(sec, UDim2.new(1, 0, 0, 26), nil, C.header, "Header")
            newFrame(hdr, UDim2.new(0, 2, 1, 0), nil, C.accent, "Edge")

            local idxLbl = newLabel(hdr, string.format("%02d", Tab._order), 8, C.accent_dim, FONT_MONO)
            idxLbl.Position = UDim2.new(0, 10, 0, 0)
            idxLbl.Size = UDim2.new(0, 20, 1, 0)

            local hdrLbl = newLabel(hdr, string.upper(sectionName), 10, C.text_sec, FONT_BOLD)
            hdrLbl.Position = UDim2.new(0, 32, 0, 0)
            hdrLbl.Size = UDim2.new(1, -70, 1, 0)

            local chev = newLabel(hdr, "-", 11, C.text_dim, FONT_MONO)
            chev.AnchorPoint = Vector2.new(1, 0.5)
            chev.Position = UDim2.new(1, -10, 0.5, 0)
            chev.Size = UDim2.new(0, 14, 1, 0)
            chev.TextXAlignment = Enum.TextXAlignment.Right

            local body = newFrame(sec, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 27), C.panel, "Body")
            body.AutomaticSize = Enum.AutomaticSize.Y
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
                hdrLbl.TextColor3 = collapsed and C.text_dim or C.text_sec
                click()
            end)
            hdrHit.MouseEnter:Connect(function()
                hdr.BackgroundColor3 = C.row_hover
                setCrumbSection(sectionName)
            end)
            hdrHit.MouseLeave:Connect(function()
                hdr.BackgroundColor3 = C.header
                setCrumbSection("")
            end)

            local sectionRef = { frame = sec, rows = {} }
            table.insert(tabData.sections, sectionRef)

            return makeItemAPI(body, sectionRef, tabData)
        end

        return Tab
    end

    -- ── SETTINGS TAB ──────────────────────────────────────────────────────
    local settingsTab = Window:Tab({ Name = "Settings", Pinned = true })

    local interfaceSec = settingsTab:Section("Interface")
    local hintLabel = interfaceSec:Label({
        Text = "MENU KEY   " .. string.upper(toggleKey.Name),
        Color = C.text_sec,
    })

    interfaceSec:Keybind({
        Name = "Menu Keybind",
        Default = toggleKey,
        Flag = "menuKey",
        Callback = function(key)
            toggleKey = key
            keyHintLbl.Text = string.upper(key.Name) .. "  :  MENU"
            hintLabel:Set("MENU KEY   " .. string.upper(key.Name))
            click()
        end,
    })

    interfaceSec:Button({
        Name = "Hide Menu",
        Description = "Collapse the interface, keep hotkeys active",
        Callback = function()
            setVisible(false)
        end,
    })

    interfaceSec:Button({
        Name = "Unload UI",
        Description = "Remove the menu, hotkeys and notices from memory",
        Callback = function()
            Window:Unload()
        end,
    })

    local appearanceSec = settingsTab:Section("Appearance")

    appearanceSec:Slider({
        Name = "Interface Scale",
        Min = 0.8,
        Max = 1.3,
        Step = 0.05,
        Default = scale,
        Suffix = "x",
        Flag = "guiScale",
        Callback = function(v) setScale(v) end,
    })

    appearanceSec:Slider({
        Name = "Background Opacity",
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
        Default = false,
        Flag = "sounds",
        Callback = function(v) soundsEnabled = v end,
    })

    appearanceSec:Toggle({
        Name = "Watermark",
        Description = "Build and performance badge",
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
        Description = "Write the current values to a slot",
        Callback = function()
            Window:SaveConfig(cfgName:Get())
            refreshConfigLabel()
        end,
    })

    configSec:Button({
        Name = "Load Config",
        Description = "Apply a saved slot",
        Callback = function()
            Window:LoadConfig(cfgName:Get())
        end,
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
        Description = "Restore every widget to its default",
        Callback = function()
            Window:ResetDefaults()
        end,
    })

    refreshConfigLabel = function()
        local names = Window:ListConfigs()
        cfgList:Set("CONFIGS   " .. (#names > 0 and table.concat(names, "   ") or "NONE"))
    end
    refreshConfigLabel()

    local buildSec = settingsTab:Section("Build")
    buildSec:Label({ Text = "VANTA  " .. VERSION .. "   PANORAMA STYLE" })
    buildSec:Label({ Text = "TOGGLE   " .. string.upper(toggleKey.Name) .. "   /   SETTINGS TAB TO UNLOAD", Color = C.text_dim })

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
            local name = string.upper(LocalPlayer.DisplayName or LocalPlayer.Name)
            subLbl.Text = name .. "  ·  " .. (ok and (tostring(ping) .. " MS") or "--- MS")
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
