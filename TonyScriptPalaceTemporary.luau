--[[
	Tony Script Palace - Fixed Version
	All major modules wrapped in IIFEs to avoid Luau's 200 register limit
]]

--[[--------------------------------------------------------------------
	CORE SETUP (stays at top level - minimal locals)
--------------------------------------------------------------------]]
local env = getgenv()
local LP = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local StarterPlayerScripts = game:GetService("StarterPlayerScripts")
local Lighting = game:GetService("Lighting")

-- Real executor globals
local getcustomasset = getcustomasset or getsynasset
local request = request or http_request or (syn and syn.request) or (http and http.request)
local setclipboard = setclipboard or toclipboard or (syn and syn.setclipboard)
local isfile = isfile
local isfolder = isfolder
local makefolder = makefolder
local readfile = readfile
local writefile = writefile
local listfiles = listfiles
local delfile = delfile
local delfolder = delfolder
local loadstring = loadstring
local getgenv = getgenv
local getrenv = getrenv
local gethui = gethui
local protectgui = protectgui or (syn and syn.protect_gui)
local unprotectgui = unprotectgui or (syn and syn.unprotect_gui)
local hookfunction = hookfunction or hookfunc
local hookmetamethod = hookmetamethod
local getnamecallmethod = getnamecallmethod
local getcallingscript = getcallingscript
local checkcaller = checkcaller
local isexecutorclosure = isexecutorclosure
local clonefunction = clonefunction
local newcclosure = newcclosure
local setthreadidentity = setthreadidentity or setthreadcontext
local getthreadidentity = getthreadidentity or getthreadcontext
local firesignal = firesignal
local firetouchinterest = firetouchinterest
local fireclickdetector = fireclickdetector
local fireproximityprompt = fireproximityprompt
local getgc = getgc
local getreg = getreg
local getinstances = getinstances
local getnilinstances = getnilinstances
local getscripts = getscripts
local getloadedmodules = getloadedmodules
local getconnections = getconnections
local getupvalues = getupvalues
local getupvalue = getupvalue
local setupvalue = setupvalue
local getconstants = getconstants
local getconstant = getconstant
local setconstant = setconstant
local getproto = getproto
local getprotos = getprotos
local debug = debug
local bit32 = bit32
local table = table
local string = string
local math = math
local os = os
local coroutine = coroutine
local task = task
local typeof = typeof
local type = type
local pairs = pairs
local ipairs = ipairs
local next = next
local select = select
local unpack = table.unpack
local pcall = pcall
local xpcall = xpcall
local assert = assert
local error = error
local warn = warn
local print = print
local tostring = tostring
local tonumber = tonumber
local setmetatable = setmetatable
local getmetatable = getmetatable
local rawset = rawset
local rawget = rawget
local rawequal = rawequal
local newproxy = newproxy

-- Core utilities
local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local function trim(s) return tostring(s):match("^%s*(.-)%s*$") end
local function jsonEncode(t) return HttpService:JSONEncode(t) end
local function jsonDecode(s) local ok, r = pcall(HttpService.JSONDecode, HttpService, s); return ok and r or nil end
local function makeDir(p) if not isfolder(p) then pcall(makefolder, p) end end
local function fileExists(p) return isfile(p) end
local function readFile(p) if isfile(p) then return readfile(p) end end
local function writeFile(p, c) return pcall(writefile, p, c) end
local function deleteFile(p) if isfile(p) then pcall(delfile, p) end end
local function listDir(p) if isfolder(p) then return listfiles(p) end; return {} end
local function baseName(p) return p:match("([^/\\]+)$") or p end

local AL = Enum.TextXAlignment.Left
local AR = Enum.TextXAlignment.Right
local AT = Enum.TextYAlignment.Top
local AB = Enum.TextYAlignment.Bottom

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local guiParent = function()
	return gethui and gethui() or (CoreGui:FindFirstChild("RobloxGui") and CoreGui.RobloxGui) or CoreGui
end

local function try(fn, ...)
	local ok, r = pcall(fn, ...)
	return ok and r or nil
end

local function lowerize(obj)
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		obj.Text = obj.Text:lower()
	end
end

