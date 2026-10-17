-- VfxLab ScreenFXPanel (Vide): screen & post FX attributes on selection.
local Selection = game:GetService("Selection")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)

local ScreenFXPanel = {}

local ATTRS = {
	{ "toggle", "Attach to screen", "IsScreenFX" },
	{ "toggle", "FOV kick", "SFX_UseFOV" },
	{ "number", "Start FOV", "SFX_StartFOV", 110 },
	{ "number", "End FOV", "SFX_EndFOV", 70 },
	{ "number", "FOV duration", "SFX_FOVDuration", 0.3 },
	{ "toggle", "Blur", "SFX_UseBlur" },
	{ "number", "Blur size", "SFX_BlurSize", 25 },
	{ "number", "Blur duration", "SFX_BlurDuration", 0.4 },
	{ "toggle", "Vignette", "SFX_UseVignette" },
	{ "number", "Vignette fade in", "SFX_VigFadeIn", 0.1 },
	{ "number", "Vignette hold", "SFX_VigDuration", 0.2 },
	{ "number", "Vignette fade out", "SFX_VigFadeOut", 0.3 },
	{ "toggle", "Camera shake", "SFX_UseShake" },
	{ "number", "Shake magnitude", "SFX_ShakeMag", 5 },
	{ "number", "Shake roughness", "SFX_ShakeRough", 10 },
	{ "number", "Shake fade in", "SFX_ShakeFadeIn", 0.05 },
	{ "number", "Shake fade out", "SFX_ShakeFadeOut", 0.15 },
}

local function target()
	return Selection:Get()[1]
end

-- Returns { Window, Destroy }. Sync() refreshes from selection.
function ScreenFXPanel.Create(parentGui)
	local refs = { states = {}, boxes = {} }
	local order = 0
	local stop = mount(function()
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabScreenFX",
			Id = "screenfx",
			Title = "SCREEN FX",
			Subtitle = "Camera and screen effects",
			Size = UDim2.fromOffset(264, 480),
			Position = UDim2.new(1, -592, 0.5, -240),
		})
		refs.window = built.Frame
		local content = built.Content
		for _, entry in ipairs(ATTRS) do
			local row, holder = Kit.Row(content, entry[2], nextOrder())
			row.Name = "SFX_" .. entry[3]
			if entry[1] == "toggle" then
				local attr = entry[3]
				local btn, set = Kit.Toggle(holder, false, function(on)
					local obj = target()
					if obj then
						obj:SetAttribute(attr, on)
						if attr == "IsScreenFX" then obj:SetAttribute("SFX_Enabled", true) end
					end
				end)
				btn.Size = UDim2.new(1, 0, 1, -6)
				btn.Position = UDim2.new(0, 0, 0, 3)
				refs.states[attr] = set
			else
				local attr, def = entry[3], entry[4]
				local box = Kit.TextInput(holder, {
					Size = UDim2.new(1, 0, 1, -6),
				Position = UDim2.new(0, 0, 0, 3),
				TextSize = 11,
				Text = tostring(def),
					OnFocusLost = function(text)
						local obj = target()
						local num = tonumber(text)
						if obj and num ~= nil then obj:SetAttribute(attr, num) end
					end,
				})
				refs.boxes[attr] = box
			end
		end
		Selection.SelectionChanged:Connect(function() ScreenFXPanel.Sync() end)
	end)
	ScreenFXPanel._refs = refs
	ScreenFXPanel._stop = stop
	ScreenFXPanel.Sync()
	return { Window = refs.window, Destroy = stop }
end

function ScreenFXPanel.Destroy()
	if ScreenFXPanel._stop then ScreenFXPanel._stop() ScreenFXPanel._stop = nil end
end

function ScreenFXPanel.Sync()
	local refs = ScreenFXPanel._refs
	if not refs or not refs.window then return end
	local obj = target()
	for attr, set in pairs(refs.states) do
		set(obj and obj:GetAttribute(attr) == true)
	end
	for attr, box in pairs(refs.boxes) do
		if obj and obj:GetAttribute(attr) ~= nil then
			box.Text = tostring(obj:GetAttribute(attr))
		end
	end
end

return ScreenFXPanel
