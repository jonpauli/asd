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
            local listLayout = Instance.new("UIListListLayout")
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

            local function hexFocusGained()
                hexFocused = true
            end
            local function hexFocusLost()
                hexFocused = false
                local parsed = fromHex(hexBox.Text)
                if parsed then
                    h, s, v = Color3.toHSV(parsed)
                end
                render(true)
            end

            hexBox.Focused:Connect(hexFocusGained)
            hexBox.FocusLost:Connect(hexFocusLost)

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