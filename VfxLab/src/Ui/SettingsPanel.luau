-- VfxLab SettingsPanel (Vide): BetterVfx Settings parity. Section titles,
-- number/boolean/dropdown/keybind rows backed by plugin:GetSetting with
-- .conf defaults, commit footer, reset buttons. All static + imperative.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local ColorWheel = require(script.Parent.ColorWheel)
local EmitController = require(script.Parent.Parent.Engine.EmitController)

local SettingsPanel = {}
local activeTarget = "Background"
local wheelBuilt = false

-- BetterVfx .conf defaults (persisted via plugin settings).
local DEFAULTS = {
	RepeatTimer = 2, TrailRadius = 5, TrailLapDuration = 2,
	PathWorkers = 24, PathPoints = 200, PathSampleRate = 32, PathTransparency = 0.75,
	FlipbookFPS = 60,
	ImportServices = true, ImportWorkspace = false, ServicesFullName = true,
	CheckUpdates = true,
	UiScale = 1, DisplayOrder = 1000, FontId = 16658221428,
	BtnHorizontal = "Right", BtnVertical = "Bottom", BtnDirection = "Horizontal",
	TextBase = 18, TextMini = 16, TextNano = 15, TextTitle = 20, TextTitleBar = 18, TextSpecial = 24,
	RoundBase = 8, RoundMini = 6, RoundNano = 4,
	PadBase = 4, PadProp = 6, PadSide = 8, PadResize = 4,
	KeyToggleUI = "LeftControl,Quote", KeyAdder = "Backquote", KeyEmit = "R",
	KeyEnabled = "LeftShift,R", KeyPaths = "LeftControl,Q",
}

function SettingsPanel.Get(plugin, key)
	if plugin then
		local ok, val = pcall(function() return plugin:GetSetting("VfxLabSet_" .. key) end)
		if ok and val ~= nil then return val end
	end
	return DEFAULTS[key]
end

function SettingsPanel.Set(plugin, key, value)
	if plugin then pcall(function() plugin:SetSetting("VfxLabSet_" .. key, value) end) end
end

local function applyWheelPick(rgbString)
	local r, g, b = rgbString:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
	if not (r and g and b) then return end
	local color = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
	Theme._active = nil
	if SettingsPanel._markActive then pcall(SettingsPanel._markActive) end
	if activeTarget == "Background" then Theme.Background(color)
	elseif activeTarget == "Text" then Theme.Text(color)
	elseif activeTarget == "Accent" then Theme.Accent(color) end
end

local function titleRow(content, text, size, order)
	local label = Kit.Label(content, text, size or Theme.TextSizes.Title, Theme.Text())
	label.FontFace = Theme.FontBold
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 22)
	return label
end

local function numberRow(content, name, key, plugin, order, min, max, isInt)
	local _, holder = Kit.Row(content, name, order)
	local box = Kit.TextInput(holder, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = tostring(SettingsPanel.Get(plugin, key)),
		TextSize = Theme.TextSizes.Mini,
		OnFocusLost = function(text)
			local v = tonumber(text)
			if v then
				v = math.clamp(v, min or -math.huge, max or math.huge)
				if isInt then v = math.round(v) end
				SettingsPanel.Set(plugin, key, v)
				box.Text = tostring(v)
			else
				box.Text = tostring(SettingsPanel.Get(plugin, key))
			end
		end,
	})
	return box
end

local function boolRow(content, name, key, plugin, order)
	local _, holder = Kit.Row(content, name, order)
	local current = SettingsPanel.Get(plugin, key) == true
	local btn, set = Kit.Checkbox(holder, current, function(next)
		SettingsPanel.Set(plugin, key, next)
	end, 18)
	btn.Position = UDim2.new(1, -20, 0.5, -9)
	return btn
end

local function dropRow(content, name, key, plugin, order, options)
	local _, holder = Kit.Row(content, name, order)
	local current = tostring(SettingsPanel.Get(plugin, key))
	local btn = Kit.Button(holder, {
		Text = current,
		TextSize = Theme.TextSizes.Mini,
		Size = UDim2.new(1, 0, 1, 0),
		OnClick = function()
			local pos = btn.AbsolutePosition + Vector2.new(0, btn.AbsoluteSize.Y + 2)
			local menuOpts = {}
			for _, opt in ipairs(options) do
				table.insert(menuOpts, { Name = opt, OnClick = function()
					SettingsPanel.Set(plugin, key, opt)
					btn.Text = opt
				end })
			end
			Kit.Options(holder:FindFirstAncestorOfClass("ScreenGui"), pos, menuOpts)
		end,
	})
	return btn
end

