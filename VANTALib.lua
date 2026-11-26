--[[
    VANTALib — CS:GO-style Roblox UI Library
    version: 1.0.0
    aesthetic: Source engine / CS:GO — dark steel panels, sharp geometry, tight monospace feel
    load via: loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_NAME/YOUR_REPO/main/VANTALib.lua"))()
]]

local VANTALib = {}
VANTALib.__index = VANTALib

-- ───────────────────────────────────────────────────────────────────────────
--  PALETTE  — CS:GO dark panel aesthetic
-- ───────────────────────────────────────────────────────────────────────────
local COLOR = {
    bg_deep      = Color3.fromRGB(18, 18, 20),     -- main window body
    bg_panel     = Color3.fromRGB(26, 26, 30),     -- tab / section panels
    bg_element   = Color3.fromRGB(34, 34, 40),     -- toggles, dropdowns, inputs
    bg_hover     = Color3.fromRGB(44, 44, 52),     -- hover state
    bg_active    = Color3.fromRGB(52, 52, 62),     -- pressed / active
    accent       = Color3.fromRGB(230, 170, 40),   -- CS:GO gold/yellow accent
    accent_dim   = Color3.fromRGB(160, 118, 28),   -- dimmed accent
    accent_text  = Color3.fromRGB(255, 195, 60),   -- accent text
    border       = Color3.fromRGB(55, 55, 65),     -- general borders
    border_light = Color3.fromRGB(80, 80, 95),     -- highlight border
    text_prim    = Color3.fromRGB(220, 220, 225),  -- primary text
    text_sec     = Color3.fromRGB(140, 140, 155),  -- secondary / label text
    text_dim     = Color3.fromRGB(85, 85, 100),    -- dimmed / placeholder
    toggle_on    = Color3.fromRGB(80, 200, 100),   -- toggle ON
    toggle_off   = Color3.fromRGB(55, 55, 65),     -- toggle OFF knob track
    danger       = Color3.fromRGB(220, 60, 60),    -- destructive
    white        = Color3.fromRGB(255, 255, 255),
    black        = Color3.fromRGB(0, 0, 0),
}

-- ───────────────────────────────────────────────────────────────────────────
--  SERVICES
-- ───────────────────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local LocalPlayer    = Players.LocalPlayer

-- ───────────────────────────────────────────────────────────────────────────
--  UTILITY
-- ───────────────────────────────────────────────────────────────────────────
local function tween(obj, props, t, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir   = dir   or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t or 0.12, style, dir), props):Play()
end

local function round(frame, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 3)
    corner.Parent = frame
    return corner
end

local function stroke(frame, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLOR.border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = frame
    return s
end

local function label(parent, text, size, color, font, pos, anc)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or COLOR.text_prim
    l.Font = font or Enum.Font.GothamMedium
    l.BackgroundTransparency = 1
    l.Position = pos or UDim2.new(0,0,0,0)
    l.AnchorPoint = anc or Vector2.new(0,0)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function newFrame(parent, size, pos, color, name)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1,0,1,0)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = color or COLOR.bg_panel
    f.BorderSizePixel = 0
    f.Name = name or "Frame"
    f.Parent = parent
    return f
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
--  NOTIFICATION SYSTEM (CS:GO-style top-right popups)
-- ───────────────────────────────────────────────────────────────────────────
local notifContainer
local function ensureNotifContainer()
    if notifContainer and notifContainer.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "_VANTANotifs"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    notifContainer = Instance.new("Frame")
    notifContainer.Name = "Container"
    notifContainer.Size = UDim2.new(0, 280, 1, 0)
    notifContainer.Position = UDim2.new(1, -290, 0, 10)
    notifContainer.BackgroundTransparency = 1
    notifContainer.Parent = sg
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = notifContainer
end

