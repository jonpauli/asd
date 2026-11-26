--[[
    VANTALib — Source-engine / CS:GO styled Roblox UI library
    version: 2.0.0
    aesthetic: Panorama — flat square panels, hairline separators, monospace readouts,
               weathered gold accents, no rounded corners, no window close button.

    load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/VANTALib.lua"))()

    Every window is built with a SETTINGS tab at the bottom of the rail:
      · rebind the key that hides/shows the menu
      · hide the menu
      · unload the whole interface from memory
]]

local VANTALib = {}
VANTALib.__index = VANTALib

local VERSION = "2.0.0"

-- ───────────────────────────────────────────────────────────────────────────
--  PALETTE — Source / CS:GO panorama
-- ───────────────────────────────────────────────────────────────────────────
local C = {
    window      = Color3.fromRGB(18, 18, 20),
    rail        = Color3.fromRGB(14, 14, 16),
    panel       = Color3.fromRGB(24, 24, 27),
    header      = Color3.fromRGB(32, 32, 36),
    row_hover   = Color3.fromRGB(31, 31, 35),
    row_active  = Color3.fromRGB(41, 41, 46),
    field       = Color3.fromRGB(15, 15, 17),
    field_hover = Color3.fromRGB(35, 35, 39),
    accent      = Color3.fromRGB(197, 152, 62),
    accent_hi   = Color3.fromRGB(232, 188, 98),
    accent_dim  = Color3.fromRGB(120, 92, 38),
    border      = Color3.fromRGB(42, 42, 47),
    border_hi   = Color3.fromRGB(66, 66, 74),
    text        = Color3.fromRGB(222, 222, 224),
    text_sec    = Color3.fromRGB(148, 148, 154),
    text_dim    = Color3.fromRGB(98, 98, 106),
    success     = Color3.fromRGB(138, 182, 96),
    danger      = Color3.fromRGB(196, 70, 58),
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
local LocalPlayer      = Players.LocalPlayer

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
    return f
end

local function stroke(gui, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = gui
    return s
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
    return b
end

local function toHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(math.clamp(c.R, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.G, 0, 1) * 255 + 0.5),
        math.floor(math.clamp(c.B, 0, 1) * 255 + 0.5))
end

local function makeDraggable(target, handle, sink)
    local dragging, dragStart, startPos
    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    local c2 = handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    local c3 = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
    if sink then
        table.insert(sink, c1)
        table.insert(sink, c2)
        table.insert(sink, c3)
    end
end

-- ───────────────────────────────────────────────────────────────────────────
--  FEED (top-right notices, Source style)
-- ───────────────────────────────────────────────────────────────────────────
local notifGui, notifHolder, notifSeq = nil, nil, 0

local function ensureNotifs()
    if notifGui and notifGui.Parent then return notifHolder end
    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "_VANTAFeed"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder = 10
    notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    notifHolder = newFrame(notifGui, UDim2.new(0, 260, 1, 0), UDim2.new(1, -272, 0, 10))
    notifHolder.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = notifHolder
    return notifHolder
end

function VANTALib:Notify(title, body, duration)
    local holder = ensureNotifs()
    duration = duration or 4
    notifSeq = notifSeq + 1

    local card = newFrame(holder, UDim2.new(1, 0, 0, 52), nil, C.panel, "Notice")
    card.LayoutOrder = notifSeq
    stroke(card, C.border, 1)
    newFrame(card, UDim2.new(0, 2, 1, 0), nil, C.accent, "Bar")

    local t = newLabel(card, string.upper(tostring(title or "")), 11, C.accent_hi, FONT_BOLD)
    t.Position = UDim2.new(0, 10, 0, 6)
    t.Size = UDim2.new(1, -16, 0, 14)

    local b = newLabel(card, tostring(body or ""), 11, C.text_sec, FONT_UI)
    b.Position = UDim2.new(0, 10, 0, 21)
    b.Size = UDim2.new(1, -16, 0, 24)
    b.TextWrapped = true
    b.TextYAlignment = Enum.TextYAlignment.Top

    local prog = newFrame(card, UDim2.new(1, -2, 0, 1), UDim2.new(0, 2, 1, -1), C.accent_dim, "Progress")
    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Size = UDim2.new(0, 0, 0, 1) }):Play()

    task.delay(duration, function()
        if card and card.Parent then card:Destroy() end
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
--  WINDOW
-- ───────────────────────────────────────────────────────────────────────────
local TITLE_H = 30
local RAIL_W = 148

function VANTALib:CreateWindow(config)
    config = config or {}
    local title = tostring(config.Title or "VANTA")
    local width = config.Width or 580
    local height = config.Height or 440
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    local connections = {}
    local inputCtx = { listening = false }

    local function claim(event, fn)
        local conn = UserInputService[event]:Connect(fn)
        table.insert(connections, conn)
        return conn
    end

    -- screen gui
    local sg = Instance.new("ScreenGui")
    sg.Name = "VANTA_" .. title
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 5
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- window body
    local root = newFrame(sg, UDim2.new(0, width, 0, height),
        UDim2.new(0.5, -width / 2, 0.5, -height / 2), C.window, "Window")
    stroke(root, C.border_hi, 1)
    newFrame(root, UDim2.new(1, 0, 0, 1), nil, C.border_hi, "TopLine")

    -- ── TITLEBAR ──────────────────────────────────────────────────────────
    local titlebar = newFrame(root, UDim2.new(1, 0, 0, TITLE_H), nil, C.header, "Titlebar")
    newFrame(titlebar, UDim2.new(0, 3, 1, 0), nil, C.accent, "Accent")

    local titleLbl = newLabel(titlebar, string.upper(title):sub(1, 26), 12, C.text, FONT_BOLD)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.Size = UDim2.new(0, 260, 1, 0)

    local keyHint = newLabel(titlebar, "v" .. VERSION .. "    " .. toggleKey.Name:upper() .. " : MENU",
        10, C.text_dim, FONT_MONO)
    keyHint.AnchorPoint = Vector2.new(1, 0)
    keyHint.Position = UDim2.new(1, -12, 0, 0)
    keyHint.Size = UDim2.new(0, 260, 1, 0)
    keyHint.TextXAlignment = Enum.TextXAlignment.Right

    newFrame(root, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, TITLE_H), C.border, "BAR_LINE")

    makeDraggable(root, titlebar, connections)

    -- menu keybind is registered before any widget listener, so a key being
    -- captured for a rebind is never also applied to the menu toggle
    claim("InputBegan", function(input, processed)
        if processed then return end
        if inputCtx.listening then return end
        if input.KeyCode == toggleKey then
            root.Visible = not root.Visible
        end
    end)

    -- ── RAIL ──────────────────────────────────────────────────────────────
    local rail = newFrame(root, UDim2.new(0, RAIL_W, 1, -(TITLE_H + 1)),
        UDim2.new(0, 0, 0, TITLE_H + 1), C.rail, "Rail")
    newFrame(root, UDim2.new(0, 1, 1, -(TITLE_H + 1)),
        UDim2.new(0, RAIL_W, 0, TITLE_H + 1), C.border, "RailLine")

    local railList = Instance.new("UIListLayout")
    railList.SortOrder = Enum.SortOrder.LayoutOrder
    railList.Padding = UDim.new(0, 1)
    railList.Parent = rail
    local railPad = Instance.new("UIPadding")
    railPad.PaddingTop = UDim.new(0, 6)
    railPad.Parent = rail

    -- ── CONTENT ───────────────────────────────────────────────────────────
    local content = newFrame(root, UDim2.new(1, -(RAIL_W + 1), 1, -(TITLE_H + 1)),
        UDim2.new(0, RAIL_W + 1, 0, TITLE_H + 1), C.window, "Content")

    -- ── ITEM API (shared by tabs and by expandable setting blocks) ────────
    local function makeItemAPI(items, claimFn, ctx)
        local Section = { _items = items, _order = 0 }

        local function newItemRow(h)
            Section._order = Section._order + 1
            local row = newFrame(items, UDim2.new(1, 0, 0, h), nil, C.panel, "Row")
            row.LayoutOrder = Section._order
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 10)
            pad.PaddingRight = UDim.new(0, 10)
            pad.Parent = row
            newFrame(row, UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 1, -1), C.border, "Sep")
            row.MouseEnter:Connect(function() row.BackgroundColor3 = C.row_hover end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = C.panel end)
            return row
        end

        -- ── TOGGLE (square CS:GO checkbox) ────────────────────────────────
        function Section:Toggle(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Toggle")
            local desc = cfg.Description
            local hasGear = cfg.Settings ~= nil
            local state = cfg.Default == true

            local row = newItemRow(desc and 46 or 34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, desc and 0 or 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0, desc and 7 or 0.5, 0)
            nameLbl.Size = UDim2.new(1, -108, 0, 15)
            nameLbl.ZIndex = 2

            if desc then
                local d = newLabel(row, tostring(desc), 10, C.text_dim, FONT_UI)
                d.Position = UDim2.new(0, 0, 0, 22)
                d.Size = UDim2.new(1, -108, 0, 13)
                d.ZIndex = 2
            end

            local stateLbl = newLabel(row, state and "ON" or "OFF", 10,
                state and C.accent_hi or C.text_dim, FONT_MONO)
            stateLbl.AnchorPoint = Vector2.new(1, 0.5)
            stateLbl.Position = UDim2.new(1, hasGear and -48 or -22, 0.5, 0)
            stateLbl.Size = UDim2.new(0, 24, 0, 12)
            stateLbl.TextXAlignment = Enum.TextXAlignment.Right
            stateLbl.ZIndex = 2

            local box = newButton(row, UDim2.new(0, 16, 0, 16), UDim2.new(1, 0, 0.5, 0),
                state and C.accent or C.field)
            box.AnchorPoint = Vector2.new(1, 0.5)
            box.ZIndex = 3
            local boxStroke = stroke(box, state and C.accent_hi or C.border, 1)

            local check = newLabel(box, "✓", 11, C.window, FONT_BOLD)
            check.Size = UDim2.new(1, 0, 1, 0)
            check.TextXAlignment = Enum.TextXAlignment.Center
            check.Visible = state
            check.ZIndex = 4

            local settingsPanel, gearGlyph, gearBtn

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

            -- expandable settings block, populated by cfg.Settings(section)
            if hasGear then
                settingsPanel = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.field, "Settings")
                settingsPanel.AutomaticSize = Enum.AutomaticSize.Y
                settingsPanel.Visible = false
                settingsPanel.LayoutOrder = Section._order + 0.5
                newFrame(settingsPanel, UDim2.new(0, 2, 1, 0), nil, C.accent_dim, "Edge")
                local cfgLayout = Instance.new("UIListLayout")
                cfgLayout.SortOrder = Enum.SortOrder.LayoutOrder
                cfgLayout.Parent = settingsPanel

                local cfgSection = makeItemAPI(settingsPanel, claimFn, ctx)
                cfg.Settings(cfgSection, cfgSection)

                gearBtn = newButton(row, UDim2.new(0, 20, 0, 20), UDim2.new(1, -22, 0.5, 0), C.field)
                gearBtn.AnchorPoint = Vector2.new(1, 0.5)
                gearBtn.ZIndex = 4
                stroke(gearBtn, C.border, 1)

                gearGlyph = newLabel(gearBtn, "▸", 10, C.text_sec, FONT_MONO)
                gearGlyph.Size = UDim2.new(1, 0, 1, 0)
                gearGlyph.TextXAlignment = Enum.TextXAlignment.Center
                gearGlyph.ZIndex = 5

                gearBtn.MouseEnter:Connect(function()
                    gearBtn.BackgroundColor3 = C.field_hover
                end)
                gearBtn.MouseLeave:Connect(function()
                    gearBtn.BackgroundColor3 = settingsPanel.Visible and C.accent_dim or C.field
                end)
                gearBtn.MouseButton1Click:Connect(function()
                    settingsPanel.Visible = not settingsPanel.Visible
                    gearGlyph.Text = settingsPanel.Visible and "▾" or "▸"
                    gearGlyph.TextColor3 = settingsPanel.Visible and C.accent_hi or C.text_sec
                    gearBtn.BackgroundColor3 = settingsPanel.Visible and C.accent_dim or C.field
                end)
            end

            local hit = newButton(row, UDim2.new(1, 0, 1, 0), nil, C.panel)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 1
            hit.MouseButton1Click:Connect(function() setState(not state) end)
            box.MouseButton1Click:Connect(function() setState(not state) end)

            local obj = {}
            function obj:Set(v) setState(v, true) end
            function obj:Get() return state end
            function obj:ToggleState() setState(not state) end
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

            local function fmt(v)
                if step >= 1 then
                    return tostring(math.floor(v + 0.5)) .. suffix
                elseif step >= 0.1 then
                    return string.format("%.1f", v) .. suffix
                end
                return string.format("%.2f", v) .. suffix
            end

            local row = newItemRow(42)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.Position = UDim2.new(0, 0, 0, 7)
            nameLbl.Size = UDim2.new(1, -100, 0, 14)
            nameLbl.ZIndex = 2

            local valLbl = newLabel(row, fmt(value), 11, C.accent_hi, FONT_MONO)
            valLbl.AnchorPoint = Vector2.new(1, 0)
            valLbl.Position = UDim2.new(1, 0, 0, 7)
            valLbl.Size = UDim2.new(0, 96, 0, 14)
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.ZIndex = 2

            local track = newFrame(row, UDim2.new(1, 0, 0, 4), UDim2.new(0, 0, 1, -10), C.field, "Track")
            track.AnchorPoint = Vector2.new(0, 1)
            track.ZIndex = 2

            local fill = newFrame(track, UDim2.new((value - min) / (max - min), 0, 1, 0), nil, C.accent, "Fill")
            fill.ZIndex = 3

            local knob = newFrame(track, UDim2.new(0, 8, 0, 12),
                UDim2.new((value - min) / (max - min), 0, 0.5, 0), C.accent_hi, "Knob")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            stroke(knob, C.accent_hi, 1)
            knob.ZIndex = 4

            local hit = newButton(row, UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -20), C.field)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 5

            local function render()
                local pct = (value - min) / (max - min)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text = fmt(value)
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
            claimFn("InputChanged", function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                setFromX(input.Position.X)
            end)
            claimFn("InputEnded", function(input)
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
            return obj
        end

        -- ── DROPDOWN ──────────────────────────────────────────────────────
        function Section:Dropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Dropdown")
            local options = cfg.Options or {}
            local selected = cfg.Default or options[1] or ""
            local open = false

            local row = newItemRow(34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
            nameLbl.Size = UDim2.new(0.42, 0, 0, 15)
            nameLbl.ZIndex = 2

            local dropBtn = newButton(row, UDim2.new(0.55, 0, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 3
            stroke(dropBtn, C.border, 1)

            local selLbl = newLabel(dropBtn, tostring(selected), 11, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 8, 0, 0)
            selLbl.Size = UDim2.new(1, -26, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 4

            local arrow = newLabel(dropBtn, "▾", 10, C.text_sec, FONT_MONO)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 4

            local listHolder = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.window, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.accent_dim, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local function renderList()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = opt == selected
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 24), nil,
                        isSel and C.row_active or C.window)
                    optBtn.LayoutOrder = i
                    if isSel then
                        newFrame(optBtn, UDim2.new(0, 2, 1, 0), nil, C.accent, "Mark")
                    end
                    local optLbl = newLabel(optBtn, tostring(opt), 11,
                        isSel and C.accent_hi or C.text, FONT_UI)
                    optLbl.Position = UDim2.new(0, 10, 0, 0)
                    optLbl.Size = UDim2.new(1, -14, 1, 0)
                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.window
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        selLbl.Text = tostring(opt)
                        open = false
                        listHolder.Visible = false
                        arrow.Text = "▾"
                        renderList()
                        if cfg.Callback then cfg.Callback(selected) end
                    end)
                end
            end
            renderList()

            dropBtn.MouseEnter:Connect(function() dropBtn.BackgroundColor3 = C.field_hover end)
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.field end)
            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                listHolder.Visible = open
                arrow.Text = open and "▴" or "▾"
                arrow.TextColor3 = open and C.accent_hi or C.text_sec
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
            return obj
        end

        -- ── MULTI DROPDOWN ────────────────────────────────────────────────
        function Section:MultiDropdown(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Multi Select")
            local options = cfg.Options or {}
            local selected = {}
            for _, v in ipairs(cfg.Default or {}) do selected[v] = true end
            local open = false

            local row = newItemRow(34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
            nameLbl.Size = UDim2.new(0.42, 0, 0, 15)
            nameLbl.ZIndex = 2

            local dropBtn = newButton(row, UDim2.new(0.55, 0, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            dropBtn.AnchorPoint = Vector2.new(0, 0.5)
            dropBtn.ZIndex = 3
            stroke(dropBtn, C.border, 1)

            local function summary()
                local t = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then table.insert(t, tostring(opt)) end
                end
                if #t == 0 then return "NONE" end
                if #t == 1 then return t[1] end
                return t[1] .. " +" .. tostring(#t - 1)
            end

            local selLbl = newLabel(dropBtn, summary(), 11, C.text, FONT_UI)
            selLbl.Position = UDim2.new(0, 8, 0, 0)
            selLbl.Size = UDim2.new(1, -26, 1, 0)
            selLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selLbl.ZIndex = 4

            local arrow = newLabel(dropBtn, "▾", 10, C.text_sec, FONT_MONO)
            arrow.Position = UDim2.new(1, -18, 0, 0)
            arrow.Size = UDim2.new(0, 14, 1, 0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.ZIndex = 4

            local listHolder = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.window, "Options")
            listHolder.AutomaticSize = Enum.AutomaticSize.Y
            listHolder.Visible = false
            listHolder.LayoutOrder = Section._order + 0.5
            stroke(listHolder, C.accent_dim, 1)
            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listHolder

            local renderList

            local function selectionList()
                local t = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then table.insert(t, opt) end
                end
                return t
            end

            renderList = function()
                for _, child in ipairs(listHolder:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") then
                        child:Destroy()
                    end
                end
                for i, opt in ipairs(options) do
                    local isSel = selected[opt] == true
                    local optBtn = newButton(listHolder, UDim2.new(1, 0, 0, 24), nil,
                        isSel and C.row_active or C.window)
                    optBtn.LayoutOrder = i

                    local box = newFrame(optBtn, UDim2.new(0, 12, 0, 12), UDim2.new(0, 9, 0.5, 0),
                        isSel and C.accent or C.field, "Check")
                    box.AnchorPoint = Vector2.new(0, 0.5)
                    stroke(box, isSel and C.accent_hi or C.border, 1)
                    if isSel then
                        local mark = newLabel(box, "✓", 9, C.window, FONT_BOLD)
                        mark.Size = UDim2.new(1, 0, 1, 0)
                        mark.TextXAlignment = Enum.TextXAlignment.Center
                    end

                    local optLbl = newLabel(optBtn, tostring(opt), 11,
                        isSel and C.text or C.text_sec, FONT_UI)
                    optLbl.Position = UDim2.new(0, 28, 0, 0)
                    optLbl.Size = UDim2.new(1, -32, 1, 0)

                    optBtn.MouseEnter:Connect(function()
                        optBtn.BackgroundColor3 = C.row_hover
                    end)
                    optBtn.MouseLeave:Connect(function()
                        optBtn.BackgroundColor3 = isSel and C.row_active or C.window
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected[opt] = not selected[opt] or nil
                        if selected[opt] == false then selected[opt] = nil end
                        selLbl.Text = summary()
                        renderList()
                        if cfg.Callback then cfg.Callback(selectionList()) end
                    end)
                end
            end
            renderList()

            dropBtn.MouseEnter:Connect(function() dropBtn.BackgroundColor3 = C.field_hover end)
            dropBtn.MouseLeave:Connect(function() dropBtn.BackgroundColor3 = C.field end)
            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                listHolder.Visible = open
                arrow.Text = open and "▴" or "▾"
                arrow.TextColor3 = open and C.accent_hi or C.text_sec
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
            return obj
        end

        -- ── COLOR PICKER ──────────────────────────────────────────────────
        function Section:ColorPicker(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Color")
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local h, s, v = Color3.toHSV(default)
            local open = false
            local hexFocused = false

            local row = newItemRow(34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -90, 0, 15)
            nameLbl.ZIndex = 2

            local swatch = newButton(row, UDim2.new(0, 76, 0, 20), UDim2.new(1, 0, 0.5, 0), default)
            swatch.AnchorPoint = Vector2.new(1, 0.5)
            swatch.ZIndex = 3
            stroke(swatch, C.border_hi, 1)

            local hexLbl = newLabel(swatch, toHex(default), 9, C.white, FONT_MONO)
            hexLbl.Size = UDim2.new(1, 0, 1, 0)
            hexLbl.TextXAlignment = Enum.TextXAlignment.Center
            hexLbl.TextStrokeTransparency = 0.4
            hexLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            hexLbl.ZIndex = 4

            local panel = newFrame(items, UDim2.new(1, 0, 0, 0), nil, C.window, "Picker")
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

            local cursor = newFrame(sv, UDim2.new(0, 8, 0, 8), UDim2.new(s, 0, 1 - v, 0), Color3.new(1, 1, 1), "Cursor")
            cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cursor.ZIndex = 5
            stroke(cursor, C.white, 1)

            local hue = newFrame(panel, UDim2.new(1, 0, 0, 10), nil, C.white, "Hue")
            hue.LayoutOrder = 2
            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,    Color3.fromHSV(0, 1, 1)),
                ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1, 1)),
                ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                ColorSequenceKeypoint.new(1,    Color3.fromHSV(1, 1, 1)),
            })
            hueGrad.Parent = hue

            local hueCursor = newFrame(hue, UDim2.new(0, 6, 0, 12), UDim2.new(h, 0, 0.5, 0),
                Color3.fromHSV(h, 1, 1), "HueCursor")
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.ZIndex = 5
            stroke(hueCursor, C.white, 1)

            local hexRow = newFrame(panel, UDim2.new(1, 0, 0, 24), nil, C.field, "HexRow")
            hexRow.LayoutOrder = 3

            local hash = newLabel(hexRow, "#", 11, C.text_sec, FONT_MONO)
            hash.Position = UDim2.new(0, 7, 0, 0)
            hash.Size = UDim2.new(0, 12, 1, 0)

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -24, 1, 0)
            hexBox.Position = UDim2.new(0, 22, 0, 0)
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
                hexLbl.Text = toHex(color)
                if not hexFocused then hexBox.Text = toHex(color):sub(2) end
                if call and cfg.Callback then cfg.Callback(color) end
            end

            local svDrag = false
            sv.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    svDrag = true
                end
            end)
            claimFn("InputChanged", function(input)
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
            claimFn("InputChanged", function(input)
                if not hueDrag then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                    and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local abs, sz = hue.AbsolutePosition, hue.AbsoluteSize
                h = math.clamp((input.Position.X - abs.X) / math.max(sz.X, 1), 0, 1)
                render(true)
            end)
            claimFn("InputEnded", function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    svDrag = false
                    hueDrag = false
                end
            end)

            hexBox.Focused:Connect(function() hexFocused = true end)
            hexBox.FocusLost:Connect(function()
                hexFocused = false
                local raw = hexBox.Text:gsub("#", ""):upper()
                if #raw == 6 then
                    local r = tonumber(raw:sub(1, 2), 16)
                    local g = tonumber(raw:sub(3, 4), 16)
                    local b = tonumber(raw:sub(5, 6), 16)
                    if r and g and b then
                        h, s, v = Color3.toHSV(Color3.fromRGB(r, g, b))
                    end
                end
                render(true)
            end)

            swatch.MouseEnter:Connect(function() swatch.BackgroundTransparency = 0.15 end)
            swatch.MouseLeave:Connect(function() swatch.BackgroundTransparency = 0 end)
            swatch.MouseButton1Click:Connect(function()
                open = not open
                panel.Visible = open
            end)

            local obj = {}
            function obj:Get() return Color3.fromHSV(h, s, v) end
            function obj:Set(color)
                h, s, v = Color3.toHSV(color)
                render(true)
            end
            return obj
        end

        -- ── BUTTON ────────────────────────────────────────────────────────
        function Section:Button(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Button")
            local desc = cfg.Description

            local row = newItemRow(desc and 46 or 34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, desc and 0 or 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0, desc and 7 or 0.5, 0)
            nameLbl.Size = UDim2.new(1, -60, 0, 15)
            nameLbl.ZIndex = 2

            if desc then
                local d = newLabel(row, tostring(desc), 10, C.text_dim, FONT_UI)
                d.Position = UDim2.new(0, 0, 0, 22)
                d.Size = UDim2.new(1, -60, 0, 13)
                d.ZIndex = 2
            end

            local runLbl = newLabel(row, "RUN", 9, C.accent_hi, FONT_MONO)
            runLbl.AnchorPoint = Vector2.new(1, 0.5)
            runLbl.Position = UDim2.new(1, 0, 0.5, 0)
            runLbl.Size = UDim2.new(0, 40, 0, 12)
            runLbl.TextXAlignment = Enum.TextXAlignment.Right
            runLbl.ZIndex = 2

            local hit = newButton(row, UDim2.new(1, 0, 1, 0), nil, C.panel)
            hit.BackgroundTransparency = 1
            hit.ZIndex = 3

            row.MouseEnter:Connect(function()
                runLbl.TextColor3 = C.white
            end)
            row.MouseLeave:Connect(function()
                runLbl.TextColor3 = C.accent_hi
            end)
            hit.MouseButton1Click:Connect(function()
                row.BackgroundColor3 = C.row_active
                task.delay(0.08, function()
                    if row and row.Parent then row.BackgroundColor3 = C.row_hover end
                end)
                if cfg.Callback then cfg.Callback() end
            end)
        end

        -- ── TEXTBOX ───────────────────────────────────────────────────────
        function Section:TextBox(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Input")
            local placeholder = tostring(cfg.Placeholder or "...")

            local row = newItemRow(34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
            nameLbl.Size = UDim2.new(0.38, 0, 0, 15)
            nameLbl.ZIndex = 2

            local inputFrame = newFrame(row, UDim2.new(0.55, 0, 0, 22), UDim2.new(0.45, 0, 0.5, 0), C.field)
            inputFrame.AnchorPoint = Vector2.new(0, 0.5)
            inputFrame.ZIndex = 2
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
            inputBox.TextSize = 11
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = inputFrame

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
            return obj
        end

        -- ── KEYBIND ───────────────────────────────────────────────────────
        function Section:Keybind(cfg)
            cfg = cfg or {}
            local name = tostring(cfg.Name or "Keybind")
            local bound = cfg.Default or Enum.KeyCode.Unknown
            local listening = false

            local row = newItemRow(34)

            local nameLbl = newLabel(row, name, 12, C.text, FONT_UI)
            nameLbl.AnchorPoint = Vector2.new(0, 0.5)
            nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
            nameLbl.Size = UDim2.new(1, -110, 0, 15)
            nameLbl.ZIndex = 2

            local kbBtn = newButton(row, UDim2.new(0, 96, 0, 20), UDim2.new(1, 0, 0.5, 0), C.field)
            kbBtn.AnchorPoint = Vector2.new(1, 0.5)
            kbBtn.ZIndex = 3
            local kbStroke = stroke(kbBtn, C.border, 1)

            local kbLbl = newLabel(kbBtn, bound.Name:upper(), 9, C.text, FONT_MONO)
            kbLbl.Size = UDim2.new(1, 0, 1, 0)
            kbLbl.TextXAlignment = Enum.TextXAlignment.Center
            kbLbl.ZIndex = 4

            local function stopListening()
                listening = false
                ctx.listening = false
                kbLbl.Text = bound.Name:upper()
                kbLbl.TextColor3 = C.text
                kbStroke.Color = C.border
                kbBtn.BackgroundColor3 = C.field
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
                ctx.listening = true
                kbLbl.Text = "PRESS KEY"
                kbLbl.TextColor3 = C.accent_hi
                kbStroke.Color = C.accent
                kbBtn.BackgroundColor3 = C.row_active
            end)

            claimFn("InputBegan", function(input, processed)
                if not listening or processed then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                bound = input.KeyCode
                stopListening()
                if cfg.Callback then cfg.Callback(bound) end
            end)

            local obj = {}
            function obj:Get() return bound end
            function obj:Set(key)
                bound = key
                kbLbl.Text = key.Name:upper()
            end
            return obj
        end

        -- ── LABEL ─────────────────────────────────────────────────────────
        function Section:Label(cfg)
            cfg = cfg or {}
            Section._order = Section._order + 1
            local row = newFrame(items, UDim2.new(1, 0, 0, 22), nil, C.panel, "LabelRow")
            row.LayoutOrder = Section._order
            local lbl = newLabel(row, tostring(cfg.Text or ""), 10,
                cfg.Color or C.text_dim, FONT_MONO)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.Size = UDim2.new(1, -20, 1, 0)
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            local obj = {}
            function obj:Set(t) lbl.Text = tostring(t) end
            return obj
        end

        -- ── SEPARATOR ─────────────────────────────────────────────────────
        function Section:Separator()
            Section._order = Section._order + 1
            local sep = newFrame(items, UDim2.new(1, -20, 0, 1), UDim2.new(0, 10, 0, 0), C.border, "Separator")
            sep.LayoutOrder = Section._order
        end

        return Section
    end

    -- ── WINDOW OBJECT ─────────────────────────────────────────────────────
    local Window = {}
    Window._tabs = {}
    Window._active = nil
    Window._gui = sg
    Window._win = root
    Window._unloaded = false

    -- ── TAB ───────────────────────────────────────────────────────────────
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tostring(tabConfig.Name or ("Tab " .. (#Window._tabs + 1)))
        local pinned = tabConfig.Pinned == true

        local tabBtn = newButton(rail, UDim2.new(1, 0, 0, 30), nil, C.rail)
        tabBtn.LayoutOrder = pinned and 900 or (#Window._tabs + 1)

        local indicator = newFrame(tabBtn, UDim2.new(0, 2, 1, 0), nil, C.accent, "Ind")
        indicator.Visible = false

        local tabLbl = newLabel(tabBtn, string.upper(tabName):sub(1, 18), 11, C.text_dim, FONT_BOLD)
        tabLbl.Position = UDim2.new(0, 14, 0, 0)
        tabLbl.Size = UDim2.new(1, -18, 1, 0)

        local page = newFrame(content, UDim2.new(1, 0, 1, 0), nil, C.window, tabName .. "Page")
        page.Visible = false

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2
        scroll.ScrollBarImageColor3 = C.border_hi
        scroll.ScrollBarImageTransparency = 0.3
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

        local entry = { page = page, btn = tabBtn, lbl = tabLbl, ind = indicator }
        table.insert(Window._tabs, entry)

        local function activate()
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
            Window._active = entry
        end

        tabBtn.MouseButton1Click:Connect(activate)
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
            sectionName = tostring(sectionName or "Section")
            Tab._order = Tab._order + 1

            local sec = newFrame(scroll, UDim2.new(1, 0, 0, 0), nil, C.panel, sectionName .. "Section")
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.LayoutOrder = Tab._order
            stroke(sec, C.border, 1)

            local hdr = newFrame(sec, UDim2.new(1, 0, 0, 22), nil, C.header, "Header")
            newFrame(hdr, UDim2.new(0, 2, 1, 0), nil, C.accent, "Edge")
            local hdrLbl = newLabel(hdr, string.upper(sectionName), 10, C.text_sec, FONT_BOLD)
            hdrLbl.Position = UDim2.new(0, 10, 0, 0)
            hdrLbl.Size = UDim2.new(1, -14, 1, 0)
            newFrame(sec, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 22), C.border, "Line")

            local items = newFrame(sec, UDim2.new(1, 0, 0, 0), UDim2.new(0, 0, 0, 23), C.panel, "Items")
            items.AutomaticSize = Enum.AutomaticSize.Y
            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Parent = items

            return makeItemAPI(items, claim, inputCtx)
        end

        return Tab
    end

    -- ── SETTINGS TAB (built into every window) ────────────────────────────
    local settingsTab = Window:Tab({ Name = "Settings", Pinned = true })
    local interfaceSec = settingsTab:Section("Interface")
    local hintLabel = interfaceSec:Label({
        Text = "MENU KEY  " .. toggleKey.Name:upper(),
        Color = C.text_sec,
    })

    interfaceSec:Keybind({
        Name = "Menu Keybind",
        Default = toggleKey,
        Callback = function(key)
            toggleKey = key
            keyHint.Text = "v" .. VERSION .. "    " .. key.Name:upper() .. " : MENU"
            hintLabel:Set("MENU KEY  " .. key.Name:upper())
            VANTALib:Notify("Keybind", "Menu key set to " .. key.Name, 2)
        end,
    })

    interfaceSec:Button({
        Name = "Hide Menu",
        Description = "Collapse the interface without unloading",
        Callback = function()
            root.Visible = false
        end,
    })

    interfaceSec:Button({
        Name = "Unload UI",
        Description = "Remove the menu, keybinds and notices from memory",
        Callback = function()
            Window:Unload()
        end,
    })

    local buildSec = settingsTab:Section("Build")
    buildSec:Label({ Text = "VANTA  " .. VERSION .. "  —  SOURCE STYLE" })
    buildSec:Label({ Text = "UNLOAD REMOVES EVERY ELEMENT", Color = C.text_dim })

    -- ── SHOW / HIDE / UNLOAD ──────────────────────────────────────────────
    function Window:Toggle()
        root.Visible = not root.Visible
    end
    function Window:Show() root.Visible = true end
    function Window:Hide() root.Visible = false end

    function Window:Unload()
        if Window._unloaded then return end
        Window._unloaded = true
        root.Visible = false
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
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
