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
    buildSec:Label({ Text = "VANTA  " .. VERSION .. "   LINORIA STYLE" })
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