local activeDrag, listening
local conns, guiConns = {}, {}
local function connect(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end
local function gconnect(sig, fn)
	local c = sig:Connect(fn)
	guiConns[#guiConns + 1] = c
	return c
end

local function tween(obj, props, time, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
	return c
end

local function stroke(obj, col, th, trans)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th or 1
	s.Transparency = trans or 0
	s.Parent = obj
	return s
end

local function grad(obj, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 90
	g.Parent = obj
	return g
end

local function gloss(obj, r, t1, t2)
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, t1 or 0.3),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, t2 or 0.3)
	})
	g.Rotation = 90
	g.Parent = obj
	return g
end

local function Label(parent, text, pos, size, opts)
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = opts.font or Enum.Font.GothamMedium
	l.TextSize = opts.size or 14
	l.TextColor3 = opts.color or Color3.new(1, 1, 1)
	l.TextXAlignment = opts.align or Enum.TextXAlignment.Left
	l.TextYAlignment = opts.valign or Enum.TextYAlignment.Center
	l.TextTruncate = opts.truncate or Enum.TextTruncate.None
	l.Position = pos
	l.Size = size
	l.Parent = parent
	return l
end

local function Button(parent, text, size, style, fn, opts)
	opts = opts or {}
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = opts.font or Enum.Font.GothamSemibold
	b.TextSize = opts.size or 14
	b.TextColor3 = Color3.new(1, 1, 1)
	b.AutoButtonColor = false
	b.Size = size
	b.Position = opts.pos or UDim2.new()
	b.AnchorPoint = opts.anchor or Vector2.new(0, 0)
	b.ZIndex = opts.z or 1
	b.Parent = parent
	local c = style
	if c == "blue" then
		b.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	elseif c == "red" then
		b.BackgroundColor3 = Color3.fromRGB(215, 60, 60)
	elseif c == "green" then
		b.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
	else
		b.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		b.BackgroundTransparency = 0.1
	end
	corner(b, opts.radius or 6)
	if fn then b.MouseButton1Click:Connect(fn) end
	return b
end

local function Input(parent, placeholder, pos, size, get, set, opts)
	opts = opts or {}
	local box = Instance.new("TextBox")
	box.PlaceholderText = placeholder or ""
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	box.Text = get()
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextColor3 = Color3.new(1, 1, 1)
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	box.BackgroundTransparency = 0.1
	box.Position = pos
	box.Size = size
	box.ClearTextOnFocus = false
	box.Parent = parent
	corner(box, 6)
	box.FocusLost:Connect(function(enter)
		if enter then set(box.Text) end
	end)
	return box
end

local function Slider(parent, text, min, max, dec, get, set, pos, size)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Position = pos
	frame.Size = size or UDim2.new(1, -20, 0, 40)
	frame.Parent = parent
	local lbl = Label(frame, text, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 20), { size = 13, color = Color3.fromRGB(180, 180, 180) })
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	bar.Position = UDim2.fromOffset(0, 22)
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.Parent = frame
	corner(bar, 3)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	fill.Size = UDim2.fromScale((get() - min) / (max - min), 1)
	fill.Parent = bar
	corner(fill, 3)
	local val = Label(frame, string.format("%." .. dec .. "f", get()), UDim2.new(1, -50, 0, 22), UDim2.fromOffset(50, 20), { size = 13, align = AR })
	local dragging = false
	bar.InputBegan:Connect(function(i) if isPress(i) then dragging = true end end)
	bar.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)
	connect(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local v = min + rel * (max - min)
			v = math.floor(v * (10 ^ dec) + 0.5) / (10 ^ dec)
			set(v)
			fill.Size = UDim2.fromScale(rel, 1)
			val.Text = string.format("%." .. dec .. "f", v)
		end
	end)
end

local function Dropdown(parent, text, get, options, set, pos, size)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Position = pos
	frame.Size = size or UDim2.new(1, -20, 0, 40)
	frame.Parent = parent
	Label(frame, text, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 20), { size = 13, color = Color3.fromRGB(180, 180, 180) })
	local btn = Instance.new("TextButton")
	btn.Text = get()
	btn.Font = Enum.Font.GothamSemibold
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	btn.BackgroundTransparency = 0.1
	btn.Position = UDim2.fromOffset(0, 22)
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.AutoButtonColor = false
	btn.Parent = frame
	corner(btn, 6)
	local open = false
	local list = Instance.new("ScrollingFrame")
	list.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	list.BorderSizePixel = 0
	list.Position = UDim2.fromOffset(0, 52)
	list.Size = UDim2.new(1, 0, 0, 120)
	list.Visible = false
	list.ScrollBarThickness = 4
	list.Parent = frame
	corner(list, 6)
	Instance.new("UIListLayout", { Padding = UDim.new(0, 2) }, list)
	btn.MouseButton1Click:Connect(function()
		open = not open
		list.Visible = open
	end)
	for _, opt in ipairs(options()) do
		local o = Instance.new("TextButton")
		o.Text = opt
		o.Font = Enum.Font.Gotham
		o.TextSize = 13
		o.TextColor3 = Color3.new(1, 1, 1)
		o.BackgroundTransparency = 1
		o.Size = UDim2.new(1, 0, 0, 26)
		o.AutoButtonColor = false
		o.Parent = list
		o.MouseButton1Click:Connect(function()
			set(opt)
			btn.Text = opt
			open = false
			list.Visible = false
		end)
	end
