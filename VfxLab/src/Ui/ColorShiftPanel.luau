-- VfxLab ColorShiftPanel (Vide): live HSL shift across the selection.
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)

local ColorShiftPanel = {}

local snapshots = {}
local shiftValues = { Hue = 0, Saturation = 0, Lightness = 0 }
local setters = {}
local setters = {}

local function rgbToHsl(color)
	local r, g, b = color.R, color.G, color.B
	local maxValue = math.max(r, g, b)
	local minValue = math.min(r, g, b)
	local lightness = (maxValue + minValue) * 0.5
	if maxValue == minValue then return 0, 0, lightness end
	local delta = maxValue - minValue
	local saturation = lightness > 0.5 and delta / (2 - maxValue - minValue) or delta / (maxValue + minValue)
	local hue
	if maxValue == r then
		hue = (g - b) / delta + (g < b and 6 or 0)
	elseif maxValue == g then
		hue = (b - r) / delta + 2
	else
		hue = (r - g) / delta + 4
	end
	return hue / 6, saturation, lightness
end

local function hueToRgb(p, q, t)
	if t < 0 then t += 1 end
	if t > 1 then t -= 1 end
	if t < 1 / 6 then return p + (q - p) * 6 * t end
	if t < 1 / 2 then return q end
	if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
	return p
end

local function hslToColor(hue, saturation, lightness)
	hue = hue % 1
	saturation = math.clamp(saturation, 0, 1)
	lightness = math.clamp(lightness, 0, 1)
	if saturation == 0 then return Color3.new(lightness, lightness, lightness) end
	local q = lightness < 0.5 and lightness * (1 + saturation) or lightness + saturation - lightness * saturation
	local p = 2 * lightness - q
	return Color3.new(hueToRgb(p, q, hue + 1 / 3), hueToRgb(p, q, hue), hueToRgb(p, q, hue - 1 / 3))
end

local function shiftColor(color)
	local hue, saturation, lightness = rgbToHsl(color)
	return hslToColor(
		hue + shiftValues.Hue / 360,
		saturation + shiftValues.Saturation / 100,
		lightness + shiftValues.Lightness / 100
	)
end

local function shiftSequence(sequence)
	local points = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(points, ColorSequenceKeypoint.new(point.Time, shiftColor(point.Value)))
	end
	return ColorSequence.new(points)
end

local function shiftEncodedColor(value)
	local numbers = {}
	for token in string.gmatch(value, "[%-%d%.]+") do
		table.insert(numbers, tonumber(token))
	end
	if #numbers < 5 or #numbers % 5 ~= 0 then return value end
	for index = 1, #numbers, 5 do
		local color = shiftColor(Color3.new(
			math.clamp(numbers[index + 1] or 0, 0, 1),
			math.clamp(numbers[index + 2] or 0, 0, 1),
			math.clamp(numbers[index + 3] or 0, 0, 1)
		))
		numbers[index + 1], numbers[index + 2], numbers[index + 3] = color.R, color.G, color.B
	end
	local output = {}
	for index, number in ipairs(numbers) do output[index] = string.format("%.6g", number) end
	return table.concat(output, " ")
end

local function addSnapshot(seen, instance, kind, key, value)
	seen[instance] = seen[instance] or {}
	local id = kind .. "|" .. key
	if seen[instance][id] then return end
	seen[instance][id] = true
	table.insert(snapshots, { Instance = instance, Kind = kind, Key = key, Value = value })
end

local function capture(targetLabel)
	table.clear(snapshots)
	local seenInstances = {}
	local seenValues = {}
	for _, selected in ipairs(Selection:Get()) do
		local objects = { selected }
		for _, descendant in ipairs(selected:GetDescendants()) do table.insert(objects, descendant) end
		for _, object in ipairs(objects) do
			if not seenInstances[object] then
				seenInstances[object] = true
				if object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail") then
					addSnapshot(seenValues, object, "Property", "Color", object.Color)
				elseif object:IsA("BasePart") or object:IsA("Light") then
					addSnapshot(seenValues, object, "Property", "Color", object.Color)
				elseif object:IsA("Decal") or object:IsA("Texture") then
					addSnapshot(seenValues, object, "Property", "Color3", object.Color3)
				elseif object:IsA("Highlight") then
					addSnapshot(seenValues, object, "Property", "FillColor", object.FillColor)
					addSnapshot(seenValues, object, "Property", "OutlineColor", object.OutlineColor)
				end
				for name, value in pairs(object:GetAttributes()) do
					if typeof(value) == "Color3" or typeof(value) == "ColorSequence" then
						addSnapshot(seenValues, object, "Attribute", name, value)
					elseif name == "Color" and type(value) == "string" then
						addSnapshot(seenValues, object, "EncodedColor", name, value)
				end
				end
			end
		end
	end
	if targetLabel then
		targetLabel.Text = #snapshots > 0 and (#snapshots .. " COLOR VALUE" .. (#snapshots == 1 and "" or "S")) or "NO COLOR VALUES"
	end
end

local function transformed(value)
	if typeof(value) == "Color3" then return shiftColor(value) end
	if typeof(value) == "ColorSequence" then return shiftSequence(value) end
	return value
