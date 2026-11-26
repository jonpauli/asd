--[[
    VANTALib — Jan's Library Style
    version: 5.0.0

    aesthetic: Classic dark flat UI (CheatX / Jan's Library) —
               0px sharp corners, 1px black & gray borders, Enum.Font.Code
               monospace typography, purple (#825AD2) accent line & fills,
               top horizontal tab bar, dual-column groupboxes with title
               cutouts on the top border, and full-width gradient sliders.

    every window is built with a pinned Settings tab:
      · rebind the menu key
      · interface scale, background opacity, sounds
      · watermark and on-screen keybind list
      · config slots (save / load / delete / reset defaults)
      · hide the menu or unload the whole interface
]]

local VANTALib = {}
VANTALib.__index = VANTALib
VANTALib.Version = "5.0.0"
local VERSION = VANTALib.Version

-- ───────────────────────────────────────────────────────────────────────────
--  FONT — Jan's Library uses Enum.Font.Code everywhere
-- ───────────────────────────────────────────────────────────────────────────
local FONT_UI   = Enum.Font.Code
local FONT_BOLD = Enum.Font.Code
local FONT_MONO = Enum.Font.Code

-- ───────────────────────────────────────────────────────────────────────────
--  PALETTE — Exact Jan's Library dark charcoal + purple accent
-- ───────────────────────────────────────────────────────────────────────────
local C = {
    window      = Color3.fromRGB(20, 20, 20),
    titlebar    = Color3.fromRGB(30, 30, 30),
    tabbar      = Color3.fromRGB(25, 25, 25),
    panel       = Color3.fromRGB(30, 30, 30),
    panel_alt   = Color3.fromRGB(25, 25, 25),
    row_hover   = Color3.fromRGB(38, 38, 38),
    row_active  = Color3.fromRGB(45, 45, 45),
    field       = Color3.fromRGB(22, 22, 22),
    field_hover = Color3.fromRGB(32, 32, 32),
    accent      = Color3.fromRGB(130, 90, 210),   -- Jan purple
    accent_hi   = Color3.fromRGB(154, 114, 232),
    accent_dim  = Color3.fromRGB(86, 56, 152),
    border      = Color3.fromRGB(60, 60, 60),
    border_blk  = Color3.fromRGB(0, 0, 0),
    text        = Color3.fromRGB(235, 235, 235),
    text_sec    = Color3.fromRGB(195, 195, 195),
    text_dim    = Color3.fromRGB(130, 130, 130),
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
local TextService      = game:GetService("TextService")
local LocalPlayer      = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────────────────
--  OPACITY
-- ───────────────────────────────────────────────────────────────────────────
local bgObjects = {}
local uiOpacity = 1

local function trackBg(obj, baseTrans)
    baseTrans = baseTrans or 0
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
--  UTILITY (Sharp 0px corners, 1px borders)
-- ───────────────────────────────────────────────────────────────────────────
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

local function newLabel(parent, text, textSize, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = textSize or 14
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

local function gradient(gui, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
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
--  FEED (top-right flat notices)
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

    notifHolder = newFrame(notifGui, UDim2.new(0, 270, 1, 0), UDim2.new(1, -282, 0, 12))
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

    local card = newFrame(holder, UDim2.new(1, 0, 0, 52), nil, C.panel, "Notice")
    card.LayoutOrder = notifSeq
    stroke(card, C.border_blk, 1)
    newFrame(card, UDim2.new(0, 2, 1, 0), nil, C.accent, "Bar")

    local t = newLabel(card, tostring(title or ""), 13, C.accent_hi, FONT_UI)
    t.Position = UDim2.new(0, 10, 0, 6)
    t.Size = UDim2.new(1, -16, 0, 16)

    local b = newLabel(card, tostring(body or ""), 12, C.text_sec, FONT_UI)
    b.Position = UDim2.new(0, 10, 0, 23)
    b.Size = UDim2.new(1, -16, 0, 24)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top

    local prog = newFrame(card, UDim2.new(1, -2, 0, 1), UDim2.new(0, 2, 1, -1), C.accent, "Progress")
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
local TITLE_H = 26
local TAB_H   = 26

function VANTALib:CreateWindow(config)
    config = config or {}
    local title = tostring(config.Title or "VANTA")
    local width = math.max(500, config.Width or 540)
    local height = math.max(400, config.Height or 560)
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
        s.Volume = 0.22
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
    -- Outer black border frame -> inner dark frame (exact Jan's Library double border)
    local root = newFrame(holder, UDim2.new(0, width, 0, height),
        UDim2.new(0, (vp.X - width) / 2, 0, (vp.Y - height) / 2),
        C.window, "Window")
    stroke(root, C.border_blk, 1)
    trackBg(root, 0)

    local innerFrame = newFrame(root, UDim2.new(1, -2, 1, -2), UDim2.new(0, 1, 0, 1), C.window, "Inner")
    stroke(innerFrame, C.border, 1)
    trackBg(innerFrame, 0)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = scale
    uiScale.Parent = root

    local function setScale(v)
        scale = math.clamp(v or 1, 0.5, 2)
        uiScale.Scale = scale
    end

    -- Titlebar (26px, gray 30,30,30)
    local titlebar = newFrame(innerFrame, UDim2.new(1, 0, 0, TITLE_H), UDim2.new(0, 0, 0, 0), C.titlebar, "Titlebar")
    trackBg(titlebar, 0)

    local titleLbl = newLabel(titlebar, title, 15, C.text, FONT_UI)
    titleLbl.Position = UDim2.new(0, 8, 0, 0)
    titleLbl.Size = UDim2.new(1, -120, 1, 0)

    local keyHintLbl = newLabel(titlebar, string.upper(toggleKey.Name), 12, C.text_dim, FONT_UI)
    keyHintLbl.AnchorPoint = Vector2.new(1, 0)
    keyHintLbl.Position = UDim2.new(1, -8, 0, 0)
    keyHintLbl.Size = UDim2.new(0, 100, 1, 0)
    keyHintLbl.TextXAlignment = Enum.TextXAlignment.Right

    -- Draggable window via titlebar
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

    -- 1px Purple Accent Line right below titlebar (signature Jan's Library detail)
    newFrame(innerFrame, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TITLE_H), C.accent, "AccentLine")

    -- Tab bar (26px, gray 25,25,25)
    local tabBar = newFrame(innerFrame, UDim2.new(1, 0, 0, TAB_H), UDim2.new(0, 0, 0, TITLE_H + 1), C.tabbar, "TabBar")
    trackBg(tabBar, 0)
    newFrame(innerFrame, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TITLE_H + 1 + TAB_H), C.border_blk, "TabBottomLine")

    local tabListFrame = newFrame(tabBar, UDim2.new(1, -12, 1, 0), UDim2.new(0, 6, 0, 0), C.tabbar, "Tabs")
    tabListFrame.BackgroundTransparency = 1
    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Padding = UDim.new(0, 4)
    tabList.Parent = tabListFrame

    -- Main content area
    local contentY = TITLE_H + TAB_H + 2
    local content = newFrame(innerFrame, UDim2.new(1, 0, 1, -contentY), UDim2.new(0, 0, 0, contentY), C.window, "Content")
    trackBg(content, 0)

    -- Tooltip
    local tooltip = newFrame(root, UDim2.new(0, 0, 0, 0), nil, C.panel, "Tooltip")
    tooltip.AutomaticSize = Enum.AutomaticSize.XY
    tooltip.Visible = false
    tooltip.ZIndex = 300
    stroke(tooltip, C.border_blk, 1)
    local ttpPad = Instance.new("UIPadding")
    ttpPad.PaddingLeft = UDim.new(0, 6)
    ttpPad.PaddingRight = UDim.new(0, 6)
    ttpPad.PaddingTop = UDim.new(0, 4)
    ttpPad.PaddingBottom = UDim.new(0, 4)
    ttpPad.Parent = tooltip
    local ttpLbl = newLabel(tooltip, "", 12, C.text_sec, FONT_UI)
    ttpLbl.Size = UDim2.new(0, 200, 0, 0)
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
            math.clamp(relX + 12, 4, math.max(4, maxX)),
            math.clamp(relY + 16, 4, math.max(4, maxY))
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

    -- Window object
    local Window = {}
    Window._tabs = {}
    Window._active = nil
    Window._gui = sg
    Window._win = root
    Window._unloaded = false

    -- Keybind overlay
    local keyHolder = newFrame(sg, UDim2.new(0, 180, 0, 0), UDim2.new(0, 12, 1, -12), C.panel, "KeyList")
    keyHolder.AutomaticSize = Enum.AutomaticSize.Y
    keyHolder.AnchorPoint = Vector2.new(0, 1)
    keyHolder.Visible = false
    stroke(keyHolder, C.border_blk, 1)
    newFrame(keyHolder, UDim2.new(1, 0, 0, 1), nil, C.accent, "Accent")
    local keyLayout = Instance.new("UIListLayout")
    keyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keyLayout.Parent = keyHolder

    local keyHead = newFrame(keyHolder, UDim2.new(1, 0, 0, 20), nil, C.titlebar, "Head")
    keyHead.LayoutOrder = 0
    local keyHeadLbl = newLabel(keyHead, " Keybinds", 13, C.text, FONT_UI)
    keyHeadLbl.Size = UDim2.new(1, 0, 1, 0)

    local keyEntries = {}
    local keyListVisible = false

    local function refreshKeyList()
        keyHolder.Visible = keyListVisible and (#keyEntries > 0)
    end

    local function addKeyEntry(name, getKey)
        local row = newFrame(keyHolder, UDim2.new(1, 0, 0, 18), nil, C.panel, "KeyEntry")
        row.LayoutOrder = #keyEntries + 1
        local lbl = newLabel(row, tostring(name), 12, C.text_sec, FONT_UI)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.Size = UDim2.new(1, -68, 1, 0)
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        local kl = newLabel(row, "", 12, C.accent_hi, FONT_UI)
        kl.Position = UDim2.new(0, 0, 0, 0)
        kl.Size = UDim2.new(1, -6, 1, 0)
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

    -- Watermark
    local wm = newFrame(sg, UDim2.new(0, 210, 0, 22), UDim2.new(0, 12, 0, 12), C.panel, "Watermark")
    stroke(wm, C.border_blk, 1)
    newFrame(wm, UDim2.new(1, 0, 0, 1), nil, C.accent, "Accent")
    local wmTitle = newLabel(wm, title, 13, C.text, FONT_UI)
    wmTitle.Position = UDim2.new(0, 8, 0, 1)
    wmTitle.Size = UDim2.new(0, 70, 1, -1)
    local wmStats = newLabel(wm, "— FPS | — MS", 12, C.text_sec, FONT_UI)
    wmStats.AnchorPoint = Vector2.new(1, 0)
    wmStats.Position = UDim2.new(1, -8, 0, 1)
    wmStats.Size = UDim2.new(0, 124, 1, -1)
    wmStats.TextXAlignment = Enum.TextXAlignment.Right

    -- Show / hide
    local function setVisible(v)
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

    -- ── WIDGET API (Jan's Library style) ────────────────────────────────
    local settingsTab

    local function makeItemAPI(items, sectionRef)
        local Section = {}
        Section._order = 0

        local function trackRow(row)
            table.insert(sectionRef.rows, row)
        end

        -- ── TOGGLE (12x12 checkbox on left) ─────────────────────────────
        function Section:Toggle(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Toggle")
            local default = cfg.Default == true
            local flag = cfg.Flag
            local callback = cfg.Callback
            local desc = cfg.Description

            local row = newFrame(items, UDim2.new(1, 0, 0, 20), nil, C.panel, "ToggleRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local checked = default

            local box = newFrame(row, UDim2.new(0, 12, 0, 12), UDim2.new(0, 6, 0.5, 0),
                checked and C.accent or C.field, "Tickbox")
            box.AnchorPoint = Vector2.new(0, 0.5)
            box.ZIndex = 4
            stroke(box, checked and C.accent_hi or C.border, 1)
            local boxGrad = gradient(box, C.accent_hi, C.accent_dim, 90)
            boxGrad.Enabled = checked

            local lbl = newLabel(row, name, 14, checked and C.text or C.text_sec, FONT_UI)
            lbl.AnchorPoint = Vector2.new(0, 0.5)
            lbl.Position = UDim2.new(0, 24, 0.5, 0)
            lbl.Size = UDim2.new(1, cfg.Settings and -50 or -30, 1, 0)
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = 3

            local hit = newButton(row, UDim2.new(1, cfg.Settings and -24 or 0, 1, 0), nil, C.panel)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 5

            local function render()
                boxGrad.Enabled = checked
                box.BackgroundColor3 = checked and C.accent or C.field
                lbl.TextColor3 = checked and C.text or C.text_sec
                for _, c in ipairs(box:GetChildren()) do
                    if c:IsA("UIStroke") then
                        c.Color = checked and C.accent_hi or C.border
                    end
                end
            end

            hit.MouseEnter:Connect(function()
                lbl.TextColor3 = C.white
                if desc then showTooltip(desc) end
            end)
            hit.MouseLeave:Connect(function()
                lbl.TextColor3 = checked and C.text or C.text_sec
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

            trackRow(row)
            Section._order = Section._order + 1

            if type(cfg.Settings) == "function" then
                local gearBtn = newButton(row, UDim2.new(0, 16, 0, 14), UDim2.new(1, -6, 0.5, 0), C.field)
                gearBtn.AnchorPoint = Vector2.new(1, 0.5)
                gearBtn.ZIndex = 5
                stroke(gearBtn, C.border, 1)
                local gearLbl = newLabel(gearBtn, "+", 12, C.text_sec, FONT_UI)
                gearLbl.Size = UDim2.new(1, 0, 1, 0)
                gearLbl.TextXAlignment = Enum.TextXAlignment.Center
                gearLbl.ZIndex = 6

                local subBody = newFrame(items, UDim2.new(1, -12, 0, 0), nil, C.panel_alt, "ToggleSettings")
                subBody.AutomaticSize = Enum.AutomaticSize.Y
                subBody.Visible = false
                subBody.LayoutOrder = Section._order - 0.5
                stroke(subBody, C.border, 1)
                local subPad = Instance.new("UIPadding")
                subPad.PaddingTop = UDim.new(0, 3)
                subPad.PaddingBottom = UDim.new(0, 3)
                subPad.Parent = subBody
                local subLayout = Instance.new("UIListLayout")
                subLayout.SortOrder = Enum.SortOrder.LayoutOrder
                subLayout.Padding = UDim.new(0, 2)
                subLayout.Parent = subBody

                local subAPI = makeItemAPI(subBody, sectionRef)
                pcall(cfg.Settings, settingsTab, subAPI)

                gearBtn.MouseButton1Click:Connect(function()
                    subBody.Visible = not subBody.Visible
                    gearLbl.Text = subBody.Visible and "-" or "+"
                    gearLbl.TextColor3 = subBody.Visible and C.accent_hi or C.text_sec
                    click()
                end)
            end

            local obj = {}
            function obj:Set(v) setState(v) end
            function obj:Get() return checked end
            return obj
        end

        -- ── SLIDER (label + value on top, full-width purple gradient bar) ─
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

            local row = newFrame(items, UDim2.new(1, 0, 0, 36), nil, C.panel, "SliderRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name .. ": " .. fmtNumber(value, step, suffix), 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 16)
            nameLbl.ZIndex = 3

            local trackOuter = newFrame(row, UDim2.new(1, -12, 0, 14), UDim2.new(0, 6, 0, 19), C.field, "Track")
            trackOuter.ZIndex = 3
            stroke(trackOuter, C.border_blk, 1)

            local trackInner = newFrame(trackOuter, UDim2.new(1, -2, 1, -2), UDim2.new(0, 1, 0, 1), C.field, "TrackInner")
            trackInner.ZIndex = 3
            stroke(trackInner, C.border, 1)

            local fill = newFrame(trackInner, UDim2.new((value - min) / (max - min), 0, 1, 0), nil, C.accent, "Fill")
            fill.ZIndex = 4
            gradient(fill, C.accent_hi, C.accent_dim, 90)

            local function render(newVal, fire)
                local raw = math.clamp(newVal or value, min, max)
                local snapped = math.clamp(math.floor((raw - min) / step + 0.5) * step + min, min, max)
                value = snapped
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                nameLbl.Text = name .. ": " .. fmtNumber(value, step, suffix)
                if fire and callback then callback(value) end
            end

            local dragging = false
            local function updateFromX(mouseX)
                local sz = math.max(1, trackInner.AbsoluteSize.X)
                local x = math.clamp(mouseX - trackInner.AbsolutePosition.X, 0, sz)
                render(min + (x / sz) * (max - min), true)
            end

            trackOuter.InputBegan:Connect(function(input)
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

            trackRow(row)
            Section._order = Section._order + 1
            return { Set = setVal, Get = function() return value end }
        end

        -- ── STEPPER ─────────────────────────────────────────────────────
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

            local row = newFrame(items, UDim2.new(1, 0, 0, 24), nil, C.panel, "StepperRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 0)
            nameLbl.Size = UDim2.new(1, -106, 1, 0)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local plus = newButton(row, UDim2.new(0, 18, 0, 18), UDim2.new(1, -6, 0.5, 0), C.field)
            plus.AnchorPoint = Vector2.new(1, 0.5)
            plus.ZIndex = 4
            stroke(plus, C.border, 1)
            local plusLbl = newLabel(plus, "+", 14, C.text_sec, FONT_UI)
            plusLbl.Size = UDim2.new(1, 0, 1, 0)
            plusLbl.TextXAlignment = Enum.TextXAlignment.Center

            local minus = newButton(row, UDim2.new(0, 18, 0, 18), UDim2.new(1, -78, 0.5, 0), C.field)
            minus.AnchorPoint = Vector2.new(1, 0.5)
            minus.ZIndex = 4
            stroke(minus, C.border, 1)
            local minusLbl = newLabel(minus, "-", 14, C.text_sec, FONT_UI)
            minusLbl.Size = UDim2.new(1, 0, 1, 0)
            minusLbl.TextXAlignment = Enum.TextXAlignment.Center

            local field = newFrame(row, UDim2.new(0, 48, 0, 18), UDim2.new(1, -27, 0.5, 0), C.field, "Field")
            field.AnchorPoint = Vector2.new(1, 0.5)
            field.ZIndex = 3
            stroke(field, C.border, 1)

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -4, 1, 0)
            box.Position = UDim2.new(0, 2, 0, 0)
            box.BackgroundTransparency = 1
            box.Text = fmtNumber(value, step, suffix)
            box.TextColor3 = C.text
            box.Font = FONT_UI
            box.TextSize = 13
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

            trackRow(row)
            Section._order = Section._order + 1
            return {
                Set = function(_, v)
                    value = math.clamp(v, min, max)
                    box.Text = fmtNumber(value, step, suffix)
                end,
                Get = function() return value end
            }
        end

        -- ── SEGMENTED ───────────────────────────────────────────────────
        function Section:Segmented(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Choice")
            local options = cfg.Options or {}
            local default = cfg.Default or options[1] or ""
            local flag = cfg.Flag
            local callback = cfg.Callback
            local selected = default

            local row = newFrame(items, UDim2.new(1, 0, 0, 40), nil, C.panel, "SegmentedRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 16)
            nameLbl.ZIndex = 3

            local strips = newFrame(row, UDim2.new(1, -12, 0, 18), UDim2.new(0, 6, 0, 20), C.field, "Strips")
            strips.BackgroundTransparency = 1
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
                    cell.stroke.Color = active and C.accent_hi or C.border
                    cell.lbl.TextColor3 = active and C.white or C.text_sec
                end
            end

            for i, opt in ipairs(options) do
                local cell = newButton(strips, UDim2.new(1 / math.max(1, #options), -2, 1, 0), nil, C.field)
                cell.LayoutOrder = i
                cell.ZIndex = 4
                local st = stroke(cell, C.border, 1)
                local lbl = newLabel(cell, tostring(opt), 12, C.text_sec, FONT_UI)
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

                cells[#cells + 1] = { btn = cell, lbl = lbl, stroke = st, value = opt }
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

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── DROPDOWN (label on top, full-width flat box below) ──────────
        function Section:Dropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Dropdown")
            local options = cfg.Options or {}
            local default = cfg.Default or options[1] or ""
            local selected = default
            local flag = cfg.Flag
            local callback = cfg.Callback

            local row = newFrame(items, UDim2.new(1, 0, 0, 42), nil, C.panel, "DropdownRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 16)
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 20), C.panel_alt)
            dropBtn.ZIndex = 4
            local dropStroke = stroke(dropBtn, C.border, 1)

            local selLbl = newLabel(dropBtn, tostring(selected), 13, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 6, 0, 0)
            selLbl.Size = UDim2.new(1, -22, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "▼", 10, C.text_sec, FONT_UI)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, -12, 0, 0), nil, C.field, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.border, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v2)
                listHolder.Visible = v2
                arrow.Text = v2 and "▲" or "▼"
                dropStroke.Color = v2 and C.accent or C.border
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
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 20), nil,
                        isSel and C.row_active or C.field)
                    optBtn.LayoutOrder = i
                    local optLbl = newLabel(optBtn, tostring(opt), 13,
                        isSel and C.accent_hi or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 6, 0, 0)
                    optLbl.Size = UDim2.new(1, -12, 1, 0)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.field
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
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.panel_alt end)
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

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── MULTI DROPDOWN ──────────────────────────────────────────────
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

            local row = newFrame(items, UDim2.new(1, 0, 0, 42), nil, C.panel, "MultiDropdownRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 16)
            nameLbl.ZIndex = 3

            local dropBtn = newButton(row, UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 20), C.panel_alt)
            dropBtn.ZIndex = 4
            local dropStroke = stroke(dropBtn, C.border, 1)

            local function summary()
                local t = selectionList()
                if #t == 0 then return "None" end
                return table.concat(t, ", ")
            end

            local selLbl = newLabel(dropBtn, summary(), 13, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 6, 0, 0)
            selLbl.Size = UDim2.new(1, -22, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 5

            local arrow = newLabel(dropBtn, "▼", 10, C.text_sec, FONT_UI)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 5

            local listHolder = newFrame(items, UDim2.new(1, -12, 0, 0), nil, C.field, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.border, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function setOpen(v2)
                listHolder.Visible = v2
                arrow.Text = v2 and "▲" or "▼"
                dropStroke.Color = v2 and C.accent or C.border
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
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 20), nil,
                        isSel and C.row_active or C.field)
                    optBtn.LayoutOrder = i
                    local optLbl = newLabel(optBtn, (isSel and "[x] " or "[ ] ") .. tostring(opt), 13,
                        isSel and C.accent_hi or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 6, 0, 0)
                    optLbl.Size = UDim2.new(1, -12, 1, 0)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.field
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
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.panel_alt end)
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

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── COLOR PICKER (compact 20x12 swatch on right) ────────────────
        function Section:ColorPicker(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Color")
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local h, s, v = Color3.toHSV(default)
            local flag = cfg.Flag
            local callback = cfg.Callback

            local row = newFrame(items, UDim2.new(1, 0, 0, 20), nil, C.panel, "ColorPickerRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 0)
            nameLbl.Size = UDim2.new(1, -40, 1, 0)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local swatch = newButton(row, UDim2.new(0, 22, 0, 12), UDim2.new(1, -6, 0.5, 0), default)
            swatch.AnchorPoint = Vector2.new(1, 0.5)
            swatch.ZIndex = 4
            local swatchStroke = stroke(swatch, C.border_blk, 1)

            local panel = newFrame(items, UDim2.new(1, -12, 0, 0), nil, C.field, "Picker")
            panel.AutomaticSize = Enum.AutomaticSize.Y
            panel.Visible = false
            panel.LayoutOrder = Section._order + 0.5
            stroke(panel, C.border, 1)
            local pPad = Instance.new("UIPadding")
            pPad.PaddingTop = UDim.new(0, 6)
            pPad.PaddingBottom = UDim.new(0, 6)
            pPad.PaddingLeft = UDim.new(0, 6)
            pPad.PaddingRight = UDim.new(0, 6)
            pPad.Parent = panel
            local pLayout = Instance.new("UIListLayout")
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pLayout.Padding = UDim.new(0, 5)
            pLayout.Parent = panel

            local sv = newFrame(panel, UDim2.new(1, 0, 0, 96), nil, Color3.fromHSV(h, 1, 1), "SV")
            sv.LayoutOrder = 1
            stroke(sv, C.border_blk, 1)

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

            local cursor = newFrame(sv, UDim2.new(0, 6, 0, 6), UDim2.new(s, 0, 1 - v, 0), C.white, "Cursor")
            cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cursor.ZIndex = 5
            stroke(cursor, C.border_blk, 1)

            local hue = newFrame(panel, UDim2.new(1, 0, 0, 10), nil, C.white, "Hue")
            hue.LayoutOrder = 2
            stroke(hue, C.border_blk, 1)
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

            local hueCursor = newFrame(hue, UDim2.new(0, 4, 0, 12), UDim2.new(h, 0, 0.5, 0), C.white, "HueCursor")
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.ZIndex = 5
            stroke(hueCursor, C.border_blk, 1)

            local hexFrame = newFrame(panel, UDim2.new(1, 0, 0, 18), nil, C.panel_alt, "HexFrame")
            hexFrame.LayoutOrder = 3
            stroke(hexFrame, C.border, 1)

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -8, 1, 0)
            hexBox.Position = UDim2.new(0, 4, 0, 0)
            hexBox.BackgroundTransparency = 1
            hexBox.Text = toHex(default)
            hexBox.TextColor3 = C.text
            hexBox.Font = FONT_UI
            hexBox.TextSize = 12
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
                swatchStroke.Color = panel.Visible and C.accent or C.border_blk
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
                swatchStroke.Color = v2 and C.accent or C.border_blk
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
            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── BUTTON ──────────────────────────────────────────────────────
        function Section:Button(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Button")
            local desc = cfg.Description

            local row = newFrame(items, UDim2.new(1, 0, 0, 24), nil, C.panel, "ButtonRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local btn = newButton(row, UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0.5, 0), C.panel_alt)
            btn.AnchorPoint = Vector2.new(0, 0.5)
            btn.ZIndex = 4
            local btnStroke = stroke(btn, C.border, 1)

            local btnLbl = newLabel(btn, name, 13, C.text, FONT_UI)
            btnLbl.Size = UDim2.new(1, 0, 1, 0)
            btnLbl.TextXAlignment = Enum.TextXAlignment.Center
            btnLbl.ZIndex = 5

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = C.field_hover
                btnStroke.Color = C.accent
                if desc then showTooltip(desc) end
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = C.panel_alt
                btnStroke.Color = C.border
                if desc then hideTooltip() end
            end)
            btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
                click()
            end)

            trackRow(row)
            Section._order = Section._order + 1
            return {}
        end

        -- ── TEXTBOX ─────────────────────────────────────────────────────
        function Section:TextBox(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Input")
            local placeholder = tostring(cfg.Placeholder or "...")
            local flag = cfg.Flag

            local row = newFrame(items, UDim2.new(1, 0, 0, 40), nil, C.panel, "TextBoxRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 16)
            nameLbl.ZIndex = 3

            local inputFrame = newFrame(row, UDim2.new(1, -12, 0, 18), UDim2.new(0, 6, 0, 20), C.field)
            inputFrame.ZIndex = 3
            local inputStroke = stroke(inputFrame, C.border, 1)

            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, -8, 1, 0)
            inputBox.Position = UDim2.new(0, 4, 0, 0)
            inputBox.BackgroundTransparency = 1
            inputBox.Text = tostring(cfg.Default or "")
            inputBox.PlaceholderText = placeholder
            inputBox.TextColor3 = C.text
            inputBox.PlaceholderColor3 = C.text_dim
            inputBox.Font = FONT_UI
            inputBox.TextSize = 13
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

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── KEYBIND ─────────────────────────────────────────────────────
        function Section:Keybind(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Keybind")
            local bound = cfg.Default or Enum.KeyCode.Unknown
            local flag = cfg.Flag
            local listening = false

            local row = newFrame(items, UDim2.new(1, 0, 0, 20), nil, C.panel, "KeybindRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name, 14, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 0)
            nameLbl.Size = UDim2.new(1, -80, 1, 0)
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 3

            local kbBtn = newButton(row, UDim2.new(0, 64, 0, 16), UDim2.new(1, -6, 0.5, 0), C.field)
            kbBtn.AnchorPoint = Vector2.new(1, 0.5)
            kbBtn.ZIndex = 4
            local kbStroke = stroke(kbBtn, C.border, 1)

            local kbLbl = newLabel(kbBtn, "[" .. bound.Name:upper() .. "]", 11, C.text_sec, FONT_UI)
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
                kbLbl.TextColor3 = C.accent_hi
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
                kbLbl.TextColor3 = C.text_sec
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

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── PROGRESS ────────────────────────────────────────────────────
        function Section:Progress(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Progress")
            local value = math.clamp(cfg.Default or 0, 0, 1)

            local row = newFrame(items, UDim2.new(1, 0, 0, 34), nil, C.panel, "ProgressRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local nameLbl = newLabel(row, name .. ": " .. tostring(math.floor(value * 100 + 0.5)) .. "%", 13, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 6, 0, 2)
            nameLbl.Size = UDim2.new(1, -12, 0, 15)
            nameLbl.ZIndex = 3

            local track = newFrame(row, UDim2.new(1, -12, 0, 12), UDim2.new(0, 6, 0, 19), C.field, "Track")
            track.ZIndex = 2
            stroke(track, C.border_blk, 1)

            local fill = newFrame(track, UDim2.new(value, 0, 1, 0), nil, C.accent, "Fill")
            gradient(fill, C.accent_hi, C.accent_dim, 90)
            fill.ZIndex = 3

            local function render(text)
                fill.Size = UDim2.new(value, 0, 1, 0)
                nameLbl.Text = text or (name .. ": " .. tostring(math.floor(value * 100 + 0.5)) .. "%")
            end

            local obj = {}
            function obj:Set(v, text)
                value = math.clamp(v or 0, 0, 1)
                render(text)
            end
            function obj:Get() return value end

            trackRow(row)
            Section._order = Section._order + 1
            return obj
        end

        -- ── LABEL ───────────────────────────────────────────────────────
        function Section:Label(cfg)
            cfg = cfg or {}
            local text = tostring(cfg.Text or "")
            local row = newFrame(items, UDim2.new(1, 0, 0, 18), nil, C.panel, "LabelRow")
            row.BackgroundTransparency = 1
            row.LayoutOrder = Section._order
            row.ZIndex = 3

            local lbl = newLabel(row, text, 13, cfg.Color or C.text_sec, FONT_UI)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.ZIndex = 4

            trackRow(row)
            Section._order = Section._order + 1
            return {
                Set = function(_, t) lbl.Text = tostring(t) end,
                Get = function() return lbl.Text end,
            }
        end

        -- ── DIVIDER / SEPARATOR (Jan's centered title divider) ──────────
        function Section:Separator(text)
            Section._order = Section._order + 1
            local sepRow = newFrame(items, UDim2.new(1, 0, 0, text and 18 or 8), nil, C.panel, "SeparatorRow")
            sepRow.BackgroundTransparency = 1
            sepRow.LayoutOrder = Section._order
            local line = newFrame(sepRow, UDim2.new(1, -16, 0, 1), UDim2.new(0, 8, 0.5, 0), C.border, "Separator")
            line.AnchorPoint = Vector2.new(0, 0.5)
            if text and text ~= "" then
                local tw = TextService:GetTextSize(tostring(text), 13, FONT_UI, Vector2.new(9e9, 9e9)).X
                local lbl = newLabel(sepRow, tostring(text), 13, C.text_sec, FONT_UI)
                lbl.BackgroundTransparency = 0
                lbl.BackgroundColor3 = C.panel
                lbl.AnchorPoint = Vector2.new(0.5, 0.5)
                lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
                lbl.Size = UDim2.new(0, tw + 10, 0, 16)
                lbl.TextXAlignment = Enum.TextXAlignment.Center
            end
            trackRow(sepRow)
            Section._order = Section._order + 1
        end

        return Section
    end

    -- ── TAB (Jan's horizontal text tabs + dual-column groupboxes) ────────
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tostring(tabConfig.Name or ("Tab " .. (#Window._tabs + 1)))
        local pinned = tabConfig.Pinned == true

        local tw = TextService:GetTextSize(tabName, 14, FONT_UI, Vector2.new(9e9, 9e9)).X
        local tabBtn = newButton(tabListFrame, UDim2.new(0, tw + 14, 1, 0), nil, C.tabbar)
        tabBtn.BackgroundTransparency = 1
        tabBtn.LayoutOrder = pinned and 900 or (#Window._tabs + 1)

        local tabLbl = newLabel(tabBtn, tabName, 14, C.text_dim, FONT_UI)
        tabLbl.Size = UDim2.new(1, 0, 1, 0)
        tabLbl.TextXAlignment = Enum.TextXAlignment.Center

        local tabLine = newFrame(tabBtn, UDim2.new(1, -6, 0, 1), UDim2.new(0, 3, 1, -1), C.accent, "ActiveLine")
        tabLine.Visible = false

        local page = newFrame(content, UDim2.new(1, 0, 1, 0), nil, C.window, tabName .. "Page")
        page.BackgroundTransparency = 1
        page.Visible = false

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = C.accent
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop = UDim.new(0, 10)
        pagePad.PaddingLeft = UDim.new(0, 8)
        pagePad.PaddingRight = UDim.new(0, 8)
        pagePad.PaddingBottom = UDim.new(0, 10)
        pagePad.Parent = scroll

        local columns = newFrame(scroll, UDim2.new(1, 0, 0, 0), nil, C.window, "Columns")
        columns.BackgroundTransparency = 1
        columns.AutomaticSize = Enum.AutomaticSize.Y

        local leftCol = newFrame(columns, UDim2.new(0.5, -4, 0, 0), UDim2.new(0, 0, 0, 0), C.window, "LeftCol")
        leftCol.BackgroundTransparency = 1
        leftCol.AutomaticSize = Enum.AutomaticSize.Y
        local leftLayout = Instance.new("UIListLayout")
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Padding = UDim.new(0, 12)
        leftLayout.Parent = leftCol

        local rightCol = newFrame(columns, UDim2.new(0.5, -4, 0, 0), UDim2.new(0.5, 4, 0, 0), C.window, "RightCol")
        rightCol.BackgroundTransparency = 1
        rightCol.AutomaticSize = Enum.AutomaticSize.Y
        local rightLayout = Instance.new("UIListLayout")
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Padding = UDim.new(0, 12)
        rightLayout.Parent = rightCol

        local entry = { page = page, btn = tabBtn, lbl = tabLbl, line = tabLine }
        table.insert(Window._tabs, entry)

        local function activate()
            closePopups()
            hideTooltip()
            for _, e in ipairs(Window._tabs) do
                e.page.Visible = false
                e.lbl.TextColor3 = C.text_dim
                e.line.Visible = false
            end
            page.Visible = true
            tabLbl.TextColor3 = C.accent_hi
            tabLine.Visible = true
            Window._active = entry
        end

        tabBtn.MouseButton1Click:Connect(function()
            if Window._active ~= entry then
                activate()
                click()
            end
        end)
        tabBtn.MouseEnter:Connect(function()
            if Window._active ~= entry then tabLbl.TextColor3 = C.text end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active ~= entry then tabLbl.TextColor3 = C.text_dim end
        end)

        if not pinned and Window._active == nil then activate() end

        local Tab = {}
        Tab._page = page
        Tab._scroll = scroll
        Tab._order = 0

        function Tab:Section(sectionName)
            sectionName = tostring(sectionName or "Section")
            Tab._order = Tab._order + 1

            local targetCol = (Tab._order % 2 == 1) and leftCol or rightCol

            local sec = newFrame(targetCol, UDim2.new(1, 0, 0, 0), nil, C.panel, sectionName .. "Section")
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.LayoutOrder = Tab._order
            stroke(sec, C.border_blk, 1)
            trackBg(sec, 0)

            -- Inner border + purple top accent line (Jan's signature groupbox)
            local secInner = newFrame(sec, UDim2.new(1, -2, 1, -2), UDim2.new(0, 1, 0, 1), C.panel, "Inner")
            secInner.AutomaticSize = Enum.AutomaticSize.Y
            stroke(secInner, C.border, 1)
            trackBg(secInner, 0)

            -- Purple 1px top line inside groupbox
            newFrame(secInner, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), C.accent, "TopAccent")

            -- Title cutout sitting right on the top border!
            local titleW = TextService:GetTextSize(sectionName, 14, FONT_UI, Vector2.new(9e9, 9e9)).X
            local hdrLbl = newLabel(sec, sectionName, 14, C.text, FONT_UI)
            hdrLbl.BackgroundTransparency = 0
            hdrLbl.BackgroundColor3 = C.panel
            hdrLbl.Position = UDim2.new(0, 10, 0, -8)
            hdrLbl.Size = UDim2.new(0, titleW + 8, 0, 16)
            hdrLbl.TextXAlignment = Enum.TextXAlignment.Center
            hdrLbl.ZIndex = 6

            local body = newFrame(secInner, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 8), C.panel, "Body")
            body.BackgroundTransparency = 1
            body.AutomaticSize = Enum.AutomaticSize.Y
            local bodyPad = Instance.new("UIPadding")
            bodyPad.PaddingTop = UDim.new(0, 4)
            bodyPad.PaddingBottom = UDim.new(0, 6)
            bodyPad.Parent = body
            local bodyList = Instance.new("UIListLayout")
            bodyList.SortOrder = Enum.SortOrder.LayoutOrder
            bodyList.Padding = UDim.new(0, 2)
            bodyList.Parent = body

            local sectionRef = { frame = sec, rows = {} }
            return makeItemAPI(body, sectionRef)
        end

        return Tab
    end

    -- ── SETTINGS TAB ──────────────────────────────────────────────────────
    settingsTab = Window:Tab({ Name = "Settings", Pinned = true })

    local interfaceSec = settingsTab:Section("Interface")
    interfaceSec:Label({ Text = "Menu Key: " .. toggleKey.Name, Color = C.text_sec })

    interfaceSec:Keybind({
        Name = "Menu Keybind",
        Default = toggleKey,
        Flag = "menuKey",
        Callback = function(key)
            toggleKey = key
            keyHintLbl.Text = string.upper(key.Name)
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
        Name = "Scale",
        Min = 0.8,
        Max = 1.3,
        Step = 0.05,
        Default = scale,
        Suffix = "x",
        Flag = "guiScale",
        Callback = function(v) setScale(v) end,
    })

    appearanceSec:Stepper({
        Name = "Opacity",
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
        Default = soundsEnabled,
        Flag = "sounds",
        Callback = function(v) soundsEnabled = v end,
    })

    appearanceSec:Toggle({
        Name = "Watermark",
        Default = true,
        Flag = "watermark",
        Callback = function(v) wm.Visible = v end,
    })

    appearanceSec:Toggle({
        Name = "Keybind List",
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

    local cfgList = configSec:Label({ Text = "Configs: None" })

    configSec:Button({
        Name = "Save Config",
        Callback = function()
            Window:SaveConfig(cfgName:Get())
            refreshConfigLabel()
        end,
    })

    configSec:Button({
        Name = "Load Config",
        Callback = function() Window:LoadConfig(cfgName:Get()) end,
    })

    configSec:Button({
        Name = "Delete Config",
        Callback = function()
            Window:DeleteConfig(cfgName:Get())
            refreshConfigLabel()
        end,
    })

    configSec:Button({
        Name = "Reset Defaults",
        Callback = function() Window:ResetDefaults() end,
    })

    refreshConfigLabel = function()
        local names = Window:ListConfigs()
        cfgList:Set("Configs: " .. (#names > 0 and table.concat(names, ", ") or "None"))
    end
    refreshConfigLabel()

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
            wmStats.Text = tostring(frames) .. " FPS | " .. (ok and tostring(ping) or "---") .. " MS"
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