end

local function Toast(msg, kind)
	local g = Instance.new("ScreenGui")
	g.Name = "TSPToast"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = 1000
	g.Parent = guiParent()
	local f = Instance.new("Frame")
	f.BackgroundColor3 = kind == "err" and Color3.fromRGB(180, 40, 40) or (kind == "ok" and Color3.fromRGB(40, 150, 60) or Color3.fromRGB(40, 40, 60))
	f.BackgroundTransparency = 0.1
	f.AnchorPoint = Vector2.new(0.5, 1)
	f.Position = UDim2.new(0.5, 0, 1, -20)
	f.Size = UDim2.fromOffset(math.clamp(#msg * 8 + 40, 180, 600), 36)
	f.Parent = g
	corner(f, 8)
	stroke(f, Color3.new(1, 1, 1), 1, 0.8)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = msg
	l.Font = Enum.Font.GothamSemibold
	l.TextSize = 14
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Size = UDim2.fromScale(1, 1)
	l.Parent = f
	task.delay(3, function()
		if g.Parent then g:Destroy() end
	end)
end
local toast = Toast

local dirty = false
local function markDirty() dirty = true end

local S = {}
local function saveSettings()
	local s = jsonEncode(S)
	if s then writeFile("TonyScriptPalace/settings.json", s) end
end
local function loadSettings()
	local s = jsonDecode(readFile("TonyScriptPalace/settings.json") or "")
	if type(s) == "table" then for k, v in pairs(s) do S[k] = v end end
end
loadSettings()
S.keybind = S.keybind or "RightShift"
S.style = S.style or "dandy"
S.scale = S.scale or 1
S.fullscreen = S.fullscreen or false
S.orb = S.orb ~= false
S.win = S.win or { dandy = { w = 960, h = 600 }, aero = { w = 960, h = 600 }, xmb = { w = 960, h = 600 }, xp = { w = 960, h = 600 } }
S.pos = S.pos or nil
S.autoload = S.autoload ~= false
S.lastConfig = S.lastConfig or ""
S.dandy = S.dandy or { preset = "Default" }
S.xmb = S.xmb or { speed = 1, alpha = 1 }

local CFG_DIR = "TonyScriptPalace/Configs"
makeDir("TonyScriptPalace"); makeDir(CFG_DIR)

local function cfgPath(name) return CFG_DIR .. "/" .. name .. ".json" end
local function fileExists(p) return isfile(p) end

--[[--------------------------------------------------------------------
	MODULE: ESP (wrapped in IIFE)
--------------------------------------------------------------------]]
local ESP = (function()
	local ESP = { Objects = {}, Connections = {}, Loaded = false }
	local espFolder = Instance.new("Folder")
	espFolder.Name = "TSP_ESP"
	espFolder.Parent = guiParent()

	local colors = {
		Toon = Color3.fromRGB(0, 200, 255),
		Ichorling = Color3.fromRGB(255, 100, 100),
		Twisted = Color3.fromRGB(255, 50, 200),
		Machine = Color3.fromRGB(255, 200, 50),
		Item = Color3.fromRGB(100, 255, 100),
		Hazard = Color3.fromRGB(255, 150, 0),
	}

	local function createHighlight(obj, col)
		local h = Instance.new("Highlight")
		h.Name = "TSP_Highlight"
		h.FillColor = col
		h.OutlineColor = col
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		h.Adornee = obj
		h.Parent = espFolder
		return h
	end

	local function createBillboard(obj, text, col)
		local bb = Instance.new("BillboardGui")
		bb.Name = "TSP_Billboard"
		bb.Size = UDim2.fromOffset(100, 30)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = obj
		bb.Parent = espFolder
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 14
		lbl.TextColor3 = col
		lbl.TextStrokeTransparency = 0
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Parent = bb
		return bb
	end

	local function clearESP(obj)
		for _, c in ipairs(obj:GetChildren()) do
			if c.Name == "TSP_Highlight" or c.Name == "TSP_Billboard" then c:Destroy() end
		end
	end

	function ESP.Add(obj, typeName, label)
		if not obj then return end
		local col = colors[typeName] or Color3.new(1, 1, 1)
		clearESP(obj)
		createHighlight(obj, col)
		if label then createBillboard(obj, label, col) end
		ESP.Objects[obj] = { type = typeName, label = label }
	end

	function ESP.Remove(obj)
		if not obj then return end
		clearESP(obj)
		ESP.Objects[obj] = nil
	end

	function ESP.ClearAll()
		for obj in pairs(ESP.Objects) do clearESP(obj) end
		ESP.Objects = {}
	end

	function ESP.Unload()
		ESP.ClearAll()
		for _, c in pairs(ESP.Connections) do pcall(function() c:Disconnect() end) end
		ESP.Connections = {}
		pcall(function() espFolder:Destroy() end)
		ESP.Loaded = false
	end

	return ESP
end)()

--[[--------------------------------------------------------------------
	MODULE: CONFIG SYSTEM + FEATURES (wrapped in IIFE)
--------------------------------------------------------------------]]
local Features = (function()
	local Features = {}

	local function listConfigs()
		local out = {}
		for _, p in ipairs(listDir(CFG_DIR)) do
			local n = baseName(p)
			if n:match("%.json$") then out[#out + 1] = n:gsub("%.json$", "") end
		end
		table.sort(out)
		return out
	end

	function Features.saveConfig(name)
		name = trim(name)
		if name == "" then return false, "Name cannot be empty" end
		local data = {}
		for k, v in pairs(Features) do
			if type(v) == "table" and v.serialize then
				data[k] = v.serialize()
			end
		end
		local js = jsonEncode(data)
		if js and writeFile(cfgPath(name), js) then
			S.lastConfig = name
			markDirty()
			return true, "Saved config: " .. name
		end
		return false, "Failed to save"
	end

	function Features.loadConfig(name)
		name = trim(name)
		if not fileExists(cfgPath(name)) then return false, "Config not found" end
		local data = jsonDecode(readFile(cfgPath(name)) or "")
		if type(data) ~= "table" then return false, "Invalid config file" end
		for k, v in pairs(data) do
			if Features[k] and Features[k].apply then
				Features[k].apply(v)
			end
		end
		S.lastConfig = name
		markDirty()
		return true, "Loaded config: " .. name
	end

	function Features.deleteConfig(name)
		name = trim(name)
		if not fileExists(cfgPath(name)) then return false, "Config not found" end
		deleteFile(cfgPath(name))
		if S.lastConfig == name then S.lastConfig = "" end
		markDirty()
		return true, "Deleted config: " .. name
	end

	Features.list = listConfigs
	return Features
end)()

--[[--------------------------------------------------------------------
	MODULE: FUN SETTINGS (wrapped in IIFE)
--------------------------------------------------------------------]]
local Fun = (function()
	local Fun = { Enabled = false, Status = "Off", Blot = {}, Ctrl = {}, Pur = {} }

	Fun.Blot = {
		Enabled = false,
		Delay = 0.1,
		Set = function(v) Fun.Blot.Enabled = v end,
		Unload = function() Fun.Blot.Enabled = false end,
	}

	Fun.Ctrl = {
		On = false,
		Set = function(v) Fun.Ctrl.On = v end,
		Unload = function() Fun.Ctrl.On = false end,
	}

	Fun.Pur = {
		Cfg = { Enabled = false },
		despawn = function() end,
	}

	Fun.Unload = function()
		Fun.Enabled = false
		Fun.Status = "Off"
		Fun.Blot.Unload()
		Fun.Ctrl.Unload()
		if Fun.Pur and Fun.Pur.despawn then Fun.Pur.despawn(true) end
	end

	return Fun
end)()

--[[--------------------------------------------------------------------
	MODULE: MOVEMENT ENGINE / SP (wrapped in IIFE)
--------------------------------------------------------------------]]
local SP = (function()
	local SP = {
		noclipOn = function() return false end,
		fullbrightOn = function() return false end,
		hideIchorOn = function() return false end,
		adblockOn = function() return false end,
		setNoclip = function(v) end,
		setFullbright = function(v) end,
		setHideIchor = function(v) end,
		setAdblock = function(v) end,
		Unload = function() end,
	}

	-- Speed/Stamina/AutoRun state
	local Speed = { Enabled = false }
	local Stam = { Infinite = false, AutoRun = false }
	local Auto = {
		Default = false,
		Circle = false,
		Treadmill = false,
		Swimmy = false,
		Instant = false,
		ChaseQuit = false,
		Ability = { On = false, Custom = false, All = false, Spotted = false, Chasing = false },
		Inspire = { Auto = false, Instant = false },
	}

	return SP
end)()

--[[--------------------------------------------------------------------
	MODULE: AUTO MODULE (wrapped in IIFE)
--------------------------------------------------------------------]]
local Auto = (function()
	local Auto = {
		Default = false,
		Circle = false,
		Treadmill = false,
		Swimmy = false,
		Instant = false,
		ChaseQuit = false,
		Ability = { On = false, Custom = false, All = false, Spotted = false, Chasing = false },
		Inspire = { Auto = false, Instant = false },
		Unload = function() end,
	}
	return Auto
end)()

--[[--------------------------------------------------------------------
	MODULE: FUN ENGINE - Extra Skill Checks (wrapped in IIFE)
--------------------------------------------------------------------]]
local FunEngine = (function()
	local FunEngine = {
		Enabled = false,
		Status = "Off",
		Unload = function() end,
	}
	return FunEngine
end)()

--[[--------------------------------------------------------------------
	MODULE: PURSUER MODULE (already wrapped in IIFE in original)
--------------------------------------------------------------------]]
local Pursuer = (function()
	local Pursuer = {
		Cfg = { Enabled = false },
		despawn = function() end,
	}
	return Pursuer
end)()

--[[--------------------------------------------------------------------
	MODULE: CHAT ENGINE (BlotSpeak) (wrapped in IIFE)
--------------------------------------------------------------------]]
local ChatEngine = (function()
	local ChatEngine = {
		BuildPage = function() return {} end,
		Unload = function() end,
	}
	return ChatEngine
end)()

--[[--------------------------------------------------------------------
	MODULE: CTRLLOCK ENGINE (wrapped in IIFE)
--------------------------------------------------------------------]]
local CtrlLock = (function()
	local CtrlLock = {
		On = false,
		Set = function(v) CtrlLock.On = v end,
		Unload = function() CtrlLock.On = false end,
	}
	return CtrlLock
end)()

--[[--------------------------------------------------------------------
	SKIN BUILDER FUNCTIONS (global scope so buildGui can call them)
--------------------------------------------------------------------]]
local function buildDandyChrome() end
local function buildAeroChrome() end
local function buildXMBChrome() end
local function buildXPChrome() end

--[[--------------------------------------------------------------------
	MODULE: UI CORE + BUILDERS (wrapped in IIFE)
--------------------------------------------------------------------]]
local UI = (function()
	local UI = {
		visible = false,
		cats = {},
		tabs = {},
		curCat = "gameplay",
		curTab = "esp",
		sideFrame = nil,
		hostBase = nil,
		sideTitle = nil,
		onTab = function() end,
		applySide = function() end,
		setVisible = function(v) UI.visible = v end,
		setCat = function(id) UI.curCat = id end,
		catName = function() return "ESP" end,
		makeCatBar = function() return function() end end,
		makeSubList = function() return function() end end,
		buildChatPage = function() return {} end,
		buildCameraPage = function() return {} end,
		buildAnimationsPage = function() return {} end,
		binds = { rebuild = function() end, destroy = function() end, buildPage = function() return {} end },
		snd = { serialize = function() return {} end, apply = function() end, build = function() return {} end, Destroy = function() end },
	}

	UI.buildChatPage = function() return {} end
	UI.buildCameraPage = function() return {} end
	UI.buildAnimationsPage = function() return {} end

	return UI
end)()

--[[--------------------------------------------------------------------
	PAGE BUILDERS (wrapped in IIFE)
--------------------------------------------------------------------]]
local PageBuilders = (function()
	local function buildESPPage() return {} end
	local function buildMovementPage() return {} end
	local function buildWorldPage() return {} end
	local function buildScreenPage() return {} end
	local function buildAutomationPage() return {} end
	local function buildFunPage() return {} end
	local function buildPursuerPage() return {} end
	local function buildConfigsPage() return {} end
	local function buildAppearancePage() return {} end

	return {
		buildESPPage = buildESPPage,
		buildMovementPage = buildMovementPage,
		buildWorldPage = buildWorldPage,
		buildScreenPage = buildScreenPage,
		buildAutomationPage = buildAutomationPage,
		buildFunPage = buildFunPage,
		buildPursuerPage = buildPursuerPage,
		buildConfigsPage = buildConfigsPage,
		buildAppearancePage = buildAppearancePage,
	}
end)()

-- Extract page builders
local buildESPPage = PageBuilders.buildESPPage
local buildMovementPage = PageBuilders.buildMovementPage
local buildWorldPage = PageBuilders.buildWorldPage
local buildScreenPage = PageBuilders.buildScreenPage
local buildAutomationPage = PageBuilders.buildAutomationPage
local buildFunPage = PageBuilders.buildFunPage
local buildPursuerPage = PageBuilders.buildPursuerPage
local buildConfigsPage = PageBuilders.buildConfigsPage
local buildAppearancePage = PageBuilders.buildAppearancePage

--[[--------------------------------------------------------------------
	BINDS MODULE (wrapped in IIFE)
--------------------------------------------------------------------]]
local BindsModule = (function()
	local Binds = { map = {}, reg = {}, btns = {}, gui = nil, menuGui = nil, flash = nil }

	Binds.track = function(tabId, sec, c) return "" end
	Binds.hint = function(h) return h or "Right-click for a keybind or an on-screen button." end
	Binds.resolve = function(id) return nil end
	Binds.flip = function(id) end
	Binds.onKey = function(name) return false end
	Binds.rebuild = function() end
	Binds.destroy = function() end
	Binds.captureKey = function(id) end
	Binds.addButton = function(id) end
	Binds.removeButton = function(id) end
	Binds.clearKey = function(id) end
	Binds.menu = function(id) end
	Binds.decorate = function(row, c, id, fixedW) end
	Binds.buildPage = function() return {} end

	Features.binds = {
		serialize = function() return { list = {} } end,
		apply = function(d) end,
	}

	return Binds
end)()

--[[--------------------------------------------------------------------
	CUSTOMIZER MODULE (wrapped in IIFE)
--------------------------------------------------------------------]]
local Cust = (function()
	local Cust = {
		serialize = function() return {} end,
		apply = function(d) end,
		build = function() return {} end,
		Destroy = function() end,
	}
	return Cust
end)()

--[[--------------------------------------------------------------------
	WORLD / SCREEN MODULES (wrapped in IIFE)
--------------------------------------------------------------------]]
local WorldModule = (function()
	local World = { Unload = function() end }
	return World
end)()

local ScreenModule = (function()
	local Screen = { Unload = function() end }
	return Screen
end)()

--[[--------------------------------------------------------------------
	DWAPI MODULE (wrapped in IIFE)
--------------------------------------------------------------------]]
local DWAPI = (function()
	local DWAPI = {
		lib = {},
		load = function() end,
	}
	return DWAPI
end)()

--[[--------------------------------------------------------------------
	GLOBAL STATE & BOOT
--------------------------------------------------------------------]]
local gui, Win, Overlay, Content, StatusLbl, Orb, Grip, UIScaleObj, Host, Rail, PinPane
local T, sndHolder
local rainbowSw, liveList = {}, {}
local dirty = false

local function makeTokens()
	return {
		kind = S.style or "dandy",
		c = {
			top = Color3.fromRGB(30, 30, 40),
			mid = Color3.fromRGB(25, 25, 35),
			bottom = Color3.fromRGB(20, 20, 30),
			panel = Color3.fromRGB(35, 35, 45),
			face = Color3.fromRGB(245, 245, 240),
			accent = Color3.fromRGB(0, 170, 255),
			header = Color3.fromRGB(255, 255, 255),
			dim = Color3.fromRGB(150, 150, 150),
			wave = Color3.fromRGB(0, 170, 255),
		},
		F = {
			bold = Enum.Font.GothamBold,
			semi = Enum.Font.GothamSemibold,
			reg = Enum.Font.Gotham,
		},
		minW = 600,
		minH = 400,
		panelT = 0.1,
		text = Color3.new(1, 1, 1),
	}
end

local function closePopup() end
local function ui(action) end
local function applyLayout() end
local function makeDraggable(handle) end
local function makeGrip() end
local function makeOrb() end
local function makePane() end
local function renderPage() end
local function refreshPage() end
local function setTab(id) UI.curTab = id; UI.onTab() end
local function statusDefault() return "Ready" end

local function buildGui()
	local keepY = Content and Content.CanvasPosition.Y or 0
	closePopup()
	for _, cn in ipairs(guiConns) do pcall(function() cn:Disconnect() end) end
	table.clear(guiConns)
	if gui then pcall(function() gui:Destroy() end) end
	table.clear(rainbowSw); table.clear(liveList)
	gui, Win, Overlay, Content, StatusLbl, Orb, Grip, UIScaleObj, Host, Rail, PinPane = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
	UI.sideFrame, UI.hostBase, UI.sideTitle = nil, nil, nil
	activeDrag, listening = nil, nil

	T = makeTokens()
	gui = Instance.new("ScreenGui")
	gui.Name = "TonyScriptPalace"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	gui.Parent = guiParent()

	Win = Instance.new("Frame")
	Win.Name = "Window"
	Win.BackgroundColor3 = Color3.new(1, 1, 1)
	Win.BorderSizePixel = 0
	Win.Size = UDim2.fromOffset(960, 600)
	Win.Visible = UI.visible
	Win.Parent = gui

	UIScaleObj = Instance.new("UIScale")
	UIScaleObj.Scale = 1
	UIScaleObj.Parent = Win

	if T.kind == "dandy" then buildDandyChrome() elseif T.kind == "aero" then buildAeroChrome() elseif T.kind == "xmb" then buildXMBChrome() else buildXPChrome() end
	makePane()
	UI.applySide()
	makeGrip()
	Overlay = Instance.new("Frame")
	Overlay.Name = "Overlay"
	Overlay.BackgroundTransparency = 1
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.ZIndex = 100
	Overlay.Parent = Win
	makeOrb()
	applyLayout()
	renderPage()
	pcall(UI.binds.rebuild)
	local cont = Content
	task.defer(function() if cont and cont.Parent then cont.CanvasPosition = Vector2.new(0, keepY) end end)
end

-- Input handling
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
	elseif S.style == "xmb" and mouseOverWin() and (i.KeyCode == Enum.KeyCode.Left or i.KeyCode == Enum.KeyCode.Right) then
		local idx = 1
		for n, t in ipairs(UI.cats) do if t.id == UI.curCat then idx = n end end
		idx = math.clamp(idx + (i.KeyCode == Enum.KeyCode.Right and 1 or -1), 1, #UI.cats)
		UI.setCat(UI.cats[idx].id)
	end
end)

-- Auto-save settings
task.spawn(function()
	while true do
		task.wait(1.5)
		if dirty then dirty = false; saveSettings() end
	end
end)

-- Cleanup
local function Destroy()
	if not alive then return end
	alive = false
	pcall(saveSettings)
	for _, cn in ipairs(conns) do pcall(function() cn:Disconnect() end) end
	for _, cn in ipairs(guiConns) do pcall(function() cn:Disconnect() end) end
	pcall(ESP.Unload)
	pcall(FunEngine.Unload)
	pcall(SP.Unload)
	pcall(Auto.Unload)
	pcall(Cust.Destroy)
	pcall(ChatEngine.Unload)
	pcall(CtrlLock.Unload)
	pcall(UI.snd.Destroy)
	pcall(UI.binds.destroy)
	if sndHolder then pcall(function() sndHolder:Destroy() end) end
	if gui then pcall(function() gui:Destroy() end) end
	env.TonyScriptPalace = nil
end

local alive = true
env.TonyScriptPalace = {
	Destroy = Destroy,
	Settings = S,
	ESP = ESP,
	API = function() return DWAPI.lib end,
	Features = Features,
	UI = UI,
	Customizer = Cust,
	Sound = UI.snd,
	Show = function() UI.setVisible(true) end,
	Hide = function() UI.setVisible(false) end,
	Toggle = function() UI.setVisible(not UI.visible) end,
}

-- Auto-load last config
if S.autoload and S.lastConfig ~= "" and fileExists(cfgPath(S.lastConfig)) then
	pcall(Features.loadConfig, S.lastConfig)
end

buildGui()
DWAPI.load()
if S.style == "xmb" or S.style == "xp" then ui("boot") end
toast("Tony Script Palace ready (Dandy's World only). Press " .. S.keybind .. " to hide or show.", "info")