end

local function applyShift()
	for _, snapshot in ipairs(snapshots) do
		local object = snapshot.Instance
		if object and object.Parent then
			pcall(function()
				if snapshot.Kind == "Property" then
					object[snapshot.Key] = transformed(snapshot.Value)
				elseif snapshot.Kind == "Attribute" then
					object:SetAttribute(snapshot.Key, transformed(snapshot.Value))
				elseif snapshot.Kind == "EncodedColor" then
					object:SetAttribute(snapshot.Key, shiftEncodedColor(snapshot.Value))
				end
			end)
		end
	end
end

local function restore()
	for _, snapshot in ipairs(snapshots) do
		local object = snapshot.Instance
		if object and object.Parent then
			pcall(function()
				if snapshot.Kind == "Property" then object[snapshot.Key] = snapshot.Value
				else object:SetAttribute(snapshot.Key, snapshot.Value) end
			end)
		end
	end
end

local function hueGradient()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 225, 70)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(70, 255, 100)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(70, 225, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(80, 100, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(220, 70, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 70)),
	})
end

-- Returns { Window, Destroy }.
function ColorShiftPanel.Create(parentGui)
	local refs = {}
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabColorShift",
			Id = "shifter_color",
			Title = "COLOR SHIFT",
			Subtitle = "Live HSL shift",
			Size = UDim2.fromOffset(292, 320),
			Position = UDim2.new(0.5, -146, 0.5, -160),
		})
		refs.window = built.Frame
		local content = built.Content
		refs.targetLabel = Kit.Label(content, "NO COLOR VALUES", 10, Theme.Text())
		refs.targetLabel.LayoutOrder = nextOrder()
		refs.targetLabel.Size = UDim2.new(1, 0, 0, 18)
		local function sliderRow(name, minimum, maximum, gradient, layoutOrder)
			local holder = create "Frame" {
				BackgroundTransparency = 1,
			LayoutOrder = layoutOrder,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = content,
			create "UIListLayout" {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			}
			local top = create "Frame" {
				BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 16),
				Parent = holder,
			}
			local nameLabel = Kit.Label(top, name, 10, Theme.Text())
			nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
			local valueLabel = Kit.Label(top, "0", 9, Theme.Text(), Enum.TextXAlignment.Right)
			valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
			valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
			local api = Kit.Slider(holder, {
				Min = minimum,
				Max = maximum,
				Value = 0,
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 8),
				Gradient = gradient,
				OnChange = function(v)
					shiftValues[name] = v
					valueLabel.Text = (v > 0 and "+" or "") .. tostring(math.round(v))
					applyShift()
				end,
			})
			setters[name] = function(v, silent)
				api.Set(v, true)
				shiftValues[name] = v
				valueLabel.Text = (v > 0 and "+" or "") .. tostring(math.round(v))
				if silent ~= true then applyShift() end
			end
		end
		sliderRow("Hue", -180, 180, hueGradient(), nextOrder())
		sliderRow("Saturation", -100, 100, ColorSequence.new(Color3.fromRGB(65, 65, 68), Color3.fromRGB(255, 80, 95)), nextOrder())
		sliderRow("Lightness", -100, 100, ColorSequence.new(Color3.fromRGB(8, 8, 9), Color3.fromRGB(250, 250, 250)), nextOrder())
		local actions = create "Frame" {
			BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 30),
			Parent = content,
		create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		Kit.Button(actions, {
			Text = "RESET",
			TextSize = 10,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 1,
			OnClick = function()
				for _, setter in pairs(setters) do setter(0, false) end
				applyShift()
			end,
		})
		Kit.Button(actions, {
			Text = "CANCEL",
			TextSize = 10,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 2,
			OnClick = function()
				restore()
				Kit.TogglePanel(refs.window, false)
			end,
		})
		Kit.Button(actions, {
			Text = "APPLY",
			TextSize = 10,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 3,
			Primary = true,
			OnClick = function()
				ChangeHistoryService:SetWaypoint("VfxLab Color Shift")
				Kit.TogglePanel(refs.window, false)
			end,
		})
	end)
	ColorShiftPanel._refs = refs
	ColorShiftPanel._stop = stop
	return { Window = refs.window, Destroy = stop }
end

function ColorShiftPanel.Open()
	local refs = ColorShiftPanel._refs
	if not refs or not refs.window then return end
	if refs.window.Visible then
		restore()
		Kit.TogglePanel(refs.window, false)
		return
	end
	for _, setter in pairs(setters) do setter(0, false) end
	ChangeHistoryService:SetWaypoint("VfxLab Color Shift - Before")
	capture(refs.targetLabel)
	Kit.TogglePanel(refs.window, true)
end

function ColorShiftPanel.SetShift(hue, saturation, lightness)
	if setters.Hue then setters.Hue(tonumber(hue) or 0, false) end
	if setters.Saturation then setters.Saturation(tonumber(saturation) or 0, false) end
	if setters.Lightness then setters.Lightness(tonumber(lightness) or 0, false) end
	applyShift()
end

function ColorShiftPanel.GetTargetCount()
	return #snapshots
end

function ColorShiftPanel.Restore()
	restore()
end

return ColorShiftPanel
