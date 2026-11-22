--#region header
--[[
    TONY SCRIPT PALACE  -  for Dandy's World ONLY  (made for the Real executor)
    -----------------------------------------------------------------
    Tabs:   ESP | Movement | World | Automation | Skill Checks | Pursuer | Customizer | Sound | Configs | Appearance

    Layout: every tab has a section rail on the left. Pick a section and its controls fill the page (no collapsing, no long scrolling).
            Wide windows also pin the Customizer's 3D preview beside whatever section you are editing.

    Styles (Appearance tab, the last one you used loads next time):
            Dandy's World (default)  |  Frutiger Aero (lowercase)  |  XMB / PlayStation  |  Windows XP Luna
    Dandy's World API Library loads in the background and feeds the live Game Info section on the World tab.

    Window: keybind show/hide (default RightShift, rebind in Appearance), hide button + optional reopen orb, start-hidden option,
            destroy button, drag the top bar, resize with the bottom-right grip, UI scale slider, fullscreen.

    Adding a new tab later:
        1. write a function that returns a list of sections
           { { title = "...", controls = { {t="toggle", ...}, ... } } }
        2. add  { id = "mytab", name = "My Tab", icon = "esp", build = fn }  to UI.tabs
           (wrap fn in  grouped(fn, { ["Section Title"] = { g = "Rail Group" } })  to group the rail)
        3. (optional) register save/load for configs:  Features.mytab = { serialize = fn, apply = fn }
    Write every label in Proper Case - the Aero skin lowercases it automatically.
]]

local env = (getgenv and getgenv()) or _G
if env.TonyScriptPalace and env.TonyScriptPalace.Destroy then pcall(env.TonyScriptPalace.Destroy) end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP               = Players.LocalPlayer

local alive = true
local conns = {}
local function connect(sig, fn) local c = sig:Connect(fn); conns[#conns + 1] = c; return c end
local function try(f, ...) local ok, a = pcall(f, ...); if ok then return a end; return nil end
local function guiParent() return (gethui and try(gethui)) or CoreGui end

--#endregion header
--#region filesystem
----------------------------------------------------------------------
-- FILE SYSTEM
----------------------------------------------------------------------
local ROOT_DIR   = "TonyScriptPalace"
local CFG_DIR    = ROOT_DIR .. "/Configs"
local SETTINGS_F = ROOT_DIR .. "/settings.json"

local function isF(p) return isfile and try(isfile, p) or false end
local function isD(p) return isfolder and try(isfolder, p) or false end
local function mkD(p) if makefolder and not isD(p) then pcall(makefolder, p) end end
local function rdF(p) return readfile and try(readfile, p) or nil end
local function wrF(p, c) if writefile then return (pcall(writefile, p, c)) end; return false end
local function lsD(p) return listfiles and try(listfiles, p) or {} end
local function dlF(p) if delfile then pcall(delfile, p) end end
local function baseName(p) p = tostring(p):gsub("\\", "/"); return p:match("([^/]+)$") or p end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function jenc(t) local ok, r = pcall(HttpService.JSONEncode, HttpService, t); return ok and r or nil end
local function jdec(s) local ok, r = pcall(HttpService.JSONDecode, HttpService, s); return ok and r or nil end
mkD(ROOT_DIR); mkD(CFG_DIR)

--#endregion filesystem
--#region colors
----------------------------------------------------------------------
-- COLOR HELPERS + PRESETS
----------------------------------------------------------------------
local C = Color3.fromRGB
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local RAINBOW = "Rainbow"

local function hexOf(c)
    return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function colorOf(s)
    if type(s) ~= "string" then return nil end
    local h = s:match("^#?(%x%x%x%x%x%x)$")
    if not h then return nil end
    return C(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
end
local function lum(c) return c.R * 0.299 + c.G * 0.587 + c.B * 0.114 end
local function copyT(t) local o = {}; for k, v in pairs(t) do o[k] = v end; return o end

local AERO_KEYS = {
    { "top", "Background Top" }, { "mid", "Background Middle" }, { "bottom", "Background Bottom" },
    { "accent", "Accent (Buttons / Title)" }, { "text", "Text" }, { "panel", "Panels" },
}
local XMB_KEYS = {
    { "top", "Background Top" }, { "bottom", "Background Bottom" }, { "wave", "Wave Color" }, { "accent", "Highlight" },
}
local AERO_ORDER = { "Default", "Dark Mode Aero", "Aqua Green", "Sunset", "Bubblegum" }
local AERO_PRESETS = {
    ["Default"]        = { top = C(185, 235, 255), mid = C(110, 200, 245), bottom = C(120, 215, 160), accent = C(20, 130, 215),  text = C(20, 62, 108),   panel = C(255, 255, 255) },
    ["Dark Mode Aero"] = { top = C(34, 58, 102),   mid = C(20, 38, 76),    bottom = C(12, 64, 78),    accent = C(45, 165, 235),  text = C(222, 240, 255), panel = C(18, 34, 64) },
    ["Aqua Green"]     = { top = C(205, 255, 230), mid = C(125, 228, 175), bottom = C(70, 180, 140),  accent = C(30, 170, 105),  text = C(8, 70, 50),     panel = C(255, 255, 255) },
    ["Sunset"]         = { top = C(255, 232, 190), mid = C(255, 175, 135), bottom = C(235, 120, 160), accent = C(225, 95, 60),   text = C(100, 30, 45),   panel = C(255, 255, 255) },
    ["Bubblegum"]      = { top = C(255, 220, 242), mid = C(210, 178, 255), bottom = C(155, 205, 255), accent = C(190, 80, 210),  text = C(85, 35, 105),   panel = C(255, 255, 255) },
}
local XMB_ORDER = { "Classic Blue", "Midnight", "Emerald", "Sakura", "Graphite" }
local XMB_PRESETS = {
    ["Classic Blue"] = { top = C(38, 98, 214),  bottom = C(5, 16, 64),  wave = C(255, 255, 255), accent = C(120, 200, 255) },
    ["Midnight"]     = { top = C(40, 36, 110),  bottom = C(4, 4, 22),   wave = C(150, 150, 255), accent = C(170, 150, 255) },
    ["Emerald"]      = { top = C(24, 150, 100), bottom = C(3, 42, 34),  wave = C(190, 255, 220), accent = C(130, 255, 190) },
    ["Sakura"]       = { top = C(238, 120, 170), bottom = C(80, 18, 64), wave = C(255, 220, 235), accent = C(255, 170, 210) },
    ["Graphite"]     = { top = C(80, 84, 96),   bottom = C(10, 10, 14), wave = C(220, 225, 235), accent = C(210, 220, 240) },
}

local XP_KEYS = {
    { "title", "Title Bar" }, { "face", "Window Face" }, { "accent", "Highlight" }, { "pane", "Side Pane" },
}
local XP_ORDER = { "Luna Blue", "Olive Green", "Silver", "Windows Classic" }
local XP_PRESETS = {
    ["Luna Blue"]       = { title = C(0, 84, 227),    face = C(236, 233, 216), accent = C(49, 106, 197),  pane = C(123, 162, 231) },
    ["Olive Green"]     = { title = C(116, 138, 72),  face = C(236, 233, 216), accent = C(147, 160, 112), pane = C(190, 204, 150) },
    ["Silver"]          = { title = C(139, 137, 176), face = C(240, 240, 245), accent = C(124, 124, 148), pane = C(196, 196, 222) },
    ["Windows Classic"] = { title = C(10, 36, 106),   face = C(212, 208, 200), accent = C(10, 36, 106),   pane = C(166, 178, 210) },
}

-- Dandy's World skin (default): dark striped panels, thick black outlines, yellow headers, orange sliders
local DANDY = {}
DANDY.keys = {
    { "panel", "Panels" }, { "header", "Headers / Highlight" }, { "fill", "Slider Fill" },
    { "on", "ON Color" }, { "off", "OFF Color" },
}
DANDY.order = { "Dandy's World", "Sprout's World", "Shelly's World", "Vee's World", "Astro's World", "Pebble's World",
    "Bobette's World", "Bassie's World", "Gourdy's World", "Lethal's World" }
DANDY.presets = {
    ["Dandy's World"]   = { panel = C(74, 74, 74),   header = C(255, 217, 0),   fill = C(255, 183, 16), on = C(108, 255, 100), off = C(255, 109, 111) },
    ["Sprout's World"]  = { panel = C(112, 40, 44),  header = C(255, 120, 110), fill = C(230, 60, 55),  on = C(255, 225, 130), off = C(255, 150, 150) },   -- red
    ["Shelly's World"]  = { panel = C(112, 92, 30),  header = C(255, 236, 90),  fill = C(255, 200, 40), on = C(150, 255, 120), off = C(255, 120, 110) },   -- yellow
    ["Vee's World"]     = { panel = C(40, 86, 48),   header = C(130, 255, 120), fill = C(70, 200, 80),  on = C(170, 255, 160), off = C(255, 130, 120) },   -- green
    ["Astro's World"]   = { panel = C(40, 70, 120),  header = C(120, 200, 255), fill = C(60, 140, 240), on = C(130, 255, 210), off = C(255, 130, 150) },   -- blue
    ["Pebble's World"]  = { panel = C(84, 84, 88),   header = C(214, 214, 218), fill = C(160, 160, 166), on = C(240, 240, 240), off = C(128, 128, 132) }, -- rock gray
    ["Bobette's World"] = { panel = C(26, 82, 44),  header = C(255, 92, 92),  fill = C(60, 170, 84),   on = C(150, 255, 150), off = C(255, 120, 120) },  -- Christmas: dark green panels, bright red headers
    ["Bassie's World"]  = { panel = C(168, 110, 140), header = C(255, 240, 120), fill = C(140, 205, 245), on = C(160, 235, 255), off = C(255, 160, 190) }, -- Easter
    ["Gourdy's World"]  = { panel = C(70, 38, 100),  header = C(255, 150, 40),  fill = C(255, 120, 20), on = C(255, 170, 60),  off = C(190, 140, 255) },  -- Halloween
    ["Lethal's World"]  = { panel = C(40, 40, 52),   header = C(255, 80, 80),   fill = C(255, 160, 40), on = C(90, 255, 140),  off = C(255, 90, 200) },   -- rainbow (title + outline cycle colors)
}

--#endregion colors
--#region settings
----------------------------------------------------------------------
-- UI SETTINGS (persisted)
----------------------------------------------------------------------
local STYLE_LIST = { "dandy", "aero", "xmb", "xp" }   -- dandy = default
local function validStyle(s) return table.find(STYLE_LIST, s) ~= nil end
local function defaultWin() return { dandy = { w = 960, h = 600 }, aero = { w = 860, h = 560 }, xmb = { w = 940, h = 580 }, xp = { w = 860, h = 560 } } end

local S = {
    style = "dandy", keybind = "RightShift", scale = 1, fullscreen = false, orb = true, startHidden = false,
    autoload = true, lastConfig = "", pos = nil, sounds = true, sfxVol = 1, win = defaultWin(),
    dandy = { preset = "Dandy's World", colors = copyT(DANDY.presets["Dandy's World"]) },
    aero = { preset = "Default", colors = copyT(AERO_PRESETS["Default"]) },
    xmb = { preset = "Classic Blue", colors = copyT(XMB_PRESETS["Classic Blue"]), speed = 1, alpha = 0.8 },
    xp = { preset = "Luna Blue", colors = copyT(XP_PRESETS["Luna Blue"]) },
}
local dirty = false

local function packColors(t) local o = {}; for k, v in pairs(t) do o[k] = hexOf(v) end; return o end
local function unpackColors(dst, src)
    if type(src) ~= "table" then return end
    for k in pairs(dst) do local c = colorOf(src[k]); if c then dst[k] = c end end
end

local function saveSettings()
    local s = jenc({
        v = 2, style = S.style, keybind = S.keybind, scale = S.scale, fullscreen = S.fullscreen, orb = S.orb, startHidden = S.startHidden,
        autoload = S.autoload, lastConfig = S.lastConfig, pos = S.pos, win = S.win, sounds = S.sounds, sfxVol = S.sfxVol,
        dandy = { preset = S.dandy.preset, colors = packColors(S.dandy.colors) },
        aero = { preset = S.aero.preset, colors = packColors(S.aero.colors) },
        xmb = { preset = S.xmb.preset, colors = packColors(S.xmb.colors), speed = S.xmb.speed, alpha = S.xmb.alpha },
        xp = { preset = S.xp.preset, colors = packColors(S.xp.colors) },
    })
    if s then wrF(SETTINGS_F, s) end
end

do -- startup load
    local s = jdec(rdF(SETTINGS_F) or "")
    if type(s) == "table" then
        -- settings saved before v2 remembered Frutiger Aero as the style; the new default is Dandy's World, so those are ignored once
        if s.v == 2 and validStyle(s.style) then S.style = s.style end
        if type(s.keybind) == "string" and pcall(function() return Enum.KeyCode[s.keybind] end) then S.keybind = s.keybind end
        S.scale = math.clamp(tonumber(s.scale) or 1, 0.6, 1.6)
        if s.fullscreen ~= nil then S.fullscreen = s.fullscreen and true or false end
        if s.orb ~= nil then S.orb = s.orb and true or false end
        if s.startHidden ~= nil then S.startHidden = s.startHidden and true or false end
        if s.autoload ~= nil then S.autoload = s.autoload and true or false end
        if s.sounds ~= nil then S.sounds = s.sounds and true or false end
        S.sfxVol = math.clamp(tonumber(s.sfxVol) or 1, 0, 1)
        if type(s.lastConfig) == "string" then S.lastConfig = s.lastConfig end
        if type(s.pos) == "table" and tonumber(s.pos.x) and tonumber(s.pos.y) then S.pos = { x = s.pos.x, y = s.pos.y } end
        if type(s.win) == "table" then
            for k in pairs(S.win) do
                local w = s.win[k]
                if type(w) == "table" and tonumber(w.w) and tonumber(w.h) then S.win[k] = { w = w.w, h = w.h } end
            end
        end
        for _, k in ipairs({ "dandy", "aero", "xmb", "xp" }) do
            local d = s[k]
            if type(d) == "table" then
                if type(d.preset) == "string" then S[k].preset = d.preset end
                unpackColors(S[k].colors, d.colors)
            end
        end
        if type(s.xmb) == "table" then
            S.xmb.speed = math.clamp(tonumber(s.xmb.speed) or 1, 0, 3)
            S.xmb.alpha = math.clamp(tonumber(s.xmb.alpha) or 0.8, 0, 1)
        end
    end
end

--#endregion settings
--#region esp
----------------------------------------------------------------------
-- ESP  (ported from DandyESP, Highlight based)
----------------------------------------------------------------------
local ESP = {}
local espDirty = true
local rainbowColor = C(255, 0, 0)
local rainbowSet = {}                                   -- [Highlight] = true
local rainbowSw = setmetatable({}, { __mode = "k" })    -- [swatch Frame] = true

local ITEM_GROUPS = {
    { C(255, 140, 0),   { "Pumpkin", "Stopwatch", "SkillCheckCandy" } },
    { C(255, 255, 255), { "Tape", "Tapes", "ResearchCapsule" } },
    { C(255, 105, 180), { "Gumball", "Jawbreaker" } },        -- the game calls them "Gumball" internally (shown as "Gumballs")
    { C(170, 255, 0),   { "Chocolate", "ChocolateBox" } },
    { C(0, 255, 0),     { "StaminaCandy", "Pop", "ProteinBar", "PopBottle" } },
    { C(160, 32, 240),  { "Instructions", "ExtractionSpeedCandy", "JumperCable", "Valve" } },
    { C(255, 0, 0),     { "AirHorn", "GigiHoard" } },
    { C(150, 90, 40),   { "BonBon" } },
    { C(255, 255, 0),   { "ChristmasCookie", "DandyCorn", "DandyEasterEggs", "SpeedCandy" } },
    { RAINBOW,          { "Bandage", "HealthKit" } },
    { C(0, 200, 120),   { "EjectButton" } },
    { C(0, 120, 255),   { "StealthCandy", "SmokeBomb" } },
}

local Cfg = {
    Enabled = false, Fill = true, FillTransparency = 0.75, OutlineTransparency = 0,
    AlwaysOnTop = true, UpdateRate = 0.2, MaxHighlights = 128,
    Categories = {
        Players    = { Enabled = true, Fill = true, Self = false, Color = C(0, 255, 0) },
        Twisteds   = { Enabled = true, Fill = true, Color = C(255, 0, 0) },
        Tendrils   = { Enabled = true, Fill = true, Color = C(255, 0, 0) },      -- Twisted Sprout's tendrils (SproutTendril)
        BlotHands  = { Enabled = true, Fill = true, Color = C(255, 0, 0) },      -- Twisted Blot's hands (the Arm in each BlotHand_R / BlotHand_L)
        IchorPuddles = { Enabled = true, Fill = true, Color = C(255, 0, 0) },   -- everything in the room's Puddles folder except Twisted Barnaby
        Generators = { Enabled = true, Fill = true, HideCompleted = false, Brusha = true, DuoOne = true, Colors = {
            Incomplete = C(255, 0, 0), InProgress = C(255, 255, 0), Completed = C(0, 255, 0), Connie = C(0, 255, 255), Brusha = C(170, 0, 255),
            DuoOne = C(255, 165, 0),      -- duo machine with only one player working on it
        } },
        Doors      = { Enabled = true, Fill = true, Color = C(255, 140, 0), HideUsed = false },
        StarPillows = { Enabled = true, Fill = true, Mode = "All", Color = C(0, 0, 255), OtherDiff = false, OtherColor = C(239, 0, 244),
            ShowTwisted = true, TwistedColor = C(255, 0, 0) },
        Bookshelves = { Enabled = false, Fill = true, Color = C(160, 32, 240), Patterns = { "bookshel", "bookcase" } },
        Items      = { Enabled = true, Fill = true, PerItem = true, Color = C(255, 255, 255), Fallback = C(200, 200, 200), Colors = {}, Hidden = {} },
    },
}
local KNOWN_ITEMS = {}
for _, g in ipairs(ITEM_GROUPS) do
    for _, n in ipairs(g[2]) do
        Cfg.Categories.Items.Colors[n] = g[1]
        KNOWN_ITEMS[#KNOWN_ITEMS + 1] = n
    end
end
table.sort(KNOWN_ITEMS)
ESP.Config = Cfg
local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepcopy(v) end
    return o
end
local DEF = deepcopy(Cfg)   -- factory defaults (used by the "Default" / "Reset ESP Colors" buttons)

do
    local holder = Instance.new("Folder")
    holder.Name = "TonyScriptPalaceESP"
    holder.Parent = guiParent()
    local live = {}  -- [Instance] = Highlight

    local function getRoomModels()
        local rooms, folder = {}, Workspace:FindFirstChild("CurrentRoom")
        if folder then for _, r in ipairs(folder:GetChildren()) do rooms[#rooms + 1] = r end end
        return rooms
    end
    local function pivotPosition(inst)
        if inst:IsA("Model") then return inst:GetPivot().Position
        elseif inst:IsA("BasePart") then return inst.Position end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or Vector3.zero
    end
    local function validTarget(inst) return inst:IsA("Model") or inst:IsA("BasePart") end

    local bookCache = { room = nil, list = {}, last = 0 }
    local function getBookshelves(room)
        local cfg, now = Cfg.Categories.Bookshelves, os.clock()
        if bookCache.room == room and now - bookCache.last < 5 then return bookCache.list end
        bookCache.room, bookCache.last, bookCache.list = room, now, {}
        local free = room:FindFirstChild("FreeArea")
        if not free then return bookCache.list end
        local matched = {}
        for _, d in ipairs(free:GetDescendants()) do
            if validTarget(d) then
                local lname, hit = d.Name:lower(), false
                for _, p in ipairs(cfg.Patterns) do
                    if lname:find(p, 1, true) then hit = true; break end
                end
                if hit then
                    local nested, p = false, d.Parent
                    while p and p ~= free do
                        if matched[p] then nested = true; break end
                        p = p.Parent
                    end
                    if not nested then matched[d] = true; bookCache.list[#bookCache.list + 1] = d end
                end
            end
        end
        return bookCache.list
    end

    -- returns color, isCompleted   (a completed machine counts as completed even if Connie did it)
    local function machineState(gen)
        local colors = Cfg.Categories.Generators.Colors
        local stats = gen:FindFirstChild("Stats")
        if not stats then return colors.Incomplete, false end
        local function val(name) local v = stats:FindFirstChild(name); return v and v.Value end
        local completed = val("Completed") == true
        if val("Connie") == true then return colors.Connie, completed end
        if completed then return colors.Completed, true end
        local workers = 0
        if val("ActivePlayer") then workers += 1 end
        if val("ActivePlayer2") then workers += 1 end
        local isDuo = gen:GetAttribute("IsDualGen") == true
        if isDuo and workers == 1 and Cfg.Categories.Generators.DuoOne then return colors.DuoOne, false end   -- one of the two slots is taken
        local needed = isDuo and 2 or 1
        if workers >= needed then return colors.InProgress, false end
        if Cfg.Categories.Generators.Brusha then      -- incomplete, idle, no Connie, but carrying Brusha's debuff chamber
            local ch = gen:FindFirstChild("BrushaDebuffChamber", true)
            if ch and ch:IsA("MeshPart") then return colors.Brusha, false end
        end
        return colors.Incomplete, false
    end

    -- Star Pillows. The game makes one Model named "StarPillowGroup" in Workspace PER OWNER (so there are several with
    -- the same name), each holding "StarPillowLocal" copies; pillows with no owner sit directly in Workspace; and the
    -- original server pillows are "StarPillow" models in CurrentRoom.<room>.StarPillows. The owner is the
    -- StarPillowTarget ObjectValue (a Player for Toons, a model named AstroMonster for Twisted Astro).
    local function isMine(v)
        if typeof(v) ~= "Instance" then return false end
        if v == LP or v == LP.Character or v.Name == LP.Name or v.Name == LP.DisplayName then return true end
        local ch = LP.Character
        return (ch and v:IsDescendantOf(ch)) or false
    end

    local function collect()
        local desired = {}
        local function add(inst, color, cat)
            if color and validTarget(inst) then desired[inst] = { color = color, cat = cat } end
        end
        local cats = Cfg.Categories
        -- Twisted Sprout's tendrils are cloned into the room while the floor runs: into its FreeArea folder, or straight into the room when it has none
        local function addTendrils(folder)
            for _, c in ipairs(folder:GetChildren()) do
                if c.Name == "SproutTendril" then add(c, cats.Tendrils.Color, "Tendrils") end
            end
        end

        if cats.Players.Enabled then
            local selfOn = cats.Players.Self
            local f = Workspace:FindFirstChild("InGamePlayers")
            if f then
                for _, m in ipairs(f:GetChildren()) do
                    if m:IsA("Model") then
                        local isSelf = m.Name == LP.Name or m.Name == LP.DisplayName or m == LP.Character
                        if selfOn or not isSelf then add(m, cats.Players.Color, "Players") end
                    end
                end
            end
            if selfOn and LP.Character and LP.Character:IsDescendantOf(Workspace) then
                add(LP.Character, cats.Players.Color, "Players")
            end
        end

        if cats.StarPillows.Enabled then
            local sp = cats.StarPillows
            local function addPillow(m)
                if not m:IsA("Model") then return end
                local tgt = m:FindFirstChild("StarPillowTarget")
                local owner = tgt and tgt:IsA("ObjectValue") and tgt.Value or nil
                if m:GetAttribute("StarPillowKind") == "Twisted" or (owner ~= nil and owner.Name == "AstroMonster") then
                    if sp.ShowTwisted then add(m, sp.TwistedColor, "StarPillows") end
                    return
                end
                local mine = isMine(owner)
                local show = sp.Mode == "All" or (sp.Mode == "Mine" and mine) or (sp.Mode == "Others" and not mine)
                if show then add(m, (sp.OtherDiff and not mine) and sp.OtherColor or sp.Color, "StarPillows") end
            end
            for _, c in ipairs(Workspace:GetChildren()) do
                if c.Name == "StarPillowGroup" then
                    for _, m in ipairs(c:GetChildren()) do
                        if m.Name == "StarPillowLocal" then addPillow(m) end
                    end
                elseif c.Name == "StarPillowLocal" then
                    addPillow(c)
                end
            end
            for _, room in ipairs(getRoomModels()) do
                local f = room:FindFirstChild("StarPillows")
                if f then
                    for _, m in ipairs(f:GetChildren()) do
                        if m.Name == "StarPillow" then addPillow(m) end
                    end
                end
            end
        end

        for _, room in ipairs(getRoomModels()) do
            if cats.Twisteds.Enabled then
                local f = room:FindFirstChild("Monsters")
                if f then
                    -- The game's ShellProjector draws some Twisteds (Flutter, which flies) from a client-side copy named "<Name>_Shell"
                    -- parented to the camera, and makes the real model in Monsters invisible (LocalTransparencyModifier = 1).
                    -- A Highlight on an invisible model shows nothing, so when a shell exists that is what gets highlighted.
                    local cam = Workspace.CurrentCamera
                    for _, m in ipairs(f:GetChildren()) do
                        local shell = cam and cam:FindFirstChild(m.Name .. "_Shell")
                        add((shell and shell:IsA("Model")) and shell or m, cats.Twisteds.Color, "Twisteds")
                    end
                end
            end
            if cats.Tendrils.Enabled then
                local fa = room:FindFirstChild("FreeArea")
                if fa then addTendrils(fa) end
                addTendrils(room)
            end
            if cats.BlotHands.Enabled then
                -- each Blot hand sits in a BlotHandZone_N; the thing worth outlining is the visible Arm MeshPart (the rest of the hand is invisible)
                for _, z in ipairs(room:GetChildren()) do
                    if z.Name:find("^BlotHandZone") then
                        for _, d in ipairs(z:GetDescendants()) do
                            if d.Name == "Arm" and d:IsA("BasePart") and d.Parent and d.Parent.Name:find("^BlotHand") then
                                add(d, cats.BlotHands.Color, "BlotHands")
                            end
                        end
                    end
                end
            end
            -- the Puddles folder holds Ichor puddles and also Twisted Barnaby (TBarnaby_v3), who belongs to the Twisted ESP
            local puddles = room:FindFirstChild("Puddles")
            if puddles then
                for _, c in ipairs(puddles:GetChildren()) do
                    if c.Name == "TBarnaby_v3" then
                        if cats.Twisteds.Enabled then add(c, cats.Twisteds.Color, "Twisteds") end
                    elseif cats.IchorPuddles.Enabled then
                        add(c, cats.IchorPuddles.Color, "IchorPuddles")
                    end
                end
            end
            if cats.Generators.Enabled then
                local f = room:FindFirstChild("Generators")
                if f then
                    for _, g in ipairs(f:GetChildren()) do
                        local col, done = machineState(g)
                        if not (cats.Generators.HideCompleted and done) then add(g, col, "Generators") end
                    end
                end
            end
            if cats.Doors.Enabled then
                local f = room:FindFirstChild("TrickOrTreatDoors")
                if f then
                    for _, d in ipairs(f:GetChildren()) do
                        local used = d:GetAttribute("TrickOrTreatUsed") or d:GetAttribute("TrickOrTreatSpent")
                        if not (cats.Doors.HideUsed and used) then add(d, cats.Doors.Color, "Doors") end
                    end
                end
            end
            if cats.Bookshelves.Enabled then
                for _, b in ipairs(getBookshelves(room)) do add(b, cats.Bookshelves.Color, "Bookshelves") end
            end
            if cats.Items.Enabled then
                local f = room:FindFirstChild("Items")
                if f then
                    local it = cats.Items
                    for _, i in ipairs(f:GetChildren()) do
                        if not it.Hidden[i.Name] then
                            local col
                            if it.PerItem then col = it.Colors[i.Name] or it.Fallback else col = it.Color end
                            add(i, col, "Items")
                        end
                    end
                end
            end
        end
        return desired
    end

    local function applyStyle(hl, entry)
        local catCfg = Cfg.Categories[entry.cat]
        local fillOn = Cfg.Fill and not (catCfg and catCfg.Fill == false)
        hl.FillTransparency = fillOn and ((catCfg and catCfg.FillTransparency) or Cfg.FillTransparency) or 1
        hl.OutlineTransparency = (catCfg and catCfg.OutlineTransparency) or Cfg.OutlineTransparency
        hl.DepthMode = Cfg.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        if entry.color == RAINBOW then
            rainbowSet[hl] = true
        else
            rainbowSet[hl] = nil
            hl.FillColor = entry.color
            hl.OutlineColor = entry.color
        end
    end

    local function removeHighlight(inst)
        local hl = live[inst]
        if hl then rainbowSet[hl] = nil; hl:Destroy(); live[inst] = nil end
    end

    function ESP.Refresh()
        if not Cfg.Enabled then
            for inst in pairs(live) do removeHighlight(inst) end
            return
        end
        local desired = collect()
        for inst in pairs(live) do
            if not desired[inst] or not inst:IsDescendantOf(game) then removeHighlight(inst) end
        end
        local cam = Workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or Vector3.zero
        local list = {}
        for inst, entry in pairs(desired) do
            list[#list + 1] = { inst = inst, entry = entry, dist = (pivotPosition(inst) - camPos).Magnitude }
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        for index, item in ipairs(list) do
            if index > Cfg.MaxHighlights then
                removeHighlight(item.inst)
            else
                local hl = live[item.inst]
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Adornee = item.inst
                    hl.Parent = holder
                    live[item.inst] = hl
                end
                applyStyle(hl, item.entry)
            end
        end
    end

    function ESP.Unload()
        for inst in pairs(live) do removeHighlight(inst) end
        pcall(function() holder:Destroy() end)
    end

    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        if not alive then return end
        rainbowColor = Color3.fromHSV((os.clock() * 0.5) % 1, 1, 1)
        for hl in pairs(rainbowSet) do hl.FillColor = rainbowColor; hl.OutlineColor = rainbowColor end
        for sw in pairs(rainbowSw) do sw.BackgroundColor3 = rainbowColor end
        acc += dt
        if espDirty or acc >= Cfg.UpdateRate then
            acc, espDirty = 0, false
            local ok, err = pcall(ESP.Refresh)
            if not ok then warn("[Tony Script Palace ESP] " .. tostring(err)) end
        end
    end)
end

--#endregion esp
--#region config-system
----------------------------------------------------------------------
-- CONFIG SYSTEM  (features register serialize/apply; ESP is the first)
----------------------------------------------------------------------
local STEP_SIZES = { Units = 1, Stars = 2.5, ["Half Stars"] = 1.25 }
local Speed = {
    Enabled = false, Mode = "Additive", Step = "Units", Floor = 0, Limit = 0, Cap = false, Auto = true,
    Add = { WalkAll = 0, WalkOdd = 0, WalkEven = 0, RunAll = 0, RunOdd = 0, RunEven = 0 },   -- speed units
    Mul = { WalkAll = 0, WalkOdd = 0, WalkEven = 0, RunAll = 0, RunOdd = 0, RunEven = 0 },   -- percent
    Anim = { On = false, Ability = true },   -- sync animation speed with stats (Ability = ability animations follow your speed while you move or decode)
    Blackout = { Mode = "Off", Sound = true, Eyes = true, Lights = true, Bulbs = true },   -- fake blackout: Off / Every Floor / Always
}
-- Infinite Stamina: Infinite = fake-run when out of stamina, ShowActual = stop faking the stamina bar,
-- Icon = show the sprint icon while fake running
-- AutoRun = hold sprint for you on treadmill machines, stopping at RunStop stamina and starting again at RunResume.
-- Peak = the highest stamina ever seen (used as the slider maximum).
-- StopMode/ResumeMode: "Number" uses RunStop/RunResume, "Fraction" uses StopFrac/ResumeFrac (like "3/4") of your maximum stamina.
local Stam = { Infinite = false, ShowActual = false, Icon = true, AutoRun = false, RunStop = 20, RunResume = 100, Peak = 0,
    StopMode = "Number", ResumeMode = "Number", StopFrac = "1/8", ResumeFrac = "1/2" }
local STAM_MODES = { "Number", "Fraction" }
-- "3/4", "1/2", "50%" or "0.75" -> 0..1 (nil if it cannot be read)
local function stamParseFraction(txt)
    txt = tostring(txt or ""):gsub("%s+", "")
    local pct = txt:match("^(%d*%.?%d+)%%$")
    if pct then return math.clamp(tonumber(pct) / 100, 0, 1) end
    local a, b = txt:match("^(%d*%.?%d+)/(%d*%.?%d+)$")
    if a then
        local n, d = tonumber(a), tonumber(b)
        if d and d > 0 then return math.clamp(n / d, 0, 1) end
        return nil
    end
    local dec = tonumber(txt)
    if dec then return math.clamp(dec, 0, 1) end
    return nil
end
local function stamThreshold(mode, number, maxStam, frac)
    if mode == "Fraction" then return maxStam * (stamParseFraction(frac) or 0.5) end
    return number
end
local function stamModeOk(m) return m == "Number" or m == "Fraction" end
-- older configs stored "Max" / "Max/2" ... "Max/16"; those become fractions
local function stamLoadMode(mode)
    if stamModeOk(mode) then return mode, nil end
    if mode == "Max" then return "Fraction", "1/1" end
    local d = tonumber(tostring(mode):match("^Max/(%d+)$"))
    if d and d > 0 then return "Fraction", "1/" .. d end
    return nil, nil
end
local Features = {}
do
    local function ser(v)
        if typeof(v) == "Color3" then return hexOf(v) end
        if type(v) == "table" then local o = {}; for k, x in pairs(v) do o[k] = ser(x) end; return o end
        return v
    end
    local function applyInto(dst, src)
        for k, v in pairs(src) do
            if type(v) == "string" then
                local col = (v:sub(1, 1) == "#") and colorOf(v)
                if col then dst[k] = col
                elseif v == RAINBOW then dst[k] = RAINBOW
                elseif type(dst[k]) == "string" then dst[k] = v end
            elseif type(v) == "table" then
                if type(dst[k]) ~= "table" then dst[k] = {} end
                applyInto(dst[k], v)
            elseif type(v) == type(dst[k]) or (dst[k] == nil and type(v) == "boolean") then
                dst[k] = v
            end
        end
    end
    Features.esp = {
        serialize = function() return ser(Cfg) end,
        apply = function(data)
            if type(data) ~= "table" then return end
            Cfg.Categories.Items.Hidden = {}
            applyInto(Cfg, data)
            local it = Cfg.Categories.Items               -- configs saved before the fix used the key "Gumballs"
            if it.Colors.Gumballs ~= nil then
                local d = type(data.Categories) == "table" and type(data.Categories.Items) == "table" and data.Categories.Items.Colors
                if not (type(d) == "table" and d.Gumball ~= nil) then it.Colors.Gumball = it.Colors.Gumballs end
                it.Colors.Gumballs = nil
            end
            if it.Hidden.Gumballs ~= nil then it.Hidden.Gumball = it.Hidden.Gumballs; it.Hidden.Gumballs = nil end
            Cfg.MaxHighlights = math.clamp(tonumber(Cfg.MaxHighlights) or 128, 4, 255)
            Cfg.UpdateRate = math.clamp(tonumber(Cfg.UpdateRate) or 0.2, 0.05, 1)
            espDirty = true
        end,
    }
    Features.speed = {
        serialize = function() return ser(Speed) end,
        apply = function(data)
            if type(data) ~= "table" then return end
            local wasOn = Speed.Enabled
            applyInto(Speed, data)
            Speed.Enabled = wasOn            -- the speed modifier switch is saved by the "switches" entry, so configs from before that was added leave it alone
            if Speed.Mode ~= "Additive" and Speed.Mode ~= "Multiplicative" then Speed.Mode = "Additive" end
            if not STEP_SIZES[Speed.Step] then Speed.Step = "Units" end
            Speed.Floor = math.clamp(tonumber(Speed.Floor) or 0, 0, 100)
            Speed.Limit = math.clamp(tonumber(Speed.Limit) or 0, 0, 200)
            Speed.Blackout.Mode = "Off"      -- the fake blackout has no switch in the UI any more, so an old config must not leave it running
        end,
    }
    Features.stamina = {
        serialize = function() return { ShowActual = Stam.ShowActual, Icon = Stam.Icon, RunStop = Stam.RunStop, RunResume = Stam.RunResume, StopMode = Stam.StopMode, ResumeMode = Stam.ResumeMode, StopFrac = Stam.StopFrac, ResumeFrac = Stam.ResumeFrac, Peak = Stam.Peak } end,   -- the Infinite Stamina and Auto Run switches are saved by the "switches" entry
        apply = function(data)
            if type(data) ~= "table" then return end
            if type(data.ShowActual) == "boolean" then Stam.ShowActual = data.ShowActual end
            if type(data.Icon) == "boolean" then Stam.Icon = data.Icon end
            Stam.RunStop = math.clamp(tonumber(data.RunStop) or Stam.RunStop, 0, 9999)
            Stam.RunResume = math.clamp(tonumber(data.RunResume) or Stam.RunResume, 0, 9999)
            local sm, sf = stamLoadMode(data.StopMode)
            if sm then Stam.StopMode = sm; if sf then Stam.StopFrac = sf end end
            local rm, rf = stamLoadMode(data.ResumeMode)
            if rm then Stam.ResumeMode = rm; if rf then Stam.ResumeFrac = rf end end
            if type(data.StopFrac) == "string" and stamParseFraction(data.StopFrac) then Stam.StopFrac = data.StopFrac end
            if type(data.ResumeFrac) == "string" and stamParseFraction(data.ResumeFrac) then Stam.ResumeFrac = data.ResumeFrac end
            Stam.Peak = math.max(Stam.Peak, math.clamp(tonumber(data.Peak) or 0, 0, 9999))
        end,
    }
end


local function cfgPath(n) return CFG_DIR .. "/" .. n .. ".json" end
local function sanitize(n) return (trim(n):gsub("[^%w%-_ ]", "_")) end
local function listConfigs()
    local out = {}
    for _, p in ipairs(lsD(CFG_DIR)) do
        local n = baseName(p)
        if n:lower():match("%.json$") then out[#out + 1] = (n:gsub("%.[jJ][sS][oO][nN]$", "")) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
local function saveConfig(name)
    local data = { version = 1, features = {} }
    for k, f in pairs(Features) do data.features[k] = f.serialize() end
    local js = jenc(data)
    return js and wrF(cfgPath(name), js) or false
end
local function loadConfig(name)
    local data = jdec(rdF(cfgPath(name)) or "")
    if type(data) ~= "table" or type(data.features) ~= "table" then return false end
    for k, f in pairs(Features) do
        if data.features[k] then f.apply(data.features[k]) end
    end
    return true
end

--#endregion config-system
--#region fun-settings
----------------------------------------------------------------------
-- FUN: MORE SKILL CHECKS  (settings + speed effects. The engine that plays the checks is further down.)
-- Effects are kept here, before the movement engine, because the movement engine applies them:
--   flat units are added to the game's base walk/run speed, BasePct adds a percent of that base speed,
--   and multipliers are folded into the game's own SpeedModifier / RunSpeedModifier. All of that happens BEFORE
--   the Speed tab's own adjustments, so the two systems stack instead of fighting.
----------------------------------------------------------------------
local Fun = {
    Enabled = false,
    When = "Always",                    -- Always | While Not Idle | While Chased
    Default = true, Circle = false, Treadmill = false,
    SizeMode = "Stat", Size = 150,      -- Stat = BoundarySize x BoundarySizeModifier, Manual = Size
    SpeedMode = "Game", DefaultTime = 2, CircleTime = 1.2, SpeedRef = 3,   -- Game = the game's own speeds, Skill Check Speed = stat-based (SpeedRef is the stat value that gives the game's normal speed), Manual = the times here (seconds)
    ChanceMode = "Stat", Chance = 25,   -- Stat = SkillCheckChance
    ValueMode = "Stat", Value = 2,      -- Stat = SkillCheckValue
    CancelWhenSpotted = false,          -- the game cancels any non-door skill check when you are spotted or hit; by default extra checks ignore that
    TwistedCount = "Chasing You",       -- which Twisteds count: Chasing You (the game's ChaseCount) | On The Floor
    ChanceScale = false, ChanceScaleMode = "Flat", ChancePer = 5, ChancePct = 10,   -- chance per Twisted: Flat = percentage points added, Multiplier = percent of the chance
    SpeedScale = false, SpeedScaleMode = "Multiplier", SpeedPct = 10, SpeedFlat = 0.1,   -- marker speed per Twisted
    SizeScale = false, SizeScaleMode = "Multiplier", SizePct = -5, SizeFlat = -10,       -- skill check size per Twisted
    Gap = 4,                            -- minimum seconds between two extra checks (the game itself uses 4)
    TreadmillDazed = true,              -- failing a treadmill check slows you like the real game (per the wiki: -70% walk, -80% run)
    TreadmillAll = false,               -- also apply the treadmill failure slow to failed default and circle checks
    PenaltiesOnTreadmill = true,        -- the Failure Penalties above also apply to failed treadmill checks
    TreadmillWalkPct = 70, TreadmillRunPct = 80, TreadmillTime = 3,
    DazedBlock = false,                 -- also block sprinting while it lasts (the game's client code has such a block)
    ShowDazed = false,                  -- the game does not normally show Dazed above your head, so this is opt-in
    CustomIcons = false,                -- icons for effects the game has no buff for (flat/multiplier boosts, Magnifying Glass)
    Rewards = false, RewardMode = "Skill Check Stat", RewardStat = "Skill Check Value",
    RewardWalk = 2, RewardRun = 2, RewardWalkPct = 10, RewardRunPct = 5, EnergizedTier = "I", EnergizedPct = 25, RewardTime = 3,
    Penalties = false, PenaltyMode = "Slow",
    PenaltyWalk = 2, PenaltyRun = 2, PenaltyWalkPct = 10, PenaltyRunPct = 10, SlowTier = "II", SlowPct = 25, PenaltyTime = 3,
    Stack = "Off", StackLimit = 3,      -- Off | On | Limit
    Trinkets = false, MagTime = 3,
    Icons = true,
    Status = "Off",
    fx = {}, dazedUntil = 0,
}
local FUN_WHEN = { "Always", "While Not Idle", "While Chased" }
local FUN_AUTO = { "Stat", "Manual" }
local FUN_SPEED = { "Game", "Skill Check Speed", "Manual" }
local FUN_REWARD_MODES = { "Skill Check Stat", "Flat", "Multiplier", "Energized" }
local FUN_REWARD_STATS = { "Skill Check Value", "Skill Check Speed" }
local FUN_PEN_MODES = { "Flat", "Multiplier", "Slow", "Kill" }
local FUN_STACK = { "Off", "On", "Limit" }
local FUN_COUNT = { "Chasing You", "On The Floor" }
local FUN_SCALE = { "Multiplier", "Flat" }
local FUN_SCALE_CHANCE = { "Flat", "Multiplier" }
local FUN_TIERS = { "I", "II", "III", "Custom" }
local FUN_SLOW_PCT = { I = 15, II = 25, III = 50 }              -- the game's Slow tiers
local FUN_ENERGIZED_PCT = { I = 25, II = 50, III = 75 }         -- the game's Energized tiers
local FUN_TIER_NUM = { I = 1, II = 2, III = 3 }

local function funIn(list, v) for _, x in ipairs(list) do if x == v then return true end end; return false end

-- adds an effect to a stacking group ("reward", "penalty", "mag") and applies the stacking rule
function Fun.add(group, e, dur)
    local now = os.clock()
    e.group, e.expires, e.dur = group, now + math.max(dur, 0.1), math.max(dur, 0.1)
    local fx, same = Fun.fx, {}
    for i, x in ipairs(fx) do if x.group == group then same[#same + 1] = i end end
    if Fun.Stack == "Off" then
        for i = #same, 1, -1 do table.remove(fx, same[i]) end            -- a new one replaces (refreshes) the old one
    elseif Fun.Stack == "Limit" then
        local limit = math.max(1, math.floor(Fun.StackLimit))
        while #same >= limit do                                           -- full: the one that would end first makes room
            local oldest = 1
            for j = 2, #same do if fx[same[j]].expires < fx[same[oldest]].expires then oldest = j end end
            table.remove(fx, same[oldest])
            same = {}
            for i, x in ipairs(fx) do if x.group == group then same[#same + 1] = i end end
        end
    end
    fx[#fx + 1] = e
end

-- returns flat units, base percent (0.04 = 4% of the base speed) and multiplier for walking or running
function Fun.mods(running)
    local now, flat, pct, mul = os.clock(), 0, 0, 1
    local fx = Fun.fx
    for i = #fx, 1, -1 do
        local e = fx[i]
        if e.expires <= now then table.remove(fx, i)
        else
            flat = flat + (running and (e.flatRun or 0) or (e.flatWalk or 0))
            pct = pct + (e.basePct or 0)
            mul = mul * (running and (e.mulRun or 1) or (e.mulWalk or 1))
        end
    end
    return flat, pct, mul
end
function Fun.dazed() return os.clock() < Fun.dazedUntil end
function Fun.activeCount() local n = 0; local now = os.clock(); for _, e in ipairs(Fun.fx) do if e.expires > now then n = n + 1 end end; return n end

--#endregion fun-settings
--#region movement-engine
----------------------------------------------------------------------
-- MOVEMENT ENGINE  (reads the player's Stats folder, writes Humanoid.WalkSpeed)
----------------------------------------------------------------------
local SP = { last = nil, learned = {}, peak = {}, flag = nil, lastTrust = nil, onFlagUI = nil }
do
    local RS = game:GetService("ReplicatedStorage")
    local statsCache, statsPath = nil, ""
    local floorCache, floorSrc, floorT = nil, nil, -10
    local RS_NAME = "TonyScriptPalaceSpeed"

    local function hasSpeedStats(f) return f and (f:FindFirstChild("WalkSpeed") or f:FindFirstChild("RunSpeed")) end
    local statsRetry = 0
    local function findStats()
        if statsCache and statsCache.Parent and hasSpeedStats(statsCache) then return statsCache end
        statsCache = nil
        if os.clock() < statsRetry then return nil end      -- don't search every frame while between rounds
        statsRetry = os.clock() + 0.5
        local ch = LP.Character
        local ig = Workspace:FindFirstChild("InGamePlayers")
        local mm = ig and (ig:FindFirstChild(LP.Name) or ig:FindFirstChild(LP.DisplayName))
        local cands = { ch and ch:FindFirstChild("Stats"), mm and mm:FindFirstChild("Stats"), LP:FindFirstChild("Stats") }
        for i = 1, 3 do
            local f = cands[i]
            if hasSpeedStats(f) then
                statsCache = f
                statsPath = (f.Parent and f.Parent.Name or "?") .. "." .. f.Name
                return f
            end
        end
        return nil
    end
    local function numOf(x)
        if typeof(x) == "Instance" and x:IsA("ValueBase") then x = x.Value end
        if type(x) == "number" then return x end
        if type(x) == "string" then return tonumber(x:match("%-?%d+")) end
        return nil
    end
    local FLOOR_NAMES = { "Floor", "CurrentFloor", "FloorNumber", "FloorNum", "FloorLevel" }
    local function floorIn(root)
        for _, n in ipairs(FLOOR_NAMES) do
            local a = numOf(root:GetAttribute(n))
            if a then return a, root.Name .. "." .. n end
            local c = root:FindFirstChild(n)
            local v = c and numOf(c)
            if v then return v, root.Name .. "." .. n end
        end
        return nil
    end
    local function detectFloor()
        local info = Workspace:FindFirstChild("Info")           -- the game keeps the floor in Workspace.Info.Floor
        local fv = info and info:FindFirstChild("Floor")
        local fnum = fv and numOf(fv)
        if fnum then return fnum, "Info.Floor" end
        local roots = { RS, Workspace, LP }
        if LP.Character then roots[#roots + 1] = LP.Character end
        if statsCache then roots[#roots + 1] = statsCache end
        for _, root in ipairs(roots) do
            local v, src = floorIn(root)
            if v then return v, src end
            for _, ch in ipairs(root:GetChildren()) do      -- one level of folders (Info, Values, ...)
                if ch:IsA("Folder") or ch:IsA("Configuration") then
                    v, src = floorIn(ch)
                    if v then return v, src end
                end
            end
        end
        return nil, nil
    end
    local function getFloor()
        if Speed.Floor > 0 then return Speed.Floor, "Manual" end
        if os.clock() - floorT > 1.5 then floorT = os.clock(); floorCache, floorSrc = detectFloor() end
        return floorCache, floorSrc
    end
    local function statNum(f, name, default)
        local v = f:FindFirstChild(name)
        local x = v and v:IsA("ValueBase") and v.Value
        if type(x) ~= "number" then x = f:GetAttribute(name) end
        if type(x) == "number" then return x end
        return default
    end

    ------------------------------------------------------------------
    -- INFINITE STAMINA ("fake sprint")
    -- The game's server decides when you sprint, so once you are out of stamina it will never
    -- report you as sprinting. Instead we watch the sprint key ourselves and, while you try to run
    -- out of stamina, write the speed a real sprint would give you, play the Run animation and
    -- show the sprint icon. Nothing is sent to the server.
    ------------------------------------------------------------------
    local fk = { char = nil, want = false, active = false, was = false, wrote = nil, lastSprint = -10, lastPress = -10,
        action = nil, conns = {}, search = 0, iconShown = false, suppress = false }
    local function touchOnly() return UIS.TouchEnabled and not UIS.KeyboardEnabled end
    local function toggleLike()                       -- true when the game's "Toggle Sprint" setting is on
        local pd = RS:FindFirstChild("PlayerData")
        local mine = pd and pd:FindFirstChild(tostring(LP.UserId))
        local st = mine and mine:FindFirstChild("SprintToggle")
        if st and st:IsA("BoolValue") and st.Value then return true end
        return touchOnly()
    end
    local function dropAction()
        for _, c in ipairs(fk.conns) do pcall(function() c:Disconnect() end) end
        table.clear(fk.conns); fk.action = nil
    end
    local function onSprintState(down)
        if down then
            if UIS:GetFocusedTextBox() then return end
            fk.lastPress = os.clock()
            if toggleLike() then fk.want = not fk.want else fk.want = true end
        elseif not toggleLike() then
            fk.want = false
        end
    end
    local function bindAction()                       -- the game's own Sprint InputAction (follows key rebinds)
        if fk.action and fk.action.Parent then return end
        if fk.action then dropAction() end
        if os.clock() < fk.search then return end
        fk.search = os.clock() + 0.5
        local ps = LP:FindFirstChild("PlayerScripts")
        local cw = ps and ps:FindFirstChild("CW_Gameplay")
        local a = cw and cw:FindFirstChild("Sprint")
        if not (a and a:IsA("InputAction")) then return end
        fk.action = a
        fk.conns[1] = a.StateChanged:Connect(onSprintState)
        local ev = RS:FindFirstChild("Events")
        ev = ev and ev:FindFirstChild("SprintEvent")
        if ev and ev:IsA("RemoteEvent") then
            -- the server cancels your sprint when stamina runs out; in toggle mode keep the intent alive
            fk.conns[2] = ev.OnClientEvent:Connect(function()
                if toggleLike() and os.clock() - fk.lastSprint < 0.75 then fk.want = true end
            end)
        end
        fk.conns[3] = UIS.WindowFocusReleased:Connect(function() if not toggleLike() then fk.want = false end end)
        if not toggleLike() then                       -- key already held when we attached
            for _, b in ipairs(a:GetChildren()) do
                if b:IsA("InputBinding") and b.KeyCode ~= Enum.KeyCode.None then
                    local ok, down = pcall(UIS.IsKeyDown, UIS, b.KeyCode)
                    if ok and down then fk.want = true end
                end
            end
        end
    end

    -- returns active (fake running right now), fatigued
    local function fakeUpdate(ch, hum, stats, gameSprint)
        if fk.char ~= ch then fk.char = ch; fk.want = false; fk.active = false; fk.wrote = nil; fk.was = false end
        bindAction()
        local now = os.clock()
        if gameSprint then fk.lastSprint = now end
        if not Stam.Infinite then fk.active = false; return false, false end
        local dec = ch:FindFirstChild("Decoding")
        local blocked = hum.Health <= 0 or ch:FindFirstChild("BoxAbilityActive") ~= nil or ch:GetAttribute("TreadmillDazed") == true
            or (dec ~= nil and dec:IsA("ObjectValue") and dec.Value ~= nil)   -- the same things that stop a real sprint
        local cur = stats:FindFirstChild("CurrentStamina")
        local fatigued = ch:GetAttribute("StaminaFatigued") == true or (cur ~= nil and cur:IsA("ValueBase") and cur.Value <= 0.01)
        if fk.suppress then fk.active = false; return false, fatigued end   -- Auto Run is resting: rest means rest
        if toggleLike() and now - fk.lastPress > 0.7 then   -- keep our toggle in step with the game's
            if gameSprint then fk.want = true
            elseif not fatigued and not fk.active then fk.want = false end
        end
        if blocked or gameSprint or not fk.want then fk.active = false
        elseif fatigued then fk.active = true end          -- once on it stays on until you stop running
        return fk.active, fatigued
    end

    -- Run animation: the game picks it from Stats.Sprinting (server controlled), so we play the Toon's own Run track
    local an = { track = nil, ch = nil, variant = nil }
    local function stopRun()
        local t = an.track
        if t and t.IsPlaying then pcall(function() t:Stop(0.2) end) end
    end
    local function pickRun(ch, variant)
        local anims = ch:FindFirstChild("Animations")
        if not anims then return nil end
        local sets = { base = {}, transform = {} }
        for _, a in ipairs(anims:GetChildren()) do
            if a:IsA("Animation") and a.AnimationId ~= "" and a.AnimationId ~= "rbxassetid://0" then
                local n = (a.Name:match("^(%a+)_%d+$") or a.Name):lower()
                local v = "base"
                if #n > 9 and n:sub(1, 9) == "transform" then v = "transform"; n = n:sub(10) end
                if n == "run" then local l = sets[v]; l[#l + 1] = a end
            end
        end
        local l = (#sets[variant] > 0) and sets[variant] or sets.base
        return l[1] and l[math.random(#l)] or nil
    end
    local function runAnim(ch, hum, play)
        local animator = hum:FindFirstChildOfClass("Animator")
        local moving = false
        if play and animator then
            local root = hum.RootPart
            local v = root and root.AssemblyLinearVelocity
            moving = hum.MoveDirection.Magnitude > 0.01 and v ~= nil and Vector3.new(v.X, 0, v.Z).Magnitude > 0.5
        end
        if not moving then stopRun(); return end
        local variant = ch:GetAttribute("Transformed") and "transform" or "base"
        if an.ch ~= ch or an.variant ~= variant or not an.track then
            stopRun(); an.track = nil
            local src = pickRun(ch, variant)
            if not src then return end
            local ok, tr = pcall(animator.LoadAnimation, animator, src)
            if not ok or not tr then return end
            tr.Priority = Enum.AnimationPriority.Action   -- above the walk track the game keeps playing
            tr.Looped = true
            an.track, an.ch, an.variant = tr, ch, variant
        end
        local tr = an.track
        if not tr.IsPlaying then tr:Play(0.2) end
        local runA = ch.Animations:FindFirstChild("Run")
        local ov = runA and runA:FindFirstChild("RunOverride")
        local sp = (ov and (ov:IsA("NumberValue") or ov:IsA("IntValue"))) and ov.Value or 1
        if tr.Speed ~= sp then tr:AdjustSpeed(sp) end
    end

    -- Sprint icon (the game shows it while you really sprint)
    local function setIcon(show, gameSprint)
        if not show and not fk.iconShown then return end
        if touchOnly() then return end
        local pg = LP:FindFirstChild("PlayerGui")
        local sg = pg and pg:FindFirstChild("ScreenGui")
        local ic = sg and sg:FindFirstChild("SprintIcon")
        if not (ic and ic:IsA("GuiObject")) then return end
        if show then
            ic.Visible = true; fk.iconShown = true
        else
            fk.iconShown = false
            if not gameSprint then ic.Visible = false end
        end
    end

    -- Stamina bar: while Infinite Stamina is on it is shown full unless "Show Actual Stamina" is on.
    -- Post-alpha HUD: PlayerGui.HUD.LeftStatus.Stamina holds "Bars" (Bar1 is the base segment, Bar2.. are extra
    -- segments; each segment's Fill.Display.ImageLabel has a UIGradient whose Offset runs -0.5 (empty) to 0.5 (full))
    -- and "Label" ("133 / 185"). The game keeps tweening all of that whenever real stamina changes, so fighting those
    -- writes every frame flickers. Instead we hide the game's Bars + Label and show clones the game never touches,
    -- parented inside the same Stamina frame (so they follow it if the game hides or moves the whole frame).
    local bar = { frame = nil, bars = nil, lbl = nil, retry = 0, faked = false, fbars = nil, flbl = nil, sig = nil, wasBars = true, wasLbl = true }
    local BAR_GREEN = Color3.fromRGB(79, 140, 0)
    local function findBar()
        if bar.frame and bar.frame.Parent and bar.bars and bar.bars.Parent and bar.lbl and bar.lbl.Parent then return true end
        bar.frame, bar.bars, bar.lbl = nil, nil, nil
        if os.clock() < bar.retry then return false end
        bar.retry = os.clock() + 0.5
        local pg = LP:FindFirstChild("PlayerGui")
        local o = pg
        for _, n in ipairs({ "HUD", "LeftStatus", "Stamina" }) do o = o and o:FindFirstChild(n) end
        if not (o and o:FindFirstChild("Bars") and o:FindFirstChild("Label")) and pg then
            o = nil   -- the HUD was reorganised: look for any Frame called Stamina that has Bars + Label (slow, so only every 3 seconds)
            bar.retry = os.clock() + 3
            for _, d in ipairs(pg:GetDescendants()) do
                if d.Name == "Stamina" and d:IsA("Frame") and d:FindFirstChild("Bars") and d:FindFirstChild("Label") then o = d; break end
            end
        end
        local b, l = o and o:FindFirstChild("Bars"), o and o:FindFirstChild("Label")
        if b and l and b:IsA("GuiObject") and l:IsA("TextLabel") then
            bar.frame, bar.bars, bar.lbl = o, b, l
            bar.retry = 0
            return true
        end
        return false
    end
    local function dropClones()
        if bar.fbars then pcall(function() bar.fbars:Destroy() end) end
        if bar.flbl then pcall(function() bar.flbl:Destroy() end) end
        bar.fbars, bar.flbl, bar.sig = nil, nil, nil
    end
    -- a fingerprint of the segment layout, so the clone is rebuilt when the game adds/removes segments (max stamina changed)
    local function barSig()
        local t = {}
        for _, c in ipairs(bar.bars:GetChildren()) do
            if c:IsA("GuiObject") and c.Name ~= "Template" then t[#t + 1] = c.Name .. ":" .. string.format("%.3f", c.Size.X.Scale) end
        end
        return table.concat(t, "|")
    end
    local function barFake(stats)
        local mx = stats:FindFirstChild("Stamina")
        local m = mx and mx:IsA("ValueBase") and mx.Value
        if type(m) ~= "number" or not findBar() then return end
        local sig = barSig()
        if not (bar.fbars and bar.flbl and bar.fbars.Parent == bar.bars.Parent and bar.flbl.Parent == bar.lbl.Parent and bar.sig == sig) then
            dropClones()
            local fb, fl = bar.bars:Clone(), bar.lbl:Clone()
            if not (fb and fl) then return end
            fb.Name, fl.Name = "TSPFakeBars", "TSPFakeLabel"
            fb.Visible, fl.Visible = true, true
            for _, seg in ipairs(fb:GetChildren()) do
                if seg:IsA("GuiObject") and seg.Name ~= "Template" then
                    local fill = seg:FindFirstChild("Fill")
                    if fill then
                        fill.Visible = true
                        for _, d in ipairs(fill:GetDescendants()) do
                            if d:IsA("ImageLabel") then d.Visible = true; d.ImageColor3 = BAR_GREEN
                            elseif d:IsA("UIGradient") and d.Parent:IsA("ImageLabel") then d.Offset = Vector2.new(0.5, 0) end   -- 0.5 = full
                        end
                    end
                    for _, n in ipairs({ "Star", "StarWhite", "Label", "LabelWhite" }) do
                        local x = seg:FindFirstChild(n)
                        if x then x.Visible = false end
                    end
                end
            end
            fb.Parent, fl.Parent = bar.bars.Parent, bar.lbl.Parent
            bar.fbars, bar.flbl, bar.sig = fb, fl, sig
        end
        if not bar.faked then bar.wasBars, bar.wasLbl = bar.bars.Visible, bar.lbl.Visible end
        bar.faked = true
        if bar.bars.Visible then bar.bars.Visible = false end
        if bar.lbl.Visible then bar.lbl.Visible = false end
        local r = math.round(m)
        local txt = r .. " / " .. r
        if bar.flbl.Text ~= txt then bar.flbl.Text = txt end
    end
    local function barRestore()
        if not bar.faked then return end
        bar.faked = false
        dropClones()
        if findBar() then bar.bars.Visible = bar.wasBars; bar.lbl.Visible = bar.wasLbl end   -- the game kept updating them while hidden
    end

    -- Auto Run On Treadmill Machines: press/release the game's own Sprint action while you are on a treadmill machine.
    -- Run until stamina drops to RunStop, rest, and start again once it climbs back to RunResume.
    local ar = { holding = false, resting = false, t = 0, lastFire = 0, scMod = nil, state = "off" }
    local function fireAction(sig)
        local a = fk.action
        if not (a and a.Parent and firesignal) then return false end
        return pcall(firesignal, a[sig])
    end
    local function clientSprinting(stats)
        if ar.scMod == nil then ar.scMod = try(require, RS.Modules.ClientUI.SprintController) or false end
        if ar.scMod and ar.scMod.isSprinting then
            local ok, v = pcall(ar.scMod.isSprinting)
            if ok then return v == true end
        end
        local sv = stats:FindFirstChild("Sprinting")
        return sv ~= nil and sv.Value == true
    end
    local function onTreadmill(ch)             -- am I working a treadmill machine (my slot of a duo machine counts)?
        local dec = ch:FindFirstChild("Decoding")
        local m = dec and dec.Value
        if typeof(m) ~= "Instance" then return false end
        local ms = m:FindFirstChild("Stats")
        local function mine(n)
            local v = ms and ms:FindFirstChild(n)
            local o = v and v.Value
            return typeof(o) == "Instance" and (o == ch or o == LP or o.Name == LP.Name)
        end
        local kind = m:GetAttribute("MinigameType")
        if mine("ActivePlayer2") and not mine("ActivePlayer") then kind = m:GetAttribute("Prompt2MinigameType") or kind end
        return kind == "MovementTreadmill"
    end
    local function autoRun(ch, stats)
        local now = os.clock()
        if now - ar.t < 0.1 then return end
        ar.t = now
        local on = Stam.AutoRun and onTreadmill(ch)
        local toggle = toggleLike()
        local sprinting = clientSprinting(stats)
        local function stopNow()
            if toggle then if sprinting then fireAction("Pressed") end else fireAction("Released") end
            ar.holding = false
        end
        if not on then
            if ar.holding then stopNow() end
            ar.holding, ar.resting, fk.suppress = false, false, false
            ar.state = Stam.AutoRun and "waiting" or "off"
            return
        end
        local curV, mxV = stats:FindFirstChild("CurrentStamina"), stats:FindFirstChild("Stamina")
        local cur = curV and tonumber(curV.Value) or 0
        local maxS = mxV and tonumber(mxV.Value) or Stam.Peak
        local stop = math.max(stamThreshold(Stam.StopMode, Stam.RunStop, maxS, Stam.StopFrac), 0)
        local resume = stamThreshold(Stam.ResumeMode, Stam.RunResume, maxS, Stam.ResumeFrac)
        if resume <= stop then resume = stop + 1 end
        ar.stopV, ar.resumeV = stop, resume
        if ar.holding then
            if cur <= stop then
                stopNow(); ar.resting = true
            elseif not sprinting and now - ar.lastFire > 0.6 then   -- the game dropped the sprint (stun, fatigue...): press again
                ar.lastFire = now
                fireAction("Pressed")
            end
        else
            if not ar.resting and cur <= stop then ar.resting = true end
            if ar.resting and cur >= resume then ar.resting = false end
            if not ar.resting then
                ar.holding = true; ar.lastFire = now
                if not (toggle and sprinting) then fireAction("Pressed") end
            elseif sprinting and now - ar.lastFire > 0.4 then       -- resting but still sprinting (your own key?): stop it again
                ar.lastFire = now
                stopNow()
            end
        end
        fk.suppress = ar.resting     -- while resting even Infinite Stamina's fake run is held back, so your numbers are respected
        ar.state = ar.holding and "running" or "resting"
    end

    ------------------------------------------------------------------
    -- SYNC ANIMATION SPEED WITH STATS (visual only, your screen only)
    --   Walk / Run : humanoid speed compared to the toon's own walk / run speed from its ModuleScript in ReplicatedStorage.TowerData
    --                (exactly that speed = normal animation speed). Falls back to your WalkSpeed / RunSpeed stats if the module has none.
    --   Decode     : the extraction animation follows DecodeSpeedModifier.
    --   Ability    : ability animations follow your walk / run ratio while you move, and your decode speed while you extract.
    --   Idle (and everything else) is never touched.
    -- The game's own track speed is remembered per track, so nothing compounds and turning it off puts everything back.
    ------------------------------------------------------------------
    local as = { orig = setmetatable({}, { __mode = "k" }), wrote = setmetatable({}, { __mode = "k" }), names = {}, ch = nil, active = false, base = nil }
    SP.animSt = { on = false, text = "Off" }
    local WALK_KEYS = { "walkspeed", "basewalkspeed", "walk", "speed" }
    local RUN_KEYS = { "runspeed", "baserunspeed", "sprintspeed", "run" }
    local function tdNumber(data, keys)
        for _, scope in ipairs({ data, data.Stats, data.BaseStats, data.Config }) do
            if type(scope) == "table" then
                local lower = {}
                for k, v in pairs(scope) do if type(k) == "string" and type(v) == "number" then lower[k:lower()] = v end end
                for _, k in ipairs(keys) do if lower[k] then return lower[k] end end
            end
        end
    end
    local function toonModule(ch)
        local cfg = ch:FindFirstChild("Config")
        local mv = cfg and cfg:FindFirstChild("ModuleName")
        local n = (mv and mv:IsA("ValueBase") and mv.Value) or ch:GetAttribute("ModuleName")
        if type(n) ~= "string" or n == "" then
            local cn = cfg and cfg:FindFirstChild("CharacterName")
            n = (cn and cn:IsA("ValueBase") and cn.Value) or ch:GetAttribute("ToonName")
        end
        return type(n) == "string" and n ~= "" and n or nil
    end
    local function animBase(ch, stats)     -- the toon's normal walk / run speed, read once per character
        if as.base and as.base.ch == ch then return as.base end
        local b = { ch = ch, info = "no TowerData module for this toon, using your WalkSpeed / RunSpeed stats" }
        local mod = toonModule(ch)
        local td = RS:FindFirstChild("TowerData")
        local tm = td and mod and td:FindFirstChild(mod)
        if tm and tm:IsA("ModuleScript") then
            local ok, data = pcall(require, tm)
            if ok and type(data) == "table" then
                b.walk, b.run = tdNumber(data, WALK_KEYS), tdNumber(data, RUN_KEYS)
                if b.walk and b.run then
                    b.info = string.format("TowerData.%s: walk %s, run %s", mod, tostring(b.walk), tostring(b.run))
                else
                    local keys = {}
                    for k in pairs(data) do if #keys < 8 then keys[#keys + 1] = tostring(k) end end
                    b.info = "TowerData." .. mod .. " has no walk / run speed I can read (keys: " .. table.concat(keys, ", ") .. "), using your stats"
                end
            else
                b.info = "could not read TowerData." .. mod .. ", using your stats"
            end
        end
        as.base = b
        return b
    end
    local function animClass(n)     -- exact names only: Walk, Run, Decode, Ability (with the game's _1 / Transform variants)
        n = tostring(n):lower():gsub("_%d+$", "")
        if n:sub(1, 9) == "transform" then n = n:sub(10) end
        if n:find("idle", 1, true) then return nil end
        if n == "walk" then return "Walk" elseif n == "run" then return "Run" elseif n == "decode" then return "Decode"
        elseif n:sub(1, 7) == "ability" then return "Ability" end
        return nil
    end
    local function animKind(ch, tr)
        local a = tr.Animation
        local id = a and a.AnimationId
        if not id or id == "" then return nil end
        local n = as.names[id]
        if n == nil then
            n = false
            local an = ch:FindFirstChild("Animations")
            if an then
                for _, x in ipairs(an:GetChildren()) do
                    if x:IsA("Animation") and x.AnimationId == id then n = x.Name; break end
                end
            end
            if not n and a.Name ~= "Animation" then n = a.Name end
            as.names[id] = n
        end
        return n and animClass(n) or nil
    end
    local function animRestore()
        if not as.active then return end
        as.active = false
        for tr, w in pairs(as.wrote) do
            local o = as.orig[tr]
            pcall(function() if o and tr.Speed == w then tr:AdjustSpeed(o) end end)
        end
        table.clear(as.wrote); table.clear(as.orig)
        SP.animSt = { on = false, text = "Off" }
    end
    SP.animRestore = animRestore
    local function animSync(ch, hum, stats, running)
        local A = Speed.Anim
        local animator = hum:FindFirstChildOfClass("Animator")
        if not (A.On and animator) then animRestore(); return end
        if as.ch ~= ch then as.ch = ch; as.names = {}; as.base = nil end
        local base = animBase(ch, stats)
        local hs = hum.WalkSpeed
        local wBase = base.walk or statNum(stats, "WalkSpeed", hs)
        local rBase = base.run or statNum(stats, "RunSpeed", hs)
        local wm = math.clamp(hs / math.max(wBase, 0.01), 0.25, 3)
        local rm = math.clamp(hs / math.max(rBase, 0.01), 0.25, 3)
        if running then wm = 1 else rm = 1 end   -- only the state you are in follows your speed, so a fading Walk or Run track is not stretched
        local dm = math.clamp(statNum(stats, "DecodeSpeedModifier", 1), 0.25, 3)
        local moving = hum.MoveDirection.Magnitude > 0.01
        local dec = ch:FindFirstChild("Decoding")
        local decoding = dec ~= nil and dec:IsA("ObjectValue") and dec.Value ~= nil
        local abilityM = nil
        if A.Ability then
            if decoding then abilityM = dm elseif moving then abilityM = running and rm or wm end
        end
        local mult = { Walk = wm, Run = rm, Decode = dm, Ability = abilityM }
        local seen = {}
        for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
            local kind = animKind(ch, tr)
            local m = kind and mult[kind]
            if m then
                local lastW = as.wrote[tr]
                if lastW == nil or math.abs(tr.Speed - lastW) > 1e-4 then as.orig[tr] = tr.Speed end   -- first time we see it, or the game changed it
                local want = as.orig[tr] * m
                if math.abs(tr.Speed - want) > 1e-4 then tr:AdjustSpeed(want) end
                as.wrote[tr] = want
                if tr.WeightCurrent > 0.05 then seen[kind] = m end
            else
                local lastW = as.wrote[tr]            -- a track we changed earlier that no longer qualifies (ability ended or you stopped): back to normal
                if lastW ~= nil and as.orig[tr] then
                    if tr.Speed == lastW then tr:AdjustSpeed(as.orig[tr]) end
                    as.wrote[tr] = nil; as.orig[tr] = nil
                end
            end
        end
        as.active = true
        local parts = {}
        for _, k in ipairs({ "Walk", "Run", "Decode", "Ability" }) do if seen[k] then parts[#parts + 1] = string.format("%s x%.2f", k, seen[k]) end end
        SP.animSt = { on = true, text = (#parts > 0 and ("Syncing: " .. table.concat(parts, ", ")) or "On, waiting for a walk, run or extraction animation") .. "  |  Base speeds from " .. base.info }
    end

    local function step()
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local stats = findStats()
        if not (hum and stats) then
            SP.last = { ok = false }
            fk.active, fk.was = false, false
            pcall(stopRun); pcall(setIcon, false, false)
            return
        end
        local hObj, sObj = stats:FindFirstChild("HoldingSprint"), stats:FindFirstChild("Sprinting")
        local holding, sprinting = hObj and hObj.Value == true, sObj and sObj.Value == true
        local running
        if hObj and sObj then running = holding and sprinting elseif sObj then running = sprinting else running = holding and true or false end
        -- Infinite Stamina: out of stamina but trying to run -> use the run speed (so your Run adjustments apply too)
        local okF, fake, fatigued = pcall(fakeUpdate, ch, hum, stats, sprinting)
        if not okF then fake, fatigued = false, false end
        if fake then running = true end
        local dazed = Fun.dazed()                                   -- fake treadmill Dazed: no sprinting
        if dazed then running = false end
        local base = statNum(stats, running and "RunSpeed" or "WalkSpeed", nil)
        if not base then SP.last = { ok = false }; return end
        local mod = statNum(stats, running and "RunSpeedModifier" or "SpeedModifier", 1)
        local vanilla = base * mod
        -- extra skill check rewards/penalties: flat units + a percent of the base speed go into the base, multipliers into the game's own modifier
        local fFlat, fPct, fMul = Fun.mods(running)
        local scOn = dazed or fFlat ~= 0 or fPct ~= 0 or fMul ~= 1
        if scOn then base = math.max(base + fFlat + base * fPct, 0); mod = mod * fMul end
        local scSpeed = math.max(base * mod, 0)
        SP.scOn = scOn
        local floor, src = getFloor()
        floor = floor and math.floor(floor)
        local odd, even = floor and floor % 2 ~= 0, floor and floor % 2 == 0
        local key = running and "Run" or "Walk"
        local final
        if Speed.Mode == "Additive" then
            local A = Speed.Add
            final = (base + A[key .. "All"] + (odd and A[key .. "Odd"] or 0) + (even and A[key .. "Even"] or 0)) * mod
        else
            local M = Speed.Mul
            final = base * mod * (1 + M[key .. "All"] / 100) * (odd and (1 + M[key .. "Odd"] / 100) or 1) * (even and (1 + M[key .. "Even"] / 100) or 1)
        end
        final = math.max(final, 0)
        if not Speed.Enabled then final = scSpeed end           -- speed modifier off: the game's speed plus the skill check effects only
        -- limits: a manual cap, and/or a limit learned after the anti-cheat flagged you at a higher speed
        local state = running and "Run" or "Walk"
        local limit, limitSource = nil, nil
        if Speed.Cap and Speed.Limit > 0 then limit, limitSource = Speed.Limit, "your manual limit" end
        if Speed.Auto then
            local L = SP.learned[state]
            if L then
                if math.abs(L.vanilla - vanilla) > 0.5 then
                    SP.learned[state] = nil                      -- your stats changed, so the old limit no longer applies
                elseif not limit or L.limit < limit then
                    limit, limitSource = L.limit, "the limit learned after a flag"
                end
            end
        end
        local capped = false
        if limit and final > limit then final = math.max(limit, 0); capped = true end
        -- remember the highest boosted speed of the last few seconds (used when a flag happens)
        local pk = SP.peak[state]
        if not pk or os.clock() - pk.t > 3 or final > pk.v then SP.peak[state] = { v = final, t = os.clock(), vanilla = vanilla } end
        -- the game exposes a speed trust score; when it drops, the anti-cheat flagged you
        local trust = LP:GetAttribute("KM_SPEED_TRUST_SCORE")
        if type(trust) == "number" then
            if SP.lastTrust and trust < SP.lastTrust then SP.onFlag(SP.lastTrust, trust) end
            SP.lastTrust = trust
        end
        -- fake running without the speed modifier writes the plain run speed; with it, your adjusted run speed
        local target = (fake and not Speed.Enabled and not scOn) and vanilla or final
        if (Speed.Enabled or fake or scOn) and hum.WalkSpeed > 0.01 and vanilla > 0 then   -- 0 = stunned/frozen, leave it alone
            hum.WalkSpeed = target
            if fake then fk.wrote = target end
        end
        if fk.was and not fake then
            -- fake run ended: the server will not resend the walk speed on its own, so put it back
            if not Speed.Enabled and not sprinting and fk.wrote and math.abs(hum.WalkSpeed - fk.wrote) < 0.01 then
                local w = statNum(stats, "WalkSpeed", nil)
                if w then hum.WalkSpeed = w * statNum(stats, "SpeedModifier", 1) end
            end
            fk.wrote = nil
        end
        fk.was = fake
        if SP.scWas and not scOn and not Speed.Enabled and not fake and not sprinting and hum.WalkSpeed > 0.01 then
            hum.WalkSpeed = vanilla                                -- skill check effect ended: the server will not resend the speed
        end
        SP.scWas = scOn and not Speed.Enabled
        pcall(animSync, ch, hum, stats, running)
        pcall(function()
            runAnim(ch, hum, fake)
            setIcon(fake and Stam.Icon, sprinting)
            if Stam.Infinite and not Stam.ShowActual then barFake(stats) else barRestore() end
            autoRun(ch, stats)
        end)
        local sc, sm = stats:FindFirstChild("CurrentStamina"), stats:FindFirstChild("Stamina")
        do   -- learn the highest stamina we have seen (the maximum for the Auto Run sliders)
            local seen = math.max(sm and tonumber(sm.Value) or 0, sc and tonumber(sc.Value) or 0, statNum(stats, "OriginalStamina", 0) * statNum(stats, "StaminaModifier", 1))
            if seen > Stam.Peak and seen < 100000 then Stam.Peak = seen end
        end
        SP.last = { ok = true, running = running, base = base, mod = mod, vanilla = vanilla, final = final, capped = capped,
            floor = floor, floorSrc = src, statsPath = statsPath, humSpeed = hum.WalkSpeed,
            limit = limit, limitSource = limitSource, trust = trust,
            fake = fake, fatigued = fatigued, stam = sc and sc.Value, stamMax = sm and sm.Value, autoRun = ar.state, autoStop = ar.stopV, autoResume = ar.resumeV }
    end
    pcall(function() RunService:UnbindFromRenderStep(RS_NAME) end)
    local warned = false
    RunService:BindToRenderStep(RS_NAME, Enum.RenderPriority.Last.Value, function()
        if not alive then return end
        local ok, err = pcall(step)
        if not ok and not warned then warned = true; warn("[Tony Script Palace Speed] " .. tostring(err)) end
    end)
    ------------------------------------------------------------------
    -- NOCLIP (World tab). Turns off collision on the map, not on you:
    --   * everything named NoClip, NoClip_Collider, InvisBlock, InvisWall or CylinderCollider (and anything with a name you add),
    --   * every part inside a "Walls" folder/model EXCEPT floors, so walls, columns and window frames stop blocking
    --     you but you do not fall through the ground,
    --   * inside Labs' LabsFakeElevator only: DoorHitbox, DoorVisible and the whole ElevatorDoor model.
    -- Original values are remembered and restored, new parts (new rooms) are caught as they appear, and the game
    -- turning collision back on is undone.
    ------------------------------------------------------------------
    local NC_NAMES = { NoClip = true, NoClip_Collider = true, InvisBlock = true, InvisWall = true, CylinderCollider = true }
    local nc = { on = false, walls = true, extra = {}, parts = {}, boxes = {}, boxCons = {}, conns = {}, gen = 0, accP = 0, accB = 0 }
    local function ncWanted(name) return NC_NAMES[name] or nc.extra[name] end
    local NC_KEEP = { "floor", "stair", "ramp", "ground" }      -- names (of the part or its folder) that stay solid
    local function ncIsFloor(part)            -- stays solid: named like a floor/stairs, or a THIN horizontal slab
        local n = part.Name:lower()
        local pn = part.Parent and part.Parent.Name:lower() or ""
        for _, k in ipairs(NC_KEEP) do
            if n:find(k, 1, true) or pn:find(k, 1, true) then return true end
        end
        local cf, sz = part.CFrame, part.Size
        local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
        local h  = math.abs(r.Y) * sz.X + math.abs(u.Y) * sz.Y + math.abs(l.Y) * sz.Z
        local ex = math.abs(r.X) * sz.X + math.abs(u.X) * sz.Y + math.abs(l.X) * sz.Z
        local ez = math.abs(r.Z) * sz.X + math.abs(u.Z) * sz.Y + math.abs(l.Z) * sz.Z
        return h <= 4 and h < math.min(ex, ez)      -- thick blocks and tall walls are NOT floors
    end
    local function ncTrack(part)
        if nc.parts[part] == nil then nc.parts[part] = part.CanCollide end
        if part.CanCollide then part.CanCollide = false end
    end
    local function ncBox(box, kind)           -- kind "all": every part; "walls": every part that is not a floor
        nc.boxes[box] = kind
        for _, d in ipairs(box:GetDescendants()) do
            if d:IsA("BasePart") and (kind == "all" or not ncIsFloor(d)) then ncTrack(d) end
        end
        if not nc.boxCons[box] then               -- new parts are caught by event instead of re-walking the folder every second
            nc.boxCons[box] = box.DescendantAdded:Connect(function(d)
                if d:IsA("BasePart") and (kind == "all" or not ncIsFloor(d)) then ncTrack(d) end
            end)
        end
    end
    -- Labs' decorative elevator (LabsFakeElevator): its DoorHitbox, its DoorVisible and everything in its ElevatorDoor model.
    -- These names are only matched INSIDE it, because the real elevator (Workspace.Elevators.Elevator) has a DoorHitbox and a
    -- DoorVisible too and keeps its collision.
    local NC_FAKE_ELEVATOR = "LabsFakeElevator"
    local NC_FAKE_PARTS = { DoorHitbox = true, DoorVisible = true }
    local function ncFakeElevator(box)
        local function consider(d)
            if NC_FAKE_PARTS[d.Name] and d:IsA("BasePart") then ncTrack(d)
            elseif d.Name == "ElevatorDoor" and (d:IsA("Model") or d:IsA("Folder")) then ncBox(d, "all") end
        end
        for _, d in ipairs(box:GetDescendants()) do pcall(consider, d) end
        if not nc.boxCons[box] then               -- parts that stream in later; cleaned up by ncStop with the other box connections
            nc.boxCons[box] = box.DescendantAdded:Connect(function(d) pcall(consider, d) end)
        end
    end
    local function ncMatch(inst)
        if ncWanted(inst.Name) then
            if inst:IsA("BasePart") then ncTrack(inst)
            elseif inst:IsA("Model") or inst:IsA("Folder") then ncBox(inst, "all") end
        elseif inst.Name == NC_FAKE_ELEVATOR and (inst:IsA("Model") or inst:IsA("Folder")) then
            ncFakeElevator(inst)
        elseif nc.walls and inst.Name == "Walls" and (inst:IsA("Model") or inst:IsA("Folder")) then
            ncBox(inst, "walls")
        end
    end
    local function ncInteresting(name) return ncWanted(name) or name == NC_FAKE_ELEVATOR or (nc.walls and name == "Walls") end
    local function ncScan(gen)                -- one pass over what already exists, in slices so it never hitches
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if nc.gen ~= gen or not alive then return end
            if ncInteresting(d.Name) then pcall(ncMatch, d) end
            n += 1
            if n % 4000 == 0 then task.wait() end
        end
    end
    local function ncStart()
        nc.gen += 1
        local gen = nc.gen
        nc.conns[1] = Workspace.DescendantAdded:Connect(function(d)
            if ncInteresting(d.Name) then pcall(ncMatch, d) end
        end)
        task.spawn(ncScan, gen)
        nc.conns[2] = RunService.Heartbeat:Connect(function(dt)
            nc.accP += dt; nc.accB += dt
            if nc.accP >= 0.25 then                                  -- keep tracked parts off
                nc.accP = 0
                for part in pairs(nc.parts) do
                    if part.Parent == nil then nc.parts[part] = nil
                    elseif part.CanCollide then part.CanCollide = false end
                end
            end
            if nc.accB >= 5 then                                     -- slow safety net (new parts are mostly caught by box.DescendantAdded)
                nc.accB = 0
                for box, kind in pairs(nc.boxes) do
                    if box.Parent == nil then
                        nc.boxes[box] = nil
                        local bc = nc.boxCons[box]
                        if bc then pcall(function() bc:Disconnect() end); nc.boxCons[box] = nil end
                    else
                        for _, d in ipairs(box:GetDescendants()) do
                            if d:IsA("BasePart") and nc.parts[d] == nil and (kind == "all" or not ncIsFloor(d)) then ncTrack(d) end
                        end
                    end
                end
            end
        end)
    end
    local function ncStop()
        nc.gen += 1
        for _, c in ipairs(nc.conns) do pcall(function() c:Disconnect() end) end
        table.clear(nc.conns)
        for _, bc in pairs(nc.boxCons) do pcall(function() bc:Disconnect() end) end
        table.clear(nc.boxCons)
        for part, was in pairs(nc.parts) do
            if part.Parent then pcall(function() part.CanCollide = was end) end
        end
        table.clear(nc.parts); table.clear(nc.boxes)
    end
    local function ncRestart() if nc.on then ncStop(); ncStart() end end
    function SP.setNoclip(on)
        on = on and true or false
        if on == nc.on then return end
        nc.on = on
        if on then ncStart() else ncStop() end
    end
    function SP.setNoclipWalls(v) v = v and true or false; if v ~= nc.walls then nc.walls = v; ncRestart() end end
    function SP.setNoclipNames(txt)             -- comma separated extra names, exact match
        local set = {}
        for name in tostring(txt or ""):gmatch("[^,]+") do
            name = name:match("^%s*(.-)%s*$")
            if name ~= "" then set[name] = true end
        end
        nc.extra = set
        ncRestart()
    end
    function SP.noclipOn() return nc.on end
    function SP.noclipWalls() return nc.walls end
    function SP.noclipCount() local n = 0; for _ in pairs(nc.parts) do n += 1 end; return n end

    ------------------------------------------------------------------
    -- FAKE BLACKOUT (World tab). Copies what a real blackout does, read from a live one:
    --   Lighting: ambient / outdoor ambient / color shifts black, black fog that ends at 100 studs, ClockTime 0
    --   every light in the room gets Range 0, except Twisteds' own lights (read from a real blackout: all but the Twisted's light were at 0).
    --   The elevator's own lights stay lit, like the real thing. The neon bulb parts in the room's Lights folder are switched to plain plastic so they stop glowing.
    --   Twisted eyes: their head SurfaceAppearances (Normal / Blink / Attack) get EmissiveStrength = the game's EmissiveEyeStrength (30), only during blackouts
    --   Toon lights: every toon gets a local TempLight PointLight (range 25, brightness 1, grey), like the one the game gives them
    -- Modes: Off | Every Floor (starts when you step onto a floor, ends with the floor) | Always.
    -- It never runs while the game's own blackout (workspace.Info.BlackOut) is on: it lets go WITHOUT restoring anything, so it can't fight the game.
    -- Same trick as the animation sync: the last value the game wrote is remembered per property / light, so ending it puts back what the game wanted.
    ------------------------------------------------------------------
    local LightingS = game:GetService("Lighting")
    local SoundS = game:GetService("SoundService")
    local DARK = Color3.new(0, 0, 0)
    local BO_TARGET = { Ambient = DARK, OutdoorAmbient = DARK, ColorShift_Bottom = DARK, ColorShift_Top = DARK, FogColor = DARK, FogEnd = 100, ClockTime = 0 }
    local EYE_NAMES = { Normal = true, Blink = true, Attack = true }
    local bo = { on = false, floorRun = false, armed = true, orig = {}, wrote = {}, lights = {}, scanAt = 0, status = "Off",
        lorig = setmetatable({}, { __mode = "k" }), lwrote = setmetatable({}, { __mode = "k" }),
        eyes = {}, eyeAt = 0, saorig = setmetatable({}, { __mode = "k" }), sawrote = setmetatable({}, { __mode = "k" }),
        toon = {}, toonAt = 0, bulbs = {}, borig = setmetatable({}, { __mode = "k" }), bwrote = setmetatable({}, { __mode = "k" }) }
    local function boRelease(restore)
        if not bo.on then return end
        bo.on = false
        if restore then
            for p, w in pairs(bo.wrote) do
                local o = bo.orig[p]
                pcall(function() if o ~= nil and LightingS[p] == w then LightingS[p] = o end end)
            end
            for l, w in pairs(bo.lwrote) do
                local o = bo.lorig[l]
                pcall(function() if o and l.Parent and l.Range == w then l.Range = o end end)
            end
        end
        if restore then
            for sa, w in pairs(bo.sawrote) do
                local o = bo.saorig[sa]
                pcall(function() if o ~= nil and sa.Parent and sa.EmissiveStrength == w then sa.EmissiveStrength = o end end)
            end
        end
        if restore then
            for p, o in pairs(bo.bwrote) do
                local orig = bo.borig[p]
                pcall(function() if orig and p.Parent and p.Material == Enum.Material.Plastic then p.Material = orig end end)
            end
        end
        table.clear(bo.bwrote); table.clear(bo.borig); bo.bulbs = {}
        for _, a in ipairs(bo.toon) do pcall(function() a:Destroy() end) end   -- our own lights always go, the game has its own during a real blackout
        table.clear(bo.orig); table.clear(bo.wrote); table.clear(bo.lorig); table.clear(bo.lwrote); table.clear(bo.sawrote); table.clear(bo.saorig)
        bo.lights = {}; bo.eyes = {}; bo.toon = {}
        bo.scanAt, bo.eyeAt, bo.toonAt = 0, 0, 0     -- so the next start applies on its very first frame
    end
    local function boScan()
        local found, bulbs = {}, {}
        local cr = Workspace:FindFirstChild("CurrentRoom")
        if cr then
            for _, room in ipairs(cr:GetChildren()) do
                local mons = room:FindFirstChild("Monsters")
                for _, d in ipairs(room:GetDescendants()) do
                    if d:IsA("Light") and not (mons and d:IsDescendantOf(mons)) then found[#found + 1] = d end
                end
                local lf = room:FindFirstChild("Lights")
                if lf and Speed.Blackout.Bulbs then
                    for _, d in ipairs(lf:GetDescendants()) do
                        if d:IsA("BasePart") and d.Material == Enum.Material.Neon then bulbs[#bulbs + 1] = d end
                    end
                end
            end
        end
        bo.lights, bo.bulbs = found, bulbs
    end
    local function boEyes()
        local info = Workspace:FindFirstChild("Info")
        local str = 30
        if info then
            if info:GetAttribute("EmissiveAggroBoost") then str = tonumber(info:GetAttribute("EmissiveAggroStrength")) or 50
            else str = tonumber(info:GetAttribute("EmissiveEyeStrength")) or 30 end
        end
        if os.clock() >= bo.eyeAt then
            bo.eyeAt = os.clock() + 0.25
            local found = {}
            local cr = Workspace:FindFirstChild("CurrentRoom")
            if cr then
                for _, room in ipairs(cr:GetChildren()) do
                    local mons = room:FindFirstChild("Monsters")
                    if mons then
                        for _, d in ipairs(mons:GetDescendants()) do
                            if d:IsA("SurfaceAppearance") and EYE_NAMES[d.Name] then found[#found + 1] = d end
                        end
                    end
                end
            end
            bo.eyes = found
        end
        for _, sa in ipairs(bo.eyes) do
            if sa.Parent then
                local cur = sa.EmissiveStrength
                if bo.sawrote[sa] == nil or cur ~= bo.sawrote[sa] then bo.saorig[sa] = cur end
                if cur ~= str then sa.EmissiveStrength = str end
                bo.sawrote[sa] = str
            end
        end
    end
    local function boToonLights()
        if os.clock() < bo.toonAt then return end
        bo.toonAt = os.clock() + 0.5
        local ig = Workspace:FindFirstChild("InGamePlayers")
        if not ig then return end
        for _, ch in ipairs(ig:GetChildren()) do
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hrp and not hrp:FindFirstChild("TSP_TempLight") then
                local att = Instance.new("Attachment")
                att.Name = "TSP_TempLight"
                local pl = Instance.new("PointLight")
                pl.Range = 25; pl.Brightness = 1; pl.Color = Color3.fromRGB(135, 135, 135); pl.Shadows = false
                pl.Parent = att
                att.Parent = hrp
                bo.toon[#bo.toon + 1] = att
            end
        end
    end
    local function boApply()
        for p, v in pairs(BO_TARGET) do
            local cur = LightingS[p]
            if bo.wrote[p] == nil or cur ~= bo.wrote[p] then bo.orig[p] = cur end   -- first time, or the game changed it
            if cur ~= v then LightingS[p] = v end
            bo.wrote[p] = v
        end
        if os.clock() >= bo.scanAt then bo.scanAt = os.clock() + 2; boScan() end
        for _, l in ipairs(bo.lights) do
            if l.Parent then
                local r = l.Range
                if bo.lwrote[l] == nil or r ~= bo.lwrote[l] then bo.lorig[l] = r end
                if r ~= 0 then l.Range = 0 end
                bo.lwrote[l] = 0
            end
        end
        for _, p in ipairs(bo.bulbs) do
            if p.Parent then
                local m = p.Material
                if bo.bwrote[p] == nil or m ~= bo.bwrote[p] then bo.borig[p] = m end
                if m ~= Enum.Material.Plastic then p.Material = Enum.Material.Plastic end
                bo.bwrote[p] = Enum.Material.Plastic
            end
        end
        if Speed.Blackout.Eyes then boEyes() end
        if Speed.Blackout.Lights then boToonLights() end
    end
    local function boStep()
        local B = Speed.Blackout
        if B.Mode == "Off" and not bo.on then bo.status = "Off"; return end
        local info = Workspace:FindFirstChild("Info")
        local realV = info and info:FindFirstChild("BlackOut")
        local real = realV ~= nil and realV.Value == true
        local fa = info and info:FindFirstChild("FloorActive")
        local active = fa ~= nil and fa.Value == true
        local stats = findStats()
        local ie = stats and stats:FindFirstChild("InElevator")
        local inElev = ie ~= nil and ie.Value == true
        if B.Mode ~= "Every Floor" or not active then
            bo.floorRun = false; bo.armed = true
        elseif real then
            bo.floorRun = false; bo.armed = false            -- the game already gave you a blackout this floor, so no fake one on top
        elseif bo.armed and not inElev then
            bo.floorRun = true; bo.armed = false             -- you just stepped onto the floor
        end
        local want = (B.Mode == "Always" or (B.Mode == "Every Floor" and bo.floorRun)) and not real
        if real and bo.on then boRelease(false) end           -- the real one takes over, hands off
        if want then
            if not bo.on then
                bo.on = true
                if B.Sound then pcall(function() SoundS:PlayLocalSound(Workspace.Blackout.PowerOut) end) end
            end
            boApply()
            bo.status = (B.Mode == "Always") and "Fake blackout is on (always)" or "Fake blackout is on for this floor"
        else
            boRelease(true)
            if B.Mode == "Off" then bo.status = "Off"
            elseif real then bo.status = "The game's own blackout is running, so the fake one is staying out of it"
            elseif active and inElev then bo.status = "Waiting for you to step onto the floor"
            else bo.status = "Waiting for the next floor" end
        end
    end
    connect(RunService.Heartbeat, function() pcall(boStep) end)
    function SP.blackoutStatus() return bo.status end

    ------------------------------------------------------------------
    -- FULLBRIGHT (World tab). Raises the ambient light, turns global shadows off and pushes the fog out of sight.
    -- Same trick as the fake blackout: the last value the game wrote is remembered per property, so turning it off (or the game
    -- changing a property on its own, e.g. at the start of a floor) puts back what the game wanted instead of what we wrote.
    -- It does not touch the room's own lights, so the game's real blackout (lights at range 0) is simply brightened by the ambient light.
    ------------------------------------------------------------------
    local fb = { on = false, level = 100, active = false, orig = {}, wrote = {} }
    local function fbSame(a, b)
        if typeof(a) == "Color3" and typeof(b) == "Color3" then
            return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
        end
        return a == b
    end
    local function fbTargets()
        local v = math.round(math.clamp(fb.level, 0, 100) * 2.55) / 255
        local c = Color3.new(v, v, v)
        return { Ambient = c, OutdoorAmbient = c, GlobalShadows = false, FogEnd = 100000 }
    end
    local function fbRelease(restore)
        if restore then
            for p, w in pairs(fb.wrote) do
                local o = fb.orig[p]
                pcall(function() if o ~= nil and fbSame(LightingS[p], w) then LightingS[p] = o end end)
            end
        end
        table.clear(fb.orig); table.clear(fb.wrote)
        fb.active = false
    end
    local function fbStep()
        if fb.on then
            fb.active = true
            for p, v in pairs(fbTargets()) do
                local cur = LightingS[p]
                if fb.wrote[p] == nil or not fbSame(cur, fb.wrote[p]) then fb.orig[p] = cur end   -- first time, or the game changed it
                if not fbSame(cur, v) then LightingS[p] = v end
                fb.wrote[p] = v
            end
        elseif fb.active then
            fbRelease(true)
        end
    end
    connect(RunService.Heartbeat, function() pcall(fbStep) end)
    function SP.fullbrightOn() return fb.on end
    function SP.setFullbright(v) fb.on = v and true or false end
    function SP.fullbrightLevel() return fb.level end
    function SP.setFullbrightLevel(v) fb.level = math.clamp(tonumber(v) or 100, 0, 100) end

    ------------------------------------------------------------------
    -- ICHOR SPLATS (World tab). Stepping in an Ichor puddle splats images across the whole screen: they are the Splat labels inside the
    -- IchorScreen frame (PlayerGui.ScreenGui.IchorScreen). While this is on that frame is kept hidden; turning it off gives it back.
    ------------------------------------------------------------------
    local ich = { on = false, frame = nil, orig = true, conn = nil, hidden = false }
    local function ichRelease()
        if ich.conn then ich.conn:Disconnect(); ich.conn = nil end
        local f = ich.frame
        if f and f.Parent and ich.hidden then pcall(function() f.Visible = ich.orig end) end
        ich.frame, ich.hidden = nil, false
    end
    local function ichStep()
        if not ich.on then
            if ich.frame then ichRelease() end
            return
        end
        local pg = LP:FindFirstChild("PlayerGui")
        local sg = pg and pg:FindFirstChild("ScreenGui")
        local f = sg and sg:FindFirstChild("IchorScreen")
        if f ~= ich.frame then          -- first time, or the game rebuilt its GUI
            ichRelease()
            if not (f and f:IsA("GuiObject")) then return end
            ich.frame, ich.orig = f, f.Visible
            ich.conn = f:GetPropertyChangedSignal("Visible"):Connect(function() if ich.on and f.Visible then f.Visible = false end end)
        end
        if f.Visible then f.Visible = false end
        ich.hidden = true
    end
    connect(RunService.RenderStepped, function() pcall(ichStep) end)
    function SP.hideIchorOn() return ich.on end
    function SP.setHideIchor(v) ich.on = v and true or false end

    function SP.Unload()
        pcall(boRelease, true)
        pcall(fbRelease, true)
        pcall(ichRelease)
        pcall(SP.setNoclip, false)
        pcall(function() RunService:UnbindFromRenderStep(RS_NAME) end)
        pcall(function() if ar.holding then ar.holding = false; if toggleLike() then if clientSprinting(statsCache or LP) then fireAction("Pressed") end else fireAction("Released") end end end)
        pcall(stopRun); pcall(setIcon, false, false); pcall(barRestore); pcall(dropAction); pcall(animRestore)
    end

    -- called when the speed trust score drops. Only blames the script if you were boosted above normal speed.
    function SP.onFlag(from, to)
        if not Speed.Enabled and not SP.scOn then
            if Stam.Infinite and SP.last and SP.last.fake then
                SP.flag = { t = os.clock(), text = "fake sprint" }
                if SP.onFlagUI then
                    SP.onFlagUI(string.format("Anti-cheat flagged you (speed trust %s -> %s) while fake sprinting. Turn Infinite Stamina off if it keeps happening.", tostring(from), tostring(to)))
                end
            end
            return
        end
        local now, parts = os.clock(), {}
        for state, pk in pairs(SP.peak) do
            if now - pk.t <= 3.5 and pk.v > pk.vanilla + 0.01 then
                parts[#parts + 1] = string.format("%s %.1f", state:lower(), pk.v)
                if Speed.Auto then SP.learned[state] = { limit = math.max(pk.vanilla, pk.v * 0.9), vanilla = pk.vanilla } end
            end
        end
        if #parts == 0 then return end
        SP.flag = { t = now, text = table.concat(parts, ", ") }
        if SP.onFlagUI then
            SP.onFlagUI(string.format("Anti-cheat flagged you (speed trust %s -> %s) at %s.%s", tostring(from), tostring(to),
                SP.flag.text, Speed.Auto and " Backing off." or " Lower your speed."))
        end
    end
    function SP.flagText()
        local f = SP.flag
        return f and string.format("%ds ago (%s)", math.floor(os.clock() - f.t), f.text) or "None"
    end
    function SP.learnedText()
        local w, r = SP.learned.Walk, SP.learned.Run
        if not (w or r) then return "None" end
        return string.format("Walk %s  Run %s", w and string.format("%.1f", w.limit) or "-", r and string.format("%.1f", r.limit) or "-")
    end

    function SP.stamStatus()
        local l = SP.last
        if not (l and l.ok) then return "info", "Waiting for your character and Stats folder..." end
        if Stam.AutoRun and (l.autoRun == "running" or l.autoRun == "resting") then
            return "safe", string.format("Auto running on a treadmill: %s (stamina %d).", l.autoRun, math.floor((l.stam or 0) + 0.5))
        end
        if not Stam.Infinite then return "info", Stam.AutoRun and "Auto Run is on and waiting for you to start a treadmill machine." or "Infinite Stamina is off, so the game controls your stamina and sprinting." end
        if l.fake then
            return "safe", string.format("Fake sprinting at speed %.1f. The game thinks you are walking.", l.humSpeed or 0)
        end
        if l.fatigued then return "warn", "Out of stamina. Hold sprint (or toggle it) and you will keep running." end
        return "safe", "Ready. When you run out of stamina and keep trying to run, you keep running."
    end

    -- returns level ("info" | "safe" | "warn" | "bad"), text
    function SP.risk()
        local l = SP.last
        if not (l and l.ok) then return "info", "Waiting for your character and Stats folder..." end
        if not Speed.Enabled and not SP.scOn then return "info", "The speed modifier is off, so the game controls your speed." end
        if l.capped then
            return "warn", string.format("Capped at %.1f (%s). The game's normal speed right now is %.1f.", l.limit, l.limitSource, l.vanilla)
        end
        if l.final - l.vanilla <= 0.01 then return "safe", "Safe: your speed is at or below what the game normally gives you." end
        local f = SP.flag
        if f and os.clock() - f.t < 20 then
            return "bad", "The anti-cheat just flagged you (" .. f.text .. "). You may lag back, so lower your speed."
        end
        return "safe", "Speed modifier active."
    end
end

--#endregion movement-engine
--#region automation-engine
----------------------------------------------------------------------
-- AUTOMATION ENGINE  (auto skill checks + instant calibration success + Swimmy Barnaby bot)
-- All skill checks listen to one InputAction ("SkillCheckTap"); firing its Pressed
-- signal is the same as pressing the key (no window focus, no latency).
----------------------------------------------------------------------
local Auto = {
    Default = false, Circle = false, Treadmill = false, Swimmy = false, Instant = false,
    InstantKinds = { default = true, circle = true, treadmill = true },   -- which machine types Instant Calibration Success answers; the others are played normally
    Snap = true,            -- nudge the marker/circle to the exact middle of gold before tapping
    TapRate = 10,           -- treadmill taps per second
    InstantDelay = 0,       -- seconds to wait before answering an instant check
    Feedback = true,        -- Instant Calibration Success also shows "Great Job!" and plays the hit sounds
    SwimmyHide = true,      -- hide the seaweed
    SwimmyCoins = true,     -- pull each coin onto Barnaby as it arrives
    SwimmyHideCoins = false,
    SwimmyInstantCoins = false, -- collect every coin the moment it spawns
    SwimmyCoinEvery = false,    -- credit one coin for every seaweed gap Barnaby passes (also the ones that spawned no coin)
    SwimmyRapid = false,        -- keep collecting coins non-stop, SwimmyRapidRate per second
    SwimmyRapidRate = 4,
    Status = "Idle",
}
do
    local function pgui() return LP:FindFirstChild("PlayerGui") end
    local IS
    local function pressTap()
        if not IS then IS = try(require, ReplicatedStorage.SharedUtils.InputService) end
        local act = IS and IS._actions and IS._actions.SkillCheckTap
        if act and firesignal and pcall(firesignal, act.Pressed) then return true end
        if keypress and keyrelease then
            pcall(keypress, 0x20); task.delay(0.03, function() pcall(keyrelease, 0x20) end)
            return true
        end
        return false
    end

    -- ---------------------------------------------------------- INSTANT CALIBRATION SUCCESS
    local fbToken = 0
    local function feedback()      -- the same "Great Job!" and sounds a real gold hit gives
        local aud = try(require, ReplicatedStorage.SharedUtils.Audio)
        if aud then
            pcall(function() aud:PlayOne("Sounds.UI.SkillCheck.Correct") end)
            pcall(function() aud:PlayOne("Sounds.UI.SkillCheck.GoldAreaHit") end)
        end
        -- the post-alpha HUD shows the message on PlayerGui.Skillchecks.Shared.Result, which listens to the "Skillchecks" HudPort:
        -- asking the port for a "great" result makes the game show its own message (text, gradient, fade) exactly as it does for a real hit
        local hp = try(require, ReplicatedStorage.SharedUtils.HudPort)
        local port = hp and try(hp.get, "Skillchecks")
        if port and pcall(function() port:fire("result", "great") end) then return end
        -- fallback if the port is ever unavailable: draw it on that label ourselves
        local sk = pgui() and pgui():FindFirstChild("Skillchecks")
        local shared = sk and sk:FindFirstChild("Shared")
        local msg = shared and shared:FindFirstChild("Result")
        if not msg then return end
        fbToken = fbToken + 1
        local my = fbToken
        task.spawn(function()
            pcall(function()
                msg.Text = "Great Job!"
                if msg:FindFirstChild("Lose") then msg.Lose.Enabled = false end
                if msg:FindFirstChild("Win") then msg.Win.Enabled = true end
                msg.TextTransparency = 0; msg.TextStrokeTransparency = 0
                msg.Visible = true
                task.wait(1)
                if my ~= fbToken then return end
                local tw = TweenService:Create(msg, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { TextTransparency = 1, TextStrokeTransparency = 1 })
                tw:Play(); tw.Completed:Wait()
                if my == fbToken then msg.Visible = false end
            end)
        end)
    end
    local remote = try(function()
        local ev = ReplicatedStorage:WaitForChild("Events", 5)
        return ev and ev:WaitForChild("SkillcheckUpdate", 5)
    end)
    local origInvoke, myWrap
    local function makeWrap(orig)
        return function(a1, a2, a3)
            local kind = (type(a2) == "table" and a2.type) or "default"
            if Auto.Instant and a1 ~= "cancel" and Auto.InstantKinds[kind] ~= false then
                if Auto.InstantDelay > 0 then task.wait(Auto.InstantDelay) end
                Auto.Status = "Instant calibration success (" .. tostring(kind) .. ")"
                if Auto.Feedback then feedback() end
                if kind == "treadmill" then return true end   -- the treadmill server only accepts true
                return "supercomplete"
            end
            if orig then return orig(a1, a2, a3) end
            return "noinput"
        end
    end
    local function maintainWrap()
        if not remote then return end
        local cur = try(getcallbackvalue, remote, "OnClientInvoke")
        if Auto.Instant then
            if cur ~= myWrap then                -- the game re-assigns it when its GUI is rebuilt
                origInvoke = cur
                myWrap = makeWrap(cur)
                pcall(function() remote.OnClientInvoke = myWrap end)
            end
        elseif myWrap and cur == myWrap then
            pcall(function() remote.OnClientInvoke = origInvoke end)
            myWrap = nil
        end
    end

    -- ---------------------------------------------------------- DEFAULT (bar + marker)
    -- Post-alpha HUD: PlayerGui.Skillchecks.Horizontal holds Marker, RequiredArea (the green calibration area, a hit anywhere in it passes)
    -- and GoldArea (a bright strip inside it that gives "Great Job!"). The game judges the marker's centre, so the tap is timed for the middle of
    -- the gold strip: that satisfies both. Positions are fractions of the bar and honour each part's anchor point.
    local dflt = { last = nil, fired = false }
    local function barSpan(o)        -- left and right edge of a part, as fractions of the bar
        local w = o.Size.X.Scale
        local l = o.Position.X.Scale - w * o.AnchorPoint.X
        return l, l + w
    end
    local function stepDefault()
        local sk = pgui() and pgui():FindFirstChild("Skillchecks")
        local f = sk and sk:FindFirstChild("Horizontal")
        if not (f and f.Visible) then dflt.last = nil; dflt.fired = false; return end
        local marker, gold, req = f:FindFirstChild("Marker"), f:FindFirstChild("GoldArea"), f:FindFirstChild("RequiredArea")
        if not (marker and (gold or req)) then return end
        local mOff = marker.Size.X.Scale * (0.5 - marker.AnchorPoint.X)        -- marker position -> marker centre
        local x = marker.Position.X.Scale + mOff
        local last = dflt.last; dflt.last = x
        if dflt.fired then if x < 0.02 then dflt.fired = false end return end
        if not last or x <= last then return end
        -- aim at the gold strip when it lies inside the required area (it normally does), otherwise at the required area
        local tl, tr
        if gold then
            local gl, gr = barSpan(gold)
            if req then
                local rl, rr = barSpan(req)
                if gl >= rl - 0.001 and gr <= rr + 0.001 then tl, tr = gl, gr else tl, tr = rl, rr end
            else
                tl, tr = gl, gr
            end
        else
            tl, tr = barSpan(req)
        end
        local center, v = (tl + tr) / 2, x - last
        if x > tr + v then dflt.fired = true; return end          -- missed the window, wait for the next check
        if x + v * 0.5 >= center then
            if Auto.Snap and (x < tl or x > tr) then
                marker.Position = UDim2.new(center - mOff, 0, marker.Position.Y.Scale, marker.Position.Y.Offset)
            end
            dflt.fired = true
            pressTap()
            Auto.Status = "Default check tapped"
        end
    end

    -- ---------------------------------------------------------- CIRCLE (shrinking ring)
    local circ = { last = nil, fired = false, frame = nil }
    local function stepCircle()
        local g = pgui() and pgui():FindFirstChild("CircleSkillCheckGui")
        local f = g and g:FindFirstChild("SkillCheckFrame")
        local c = f and f:FindFirstChild("Container")
        if not (f and c and f.Visible) then circ.last = nil; circ.fired = false; circ.frame = nil; return end
        local sh, ye, hole = c:FindFirstChild("ShrinkingCircle"), c:FindFirstChild("YellowCircle"), c:FindFirstChild("CenterHole")
        if not (sh and ye and hole) then return end
        if circ.frame ~= f then circ.frame = f; circ.fired = false; circ.last = nil end
        if circ.fired then return end
        local r = sh.Size.X.Offset / 2
        local rOut, rIn = ye.Size.X.Offset / 2, hole.Size.X.Offset / 2
        local last = circ.last; circ.last = r
        if not last or r >= last then return end
        local v, target = last - r, (rOut + rIn) / 2
        if r < rIn - v then circ.fired = true; return end              -- already shrank past gold
        if r <= target + v * 0.5 then
            if Auto.Snap and (r > rOut or r <= rIn) then
                local d = target * 2
                sh.Size = UDim2.new(0, d, 0, d)
            end
            circ.fired = true
            pressTap()
            Auto.Status = "Circle check tapped"
        end
    end

    -- ---------------------------------------------------------- TREADMILL (tap N times)
    local tread = { mod = nil, acc = 0 }
    local function stepTread(dt)
        if not tread.mod then tread.mod = try(require, ReplicatedStorage.Modules.Gameplay.TreadmillTapSkillCheck) end
        local a = tread.mod and tread.mod.ActiveSkillCheck
        local active = a and a.isActive and try(a.isActive)
        if not active then tread.acc = 0; return end
        if Auto.TapRate <= 0 then tread.acc = 0; return end
        tread.acc = math.min(tread.acc + dt * Auto.TapRate, 3)
        while tread.acc >= 1 do
            tread.acc = tread.acc - 1
            local lbl = a.ui and a.ui.TapCounter
            local c, n = tostring(lbl and lbl.Text or ""):match("(%d+)%s*/%s*(%d+)")
            if c and n and tonumber(c) >= tonumber(n) then return end
            pressTap()
            Auto.Status = "Treadmill tapping (" .. tostring(c or "0") .. "/" .. tostring(n or "?") .. ")"
        end
    end

    -- ---------------------------------------------------------- SWIMMY BARNABY
    -- Runs inside the game's own tick (patched on the class, so it also catches a game that is already running).
    -- Barnaby gets no gravity and no collision, so he flies dead level. Coins are the gold skill checks: the
    -- coin part is moved onto Barnaby and the game's own pickup code (sound, popup, score) does the rest.
    -- NOTE: PivotTo is used everywhere because it also carries the anchored child parts (the visuals);
    -- assigning .CFrame would only move the invisible parent part.
    local sw = { M = nil, orig = nil, had = nil, inst = nil, jumpT = 0, oc = nil }
    local function restoreFish()
        local fish = sw.inst and sw.inst.Fish
        if type(fish) == "table" and rawget(fish, "TSPNoClip") then
            pcall(rawset, fish, "IsOverlapping", nil)
            pcall(rawset, fish, "IsOutOfBounds", nil)
            pcall(rawset, fish, "Acceleration_Y", fish.TSPAccel)
            pcall(rawset, fish, "TSPNoClip", nil)
        end
    end
    local function hideTree(o, root, hidden)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1; hidden[d] = true
            elseif d:IsA("BasePart") then d.Transparency = 1
            elseif d:IsA("ParticleEmitter") then d.Enabled = false end
        end
    end
    local function applyHiding(o)
        local hidden = {}
        local coin = o.Coin
        if Auto.SwimmyHide and not o.TSPSea then
            o.TSPSea = true
            -- everything in the obstacle model except the coin is seaweed
            for _, d in ipairs(o.Model:GetDescendants()) do
                if not (coin and (d == coin or d:IsDescendantOf(coin))) then
                    if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1; hidden[d] = true
                    elseif d:IsA("BasePart") then d.Transparency = 1 end
                end
            end
        end
        if Auto.SwimmyHideCoins and coin and not o.TSPCoin then
            o.TSPCoin = true
            hideTree(o, coin, hidden)
            coin.Transparency = 1
        end
        -- the obstacle's tick keeps rewriting Transparency on its fade list, so drop what we hid from it
        local list = rawget(o, "_fadeDecals")
        if list and next(hidden) then
            for i = #list, 1, -1 do if hidden[list[i]] then table.remove(list, i) end end
        end
    end
    -- The game builds each obstacle inside its own RenderStepped and parents it straight away, so hiding it from our
    -- tick hook shows it for one frame. Wrapping the obstacle creator hides it BEFORE it is parented (no flash).
    local function wrapCreators(inst)
        local oc = inst.object_creators
        if type(oc) ~= "table" or rawget(oc, "TSPOrig") then return end
        local orig = oc.Obstacle
        if type(orig) ~= "function" then return end
        rawset(oc, "TSPOrig", orig)
        rawset(oc, "Obstacle", function(...)
            local o = orig(...)
            if Auto.Swimmy and (Auto.SwimmyHide or Auto.SwimmyHideCoins) and type(o) == "table" and o.Model then
                pcall(applyHiding, o)
            end
            return o
        end)
        sw.oc = oc
    end
    local function unwrapCreators()
        local oc = sw.oc
        if oc and rawget(oc, "TSPOrig") then
            pcall(rawset, oc, "Obstacle", rawget(oc, "TSPOrig"))
            pcall(rawset, oc, "TSPOrig", nil)
        end
        sw.oc = nil
    end
    local function rapidCoins(inst, dt)
        if not Auto.SwimmyRapid then sw.rapid = 0; return end
        if inst._countingDown or not inst.Fish then return end
        if inst.HasWon and inst:HasWon() then return end
        sw.rapid = (sw.rapid or 0) + dt * Auto.SwimmyRapidRate
        if sw.rapid >= 1 then
            sw.rapid = sw.rapid % 1
            if type(inst.CollectCoin) == "function" then
                pcall(inst.CollectCoin, inst)
                sw.sent = (sw.sent or 0) + 1
                Auto.Status = "Swimmy: continuous coins (" .. sw.sent .. " sent)"
            end
        end
    end
    local function stepSwim(inst, dt)
        local fish = inst.Fish
        local part = fish and not fish.Destroyed and fish.Part
        if not (part and part.Parent) or inst._countingDown then return end
        if not rawget(fish, "TSPNoClip") then
            fish.TSPAccel = fish.Acceleration_Y
            rawset(fish, "IsOverlapping", function() return false end)
            rawset(fish, "IsOutOfBounds", function() return false end)
            rawset(fish, "Acceleration_Y", 0)
            rawset(fish, "TSPNoClip", true)
        end
        local now = os.clock()
        if fish.Weightless then                      -- the first flap launches the run
            if now - sw.jumpT > 0.6 then sw.jumpT = now; pcall(fish.Jump, fish) end
            return
        end
        fish.Velocity_Y = 0
        local pos = part.Position
        if math.abs(pos.Y) > 0.02 then               -- level out at the middle of the screen
            local y = pos.Y - pos.Y * math.min(1, dt * 10)
            part:PivotTo(CFrame.new(pos.X, y, pos.Z) * part.CFrame.Rotation)
            pos = part.Position
        end
        for _, o in ipairs(inst._objects or {}) do
            if type(o) == "table" and o.Model and o.Model.Name == "ObstacleSet" and not o.Destroyed then
                if Auto.SwimmyHide or Auto.SwimmyHideCoins then pcall(applyHiding, o) end
                local coin = o.Coin
                if coin and coin.Parent and not o.CoinCollected then
                    local cp = coin.Position
                    if Auto.SwimmyInstantCoins then
                        coin:PivotTo(CFrame.new(pos.X, pos.Y, pos.Z) * coin.CFrame.Rotation)
                        Auto.Status = "Swimmy: coin collected"
                    elseif Auto.SwimmyCoins and cp.X - pos.X < 16 and cp.X - pos.X > -3 then
                        local k = math.min(1, dt * 18)
                        coin:PivotTo(CFrame.new(cp.X, cp.Y + (pos.Y - cp.Y) * k, cp.Z + (pos.Z - cp.Z) * k) * coin.CFrame.Rotation)
                        Auto.Status = "Swimmy: pulling coin in"
                    end
                end
                if Auto.SwimmyCoinEvery and not o.TSPPass and not o.Scored then
                    local okp, mp = pcall(function() return o.Model:GetPivot().Position end)
                    if okp and mp.X < pos.X + 6 then           -- the seaweed is reaching Barnaby
                        o.TSPPass = true
                        if not o.CoinCollected then
                            o.CoinCollected = true               -- stops the game also reporting it as a missed coin
                            if coin and coin.Parent then pcall(function() coin:Destroy() end) end
                            if type(inst.CollectCoin) == "function" then pcall(inst.CollectCoin, inst) end
                            Auto.Status = "Swimmy: coin for every seaweed"
                        end
                    end
                end
            end
        end
    end
    local function hookSwim()
        if sw.M then return end
        local M = try(require, ReplicatedStorage.Modules.GenArcade.SwimmyBarnaby)
        if type(M) ~= "table" then return end
        sw.M = M; sw.had = rawget(M, "tick"); sw.orig = M.tick
        if type(sw.orig) ~= "function" then sw.M = nil; return end
        rawset(M, "tick", function(self, dt)
            if Auto.Swimmy then pcall(wrapCreators, self) end
            local r = sw.orig(self, dt)
            sw.inst = self
            if Auto.Swimmy then pcall(stepSwim, self, dt); pcall(rapidCoins, self, dt) end
            return r
        end)
    end
    local function unhookSwim()
        restoreFish()
        unwrapCreators()
        if sw.M then pcall(rawset, sw.M, "tick", sw.had) end
        sw.M = nil; sw.inst = nil
    end

    -- ---------------------------------------------------------- MAIN LOOP
    local tmr = 0
    connect(RunService.RenderStepped, function(dt)
        if not alive then return end
        dt = math.min(dt, 0.1)
        tmr = tmr + dt
        if tmr > 0.3 then tmr = 0; pcall(maintainWrap) end
        if Auto.Default then pcall(stepDefault) else dflt.last = nil end
        if Auto.Circle then pcall(stepCircle) else circ.last = nil end
        if Auto.Treadmill then pcall(stepTread, dt) end
        if Auto.Swimmy then
            if not sw.M then hookSwim() end
        elseif sw.M then unhookSwim() end
    end)

    function Auto.Unload()
        Auto.Instant = false
        pcall(maintainWrap)
        unhookSwim()
    end
end

--#endregion automation-engine
--#region fun-engine
----------------------------------------------------------------------
-- FUN ENGINE  (extra skill checks outside machines)
-- Default check : replicated here (the game's own version only runs while you are on a machine).
-- Circle/Treadmill : the game's own SkillCheckController.handleInvoke, fed the same config the server sends.
----------------------------------------------------------------------
do
    local GC, IS, SCC, TouchBtn, Audio
    local function lazy()
        if not GC then GC = try(require, ReplicatedStorage.Modules.Core.GameContext) end
        if not IS then IS = try(require, ReplicatedStorage.SharedUtils.InputService) end
        if not SCC then SCC = try(require, ReplicatedStorage.Modules.ClientUI.SkillCheckController) end
        if not TouchBtn then TouchBtn = try(require, ReplicatedStorage.Modules.Gameplay.SkillCheckTouchButton) end
        if not Audio then Audio = try(require, ReplicatedStorage.SharedUtils.Audio) end
        return (GC and IS and SCC and Audio) and true or false
    end

    local function menu()
        local pg = LP:FindFirstChild("PlayerGui")
        local sg = pg and pg:FindFirstChild("ScreenGui")
        return sg and sg:FindFirstChild("Menu")
    end
    local function charStats() local ch = LP.Character; return ch, ch and ch:FindFirstChild("Stats") end
    local function statv(stats, name, d)
        local v = stats and stats:FindFirstChild(name)
        local x = v and v:IsA("ValueBase") and v.Value
        return type(x) == "number" and x or d
    end
    local function equipped(name)
        for i = 1, 2 do
            if LP:GetAttribute("EquippedTrinket" .. i) == name then return true end
            local ch = LP.Character
            if ch and ch:GetAttribute("EquippedTrinket" .. i) == name then return true end
        end
        return false
    end
    local function mimeActive() return Fun.Trinkets and equipped("MimeMakeup") end

    local cur, lastEnd, holdTok, holding = nil, 0, 0, false
    local prevPPS = nil

    ------------------------------------------------------------------
    -- settings -> numbers
    ------------------------------------------------------------------
    local function gameCircleTime(b)       -- the circle handler's own speed table, keyed on BoundarySize
        if b <= 63 then return 0.6 elseif b <= 125 then return 0.75 elseif b <= 188 then return 0.9 elseif b <= 250 then return 1.2 end
        return 1.8
    end
    local function twistedCount()
        if Fun.TwistedCount == "On The Floor" then
            local n, cr = 0, Workspace:FindFirstChild("CurrentRoom")
            if cr then
                for _, room in ipairs(cr:GetChildren()) do
                    local mon = room:FindFirstChild("Monsters")
                    if mon then for _, m in ipairs(mon:GetChildren()) do if m:IsA("Model") then n = n + 1 end end end
                end
            end
            return n
        end
        return math.max(0, math.floor(tonumber(LP:GetAttribute("ChaseCount")) or 0))      -- the game's own count of Twisteds chasing you
    end
    -- "Skill Check Speed" mode: stat x modifier, relative to the reference value, speeds up (or slows down) the game's normal sweep
    local function speedMult(stats)
        local v = statv(stats, "SkillCheckSpeed", Fun.SpeedRef) * statv(stats, "SkillCheckSpeedModifier", 1)
        return math.clamp(v / math.max(Fun.SpeedRef, 0.1), 0.2, 8)
    end
    local function rewardFlat(stats)
        if Fun.RewardStat == "Skill Check Speed" then
            return statv(stats, "SkillCheckSpeed", 0) * statv(stats, "SkillCheckSpeedModifier", 1)
        end
        return (Fun.ValueMode == "Manual") and Fun.Value or statv(stats, "SkillCheckValue", 0)
    end

    -- everything the next extra check will use, in one place (the checks and the live readouts both read this)
    local function calc(stats)
        local n = twistedCount()
        local manualSize = Fun.SizeMode == "Manual"
        local base = manualSize and Fun.Size or statv(stats, "BoundarySize", 150)
        local mod = manualSize and 1 or statv(stats, "BoundarySizeModifier", 1)         -- the game's own size modifier
        local gameMod = mod
        if Fun.SizeScale then
            if Fun.SizeScaleMode == "Flat" then base = base + Fun.SizeFlat * n               -- flat goes in before the modifiers
            else mod = mod * math.max(1 + Fun.SizePct * n / 100, 0) end                       -- the percents add up per Twisted, then multiply with the game's modifier
        end
        base, mod = math.max(base, 0), math.max(mod, 0)
        local size = base * mod
        -- chance works like the game's own roll, stat x multiplier + additive, except that chance percentages never multiply
        -- together: they all add up first (5% + 5% = 10%), and that total multiplies the stat once
        local chanceBase = (Fun.ChanceMode == "Manual") and Fun.Chance or statv(stats, "SkillCheckChance", 25)
        local chancePct, chanceFlat = 0, 0
        if Fun.ChanceScale then
            if Fun.ChanceScaleMode == "Multiplier" then chancePct = Fun.ChancePct * n else chanceFlat = Fun.ChancePer * n end
        end
        local chanceMul = math.max(1 + chancePct / 100, 0)
        local chance = math.clamp(chanceBase * chanceMul + chanceFlat, 0, 100)
        local statM = (Fun.SpeedMode == "Skill Check Speed") and speedMult(stats) or 1
        local twM = 1
        if Fun.SpeedScale then
            if Fun.SpeedScaleMode == "Flat" then twM = 1 + Fun.SpeedFlat * n else twM = 1 + Fun.SpeedPct * n / 100 end
        end
        local mult = math.clamp(statM * math.max(twM, 0.05), 0.2, 8)                          -- above 1 = faster
        local manualT = Fun.SpeedMode == "Manual"
        local sweepD = math.clamp((manualT and Fun.DefaultTime or 2) / mult, 0.25, 10)
        local sweepC = math.clamp((manualT and Fun.CircleTime or gameCircleTime(base)) / mult, 0.25, 6)
        local overrideC = manualT or statM ~= 1 or twM ~= 1
        if overrideC and math.abs(sweepC - 1.2) <= 0.01 then sweepC = 1.211 end             -- the handler treats 1.2 as "use my own table"
        local value = (Fun.ValueMode == "Manual") and Fun.Value or statv(stats, "SkillCheckValue", 0)
        return { n = n, chance = chance, chanceBase = chanceBase, chanceMul = chanceMul, chanceFlat = chanceFlat, size = size, base = base, mod = mod, gameMod = gameMod, ratio = math.clamp(size / 1000, 0.02, 1),
            mult = mult, sweepD = sweepD, sweepC = sweepC, overrideC = overrideC, value = value }
    end

    ------------------------------------------------------------------
    -- feedback text (same look as the game's own)
    ------------------------------------------------------------------
    local msgTok = 0
    local function message(text, win, hold)
        local m = menu(); local msg = m and m:FindFirstChild("SkillCheckMessage")
        if not msg then return end
        msgTok = msgTok + 1; local my = msgTok
        task.spawn(function()
            pcall(function()
                msg.Text = text
                local g, gw = msg:FindFirstChild("UIGradient"), msg:FindFirstChild("UIGradientWin")
                if g then g.Enabled = not win end
                if gw then gw.Enabled = win end
                msg.Visible = true; msg.TextTransparency = 0; msg.TextStrokeTransparency = 0
                task.wait(hold)
                if my ~= msgTok then return end
                local tw = TweenService:Create(msg, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1, TextStrokeTransparency = 1 })
                tw:Play(); tw.Completed:Wait()
                if my == msgTok then msg.Visible = false end
            end)
        end)
    end
    local function failFeedback()
        -- like the game: a Mime Makeup that is equipped changes the text and the sound, whatever the modification settings are
        local text, sound = "Be careful! They can hear you...", nil
        if equipped("MimeMakeup") then
            local td = ReplicatedStorage:FindFirstChild("TrinketData")
            local mod = td and td:FindFirstChild("MimeMakeup")
            local d = mod and try(require, mod)
            if type(d) == "table" then text = d.GeneratorText or text; sound = d.GeneratorSound end
        end
        local m = menu()
        pcall(function()
            if sound then Audio:Play(sound, { Parent = m and m.Parent }) else Audio:Play("Sounds.UI.SkillCheck.Wrong") end
        end)
        message(text, false, 2)
    end

    ------------------------------------------------------------------
    -- the default (horizontal bar) check
    ------------------------------------------------------------------
    local function overlap(a, b)
        local s, bs = a.Position.X.Scale, b.Position.X.Scale
        return bs <= s and s <= bs + b.Size.X.Scale
    end
    -- returns "gold" | "white" | "fail" | nil (aborted / could not start)
    local function runDefault(ratio, pos, sweep, me)
        local m = menu()
        local f = m and m:FindFirstChild("SkillCheckFrame")
        local req, gold, marker = f and f:FindFirstChild("RequiredArea"), f and f:FindFirstChild("GoldArea"), f and f:FindFirstChild("Marker")
        local cal, prompt, msg = m and m:FindFirstChild("Calibrate"), m and m:FindFirstChild("SpaceBarPromptText"), m and m:FindFirstChild("SkillCheckMessage")
        if not (f and req and gold and marker and cal) then return nil end
        local stop = m:FindFirstChild("StopGenerator"); if stop then stop.Visible = false end
        f.Visible = true; cal.Visible = true
        if prompt then prompt.Visible = true end
        if msg then msgTok = msgTok + 1; msg.Visible = false; msg.TextTransparency = 1; msg.TextStrokeTransparency = 1 end
        req.Size = UDim2.new(ratio, 0, 1, 0)
        req.Position = UDim2.new(math.clamp(pos, 0.1, 0.75), 0, 0, 0)
        gold.Size = UDim2.new(ratio / 3, 0, 1, 0)
        gold.Position = req.Position + UDim2.new((ratio - ratio / 3) / 2, 0, 0, 0)
        marker.Position = UDim2.new(0, 0, -0.399, 0)
        f.Position = UDim2.new(0.35, 0, 0.8, 0)
        req.BackgroundTransparency, gold.BackgroundTransparency, marker.BackgroundTransparency, f.BackgroundTransparency = 1, 1, 1, 1
        pcall(function() Audio:PlayOne("Sounds.UI.SkillCheck.SkillCheck") end)
        local ti = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(f, ti, { Position = UDim2.new(0.35, 0, 0.78, 0) }):Play()
        for _, o in ipairs({ f, marker, req, gold }) do pcall(function() TweenService:Create(o, ti, { Transparency = 0 }):Play() end) end

        local result, done, tapped = nil, false, false
        local conns, tween = {}, nil
        local function cleanup()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            if tween then pcall(function() tween:Cancel(); tween:Destroy() end) end
            f.Visible = false; cal.Visible = false
            if prompt and GC.currentgenerator == nil then prompt.Visible = false end
        end
        me.abort = function() done = true; result = nil end

        local t0 = os.clock()
        while os.clock() - t0 < 1 and not me.aborted do task.wait() end      -- the game waits a second before the marker moves
        if me.aborted then cleanup(); return nil end

        tween = TweenService:Create(marker, TweenInfo.new(sweep, Enum.EasingStyle.Linear), { Position = UDim2.new(1, 0, -0.399, 0) })
        local function onTap()
            if done or tapped then return end
            tapped = true; done = true
            pcall(function() tween:Pause() end)
            local inReq, inGold = overlap(marker, req), overlap(marker, gold)
            result = (not inReq) and "fail" or (inGold and "gold" or "white")
        end
        conns[#conns + 1] = IS:OnAction("SkillCheckTap", function() if IS:IsTyping() then return end; onTap() end)
        if TouchBtn then conns[#conns + 1] = TouchBtn.bind(cal, function() return not done and not tapped end, onTap) end
        local inG, inR = false, false
        conns[#conns + 1] = RunService.RenderStepped:Connect(function()
            local r = overlap(marker, req)
            if not overlap(marker, gold) then inG = false
            elseif not inG then inG = true; inR = false; pcall(function() Audio:PlayOne("Sounds.UI.SkillCheck.Ticks.TinierTick") end) end
            if r and not inR and not inG then inR = true; pcall(function() Audio:PlayOne("Sounds.UI.SkillCheck.Ticks.TinyTick") end) end
        end)
        conns[#conns + 1] = tween.Completed:Connect(function(state)
            if not done and state == Enum.PlaybackState.Completed then done = true; result = "fail" end   -- ran out without a tap
        end)
        tween:Play()
        while not done and not me.aborted do
            task.wait()
            if not f.Visible then f.Visible = true; cal.Visible = true end   -- something else hid it (the spotted handler when the setting is off)
        end
        cleanup()
        if me.aborted then return nil end
        if result == "gold" then
            pcall(function() Audio:PlayOne("Sounds.UI.SkillCheck.Correct"); Audio:PlayOne("Sounds.UI.SkillCheck.GoldAreaHit") end)
            message("Great Job!", true, 1)
        elseif result == "white" then
            pcall(function() Audio:PlayOne("Sounds.UI.SkillCheck.Correct") end)
            message("Good Job!", false, 1)
        else
            failFeedback()
        end
        return result
    end

    ------------------------------------------------------------------
    -- rewards and penalties
    ------------------------------------------------------------------
    local function applyOutcome(kind, outcome, stats)
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if outcome ~= "fail" and Fun.Trinkets and equipped("MagnifyingGlass") then
            Fun.add("mag", { basePct = 0.04, hud = "Energized", label = "Magnifying Glass" }, Fun.MagTime)
        end
        if outcome == "gold" and Fun.Rewards then
            local m = Fun.RewardMode
            if m == "Skill Check Stat" then
                local v = rewardFlat(stats)
                Fun.add("reward", { flatWalk = v, flatRun = v, hud = "Energized", label = "Skill Check Boost" }, Fun.RewardTime)
            elseif m == "Flat" then
                Fun.add("reward", { flatWalk = Fun.RewardWalk, flatRun = Fun.RewardRun, hud = "Energized", label = "Skill Check Boost" }, Fun.RewardTime)
            elseif m == "Multiplier" then
                Fun.add("reward", { mulWalk = 1 + Fun.RewardWalkPct / 100, mulRun = 1 + Fun.RewardRunPct / 100, hud = "Energized", label = "Skill Check Boost" }, Fun.RewardTime)
            else
                local pct = FUN_ENERGIZED_PCT[Fun.EnergizedTier] or Fun.EnergizedPct
                local k = 1 + pct / 100
                Fun.add("reward", { mulWalk = k, mulRun = k, hud = "Energized", label = "Energized", native = true, tier = FUN_TIER_NUM[Fun.EnergizedTier] }, Fun.RewardTime)
            end
        end
        if outcome == "fail" then
            if Fun.TreadmillDazed and (kind == "treadmill" or Fun.TreadmillAll) then
                Fun.add("dazed", { mulWalk = math.max(0, 1 - Fun.TreadmillWalkPct / 100), mulRun = math.max(0, 1 - Fun.TreadmillRunPct / 100),
                    hud = "TreadmillDazed", label = "Dazed", native = true }, Fun.TreadmillTime)
                if Fun.DazedBlock and ch then
                    if not Fun.dazedSet then Fun.dazedPrev = ch:GetAttribute("TreadmillDazed") end
                    Fun.dazedSet = true
                    Fun.dazedUntil = os.clock() + Fun.TreadmillTime
                    ch:SetAttribute("TreadmillDazed", true)     -- the game's own SprintController reads this to block sprinting
                    -- end a sprint already in progress the way the game's own stop does: clear the client flag and tell the server
                    local sc = try(require, ReplicatedStorage.Modules.ClientUI.SprintController)
                    if sc and sc.resetState then pcall(sc.resetState) end
                    local evs = ReplicatedStorage:FindFirstChild("Events")
                    local sev = evs and evs:FindFirstChild("SprintEvent")
                    if sev then pcall(function() sev:FireServer(false) end) end
                end
            end
            if Fun.Penalties and (kind ~= "treadmill" or Fun.PenaltiesOnTreadmill) then
                if mimeActive() then Fun.Status = "Mime Makeup: no penalty"; return end
                local m = Fun.PenaltyMode
                if m == "Kill" then
                    if hum then hum.Health = 0; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end) end
                elseif m == "Flat" then
                    Fun.add("penalty", { flatWalk = -Fun.PenaltyWalk, flatRun = -Fun.PenaltyRun, hud = "Slow", label = "Skill Check Penalty" }, Fun.PenaltyTime)
                elseif m == "Multiplier" then
                    Fun.add("penalty", { mulWalk = math.max(0, 1 - Fun.PenaltyWalkPct / 100), mulRun = math.max(0, 1 - Fun.PenaltyRunPct / 100), hud = "Slow", label = "Skill Check Penalty" }, Fun.PenaltyTime)
                else
                    if Fun.Trinkets and equipped("TrainWhistle") then Fun.Status = "Train Whistle: immune to Slowness"; return end
                    local pct = FUN_SLOW_PCT[Fun.SlowTier] or Fun.SlowPct
                    local k = math.max(0, 1 - pct / 100)
                    Fun.add("penalty", { mulWalk = k, mulRun = k, hud = "Slow", label = "Slowness", native = true, tier = FUN_TIER_NUM[Fun.SlowTier] }, Fun.PenaltyTime)
                end
            end
        end
    end

    ------------------------------------------------------------------
    -- running one check
    ------------------------------------------------------------------
    local function setPrompts(off)
        local pps = game:GetService("ProximityPromptService")
        if off then
            if prevPPS == nil then prevPPS = pps.Enabled; pps.Enabled = false end
        elseif prevPPS ~= nil then
            pps.Enabled = prevPPS; prevPPS = nil
        end
    end
    -- When you are spotted or hit, the game's StoryEventsController cancels every skill check that is not a door check
    -- (it asks SkillCheckController.isDoorCheckActive, which nothing else uses). While one of our checks is up we make that
    -- answer "yes", so the game's own code skips the cancel. Turn the setting on to get the game's cancel back.
    local doorOrig = nil
    local function guardOn()
        if doorOrig or Fun.CancelWhenSpotted or not SCC then return end
        local orig = SCC.isDoorCheckActive
        if type(orig) ~= "function" then return end
        doorOrig = orig
        SCC.isDoorCheckActive = function(...)
            if cur and not cur.aborted then return true end
            return orig(...)
        end
    end
    local function guardOff()
        if doorOrig then SCC.isDoorCheckActive = doorOrig; doorOrig = nil end
    end
    local function release(hold)
        guardOff()
        setPrompts(false)
        cur = nil
        holdTok = holdTok + 1
        local t = holdTok
        if hold > 0 then
            holding = true
            task.delay(hold, function()
                if t == holdTok then
                    holding = false
                    if not cur and GC and GC.currentgenerator == nil then GC.skillchecking = false end
                end
            end)
        else
            holding = false
            if GC and GC.currentgenerator == nil then GC.skillchecking = false end
        end
    end
    local function abortCheck(reason)
        local me = cur
        if not me or me.aborted then return end
        me.aborted = true
        if me.abort then pcall(me.abort) end
        if me.kind ~= "default" and SCC then pcall(function() SCC.handleInvoke("cancel") end) end
        Fun.Status = "Aborted: " .. reason
    end
    local function startCheck(kind)
        local ch, stats = charStats()
        if cur or not stats or not lazy() then return end
        local c = calc(stats)
        local me = { kind = kind, aborted = false }
        cur = me
        holdTok = holdTok + 1; holding = false
        GC.skillchecking = true
        setPrompts(true)                                  -- machines cannot be started while a check is up
        guardOn()
        Fun.Status = "Playing a " .. kind .. " check"
        task.spawn(function()
            local outcome
            local ok, err = pcall(function()
                if kind == "default" then
                    local ratio = math.clamp(c.size * math.random(95, 105) / 100 / 1000, 0.02, 1)
                    local sweep = c.sweepD
                    outcome = runDefault(ratio, math.random(20, 100) / 100 - ratio, sweep, me)
                elseif kind == "circle" then
                    local cfg = {
                        type = "circle", randomPosition = true,
                        boundarySize = math.max(c.base, 1), boundaryModifier = c.mod,
                        movementConfig = { speed = 1, amplitude = 50, radius = 30 },
                        circles = { { reward = 1 }, { reward = c.value }, { reward = 0 } },
                    }
                    if c.overrideC then cfg.markerSpeed = c.sweepC end
                    local res = SCC.handleInvoke(true, cfg)
                    if me.aborted then return end
                    -- the handler returns "supercomplete" (great), true (good), false (miss), "noinput" (ran out) or "forcestopped"
                    if res == "supercomplete" then outcome = "gold"
                    elseif res == true then outcome = "white"
                    elseif res == false or res == "noinput" then outcome = "fail" end
                else
                    local res = SCC.handleInvoke(true, { type = "treadmill", boundarySize = math.max(c.size, 1), animationBoost = 1 })
                    if me.aborted then return end
                    if res == true then outcome = "white"
                    elseif res == false or res == "noinput" then outcome = "fail" end
                end
            end)
            if not ok then warn("[Fun] skill check error: " .. tostring(err)) end
            local aborted = me.aborted
            if not aborted and not outcome and ok then Fun.Status = "Could not start a " .. kind .. " check" end
            release((not aborted and outcome) and (outcome == "fail" and 3 or 2) or 0)
            lastEnd = os.clock()
            if not aborted and outcome then
                local ch2, stats2 = charStats()
                pcall(applyOutcome, kind, outcome, stats2 or stats)
                if Fun.Status:sub(1, 7) ~= "Mime Ma" and Fun.Status:sub(1, 7) ~= "Train W" then Fun.Status = "Last check: " .. kind .. " " .. outcome end
            end
        end)
        task.delay(14, function() if cur == me then abortCheck("timed out") end end)   -- safety net
    end

    ------------------------------------------------------------------
    -- when may a check happen / when must one stop
    ------------------------------------------------------------------
    local function hardStop()
        local ch, stats = charStats()
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not (hum and stats) or hum.Health <= 0 then return "no character" end
        local info = Workspace:FindFirstChild("Info")
        local fa = info and info:FindFirstChild("FloorActive")
        if not (fa and fa.Value == true) then return "floor is not active" end
        local ie = stats:FindFirstChild("InElevator")
        if ie and ie.Value == true then return "in the elevator" end
        local dec = ch:FindFirstChild("Decoding")
        if dec and dec:IsA("ObjectValue") and dec.Value ~= nil then return "extracting" end
        return nil
    end
    local function blocked()
        if not lazy() then return "Waiting for the game's skill check code" end
        local why = hardStop()
        if why then return "Paused: " .. why end
        if (GC.skillchecking and not holding) or GC.currentgenerator ~= nil then return "Paused: a real skill check is active" end
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if Fun.When == "While Not Idle" and hum.MoveDirection.Magnitude < 0.01 then return "Waiting: standing still" end
        if Fun.When == "While Chased" and (tonumber(LP:GetAttribute("ChaseCount")) or 0) <= 0 then return "Waiting: not being chased" end
        return nil
    end

    ------------------------------------------------------------------
    -- status icons: the game's own right-side status HUD and its overhead DebuffWindow, filled in with the game's own templates
    ------------------------------------------------------------------
    local SEC, DC
    local hud = { shown = {}, over = {} }
    local function hudModules()
        if not SEC then SEC = try(require, ReplicatedStorage.Modules.ClientUI.StatusEffectController) end
        if not DC then DC = try(require, ReplicatedStorage.Modules.Gameplay.DebuffConfig) end
        return (SEC and DC) and true or false
    end
    local function overheadSet(key, w, def)
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local dw = hrp and hrp:FindFirstChild("DebuffWindow")
        local holder = dw and dw:FindFirstChild("HolderFrame")
        local tpl = holder and holder:FindFirstChild("Template")
        if not tpl then return end
        local fr = hud.over[key]
        if not (fr and fr.Parent == holder) then
            if fr then fr:Destroy() end
            fr = tpl:Clone(); fr.Name = "TSP_" .. key; fr.Visible = true; fr.Parent = holder
            hud.over[key] = fr
        end
        local col = def.color or Color3.new(1, 1, 1)
        local img, nm, tm = fr:FindFirstChild("DebuffImage"), fr:FindFirstChild("DebuffName"), fr:FindFirstChild("DebuffTime")
        if img then img.Image = tostring(def.icon or ""); img.ImageColor3 = col end
        if nm then nm.Text = w.label; nm.TextColor3 = col end
        if tm then
            local numeral = ""
            if w.n > 1 then numeral = "x" .. w.n
            elseif w.tier then local okN, v = pcall(DC.GetStageNumeral, w.tier); numeral = okN and tostring(v or "") or "" end
            tm.Text = numeral; tm.TextColor3 = col
        end
        local ba, da = fr:FindFirstChild("BuffArrow"), fr:FindFirstChild("DebuffArrow")
        if ba then ba.Visible = w.isBuff end
        if da then da.Visible = not w.isBuff end
    end
    local function hudClear()
        if SEC then for key in pairs(hud.shown) do pcall(SEC.hide, "TSP_" .. key) end end
        table.clear(hud.shown)
        for _, fr in pairs(hud.over) do pcall(function() fr:Destroy() end) end
        table.clear(hud.over)
    end
    local function hudUpdate()
        if not hudModules() then return end
        local now, want = os.clock(), {}
        if Fun.Icons then
            for _, e in ipairs(Fun.fx) do
                local show = (e.group == "dazed") and Fun.ShowDazed or (e.native and true or Fun.CustomIcons)
                if show and e.expires > now then
                    local w = want[e.group]
                    if not w then
                        w = { def = e.hud, label = e.label or "Effect", n = 0, expires = 0, dur = 1, isBuff = e.hud == "Energized" }
                        want[e.group] = w
                    end
                    w.n = w.n + 1
                    if e.expires > w.expires then w.expires, w.dur, w.label, w.tier = e.expires, e.dur or (e.expires - now), e.label or w.label, e.tier end
                end
            end
        end
        for key, w in pairs(want) do
            local def = DC.Get(w.def) or {}
            local s = hud.shown[key]
            if not s or s.n ~= w.n or s.tier ~= w.tier or math.abs(s.expires - w.expires) > 0.05 then
                pcall(SEC.show, "TSP_" .. key, { duration = w.expires - now, totalDuration = w.dur, tier = w.tier or 1, hideTier = (w.tier == nil),
                    stacks = w.n > 1 and w.n or nil, icon = def.icon, color = def.color, isBuff = w.isBuff })
                hud.shown[key] = { n = w.n, expires = w.expires, tier = w.tier }
            end
            pcall(overheadSet, key, w, def)
        end
        for key in pairs(hud.shown) do
            if not want[key] then pcall(SEC.hide, "TSP_" .. key); hud.shown[key] = nil end
        end
        for key, fr in pairs(hud.over) do
            if not want[key] then pcall(function() fr:Destroy() end); hud.over[key] = nil end
        end
    end

    ------------------------------------------------------------------
    -- main loop
    ------------------------------------------------------------------
    local acc, hudAcc = 0, 0
    connect(RunService.Heartbeat, function(dt)
        if not alive then return end
        hudAcc = hudAcc + dt
        if hudAcc >= 0.1 then hudAcc = 0; pcall(hudUpdate) end
        if Fun.dazedSet and os.clock() >= Fun.dazedUntil then            -- give the sprint block back
            Fun.dazedSet = false
            local ch = LP.Character
            if ch and ch:GetAttribute("TreadmillDazed") == true then ch:SetAttribute("TreadmillDazed", Fun.dazedPrev) end
        end
        if cur then
            local why = (not Fun.Enabled) and "turned off" or hardStop()
            if why then abortCheck(why) end
        end
        acc = acc + dt
        if acc < 1 then return end
        acc = 0
        if not Fun.Enabled then if not cur then Fun.Status = "Off" end; return end
        if cur then return end
        if os.clock() - lastEnd < Fun.Gap then return end
        local why = blocked()
        if why then Fun.Status = why; return end
        local kinds = {}
        if Fun.Default then kinds[#kinds + 1] = "default" end
        if Fun.Circle then kinds[#kinds + 1] = "circle" end
        if Fun.Treadmill then kinds[#kinds + 1] = "treadmill" end
        if #kinds == 0 then Fun.Status = "No check type selected"; return end
        local _, stats = charStats()
        local chance = calc(stats).chance
        if math.random(1, 100) <= chance then startCheck(kinds[math.random(1, #kinds)])
        else Fun.Status = "Rolling for a skill check..." end
    end)

    function Fun.calc() local _, st = charStats(); return calc(st) end

    function Fun.Unload()
        if cur then abortCheck("unloaded") end
        guardOff()
        setPrompts(false)
        if GC and GC.currentgenerator == nil then pcall(function() GC.skillchecking = false end) end
        local ch = LP.Character
        if Fun.dazedSet and ch and ch:GetAttribute("TreadmillDazed") == true then ch:SetAttribute("TreadmillDazed", Fun.dazedPrev) end
        Fun.dazedSet = false
        table.clear(Fun.fx); Fun.dazedUntil = 0
        pcall(hudClear)
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")           -- hand the walk speed back to the game
        if hum and SP.scWas and SP.last and SP.last.vanilla and hum.WalkSpeed > 0.01 then hum.WalkSpeed = SP.last.vanilla end
    end
end

--#endregion fun-engine

--#region pursuer-engine
----------------------------------------------------------------------
-- PURSUER  (a custom chaser you design: Pizzaface / Nextbot / Dark Esau style)
-- Client side only: a flat picture on an invisible part that follows you, kills you on touch and obeys the floor rules
-- (it appears when you leave the elevator, fades when you re-enter it, waits while you extract, and so on).
-- Everything lives in ONE function scope and hangs off Fun.Pur, so this region adds NO top-level locals
-- (the main script is close to Luau's 200-locals limit).
----------------------------------------------------------------------
Fun.Pur = (function()
local P = {}
local PathfindingService = game:GetService("PathfindingService")
local getasset = getcustomasset or getsynasset
local httpReq = request or http_request or (syn and syn.request) or (http and http.request)

local DIR = ROOT_DIR .. "/Pursuer"
local IMG_DIR, SND_DIR, CACHE_DIR = DIR .. "/Images", DIR .. "/Sounds", DIR .. "/Cache"
mkD(DIR); mkD(IMG_DIR); mkD(SND_DIR); mkD(CACHE_DIR)

----------------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------------
local LISTS = {
    ImageMode = { "Static", "Sprite Sheet", "Frame List" },
    Billboard = { "Y Only", "Full", "Off" },
    WallMode  = { "Solid (Pathfinds)", "Through Walls" },
    Vertical  = { "Follow The Floor", "Match My Height", "Fly Up And Down" },
    SpeedMode = { "Constant", "Faster When Far", "Slower When Close", "Faster Far, Slower Close", "Slower When Close, Stops Near" },
    DecodeSlow = { "Off", "Slow By Flat Amount", "Slow By Percent", "Set Speed To" },
    PanicMode = { "Off", "Increase By Percent", "Increase By Flat Amount", "Set Speed To" },
    SuppressMode = { "Not At All", "Lower By Flat Amount", "Lower By Percent" },
    Trigger   = { "Right Away", "When The Elevator Opens", "After A Timer" },
    Emissive  = { "During Blackouts", "Always", "Off" },
    SpotVariant = { "Spotted", "Spotted 2" },
}
P.LISTS = LISTS

local D = {
    Enabled = false, Kill = true, HitScale = 1,
    ImageMode = "Static", ImageSrc = "", FrameList = "", Cols = 4, Rows = 4, FrameCount = 16, FPS = 12,
    Billboard = "Y Only", Pixelated = true, Width = 6, Height = 6, FeetOnGround = true, Hover = 3,
    Opacity = 1, Tint = "#ffffff", Emissive = "During Blackouts", GlowLight = false,
    WallMode = "Solid (Pathfinds)", Vertical = "Follow The Floor", VertSpeed = 12, FlyOffset = 0,
    Speed = 14, SpeedMode = "Constant", NearDist = 10, FarDist = 70, CloseMult = 0.4, FarMult = 2, StopDist = 6,
    PanicMode = "Off", PanicPercent = 25, PanicFlat = 4, PanicSet = 20,                  -- speed in panic mode: Off / Increase By Percent / Increase By Flat Amount / Set Speed To
    SuppressMode = "Lower By Percent", SuppressPercent = 20, SuppressFlat = 5,           -- what the Suppression card does to that boost
    PauseDecode = true,
    DecodeSlow = "Off", DecodeFlat = 5, DecodePercent = 50, DecodeSet = 6,   -- speed while you extract: Off / Slow By Flat Amount / Slow By Percent / Set Speed To
    Dash = false, DashSpeed = 70, DashDistance = 45, DashWindup = 0.9, DashCdMin = 6, DashCdMax = 12, DashRange = 80, DashNeedsSight = true,
    Trigger = "Right Away", FlashTime = 3, FlashRate = 5,
    SpotSound = true, SpotVariant = "Spotted", EyeIcon = true,
    Timer = 120, TimerPauseDecode = true, TimerHud = true,
    Music = false, MusicSrc = "", MusicVol = 1, MusicRange = 120, Music3D = true,
    SpawnSound = false, SpawnSrc = "", SpawnVol = 1,
    DeathSound = false, DeathSrc = "", DeathVol = 1,
    After = false, AfterRate = 0.07, AfterFade = 0.45, AfterStart = 0.5, AfterDashOnly = false,
}
P.Defaults = D
local Cfg = copyT(D)
P.Cfg = Cfg

local RANGES = {
    PanicPercent = { 0, 500 }, PanicFlat = { 0, 100 }, PanicSet = { 1, 200 }, SuppressPercent = { 0, 100 }, SuppressFlat = { 0, 200 },
    DecodeFlat = { 0, 100 }, DecodePercent = { 0, 100 }, DecodeSet = { 0, 200 },
    HitScale = { 0.2, 3 }, Cols = { 1, 32 }, Rows = { 1, 32 }, FrameCount = { 1, 1024 }, FPS = { 1, 60 },
    Width = { 0.5, 40 }, Height = { 0.5, 40 }, Hover = { 0, 30 }, Opacity = { 0.05, 1 },
    VertSpeed = { 1, 150 }, FlyOffset = { -20, 30 },
    Speed = { 1, 200 }, NearDist = { 0, 300 }, FarDist = { 1, 500 }, CloseMult = { 0, 1 }, FarMult = { 1, 8 }, StopDist = { 0, 60 },
    DashSpeed = { 10, 300 }, DashDistance = { 5, 300 }, DashWindup = { 0, 5 }, DashCdMin = { 0.5, 120 }, DashCdMax = { 0.5, 180 }, DashRange = { 5, 500 },
    FlashTime = { 0, 15 }, FlashRate = { 1, 20 }, Timer = { 5, 1800 },
    MusicVol = { 0, 2 }, MusicRange = { 10, 1000 }, SpawnVol = { 0, 2 }, DeathVol = { 0, 2 },
    AfterRate = { 0.02, 0.5 }, AfterFade = { 0.1, 2 }, AfterStart = { 0.05, 1 },
}
P.RANGES = RANGES
local TEXTKEYS = { "ImageSrc", "FrameList", "MusicSrc", "SpawnSrc", "DeathSrc" }

function P.sanitize()
    for k, r in pairs(RANGES) do
        local v = tonumber(Cfg[k])
        if not v or v ~= v then v = D[k] end
        Cfg[k] = math.clamp(v, r[1], r[2])
    end
    for k, list in pairs(LISTS) do if not table.find(list, Cfg[k]) then Cfg[k] = D[k] end end
    if Cfg.DashCdMax < Cfg.DashCdMin then Cfg.DashCdMax = Cfg.DashCdMin end
    if Cfg.FarDist <= Cfg.NearDist then Cfg.FarDist = Cfg.NearDist + 1 end
    if not colorOf(Cfg.Tint) then Cfg.Tint = D.Tint end
    for _, k in ipairs(TEXTKEYS) do Cfg[k] = tostring(Cfg[k] or "") end
end
function P.set(k, v) Cfg[k] = v; P.sanitize() end

Features.pursuer = {
    serialize = function() local o = {}; for k, v in pairs(Cfg) do if k ~= "Enabled" then o[k] = v end end; return o end,   -- no Enabled here: saved Pursuer looks reuse this, and loading a look must not arm it (configs save that switch in "switches")
    apply = function(data)
        if type(data) ~= "table" then return end
        if data.PanicBoost == true and data.PanicMode == nil then data = setmetatable({ PanicMode = "Increase By Percent" }, { __index = data }) end   -- saved before the panic options existed
        for k, dv in pairs(D) do
            local v = data[k]
            if k ~= "Enabled" and v ~= nil and type(v) == type(dv) then Cfg[k] = v end
        end
        P.sanitize()
    end,
}

----------------------------------------------------------------------
-- ASSET SOURCES  (rbxassetid / link / file in TonyScriptPalace/Pursuer/Images or /Sounds)
----------------------------------------------------------------------
local IMG_EXT = { png = true, jpg = true, jpeg = true, webp = true, bmp = true, tga = true }
local SND_EXT = { mp3 = true, ogg = true, wav = true, flac = true }
local memo = {}

local function hashS(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format("%08x%x", h, #s)
end
local function normalizeUrl(u)
    u = trim(u)
    local id = u:match("drive%.google%.com/file/d/([%w_%-]+)") or u:match("drive%.google%.com/open%?id=([%w_%-]+)")
    if id then return "https://drive.google.com/uc?export=download&id=" .. id end
    local repo, rest = u:match("^https://github%.com/([^/]+/[^/]+)/blob/(.+)$")
    if repo then return "https://raw.githubusercontent.com/" .. repo .. "/" .. rest end
    if u:find("dropbox.com", 1, true) then
        u = u:gsub("[?&]dl=0", ""):gsub("[?&]raw=1", "")
        u = u .. (u:find("?", 1, true) and "&" or "?") .. "dl=1"
    end
    return u
end
local function sniff(b, kind)
    if kind == "img" then
        if b:sub(1, 4) == "\137PNG" then return "png" end
        if b:sub(1, 3) == "\255\216\255" then return "jpg" end
        if b:sub(1, 4) == "RIFF" and b:sub(9, 12) == "WEBP" then return "webp" end
        if b:sub(1, 3) == "GIF" then return "gif" end
        if b:sub(1, 2) == "BM" then return "bmp" end
        return nil
    end
    if b:sub(1, 3) == "ID3" then return "mp3" end
    local h = b:sub(1, 4)
    if h == "OggS" then return "ogg" end
    if h == "RIFF" then return "wav" end
    if h == "fLaC" then return "flac" end
    if b:sub(5, 8) == "ftyp" then return "m4a" end
    local b1, b2 = b:byte(1, 2)
    if b1 == 0xFF and b2 and bit32.band(b2, 0xE0) == 0xE0 then return "mp3" end
    return nil
end
local function isHtml(b)
    local h = b:sub(1, 300):lower()
    return h:find("<!doctype", 1, true) ~= nil or h:find("<html", 1, true) ~= nil
end
local function fetchBody(url)
    if not httpReq then return nil, "This executor has no request()." end
    local ok, res = pcall(httpReq, { Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
    if not ok then return nil, "Request failed: " .. tostring(res) end
    if not res then return nil, "No response." end
    local code = res.StatusCode or res.status_code or 0
    if code >= 400 then return nil, "Server answered HTTP " .. code .. " (is the link public?)" end
    return res.Body or "", nil
end
local function cachedFile(key)
    for _, e in ipairs({ "png", "jpg", "webp", "bmp", "mp3", "ogg", "wav", "flac" }) do
        local p = CACHE_DIR .. "/" .. key .. "." .. e
        if isF(p) then return p end
    end
end
local function findFile(kind, name)
    name = tostring(name):gsub("\\", "/")
    if isF(name) then return name end
    local dir = (kind == "img") and IMG_DIR or SND_DIR
    if isF(dir .. "/" .. name) then return dir .. "/" .. name end
    local ln = name:lower():gsub("^.*/", "")
    for _, p in ipairs(lsD(dir)) do
        local n = baseName(p):lower()
        if n == ln or (n:gsub("%.%w+$", "")) == ln then return dir .. "/" .. baseName(p) end
    end
end
function P.listFiles(kind)
    local dir, okExt = (kind == "img") and IMG_DIR or SND_DIR, (kind == "img") and IMG_EXT or SND_EXT
    local out = {}
    for _, p in ipairs(lsD(dir)) do
        local n = baseName(p)
        local e = n:match("%.(%w+)$")
        if e and okExt[e:lower()] then out[#out + 1] = n end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end

-- cb(asset) or cb(nil, errorMessage). Results are remembered, so a source is only fetched once.
local function resolve(kind, src, cb)
    src = trim(src or "")
    if src == "" then return cb(nil, "empty") end
    local mk = kind .. "|" .. src
    if memo[mk] then return cb(memo[mk]) end
    local function done(a, e) if a then memo[mk] = a end; cb(a, e) end
    local num = src:match("^(%d+)$") or src:match("^rbxassetid://(%d+)$")
    if num then return done("rbxassetid://" .. num) end
    if src:sub(1, 11) == "rbxasset://" then return done(src) end
    if not getasset then return cb(nil, "This executor has no getcustomasset.") end
    task.spawn(function()
        local path
        if src:match("^https?://") then
            local url = normalizeUrl(src)
            local key = hashS(url)
            path = cachedFile(key)
            if not path then
                local body, err = fetchBody(url)
                if not body then return cb(nil, err) end
                if isHtml(body) then return cb(nil, "That link gave a web page, not a file. Use a direct download link.") end
                if #body < 100 then return cb(nil, "Downloaded file is too small.") end
                local ext = sniff(body, kind)
                if ext == "gif" then return cb(nil, "GIFs can't be used by Roblox. Turn it into a sprite sheet (a grid of frames) and use Sprite Sheet mode.") end
                if ext == "m4a" then return cb(nil, "m4a isn't supported by Roblox. Convert it to mp3 or ogg.") end
                if not ext then return cb(nil, "Unrecognised file type.") end
                path = CACHE_DIR .. "/" .. key .. "." .. ext
                if not wrF(path, body) then return cb(nil, "Couldn't write the cache file.") end
            end
        else
            path = findFile(kind, src)
            if not path then return cb(nil, "File not found: " .. src .. " (put it in TonyScriptPalace/Pursuer/" .. (kind == "img" and "Images" or "Sounds") .. ")") end
        end
        local ok, res = pcall(getasset, path)
        if ok and res then done(res) else cb(nil, "getcustomasset failed: " .. tostring(res)) end
    end)
end
P.resolve = resolve

----------------------------------------------------------------------
-- IMAGE (single picture, sprite sheet or list of frames)
----------------------------------------------------------------------
local img = { key = nil, tok = 0, list = {}, err = nil, busy = false }
function P.imageState()
    local key = Cfg.ImageMode .. "|" .. Cfg.ImageSrc .. "|" .. Cfg.FrameList
    if key ~= img.key then
        img.key = key; img.tok += 1
        local tok = img.tok
        img.list, img.err, img.busy = {}, nil, false
        local srcs = {}
        if Cfg.ImageMode == "Frame List" then
            for part in Cfg.FrameList:gmatch("[^|]+") do
                local p = trim(part)
                if p ~= "" then srcs[#srcs + 1] = p end
            end
        elseif trim(Cfg.ImageSrc) ~= "" then srcs[1] = trim(Cfg.ImageSrc) end
        if #srcs > 0 then
            img.busy = true
            local got, left = {}, #srcs
            for i, s in ipairs(srcs) do
                resolve("img", s, function(a, e)
                    if tok ~= img.tok then return end
                    if a then got[i] = a else img.err = tostring(e) end
                    left -= 1
                    if left == 0 then
                        local l = {}
                        for j = 1, #srcs do if got[j] then l[#l + 1] = got[j] end end
                        img.list, img.busy = l, false
                    end
                end)
            end
        end
    end
    return img
end

function P.imageStatus()
    local st = P.imageState()
    if st.busy then return "Loading the picture..." end
    if st.err then return "Picture problem: " .. st.err end
    if #st.list == 0 then return "No picture set yet: it shows as a red block." end
    return #st.list > 1 and ("Loaded " .. #st.list .. " frames.") or "Picture loaded."
end
function P.reload()
    for k in pairs(memo) do memo[k] = nil end
    img.key = nil
end

local tintKey, tintVal = nil, WHITE
local function tint()
    if tintKey ~= Cfg.Tint then tintKey = Cfg.Tint; tintVal = colorOf(Cfg.Tint) or WHITE end
    return tintVal
end

-- a clipping frame + an image label inside it (a sprite sheet is just a big label that slides behind the clip)
function P.buildSprite(parent)
    local clip = Instance.new("Frame")
    clip.Name = "Clip"; clip.BackgroundColor3 = Color3.fromRGB(200, 30, 40); clip.BackgroundTransparency = 1
    clip.BorderSizePixel = 0; clip.Size = UDim2.fromScale(1, 1); clip.ClipsDescendants = true
    clip.Parent = parent
    local im = Instance.new("ImageLabel")
    im.Name = "Img"; im.BackgroundTransparency = 1; im.BorderSizePixel = 0; im.Size = UDim2.fromScale(1, 1)
    im.ScaleType = Enum.ScaleType.Stretch; im.Visible = false; im.Parent = clip
    return { clip = clip, img = im }
end

-- draws the current frame. returns true when a picture is showing (false: placeholder block or nothing)
function P.paintSprite(sp, t, alpha)
    local st = P.imageState()
    local im = sp.img
    local asset, cols, rows, idx = nil, 1, 1, 0
    if Cfg.ImageMode == "Frame List" then
        local n = #st.list
        if n > 0 then idx = math.floor(t * Cfg.FPS) % n; asset = st.list[idx + 1] end
    else
        asset = st.list[1]
        if Cfg.ImageMode == "Sprite Sheet" then
            cols, rows = math.max(1, math.floor(Cfg.Cols)), math.max(1, math.floor(Cfg.Rows))
            local n = math.clamp(math.floor(Cfg.FrameCount), 1, cols * rows)
            idx = math.floor(t * Cfg.FPS) % n
        end
    end
    local vis = math.clamp(alpha * Cfg.Opacity, 0, 1)
    if not asset then
        im.Visible = false
        sp.clip.BackgroundTransparency = 1 - 0.85 * vis          -- no picture yet: a plain red block so you can still see what you're fighting
        return false
    end
    sp.clip.BackgroundTransparency = 1
    if im.Image ~= asset then im.Image = asset end
    im.Visible = true
    local sz = UDim2.fromScale(cols, rows)
    if im.Size ~= sz then im.Size = sz end
    im.Position = UDim2.fromScale(-(idx % cols), -math.floor(idx / cols))
    im.ImageTransparency = 1 - vis
    im.ImageColor3 = tint()
    local want = Cfg.Pixelated and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default
    if im.ResampleMode ~= want then im.ResampleMode = want end
    return true
end

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------
-- phase: off | waiting | flash | chase | dead | fading | gone
local E = {
    phase = "off", alpha = 0, pos = Vector3.zero, prev = Vector3.zero, face = Vector3.new(0, 0, 1),
    t0 = 0, spawnedFloor = -1, forced = false, dist = 0, speedNow = 0, dash = "idle", dashT = 0, dashDist = 0, dashDir = Vector3.zero,
    nextDash = 0, shake = 0, afterT = 0, nAfter = 0, timer = 120, timerOn = false, deadAt = 0,
    filterAt = -10, pathAt = 0, pathBusy = false, pathTok = 0, stuckT = 0, stuckPos = Vector3.zero, path = nil, pathI = 1, pathGoal = nil,
    why = "Off", hudUntil = 0, hudTxt = nil,
}
P.E = E
local F = { id = 0, floor = nil, active = nil, sawOpen = false, closed = false, joinedMid = false, t0 = 0, open = false }
P.F = F

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.IgnoreWater = true
pcall(function() rp.RespectCanCollide = true end)

local function infoVal(name)
    local i = Workspace:FindFirstChild("Info")
    local v = i and i:FindFirstChild(name)
    if v and v:IsA("ValueBase") then return v.Value end
end
local function me()
    local ch = LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not (ch and hrp and hum) then return nil end
    return ch, hrp, hum, ch:FindFirstChild("Stats"), hrp.Position.Y - hrp.Size.Y / 2 - hum.HipHeight
end
local function suppressed()
    local i = Workspace:FindFirstChild("Info")
    local cm = i and i:FindFirstChild("CardModifiers")
    return cm ~= nil and cm:FindFirstChild("MonsterPanicReduction") ~= nil    -- the Suppression card
end
-- speed in panic mode. The Suppression card can lower the boost: by a flat amount (in the boost's own unit) or by a percentage of it.
local function panicOn() return Cfg.PanicMode ~= "Off" and infoVal("Panic") == true end
local function panicAmount(base)
    if suppressed() then
        if Cfg.SuppressMode == "Lower By Flat Amount" then return math.max(base - Cfg.SuppressFlat, 0)
        elseif Cfg.SuppressMode == "Lower By Percent" then return base * (1 - Cfg.SuppressPercent / 100) end
    end
    return base
end
function P.panicMult()     -- percent mode as a plain multiplier (also used for the up and down speed)
    if panicOn() and Cfg.PanicMode == "Increase By Percent" then return 1 + panicAmount(Cfg.PanicPercent) / 100 end
    return 1
end
function P.panicAdjust(spd, dash)
    if spd <= 0 or not panicOn() then return spd end       -- a pursuer standing still (stops near you) stays still
    local m = Cfg.PanicMode
    if m == "Increase By Percent" then return spd * P.panicMult()
    elseif m == "Increase By Flat Amount" then return spd + panicAmount(Cfg.PanicFlat)
    elseif m == "Set Speed To" and not dash then return math.max(panicAmount(Cfg.PanicSet), 0) end   -- the dash keeps its own speed
    return spd
end

local function ensureFolder()
    if not E.folder then
        E.folder = Instance.new("Folder"); E.folder.Name = "TSP_Pursuer"
    end
    local want = Workspace.CurrentCamera or Workspace
    if E.folder.Parent ~= want then E.folder.Parent = want end
end
local function refreshFilter()
    local list = { E.folder }
    for _, n in ipairs({ "InGamePlayers", "Players" }) do
        local f = Workspace:FindFirstChild(n)
        if f then list[#list + 1] = f end
    end
    if LP.Character then list[#list + 1] = LP.Character end
    local cr = Workspace:FindFirstChild("CurrentRoom")
    if cr then
        for _, room in ipairs(cr:GetChildren()) do
            for _, n in ipairs({ "Monsters", "Items" }) do
                local f = room:FindFirstChild(n)
                if f then list[#list + 1] = f end
            end
        end
    end
    rp.FilterDescendantsInstances = list
end

----------------------------------------------------------------------
-- SOUNDS
----------------------------------------------------------------------
local function playOnce(kind, src, vol)
    resolve("snd", src, function(a)
        if not a or not alive or not E.folder then return end
        local s = Instance.new("Sound")
        s.SoundId = a; s.Volume = vol; s.Parent = E.folder
        s.Ended:Connect(function() s:Destroy() end)
        s:Play()
        task.delay(30, function() if s.Parent then s:Destroy() end end)
    end)
end
local function stopMusic()
    if E.music then pcall(function() E.music.sound:Destroy() end); E.music = nil end
end
local function updateMusic()
    local want = Cfg.Music and trim(Cfg.MusicSrc) ~= "" and E.body ~= nil and (E.phase == "flash" or E.phase == "chase" or E.phase == "fading")
    if not want then if E.music then stopMusic() end; return end
    local key = Cfg.MusicSrc .. "|" .. tostring(Cfg.Music3D)
    if E.music and E.music.key ~= key then stopMusic() end
    if not E.music then
        E.musicTok = (E.musicTok or 0) + 1
        local tok = E.musicTok
        E.music = { key = key, pending = true }
        resolve("snd", Cfg.MusicSrc, function(a, err)
            if tok ~= E.musicTok or not E.music or not E.body then return end
            local s = Instance.new("Sound")
            s.SoundId = a or ""; s.Looped = true; s.Volume = 0
            if Cfg.Music3D then
                s.RollOffMode = Enum.RollOffMode.InverseTapered
                s.RollOffMinDistance = 10
                s.RollOffMaxDistance = Cfg.MusicRange
                s.Parent = E.body.part
            else s.Parent = E.folder end
            E.music.sound = s; E.music.pending = nil
            if a then s:Play() else P.say("Pursuer music: " .. tostring(err), "err") end
        end)
    end
    local m = E.music
    if m and m.sound and m.sound.Parent then
        m.sound.Volume = Cfg.MusicVol * E.alpha
        if Cfg.Music3D then m.sound.RollOffMaxDistance = Cfg.MusicRange end
    end
end

----------------------------------------------------------------------
-- BODY (an invisible part carrying the picture on a SurfaceGui, so walls hide it like any other object)
----------------------------------------------------------------------
local function makeBody()
    local part = Instance.new("Part")
    part.Name = "PursuerBody"; part.Anchored = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
    part.CastShadow = false; part.Transparency = 1; part.Size = Vector3.new(Cfg.Width, Cfg.Height, 0.05)
    local b = { part = part, w = -1, h = -1, li = -1 }
    local function gui(face)
        local g = Instance.new("SurfaceGui")
        g.Face = face; g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; g.CanvasSize = Vector2.new(512, 512)
        g.LightInfluence = 1; g.ResetOnSpawn = false; g.AlwaysOnTop = false; g.Adornee = part; g.Parent = part
        return g
    end
    b.gF = gui(Enum.NormalId.Front); b.gB = gui(Enum.NormalId.Back)
    b.spF = P.buildSprite(b.gF); b.spB = P.buildSprite(b.gB)
    b.light = Instance.new("PointLight"); b.light.Enabled = false; b.light.Parent = part
    part.Parent = E.folder
    return b
end
local function killBody()
    stopMusic()
    if E.body then pcall(function() E.body.part:Destroy() end); E.body = nil end
end

local function bodyCenter()
    local h = Cfg.Height
    return Vector3.new(E.pos.X, E.pos.Y + (Cfg.FeetOnGround and h / 2 or Cfg.Hover), E.pos.Z)
end
local function emissiveOn()
    if Cfg.Emissive == "Always" then return true end
    return Cfg.Emissive == "During Blackouts" and infoVal("BlackOut") == true
end

local function updateBody(t)
    local b = E.body
    if not b then return end
    local w, h = Cfg.Width, Cfg.Height
    if b.w ~= w or b.h ~= h then
        b.w, b.h = w, h
        b.part.Size = Vector3.new(w, h, 0.05)
        local pps = math.clamp(1024 / math.max(w, h), 8, 64)
        local cv = Vector2.new(math.max(16, math.floor(w * pps)), math.max(16, math.floor(h * pps)))
        b.gF.CanvasSize = cv; b.gB.CanvasSize = cv
    end
    local center = bodyCenter()
    if E.shake > 0 then center += Vector3.new((math.random() - 0.5) * E.shake, 0, (math.random() - 0.5) * E.shake) end
    local cam = Workspace.CurrentCamera
    local cf
    if Cfg.Billboard == "Full" and cam then
        local c = cam.CFrame
        cf = CFrame.fromMatrix(center, -c.RightVector, c.UpVector, c.LookVector)
    elseif Cfg.Billboard == "Y Only" and cam then
        local d = Vector3.new(cam.CFrame.Position.X - center.X, 0, cam.CFrame.Position.Z - center.Z)
        if d.Magnitude < 0.01 then d = E.face end
        cf = CFrame.lookAt(center, center + d)
    else
        cf = CFrame.lookAt(center, center + E.face)
    end
    b.part.CFrame = cf
    local emi = emissiveOn()
    local li = emi and 0 or 1
    if b.li ~= li then b.li = li; b.gF.LightInfluence = li; b.gB.LightInfluence = li end
    P.paintSprite(b.spF, t, E.alpha)
    local both = Cfg.Billboard == "Off"
    b.gB.Enabled = both
    if both then P.paintSprite(b.spB, t, E.alpha) end
    local glow = Cfg.GlowLight and emi
    b.light.Enabled = glow and E.alpha > 0.05
    if glow then b.light.Color = tint(); b.light.Brightness = 2 * E.alpha; b.light.Range = math.max(w, h) * 3 + 8 end
end

local function afterimage()
    local b = E.body
    if not b or E.nAfter >= 24 then return end
    local c = b.part:Clone()
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("Sound") or d:IsA("PointLight") then d:Destroy()
        elseif d:IsA("SurfaceGui") then d.Adornee = c end      -- a clone still points at the original part otherwise
    end
    c.Parent = E.folder
    E.nAfter += 1
    local start = 1 - math.clamp(Cfg.AfterStart * E.alpha * Cfg.Opacity, 0, 1)
    local ti = TweenInfo.new(Cfg.AfterFade, Enum.EasingStyle.Linear)
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("ImageLabel") then
            d.ImageTransparency = start
            TweenService:Create(d, ti, { ImageTransparency = 1 }):Play()
        elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
            d.BackgroundTransparency = math.max(d.BackgroundTransparency, start)
            TweenService:Create(d, ti, { BackgroundTransparency = 1 }):Play()
        end
    end
    task.delay(Cfg.AfterFade + 0.1, function()
        E.nAfter = math.max(0, E.nAfter - 1)
        pcall(function() c:Destroy() end)
    end)
end

----------------------------------------------------------------------
-- FLOOR TRACKING (the elevator opens, you walk out, it closes)
----------------------------------------------------------------------
local function elevatorOpen()
    local el = Workspace:FindFirstChild("Elevators")
    if not el then return false end
    for _, e in ipairs(el:GetChildren()) do
        local o = e:FindFirstChild("Opened")
        if o and o:IsA("BoolValue") and o.Value then return true end
    end
    return false
end
local function trackFloor(t, active)
    local fl = infoVal("Floor")
    local open = elevatorOpen()
    if F.floor ~= fl or (active and not F.active) then
        F.id += 1; F.t0 = t; F.sawOpen = open; F.closed = false
        F.joinedMid = (F.id == 1) and active and not open      -- the script was loaded in the middle of a floor
        if F.joinedMid then F.closed = true end
        E.timer = Cfg.Timer; E.timerOn = false
    end
    F.floor, F.active, F.open = fl, active, open
    if not F.closed then
        if open then F.sawOpen = true
        elseif F.sawOpen then F.closed = true
        elseif active and t - F.t0 > 25 then F.closed = true end   -- never saw it open: do not wait forever
    end
end

-- keeps the pursuer out of the elevator room (the game's own MonsterBlocker box)
local function avoidElevator()
    local el = Workspace:FindFirstChild("Elevators")
    if not el then return end
    for _, e in ipairs(el:GetChildren()) do
        local hb = e:FindFirstChild("MonsterBlocker") or e:FindFirstChild("ElevatorHitBox")
        if hb and hb:IsA("BasePart") then
            local lp = hb.CFrame:PointToObjectSpace(E.pos + Vector3.new(0, 2, 0))
            local hx, hy, hz = hb.Size.X / 2 + 1.5, hb.Size.Y / 2, hb.Size.Z / 2 + 1.5
            if math.abs(lp.X) < hx and math.abs(lp.Y) < hy and math.abs(lp.Z) < hz then
                local dx, dz = hx - math.abs(lp.X), hz - math.abs(lp.Z)
                local nl
                if dx < dz then nl = Vector3.new((lp.X >= 0 and hx or -hx), lp.Y, lp.Z) else nl = Vector3.new(lp.X, lp.Y, (lp.Z >= 0 and hz or -hz)) end
                local w = hb.CFrame:PointToWorldSpace(nl)
                E.pos = Vector3.new(w.X, E.pos.Y, w.Z)
            end
        end
    end
end

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
-- speed while you are extracting (choosing a mode here replaces the pause)
local function decodeAdjust(spd)
    if not E.decoding or spd <= 0 then return spd end      -- a pursuer that is standing still (stops near you) stays still
    local m = Cfg.DecodeSlow
    if m == "Slow By Flat Amount" then return math.max(spd - Cfg.DecodeFlat, 0)
    elseif m == "Slow By Percent" then return spd * (1 - math.clamp(Cfg.DecodePercent, 0, 100) / 100)
    elseif m == "Set Speed To" then return math.max(Cfg.DecodeSet, 0) end
    return spd
end

local function speedFor(d)
    local m, mode = 1, Cfg.SpeedMode
    local span = math.max(Cfg.FarDist - Cfg.NearDist, 0.1)
    local k = math.clamp((d - Cfg.NearDist) / span, 0, 1)
    if mode == "Faster When Far" then m = 1 + (Cfg.FarMult - 1) * k
    elseif mode == "Slower When Close" then m = Cfg.CloseMult + (1 - Cfg.CloseMult) * k
    elseif mode == "Faster Far, Slower Close" then m = Cfg.CloseMult + (Cfg.FarMult - Cfg.CloseMult) * k
    elseif mode == "Slower When Close, Stops Near" then m = (d <= Cfg.StopDist) and 0 or (Cfg.CloseMult + (1 - Cfg.CloseMult) * k) end
    return decodeAdjust(P.panicAdjust(Cfg.Speed * m))
end
function P.currentSpeed() return E.speedNow end

local function radius() return 1.2 end      -- collision body is small and fixed: the picture can be huge, but doorways are narrow

-- moves along dir (flat unit) for dist studs, sliding along walls. Returns the movement and whether a wall stopped it.
local function slideStep(dir, dist)
    local origin = Vector3.new(E.pos.X, E.pos.Y + 3, E.pos.Z)
    local reach = dist + radius()
    local hit = Workspace:Raycast(origin, dir * reach, rp)
    if not hit or hit.Normal.Y > 0.6 then return dir * dist, false end     -- floors and ramps are not walls
    local n = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
    if n.Magnitude < 0.01 then return Vector3.zero, true end
    n = n.Unit
    local slide = dir - n * dir:Dot(n)
    if slide.Magnitude < 0.08 then return Vector3.zero, true end
    slide = slide.Unit
    local h2 = Workspace:Raycast(origin, slide * reach, rp)
    if h2 and h2.Normal.Y <= 0.6 then return Vector3.zero, true end
    return slide * dist * 0.9, true
end

local function clearLine(hrp)
    local y = hrp.Position.Y
    local from = Vector3.new(E.pos.X, y, E.pos.Z)
    local to = hrp.Position
    local d = to - from
    if d.Magnitude < 1 then return true end
    local side = Vector3.new(-d.Z, 0, d.X)
    side = side.Magnitude > 0.01 and side.Unit * radius() or Vector3.zero
    for _, off in ipairs({ Vector3.zero, side, -side }) do
        if Workspace:Raycast(from + off, d, rp) then return false end
    end
    return true
end

local function requestPath(goal)
    if E.pathBusy then return end
    E.pathBusy = true
    E.pathGoal = goal
    local tok, from = E.pathTok, E.pos
    task.spawn(function()
        local ok, path = pcall(function()
            -- radius 1.5 succeeds in these rooms, 3 does not (tested in game); 1 is the fallback for very tight spots
            local p
            for _, r in ipairs({ 1.5, 1 }) do
                p = PathfindingService:CreatePath({ AgentRadius = r, AgentHeight = 5, AgentCanJump = false, AgentCanClimb = false, WaypointSpacing = 5 })
                p:ComputeAsync(from, goal)
                if p.Status == Enum.PathStatus.Success then break end
            end
            return p
        end)
        E.pathBusy = false
        E.pathAt = os.clock()
        if tok ~= E.pathTok then return end
        if ok and path and path.Status == Enum.PathStatus.Success then
            E.path = path:GetWaypoints(); E.pathI = 2
        else E.path = nil end
    end)
end
local function pathDir(t, goal)
    local stale = (E.path == nil and t - E.pathAt > 0.5) or (t - E.pathAt > 1.2)
    local moved = E.pathGoal and (goal - E.pathGoal).Magnitude > 6 and t - E.pathAt > 0.35
    if (stale or moved) and not E.pathBusy then requestPath(goal) end
    if E.path then
        local wp = E.path[E.pathI]
        while wp do
            local dx, dz = wp.Position.X - E.pos.X, wp.Position.Z - E.pos.Z
            if math.sqrt(dx * dx + dz * dz) < 2.5 then E.pathI += 1; wp = E.path[E.pathI] else break end
        end
        if wp then return Vector3.new(wp.Position.X - E.pos.X, 0, wp.Position.Z - E.pos.Z) end
    end
    return nil
end

local function updateY(dt, myFeet)
    if Cfg.Vertical == "Fly Up And Down" then
        -- it rises and falls toward your height at its own speed (not a snap), only while it is actually moving
        if E.phase ~= "chase" or E.dash == "dashing" or E.speedNow <= 0.01 then return end
        local maxd = Cfg.VertSpeed * P.panicMult() * dt
        local ty = myFeet + Cfg.FlyOffset
        E.pos = Vector3.new(E.pos.X, E.pos.Y + math.clamp(ty - E.pos.Y, -maxd, maxd), E.pos.Z)
        return
    end
    local ty
    local match = Cfg.Vertical == "Match My Height"
    if match then ty = myFeet
    else
        local hit = Workspace:Raycast(Vector3.new(E.pos.X, E.pos.Y + 3.5, E.pos.Z), Vector3.new(0, -24, 0), rp)
        ty = hit and hit.Position.Y or E.pos.Y        -- no floor below: stay where you are, it never falls
    end
    local maxd = (match and 18 or 30) * dt
    E.pos = Vector3.new(E.pos.X, E.pos.Y + math.clamp(ty - E.pos.Y, -maxd, maxd), E.pos.Z)
end

local function killMe(t, hum)
    if E.phase == "dead" then return end
    E.phase, E.deadAt = "dead", t
    E.speedNow = 0
    stopMusic()
    if hum and hum.Health > 0 then
        hum.Health = 0
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
    end
    if Cfg.DeathSound and trim(Cfg.DeathSrc) ~= "" then playOnce("snd", Cfg.DeathSrc, Cfg.DeathVol) end
end

local function touching(hrp)
    local p, q = E.prev, E.pos
    local a, b, c = Vector2.new(p.X, p.Z), Vector2.new(q.X, q.Z), Vector2.new(hrp.Position.X, hrp.Position.Z)
    local ab = b - a
    local l2 = ab:Dot(ab)
    local u = l2 > 1e-6 and math.clamp((c - a):Dot(ab) / l2, 0, 1) or 0
    if (c - (a + ab * u)).Magnitude > Cfg.Width * 0.5 * Cfg.HitScale + 1 then return false end     -- swept, so a fast dash can't skip over you
    local bottom = q.Y + (Cfg.FeetOnGround and 0 or (Cfg.Hover - Cfg.Height / 2))
    local y = hrp.Position.Y
    return y >= bottom - 3 and y <= bottom + Cfg.Height + 1.5
end

local function chaseStep(dt, t, hrp, myFeet, paused)
    local tp = hrp.Position
    local flat = Vector3.new(tp.X - E.pos.X, 0, tp.Z - E.pos.Z)
    local dist = flat.Magnitude
    E.dist = dist
    E.shake = 0
    if paused then E.speedNow = 0; E.nextDash += dt; E.dashT += dt; return end
    local through = Cfg.WallMode == "Through Walls"

    -- dash (Dark Esau style: stop, shake, then lunge in a straight line)
    if Cfg.Dash then
        if E.dash == "idle" and t >= E.nextDash and dist <= Cfg.DashRange and (not Cfg.DashNeedsSight or through or clearLine(hrp)) then
            E.dash, E.dashT = "windup", t
        end
        if E.dash == "windup" then
            E.speedNow = 0
            E.shake = 0.5
            if flat.Magnitude > 0.01 then E.face = flat.Unit end
            if t - E.dashT >= Cfg.DashWindup then
                E.dash, E.dashDist = "dashing", 0
                E.dashDir = flat.Magnitude > 0.01 and flat.Unit or E.face
                if Cfg.Vertical == "Fly Up And Down" then      -- flying: it lunges straight at you, up or down
                    local d3 = Vector3.new(tp.X - E.pos.X, (myFeet + Cfg.FlyOffset) - E.pos.Y, tp.Z - E.pos.Z)
                    if d3.Magnitude > 0.01 then E.dashDir = d3.Unit end
                end
                E.shake = 0
            end
            return
        elseif E.dash == "dashing" then
            local spd = decodeAdjust(P.panicAdjust(Cfg.DashSpeed, true))
            local step = spd * dt
            E.speedNow = spd
            local mv, blocked = E.dashDir * step, false
            if not through then
                local hit = Workspace:Raycast(Vector3.new(E.pos.X, E.pos.Y + 3, E.pos.Z), E.dashDir * (step + radius()), rp)
                -- floors don't count as walls on the ground, but a flying dash must not dive through them
                if hit and (hit.Normal.Y <= 0.6 or Cfg.Vertical == "Fly Up And Down") then mv, blocked = Vector3.zero, true end
            end
            E.pos += mv
            local fl = Vector3.new(E.dashDir.X, 0, E.dashDir.Z)
            if fl.Magnitude > 0.01 then E.face = fl.Unit end
            E.dashDist += step
            if blocked or E.dashDist >= Cfg.DashDistance then
                E.dash = "idle"
                E.nextDash = t + Cfg.DashCdMin + math.random() * (Cfg.DashCdMax - Cfg.DashCdMin)
            end
            return
        end
    else E.dash = "idle" end

    -- normal chase
    local spd = speedFor(dist)
    E.speedNow = spd
    local dirV
    if through then
        dirV = flat
    elseif clearLine(hrp) then
        dirV = flat
        E.path = nil
    else
        dirV = pathDir(t, Vector3.new(tp.X, myFeet, tp.Z)) or flat
    end
    if spd > 0 and dirV.Magnitude > 0.01 then
        local u = dirV.Unit
        local step = spd * dt
        if dist < step then step = dist end
        local mv = u * step
        if not through then mv = slideStep(u, step) end
        E.pos += mv
        if mv.Magnitude > 0.001 then E.face = E.face:Lerp(mv.Unit, math.min(1, dt * 10)) end
        -- stuck? ask for a fresh path
        if t - E.stuckT > 0.8 then
            if not through and (E.pos - E.stuckPos).Magnitude < spd * 0.15 and dist > 6 then E.path = nil; E.pathAt = 0 end
            E.stuckT, E.stuckPos = t, E.pos
        end
    end
end

----------------------------------------------------------------------
-- CHASE ALERT: the game's own "spotted" sound and eye icon
-- The game draws the eye and the little counter from a number on your player (ChaseCount). We add one to it while the
-- pursuer is chasing, so the game's own UI shows and counts it exactly like a Twisted.
----------------------------------------------------------------------
local SPOT_PATH = { ["Spotted"] = "Sounds.UI.Alerts.Spotted", ["Spotted 2"] = "Sounds.UI.Alerts.Spotted2" }
local audioMod
local function playSpotted()
    local ok = pcall(function()
        audioMod = audioMod or require(game:GetService("ReplicatedStorage"):WaitForChild("SharedUtils", 2):WaitForChild("Audio", 2))
        audioMod:PlayOne(SPOT_PATH[Cfg.SpotVariant] or SPOT_PATH.Spotted)
    end)
    if ok then return end
    pcall(function()      -- fallback: a copy of the game's own sound object
        local g = LP.PlayerGui:FindFirstChild("ScreenGui")
        local snd = g and g:FindFirstChild(Cfg.SpotVariant == "Spotted 2" and "Spotted2" or "Spotted")
        if snd then
            local c = snd:Clone(); c.Parent = snd.Parent
            c.Ended:Connect(function() c:Destroy() end)
            c:Play()
            task.delay(15, function() if c.Parent then c:Destroy() end end)
        end
    end)
end

local countConn
local function chaseAttr() return tonumber(LP:GetAttribute("ChaseCount")) or 0 end
local function writeCount(v) E.lastSet = v; LP:SetAttribute("ChaseCount", v) end
local function setCounted(want)
    if want == (E.counted == true) then return end
    E.counted = want
    if want then
        if not countConn then
            countConn = LP:GetAttributeChangedSignal("ChaseCount"):Connect(function()
                if not E.counted then return end
                local v = chaseAttr()
                if v ~= E.lastSet then writeCount(v + 1) end     -- the game wrote its own count: put ourselves back on top of it
            end)
        end
        writeCount(chaseAttr() + 1)
    else
        local v = chaseAttr()
        if v > 0 then writeCount(v - 1) end
    end
end

----------------------------------------------------------------------
-- SPAWN / DESPAWN
----------------------------------------------------------------------
function P.spawn(force)
    local ch, hrp, hum, stats, myFeet = me()
    if not hrp then return false end
    ensureFolder(); refreshFilter()
    killBody()
    E.body = makeBody()
    E.pos = Vector3.new(hrp.Position.X, myFeet, hrp.Position.Z)       -- it appears exactly where you stand
    E.prev = E.pos
    local look = hrp.CFrame.LookVector
    E.face = Vector3.new(look.X, 0, look.Z); if E.face.Magnitude < 0.01 then E.face = Vector3.new(0, 0, 1) end; E.face = E.face.Unit
    E.phase, E.t0, E.alpha, E.forced = "flash", os.clock(), 0.1, force == true
    E.spawnedFloor = F.id
    E.dash, E.shake, E.path, E.pathAt, E.pathTok = "idle", 0, nil, 0, E.pathTok + 1
    E.nextDash = 0
    E.hudUntil = 0
    if Cfg.SpawnSound and trim(Cfg.SpawnSrc) ~= "" then playOnce("snd", Cfg.SpawnSrc, Cfg.SpawnVol) end
    return true
end
function P.despawn(instant)
    setCounted(false)
    if instant or not E.body then killBody(); E.phase = Cfg.Enabled and "waiting" or "off"; E.alpha = 0; return end
    E.phase = "fading"
end

local function beginChase(t)
    E.phase, E.alpha = "chase", 1
    if Cfg.SpotSound then playSpotted() end      -- the "a Twisted has spotted you" sound
    E.nextDash = t + Cfg.DashCdMin + math.random() * (Cfg.DashCdMax - Cfg.DashCdMin)
    E.dash = "idle"
    E.stuckT, E.stuckPos = t, E.pos
end

----------------------------------------------------------------------
-- TIMER HUD (like the Pizza Time bar)
----------------------------------------------------------------------
local hud
local function hudDestroy() if hud then pcall(function() hud.gui:Destroy() end); hud = nil end end
local function hudUpdate(show, text, frac, urgent)
    if not show then if hud then hud.gui.Enabled = false end; return end
    if not hud then
        local g = Instance.new("ScreenGui")
        g.Name = "TSP_PursuerHud"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 50
        g.Parent = guiParent()
        local root = Instance.new("Frame"); root.BackgroundTransparency = 1; root.AnchorPoint = Vector2.new(0.5, 0); root.Position = UDim2.new(0.5, 0, 0, 14); root.Size = UDim2.fromOffset(300, 74); root.Parent = g
        local lab = Instance.new("TextLabel"); lab.BackgroundTransparency = 1; lab.Size = UDim2.new(1, 0, 0, 46); lab.Font = Enum.Font.GothamBlack; lab.TextSize = 40
        lab.TextColor3 = Color3.fromRGB(255, 214, 64); lab.TextStrokeTransparency = 0; lab.TextStrokeColor3 = Color3.new(0, 0, 0); lab.Parent = root
        local sub = Instance.new("TextLabel"); sub.BackgroundTransparency = 1; sub.Position = UDim2.fromOffset(0, 46); sub.Size = UDim2.new(1, 0, 0, 14); sub.Font = Enum.Font.GothamBold; sub.TextSize = 12
        sub.Text = "SOMETHING IS COMING"; sub.TextColor3 = Color3.fromRGB(255, 255, 255); sub.TextStrokeTransparency = 0.4; sub.Parent = root
        local back = Instance.new("Frame"); back.BackgroundColor3 = Color3.new(0, 0, 0); back.BackgroundTransparency = 0.35; back.BorderSizePixel = 0; back.Position = UDim2.fromOffset(20, 64); back.Size = UDim2.new(1, -40, 0, 7); back.Parent = root
        local bar = Instance.new("Frame"); bar.BorderSizePixel = 0; bar.Size = UDim2.fromScale(1, 1); bar.BackgroundColor3 = Color3.fromRGB(255, 190, 40); bar.Parent = back
        hud = { gui = g, root = root, lab = lab, sub = sub, bar = bar }
    end
    hud.gui.Enabled = true
    hud.lab.Text = text
    hud.bar.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
    local col = urgent and Color3.fromRGB(255, 70, 50) or Color3.fromRGB(255, 214, 64)
    hud.lab.TextColor3 = col; hud.bar.BackgroundColor3 = col
    if urgent then hud.root.Position = UDim2.new(0.5, math.random(-2, 2), 0, 14 + math.random(-2, 2)) else hud.root.Position = UDim2.new(0.5, 0, 0, 14) end
end
local function fmtTime(s)
    s = math.max(0, math.ceil(s))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

----------------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------------
local BIND = "TSP_Pursuer"
local function step(dt)
    if not alive then return end
    dt = math.min(dt, 0.1)
    local t = os.clock()
    local active = infoVal("FloorActive") == true
    trackFloor(t, active)
    local ch, hrp, hum, stats, myFeet = me()
    local inElev = false
    if stats then local v = stats:FindFirstChild("InElevator"); inElev = v ~= nil and v:IsA("ValueBase") and v.Value == true end
    local dead = (not hum) or hum.Health <= 0 or LP:GetAttribute("isDead") == true
    local dec = ch and ch:FindFirstChild("Decoding")
    local decoding = dec ~= nil and dec:IsA("ObjectValue") and dec.Value ~= nil
    E.decoding = decoding

    if not Cfg.Enabled then
        setCounted(false)
        if E.phase ~= "off" then killBody(); E.phase = "off"; E.alpha = 0 end
        E.why = "Off"
        hudUpdate(false)
        return
    end
    if E.phase == "off" then E.phase = "waiting"; E.timer = Cfg.Timer; E.timerOn = false end
    ensureFolder()
    if t - E.filterAt > 1 then E.filterAt = t; refreshFilter() end

    local ph = E.phase
    -- things that make it go away: you in the elevator, the floor not running, you dying somewhere it did not kill you
    if (ph == "flash" or ph == "chase") and (inElev or (not active and not E.forced) or dead) then
        E.phase = "fading"; ph = "fading"
    end

    if ph == "waiting" or ph == "gone" then
        E.why = "Waiting"
        local can = hrp and active and not inElev and not dead and E.spawnedFloor ~= F.id
        if Cfg.Trigger == "Right Away" then
            E.why = can and "Spawning" or (inElev and "Waiting (you're in the elevator)" or "Waiting for a floor")
            if can then P.spawn(false) end
        elseif Cfg.Trigger == "When The Elevator Opens" then
            E.why = F.sawOpen and "Waiting for you to leave the elevator" or "Waiting for the elevator to open"
            if can and F.sawOpen and not F.joinedMid then P.spawn(false) end
        else
            -- the timer counts while you are out on a floor with the elevator closed
            local counting = hrp and active and not inElev and not dead and F.closed and E.spawnedFloor ~= F.id
                and not (decoding and Cfg.TimerPauseDecode)
            if counting then
                E.timerOn = true
                E.timer -= dt
            end
            if E.timer < 0 then E.timer = 0 end
            E.why = counting and "Counting down" or (E.spawnedFloor == F.id and "Already spawned this floor" or "Timer paused")
            if can and E.timerOn and E.timer <= 0 and F.closed then P.spawn(false) end
        end
        ph = E.phase
    end

    if ph == "flash" and hrp then
        E.why = "Spawning (can't hurt you yet)"
        local k = (t - E.t0) * Cfg.FlashRate
        E.alpha = 0.12 + 0.68 * (0.5 + 0.5 * math.sin(k * math.pi * 2))
        E.shake = 0
        local waitClose = Cfg.Trigger == "When The Elevator Opens" and not F.closed and not E.forced
        if t - E.t0 >= Cfg.FlashTime then
            if waitClose then E.why = "Spawned, waiting for the elevator to close" else beginChase(t); ph = "chase" end
        end
        updateY(dt, myFeet)
    elseif ph == "chase" and hrp then
        local paused = decoding and Cfg.PauseDecode and Cfg.DecodeSlow == "Off"   -- a speed mode for extracting replaces the pause
        E.why = paused and "Paused (you are extracting)" or (E.dash == "windup" and "Winding up a dash" or (E.dash == "dashing" and "Dashing" or "Chasing"))
        E.prev = E.pos
        chaseStep(dt, t, hrp, myFeet, paused)
        if not inElev then avoidElevator() end
        updateY(dt, myFeet)
        E.alpha = math.min(1, E.alpha + dt * 4)
        if Cfg.After and E.nAfter < 24 and (E.speedNow > 0.5) and (not Cfg.AfterDashOnly or E.dash == "dashing") and t - E.afterT >= Cfg.AfterRate then
            E.afterT = t; afterimage()
        end
        if Cfg.Kill and touching(hrp) then killMe(t, hum) end      -- "Kills You On Touch" off = harmless, for testing
    elseif ph == "dead" then
        E.why = "Got you"
        if t - E.deadAt > 2.5 then E.phase = "fading" end
    elseif ph == "fading" then
        E.why = "Fading away"
        E.alpha = E.alpha - dt * 1.2
        E.shake = 0
        if E.alpha <= 0 then killBody(); E.alpha = 0; E.phase = "gone"; E.dash = "idle" end
    end

    E.dist = hrp and (Vector3.new(hrp.Position.X - E.pos.X, 0, hrp.Position.Z - E.pos.Z)).Magnitude or 0
    setCounted(Cfg.EyeIcon and E.phase == "chase")
    updateBody(t)
    updateMusic()

    -- timer HUD
    local showHud = Cfg.Trigger == "After A Timer" and Cfg.TimerHud and active and not inElev and not dead
    if showHud then
        if E.phase == "waiting" or E.phase == "gone" then
            if E.spawnedFloor ~= F.id then
                hudUpdate(true, fmtTime(E.timer), E.timer / Cfg.Timer, E.timer <= 10 and E.timerOn)
                if hud then hud.sub.Text = E.timerOn and "HURRY UP" or "TIMER STARTS WHEN THE ELEVATOR CLOSES" end
            else hudUpdate(false) end
        elseif E.phase == "flash" or E.phase == "chase" then
            hudUpdate(true, "IT'S HERE", 0, true)
            if hud then hud.sub.Text = "RUN" end
        else hudUpdate(false) end
    else hudUpdate(false) end
end
RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, function(dt)
    local ok, err = pcall(step, dt)
    if not ok and not E.errShown then
        E.errShown = true      -- tell you once instead of every frame
        warn("[Pursuer] " .. tostring(err))
        P.say("Pursuer hit an error (see the console). Turn it off and on to retry.", "err")
    end
end)

function P.status() return E.why end
function P.distance() return E.phase == "chase" and string.format("%.0f studs", E.dist) or "-" end
function P.timerText() return fmtTime(E.timer) end
function P.floorText()
    return string.format("floor %s | elevator %s", tostring(F.floor), F.open and "open" or (F.closed and "closed" or "not opened yet"))
end
function P.active() return E.phase == "flash" or E.phase == "chase" or E.phase == "dead" or E.phase == "fading" end
P.say = function() end      -- the page sets this to the hub's toast

----------------------------------------------------------------------
-- SAVED PURSUERS (TonyScriptPalace/Pursuer/Presets/<name>.json)
----------------------------------------------------------------------
local PRESET_DIR = DIR .. "/Presets"
mkD(PRESET_DIR)
P.presetName = ""
local function presetClean(n) return (trim(n):gsub("[^%w%-_ ]", "_")) end
local function presetPath(n) return PRESET_DIR .. "/" .. presetClean(n) .. ".json" end
function P.presetClean(n) return presetClean(n) end
function P.presetExists(n) n = presetClean(n); return n ~= "" and isF(presetPath(n)) end
function P.listPresets()
    local out = {}
    for _, f in ipairs(lsD(PRESET_DIR)) do
        local n = baseName(f)
        if n:lower():sub(-5) == ".json" then out[#out + 1] = n:sub(1, -6) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
function P.savePreset(n)
    n = presetClean(n)
    if n == "" then return false, "Type a name first." end
    if not writefile then return false, "This executor can't write files." end
    local json = jenc({ Format = 1, Name = n, Settings = Features.pursuer.serialize() })
    if not json then return false, "Couldn't encode the settings." end
    if not wrF(presetPath(n), json) then return false, "Couldn't write the file." end
    return true, n
end
function P.loadPreset(n)
    n = presetClean(n)
    if n == "" then return false, "Pick a saved pursuer first." end
    local raw = isF(presetPath(n)) and rdF(presetPath(n))
    local data = raw and jdec(raw)
    if type(data) ~= "table" or type(data.Settings) ~= "table" then return false, "Couldn't read '" .. n .. "'." end
    Features.pursuer.apply(data.Settings)
    P.reload()
    return true, n
end
function P.deletePreset(n)
    n = presetClean(n)
    if not P.presetExists(n) then return false, "No saved pursuer called '" .. n .. "'." end
    dlF(presetPath(n))
    return true, n
end

function P.Unload()
    pcall(function() RunService:UnbindFromRenderStep(BIND) end)
    pcall(function() setCounted(false) end)
    if countConn then countConn:Disconnect(); countConn = nil end
    killBody()
    hudDestroy()
    if E.folder then pcall(function() E.folder:Destroy() end); E.folder = nil end
end

return P
end)()

-- the hub's existing Fun.Unload also cleans this up
do
    local prevUnload = Fun.Unload
    Fun.Unload = function()
        pcall(Fun.Pur.Unload)
        if prevUnload then prevUnload() end
    end
end

--#endregion pursuer-engine

--#region ui-core
----------------------------------------------------------------------
-- UI CORE
----------------------------------------------------------------------
local UI = { tabs = {}, current = "esp", visible = not S.startHidden, sel = {} }   -- sel[tab id] = key of the section picked in that tab
local T                                   -- active style tokens
local gui, Win, Overlay, Content, StatusLbl, Orb, Grip, UIScaleObj, Host, Rail, PinPane
local guiConns, popup, popupClose = {}, nil, nil
local activeDrag, listening = nil, nil
local buildGui, renderPage, applyLayout, toast, Destroy
local builders = {}
local liveList = {}   -- functions that refresh live text on the current page (5x per second)

local F_AERO = { reg = Enum.Font.SourceSans, semi = Enum.Font.SourceSansSemibold, bold = Enum.Font.SourceSansBold }
local F_XMB  = { reg = Enum.Font.Gotham, semi = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold }
local F_DANDY = { reg = Enum.Font.SourceSansSemibold, semi = Enum.Font.FredokaOne, bold = Enum.Font.FredokaOne }
local F_XP   = { reg = Enum.Font.Arial, semi = Enum.Font.Arial, bold = Enum.Font.ArialBold }   -- closest thing to Tahoma
local AL, AC, AR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right

local function gconnect(sig, fn) local c = sig:Connect(fn); guiConns[#guiConns + 1] = c; return c end
local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, col, th, tr)
    return New("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function grad(o, c0, c1, rot) return New("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rot or 90 }, o) end
local function tween(o, props, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function gloss(parent, radius, a0, a1)
    local g = New("Frame", { Name = "Gloss", BackgroundColor3 = WHITE, BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0, 2), Size = UDim2.new(1, -6, 0.48, 0), ZIndex = 2 }, parent)
    corner(g, math.max(radius - 2, 2))
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(a0 or 0.2, a1 or 0.88) }, g)
    return g
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end

local function makeTokens()
    if S.style == "dandy" then
        local c = S.dandy.colors
        return { kind = "dandy", c = c, F = F_DANDY, dark = true, text = C(240, 240, 244), dim = C(196, 196, 204), size = 18, rowH = 40,
            accent = c.header, fill = c.fill, minW = 720, minH = 440 }
    end
    if S.style == "xp" then
        local c = S.xp.colors
        return { kind = "xp", c = c, F = F_XP, text = C(0, 0, 0), dim = C(92, 92, 84), size = 15, rowH = 32,
            accent = c.accent, minW = 600, minH = 400 }
    end
    if S.style == "xmb" then
        local c = S.xmb.colors
        return { kind = "xmb", c = c, F = F_XMB, text = WHITE, dim = C(185, 202, 235), size = 15, rowH = 44,
            accent = c.accent, minW = 640, minH = 420 }
    end
    local c = S.aero.colors
    local dark = lum(c.panel) < 0.45
    return { kind = "aero", c = c, F = F_AERO, dark = dark, text = c.text, dim = c.text:Lerp(c.top, 0.35), size = 16,
        rowH = 34, accent = c.accent, panelT = dark and 0.3 or 0.5, minW = 560, minH = 380 }
end
local function fieldBg() return T.dark and T.c.panel:Lerp(WHITE, 0.1) or WHITE end
local function okCol() return (T.kind == "xmb" or T.dark) and C(130, 245, 165) or C(10, 110, 50) end
local function errCol() return (T.kind == "xmb" or T.dark) and C(255, 140, 140) or C(170, 25, 25) end

local function aeroTheme(name)
    local a = T.accent
    if name == "blue" then return { top = a:Lerp(WHITE, 0.55), bot = a, stroke = a:Lerp(BLACK, 0.45), text = WHITE, st = 0.55 }
    elseif name == "green" then return { top = C(175, 240, 120), bot = C(35, 160, 50), stroke = C(15, 105, 30), text = WHITE, st = 0.55 }
    elseif name == "red" then return { top = C(255, 165, 140), bot = C(205, 45, 38), stroke = C(135, 22, 20), text = WHITE, st = 0.55 }
    end
    if T.dark then
        local p = T.c.panel
        return { top = p:Lerp(WHITE, 0.28), bot = p:Lerp(WHITE, 0.06), stroke = a:Lerp(p, 0.35), text = T.text, st = 1 }
    end
    return { top = WHITE, bot = a:Lerp(WHITE, 0.8), stroke = a:Lerp(WHITE, 0.4), text = T.text, st = 1 }
end

-- Aero keeps everything lowercase
local function lowerize(o)
    if o:IsA("TextLabel") or o:IsA("TextButton") then
        local busy = false
        local function f()
            if busy then return end
            local l = o.Text:lower()
            if l ~= o.Text then busy = true; o.Text = l; busy = false end
        end
        f()
        o:GetPropertyChangedSignal("Text"):Connect(f)
    elseif o:IsA("TextBox") then
        o.PlaceholderText = o.PlaceholderText:lower()
    end
end

local function closePopup()
    local cb = popupClose
    popupClose = nil
    if popup then popup:Destroy(); popup = nil end
    if cb then cb() end
end

--#endregion ui-core
--#region ui-sounds
----------------------------------------------------------------------
-- UI SOUNDS  (each skin has its own set; toggle + volume in Appearance)
----------------------------------------------------------------------
local sndHolder = Instance.new("Folder")
sndHolder.Name = "TonyScriptPalaceSounds"
sndHolder.Parent = guiParent()

-- { id, volume, speed }
local SOUND_SETS = {
    -- Dandy's World: the game's own UI sounds
    dandy = {
        hover  = { "rbxassetid://6895079853", 0.3, 1 },
        click  = { "rbxassetid://552900451", 0.5, 1 },
        on     = { "rbxassetid://121531878137469", 0.7, 1 },
        off    = { "rbxassetid://121531878137469", 0.7, 0.88 },
        open   = { "rbxassetid://261072074", 0.33, 1 },
        close  = { "rbxassetid://4228160116", 0.4, 1 },
        tick   = { "rbxassetid://147982968", 0.3, 1 },
        option = { "rbxassetid://2034189546", 0.3, 1 },
        ok     = { "rbxassetid://4612383453", 0.4, 1 },
        err    = { "rbxassetid://4499400560", 0.3, 1 },
    },
    -- Frutiger Aero: glassy clicks, pings, bubbles
    aero = {
        hover = { "rbxassetid://18211667014", 0.25, 1 },
        click = { "rbxassetid://126825367714667", 0.45, 1 },
        on    = { "rbxassetid://100772509583336", 0.45, 1 },
        off   = { "rbxassetid://9060371785", 0.45, 1 },
        open  = { "rbxassetid://118128903974757", 0.45, 1 },
        tick  = { "rbxassetid://98962075258183", 0.25, 1 },
        ok    = { "rbxassetid://116399794334864", 0.5, 1 },
        err   = { "rbxassetid://138365624960402", 0.5, 1 },
    },
    -- XMB / PlayStation. 4th value = PS3 sound file (downloaded once and cached, see loader below).
    -- Until a file is ready (or if downloading isn't possible) the stock Roblox sound in slot 1 plays instead.
    -- hover / tick / category-change reuse snd_option (hover + tick are quieter and slightly higher).
    xmb = {
        hover    = { "rbxasset://sounds/clickfast.wav", 0.15, 1.25, "snd_option.wav" },
        tick     = { "rbxasset://sounds/switch.wav", 0.15, 1.25, "snd_option.wav" },
        open     = { "rbxasset://sounds/snap.mp3", 0.4, 1, "snd_option.wav" },
        click    = { "rbxasset://sounds/button.wav", 0.4, 1, "snd_system_ok.wav" },
        on       = { "rbxasset://sounds/electronicpingshort.wav", 0.4, 1, "snd_system_ok.wav" },
        off      = { "rbxasset://sounds/electronicpingshort.wav", 0.4, 1, "snd_cancel.wav" },
        close    = { "rbxasset://sounds/clickfast.wav", 0.4, 1, "snd_cancel.wav" },
        option   = { "rbxasset://sounds/snap.mp3", 0.45, 1, "snd_option.wav" },
        ok       = { "rbxasset://sounds/electronicpingshort.wav", 0.5, 1, "snd_trophy.wav" },
        err      = { "rbxasset://sounds/bass.mp3", 0.5, 1, "snd_error.wav" },
        ng       = { "rbxasset://sounds/bass.mp3", 0.45, 1.3, "snd_system_ng.wav" },
        boot     = { "", 0.6, 1, "coldboot_stereo.wav" },
        gameboot = { "", 0.6, 1, "gameboot_stereo.wav" },
    },
    -- Windows XP Luna. 4th value = file name in the "Windows XP Sounds" folder (downloaded once and cached, see loader below).
    -- No hover sound, like the real thing. Stock Roblox sounds play until a file is ready.
    xp = {
        click  = { "rbxasset://sounds/button.wav", 0.4, 1, "Windows XP Menu Command.wav" },
        on     = { "rbxasset://sounds/button.wav", 0.4, 1, "Windows XP Menu Command.wav" },
        off    = { "rbxasset://sounds/button.wav", 0.4, 1, "Windows XP Menu Command.wav" },
        tick   = { "rbxasset://sounds/switch.wav", 0.2, 1.15, "Windows XP Menu Command.wav" },
        option = { "rbxasset://sounds/snap.mp3", 0.4, 1, "Windows XP Start.wav" },
        open   = { "rbxasset://sounds/snap.mp3", 0.4, 1, "Windows XP Restore.wav" },
        close  = { "rbxasset://sounds/clickfast.wav", 0.4, 1, "Windows XP Minimize.wav" },
        ok     = { "rbxasset://sounds/electronicpingshort.wav", 0.5, 1, "Windows XP Ding.wav" },
        err    = { "rbxasset://sounds/bass.mp3", 0.5, 1, "Windows XP Error.wav" },
        ng     = { "rbxasset://sounds/bass.mp3", 0.5, 1, "Windows XP Critical Stop.wav" },
        boot   = { "", 0.6, 1, "Windows XP Startup.wav" },
    },
}
local SND_FALLBACK = {  -- used only if a Dandy or Aero asset id fails to load
    hover = "rbxasset://sounds/clickfast.wav", click = "rbxasset://sounds/button.wav",
    on = "rbxasset://sounds/electronicpingshort.wav", off = "rbxasset://sounds/electronicpingshort.wav",
    open = "rbxasset://sounds/snap.mp3", tick = "rbxasset://sounds/switch.wav",
    ok = "rbxasset://sounds/victory.wav", err = "rbxasset://sounds/bass.mp3",
    close = "rbxasset://sounds/clickfast.wav", option = "rbxasset://sounds/snap.mp3",
}
local uiSnd = { dandy = {}, aero = {}, xmb = {}, xp = {} }
for style, set in pairs(SOUND_SETS) do
    for k, d in pairs(set) do
        local snd = Instance.new("Sound")
        snd.Name = style .. "_" .. k; snd.SoundId = d[1]; snd.Volume = d[2]; snd.Parent = sndHolder
        uiSnd[style][k] = snd
        if style == "aero" or style == "dandy" then
            task.spawn(function()
                local t0 = os.clock()
                while alive and not snd.IsLoaded and os.clock() - t0 < 6 do task.wait(0.2) end
                if alive and not snd.IsLoaded then snd.SoundId = SND_FALLBACK[k] end
            end)
        end
    end
end
local SOUND_ALIAS = { ng = "err", close = "click", option = "open" }  -- a skin without that sound uses this one
local soundReady = { xmb = {}, xp = {} }  -- [style][sound name] = true once its file is loaded
local function ui(name)
    if not S.sounds or S.sfxVol <= 0 then return end
    local set = SOUND_SETS[S.style]
    if set and not set[name] then name = SOUND_ALIAS[name] or name end
    local def = set and set[name]
    local base = uiSnd[S.style] and uiSnd[S.style][name]
    if not (def and base) then return end
    local c = base:Clone()
    c.Volume = def[2] * S.sfxVol
    c.PlaybackSpeed = def[3]
    c.Parent = sndHolder
    c.Ended:Connect(function() c:Destroy() end)
    c:Play()
    task.delay(12, function() if c.Parent then c:Destroy() end end)
end

-- play a sound as soon as its file has downloaded (used for the boot sounds)
local function uiWhenReady(name)
    local st = S.style
    if not soundReady[st] then return end
    task.spawn(function()
        local t0 = os.clock()
        while alive and S.style == st and not soundReady[st][name] and os.clock() - t0 < 8 do task.wait(0.2) end
        if alive and S.style == st and soundReady[st][name] then ui(name) end
    end)
end

-- download the XMB sound files once, cache them in workspace/TonyScriptPalace/Sounds,
-- then point the XMB sounds at them. Needs an executor with request/HttpGet + writefile + getcustomasset.
local SND_DIR = ROOT_DIR .. "/Sounds"
local XMB_SOUND_URL = "https://file.garden/aRURJecPmmjLUziC/Sound%20Effects%20-%20XMB%20-%20PlayStation%203/"
local XP_SOUND_URL  = "https://file.garden/aRURJecPmmjLUziC/Windows%20XP%20Sounds/"
task.spawn(function()
    local getAsset = env.getcustomasset or env.getsynasset
    if not (getAsset and writefile) then return end
    mkD(SND_DIR)
    local function download(url)
        local req = env.request or env.http_request
        if req then
            local ok, r = pcall(req, { Url = url, Method = "GET" })
            if ok and type(r) == "table" and type(r.Body) == "string" and #r.Body > 1000 then return r.Body end
        end
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and type(body) == "string" and #body > 1000 then return body end
        return nil
    end
    for _, style in ipairs({ "xmb", "xp" }) do
        for name, d in pairs(SOUND_SETS[style]) do
            local file = d[4]
            if file and alive then
                -- XP files have spaces in their names: cache them under a clean name and percent-encode the URL
                local cache = (style == "xp") and ("xp_" .. file:lower():gsub("[^%w%.]+", "_")) or file
                local url = (style == "xp") and (XP_SOUND_URL .. file:gsub(" ", "%%20")) or (XMB_SOUND_URL .. file)
                local path = SND_DIR .. "/" .. cache
                if not isF(path) then
                    local body = download(url)
                    if body and body:sub(1, 4) == "RIFF" then wrF(path, body) end   -- only keep real .wav data
                end
                if isF(path) then
                    local ok, id = pcall(getAsset, path)
                    if ok and id and alive then
                        uiSnd[style][name].SoundId = id
                        soundReady[style][name] = true
                    end
                end
            end
        end
    end
end)

--#endregion ui-sounds
--#region widgets
----------------------------------------------------------------------
-- WIDGETS (shared by both skins, drawn from tokens)
----------------------------------------------------------------------
local function Label(parent, text, pos, size, o)
    o = o or {}
    return New("TextLabel", {
        BackgroundTransparency = 1, Text = text, Font = o.font or T.F.semi, TextSize = o.size or T.size,
        TextColor3 = o.color or T.text, TextXAlignment = o.align or AL, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = pos, Size = size, TextWrapped = o.wrap or false,
    }, parent)
end

local function Button(parent, text, size, style, cb, o)
    o = o or {}
    local b, lb
    if T.kind == "dandy" then
        local pal = { blue = C(224, 165, 22), green = C(55, 150, 58), red = C(190, 55, 55), yellow = C(224, 165, 22), orange = C(217, 102, 28) }
        local base = pal[style] or C(104, 104, 108)
        b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = base, BorderSizePixel = 0, Size = size, Position = o.pos or UDim2.new() }, parent)
        corner(b, o.radius or 8); stroke(b, BLACK, 2.5, 0); grad(b, WHITE, C(128, 128, 128), 90)
        lb = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text, Font = T.F.bold, TextSize = o.size or 16,
            TextColor3 = WHITE, TextStrokeTransparency = 0.35, TextStrokeColor3 = BLACK, ZIndex = 3, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = o.align or AC }, b)
        if o.pad then New("UIPadding", { PaddingLeft = UDim.new(0, o.pad), PaddingRight = UDim.new(0, o.padR or o.pad) }, lb) end
        b.MouseEnter:Connect(function() ui("hover"); tween(b, { BackgroundColor3 = base:Lerp(WHITE, 0.2) }, 0.1) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = base }, 0.1) end)
        b.MouseButton1Down:Connect(function() tween(b, { BackgroundColor3 = base:Lerp(BLACK, 0.25) }, 0.05) end)
        b.MouseButton1Up:Connect(function() tween(b, { BackgroundColor3 = base:Lerp(WHITE, 0.2) }, 0.1) end)
    elseif T.kind == "aero" then
        local th, rad = aeroTheme(style), o.radius or 8
        b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C(238, 238, 238), BorderSizePixel = 0,
            Size = size, Position = o.pos or UDim2.new() }, parent)
        corner(b, rad); grad(b, th.top, th.bot, 90); stroke(b, th.stroke, 1, 0.1); gloss(b, rad)
        lb = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text, Font = T.F.bold,
            TextSize = o.size or 15, TextColor3 = th.text, TextStrokeTransparency = th.st, TextStrokeColor3 = th.stroke,
            ZIndex = 3, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = o.align or AC }, b)
        if o.pad then New("UIPadding", { PaddingLeft = UDim.new(0, o.pad), PaddingRight = UDim.new(0, o.padR or o.pad) }, lb) end
        b.MouseEnter:Connect(function() ui("hover"); tween(b, { BackgroundColor3 = WHITE }, 0.1) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = C(238, 238, 238) }, 0.1) end)
        b.MouseButton1Down:Connect(function() tween(b, { BackgroundColor3 = C(190, 200, 210) }, 0.05) end)
        b.MouseButton1Up:Connect(function() tween(b, { BackgroundColor3 = WHITE }, 0.1) end)
    elseif T.kind == "xp" then
        local top, bot = C(255, 255, 255), C(214, 208, 197)
        if style == "blue" then bot = T.accent:Lerp(WHITE, 0.55)
        elseif style == "green" then top, bot = C(232, 250, 220), C(150, 205, 120)
        elseif style == "red" then top, bot = C(255, 232, 222), C(235, 150, 130) end
        b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, BorderSizePixel = 0,
            Size = size, Position = o.pos or UDim2.new() }, parent)
        corner(b, 3)
        local g = grad(b, top, bot, 90)
        local baseCol, baseTh = C(0, 60, 116), 1
        if style == "blue" then baseCol, baseTh = T.accent, 2 end   -- XP "default button" look
        local st = stroke(b, baseCol, baseTh, 0)
        lb = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text, Font = T.F.reg,
            TextSize = o.size or 14, TextColor3 = C(0, 0, 0), TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = o.align or AC }, b)
        if o.pad then New("UIPadding", { PaddingLeft = UDim.new(0, o.pad), PaddingRight = UDim.new(0, o.padR or o.pad) }, lb) end
        b.MouseEnter:Connect(function() ui("hover"); st.Color = C(230, 160, 40); st.Thickness = 2 end)   -- orange hover ring
        b.MouseLeave:Connect(function() st.Color = baseCol; st.Thickness = baseTh; g.Color = ColorSequence.new(top, bot) end)
        b.MouseButton1Down:Connect(function() g.Color = ColorSequence.new(bot, top) end)
        b.MouseButton1Up:Connect(function() g.Color = ColorSequence.new(top, bot) end)
    else
        local tints = { blue = T.accent, green = C(110, 235, 150), red = C(255, 110, 110) }
        local tint = style and tints[style]
        local base = tint and 0.62 or 0.86
        b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = tint or WHITE, BackgroundTransparency = base,
            BorderSizePixel = 0, Size = size, Position = o.pos or UDim2.new() }, parent)
        corner(b, 6); stroke(b, WHITE, 1, 0.55)
        lb = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = text, Font = T.F.semi,
            TextSize = o.size or 14, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = o.align or AC }, b)
        if o.pad then New("UIPadding", { PaddingLeft = UDim.new(0, o.pad), PaddingRight = UDim.new(0, o.padR or o.pad) }, lb) end
        b.MouseEnter:Connect(function() ui("hover"); tween(b, { BackgroundTransparency = base - 0.12 }, 0.1) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = base }, 0.1) end)
        b.MouseButton1Down:Connect(function() tween(b, { BackgroundTransparency = base - 0.22 }, 0.05) end)
        b.MouseButton1Up:Connect(function() tween(b, { BackgroundTransparency = base - 0.12 }, 0.1) end)
    end
    b.MouseButton1Click:Connect(function() ui("click"); if cb then cb() end end)
    return b, lb
end

local function Input(parent, text, ph, commit, size)
    local aero = T.kind == "aero"
    local xp = T.kind == "xp"
    local dandy = T.kind == "dandy"
    local tb = New("TextBox", {
        Text = text or "", PlaceholderText = ph or "", PlaceholderColor3 = T.dim, ClearTextOnFocus = false,
        Font = T.F.reg, TextSize = size or 15, TextColor3 = T.text,
        BackgroundColor3 = dandy and C(30, 30, 34) or (aero and fieldBg() or WHITE), BackgroundTransparency = dandy and 0.05 or (xp and 0 or (aero and 0.12 or 0.88)),
        BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), TextXAlignment = AL, ClipsDescendants = true,
    }, parent)
    corner(tb, xp and 2 or (dandy and 6 or (aero and 7 or 5)))
    local base = dandy and BLACK or (xp and C(127, 157, 185) or (aero and T.accent:Lerp(WHITE, 0.4) or WHITE))
    local baseTr = dandy and 0 or (xp and 0 or (aero and 0.1 or 0.6))
    local st = stroke(tb, base, dandy and 2 or 1, baseTr)
    New("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, tb)
    tb.Focused:Connect(function() ui("tick"); st.Color = T.accent; st.Thickness = 2; st.Transparency = 0 end)
    tb.FocusLost:Connect(function(enter)
        st.Color = base; st.Thickness = dandy and 2 or 1; st.Transparency = baseTr
        if commit then commit(tb.Text, enter) end
    end)
    return tb
end

local function ToggleW(holder, value, cb)
    local obj = { value = value and true or false }
    local aero = T.kind == "aero"
    local g, knob, txt, chk1, chk2
    local xp = T.kind == "xp"
    local dandy = T.kind == "dandy"
    if dandy then   -- the game's  ◀ ON ▶  switch
        txt = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = T.F.bold, TextSize = 19, TextXAlignment = AR,
            TextStrokeTransparency = 0.3, TextStrokeColor3 = BLACK }, holder)
    elseif xp then   -- classic XP check box
        local box = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(15, 15),
            BackgroundColor3 = WHITE, BorderSizePixel = 0 }, holder)
        stroke(box, C(28, 81, 128), 1, 0); grad(box, C(220, 220, 215), WHITE, 45)
        chk1 = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(5, 9), Size = UDim2.fromOffset(2, 5),
            Rotation = -45, BackgroundColor3 = C(33, 161, 33), BorderSizePixel = 0 }, box)
        chk2 = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(9, 7), Size = UDim2.fromOffset(2, 9),
            Rotation = 45, BackgroundColor3 = C(33, 161, 33), BorderSizePixel = 0 }, box)
    elseif aero then
        local track = New("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(44, 22),
            BackgroundColor3 = WHITE, BorderSizePixel = 0 }, holder)
        corner(track, 11); stroke(track, T.accent:Lerp(BLACK, 0.35), 1, 0.15)
        g = New("UIGradient", { Rotation = 90 }, track)
        knob = New("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2 }, track)
        corner(knob, 9); stroke(knob, T.accent:Lerp(BLACK, 0.2), 1, 0.1); grad(knob, WHITE, C(205, 228, 245), 90)
    else
        txt = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = T.F.semi, TextSize = 15, TextXAlignment = AR }, holder)
    end
    local function paint(anim)
        if dandy then
            txt.Text = obj.value and "◀ ON ▶" or "◀ OFF ▶"
            txt.TextColor3 = obj.value and T.c.on or T.c.off
        elseif xp then
            chk1.Visible = obj.value; chk2.Visible = obj.value
        elseif aero then
            g.Color = obj.value and ColorSequence.new(C(165, 245, 120), C(35, 165, 55))
                or (T.dark and ColorSequence.new(C(90, 105, 130), C(45, 58, 82)) or ColorSequence.new(C(210, 222, 233), C(140, 165, 190)))
            local target = UDim2.fromOffset(obj.value and 24 or 2, 2)
            if anim then tween(knob, { Position = target }, 0.15) else knob.Position = target end
        else
            txt.Text = obj.value and "On" or "Off"
            txt.TextColor3 = obj.value and T.accent or T.dim
        end
    end
    paint(false)
    function obj.flip() obj.value = not obj.value; paint(true); ui(obj.value and "on" or "off"); if cb then cb(obj.value) end end
    function obj.set(v) obj.value = v and true or false; paint(false) end
    return obj
end

local function Slider(parent, min, max, dec, init, cb, step, free)
    local aero = T.kind == "aero"
    local xp = T.kind == "xp"
    local dandy = T.kind == "dandy"
    local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
    local boxW = 54
    local track = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, -boxW - 12, 0, aero and 8 or 4), BackgroundColor3 = aero and fieldBg() or WHITE,
        BackgroundTransparency = aero and 0.15 or 0.75, BorderSizePixel = 0 }, f)
    corner(track, 4)
    if aero then stroke(track, T.accent:Lerp(WHITE, 0.3), 1, 0.1) end
    if xp then track.BackgroundColor3 = WHITE; track.BackgroundTransparency = 0; stroke(track, C(172, 168, 153), 1, 0) end
    if dandy then   -- dark groove between the orange - and + buttons
        track.BackgroundColor3 = C(26, 26, 28); track.BackgroundTransparency = 0; stroke(track, BLACK, 2, 0)
        track.Size = UDim2.new(1, -(30 + boxW + 8 + 26 + 4), 0, 10); track.Position = UDim2.new(0, 30, 0.5, 0)
    end
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, track)
    corner(fill, 4)
    if aero then grad(fill, T.accent:Lerp(WHITE, 0.55), T.accent, 90) else fill.BackgroundColor3 = dandy and T.fill or T.accent end
    local ks = aero and 18 or 14
    local knob = New("Frame", { Size = UDim2.fromOffset(ks, ks), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, track)
    local kc = corner(knob, ks / 2)
    if xp then   -- XP trackbar thumb: small raised rectangle
        kc.CornerRadius = UDim.new(0, 2); knob.Size = UDim2.fromOffset(11, 20)
        grad(knob, WHITE, C(214, 208, 197), 90); stroke(knob, C(0, 60, 116), 1, 0)
    end
    if aero then stroke(knob, T.accent:Lerp(BLACK, 0.3), 1, 0); grad(knob, WHITE, T.accent:Lerp(WHITE, 0.7), 90) end
    if dandy then knob.BackgroundColor3 = C(236, 236, 236); stroke(knob, BLACK, 2, 0); grad(knob, WHITE, C(170, 170, 170), 90) end
    local hit = New("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, -8, 0.5, -13),
        Size = UDim2.new(1, 16, 0, 26), ZIndex = 4 }, track)
    local boxHolder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(boxW, 24) }, f)
    local box, valLbl
    if aero or xp or dandy or free then
        box = Input(boxHolder, "", "", nil, 14); box.TextXAlignment = AC
    else
        valLbl = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = T.F.semi, TextSize = 14,
            TextColor3 = T.text, TextXAlignment = AR }, boxHolder)
    end
    local obj, val = {}, init
    local fmt = "%." .. dec .. "f"
    -- free mode: typed numbers are exact (up to 3 decimals) and may go past the slider's range, up to free.min / free.max
    local hmin = (type(free) == "table" and free.min) or min
    local hmax = (type(free) == "table" and free.max) or max
    local rd = free and 3 or dec
    local function render()
        local a = math.clamp((val - min) / (max - min), 0, 1)
        fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, 0.5)
        local s = string.format(fmt, val)
        if free then s = string.format("%.3f", val):gsub("0+$", ""):gsub("%.$", "") end
        if box then box.Text = s else valLbl.Text = s end
    end
    local function setFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = min + (max - min) * a
        if step then v = math.floor(v / step + 0.5) * step end
        local m = 10 ^ rd
        v = math.floor(v * m + 0.5) / m
        if v ~= val then val = v; render(); ui("tick"); if cb then cb(val) end end
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then setFromX(i.Position.X); activeDrag = function(p) setFromX(p.X) end end
    end)
    if box then
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then
                if free then
                    local m = 10 ^ rd
                    val = math.clamp(math.floor(n * m + 0.5) / m, hmin, hmax)      -- exactly what you typed, no snapping to the step
                else
                    if step then n = math.floor(n / step + 0.5) * step end
                    val = math.clamp(n, min, max)
                end
                if cb then cb(val) end
            end
            render()
        end)
    end
    function obj.set(v) val = math.clamp(v, hmin, hmax); render() end
    if dandy then
        local inc = step or ((dec > 0) and 10 ^ -dec or 1)
        local function nudge(dir)
            local m = 10 ^ rd
            local v = math.clamp(math.floor((val + dir * inc) * m + 0.5) / m, hmin, hmax)
            if v ~= val then val = v; render(); if cb then cb(val) end end
        end
        Button(f, "-", UDim2.fromOffset(26, 26), "orange", function() nudge(-1) end, { size = 22, radius = 6, pos = UDim2.new(0, 0, 0.5, -13) })
        Button(f, "+", UDim2.fromOffset(26, 26), "orange", function() nudge(1) end, { size = 20, radius = 6, pos = UDim2.new(1, -(boxW + 8 + 26), 0.5, -13) })
    end
    render()
    return obj
end

local function openMenu(anchor, options, onPick)
    closePopup()
    ui("option")
    local sc = UIScaleObj.Scale
    local blocker = New("TextButton", { Name = "Menu", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, Overlay)
    popup = blocker
    blocker.MouseButton1Click:Connect(function() ui("close"); closePopup() end)
    local aero = T.kind == "aero"
    local xp = T.kind == "xp"
    local dandy = T.kind == "dandy"
    local lh = 28
    local h = math.min(math.max(#options, 1) * lh + 8, 240)
    local rel = (anchor.AbsolutePosition - Win.AbsolutePosition) / sc
    local w = math.max(anchor.AbsoluteSize.X / sc, 160)
    local winH, winW = Win.AbsoluteSize.Y / sc, Win.AbsoluteSize.X / sc
    local y = rel.Y + anchor.AbsoluteSize.Y / sc + 2
    if y + h > winH - 4 then y = rel.Y - h - 2 end
    y = math.max(y, 4)
    local x = math.clamp(rel.X, 4, math.max(winW - w - 6, 4))
    local list = New("ScrollingFrame", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Active = true,
        BackgroundColor3 = xp and WHITE or (dandy and C(44, 44, 48)) or (aero and (T.dark and C(24, 40, 70) or C(238, 250, 255)) or C(10, 24, 62)),
        BackgroundTransparency = (aero or xp or dandy) and 0 or 0.08, BorderSizePixel = 0, ScrollBarThickness = 5,
        ScrollBarImageColor3 = T.accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, blocker)
    if xp then corner(list, 2); stroke(list, C(130, 128, 120), 1, 0)
    elseif dandy then corner(list, 8); stroke(list, BLACK, 3, 0)
    else corner(list, 8); stroke(list, aero and T.accent:Lerp(WHITE, 0.2) or WHITE, aero and 1.5 or 1, aero and 0 or 0.5) end
    New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, list)
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
    for i, opt in ipairs(options) do
        local it = New("TextButton", { Text = tostring(opt), Font = T.F.semi, TextSize = 14, TextColor3 = (aero or xp or dandy) and T.text or WHITE,
            TextXAlignment = AL, BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, lh), LayoutOrder = i, AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd }, list)
        if aero and T.dark then it.TextColor3 = T.text end
        corner(it, 6)
        New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }, it)
        it.MouseEnter:Connect(function() ui("hover"); it.BackgroundTransparency = xp and 0 or 0.6; if xp then it.TextColor3 = WHITE end end)
        it.MouseLeave:Connect(function() it.BackgroundTransparency = 1; if xp then it.TextColor3 = T.text end end)
        it.MouseButton1Click:Connect(function() ui("click"); closePopup(); onPick(opt) end)
    end
end

-- official highlight colors used in the game (name, r, g, b)
local GAME_COLORS = {
    { "Astro Blue", 120, 200, 255 }, { "Brusha Purple", 153, 81, 137 }, { "Dessa Green", 0, 255, 38 }, { "Eclipse Blue", 150, 180, 220 }, { "Soulvester Blue", 129, 215, 180 },
    { "Vee Green", 100, 255, 97 }, { "Egg Radar Pink", 255, 192, 203 }, { "Festive Lights Yellow", 255, 215, 0 },
    { "Fishing Rod Blue", 61, 151, 220 }, { "Memory Locket Green", 168, 255, 160 }, { "Party Popper Pink", 255, 132, 203 },
    { "Trick or Treat Door Orange", 255, 150, 40 },
    { "Default Green", 51, 117, 56 }, { "Default Lime", 0, 255, 0 }, { "Default Teal", 0, 158, 115 },
    { "Default Blue", 0, 114, 178 }, { "Default Light Blue", 37, 212, 247 }, { "Default Cyan", 36, 192, 206 },
    { "Default Red", 241, 48, 83 }, { "Default Magenta", 239, 0, 244 }, { "Default Pink", 239, 122, 187 },
    { "Default Orange", 213, 94, 0 }, { "Default Yellow", 255, 255, 0 }, { "Default Yellow 2", 240, 228, 66 },
    { "Default Black", 17, 17, 17 }, { "Default Gray", 160, 160, 160 }, { "Default White", 255, 255, 255 },
}

local function openColorPicker(c)
    closePopup()
    ui("option")
    local aero = T.kind == "aero"
    local xp = T.kind == "xp"
    local cur = c.get()
    local rb = (cur == RAINBOW)
    local base = rb and C(255, 0, 0) or cur
    local hh, ss, vv = base:ToHSV()
    hh, ss, vv = hh * 360, ss * 100, vv * 100

    local blocker = New("TextButton", { Name = "Picker", Text = "", AutoButtonColor = false, BackgroundColor3 = BLACK,
        BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1) }, Overlay)
    popup = blocker
    local cw = 330
    local outer = New("Frame", { Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(cw, 300), BorderSizePixel = 0,
        BackgroundColor3 = xp and T.c.face or (T.kind == "dandy" and C(58, 58, 62)) or (aero and (T.dark and C(22, 38, 68) or C(236, 249, 255)) or C(10, 24, 62)),
        BackgroundTransparency = (aero or xp or T.kind == "dandy") and 0 or 0.05 }, blocker)
    if xp then corner(outer, 6); stroke(outer, T.c.title, 3, 0)
    elseif T.kind == "dandy" then corner(outer, 14); stroke(outer, BLACK, 4, 0)
    else corner(outer, 14); stroke(outer, aero and T.accent:Lerp(WHITE, 0.2) or WHITE, aero and 2 or 1, aero and 0 or 0.4) end
    -- the card scrolls if the window is too short to show everything
    local card = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 4, ScrollBarImageColor3 = T.accent, CanvasSize = UDim2.new() }, outer)

    Label(card, c.text or "Color", UDim2.fromOffset(14, 10), UDim2.fromOffset(200, 24), { font = T.F.bold, size = 17 })
    local prev = New("Frame", { Position = UDim2.fromOffset(cw - 14 - 60, 10), Size = UDim2.fromOffset(60, 24), BackgroundColor3 = base, BorderSizePixel = 0 }, card)
    corner(prev, 6); stroke(prev, WHITE, 1.5, 0.2)

    local hexBox
    local function paintSw(col)
        local sw = c._sw
        if sw and sw.Parent then
            if rb then rainbowSw[sw] = true else rainbowSw[sw] = nil; sw.BackgroundColor3 = col end
        end
    end
    local function apply()
        local col = Color3.fromHSV(math.clamp(hh, 0, 359.99) / 360, ss / 100, vv / 100)
        prev.BackgroundColor3 = col
        if hexBox then hexBox.Text = hexOf(col) end
        c.set(col)
        paintSw(col)
    end
    local sliders = {}
    local rbT
    local function unRainbow() if rb then rb = false; if rbT then rbT.set(false) end end end
    local rowsY = { 46, 78, 110 }
    local defs = { { "Hue", 360, function(v) hh = v end }, { "Saturation", 100, function(v) ss = v end }, { "Brightness", 100, function(v) vv = v end } }
    local inits = { hh, ss, vv }
    for i, d in ipairs(defs) do
        Label(card, d[1], UDim2.fromOffset(14, rowsY[i]), UDim2.fromOffset(84, 24), { size = 14 })
        local hold = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(98, rowsY[i]), Size = UDim2.fromOffset(cw - 98 - 14 - 6, 24) }, card)
        sliders[i] = Slider(hold, 0, d[2], 0, inits[i], function(v) d[3](v); unRainbow(); apply() end)
    end
    local function setColor(col)   -- jump to an exact color (palette / hex / default)
        local a, b2, c2 = col:ToHSV()
        hh, ss, vv = a * 360, b2 * 100, c2 * 100
        sliders[1].set(hh); sliders[2].set(ss); sliders[3].set(vv)
        unRainbow(); apply()
    end
    Label(card, "Hex", UDim2.fromOffset(14, 148), UDim2.fromOffset(60, 28), { size = 14 })
    local hexHold = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(98, 148), Size = UDim2.fromOffset(110, 28) }, card)
    hexBox = Input(hexHold, hexOf(base), "#rrggbb", function(txt)
        local col = colorOf(trim(txt))
        if col then setColor(col) else hexBox.Text = hexOf(prev.BackgroundColor3) end
    end, 14)

    local y = 188
    if c.palette ~= false then
        Label(card, "Game Colors", UDim2.fromOffset(14, y), UDim2.fromOffset(200, 18), { size = 13, color = T.dim })
        local cols, sz, gap = 10, 26, 4
        local gy = y + 22
        local rows = math.ceil(#GAME_COLORS / cols)
        local nameLbl = Label(card, "Tap a color to use it", UDim2.fromOffset(14, gy + rows * (sz + gap)), UDim2.fromOffset(cw - 28, 18), { size = 13, color = T.dim })
        for i, g in ipairs(GAME_COLORS) do
            local r, k = math.floor((i - 1) / cols), (i - 1) % cols
            local col = C(g[2], g[3], g[4])
            local sw = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = col, BorderSizePixel = 0,
                Position = UDim2.fromOffset(14 + k * (sz + gap), gy + r * (sz + gap)), Size = UDim2.fromOffset(sz, sz) }, card)
            corner(sw, 6); stroke(sw, WHITE, 1, 0.3)
            sw.MouseEnter:Connect(function()
                ui("hover"); nameLbl.Text = string.format("%s  (%d, %d, %d)", g[1], g[2], g[3], g[4])
            end)
            sw.MouseButton1Click:Connect(function() ui("click"); setColor(col) end)
        end
        y = gy + rows * (sz + gap) + 26
    end
    if c.rainbow then
        Label(card, "Rainbow", UDim2.fromOffset(14, y), UDim2.fromOffset(120, 24), { size = 14 })
        local hold = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(cw - 14 - 60, y), Size = UDim2.fromOffset(60, 24) }, card)
        rbT = ToggleW(hold, rb, function(v)
            rb = v
            if v then c.set(RAINBOW); paintSw(nil) else apply() end
        end)
        local hb = New("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, hold)
        hb.MouseButton1Click:Connect(function() rbT.flip() end)
        y += 36
    end
    local function done() ui("close"); closePopup() end
    if c.default then
        Button(card, "Default", UDim2.fromOffset(96, 30), "glass", function()
            local d = c.default()
            if d == RAINBOW then
                rb = true; if rbT then rbT.set(true) end
                c.set(RAINBOW); paintSw(nil)
            else
                setColor(d)
            end
        end, { pos = UDim2.fromOffset(14, y), size = 15 })
    end
    Button(card, "Done", UDim2.fromOffset(96, 30), "blue", done, { pos = UDim2.fromOffset(cw - 14 - 96, y), size = 15 })
    local ch = y + 30 + 14
    card.CanvasSize = UDim2.fromOffset(0, ch)
    local availH = math.max(Win.AbsoluteSize.Y / UIScaleObj.Scale - 16, 200)
    outer.Size = UDim2.fromOffset(cw, math.min(ch, availH))
    blocker.MouseButton1Click:Connect(done)
    if c.rebuild then popupClose = function() if alive then buildGui() end end end
end

--#endregion widgets
--#region row-builders
----------------------------------------------------------------------
-- ROW BUILDERS  (one per control type)
----------------------------------------------------------------------
local function padX() return (T.kind == "xmb" and 42) or (T.kind == "dandy" and 12) or 6 end

local function rowFor(parent, order, h)
    local row = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, h or T.rowH), LayoutOrder = order }, parent)
    local hintTxt = UI.curHint
    if hintTxt then
        row.MouseEnter:Connect(function() UI.hintOn(hintTxt) end)
        row.MouseLeave:Connect(function() UI.hintOff() end)
    end
    if T.kind == "xmb" then
        local hl = New("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, row)
        corner(hl, 6)
        local ic = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(20, 20),
            BackgroundColor3 = T.accent, BackgroundTransparency = 0.4, BorderSizePixel = 0 }, row)
        corner(ic, 10); stroke(ic, WHITE, 1.5, 0.3)
        row.MouseEnter:Connect(function() ui("tick"); hl.BackgroundTransparency = 0.9; ic.BackgroundTransparency = 0.1 end)
        row.MouseLeave:Connect(function() hl.BackgroundTransparency = 1; ic.BackgroundTransparency = 0.4 end)
    elseif T.kind == "dandy" then   -- chunky dark card, lights up yellow under the cursor
        local base = T.c.panel:Lerp(BLACK, 0.12)
        row.BackgroundColor3 = base; row.BackgroundTransparency = 0.1
        corner(row, 8); stroke(row, BLACK, 2, 0.25)
        grad(row, WHITE, C(150, 150, 150), 90)
        row.MouseEnter:Connect(function() ui("tick"); tween(row, { BackgroundColor3 = base:Lerp(T.accent, 0.22) }, 0.1) end)
        row.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = base }, 0.1) end)
    elseif T.kind == "xp" then
        local hl = New("Frame", { BackgroundColor3 = T.accent, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, row)
        corner(hl, 2)
        row.MouseEnter:Connect(function() hl.BackgroundTransparency = 0.88 end)
        row.MouseLeave:Connect(function() hl.BackgroundTransparency = 1 end)
    end
    return row
end

-- label on the left, a holder frame on the right. flex = scale width, otherwise fixed pixel width
local function layoutRow(row, text, flex, fixedW)
    local x = padX()
    local lab, holder
    local hgt = -8
    if flex then
        lab = Label(row, text, UDim2.fromOffset(x, 0), UDim2.new(0.4, -x, 1, 0))
        holder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.new(0.55, 0, 1, hgt) }, row)
    else
        lab = Label(row, text, UDim2.fromOffset(x, 0), UDim2.new(1, -x - fixedW - 14, 1, 0))
        holder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.new(0, fixedW, 1, hgt) }, row)
    end
    return lab, holder
end

builders.toggle = function(parent, c, order)
    local row = rowFor(parent, order)
    local fixedW = T.kind == "dandy" and 112 or 56
    local _, holder = layoutRow(row, c.text, false, fixedW)
    local tw = ToggleW(holder, c.get(), function(v) c.set(v) end)
    row.MouseButton1Click:Connect(function() tw.flip() end)
    local bindId = UI.curBindId
    if bindId and UI.binds then UI.binds.decorate(row, c, bindId, fixedW) end     -- right-click menu for keybinds and on-screen buttons
end

builders.slider = function(parent, c, order)
    local row = rowFor(parent, order)
    local _, holder = layoutRow(row, c.text, true)
    Slider(holder, c.min, c.max, c.dec or 0, c.get(), c.set, c.step, c.free)
end

builders.color = function(parent, c, order)
    local row = rowFor(parent, order)
    local w = c.enable and 84 or 54
    local _, holder = layoutRow(row, c.text, false, w)
    local on = true
    if c.enable then
        on = c.enable.get() and true or false
        local box = New("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = T.accent, BackgroundTransparency = on and 0 or 1, BorderSizePixel = 0 }, holder)
        corner(box, 6); stroke(box, (T.kind == "aero" and T.accent:Lerp(BLACK, 0.3)) or (T.kind == "xp" and C(28, 81, 128)) or WHITE, 1.5, 0.2)
        local dot = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = on }, box)
        corner(dot, 4)
        box.MouseButton1Click:Connect(function()
            on = not on
            box.BackgroundTransparency = on and 0 or 1; dot.Visible = on
            c.enable.set(on)
            if c._sw then c._sw.BackgroundTransparency = on and 0 or 0.65 end
        end)
    end
    local sw = New("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(50, 22), BorderSizePixel = 0, BackgroundTransparency = on and 0 or 0.65 }, holder)
    corner(sw, 6); stroke(sw, (T.kind == "dandy" and BLACK) or (T.kind == "xp" and C(28, 81, 128)) or WHITE, T.kind == "dandy" and 2.5 or 1.5, (T.kind == "xp" or T.kind == "dandy") and 0 or 0.2)
    if T.kind == "aero" then gloss(sw, 6, 0.45, 0.92) end
    local cur = c.get()
    if cur == RAINBOW then rainbowSw[sw] = true; sw.BackgroundColor3 = rainbowColor else sw.BackgroundColor3 = cur end
    c._sw = sw
    sw.MouseButton1Click:Connect(function() openColorPicker(c) end)
    row.MouseButton1Click:Connect(function() openColorPicker(c) end)
end

builders.dropdown = function(parent, c, order)
    local row = rowFor(parent, order)
    local _, holder = layoutRow(row, c.text, true)
    local btn
    btn = Button(holder, c.get(), UDim2.fromScale(1, 1), "glass", function()
        openMenu(btn, c.options(), function(o) c.set(o) end)
    end, { align = AL, pad = 9, padR = 22, size = 14 })
    New("TextLabel", { BackgroundTransparency = 1, Text = "v", Font = T.F.bold, TextSize = 13, TextColor3 = (T.kind == "aero" and T.accent) or (T.kind == "xp" and C(77, 97, 133)) or WHITE,
        Size = UDim2.new(0, 18, 1, 0), Position = UDim2.new(1, -20, 0, 0), ZIndex = 4 }, btn)
end

builders.input = function(parent, c, order)
    local row = rowFor(parent, order)
    local _, holder = layoutRow(row, c.text, true)
    local tb = Input(holder, c.get and c.get() or "", c.placeholder or "", function(txt, enter) if c.set then c.set(txt, enter) end end, 15)
    if c.bind then c.bind(tb) end
end

builders.keybind = function(parent, c, order)
    local row = rowFor(parent, order)
    local _, holder = layoutRow(row, c.text, false, 150)
    local b, lb
    b, lb = Button(holder, c.get(), UDim2.fromScale(1, 1), "glass", function()
        lb.Text = "Press a key..."
        listening = function(name)
            if name then c.set(name) end
            if lb.Parent then lb.Text = c.get() end
        end
    end, { size = 14 })
end

builders.buttons = function(parent, c, order)
    local n = #c.items
    local row = rowFor(parent, order, T.rowH)
    local holder
    if c.text then
        local w = 112 * n + 6 * (n - 1)
        local _, h = layoutRow(row, c.text, false, w)
        holder = h
    else
        holder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -16, 1, -6) }, row)
    end
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center }, holder)
    for i, it in ipairs(c.items) do
        local armed = false
        local b, lb
        b, lb = Button(holder, it.label, UDim2.new(1 / n, -(6 * (n - 1)) / n, 1, 0), it.style or "glass", function()
            if it.confirm and not armed then
                armed = true; lb.Text = "Sure?"
                task.delay(3, function() if armed and lb.Parent then armed = false; lb.Text = it.label end end)
                return
            end
            armed = false; lb.Text = it.label
            it.fn()
        end, { size = 15 })
        b.LayoutOrder = i
    end
end

builders.text = function(parent, c, order)
    local x = padX()
    local font = T.F.reg
    if c.font == "bold" then font = T.F.bold
    elseif c.font == "semi" then font = T.F.semi end
    local lb = New("TextLabel", { BackgroundTransparency = 1, Text = c.text, Font = font, TextSize = 14, TextColor3 = T.dim,
        TextWrapped = true, TextXAlignment = AL, TextYAlignment = Enum.TextYAlignment.Top, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0), LayoutOrder = order }, parent)
    New("UIPadding", { PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 5) }, lb)
end

builders.list = function(parent, c, order)
    local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, parent)
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, f)
    local items, sel = c.items(), c.selected()
    if #items == 0 then builders.text(f, { text = c.empty or "(nothing here yet)" }, 1) end
    for i, name in ipairs(items) do
        local b = Button(f, name, UDim2.new(1, 0, 0, 30), (name == sel) and "blue" or "glass", function() c.onSelect(name) end,
            { align = AL, pad = 12, size = 15 })
        b.LayoutOrder = i
    end
end

local function warnCol() return (T.kind == "xmb" or T.dark) and C(255, 205, 90) or C(185, 105, 0) end

builders.readout = function(parent, c, order)
    local row = rowFor(parent, order)
    local x = padX()
    Label(row, c.text, UDim2.fromOffset(x, 0), UDim2.new(0.4, -x, 1, 0))
    local val = Label(row, "", UDim2.new(0.4, 0, 0, 0), UDim2.new(0.6, -10, 1, 0), { align = AR, font = T.F.bold })
    local function upd() val.Text = tostring(c.get()) end
    upd()
    liveList[#liveList + 1] = upd
end

builders.livetext = function(parent, c, order)
    local x = padX()
    local lb = New("TextLabel", { BackgroundTransparency = 1, Text = "", Font = T.F.semi, TextSize = 14, TextWrapped = true,
        TextXAlignment = AL, TextYAlignment = Enum.TextYAlignment.Top, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0), LayoutOrder = order }, parent)
    New("UIPadding", { PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 5) }, lb)
    local function upd()
        local level, txt = c.get()
        lb.Text = txt
        lb.TextColor3 = (level == "safe" and okCol()) or (level == "bad" and errCol()) or (level == "warn" and warnCol()) or T.dim
    end
    upd()
    liveList[#liveList + 1] = upd
end

do
    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        acc += dt
        if acc < 0.2 or not UI.visible then return end
        acc = 0
        for _, f in ipairs(liveList) do pcall(f) end
    end)
end

-- 3D preview (used by the Customizer tab). The viewport only exists while its section is expanded, so a collapsed
-- section costs nothing. It rebuilds when the customizer says something changed, plus a slow refresh so blinking faces show.
-- c.model() -> Model | nil, c.dirty() -> bool (consumed), c.spin() -> bool, c.zoom() -> number, c.panMode() -> bool, c.bind(ctl) receives { reset, setZoom }
-- drag = rotate, middle mouse drag (or Shift + drag, or Pan Mode for touch) = move the view, wheel = zoom
builders.preview = function(parent, c, order)
    local kind = T.kind
    local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, c.height or 250), LayoutOrder = order }, parent)
    local x = padX()
    local vpf = New("ViewportFrame", { Position = UDim2.fromOffset(x, 4), Size = UDim2.new(1, -(x + 8), 1, -8),
        BackgroundColor3 = (kind == "xmb" and C(10, 24, 62)) or (kind == "xp" and C(236, 233, 216)) or (T.dark and (T.kind == "dandy" and C(30, 30, 34) or C(18, 34, 64)) or C(215, 240, 255)),
        BackgroundTransparency = 0.15, BorderSizePixel = 0, Ambient = C(190, 190, 200), LightColor = WHITE,
        LightDirection = Vector3.new(-1, -1.5, -1), Active = true }, row)
    corner(vpf, 8); stroke(vpf, T.accent, 1, 0.3)
    local world = New("WorldModel", {}, vpf)
    local cam = New("Camera", { FieldOfView = 35 }, vpf)
    vpf.CurrentCamera = cam
    local pv = { yaw = 0.6, pitch = 0.12, zoom = (c.zoom and c.zoom()) or 1, center = Vector3.new(0, 0, 0), pan = Vector3.new(0, 0, 0), size = 6 }
    local function place()
        local d = pv.size * 1.9 * pv.zoom
        local dir = Vector3.new(math.sin(pv.yaw) * math.cos(pv.pitch), math.sin(pv.pitch), math.cos(pv.yaw) * math.cos(pv.pitch))
        local focus = pv.center + pv.pan
        cam.CFrame = CFrame.new(focus + dir * d, focus)
    end
    place()
    local myDrag, dragBtn
    vpf.InputBegan:Connect(function(i)
        local t = i.UserInputType
        local middle = t == Enum.UserInputType.MouseButton3
        if not (middle or isPress(i)) then return end
        local panning = middle or (c.panMode and c.panMode()) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        local sp, y0, p0, pan0 = i.Position, pv.yaw, pv.pitch, pv.pan
        if panning then
            local right, up = cam.CFrame.RightVector, cam.CFrame.UpVector
            dragBtn = middle and t or nil                      -- Tony's global handler only ends left-click drags, so we watch this button ourselves
            myDrag = function(p)
                local k = 2 * pv.size * 1.9 * pv.zoom * math.tan(math.rad(17.5)) / math.max(vpf.AbsoluteSize.Y, 1)   -- studs per pixel at the focus point, so the model follows the cursor 1:1
                local v = pan0 - right * (p.X - sp.X) * k + up * (p.Y - sp.Y) * k
                local lim = pv.size * 1.5
                if v.Magnitude > lim then v = v.Unit * lim end
                pv.pan = v
                place()
            end
        else
            dragBtn = nil
            myDrag = function(p)
                pv.yaw = y0 - (p.X - sp.X) * 0.012
                pv.pitch = math.clamp(p0 + (p.Y - sp.Y) * 0.008, -1.2, 1.2)
                place()
            end
        end
        activeDrag = myDrag
    end)
    vpf.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseWheel then
            pv.zoom = math.clamp(pv.zoom - i.Position.Z * 0.08, 0.3, 3)
            place()
        end
    end)
    local shown, lastBuild, pending = nil, -10, true
    local function rebuild(m)
        lastBuild = os.clock(); shown = m; pending = false
        world:ClearAllChildren()
        if not m or not m.Parent then return end
        local touched = {}
        for _, d in ipairs(m:GetDescendants()) do
            if not d.Archivable then d.Archivable = true; touched[#touched + 1] = d end
        end
        if not m.Archivable then m.Archivable = true; touched[#touched + 1] = m end
        local ok, clone = pcall(function() return m:Clone() end)
        for _, d in ipairs(touched) do pcall(function() d.Archivable = false end) end
        if not ok or not clone then return end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("Humanoid") or d:IsA("Animator") or d:IsA("AnimationController") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false end
        end
        clone.Parent = world
        pcall(function() clone:PivotTo(CFrame.new(0, 0, 0)) end)
        local okb, cf, size = pcall(function() return clone:GetBoundingBox() end)
        if okb then pv.center = cf.Position; pv.size = math.max(size.X, size.Y, size.Z, 1) end
        place()
    end
    local con
    con = RunService.Heartbeat:Connect(function(dt)
        if not alive or not vpf:IsDescendantOf(game) then con:Disconnect(); return end
        if not UI.visible then return end
        if dragBtn and not UIS:IsMouseButtonPressed(dragBtn) then       -- middle button let go
            if activeDrag == myDrag then activeDrag = nil end
            dragBtn = nil
        end
        if c.spin and c.spin() and activeDrag ~= myDrag then pv.yaw = pv.yaw + dt * 0.7; place() end
        local now = os.clock()
        local m = c.model()
        if c.dirty and c.dirty() then pending = true end
        if m ~= shown or (pending and now - lastBuild > 0.3) or now - lastBuild > 2 then rebuild(m) end
    end)
    if c.bind then c.bind({
        reset = function() pv.yaw, pv.pitch, pv.zoom, pv.pan = 0.6, 0.12, 1, Vector3.new(0, 0, 0); place() end,
        setZoom = function(z) pv.zoom = z; place() end,
    }) end
end

-- HOVER HINTS: one-liners shown in the status bar when you hover a control.
-- Looked up as "Section/Label" first, then "Label". A control can also carry its own  desc = "..."  field.
UI.hints = {
    -- ESP
    ["Enable ESP"] = "Master switch. Off means no highlights at all.",
    ["Fill Highlights"] = "Colors the whole body instead of just the outline.",
    ["Fill Transparency"] = "How see-through the fill is. 1 is invisible, 0 is a solid blob.",
    ["Outline Transparency"] = "Same idea, but for the outline.",
    ["Show Through Walls"] = "On: see everything through walls. Off: only what you could see anyway.",
    ["Max Highlights"] = "Roblox only allows so many highlights at once. This is the cap.",
    ["Refresh Rate (sec)"] = "How often ESP rescans the map. Lower is snappier and a bit heavier.",
    ["Highlight Myself"] = "Highlights you too, for the self-obsessed.",
    ["Hide Completed Machines"] = "Finished machines stop glowing, so you only see the ones left.",
    ["Hide Used Doors"] = "Used Trick or Treat doors lose their highlight.",
    ["Per-Item Colors"] = "Gives each item type its own color (see Item Colors).",
    ["Show Twisted Astro's Pillows"] = "Shows Twisted Astro's pillows, in their own color.",
    ["Different Color For Others"] = "Other people's pillows get a color of their own.",
    ["Color Brusha Debuffed Machines"] = "Tints the machines Brusha has messed with.",
    ["Color Duo Machines With One Worker"] = "Tints duo machines that only have one person on them.",
    -- Movement
    ["Infinite Stamina"] = "You never visibly run out. The server disagrees, but nobody asked it.",
    ["Show Actual Stamina"] = "Drops the fake full bar and shows the real number.",
    ["Show Sprint Icon While Fake Running"] = "Keeps the sprint icon up while the fake run is going.",
    ["Enable Speed Modifier"] = "Turns on the speed boost below. Mind the anti-cheat.",
    ["Speed/Mode"] = "Additive adds units, multiplicative multiplies. The note above has the details.",
    ["Manual Floor (0 = Auto)"] = "Pretend you're on this floor for the odd/even split. 0 figures it out itself.",
    ["Step"] = "How big each nudge on the speed sliders is.",
    ["Sync Animation Speed With Stats"] = "Walk, run and extraction animations match your speed. Idle is left alone.",
    ["Ability Animations Follow Speed"] = "Ability animations match your speed while you move, or your decode speed while you extract.",
    ["Fullbright"] = "See everything. Raises the ambient light, removes shadows and fog.",
    ["Hide Ichor Splats"] = "Hides the ink that covers your screen when you step in an Ichor puddle.",
    ["Fullbright Brightness"] = "How bright the ambient light is while Fullbright is on.",
    ["Walk Speed (Units Added)/All Floors"] = "Extra walk speed on every floor.",
    ["Walk Speed (Units Added)/Odd Floors"] = "Extra walk speed, odd floors only.",
    ["Walk Speed (Units Added)/Even Floors"] = "Extra walk speed, even floors only.",
    ["Run Speed (Units Added)/All Floors"] = "Extra run speed on every floor.",
    ["Run Speed (Units Added)/Odd Floors"] = "Extra run speed, odd floors only.",
    ["Run Speed (Units Added)/Even Floors"] = "Extra run speed, even floors only.",
    -- World
    ["Noclip"] = "Walk through walls. Floors stay solid, so you won't fall out of the map.",
    ["Include Walls Folders (Keeps Floors)"] = "Also opens up everything inside the Walls folders.",
    ["Extra Names (Comma Separated)"] = "Extra things to turn non-solid. Press Enter to apply.",
    -- Automation
    ["Default Machines"] = "Taps the standard skill check for you.",
    ["Circle Machines"] = "Handles the circle skill check for you.",
    ["Treadmill Machines"] = "Taps through treadmill checks so you don't have to.",
    ["Swimmy Barnaby Machines"] = "Barnaby flies dead level and the seaweed never lands a hit.",
    ["Snap To Green/Yellow"] = "Nudges the marker or ring onto the exact middle of the green or yellow zone before it taps.",
    ["Treadmill Taps Per Second"] = "How fast it taps on treadmill checks.",
    ["Hide Seaweed"] = "Hides obstacles before the game shows them, so Barnaby has nothing to hit.",
    ["Pull Coins Into Barnaby"] = "Drags each coin to Barnaby as it approaches.",
    ["Instant Coins"] = "Grabs each coin the second it spawns.",
    ["Coin For Every Seaweed"] = "Pays you a coin for every seaweed gap, even the empty ones.",
    ["Continuous Coins"] = "Collects coins nonstop. The server may get picky if it's too fast.",
    ["Continuous Coins Per Second"] = "Lower this if your progress stops going up.",
    ["Auto Run On Treadmill Machines"] = "Holds sprint for you while you work a treadmill.",
    ["Instant Calibration Success"] = "Skips the minigame with a perfect hit. Not subtle, but effective.",
    ["Affect Default Machines"] = "Instant Calibration Success answers default (bar and marker) machines.",
    ["Affect Circle Machines"] = "Instant Calibration Success answers circle machines.",
    ["Affect Treadmill Machines"] = "Instant Calibration Success answers treadmill machines.",
    ["Response Delay (Seconds)"] = "How long it waits before answering. A little delay looks less robotic.",
    -- Skill Checks
    ["More Skill Checks (Outside Machines)"] = "Extra skill checks when you're not on a machine, because normal ones weren't stress enough.",
    ["When Can They Happen"] = "Limits extra checks to certain situations.",
    ["Default Skill Check"] = "Lets the default check show up as an extra check.",
    ["Circle Skill Check"] = "Lets the circle check show up as an extra check.",
    ["Treadmill Skill Check"] = "Lets the treadmill check show up as an extra check.",
    ["Minimum Seconds Between Checks"] = "Breathing room between extra checks.",
    ["Count Twisteds"] = "Which Twisteds count toward the per-Twisted changes.",
    ["Gold Skill Check Rewards"] = "Bonus rewards when you land a gold hit.",
    ["Skill Check Failure Penalties"] = "What failing an extra check costs you. Sadness not included.",
    ["Stacking"] = "What happens when the same effect hits you again.",
    ["Trinket Interactions"] = "Lets equipped trinkets mess with extra checks.",
    ["Failed Treadmill Check Slows You"] = "The wiki's treadmill penalty, for when you flub one.",
    ["Show Effect Icons (Right Side And Overhead)"] = "Shows the game's buff icons for your fake effects.",
    -- Pursuer
    ["Pursuer"] = "Master switch for your personal nightmare.",
    ["Kills You On Touch (Turn Off To Test)"] = "Off lets you test it without consequences. On brings the consequences.",
    ["Touch Size (x)"] = "How big its hitbox is, as a multiplier.",
    ["Pixelated (Crisp Pixels, No Smoothing)"] = "Crisp pixels instead of blurry smoothing. Better for memes.",
    ["Tint (Hex, ffffff = None)"] = "Color tint for the picture. ffffff leaves it alone.",
    ["Dash (Dark Esau Style)"] = "Now and then it lunges at you. Dark Esau energy.",
    ["Afterimages"] = "Fading copies trail behind it. Purely for drama.",
    ["It Plays Music"] = "Plays its own music while it chases you.",
    ["Eye Icon And Chase Counter While It Chases"] = "Shows the game's eye icon, like a real Twisted spotted you.",
    ["Speed While You Extract"] = "Slow it down, or set an exact speed, while you decode. Replaces the pause.",
    ["Speed In Panic Mode"] = "Boost it in panic mode by a percentage, a flat amount, or set one exact speed.",
    ["Suppression Card Lowers The Boost"] = "What the Suppression card does to the panic boost: nothing, a flat amount or a percentage.",
    ["Pauses While You Extract From A Machine"] = "Stands still while you're decoding.",
    -- Customizer
    ["Auto-Spin"] = "Spins the model on its own, like a display case.",
    ["Drag Moves Instead Of Rotating"] = "Dragging pans the view. Handy on touch screens.",
    ["Keep Animations Local"] = "On: only you see your custom animations.",
    ["2D Character"] = "Swaps your 3D body for a flat picture.",
    ["Auto-Apply On Join"] = "Loads this config for you as soon as you join.",
    ["Keep Edits Between Rounds"] = "Your edits survive when a round ends.",
    ["Only Load For This Toon"] = "The config only loads when you're playing this toon.",
    -- Sound
    ["Music Player"] = "Master switch for your music.",
    ["Sound Effects"] = "Master switch for your custom sound effects.",
    ["Twisted Emitters"] = "Master switch for sounds attached to Twisteds.",
    ["Game Sound Replacement"] = "Master switch for swapping the game's own sounds.",
    ["Mute Game Music"] = "Silences the game's music so it stops fighting yours.",
    ["Mute Keywords"] = "Sounds with these words in their name get muted.",
    ["Log Playing Sounds"] = "Records what's playing so the browser can show it.",
    -- Configs + Appearance
    ["Auto-Load Last Config"] = "Loads the config you used last time when the script starts.",
    ["UI Sounds"] = "The little clicks and pings. Off if you hate joy.",
    ["UI Volume"] = "How loud those clicks and pings are.",
    ["Show / Hide Key"] = "The key that shows and hides this window.",
    ["UI Scale"] = "Makes the whole window bigger or smaller.",
    ["Fullscreen"] = "The window takes over the screen. Subtle.",
    ["Show Orb When Hidden"] = "A small button that brings the window back.",
    ["Start Hidden"] = "Starts out of sight. Press your key when you're ready.",
}
function UI.hintFor(sec, c)
    if c.desc then return c.desc end
    local h = UI.hints
    return h[tostring(sec.title) .. "/" .. tostring(c.text)] or h[tostring(c.text)]
end

-- LAYOUT: every tab is a "section rail" (left) + one section at a time (middle) + an optional pinned pane (right, wide windows only).
-- Nothing collapses and nothing needs a long scroll: pick a section in the rail and its controls fill the page.
local makePane, clearGui, loadSections   -- used by the skins, the library adapter and buildGui
do
local RAIL_W, PIN_W, PIN_MIN = 176, 300, 380                  -- rail width, pinned pane width, minimum width kept for the middle
local SIDE_W = { dandy = 200, aero = 190, xmb = 90, xp = 190 }   -- how much of the window the skin's own tab column takes

local function designW()
    local w = (Win and UIScaleObj) and (Win.AbsoluteSize.X / math.max(UIScaleObj.Scale, 0.1)) or 0
    if w < 200 then w = S.fullscreen and 1280 or (S.win[S.style] and S.win[S.style].w) or 900 end
    return w
end
local function canPin() return designW() - (SIDE_W[T.kind] or 190) >= RAIL_W + PIN_W + PIN_MIN end

function clearGui(o) for _, ch in ipairs(o:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end end

-- wraps the skin's scrolling Content in a Host frame that also holds the rail and the pinned pane
function makePane()
    local par, pos, size = Content.Parent, Content.Position, Content.Size
    Host = New("Frame", { Name = "Pane", BackgroundTransparency = 1, BorderSizePixel = 0, Position = pos, Size = size }, par)
    Content.Parent = Host
    local function side(name)
        local sf = New("ScrollingFrame", { Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Visible = false,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Host)
        if T.kind == "dandy" then
            sf.BackgroundColor3 = C(15, 15, 15); sf.BackgroundTransparency = 0.45
            corner(sf, 10); stroke(sf, BLACK, 3, 0)
        end
        New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }, sf)
        return sf
    end
    Rail = side("Rail")
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, Rail)
    PinPane = side("Pinned")
    PinPane.AnchorPoint = Vector2.new(1, 0)
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, PinPane)
    -- re-flow when the window is resized across the "wide enough to pin" line
    gconnect(Win:GetPropertyChangedSignal("AbsoluteSize"), function()
        if UI.pinned ~= nil and UI.pinned ~= (UI.pinWanted and canPin()) then task.defer(function() if Host and Host.Parent then renderPage() end end) end
    end)
end

local function layoutPane(showRail, showPin)
    local rw = showRail and RAIL_W or 0
    local pw = showPin and PIN_W or 0
    Rail.Visible = showRail
    Rail.Position = UDim2.fromOffset(0, 0); Rail.Size = UDim2.new(0, RAIL_W - 6, 1, 0)
    PinPane.Visible = showPin
    PinPane.Position = UDim2.new(1, 0, 0, 0); PinPane.Size = UDim2.new(0, PIN_W - 6, 1, 0)
    Content.Position = UDim2.fromOffset(rw, 0)
    Content.Size = UDim2.new(1, -(rw + pw), 1, 0)
end

local function renderSection(parent, sec, order)
    local kind = T.kind
    local f = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, parent)
    if kind == "aero" then
        f.BackgroundTransparency = T.panelT; f.BackgroundColor3 = T.c.panel
        corner(f, 14); stroke(f, WHITE, 1.5, 0.2)
        New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.1, 0.5) }, f)
        New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, f)
    else
        New("UIPadding", { PaddingBottom = UDim.new(0, 8) }, f)
    end
    New("UIListLayout", { Padding = UDim.new(0, kind == "dandy" and 5 or 2), SortOrder = Enum.SortOrder.LayoutOrder }, f)
    if sec.title then
        local head = Label(f, sec.title, UDim2.new(), UDim2.new(1, 0, 0, kind == "dandy" and 34 or 28), {
            font = T.F.bold, size = (kind == "dandy" and 24) or (kind == "aero" and 19) or 15,
            color = (kind == "dandy" and T.accent) or (kind == "xp" and T.c.title:Lerp(BLACK, 0.1)) or (kind == "xmb" and T.dim) or T.text })
        head.LayoutOrder = 0
        if kind == "dandy" then head.TextStrokeTransparency = 0; head.TextStrokeColor3 = BLACK; head.TextXAlignment = AL end
        if kind ~= "aero" then New("UIPadding", { PaddingLeft = UDim.new(0, padX()) }, head) end
    end
    for i, c in ipairs(sec.controls) do
        local b = builders[c.t]
        if b then
            UI.curHint = UI.hintFor(sec, c)
            UI.curBindId = nil
            if c.t == "toggle" and UI.binds and not c.nobind then
                UI.curBindId = UI.binds.track(UI.current, sec, c)
                UI.curHint = UI.binds.hint(UI.curHint)
            end
            local ok, err = pcall(b, f, c, i)
            UI.curHint, UI.curBindId = nil, nil
            if not ok then warn("[Tony Script Palace] control error (" .. tostring(c.t) .. " '" .. tostring(c.text) .. "'): " .. tostring(err)) end
        end
    end
end

-- builds a tab's sections and gives each one a stable key (group|title)
function loadSections(tab)
    local ok, secs = pcall(tab.build)
    if not ok then warn("[Tony Script Palace] page error: " .. tostring(secs)); return nil end
    for _, sec in ipairs(secs) do sec._key = (sec.group or "") .. "|" .. tostring(sec.title) end
    return secs
end

local function buildRail(navs, selKey, tabId)
    clearGui(Rail)
    local lastGroup, order = nil, 0
    for _, sec in ipairs(navs) do
        if sec.group and sec.group ~= lastGroup then
            lastGroup = sec.group
            order += 1
            local h = Label(Rail, string.upper(sec.group), UDim2.new(), UDim2.new(1, 0, 0, 24), { font = T.F.bold, size = 13, color = (T.kind == "dandy") and T.accent or T.dim })
            h.LayoutOrder = order
            New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 6) }, h)
        end
        order += 1
        local b = Button(Rail, sec.rail or sec.title, UDim2.new(1, -2, 0, T.kind == "dandy" and 34 or 32), (sec._key == selKey) and "blue" or "glass", function()
            if UI.sel[tabId] == sec._key then return end
            UI.sel[tabId] = sec._key
            renderPage()
            if Content then Content.CanvasPosition = Vector2.zero end
        end, { align = AL, pad = 10, size = 15 })
        b.LayoutOrder = order
    end
end

function renderPage()
    if not Content then return end
    closePopup()
    clearGui(Content); clearGui(PinPane); clearGui(Rail)
    table.clear(rainbowSw)
    table.clear(liveList)
    local tab
    for _, t in ipairs(UI.tabs) do if t.id == UI.current then tab = t end end
    if not tab then return end
    local secs = loadSections(tab)
    if not secs then return end

    UI.pinWanted = true
    local pin = canPin()
    UI.pinned = pin
    local navs, pins = {}, {}
    for _, sec in ipairs(secs) do
        if sec.pin and pin then pins[#pins + 1] = sec else navs[#navs + 1] = sec end
    end
    local sel = navs[1]
    for _, sec in ipairs(navs) do if sec._key == UI.sel[tab.id] then sel = sec end end
    if not sel then layoutPane(false, #pins > 0); for i, sec in ipairs(pins) do renderSection(PinPane, sec, i) end; return end

    layoutPane(#navs > 1, #pins > 0)
    if #navs > 1 then buildRail(navs, sel._key, tab.id) end
    renderSection(Content, sel, 1)
    for i, sec in ipairs(pins) do renderSection(PinPane, sec, i) end
end

end   -- layout internals

local function refreshPage()
    local y = Content and Content.CanvasPosition.Y or 0
    renderPage()
    task.defer(function() if Content and Content.Parent then Content.CanvasPosition = Vector2.new(0, y) end end)
end

local function setTab(id)
    if UI.current == id then return end
    UI.current = id
    if T and T.kind == "xmb" then ui("open") end
    if UI.onTab then UI.onTab() end
    renderPage()
    if Content then Content.CanvasPosition = Vector2.zero end
end

local function statusDefault() return "Press " .. S.keybind .. " to hide or show the hub." end
function UI.hintOn(msg) if StatusLbl then StatusLbl.Text = msg; StatusLbl.TextColor3 = T.text end end
function UI.hintOff() if StatusLbl then StatusLbl.Text = statusDefault(); StatusLbl.TextColor3 = T.dim end end
local statusToken = 0
function toast(msg, kind)
    statusToken += 1
    local tok = statusToken
    if kind == "ok" then ui("ok") elseif kind == "err" then ui("err") elseif kind == "ng" then ui("ng") end
    if StatusLbl then
        StatusLbl.Text = msg
        StatusLbl.TextColor3 = ((kind == "err" or kind == "ng") and errCol()) or (kind == "ok" and okCol()) or T.text
    end
    task.delay(4.5, function()
        if alive and tok == statusToken and StatusLbl and StatusLbl.Parent then
            StatusLbl.Text = statusDefault(); StatusLbl.TextColor3 = T.dim
        end
    end)
end

SP.onFlagUI = function(msg) toast(msg, "err") end

--#endregion row-builders
--#region libs
----------------------------------------------------------------------
-- EXTERNAL LIBRARY (optional, loaded safely)
--   Dandy's World API Library : live game info (floor, machines, players alive...) for the World tab. Loads in the background.
----------------------------------------------------------------------
local fetchLib   -- download + run a library, returns (lib) or (nil, reason)
do
local loadStr = loadstring or env.loadstring

function fetchLib(url)
    if not loadStr then return nil, "this executor has no loadstring" end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or type(body) ~= "string" or #body < 100 then return nil, "download failed" end
    local fn, cerr = loadStr(body)
    if not fn then return nil, tostring(cerr) end
    local ok2, lib = pcall(fn)
    if not ok2 then return nil, tostring(lib) end
    return lib
end

end

local API_URL = "https://raw.githubusercontent.com/did-i-leave-the-oven-on/Dandy-s-World-API-Library/refs/heads/main/Dandy's%20World%20API%20Library.lua"
local DWAPI = { lib = env.TonyScriptPalaceAPI, state = "idle" }   -- the library can only be loaded once per session, so the table is kept in env
function DWAPI.load()
    if DWAPI.lib or DWAPI.state == "loading" then return end
    DWAPI.state = "loading"
    task.spawn(function()
        local lib = fetchLib(API_URL)
        if type(lib) == "table" and lib.GetGameInfo then
            DWAPI.lib = lib; env.TonyScriptPalaceAPI = lib; DWAPI.state = "ready"
        else
            DWAPI.state = env.DWAPIL_LOADED and "other" or "failed"   -- "other" = another script already loaded it and kept the table to itself
        end
    end)
end
local function apiField(fn)   -- a safe readout for the World tab
    return function()
        local api = DWAPI.lib
        if not api then
            return (DWAPI.state == "loading" and "Loading...") or (DWAPI.state == "other" and "In use by another script") or "Not loaded"
        end
        if not api.InRun then return "Not in a run" end
        local ok, v = pcall(fn, api)
        if ok and v ~= nil then return tostring(v) end
        return "-"
    end
end


--#endregion libs
--#region page-esp
----------------------------------------------------------------------
-- PAGES
----------------------------------------------------------------------
local ITEM_LABELS = { GigiHoard = "Twisted Gigi's Stash", Gumball = "Gumballs" }   -- internal name -> official name
local function pretty(n) return ITEM_LABELS[n] or (n:gsub("(%l)(%u)", "%1 %2")) end

local function resetESPColors()
    local c, d = Cfg.Categories, DEF.Categories
    for _, k in ipairs({ "Players", "Twisteds", "Tendrils", "BlotHands", "IchorPuddles", "Doors", "Bookshelves", "StarPillows" }) do c[k].Color = d[k].Color end
    c.StarPillows.OtherColor = d.StarPillows.OtherColor
    c.StarPillows.TwistedColor = d.StarPillows.TwistedColor
    c.Generators.Colors = deepcopy(d.Generators.Colors)
    c.Items.Color, c.Items.Fallback, c.Items.Colors = d.Items.Color, d.Items.Fallback, deepcopy(d.Items.Colors)
    espDirty = true
end

local function buildESPPage()
    local cats = Cfg.Categories
    local function tg(text, tbl, key)
        return { t = "toggle", text = text, get = function() return tbl[key] end, set = function(v) tbl[key] = v; espDirty = true end }
    end
    local function cl(text, tbl, key, dtbl)
        return { t = "color", text = text, rainbow = true, get = function() return tbl[key] end,
            set = function(v) tbl[key] = v; espDirty = true end, default = function() return dtbl[key] end }
    end
    local function sl(text, tbl, key, min, max, dec)
        return { t = "slider", text = text, min = min, max = max, dec = dec, get = function() return tbl[key] end, set = function(v) tbl[key] = v; espDirty = true end }
    end
    local secs = {}
    secs[#secs + 1] = { title = "General", controls = {
        tg("Enable ESP", Cfg, "Enabled"),
        tg("Fill Highlights", Cfg, "Fill"),
        { t = "text", text = "Turn this off if you only want outlines. Each category below also has its own Fill switch, because one was apparently not enough."},
        sl("Fill Transparency", Cfg, "FillTransparency", 0, 1, 2),
        sl("Outline Transparency", Cfg, "OutlineTransparency", 0, 1, 2),
        tg("Show Through Walls", Cfg, "AlwaysOnTop"),
        sl("Max Highlights", Cfg, "MaxHighlights", 4, 255, 0),
        sl("Refresh Rate (sec)", Cfg, "UpdateRate", 0.05, 1, 2),
        { t = "buttons", items = { { label = "Reset ESP Colors", style = "red", confirm = true, fn = function()
            resetESPColors(); refreshPage(); toast("ESP colors reset to default.", "ok")
        end } } },
    } }
    secs[#secs + 1] = { title = "Toons", controls = { tg("Enabled", cats.Players, "Enabled"), tg("Fill", cats.Players, "Fill"), tg("Highlight Myself", cats.Players, "Self"), cl("Color", cats.Players, "Color", DEF.Categories.Players) } }
    secs[#secs + 1] = { title = "Twisteds", controls = { tg("Enabled", cats.Twisteds, "Enabled"), tg("Fill", cats.Twisteds, "Fill"), cl("Color", cats.Twisteds, "Color", DEF.Categories.Twisteds) } }
    secs[#secs + 1] = { title = "Twisted Sprout's Tendrils", controls = { tg("Enabled", cats.Tendrils, "Enabled"), tg("Fill", cats.Tendrils, "Fill"), cl("Color", cats.Tendrils, "Color", DEF.Categories.Tendrils) } }
    secs[#secs + 1] = { title = "Twisted Blot's Hands", controls = { tg("Enabled", cats.BlotHands, "Enabled"), tg("Fill", cats.BlotHands, "Fill"), cl("Color", cats.BlotHands, "Color", DEF.Categories.BlotHands) } }
    secs[#secs + 1] = { title = "Ichor Puddles", controls = { tg("Enabled", cats.IchorPuddles, "Enabled"), tg("Fill", cats.IchorPuddles, "Fill"), cl("Color", cats.IchorPuddles, "Color", DEF.Categories.IchorPuddles) } }
    secs[#secs + 1] = { title = "Machines", controls = {
        tg("Enabled", cats.Generators, "Enabled"), tg("Fill", cats.Generators, "Fill"),
        tg("Hide Completed Machines", cats.Generators, "HideCompleted"),
        cl("Incomplete", cats.Generators.Colors, "Incomplete", DEF.Categories.Generators.Colors), cl("In Progress", cats.Generators.Colors, "InProgress", DEF.Categories.Generators.Colors),
        cl("Completed", cats.Generators.Colors, "Completed", DEF.Categories.Generators.Colors), cl("Connie", cats.Generators.Colors, "Connie", DEF.Categories.Generators.Colors),
        tg("Color Brusha Debuffed Machines", cats.Generators, "Brusha"), cl("Brusha Debuffed", cats.Generators.Colors, "Brusha", DEF.Categories.Generators.Colors),
        tg("Color Duo Machines With One Worker", cats.Generators, "DuoOne"), cl("Duo, One Worker", cats.Generators.Colors, "DuoOne", DEF.Categories.Generators.Colors),
    } }
    secs[#secs + 1] = { title = "Trick or Treat Doors", controls = {
        tg("Enabled", cats.Doors, "Enabled"), tg("Fill", cats.Doors, "Fill"), cl("Color", cats.Doors, "Color", DEF.Categories.Doors), tg("Hide Used Doors", cats.Doors, "HideUsed"),
    } }
    secs[#secs + 1] = { title = "Bookshelves", controls = { tg("Enabled", cats.Bookshelves, "Enabled"), tg("Fill", cats.Bookshelves, "Fill"), cl("Color", cats.Bookshelves, "Color", DEF.Categories.Bookshelves) } }

    local it = cats.Items
    local itemCtl = {
        tg("Enabled", it, "Enabled"), tg("Fill", it, "Fill"),
        { t = "toggle", text = "Per-Item Colors", get = function() return it.PerItem end,
            set = function(v) it.PerItem = v; espDirty = true; refreshPage() end },
    }
    if it.PerItem then itemCtl[#itemCtl + 1] = cl("Other Items", it, "Fallback", DEF.Categories.Items)
    else itemCtl[#itemCtl + 1] = cl("All Items", it, "Color", DEF.Categories.Items) end
    secs[#secs + 1] = { title = "Items", controls = itemCtl }

    if it.PerItem then
        local ic = { { t = "text", text = "Tick the box to show an item, click the swatch to pick its color. Truly cutting-edge technology."} }
        for _, name in ipairs(KNOWN_ITEMS) do
            ic[#ic + 1] = { t = "color", text = pretty(name), rainbow = true,
                enable = { get = function() return not it.Hidden[name] end, set = function(v) it.Hidden[name] = (not v) or nil; espDirty = true end },
                get = function() return it.Colors[name] or it.Fallback end,
                default = function() return DEF.Categories.Items.Colors[name] or DEF.Categories.Items.Fallback end,
                set = function(v) it.Colors[name] = v; espDirty = true end }
        end
        secs[#secs + 1] = { title = "Item Colors", controls = ic }
    end

    local PILLOW_NAMES = { All = "Everyone's", Mine = "Only Mine", Others = "Only Others'" }
    local PILLOW_MODES = { ["Everyone's"] = "All", ["Only Mine"] = "Mine", ["Only Others'"] = "Others" }
    local sp = cats.StarPillows
    secs[#secs + 1] = { title = "Star Pillows", controls = {
        tg("Enabled", sp, "Enabled"), tg("Fill", sp, "Fill"),
        { t = "dropdown", text = "Highlight", get = function() return PILLOW_NAMES[sp.Mode] or "Everyone's" end,
            options = function() return { "Everyone's", "Only Mine", "Only Others'" } end,
            set = function(o) sp.Mode = PILLOW_MODES[o] or "All"; espDirty = true; refreshPage() end },
        cl("Color", sp, "Color", DEF.Categories.StarPillows),
        tg("Different Color For Others", sp, "OtherDiff"),
        cl("Others' Color", sp, "OtherColor", DEF.Categories.StarPillows),
        tg("Show Twisted Astro's Pillows", sp, "ShowTwisted"),
        cl("Twisted Astro's Color", sp, "TwistedColor", DEF.Categories.StarPillows),
        { t = "text", text = "Highlight (Everyone's / Only Mine / Only Others') is for Toon pillows. Twisted Astro's pillows do their own thing, with their own switch and color."},
    } }
    return secs
end

--#endregion page-esp
--#region page-movement
local function num(n) return ((string.format("%.2f", n):gsub("%.?0+$", ""))) end

local function buildMovementPage()
    local additive = Speed.Mode == "Additive"
    local stepSize = STEP_SIZES[Speed.Step] or 1
    local sdec = (stepSize == 1 and 0) or (stepSize == 2.5 and 1) or 2
    local function L(f, fallback) local l = SP.last; if l and l.ok then return f(l) end; return fallback or "-" end

    local secs = {}
    secs[1] = { title = "Stamina", controls = {
        { t = "livetext", get = function() return SP.stamStatus() end },
        { t = "readout", text = "Stamina", get = function()
            return L(function(l) return l.stam and (math.floor(l.stam + 0.5) .. " / " .. tostring(l.stamMax)) or "-" end)
        end },
        { t = "toggle", text = "Infinite Stamina", get = function() return Stam.Infinite end,
            set = function(v)
                Stam.Infinite = v
                if v then toast("Infinite Stamina is on. Run out of stamina and keep holding sprint to keep running.", "info") end
            end },
        { t = "toggle", text = "Show Actual Stamina", get = function() return Stam.ShowActual end, set = function(v) Stam.ShowActual = v end },
        { t = "toggle", text = "Show Sprint Icon While Fake Running", get = function() return Stam.Icon end, set = function(v) Stam.Icon = v end },
        { t = "text", text = "Infinite Stamina is smoke and mirrors. The server still thinks you're out of stamina and walking, so we set your speed to what a real sprint would give you (your Run adjustments below count if the speed modifier is on) and play the run animation. It kicks in when you try to run while empty. Show Actual Stamina gets rid of the fake full bar if you'd rather know the truth."},
    } }
    secs[#secs + 1] = { title = "Animation Sync", controls = {
        { t = "text", text = "Makes your animations match your speed. Walk and run animations play faster or slower depending on how your humanoid speed compares to your toon's own walk and run speed (from its TowerData module), and exactly that speed means normal. The extraction animation follows your DecodeSpeedModifier, and ability animations follow your speed while you move or your decode speed while you extract. Idle is never touched. Visual only, and only on your screen." },
        { t = "toggle", text = "Sync Animation Speed With Stats", get = function() return Speed.Anim.On end,
            set = function(v) Speed.Anim.On = v; if not v then SP.animRestore() end end },
        { t = "toggle", text = "Ability Animations Follow Speed", get = function() return Speed.Anim.Ability end,
            set = function(v) Speed.Anim.Ability = v end },
        { t = "livetext", get = function() return "info", SP.animSt.text end },
    } }
    secs[#secs + 1] = { title = "Speed", controls = {
        { t = "text", text = "Speeding in Dandy's World is not a victimless crime.\n\n   \"Sir, do you know how fast you were walking?\"\n   \"Fast enough to lagback, officer.\"\n\nGo too fast and the anti-cheat yanks you back to where you were. It's not a ban, just the game telling you to chill. The Speed Trust score below drops every time you get flagged, so if it's dropping, ease off."},
        { t = "livetext", get = function() return SP.risk() end },
        { t = "readout", text = "Humanoid Speed", get = function() return L(function(l) return num(l.humSpeed) end) end },
        { t = "readout", text = "State", get = function() return L(function(l) return l.running and "Running" or "Walking" end) end },
        { t = "readout", text = "Game Speed (Normal)", get = function() return L(function(l) return num(l.vanilla) end) end },
        { t = "readout", text = "Script Speed", get = function() return L(function(l) return num(l.final) end) end },
        { t = "readout", text = "Floor", get = function()
            return L(function(l) return l.floor and (l.floor .. "  (" .. tostring(l.floorSrc) .. ")") or "Not found - set it below" end)
        end },
        { t = "readout", text = "Stats Folder", get = function() return L(function(l) return l.statsPath end, "Not found") end },
        { t = "readout", text = "Speed Trust Score", get = function()
            return L(function(l) return l.trust ~= nil and tostring(l.trust) or "-" end)
        end },
        { t = "toggle", text = "Enable Speed Modifier", get = function() return Speed.Enabled end,
            set = function(v)
                Speed.Enabled = v
                if v then
                    task.delay(0.3, function()
                        local level, txt = SP.risk()
                        if level == "warn" or level == "bad" then toast(txt, "ng") end
                    end)
                end
            end },
        { t = "dropdown", text = "Mode", get = function() return Speed.Mode end,
            options = function() return { "Additive", "Multiplicative" } end,
            set = function(o) Speed.Mode = o; refreshPage() end },
        { t = "text", text = additive
            and "Additive: (game speed + your units) x the game's modifier. Only one mode runs at a time."
            or "Multiplicative: game speed x the game's modifier x your multiplier. Percents stack, so the game's +10% and your +5% make +15.5%, not 15. Only one mode runs at a time."},
        { t = "slider", text = "Manual Floor (0 = Auto)", min = 0, max = 100, dec = 0, step = 1,
            get = function() return Speed.Floor end, set = function(v) Speed.Floor = v end },
    } }
    if additive then
        secs[#secs + 1] = { title = "Adjustment Step", controls = {
            { t = "dropdown", text = "Step", get = function() return Speed.Step end,
                options = function() return { "Units", "Stars", "Half Stars" } end,
                set = function(o)
                    Speed.Step = o
                    local st = STEP_SIZES[o] or 1
                    for k, v in pairs(Speed.Add) do Speed.Add[k] = math.clamp(math.floor(v / st + 0.5) * st, -100, 100) end
                    refreshPage()
                end },
            { t = "text", text = "Units move by 1, Stars by 2.5 (one star) and Half Stars by 1.25. Go negative if you ever want to slow down on purpose."},
        } }
    end
    local tbl = additive and Speed.Add or Speed.Mul
    local function group(title, key)
        local ctl = {}
        for _, p in ipairs({ { "All", "All Floors" }, { "Odd", "Odd Floors" }, { "Even", "Even Floors" } }) do
            local k = key .. p[1]
            ctl[#ctl + 1] = { t = "slider", text = p[2], min = -100, max = additive and 100 or 500,
                dec = additive and sdec or 0, step = additive and stepSize or 1,
                get = function() return tbl[k] end, set = function(v) tbl[k] = v end }
        end
        return { title = title .. (additive and " (Units Added)" or " (Multiplier %)"), controls = ctl }
    end
    secs[#secs + 1] = group("Walk Speed", "Walk")
    secs[#secs + 1] = group("Run Speed", "Run")
    return secs
end

local cfgState = { name = "", box = nil }
--#endregion page-movement
--#region page-configs
local function buildConfigsPage()
    if cfgState.name == "" and S.lastConfig ~= "" then cfgState.name = S.lastConfig end
    local function curName()
        local raw = cfgState.box and cfgState.box.Text or cfgState.name
        return sanitize(raw)
    end
    local function exists(n) return n ~= "" and isF(cfgPath(n)) end
    local secs = {}
    secs[1] = { title = "Save / Load", controls = {
        { t = "input", text = "Config Name", placeholder = "my config", get = function() return cfgState.name end,
            set = function(txt) cfgState.name = txt end, bind = function(tb) cfgState.box = tb end },
        { t = "buttons", items = {
            { label = "Save", style = "green", fn = function()
                local n = curName()
                if n == "" then return toast("Type a config name first.", "ng") end
                if not writefile then return toast("This executor can't write files.", "err") end
                if saveConfig(n) then
                    cfgState.name = n; S.lastConfig = n; dirty = true
                    refreshPage(); toast("Saved config '" .. n .. "'.", "ok")
                else toast("Couldn't write the config file.", "err") end
            end },
            { label = "Load", style = "blue", fn = function()
                local n = curName()
                if n == "" then return toast("Pick a config to load.", "ng") end
                if loadConfig(n) then
                    cfgState.name = n; S.lastConfig = n; dirty = true
                    refreshPage(); toast("Loaded config '" .. n .. "'.", "ok")
                else toast("Couldn't load '" .. n .. "'.", "err") end
            end },
            { label = "Delete", style = "red", confirm = true, fn = function()
                local n = curName()
                if not exists(n) then return toast("Pick an existing config to delete.", "ng") end
                dlF(cfgPath(n))
                if S.lastConfig == n then S.lastConfig = ""; dirty = true end
                cfgState.name = ""
                refreshPage(); toast("Deleted config '" .. n .. "'.", "ok")
            end },
        } },
        { t = "toggle", text = "Auto-Load Last Config", get = function() return S.autoload end,
            set = function(v) S.autoload = v; dirty = true end },
    } }
    local names = listConfigs()
    secs[2] = { title = "Your Configs (" .. #names .. ")", controls = {
        { t = "list", items = function() return names end, selected = function() return cfgState.name end,
            empty = "No configs yet. Type a name above and press Save.",
            onSelect = function(n) cfgState.name = n; refreshPage() end },
        { t = "buttons", items = { { label = "Refresh List", fn = function() refreshPage(); toast("Config list refreshed.", "info") end } } },
        { t = "text", text = "Configs live in workspace/" .. CFG_DIR .. ". They keep all of your settings and every on/off switch: ESP, Movement, World, Automation, Pursuer, Fun, Sound, the Customizer's options and your keybinds and on-screen buttons, so loading one can switch things on straight away. Sound setups, Customizer configs and saved Pursuers are their own libraries: a config remembers which one you were using. Look and feel (the Appearance tab) is saved on its own and is not part of a config."},
    } }
    return secs
end


--#endregion page-configs
--#region page-appearance
local buildAppearancePage
do
local STYLE_NAMES = { dandy = "Dandy's World", aero = "Frutiger Aero", xmb = "XMB / PlayStation", xp = "Windows XP Luna" }
local STYLE_BY_NAME = {}
for k, v in pairs(STYLE_NAMES) do STYLE_BY_NAME[v] = k end
local STYLE_BLURB = {
    dandy = "The default. Dark striped panels, thick black outlines, yellow headers and orange sliders, like the game's own menus.",
    aero = "Glossy glass, bubbles and soft gradients. Everything is lowercase, because it's relaxed like that.",
    xmb = "The PlayStation cross media bar: moving waves, Proper Case and PS3 sounds.",
    xp = "Windows XP Luna: blue title bar, task pane groups and the real XP sounds. Nostalgia included.",
}
local STYLE_DATA = {   -- skins that can be recolored
    dandy = { order = DANDY.order, presets = DANDY.presets, keys = DANDY.keys },
    aero  = { order = AERO_ORDER,  presets = AERO_PRESETS,  keys = AERO_KEYS },
    xmb   = { order = XMB_ORDER,   presets = XMB_PRESETS,   keys = XMB_KEYS },
    xp    = { order = XP_ORDER,    presets = XP_PRESETS,    keys = XP_KEYS },
}

local function applyPreset(name)
    local d = STYLE_DATA[S.style]
    local p = d and d.presets[name]
    if not p then return end
    S[S.style].colors = copyT(p); S[S.style].preset = name
    saveSettings(); buildGui()
end

local function resetAppearance()
    S.scale, S.fullscreen, S.orb, S.pos, S.keybind, S.startHidden = 1, false, true, nil, "RightShift", false
    S.sounds, S.sfxVol = true, 1
    S.win = defaultWin()
    S.dandy = { preset = "Dandy's World", colors = copyT(DANDY.presets["Dandy's World"]) }
    S.aero = { preset = "Default", colors = copyT(AERO_PRESETS["Default"]) }
    S.xmb = { preset = "Classic Blue", colors = copyT(XMB_PRESETS["Classic Blue"]), speed = 1, alpha = 0.8 }
    S.xp = { preset = "Luna Blue", colors = copyT(XP_PRESETS["Luna Blue"]) }
    UI.orbPos = nil
    saveSettings(); buildGui()
    toast("Appearance reset to default.", "ok")
end

function buildAppearancePage()
    local st = S.style
    local data = STYLE_DATA[st]
    local cur = S[st]
    local secs = {}

    local iface = {
        { t = "dropdown", text = "Style", get = function() return STYLE_NAMES[S.style] end,
            options = function() local o = {}; for i, k in ipairs(STYLE_LIST) do o[i] = STYLE_NAMES[k] end; return o end,
            set = function(o)
                local ns = STYLE_BY_NAME[o]
                if ns and ns ~= S.style then
                    S.style = ns; saveSettings(); buildGui()
                    if ns == "xmb" then uiWhenReady("gameboot") elseif ns == "xp" then uiWhenReady("boot") end
                end
            end },
        { t = "text", text = STYLE_BLURB[st] .. " Switching style restarts the GUI, and the last one you used loads next time."},
    }
    if data then
        iface[#iface + 1] = { t = "dropdown", text = "Preset", get = function() return cur.preset end,
            options = function() return data.order end, set = function(o) applyPreset(o) end }
    end
    secs[#secs + 1] = { title = "Interface", controls = iface }

    if data then
        local colorCtl = {}
        for _, k in ipairs(data.keys) do
            colorCtl[#colorCtl + 1] = { t = "color", text = k[2], rebuild = true, rainbow = false, palette = false,
                get = function() return cur.colors[k[1]] end,
                set = function(v) cur.colors[k[1]] = v; cur.preset = "Custom"; dirty = true end }
        end
        if st == "xmb" then
            colorCtl[#colorCtl + 1] = { t = "slider", text = "Wave Speed", min = 0, max = 3, dec = 1, get = function() return S.xmb.speed end,
                set = function(v) S.xmb.speed = v; dirty = true end }
            colorCtl[#colorCtl + 1] = { t = "slider", text = "Wave Opacity", min = 0, max = 1, dec = 2, get = function() return S.xmb.alpha end,
                set = function(v) S.xmb.alpha = v; dirty = true end }
        end
        secs[#secs + 1] = { title = "Colors", controls = colorCtl }
    end

    secs[#secs + 1] = { title = "Sounds", controls = {
        { t = "toggle", text = "UI Sounds", get = function() return S.sounds end,
            set = function(v) S.sounds = v; dirty = true end },
        { t = "slider", text = "UI Volume", min = 0, max = 1, dec = 2, get = function() return S.sfxVol end,
            set = function(v) S.sfxVol = v; dirty = true end },
        { t = "text", text = (st == "xmb" and "XMB brings the PS3 sound effects (downloaded once, then cached): OK, cancel, option menu, trophy, error and the boot sounds.")
            or (st == "xp" and "XP brings the real Windows sounds (downloaded once, then cached): menu click, start, restore, minimize, ding, error, critical stop and the startup jingle. Yes, that one.")
            or (st == "aero" and "Aero has glassy clicks, pings and bubbles.")
            or "Dandy's World uses the game's own UI sounds: click, hover, toggle, tick, open and close."},
    } }

    local win = {
        { t = "keybind", text = "Show / Hide Key", get = function() return S.keybind end,
            set = function(k)
                S.keybind = k; dirty = true
                toast("Keybind set to " .. k .. ".", "ok")
            end },
    }
    do
        win[#win + 1] = { t = "slider", text = "UI Scale", min = 0.6, max = 1.6, dec = 2, get = function() return S.scale end,
            set = function(v) S.scale = v; applyLayout(); dirty = true end }
        win[#win + 1] = { t = "toggle", text = "Fullscreen", get = function() return S.fullscreen end,
            set = function(v) S.fullscreen = v; applyLayout(); dirty = true end }
    end
    win[#win + 1] = { t = "toggle", text = "Show Orb When Hidden", get = function() return S.orb end,
        set = function(v)
            S.orb = v; dirty = true
            if Orb then Orb.Visible = (not UI.visible) and v end
            if not v then toast("Orb hidden. Press " .. S.keybind .. " to open the hub.", "info") end
        end }
    win[#win + 1] = { t = "toggle", text = "Start Hidden", get = function() return S.startHidden end,
        set = function(v) S.startHidden = v; dirty = true; if v then toast("The hub will start hidden. Press " .. S.keybind .. " to open it.", "info") end end }
    do win[#win + 1] = { t = "text", text = "Drag the top bar to move the window and the bottom-right grip to resize it. That's the whole tutorial."} end
    win[#win + 1] = { t = "buttons", items = {
        { label = "Hide GUI", fn = function() UI.setVisible(false) end },
        { label = "Destroy GUI", style = "red", confirm = true, fn = function() Destroy() end },
    } }
    secs[#secs + 1] = { title = "Window", controls = win }

    secs[#secs + 1] = { title = "Reset", controls = {
        { t = "text", text = "Resets window size and position, scale, colors, presets, sounds and the keybind for every style. Your current style stays put."},
        { t = "buttons", items = { { label = "Reset Appearance to Default", style = "red", confirm = true, fn = resetAppearance } } },
    } }
    return secs
end

end
--#endregion page-appearance
--#region page-world
local worldNames = ""     -- what is typed in the World tab's "Extra Names" box
-- game GUI tweaks (things drawn on your screen, rather than things in the map)
local function buildScreenPage()
    return {
        { title = "Ichor Splats", controls = {
            { t = "text", text = "Stepping in an Ichor puddle splats ink across your whole screen. This hides those splats. Turn it off and they come back."},
            { t = "toggle", text = "Hide Ichor Splats", get = function() return SP.hideIchorOn() end,
                set = function(v) SP.setHideIchor(v); toast(v and "Ichor splats hidden." or "Ichor splats back.", "info") end },
        } },
    }
end

local function buildWorldPage()
    return {
        { title = "Noclip", controls = {
            { t = "text", text = "Noclip changes the map, not you. It turns off collision for everything named NoClip, NoClip_Collider, InvisBlock, InvisWall and CylinderCollider, and also for the DoorHitbox, the DoorVisible and the whole ElevatorDoor model of the fake elevator in Labs (the real elevator is left alone), and optionally for the parts inside every Walls folder, so walls, columns and window frames stop being a problem. Floors stay solid so you don't fall into the void. New rooms are handled automatically, everything goes back to normal when you turn it off, and it starts off unless a config you load turns it on."},
            { t = "toggle", text = "Noclip", get = function() return SP.noclipOn() end,
                set = function(v) SP.setNoclip(v); toast(v and "Noclip on." or "Noclip off, collisions restored.", "info") end },
            { t = "toggle", text = "Include Walls Folders (Keeps Floors)", get = function() return SP.noclipWalls() end,
                set = function(v) SP.setNoclipWalls(v) end },
            { t = "input", text = "Extra Names (Comma Separated)", placeholder = "e.g. Wall, WindowFrame", get = function() return worldNames end,
                set = function(txt, enter) worldNames = tostring(txt or ""); if enter then SP.setNoclipNames(worldNames) end end },
            { t = "text", text = "Extra Names turns off collision for any part, model or folder with exactly that name, floors included, so think twice before typing something like Floor. Press Enter in the box to apply it."},
            { t = "readout", text = "Parts Affected", get = function() return tostring(SP.noclipCount()) end },
        } },
        { title = "Fullbright", controls = {
            { t = "text", text = "Lights up the whole map: the ambient light is raised, shadows are switched off and the fog is pushed so far back you never see it. The room's own lights are left alone, so everything simply becomes easy to see. Turning it off puts back whatever the game had."},
            { t = "toggle", text = "Fullbright", get = function() return SP.fullbrightOn() end,
                set = function(v) SP.setFullbright(v); toast(v and "Fullbright on." or "Fullbright off.", "info") end },
            { t = "slider", text = "Fullbright Brightness", min = 0, max = 100, dec = 0, step = 1,
                get = function() return SP.fullbrightLevel() end, set = function(v) SP.setFullbrightLevel(v) end },
        } },
        { title = "Game Info", controls = {
            { t = "text", text = "Live info from the Dandy's World API Library. It only has anything to say inside a run."},
            { t = "readout", text = "Floor", get = apiField(function(a) return a.GetGameInfo("floor") end) },
            { t = "readout", text = "Players Alive", get = apiField(function(a) return a.GetPlayersAlive("number") end) },
            { t = "readout", text = "Machines", get = apiField(function(a)
                local i = a.GetGameInfo(); return i.machinesCompleted .. " / " .. i.machinesRequired end) },
            { t = "readout", text = "Twisteds On Floor", get = apiField(function(a) return a.GetTwistedsOnFloor("number") end) },
            { t = "readout", text = "Panic Mode", get = apiField(function(a) return a.GetGameInfo("panicMode") and "On" or "Off" end) },
            { t = "readout", text = "Blackout", get = apiField(function(a) return a.GetGameInfo("blackout") and "On" or "Off" end) },
        } },
    }
end

--#endregion page-world
--#region page-automation
local function buildAutomationPage()
    local smax = math.max(150, math.ceil(Stam.Peak / 5) * 5)      -- Auto Run slider maximum: the highest stamina seen so far
    local function fracInput(label, key)       -- a box you type a fraction into: 3/4, 1/2, 50% or 0.75
        return { t = "input", text = label, placeholder = "e.g. 3/4, 1/2, 50%", get = function() return Stam[key] end,
            set = function(txt, enter)
                if stamParseFraction(txt) then Stam[key] = tostring(txt)
                elseif enter then toast("Type a fraction like 3/4 or 1/8, a percent like 50%, or a decimal like 0.75.", "ng") end
            end }
    end
    local function autoRunControls()           -- built step by step: sliders show in "Number" mode, a fraction box in "Fraction" mode
        local c = {}
        c[#c + 1] = { t = "text", text = "Holds sprint for you while you work a treadmill machine. It stops running when your stamina drops to the first setting, rests, and starts again when stamina climbs back to the second. Each can be a stamina number or a fraction of your max that you type in yourself (1/2, 3/4, 1/8, 50%, 0.75...). The limits still count with Infinite Stamina on."}
        c[#c + 1] = { t = "toggle", text = "Auto Run On Treadmill Machines", get = function() return Stam.AutoRun end,
            set = function(v)
                Stam.AutoRun = v
                Auto.Status = v and "Auto Run on" or "Auto Run off"
                if v then toast("Auto Run is on. It starts as soon as you begin a treadmill machine.", "info") end
            end }
        c[#c + 1] = { t = "dropdown", text = "Stop Running At", get = function() return Stam.StopMode end,
            options = function() return STAM_MODES end, set = function(o) Stam.StopMode = o; refreshPage() end }
        if Stam.StopMode == "Number" then
            c[#c + 1] = { t = "slider", text = "Stop Running At (Stamina)", min = 0, max = smax, dec = 0, step = 1,
                get = function() return math.min(Stam.RunStop, smax) end, set = function(v) Stam.RunStop = v end }
        else
            c[#c + 1] = fracInput("Stop At (Fraction Of Max)", "StopFrac")
        end
        c[#c + 1] = { t = "dropdown", text = "Start Running Again At", get = function() return Stam.ResumeMode end,
            options = function() return STAM_MODES end, set = function(o) Stam.ResumeMode = o; refreshPage() end }
        if Stam.ResumeMode == "Number" then
            c[#c + 1] = { t = "slider", text = "Start Running Again At (Stamina)", min = 0, max = smax, dec = 0, step = 1,
                get = function() return math.min(Stam.RunResume, smax) end, set = function(v) Stam.RunResume = v end }
        else
            c[#c + 1] = fracInput("Start Again At (Fraction Of Max)", "ResumeFrac")
        end
        c[#c + 1] = { t = "readout", text = "Stops / Starts Again At", get = function()
            local l = SP.last
            local mx = l and l.ok and tonumber(l.stamMax) or Stam.Peak
            local a = stamThreshold(Stam.StopMode, Stam.RunStop, mx, Stam.StopFrac)
            local b = stamThreshold(Stam.ResumeMode, Stam.RunResume, mx, Stam.ResumeFrac)
            if b <= a then b = a + 1 end
            return string.format("%d  /  %d  (max %d)", math.floor(a + 0.5), math.floor(b + 0.5), math.floor(mx + 0.5))
        end }
        c[#c + 1] = { t = "readout", text = "Highest Stamina Seen", get = function() return Stam.Peak > 0 and tostring(math.floor(Stam.Peak + 0.5)) or "-" end }
        c[#c + 1] = { t = "readout", text = "Auto Run State", get = function() local l = SP.last; return l and l.ok and tostring(l.autoRun or "off") or "-" end }
        return c
    end
    local function tog(text, key, extra)
        return { t = "toggle", text = text, get = function() return Auto[key] end,
            set = function(v) Auto[key] = v; Auto.Status = v and (text .. " on") or (text .. " off"); if extra then extra(v) end end }
    end
    return {
        { title = "Auto Skill Checks", controls = {
            { t = "text", text = "Each toggle taps the skill check for you at the right moment. The green or yellow zone is found from the live on-screen zones, so tiny skill check sizes are no problem. Turn them on before you start a machine."},
            tog("Default Machines", "Default"),
            tog("Circle Machines", "Circle"),
            tog("Treadmill Machines", "Treadmill"),
            tog("Swimmy Barnaby Machines", "Swimmy"),
            { t = "toggle", text = "Snap To Green/Yellow", get = function() return Auto.Snap end, set = function(v) Auto.Snap = v end },
            { t = "text", text = "Snap To Green/Yellow nudges the marker (the green calibration area on default machines) or the ring (the yellow zone on circle machines) onto the exact middle of that zone right before tapping. Turn it off to only hit when the marker really lands there (it can miss tiny zones at low FPS, so your call)."},
            { t = "slider", text = "Treadmill Taps Per Second", min = 0, max = 20, dec = 0, step = 1,
                get = function() return Auto.TapRate end, set = function(v) Auto.TapRate = v end },
        } },
        { title = "Swimmy Barnaby", controls = {
            { t = "text", text = "With Swimmy Barnaby Machines on, Barnaby flies dead level and can't hit the seaweed. Coins count as this machine's gold skill checks."},
            { t = "toggle", text = "Hide Seaweed", get = function() return Auto.SwimmyHide end, set = function(v) Auto.SwimmyHide = v end },
            { t = "toggle", text = "Hide Coins", get = function() return Auto.SwimmyHideCoins end, set = function(v) Auto.SwimmyHideCoins = v end },
            { t = "toggle", text = "Pull Coins Into Barnaby", get = function() return Auto.SwimmyCoins end, set = function(v) Auto.SwimmyCoins = v end },
            { t = "toggle", text = "Instant Coins", get = function() return Auto.SwimmyInstantCoins end, set = function(v) Auto.SwimmyInstantCoins = v end },
            { t = "toggle", text = "Coin For Every Seaweed", get = function() return Auto.SwimmyCoinEvery end, set = function(v) Auto.SwimmyCoinEvery = v end },
            { t = "toggle", text = "Continuous Coins", get = function() return Auto.SwimmyRapid end, set = function(v) Auto.SwimmyRapid = v end },
            { t = "slider", text = "Continuous Coins Per Second", min = 1, max = 30, dec = 0, step = 1,
                get = function() return Auto.SwimmyRapidRate end, set = function(v) Auto.SwimmyRapidRate = v end },
            { t = "text", text = "Pull Coins brings each coin to Barnaby as it approaches. Instant Coins grabs each one the moment it spawns. Coin For Every Seaweed gives you a coin for every seaweed gap Barnaby passes, even the ones that spawned no coin. Continuous Coins keeps collecting non-stop at the rate below. The server may ignore coins that come too fast, so if your progress stops going up, lower the rate. Hiding happens before the game shows an obstacle, so nothing flashes on screen."},
        } },
        { title = "Auto Run (Treadmill Machines)", controls = autoRunControls() },
        { title = "Instant Calibration Success", controls = {
            { t = "text", text = "Answers the server's calibration check instantly as a perfect hit (supercomplete) and skips the minigame entirely. The three Affect toggles choose which machines it answers: turn one off to play that kind of machine yourself while the others stay instant."},
            tog("Instant Calibration Success", "Instant"),
            { t = "toggle", text = "Great Job Text And Sounds", get = function() return Auto.Feedback end, set = function(v) Auto.Feedback = v end },
            { t = "toggle", text = "Affect Default Machines", get = function() return Auto.InstantKinds.default end, set = function(v) Auto.InstantKinds.default = v end },
            { t = "toggle", text = "Affect Circle Machines", get = function() return Auto.InstantKinds.circle end, set = function(v) Auto.InstantKinds.circle = v end },
            { t = "toggle", text = "Affect Treadmill Machines", get = function() return Auto.InstantKinds.treadmill end, set = function(v) Auto.InstantKinds.treadmill = v end },
            { t = "slider", text = "Response Delay (Seconds)", min = 0, max = 2, dec = 2, step = 0.05,
                get = function() return Auto.InstantDelay end, set = function(v) Auto.InstantDelay = v end },
        } },
        { title = "Status", controls = {
            { t = "readout", text = "Last Action", get = function() return Auto.Status end },
        } },
    }
end

Features.world = {
    serialize = function() return { Walls = SP.noclipWalls(), Names = worldNames, FullbrightLevel = SP.fullbrightLevel() } end,        -- the Noclip and Fullbright switches are saved by the "switches" entry
    apply = function(data)
        if type(data) ~= "table" then return end
        if type(data.Walls) == "boolean" then SP.setNoclipWalls(data.Walls) end
        if type(data.Names) == "string" then worldNames = data.Names; SP.setNoclipNames(worldNames) end
        if type(data.FullbrightLevel) == "number" then SP.setFullbrightLevel(data.FullbrightLevel) end
    end,
}

Features.automation = {
    serialize = function() return { Snap = Auto.Snap, TapRate = Auto.TapRate, InstantDelay = Auto.InstantDelay, Feedback = Auto.Feedback, InstantKinds = { default = Auto.InstantKinds.default, circle = Auto.InstantKinds.circle, treadmill = Auto.InstantKinds.treadmill }, SwimmyHide = Auto.SwimmyHide, SwimmyCoins = Auto.SwimmyCoins, SwimmyHideCoins = Auto.SwimmyHideCoins, SwimmyInstantCoins = Auto.SwimmyInstantCoins, SwimmyCoinEvery = Auto.SwimmyCoinEvery, SwimmyRapid = Auto.SwimmyRapid, SwimmyRapidRate = Auto.SwimmyRapidRate } end,
    apply = function(data)               -- the auto skill check switches are saved by the "switches" entry
        if type(data) ~= "table" then return end
        if type(data.Snap) == "boolean" then Auto.Snap = data.Snap end
        if type(data.InstantKinds) == "table" then
            for _, k in ipairs({ "default", "circle", "treadmill" }) do
                if type(data.InstantKinds[k]) == "boolean" then Auto.InstantKinds[k] = data.InstantKinds[k] end
            end
        end
        for _, k in ipairs({ "Feedback", "SwimmyHide", "SwimmyHideCoins", "SwimmyCoins", "SwimmyInstantCoins", "SwimmyCoinEvery", "SwimmyRapid" }) do
            if type(data[k]) == "boolean" then Auto[k] = data[k] end
        end
        Auto.TapRate = math.clamp(tonumber(data.TapRate) or Auto.TapRate, 0, 20)
        Auto.InstantDelay = math.clamp(tonumber(data.InstantDelay) or Auto.InstantDelay, 0, 2)
        Auto.SwimmyRapidRate = math.clamp(tonumber(data.SwimmyRapidRate) or Auto.SwimmyRapidRate, 1, 30)
    end,
}

--#endregion page-automation
--#region page-fun
----------------------------------------------------------------------
-- PURSUER PAGE: live preview + all the settings (its own tab)
-- No new top-level locals: the builder hangs off `builders`, the sections off Fun.Pur.
----------------------------------------------------------------------
Fun.Pur.say = function(m, k) toast(m, k) end

-- live preview: the picture at its real proportions next to a 2 x 5 stud "you", standing on a floor line
builders.pursuerpreview = function(parent, c, order)
    local Pur = Fun.Pur
    local PC = Pur.Cfg
    local kind = T.kind
    local row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 250), LayoutOrder = order }, parent)
    local x = padX()
    local box = New("Frame", { Position = UDim2.fromOffset(x, 4), Size = UDim2.new(1, -(x + 8), 1, -8), BorderSizePixel = 0, ClipsDescendants = true,
        BackgroundColor3 = (kind == "xmb" and C(10, 24, 62)) or (kind == "xp" and C(236, 233, 216)) or (T.dark and (T.kind == "dandy" and C(30, 30, 34) or C(18, 34, 64)) or C(215, 240, 255)) }, row)
    corner(box, 8); stroke(box, T.accent, 1, 0.3)
    local floorFrac = 0.84
    New("Frame", { BackgroundColor3 = T.text, BackgroundTransparency = 0.65, BorderSizePixel = 0, Position = UDim2.fromScale(0, floorFrac), Size = UDim2.new(1, 0, 0, 2) }, box)
    local you = New("Frame", { AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = T.dim, BackgroundTransparency = 0.5, BorderSizePixel = 0 }, box)
    corner(you, 4)
    New("TextLabel", { BackgroundTransparency = 1, Text = "you", Font = T.F.semi, TextSize = 13, TextColor3 = T.text, Size = UDim2.fromScale(1, 1) }, you)
    local holder = New("Frame", { AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1 }, box)
    local sp = Pur.buildSprite(holder)
    local msg = New("TextLabel", { BackgroundTransparency = 1, Font = T.F.semi, TextSize = 13, TextColor3 = T.dim, TextXAlignment = AL, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 34) }, box)
    local con
    con = RunService.RenderStepped:Connect(function()
        if not alive or not box:IsDescendantOf(game) then con:Disconnect(); return end
        if not UI.visible then return end
        pcall(function()
        local W, H = box.AbsoluteSize.X, box.AbsoluteSize.Y
        if W < 10 or H < 10 then return end
        local w, h = PC.Width, PC.Height
        local floorPx = H * floorFrac
        local top = PC.FeetOnGround and h or (PC.Hover + h / 2)
        local pps = math.max(2, math.min((floorPx - 30) / math.max(top, 5), (W - 24) / (w + 4.5)))
        local youW = 2 * pps
        local cx = 12 + youW / 2
        you.Position = UDim2.fromOffset(cx, floorPx); you.Size = UDim2.fromOffset(youW, 5 * pps)
        local px = cx + youW / 2 + 1.2 * pps + (w * pps) / 2
        holder.Position = UDim2.fromOffset(px, floorPx - (PC.FeetOnGround and 0 or (PC.Hover - h / 2) * pps))
        holder.Size = UDim2.fromOffset(w * pps, h * pps)
        Pur.paintSprite(sp, os.clock(), 1)
        local st = Pur.imageState()
        msg.Text = Pur.imageStatus()
        msg.TextColor3 = st.err and errCol() or T.dim
        end)
    end)
end

function Fun.Pur.sections()
    local Pur = Fun.Pur
    local PC = Pur.Cfg
    local L = Pur.LISTS
    local function tg(key, text) return { t = "toggle", text = text, get = function() return PC[key] end, set = function(v) PC[key] = v end } end
    local function tgR(key, text) return { t = "toggle", text = text, get = function() return PC[key] end, set = function(v) PC[key] = v; refreshPage() end } end
    local function dd(key, text) return { t = "dropdown", text = text, get = function() return PC[key] end, options = function() return L[key] end, set = function(o) Pur.set(key, o); refreshPage() end } end
    local INT = { Cols = true, Rows = true, FrameCount = true }      -- whole numbers only
    local function sl(key, text, min, max, dec, step)
        local get, set = function() return PC[key] end, function(v) Pur.set(key, v) end
        if INT[key] then return { t = "slider", text = text, min = min, max = max, dec = 0, step = 1, get = get, set = set } end
        local r = Pur.RANGES[key]
        -- dragging uses a finer step than before, and typing in the box takes any value (3 decimals) up to the real limit
        return { t = "slider", text = text, min = min, max = max, dec = 3, step = step and math.max(step / 5, 0.01) or nil,
            free = r and { min = r[1], max = r[2] } or true, get = get, set = set }
    end
    local function inp(key, text, ph) return { t = "input", text = text, placeholder = ph, get = function() return PC[key] end, set = function(txt) Pur.set(key, txt) end } end
    local function pick(kind, key, text, append)
        return { t = "dropdown", text = text, get = function() return "Choose A File..." end,
            options = function() local l = Pur.listFiles(kind); if #l == 0 then return { "(no files yet)" } end; return l end,
            set = function(o)
                if o:sub(1, 1) == "(" then return end
                if append and PC[key] ~= "" then Pur.set(key, PC[key] .. " | " .. o) else Pur.set(key, o) end
                refreshPage()
            end }
    end

    -- 1. main ---------------------------------------------------------
    local main = {
        { t = "text", text = "Your own chaser, like Pizzaface, a Nextbot or Dark Esau. You pick the picture and how it behaves. It's a flat picture on an invisible part that only exists on your screen: it kills you by touching you, appears where you stand and flashes before it starts, never goes in the elevator (it fades when you do), and walls hide it. It starts off every time. Put picture and sound files in TonyScriptPalace/Pursuer/Images and /Sounds, or use a link or a Roblox asset number."},
        { t = "toggle", text = "Pursuer", get = function() return PC.Enabled end,
            set = function(v) PC.Enabled = v; Pur.E.errShown = false; if not v then Pur.despawn(true) end; toast(v and "Pursuer armed. It spawns the way you set below." or "Pursuer off.", "info") end },
        { t = "buttons", items = {
            { label = "Spawn Now", fn = function()
                if not PC.Enabled then PC.Enabled = true; refreshPage() end
                if not Pur.spawn(true) then toast("No character to spawn on.", "err") end
            end },
            { label = "Despawn", fn = function() Pur.despawn(false) end },
        } },
        { t = "toggle", text = "Kills You On Touch (Turn Off To Test)", get = function() return PC.Kill end, set = function(v) PC.Kill = v end },
        sl("HitScale", "Touch Size (x)", 0.2, 3, 2, 0.05),
        { t = "text", text = "How close it has to get to kill you. 1 is about the width of the picture. It can't hurt you while it's still flashing in, so no cheap deaths."},
        { t = "readout", text = "Status", get = function() return Pur.status() end },
        { t = "readout", text = "Distance From You", get = function() return Pur.distance() end },
        { t = "readout", text = "Its Speed Now", get = function() return string.format("%.1f studs/s", Pur.currentSpeed()) end },
        { t = "readout", text = "Your Walk Speed", get = function() local ch = LP.Character; local h = ch and ch:FindFirstChildOfClass("Humanoid"); return h and string.format("%.1f studs/s", h.WalkSpeed) or "-" end },
        { t = "readout", text = "Floor Tracker", get = function() return Pur.floorText() end },
    }

    -- 2. look ---------------------------------------------------------
    local look = {
        { t = "pursuerpreview" },
        { t = "text", text = "The preview shows the picture at its real proportions next to a 2 x 5 stud toon. In the real thing, walls hide it and it flashes while it spawns."},
        dd("ImageMode", "Picture Type"),
    }
    local mode = PC.ImageMode
    if mode == "Frame List" then
        look[#look + 1] = inp("FrameList", "Frames (Separate With | )", "file1.png | file2.png | https://...")
        look[#look + 1] = pick("img", "FrameList", "Add A File To The List", true)
        look[#look + 1] = sl("FPS", "Frames Per Second", 1, 30, 0, 1)
        look[#look + 1] = { t = "text", text = "Each frame is its own picture, shown in order and looping. Frames can be files, links or Roblox asset numbers, mixed however you like."}
    else
        look[#look + 1] = inp("ImageSrc", "Picture (File, Link Or Asset Number)", "cat.png or https://... or 123456")
        look[#look + 1] = pick("img", "ImageSrc", "Pick A File")
        if mode == "Sprite Sheet" then
            look[#look + 1] = sl("Cols", "Columns", 1, 16, 0, 1)
            look[#look + 1] = sl("Rows", "Rows", 1, 16, 0, 1)
            look[#look + 1] = sl("FrameCount", "Number Of Frames", 1, 128, 0, 1)
            look[#look + 1] = sl("FPS", "Frames Per Second", 1, 30, 0, 1)
            look[#look + 1] = { t = "text", text = "A sprite sheet is one picture holding a grid of frames, read left to right, top to bottom. Roblox can't play GIFs, so convert yours (ezgif.com has a GIF to sprite sheet tool), upload the sheet and set the grid here. Number Of Frames is for sheets whose last row isn't full."}
        else
            look[#look + 1] = { t = "text", text = "Roblox doesn't do GIFs. For an animated picture, pick Sprite Sheet or Frame List above."}
        end
    end
    look[#look + 1] = { t = "buttons", items = { { label = "Reload Picture", fn = function() Pur.reload(); toast("Reloading the picture...", "info") end } } }
    look[#look + 1] = dd("Billboard", "Facing")
    look[#look + 1] = { t = "text", text = "Y Only turns to face you but stays upright (like most Nextbots). Full always squares up to your camera, even if you look down at it. Off keeps it flat and turns it to face where it's going; both sides show the picture."}
    look[#look + 1] = tg("Pixelated", "Pixelated (Crisp Pixels, No Smoothing)")
    look[#look + 1] = sl("Width", "Width (Studs)", 0.5, 30, 1, 0.5)
    look[#look + 1] = sl("Height", "Height (Studs)", 0.5, 30, 1, 0.5)
    look[#look + 1] = tgR("FeetOnGround", "Feet On The Ground")
    if not PC.FeetOnGround then look[#look + 1] = sl("Hover", "Floating Height (Studs Up To Its Middle)", 0, 20, 1, 0.5) end
    look[#look + 1] = sl("Opacity", "Opacity", 0.05, 1, 2, 0.05)
    look[#look + 1] = inp("Tint", "Tint (Hex, ffffff = None)", "#ffffff")
    look[#look + 1] = dd("Emissive", "Glows (Ignores Lighting)")
    look[#look + 1] = { t = "text", text = "Pictures get lit by the room, so they go dark when the lights do. Glows keeps it fully bright: During Blackouts only when the lights are out (the game's own Twisteds do the same), Always, or Off."}
    look[#look + 1] = tg("GlowLight", "Also Lights Up Its Surroundings When It Glows")

    -- 3. movement -----------------------------------------------------
    local move = {
        dd("WallMode", "Walls"),
        { t = "text", text = "Solid: walls and furniture block it, so it uses Roblox's pathfinding to get around (like the Twisteds) and slides along walls. Through Walls: it flies straight at you through everything. Either way it never falls, since a ray under it finds the floor, so it climbs stairs and ramps just fine."},
        dd("Vertical", "Up And Down"),
        { t = "text", text = "Follow The Floor: walks on the ground like a Twisted. Match My Height: floats at your height and follows you up fast. Fly Up And Down: rises and falls toward you at a speed you pick, so it can swoop, and a dash lunges straight at you, up or down."},
        sl("Speed", "Speed (Studs Per Second)", 1, 60, 1, 0.5),
        dd("SpeedMode", "Speed Behavior"),
    }
    if PC.Vertical == "Fly Up And Down" then
        table.insert(move, 5, sl("VertSpeed", "Up And Down Speed (Studs Per Second)", 1, 60, 1, 0.5))
        table.insert(move, 6, sl("FlyOffset", "Flies This Far Above You (Negative = Below)", -10, 20, 1, 0.5))
    end
    local sm = PC.SpeedMode
    if sm ~= "Constant" then
        move[#move + 1] = sl("NearDist", "Close Distance (Studs)", 0, 100, 0, 1)
        move[#move + 1] = sl("FarDist", "Far Distance (Studs)", 10, 300, 0, 5)
        if sm == "Faster When Far" or sm == "Faster Far, Slower Close" then move[#move + 1] = sl("FarMult", "Speed When Far (x)", 1, 5, 2, 0.1) end
        if sm ~= "Faster When Far" then move[#move + 1] = sl("CloseMult", "Speed When Close (x)", 0, 1, 2, 0.05) end
        if sm == "Slower When Close, Stops Near" then move[#move + 1] = sl("StopDist", "Stops Moving Within (Studs)", 0, 40, 0, 1) end
        move[#move + 1] = { t = "text", text = "Closer than Close Distance it moves at its closest-up speed, farther than Far Distance at its farthest speed, and it blends smoothly in between. Stops Near makes it halt completely inside the stop distance and start again when you walk away."}
    end
    move[#move + 1] = dd("PanicMode", "Speed In Panic Mode")
    if PC.PanicMode == "Increase By Percent" then move[#move + 1] = sl("PanicPercent", "Faster By (%)", 0, 200, 0, 1)
    elseif PC.PanicMode == "Increase By Flat Amount" then move[#move + 1] = sl("PanicFlat", "Faster By (Studs Per Second)", 0, 60, 1, 0.5)
    elseif PC.PanicMode == "Set Speed To" then move[#move + 1] = sl("PanicSet", "Panic Speed (Studs Per Second)", 1, 80, 1, 0.5) end
    if PC.PanicMode ~= "Off" then
        move[#move + 1] = dd("SuppressMode", "Suppression Card Lowers The Boost")
        if PC.SuppressMode == "Lower By Percent" then move[#move + 1] = sl("SuppressPercent", "Lowers It By (% Of The Boost)", 0, 100, 0, 1)
        elseif PC.SuppressMode == "Lower By Flat Amount" then move[#move + 1] = sl("SuppressFlat", "Lowers It By (Same Unit As The Boost)", 0, 60, 1, 0.5) end
    end
    move[#move + 1] = { t = "text", text = "Panic mode only. Percent and flat boosts apply to the dash too, and Set Speed To leaves the dash alone. Suppression is read from the game: with Lower By Percent at 20 the boost shrinks by a fifth (25% becomes 20%, which is what the game does), and Lower By Flat Amount takes that many off instead (percentage points, studs per second, or off the panic speed itself)." }
    move[#move + 1] = tg("PauseDecode", "Pauses While You Extract From A Machine")
    move[#move + 1] = dd("DecodeSlow", "Speed While You Extract")
    if PC.DecodeSlow == "Slow By Flat Amount" then move[#move + 1] = sl("DecodeFlat", "Slower By (Studs Per Second)", 0, 60, 1, 0.5)
    elseif PC.DecodeSlow == "Slow By Percent" then move[#move + 1] = sl("DecodePercent", "Slower By (%)", 0, 100, 0, 1)
    elseif PC.DecodeSlow == "Set Speed To" then move[#move + 1] = sl("DecodeSet", "Speed While Extracting (Studs Per Second)", 0, 60, 1, 0.5) end
    move[#move + 1] = { t = "text", text = "Instead of pausing, it can keep chasing more slowly while you extract: slower by a flat number of studs per second, slower by a percentage, or locked to one exact speed. It applies to its dash too. Picking one of these replaces the pause above." }
    move[#move + 1] = { t = "text", text = "Extracting is what the game calls \"decoding\". Paused means it stands still and its dash timer waits too. The Suppression card is read from the game, so the boost drops to 20% once it's been voted."}

    -- 4. dash ---------------------------------------------------------
    local dash = {
        tgR("Dash", "Dash (Dark Esau Style)"),
        { t = "text", text = "Every so often it stops, shakes, then lunges in a straight line at where you were. It keeps going the full distance even if you dodge, and stops at a wall unless it's going Through Walls."},
    }
    if PC.Dash then
        dash[#dash + 1] = sl("DashDistance", "How Far (Studs)", 10, 150, 0, 5)
        dash[#dash + 1] = sl("DashSpeed", "Dash Speed (Studs Per Second)", 20, 200, 0, 5)
        dash[#dash + 1] = sl("DashWindup", "Warning Shake (Seconds)", 0, 3, 2, 0.05)
        dash[#dash + 1] = sl("DashCdMin", "Wait Between Dashes, At Least (Seconds)", 1, 60, 1, 0.5)
        dash[#dash + 1] = sl("DashCdMax", "Wait Between Dashes, At Most (Seconds)", 1, 90, 1, 0.5)
        dash[#dash + 1] = sl("DashRange", "Only Dashes When Closer Than (Studs)", 10, 200, 0, 5)
        dash[#dash + 1] = tg("DashNeedsSight", "Only Dashes When It Can See You")
    end

    -- 5. spawning -----------------------------------------------------
    local spawn = {
        dd("Trigger", "When It Spawns"),
        { t = "text", text = "Right Away: as soon as you're out on a floor. When The Elevator Opens: it appears as you step out and starts chasing once the elevator closes. After A Timer: it shows up when you've taken too long, like Pizza Time. Either way it appears on top of you and flashes harmlessly first, and it fades when you get back in the elevator until the next floor."},
        sl("FlashTime", "Flash Time Before It Chases (Seconds)", 0, 10, 1, 0.5),
        sl("FlashRate", "Flashes Per Second", 1, 15, 0, 1),
    }
    if PC.Trigger == "After A Timer" then
        spawn[#spawn + 1] = sl("Timer", "Time Allowed On A Floor (Seconds)", 10, 900, 0, 5)
        spawn[#spawn + 1] = tg("TimerPauseDecode", "Timer Pauses While You Extract")
        spawn[#spawn + 1] = tg("TimerHud", "Show The Timer On Screen")
        spawn[#spawn + 1] = { t = "readout", text = "Time Left", get = function() return Pur.timerText() end }
        spawn[#spawn + 1] = { t = "text", text = "The timer starts once you're out and the elevator has closed. It pauses while you're in the elevator and (if ticked) while you extract."}
    end

    -- 5b. chase alert -------------------------------------------------
    local alert = {
        tgR("SpotSound", "Twisted Spotting Sound When It Starts Chasing"),
    }
    if PC.SpotSound then alert[#alert + 1] = dd("SpotVariant", "Which Spotting Sound") end
    alert[#alert + 1] = tg("EyeIcon", "Eye Icon And Chase Counter While It Chases")
    alert[#alert + 1] = { t = "text", text = "These use the game's own sound and eye icon, so it looks and sounds exactly like a Twisted spotting you. The sound plays the moment it stops flashing and starts chasing. The icon works by adding one to your chase count while it chases: if real Twisteds are chasing you too, the counter goes up by one, then back down when it stops. Anything else that reads your chase count (the game's chase effects, the Twisted count in the Skill Checks settings) will treat it as a chasing Twisted too. The count only changes on your screen, never for the server."}

    -- 6. sounds -------------------------------------------------------
    local snd = {
        tgR("Music", "It Plays Music"),
    }
    if PC.Music then
        snd[#snd + 1] = inp("MusicSrc", "Music (File, Link Or Asset Number)", "theme.mp3 or https://... or 123456")
        snd[#snd + 1] = pick("snd", "MusicSrc", "Pick A File")
        snd[#snd + 1] = sl("MusicVol", "Music Volume", 0, 2, 2, 0.05)
        snd[#snd + 1] = tgR("Music3D", "Music Gets Louder As It Gets Closer")
        if PC.Music3D then snd[#snd + 1] = sl("MusicRange", "Music Can Be Heard From (Studs)", 20, 500, 0, 10) end
    end
    snd[#snd + 1] = tgR("SpawnSound", "Sound When It Spawns")
    if PC.SpawnSound then
        snd[#snd + 1] = inp("SpawnSrc", "Spawn Sound", "scare.mp3 or https://... or 123456")
        snd[#snd + 1] = pick("snd", "SpawnSrc", "Pick A File")
        snd[#snd + 1] = sl("SpawnVol", "Spawn Sound Volume", 0, 2, 2, 0.05)
    end
    snd[#snd + 1] = tgR("DeathSound", "Sound After It Kills You")
    if PC.DeathSound then
        snd[#snd + 1] = inp("DeathSrc", "Death Sound", "gotcha.mp3 or https://... or 123456")
        snd[#snd + 1] = pick("snd", "DeathSrc", "Pick A File")
        snd[#snd + 1] = sl("DeathVol", "Death Sound Volume", 0, 2, 2, 0.05)
    end
    snd[#snd + 1] = { t = "text", text = "Sounds can be files in TonyScriptPalace/Pursuer/Sounds, direct links (mp3, ogg or wav; Google Drive, Dropbox and GitHub links get converted) or Roblox asset numbers. The music stops when it kills you."}

    -- 7. afterimages --------------------------------------------------
    local after = {
        tgR("After", "Afterimages"),
        { t = "text", text = "Leaves fading copies of itself behind as it moves. Purely for drama."},
    }
    if PC.After then
        after[#after + 1] = sl("AfterRate", "Seconds Between Copies", 0.02, 0.3, 2, 0.01)
        after[#after + 1] = sl("AfterFade", "Fade Time (Seconds)", 0.1, 1.5, 2, 0.05)
        after[#after + 1] = sl("AfterStart", "Copy Opacity", 0.1, 1, 2, 0.05)
        after[#after + 1] = tg("AfterDashOnly", "Only While Dashing")
    end

    -- 1b. saved pursuers -----------------------------------------------
    local saved = {
        { t = "input", text = "Pursuer Name", placeholder = "my pursuer", get = function() return Pur.presetName end, set = function(txt) Pur.presetName = txt end },
        { t = "buttons", items = {
            { label = "Save", style = "green", fn = function()
                local ok, r = Pur.savePreset(Pur.presetName)
                if ok then Pur.presetName = r; refreshPage(); toast("Saved pursuer '" .. r .. "'.", "ok") else toast(r, "ng") end
            end },
            { label = "Load", style = "blue", fn = function()
                local ok, r = Pur.loadPreset(Pur.presetName)
                if ok then Pur.presetName = r; refreshPage(); toast("Loaded pursuer '" .. r .. "'.", "ok") else toast(r, "ng") end
            end },
            { label = "Delete", style = "red", confirm = true, fn = function()
                local ok, r = Pur.deletePreset(Pur.presetName)
                if ok then Pur.presetName = ""; refreshPage(); toast("Deleted pursuer '" .. r .. "'.", "ok") else toast(r, "ng") end
            end },
        } },
        { t = "dropdown", text = "Saved Pursuers", get = function() return "Choose One To Load..." end,
            options = function() local l = Pur.listPresets(); if #l == 0 then return { "(none saved yet)" } end; return l end,
            set = function(o)
                if o:sub(1, 1) == "(" then return end
                local ok, r = Pur.loadPreset(o)
                if ok then Pur.presetName = r; refreshPage(); toast("Loaded pursuer '" .. r .. "'.", "ok") else toast(r, "ng") end
            end },
        { t = "text", text = "A saved pursuer holds every setting in the Pursuer sections except the on/off switch. Files go in TonyScriptPalace/Pursuer/Presets, so you can share them. A pursuer points to its pictures and sounds by file name or link, so keep those in the Images and Sounds folders (or use links or asset numbers) if you want it to look right on someone else's machine."},
    }

    return {
        { title = "Pursuer (Custom Chaser)", collapsed = false, controls = main },
        { title = "Pursuer: Saved Pursuers", collapsed = false, controls = saved },
        { title = "Pursuer: Look And Preview", controls = look },
        { title = "Pursuer: Movement And Speed", collapsed = true, controls = move },
        { title = "Pursuer: Dash", collapsed = true, controls = dash },
        { title = "Pursuer: Spawning", collapsed = true, controls = spawn },
        { title = "Pursuer: Chase Alert", collapsed = true, controls = alert },
        { title = "Pursuer: Sounds", collapsed = true, controls = snd },
        { title = "Pursuer: Afterimages", collapsed = true, controls = after },
    }
end

local function buildFunPage()
    local function tg(key, text) return { t = "toggle", text = text, get = function() return Fun[key] end, set = function(v) Fun[key] = v end } end
    local function tgR(key, text) return { t = "toggle", text = text, get = function() return Fun[key] end, set = function(v) Fun[key] = v; refreshPage() end } end
    local function dd(key, text, list, refresh)
        return { t = "dropdown", text = text, get = function() return Fun[key] end, options = function() return list end,
            set = function(o) Fun[key] = o; refreshPage() end }
    end
    local function sl(key, text, min, max, dec, step) return { t = "slider", text = text, min = min, max = max, dec = dec, step = step, get = function() return Fun[key] end, set = function(v) Fun[key] = v end } end

    local main = {
        { t = "text", text = "Gives you skill checks while you're NOT working a machine, for when life is just too easy. They use the game's own skill check look and sounds, and never happen while the floor isn't active, while you're in the elevator or while you're extracting. Machines can't be started while one is on screen, and one that's up when you enter the elevator gets cancelled. Extra checks only play out on your screen, nothing goes to the server, so failing one doesn't alert the Twisteds. Starts off every time."},
        { t = "toggle", text = "More Skill Checks (Outside Machines)", get = function() return Fun.Enabled end,
            set = function(v) Fun.Enabled = v; Fun.Status = v and "On" or "Off"; toast(v and "Extra skill checks on." or "Extra skill checks off.", "info") end },
        dd("When", "When Can They Happen", FUN_WHEN),
        tg("CancelWhenSpotted", "Being Spotted Or Hit Cancels Extra Checks (Like The Game)"),
        { t = "text", text = "The game cancels any skill check that isn't a door check when a Twisted spots or hits you. That would make While Chased pointless, so extra checks ignore it by default. Turn this on to get the game's cancel back (it applies from the next check)."},
        tg("Default", "Default Skill Check"), tg("Circle", "Circle Skill Check"), tg("Treadmill", "Treadmill Skill Check"),
        { t = "text", text = "With more than one type ticked, each check picks at random from the ticked types. It rolls once a second and never twice within the gap below."},
        sl("Gap", "Minimum Seconds Between Checks", 0, 15, 1, 0.5),
        { t = "readout", text = "Status", get = function() return Fun.Status end },
    }

    local live = {
        { t = "text", text = "What the next extra skill check will use right now, including your Per-Twisted settings. Updates live."},
        { t = "readout", text = "Twisteds Counted", get = function() local c = Fun.calc(); return tostring(c.n) .. " (" .. Fun.TwistedCount .. ")" end },
        { t = "readout", text = "Skill Check Chance", get = function() return string.format("%.1f%% per roll", Fun.calc().chance) end },
        { t = "readout", text = "Chance Breakdown", get = function() local c = Fun.calc(); return string.format("%.1f  x  %.2f  +  %.1f points", c.chanceBase, c.chanceMul, c.chanceFlat) end },
        { t = "readout", text = "Skill Check Size", get = function() local c = Fun.calc(); return string.format("%.0f units (default check: %.1f%% of the bar)", c.size, c.ratio * 100) end },
        { t = "readout", text = "Size Breakdown", get = function() local c = Fun.calc(); return string.format("%.0f  x  %.3f  (game's modifier %.3f)", c.base, c.mod, c.gameMod) end },
        { t = "readout", text = "Marker Speed", get = function() return string.format("%.2fx", Fun.calc().mult) end },
        { t = "readout", text = "Default Check Sweep", get = function() return string.format("%.2f seconds", Fun.calc().sweepD) end },
        { t = "readout", text = "Circle Check Shrink", get = function() local c = Fun.calc(); return string.format("%.2f seconds%s", c.sweepC, c.overrideC and "" or " (the game's own)") end },
        { t = "readout", text = "Skill Check Value", get = function() return string.format("%.1f", Fun.calc().value) end },
    }

    local scale = {
        { t = "text", text = "Makes the checks harder or easier depending on how many Twisteds there are. Negative numbers do the opposite. Percentages add up per Twisted (5% each with two Twisteds makes 10%), and that total gets multiplied with the game's own size modifier (10% on top of the game's 5% makes 15.5%). Flat size is added to your BoundarySize before the modifiers, and flat speed is added to the marker speed multiplier. Higher speed means a faster marker."},
        dd("TwistedCount", "Count Twisteds", FUN_COUNT),
        tgR("ChanceScale", "Chance Changes For Each Twisted"),
    }
    if Fun.ChanceScale then
        scale[#scale + 1] = dd("ChanceScaleMode", "Chance Change Type", FUN_SCALE_CHANCE)
        if Fun.ChanceScaleMode == "Multiplier" then scale[#scale + 1] = sl("ChancePct", "Chance Per Twisted (%)", -100, 100, 0, 1)
        else scale[#scale + 1] = sl("ChancePer", "Chance Per Twisted (Percentage Points)", -25, 25, 1, 0.5) end
        scale[#scale + 1] = { t = "text", text = "Chance percentages never multiply, they just add up (5% for each of two Twisteds makes 10%, so a 25% chance becomes 27.5%). Flat adds percentage points after that, like the game's own additive part."}
    end
    scale[#scale + 1] = tgR("SpeedScale", "Marker Speed Changes For Each Twisted")
    if Fun.SpeedScale then
        scale[#scale + 1] = dd("SpeedScaleMode", "Speed Change Type", FUN_SCALE)
        if Fun.SpeedScaleMode == "Flat" then scale[#scale + 1] = sl("SpeedFlat", "Speed Per Twisted (x)", -1, 2, 2, 0.05)
        else scale[#scale + 1] = sl("SpeedPct", "Speed Per Twisted (%)", -50, 100, 0, 1) end
    end
    scale[#scale + 1] = tgR("SizeScale", "Skill Check Size Changes For Each Twisted")
    if Fun.SizeScale then
        scale[#scale + 1] = dd("SizeScaleMode", "Size Change Type", FUN_SCALE)
        if Fun.SizeScaleMode == "Flat" then scale[#scale + 1] = sl("SizeFlat", "Size Per Twisted (BoundarySize Units)", -200, 200, 0, 5)
        else scale[#scale + 1] = sl("SizePct", "Size Per Twisted (%)", -50, 100, 0, 1) end
    end

    local tune = {
        { t = "text", text = "Size: Stat uses your BoundarySize x BoundarySizeModifier, so a Magnifying Glass (which lowers the modifier) shrinks it like it does in machines. Chance and Value: Stat uses SkillCheckChance and SkillCheckValue. Speed: Game uses the game's own speeds (the default check always sweeps in 2 seconds, the circle check's speed comes from your BoundarySize), Skill Check Speed is a just-for-fun option that uses that stat, and Manual lets you set the times yourself."},
        dd("SizeMode", "Size", FUN_AUTO, true),
    }
    if Fun.SizeMode == "Manual" then tune[#tune + 1] = sl("Size", "Manual Size (BoundarySize Units)", 0, 1000, 0, 5) end
    tune[#tune + 1] = dd("SpeedMode", "Speed", FUN_SPEED, true)
    if Fun.SpeedMode == "Skill Check Speed" then
        tune[#tune + 1] = { t = "text", text = "Just-for-fun option: your SkillCheckSpeed x SkillCheckSpeedModifier, compared to the reference below, speeds up the game's normal sweep (2 seconds for the default check, 1.2 for the circle check). At the reference value it's the game's normal speed, double the reference is twice as fast. The game itself never uses this stat for skill checks, so this one is purely us having fun."}
        tune[#tune + 1] = sl("SpeedRef", "Reference Stat (Normal Speed)", 1, 10, 1, 0.5)
            end
    if Fun.SpeedMode == "Manual" then
        tune[#tune + 1] = sl("DefaultTime", "Default Check Sweep Time (Seconds)", 0.3, 5, 1, 0.1)
        tune[#tune + 1] = sl("CircleTime", "Circle Check Shrink Time (Seconds)", 0.3, 3, 1, 0.1)
    end
    tune[#tune + 1] = dd("ChanceMode", "Chance", FUN_AUTO, true)
    if Fun.ChanceMode == "Manual" then tune[#tune + 1] = sl("Chance", "Manual Chance (% Per Roll)", 0, 100, 0, 1) end
    tune[#tune + 1] = dd("ValueMode", "Value", FUN_AUTO, true)
    if Fun.ValueMode == "Manual" then tune[#tune + 1] = sl("Value", "Manual Value", 0, 3, 1, 0.5) end

    local rew = {
        { t = "text", text = "Gold skill checks only (the default check's gold zone, the circle check's great ring). The treadmill check has no gold; in the real game a good one just fills the machine."},
        tgR("Rewards", "Gold Skill Check Rewards"),
    }
    if Fun.Rewards then
        rew[#rew + 1] = dd("RewardMode", "Reward", FUN_REWARD_MODES, true)
        local m = Fun.RewardMode
        if m == "Skill Check Stat" then
            rew[#rew + 1] = { t = "text", text = "A flat speed boost equal to the stat, added to your walk AND run speed before any multipliers."}
            rew[#rew + 1] = dd("RewardStat", "Stat To Use", FUN_REWARD_STATS, true)
        elseif m == "Flat" then
            rew[#rew + 1] = sl("RewardWalk", "Walk Speed Boost", 0, 20, 1, 0.5)
            rew[#rew + 1] = sl("RewardRun", "Run Speed Boost", 0, 20, 1, 0.5)
        elseif m == "Multiplier" then
            rew[#rew + 1] = { t = "text", text = "Multiplied with the game's own SpeedModifier / RunSpeedModifier, so 10% on top of the game's 5% gives 15.5%. Percent math, not addition."}
            rew[#rew + 1] = sl("RewardWalkPct", "Walk Speed Multiplier (%)", 0, 100, 0, 1)
            rew[#rew + 1] = sl("RewardRunPct", "Run Speed Multiplier (%)", 0, 100, 0, 1)
        else
            rew[#rew + 1] = { t = "text", text = "A fake Energized buff using the game's own tiers: I = +25%, II = +50%, III = +75% to walk and run speed. It shows with the game's own icon on the right side of the screen and above your head. Custom lets you pick the percent yourself."}
            rew[#rew + 1] = dd("EnergizedTier", "Energized Tier", FUN_TIERS, true)
            if Fun.EnergizedTier == "Custom" then rew[#rew + 1] = sl("EnergizedPct", "Custom Energized Boost (%)", 0, 200, 0, 1) end
        end
        rew[#rew + 1] = sl("RewardTime", "Reward Duration (Seconds)", 0.5, 30, 1, 0.5)
        if m == "Skill Check Stat" and Fun.RewardStat == "Skill Check Value" and Fun.ValueMode == "Stat" then
            rew[#rew + 1] = { t = "readout", text = "Current Boost", get = function()
                local st = LP.Character and LP.Character:FindFirstChild("Stats")
                local v = st and st:FindFirstChild("SkillCheckValue")
                return v and tostring(v.Value) or "?"
            end }
        end
    end

    local pen = {
        { t = "text", text = "Applies when you fail or miss any extra skill check."},
        tgR("Penalties", "Skill Check Failure Penalties"),
    }
    if Fun.Penalties then
        pen[#pen + 1] = tg("PenaltiesOnTreadmill", "Also Apply To Failed Treadmill Checks")
        pen[#pen + 1] = { t = "text", text = "Turn that off if you only want the real treadmill penalty (set up under Treadmill And Icons) on treadmill checks."}
        pen[#pen + 1] = dd("PenaltyMode", "Penalty", FUN_PEN_MODES, true)
        local m = Fun.PenaltyMode
        if m == "Flat" then
            pen[#pen + 1] = sl("PenaltyWalk", "Walk Speed Nerf", 0, 20, 1, 0.5)
            pen[#pen + 1] = sl("PenaltyRun", "Run Speed Nerf", 0, 20, 1, 0.5)
        elseif m == "Multiplier" then
            pen[#pen + 1] = sl("PenaltyWalkPct", "Walk Speed Penalty (%)", 0, 100, 0, 1)
            pen[#pen + 1] = sl("PenaltyRunPct", "Run Speed Penalty (%)", 0, 100, 0, 1)
        elseif m == "Slow" then
            pen[#pen + 1] = { t = "text", text = "A fake Slowness debuff using the game's own tiers: I = -15%, II = -25%, III = -50% to walk and run speed. Same icon treatment as Energized: right side of the screen and above your head. Custom lets you pick the percent yourself."}
            pen[#pen + 1] = dd("SlowTier", "Slowness Tier", FUN_TIERS, true)
            if Fun.SlowTier == "Custom" then pen[#pen + 1] = sl("SlowPct", "Custom Slowness (%)", 0, 100, 0, 1) end
        else
            pen[#pen + 1] = { t = "text", text = "Sets your health to 0 the moment you fail. Hurting you for a smaller amount isn't an option, since the server controls your health and won't be talked into it."}
        end
        if m ~= "Kill" then pen[#pen + 1] = sl("PenaltyTime", "Penalty Duration (Seconds)", 0.5, 30, 1, 0.5) end
    end

    local stack = {
        { t = "text", text = "What happens when you get the same kind of effect again while it's still running. Off refreshes it, On stacks with no limit, Limit stacks up to a maximum and then replaces the one that would end first."},
        dd("Stack", "Stacking", FUN_STACK, true),
    }
    if Fun.Stack == "Limit" then stack[#stack + 1] = sl("StackLimit", "Stack Limit", 1, 10, 0, 1) end

    local trink = {
        { t = "text", text = "Magnifying Glass: a white or gold hit gives a slight speed boost (4% of your walk speed while walking, 4% of your run speed while running). Mime Makeup: failing has no penalty, as if penalties were off (its own text and sound always play when it's equipped, like in the game). Train Whistle: immune to the fake Slowness. Only trinkets you actually have equipped count."},
        tgR("Trinkets", "Trinket Interactions"),
    }
    if Fun.Trinkets then trink[#trink + 1] = sl("MagTime", "Magnifying Glass Boost Duration (Seconds)", 0.5, 30, 1, 0.5) end

    local misc = {
        { t = "text", text = "Per the wiki, failing a treadmill skill check gives -70% walk speed and -80% run speed (for 3 seconds in the game's code). Mime Makeup doesn't stop this in the real game, so it doesn't here either. The real one also alerts the Twisteds, which this can't do."},
        tgR("TreadmillDazed", "Failed Treadmill Check Slows You"),
    }
    if Fun.TreadmillDazed then
        misc[#misc + 1] = tg("TreadmillAll", "Also Apply To Failed Default And Circle Checks")
        misc[#misc + 1] = sl("TreadmillWalkPct", "Walk Speed Nerf (%)", 0, 100, 0, 1)
        misc[#misc + 1] = sl("TreadmillRunPct", "Run Speed Nerf (%)", 0, 100, 0, 1)
        misc[#misc + 1] = sl("TreadmillTime", "Duration (Seconds)", 0.5, 30, 1, 0.5)
        misc[#misc + 1] = tg("DazedBlock", "Also Block Sprinting While It Lasts")
        misc[#misc + 1] = { t = "text", text = "The game's own sprint code refuses to start a sprint while a Dazed marker is set, and the wiki doesn't mention that, so this is off by default."}
    end
    misc[#misc + 1] = tg("Icons", "Show Effect Icons (Right Side And Overhead)")
    misc[#misc + 1] = tg("ShowDazed", "Show Dazed Icon")
    misc[#misc + 1] = tg("CustomIcons", "Show Icons For Custom Effects")
    misc[#misc + 1] = { t = "text", text = "The game only has Slow, Energized and Dazed. Flat and multiplier boosts and penalties, plus the Magnifying Glass boost, have no buff of their own, so their icons stay off unless you turn the last toggle on (they then borrow the Energized or Slow icon). The game doesn't normally show Dazed above your head, so that's its own toggle too."}
    misc[#misc + 1] = { t = "readout", text = "Active Effects", get = function() return tostring(Fun.activeCount()) end }

    local secs = {
        { title = "More Skill Checks", controls = main },
        { title = "Live Values", controls = live },
        { title = "Size, Speed, Chance And Value", collapsed = true, controls = tune },
        { title = "Per-Twisted Changes", collapsed = true, controls = scale },
        { title = "Gold Rewards", collapsed = true, controls = rew },
        { title = "Failure Penalties", collapsed = true, controls = pen },
        { title = "Stacking", collapsed = true, controls = stack },
        { title = "Trinkets", collapsed = true, controls = trink },
        { title = "Treadmill Failure And Icons", collapsed = true, controls = misc },
    }
    return secs
end

local function buildPursuerPage() return Fun.Pur.sections() end

Features.fun = {
    serialize = function()
        local out = {}
        for k, v in pairs(Fun) do
            if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
                if k ~= "Enabled" and k ~= "Status" and k ~= "dazedUntil" and k ~= "dazedSet" and k ~= "dazedPrev" then out[k] = v end   -- the More Skill Checks switch is saved by the "switches" entry
            end
        end
        return out
    end,
    apply = function(data)
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            local cur = Fun[k]
            if k ~= "Enabled" and k ~= "Status" and k ~= "dazedUntil" and k ~= "dazedSet" and k ~= "dazedPrev" and type(cur) == type(v) and (type(v) ~= "number" or v == v) then Fun[k] = v end
        end
        Fun.Size = math.clamp(Fun.Size, 0, 1000)
        Fun.Value = math.clamp(math.floor(Fun.Value * 2 + 0.5) / 2, 0, 3)
        if not funIn(FUN_WHEN, Fun.When) then Fun.When = "Always" end
        if not funIn(FUN_AUTO, Fun.SizeMode) then Fun.SizeMode = "Stat" end
        Fun.SpeedRef = math.clamp(Fun.SpeedRef, 1, 10)
        if not funIn(FUN_AUTO, Fun.ChanceMode) then Fun.ChanceMode = "Stat" end
        if not funIn(FUN_AUTO, Fun.ValueMode) then Fun.ValueMode = "Stat" end
        if not funIn(FUN_SPEED, Fun.SpeedMode) then Fun.SpeedMode = "Game" end
        if not funIn(FUN_REWARD_MODES, Fun.RewardMode) then Fun.RewardMode = "Skill Check Stat" end
        if not funIn(FUN_REWARD_STATS, Fun.RewardStat) then Fun.RewardStat = "Skill Check Value" end
        if not funIn(FUN_PEN_MODES, Fun.PenaltyMode) then Fun.PenaltyMode = "Slow" end
        if not funIn(FUN_STACK, Fun.Stack) then Fun.Stack = "Off" end
        if not funIn(FUN_COUNT, Fun.TwistedCount) then Fun.TwistedCount = "Chasing You" end
        if not funIn(FUN_SCALE_CHANCE, Fun.ChanceScaleMode) then Fun.ChanceScaleMode = "Flat" end
        if not funIn(FUN_SCALE, Fun.SpeedScaleMode) then Fun.SpeedScaleMode = "Multiplier" end
        if not funIn(FUN_SCALE, Fun.SizeScaleMode) then Fun.SizeScaleMode = "Multiplier" end
        if not funIn(FUN_TIERS, Fun.EnergizedTier) then Fun.EnergizedTier = "I" end
        if not funIn(FUN_TIERS, Fun.SlowTier) then Fun.SlowTier = "II" end
    end,
}

--#endregion page-fun
--#region customizer-engine
----------------------------------------------------------------------
-- CHARACTER CUSTOMIZER  (cosmetic, client-side only: engine + its tab)
-- Toons are collected from three places:
--   Lobby          workspace.Players
--   Game           workspace.InGamePlayers
--   Roleplay Mode  found automatically (the folder that holds your character, or any workspace folder full of toon models)
-- Files live in TonyScriptPalace/CharacterCustomizer (Configs, Library, Cache). Anything in the old standalone
-- script's DandyCustomizer folder is copied over once, automatically.
-- Everything lives inside one function so it only costs the hub ONE top-level local (Luau allows 200).
----------------------------------------------------------------------
local Cust = (function(tspToast, tspRefresh)
local RS = ReplicatedStorage
local getasset = getcustomasset or getsynasset
local httpReq  = request or http_request or (syn and syn.request) or (http and http.request)
local alive = true
local conns = {}
local toast = tspToast

----------------------------------------------------------------------
-- FILE SYSTEM
----------------------------------------------------------------------
local ROOT_DIR   = ROOT_DIR .. "/CharacterCustomizer"   -- inside the hub's own folder (the hub's ROOT_DIR is "TonyScriptPalace")
local CFG_DIR    = ROOT_DIR .. "/Configs"
local LIB_DIR    = ROOT_DIR .. "/Library"
local CACHE_DIR  = ROOT_DIR .. "/Cache"
local SETTINGS_F = ROOT_DIR .. "/settings.json"

local function try(f, ...) local ok, a = pcall(f, ...); if ok then return a end; return nil end
local function isF(p) return isfile and try(isfile, p) or false end
local function isD(p) return isfolder and try(isfolder, p) or false end
local function mkD(p) if makefolder and not isD(p) then pcall(makefolder, p) end end
local function rdF(p) return readfile and try(readfile, p) or nil end
local function wrF(p, c) if writefile then return pcall(writefile, p, c) end; return false end
local function lsD(p) return listfiles and try(listfiles, p) or {} end
local function dlF(p) if delfile then pcall(delfile, p) end end
local function baseName(p) p = tostring(p):gsub("\\", "/"); return p:match("([^/]+)$") or p end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function jenc(t) local ok, r = pcall(HttpService.JSONEncode, HttpService, t); return ok and r or nil end
local function jdec(s) local ok, r = pcall(HttpService.JSONDecode, HttpService, s); return ok and r or nil end
local function sanitize(s) return (tostring(s):gsub("[^%w%-_ ]", "_")) end
local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepcopy(v) end
    return o
end

mkD(ROOT_DIR); mkD(CFG_DIR); mkD(LIB_DIR); mkD(CACHE_DIR)

----------------------------------------------------------------------
-- CUSTOMIZER SETTINGS
----------------------------------------------------------------------
-- One-time copy from the old standalone script's "DandyCustomizer" folder (settings, configs and the toon library).
-- The old folder is left alone, so you can delete it whenever you like. Cached downloads are not copied; they re-download when needed.
do
    local OLD, DONE = "DandyCustomizer", ROOT_DIR .. "/migrated.txt"
    if isD(OLD) and not isF(DONE) then
        local copied = 0
        for _, sub in ipairs({ "Configs", "Library" }) do
            for _, p in ipairs(lsD(OLD .. "/" .. sub)) do
                local name = baseName(p)
                local dst = ROOT_DIR .. "/" .. sub .. "/" .. name
                if name:lower():match("%.json$") and not isF(dst) then
                    local d = rdF(OLD .. "/" .. sub .. "/" .. name)
                    if d and wrF(dst, d) then copied = copied + 1 end
                end
            end
        end
        if not isF(SETTINGS_F) and isF(OLD .. "/settings.json") then
            local d = rdF(OLD .. "/settings.json")
            if d and wrF(SETTINGS_F, d) then copied = copied + 1 end
        end
        wrF(DONE, "copied " .. copied .. " files from " .. OLD)
    end
end

local S = {
    rules = {}, folders = { "Images", "Textures", "Animations" }, autoApply = false, autoConfig = "", keepWorking = true, localAnims = true,
    sources = { Lobby = true, Game = true, Roleplay = true }, captureOthers = true,
}
do
    local s = jdec(rdF(SETTINGS_F) or "")
    if type(s) == "table" then
        if type(s.folders) == "table" then S.folders = s.folders end
        if s.autoApply ~= nil then S.autoApply = s.autoApply and true or false end
        if type(s.autoConfig) == "string" then S.autoConfig = s.autoConfig end
        if s.keepWorking ~= nil then S.keepWorking = s.keepWorking and true or false end
        if type(s.rules) == "table" then S.rules = s.rules end
        if s.localAnims ~= nil then S.localAnims = s.localAnims and true or false end
        if s.captureOthers ~= nil then S.captureOthers = s.captureOthers and true or false end
        if type(s.sources) == "table" then
            for _, k in ipairs({ "Lobby", "Game", "Roleplay" }) do
                if s.sources[k] ~= nil then S.sources[k] = s.sources[k] and true or false end
            end
        end
    end
end
local function saveSettings() local j = jenc(S); if j then wrF(SETTINGS_F, j) end end

-- Folders are always INSIDE TonyScriptPalace/CharacterCustomizer (never the executor's workspace root).
local function cleanFolder(f)
    f = tostring(f or ""):gsub("\\", "/")
    local pre = (ROOT_DIR .. "/"):lower()
    if f:lower():sub(1, #pre) == pre then f = f:sub(#pre + 1) end
    f = f:gsub("%.%.+", "")                 -- cannot climb out of the folder
    f = f:gsub("^/+", "")
    f = f:gsub("/+$", "")
    return f
end
local function ensureDir(rel)               -- creates nested folders one segment at a time
    local cur = ROOT_DIR
    for seg in tostring(rel):gmatch("[^/]+") do
        cur = cur .. "/" .. seg
        if not isD(cur) then pcall(mkD, cur) end
    end
end
do
    local seen, clean = {}, {}
    for _, f in ipairs(S.folders) do
        local c = cleanFolder(f)
        if c ~= "" and not seen[c] then seen[c] = true; clean[#clean + 1] = c end
    end
    S.folders = clean
    for _, f in ipairs(S.folders) do ensureDir(f) end
end


-- Writing MeshId only changes the property: the geometry is NOT reloaded, so the old shape just gets stretched.
-- AssetService:CreateMeshPartAsync loads real geometry, and ApplyMesh copies it onto a live part (verified in-game).
local meshCache = {}
local function getMesh(id)   -- yields
    local c = meshCache[id]
    if c then return c end
    local ok, mp = pcall(function() return game:GetService("AssetService"):CreateMeshPartAsync(id) end)
    if ok and typeof(mp) == "Instance" then meshCache[id] = mp; return mp end
    return nil, tostring(mp)
end

----------------------------------------------------------------------
-- ASSET SOURCES  (rbxassetid / link / file in a folder YOU registered)
----------------------------------------------------------------------
local EXTS, classifyAsset, resolveAsset, resolveAnim, fileOptions, walkFiles, findFile
do
EXTS = { "png", "jpg", "jpeg", "webp", "bmp", "tga", "obj", "mesh", "rbxm", "rbxmx", "mp3", "ogg", "wav" }
local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format("%08x%x", h, #s)
end

classifyAsset = function(src)
    src = trim(src)
    if src == "" then return "empty" end
    local id = src:match("^rbxassetid://(%d+)") or src:match("^(%d+)$") or src:match("^rbxassetid:(%d+)")
    if id then return "id", id end
    if src:lower():find("roblox%.com", 1) then
        local i = src:match("[?&]id=(%d+)") or src:match("/library/(%d+)") or src:match("/catalog/(%d+)")
        if i then return "id", i end
    end
    if src:match("^https?://") then return "url", src end
    if src:match("^rbxasset://") then return "builtin", src end
    return "file", src
end

local function normalizeUrl(u)
    local id = u:match("drive%.google%.com/file/d/([%w%-_]+)")
    if not id and (u:find("drive.google.com", 1, true) or u:find("docs.google.com", 1, true)) then
        id = u:match("[?&]id=([%w%-_]+)")
    end
    if id then return "https://drive.usercontent.google.com/download?id=" .. id .. "&export=download&confirm=t" end
    if u:find("dropbox.com", 1, true) then
        u = u:gsub("://www%.dropbox%.com", "://dl.dropboxusercontent.com"):gsub("://dropbox%.com", "://dl.dropboxusercontent.com")
        u = u:gsub("dl=0", "dl=1")
        return u
    end
    local user, repo, rest = u:match("^https://github%.com/([^/]+)/([^/]+)/blob/(.+)$")
    if user then return ("https://raw.githubusercontent.com/%s/%s/%s"):format(user, repo, rest) end
    return u
end

local function sniff(b)
    if b:sub(1, 4) == "\137PNG" then return "png" end
    if b:sub(1, 3) == "\255\216\255" then return "jpg" end
    if b:sub(1, 4) == "RIFF" and b:sub(9, 12) == "WEBP" then return "webp" end
    if b:sub(1, 4) == "RIFF" then return "wav" end
    if b:sub(1, 3) == "ID3" then return "mp3" end
    if b:sub(1, 4) == "OggS" then return "ogg" end
    if b:sub(1, 2) == "BM" then return "bmp" end
    if b:sub(1, 14) == "<roblox!\137\255\r\n" or b:sub(1, 8) == "<roblox!" then return "rbxm" end
    if b:sub(1, 7) == "<roblox" then return "rbxmx" end
    if b:sub(1, 8) == "version " then return "mesh" end
    return nil
end
local function isHtml(b)
    local h = b:sub(1, 300):lower()
    return h:find("<!doctype", 1, true) ~= nil or h:find("<html", 1, true) ~= nil
end
local function fetch(url)
    if not httpReq then return nil, "This executor has no request()." end
    local ok, res = pcall(httpReq, { Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
    if not ok then return nil, "Request failed: " .. tostring(res) end
    if not res then return nil, "No response." end
    local code = res.StatusCode or res.status_code or 0
    if code >= 400 then return nil, "Server answered HTTP " .. code .. " (is the link public?)" end
    return res.Body or "", nil
end
local function cachedPath(key)
    for _, e in ipairs(EXTS) do
        local p = CACHE_DIR .. "/" .. key .. "." .. e
        if isF(p) then return p end
    end
end
local function fetchToCache(url, force)
    local nurl = normalizeUrl(url)
    local key = hash(nurl)
    if not force then
        local p = cachedPath(key)
        if p then return p end
    end
    local body, err = fetch(nurl)
    if not body then return nil, err end
    if isHtml(body) then return nil, "That link gave a web page, not a file. Use a direct download link." end
    if #body < 100 then return nil, "Downloaded file is too small." end
    local ext = sniff(body)
    if not ext then
        local e = (nurl:gsub("[?#].*$", "")):match("%.(%w+)$")
        e = e and e:lower()
        if e and table.find(EXTS, e) then ext = e end
    end
    if not ext then return nil, "Unrecognised file type (png / jpg / webp / obj / mesh / rbxm)." end
    local path = CACHE_DIR .. "/" .. key .. "." .. ext
    if not wrF(path, body) then return nil, "Couldn't write the cache file." end
    return path
end

walkFiles = function(folder, depth, out)
    for _, p in ipairs(lsD(folder)) do
        p = (p:gsub("\\", "/"))
        if isD(p) then
            if depth < 3 then walkFiles(p, depth + 1, out) end
        else
            out[#out + 1] = p
        end
    end
end
local function registeredFiles()
    local out = {}
    for _, folder in ipairs(S.folders) do          -- folders live inside TonyScriptPalace/CharacterCustomizer
        local all = {}
        walkFiles(ROOT_DIR .. "/" .. folder, 0, all)
        for _, p in ipairs(all) do
            local e = baseName(p):match("%.(%w+)$")
            if e and table.find(EXTS, e:lower()) then
                local rel = p:gsub("\\", "/")
                local pre = (ROOT_DIR .. "/"):lower()
                local i = rel:lower():find(pre, 1, true)
                if i then rel = rel:sub(i + #pre) end     -- show it as  Images/face.png
                out[#out + 1] = { label = rel, ext = e:lower(), path = p }
            end
        end
    end
    table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
    return out
end
local IMG = { png = true, jpg = true, jpeg = true, webp = true, bmp = true, tga = true }
local MESHX = { obj = true, mesh = true }
local ANIMX = { rbxm = true, rbxmx = true }
fileOptions = function(kind)
    local out = {}
    for _, f in ipairs(registeredFiles()) do
        local ok = (kind == "img" and IMG[f.ext]) or (kind == "mesh" and (MESHX[f.ext])) or (kind == "anim" and ANIMX[f.ext]) or (kind == "any")
        if ok then out[#out + 1] = f.label end
    end
    if #out == 0 then
        if #S.folders == 0 then return { "(no folders added yet: see Files & Library)" } end
        return { "(no matching files in your folders)" }
    end
    return out
end
findFile = function(name)
    name = trim(name):gsub("\\", "/")
    local pre = ROOT_DIR .. "/"
    if name:lower():sub(1, #pre:lower()) == pre:lower() then name = name:sub(#pre + 1) end
    if isF(ROOT_DIR .. "/" .. name) then return ROOT_DIR .. "/" .. name end             -- inside CharacterCustomizer (Images/face.png)
    for _, folder in ipairs(S.folders) do
        local p = ROOT_DIR .. "/" .. folder .. "/" .. name                                -- just the file name (face.png)
        if isF(p) then return p end
    end
    if isF(name) then return name end                                                     -- old behaviour: a path from the workspace root
    local ln = name:lower()
    for _, f in ipairs(registeredFiles()) do
        local b = baseName(f.label):lower()
        if f.label:lower() == ln or b == ln or (b:gsub("%.%w+$", "")) == ln then return f.path end
    end
end

-- cb(content, errorMessage)
resolveAsset = function(src, cb)
    local kind, v = classifyAsset(src)
    if kind == "empty" then return cb(nil, "empty") end
    if kind == "id" then return cb("rbxassetid://" .. v) end
    if kind == "builtin" then return cb(v) end
    if not getasset then return cb(nil, "This executor has no getcustomasset.") end
    if kind == "file" then
        local p = findFile(v)
        if not p then return cb(nil, "File not found: " .. v .. " (put it in a folder inside TonyScriptPalace/CharacterCustomizer)") end
        local ok, res = pcall(getasset, p)
        if ok and res then return cb(res) end
        return cb(nil, "getcustomasset failed: " .. tostring(res))
    end
    local nurl = normalizeUrl(v)
    local cp = cachedPath(hash(nurl))
    if cp then
        local ok, res = pcall(getasset, cp)
        if ok and res then return cb(res) end
    end
    task.spawn(function()
        local p, err = fetchToCache(v)
        if not p then return cb(nil, err) end
        local ok, res = pcall(getasset, p)
        if ok and res then cb(res) else cb(nil, "getcustomasset failed: " .. tostring(res)) end
    end)
end

-- animations: asset id, or a .rbxm/.rbxmx holding a KeyframeSequence (experimental)
resolveAnim = function(src, cb)
    local kind, v = classifyAsset(src)
    if kind == "id" then return cb("rbxassetid://" .. v) end
    if kind == "empty" then return cb(nil, "empty") end
    resolveAsset(src, function(content, err)
        if not content then return cb(nil, err) end
        local ok, objs = pcall(function() return game:GetObjects(content) end)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                local ks = (o:IsA("KeyframeSequence") and o) or o:FindFirstChildWhichIsA("KeyframeSequence", true)
                if ks then
                    local ok2, id = pcall(function() return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(ks) end)
                    if ok2 and id then
                        id = tostring(id)
                        if id:match("^rbxassetid://%d+$") then return cb(id) end
                        return cb(nil, "The game only accepts rbxassetid:// animations; this executor produced '" .. id .. "'.")
                    end
                end
            end
        end
        cb(nil, "Couldn't read a KeyframeSequence from that file.")
    end)
end

end
----------------------------------------------------------------------
-- VALUE ENCODING  (everything in a config is plain JSON)
----------------------------------------------------------------------
local ENUM_OF = { Material = "Material", Shape = "PartType", Face = "NormalId", ResampleMode = "ResamplerMode" }
local PK = {
    Transparency = "num", Reflectance = "num", Color = "color", Color3 = "color", TextColor3 = "color",
    Material = "enum", Shape = "enum", Face = "enum", Size = "vec3", Offset = "vec3", Rotation = "vec3",
    MeshId = "asset", TextureID = "asset", Texture = "asset", Image = "asset",
    Enabled = "bool", ResampleMode = "enum", AlwaysOnTop = "bool", TextScaled = "bool", Hidden = "bool",
    LightInfluence = "num", PixelsPerStud = "num", Text = "string", ImageTransparency = "num",
    StudsPerTileU = "num", StudsPerTileV = "num", Brightness = "num", Range = "num",
}
local function decV(prop, enc)
    local k = PK[prop]
    if k == "num" then return tonumber(enc)
    elseif k == "bool" then return enc and true or false
    elseif k == "string" then return tostring(enc)
    elseif k == "color" then
        local ok, c = pcall(Color3.fromHex, tostring(enc))
        if ok then return c end
    elseif k == "vec3" then
        if type(enc) == "table" then return Vector3.new(tonumber(enc[1]) or 0, tonumber(enc[2]) or 0, tonumber(enc[3]) or 0) end
    elseif k == "enum" then
        local ok, e = pcall(function() return Enum[ENUM_OF[prop]][enc] end)
        if ok then return e end
    end
    return nil
end
local function encInst(inst, prop)
    local k = PK[prop]
    local ok, v = pcall(function() return inst[prop] end)
    if not ok then return nil end
    if k == "vec3" then return { v.X, v.Y, v.Z }
    elseif k == "color" then return "#" .. v:ToHex()
    elseif k == "enum" then return v.Name end
    return v
end

----------------------------------------------------------------------
-- MODEL HELPERS
----------------------------------------------------------------------
local LOCK = { HumanoidRootPart = true, RootPart = true, DWFlat = true }
local function pathOf(model, inst)
    local t, c = {}, inst
    while c and c ~= model do table.insert(t, 1, c.Name); c = c.Parent end
    return table.concat(t, "/")
end
local function findPath(model, path)
    local c = model
    for part in tostring(path):gmatch("[^/]+") do
        if not c then return nil end
        c = c:FindFirstChild(part)
    end
    return c
end
local function jointFor(inst)
    local second
    for _, d in ipairs(inst:GetChildren()) do
        if d:IsA("Motor6D") or d:IsA("Weld") or d:IsA("ManualWeld") then
            if d.Part1 == inst then return d end
            if d.Part0 == inst then second = second or d end
        end
    end
    return second
end
local function identity(model)
    local cfg = model and model:FindFirstChild("Config")
    local function sv(n) local v = cfg and cfg:FindFirstChild(n); return v and v.Value or nil end
    return {
        CharacterName = sv("CharacterName") or (model and model:GetAttribute("ToonName")),
        ModuleName = sv("ModuleName") or (model and model:GetAttribute("ModuleName")),
        Skin = model and model:GetAttribute("CurrentSkin"),
    }
end
-- WHERE TOONS LIVE. Lobby = workspace.Players, Game = workspace.InGamePlayers, Roleplay = auto-detected.
local PLACE_MODE = { [16116270224] = "Lobby", [16552821455] = "Game", [18984416148] = "Roleplay" }   -- verified live: Roleplay Mode is its own place and also uses workspace.Players
local RP_NAMES = { "RoleplayPlayers", "RoleplayCharacters", "RPPlayers", "RPCharacters", "RoleplayMode", "Roleplay" }
local function looksToon(m) return m:IsA("Model") and m:FindFirstChild("Config") ~= nil and m:FindFirstChild("Animations") ~= nil end
local function classify(folder)
    -- Roleplay Mode (and any place we do not recognise) labels everything Roleplay, whatever the folder is called
    local pm = PLACE_MODE[game.PlaceId]
    if pm == nil or pm == "Roleplay" then return "Roleplay" end
    if folder == workspace then return pm end          -- verified live: your toon spawns in workspace for a moment before moving to InGamePlayers
    if folder.Name == "InGamePlayers" then return "Game" end
    if folder.Name == "Players" then return "Lobby" end
    return "Roleplay"
end
local rpFound, lastDiscover = {}, 0
local function rootsNow()
    local out, seen = {}, {}
    local function add(f) if f and f.Parent and not seen[f] then seen[f] = true; out[#out + 1] = { f = f, mode = classify(f) } end end
    add(workspace:FindFirstChild("InGamePlayers"))
    add(workspace:FindFirstChild("Players"))
    local ch = LP.Character
    if ch and ch.Parent then add(ch.Parent) end          -- wherever the game parked YOUR toon (covers Roleplay Mode)
    for _, n in ipairs(RP_NAMES) do
        local f = workspace:FindFirstChild(n)
        if f and (f:IsA("Folder") or f:IsA("Model")) then add(f) end
    end
    if os.clock() - lastDiscover > 4 then                 -- slow discovery: other folders that directly hold player toons
        lastDiscover = os.clock()
        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Folder") and c.Name ~= "Players" and c.Name ~= "InGamePlayers" and not rpFound[c] then
                for _, m in ipairs(c:GetChildren()) do
                    if looksToon(m) and Players:FindFirstChild(m.Name) then rpFound[c] = true; break end
                end
            end
        end
    end
    for f in pairs(rpFound) do if f.Parent then add(f) else rpFound[f] = nil end end
    return out
end
local function findMine(roots)
    for _, r in ipairs(roots) do
        local m = r.f ~= workspace and r.f:FindFirstChild(LP.Name)
        if m and m:IsA("Model") then return m, r.mode end
    end
    local ch = LP.Character
    if ch and ch.Parent and ch:FindFirstChild("Config") then return ch, classify(ch.Parent) end
end
local function reqMismatch(req, id)
    for _, k in ipairs({ "CharacterName", "ModuleName", "Skin" }) do
        local want = req and req[k]
        if want and want ~= "" and tostring(id[k] or "") ~= want then return k, want, id[k] end
    end
end

----------------------------------------------------------------------
-- LIBRARY  (toons the script has seen; filled automatically)
----------------------------------------------------------------------
local Library = {}
local function serializeModel(model)
    local id = identity(model)
    local cfg = model:FindFirstChild("Config")
    local d = {
        toon = tostring(id.CharacterName or id.ModuleName or model.Name),
        module = tostring(id.ModuleName or id.CharacterName or "Unknown"),
        skin = tostring(id.Skin or "Default"),
        tex = {}, anims = {},
    }
    d.key = d.module .. "__" .. d.skin
    d.v = 3                              -- v3: face textures, animations and the voting icon
    if cfg then                          -- every face slot the toon has: Normal, Blink, Hurt, Face, Transform..., whatever the game defines
        for _, dc in ipairs(cfg:GetChildren()) do
            local k = dc:IsA("Decal") and dc.Name:match("^(.+)Texture$")
            if k and dc.Texture ~= "" then d.tex[k] = dc.Texture end
        end
    end
    local ic = cfg and cfg:FindFirstChild("Icon")
    if ic and ic:IsA("Decal") then d.icon = ic.Texture end
    local an = model:FindFirstChild("Animations")
    if an then for _, a in ipairs(an:GetChildren()) do if a:IsA("Animation") and a.AnimationId ~= "" then d.anims[a.Name] = a.AnimationId end end end
    return d
end

local function keyOf(model)
    local id = identity(model)
    return tostring(id.ModuleName or id.CharacterName or "Unknown") .. "__" .. tostring(id.Skin or "Default")
end
local forceCaptureUntil = 0
local function captureModel(model, mode)
    if not model:FindFirstChild("Config") then return end   -- only real toon models go in the library
    local prev = Library[keyOf(model)]
    -- already saved and already seen in this source: nothing new to learn
    if prev and (prev.v or 1) >= 3 and mode and type(prev.srcs) == "table" and prev.srcs[mode] and os.clock() > forceCaptureUntil then return end
    local ok, d = pcall(serializeModel, model)
    if not ok or not d then return end
    d.srcs = {}
    local changed = (not prev) or (prev.v or 1) < 3
    if prev and type(prev.srcs) == "table" then for k, v in pairs(prev.srcs) do d.srcs[k] = v end end
    if mode and not d.srcs[mode] then d.srcs[mode] = true; changed = true end
    Library[d.key] = d
    if changed then
        local j = jenc(d)
        if j then wrF(LIB_DIR .. "/" .. sanitize(d.key) .. ".json", j) end
    end
end
do
    for _, p in ipairs(lsD(LIB_DIR)) do
        local n = baseName(p)
        if n:lower():match("%.json$") then
            local d = jdec(rdF(LIB_DIR .. "/" .. n) or "")
            if type(d) == "table" and d.key and type(d.tex) == "table" then
                d.parts, d.bones = nil, nil      -- model data from older captures is not used
                d.anims = d.anims or {}
                Library[d.key] = d
            end
        end
    end
end
local function libEntries()
    local out = {}
    for _, e in pairs(Library) do out[#out + 1] = e end
    table.sort(out, function(a, b)
        if a.toon ~= b.toon then return a.toon:lower() < b.toon:lower() end
        return a.skin:lower() < b.skin:lower()
    end)
    return out
end
local function libLabel(e) return e.toon .. " (" .. e.skin .. ")" end

-- vote icons for ALL toons come straight from the game's own data
local function towerIcons()
    local out = {}
    local td = RS:FindFirstChild("TowerData")
    if td then
        for _, m in ipairs(td:GetChildren()) do
            if m:IsA("ModuleScript") then
                local ok, d = pcall(require, m)
                if ok and type(d) == "table" and type(d.VoteIcon) == "string" then out[#out + 1] = { name = m.Name, icon = d.VoteIcon } end
            end
        end
    end
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    return out
end
----------------------------------------------------------------------
-- CONTEXT  (everything we do to ONE character model, fully reversible)
----------------------------------------------------------------------
local Ctx = {}
Ctx.__index = Ctx

local function hookPart(c, p)
    local con = p:GetPropertyChangedSignal("TextureID"):Connect(function()
        if c.guard then return end
        local m = c.texMap[p.TextureID]
        local d = c.desired[p]
        if m and not (d and d.TextureID ~= nil) then
            c.guard = true
            pcall(function() p.TextureID = m end)
            c.guard = false
        end
    end)
    c.hooks[#c.hooks + 1] = con
end

local function newCtx(model, mine)
    local c = setmetatable({
        model = model, mine = mine, orig = {}, desired = {}, texMap = {}, revMap = {}, jointBase = {}, infoOf = {},
        created = {}, specIdOf = {}, createdSet = {}, mcreated = {}, weldOf = {}, hooks = {}, guard = false,
        iconMap = {}, iconTouched = {}, origTex = {}, origAnim = {}, localAnim = {}, mirror = nil, gen = 0,
    }, Ctx)
    local cfg = model:FindFirstChild("Config")
    if cfg then
        for _, d in ipairs(cfg:GetChildren()) do
            local k = d:IsA("Decal") and d.Name:match("^(.+)Texture$")
            if k then c.origTex[k] = d.Texture end
        end
    end
    local ic = cfg and cfg:FindFirstChild("Icon")
    c.origIcon = ic and ic:IsA("Decal") and ic.Texture or nil
    c.origIconAttr = model:GetAttribute("Icon")
    local okh, ext = pcall(function() return model:GetExtentsSize() end)
    c.origHeight = okh and ext.Y or nil
    local an = model:FindFirstChild("Animations")
    if an then for _, a in ipairs(an:GetChildren()) do if a:IsA("Animation") then c.origAnim[a.Name] = a.AnimationId end end end
    for _, d in ipairs(model:GetDescendants()) do if d:IsA("MeshPart") then hookPart(c, d) end end
    c.hooks[#c.hooks + 1] = model.DescendantAdded:Connect(function(d) if d:IsA("MeshPart") then hookPart(c, d) end end)
    return c
end

function Ctx:destroy()
    self:stopMirror()
    for _, h in ipairs(self.hooks) do pcall(function() h:Disconnect() end) end
    self.hooks = {}
end

function Ctx:setD(inst, prop, val)
    local o = self.orig[inst]
    if not o then o = {}; self.orig[inst] = o end
    if o[prop] == nil then
        local ok, cur = pcall(function() return inst[prop] end)
        if ok then o[prop] = cur end
    end
    local d = self.desired[inst]
    if not d then d = {}; self.desired[inst] = d end
    d[prop] = val
    if prop == "MeshId" and inst:IsA("MeshPart") then self:queueMesh(inst, val); return end
    pcall(function() inst[prop] = val end)
end

-- load + apply a mesh on a live part (keeps its texture, which ApplyMesh would otherwise clear)
function Ctx:queueMesh(inst, id, keepSize)
    self.meshTok = self.meshTok or {}
    local tok = (self.meshTok[inst] or 0) + 1
    self.meshTok[inst] = tok
    task.spawn(function()
        local mp, err = getMesh(id)
        if self.meshTok[inst] ~= tok or not alive then return end
        if not mp then toast("Couldn't load mesh " .. tostring(id) .. ": " .. tostring(err), "err"); return end
        local tex = inst.TextureID
        local ok = pcall(function() inst:ApplyMesh(mp) end)
        if not ok then toast("This executor can't swap meshes (MeshPart:ApplyMesh is blocked).", "err") end
        if ok then
            pcall(function() if inst.TextureID ~= tex then inst.TextureID = tex end end)
            local d = self.desired[inst]
            local want = (d and d.Size) or keepSize
            if want then pcall(function() inst.Size = want end) end
        end
    end)
end

function Ctx:unset(inst, prop)
    local d = self.desired[inst]
    if d then d[prop] = nil end
    local o = self.orig[inst]
    if o and o[prop] ~= nil then
        local v = o[prop]
        o[prop] = nil
        if prop == "MeshId" and inst:IsA("MeshPart") then self:queueMesh(inst, v, o.Size or inst.Size)
        else pcall(function() inst[prop] = v end) end
    end
end

function Ctx:restoreInst(inst)
    local o = self.orig[inst]
    if o then
        local keys = {}
        for k in pairs(o) do keys[#keys + 1] = k end
        for _, k in ipairs(keys) do self:unset(inst, k) end
    end
    self.desired[inst] = nil
end

-- restore a DEFAULT part, its joint and its default (non-added) descendants
function Ctx:restoreTree(inst)
    self:restoreInst(inst)
    local j = jointFor(inst)
    if j then self:restoreInst(j); self.jointBase[j] = nil end
    for _, d in ipairs(inst:GetDescendants()) do
        if not self.createdSet[d] then self:restoreInst(d) end
    end
end

function Ctx:clearTexMaps()
    self.guard = true
    for _, p in ipairs(self.model:GetDescendants()) do
        if p:IsA("MeshPart") then
            local back = self.revMap[p.TextureID]
            local d = self.desired[p]
            if back and not (d and d.TextureID ~= nil) then pcall(function() p.TextureID = back end) end
        end
    end
    self.guard = false
    self.texMap = {}; self.revMap = {}
    for gi, orig in pairs(self.iconTouched) do pcall(function() gi.Image = orig end) end
    self.iconTouched = {}; self.iconMap = {}
end

function Ctx:revertAll()
    self.gen = self.gen + 1
    self.localAnim = {}
    self:stopMirror()
    self:clearFlat()
    self:clearTexMaps()
    local list = {}
    for inst in pairs(self.orig) do list[#list + 1] = inst end
    for _, inst in ipairs(list) do self:restoreInst(inst) end
    for _, i in pairs(self.created) do pcall(function() i:Destroy() end) end
    for _, i in ipairs(self.mcreated) do pcall(function() i:Destroy() end) end
    self.created = {}; self.specIdOf = {}; self.createdSet = {}; self.mcreated = {}; self.weldOf = {}
    self.infoOf = {}; self.jointBase = {}; self.desired = {}; self.orig = {}
    if self.origIconAttr ~= nil then pcall(function() self.model:SetAttribute("Icon", self.origIconAttr) end) end
end

-- texture / icon / animation layers ----------------------------------------
function Ctx:applyTexture(key, src)
    local orig = self.origTex[key]
    if not orig then return end
    resolveAsset(src, function(content, err)
        if not alive or not self.model.Parent then return end
        if not content then toast("Texture " .. key .. ": " .. tostring(err), "err"); return end
        self.texMap[orig] = content; self.revMap[content] = orig
        local cfg = self.model:FindFirstChild("Config")
        local d = cfg and cfg:FindFirstChild(key .. "Texture")
        if d then self:setD(d, "Texture", content) end
        self.guard = true
        for _, p in ipairs(self.model:GetDescendants()) do
            if p:IsA("MeshPart") and p.TextureID == orig then
                local dd = self.desired[p]
                if not (dd and dd.TextureID ~= nil) then pcall(function() p.TextureID = content end) end
            end
        end
        self.guard = false
    end)
end

function Ctx:applyIcon(src)
    resolveAsset(src, function(content, err)
        if not alive or not self.model.Parent then return end
        if not content then toast("Vote icon: " .. tostring(err), "err"); return end
        local cfg = self.model:FindFirstChild("Config")
        local d = cfg and cfg:FindFirstChild("Icon")
        if d and d:IsA("Decal") then self:setD(d, "Texture", content) end
        if self.origIcon then self.iconMap[self.origIcon] = content end
        local mod = identity(self.model).ModuleName
        local td = RS:FindFirstChild("TowerData")
        local tm = td and mod and td:FindFirstChild(tostring(mod))
        if tm then
            local ok, data = pcall(require, tm)
            if ok and type(data) == "table" and type(data.VoteIcon) == "string" then self.iconMap[data.VoteIcon] = content end
        end
        pcall(function() self.model:SetAttribute("Icon", content) end)
        self:scanIcons()
    end)
end

function Ctx:scanIcons()
    if next(self.iconMap) == nil then return end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, g in ipairs(pg:GetDescendants()) do
        if g:IsA("ImageLabel") or g:IsA("ImageButton") then
            local m = self.iconMap[g.Image]
            if m and g.Image ~= m then
                if self.iconTouched[g] == nil then self.iconTouched[g] = g.Image end
                pcall(function() g.Image = m end)
            end
        end
    end
end

-- LOCAL-ONLY ANIMATIONS --------------------------------------------------------------------------------
-- The game plays animations on your real Animator and Roblox replicates that to every other player. Rewriting the
-- Animation ids would make everyone see your replacement animations driving your ORIGINAL rig (a T-pose).
-- Replacement animations use their own joint names. In local mode the real Animations folder is never changed:
-- we read the replacement's keyframes ourselves and write them straight onto the matching bones/joints every frame.
-- Bone.Transform is client-side only, so nothing here can replicate.
local ksCache = {}
local function prepareKS(ks)
    local kfs = ks:GetKeyframes()
    table.sort(kfs, function(a, b) return a.Time < b.Time end)
    local frames, names = {}, {}
    for _, kf in ipairs(kfs) do
        local poses = {}
        local function walk(p)
            if p:IsA("Pose") then
                if p.Weight > 0 then poses[p.Name] = { cf = p.CFrame, style = p.EasingStyle, dir = p.EasingDirection }; names[p.Name] = true end
                for _, c in ipairs(p:GetChildren()) do walk(c) end
            end
        end
        for _, p in ipairs(kf:GetPoses()) do walk(p) end
        frames[#frames + 1] = { t = kf.Time, poses = poses }
    end
    return { frames = frames, length = (#frames > 0) and frames[#frames].t or 0, loop = ks.Loop, names = names }
end
local function sampleKS(prep, t, out)
    local fr = prep.frames
    local n = #fr
    if n == 0 then return end
    local i = 1
    while i < n and fr[i + 1].t <= t do i = i + 1 end
    local a, b = fr[i], fr[math.min(i + 1, n)]
    local alpha = (b.t > a.t) and math.clamp((t - a.t) / (b.t - a.t), 0, 1) or 0
    for name in pairs(prep.names) do
        local pa, pb = a.poses[name], b.poses[name]
        local ca, cb = pa and pa.cf, pb and pb.cf
        if ca or cb then
            ca = ca or cb; cb = cb or ca
            local e = alpha
            if pb then
                if pb.style == Enum.PoseEasingStyle.Constant then e = (alpha < 1) and 0 or 1
                elseif pb.style ~= Enum.PoseEasingStyle.Linear then
                    local ok, v = pcall(function() return TweenService:GetValue(alpha, Enum.EasingStyle[pb.style.Name], Enum.EasingDirection[pb.dir.Name]) end)
                    if ok then e = v end
                end
            end
            out[name] = ca:Lerp(cb, e)
        end
    end
end
-- src: an animation id, link or file -> cb(prepared keyframes | nil, error)
local function loadKS(src, cb)
    local kind, v = classifyAsset(src)
    if kind == "empty" then return cb(nil, "empty") end
    local key = (kind == "id") and v or nil
    if key and ksCache[key] then return cb(ksCache[key]) end
    local function fromContent(content)
        local ok, objs = pcall(function() return game:GetObjects(content) end)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                local ks = (o:IsA("KeyframeSequence") and o) or o:FindFirstChildWhichIsA("KeyframeSequence", true)
                if ks then
                    local p = prepareKS(ks)
                    if key then ksCache[key] = p end
                    return cb(p)
                end
            end
        end
        cb(nil, "couldn't read keyframes from that animation (turn off Keep Animations Local to use it for everyone)")
    end
    if kind == "id" then task.spawn(fromContent, "rbxassetid://" .. v)
    else resolveAsset(src, function(content, err) if not content then return cb(nil, err) end; task.spawn(fromContent, content) end) end
end

function Ctx:applyAnim(name, src)
    local an = self.model:FindFirstChild("Animations")
    local a = an and an:FindFirstChild(name)
    if not a then return end
    local gen = self.gen
    if S.localAnims then
        loadKS(src, function(prep, err)
            if not alive or self.gen ~= gen then return end        -- reverted or re-applied while the download was running
            if not prep then toast("Animation " .. name .. ": " .. tostring(err), "err"); return end
            self.localAnim[name] = prep
            self:startMirror()
        end)
        return
    end
    resolveAnim(src, function(id, err)                              -- replicated mode: the game plays it for everyone
        if not alive or not a.Parent or self.gen ~= gen then return end
        if not id then toast("Animation " .. name .. ": " .. tostring(err), "err"); return end
        self:setD(a, "AnimationId", id)
    end)
end

function Ctx:stopMirror()
    local m = self.mirror
    if not m then return end
    self.mirror = nil
    if m.conn then pcall(function() m.conn:Disconnect() end) end
    for bone in pairs(m.written) do pcall(function() bone.Transform = CFrame.new() end) end
end
function Ctx:stepMirror(m)
    local hum = self.model:FindFirstChildWhichIsA("Humanoid")
    local real = hum and hum:FindFirstChildOfClass("Animator")
    local now = os.clock()
    if now - m.bonesAt > 1 then                                     -- re-read the rig now and then in case parts are added or removed
        m.bonesAt = now; m.bones = {}
        for _, d in ipairs(self.model:GetDescendants()) do
            if d:IsA("Bone") and not m.bones[d.Name] then m.bones[d.Name] = d end
        end
        for _, d in ipairs(self.model:GetDescendants()) do         -- classic rigs animate Motor6Ds, and name each pose after the part it moves
            local p1 = d:IsA("Motor6D") and d.Part1
            if p1 and not LOCK[p1.Name] and not m.bones[p1.Name] then m.bones[p1.Name] = d end
        end
    end
    -- the game keeps many copies of the same animation running at weight 0, so follow the strongest copy of each one
    local best = {}
    if real then
        for _, tr in ipairs(real:GetPlayingAnimationTracks()) do
            local id = tr.Animation and tr.Animation.AnimationId
            local name = id and m.byId[id]
            if name and self.localAnim[name] and (not best[name] or tr.WeightCurrent > best[name].WeightCurrent) then best[name] = tr end
        end
    end
    local dt = m.lastStep and (now - m.lastStep) or 0
    m.lastStep = now
    for name, tr in pairs(best) do                                  -- stick with the copy we were following unless another is clearly stronger
        local keep = m.pick[name]
        if keep and keep ~= tr and keep.IsPlaying and keep.WeightCurrent > 0.01 and keep.WeightCurrent >= 0.6 * tr.WeightCurrent then best[name] = keep end
        m.pick[name] = best[name]
    end
    for name in pairs(m.phase) do if not best[name] then m.phase[name] = nil; m.pick[name] = nil end end
    local levels = {}                                               -- animation priority -> { pose, weight } list
    for name, tr in pairs(best) do
        local prep = self.localAnim[name]
        if tr.WeightCurrent > 0.01 and prep.length > 0 then
            -- our own phase (0..1) keeps moving smoothly; we only snap to the game's when we have really drifted apart
            local rp = (tr.Length > 0) and tr.TimePosition / tr.Length or 0
            local ph = m.phase[name]
            if ph then ph = ph + dt * tr.Speed / math.max(tr.Length, 0.01) else ph = rp end
            local diff = math.abs(((ph - rp + 0.5) % 1) - 0.5)
            if diff > 0.12 or not prep.loop and ph > 1 then ph = rp end
            m.phase[name] = ph
            local phase = ph
            local t = prep.loop and (phase % 1) * prep.length or math.clamp(phase, 0, 1) * prep.length
            local pose = {}
            sampleKS(prep, t, pose)
            local pv = tr.Priority.Value
            local lv = levels[pv]
            if not lv then lv = {}; levels[pv] = lv end
            lv[#lv + 1] = { pose = pose, w = tr.WeightCurrent }
        end
    end
    local order = {}
    for pv in pairs(levels) do order[#order + 1] = pv end
    table.sort(order, function(x, y) return x > y end)
    local written = {}
    for bname, bone in pairs(m.bones) do
        if bone.Parent then
            local result, acc = nil, 0                              -- higher priorities win, like Roblox's own blending
            for _, pv in ipairs(order) do
                if acc >= 1 then break end
                local total, blend, bw = 0, nil, 0
                for _, e in ipairs(levels[pv]) do
                    local cf = e.pose[bname]
                    if cf then
                        total = total + e.w
                        if not blend then blend = cf; bw = e.w else blend = blend:Lerp(cf, e.w / (bw + e.w)); bw = bw + e.w end
                    end
                end
                if blend then
                    local use = math.min(total, 1 - acc)
                    if not result then result = blend else result = result:Lerp(blend, use / (acc + use)) end
                    acc = acc + use
                end
            end
            if result then
                if acc < 1 then result = CFrame.new():Lerp(result, acc) end
                bone.Transform = result
                written[bone] = true; m.written[bone] = true
            end
        end
    end
    for bone in pairs(m.written) do                                 -- bones that stopped being animated go back to rest
        if not written[bone] then pcall(function() bone.Transform = CFrame.new() end); m.written[bone] = nil end
    end
end
function Ctx:startMirror()
    if self.mirror then return end
    local byId = {}
    for n, id in pairs(self.origAnim) do byId[id] = n end
    local m = { byId = byId, bones = {}, bonesAt = -10, written = {}, pick = {}, phase = {}, lastStep = nil }
    self.mirror = m
    m.conn = RunService.Heartbeat:Connect(function()
        if not alive or self.mirror ~= m then return end
        pcall(function() self:stepMirror(m) end)
    end)
end



-- props / joints --------------------------------------------------------------
function Ctx:refreshJoint(inst)
    local props = self.infoOf[inst]
    local off = (props and props.Offset) or { 0, 0, 0 }
    local rot = (props and props.Rotation) or { 0, 0, 0 }
    local O = CFrame.new(off[1] or 0, off[2] or 0, off[3] or 0)
        * CFrame.Angles(math.rad(rot[1] or 0), math.rad(rot[2] or 0), math.rad(rot[3] or 0))
    local w = self.weldOf[inst]
    if w and w.Parent then w.C0 = O; return end
    if self.createdSet[inst] then return end
    local j = jointFor(inst)
    if not j then return end
    local prop = (j.Part1 == inst) and "C1" or "C0"
    local jb = self.jointBase[j]
    if not jb then jb = { C0 = j.C0, C1 = j.C1 }; self.jointBase[j] = jb end
    self:setD(j, prop, O:Inverse() * jb[prop])
end

local function applyProp(ctx, inst, prop, enc)
    local props = ctx.infoOf[inst]
    if prop == "Hidden" then
        if enc then ctx:hide(inst) else ctx:unhide(inst) end
        return
    end
    if props and props.Hidden and (prop == "Transparency" or prop == "Enabled") then return end
    if prop == "Offset" or prop == "Rotation" then ctx:refreshJoint(inst); return end
    local kind = PK[prop]
    if kind == "asset" then
        resolveAsset(tostring(enc or ""), function(content, err)
            if content and inst.Parent then ctx:setD(inst, prop, content)
            elseif err and err ~= "empty" then toast(prop .. ": " .. tostring(err), "err") end
        end)
    else
        local v = decV(prop, enc)
        if v ~= nil then ctx:setD(inst, prop, v) end
    end
end

local function hideTargets(root)
    local out = { root }
    for _, d in ipairs(root:GetDescendants()) do out[#out + 1] = d end
    return out
end
function Ctx:hide(inst)
    for _, d in ipairs(hideTargets(inst)) do
        if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then self:setD(d, "Transparency", 1)
        elseif d:IsA("SurfaceGui") or d:IsA("PointLight") then self:setD(d, "Enabled", false) end
    end
end
function Ctx:unhide(inst)
    for _, d in ipairs(hideTargets(inst)) do
        if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then self:unset(d, "Transparency")
        elseif d:IsA("SurfaceGui") or d:IsA("PointLight") then self:unset(d, "Enabled") end
        local pr = self.infoOf[d]
        if pr then
            for k, v in pairs(pr) do
                if k ~= "Hidden" and (k == "Transparency" or k == "Enabled") then applyProp(self, d, k, v) end
            end
        end
    end
end

function Ctx:resolveRef(ref)
    if type(ref) ~= "table" then return nil end
    if ref.kind == "id" then return self.created[ref.v] end
    return findPath(self.model, ref.v)
end

function Ctx:buildSpec(spec)
    local ok, inst = pcall(Instance.new, spec.class)
    if not ok or not inst then return nil end
    inst.Name = spec.name or spec.class
    if inst:IsA("BasePart") then
        inst.Anchored = false; inst.CanCollide = false; inst.CanTouch = false; inst.CanQuery = false; inst.Massless = true
        local base = self:resolveRef(spec.attach) or self.model:FindFirstChild("Torso") or self.model:FindFirstChild("HumanoidRootPart")
        if not base then inst:Destroy(); return nil end
        inst.Parent = self.model
        local w = Instance.new("Weld")
        w.Part0 = base; w.Part1 = inst; w.Parent = inst
        self.weldOf[inst] = w
    else
        local parent = self:resolveRef(spec.parent)
        if not parent then inst:Destroy(); return nil end
        if inst:IsA("SurfaceGui") then inst.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud end
        if inst:IsA("TextLabel") or inst:IsA("ImageLabel") then
            inst.BackgroundTransparency = 1; inst.Size = UDim2.fromScale(1, 1)
        end
        inst.Parent = parent
    end
    self.created[spec.id] = inst
    self.specIdOf[inst] = spec.id
    self.createdSet[inst] = true
    self.infoOf[inst] = spec.props
    for prop, enc in pairs(spec.props) do
        if prop ~= "Hidden" and prop ~= "Offset" and prop ~= "Rotation" then applyProp(self, inst, prop, enc) end
    end
    self:refreshJoint(inst)
    if spec.props.Hidden then self:hide(inst) end
    return inst
end



-- 2D character: an image on an invisible part (Decal / SurfaceGui / BillboardGui / Beam) -------------
function Ctx:clearFlat()
    if self.ntOrig and self.ntRef and self.ntRef.Parent then pcall(function() self.ntRef.StudsOffsetWorldSpace = self.ntOrig end) end
    self.ntOrig = nil; self.ntRef = nil
    if self.flatConn then pcall(function() self.flatConn:Disconnect() end); self.flatConn = nil end
    if self.flatHead then pcall(function() self.flatHead:Disconnect() end); self.flatHead = nil end
    if self.flatPart then pcall(function() self.flatPart:Destroy() end); self.flatPart = nil end
end

function Ctx:applyFlat(f)
    self:clearFlat()
    local model = self.model
    local base = model:FindFirstChild(f.attach or "RootPart") or model:FindFirstChild("RootPart") or model:FindFirstChild("Torso")
    if not base or not base:IsA("BasePart") then toast("2D: couldn't find a part to attach to.", "err"); return end
    if f.hideBody then
        for _, ch in ipairs(model:GetChildren()) do
            if ch:IsA("BasePart") and not LOCK[ch.Name] and not self.createdSet[ch] then self:hide(ch) end
        end
    end
    local mode = f.mode or "Decal"
    local part = Instance.new("Part")
    part.Name = "DWFlat"; part.Anchored = false; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
    part.Massless = true; part.CastShadow = false; part.Transparency = 1
    part.Size = Vector3.new(0.2, 0.2, 0.05)
    local weld = Instance.new("Weld")
    weld.Part0 = base; weld.Part1 = part; weld.Parent = part
    local img, img2, beam, a0, a1, bb
    local back = f.back or "same"   -- Decal / SurfaceGui only show on one side, so the back gets its own copy
    local flip = (f.backFlip == true) or back == "mirror"
    if back == "mirror" then back = "same" end
    if flip and mode == "Decal" and back ~= "off" then toast("Decals can't be flipped. Use SurfaceGui to flip the back image.", "info") end
    if mode == "Decal" then
        img = Instance.new("Decal"); img.Face = Enum.NormalId.Front; img.Parent = part
        if back ~= "off" then img2 = Instance.new("Decal"); img2.Face = Enum.NormalId.Back; img2.Parent = part end
    elseif mode == "SurfaceGui" then
        local g = Instance.new("SurfaceGui")
        g.Face = Enum.NormalId.Front; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        g.PixelsPerStud = 100; g.LightInfluence = 0; g.Parent = part
        img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.Size = UDim2.fromScale(1, 1); img.Parent = g
        if back ~= "off" then
            local g2 = Instance.new("SurfaceGui")
            g2.Face = Enum.NormalId.Back; g2.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            g2.PixelsPerStud = 100; g2.LightInfluence = 0; g2.Parent = part
            img2 = Instance.new("ImageLabel"); img2.BackgroundTransparency = 1
            if flip then img2.Size = UDim2.fromScale(-1, 1); img2.Position = UDim2.fromScale(1, 0)   -- see-through paper look
            else img2.Size = UDim2.fromScale(1, 1) end
            img2.Parent = g2
        end
    elseif mode == "BillboardGui" then
        bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = false; bb.LightInfluence = 0; bb.ResetOnSpawn = false; bb.Adornee = part; bb.Parent = part
        img = Instance.new("ImageLabel"); img.BackgroundTransparency = 1; img.Size = UDim2.fromScale(1, 1); img.Parent = bb
    else
        a0 = Instance.new("Attachment"); a1 = Instance.new("Attachment"); a0.Parent = part; a1.Parent = part
        beam = Instance.new("Beam")
        beam.Attachment0 = a0; beam.Attachment1 = a1; beam.TextureMode = Enum.TextureMode.Stretch
        beam.FaceCamera = true; beam.Segments = 1; beam.LightEmission = 0; beam.LightInfluence = 0
        beam.Transparency = NumberSequence.new(0); beam.Parent = part
    end
    part.Parent = model
    self.flatPart = part

    if f.pixelated ~= false and (mode == "Decal" or mode == "Beam") then
        toast("Decal and Beam always smooth images. Use SurfaceGui or BillboardGui for crisp pixels.", "info")
    end
    local function setImg(c, c2)
        c2 = c2 or c
        if mode == "Decal" then img.Texture = c; if img2 then img2.Texture = c2 end
        elseif beam then beam.Texture = c
        else img.Image = c; if img2 then img2.Image = c2 end end
    end
    local function applySize(w, h)
        if mode == "Decal" or mode == "SurfaceGui" then
            part.Size = Vector3.new(w, h, 0.05)
        elseif mode == "BillboardGui" then
            bb.Size = UDim2.fromScale(w, h)
        else
            local d = f.beamDir or "Top to bottom"
            local vertical = (d == "Top to bottom" or d == "Bottom to top")
            local wid = vertical and w or h
            local p0, p1
            if d == "Top to bottom" then p0, p1 = Vector3.new(0, h / 2, 0), Vector3.new(0, -h / 2, 0)
            elseif d == "Bottom to top" then p0, p1 = Vector3.new(0, -h / 2, 0), Vector3.new(0, h / 2, 0)
            elseif d == "Left to right" then p0, p1 = Vector3.new(-w / 2, 0, 0), Vector3.new(w / 2, 0, 0)
            else p0, p1 = Vector3.new(w / 2, 0, 0), Vector3.new(-w / 2, 0, 0) end
            a0.Position = p0; a1.Position = p1; beam.Width0 = wid; beam.Width1 = wid
        end
    end

    -- your drawings for Normal / Blink / Hurt; the game's own head texture tells us which one to show
    local content = {}
    local head = model:FindFirstChild("Head")
    local function currentState()
        if not head then return "Normal" end
        local tid = head.TextureID
        local o = self.revMap[tid] or tid
        if o ~= "" and o == self.origTex.Blink then return "Blink" end
        if o ~= "" and o == self.origTex.Hurt then return "Hurt" end
        return "Normal"
    end
    local function show()
        local c = content[currentState()] or content.Normal
        if c then setImg(c, content.Back) end
    end
    for _, st in ipairs({ "Normal", "Blink", "Hurt", "Back" }) do
        local src = f.images and f.images[st]
        if src and trim(src) ~= "" then
            resolveAsset(src, function(c, err)
                if not alive or not part.Parent then return end
                if c then content[st] = c; show() else toast("2D " .. st .. ": " .. tostring(err), "err") end
            end)
        end
    end
    if head then self.flatHead = head:GetPropertyChangedSignal("TextureID"):Connect(show) end

    local lw, lh, ld
    local function step()
        if not part.Parent or not base.Parent then return end
        local w, h = tonumber(f.width) or 4, tonumber(f.height) or 4
        if w ~= lw or h ~= lh or f.beamDir ~= ld then lw, lh, ld = w, h, f.beamDir; applySize(w, h) end
        local o = f.offset or { 0, 0, 0 }
        local r = f.rot or { 0, 0, 0 }
        local R = CFrame.Angles(math.rad(r[1] or 0), math.rad(r[2] or 0), math.rad(r[3] or 0))
        if img and img:IsA("ImageLabel") then
            local want = (f.pixelated ~= false) and Enum.ResamplerMode.Pixelated or Enum.ResamplerMode.Default
            pcall(function()
                if img.ResampleMode ~= want then img.ResampleMode = want end
                if img2 and img2.ResampleMode ~= want then img2.ResampleMode = want end
            end)
        end
        local pos
        if f.groundAlign ~= false then
            -- feet level = HumanoidRootPart bottom minus HipHeight (read-only; matched a raycast to the floor exactly)
            local hrp = model:FindFirstChild("HumanoidRootPart") or base
            local hum = model:FindFirstChildOfClass("Humanoid")
            local feetY = hrp.Position.Y - hrp.Size.Y / 2 - (hum and hum.HipHeight or 0)
            local bp = (base.CFrame * CFrame.new(o[1] or 0, 0, o[3] or 0)).Position
            pos = Vector3.new(bp.X, feetY + h / 2 + (tonumber(f.groundOffset) or 0) + (o[2] or 0), bp.Z)
        else
            pos = (base.CFrame * CFrame.new(o[1] or 0, o[2] or 0, o[3] or 0)).Position
        end
        -- NameTag: keep it above your image (Auto), or just nudge it (Manual)
        local ntRoot = model:FindFirstChild("HumanoidRootPart")
        local nt = ntRoot and ntRoot:FindFirstChild("NameTag")
        local ntMode = f.nameTag or "auto"
        if nt and nt:IsA("BillboardGui") then
            if ntMode == "off" then
                if self.ntOrig then nt.StudsOffsetWorldSpace = self.ntOrig; self.ntOrig = nil end
            else
                if not self.ntOrig then self.ntOrig = nt.StudsOffsetWorldSpace; self.ntRef = nt end
                local att = nt.Adornee
                local attY = (att and att:IsA("Attachment") and att.WorldPosition.Y) or ntRoot.Position.Y
                local lift = tonumber(f.nameLift) or 0
                local newY
                if ntMode == "manual" then
                    newY = self.ntOrig.Y + lift
                else
                    local tagH = (nt.Size.Y.Scale > 0 and nt.Size.Y.Scale) or 3
                    newY = (pos.Y + h / 2 + tagH / 2 + 0.2 + lift) - attY
                end
                local want = Vector3.new(self.ntOrig.X, newY, self.ntOrig.Z)
                if (nt.StudsOffsetWorldSpace - want).Magnitude > 0.001 then nt.StudsOffsetWorldSpace = want end
            end
        end
        local facing = f.facing or "yaw"
        local cam = workspace.CurrentCamera
        local world
        if cam and facing ~= "fixed" and (mode == "Decal" or mode == "SurfaceGui") then
            local target = cam.CFrame.Position
            if facing == "yaw" then target = Vector3.new(target.X, pos.Y, target.Z) end
            if (target - pos).Magnitude > 0.01 then world = CFrame.lookAt(pos, target) * R end
        else
            world = CFrame.new(pos) * (base.CFrame - base.CFrame.Position) * R
        end
        if world then weld.C0 = base.CFrame:ToObjectSpace(world) end
    end
    self.flatConn = RunService.RenderStepped:Connect(function()
        local ok, err = pcall(step)
        if not ok and not self.flatErr then self.flatErr = true; toast("2D error: " .. tostring(err), "err") end
    end)
end

----------------------------------------------------------------------
-- WORKING CONFIG
----------------------------------------------------------------------
local function newCfg()
    return { name = "", requires = {}, textures = {}, animations = {}, overrides = {}, added = {}, nextId = 1 }
end
local W = { cfg = newCfg(), mine = nil, sel = nil, libSel = nil, others = {} }
local ctxs = {}   -- model -> ctx (others)

local function normCfg(c)
    c = type(c) == "table" and c or {}
    local o = newCfg()
    o.name = tostring(c.name or "")
    if type(c.requires) == "table" then o.requires = c.requires end
    if type(c.textures) == "table" then o.textures = c.textures end
    if type(c.animations) == "table" then o.animations = c.animations end
    if type(c.overrides) == "table" then o.overrides = c.overrides end
    if type(c.added) == "table" then o.added = c.added end
    if type(c.flat) == "table" then o.flat = c.flat end
    o.nextId = tonumber(c.nextId) or (#o.added + 1)
    for _, s in ipairs(o.added) do if type(s.id) == "number" and s.id >= o.nextId then o.nextId = s.id + 1 end end
    return o
end

local function cfgHasContent(c)
    if c.flat or next(c.textures) or next(c.animations) or next(c.overrides) or #c.added > 0 then return true end
    return false
end

local function applyConfig(ctx, cfg)
    ctx:revertAll()
    for k, src in pairs(cfg.textures) do
        if k == "Icon" then ctx:applyIcon(src) else ctx:applyTexture(k, src) end
    end
    for n, src in pairs(cfg.animations) do ctx:applyAnim(n, src) end
    for path, props in pairs(cfg.overrides) do
        local inst = findPath(ctx.model, path)
        if inst then
            ctx.infoOf[inst] = props
            local hidden = props.Hidden
            for prop, enc in pairs(props) do
                if prop ~= "Hidden" then applyProp(ctx, inst, prop, enc) end
            end
            if hidden then ctx:hide(inst) end
        end
    end
    for _, spec in ipairs(cfg.added) do ctx:buildSpec(spec) end
    if cfg.flat and cfg.flat.enabled then ctx:applyFlat(cfg.flat) end
end

local previewDirty = true
local refreshPages = function() end
local function reapply()
    if W.mine then applyConfig(W.mine, W.cfg) end
    previewDirty = true
    refreshPages()
end

-- One-time copy of files from the OLD workspace-root folders (for example "Images" and "Textures" next to the hub's folder)
-- into TonyScriptPalace/CharacterCustomizer. The old folders are only read, never changed or deleted.
do
    local DONE = ROOT_DIR .. "/migrated_folders.txt"
    if not isF(DONE) then
        local copied = 0
        for _, f in ipairs(S.folders) do
            if isD(f) then
                local all = {}
                walkFiles(f, 0, all)
                for _, p in ipairs(all) do
                    local rel = p:gsub("\\", "/")
                    local i = rel:lower():find(f:lower() .. "/", 1, true)
                    rel = i and rel:sub(i + #f + 1) or baseName(p)
                    local dst = ROOT_DIR .. "/" .. f .. "/" .. rel
                    if not isF(dst) then
                        local sub = rel:match("^(.*)/[^/]+$")
                        ensureDir(sub and (f .. "/" .. sub) or f)
                        local d = rdF(p)
                        if d and wrF(dst, d) then copied = copied + 1 end
                    end
                end
            end
        end
        wrF(DONE, "copied " .. copied .. " files from workspace-root folders")
    end
end

----------------------------------------------------------------------
-- RULES + BINDING YOUR TOON + CAPTURE LOOP
----------------------------------------------------------------------
local function matchRule(id, isMe)
    local best, bestScore
    for _, r in ipairs(S.rules) do
        if r.enabled and r.config and r.config ~= "" and (isMe or r.scope == "all") then
            local ok, score = true, 0
            for _, k in ipairs({ "CharacterName", "ModuleName", "Skin" }) do
                local want = r[k]
                if want and want ~= "" then
                    score = score + 1
                    if tostring(id[k] or "") ~= want then ok = false; break end
                end
            end
            if ok and (not best or score > bestScore) then best, bestScore = r, score end
        end
    end
    return best
end
local function loadRuleCfg(rule)
    local data = jdec(rdF(CFG_DIR .. "/" .. rule.config .. ".json") or "")
    if type(data) ~= "table" then toast("Rule config '" .. tostring(rule.config) .. "' wasn't found.", "err"); return nil end
    return normCfg(data)
end

local boundModel, mineMode = nil, nil
local capturedModels = {}
local rootCache = {}   -- mode -> { name, n }   (read by the Sources readouts)

local function modelReady(m) return m:FindFirstChildWhichIsA("BasePart", true) ~= nil end
local function modelComplete(m)
    return m:FindFirstChild("Config") and m:FindFirstChild("Animations") and m:FindFirstChild("Head") and m:FindFirstChild("Torso")
end

local function bindMine(model, mode)
    if W.mine then W.mine:destroy() end
    W.mine = nil; W.sel = nil
    boundModel = model; mineMode = mode
    task.spawn(function()
        local t0 = os.clock()
        while alive and model.Parent and not modelReady(model) and os.clock() - t0 < 15 do task.wait(0.2) end
        local t1 = os.clock()
        while alive and model.Parent and not modelComplete(model) and os.clock() - t1 < 3 do task.wait(0.2) end
        if not alive or boundModel ~= model or not model.Parent then return end
        task.wait(0.8)   -- let the server finish skins
        if boundModel ~= model then return end
        if S.sources[mode] then captureModel(model, mode) end
        W.mine = newCtx(model, true)
        capturedModels[model] = true
        local id = identity(model)
        local applied = false
        local rule = matchRule(id, true)
        if rule then
            local rc = loadRuleCfg(rule)
            if rc then W.cfg = rc; applied = true; toast("Rule applied: '" .. rule.config .. "'.", "ok") end
        end
        if not applied and S.autoApply and S.autoConfig ~= "" then
            local data = jdec(rdF(CFG_DIR .. "/" .. S.autoConfig .. ".json") or "")
            if type(data) == "table" then
                local c = normCfg(data)
                local k = reqMismatch(c.requires, id)
                if not k then W.cfg = c; applied = true; toast("Auto-applied '" .. S.autoConfig .. "'.", "ok")
                else toast("Auto-apply skipped: needs " .. k .. " to match.", "info") end
            end
        end
        if not applied and S.keepWorking and cfgHasContent(W.cfg) then
            local k = reqMismatch(W.cfg.requires, id)
            if k then toast("Your edits were not re-applied: this config needs a different " .. k .. ".", "info") else applied = true end
        end
        if applied then applyConfig(W.mine, W.cfg) end
        previewDirty = true
        refreshPages()
    end)
end

task.spawn(function()
    while alive do
        task.wait(1)
        pcall(function()
            if W.rescan then
                W.rescan = false
                forceCaptureUntil = os.clock() + 6          -- re-read every toon once so the library picks up game updates
                for m, c in pairs(ctxs) do pcall(function() c:revertAll(); c:destroy() end); ctxs[m] = nil end
                capturedModels = {}
                boundModel = nil
            end
            local roots = rootsNow()
            table.clear(rootCache)
            for _, r in ipairs(roots) do
                local n = #r.f:GetChildren()
                local old = rootCache[r.mode]
                rootCache[r.mode] = { name = (r.f == workspace) and "workspace" or r.f.Name, n = (old and old.n or 0) + n }
            end
            local mine, myMode = findMine(roots)
            if mine and mine ~= boundModel then
                bindMine(mine, myMode)
            elseif mine then
                mineMode = myMode                               -- the model can move folders (workspace -> InGamePlayers)
            elseif boundModel and not boundModel.Parent then
                if W.mine then W.mine:destroy() end
                W.mine = nil; boundModel = nil; mineMode = nil; W.sel = nil
                refreshPages()
            end
            if S.captureOthers then
                for _, r in ipairs(roots) do
                    if S.sources[r.mode] then
                        for _, m in ipairs(r.f:GetChildren()) do
                            if m ~= boundModel and not capturedModels[m] and m:IsA("Model")
                                and (r.f ~= workspace or Players:FindFirstChild(m.Name)) and modelComplete(m) then
                                capturedModels[m] = true
                                local mode = r.mode
                                task.delay(1.2, function()
                                    if not alive or not m.Parent then return end
                                    captureModel(m, mode)
                                    local rule = matchRule(identity(m), false)
                                    if rule then
                                        local rc = loadRuleCfg(rule)
                                        if rc then
                                            local cx = ctxs[m] or newCtx(m, false)
                                            ctxs[m] = cx
                                            applyConfig(cx, rc)
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            for m in pairs(capturedModels) do if not m.Parent then capturedModels[m] = nil end end   -- the old loop never forgot a model
            for m, c in pairs(ctxs) do
                if not m.Parent then c:destroy(); ctxs[m] = nil end
            end
        end)
    end
end)

-- keeps the game from undoing your edits (only runs real work when something is actually edited)
local function enforce(c)
    for inst, props in pairs(c.desired) do
        if inst.Parent then
            for prop, v in pairs(props) do
                if prop ~= "MeshId" then
                    local ok, cur = pcall(function() return inst[prop] end)
                    if ok and cur ~= v then pcall(function() inst[prop] = v end) end
                end
            end
        end
    end
end
task.spawn(function()
    local tick = 0
    while alive do
        task.wait(0.25)
        tick = tick + 1
        pcall(function()
            if W.mine then
                if next(W.mine.desired) then enforce(W.mine) end
                if tick % 8 == 0 then W.mine:scanIcons() end
            end
            for _, c in pairs(ctxs) do if next(c.desired) then enforce(c) end end
        end)
    end
end)


--#endregion customizer-engine
--#region customizer-tab
local function targetsOf(model)
    local out = {}
    local function visit(inst, depth)
        local kids = inst:GetChildren()
        table.sort(kids, function(a, b) return a.Name:lower() < b.Name:lower() end)
        for _, k in ipairs(kids) do
            local ok = false
            if k:IsA("BasePart") then ok = not LOCK[k.Name]
            elseif k:IsA("Decal") or k:IsA("Texture") or k:IsA("SurfaceGui") or k:IsA("PointLight") then ok = true
            elseif k:IsA("TextLabel") or k:IsA("ImageLabel") then ok = inst:IsA("SurfaceGui") end
            if ok and k.Name ~= "DWPreviewPart" then
                out[#out + 1] = { inst = k, depth = depth }
                if k:IsA("BasePart") or k:IsA("SurfaceGui") then visit(k, depth + 1) end
            end
        end
    end
    visit(model, 0)
    return out
end

local function editProp(inst, prop, enc)
    local ctx = W.mine
    if not ctx then return end
    local props = ctx.infoOf[inst]
    if not props then
        local path = pathOf(ctx.model, inst)
        W.cfg.overrides[path] = W.cfg.overrides[path] or {}
        props = W.cfg.overrides[path]
        ctx.infoOf[inst] = props
    end
    props[prop] = enc
    applyProp(ctx, inst, prop, enc)
    previewDirty = true
end

local function curEnc(inst, prop)
    local ctx = W.mine
    local props = ctx and ctx.infoOf[inst]
    if props and props[prop] ~= nil then return props[prop] end
    if prop == "Offset" or prop == "Rotation" then return { 0, 0, 0 } end
    return encInst(inst, prop)
end


----------------------------------------------------------------------
-- CUSTOMIZER TAB  (sections built from the hub's own control types, so it follows whichever skin is active)
----------------------------------------------------------------------
local P = {
    texSlot = "Normal", texSrc = "", animName = nil, animSrc = "", part = nil, cfgSel = "", cfgName = "", folderIn = "",
    spin = false, zoom = 1, pv = nil, panMode = false,
}
local texBox, animBox
local MODES = { "Lobby", "Game", "Roleplay" }
local function texSlots()            -- every face slot this toon has (Normal, Blink, Hurt, Face, Transform...), plus the voting icon
    local out, seen = {}, {}
    local function add(k) if not seen[k] then seen[k] = true; out[#out + 1] = k end end
    for _, k in ipairs({ "Normal", "Blink", "Hurt" }) do if W.mine and W.mine.origTex[k] ~= nil then add(k) end end
    if W.mine then
        local rest = {}
        for k in pairs(W.mine.origTex) do if not seen[k] then rest[#rest + 1] = k end end
        table.sort(rest)
        for _, k in ipairs(rest) do add(k) end
    end
    if #out == 0 then for _, k in ipairs({ "Normal", "Blink", "Hurt" }) do add(k) end end
    add("Icon")
    return out
end

local function need()
    if not W.mine then toast("No character found yet. Join the lobby, a match or Roleplay Mode.", "err"); return false end
    return true
end
local function short(s, n)
    s = tostring(s); n = n or 30
    if #s > n then return s:sub(1, n - 3) .. "..." end
    return s
end
local function entriesFor(filter)
    local out = {}
    for _, e in ipairs(libEntries()) do
        if filter == "All" or (type(e.srcs) == "table" and e.srcs[filter]) then out[#out + 1] = e end
    end
    return out
end
local function toonOpts(kind, filter)       -- labels, map
    local labels, map = {}, {}
    for _, e in ipairs(entriesFor(filter or "All")) do
        local ok = (kind == "tex" and next(e.tex) ~= nil) or (kind == "anim" and next(e.anims) ~= nil) or kind == nil
        if ok then local l = libLabel(e); labels[#labels + 1] = l; map[l] = e end
    end
    return labels, map
end
local function fileOpts(kind) return fileOptions(kind) end      -- entries starting with "(" are hints, not files
local function cfgList()
    local out = {}
    for _, p in ipairs(lsD(CFG_DIR)) do
        local n = baseName(p)
        if n:lower():match("%.json$") then out[#out + 1] = (n:gsub("%.[jJ][sS][oO][nN]$", "")) end
    end
    table.sort(out, function(a, b) return a:lower() < b:lower() end)
    return out
end
local function curIdentity() return identity(W.mine and W.mine.model) end
local function loadCfgFile(n, force)
    local data = jdec(rdF(CFG_DIR .. "/" .. n .. ".json") or "")
    if type(data) ~= "table" then return false, "Couldn't read '" .. n .. "'." end
    local c = normCfg(data)
    if not force then
        local k, want, have = reqMismatch(c.requires, curIdentity())
        if k then return false, "'" .. n .. "' needs " .. k .. " = " .. tostring(want) .. " (you are " .. tostring(have) .. "). Use Force Load to ignore." end
    end
    W.cfg = c
    return true
end

-- status ---------------------------------------------------------------
local function statusLine()
    if W.mine then
        local id = identity(W.mine.model)
        return "safe", "Editing " .. tostring(id.CharacterName or "?") .. "  |  module " .. tostring(id.ModuleName or "?")
            .. "  |  skin " .. tostring(id.Skin or "default") .. "  |  source " .. tostring(mineMode or "?")
    end
    return "warn", "Waiting for your character (join the lobby, a match or Roleplay Mode)..."
end

-- The game keeps many finished toon models in memory (parented to nil). Capturing them fills the library without having to
-- meet every toon in a match.
local function scanMemory()
    local ok, nils = pcall(getnilinstances)
    if not ok or type(nils) ~= "table" then return toast("This executor cannot list hidden instances.", "err") end
    toast("Scanning the game's memory for toon models...", "info")
    task.spawn(function()
        local function count() local n = 0; for _ in pairs(Library) do n = n + 1 end; return n end
        local before, seen = count(), 0
        local mode = PLACE_MODE[game.PlaceId] or "Roleplay"
        for _, m in ipairs(nils) do
            if not alive then return end
            if m:IsA("Model") and modelComplete(m) then
                pcall(captureModel, m, mode)
                seen = seen + 1
                if seen % 4 == 0 then task.wait() end
            end
        end
        toast(string.format("Checked %d hidden toon models: %d new toons added to the library.", seen, count() - before), "ok")
        tspRefresh()
    end)
end
-- textures -------------------------------------------------------------
local function texNow() return trim((texBox and texBox.Parent) and texBox.Text or P.texSrc) end
local function texApply(src)
    if not need() then return end
    src = trim(src or "")
    if src == "" then return toast("Type an id, link or file first.", "err") end
    W.cfg.textures[P.texSlot] = src
    if P.texSlot == "Icon" then W.mine:applyIcon(src) else W.mine:applyTexture(P.texSlot, src) end
    toast(P.texSlot .. " replaced.", "ok"); tspRefresh()
end
local function iconOpts()
    local out = {}
    for _, t in ipairs(towerIcons()) do out[#out + 1] = "Toon icon: " .. t.name end
    for _, e in ipairs(libEntries()) do if e.icon then out[#out + 1] = "Seen: " .. libLabel(e) end end
    return out
end

-- animations -----------------------------------------------------------
local function animNames()
    local t = {}
    if W.mine then for n in pairs(W.mine.origAnim) do t[#t + 1] = n end end
    table.sort(t)
    return t
end
local function animNow() return trim((animBox and animBox.Parent) and animBox.Text or P.animSrc) end

-- parts ----------------------------------------------------------------
local function partMap()
    local labels, map = {}, {}
    if W.mine then
        for _, t in ipairs(targetsOf(W.mine.model)) do
            local l = pathOf(W.mine.model, t.inst) .. " (" .. t.inst.ClassName .. ")"
            labels[#labels + 1] = l; map[l] = t.inst
        end
    end
    return labels, map
end
local function partInst() local p = P.part; if p and p.Parent and W.mine and p:IsDescendantOf(W.mine.model) then return p end end
local function partProps(inst)
    local ctx = W.mine
    return ctx and (ctx.infoOf[inst] or W.cfg.overrides[pathOf(ctx.model, inst)]) or nil
end
local function colorProp(inst) return inst:IsA("BasePart") and "Color" or ((inst:IsA("Decal") or inst:IsA("Texture")) and "Color3" or nil) end
local function hasTransp(inst) return inst:IsA("BasePart") or inst:IsA("Decal") or inst:IsA("Texture") end

-- 2D character ---------------------------------------------------------
local function flatDefaults()
    return {
        enabled = false, mode = "Decal", facing = "yaw", beamDir = "Top to bottom", attach = "RootPart",
        images = { Normal = "", Blink = "", Hurt = "", Back = "" }, width = 4, height = 4,
        offset = { 0, 0, 0 }, rot = { 0, 0, 0 }, hideBody = true, groundAlign = true, groundOffset = 0, pixelated = true, back = "same", backFlip = false, nameTag = "auto", nameLift = 0,
    }
end
local FACING = { yaw = "Camera (yaw only)", full = "Camera (full)", fixed = "Fixed" }
local FACING_REV = { ["Camera (yaw only)"] = "yaw", ["Camera (full)"] = "full", ["Fixed"] = "fixed" }
local function flat() if not W.cfg.flat then W.cfg.flat = flatDefaults() end; return W.cfg.flat end

----------------------------------------------------------------------
local function buildPage()
    local secs = {}

    -- 0. PREVIEW (the viewport is only built while this section is expanded) ------
    secs[#secs + 1] = { title = "Preview", collapsed = true, controls = {
        { t = "preview", height = 260,
            model = function() return W.mine and W.mine.model end,
            dirty = function() local d = previewDirty; previewDirty = false; return d end,
            spin = function() return P.spin end, zoom = function() return P.zoom end, panMode = function() return P.panMode end, bind = function(ctl) P.pv = ctl end },
        { t = "text", text = "Drag to rotate. Hold the middle mouse button and drag (or hold Shift and drag) to move the view around. Scroll to zoom. It refreshes on its own when you change something."},
        { t = "toggle", text = "Drag Moves Instead Of Rotating", get = function() return P.panMode end, set = function(v) P.panMode = v end },
        { t = "toggle", text = "Auto-Spin", get = function() return P.spin end, set = function(v) P.spin = v end },
        { t = "slider", text = "Zoom", min = 0.3, max = 3, dec = 2, get = function() return P.zoom end,
            set = function(v) P.zoom = v; if P.pv then P.pv.setZoom(v) end end },
        { t = "buttons", items = { { label = "Reset View", fn = function() P.zoom = 1; if P.pv then P.pv.reset() end; tspRefresh() end } } },
        { t = "text", text = "If the preview stays blank, your Roblox client isn't drawing viewports right now (in testing, even a plain ball in a fresh viewport stayed invisible). Nothing else in the Customizer needs it, so you can shrug and move on."},
    } }

    -- 1. STATUS -------------------------------------------------------
    secs[#secs + 1] = { title = "Status", collapsed = true, controls = {
        { t = "livetext", get = statusLine },
        { t = "text", text = "Everything here is cosmetic and only on your client. Nothing touches the Humanoid, RootPart, speed or any remote, so it's strictly for show."},
        { t = "buttons", items = {
            { label = "Rescan Models", fn = function() W.rescan = true; toast("Rescanning every model source...", "info") end },
            { label = "Revert Everything", style = "red", confirm = true, fn = function()
                W.cfg = newCfg(); if W.mine then W.mine:revertAll() end; reapply(); toast("Everything reverted.", "ok") end },
        } },
    } }

    -- 2. SOURCES ------------------------------------------------------
    local src = {
        { t = "text", text = "Pick where toons get collected from. Your own toon always binds wherever the game puts it."},
    }
    local where = { Lobby = "Lobby  (workspace.Players)", Game = "Game  (workspace.InGamePlayers)", Roleplay = "Roleplay Mode  (auto-detected)" }
    for _, m in ipairs(MODES) do
        src[#src + 1] = { t = "toggle", text = "Collect From " .. where[m], get = function() return S.sources[m] end,
            set = function(v) S.sources[m] = v; saveSettings() end }
    end
    for _, m in ipairs(MODES) do
        src[#src + 1] = { t = "readout", text = m .. " Folder Now", get = function()
            local c = rootCache[m]
            return c and (c.name .. "  (" .. c.n .. ")") or "not here right now"
        end }
    end
    src[#src + 1] = { t = "toggle", text = "Collect Other Players' Toons", get = function() return S.captureOthers end,
        set = function(v) S.captureOthers = v; saveSettings() end }
    secs[#secs + 1] = { title = "Model Sources", collapsed = true, controls = src }

    -- 4. TEXTURES -----------------------------------------------------
    secs[#secs + 1] = { title = "Textures", collapsed = true, controls = {
        { t = "text", text = "Change what your toon looks like. Face textures swap with blinking and hurting automatically."},
        { t = "dropdown", text = "Slot", get = function() return P.texSlot end, options = function() return texSlots() end,
            set = function(o) P.texSlot = o; tspRefresh() end },
        { t = "readout", text = "Current", get = function() local c = W.cfg.textures[P.texSlot]; return c and short(c, 26) or "game default" end },
        { t = "input", text = "Source", placeholder = "rbxassetid / link / file",
            get = function() return P.texSrc end, set = function(txt) P.texSrc = trim(txt) end, bind = function(tb) texBox = tb end },
        { t = "dropdown", text = "Pick A File", get = function() return "Files..." end, options = function() return fileOpts("img") end,
            set = function(o) if o:sub(1, 1) ~= "(" then P.texSrc = o; if texBox and texBox.Parent then texBox.Text = o end end end },
        { t = "dropdown", text = "Texture Set From Toon", get = function() return "Toons..." end,
            options = function() local l = toonOpts("tex"); if #l == 0 then return { "(nothing captured yet)" } end; return l end,
            set = function(o)
                local _, map = toonOpts("tex"); local e = map[o]
                if not e or not need() then return end
                for k, v in pairs(e.tex) do W.cfg.textures[k] = v end
                reapply(); toast("Texture set applied.", "ok")
            end },
        { t = "dropdown", text = "Voting Icon From", get = function() return "Icons..." end,
            options = function() local l = iconOpts(); if #l == 0 then return { "(no icons found yet)" } end; return l end,
            set = function(o)
                local found
                if o:sub(1, 11) == "Toon icon: " then
                    for _, t in ipairs(towerIcons()) do if t.name == o:sub(12) then found = t.icon end end
                elseif o:sub(1, 6) == "Seen: " then
                    for _, e in ipairs(libEntries()) do if libLabel(e) == o:sub(7) then found = e.icon end end
                end
                if found and need() then W.cfg.textures.Icon = found; W.mine:applyIcon(found); toast("Voting icon replaced.", "ok"); tspRefresh() end
            end },
        { t = "buttons", items = {
            { label = "Apply", style = "green", fn = function() texApply(texNow()) end },
            { label = "Restore Slot", fn = function() W.cfg.textures[P.texSlot] = nil; reapply(); toast(P.texSlot .. " restored.", "ok") end },
            { label = "Restore All", style = "red", confirm = true, fn = function() W.cfg.textures = {}; reapply(); toast("All textures restored.", "ok") end },
        } },
    } }

    -- 5. ANIMATIONS ---------------------------------------------------
    secs[#secs + 1] = { title = "Animations", collapsed = true, controls = {
        { t = "text", text = "Swap animations one at a time, or grab a whole pack from another toon. Files: .rbxm with a KeyframeSequence (experimental, so keep expectations reasonable)."},
        { t = "toggle", text = "Keep Animations Local", get = function() return S.localAnims end,
            set = function(v) S.localAnims = v; saveSettings(); reapply(); toast(v and "Animations are now local: only you see them." or "Animations are now replicated: everyone sees them.", "info") end },
        { t = "text", text = "On: only you see your custom animations and everyone else keeps seeing your normal ones. Off: the game plays them for everyone, which can look broken to others if the rig doesn't match (hello, T-pose)."},
        { t = "dropdown", text = "Animation", get = function() return P.animName or "Pick an animation..." end,
            options = function() local n = animNames(); if #n == 0 then return { "(no character found yet)" } end; return n end,
            set = function(o) if W.mine and W.mine.origAnim[o] then P.animName = o; tspRefresh() end end },
        { t = "readout", text = "Current", get = function()
            local n = P.animName
            if not n then return "-" end
            local c = W.cfg.animations[n]
            return c and short(c, 26) or "game default"
        end },
        { t = "input", text = "Source", placeholder = "rbxassetid / .rbxm file",
            get = function() return P.animSrc end, set = function(txt) P.animSrc = trim(txt) end, bind = function(tb) animBox = tb end },
        { t = "dropdown", text = "Pick A File", get = function() return "Files..." end, options = function() return fileOpts("anim") end,
            set = function(o) if o:sub(1, 1) ~= "(" then P.animSrc = o; if animBox and animBox.Parent then animBox.Text = o end end end },
        { t = "dropdown", text = "This Animation From Toon", get = function() return "Toons..." end,
            options = function()
                local out = {}
                if P.animName then for _, e in ipairs(libEntries()) do if e.anims[P.animName] then out[#out + 1] = libLabel(e) end end end
                if #out == 0 then return { "(pick an animation first)" } end
                return out
            end,
            set = function(o)
                local n = P.animName
                if not n or not need() then return end
                for _, e in ipairs(libEntries()) do
                    if libLabel(e) == o and e.anims[n] then W.cfg.animations[n] = e.anims[n]; W.mine:applyAnim(n, e.anims[n]); toast(n .. " replaced.", "ok"); tspRefresh(); return end
                end
            end },
        { t = "buttons", items = {
            { label = "Apply", style = "green", fn = function()
                local n, s = P.animName, animNow()
                if not n then return toast("Pick an animation first.", "err") end
                if s == "" then return toast("Type an id or file first.", "err") end
                if not need() then return end
                W.cfg.animations[n] = s; W.mine:applyAnim(n, s); toast(n .. " replaced.", "ok"); tspRefresh()
            end },
            { label = "Restore", fn = function()
                if P.animName then W.cfg.animations[P.animName] = nil; reapply(); toast(P.animName .. " restored.", "ok") end
            end },
        } },
        { t = "dropdown", text = "Whole Pack From Toon", get = function() return "Toons..." end,
            options = function() local l = toonOpts("anim"); if #l == 0 then return { "(nothing captured yet)" } end; return l end,
            set = function(o)
                local _, map = toonOpts("anim"); local e = map[o]
                if not e or not need() then return end
                local n = 0
                for name, id in pairs(e.anims) do if W.mine.origAnim[name] then W.cfg.animations[name] = id; n = n + 1 end end
                reapply(); toast("Animation pack applied (" .. n .. " animations).", "ok")
            end },
        { t = "buttons", items = {
            { label = "Restore All Animations", style = "red", confirm = true, fn = function() W.cfg.animations = {}; reapply(); toast("All animations restored.", "ok") end },
        } },
    } }

    -- 6. PARTS --------------------------------------------------------
    do
        local ctl = {
            { t = "text", text = "Hide a part, fade it or recolor it. Pick one from your toon first."},
            { t = "dropdown", text = "Part", get = function() local p = partInst(); return p and short(pathOf(W.mine.model, p), 26) or "Pick a part..." end,
                options = function() local l = partMap(); if #l == 0 then return { "(no character found yet)" } end; return l end,
                set = function(o) local _, map = partMap(); if map[o] then P.part = map[o]; tspRefresh() end end },
        }
        local inst = partInst()
        if inst then
            ctl[#ctl + 1] = { t = "toggle", text = "Hidden", get = function() local pr = partProps(inst); return pr and pr.Hidden and true or false end,
                set = function(v) editProp(inst, "Hidden", v and true or nil) end }
            if hasTransp(inst) then
                ctl[#ctl + 1] = { t = "slider", text = "Transparency", min = 0, max = 1, dec = 2,
                    get = function() local v = curEnc(inst, "Transparency"); return tonumber(v) or 0 end,
                    set = function(v) editProp(inst, "Transparency", v) end }
            end
            local cp = colorProp(inst)
            if cp then
                ctl[#ctl + 1] = { t = "color", text = "Color", rebuild = false, rainbow = false, palette = false,
                    get = function() local ok, c = pcall(function() return inst[cp] end); return (ok and c) or Color3.new(1, 1, 1) end,
                    set = function(v) editProp(inst, cp, "#" .. v:ToHex()) end }
            end
            ctl[#ctl + 1] = { t = "buttons", items = {
                { label = "Reset This Part", fn = function()
                    if not W.mine then return end
                    W.cfg.overrides[pathOf(W.mine.model, inst)] = nil
                    reapply(); toast("Part reset.", "ok")
                end },
                { label = "Reset All Parts", style = "red", confirm = true, fn = function() W.cfg.overrides = {}; reapply(); toast("All part edits reset.", "ok") end },
            } }
        end
        secs[#secs + 1] = { title = "Parts", collapsed = true, controls = ctl }
    end

    -- 7. 2D CHARACTER -------------------------------------------------
    do
        local f = W.cfg.flat or flatDefaults()
        local function imgRow(st)
            return { t = "input", text = st .. " Image", placeholder = "rbxassetid / link / file",
                get = function() return (W.cfg.flat and W.cfg.flat.images and W.cfg.flat.images[st]) or "" end,
                set = function(txt) local fl = flat(); fl.images = fl.images or {}; fl.images[st] = trim(txt); if fl.enabled then reapply() end end }
        end
        secs[#secs + 1] = { title = "2D Character", collapsed = true, controls = {
            { t = "text", text = "Draw your toon yourself: your images replace the 3D body. Blink and Hurt images show up automatically."},
            { t = "toggle", text = "2D Character", get = function() return W.cfg.flat and W.cfg.flat.enabled or false end,
                set = function(v) flat().enabled = v; reapply() end },
            { t = "dropdown", text = "Mode", get = function() return f.mode end, options = function() return { "Decal", "SurfaceGui", "BillboardGui", "Beam" } end,
                set = function(o) flat().mode = o; reapply(); tspRefresh() end },
            { t = "dropdown", text = "Facing", get = function() return FACING[f.facing] or "Camera (yaw only)" end,
                options = function() return { "Camera (yaw only)", "Camera (full)", "Fixed" } end,
                set = function(o) flat().facing = FACING_REV[o] or "yaw"; reapply(); tspRefresh() end },
            { t = "toggle", text = "Hide Body", get = function() return f.hideBody ~= false end, set = function(v) flat().hideBody = v; reapply() end },
            imgRow("Normal"), imgRow("Blink"), imgRow("Hurt"),
            { t = "slider", text = "Width", min = 0.5, max = 20, dec = 2, get = function() return tonumber(f.width) or 4 end, set = function(v) flat().width = v end },
            { t = "slider", text = "Height", min = 0.5, max = 20, dec = 2, get = function() return tonumber(f.height) or 4 end, set = function(v) flat().height = v end },
            { t = "toggle", text = "Feet On Ground", get = function() return f.groundAlign ~= false end, set = function(v) flat().groundAlign = v end },
            { t = "toggle", text = "Pixelated", get = function() return f.pixelated ~= false end, set = function(v) flat().pixelated = v end },
        } }
    end

    -- 8. CONFIGS ------------------------------------------------------
    secs[#secs + 1] = { title = "Customizer Configs", collapsed = true, controls = {
        { t = "text", text = "These save your toon edits (model, textures, animations, parts, 2D). Hub configs in the Configs tab only remember which one is loaded."},
        { t = "dropdown", text = "Saved Configs", get = function() return P.cfgSel ~= "" and P.cfgSel or "Pick a config..." end,
            options = function() local l = cfgList(); if #l == 0 then return { "(none saved yet)" } end; return l end,
            set = function(o) if o:sub(1, 1) ~= "(" then P.cfgSel = o; P.cfgName = o; tspRefresh() end end },
        { t = "input", text = "Name", placeholder = "config name", get = function() return P.cfgName end, set = function(txt) P.cfgName = trim(txt) end },
        { t = "buttons", items = {
            { label = "Save", style = "green", fn = function()
                local n = sanitize(trim(P.cfgName))
                if n == "" then return toast("Type a config name first.", "err") end
                W.cfg.name = n
                local js = jenc(W.cfg)
                if js and wrF(CFG_DIR .. "/" .. n .. ".json", js) then P.cfgSel = n; toast("Saved '" .. n .. "'.", "ok"); tspRefresh()
                else toast("Couldn't write the config file.", "err") end
            end },
            { label = "Load", style = "blue", fn = function()
                local n = P.cfgSel ~= "" and P.cfgSel or trim(P.cfgName)
                if n == "" then return toast("Pick a config to load.", "err") end
                local ok, err = loadCfgFile(n, false)
                if not ok then return toast(err, "err") end
                reapply(); toast("Loaded '" .. n .. "'.", "ok")
            end },
            { label = "Force Load", fn = function()
                local n = P.cfgSel ~= "" and P.cfgSel or trim(P.cfgName)
                if n == "" then return toast("Pick a config to load.", "err") end
                local ok, err = loadCfgFile(n, true)
                if not ok then return toast(err, "err") end
                reapply(); toast("Force-loaded '" .. n .. "'.", "ok")
            end },
        } },
        { t = "buttons", items = {
            { label = "New Blank", fn = function() W.cfg = newCfg(); P.cfgName = ""; reapply(); toast("Started a blank config.", "ok") end },
            { label = "Use For Auto-Apply", fn = function()
                local n = P.cfgSel ~= "" and P.cfgSel or trim(P.cfgName)
                if n == "" then return toast("Pick a config first.", "err") end
                S.autoConfig = n; saveSettings(); toast("Auto-apply config is now '" .. n .. "'.", "ok"); tspRefresh()
            end },
            { label = "Delete", style = "red", confirm = true, fn = function()
                local n = P.cfgSel ~= "" and P.cfgSel or trim(P.cfgName)
                if n == "" or not isF(CFG_DIR .. "/" .. n .. ".json") then return toast("Pick an existing config to delete.", "err") end
                dlF(CFG_DIR .. "/" .. n .. ".json")
                if S.autoConfig == n then S.autoConfig = ""; saveSettings() end
                P.cfgSel = ""; P.cfgName = ""; toast("Deleted '" .. n .. "'.", "ok"); tspRefresh()
            end },
        } },
        { t = "toggle", text = "Auto-Apply On Join", get = function() return S.autoApply end, set = function(v) S.autoApply = v; saveSettings() end },
        { t = "readout", text = "Auto-Apply Config", get = function()
            if S.autoConfig == "" then return "(none)" end
            return isF(CFG_DIR .. "/" .. S.autoConfig .. ".json") and S.autoConfig or (S.autoConfig .. "  (file missing)")
        end },
        { t = "buttons", items = { { label = "Clear Auto-Apply Config", fn = function()
            S.autoConfig = ""; saveSettings(); toast("Auto-apply config cleared: nothing will be applied on join.", "ok"); tspRefresh()
        end } } },
        { t = "toggle", text = "Keep Edits Between Rounds", get = function() return S.keepWorking end, set = function(v) S.keepWorking = v; saveSettings() end },
        { t = "toggle", text = "Only Load For This Toon", get = function() return next(W.cfg.requires) ~= nil end,
            set = function(v)
                if v then
                    local id = curIdentity()
                    for _, k in ipairs({ "CharacterName", "ModuleName", "Skin" }) do if id[k] then W.cfg.requires[k] = tostring(id[k]) end end
                else W.cfg.requires = {} end
            end },
    } }

    -- 9. FILES & LIBRARY ---------------------------------------------
    local fl = {
        { t = "text", text = "Folders live inside TonyScriptPalace/CharacterCustomizer in your executor's workspace (Images, Textures and Animations are made for you). Drop files in and they show up in every Pick A File menu. Images: png, jpg, webp. Animations: rbxm."},
        { t = "input", text = "Add Folder", placeholder = "name, like Images/Faces, then Enter", get = function() return P.folderIn end,
            set = function(txt, enter)
                P.folderIn = trim(txt)
                if enter and P.folderIn ~= "" then
                    local f = cleanFolder(P.folderIn)           -- always relative to CharacterCustomizer
                    if f == "" then return toast("Type a folder name, like Images/Faces.", "err") end
                    if not table.find(S.folders, f) then
                        ensureDir(f)
                        S.folders[#S.folders + 1] = f; saveSettings()
                        toast("Added folder '" .. f .. "' inside CharacterCustomizer.", "ok")
                    end
                    P.folderIn = ""; tspRefresh()
                end
            end },
        { t = "text", text = #S.folders == 0 and "No folders added yet." or ("Your folders (inside CharacterCustomizer): " .. table.concat(S.folders, ",  "))},
    }
    if #S.folders > 0 then
        fl[#fl + 1] = { t = "dropdown", text = "Remove Folder", get = function() return "Pick a folder..." end,
            options = function() return S.folders end,
            set = function(o) local i = table.find(S.folders, o); if i then table.remove(S.folders, i); saveSettings(); tspRefresh() end end }
    end
    fl[#fl + 1] = { t = "text", text = "Scan Game Memory digs through toon models the game keeps hidden in memory and saves them to your library (experimental, can take a few seconds)."}
    fl[#fl + 1] = { t = "buttons", items = { { label = "Scan Game Memory For Toons", fn = scanMemory } } }
    fl[#fl + 1] = { t = "dropdown", text = "Remove Toon From Library", get = function() return "Pick a toon..." end,
        options = function() local l = toonOpts(nil, "All"); if #l == 0 then return { "(library is empty)" } end; return l end,
        set = function(o)
            local _, map = toonOpts(nil, "All")
            local e = map[o]
            if not e then return end
            Library[e.key] = nil
            dlF(LIB_DIR .. "/" .. sanitize(e.key) .. ".json")
            tspRefresh()
        end }
    fl[#fl + 1] = { t = "readout", text = "Toons In Library", get = function() local n = 0; for _ in pairs(Library) do n = n + 1 end; return n end }
    fl[#fl + 1] = { t = "buttons", items = {
        { label = "Clear Library", style = "red", confirm = true, fn = function()
            for k in pairs(Library) do Library[k] = nil end
            for _, p in ipairs(lsD(LIB_DIR)) do if baseName(p):lower():match("%.json$") then dlF(p) end end
            W.libSel = nil; toast("Library cleared. It refills as you play.", "ok"); tspRefresh()
        end },
    } }
    secs[#secs + 1] = { title = "Files & Library", collapsed = true, controls = fl }

    return secs
end

----------------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------------
refreshPages = function() tspRefresh() end

local API = { build = buildPage, working = W }
function API.serialize()
    return { config = (W.cfg.name ~= "" and W.cfg.name) or nil,
        settings = { autoApply = S.autoApply, autoConfig = S.autoConfig, keepWorking = S.keepWorking, localAnims = S.localAnims, captureOthers = S.captureOthers,
            sources = { Lobby = S.sources.Lobby, Game = S.sources.Game, Roleplay = S.sources.Roleplay } } }
end
function API.apply(d)
    if type(d) == "table" and type(d.settings) == "table" then
        local t = d.settings
        for _, k in ipairs({ "autoApply", "keepWorking", "localAnims", "captureOthers" }) do
            if type(t[k]) == "boolean" then S[k] = t[k] end
        end
        if type(t.autoConfig) == "string" then S.autoConfig = t.autoConfig end
        if type(t.sources) == "table" then
            for _, k in ipairs({ "Lobby", "Game", "Roleplay" }) do if type(t.sources[k]) == "boolean" then S.sources[k] = t.sources[k] end end
        end
        pcall(saveSettings)
    end
    if type(d) == "table" and type(d.config) == "string" and isF(CFG_DIR .. "/" .. d.config .. ".json") then
        if loadCfgFile(d.config, true) then reapply() end
    end
end
function API.Destroy()
    alive = false
    pcall(saveSettings)
    pcall(function() if W.mine then W.mine:revertAll(); W.mine:destroy() end end)
    for _, c in pairs(ctxs) do pcall(function() c:revertAll(); c:destroy() end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end
return API
end)(function(m, k) toast(m, k) end, function() if UI.current == "customizer" then refreshPage() end end)


--#endregion customizer-tab
--#region sound-engine
----------------------------------------------------------------------
-- SOUND ENGINE  (music player + sound effects + game sound replacement)
-- Lives at UI.snd (no new top-level locals). The Sound tab (page-sound region) talks to it through that table.
----------------------------------------------------------------------
UI.snd = (function()   -- one function scope: the main script is close to Lua's 200-locals limit, so this region adds NO top-level locals
local Snd = { K = {} }
    local getasset = getcustomasset or getsynasset
    local httpReq  = request or http_request or (syn and syn.request) or (http and http.request)
    local SoundService = game:GetService("SoundService")
    local dead = false

    -- files -----------------------------------------------------------
    local ROOT       = "TonyScriptPalace/Sound"
    local SETUP_DIR  = ROOT .. "/Setups"
    local CACHE_DIR  = ROOT .. "/Cache"
    local FILES_DIR  = ROOT .. "/Files"
    local SETTINGS_F = ROOT .. "/settings.json"
    local AUTOSAVE_F = ROOT .. "/autosave.json"
    local FILE_DIRS  = { "Music", "Sounds", FILES_DIR }   -- folders (inside the executor workspace) that sources can point into
    local EXTS = { "mp3", "ogg", "wav", "flac" }

    local function isF(p) return isfile and try(isfile, p) or false end
    local function isD(p) return isfolder and try(isfolder, p) or false end
    local function mkD(p) if makefolder and not isD(p) then pcall(makefolder, p) end end
    local function rdF(p) return readfile and try(readfile, p) or nil end
    local function wrF(p, c) if writefile then return (pcall(writefile, p, c)) end; return false end
    local function lsD(p) return listfiles and try(listfiles, p) or {} end
    local function dlF(p) if delfile then pcall(delfile, p) end end
    local function baseName(p) p = tostring(p):gsub("\\", "/"); return p:match("([^/]+)$") or p end
    local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
    local function jenc(t) local ok, r = pcall(HttpService.JSONEncode, HttpService, t); return ok and r or nil end
    local function jdec(s) local ok, r = pcall(HttpService.JSONDecode, HttpService, s); return ok and r or nil end
    local function fmtTime(s) s = math.floor(s or 0); return string.format("%d:%02d", s // 60, s % 60) end

    mkD("TonyScriptPalace"); mkD(ROOT); mkD(SETUP_DIR); mkD(CACHE_DIR); mkD(FILES_DIR); mkD("Music"); mkD("Sounds")

    local holder = Instance.new("Folder")
    holder.Name = "TSP_SoundHolder"
    holder.Parent = guiParent()

    -- state -----------------------------------------------------------
    local st = {
        enabled = false, gameOn = false, sfxOn = false, emitOn = false,
        volume = 1, pitch = 1, sfxVol = 1,
        transition = "Crossfade", fadeTime = 2,
        offMode = "Stop",                       -- what a song does while it is NOT the one playing: Stop | Pause | Mute
        muteGame = false, muteOnlyMine = false, muteKeywords = "music,theme,bgm,ost,chase,soundtrack",
        songs = {}, sfx = {}, rules = {}, emitters = {}, mixer = {},
        spy = false, lastSetup = "",
    }
    Snd.st = st
    local rt = {}            -- runtime info per item id: { status, asset, assets, err, info, len, token, ended }
    Snd.rt = rt
    local voices = {}        -- song id -> { sound, gain }
    local songMap = {}
    local seenRooms, seenSet = {}, {}
    local previewId, winner = nil, nil
    local metSet = {}
    local ractive = {}       -- rule id -> bool (are its conditions met right now)
    local srt = {}           -- sfx runtime: id -> { last, nextAt, cdUntil }
    local dirty = false
    local idCounter = 0
    local function newId() idCounter += 1; return "i" .. idCounter .. "_" .. math.random(1000, 9999) end
    local function markDirty() dirty = true end
    Snd.markDirty = markDirty
    local function rebuildMap() songMap = {}; for _, s in ipairs(st.songs) do songMap[s.id] = s end end

    -- constants shared with the Sound tab ------------------------------
    local K = Snd.K
    K.SOURCES   = { "Info", "My Config", "My Stats", "My Model", "My Game Stats", "Room", "Custom" }
    K.OPS       = { "==", "~=", ">", ">=", "<", "<=", "contains", "not contains", "is true", "is false", "exists", "missing" }
    K.NOVAL     = { ["is true"] = true, ["is false"] = true, exists = true, missing = true }
    K.ROOM_OPS  = { "is", "is not", "contains", "not contains" }
    K.T_MODES   = { "chasing me", "not chasing me", "chasing anyone", "chasing player", "within range", "present in room", "not in room" }
    K.TRANS_ALL = { "Instant", "Fade", "Crossfade" }
    K.TRANS_SONG = { "Global", "Instant", "Fade", "Crossfade" }
    K.OFF_ALL   = { "Stop", "Pause", "Mute" }
    K.OFF_SONG  = { "Global", "Stop", "Pause", "Mute" }
    K.OFF_HELP  = { Stop = "Stop (restart from 0 next time)", Pause = "Pause (resume where it left off)", Mute = "Mute (keeps running silently, so it is in sync when it returns)" }
    K.TRIGGERS  = { "Rising edge", "While true", "Falling edge" }
    K.ACTIONS   = { "Replace", "Mute", "Adjust" }
    K.NAME_MODES = { "is", "contains" }
    K.EMIT_WHEN  = { "Always", "Chasing me", "Chasing anyone", "Within range of me" }
    K.EMIT_MODES = { "Loop", "Repeat" }
    K.MATCH_MODES = { "All", "Any", "AtLeast" }
    K.MATCH_LABEL = { All = "ALL must be true (AND)", Any = "ANY can be true (OR)", AtLeast = "At least N must be true" }
    K.TYPE_ORDER = { "Always", "Value", "State", "Event", "Room", "Twisted", "Key", "Sound", "Luau", "Group" }
    K.TYPE_LABELS = { Always = "Always", Value = "Value (Info / Config / Stats)", State = "Game State", Event = "Event (just happened)", Room = "Current Room",
        Twisted = "Twisted (Monsters)", Key = "Key Press", Sound = "Game Sound Playing", Luau = "Custom Luau", Group = "Group (AND / OR)" }
    K.STATE_LIST = { "Panic mode", "In elevator", "Floor in progress", "Blackout", "Hurry up", "Dandy store open", "All generators done", "Voting",
        "In a run (alive)", "Dead / spectating", "Sprinting" }
    K.EVENT_LIST = { "I got hurt", "I got healed", "I died", "I spawned", "Room changed", "Floor changed", "Generator completed", "Panic started" }
    local EVENT_KEY = { ["I got hurt"] = "hurt", ["I got healed"] = "heal", ["I died"] = "died", ["I spawned"] = "spawn", ["Room changed"] = "room",
        ["Floor changed"] = "floor", ["Generator completed"] = "gen", ["Panic started"] = "panic" }
    K.labelToType, K.typeLabelList = {}, {}
    for _, t in ipairs(K.TYPE_ORDER) do K.labelToType[K.TYPE_LABELS[t]] = t; K.typeLabelList[#K.typeLabelList + 1] = K.TYPE_LABELS[t] end

    -- items -----------------------------------------------------------
    local function newGroup(match) return { type = "Group", match = match or "All", n = 1, children = {}, enabled = true } end
    local function newCond(t)
        if t == "Value" then return { type = "Value", src = "Info", name = "", op = "==", value = "", enabled = true }
        elseif t == "Room" then return { type = "Room", op = "contains", value = "", enabled = true }
        elseif t == "Twisted" then return { type = "Twisted", mode = "chasing me", twisted = "Any", player = "", dist = 60, enabled = true }
        elseif t == "State" then return { type = "State", what = "Panic mode", enabled = true }
        elseif t == "Event" then return { type = "Event", kind = "I got hurt", hold = 2, enabled = true }
        elseif t == "Key" then return { type = "Key", key = "G", mode = "held", enabled = true }
        elseif t == "Sound" then return { type = "Sound", name = "", group = "", id = "", enabled = true }
        elseif t == "Luau" then return { type = "Luau", code = "workspace.Info.Danger.Value > 3", enabled = true }
        elseif t == "Group" then return newGroup("All")
        end
        return { type = "Always", enabled = true }
    end
    local function normNode(c)
        if type(c) ~= "table" or type(c.type) ~= "string" then return nil end
        if c.enabled == nil then c.enabled = true end
        if c.type == "Group" then
            c.match = (c.match == "Any" or c.match == "AtLeast") and c.match or "All"
            c.n = tonumber(c.n) or 1
            local kids = {}
            for _, k in ipairs(type(c.children) == "table" and c.children or {}) do
                local nk = normNode(k)
                if nk then kids[#kids + 1] = nk end
            end
            c.children = kids
        end
        return c
    end
    local function normRoot(t)
        if type(t.root) == "table" then
            local r = normNode(t.root)
            if r and r.type == "Group" then return r end
        end
        local g = newGroup(t.match == "Any" and "Any" or "All")   -- old Aero Music Player files: flat conditions + one Match mode
        if type(t.conditions) == "table" then
            for _, c in ipairs(t.conditions) do
                local nc = normNode(c)
                if nc then g.children[#g.children + 1] = nc end
            end
        end
        return g
    end
    local function oneOf(v, list, def) for _, x in ipairs(list) do if x == v then return v end end; return def end
    local function num(v, d) return tonumber(v) or d end

    local function normSong(t)
        t = type(t) == "table" and t or {}
        local off = oneOf(t.offMode, K.OFF_SONG, nil) or (t.restart == false and "Pause") or "Global"
        return { id = newId(), name = tostring(t.name or "New Song"), source = tostring(t.source or ""), enabled = t.enabled ~= false,
            priority = num(t.priority, 0), volume = num(t.volume, 1), pitch = num(t.pitch, 1), loop = t.loop ~= false, offMode = off,
            transition = oneOf(t.transition, K.TRANS_SONG, "Global"), root = normRoot(t) }
    end
    local function normSfx(t)
        t = type(t) == "table" and t or {}
        return { id = newId(), name = tostring(t.name or "New Sound Effect"), source = tostring(t.source or ""), enabled = t.enabled ~= false,
            volume = num(t.volume, 1), pitch = num(t.pitch, 1), pitchVar = math.clamp(num(t.pitchVar, 0), 0, 1),
            trigger = oneOf(t.trigger, K.TRIGGERS, "Rising edge"), cooldown = math.max(num(t.cooldown, 0.3), 0), interval = math.max(num(t.interval, 1), 0.05),
            root = normRoot(t) }
    end
    local function normRule(t)
        t = type(t) == "table" and t or {}
        local m = type(t.m) == "table" and t.m or {}
        return { id = newId(), name = tostring(t.name or "New Replacement"), enabled = t.enabled ~= false,
            m = { name = tostring(m.name or ""), nameMode = oneOf(m.nameMode, K.NAME_MODES, "is"), path = tostring(m.path or ""), id = tostring(m.id or ""), group = tostring(m.group or "") },
            action = oneOf(t.action, K.ACTIONS, "Replace"), source = tostring(t.source or ""), volume = num(t.volume, 1), pitch = num(t.pitch, 1), root = normRoot(t) }
    end
    local function normEmitter(t)
        t = type(t) == "table" and t or {}
        return { id = newId(), name = tostring(t.name or "New Emitter"), enabled = t.enabled ~= false, source = tostring(t.source or ""),
            twisted = tostring(t.twisted or "Any"), when = oneOf(t.when, K.EMIT_WHEN, "Always"), range = math.max(num(t.range, 60), 1),
            mode = oneOf(t.mode, K.EMIT_MODES, "Loop"), interval = math.max(num(t.interval, 4), 0.2), pitchVar = math.clamp(num(t.pitchVar, 0.1), 0, 1),
            volume = num(t.volume, 1), pitch = num(t.pitch, 1), minDist = math.max(num(t.minDist, 10), 1), maxDist = math.max(num(t.maxDist, 80), 5),
            muteTheirs = t.muteTheirs == true, root = normRoot(t) }
    end
    local NORM = { songs = normSong, sfx = normSfx, rules = normRule, emitters = normEmitter }
    Snd.normNode, Snd.newCond, Snd.newGroup = normNode, newCond, newGroup

    -- sources (asset id / file / link) ------------------------------------
    local function hash(s)
        local h = 5381
        for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
        return string.format("%08x%x", h, #s)
    end
    local function classify(src)
        src = trim(src)
        if src == "" then return "empty" end
        local id = src:match("^rbxassetid://(%d+)") or src:match("^(%d+)$") or src:match("^rbxassetid:(%d+)")
        if id then return "asset", id end
        if src:lower():find("roblox%.com", 1) then
            local i = src:match("[?&]id=(%d+)") or src:match("/library/(%d+)") or src:match("/catalog/(%d+)")
            if i then return "asset", i end
        end
        if src:match("^https?://") then return "url", src end
        if src:match("^rbxasset://") then return "builtin", src end
        return "file", src
    end
    local function normalizeUrl(u)
        local label = "Direct link"
        local id = u:match("drive%.google%.com/file/d/([%w%-_]+)")
        if not id and (u:find("drive.google.com", 1, true) or u:find("docs.google.com", 1, true)) then id = u:match("[?&]id=([%w%-_]+)") end
        if id then return "https://drive.usercontent.google.com/download?id=" .. id .. "&export=download&confirm=t", "Google Drive" end
        if u:find("dropbox.com", 1, true) then
            u = u:gsub("://www%.dropbox%.com", "://dl.dropboxusercontent.com"):gsub("://dropbox%.com", "://dl.dropboxusercontent.com")
            u = u:gsub("dl=0", "dl=1")
            return u, "Dropbox"
        end
        local user, repo, rest = u:match("^https://github%.com/([^/]+)/([^/]+)/blob/(.+)$")
        if user then return ("https://raw.githubusercontent.com/%s/%s/%s"):format(user, repo, rest), "GitHub" end
        if u:find("file.garden", 1, true) or u:find("filegarden", 1, true) then label = "File Garden" end
        return u, label
    end
    local function sniff(b)
        if b:sub(1, 3) == "ID3" then return "mp3" end
        local h = b:sub(1, 4)
        if h == "OggS" then return "ogg" end
        if h == "RIFF" then return "wav" end
        if h == "fLaC" then return "flac" end
        if b:sub(5, 8) == "ftyp" then return "m4a" end
        local b1, b2 = b:byte(1, 2)
        if b1 == 0xFF and b2 and bit32.band(b2, 0xE0) == 0xE0 then return "mp3" end
        return nil
    end
    local function isHtml(b)
        local h = b:sub(1, 300):lower()
        return h:find("<!doctype", 1, true) ~= nil or h:find("<html", 1, true) ~= nil
    end
    local function fetch(url)
        if not httpReq then return nil, "This executor has no request() / http_request()." end
        local ok, res = pcall(httpReq, { Url = url, Method = "GET", Headers = { ["User-Agent"] = "Mozilla/5.0" } })
        if not ok then return nil, "Request failed: " .. tostring(res) end
        if not res then return nil, "No response from server." end
        local code = res.StatusCode or res.status_code or 0
        if code >= 400 then return nil, "Server answered HTTP " .. code .. " (is the link public?)" end
        return res.Body or "", nil
    end
    local function driveRetry(body)
        local action = body:match('<form[^>]-action="([^"]+)"')
        if not action then return nil end
        action = action:gsub("&amp;", "&")
        local params = {}
        for n, v in body:gmatch('<input[^>]-name="([^"]+)"[^>]-value="([^"]*)"') do params[#params + 1] = n .. "=" .. v end
        return action .. (action:find("?", 1, true) and "&" or "?") .. table.concat(params, "&")
    end
    local function cachedPath(key)
        for _, e in ipairs(EXTS) do
            local p = CACHE_DIR .. "/" .. key .. "." .. e
            if isF(p) then return p end
        end
    end
    local function fetchToCache(url, force)
        local nurl, label = normalizeUrl(url)
        local key = hash(nurl)
        if not force then
            local p = cachedPath(key)
            if p then return p, label .. " (cached)" end
        end
        local body, err = fetch(nurl)
        if not body then return nil, err end
        if isHtml(body) then
            local retry = driveRetry(body)
            if retry then body, err = fetch(retry); if not body then return nil, err end end
        end
        if isHtml(body) then return nil, "Link gave a web page, not an audio file. Use a direct link (Drive: share as 'Anyone with the link')." end
        if #body < 2000 then return nil, "Downloaded file is too small to be audio." end
        local ext = sniff(body)
        if not ext then
            local e = (nurl:gsub("[?#].*$", "")):match("%.(%w+)$")
            e = e and e:lower()
            if e and table.find(EXTS, e) then ext = e end
        end
        if not ext then return nil, "Unrecognised audio format (use mp3 / ogg / wav)." end
        if ext == "m4a" then return nil, "m4a/mp4 isn't supported by Roblox. Convert it to mp3 or ogg." end
        local path = CACHE_DIR .. "/" .. key .. "." .. ext
        if not wrF(path, body) then return nil, "Couldn't write the cache file." end
        return path, label
    end

    -- every audio file in the Music / Sounds / TonyScriptPalace/Sound/Files folders.  Music files keep their bare name (old setups still work).
    function Snd.listFiles()
        local out = {}
        for _, dir in ipairs(FILE_DIRS) do
            for _, p in ipairs(lsD(dir)) do
                local n = baseName(p)
                local e = n:match("%.(%w+)$")
                if e and table.find(EXTS, e:lower()) then out[#out + 1] = (dir == "Music") and n or (baseName(dir) .. "/" .. n) end
            end
        end
        table.sort(out, function(a, b) return a:lower() < b:lower() end)
        return out
    end
    local function findFile(name)
        name = tostring(name):gsub("\\", "/")
        if isF(name) then return name end
        for _, dir in ipairs(FILE_DIRS) do
            local direct = dir .. "/" .. name
            if isF(direct) then return direct end
        end
        local ln = name:lower():gsub("^.*/", "")
        for _, dir in ipairs(FILE_DIRS) do
            for _, p in ipairs(lsD(dir)) do
                local n = baseName(p):lower()
                if n == ln or (n:gsub("%.%w+$", "")) == ln then return dir .. "/" .. baseName(p) end
            end
        end
    end

    -- turns ONE source string into an asset the engine can put in Sound.SoundId   cb(asset, info) / cb(nil, errorMessage)
    local function resolveOne(src, force, cb)
        local kind, val = classify(src)
        if kind == "asset" then return cb("rbxassetid://" .. val, "Roblox asset " .. val) end
        if kind == "builtin" then return cb(val, "Built-in sound") end
        if kind == "file" then
            task.spawn(function()
                local p = findFile(val)
                if not p then return cb(nil, "Not found in Music / Sounds / TonyScriptPalace/Sound/Files: " .. val) end
                if not getasset then return cb(nil, "This executor has no getcustomasset.") end
                local ok, res = pcall(getasset, p)
                if ok and res then cb(res, "File: " .. baseName(p)) else cb(nil, "getcustomasset failed: " .. tostring(res)) end
            end)
        else
            task.spawn(function()
                local p, lab = fetchToCache(val, force)
                if not p then return cb(nil, lab) end
                if not getasset then return cb(nil, "This executor has no getcustomasset.") end
                local ok, res = pcall(getasset, p)
                if ok and res then cb(res, lab) else cb(nil, "getcustomasset failed: " .. tostring(res)) end
            end)
        end
    end
    local function splitSources(s)
        local out = {}
        for part in tostring(s or ""):gmatch("[^|]+") do
            part = trim(part)
            if part ~= "" then out[#out + 1] = part end
        end
        return out
    end

    local reapplyAll, needRescan   -- game sound rules (defined further down)
    local getVoice

    -- resolves every source of an item (songs use the first one, effects and replacements pick a random variant)
    local function resolveItem(item, force, isSong)
        local r = rt[item.id]
        if not r then r = { token = 0 }; rt[item.id] = r end
        r.token += 1
        local tok = r.token
        r.err, r.asset, r.assets, r.len, r.info, r.ended = nil, nil, {}, nil, nil, false
        local v = voices[item.id]
        if v then v.sound:Stop(); v.sound.SoundId = ""; v.gain = 0 end
        local list = splitSources(item.source)
        if isSong and #list > 1 then list = { list[1] } end
        if #list == 0 then r.status = "empty"; if reapplyAll then reapplyAll() end; return end
        r.status = "loading"; r.info = "Working..."
        local pending, got = #list, 0
        for _, src in ipairs(list) do
            resolveOne(src, force, function(asset, info)
                if tok ~= r.token then return end
                pending -= 1
                if asset then
                    got += 1; r.assets[#r.assets + 1] = asset; r.asset = r.asset or asset
                    r.info = (#list > 1) and (got .. " of " .. #list .. " variants") or info
                else r.err = r.err or info end
                if pending > 0 then return end
                if got == 0 then r.status = "error"; if reapplyAll then reapplyAll() end; return end
                if not isSong then r.status = "ready"; if reapplyAll then reapplyAll() end; return end
                local vv = getVoice(item.id)
                vv.sound.SoundId = r.asset
                task.spawn(function()
                    local t0 = os.clock()
                    while not dead and tok == r.token and not vv.sound.IsLoaded and os.clock() - t0 < 20 do task.wait(0.1) end
                    if tok ~= r.token or dead then return end
                    if vv.sound.IsLoaded then r.status = "ready"; r.len = vv.sound.TimeLength
                    else r.status = "error"; r.err = "Roblox couldn't load this audio (private, deleted, or unsupported)." end
                end)
            end)
        end
    end
    Snd.resolve = function(item, force, kind) resolveItem(item, force, kind == "songs") end
    local function resolveAny(item) resolveItem(item, false, songMap[item.id] ~= nil) end

    function Snd.status(item)
        local r = rt[item.id]
        if not r or r.status == "empty" then return nil, "Set a source: a Roblox asset id, a file name from your Music / Sounds folders, or a direct link. Put | between several to use random variants." end
        if r.status == "ready" then return "safe", "Ready  |  " .. (r.len and (fmtTime(r.len) .. "  |  ") or "") .. tostring(r.info or "") end
        if r.status == "loading" then return "warn", "Loading...  " .. tostring(r.info or "") end
        return "bad", "Error: " .. tostring(r.err or "unknown")
    end

    -- voices (one Sound per song) -----------------------------------------
    getVoice = function(id)
        local v = voices[id]
        if v then return v end
        local s = Instance.new("Sound")
        s.Name = id; s.Volume = 0; s.Looped = true; s.Parent = holder
        v = { sound = s, gain = 0 }
        v.ended = s.Ended:Connect(function()
            local song, r = songMap[id], rt[id]
            if song and r and song.loop == false and v.gain > 0.05 then r.ended = true end
        end)
        voices[id] = v
        return v
    end
    local function dropVoice(id)
        local v = voices[id]
        if v then
            pcall(function() v.ended:Disconnect() end)
            pcall(function() v.sound:Destroy() end)
            voices[id] = nil
        end
        rt[id] = nil
    end

    -- conditions ----------------------------------------------------------
    local function myModel()
        local f = workspace:FindFirstChild("InGamePlayers")
        return f and f:FindFirstChild(LP.Name)
    end
    local function roomModel()
        local cr = workspace:FindFirstChild("CurrentRoom")
        return cr and cr:GetChildren()[1]
    end
    local function sourceRoot(src)
        local ws = workspace
        if src == "Info" then return ws:FindFirstChild("Info")
        elseif src == "My Config" then local m = myModel(); return m and m:FindFirstChild("Config")
        elseif src == "My Stats" then local m = myModel(); return m and m:FindFirstChild("Stats")
        elseif src == "My Model" then return myModel()
        elseif src == "My Game Stats" then
            local i = ws:FindFirstChild("Info"); local p = i and i:FindFirstChild("PlayerStats")
            return p and p:FindFirstChild(LP.Name)
        elseif src == "Room" then return roomModel() end
    end
    local function walk(root, path)
        local cur = root
        for part in tostring(path):gmatch("[^/%.]+") do
            if not cur then return nil end
            cur = cur:FindFirstChild(part)
        end
        return cur
    end
    local function readInst(inst, attr)
        if not inst then return nil end
        if attr then return inst:GetAttribute(attr) end
        if inst:IsA("ValueBase") then
            local ok, v = pcall(function() return inst.Value end)
            return ok and v or nil
        end
    end
    local function readPath(root, path)
        local p, a = path:match("^(.-)@(.+)$")
        if not p then p = path end
        local inst = (p == "") and root or walk(root, p)
        return readInst(inst, a)
    end
    local function readCustom(path)
        path = path:gsub("{me}", LP.Name)
        local p, a = path:match("^(.-)@(.+)$")
        if not p then p = path end
        local cur, first = game, true
        for part in p:gmatch("[^/%.]+") do
            if first and part:lower() == "game" then cur = game
            elseif first and part:lower() == "workspace" then cur = workspace
            else
                local nxt = cur:FindFirstChild(part)
                if not nxt and cur == game then nxt = try(game.GetService, game, part) end
                cur = nxt
            end
            first = false
            if not cur then return nil end
        end
        return readInst(cur, a)
    end
    local function infoVal(name)
        local i = workspace:FindFirstChild("Info")
        local v = i and i:FindFirstChild(name)
        if v and v:IsA("ValueBase") then return v.Value end
    end
    local function myStat(name)
        local m = myModel()
        local s = m and m:FindFirstChild("Stats")
        local v = s and s:FindFirstChild(name)
        if v and v:IsA("ValueBase") then return v.Value end
    end
    local function toBool(s)
        s = tostring(s):lower()
        if s == "true" or s == "1" or s == "yes" or s == "on" then return true end
        if s == "false" or s == "0" or s == "no" or s == "off" or s == "" then return false end
    end
    local function compare(a, op, b)
        if typeof(a) == "Instance" then a = a.Name end
        if op == "exists" then return a ~= nil end
        if op == "missing" then return a == nil end
        if op == "is true" then return a == true or (type(a) == "number" and a ~= 0) or (type(a) == "string" and toBool(a) == true) end
        if op == "is false" then return a == false or a == 0 or (type(a) == "string" and toBool(a) == false) end
        if a == nil then return op == "~=" or op == "not contains" end
        local sa, sb = tostring(a), tostring(b)
        if op == "contains" then return sa:lower():find(sb:lower(), 1, true) ~= nil end
        if op == "not contains" then return sa:lower():find(sb:lower(), 1, true) == nil end
        if type(a) == "boolean" then
            local bb = toBool(b)
            if op == "==" then return a == bb elseif op == "~=" then return a ~= bb end
            return false
        end
        local na, nb = tonumber(a), tonumber(b)
        if op == "==" or op == "~=" then
            local eq
            if na and nb then eq = math.abs(na - nb) < 1e-9 else eq = sa:lower() == sb:lower() end
            if op == "==" then return eq else return not eq end
        end
        if not (na and nb) then return false end
        if op == ">" then return na > nb elseif op == ">=" then return na >= nb
        elseif op == "<" then return na < nb elseif op == "<=" then return na <= nb end
        return false
    end

    local function allMonsters()
        local out = {}
        local cr = workspace:FindFirstChild("CurrentRoom")
        if cr then
            for _, room in ipairs(cr:GetChildren()) do
                local mf = room:FindFirstChild("Monsters")
                if mf then for _, m in ipairs(mf:GetChildren()) do out[#out + 1] = m end end
            end
        end
        local wm = workspace:FindFirstChild("Monsters")
        if wm then for _, m in ipairs(wm:GetChildren()) do out[#out + 1] = m end end
        return out
    end
    local function chasingNames(m)
        local names = {}
        local cv = m:FindFirstChild("ChasingValue")
        if cv and cv:IsA("ValueBase") then
            local v = cv.Value
            if typeof(v) == "Instance" then
                names[#names + 1] = v.Name
                if v:IsA("Player") then names[#names + 1] = v.DisplayName end
                if v:IsA("BasePart") and v.Parent then names[#names + 1] = v.Parent.Name end
            elseif type(v) == "string" and v ~= "" then names[#names + 1] = v end
        end
        return names
    end
    local function isChasingAny(m)
        if #chasingNames(m) > 0 then return true end
        local c = m:FindFirstChild("Chasing")
        return c and c:IsA("BoolValue") and c.Value or false
    end
    local function nameIs(names, who)
        who = tostring(who):lower()
        for _, n in ipairs(names) do if tostring(n):lower() == who then return true end end
        return false
    end
    local function twistedMatches(m, filter)
        filter = trim(filter or "")
        if filter == "" or filter:lower() == "any" then return true end
        return m.Name:lower():find(filter:lower(), 1, true) ~= nil
    end

    local luauCache = {}
    local function evalLuau(c)
        local code = c.code or ""
        if trim(code) == "" then return false end
        local fn = luauCache[code]
        if fn == nil then
            local pre = "local LP, Info, Room, Me = ...; "
            local f = loadstring(pre .. "return " .. code)
            if not f then f = loadstring(pre .. code) end
            fn = f or false
            luauCache[code] = fn
        end
        if not fn then return false end
        local ok, res = pcall(fn, LP, workspace:FindFirstChild("Info"), roomModel(), LP.Name)
        return (ok and res) and true or false
    end
    Snd.clearLuauCache = function() luauCache = {} end

    -- things that "just happened" (hurt, room change, ...) stay true for a few seconds so music/effects can react
    local ev, prev = {}, {}
    local function watchEvents()
        local now = os.clock()
        local hp = myStat("Health")
        if type(hp) == "number" then
            if prev.hp and hp < prev.hp then ev.hurt = now elseif prev.hp and hp > prev.hp then ev.heal = now end
            prev.hp = hp
        else prev.hp = nil end
        local has = myModel() ~= nil
        if prev.has ~= nil and has ~= prev.has then ev[has and "spawn" or "died"] = now end
        prev.has = has
        local fl = infoVal("Floor")
        if prev.floor ~= nil and fl ~= prev.floor then ev.floor = now end
        prev.floor = fl
        local g = infoVal("GeneratorsCompleted")
        if type(g) == "number" then
            if prev.gen and g > prev.gen then ev.gen = now end
            prev.gen = g
        end
        local rm = roomModel()
        local rn = rm and rm.Name
        if prev.room ~= nil and rn ~= nil and rn ~= prev.room then ev.room = now end
        if rn ~= nil then prev.room = rn end
        local pn = infoVal("Panic") == true
        if prev.panic ~= nil and pn and not prev.panic then ev.panic = now end
        prev.panic = pn
    end

    local STATES = {
        ["Panic mode"] = function() return infoVal("Panic") == true end,
        ["In elevator"] = function() return myStat("InElevator") == true end,
        ["Floor in progress"] = function() return infoVal("FloorActive") == true end,
        ["Blackout"] = function() return infoVal("BlackOut") == true end,
        ["Hurry up"] = function() return infoVal("HurryUp") == true end,
        ["Dandy store open"] = function() return infoVal("DandyStoreOpen") == true end,
        ["All generators done"] = function()
            local need, done = infoVal("RequiredGenerators"), infoVal("GeneratorsCompleted")
            return type(need) == "number" and type(done) == "number" and need > 0 and done >= need
        end,
        ["Voting"] = function() return infoVal("Voting") == true end,
        ["In a run (alive)"] = function() return myModel() ~= nil end,
        ["Dead / spectating"] = function() return myModel() == nil and infoVal("GameStarted") == true end,
        ["Sprinting"] = function() return myStat("Sprinting") == true end,
    }

    -- keys ("held" or "toggle")
    local keyNodes, keyTog = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
    connect(UIS.InputBegan, function(i, gp)
        if i.UserInputType ~= Enum.UserInputType.Keyboard or UIS:GetFocusedTextBox() then return end
        for node in pairs(keyNodes) do
            if node.mode == "toggle" and node.key == i.KeyCode.Name then keyTog[node] = not keyTog[node] end
        end
    end)

    -- every Sound the game has made (weak) - used by the replacement hook, the browser and the "Game Sound Playing" condition
    local known = setmetatable({}, { __mode = "k" })
    local function soundIdNum(id) return tostring(id):match("(%d+)%s*$") or "" end
    local function soundMatchesLoose(snd, c)
        local n, g, i = trim(c.name or ""):lower(), trim(c.group or ""):lower(), trim(c.id or "")
        if n == "" and g == "" and i == "" then return false end
        if n ~= "" and not snd.Name:lower():find(n, 1, true) then return false end
        if g ~= "" and not ((snd.SoundGroup and snd.SoundGroup.Name or ""):lower():find(g, 1, true)) then return false end
        if i ~= "" and soundIdNum(snd.SoundId) ~= soundIdNum(i) then return false end
        return true
    end

    local function condEval(c)
        local t = c.type
        if t == "Always" then return true
        elseif t == "Value" then
            local raw
            if c.src == "Custom" then raw = readCustom(c.name or "")
            else
                local root = sourceRoot(c.src)
                if root and (c.name or "") ~= "" then raw = readPath(root, c.name) end
            end
            return compare(raw, c.op or "==", c.value or "")
        elseif t == "State" then
            local f = STATES[c.what]
            return f and f() or false
        elseif t == "Event" then
            local k = EVENT_KEY[c.kind]
            return k ~= nil and ev[k] ~= nil and (os.clock() - ev[k]) < math.max(tonumber(c.hold) or 2, 0.1)
        elseif t == "Key" then
            local ok, kc = pcall(function() return Enum.KeyCode[c.key or "G"] end)
            if not ok then return false end
            keyNodes[c] = true
            if c.mode == "toggle" then return keyTog[c] == true end
            return UIS:IsKeyDown(kc) and UIS:GetFocusedTextBox() == nil
        elseif t == "Sound" then
            for snd in pairs(known) do
                if snd.Parent and snd.Playing and not snd:IsDescendantOf(holder) and soundMatchesLoose(snd, c) then return true end
            end
            return false
        elseif t == "Room" then
            local cr = workspace:FindFirstChild("CurrentRoom")
            local op, want = c.op or "contains", tostring(c.value or ""):lower()
            local found = false
            if cr then
                for _, room in ipairs(cr:GetChildren()) do
                    local n = room.Name:lower()
                    if op == "is" or op == "is not" then
                        if n == want then found = true end
                    elseif want ~= "" and n:find(want, 1, true) then found = true end
                end
            end
            if op == "is not" or op == "not contains" then return not found end
            return found
        elseif t == "Twisted" then
            local mode = c.mode or "chasing me"
            local hit, present = false, false
            local me = myModel()
            local root = me and me:FindFirstChild("HumanoidRootPart")
            for _, m in ipairs(allMonsters()) do
                if twistedMatches(m, c.twisted) then
                    present = true
                    if mode == "chasing me" or mode == "not chasing me" then
                        local names = chasingNames(m)
                        if nameIs(names, LP.Name) or nameIs(names, LP.DisplayName) then hit = true end
                    elseif mode == "chasing anyone" then
                        if isChasingAny(m) then hit = true end
                    elseif mode == "chasing player" then
                        if nameIs(chasingNames(m), c.player or "") then hit = true end
                    elseif mode == "within range" and root then
                        local ok, pv = pcall(function() return m:GetPivot().Position end)
                        if ok and (pv - root.Position).Magnitude <= (tonumber(c.dist) or 60) then hit = true end
                    end
                end
            end
            if mode == "not chasing me" then return not hit end
            if mode == "present in room" then return present end
            if mode == "not in room" then return not present end
            return hit
        elseif t == "Luau" then return evalLuau(c)
        end
        return false
    end

    -- evaluates a condition (or a whole group).  nil = switched off, so it is ignored
    local function evalNode(n)
        if n.enabled == false then return nil end
        local ok
        if n.type == "Group" then
            local tot, hit = 0, 0
            for _, k in ipairs(n.children) do
                local r = evalNode(k)
                if r ~= nil then tot += 1; if r then hit += 1 end end
            end
            if tot == 0 then ok = true
            elseif n.match == "Any" then ok = hit > 0
            elseif n.match == "AtLeast" then ok = hit >= math.max(1, math.floor(tonumber(n.n) or 1))
            else ok = hit == tot end
        else
            local good, res = pcall(condEval, n)
            ok = good and res and true or false
        end
        if n.invert then ok = not ok end
        return ok
    end
    Snd.evalNode = function(n) local r = evalNode(n); return r end

    function Snd.condSummary(c)
        local t = c.type
        if t == "Always" then return "Always"
        elseif t == "Value" then return (c.src or "Info") .. " > " .. ((c.name or "") ~= "" and c.name or "?") .. " " .. (c.op or "==") .. (K.NOVAL[c.op] and "" or (" " .. tostring(c.value or "")))
        elseif t == "State" then return "State: " .. tostring(c.what)
        elseif t == "Event" then return "Event: " .. tostring(c.kind) .. " (" .. tostring(c.hold or 2) .. "s)"
        elseif t == "Key" then return "Key " .. tostring(c.key) .. " (" .. tostring(c.mode) .. ")"
        elseif t == "Sound" then return "Game sound playing: " .. (trim(c.name or "") ~= "" and c.name or (trim(c.id or "") ~= "" and c.id or (c.group or "?")))
        elseif t == "Room" then return "Room " .. (c.op or "contains") .. " " .. tostring(c.value or "")
        elseif t == "Twisted" then return "Twisted " .. tostring(c.twisted or "Any") .. ": " .. tostring(c.mode) .. (c.mode == "within range" and (" " .. tostring(c.dist) .. " studs") or "")
        elseif t == "Luau" then return "Luau: " .. tostring(c.code or ""):sub(1, 32)
        elseif t == "Group" then return "Group (" .. ((c.match == "Any" and "OR") or (c.match == "AtLeast" and ("at least " .. tostring(c.n))) or "AND") .. ", " .. #c.children .. " inside)"
        end
        return tostring(t)
    end

    -- lists for the dropdowns
    function Snd.listNames(src)
        local out = {}
        if src == "Custom" then return out end
        local root = sourceRoot(src)
        if not root then return out end
        local maxDepth = (src == "Info") and 2 or 3
        local function rec(inst, prefix, depth)
            for _, c in ipairs(inst:GetChildren()) do
                if c:IsA("ValueBase") then out[#out + 1] = prefix .. c.Name
                elseif depth < maxDepth and (c:IsA("Folder") or c:IsA("Configuration")) then rec(c, prefix .. c.Name .. "/", depth + 1) end
            end
        end
        rec(root, "", 0)
        table.sort(out, function(a, b) return a:lower() < b:lower() end)
        local attrs = {}
        for k in pairs(root:GetAttributes()) do attrs[#attrs + 1] = "@" .. k end
        table.sort(attrs)
        for _, a in ipairs(attrs) do out[#out + 1] = a end
        return out
    end
    local twistedNames
    function Snd.twistedList()
        if not twistedNames then
            twistedNames = {}
            local md = ReplicatedStorage:FindFirstChild("MonsterData")
            if md then for _, c in ipairs(md:GetChildren()) do twistedNames[#twistedNames + 1] = (c.Name:gsub("Monster$", "")) end end
            table.sort(twistedNames, function(a, b) return a:lower() < b:lower() end)
        end
        local out = { "Any" }
        for _, n in ipairs(twistedNames) do out[#out + 1] = n end
        return out
    end
    function Snd.roomList()
        local out = table.clone(seenRooms)
        table.sort(out, function(a, b) return a:lower() < b:lower() end)
        return out
    end
    function Snd.groupList()
        local out, seen = {}, {}
        for _, d in ipairs(SoundService:GetDescendants()) do
            if d:IsA("SoundGroup") and not seen[d.Name] then seen[d.Name] = true; out[#out + 1] = d.Name end
        end
        table.sort(out, function(a, b) return a:lower() < b:lower() end)
        return out
    end

    -- TWISTED EMITTERS ---------------------------------------------------------
    -- a 3D Sound is parked on every matching Twisted (it follows it around, quieter with distance)
    local ours = setmetatable({}, { __mode = "k" })     -- Sounds made by us: the replacement hook must leave them alone
    local emit = {}                                      -- emitter id -> { [monster model] = { snd, nextAt } }
    local mrules = {}                                    -- emitter id -> hidden "mute their own sounds" rule
    local function monsterRoot(m) return m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart") end
    local function monsterOf(snd)
        local p = snd.Parent
        while p and p ~= workspace and p ~= game do
            if p.Parent and p.Parent.Name == "Monsters" then return p end
            p = p.Parent
        end
    end
    local function clearEmitter(id)
        local t = emit[id]
        if t then for _, a in pairs(t) do pcall(function() a.snd:Destroy() end) end end
        emit[id] = nil
    end
    local function monsterOk(e, m, myRoot)
        local w = e.when
        if w == "Chasing me" then
            local n = chasingNames(m)
            return nameIs(n, LP.Name) or nameIs(n, LP.DisplayName)
        elseif w == "Chasing anyone" then return isChasingAny(m)
        elseif w == "Within range of me" then
            if not myRoot then return false end
            local ok, p = pcall(function() return m:GetPivot().Position end)
            return ok and (p - myRoot.Position).Magnitude <= (e.range or 60)
        end
        return true
    end
    local function updateEmitters(now)
        local me = myModel()
        local myRoot = me and me:FindFirstChild("HumanoidRootPart")
        local monsters
        local muteChanged = false
        for _, e in ipairs(st.emitters) do
            local active = st.emitOn and e.enabled and evalNode(e.root) ~= false
            local mr = mrules[e.id]
            if not mr then mr = { id = e.id .. "_mute", action = "Mute", volume = 1, pitch = 1 }; mrules[e.id] = mr end
            local wantMute = (active and e.muteTheirs) and true or false
            if ractive[mr.id] ~= wantMute then ractive[mr.id] = wantMute; muteChanged = true end
            local r = rt[e.id]
            local ready = r and r.status == "ready" and r.assets and #r.assets > 0
            local tbl = emit[e.id]
            if not (active and ready) then
                if tbl then clearEmitter(e.id) end
            else
                if not tbl then tbl = {}; emit[e.id] = tbl end
                monsters = monsters or allMonsters()
                local keep = {}
                for _, m in ipairs(monsters) do
                    if twistedMatches(m, e.twisted) and monsterOk(e, m, myRoot) then
                        keep[m] = true
                        local a = tbl[m]
                        local part = monsterRoot(m)
                        if part and (not a or not a.snd.Parent) then
                            local s = Instance.new("Sound")
                            ours[s] = true
                            s.Name = "TSP_Emitter"
                            s.SoundId = r.assets[math.random(#r.assets)]
                            s.RollOffMode = Enum.RollOffMode.InverseTapered
                            a = { snd = s, nextAt = now + math.random() * 0.5 }
                            tbl[m] = a
                            s.Looped = e.mode == "Loop"
                            s.Parent = part
                            if e.mode == "Loop" then s:Play() end
                        end
                        if a then
                            local s = a.snd
                            local vol = math.clamp((e.volume or 1) * st.sfxVol, 0, 10)
                            if s.Volume ~= vol then s.Volume = vol end
                            if s.RollOffMinDistance ~= e.minDist then s.RollOffMinDistance = e.minDist end
                            if s.RollOffMaxDistance ~= e.maxDist then s.RollOffMaxDistance = e.maxDist end
                            if e.mode == "Loop" then
                                local sp = math.clamp(e.pitch or 1, 0.05, 6)
                                if s.PlaybackSpeed ~= sp then s.PlaybackSpeed = sp end
                                if not s.Looped then s.Looped = true end
                                if not s.Playing then s:Play() end
                            else
                                if s.Looped then s.Looped = false end
                                if not s.Playing and now >= a.nextAt then
                                    s.SoundId = r.assets[math.random(#r.assets)]
                                    s.PlaybackSpeed = math.clamp((e.pitch or 1) * (1 + (math.random() * 2 - 1) * (e.pitchVar or 0)), 0.05, 6)
                                    s:Play()
                                    a.nextAt = now + math.max(e.interval or 4, 0.2) * (0.8 + math.random() * 0.4)
                                end
                            end
                        end
                    end
                end
                for m, a in pairs(tbl) do
                    if not keep[m] then pcall(function() a.snd:Destroy() end); tbl[m] = nil end
                end
            end
        end
        for id in pairs(emit) do
            local alive2 = false
            for _, e in ipairs(st.emitters) do if e.id == id then alive2 = true end end
            if not alive2 then clearEmitter(id) end
        end
        if muteChanged then reapplyAll() end
    end
    function Snd.emitCount(e)
        local n = 0
        for _ in pairs(emit[e.id] or {}) do n += 1 end
        return n
    end

    -- MUSIC ---------------------------------------------------------------
    local lastWinnerId, activeMode = false, "Crossfade"
    local lastRoomScan = 0
    local pseudo = { id = "pseudo_mute", action = "Mute", volume = 1, pitch = 1 }   -- the "mute game music" option, handled like a replacement rule

    local function evaluate()
        if needRescan then needRescan = false; Snd.rescan() end
        watchEvents()
        local changed = false
        for _, rule in ipairs(st.rules) do
            local a = rule.enabled ~= false and st.gameOn and evalNode(rule.root) ~= false
            if ractive[rule.id] ~= a then ractive[rule.id] = a; changed = true end
        end
        metSet = {}
        local best
        for _, s in ipairs(st.songs) do
            local r = rt[s.id]
            if s.enabled then
                local met = evalNode(s.root) ~= false
                metSet[s.id] = met
                if not met and r and r.ended then r.ended = false end
                if met and r and r.status ~= "error" and r.status ~= "empty" and not r.ended then
                    if not best or s.priority > best.priority then best = s end
                end
            end
        end
        if previewId then
            local ps = songMap[previewId]
            local pr = ps and rt[ps.id]
            if ps and pr and pr.status ~= "error" and pr.status ~= "empty" then best = ps else previewId = nil end
        elseif not st.enabled then best = nil end
        winner = best

        local pa = st.muteGame and (not st.muteOnlyMine or winner ~= nil)
        if ractive[pseudo.id] ~= (pa and true or false) then ractive[pseudo.id] = pa and true or false; changed = true end
        if changed then reapplyAll() end

        -- sound effects
        local now = os.clock()
        for _, f in ipairs(st.sfx) do
            local rs = srt[f.id]
            if not rs then rs = { nextAt = 0, cdUntil = 0 }; srt[f.id] = rs end
            local active = st.sfxOn and f.enabled
            local cur = active and evalNode(f.root) ~= false
            local fire = false
            if f.trigger == "While true" then fire = cur and now >= rs.nextAt
            elseif active and rs.last ~= nil then
                if f.trigger == "Rising edge" then fire = cur and not rs.last else fire = (not cur) and rs.last end
            end
            if active then rs.last = cur and true or false else rs.last = nil end   -- first look after switching on never fires an edge
            if fire and now >= rs.cdUntil then
                rs.cdUntil = now + math.max(f.cooldown or 0, 0)
                rs.nextAt = now + math.max(f.interval or 1, 0.05)
                Snd.fire(f)
            end
        end

        pcall(updateEmitters, now)

        if os.clock() - lastRoomScan > 1 then
            lastRoomScan = os.clock()
            local cr = workspace:FindFirstChild("CurrentRoom")
            if cr then
                for _, room in ipairs(cr:GetChildren()) do
                    if not seenSet[room.Name] and #seenRooms < 400 then seenSet[room.Name] = true; seenRooms[#seenRooms + 1] = room.Name; markDirty() end
                end
            end
        end
    end

    local function step(dt)
        local wid = winner and winner.id or nil
        if wid ~= lastWinnerId then
            lastWinnerId = wid
            local tr = winner and winner.transition
            activeMode = (tr and tr ~= "Global" and tr) or st.transition
        end
        local inc = dt / math.max(st.fadeTime, 0.01)
        local othersSilent = true
        for id, v in pairs(voices) do
            if id ~= wid and v.gain > 0.002 then othersSilent = false; break end
        end
        for id, v in pairs(voices) do
            local song = songMap[id]
            if not song then dropVoice(id)
            else
                local r = rt[id]
                local isWin = (id == wid)
                if activeMode == "Instant" then v.gain = isWin and 1 or 0
                elseif isWin then
                    if activeMode == "Crossfade" or othersSilent then v.gain = math.min(1, v.gain + inc) end
                else v.gain = math.max(0, v.gain - inc) end
                local snd = v.sound
                local allowed = (st.enabled or previewId == id)
                local vol = math.clamp((song.volume or 1) * st.volume * v.gain * (allowed and 1 or 0), 0, 10)
                if snd.Volume ~= vol then snd.Volume = vol end
                local sp = math.clamp((song.pitch or 1) * st.pitch, 0.05, 6)
                if snd.PlaybackSpeed ~= sp then snd.PlaybackSpeed = sp end
                local lp = song.loop ~= false
                if snd.Looped ~= lp then snd.Looped = lp end

                local mode = (song.offMode and song.offMode ~= "Global") and song.offMode or st.offMode
                local shouldPlay = v.gain > 0.002 or (isWin and (activeMode ~= "Fade" or othersSilent))
                if r and r.ended then shouldPlay = false end
                if shouldPlay then
                    if not snd.Playing and snd.SoundId ~= "" then snd:Play() end
                elseif mode == "Mute" and st.enabled and song.enabled and lp and r and r.status == "ready" and not r.ended then
                    -- "mute instead of stop": the song keeps running silently so it is in sync when it comes back
                    if not snd.Playing and snd.SoundId ~= "" then snd:Play() end
                elseif snd.Playing then
                    if mode == "Stop" then snd:Stop() else snd:Pause() end
                end
            end
        end
    end

    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        if dead then return end
        acc += dt
        if acc >= 0.1 then acc = 0; pcall(evaluate) end
        pcall(step, dt)
    end)

    function Snd.now()
        if previewId and songMap[previewId] then return "Previewing: " .. songMap[previewId].name end
        if not st.enabled then return "Music player is OFF." end
        if winner then return "Now playing: " .. winner.name .. "   (priority " .. winner.priority .. ", " .. activeMode .. ")" end
        return "No song matches right now."
    end
    function Snd.songState(s)
        local r = rt[s.id]
        if not s.enabled then return "off" end
        if r and r.status == "error" then return "error" end
        if winner and winner.id == s.id then return "playing" end
        if metSet[s.id] then return "waiting" end
        return "idle"
    end
    function Snd.previewSong(id) if previewId == id then previewId = nil else previewId = id end; return previewId == id end
    function Snd.isPreviewing(id) return previewId == id end

    -- play one sound effect now (also used by the Test buttons)
    function Snd.fire(f)
        local r = rt[f.id]
        if not r or not r.assets or #r.assets == 0 then return false end
        local s = Instance.new("Sound")
        s.SoundId = r.assets[math.random(#r.assets)]
        s.Volume = math.clamp((f.volume or 1) * st.sfxVol, 0, 10)
        s.PlaybackSpeed = math.clamp((f.pitch or 1) * (1 + (math.random() * 2 - 1) * (f.pitchVar or 0)), 0.05, 6)
        s.Parent = holder
        s.Ended:Connect(function() s:Destroy() end)
        s:Play()
        task.delay(60, function() if s.Parent then s:Destroy() end end)
        return true
    end

    -- GAME SOUND REPLACEMENT ---------------------------------------------
    -- Every Sound the game owns that matches a rule gets "hooked": we swap its SoundId / volume / pitch and keep that in place
    -- even if the game changes it, and put the original back the moment the rule stops applying.
    local entries = {}
    local attach, refresh, detach, onProp

    local function pathOf(snd)
        local ok, p = pcall(snd.GetFullName, snd)
        p = ok and p or snd.Name
        return (p:gsub("^Workspace%.", ""))
    end
    local function groupOf(snd) return snd.SoundGroup and snd.SoundGroup.Name or "" end
    local function kwList()
        local out = {}
        for k in tostring(st.muteKeywords):gmatch("[^,]+") do
            k = trim(k):lower()
            if k ~= "" then out[#out + 1] = k end
        end
        return out
    end
    local function keywordHit(snd, kws)
        local n = snd.Name:lower()
        local p = snd.Parent and snd.Parent.Name:lower() or ""
        for _, k in ipairs(kws) do
            if k == "*long" then
                if snd.Playing and snd.Looped and snd.TimeLength > 45 then return true end
            elseif n:find(k, 1, true) or p:find(k, 1, true) then return true end
        end
        return false
    end
    local function ruleMatches(rule, snd)
        local m = rule.m
        local n, p, i, g = trim(m.name), trim(m.path):lower(), trim(m.id), trim(m.group):lower()
        if n == "" and p == "" and i == "" and g == "" then return false end
        if n ~= "" then
            local sn, want = snd.Name:lower(), n:lower()
            if m.nameMode == "contains" then if not sn:find(want, 1, true) then return false end
            elseif sn ~= want then return false end
        end
        if i ~= "" and soundIdNum(snd.SoundId) ~= soundIdNum(i) then return false end
        if g ~= "" and not groupOf(snd):lower():find(g, 1, true) then return false end
        if p ~= "" and not pathOf(snd):lower():find(p, 1, true) then return false end
        return true
    end
    local function rulesFor(snd)
        local list = {}
        if ours[snd] or snd:IsDescendantOf(holder) then return list end
        for _, rule in ipairs(st.rules) do
            if rule.enabled ~= false and ruleMatches(rule, snd) then list[#list + 1] = rule end
        end
        if st.muteGame and keywordHit(snd, kwList()) then list[#list + 1] = pseudo end
        if #st.emitters > 0 then
            local mon
            for _, em in ipairs(st.emitters) do
                if em.enabled and em.muteTheirs then
                    if mon == nil then mon = monsterOf(snd) or false end
                    if mon and twistedMatches(mon, em.twisted) and mrules[em.id] then list[#list + 1] = mrules[em.id] end
                end
            end
        end
        return list
    end
    local function near(a, b) return math.abs(a - b) < 1e-4 end
    local function pickAsset(rule, e)
        local r = rt[rule.id]
        if not r or not r.assets or #r.assets == 0 then return nil, r and r.status end
        return r.assets[(e.pick % #r.assets) + 1]
    end

    refresh = function(e)
        local snd = e.snd
        if not snd.Parent then return end
        local rule
        for _, r in ipairs(e.rules) do if ractive[r.id] then rule = r; break end end
        local id, vol, sp = e.baseId, e.baseVol, e.baseSp
        if rule then
            local mult = rule.volume or 1
            if rule.action == "Mute" then mult = 0
            elseif rule.action == "Replace" then
                local a, status = pickAsset(rule, e)
                if a then id = a elseif status == "loading" then mult = 0 end   -- still downloading: stay silent instead of playing the original
            end
            vol = e.baseVol * mult
            sp = e.baseSp * (rule.pitch or 1)
        end
        vol = math.clamp(vol, 0, 10); sp = math.clamp(sp, 0.05, 6)
        if snd.SoundId ~= id then e.setId = id; snd.SoundId = id end
        if not near(snd.Volume, vol) then e.setVol = vol; snd.Volume = vol end
        if not near(snd.PlaybackSpeed, sp) then e.setSp = sp; snd.PlaybackSpeed = sp end
    end

    detach = function(e)
        e.rules = {}
        pcall(refresh, e)
        for _, c in ipairs(e.conns) do pcall(function() c:Disconnect() end) end
        entries[e.snd] = nil
    end

    onProp = function(e, which)
        if dead or entries[e.snd] ~= e then return end
        local snd = e.snd
        if which == "id" then
            if snd.SoundId == e.setId then return end
            e.baseId = snd.SoundId
            attach(snd)                                     -- the game gave it a different sound: re-check which rules fit
        elseif which == "vol" then
            if e.setVol and near(snd.Volume, e.setVol) then return end
            e.baseVol = snd.Volume
            refresh(e)
        elseif which == "sp" then
            if e.setSp and near(snd.PlaybackSpeed, e.setSp) then return end
            e.baseSp = snd.PlaybackSpeed
            refresh(e)
        else
            e.pick = math.random(1, 1000000)                -- a new random variant for the next play
            refresh(e)
        end
    end

    attach = function(snd)
        if dead then return end
        local e = entries[snd]
        local list = rulesFor(snd)
        if #list == 0 then
            if e then detach(e) end
            return
        end
        if not e then
            e = { snd = snd, baseId = snd.SoundId, baseVol = snd.Volume, baseSp = snd.PlaybackSpeed, pick = math.random(1, 1000000), conns = {} }
            entries[snd] = e
            e.conns[1] = snd:GetPropertyChangedSignal("SoundId"):Connect(function() onProp(e, "id") end)
            e.conns[2] = snd:GetPropertyChangedSignal("Volume"):Connect(function() onProp(e, "vol") end)
            e.conns[3] = snd:GetPropertyChangedSignal("PlaybackSpeed"):Connect(function() onProp(e, "sp") end)
            e.conns[4] = snd.Ended:Connect(function() onProp(e, "end") end)
            e.conns[5] = snd.Stopped:Connect(function() onProp(e, "end") end)
        end
        e.rules = list
        refresh(e)
    end

    reapplyAll = function() for _, e in pairs(entries) do pcall(refresh, e) end end
    function Snd.rescan()
        for snd in pairs(known) do
            if snd.Parent then pcall(attach, snd) else known[snd] = nil end
        end
    end
    needRescan = false
    function Snd.changed() needRescan = true; markDirty() end

    local mcache = {}
    function Snd.matchCount(rule)
        local c = mcache[rule.id]
        if c and os.clock() - c.t < 1 then return c.n end
        local n = 0
        for snd in pairs(known) do
            if snd.Parent and not snd:IsDescendantOf(holder) and ruleMatches(rule, snd) then n += 1 end
        end
        mcache[rule.id] = { t = os.clock(), n = n }
        return n
    end

    local function onSound(d)
        if ours[d] then return end
        known[d] = true
        if #st.rules > 0 or st.muteGame or #st.emitters > 0 then pcall(attach, d) end
    end
    connect(game.DescendantAdded, function(d) if d.ClassName == "Sound" then onSound(d) end end)

    -- GAME SOUND BROWSER (what is the game playing?) -----------------------
    local seen, seenOrder = {}, {}
    local wasPlaying = setmetatable({}, { __mode = "k" })
    local function record(snd, played)
        local id = soundIdNum(snd.SoundId)
        local key = snd.Name .. "|" .. id
        local e = seen[key]
        if not e then
            if #seenOrder >= 700 then return end
            e = { key = key, name = snd.Name, id = id, full = snd.SoundId, group = groupOf(snd), count = 0, last = 0 }
            seen[key] = e; seenOrder[#seenOrder + 1] = e
        end
        e.path = pathOf(snd); e.group = groupOf(snd); e.len = snd.TimeLength; e.looped = snd.Looped
        if played then e.count += 1; e.last = os.clock() end
    end
    local spyAcc = 0
    connect(RunService.Heartbeat, function(dt)
        if dead or not st.spy then return end
        spyAcc += dt
        if spyAcc < 0.2 then return end
        spyAcc = 0
        for snd in pairs(known) do
            local p = snd.Playing
            if p and not wasPlaying[snd] and not snd:IsDescendantOf(holder) then pcall(record, snd, true) end
            wasPlaying[snd] = p or nil
        end
    end)
    local scanning = false
    local function scanRoots(templates)
        local roots = { SoundService, LP:FindFirstChild("PlayerGui"), LP:FindFirstChild("PlayerScripts"), LP.Character,
            workspace:FindFirstChild("Sounds"), workspace:FindFirstChild("CurrentRoom"), workspace:FindFirstChild("Elevators"),
            workspace:FindFirstChild("InGamePlayers"), workspace:FindFirstChild("Monsters") }
        if templates then roots[#roots + 1] = ReplicatedStorage; roots[#roots + 1] = game:GetService("StarterGui") end
        return roots
    end
    function Snd.scanGame(done)
        if scanning then return end
        scanning = true
        task.spawn(function()
            local n = 0
            for _, root in ipairs(scanRoots(true)) do
                local ok, list = pcall(root.GetDescendants, root)
                if ok then
                    for _, d in ipairs(list) do
                        if d.ClassName == "Sound" and not d:IsDescendantOf(holder) then
                            known[d] = true; pcall(record, d, false)
                            n += 1
                            if n % 300 == 0 then task.wait() end
                        end
                    end
                end
            end
            scanning = false
            if done then done(n) end
        end)
    end
    -- first look at the game (rule hooks need this to find sounds that already exist)
    task.spawn(function()
        for _, root in ipairs(scanRoots(false)) do
            local ok, list = pcall(root.GetDescendants, root)
            if ok then
                local n = 0
                for _, d in ipairs(list) do
                    if d.ClassName == "Sound" and not d:IsDescendantOf(holder) then
                        known[d] = true
                        n += 1
                        if n % 300 == 0 then task.wait() end
                    end
                end
            end
        end
        if not dead then Snd.rescan() end
    end)

    function Snd.seenList(filter)
        filter = trim(filter or ""):lower()
        local out = {}
        for _, e in ipairs(seenOrder) do
            if filter == "" or e.name:lower():find(filter, 1, true) or e.id:find(filter, 1, true) or (e.path or ""):lower():find(filter, 1, true) or e.group:lower():find(filter, 1, true) then
                out[#out + 1] = e
            end
        end
        table.sort(out, function(a, b)
            if (a.last > 0) ~= (b.last > 0) then return a.last > 0 end
            if a.last ~= b.last then return a.last > b.last end
            return a.name:lower() < b.name:lower()
        end)
        return out
    end
    function Snd.clearSeen() seen, seenOrder = {}, {} end
    local pv
    function Snd.previewGame(e)
        if pv then pcall(function() pv:Destroy() end); pv = nil end
        local s = Instance.new("Sound")
        s.SoundId = e.full; s.Volume = 0.6; s.Parent = holder
        s:Play(); pv = s
        task.delay(12, function() if pv == s then pcall(function() s:Destroy() end); pv = nil end end)
    end
    function Snd.stopPreviews()
        if pv then pcall(function() pv:Destroy() end); pv = nil end
        previewId = nil
    end
    function Snd.ruleFromSeen(e, action)
        local rule = normRule({ name = e.name, m = { name = e.name, nameMode = "is", id = e.id }, action = action })
        st.rules[#st.rules + 1] = rule
        resolveAny(rule); Snd.changed()
        return rule
    end

    -- GAME MIXER (SoundGroup volumes) -------------------------------------
    local mixBase = {}
    local function eachGroup(name, fn)
        for _, d in ipairs(SoundService:GetDescendants()) do
            if d:IsA("SoundGroup") and d.Name == name then fn(d) end
        end
    end
    function Snd.setMixer(name, v)
        if math.abs(v - 1) < 0.005 then st.mixer[name] = nil else st.mixer[name] = v end
        eachGroup(name, function(g)
            if mixBase[g] == nil then mixBase[g] = g.Volume end
            g.Volume = mixBase[g] * (st.mixer[name] or 1)
        end)
        markDirty()
    end
    local function enforceMixer()
        for name, mult in pairs(st.mixer) do
            eachGroup(name, function(g)
                if mixBase[g] == nil then mixBase[g] = g.Volume end
                local want = mixBase[g] * mult
                if not near(g.Volume, want) then g.Volume = want end
            end)
        end
    end
    local function restoreMixer()
        for g, base in pairs(mixBase) do pcall(function() g.Volume = base end) end
        mixBase = {}
    end

    -- PERSISTENCE -----------------------------------------------------------
    local function audioBlock()
        return { volume = st.volume, pitch = st.pitch, sfxVol = st.sfxVol, transition = st.transition, fadeTime = st.fadeTime, offMode = st.offMode }
    end
    local function applyAudio(a)
        if type(a) ~= "table" then return end
        st.volume = num(a.volume, st.volume); st.pitch = num(a.pitch, st.pitch); st.sfxVol = num(a.sfxVol, st.sfxVol)
        st.transition = oneOf(a.transition, K.TRANS_ALL, st.transition)
        st.fadeTime = num(a.fadeTime, st.fadeTime)
        st.offMode = oneOf(a.offMode, K.OFF_ALL, st.offMode)
    end
    local function saveAll()
        local s = jenc({ enabled = st.enabled, gameOn = st.gameOn, sfxOn = st.sfxOn, emitOn = st.emitOn, muteGame = st.muteGame, muteOnlyMine = st.muteOnlyMine,
            muteKeywords = st.muteKeywords, seenRooms = seenRooms, audio = audioBlock(), mixer = st.mixer, lastSetup = st.lastSetup })
        if s then wrF(SETTINGS_F, s) end
        local a = jenc({ songs = st.songs, sfx = st.sfx, rules = st.rules, emitters = st.emitters })
        if a then wrF(AUTOSAVE_F, a) end
    end
    Snd.save = saveAll

    local function clearAll()
        previewId = nil
        for id in pairs(voices) do dropVoice(id) end
        for id in pairs(emit) do clearEmitter(id) end
        st.songs, st.sfx, st.rules, st.emitters = {}, {}, {}, {}
        for k in pairs(rt) do rt[k] = nil end
        ractive, srt = {}, {}
        songMap = {}
    end
    local function loadItems(data)
        for _, key in ipairs({ "songs", "sfx", "rules", "emitters" }) do
            if type(data[key]) == "table" then
                for _, t in ipairs(data[key]) do st[key][#st[key] + 1] = NORM[key](t) end
            end
        end
        rebuildMap()
        for _, key in ipairs({ "songs", "sfx", "rules", "emitters" }) do
            for _, item in ipairs(st[key]) do resolveItem(item, false, key == "songs") end
        end
    end
    local function listFilesIn(dir)
        local out = {}
        for _, p in ipairs(lsD(dir)) do out[#out + 1] = baseName(p) end
        return out
    end

    do -- startup load (+ one-time import of the old Aero Music Player files)
        local s = jdec(rdF(SETTINGS_F) or "")
        local a = jdec(rdF(AUTOSAVE_F) or "")
        local imported = false
        if not a and isF("AeroMusic/autosave.json") then
            a = jdec(rdF("AeroMusic/autosave.json")); imported = a ~= nil
            if imported then
                local old = jdec(rdF("AeroMusic/settings.json") or "")
                if type(old) == "table" and not s then
                    s = { muteGame = old.muteGame, muteKeywords = old.muteKeywords, seenRooms = old.seenRooms, audio = old.audio }
                end
                for _, n in ipairs(listFilesIn("AeroMusic/Setups")) do
                    if n:lower():match("%.json$") and not isF(SETUP_DIR .. "/" .. n) then
                        local body = rdF("AeroMusic/Setups/" .. n)
                        if body then wrF(SETUP_DIR .. "/" .. n, body) end
                    end
                end
            end
        end
        if type(s) == "table" then
            for _, k in ipairs({ "enabled", "gameOn", "sfxOn", "emitOn", "muteGame", "muteOnlyMine" }) do if s[k] ~= nil then st[k] = s[k] and true or false end end
            if type(s.muteKeywords) == "string" then st.muteKeywords = s.muteKeywords end
            if type(s.lastSetup) == "string" then st.lastSetup = s.lastSetup end
            if type(s.seenRooms) == "table" then
                for _, n in ipairs(s.seenRooms) do if not seenSet[n] then seenSet[n] = true; seenRooms[#seenRooms + 1] = n end end
            end
            if type(s.mixer) == "table" then
                for k, v in pairs(s.mixer) do if type(k) == "string" and tonumber(v) then st.mixer[k] = math.clamp(tonumber(v), 0, 3) end end
            end
            applyAudio(s.audio)
        end
        if type(a) == "table" then
            applyAudio(a.audio)
            loadItems(a)
        end
        rebuildMap()
        if imported then dirty = true end
    end

    -- setups = named copies of everything (songs, effects, replacements, audio, mixer)
    function Snd.listSetups()
        local out = {}
        for _, p in ipairs(lsD(SETUP_DIR)) do
            local n = baseName(p)
            if n:lower():match("%.json$") then out[#out + 1] = (n:gsub("%.[jJ][sS][oO][nN]$", "")) end
        end
        table.sort(out, function(a, b) return a:lower() < b:lower() end)
        return out
    end
    function Snd.saveSetup(name)
        name = trim(name):gsub("[^%w%-_ ]", "_")
        if name == "" then return false, "Type a setup name first." end
        local js = jenc({ name = name, songs = st.songs, sfx = st.sfx, rules = st.rules, emitters = st.emitters, audio = audioBlock(), mixer = st.mixer })
        if js and wrF(SETUP_DIR .. "/" .. name .. ".json", js) then st.lastSetup = name; markDirty(); return true, "Saved setup '" .. name .. "'." end
        return false, "Couldn't write the setup file."
    end
    function Snd.loadSetup(name)
        name = trim(name)
        local data = jdec(rdF(SETUP_DIR .. "/" .. name .. ".json") or "")
        if type(data) ~= "table" then return false, "Couldn't load '" .. name .. "'." end
        clearAll()
        loadItems(data)
        applyAudio(data.audio)
        if type(data.mixer) == "table" then
            for k in pairs(st.mixer) do Snd.setMixer(k, 1) end
            for k, v in pairs(data.mixer) do if tonumber(v) then Snd.setMixer(k, math.clamp(tonumber(v), 0, 3)) end end
        end
        st.lastSetup = name; Snd.changed()
        return true, "Loaded setup '" .. name .. "'."
    end
    function Snd.deleteSetup(name)
        name = trim(name)
        if not isF(SETUP_DIR .. "/" .. name .. ".json") then return false, "Pick an existing setup to delete." end
        dlF(SETUP_DIR .. "/" .. name .. ".json")
        if st.lastSetup == name then st.lastSetup = "" end
        return true, "Deleted setup '" .. name .. "'."
    end

    -- config-system hooks (Configs tab): a config remembers the on/off switches and which setup to use
    function Snd.serialize()
        return { enabled = st.enabled, gameOn = st.gameOn, sfxOn = st.sfxOn, emitOn = st.emitOn, muteGame = st.muteGame, setup = st.lastSetup,
            muteOnlyMine = st.muteOnlyMine, muteKeywords = st.muteKeywords, audio = audioBlock(), mixer = st.mixer }
    end
    function Snd.apply(d)
        if type(d) ~= "table" then return end
        for _, k in ipairs({ "enabled", "gameOn", "sfxOn", "emitOn", "muteGame" }) do if d[k] ~= nil then st[k] = d[k] and true or false end end
        if type(d.setup) == "string" and d.setup ~= "" and d.setup ~= st.lastSetup and isF(SETUP_DIR .. "/" .. d.setup .. ".json") then Snd.loadSetup(d.setup) end
        -- the config's own volume, pitch, fades and mixer go on top of whatever the setup just set
        applyAudio(d.audio)
        if type(d.muteOnlyMine) == "boolean" then st.muteOnlyMine = d.muteOnlyMine end
        if type(d.muteKeywords) == "string" then st.muteKeywords = d.muteKeywords end
        if type(d.mixer) == "table" then
            for k in pairs(st.mixer) do Snd.setMixer(k, 1) end
            for k, v in pairs(d.mixer) do if tonumber(v) then Snd.setMixer(k, math.clamp(tonumber(v), 0, 3)) end end
        end
        Snd.changed()
    end

    -- item management used by the tab
    function Snd.add(kind)
        local item = NORM[kind]({})
        local list = st[kind]
        item.name = item.name .. " " .. (#list + 1)
        list[#list + 1] = item
        if kind == "songs" then rebuildMap() end
        resolveItem(item, false, kind == "songs"); Snd.changed()
        return item
    end
    function Snd.duplicate(kind, item)
        local copy = NORM[kind](jdec(jenc(item) or "") or {})
        copy.name = item.name .. " copy"
        st[kind][#st[kind] + 1] = copy
        if kind == "songs" then rebuildMap() end
        resolveItem(copy, false, kind == "songs"); Snd.changed()
        return copy
    end
    function Snd.remove(kind, item)
        local i = table.find(st[kind], item)
        if i then table.remove(st[kind], i) end
        if kind == "songs" then
            if previewId == item.id then previewId = nil end
            dropVoice(item.id); rebuildMap()
        end
        rt[item.id] = nil; ractive[item.id] = nil; srt[item.id] = nil
        if kind == "emitters" then clearEmitter(item.id); ractive[item.id .. "_mute"] = nil; mrules[item.id] = nil end
        Snd.changed()
    end
    function Snd.reloadAll()
        for _, key in ipairs({ "songs", "sfx", "rules", "emitters" }) do
            for _, item in ipairs(st[key]) do resolveItem(item, true, key == "songs") end
        end
    end

    -- background jobs -------------------------------------------------------
    task.spawn(function()
        while not dead and alive do
            task.wait(1.5)
            if dirty then dirty = false; pcall(saveAll) end
        end
    end)
    task.spawn(function()
        while not dead and alive do
            task.wait(1)
            for snd, e in pairs(entries) do
                if not snd:IsDescendantOf(game) then pcall(detach, e) end
            end
            if st.muteGame then pcall(Snd.rescan) end      -- "*long" keyword depends on what is playing right now
            pcall(enforceMixer)
        end
    end)
    task.defer(function() for name, v in pairs(st.mixer) do pcall(Snd.setMixer, name, v) end end)

    function Snd.Destroy()
        if dead then return end
        dead = true
        if dirty then pcall(saveAll) end
        for id in pairs(emit) do pcall(clearEmitter, id) end
        for _, e in pairs(entries) do pcall(detach, e) end
        pcall(restoreMixer)
        for id in pairs(voices) do pcall(dropVoice, id) end
        pcall(function() holder:Destroy() end)
    end
    return Snd
end)()

--#endregion sound-engine
--#region page-sound
----------------------------------------------------------------------
-- SOUND TAB  (page for the sound engine above)
----------------------------------------------------------------------
;(function()
    local Snd = UI.snd
    local st, K = Snd.st, Snd.K
    local U = { song = nil, sfx = nil, rule = nil, emitter = nil, seen = nil, filter = "", setupName = "", pick = nil }
    Snd.ui = U
    local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
    local function dirty() Snd.markDirty() end
    local function again() refreshPage() end

    ---------------------------------------------------------------- lists
    -- a selectable list of items.  label -> item map is rebuilt every time the page is drawn
    local function itemList(kind, field, sortFn, labelFn, empty)
        local map, selLabel = {}, nil
        return { t = "list", empty = empty,
            items = function()
                local names, used = {}, {}
                local items = table.clone(st[kind])
                if sortFn then table.sort(items, sortFn) end
                if not (U[field] and table.find(st[kind], U[field])) then U[field] = items[1] end
                map, selLabel = {}, nil
                for _, it in ipairs(items) do
                    local base = labelFn(it)
                    local label, n = base, 1
                    while used[label] do n += 1; label = base .. " #" .. n end
                    used[label] = true; names[#names + 1] = label; map[label] = it
                    if it == U[field] then selLabel = label end
                end
                return names
            end,
            selected = function() return selLabel end,
            onSelect = function(label) U[field] = map[label]; again() end }
    end
    local function listButtons(kind, field, noun)
        return { t = "buttons", items = {
            { label = "+ Add " .. noun, style = "green", fn = function() U[field] = Snd.add(kind); again() end },
            { label = "Duplicate", fn = function()
                if U[field] then U[field] = Snd.duplicate(kind, U[field]); again() end
            end },
            { label = "Delete", style = "red", confirm = true, fn = function()
                if U[field] then Snd.remove(kind, U[field]); U[field] = nil; again() end
            end },
        } }
    end

    ---------------------------------------------------------------- conditions
    local MATCH_FROM_LABEL = {}
    for m, l in pairs(K.MATCH_LABEL) do MATCH_FROM_LABEL[l] = m end
    local function matchOptions() local o = {}; for _, m in ipairs(K.MATCH_MODES) do o[#o + 1] = K.MATCH_LABEL[m] end; return o end

    -- appends the controls that edit one condition (and, for a group, everything inside it)
    local function addNode(list, parent, node, num, depth)
        local pad = string.rep("    ", depth)
        local function rem() local i = table.find(parent.children, node); if i then table.remove(parent.children, i) end end
        list[#list + 1] = { t = "livetext", get = function()
            local r = Snd.evalNode(node)
            local txt = pad .. num .. "  " .. Snd.condSummary(node)
            if r == nil then return "warn", txt .. "   [switched off]" end
            return r and "safe" or nil, txt .. (r and "   TRUE" or "   false")
        end }
        list[#list + 1] = { t = "dropdown", text = pad .. "Type", get = function() return K.TYPE_LABELS[node.type] or node.type end,
            options = function() return K.typeLabelList end,
            set = function(label)
                local nt = K.labelToType[label]
                if nt and nt ~= node.type then
                    local inv, en = node.invert, node.enabled
                    for k in pairs(node) do node[k] = nil end
                    for k, v in pairs(Snd.newCond(nt)) do node[k] = v end
                    node.invert, node.enabled = inv, en
                    dirty(); again()
                end
            end }
        local t = node.type
        if t == "Value" then
            list[#list + 1] = { t = "dropdown", text = pad .. "Look in", get = function() return node.src or "Info" end, options = function() return K.SOURCES end,
                set = function(s) node.src = s; node.name = ""; dirty(); again() end }
            if node.src == "Custom" then
                list[#list + 1] = { t = "input", text = pad .. "Path", placeholder = "Workspace.Info.Floor", get = function() return node.name or "" end,
                    set = function(txt) node.name = trim(txt); dirty() end }
            else
                list[#list + 1] = { t = "dropdown", text = pad .. "Value", get = function() return (node.name and node.name ~= "") and node.name or "pick a value..." end,
                    options = function() return Snd.listNames(node.src) end, set = function(n) node.name = n; dirty(); again() end }
            end
            list[#list + 1] = { t = "dropdown", text = pad .. "Compare", get = function() return node.op or "==" end, options = function() return K.OPS end,
                set = function(o) node.op = o; dirty(); again() end }
            if not K.NOVAL[node.op] then
                list[#list + 1] = { t = "input", text = pad .. "Against", placeholder = "value", get = function() return tostring(node.value or "") end,
                    set = function(txt) node.value = txt; dirty() end }
            end
        elseif t == "Room" then
            list[#list + 1] = { t = "dropdown", text = pad .. "Room name", get = function() return node.op or "contains" end, options = function() return K.ROOM_OPS end,
                set = function(o) node.op = o; dirty(); again() end }
            list[#list + 1] = { t = "input", text = pad .. "Text", placeholder = "e.g. RainbowWall", get = function() return node.value or "" end,
                set = function(txt) node.value = trim(txt); dirty() end }
            list[#list + 1] = { t = "dropdown", text = pad .. "Rooms I've seen", get = function() return "pick one..." end, options = Snd.roomList,
                set = function(n) node.value = n; dirty(); again() end }
        elseif t == "Twisted" then
            list[#list + 1] = { t = "dropdown", text = pad .. "When", get = function() return node.mode or "chasing me" end, options = function() return K.T_MODES end,
                set = function(m) node.mode = m; dirty(); again() end }
            list[#list + 1] = { t = "dropdown", text = pad .. "Twisted", get = function() return tostring(node.twisted or "Any") end, options = Snd.twistedList,
                set = function(n) node.twisted = n; dirty(); again() end }
            if node.mode == "chasing player" then
                list[#list + 1] = { t = "input", text = pad .. "Username", placeholder = "username", get = function() return node.player or "" end,
                    set = function(txt) node.player = trim(txt); dirty() end }
            elseif node.mode == "within range" then
                list[#list + 1] = { t = "slider", text = pad .. "Within (studs)", min = 5, max = 300, dec = 0, get = function() return tonumber(node.dist) or 60 end,
                    set = function(v) node.dist = v; dirty() end }
            end
        elseif t == "State" then
            list[#list + 1] = { t = "dropdown", text = pad .. "State", get = function() return node.what or "Panic mode" end, options = function() return K.STATE_LIST end,
                set = function(w) node.what = w; dirty(); again() end }
        elseif t == "Event" then
            list[#list + 1] = { t = "dropdown", text = pad .. "Event", get = function() return node.kind or "I got hurt" end, options = function() return K.EVENT_LIST end,
                set = function(k) node.kind = k; dirty(); again() end }
            list[#list + 1] = { t = "slider", text = pad .. "Stays true (s)", min = 0.2, max = 15, dec = 1, get = function() return tonumber(node.hold) or 2 end,
                set = function(v) node.hold = v; dirty() end }
        elseif t == "Key" then
            list[#list + 1] = { t = "keybind", text = pad .. "Key", get = function() return node.key or "G" end, set = function(n) node.key = n; dirty(); again() end }
            list[#list + 1] = { t = "dropdown", text = pad .. "Behaviour", get = function() return node.mode or "held" end, options = function() return { "held", "toggle" } end,
                set = function(m) node.mode = m; dirty(); again() end }
        elseif t == "Sound" then
            list[#list + 1] = { t = "input", text = pad .. "Name has", placeholder = "e.g. chase", get = function() return node.name or "" end,
                set = function(txt) node.name = trim(txt); dirty() end }
            list[#list + 1] = { t = "input", text = pad .. "Sound ID", placeholder = "e.g. 16792623393", get = function() return node.id or "" end,
                set = function(txt) node.id = trim(txt); dirty() end }
            list[#list + 1] = { t = "dropdown", text = pad .. "Sound group", get = function() return (node.group and node.group ~= "") and node.group or "(any group)" end,
                options = function() local o = { "(any group)" }; for _, g in ipairs(Snd.groupList()) do o[#o + 1] = g end; return o end,
                set = function(g) node.group = (g == "(any group)") and "" or g; dirty(); again() end }
        elseif t == "Luau" then
            list[#list + 1] = { t = "input", text = pad .. "Expression", placeholder = "Info.Danger.Value > 3   (LP, Info, Room, Me)", get = function() return node.code or "" end,
                set = function(txt) node.code = txt; Snd.clearLuauCache(); dirty() end }
        elseif t == "Group" then
            list[#list + 1] = { t = "dropdown", text = pad .. "Inside, match", get = function() return K.MATCH_LABEL[node.match] or K.MATCH_LABEL.All end, options = matchOptions,
                set = function(l) node.match = MATCH_FROM_LABEL[l] or "All"; dirty(); again() end }
            if node.match == "AtLeast" then
                list[#list + 1] = { t = "slider", text = pad .. "At least", min = 1, max = 10, dec = 0, get = function() return tonumber(node.n) or 1 end,
                    set = function(v) node.n = v; dirty() end }
            end
            list[#list + 1] = { t = "dropdown", text = pad .. "+ Add inside", get = function() return "choose a type..." end, options = function() return K.typeLabelList end,
                set = function(l) local nt = K.labelToType[l]; if nt then node.children[#node.children + 1] = Snd.newCond(nt); dirty(); again() end end }
            for i, kid in ipairs(node.children) do addNode(list, node, kid, num .. "." .. i, depth + 1) end
        end
        list[#list + 1] = { t = "buttons", items = {
            { label = node.invert and "NOT: on" or "NOT: off", style = node.invert and "red" or "glass", fn = function() node.invert = not node.invert; dirty(); again() end },
            { label = node.enabled ~= false and "Enabled" or "Disabled", style = node.enabled ~= false and "green" or "glass",
              fn = function() node.enabled = not (node.enabled ~= false); dirty(); again() end },
            { label = "Remove", style = "red", fn = function() rem(); dirty(); again() end },
        } }
    end
    local function conditionSection(title, item)
        local list = {}
        if not item then
            return { title = title, controls = { { t = "text", text = "Nothing selected yet."} } }
        end
        local root = item.root
        list[#list + 1] = { t = "livetext", get = function()
            local r = Snd.evalNode(root)
            return r and "safe" or nil, (r and "Conditions are met right now." or "Conditions are not met right now.")
        end }
        list[#list + 1] = { t = "dropdown", text = "Combine", get = function() return K.MATCH_LABEL[root.match] or K.MATCH_LABEL.All end, options = matchOptions,
            set = function(l) root.match = MATCH_FROM_LABEL[l] or "All"; dirty(); again() end }
        if root.match == "AtLeast" then
            list[#list + 1] = { t = "slider", text = "At least", min = 1, max = 10, dec = 0, get = function() return tonumber(root.n) or 1 end, set = function(v) root.n = v; dirty() end }
        end
        list[#list + 1] = { t = "dropdown", text = "+ Add condition", get = function() return "choose a type..." end, options = function() return K.typeLabelList end,
            set = function(l) local nt = K.labelToType[l]; if nt then root.children[#root.children + 1] = Snd.newCond(nt); dirty(); again() end end }
        if #root.children == 0 then
            list[#list + 1] = { t = "text", text = "No conditions means it's always eligible. Use a Group to mix AND and OR, e.g. (Panic OR Twisted chasing me) AND Floor 2."}
        end
        for i, c in ipairs(root.children) do addNode(list, root, c, tostring(i), 0) end
        return { title = title, controls = list }
    end

    ---------------------------------------------------------------- shared editor pieces
    local function srcControls(list, item, kind)
        list[#list + 1] = { t = "input", text = "Source", placeholder = "asset id / file name / link   (use | for variants)", get = function() return item.source end,
            set = function(txt)
                txt = trim(txt)
                if txt ~= item.source then item.source = txt; Snd.resolve(item, false, kind); Snd.changed() end
            end }
        list[#list + 1] = { t = "dropdown", text = "Pick a file", get = function() return "Music / Sounds folders..." end, options = Snd.listFiles,
            set = function(n)
                item.source = n; Snd.resolve(item, false, kind); Snd.changed(); again()
            end }
        list[#list + 1] = { t = "livetext", get = function() return Snd.status(item) end }
    end
    local function nameRow(list, item, after)
        list[#list + 1] = { t = "input", text = "Name", placeholder = "name", get = function() return item.name end,
            set = function(txt) txt = trim(txt); if txt == "" then txt = "Untitled" end; item.name = txt; dirty(); again() end }
        list[#list + 1] = { t = "toggle", text = "Enabled", get = function() return item.enabled ~= false end, set = function(v) item.enabled = v; Snd.changed() end }
    end

    ---------------------------------------------------------------- sections
    local function playerSection()
        local offLabels = { Stop = "Stop (restart)", Pause = "Pause (resume)", Mute = "Mute (keeps running)" }
        local fromLabel = { ["Stop (restart)"] = "Stop", ["Pause (resume)"] = "Pause", ["Mute (keeps running)"] = "Mute" }
        local offOpts = { "Stop (restart)", "Pause (resume)", "Mute (keeps running)" }
        return { title = "Player", controls = {
            { t = "toggle", text = "Music Player", get = function() return st.enabled end, set = function(v) st.enabled = v; dirty() end },
            { t = "toggle", text = "Sound Effects", get = function() return st.sfxOn end, set = function(v) st.sfxOn = v; dirty() end },
            { t = "toggle", text = "Twisted Emitters", get = function() return st.emitOn end, set = function(v) st.emitOn = v; dirty() end },
            { t = "toggle", text = "Game Sound Replacement", get = function() return st.gameOn end, set = function(v) st.gameOn = v; dirty() end },
            { t = "livetext", get = function() return (st.enabled and "safe" or nil), Snd.now() end },
            { t = "slider", text = "Music Volume", min = 0, max = 2, dec = 2, get = function() return st.volume end, set = function(v) st.volume = v; dirty() end },
            { t = "slider", text = "Music Pitch", min = 0.25, max = 3, dec = 2, get = function() return st.pitch end, set = function(v) st.pitch = v; dirty() end },
            { t = "slider", text = "Effects Volume", min = 0, max = 2, dec = 2, get = function() return st.sfxVol end, set = function(v) st.sfxVol = v; dirty() end },
            { t = "dropdown", text = "Song Change", get = function() return st.transition end, options = function() return K.TRANS_ALL end, set = function(o) st.transition = o; dirty(); again() end },
            { t = "slider", text = "Fade Time (s)", min = 0.1, max = 10, dec = 1, get = function() return st.fadeTime end, set = function(v) st.fadeTime = v; dirty() end },
            { t = "dropdown", text = "Song Not Playing", get = function() return offLabels[st.offMode] or "Stop (restart)" end, options = function() return offOpts end,
              set = function(l) st.offMode = fromLabel[l] or "Stop"; dirty(); again() end },
            { t = "text", text = "What a song does when something else takes over. Stop: starts from 0 next time. Pause: picks up where it left off. Mute: keeps playing silently in the background, so when it comes back it's exactly where it would have been (handy for songs that line up, like layered stems). Each song can override this."},
            { t = "toggle", text = "Mute Game Music", get = function() return st.muteGame end, set = function(v) st.muteGame = v; Snd.changed() end },
            { t = "toggle", text = "Only While Mine Plays", get = function() return st.muteOnlyMine end, set = function(v) st.muteOnlyMine = v; dirty() end },
            { t = "input", text = "Mute Keywords", placeholder = "music,theme,bgm  (*long = any long loop)", get = function() return st.muteKeywords end,
              set = function(txt) st.muteKeywords = txt; Snd.changed() end },
            { t = "buttons", items = {
                { label = "Stop Previews", fn = function() Snd.stopPreviews(); again() end },
                { label = "Reload Sources", fn = function() Snd.reloadAll(); toast("Reloading every source...", "info") end },
            } },
        } }
    end

    local function songSections()
        local song = U.song
        local out = {}
        out[#out + 1] = { title = "Songs", controls = {
            itemList("songs", "song", function(a, b) return a.priority > b.priority end,
                function(s) return "P" .. s.priority .. "  " .. s.name .. (s.enabled and "" or "  (off)") end, "No songs yet. Press + Add Song."),
            listButtons("songs", "song", "Song"),
        } }
        local c = {}
        if not song then
            c[1] = { t = "text", text = "No song selected."}
        else
            nameRow(c, song)
            c[#c + 1] = { t = "slider", text = "Priority", min = -50, max = 50, dec = 0, get = function() return song.priority end, set = function(v) song.priority = math.floor(v); dirty() end }
            srcControls(c, song, "songs")
            c[#c + 1] = { t = "buttons", items = {
                { label = "Reload", style = "blue", fn = function() Snd.resolve(song, true, "songs") end },
                { label = Snd.isPreviewing(song.id) and "Stop Preview" or "Preview", style = "blue", fn = function() Snd.previewSong(song.id); again() end },
            } }
            c[#c + 1] = { t = "toggle", text = "Loop", get = function() return song.loop ~= false end, set = function(v) song.loop = v; dirty() end }
            c[#c + 1] = { t = "dropdown", text = "Song Change", get = function() return song.transition == "Global" and "Use global" or song.transition end,
                options = function() return K.TRANS_SONG end, set = function(o) song.transition = o; dirty(); again() end }
            c[#c + 1] = { t = "dropdown", text = "Not Playing", get = function() return song.offMode == "Global" and ("Use global (" .. st.offMode .. ")") or song.offMode end,
                options = function() return K.OFF_SONG end, set = function(o) song.offMode = o; dirty(); again() end }
            c[#c + 1] = { t = "slider", text = "Volume", min = 0, max = 3, dec = 2, get = function() return song.volume end, set = function(v) song.volume = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Pitch", min = 0.25, max = 3, dec = 2, get = function() return song.pitch end, set = function(v) song.pitch = v; dirty() end }
        end
        out[#out + 1] = { title = "Song Editor", controls = c }
        out[#out + 1] = conditionSection("Song Conditions", song)
        return out
    end

    local function sfxSections()
        local fx = U.sfx
        local out = {}
        out[#out + 1] = { title = "Sound Effects", controls = {
            itemList("sfx", "sfx", nil, function(f) return f.name .. (f.enabled and "" or "  (off)") end, "No effects yet. Press + Add Effect."),
            listButtons("sfx", "sfx", "Effect"),
        } }
        local c = {}
        if not fx then
            c[1] = { t = "text", text = "No effect selected."}
        else
            nameRow(c, fx)
            srcControls(c, fx, "sfx")
            c[#c + 1] = { t = "buttons", items = {
                { label = "Reload", style = "blue", fn = function() Snd.resolve(fx, true, "sfx") end },
                { label = "Test Play", style = "green", fn = function() if not Snd.fire(fx) then toast("That effect has no loaded sound yet.", "err") end end },
            } }
            c[#c + 1] = { t = "dropdown", text = "Plays", get = function() return fx.trigger end, options = function() return K.TRIGGERS end, set = function(o) fx.trigger = o; dirty(); again() end }
            c[#c + 1] = { t = "text", text = "Rising edge: once each time the conditions turn true. Falling edge: once when they stop being true. While true: repeats every Repeat seconds."}
            c[#c + 1] = { t = "slider", text = "Cooldown (s)", min = 0, max = 30, dec = 1, get = function() return fx.cooldown end, set = function(v) fx.cooldown = v; dirty() end }
            if fx.trigger == "While true" then
                c[#c + 1] = { t = "slider", text = "Repeat (s)", min = 0.05, max = 30, dec = 2, get = function() return fx.interval end, set = function(v) fx.interval = v; dirty() end }
            end
            c[#c + 1] = { t = "slider", text = "Volume", min = 0, max = 3, dec = 2, get = function() return fx.volume end, set = function(v) fx.volume = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Pitch", min = 0.25, max = 3, dec = 2, get = function() return fx.pitch end, set = function(v) fx.pitch = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Pitch Variation", min = 0, max = 1, dec = 2, get = function() return fx.pitchVar end, set = function(v) fx.pitchVar = v; dirty() end }
        end
        out[#out + 1] = { title = "Effect Editor", controls = c }
        out[#out + 1] = conditionSection("Effect Conditions", fx)
        return out
    end

    local function ruleSections()
        local rule = U.rule
        local out = {}
        out[#out + 1] = { title = "Game Sound Replacement", controls = {
            { t = "text", text = "Swap, mute or adjust sounds the game itself plays: hurt sounds, ambience, jingles, footsteps, even the game's music. Use the Sound Browser to find out what a sound is called."},
            itemList("rules", "rule", nil, function(r) return r.action .. ": " .. r.name .. (r.enabled and "" or "  (off)") end, "No replacements yet. Press + Add Rule."),
            listButtons("rules", "rule", "Rule"),
        } }
        local c = {}
        if not rule then
            c[1] = { t = "text", text = "No rule selected."}
        else
            local m = rule.m
            nameRow(c, rule)
            c[#c + 1] = { t = "text", text = "A sound is affected when EVERY box you fill in matches. Empty boxes are ignored."}
            c[#c + 1] = { t = "input", text = "Sound Name", placeholder = "e.g. Damage", get = function() return m.name end, set = function(txt) m.name = trim(txt); Snd.changed() end }
            c[#c + 1] = { t = "dropdown", text = "Name Match", get = function() return m.nameMode end, options = function() return K.NAME_MODES end, set = function(o) m.nameMode = o; Snd.changed(); again() end }
            c[#c + 1] = { t = "input", text = "Path Has", placeholder = "e.g. PlayerGui or Ambience", get = function() return m.path end, set = function(txt) m.path = trim(txt); Snd.changed() end }
            c[#c + 1] = { t = "input", text = "Sound ID", placeholder = "e.g. 16792623393", get = function() return m.id end, set = function(txt) m.id = trim(txt); Snd.changed() end }
            c[#c + 1] = { t = "dropdown", text = "Sound Group", get = function() return m.group ~= "" and m.group or "(any group)" end,
                options = function() local o = { "(any group)" }; for _, g in ipairs(Snd.groupList()) do o[#o + 1] = g end; return o end,
                set = function(g) m.group = (g == "(any group)") and "" or g; Snd.changed(); again() end }
            c[#c + 1] = { t = "livetext", get = function()
                local n = Snd.matchCount(rule)
                if n == 0 then return "warn", "Matches no sound the game has made so far (it may only appear later)." end
                return "safe", "Matches " .. n .. (n == 1 and " sound" or " sounds") .. " right now."
            end }
            c[#c + 1] = { t = "dropdown", text = "Action", get = function() return rule.action end, options = function() return K.ACTIONS end, set = function(o) rule.action = o; Snd.changed(); again() end }
            if rule.action == "Replace" then
                srcControls(c, rule, "rules")
                c[#c + 1] = { t = "buttons", items = {
                    { label = "Reload", style = "blue", fn = function() Snd.resolve(rule, true, "rules") end },
                    { label = "Hear Replacement", style = "green", fn = function() if not Snd.fire(rule) then toast("The replacement isn't loaded yet.", "err") end end },
                } }
            end
            if rule.action ~= "Mute" then
                c[#c + 1] = { t = "slider", text = "Volume x", min = 0, max = 4, dec = 2, get = function() return rule.volume end, set = function(v) rule.volume = v; Snd.markDirty() end }
                c[#c + 1] = { t = "slider", text = "Pitch x", min = 0.25, max = 3, dec = 2, get = function() return rule.pitch end, set = function(v) rule.pitch = v; Snd.markDirty() end }
            end
        end
        out[#out + 1] = { title = "Replacement Editor", controls = c }
        out[#out + 1] = conditionSection("Replacement Conditions", rule)
        return out
    end

    local function emitterSections()
        local em = U.emitter
        local out = {}
        out[#out + 1] = { title = "Twisted Emitters", controls = {
            { t = "text", text = "Make Twisteds play sounds or music. The sound is attached to the Twisted itself, follows it around and gets quieter with distance. Great for a theme that fades in as one gets close."},
            itemList("emitters", "emitter", nil, function(x) return x.twisted .. ": " .. x.name .. (x.enabled and "" or "  (off)") end, "No emitters yet. Press + Add Emitter."),
            listButtons("emitters", "emitter", "Emitter"),
        } }
        local c = {}
        if not em then
            c[1] = { t = "text", text = "No emitter selected."}
        else
            nameRow(c, em)
            c[#c + 1] = { t = "dropdown", text = "Twisted", get = function() return em.twisted end, options = Snd.twistedList, set = function(n) em.twisted = n; Snd.changed(); again() end }
            c[#c + 1] = { t = "dropdown", text = "Only When", get = function() return em.when end, options = function() return K.EMIT_WHEN end, set = function(o) em.when = o; dirty(); again() end }
            if em.when == "Within range of me" then
                c[#c + 1] = { t = "slider", text = "Range (studs)", min = 5, max = 300, dec = 0, get = function() return em.range end, set = function(v) em.range = v; dirty() end }
            end
            srcControls(c, em, "emitters")
            c[#c + 1] = { t = "buttons", items = {
                { label = "Reload", style = "blue", fn = function() Snd.resolve(em, true, "emitters") end },
                { label = "Hear It", style = "green", fn = function() if not Snd.fire(em) then toast("That emitter has no loaded sound yet.", "err") end end },
            } }
            c[#c + 1] = { t = "livetext", get = function()
                local n = Snd.emitCount(em)
                if n == 0 then return nil, "Not attached to any Twisted right now." end
                return "safe", "Attached to " .. n .. (n == 1 and " Twisted" or " Twisteds") .. " right now."
            end }
            c[#c + 1] = { t = "dropdown", text = "Plays", get = function() return em.mode end, options = function() return K.EMIT_MODES end, set = function(o) em.mode = o; dirty(); again() end }
            c[#c + 1] = { t = "text", text = "Loop: keeps playing for as long as the Twisted qualifies (good for themes). Repeat: plays again every few seconds with a little random pitch (good for noises and callouts)."}
            if em.mode == "Repeat" then
                c[#c + 1] = { t = "slider", text = "Repeat (s)", min = 0.2, max = 60, dec = 1, get = function() return em.interval end, set = function(v) em.interval = v; dirty() end }
                c[#c + 1] = { t = "slider", text = "Pitch Variation", min = 0, max = 1, dec = 2, get = function() return em.pitchVar end, set = function(v) em.pitchVar = v; dirty() end }
            end
            c[#c + 1] = { t = "slider", text = "Volume", min = 0, max = 4, dec = 2, get = function() return em.volume end, set = function(v) em.volume = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Pitch", min = 0.25, max = 3, dec = 2, get = function() return em.pitch end, set = function(v) em.pitch = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Full Volume Within", min = 1, max = 100, dec = 0, get = function() return em.minDist end, set = function(v) em.minDist = v; dirty() end }
            c[#c + 1] = { t = "slider", text = "Silent Beyond", min = 10, max = 500, dec = 0, get = function() return em.maxDist end, set = function(v) em.maxDist = v; dirty() end }
            c[#c + 1] = { t = "toggle", text = "Mute Its Own Sounds", get = function() return em.muteTheirs end, set = function(v) em.muteTheirs = v; Snd.changed() end }
        end
        out[#out + 1] = { title = "Emitter Editor", controls = c }
        out[#out + 1] = conditionSection("Emitter Conditions", em)
        return out
    end

    local function browserSection()
        local map = {}
        local function entryList()
            return { t = "list", empty = "Nothing logged yet. Turn the log on (or scan) and let the game make noise.",
                items = function()
                    local names, used = {}, {}
                    map = {}
                    local all = Snd.seenList(U.filter)
                    for i = 1, math.min(#all, 60) do
                        local e = all[i]
                        local base = e.name .. "  (" .. (e.id ~= "" and e.id or "no id") .. ")" .. (e.count > 0 and ("  x" .. e.count) or "")
                        local label, n = base, 1
                        while used[label] do n += 1; label = base .. " #" .. n end
                        used[label] = true; names[#names + 1] = label; map[label] = e
                    end
                    return names
                end,
                selected = function()
                    for label, e in pairs(map) do if e.key == U.seen then return label end end
                end,
                onSelect = function(label) U.seen = map[label] and map[label].key; again() end }
        end
        local sel
        for _, e in ipairs(Snd.seenList("")) do if e.key == U.seen then sel = e end end
        local c = {
            { t = "toggle", text = "Log Playing Sounds", get = function() return st.spy end, set = function(v) st.spy = v end },
            { t = "buttons", items = {
                { label = "Scan All", style = "blue", fn = function()
                    toast("Scanning the game's sounds...", "info")
                    Snd.scanGame(function(n) toast("Scan done: " .. n .. " sounds found.", "ok"); if refreshPage then again() end end)
                end },
                { label = "Refresh", fn = function() again() end },
                { label = "Clear", style = "red", fn = function() Snd.clearSeen(); U.seen = nil; again() end },
            } },
            { t = "input", text = "Filter", placeholder = "name, id, group or path", get = function() return U.filter end, set = function(txt) U.filter = trim(txt); again() end },
            entryList(),
        }
        if sel then
            c[#c + 1] = { t = "text", font = "semi", text = sel.name .. "\nID " .. (sel.id ~= "" and sel.id or "none") .. "   Group: " .. (sel.group ~= "" and sel.group or "none")
                .. "   " .. (sel.looped and "Looped" or "One-shot") .. (sel.len and (string.format("   %.1fs", sel.len)) or "") .. "\n" .. tostring(sel.path) }
            c[#c + 1] = { t = "buttons", items = {
                { label = "Replace It", style = "green", fn = function()
                    U.rule = Snd.ruleFromSeen(sel, "Replace"); toast("Rule added. Open Replacement Editor to choose what plays instead.", "ok"); again()
                end },
                { label = "Mute It", style = "red", fn = function() U.rule = Snd.ruleFromSeen(sel, "Mute"); toast("Mute rule added.", "ok"); again() end },
            } }
            c[#c + 1] = { t = "buttons", items = {
                { label = "Hear Original", style = "blue", fn = function() Snd.previewGame(sel) end },
                { label = "Stop", fn = function() Snd.stopPreviews(); again() end },
                { label = "Copy ID", fn = function()
                    if setclipboard then setclipboard(sel.id); toast("Copied " .. sel.id, "ok") else toast("This executor has no setclipboard.", "err") end
                end },
            } }
        end
        return { title = "Sound Browser", controls = c }
    end

    local function mixerSection()
        local c = { { t = "text", text = "Scales the game's own volume channels (SoundGroups). 1.00 leaves a channel alone."} }
        local groups = Snd.groupList()
        if #groups == 0 then c[#c + 1] = { t = "text", text = "No sound groups found. Hop into a game first."} end
        for _, name in ipairs(groups) do
            if name ~= "Master" then
                c[#c + 1] = { t = "slider", text = name, min = 0, max = 2, dec = 2, get = function() return st.mixer[name] or 1 end, set = function(v) Snd.setMixer(name, v) end }
            end
        end
        return { title = "Game Mixer", controls = c }
    end

    local function setupSection()
        return { title = "Setups", controls = {
            { t = "text", text = "A setup is a named copy of all your songs, effects, replacements and mixer levels. Old Aero Music Player files get imported automatically the first time."},
            { t = "dropdown", text = "Saved Setups", get = function() return U.pick or (st.lastSetup ~= "" and st.lastSetup) or "pick a setup..." end, options = Snd.listSetups,
              set = function(n) U.pick = n; U.setupName = n; again() end },
            { t = "input", text = "Setup Name", placeholder = "setup name", get = function() return U.setupName end, set = function(txt) U.setupName = trim(txt) end },
            { t = "buttons", items = {
                { label = "Save", style = "green", fn = function() local ok, msg = Snd.saveSetup(U.setupName); toast(msg, ok and "ok" or "err"); if ok then again() end end },
                { label = "Load", style = "blue", fn = function()
                    local n = U.setupName ~= "" and U.setupName or (U.pick or "")
                    local ok, msg = Snd.loadSetup(n); toast(msg, ok and "ok" or "err")
                    U.song, U.sfx, U.rule = nil, nil, nil; again()
                end },
                { label = "Delete", style = "red", confirm = true, fn = function()
                    local n = U.setupName ~= "" and U.setupName or (U.pick or "")
                    local ok, msg = Snd.deleteSetup(n); toast(msg, ok and "ok" or "err"); if ok then U.pick = nil; U.setupName = ""; again() end
                end },
            } },
        } }
    end

    function Snd.build()
        local secs = { playerSection() }
        for _, s in ipairs(songSections()) do secs[#secs + 1] = s end
        for _, s in ipairs(sfxSections()) do secs[#secs + 1] = s end
        for _, s in ipairs(emitterSections()) do secs[#secs + 1] = s end
        for _, s in ipairs(ruleSections()) do secs[#secs + 1] = s end
        secs[#secs + 1] = browserSection()
        secs[#secs + 1] = mixerSection()
        secs[#secs + 1] = setupSection()
        return secs
    end
end)()

--#endregion page-sound
--#region binds
----------------------------------------------------------------------
-- KEYBINDS AND ON-SCREEN BUTTONS FOR TOGGLES
-- Right-click any toggle in the hub for a menu: set a keybind, add an on-screen button. A toggle is found again by an id made of its tab,
-- its section and its text, so binds survive restarts and are saved inside configs (Features.binds).
--  * keybinds use the same key capture as the hub key, and never fire while you are typing in a text box
--  * on-screen buttons live in their own ScreenGui, are drawn with the skin's own Button, and are rebuilt when the skin changes.
--    Click = flip the toggle, drag = move, right-click = menu (remove). They light up while the toggle is on.
----------------------------------------------------------------------
local Binds = { map = {}, reg = {}, btns = {}, gui = nil, menuGui = nil, flash = nil }
UI.binds = Binds

local BIND_AMBIGUOUS = { Enabled = true, Fill = true }     -- toggle names that repeat in every section: the section name is added in front

local function bindTab(tabId)
    for _, t in ipairs(UI.tabs) do if t.id == tabId then return t end end
end

-- called for every toggle a page draws: remembers it (so a hotkey can flip it) and returns its id
function Binds.track(tabId, sec, c)
    local label = tostring(c.text)
    if BIND_AMBIGUOUS[label] then label = tostring(sec.title) .. ": " .. label end
    local id = tostring(tabId) .. "|" .. tostring(sec.title) .. "|" .. tostring(c.text)
    Binds.reg[id] = { c = c, label = label, tab = tabId }
    local m = Binds.map[id]
    if m then m.label = label end
    return id
end

function Binds.hint(h)
    local tip = "Right-click for a keybind or an on-screen button."
    return (h and h ~= "") and (h .. "  " .. tip) or tip
end

-- finds a toggle by id. If its page has not been drawn this session, the page's sections are built once to find it.
function Binds.resolve(id)
    if Binds.reg[id] then return Binds.reg[id] end
    local tabId = id:match("^([^|]*)|")
    local tab = tabId and bindTab(tabId)
    if not tab or tabId == "binds" then return nil end
    local ok, secs = pcall(tab.build)
    if not ok or type(secs) ~= "table" then return nil end
    for _, sec in ipairs(secs) do
        for _, c in ipairs(sec.controls or {}) do
            if c.t == "toggle" then Binds.track(tabId, sec, c) end
        end
    end
    return Binds.reg[id]
end

local function bindEntry(id)
    local m = Binds.map[id]
    if not m then
        local r = Binds.reg[id]
        m = { label = r and r.label or id }
        Binds.map[id] = m
    end
    return m
end
local function bindPrune(id)
    local m = Binds.map[id]
    if m and not m.key and not m.btn then Binds.map[id] = nil end
end

local function bindGuiOn()
    if Binds.gui and Binds.gui.Parent then return Binds.gui end
    if not T then return nil end            -- the skin is not built yet (a config auto-loads before the hub exists)
    local g = New("ScreenGui", { Name = "TonyScriptPalaceButtons", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
    g.Parent = guiParent()
    if T.kind == "aero" then g.DescendantAdded:Connect(lowerize) end
    Binds.gui = g
    return g
end

-- a small message in the top middle of the screen, so a hotkey gives feedback even while the hub is hidden
function Binds.notice(msg)
    local g = bindGuiOn()
    if not g then return end
    if Binds.flash then pcall(function() Binds.flash:Destroy() end) end
    local f = New("TextLabel", { Text = msg, Font = T.F.bold, TextSize = 17, TextColor3 = WHITE, BackgroundColor3 = C(20, 20, 24),
        BackgroundTransparency = 0.2, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58),
        Size = UDim2.fromOffset(math.clamp(#msg * 9 + 36, 150, 560), 34), ZIndex = 5 }, g)
    corner(f, 8); stroke(f, T.accent, 2, 0)
    Binds.flash = f
    task.delay(1.7, function() if Binds.flash == f then Binds.flash = nil end; if f.Parent then f:Destroy() end end)
end

function Binds.flip(id)
    local e = Binds.resolve(id)
    local label = (e and e.label) or (Binds.map[id] and Binds.map[id].label) or "That toggle"
    if not e then Binds.notice(label .. " isn't available right now."); return end
    local ok, cur = pcall(e.c.get)
    if not ok then Binds.notice(label .. " isn't available right now."); return end
    pcall(e.c.set, not cur)
    local ok2, now = pcall(e.c.get)
    Binds.notice(label .. ": " .. ((ok2 and now) and "On" or "Off"))
    if UI.visible then pcall(refreshPage) end        -- so an open page shows the new state
end

-- a keyboard key was pressed: flips every toggle bound to it. Returns true when something was bound to that key.
function Binds.onKey(name)
    local hit = false
    for id, m in pairs(Binds.map) do
        if m.key == name then hit = true; task.spawn(Binds.flip, id) end
    end
    return hit
end

-- ---------------------------------------------------------------- the menu (lives in its own ScreenGui so it also works with the hub hidden)
local function bindCloseMenu()
    if Binds.menuGui then pcall(function() Binds.menuGui:Destroy() end); Binds.menuGui = nil end
end
local function bindMenu(title, items)
    bindCloseMenu()
    if not T then return end
    local g = New("ScreenGui", { Name = "TonyScriptPalaceMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1001 })
    g.Parent = guiParent()
    if T.kind == "aero" then g.DescendantAdded:Connect(lowerize) end
    Binds.menuGui = g
    local blocker = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, g)
    blocker.MouseButton1Click:Connect(bindCloseMenu)
    blocker.MouseButton2Click:Connect(bindCloseMenu)
    local w, bh, gap, th = 250, 32, 4, 26
    local h = th + #items * (bh + gap) + gap
    local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local m = UIS:GetMouseLocation()
    local x = math.clamp(m.X, 4, math.max(vs.X - w - 4, 4))
    local y = math.clamp(m.Y, 4, math.max(vs.Y - h - 4, 4))
    local panel = New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = C(28, 28, 34),
        BackgroundTransparency = 0.06, BorderSizePixel = 0, Active = true }, blocker)
    corner(panel, 10); stroke(panel, T.accent, 2, 0)
    New("TextLabel", { BackgroundTransparency = 1, Text = title, Font = T.F.bold, TextSize = 15, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = AL, Position = UDim2.fromOffset(10, 3), Size = UDim2.fromOffset(w - 20, th - 4) }, panel)
    for i, it in ipairs(items) do
        Button(panel, it.text, UDim2.fromOffset(w - gap * 2, bh), it.style or "glass", function()
            bindCloseMenu()
            if it.fn then it.fn() end
        end, { pos = UDim2.fromOffset(gap, th + gap + (i - 1) * (bh + gap)), size = 14 })
    end
end

-- ---------------------------------------------------------------- on-screen buttons
local function bindNextPos()
    local n = 0
    for _, m in pairs(Binds.map) do if m.btn then n += 1 end end
    return { x = 0.1 + 0.11 * math.floor(n / 8), y = 0.22 + 0.075 * (n % 8) }
end

local function bindIsOn(id)
    local e = Binds.reg[id]
    if not e then return false end
    local ok, v = pcall(e.c.get)
    return ok and v and true or false
end

local function bindMakeButton(g, id, m)
    Binds.resolve(id)                   -- finds the toggle even when its page was never opened this session
    local on = bindIsOn(id)
    local label = m.label or id
    local b = Button(g, label, UDim2.fromOffset(math.clamp(#label * 8 + 30, 100, 300), 38), on and "blue" or "glass", nil, { size = 15 })
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = UDim2.fromScale(m.btn.x, m.btn.y)
    Binds.btns[id] = { obj = b, on = on }
    local moved = false
    b.InputBegan:Connect(function(i)
        if isPress(i) then
            moved = false
            local start = Vector2.new(i.Position.X, i.Position.Y)
            local vs0 = g.AbsoluteSize           -- (not b.AbsolutePosition: on an IgnoreGuiInset gui it reads one top-bar inset too high, which made the button jump up)
            local origin = Vector2.new(m.btn.x * vs0.X, m.btn.y * vs0.Y)
            activeDrag = function(pos)
                local d = Vector2.new(pos.X, pos.Y) - start
                if not moved and d.Magnitude < 6 then return end
                moved = true
                local vs = g.AbsoluteSize
                local np = origin + d
                m.btn.x, m.btn.y = math.clamp(np.X / math.max(vs.X, 1), 0.02, 0.98), math.clamp(np.Y / math.max(vs.Y, 1), 0.02, 0.98)
                b.Position = UDim2.fromScale(m.btn.x, m.btn.y)
            end
        elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
            bindMenu(label, {
                { text = "Remove This Button", style = "red", fn = function() m.btn = nil; bindPrune(id); Binds.rebuild(); if UI.visible then pcall(refreshPage) end end },
                { text = m.key and ("Change Keybind (" .. m.key .. ")") or "Set Keybind", fn = function() Binds.captureKey(id) end },
                { text = "Cancel" },
            })
        end
    end)
    b.MouseButton1Click:Connect(function()
        if moved then moved = false; return end
        Binds.flip(id)
    end)
end

function Binds.rebuild()
    if Binds.gui then pcall(function() Binds.gui:Destroy() end); Binds.gui = nil end
    table.clear(Binds.btns)
    if not T then return end
    local any = false
    for _, m in pairs(Binds.map) do if m.btn then any = true end end
    if not any then return end
    local g = bindGuiOn()
    if not g then return end
    local ids = {}
    for id, m in pairs(Binds.map) do if m.btn then ids[#ids + 1] = id end end
    table.sort(ids)
    for _, id in ipairs(ids) do pcall(bindMakeButton, g, id, Binds.map[id]) end
end

function Binds.destroy()
    bindCloseMenu()
    if Binds.gui then pcall(function() Binds.gui:Destroy() end); Binds.gui = nil end
end

-- the buttons show the toggle's state, which can change from anywhere (the hub, a config, a hotkey)
task.spawn(function()
    while alive do
        task.wait(0.25)
        if Binds.gui and Binds.gui.Parent and not activeDrag then
            for id, b in pairs(Binds.btns) do
                if bindIsOn(id) ~= b.on then pcall(Binds.rebuild); break end
            end
        end
    end
end)

-- ---------------------------------------------------------------- set a key / add or remove a button
function Binds.captureKey(id)
    local m0 = Binds.map[id]
    local r = Binds.reg[id]
    local label = (r and r.label) or (m0 and m0.label) or id
    Binds.notice("Press a key for " .. label .. "  (Esc cancels)")
    listening = function(name)
        if not name then Binds.notice("Keybind cancelled."); return end
        if name == S.keybind then Binds.notice(name .. " is the key that shows and hides the hub. Pick another."); return end
        local m = bindEntry(id)
        m.key = name
        Binds.notice(label .. " is now on " .. name)
        if UI.visible then pcall(refreshPage) end
    end
end

function Binds.addButton(id)
    local m = bindEntry(id)
    if not m.btn then m.btn = bindNextPos() end
    Binds.rebuild()
    if UI.visible then pcall(refreshPage) end
end

function Binds.removeButton(id)
    local m = Binds.map[id]
    if m then m.btn = nil; bindPrune(id) end
    Binds.rebuild()
    if UI.visible then pcall(refreshPage) end
end

function Binds.clearKey(id)
    local m = Binds.map[id]
    if m then m.key = nil; bindPrune(id) end
    if UI.visible then pcall(refreshPage) end
end

-- the right-click menu of a toggle
function Binds.menu(id)
    local r = Binds.reg[id]
    local m = Binds.map[id]
    local items = { { text = (m and m.key) and ("Change Keybind (" .. m.key .. ")") or "Set Keybind", fn = function() Binds.captureKey(id) end } }
    if m and m.key then items[#items + 1] = { text = "Clear Keybind", fn = function() Binds.clearKey(id) end } end
    if m and m.btn then items[#items + 1] = { text = "Remove On-Screen Button", style = "red", fn = function() Binds.removeButton(id) end }
    else items[#items + 1] = { text = "Add On-Screen Button", fn = function() Binds.addButton(id) end } end
    items[#items + 1] = { text = "Cancel" }
    bindMenu((r and r.label) or id, items)
end

-- extras drawn on a toggle's row: the right-click menu and a small tag showing what is bound
function Binds.decorate(row, c, id, fixedW)
    row.MouseButton2Click:Connect(function() Binds.menu(id) end)
    local m = Binds.map[id]
    if m and (m.key or m.btn) then
        local tag = (m.key and ("[" .. m.key .. "]") or "") .. ((m.key and m.btn) and " " or "") .. (m.btn and "(button)" or "")
        New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(fixedW + 18), 0.5, 0),
            Size = UDim2.fromOffset(120, 18), Text = tag, Font = T.F.semi, TextSize = 13, TextColor3 = T.dim, TextXAlignment = AR }, row)
    end
end

-- ---------------------------------------------------------------- saved inside configs
Features.binds = {
    serialize = function()
        local list = {}
        for id, m in pairs(Binds.map) do
            list[#list + 1] = { id = id, label = m.label, key = m.key, x = m.btn and m.btn.x or nil, y = m.btn and m.btn.y or nil }
        end
        table.sort(list, function(a, b) return a.id < b.id end)
        return { list = list }
    end,
    apply = function(d)
        if type(d) ~= "table" or type(d.list) ~= "table" then return end
        local map = {}
        for _, e in ipairs(d.list) do
            if type(e) == "table" and type(e.id) == "string" and e.id ~= "" then
                local m = { label = tostring(e.label or e.id) }
                if type(e.key) == "string" and e.key ~= "" and pcall(function() return Enum.KeyCode[e.key] end) then m.key = e.key end
                if type(e.x) == "number" and type(e.y) == "number" then m.btn = { x = math.clamp(e.x, 0.02, 0.98), y = math.clamp(e.y, 0.02, 0.98) } end
                if m.key or m.btn then map[e.id] = m end
            end
        end
        Binds.map = map
        pcall(Binds.rebuild)
        if UI.visible then pcall(refreshPage) end
    end,
}

-- ---------------------------------------------------------------- the Keybinds tab
local bindPick = { tab = "esp", label = nil }

local function bindToggleList(tabId)
    local out, seen = {}, {}
    local tab = bindTab(tabId)
    if not tab then return out end
    local ok, secs = pcall(tab.build)
    if not ok or type(secs) ~= "table" then return out end
    for _, sec in ipairs(secs) do
        for _, c in ipairs(sec.controls or {}) do
            if c.t == "toggle" then
                local id = Binds.track(tabId, sec, c)
                local label = Binds.reg[id].label
                seen[label] = (seen[label] or 0) + 1
                if seen[label] > 1 then label = label .. " (" .. seen[label] .. ")" end
                out[#out + 1] = { id = id, label = label }
            end
        end
    end
    return out
end

local function buildBindsPage()
    local secs = {}
    -- Your binds
    local ids = {}
    for id in pairs(Binds.map) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return (Binds.map[a].label or a):lower() < (Binds.map[b].label or b):lower() end)
    local mine = { { t = "text", text = "Every toggle can have a keybind and an on-screen button. Right-click any toggle in the hub to make one, or use Add A Bind below. They are saved inside configs, so each config can have its own set. Click an on-screen button to flip its toggle, drag it to move it, right-click it for a menu." } }
    if #ids == 0 then
        mine[#mine + 1] = { t = "text", text = "No binds yet." }
    end
    for _, id in ipairs(ids) do
        local m = Binds.map[id]
        mine[#mine + 1] = { t = "keybind", text = m.label or id, get = function() return m.key or "None" end,
            set = function(name)
                if name == S.keybind then toast(name .. " is the key that shows and hides the hub. Pick another.", "err"); return end
                m.key = name; if UI.visible then pcall(refreshPage) end
            end }
        mine[#mine + 1] = { t = "buttons", items = {
            { label = m.btn and "Remove Button" or "Add Button", fn = function() if m.btn then Binds.removeButton(id) else Binds.addButton(id) end end },
            { label = "Clear Key", fn = function() Binds.clearKey(id) end },
            { label = "Delete Bind", style = "red", fn = function() Binds.map[id] = nil; Binds.rebuild(); refreshPage() end },
        } }
    end
    secs[#secs + 1] = { title = "Your Binds", controls = mine }

    -- Add a bind without right-clicking (also works on touch)
    local tabNames, tabIdOf, nameOf = {}, {}, {}
    for _, t in ipairs(UI.tabs) do
        if t.id ~= "binds" and t.id ~= "configs" then tabNames[#tabNames + 1] = t.name; tabIdOf[t.name] = t.id; nameOf[t.id] = t.name end
    end
    local toggles = bindToggleList(bindPick.tab)
    local labels, byLabel = {}, {}
    for _, e in ipairs(toggles) do labels[#labels + 1] = e.label; byLabel[e.label] = e.id end
    if not (bindPick.label and byLabel[bindPick.label]) then bindPick.label = labels[1] end
    local function pickedId() return bindPick.label and byLabel[bindPick.label] end
    secs[#secs + 1] = { title = "Add A Bind", controls = {
        { t = "text", text = "Pick a tab and one of its toggles, then give it a keybind or an on-screen button." },
        { t = "dropdown", text = "Tab", get = function() return nameOf[bindPick.tab] or "ESP" end, options = function() return tabNames end,
            set = function(o) bindPick.tab = tabIdOf[o] or "esp"; bindPick.label = nil; refreshPage() end },
        { t = "dropdown", text = "Toggle", get = function() return bindPick.label or "(none)" end, options = function() return labels end,
            set = function(o) bindPick.label = o; refreshPage() end },
        { t = "buttons", items = {
            { label = "Set A Keybind", fn = function() local id = pickedId(); if id then Binds.captureKey(id) end end },
            { label = "Add On-Screen Button", fn = function() local id = pickedId(); if id then Binds.addButton(id) end end },
        } },
    } }

    secs[#secs + 1] = { title = "On-Screen Buttons", controls = {
        { t = "text", text = "Put every on-screen button back in a tidy column, or take them all away. Keybinds are not affected." },
        { t = "buttons", items = {
            { label = "Tidy Up Buttons", fn = function()
                local n = 0
                local order = {}
                for id, m in pairs(Binds.map) do if m.btn then order[#order + 1] = id end end
                table.sort(order)
                for _, id in ipairs(order) do Binds.map[id].btn = { x = 0.1 + 0.11 * math.floor(n / 8), y = 0.22 + 0.075 * (n % 8) }; n += 1 end
                Binds.rebuild()
            end },
            { label = "Remove All Buttons", style = "red", confirm = true, fn = function()
                for id, m in pairs(Binds.map) do m.btn = nil end
                for id in pairs(Binds.map) do bindPrune(id) end
                Binds.rebuild(); refreshPage()
            end },
        } },
    } }
    return secs
end
Binds.buildPage = buildBindsPage

--#endregion binds
--#region tabs
do
-- every master switch in one entry. Configs saved before this existed have no "switches" entry, so loading one of those leaves your switches alone.
Features.switches = {
    serialize = function()
        local pc = Fun.Pur.Cfg
        return {
            SpeedModifier = Speed.Enabled, InfiniteStamina = Stam.Infinite, AutoRun = Stam.AutoRun,
            Noclip = SP.noclipOn(), Fullbright = SP.fullbrightOn(), HideIchorSplats = SP.hideIchorOn(),
            AutoDefault = Auto.Default, AutoCircle = Auto.Circle, AutoTreadmill = Auto.Treadmill, AutoSwimmy = Auto.Swimmy, AutoInstant = Auto.Instant,
            Pursuer = pc.Enabled, MoreSkillChecks = Fun.Enabled,
        }
    end,
    apply = function(d)
        if type(d) ~= "table" then return end
        local function has(k) return type(d[k]) == "boolean" end
        if has("SpeedModifier") then Speed.Enabled = d.SpeedModifier end
        if has("InfiniteStamina") then Stam.Infinite = d.InfiniteStamina end
        if has("AutoRun") then Stam.AutoRun = d.AutoRun end
        if has("Noclip") and SP.noclipOn() ~= d.Noclip then SP.setNoclip(d.Noclip) end
        if has("Fullbright") then SP.setFullbright(d.Fullbright) end
        if has("HideIchorSplats") then SP.setHideIchor(d.HideIchorSplats) end
        for k, key in pairs({ AutoDefault = "Default", AutoCircle = "Circle", AutoTreadmill = "Treadmill", AutoSwimmy = "Swimmy", AutoInstant = "Instant" }) do
            if has(k) then Auto[key] = d[k] end
        end
        if has("Pursuer") then
            local pc = Fun.Pur.Cfg
            local was = pc.Enabled
            pc.Enabled = d.Pursuer
            if was and not d.Pursuer then pcall(Fun.Pur.despawn, true) end
        end
        if has("MoreSkillChecks") then Fun.Enabled = d.MoreSkillChecks; Fun.Status = d.MoreSkillChecks and "On" or "Off" end
    end,
}
Features.customizer = { serialize = function() return Cust.serialize() end, apply = function(d) Cust.apply(d) end }
Features.sound = { serialize = function() return UI.snd.serialize() end, apply = function(d) UI.snd.apply(d) end }

-- puts a page's sections into rail groups: spec[title] = { g = group, t = shorter title, pin = keep it beside the other sections on wide windows }
local function grouped(build, spec)
    return function()
        local secs = build()
        for _, sec in ipairs(secs) do
            local m = spec[sec.title]
            if m then
                sec.group = m.g
                if m.pin then sec.pin = true end
                if m.t then sec.title = m.t end
                if m.r then sec.rail = m.r end
            end
        end
        return secs
    end
end

local ESP_GROUPS = {
    ["General"] = { g = "Basics" },
    ["Toons"] = { g = "Players" },
    ["Twisteds"] = { g = "Twisteds" },
    ["Twisted Sprout's Tendrils"] = { g = "Hazards", r = "Sprout's Tendrils" },   -- the full name is 25 characters, too wide for the rail in most skins
    ["Twisted Blot's Hands"] = { g = "Hazards", r = "Blot's Hands" }, ["Ichor Puddles"] = { g = "Hazards" },
    ["Machines"] = { g = "Objects" }, ["Trick or Treat Doors"] = { g = "Objects" }, ["Bookshelves"] = { g = "Objects" },
    ["Items"] = { g = "Items" }, ["Item Colors"] = { g = "Items" }, ["Star Pillows"] = { g = "Items" },
}
local SKILL_GROUPS = {
    ["More Skill Checks"] = { g = "Basics", t = "Main" }, ["Live Values"] = { g = "Basics" },
    ["Size, Speed, Chance And Value"] = { g = "Tuning", t = "Size, Speed, Chance" }, ["Per-Twisted Changes"] = { g = "Tuning" },
    ["Gold Rewards"] = { g = "Tuning" }, ["Failure Penalties"] = { g = "Tuning" },
    ["Stacking"] = { g = "Extras" }, ["Trinkets"] = { g = "Extras" }, ["Treadmill Failure And Icons"] = { g = "Extras", t = "Treadmill And Icons" },
}
local PURSUER_GROUPS = {
    ["Pursuer (Custom Chaser)"] = { g = "Setup", t = "Main" }, ["Pursuer: Saved Pursuers"] = { g = "Setup", t = "Saved Pursuers" },
    ["Pursuer: Look And Preview"] = { g = "Setup", t = "Look And Preview" },
    ["Pursuer: Movement And Speed"] = { g = "Behavior", t = "Movement And Speed" }, ["Pursuer: Dash"] = { g = "Behavior", t = "Dash" }, ["Pursuer: Spawning"] = { g = "Behavior", t = "Spawning" },
    ["Pursuer: Chase Alert"] = { g = "Extras", t = "Chase Alert" }, ["Pursuer: Sounds"] = { g = "Extras", t = "Sounds" }, ["Pursuer: Afterimages"] = { g = "Extras", t = "Afterimages" },
}
local CUSTOMIZER_GROUPS = {
    ["Preview"] = { g = "View", pin = true },
    ["Status"] = { g = "Model" }, ["Model Sources"] = { g = "Model" },
    ["Textures"] = { g = "Look" }, ["Animations"] = { g = "Look" }, ["Parts"] = { g = "Look" }, ["2D Character"] = { g = "Look" },
    ["Customizer Configs"] = { g = "Library" }, ["Files & Library"] = { g = "Library" },
}
local SOUND_GROUPS = {
    ["Player"] = { g = "Music" }, ["Songs"] = { g = "Music" }, ["Song Editor"] = { g = "Music" },
    ["Sound Effects"] = { g = "Effects" }, ["Effect Editor"] = { g = "Effects" },
    ["Game Sound Replacement"] = { g = "Game Audio", t = "Replace Sounds" }, ["Replacement Editor"] = { g = "Game Audio" },
    ["Twisted Emitters"] = { g = "Game Audio" }, ["Emitter Editor"] = { g = "Game Audio" },
    ["Sound Browser"] = { g = "Game Audio" }, ["Game Mixer"] = { g = "Game Audio" },
    ["Setups"] = { g = "Setups" },
}

UI.tabs = {
    { id = "esp",        name = "ESP",          icon = "esp",        build = grouped(buildESPPage, ESP_GROUPS) },
    { id = "movement",   name = "Movement",     icon = "movement",   build = buildMovementPage },
    { id = "world",      name = "World",        icon = "world",      build = buildWorldPage },
    { id = "screen",     name = "Screen",       icon = "esp",        build = buildScreenPage },
    { id = "automation", name = "Automation",   icon = "automation", build = buildAutomationPage },
    { id = "fun",        name = "Skill Checks", icon = "fun",        build = grouped(buildFunPage, SKILL_GROUPS) },
    { id = "pursuer",    name = "Pursuer",      icon = "fun",        build = grouped(buildPursuerPage, PURSUER_GROUPS) },
    { id = "customizer", name = "Customizer",   icon = "customizer", build = grouped(Cust.build, CUSTOMIZER_GROUPS) },
    { id = "sound",      name = "Sound",        icon = "fun",        build = grouped(UI.snd.build, SOUND_GROUPS) },   -- icon: reusing "fun" until the skins get a speaker icon
    { id = "binds",      name = "Keybinds",     icon = "automation", build = grouped(Binds.buildPage, {}) },
    { id = "configs",    name = "Configs",      icon = "configs",    build = buildConfigsPage },
    { id = "appearance", name = "Appearance",   icon = "appearance", build = buildAppearancePage },
}

end
--#endregion tabs
--#region window-behaviour
----------------------------------------------------------------------
-- WINDOW BEHAVIOUR
----------------------------------------------------------------------
function UI.setVisible(v)
    UI.visible = v and true or false
    closePopup()
    ui(UI.visible and "open" or "close")
    if Win then Win.Visible = UI.visible end
    if Orb then Orb.Visible = (not UI.visible) and S.orb end
end

function applyLayout()
    if not (Win and UIScaleObj) then return end
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local sc = S.fullscreen and 1 or S.scale
    UIScaleObj.Scale = sc
    if S.fullscreen then
        Win.Position = UDim2.fromOffset(0, 0); Win.Size = UDim2.fromScale(1, 1)
    else
        local ws = S.win[S.style]
        local w = math.clamp(ws.w, T.minW, math.max(vp.X / sc - 16, T.minW))
        local h = math.clamp(ws.h, T.minH, math.max(vp.Y / sc - 16, T.minH))
        Win.Size = UDim2.fromOffset(w, h)
        local px, py
        if S.pos then px, py = S.pos.x, S.pos.y else px, py = (vp.X - w * sc) / 2, (vp.Y - h * sc) / 2 end
        px = math.clamp(px, 0, math.max(vp.X - 120, 0)); py = math.clamp(py, 0, math.max(vp.Y - 60, 0))
        Win.Position = UDim2.fromOffset(px, py)
    end
    if Grip then Grip.Visible = not S.fullscreen end
end

local function makeDraggable(handle)
    handle.InputBegan:Connect(function(i)
        if isPress(i) and not S.fullscreen then
            local sp, wp = i.Position, Win.Position
            activeDrag = function(p)
                local cam = Workspace.CurrentCamera
                local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
                local nx = math.clamp(wp.X.Offset + (p.X - sp.X), -(Win.AbsoluteSize.X - 120), vp.X - 120)
                local ny = math.clamp(wp.Y.Offset + (p.Y - sp.Y), 0, vp.Y - 40)
                Win.Position = UDim2.fromOffset(nx, ny)
                S.pos = { x = nx, y = ny }; dirty = true
            end
        end
    end)
end

local function makeGrip()
    Grip = New("TextButton", { Name = "Grip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(22, 22), ZIndex = 10 }, Win)
    for r = 0, 2 do
        for k = 0, r do
            local d = New("Frame", { BackgroundColor3 = (T.kind == "aero" and T.text) or (T.kind == "xp" and C(140, 140, 130)) or WHITE, BackgroundTransparency = 0.45, BorderSizePixel = 0,
                Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(16 - 5 * (r - k), 16 - 5 * k), ZIndex = 10 }, Grip)
            corner(d, 2)
        end
    end
    Grip.InputBegan:Connect(function(i)
        if isPress(i) and not S.fullscreen then
            local sp = i.Position
            local ws = S.win[S.style]
            local w0, h0, sc = ws.w, ws.h, UIScaleObj.Scale
            activeDrag = function(p)
                local cam = Workspace.CurrentCamera
                local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
                local nw = math.clamp(w0 + (p.X - sp.X) / sc, T.minW, math.max(vp.X / sc - 16, T.minW))
                local nh = math.clamp(h0 + (p.Y - sp.Y) / sc, T.minH, math.max(vp.Y / sc - 16, T.minH))
                S.win[S.style] = { w = nw, h = nh }
                Win.Size = UDim2.fromOffset(nw, nh); dirty = true
            end
        end
    end)
end

local function makeOrb()
    local aero = T.kind == "aero"
    local xp = T.kind == "xp"
    Orb = New("TextButton", { Name = "Orb", Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(46, 46),
        Position = UI.orbPos or UDim2.new(0, 18, 1, -70), BorderSizePixel = 0, Visible = (not UI.visible) and S.orb }, gui)
    corner(Orb, 23)
    if T.kind == "dandy" then
        Orb.BackgroundColor3 = T.accent; grad(Orb, WHITE, C(170, 170, 170), 90); stroke(Orb, BLACK, 3, 0)
    elseif aero then
        grad(Orb, T.accent:Lerp(WHITE, 0.55), T.accent, 90); stroke(Orb, WHITE, 2, 0.1); gloss(Orb, 23, 0.1, 0.8)
    elseif xp then   -- little green "Start" button
        grad(Orb, C(130, 215, 100), C(35, 130, 30), 90); stroke(Orb, WHITE, 2, 0.1); gloss(Orb, 23, 0.2, 0.85)
    else
        Orb.BackgroundColor3 = T.c.top; Orb.BackgroundTransparency = 0.15; stroke(Orb, WHITE, 2, 0.3)
    end
    New("TextLabel", { BackgroundTransparency = 1, Text = "T", Font = T.F.bold, TextSize = 22, TextColor3 = WHITE,
        TextStrokeTransparency = (aero or xp or T.kind == "dandy") and 0.5 or 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, Orb)
    local moved = false
    Orb.MouseEnter:Connect(function() ui("hover") end)
    Orb.InputBegan:Connect(function(i)
        if isPress(i) then
            local sp, op = i.Position, Orb.Position
            moved = false
            activeDrag = function(p)
                local dx, dy = p.X - sp.X, p.Y - sp.Y
                if math.abs(dx) + math.abs(dy) > 4 then moved = true end
                if not moved then return end
                local sz = gui.AbsoluteSize
                local nx = math.clamp(op.X.Offset + dx, 0, math.max(sz.X - 46, 0))
                local ny = op.Y.Offset + dy
                Orb.Position = UDim2.new(op.X.Scale, nx, op.Y.Scale, ny)
                UI.orbPos = Orb.Position
            end
        end
    end)
    Orb.MouseButton1Click:Connect(function()
        if moved then moved = false; return end
        UI.setVisible(true)
    end)
end

--#endregion window-behaviour
--#region skin-dandy
----------------------------------------------------------------------
-- SKIN: DANDY'S WORLD (default)
----------------------------------------------------------------------
local function buildDandyChrome()
    local c = T.c
    Win.BackgroundColor3 = c.panel; Win.ClipsDescendants = true
    corner(Win, 14)
    local winStroke = stroke(Win, BLACK, 4, 0)
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.55, C(140, 140, 140)), ColorSequenceKeypoint.new(1, C(92, 92, 92)) }) }, Win)
    New("ImageLabel", { Name = "Stripes", BackgroundTransparency = 1, Image = "rbxassetid://6794283750", ImageColor3 = C(211, 211, 211), ImageTransparency = 0.94,
        ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(56, 56), Size = UDim2.fromScale(1, 1) }, Win)

    -- title bar
    local Title = New("Frame", { Name = "Title", BackgroundColor3 = C(15, 15, 15), BackgroundTransparency = 0.1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 46) }, Win)
    corner(Title, 10); stroke(Title, BLACK, 3, 0)
    local titleLbl = New("TextLabel", { BackgroundTransparency = 1, Text = "Tony Script Palace", Font = F_DANDY.bold, TextSize = 26, TextColor3 = c.header,
        TextStrokeTransparency = 0, TextStrokeColor3 = BLACK, TextXAlignment = AL, Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(250, 46) }, Title)
    New("TextLabel", { BackgroundTransparency = 1, Text = "for Dandy's World only", Font = F_DANDY.reg, TextSize = 17, TextColor3 = T.dim,
        TextXAlignment = AL, Position = UDim2.fromOffset(270, 0), Size = UDim2.new(1, -370, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd }, Title)
    local hb = Button(Title, "-", UDim2.fromOffset(34, 30), "glass", function() UI.setVisible(false) end, { size = 22, pos = UDim2.new(1, -80, 0.5, -15) })
    hb.ZIndex = 5
    local armed = false
    local xb, xl
    xb, xl = Button(Title, "x", UDim2.fromOffset(34, 30), "red", function()
        if not armed then
            armed = true; xl.Text = "?"
            toast("Click again to delete the GUI.", "info")
            task.delay(2.5, function() armed = false; if xl.Parent then xl.Text = "x" end end)
            return
        end
        Destroy()
    end, { size = 18, pos = UDim2.new(1, -40, 0.5, -15) })
    xb.ZIndex = 5
    makeDraggable(Title)

    if S.dandy.preset == "Lethal's World" then   -- rainbow preset: the title and the window outline cycle through the hues
        gconnect(RunService.Heartbeat, function()
            if not Win.Visible then return end
            local h = (os.clock() * 0.25) % 1
            titleLbl.TextColor3 = Color3.fromHSV(h, 0.75, 1)
            winStroke.Color = Color3.fromHSV((h + 0.5) % 1, 0.8, 0.55)
        end)
    end

    -- tab column
    local Side = New("Frame", { BackgroundColor3 = C(15, 15, 15), BackgroundTransparency = 0.3, BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 64), Size = UDim2.new(0, 178, 1, -104) }, Win)
    corner(Side, 10); stroke(Side, BLACK, 3, 0)
    local tabList = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16), ScrollBarThickness = 3, ScrollBarImageColor3 = c.header, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Side)
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local function buildTabs()
        clearGui(tabList)
        for i, tb in ipairs(UI.tabs) do
            local b = Button(tabList, tb.name, UDim2.new(1, -4, 0, 40), (tb.id == UI.current) and "blue" or "glass", function() setTab(tb.id) end, { size = 17, align = AL, pad = 12 })
            b.LayoutOrder = i
        end
    end
    buildTabs()
    UI.onTab = buildTabs

    -- content (wrapped into the rail + page + pinned pane layout by makePane)
    Content = New("ScrollingFrame", { Name = "Content", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(198, 64),
        Size = UDim2.new(1, -208, 1, -104), ScrollBarThickness = 6, ScrollBarImageColor3 = c.header, CanvasSize = UDim2.new(), Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, Win)
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Content)
    New("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4) }, Content)

    StatusLbl = Label(Win, statusDefault(), UDim2.new(0, 18, 1, -34), UDim2.new(1, -70, 0, 24), { size = 16, color = T.dim })
end

--#endregion skin-dandy
--#region skin-aero
----------------------------------------------------------------------
-- SKIN: FRUTIGER AERO
----------------------------------------------------------------------
local function buildAeroChrome()
    local c = T.c
    Win.ClipsDescendants = true
    corner(Win, 18); stroke(Win, WHITE, 2.5, 0.15)
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c.top), ColorSequenceKeypoint.new(0.55, c.mid), ColorSequenceKeypoint.new(1, c.bottom) }) }, Win)

    -- floating bubbles
    local bubbles = {}
    for i = 1, 8 do
        local d = math.random(34, 100)
        local bub = New("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.8, BorderSizePixel = 0, Size = UDim2.fromOffset(d, d) }, Win)
        corner(bub, d); stroke(bub, WHITE, 1.5, 0.45)
        New("UIGradient", { Rotation = 45, Transparency = NumberSequence.new(0.35, 0.95) }, bub)
        bubbles[i] = { f = bub, sx = math.random(5, 90) / 100, sy = math.random(15, 90) / 100, sp = 0.25 + math.random() * 0.4,
            ph = math.random() * 6.28, amp = 5 + math.random() * 9 }
    end
    local bubbleFrame = 0
    gconnect(RunService.Heartbeat, function()
        if not Win.Visible then return end
        bubbleFrame += 1
        if bubbleFrame % 2 ~= 0 then return end
        local t = os.clock()
        for _, b in ipairs(bubbles) do
            b.f.Position = UDim2.new(b.sx, math.sin(t * b.sp + b.ph) * b.amp, b.sy, math.cos(t * b.sp * 0.8 + b.ph) * b.amp)
        end
    end)

    -- title bar
    local Title = New("Frame", { Name = "Title", BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 38) }, Win)
    corner(Title, 12); grad(Title, c.accent:Lerp(WHITE, 0.5), c.accent:Lerp(BLACK, 0.12), 90)
    stroke(Title, c.accent:Lerp(BLACK, 0.45), 1.5, 0.1); gloss(Title, 12, 0.15, 0.85)
    New("TextLabel", { BackgroundTransparency = 1, Text = "Tony Script Palace", Font = F_AERO.bold, TextSize = 21, TextColor3 = WHITE,
        TextStrokeTransparency = 0.45, TextStrokeColor3 = c.accent:Lerp(BLACK, 0.5), TextXAlignment = AL,
        Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(200, 38), ZIndex = 4 }, Title)
    New("TextLabel", { BackgroundTransparency = 1, Text = "for Dandy's World only", Font = F_AERO.semi, TextSize = 14,
        TextColor3 = WHITE, TextTransparency = 0.1, TextXAlignment = AL, Position = UDim2.fromOffset(222, 0),
        Size = UDim2.new(1, -310, 1, 0), ZIndex = 4, TextTruncate = Enum.TextTruncate.AtEnd }, Title)
    local hb = Button(Title, "-", UDim2.fromOffset(28, 26), "glass", function() UI.setVisible(false) end, { size = 20, radius = 7, pos = UDim2.new(1, -70, 0.5, -13) })
    hb.ZIndex = 5
    local armed = false
    local xb, xl
    xb, xl = Button(Title, "x", UDim2.fromOffset(28, 26), "red", function()
        if not armed then
            armed = true; xl.Text = "?"
            toast("Click again to delete the GUI.", "info")
            task.delay(2.5, function() armed = false; if xl.Parent then xl.Text = "x" end end)
            return
        end
        Destroy()
    end, { size = 15, radius = 7, pos = UDim2.new(1, -38, 0.5, -13) })
    xb.ZIndex = 5
    makeDraggable(Title)

    -- sidebar
    local Side = New("Frame", { BackgroundColor3 = c.panel, BackgroundTransparency = T.panelT, BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 54), Size = UDim2.new(0, 150, 1, -92) }, Win)
    corner(Side, 14); stroke(Side, WHITE, 1.5, 0.2)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.1, 0.5) }, Side)
    Label(Side, "Menu", UDim2.fromOffset(14, 8), UDim2.fromOffset(100, 22), { font = F_AERO.bold, size = 17 })
    local tabList = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 36),
        Size = UDim2.new(1, -16, 1, -44), ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Side)
    New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local function buildTabs()
        for _, ch in ipairs(tabList:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
        for i, tb in ipairs(UI.tabs) do
            local b = Button(tabList, tb.name, UDim2.new(1, 0, 0, 36), (tb.id == UI.current) and "blue" or "glass", function() setTab(tb.id) end, { size = 16 })
            b.LayoutOrder = i
        end
    end
    buildTabs()
    UI.onTab = buildTabs

    -- content
    Content = New("ScrollingFrame", { Name = "Content", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(172, 54),
        Size = UDim2.new(1, -184, 1, -92), ScrollBarThickness = 6, ScrollBarImageColor3 = c.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, Win)
    New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, Content)
    New("UIPadding", { PaddingRight = UDim.new(0, 8) }, Content)

    StatusLbl = Label(Win, statusDefault(), UDim2.new(0, 18, 1, -32), UDim2.new(1, -64, 0, 22), { size = 15, color = T.dim })
end

--#endregion skin-aero
--#region skin-xmb
----------------------------------------------------------------------
-- SKIN: XMB / PLAYSTATION
----------------------------------------------------------------------
local function drawIcon(parent, id)
    local function circ(x, y, d, filled, th)
        local f = New("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(d, d), BackgroundColor3 = WHITE,
            BackgroundTransparency = filled and 0 or 1, BorderSizePixel = 0 }, parent)
        corner(f, d / 2)
        if not filled then stroke(f, WHITE, th or 3, 0) end
        return f
    end
    if id == "esp" then
        local eye = New("Frame", { Position = UDim2.fromOffset(4, 17), Size = UDim2.fromOffset(56, 30), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
        corner(eye, 15); stroke(eye, WHITE, 3, 0)
        circ(24, 24, 16, true)
    elseif id == "configs" then
        for i = 0, 2 do
            circ(8, 12 + i * 15, 8, true)
            local bar = New("Frame", { Position = UDim2.fromOffset(24, 12 + i * 15), Size = UDim2.fromOffset(34, 8), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, parent)
            corner(bar, 4)
        end
    elseif id == "movement" then
        for i = 0, 2 do
            local bar = New("Frame", { Position = UDim2.fromOffset(6 + i * 8, 14 + i * 15), Size = UDim2.fromOffset(48 - i * 8, 8),
                BackgroundColor3 = WHITE, BorderSizePixel = 0 }, parent)
            corner(bar, 4)
        end
    elseif id == "world" then
        circ(10, 10, 44, false, 4)
        local eq = New("Frame", { Position = UDim2.fromOffset(10, 30), Size = UDim2.fromOffset(44, 4), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, parent)
        corner(eq, 2)
    elseif id == "automation" then
        circ(10, 10, 44, false, 4); circ(24, 24, 16, true)
    elseif id == "fun" then
        circ(10, 10, 44, false, 4); circ(20, 22, 8, true); circ(36, 22, 8, true)
        local sm = New("Frame", { Position = UDim2.fromOffset(20, 38), Size = UDim2.fromOffset(24, 5), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, parent)
        corner(sm, 3)
    elseif id == "customizer" then
        circ(20, 5, 24, false, 4)
        local body = New("Frame", { Position = UDim2.fromOffset(11, 33), Size = UDim2.fromOffset(42, 26), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
        corner(body, 13); stroke(body, WHITE, 4, 0)
    elseif id == "appearance" then
        circ(6, 8, 30, false); circ(28, 8, 30, false); circ(17, 26, 30, false)
    else
        circ(10, 10, 44, false)
    end
end

local function buildXMBChrome()
    local c = T.c
    corner(Win, 12); stroke(Win, WHITE, 1.5, 0.6)
    Win.ClipsDescendants = true
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(c.top, c.bottom) }, Win)

    -- Flow waves
    local waves = New("Frame", { Name = "Waves", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, Win)
    local N = 64
    local defs = {
        { y = 0.60, amp = 0.10, th = 0.16, k = 1.3, sp = 0.35, ph = 0.0, a = 1.0 },
        { y = 0.68, amp = 0.08, th = 0.10, k = 1.9, sp = -0.28, ph = 2.0, a = 0.8 },
        { y = 0.54, amp = 0.12, th = 0.08, k = 0.9, sp = 0.20, ph = 4.0, a = 0.6 },
    }
    local bands = {}
    for bi, d in ipairs(defs) do
        local cols = {}
        for i = 1, N do
            cols[i] = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = c.wave, BackgroundTransparency = 1,
                BorderSizePixel = 0, Size = UDim2.new(1 / N, 3, d.th, 0) }, waves)
        end
        bands[bi] = { d = d, cols = cols }
    end
    local frame, clockAcc = 0, 1
    local clock
    gconnect(RunService.Heartbeat, function(dt)
        if not Win.Visible then return end
        frame += 1
        clockAcc += dt
        if clock and clockAcc >= 1 then clockAcc = 0; clock.Text = os.date("%m/%d   %I:%M %p") end
        if frame % 2 ~= 0 then return end
        local t = os.clock() * S.xmb.speed
        local sz = Win.AbsoluteSize
        local aspect = sz.Y / math.max(sz.X, 1)
        for _, bnd in ipairs(bands) do
            local d = bnd.d
            for i = 1, N do
                local x = (i - 0.5) / N
                local arg = x * d.k * math.pi * 2 + t * d.sp * 2 + d.ph
                local env2 = math.sin(math.pi * x) ^ 0.8
                local y = d.y + math.sin(arg) * d.amp * (0.7 + 0.3 * math.sin(x * 3 + t * 0.3 + d.ph))
                local slope = math.cos(arg) * d.amp * d.k * math.pi * 2 * aspect
                local f = bnd.cols[i]
                f.Position = UDim2.new(x, 0, y, 0)
                f.Size = UDim2.new(1 / N, 3, d.th * (0.2 + 0.8 * env2), 0)
                f.Rotation = math.deg(math.atan(slope))
                f.BackgroundTransparency = 1 - math.clamp(S.xmb.alpha * 0.32 * d.a * env2 * (0.55 + 0.45 * math.sin(arg * 0.5 + d.ph)), 0, 1)
            end
        end
    end)

    -- top bar
    local Top = New("TextButton", { Name = "Top", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42) }, Win)
    New("TextLabel", { BackgroundTransparency = 1, Text = "Tony Script Palace", Font = F_XMB.bold, TextSize = 15, TextColor3 = WHITE, TextXAlignment = AL,
        Position = UDim2.fromOffset(22, 0), Size = UDim2.fromOffset(170, 42) }, Top)
    New("TextLabel", { BackgroundTransparency = 1, Text = "Dandy's World Only", Font = F_XMB.semi, TextSize = 12, TextColor3 = T.dim, TextXAlignment = AL,
        Position = UDim2.fromOffset(196, 0), Size = UDim2.fromOffset(160, 42), TextTruncate = Enum.TextTruncate.AtEnd }, Top)
    clock = New("TextLabel", { BackgroundTransparency = 1, Text = os.date("%m/%d   %I:%M %p"), Font = F_XMB.semi, TextSize = 13, TextColor3 = T.dim,
        TextXAlignment = AR, Position = UDim2.new(1, -270, 0, 0), Size = UDim2.fromOffset(190, 42) }, Top)
    Button(Top, "-", UDim2.fromOffset(30, 24), nil, function() UI.setVisible(false) end, { size = 18, pos = UDim2.new(1, -72, 0.5, -12) })
    local armed = false
    local xb, xl
    xb, xl = Button(Top, "x", UDim2.fromOffset(30, 24), "red", function()
        if not armed then
            armed = true; xl.Text = "?"
            toast("Click again to delete the GUI.", "info")
            task.delay(2.5, function() armed = false; if xl.Parent then xl.Text = "x" end end)
            return
        end
        Destroy()
    end, { size = 14, pos = UDim2.new(1, -38, 0.5, -12) })
    makeDraggable(Top)

    -- categories
    local Cats = New("Frame", { Name = "Cats", BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromOffset(0, 46),
        Size = UDim2.new(1, 0, 0, 116) }, Win)
    local refs = {}
    for i, tb in ipairs(UI.tabs) do
        local f = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.fromOffset(104, 104) }, Cats)
        local holder = New("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.fromOffset(64, 64) }, f)
        local sc = New("UIScale", { Scale = 1 }, holder)
        drawIcon(holder, tb.icon)
        local lb = New("TextLabel", { BackgroundTransparency = 1, Text = tb.name, Font = F_XMB.semi, TextSize = 14, TextColor3 = WHITE,
            Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 22) }, f)
        f.MouseButton1Click:Connect(function() setTab(tb.id) end)
        refs[i] = { f = f, scale = sc, lb = lb }
    end
    local function layoutCats(anim)
        local si = 1
        for i, tb in ipairs(UI.tabs) do if tb.id == UI.current then si = i end end
        for i, r in ipairs(refs) do
            local rel = i - si
            local sx = 86 + 112 * math.min(si - 1, 1)   -- leave room for the previous category
            local gap = (rel > 0 and 16) or (rel < 0 and -16) or 0
            local target = UDim2.fromOffset(sx + rel * 112 + gap, rel == 0 and 0 or 10)
            if anim then tween(r.f, { Position = target }, 0.22) else r.f.Position = target end
            local s = (rel == 0) and 1 or 0.7
            if anim then tween(r.scale, { Scale = s }, 0.2) else r.scale.Scale = s end
            r.lb.TextColor3 = (rel == 0) and WHITE or T.dim
            r.lb.Font = (rel == 0) and F_XMB.bold or F_XMB.semi
        end
    end
    layoutCats(false)
    UI.onTab = function() layoutCats(true) end

    -- items
    Content = New("ScrollingFrame", { Name = "Content", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 40, 0, 172),
        Size = UDim2.new(1, -80, 1, -212), ScrollBarThickness = 4, ScrollBarImageColor3 = WHITE, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, Win)
    New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Content)
    New("UIPadding", { PaddingRight = UDim.new(0, 8) }, Content)

    StatusLbl = Label(Win, statusDefault(), UDim2.new(0, 24, 1, -32), UDim2.new(1, -70, 0, 22), { size = 13, color = T.dim })
end

--#endregion skin-xmb
--#region skin-xp
----------------------------------------------------------------------
-- SKIN: WINDOWS XP LUNA
----------------------------------------------------------------------
local function buildXPChrome()
    local c = T.c
    Win.BackgroundColor3 = c.title:Lerp(BLACK, 0.12)   -- the thick Luna window frame
    corner(Win, 9)

    -- title bar
    local Title = New("Frame", { Name = "Title", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30) }, Win)
    corner(Title, 9)
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c.title:Lerp(WHITE, 0.45)), ColorSequenceKeypoint.new(0.12, c.title:Lerp(WHITE, 0.25)),
        ColorSequenceKeypoint.new(0.5, c.title), ColorSequenceKeypoint.new(1, c.title:Lerp(BLACK, 0.18)) }) }, Title)
    -- tiny four-colour flag icon
    local flag = { C(241, 80, 34), C(127, 186, 0), C(0, 164, 239), C(255, 185, 0) }
    for i = 0, 3 do
        New("Frame", { BackgroundColor3 = flag[i + 1], BorderSizePixel = 0, Size = UDim2.fromOffset(6, 6),
            Position = UDim2.fromOffset(9 + (i % 2) * 7, 8 + math.floor(i / 2) * 7), ZIndex = 4 }, Title)
    end
    New("TextLabel", { BackgroundTransparency = 1, Text = "Tony Script Palace  -  for Dandy's World only", Font = F_XP.bold, TextSize = 15,
        TextColor3 = WHITE, TextStrokeColor3 = BLACK, TextStrokeTransparency = 0.7, TextXAlignment = AL,
        TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -90, 1, 0), ZIndex = 4 }, Title)

    local function capBtn(xOff, col)
        local b = New("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(22, 22), ZIndex = 5 }, Title)
        corner(b, 4); stroke(b, WHITE, 1, 0.1); grad(b, col:Lerp(WHITE, 0.4), col, 90)
        b.MouseEnter:Connect(function() ui("hover") end)
        b.MouseButton1Down:Connect(function() b.BackgroundColor3 = C(200, 200, 200) end)
        b.MouseButton1Up:Connect(function() b.BackgroundColor3 = WHITE end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = WHITE end)
        return b
    end
    local mb = capBtn(-32, c.title:Lerp(WHITE, 0.12))
    New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 13), Size = UDim2.fromOffset(9, 3), ZIndex = 6 }, mb)
    mb.MouseButton1Click:Connect(function() ui("click"); UI.setVisible(false) end)
    local xb = capBtn(-6, C(214, 76, 50))
    local xl = New("TextLabel", { BackgroundTransparency = 1, Text = "X", Font = F_XP.bold, TextSize = 14, TextColor3 = WHITE,
        TextStrokeColor3 = BLACK, TextStrokeTransparency = 0.7, Size = UDim2.fromScale(1, 1), ZIndex = 6 }, xb)
    local armed = false
    xb.MouseButton1Click:Connect(function()
        ui("click")
        if not armed then
            armed = true; xl.Text = "?"
            toast("Click again to delete the GUI.", "info")
            task.delay(2.5, function() armed = false; if xl.Parent then xl.Text = "X" end end)
            return
        end
        Destroy()
    end)
    makeDraggable(Title)

    -- window face (the beige dialog area)
    local Face = New("Frame", { Name = "Face", BackgroundColor3 = c.face, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 30),
        Size = UDim2.new(1, -8, 1, -34) }, Win)
    corner(Face, 2)

    -- left task pane
    local Side = New("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(0, 156, 1, -44) }, Face)
    corner(Side, 3); grad(Side, c.pane, c.pane:Lerp(BLACK, 0.15), 90)
    Label(Side, "Categories", UDim2.fromOffset(10, 6), UDim2.new(1, -20, 0, 22), { font = F_XP.bold, size = 14, color = WHITE })
    local tabList = New("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 32),
        Size = UDim2.new(1, -16, 1, -40), ScrollBarThickness = 4, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, Side)
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local link = c.title:Lerp(BLACK, 0.1)
    local function buildTabs()
        for _, ch in ipairs(tabList:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
        for i, tb in ipairs(UI.tabs) do
            local sel = tb.id == UI.current
            local base = sel and WHITE or c.pane:Lerp(WHITE, 0.7)
            local b = New("TextButton", { Text = tb.name, Font = sel and F_XP.bold or F_XP.reg, TextSize = 14, TextColor3 = link,
                TextXAlignment = AL, BackgroundColor3 = base, BorderSizePixel = 0, AutoButtonColor = false,
                Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i }, tabList)
            corner(b, 3); New("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b)
            if sel then stroke(b, c.accent, 1, 0) end
            b.MouseEnter:Connect(function() b.BackgroundColor3 = WHITE end)
            b.MouseLeave:Connect(function() b.BackgroundColor3 = base end)
            b.MouseButton1Click:Connect(function() ui("click"); setTab(tb.id) end)
        end
    end
    buildTabs()
    UI.onTab = buildTabs

    -- content (white "list view" with a sunken border)
    Content = New("ScrollingFrame", { Name = "Content", BackgroundColor3 = WHITE, BorderSizePixel = 0, Position = UDim2.fromOffset(172, 8),
        Size = UDim2.new(1, -180, 1, -44), ScrollBarThickness = 12, ScrollBarImageColor3 = c.pane, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y }, Face)
    corner(Content, 2); stroke(Content, C(127, 157, 185), 1, 0)
    New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Content)
    New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, Content)

    -- status bar
    New("Frame", { BackgroundColor3 = C(172, 168, 153), BorderSizePixel = 0, Position = UDim2.new(0, 6, 1, -32), Size = UDim2.new(1, -12, 0, 1) }, Face)
    StatusLbl = Label(Face, statusDefault(), UDim2.new(0, 12, 1, -28), UDim2.new(1, -44, 0, 20), { size = 13, color = T.dim })
end

--#endregion skin-xp
--#region build-gui
----------------------------------------------------------------------
-- BUILD / REBUILD THE WHOLE GUI
----------------------------------------------------------------------
function buildGui()
    local keepY = Content and Content.CanvasPosition.Y or 0
    closePopup()
    for _, cn in ipairs(guiConns) do pcall(function() cn:Disconnect() end) end
    table.clear(guiConns)
    if gui then pcall(function() gui:Destroy() end) end
    table.clear(rainbowSw); table.clear(liveList)
    gui, Win, Overlay, Content, StatusLbl, Orb, Grip, UIScaleObj, Host, Rail, PinPane = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    activeDrag, listening = nil, nil

    T = makeTokens()
    gui = New("ScreenGui", { Name = "TonyScriptPalace", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    gui.Parent = guiParent()
    if T.kind == "aero" then gconnect(gui.DescendantAdded, lowerize) end

    Win = New("Frame", { Name = "Window", BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.fromOffset(960, 600),
        Visible = UI.visible }, gui)
    UIScaleObj = New("UIScale", { Scale = 1 }, Win)

    if T.kind == "dandy" then buildDandyChrome() elseif T.kind == "aero" then buildAeroChrome() elseif T.kind == "xp" then buildXPChrome() else buildXMBChrome() end
    makePane()
    makeGrip()
    Overlay = New("Frame", { Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 100 }, Win)
    makeOrb()
    applyLayout()
    renderPage()
    pcall(UI.binds.rebuild)                 -- the on-screen buttons are drawn with the skin, so they are rebuilt with it
    local cont = Content
    task.defer(function() if cont and cont.Parent then cont.CanvasPosition = Vector2.new(0, keepY) end end)
end

--#endregion build-gui
--#region boot
----------------------------------------------------------------------
-- INPUT + BOOT + CLEANUP
----------------------------------------------------------------------
connect(UIS.InputChanged, function(i)
    if activeDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        activeDrag(i.Position)
    end
end)
connect(UIS.InputEnded, function(i) if isPress(i) then activeDrag = nil end end)

local function mouseOverWin()
    if not (Win and Win.Visible) then return false end
    local m, p, s = UIS:GetMouseLocation(), Win.AbsolutePosition, Win.AbsoluteSize
    return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

connect(UIS.InputBegan, function(i, gp)
    if listening then
        if i.UserInputType == Enum.UserInputType.Keyboard then
            local cb = listening
            listening = nil
            cb(i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode.Name or nil)
        end
        return
    end
    if gp or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if i.KeyCode.Name == S.keybind then
        UI.setVisible(not UI.visible)
    elseif UI.binds and UI.binds.onKey(i.KeyCode.Name) then
        -- a toggle was bound to this key; it has been flipped
    elseif S.style == "xmb" and mouseOverWin() and (i.KeyCode == Enum.KeyCode.Left or i.KeyCode == Enum.KeyCode.Right) then
        local idx = 1
        for n, t in ipairs(UI.tabs) do if t.id == UI.current then idx = n end end
        idx = math.clamp(idx + (i.KeyCode == Enum.KeyCode.Right and 1 or -1), 1, #UI.tabs)
        setTab(UI.tabs[idx].id)
    end
end)

task.spawn(function()
    while alive do
        task.wait(1.5)
        if dirty then dirty = false; saveSettings() end
    end
end)

function Destroy()
    if not alive then return end
    alive = false
    pcall(saveSettings)
    for _, cn in ipairs(conns) do pcall(function() cn:Disconnect() end) end
    for _, cn in ipairs(guiConns) do pcall(function() cn:Disconnect() end) end
    pcall(ESP.Unload)
    pcall(Fun.Unload)
    pcall(SP.Unload)
    pcall(Auto.Unload)
    pcall(Cust.Destroy)
    pcall(UI.snd.Destroy)
    pcall(UI.binds.destroy)
    pcall(function() sndHolder:Destroy() end)
    if gui then pcall(function() gui:Destroy() end) end
    env.TonyScriptPalace = nil
end
env.TonyScriptPalace = { Destroy = Destroy, Settings = S, ESP = ESP, API = function() return DWAPI.lib end, Features = Features, UI = UI, Customizer = Cust, Sound = UI.snd,
    Show = function() UI.setVisible(true) end, Hide = function() UI.setVisible(false) end, Toggle = function() UI.setVisible(not UI.visible) end }

-- auto-load the last config
if S.autoload and S.lastConfig ~= "" and isF(cfgPath(S.lastConfig)) then
    pcall(loadConfig, S.lastConfig)
end

buildGui()
DWAPI.load()
if S.style == "xmb" or S.style == "xp" then uiWhenReady("boot") end
toast("Tony Script Palace ready (Dandy's World only). Press " .. S.keybind .. " to hide or show.", "info")

--#endregion boot