function VANTALib:Notify(title, body, duration)
    ensureNotifContainer()
    duration = duration or 4
    local card = newFrame(notifContainer, UDim2.new(1,0,0,70), nil, COLOR.bg_panel, "Notif")
    round(card, 3)
    stroke(card, COLOR.accent, 1)
    card.BackgroundTransparency = 1
    tween(card, {BackgroundTransparency = 0}, 0.18)

    local accentBar = newFrame(card, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), COLOR.accent, "Bar")
    round(accentBar, 2)

    label(card, title, 13, COLOR.accent_text, Enum.Font.GothamBold,
        UDim2.new(0,12,0,8), Vector2.new(0,0)).Size = UDim2.new(1,-16,0,18)
    local bodyL = label(card, body or "", 12, COLOR.text_sec, Enum.Font.Gotham,
        UDim2.new(0,12,0,28), Vector2.new(0,0))
    bodyL.Size = UDim2.new(1,-16,0,36)
    bodyL.TextWrapped = true

    -- progress bar
    local prog = newFrame(card, UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), COLOR.accent_dim, "Prog")
    tween(prog, {Size = UDim2.new(0,0,0,2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tween(card, {BackgroundTransparency = 1}, 0.2)
        task.delay(0.22, function() card:Destroy() end)
    end)
end

-- ───────────────────────────────────────────────────────────────────────────
--  WINDOW
-- ───────────────────────────────────────────────────────────────────────────
function VANTALib:CreateWindow(config)
    config = config or {}
    local title   = config.Title   or "VANTA"
    local width   = config.Width   or 560
    local height  = config.Height  or 420
    local togKey  = config.ToggleKey or Enum.KeyCode.RightShift

    -- screen gui
    local sg = Instance.new("ScreenGui")
    sg.Name = "VANTALib_" .. title
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- root window
    local win = newFrame(sg,
        UDim2.new(0, width, 0, height),
        UDim2.new(0.5, -width/2, 0.5, -height/2),
        COLOR.bg_deep, "Window")
    round(win, 4)
    stroke(win, COLOR.border, 1)

    -- ── TITLEBAR ──────────────────────────────────────────────────────────
    local titlebar = newFrame(win, UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), COLOR.bg_panel, "Titlebar")
    round(titlebar, 4)
    -- bottom corners square
    local squareMask = newFrame(titlebar, UDim2.new(1,0,0,8), UDim2.new(0,0,1,-8), COLOR.bg_panel, "Mask")
    squareMask.ZIndex = 2

    -- accent strip left edge
    local strip = newFrame(titlebar, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), COLOR.accent, "Strip")

    -- title text
    local titleLabel = label(titlebar, title:upper(), 13, COLOR.accent_text,
        Enum.Font.GothamBold, UDim2.new(0,14,0,0))
    titleLabel.Size = UDim2.new(0,200,1,0)
    titleLabel.ZIndex = 3

    -- version / watermark right side
    local ver = label(titlebar, "v1.0  •  VANTA", 11, COLOR.text_dim,
        Enum.Font.Gotham, UDim2.new(1,-8,0,0), Vector2.new(1,0))
    ver.Size = UDim2.new(0,120,1,0)
    ver.TextXAlignment = Enum.TextXAlignment.Right
    ver.ZIndex = 3

    -- close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-32,0.5,0)
    closeBtn.AnchorPoint = Vector2.new(0,0.5)
    closeBtn.BackgroundColor3 = COLOR.bg_element
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLOR.text_sec
    closeBtn.TextSize = 11
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 4
    closeBtn.Parent = titlebar
    round(closeBtn, 3)
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {BackgroundColor3 = COLOR.danger}, 0.1) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {BackgroundColor3 = COLOR.bg_element}, 0.1) end)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    makeDraggable(win, titlebar)

    -- ── TAB BAR ───────────────────────────────────────────────────────────
    local tabBar = newFrame(win,
        UDim2.new(0, 130, 1, -36),
        UDim2.new(0, 0, 0, 36),
        COLOR.bg_panel, "TabBar")
    local tabBarStroke = stroke(tabBar, COLOR.border, 1)
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop = UDim.new(0,6)
    tabPad.PaddingLeft = UDim.new(0,6)
    tabPad.PaddingRight = UDim.new(0,6)
    tabPad.Parent = tabBar

    -- ── CONTENT AREA ──────────────────────────────────────────────────────
    local contentArea = newFrame(win,
        UDim2.new(1,-134,1,-42),
        UDim2.new(0,132,0,38),
        COLOR.bg_deep, "Content")

    -- ── TOGGLE KEY ────────────────────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == togKey then
            win.Visible = not win.Visible
        end
    end)

    -- ── WINDOW OBJECT ─────────────────────────────────────────────────────
    local Window = {}
    Window._tabs   = {}
    Window._active = nil
    Window._gui    = sg
    Window._win    = win

    -- ── CREATE TAB ────────────────────────────────────────────────────────
    function Window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or ("Tab " .. (#self._tabs+1))
        local tabIcon = tabConfig.Icon or ""

        -- tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1,0,0,32)
        tabBtn.BackgroundColor3 = COLOR.bg_element
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.LayoutOrder = #self._tabs + 1
        tabBtn.Parent = tabBar
        round(tabBtn, 3)

        local tabBtnStroke = stroke(tabBtn, COLOR.border, 0)
        local indicator = newFrame(tabBtn, UDim2.new(0,3,0.6,0),
            UDim2.new(0,0,0.2,0), COLOR.accent, "Ind")
        indicator.Visible = false
        round(indicator, 2)

        local tabBtnLabel = label(tabBtn,
            (tabIcon ~= "" and tabIcon.." " or "") .. tabName,
            12, COLOR.text_sec, Enum.Font.GothamMedium,
            UDim2.new(0,10,0,0))
        tabBtnLabel.Size = UDim2.new(1,-10,1,0)

        -- content page
        local page = newFrame(contentArea,
            UDim2.new(1,0,1,0),
            UDim2.new(0,0,0,0),
            COLOR.bg_deep, tabName.."_Page")
        page.Visible = false
        page.ClipsDescendants = true

        local pageScroll = Instance.new("ScrollingFrame")
        pageScroll.Size = UDim2.new(1,0,1,0)
        pageScroll.Position = UDim2.new(0,0,0,0)
        pageScroll.BackgroundTransparency = 1
        pageScroll.ScrollBarThickness = 3
        pageScroll.ScrollBarImageColor3 = COLOR.accent_dim
        pageScroll.CanvasSize = UDim2.new(0,0,0,0)
        pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        pageScroll.BorderSizePixel = 0
        pageScroll.Parent = page

        local sectionLayout = Instance.new("UIListLayout")
        sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sectionLayout.Padding = UDim.new(0,8)
        sectionLayout.Parent = pageScroll
        local sPad = Instance.new("UIPadding")
        sPad.PaddingTop = UDim.new(0,10)
        sPad.PaddingLeft = UDim.new(0,10)
        sPad.PaddingRight = UDim.new(0,10)
        sPad.PaddingBottom = UDim.new(0,10)
        sPad.Parent = pageScroll

        -- activate tab function
        local function activate()
            for _, t in ipairs(Window._tabs) do
                t.page.Visible = false
                tween(t.btn, {BackgroundColor3 = COLOR.bg_deep}, 0.1)
                tween(t.lbl, {TextColor3 = COLOR.text_dim}, 0.1)
                t.ind.Visible = false
                t.btnStroke.Thickness = 0
            end
            page.Visible = true
            tween(tabBtn, {BackgroundColor3 = COLOR.bg_active}, 0.1)
            tween(tabBtnLabel, {TextColor3 = COLOR.text_prim}, 0.1)
            indicator.Visible = true
            tabBtnStroke.Thickness = 1
            Window._active = #Window._tabs
        end

        tabBtn.MouseButton1Click:Connect(activate)
        tabBtn.MouseEnter:Connect(function()
            if Window._active ~= #Window._tabs then
                tween(tabBtn, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active ~= #Window._tabs then
                tween(tabBtn, {BackgroundColor3 = COLOR.bg_deep}, 0.08)
            end
        end)

        -- Tab object
        local Tab = {}
        Tab._page = page
        Tab._scroll = pageScroll
        Tab._order = 0

        table.insert(Window._tabs, {
            page = page, btn = tabBtn, lbl = tabBtnLabel,
            ind = indicator, btnStroke = tabBtnStroke
        })

        -- activate first tab automatically
        if #Window._tabs == 1 then activate() end

        -- ── SECTION ───────────────────────────────────────────────────────
        function Tab:Section(sName)
            Tab._order = Tab._order + 1
            local sec = newFrame(pageScroll,
                UDim2.new(1,0,0,0),
                nil, COLOR.bg_panel, sName.."_Section")
            sec.AutomaticSize = Enum.AutomaticSize.Y
            sec.LayoutOrder = Tab._order
            round(sec, 4)
            stroke(sec, COLOR.border, 1)

            -- section header
            local hdr = newFrame(sec, UDim2.new(1,0,0,28), nil, COLOR.bg_active, "Header")
            hdr.ZIndex = 2
            round(hdr, 4)
            local hdrMask = newFrame(hdr, UDim2.new(1,0,0,8), UDim2.new(0,0,1,-8), COLOR.bg_active, "M")
            hdrMask.ZIndex = 3

            local accentDot = newFrame(hdr, UDim2.new(0,4,0,4),
                UDim2.new(0,8,0.5,0), COLOR.accent, "Dot")
            accentDot.AnchorPoint = Vector2.new(0,0.5)
            round(accentDot, 2)
            accentDot.ZIndex = 4

            local hdrLabel = label(hdr, sName:upper(), 11, COLOR.text_sec,
                Enum.Font.GothamBold, UDim2.new(0,20,0,0))
            hdrLabel.Size = UDim2.new(1,-20,1,0)
            hdrLabel.ZIndex = 4

            -- items container
            local items = newFrame(sec, UDim2.new(1,0,0,0), UDim2.new(0,0,0,28),
                COLOR.bg_panel, "Items")
            items.AutomaticSize = Enum.AutomaticSize.Y
            local iLayout = Instance.new("UIListLayout")
            iLayout.SortOrder = Enum.SortOrder.LayoutOrder
            iLayout.Padding = UDim.new(0,1)
            iLayout.Parent = items
            local iPad = Instance.new("UIPadding")
            iPad.PaddingBottom = UDim.new(0,6)
            iPad.Parent = items

            local Section = {}
            Section._items = items
            Section._order = 0

            -- ── ITEM BASE ──────────────────────────────────────────────
            local function makeItemRow(h)
                Section._order = Section._order + 1
                local row = newFrame(items, UDim2.new(1,0,0,h or 36),
                    nil, COLOR.bg_element, "Row")
                row.LayoutOrder = Section._order
                local rPad = Instance.new("UIPadding")
                rPad.PaddingLeft = UDim.new(0,10)
                rPad.PaddingRight = UDim.new(0,10)
                rPad.Parent = row
                return row
            end

            -- ── TOGGLE ────────────────────────────────────────────────
            function Section:Toggle(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Toggle"
                local default = cfg.Default or false
                local desc    = cfg.Description
                local onChg   = cfg.Callback or function() end
                local hasGear = cfg.Settings ~= nil
                local state   = default

                local rowH = desc and 48 or 36
                local row = makeItemRow(rowH)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0,desc and 8 or 0)).Size = UDim2.new(0.6,0,0,18)

                if desc then
                    local d = label(row, desc, 11, COLOR.text_dim, Enum.Font.Gotham,
                        UDim2.new(0,0,0,26))
                    d.Size = UDim2.new(0.7,0,0,14)
                end

                -- toggle track
                local trackW, trackH = 38, 20
                local track = newFrame(row, UDim2.new(0,trackW,0,trackH),
                    UDim2.new(1, hasGear and -48 or -trackW-2, 0.5,0),
                    state and COLOR.toggle_on or COLOR.toggle_off, "Track")
                track.AnchorPoint = Vector2.new(0,0.5)
                round(track, 10)
                stroke(track, COLOR.border, 1)

                local knob = newFrame(track, UDim2.new(0,14,0,14),
                    UDim2.new(0, state and trackW-16 or 2, 0.5,0),
                    COLOR.white, "Knob")
                knob.AnchorPoint = Vector2.new(0,0.5)
                round(knob, 7)

                -- gear / settings button
                if hasGear then
                    local gearBtn = Instance.new("TextButton")
                    gearBtn.Size = UDim2.new(0,24,0,24)
                    gearBtn.Position = UDim2.new(1,-24,0.5,0)
                    gearBtn.AnchorPoint = Vector2.new(0,0.5)
                    gearBtn.BackgroundColor3 = COLOR.bg_active
                    gearBtn.Text = "⚙"
                    gearBtn.TextColor3 = COLOR.text_sec
                    gearBtn.TextSize = 13
                    gearBtn.Font = Enum.Font.Gotham
                    gearBtn.Parent = row
                    round(gearBtn, 3)

                    gearBtn.MouseEnter:Connect(function()
                        tween(gearBtn, {TextColor3 = COLOR.accent_text}, 0.1)
                    end)
                    gearBtn.MouseLeave:Connect(function()
                        tween(gearBtn, {TextColor3 = COLOR.text_sec}, 0.1)
                    end)

                    -- settings panel (dropdown under row)
                    local settingsPanel = newFrame(items,
                        UDim2.new(1,0,0,0), nil, COLOR.bg_deep, "SettingsPanel")
                    settingsPanel.AutomaticSize = Enum.AutomaticSize.Y
                    settingsPanel.Visible = false
                    settingsPanel.LayoutOrder = Section._order
                    round(settingsPanel, 3)
                    stroke(settingsPanel, COLOR.accent_dim, 1)

                    local sPanelPad = Instance.new("UIPadding")
                    sPanelPad.PaddingAll = UDim.new(0,8)
                    sPanelPad.Parent = settingsPanel
                    local sPanelLayout = Instance.new("UIListLayout")
                    sPanelLayout.Padding = UDim.new(0,6)
                    sPanelLayout.Parent = settingsPanel

                    -- build settings items via callback
                    local settingsTab = {_items = settingsPanel, _order = 0}
                    -- expose mini-section for caller to populate
                    cfg.Settings(settingsTab, Section)

                    gearBtn.MouseButton1Click:Connect(function()
                        settingsPanel.Visible = not settingsPanel.Visible
                        tween(gearBtn, {
                            BackgroundColor3 = settingsPanel.Visible
                                and COLOR.accent_dim or COLOR.bg_active
                        }, 0.1)
                    end)
                end

                -- click region
                local clickBtn = Instance.new("TextButton")
                clickBtn.Size = UDim2.new(1, hasGear and -34 or 0, 1, 0)
                clickBtn.BackgroundTransparency = 1
                clickBtn.Text = ""
                clickBtn.Parent = row

                local function setToggle(v)
                    state = v
                    tween(track, {BackgroundColor3 = state and COLOR.toggle_on or COLOR.toggle_off}, 0.15)
                    tween(knob, {Position = UDim2.new(0, state and trackW-16 or 2, 0.5, 0)}, 0.15)
                    onChg(state)
                end

                clickBtn.MouseButton1Click:Connect(function() setToggle(not state) end)
                row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = COLOR.bg_hover}, 0.08) end)
                row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = COLOR.bg_element}, 0.08) end)

                local obj = {}
                function obj:Set(v) setToggle(v) end
                function obj:Get() return state end
                return obj
            end

            -- ── SLIDER ────────────────────────────────────────────────
            function Section:Slider(cfg)
                cfg = cfg or {}
                local name   = cfg.Name    or "Slider"
                local min    = cfg.Min     or 0
                local max    = cfg.Max     or 100
                local step   = cfg.Step    or 1
                local default= cfg.Default or min
                local suffix = cfg.Suffix  or ""
                local onChg  = cfg.Callback or function() end
                local val    = default

                local row = makeItemRow(46)
                row.AutomaticSize = Enum.AutomaticSize.None

                local nameLbl = label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0,6))
                nameLbl.Size = UDim2.new(0.7,0,0,16)

                local valLbl = label(row, tostring(val)..suffix, 12, COLOR.accent_text,
                    Enum.Font.GothamBold, UDim2.new(1,0,0,6), Vector2.new(1,0))
                valLbl.Size = UDim2.new(0.3,0,0,16)
                valLbl.TextXAlignment = Enum.TextXAlignment.Right

                -- track
                local sliderTrack = newFrame(row, UDim2.new(1,0,0,4),
                    UDim2.new(0,0,1,-10), COLOR.bg_active, "SliderTrack")
                sliderTrack.AnchorPoint = Vector2.new(0,1)
                round(sliderTrack, 2)

                local sliderFill = newFrame(sliderTrack,
                    UDim2.new((val-min)/(max-min),0,1,0),
                    nil, COLOR.accent, "Fill")
                round(sliderFill, 2)

                local sliderKnob = newFrame(sliderTrack, UDim2.new(0,10,0,10),
                    UDim2.new((val-min)/(max-min),0,0.5,0),
                    COLOR.white, "Knob")
                sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                round(sliderKnob, 5)
                stroke(sliderKnob, COLOR.accent, 1)

                local dragging = false
                sliderTrack.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = sliderTrack.AbsolutePosition
                        local sz  = sliderTrack.AbsoluteSize
                        local rel = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                        local raw = min + (max-min)*rel
                        val = math.round(raw / step) * step
                        val = math.clamp(val, min, max)
                        local pct = (val-min)/(max-min)
                        tween(sliderFill, {Size = UDim2.new(pct,0,1,0)}, 0.05)
                        tween(sliderKnob, {Position = UDim2.new(pct,0,0.5,0)}, 0.05)
                        valLbl.Text = tostring(val)..suffix
                        onChg(val)
                    end
                end)

                local obj = {}
                function obj:Set(v)
                    v = math.clamp(v, min, max)
                    val = v
                    local pct = (v-min)/(max-min)
                    tween(sliderFill, {Size = UDim2.new(pct,0,1,0)}, 0.1)
                    tween(sliderKnob, {Position = UDim2.new(pct,0,0.5,0)}, 0.1)
                    valLbl.Text = tostring(v)..suffix
                    onChg(v)
                end
                function obj:Get() return val end
                return obj
            end

            -- ── DROPDOWN (single select) ───────────────────────────────
            function Section:Dropdown(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Dropdown"
                local options = cfg.Options or {}
                local default = cfg.Default or (options[1] or "")
                local onChg   = cfg.Callback or function() end
                local selected= default
                local open    = false

                local row = makeItemRow(36)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5)).Size = UDim2.new(0.4,0,0,20)

                local dropBtn = Instance.new("TextButton")
                dropBtn.Size = UDim2.new(0.55,0,0,24)
                dropBtn.Position = UDim2.new(0.4,0,0.5,0)
                dropBtn.AnchorPoint = Vector2.new(0,0.5)
                dropBtn.BackgroundColor3 = COLOR.bg_active
                dropBtn.Text = ""
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = row
                round(dropBtn, 3)
                stroke(dropBtn, COLOR.border, 1)

                local selLabel = label(dropBtn, selected, 12, COLOR.text_prim,
                    Enum.Font.Gotham, UDim2.new(0,8,0,0))
                selLabel.Size = UDim2.new(1,-24,1,0)

                local arrow = label(dropBtn, "▾", 12, COLOR.text_sec,
                    Enum.Font.GothamBold, UDim2.new(1,-16,0.5,0), Vector2.new(0.5,0.5))

                -- dropdown list (created in content area to overflow)
                local listHolder = newFrame(items, UDim2.new(1,0,0,0),
                    nil, COLOR.bg_active, "DDList")
                listHolder.AutomaticSize = Enum.AutomaticSize.Y
                listHolder.Visible = false
                listHolder.LayoutOrder = Section._order
                round(listHolder, 3)
                stroke(listHolder, COLOR.accent_dim, 1)
                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent = listHolder

                local function buildList()
                    for _, child in ipairs(listHolder:GetChildren()) do
                        if child:IsA("Frame") or child:IsA("TextButton") then
                            child:Destroy()
                        end
                    end
                    for i, opt in ipairs(options) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1,0,0,30)
                        optBtn.BackgroundColor3 = opt == selected and COLOR.bg_hover or COLOR.bg_active
                        optBtn.Text = ""
                        optBtn.LayoutOrder = i
                        optBtn.AutoButtonColor = false
                        optBtn.Parent = listHolder
                        local optLbl = label(optBtn, opt, 12,
                            opt == selected and COLOR.accent_text or COLOR.text_prim,
                            Enum.Font.Gotham, UDim2.new(0,10,0,0))
                        optLbl.Size = UDim2.new(1,-10,1,0)
                        if opt == selected then
                            local checkLbl = label(optBtn, "✓", 11, COLOR.accent_text,
                                Enum.Font.GothamBold, UDim2.new(1,-8,0.5,0), Vector2.new(1,0.5))
                        end
                        optBtn.MouseEnter:Connect(function()
                            tween(optBtn, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            tween(optBtn, {BackgroundColor3 =
                                opt == selected and COLOR.bg_hover or COLOR.bg_active}, 0.08)
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            selLabel.Text = opt
                            open = false
                            listHolder.Visible = false
                            tween(arrow, {Rotation = 0}, 0.1)
                            buildList()
                            onChg(selected)
                        end)
                    end
                end
                buildList()

                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listHolder.Visible = open
                    tween(arrow, {Rotation = open and 180 or 0}, 0.15)
                end)
                dropBtn.MouseEnter:Connect(function()
                    tween(dropBtn, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
                end)
                dropBtn.MouseLeave:Connect(function()
                    tween(dropBtn, {BackgroundColor3 = COLOR.bg_active}, 0.08)
                end)

                local obj = {}
                function obj:Set(v)
                    selected = v
                    selLabel.Text = v
                    buildList()
                    onChg(v)
                end
                function obj:Get() return selected end
                function obj:SetOptions(opts)
                    options = opts
                    buildList()
                end
                return obj
            end

            -- ── MULTI-DROPDOWN ────────────────────────────────────────
            function Section:MultiDropdown(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Multi Select"
                local options = cfg.Options or {}
                local default = cfg.Default or {}
                local onChg   = cfg.Callback or function() end
                local open    = false
                local selected= {}
                for _, v in ipairs(default) do selected[v] = true end

                local row = makeItemRow(36)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5)).Size = UDim2.new(0.4,0,0,20)

                local dropBtn = Instance.new("TextButton")
                dropBtn.Size = UDim2.new(0.55,0,0,24)
                dropBtn.Position = UDim2.new(0.4,0,0.5,0)
                dropBtn.AnchorPoint = Vector2.new(0,0.5)
                dropBtn.BackgroundColor3 = COLOR.bg_active
                dropBtn.Text = ""
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = row
                round(dropBtn, 3)
                stroke(dropBtn, COLOR.border, 1)

                local function selText()
                    local t = {}
                    for k,v in pairs(selected) do if v then table.insert(t,k) end end
                    if #t == 0 then return "None" end
                    if #t == 1 then return t[1] end
                    return t[1].." +"..tostring(#t-1)
                end

                local selLabel = label(dropBtn, selText(), 12, COLOR.text_prim,
                    Enum.Font.Gotham, UDim2.new(0,8,0,0))
                selLabel.Size = UDim2.new(1,-24,1,0)

                local arrow = label(dropBtn, "▾", 12, COLOR.text_sec,
                    Enum.Font.GothamBold, UDim2.new(1,-16,0.5,0), Vector2.new(0.5,0.5))

                local listHolder = newFrame(items, UDim2.new(1,0,0,0),
                    nil, COLOR.bg_active, "MDD_List")
                listHolder.AutomaticSize = Enum.AutomaticSize.Y
                listHolder.Visible = false
                listHolder.LayoutOrder = Section._order
                round(listHolder, 3)
                stroke(listHolder, COLOR.accent_dim, 1)
                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Parent = listHolder

                local function buildList()
                    for _, c in ipairs(listHolder:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for i, opt in ipairs(options) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1,0,0,30)
                        optBtn.BackgroundColor3 = selected[opt] and COLOR.bg_hover or COLOR.bg_active
                        optBtn.Text = ""
                        optBtn.LayoutOrder = i
                        optBtn.AutoButtonColor = false
                        optBtn.Parent = listHolder

                        -- checkbox visual
                        local chkBox = newFrame(optBtn, UDim2.new(0,14,0,14),
                            UDim2.new(0,8,0.5,0), selected[opt] and COLOR.accent or COLOR.bg_deep, "Chk")
                        chkBox.AnchorPoint = Vector2.new(0,0.5)
                        round(chkBox, 2)
                        stroke(chkBox, COLOR.border, 1)

                        if selected[opt] then
                            local checkMark = label(chkBox, "✓", 10, COLOR.bg_deep,
                                Enum.Font.GothamBold, UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5))
                            checkMark.Size = UDim2.new(1,0,1,0)
                            checkMark.TextXAlignment = Enum.TextXAlignment.Center
                        end

                        local optLbl = label(optBtn, opt, 12,
                            selected[opt] and COLOR.text_prim or COLOR.text_sec,
                            Enum.Font.Gotham, UDim2.new(0,30,0,0))
                        optLbl.Size = UDim2.new(1,-30,1,0)

                        optBtn.MouseEnter:Connect(function()
                            tween(optBtn, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            tween(optBtn, {BackgroundColor3 =
                                selected[opt] and COLOR.bg_hover or COLOR.bg_active}, 0.08)
                        end)
                        optBtn.MouseButton1Click:Connect(function()
                            selected[opt] = not selected[opt]
                            selLabel.Text = selText()
                            buildList()
                            local t = {}
                            for k,v in pairs(selected) do if v then table.insert(t,k) end end
                            onChg(t)
                        end)
                    end
                end
                buildList()

                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listHolder.Visible = open
                    tween(arrow, {Rotation = open and 180 or 0}, 0.15)
                end)
                dropBtn.MouseEnter:Connect(function()
                    tween(dropBtn, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
                end)
                dropBtn.MouseLeave:Connect(function()
                    tween(dropBtn, {BackgroundColor3 = COLOR.bg_active}, 0.08)
                end)

                local obj = {}
                function obj:Get()
                    local t = {}
                    for k,v in pairs(selected) do if v then table.insert(t,k) end end
                    return t
                end
                function obj:Set(list)
                    selected = {}
                    for _, v in ipairs(list) do selected[v] = true end
                    selLabel.Text = selText()
                    buildList()
                end
                function obj:SetOptions(opts)
                    options = opts
                    buildList()
                end
                return obj
            end

            -- ── COLOR PICKER ──────────────────────────────────────────
            function Section:ColorPicker(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Color"
                local default = cfg.Default or Color3.fromRGB(255,255,255)
                local onChg   = cfg.Callback or function() end
                local open    = false
                local currentH, currentS, currentV = Color3.toHSV(default)

                local row = makeItemRow(36)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5)).Size = UDim2.new(0.6,0,0,20)

                -- color preview swatch
                local swatchBtn = Instance.new("TextButton")
                swatchBtn.Size = UDim2.new(0,52,0,22)
                swatchBtn.Position = UDim2.new(1,0,0.5,0)
                swatchBtn.AnchorPoint = Vector2.new(1,0.5)
                swatchBtn.BackgroundColor3 = default
                swatchBtn.Text = ""
                swatchBtn.AutoButtonColor = false
                swatchBtn.Parent = row
                round(swatchBtn, 3)
                stroke(swatchBtn, COLOR.border, 1)

                -- hex label on swatch
                local hexLbl = label(swatchBtn, "", 9, COLOR.white,
                    Enum.Font.RobotoMono, UDim2.new(0.5,0,0.5,0), Vector2.new(0.5,0.5))
                hexLbl.Size = UDim2.new(1,0,1,0)
                hexLbl.TextXAlignment = Enum.TextXAlignment.Center
                hexLbl.TextStrokeTransparency = 0.4
                hexLbl.TextStrokeColor3 = COLOR.black

                local function colorToHex(c)
                    return string.format("#%02X%02X%02X",
                        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                end
                hexLbl.Text = colorToHex(default)

                -- picker panel
                local pickerPanel = newFrame(items, UDim2.new(1,0,0,0),
                    nil, COLOR.bg_active, "ColorPanel")
                pickerPanel.AutomaticSize = Enum.AutomaticSize.Y
                pickerPanel.Visible = false
                pickerPanel.LayoutOrder = Section._order
                round(pickerPanel, 3)
                stroke(pickerPanel, COLOR.accent_dim, 1)

                local ppPad = Instance.new("UIPadding")
                ppPad.PaddingAll = UDim.new(0,10)
                ppPad.Parent = pickerPanel

                local ppLayout = Instance.new("UIListLayout")
                ppLayout.Padding = UDim.new(0,8)
                ppLayout.Parent = pickerPanel

                -- SV square (saturation/value)
                local svSquare = newFrame(pickerPanel, UDim2.new(1,0,0,120),
                    nil, Color3.fromHSV(currentH,1,1), "SVSquare")
                svSquare.AutomaticSize = Enum.AutomaticSize.None
                round(svSquare, 3)

                -- white gradient (left-right saturation)
                local wGrad = newFrame(svSquare, UDim2.new(1,0,1,0), nil, COLOR.white, "WGrad")
                local wGradObj = Instance.new("UIGradient")
                wGradObj.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                    ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
                }
                wGradObj.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }
                wGradObj.Parent = wGrad

                -- black gradient (top-bottom value)
                local bGrad = newFrame(svSquare, UDim2.new(1,0,1,0), nil, COLOR.black, "BGrad")
                local bGradObj = Instance.new("UIGradient")
                bGradObj.Color = ColorSequence.new(Color3.new(0,0,0))
                bGradObj.Rotation = 90
                bGradObj.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                }
                bGradObj.Parent = bGrad

                -- SV cursor
                local svCursor = newFrame(svSquare, UDim2.new(0,10,0,10),
                    UDim2.new(currentS, 0, 1-currentV, 0),
                    Color3.fromHSV(currentH,currentS,currentV), "SVCursor")
                svCursor.AnchorPoint = Vector2.new(0.5,0.5)
                svCursor.ZIndex = 5
                round(svCursor, 5)
                stroke(svCursor, COLOR.white, 2)

                -- HUE slider
                local hueSlider = newFrame(pickerPanel, UDim2.new(1,0,0,14),
                    nil, COLOR.white, "HueSlider")
                hueSlider.AutomaticSize = Enum.AutomaticSize.None
                round(hueSlider, 7)

                local hueGrad = Instance.new("UIGradient")
                hueGrad.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,   1,1)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,1,1)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,1,1)),
                    ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1,1)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,1,1)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,1,1)),
                    ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1,1)),
                }
                hueGrad.Parent = hueSlider

                local hueCursor = newFrame(hueSlider, UDim2.new(0,12,0,12),
                    UDim2.new(currentH,0,0.5,0),
                    Color3.fromHSV(currentH,1,1), "HueCursor")
                hueCursor.AnchorPoint = Vector2.new(0.5,0.5)
                hueCursor.ZIndex = 5
                round(hueCursor, 6)
                stroke(hueCursor, COLOR.white, 2)

                -- hex input row
                local hexRow = newFrame(pickerPanel, UDim2.new(1,0,0,26), nil,
                    COLOR.bg_deep, "HexRow")
                hexRow.AutomaticSize = Enum.AutomaticSize.None
                round(hexRow, 3)

                local hexHashLabel = label(hexRow, "#", 12, COLOR.text_sec,
                    Enum.Font.RobotoMono, UDim2.new(0,6,0,0))
                hexHashLabel.Size = UDim2.new(0,14,1,0)

                local hexInput = Instance.new("TextBox")
                hexInput.Size = UDim2.new(1,-20,1,0)
                hexInput.Position = UDim2.new(0,20,0,0)
                hexInput.BackgroundTransparency = 1
                hexInput.Text = colorToHex(default):sub(2)
                hexInput.TextColor3 = COLOR.text_prim
                hexInput.Font = Enum.Font.RobotoMono
                hexInput.TextSize = 12
                hexInput.PlaceholderText = "RRGGBB"
                hexInput.PlaceholderColor3 = COLOR.text_dim
                hexInput.Parent = hexRow

                local function applyColor()
                    local c = Color3.fromHSV(currentH, currentS, currentV)
                    swatchBtn.BackgroundColor3 = c
                    hexLbl.Text = colorToHex(c)
                    hexInput.Text = colorToHex(c):sub(2)
                    svSquare.BackgroundColor3 = Color3.fromHSV(currentH,1,1)
                    tween(svCursor, {
                        Position = UDim2.new(currentS,0,1-currentV,0),
                        BackgroundColor3 = c
                    }, 0.05)
                    tween(hueCursor, {
                        Position = UDim2.new(currentH,0,0.5,0),
                        BackgroundColor3 = Color3.fromHSV(currentH,1,1)
                    }, 0.05)
                    onChg(c)
                end

                -- SV dragging
                local svDrag = false
                svSquare.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDrag = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDrag = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = svSquare.AbsolutePosition
                        local sz  = svSquare.AbsoluteSize
                        currentS = math.clamp((inp.Position.X - abs.X)/sz.X, 0, 1)
                        currentV = 1 - math.clamp((inp.Position.Y - abs.Y)/sz.Y, 0, 1)
                        applyColor()
                    end
                end)

                -- Hue dragging
                local hueDrag = false
                hueSlider.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDrag = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDrag = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs = hueSlider.AbsolutePosition
                        local sz  = hueSlider.AbsoluteSize
                        currentH = math.clamp((inp.Position.X - abs.X)/sz.X, 0, 1)
                        applyColor()
                    end
                end)

                -- hex input
                hexInput.FocusLost:Connect(function()
                    local hex = hexInput.Text:gsub("#","")
                    if #hex == 6 then
                        local r = tonumber(hex:sub(1,2),16)
                        local g = tonumber(hex:sub(3,4),16)
                        local b = tonumber(hex:sub(5,6),16)
                        if r and g and b then
                            local c = Color3.fromRGB(r,g,b)
                            currentH, currentS, currentV = Color3.toHSV(c)
                            applyColor()
                        end
                    end
                end)

                swatchBtn.MouseButton1Click:Connect(function()
                    open = not open
                    pickerPanel.Visible = open
                end)

                local obj = {}
                function obj:Get()
                    return Color3.fromHSV(currentH, currentS, currentV)
                end
                function obj:Set(c)
                    currentH, currentS, currentV = Color3.toHSV(c)
                    applyColor()
                end
                return obj
            end

            -- ── BUTTON ────────────────────────────────────────────────
            function Section:Button(cfg)
                cfg = cfg or {}
                local name   = cfg.Name   or "Button"
                local desc   = cfg.Description
                local onClk  = cfg.Callback or function() end

                local row = makeItemRow(desc and 46 or 36)

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,1,0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = row

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0, desc and 0 or 0.5, desc and 8 or 0),
                    Vector2.new(0, desc and 0 or 0.5)).Size = UDim2.new(0.7,0,0,18)

                if desc then
                    label(row, desc, 11, COLOR.text_dim, Enum.Font.Gotham,
                        UDim2.new(0,0,0,26)).Size = UDim2.new(0.7,0,0,14)
                end

                -- execute label (right side)
                local exeLabel = label(row, "▶  Execute", 11, COLOR.accent_text,
                    Enum.Font.GothamBold, UDim2.new(1,0,0.5,0), Vector2.new(1,0.5))
                exeLabel.Size = UDim2.new(0,80,0,20)
                exeLabel.TextXAlignment = Enum.TextXAlignment.Right

                row.MouseEnter:Connect(function()
                    tween(row, {BackgroundColor3 = COLOR.bg_hover}, 0.08)
                    tween(exeLabel, {TextColor3 = COLOR.white}, 0.08)
                end)
                row.MouseLeave:Connect(function()
                    tween(row, {BackgroundColor3 = COLOR.bg_element}, 0.08)
                    tween(exeLabel, {TextColor3 = COLOR.accent_text}, 0.08)
                end)
                btn.MouseButton1Click:Connect(function()
                    tween(row, {BackgroundColor3 = COLOR.bg_active}, 0.06)
                    task.delay(0.1, function()
                        tween(row, {BackgroundColor3 = COLOR.bg_element}, 0.08)
                    end)
                    onClk()
                end)
            end

            -- ── TEXTBOX ───────────────────────────────────────────────
            function Section:TextBox(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Input"
                local default = cfg.Default or ""
                local placeholder = cfg.Placeholder or "..."
                local onChg   = cfg.Callback or function() end
                local onEnter = cfg.OnEnter  or function() end

                local row = makeItemRow(36)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5)).Size = UDim2.new(0.35,0,0,20)

                local inputFrame = newFrame(row,
                    UDim2.new(0.6,0,0,24),
                    UDim2.new(0.38,0,0.5,0),
                    COLOR.bg_deep, "InputFrame")
                inputFrame.AnchorPoint = Vector2.new(0,0.5)
                round(inputFrame, 3)
                stroke(inputFrame, COLOR.border, 1)

                local inputBox = Instance.new("TextBox")
                inputBox.Size = UDim2.new(1,-12,1,0)
                inputBox.Position = UDim2.new(0,6,0,0)
                inputBox.BackgroundTransparency = 1
                inputBox.Text = default
                inputBox.PlaceholderText = placeholder
                inputBox.TextColor3 = COLOR.text_prim
                inputBox.PlaceholderColor3 = COLOR.text_dim
                inputBox.Font = Enum.Font.Gotham
                inputBox.TextSize = 12
                inputBox.TextXAlignment = Enum.TextXAlignment.Left
                inputBox.ClearTextOnFocus = false
                inputBox.Parent = inputFrame

                inputBox.Focused:Connect(function()
                    tween(inputFrame, {}, 0.1)
                    stroke(inputFrame, COLOR.accent, 1)
                end)
                inputBox.FocusLost:Connect(function(enterPressed)
                    stroke(inputFrame, COLOR.border, 1)
                    onChg(inputBox.Text)
                    if enterPressed then onEnter(inputBox.Text) end
                end)

                local obj = {}
                function obj:Get() return inputBox.Text end
                function obj:Set(v) inputBox.Text = v end
                return obj
            end

            -- ── KEYBIND ───────────────────────────────────────────────
            function Section:Keybind(cfg)
                cfg = cfg or {}
                local name    = cfg.Name    or "Keybind"
                local default = cfg.Default or Enum.KeyCode.Unknown
                local onChg   = cfg.Callback or function() end
                local bound   = default
                local listening= false

                local row = makeItemRow(36)

                label(row, name, 13, COLOR.text_prim, Enum.Font.GothamMedium,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5)).Size = UDim2.new(0.6,0,0,20)

                local kbBtn = Instance.new("TextButton")
                kbBtn.Size = UDim2.new(0,80,0,22)
                kbBtn.Position = UDim2.new(1,0,0.5,0)
                kbBtn.AnchorPoint = Vector2.new(1,0.5)
                kbBtn.BackgroundColor3 = COLOR.bg_deep
                kbBtn.Text = bound.Name
                kbBtn.TextColor3 = COLOR.text_prim
                kbBtn.TextSize = 11
                kbBtn.Font = Enum.Font.GothamBold
                kbBtn.AutoButtonColor = false
                kbBtn.Parent = row
                round(kbBtn, 3)
                stroke(kbBtn, COLOR.border, 1)

                kbBtn.MouseButton1Click:Connect(function()
                    listening = true
                    kbBtn.Text = "..."
                    kbBtn.TextColor3 = COLOR.accent_text
                    tween(kbBtn, {BackgroundColor3 = COLOR.bg_active}, 0.1)
                end)

                UserInputService.InputBegan:Connect(function(inp, gp)
                    if listening and not gp and inp.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        bound = inp.KeyCode
                        kbBtn.Text = bound.Name
                        kbBtn.TextColor3 = COLOR.text_prim
                        tween(kbBtn, {BackgroundColor3 = COLOR.bg_deep}, 0.1)
                        onChg(bound)
                    end
                end)

                local obj = {}
                function obj:Get() return bound end
                function obj:Set(k) bound = k; kbBtn.Text = k.Name end
                return obj
            end

            -- ── LABEL (static text) ───────────────────────────────────
            function Section:Label(cfg)
                cfg = cfg or {}
                local text  = cfg.Text  or ""
                local color = cfg.Color or COLOR.text_dim
                local row = makeItemRow(28)
                row.BackgroundTransparency = 1
                local lbl = label(row, text, 12, color, Enum.Font.Gotham,
                    UDim2.new(0,0,0.5,0), Vector2.new(0,0.5))
                lbl.Size = UDim2.new(1,0,0,20)
                local obj = {}
                function obj:Set(t) lbl.Text = t end
                return obj
            end

            -- ── SEPARATOR ─────────────────────────────────────────────
            function Section:Separator()
                Section._order = Section._order + 1
                local sep = newFrame(items, UDim2.new(1,0,0,1), nil, COLOR.border, "Sep")
                sep.LayoutOrder = Section._order
            end

            return Section
        end

        return Tab
    end

    return Window
end

return VANTALib
