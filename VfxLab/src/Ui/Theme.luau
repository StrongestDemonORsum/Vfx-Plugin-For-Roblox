-- VfxLab Theme: purplish darker default palette (BetterVfx-inspired).
-- Tokens ported from BetterVfx ui_theme/ui_conf (Fusion -> Vide-safe statics + sources).
local Vide = require(script.Parent.Parent.Modules.vide)
local source = Vide.source

local GOTHAM = "rbxasset://fonts/families/Gotham.json"

-- Inter first (BetterVfx font), Gotham fallback: Gotham fails to load on
-- some machines (see boot log), Inter is the reference font.
local okInter, interFont = pcall(Font.fromId, 16658221428)
local InterMedium = (okInter and interFont) or Font.new(GOTHAM, Enum.FontWeight.Medium)

local Theme = {
	Background = source(Color3.fromRGB(36, 31, 49)),
	Surface = source(Color3.fromRGB(50, 43, 69)),
	Input = source(Color3.fromRGB(50, 43, 69)),
	Selected = source(Color3.fromRGB(143, 123, 255)),
	Hover = source(Color3.fromRGB(61, 54, 84)),
	Border = source(Color3.fromRGB(74, 67, 96)),
	Raised = source(Color3.fromRGB(69, 62, 94)),
	Error = source(Color3.fromRGB(255, 107, 107)),
	OnAccent = source(Color3.fromRGB(255, 255, 255)),
	Accent = source(Color3.fromRGB(155, 140, 255)),
	AccentStroke = source(Color3.fromRGB(155, 140, 255)),
	Text = source(Color3.fromRGB(236, 233, 247)),
	SubText = source(Color3.fromRGB(164, 158, 194)),
	Pinned = source(Color3.fromRGB(255, 176, 32)),
	White = source(Color3.fromRGB(255, 255, 255)),
	Slider = source(Color3.fromRGB(74, 67, 96)),
	Overlay = source(Color3.fromRGB(74, 67, 96)),
	Muted = source(Color3.fromRGB(126, 120, 150)),
	Highlight = source(Color3.fromRGB(90, 84, 120)),
	Font = InterMedium,
	FontBold = (okInter and interFont) or Font.new(GOTHAM, Enum.FontWeight.Bold),
	Inter = InterMedium,
	InterSemi = (okInter and interFont) or Font.new(GOTHAM, Enum.FontWeight.Bold),
	Mono = Enum.Font.RobotoMono,
	HOVER_STRENGTH = 0.4,
	HoverScale = 1,
	DisplayOrder = 1000,
	Pad = 5,
	Gap = 5,
	Radius = 6,
	RowH = 24,
	-- BetterVfx ui_conf tokens (px)
	TextSizes = { Nano = 15, Mini = 16, Base = 18, TitleBar = 18, Title = 20, Special = 24 },
	Rounding = { Base = 8, Mini = 6, Nano = 4 },
	Padding = { Resize = 4, Base = 4, Prop = 6, Side = 8 },
	TitleBarH = 26,
	Changed = Instance.new("BindableEvent"),
}

Theme.Default = "Reference"
Theme._active = "Reference"
Theme.Presets = {
	Reference = {
		Background = Color3.fromRGB(36, 31, 49),
		Surface = Color3.fromRGB(50, 43, 69),
		Input = Color3.fromRGB(50, 43, 69),
		Selected = Color3.fromRGB(143, 123, 255),
		Hover = Color3.fromRGB(61, 54, 84),
		Border = Color3.fromRGB(74, 67, 96),
		Raised = Color3.fromRGB(69, 62, 94),
		Error = Color3.fromRGB(255, 107, 107),
		OnAccent = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(155, 140, 255),
		AccentStroke = Color3.fromRGB(155, 140, 255),
		Text = Color3.fromRGB(236, 233, 247),
		SubText = Color3.fromRGB(164, 158, 194),
		Pinned = Color3.fromRGB(255, 176, 32),
		Overlay = Color3.fromRGB(74, 67, 96),
		Muted = Color3.fromRGB(126, 120, 150),
		Highlight = Color3.fromRGB(90, 84, 120),
	},
	Violet = {
		Background = Color3.fromRGB(245, 240, 255),
		Surface = Color3.fromRGB(255, 255, 255),
		Input = Color3.fromRGB(255, 255, 255),
		Selected = Color3.fromRGB(187, 169, 255),
		Hover = Color3.fromRGB(235, 228, 250),
		Border = Color3.fromRGB(210, 200, 230),
		Raised = Color3.fromRGB(225, 218, 240),
		Error = Color3.fromRGB(200, 50, 50),
		OnAccent = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(187, 169, 255),
		AccentStroke = Color3.fromRGB(187, 169, 255),
		Text = Color3.fromRGB(40, 30, 60),
		SubText = Color3.fromRGB(140, 132, 165),
		Pinned = Color3.fromRGB(255, 170, 0),
		Overlay = Color3.fromRGB(220, 222, 228),
		Muted = Color3.fromRGB(150, 150, 160),
		Highlight = Color3.fromRGB(210, 212, 220),
	},
	Midnight = {
		Background = Color3.fromRGB(235, 238, 245),
		Surface = Color3.fromRGB(255, 255, 255),
		Input = Color3.fromRGB(255, 255, 255),
		Selected = Color3.fromRGB(140, 123, 255),
		Hover = Color3.fromRGB(225, 228, 240),
		Border = Color3.fromRGB(200, 205, 220),
		Raised = Color3.fromRGB(215, 218, 230),
		Error = Color3.fromRGB(200, 50, 50),
		OnAccent = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(140, 123, 255),
		AccentStroke = Color3.fromRGB(140, 123, 255),
		Text = Color3.fromRGB(25, 30, 45),
		SubText = Color3.fromRGB(160, 166, 182),
		Pinned = Color3.fromRGB(255, 170, 0),
		Overlay = Color3.fromRGB(220, 222, 228),
		Muted = Color3.fromRGB(150, 150, 160),
		Highlight = Color3.fromRGB(210, 212, 220),
	},
	Ember = {
		Background = Color3.fromRGB(255, 245, 240),
		Surface = Color3.fromRGB(255, 255, 255),
		Input = Color3.fromRGB(255, 255, 255),
		Selected = Color3.fromRGB(255, 138, 101),
		Hover = Color3.fromRGB(250, 235, 228),
		Border = Color3.fromRGB(230, 210, 200),
		Raised = Color3.fromRGB(240, 225, 218),
		Error = Color3.fromRGB(200, 50, 50),
		OnAccent = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(255, 138, 101),
		AccentStroke = Color3.fromRGB(255, 138, 101),
		Text = Color3.fromRGB(60, 35, 25),
		SubText = Color3.fromRGB(178, 152, 146),
		Pinned = Color3.fromRGB(255, 170, 0),
		Overlay = Color3.fromRGB(220, 222, 228),
		Muted = Color3.fromRGB(150, 150, 160),
		Highlight = Color3.fromRGB(210, 212, 220),
	},
}