local function keyRow(content, name, key, plugin, order)
	local _, holder = Kit.Row(content, name, order)
	local btn = Kit.Button(holder, {
		Text = tostring(SettingsPanel.Get(plugin, key)),
		TextSize = Theme.TextSizes.Mini,
		Size = UDim2.new(1, 0, 1, 0),
	})
	btn.Activated:Connect(function()
		btn.Text = "press keys..."
		local pressed, conns, idle
		local function finish()
			for _, c in ipairs(conns) do c:Disconnect() end
			if idle then task.cancel(idle) end
			if #pressed > 0 then
				local seq = table.concat(pressed, ",")
				SettingsPanel.Set(plugin, key, seq)
				btn.Text = seq
			else
				btn.Text = tostring(SettingsPanel.Get(plugin, key))
			end
		end
		local armIdle
		armIdle = function()
			if idle then task.cancel(idle) end
			idle = task.delay(0.6, finish)
		end
		conns = {
			game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
				if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				local nm = input.KeyCode.Name
				if not table.find(pressed, nm) then table.insert(pressed, nm) end
				btn.Text = table.concat(pressed, "+")
				armIdle()
			end),
		}
		armIdle()
	end)
	return btn
end

-- Returns { Window, Destroy }.
function SettingsPanel.Create(parentGui, plugin)
	if not wheelBuilt then
		ColorWheel.Create(parentGui, applyWheelPick)
		wheelBuilt = true
	end
	local refs = {}
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabSettings",
			Title = "SETTINGS",
			Subtitle = "Theme + system",
			Size = UDim2.fromOffset(292, 420),
			Position = UDim2.new(0.5, -146, 0.5, -210),
			Id = "settings",
		})
		refs.window = built.Frame
		local content = built.Content
		-- Theme presets (VfxLab extra on top of BetterVfx).
		Kit.Section(content, "INTERFACE THEME", nextOrder())
		local presetBtns = {}
		local function markActive()
			for name, btn in pairs(presetBtns) do
				if btn and btn.Parent then
					btn.Text = (Theme._active == name and "● " or "○ ") .. name
				end
			end
		end
		for _, name in ipairs({ "Reference", "Violet", "Midnight", "Ember" }) do
			local btn = Kit.Button(content, {
				Text = name,
				TextSize = Theme.TextSizes.Mini,
				Size = UDim2.new(1, 0, 0, 24),
				LayoutOrder = nextOrder(),
				OnClick = function()
					Theme.ApplyPreset(name)
					markActive()
				end,
			})
			presetBtns[name] = btn
		end
		markActive()
		SettingsPanel._markActive = markActive
		local function themeButton(label, target, layoutOrder)
			Kit.Button(content, {
				Text = label,
				TextSize = Theme.TextSizes.Mini,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = layoutOrder,
				OnClick = function()
					activeTarget = target
					local current
					if target == "Background" then current = Theme.Background()
					elseif target == "Text" then current = Theme.Text()
					elseif target == "Accent" then current = Theme.Accent() end
					ColorWheel.SetColor(current)
					ColorWheel.Open()
				end,
			})
		end
		themeButton("Background color", "Background", nextOrder())
		themeButton("Text color", "Text", nextOrder())
		themeButton("Accent color", "Accent", nextOrder())
		-- BetterVfx Settings sections.
		local sec = Kit.Section(content, "EMISSION", nextOrder())
		numberRow(sec, "Repeat Timer", "RepeatTimer", plugin, 1, 0, math.huge)
		numberRow(sec, "Trail Radius", "TrailRadius", plugin, 2, 0, math.huge)
		numberRow(sec, "Trail Lap", "TrailLapDuration", plugin, 3, 0, math.huge)
		sec = Kit.Section(content, "PATH PREVIEW", nextOrder())
		numberRow(sec, "Workers", "PathWorkers", plugin, 1, 1, math.huge, true)
		numberRow(sec, "Max Points", "PathPoints", plugin, 2, 0, math.huge, true)
		numberRow(sec, "Sample Rate", "PathSampleRate", plugin, 3, 0, math.huge, true)
		numberRow(sec, "Transparency", "PathTransparency", plugin, 4, 0, 1)
		sec = Kit.Section(content, "FLIPBOOKS", nextOrder())
		numberRow(sec, "Default FPS", "FlipbookFPS", plugin, 1, 0.001, math.huge)
		sec = Kit.Section(content, "EMIT CODE", nextOrder())
		boolRow(sec, "Import Services", "ImportServices", plugin, 1)
		boolRow(sec, "Import Workspace", "ImportWorkspace", plugin, 2)
		boolRow(sec, "Full Names", "ServicesFullName", plugin, 3)
		sec = Kit.Section(content, "NOTIFICATIONS", nextOrder())
		boolRow(sec, "Check Updates", "CheckUpdates", plugin, 1)
		sec = Kit.Section(content, "INTERFACE", nextOrder())
		numberRow(sec, "Scale", "UiScale", plugin, 1, 0.5, 3)
		numberRow(sec, "Display Order", "DisplayOrder", plugin, 2, -math.huge, math.huge, true)
		numberRow(sec, "Font Id", "FontId", plugin, 3, 0, math.huge, true)
		dropRow(sec, "Btn Horizontal", "BtnHorizontal", plugin, 4, { "Left", "Center", "Right" })
		dropRow(sec, "Btn Vertical", "BtnVertical", plugin, 5, { "Top", "Center", "Bottom" })
		dropRow(sec, "Btn Direction", "BtnDirection", plugin, 6, { "Horizontal", "Vertical" })
		sec = Kit.Section(content, "KEYBINDS", nextOrder())
		keyRow(sec, "Toggle UI", "KeyToggleUI", plugin, 1)
		keyRow(sec, "Adder (`)", "KeyAdder", plugin, 2)
		keyRow(sec, "Emit", "KeyEmit", plugin, 3)
		keyRow(sec, "Toggle Enabled", "KeyEnabled", plugin, 4)
		keyRow(sec, "Toggle Paths", "KeyPaths", plugin, 5)
		sec = Kit.Section(content, "SYSTEM", nextOrder())
		local clearBtn
		clearBtn = Kit.Button(sec, {
			Text = "Clear preview cache",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			OnClick = function()
				EmitController.ClearCache()
				EmitController.ClearVisualizer()
				clearBtn.Text = "Cleared!"
				task.delay(1, function()
					if clearBtn and clearBtn.Parent then clearBtn.Text = "Clear preview cache" end
				end)
			end,
		})
		Kit.Button(sec, {
			Text = "Open update log",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 2,
			OnClick = function() if SettingsPanel._openLog then pcall(SettingsPanel._openLog) end end,
		})
		sec = Kit.Section(content, "RESET OPTIONS", nextOrder())
		local resetBtn
		resetBtn = Kit.Button(sec, {
			Text = "Reset settings",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			OnClick = function()
				if plugin then
					for key, _ in pairs(DEFAULTS) do
						pcall(function() plugin:SetSetting("VfxLabSet_" .. key, nil) end)
					end
				end
				resetBtn.Text = "Settings reset"
				task.delay(1.2, function()
					if resetBtn and resetBtn.Parent then resetBtn.Text = "Reset settings" end
				end)
			end,
		})
		Kit.Button(sec, {
			Text = "Reset window layout",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 2,
			OnClick = function()
				if plugin then
					for _, id in ipairs({ "tools", "attributes", "settings", "library", "adjust",
						"copier", "curve", "shifter_color", "screenfx", "debris", "emitcode",
						"shifter", "emit", "updlog", "flipbooks", "emitimport" }) do
						pcall(function() plugin:SetSetting("VfxLabWin_" .. id, nil) end)
					end
				end
				for _, child in ipairs(parentGui:GetChildren()) do
					if child:IsA("Frame") and child.Name:find("VfxLab") then
						child.Position = UDim2.new(0.5, -child.Size.X.Offset / 2, 0.5, -child.Size.Y.Offset / 2)
					end
				end
			end,
		})
		sec = Kit.Section(content, "DANGER ZONE", nextOrder())
		Kit.Button(sec, {
			Text = "Reset all data",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			Danger = true,
			OnClick = function()
				if plugin then
					for key, _ in pairs(DEFAULTS) do
						pcall(function() plugin:SetSetting("VfxLabSet_" .. key, nil) end)
					end
					pcall(function() plugin:SetSetting("VfxLab_PresetNames", nil) end)
				end
				Kit.Notify(parentGui, "All VfxLab data reset")
			end,
		})
		local foot = Kit.Label(content, "VfxLab v0.6 (Vide)", Theme.TextSizes.Mini, Theme.Highlight())
		foot.LayoutOrder = nextOrder()
		foot.Size = UDim2.new(1, 0, 0, 18)
		foot.TextXAlignment = Enum.TextXAlignment.Center
	end)
	SettingsPanel._refs = refs
	SettingsPanel._stop = stop
	return { Window = refs.window, Destroy = stop }
end

function SettingsPanel.Open()
	local refs = SettingsPanel._refs
	if not refs or not refs.window then return end
	Kit.TogglePanel(refs.window, not refs.window.Visible)
end

return SettingsPanel
