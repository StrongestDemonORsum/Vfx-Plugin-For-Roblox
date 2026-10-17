-- VfxLab DebrisPanel (Vide): ground debris attributes on the selection.
local Selection = game:GetService("Selection")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)

local DebrisPanel = {}

local ATTRS = {
	{ "toggle", "Ground debris", "Debris_Enabled" },
	{ "number", "Crater rings", "Debris_Rings", 3 },
	{ "number", "Base amount", "Debris_Amount", 8 },
	{ "number", "Size multiplier", "Debris_SizeMult", 0.43 },
	{ "number", "Base size", "Debris_Size", 0.7 },
	{ "toggle", "No smoke", "Debris_NoSmoke" },
	{ "toggle", "No sound", "Debris_NoSound" },
	{ "toggle", "No rocks", "Debris_NoDebris" },
}

local function target()
	return Selection:Get()[1]
end

-- Returns { Window, Destroy }. Sync() refreshes from selection.
function DebrisPanel.Create(parentGui)
	local refs = { states = {}, boxes = {} }
	local order = 0
	local stop = mount(function()
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabDebris",
			Id = "debris",
			Title = "DEBRIS",
			Subtitle = "Ground crater debris",
			Size = UDim2.fromOffset(264, 380),
			Position = UDim2.new(1, -592, 0.5, -190),
		})
		refs.window = built.Frame
		local content = built.Content
		for _, entry in ipairs(ATTRS) do
			local row, holder = Kit.Row(content, entry[2], nextOrder())
			row.Name = "Debris_" .. entry[3]
			if entry[1] == "toggle" then
				local attr = entry[3]
				local btn, set = Kit.Toggle(holder, false, function(on)
					local obj = target()
					if obj then obj:SetAttribute(attr, on) end
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
		Selection.SelectionChanged:Connect(function() DebrisPanel.Sync() end)
	end)
	DebrisPanel._refs = refs
	DebrisPanel._stop = stop
	DebrisPanel.Sync()
	return { Window = refs.window, Destroy = stop }
end

function DebrisPanel.Destroy()
	if DebrisPanel._stop then DebrisPanel._stop() DebrisPanel._stop = nil end
end

function DebrisPanel.Sync()
	local refs = DebrisPanel._refs
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

return DebrisPanel
