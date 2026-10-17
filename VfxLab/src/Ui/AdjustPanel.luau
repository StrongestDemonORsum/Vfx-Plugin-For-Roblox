-- VfxLab AdjustPanel (Vide): Resize + Retime + Shift in one window.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local PropertiesPanel = require(script.Parent.PropertiesPanel)

local AdjustPanel = {}

local function refreshProps()
	pcall(PropertiesPanel.UpdateUI)
end

-- BetterVfx Resize/Retime layout: min/factor/max fields, live-preview slider
-- on surface bg, primary commit button + reset button. previewFn applies
-- incrementally without undo waypoints; applyFn commits with history.
local function buildMult(section, initial, previewFn, applyFn, verb)
	local factor = source(initial)
	local prevFactor = initial
	local minVal, maxVal = 0.5, 2
	local rowH = Theme.TextSizes.Mini + Theme.Padding.Base * 2
	local fields = create "Frame" {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, rowH),
		Parent = section,
		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, Theme.Padding.Side),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
	local function numField(order, text, placeholder, onLost)
		local box = Kit.TextInput(fields, {
			Size = UDim2.new(0.75, 0, 1, 0),
			LayoutOrder = order,
			Text = text,
			TextSize = Theme.TextSizes.Mini,
			Placeholder = placeholder,
			OnFocusLost = onLost,
		})
		return box
	end
	local minBox = numField(1, "0.5", "min", function(text)
		minVal = math.max(tonumber(text) or 0.5, 0.001)
	end)
	local factorBox = Kit.TextInput(fields, {
		Size = UDim2.new(1, 0, 1, 0),
		LayoutOrder = 2,
		Text = tostring(initial),
		TextSize = Theme.TextSizes.Mini,
		Placeholder = "factor",
		OnFocusLost = function(text)
			local v = math.max(tonumber(text) or initial, 0.001)
			previewFn(v / prevFactor)
			prevFactor = v
			factor(v)
			if sliderApi then sliderApi.Set(v, true) end
		end,
	})
	local maxBox = numField(3, "2", "max", function(text)
		maxVal = math.max(tonumber(text) or 2, minVal)
	end)
	local sliderApi = nil
	local sliderWrap = create "Frame" {
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 8 + Theme.Padding.Prop),
		Parent = section,
	}
	sliderApi = Kit.Slider(sliderWrap, {
		Min = minVal,
		Max = maxVal,
		Value = initial,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 8),
		OnChange = function(v)
			factor(v)
			factorBox.Text = string.format("%.3f", v):gsub("0+$", ""):gsub("%.$", "")
			previewFn(v / prevFactor)
			prevFactor = v
		end,
	})
	local btnRow = create "Frame" {
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, rowH),
		Parent = section,
		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, Theme.Padding.Side),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
	local applyBtn
	applyBtn = Kit.Button(btnRow, {
		Text = verb,
		TextSize = Theme.TextSizes.Mini,
		Size = UDim2.new(1, 0, 1, 0),
		LayoutOrder = 1,
		Primary = true,
		OnClick = function()
			if applyFn(factor()) then
				prevFactor = 1
				factor(1)
				factorBox.Text = "1"
				if sliderApi then sliderApi.Set(1, true) end
				applyBtn.Text = "Applied!"
				task.delay(0.8, function()
					if applyBtn.Parent then applyBtn.Text = verb end
				end)
				refreshProps()
			end
		end,
	})
	Kit.Button(btnRow, {
		Text = "R",
		TextSize = Theme.TextSizes.Mini,
		Size = UDim2.new(0, rowH, 1, 0),
		LayoutOrder = 2,
		OnClick = function()
			previewFn(1 / prevFactor)
			prevFactor = 1
			factor(1)
			factorBox.Text = "1"
			if sliderApi then sliderApi.Set(1, true) end
		end,
	})
	return applyBtn
end

-- Returns { Window, Destroy }.
function AdjustPanel.Create(parentGui)
	local refs = {}
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabAdjust",
			Id = "adjust",
			Title = "ADJUST",
			Subtitle = "Resize, retime, shift",
			Size = UDim2.fromOffset(248, 480),
			Position = UDim2.new(0, 300, 0.5, -240),
		})
		refs.window = built.Frame
		local content = built.Content
		local resizeSection = Kit.Section(content, "Resize", nextOrder())
		buildMult(resizeSection, 1, EmitterManager.PreviewResize, EmitterManager.ResizeVFX, "resize")
		local retimeSection = Kit.Section(content, "Retime", nextOrder())
		buildMult(retimeSection, 1, EmitterManager.PreviewRetime, EmitterManager.RetimeVFX, "retime")
		local shiftSection = Kit.Section(content, "Shift", nextOrder())
		local fields = {}
		for i, entry in ipairs({ { "Hue", "0" }, { "Saturation", "0" }, { "Brightness", "0" }, { "Size", "1" }, { "Lifetime", "1" }, { "Speed", "1" }, { "Light", "0" } }) do
			local row, holder = Kit.Row(shiftSection, entry[1], i)
			local box = Kit.TextInput(holder, {
				Size = UDim2.new(1, 0, 1, -6),
			Position = UDim2.new(0, 0, 0, 3),
			TextSize = 11,
			Text = entry[2],
			})
			fields[entry[1]] = box
		end
		Kit.Button(shiftSection, {
			Text = "Apply shift",
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 8,
			Primary = true,
			OnClick = function()
				local ok = EmitterManager.ShiftVFX({
					Hue = tonumber(fields.Hue.Text) or 0,
					Saturation = tonumber(fields.Saturation.Text) or 0,
					Brightness = tonumber(fields.Brightness.Text) or 0,
					SizeFactor = tonumber(fields.Size.Text) or 1,
					LifetimeFactor = tonumber(fields.Lifetime.Text) or 1,
					SpeedFactor = tonumber(fields.Speed.Text) or 1,
					LightEmission = tonumber(fields.Light.Text) or 0,
				})
				if ok then refreshProps() end
			end,
		})
	end)
	return { Window = refs.window, Destroy = stop }
end

return AdjustPanel
