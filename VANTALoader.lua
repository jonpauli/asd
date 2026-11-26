--[[
    VANTALoader — fetches VANTALib from GitHub and runs your script
    ─────────────────────────────────────────────────────────────────
    HOW TO USE:
      1. Upload VANTALib.lua to your GitHub repo (raw URL below)
      2. Upload this file (or paste inline in your executor)
      3. Put all your UI logic in the "-- YOUR SCRIPT BELOW" section

    Raw URL format:
      https://raw.githubusercontent.com/<USER>/<REPO>/<BRANCH>/VANTALib.lua

    Replace USER / REPO / BRANCH below.
]]

local LIB_URL = "https://raw.githubusercontent.com/jonpauli/asd/refs/heads/main/VANTALib.lua"

-- ── fetch & load library ────────────────────────────────────────────────────
local ok, result = pcall(function()
    return loadstring(game:HttpGet(LIB_URL, true))()
end)

if not ok then
    warn("[VANTALoader] Failed to load VANTALib: " .. tostring(result))
    return
end

local VANTA = result
-- ────────────────────────────────────────────────────────────────────────────

-- ── YOUR SCRIPT BELOW ───────────────────────────────────────────────────────
-- Everything below is example usage. Replace with your own logic.

local Win = VANTA:CreateWindow({
    Title      = "VANTA",          -- window title bar text
    Width      = 580,
    Height     = 440,
    ToggleKey  = Enum.KeyCode.RightShift,  -- key to show/hide
})

-- ── TAB 1: COMBAT ───────────────────────────────────────────────────────────
local CombatTab = Win:Tab({ Name = "Combat", Icon = "⚔" })

local AimSection = CombatTab:Section("Aimbot")

local aimbotToggle = AimSection:Toggle({
    Name        = "Aimbot",
    Default     = false,
    Description = "Snap aim to nearest target",
    Callback    = function(state)
        print("Aimbot:", state)
    end,
    -- gear button expands an inline settings block
    Settings = function(settingsTab, parentSection)
        parentSection:Slider({
            Name     = "FOV",
            Min      = 10,
            Max      = 360,
            Default  = 90,
            Suffix   = "°",
            Callback = function(v) print("FOV:", v) end,
        })
        parentSection:Dropdown({
            Name     = "Bone Target",
            Options  = { "Head", "Neck", "Chest", "Pelvis" },
            Default  = "Head",
            Callback = function(v) print("Bone:", v) end,
        })
        parentSection:Slider({
            Name     = "Smoothing",
            Min      = 1,
            Max      = 100,
            Default  = 20,
            Suffix   = "%",
            Callback = function(v) print("Smooth:", v) end,
        })
    end,
})

AimSection:Keybind({
    Name     = "Aimbot Key",
    Default  = Enum.KeyCode.C,
    Callback = function(key) print("Aimbot key set to:", key.Name) end,
})

AimSection:Slider({
    Name     = "Prediction",
    Min      = 0,
    Max      = 1,
    Step     = 0.01,
    Default  = 0.15,
    Suffix   = "s",
    Callback = function(v) print("Prediction:", v) end,
})

local TriggerSection = CombatTab:Section("Triggerbot")

TriggerSection:Toggle({
    Name     = "Triggerbot",
    Default  = false,
    Callback = function(state) print("Triggerbot:", state) end,
})

TriggerSection:Slider({
    Name     = "Delay (ms)",
    Min      = 0,
    Max      = 300,
    Step     = 5,
    Default  = 50,
    Suffix   = "ms",
    Callback = function(v) print("Trigger delay:", v) end,
})

-- ── TAB 2: VISUALS ──────────────────────────────────────────────────────────
local VisualTab = Win:Tab({ Name = "Visuals", Icon = "👁" })

local ESPSection = VisualTab:Section("ESP")

ESPSection:Toggle({
    Name     = "Player ESP",
    Default  = true,
    Callback = function(state) print("ESP:", state) end,
})

ESPSection:MultiDropdown({
    Name    = "ESP Components",
    Options = { "Box", "Name", "Distance", "Health Bar", "Skeleton", "Head Dot" },
    Default = { "Box", "Name", "Health Bar" },
    Callback = function(selected)
        print("ESP Components:", table.concat(selected, ", "))
    end,
})