function Theme.ApplyPreset(name)
	local preset = Theme.Presets[name]
	if not preset then return end
	for key, color in pairs(preset) do
		local src = Theme[key]
		if typeof(src) == "function" then pcall(src, color) end
	end
	Theme._active = name
	pcall(function() Theme.Changed:Fire(name) end)
end

-- Imperative repaint: re-apply Theme colors to an open window subtree.
-- Tagging scheme (set at creation, all static/Vide-safe):
--   ThemePaint            -> background color key (opaque colored widgets)
--   ThemePaintText        -> text color key (TextLabel/TextButton/TextBox)
--   ThemePaintPlaceholder -> placeholder color key (TextBox)
--   ToggleState (bool) + ToggleOff (key, default "Overlay") -> toggle/
--     checkbox tracks repaint Accent when on, ToggleOff when off.
-- UIStroke uses ThemePaint for Color; ImageLabel/ImageButton for ImageColor3.
local function paintOne(desc)
	local class = desc.ClassName
	if desc:IsA("UIStroke") then
		local key = desc:GetAttribute("ThemePaint")
		if key and typeof(Theme[key]) == "function" then
			local ok, c = pcall(Theme[key])
			if ok and typeof(c) == "Color3" then desc.Color = c end
		end
		return
	end
	if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
		local key = desc:GetAttribute("ThemePaint")
		if key and typeof(Theme[key]) == "function" then
			local ok, c = pcall(Theme[key])
			if ok and typeof(c) == "Color3" then desc.ImageColor3 = c end
		end
		return
	end
	local isText = desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")
	local bgKey = desc:GetAttribute("ThemePaint")
	local toggleState = desc:GetAttribute("ToggleState")
	if toggleState ~= nil then
		local key = toggleState and "Accent" or (desc:GetAttribute("ToggleOff") or "Overlay")
		if typeof(Theme[key]) == "function" then
			local ok, c = pcall(Theme[key])
			if ok and typeof(c) == "Color3" then desc.BackgroundColor3 = c end
		end
	elseif bgKey and bgKey ~= "" and not isText then
		if typeof(Theme[bgKey]) == "function" then
			local ok, c = pcall(Theme[bgKey])
			if ok and typeof(c) == "Color3" then desc.BackgroundColor3 = c end
		end
	end
	if isText then
		-- Text key: ThemePaintText, or legacy ThemePaintProp on buttons.
		local textKey = desc:GetAttribute("ThemePaintText")
		if not textKey and desc:IsA("TextButton") then
			textKey = desc:GetAttribute("ThemePaintProp")
		end
		if textKey and typeof(Theme[textKey]) == "function" then
			local ok, c = pcall(Theme[textKey])
			if ok and typeof(c) == "Color3" then desc.TextColor3 = c end
		end
		-- Background: buttons always use ThemePaint; labels/boxes only
		-- when they also carry an explicit text key (opaque rows/chips).
		if bgKey and bgKey ~= "" and (desc:IsA("TextButton") or desc:GetAttribute("ThemePaintText")) then
			if typeof(Theme[bgKey]) == "function" then
				local ok, c = pcall(Theme[bgKey])
				if ok and typeof(c) == "Color3" then desc.BackgroundColor3 = c end
			end
		end
		if desc:IsA("TextBox") then
			local phKey = desc:GetAttribute("ThemePaintPlaceholder")
			if phKey and typeof(Theme[phKey]) == "function" then
				local ok, c = pcall(Theme[phKey])
				if ok and typeof(c) == "Color3" then desc.PlaceholderColor3 = c end
			end
		end
	end
end

function Theme.RepaintStatic(root)
	if not root or not root.Parent then return end
	paintOne(root)
	for _, desc in ipairs(root:GetDescendants()) do
		paintOne(desc)
	end
end

return Theme