ESPSection:ColorPicker({
    Name     = "ESP Color (Enemy)",
    Default  = Color3.fromRGB(230, 60, 60),
    Callback = function(c)
        print("ESP Color:", c)
    end,
})

ESPSection:ColorPicker({
    Name     = "ESP Color (Team)",
    Default  = Color3.fromRGB(60, 180, 230),
    Callback = function(c)
        print("Team ESP Color:", c)
    end,
})

ESPSection:Slider({
    Name     = "Max Distance",
    Min      = 50,
    Max      = 2000,
    Step     = 50,
    Default  = 500,
    Suffix   = " st",
    Callback = function(v) print("ESP dist:", v) end,
})

local WorldSection = VisualTab:Section("World")

WorldSection:Toggle({
    Name     = "No Fog",
    Default  = false,
    Callback = function(state) print("No fog:", state) end,
})

WorldSection:Dropdown({
    Name     = "Lighting Mode",
    Options  = { "Default", "Night", "Bright", "Neon" },
    Default  = "Default",
    Callback = function(v) print("Lighting:", v) end,
})

-- ── TAB 3: MOVEMENT ─────────────────────────────────────────────────────────
local MoveTab = Win:Tab({ Name = "Movement", Icon = "⚡" })

local MoveSection = MoveTab:Section("Speed & Physics")

MoveSection:Toggle({
    Name     = "Speed Hack",
    Default  = false,
    Callback = function(state) print("Speed hack:", state) end,
    Settings = function(settingsTab, parentSection)
        parentSection:Slider({
            Name = "Speed Multiplier",
            Min = 1, Max = 10, Step = 0.5, Default = 2,
            Callback = function(v) print("Speed mult:", v) end,
        })
    end,
})

MoveSection:Toggle({
    Name     = "Infinite Jump",
    Default  = false,
    Callback = function(state) print("Inf jump:", state) end,
})

MoveSection:Slider({
    Name     = "Jump Power",
    Min      = 50,
    Max      = 500,
    Step     = 10,
    Default  = 50,
    Suffix   = "",
    Callback = function(v)
        if game.Players.LocalPlayer.Character then
            local hum = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end,
})

MoveSection:Toggle({
    Name     = "No Clip",
    Default  = false,
    Callback = function(state) print("Noclip:", state) end,
})

-- ── TAB 4: MISC ─────────────────────────────────────────────────────────────
local MiscTab = Win:Tab({ Name = "Misc", Icon = "⚙" })

local MiscSection = MiscTab:Section("Utilities")

MiscSection:TextBox({
    Name        = "Chat Command",
    Placeholder = "Type command...",
    Callback    = function(text) print("Chat cmd changed:", text) end,
    OnEnter     = function(text)
        game.Players.LocalPlayer:Chat(text)
    end,
})

MiscSection:Button({
    Name        = "Rejoin Server",
    Description = "Reconnects to a fresh server",
    Callback    = function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, game.Players.LocalPlayer)
    end,
})

MiscSection:Button({
    Name        = "Copy Game ID",
    Description = "Copies PlaceId to clipboard",
    Callback    = function()
        setclipboard(tostring(game.PlaceId))
        VANTA:Notify("Copied", "PlaceId: " .. game.PlaceId, 3)
    end,
})

MiscSection:Separator()

local InfoSection = MiscTab:Section("Info")

local pingLabel = InfoSection:Label({ Text = "Ping: —", Color = Color3.fromRGB(140,220,140) })
local fpsLabel  = InfoSection:Label({ Text = "FPS:  —", Color = Color3.fromRGB(140,180,255) })

-- live update ping + fps every second
task.spawn(function()
    local RS = game:GetService("RunService")
    local last = tick()
    while task.wait(1) do
        local stats = game:GetService("Stats")
        local ping  = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        pingLabel:Set(string.format("Ping: %d ms", ping))
    end
end)

task.spawn(function()
    local RS = game:GetService("RunService")
    local frames, last = 0, tick()
    RS.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - last >= 1 then
            fpsLabel:Set(string.format("FPS:  %d", frames))
            frames = 0
            last = tick()
        end
    end)
end)

-- startup notification
-- (the SETTINGS tab at the bottom of the rail lets you rebind this key,
--  hide the menu, or unload it completely)
VANTA:Notify("VANTA Loaded", "RightShift toggles the menu — Settings tab to unload", 5)
