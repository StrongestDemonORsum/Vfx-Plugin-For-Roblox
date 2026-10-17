-- VfxLab PropertiesPanel (Vide): matches reference PropertiesWindow layout.
-- Search box, bordered content area, custom slider, toggles, dropdowns.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local StructuredRuntime = require(script.Parent.Parent.Engine.Assets.VFXPlayer.StructuredRuntime)
local AttributeSchema = require(script.Parent.Parent.Engine.Core.AttributeSchema)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local PropertiesPanel = { Inputs = {}, Rows = {}, Sections = {} }

local Categories = {
	{Name = "Spawning", Props = {"EmitCount", "EmitDelay", "LoopDelay", "Rate", "Lifetime"}},
	{Name = "Motion", Props = {"Speed", "Drag", "SpreadAngle", "Acceleration"}},
	{Name = "Transform", Props = {"Size", "Size_X", "Size_Y", "Size_Z", "Squash", "OffsetStart", "OffsetEnd", "OffsetEasing", "EasingStyle"}},
	{Name = "Rotation", Props = {"Rotation", "RotSpeed", "MeshRotation", "MeshRotSpeed", "Orientation"}},
	{Name = "Appearance", Props = {"Texture", "Material", "Color", "Transparency", "Brightness", "LightEmission", "LightInfluence", "DecalTransStart", "DecalTransEnd", "DecalEasing"}},
	{Name = "Beam / Trail", Props = {"Width0", "Width1", "CurveSize0", "CurveSize1", "WidthScale", "MinLength", "TextureLength", "TextureSpeed", "TextureMode", "Segments", "FaceCamera", "ZOffset"}},
	{Name = "Trail Motion", Props = {"TrailPathPreset", "TrailPathMode", "TrailPathCurve", "TrailPathCount", "TrailPathBurstCount", "TrailPathStagger", "TrailPathDuration", "TrailPathDurationJitter", "TrailPathSmoothness", "TrailPathReverse", "TrailPathPingPong", "TrailPathRadius", "TrailPathTurns", "TrailPathHeight"}},
	{Name = "Trail Position Curve", Props = {"TrailPathOffsetStart", "TrailPathControl1", "TrailPathControl2", "TrailPathOffsetEnd", "TrailPathWobble", "TrailPathWobbleSpeed"}},
	{Name = "Trail Rotation Curve", Props = {"TrailPathRotationStart", "TrailPathRotationEnd", "TrailPathRotationSpread", "TrailPathRotationSpeed", "TrailPathOrientationOffset", "TrailPathRandomRotation", "TrailPathFaceMotion"}},
	{Name = "Lightning Spread", Props = {"LightningMode", "LightningBoltCount", "LightningSpread"}},
	{Name = "Lightning Path", Props = {"LightningCurveSize0", "LightningCurveSize1", "LightningSegments", "LightningFrequency", "LightningMinRadius", "LightningMaxRadius"}},
	{Name = "Lightning Colors", Props = {"LightningPartColor", "LightningHighlightColor"}},
	{Name = "Lightning Shape", Props = {"LightningThickness", "LightningMinThicknessMultiplier", "LightningMaxThicknessMultiplier", "LightningGlowThickness", "LightningTransparency", "LightningGlowTransparency", "LightningFlicker"}},
	{Name = "Lightning Motion", Props = {"LightningLifetime", "LightningAnimationSpeed", "LightningRefreshRate", "LightningPulseSpeed", "LightningPulseLength", "LightningFadeLength", "LightningContractFrom"}},
	{Name = "Lightning Branches", Props = {"LightningBranches", "LightningBranchChance", "LightningBranchLength", "LightningBranchSegments"}},
	{Name = "Highlight", Props = {"HL_Enabled", "HL_FillColor", "HL_OutlineColor", "HL_FillTrans", "HL_OutTrans"}},
}
PropertiesPanel.TypeLists = {
	Mesh = { "Texture", "Material", "Color", "Transparency", "EmitCount", "EmitDelay", "LoopDelay", "Rate", "Lifetime", "Speed", "Size", "Size_X", "Size_Y", "Size_Z", "MeshRotation", "MeshRotSpeed", "Drag", "SpreadAngle", "Acceleration", "OffsetStart", "OffsetEnd", "OffsetEasing", "EasingStyle", "HL_Enabled", "HL_FillColor", "HL_OutlineColor", "HL_FillTrans", "HL_OutTrans", "DecalTransStart", "DecalTransEnd", "DecalEasing" },
	Particle = { "Texture", "Orientation", "LightEmission", "LightInfluence", "Color", "Transparency", "EmitCount", "EmitDelay", "Rate", "Lifetime", "Speed", "Size", "Squash", "Rotation", "RotSpeed", "Drag", "SpreadAngle", "Acceleration" },
	Beam = { "Color", "Transparency", "EmitCount", "EmitDelay", "Width0", "Width1", "CurveSize0", "CurveSize1", "TextureLength", "TextureSpeed", "TextureMode", "Segments", "FaceCamera", "ZOffset", "Brightness", "LightEmission", "LightInfluence" },
	Trail = { "Color", "Transparency", "EmitCount", "EmitDelay", "Lifetime", "WidthScale", "MinLength", "TextureLength", "TextureMode", "FaceCamera", "LightEmission", "LightInfluence", "TrailPathPreset", "TrailPathMode", "TrailPathCurve", "TrailPathRadius", "TrailPathTurns", "TrailPathHeight", "TrailPathCount", "TrailPathBurstCount", "TrailPathStagger", "TrailPathDuration", "TrailPathDurationJitter", "TrailPathSmoothness", "TrailPathReverse", "TrailPathPingPong", "TrailPathOffsetStart", "TrailPathControl1", "TrailPathControl2", "TrailPathOffsetEnd", "TrailPathWobble", "TrailPathWobbleSpeed", "TrailPathRotationStart", "TrailPathRotationEnd", "TrailPathRotationSpread", "TrailPathRotationSpeed", "TrailPathOrientationOffset", "TrailPathRandomRotation", "TrailPathFaceMotion" },
	Lightning = { "LightningPartColor", "LightningHighlightColor", "EmitCount", "EmitDelay", "LoopDelay", "Rate", "LightningMode", "LightningBoltCount", "LightningSpread", "LightningCurveSize0", "LightningCurveSize1", "LightningSegments", "LightningFrequency", "LightningMinRadius", "LightningMaxRadius", "LightningThickness", "LightningMinThicknessMultiplier", "LightningMaxThicknessMultiplier", "LightningGlowThickness", "LightningTransparency", "LightningGlowTransparency", "LightningFlicker", "LightningLifetime", "LightningAnimationSpeed", "LightningRefreshRate", "LightningPulseSpeed", "LightningPulseLength", "LightningFadeLength", "LightningContractFrom", "LightningBranches", "LightningBranchChance", "LightningBranchLength", "LightningBranchSegments" },
}
local OptionsMap = {
	LightningMode = {"Single", "Spread", "Radial"},
	TrailPathPreset = {"Custom", "b1 - Swirl Burst", "b2 - Scatter Burst", "b3 - Orbit Burst"},
	TrailPathMode = {"Static", "Bezier Orbit", "Spiral", "Radial In", "Radial Out"},
	TrailPathCurve = {"Custom", "Linear", "Quad In", "Quad Out", "Quad InOut", "Smooth", "Smoother", "Snap"},
	TrailPathRandomRotation = {"false", "true"},
	TrailPathFaceMotion = {"false", "true"},
	TrailPathReverse = {"false", "true"},
	TrailPathPingPong = {"false", "true"},
	Orientation = {"Camera", "WorldUp", "Parallel", "Perpendicular"},
	OffsetEasing = {"Linear", "EaseIn", "EaseOut", "EaseInOut", "Spike", "Sine"},
	DecalEasing = {"Linear", "EaseIn", "EaseOut", "EaseInOut", "Spike", "Sine"},
	Material = {"Plastic", "Neon", "Glass", "Metal", "Wood", "ForceField"},
	TextureMode = {"Stretch", "Wrap", "Static"},
	HL_Enabled = {"true", "false"},
	FaceCamera = {"true", "false"},
}
local Vector3Props = {
	Acceleration = true, OffsetStart = true, OffsetEnd = true,
	TrailPathOffsetStart = true, TrailPathControl1 = true, TrailPathControl2 = true,
	TrailPathOffsetEnd = true, TrailPathWobble = true, TrailPathWobbleSpeed = true,
	TrailPathRotationStart = true, TrailPathRotationEnd = true, TrailPathRotationSpread = true,
	TrailPathRotationSpeed = true, TrailPathOrientationOffset = true,
}
local ColorProps = {
	Color = true, LightningPartColor = true, LightningHighlightColor = true,
	HL_FillColor = true, HL_OutlineColor = true,
}
local SliderRanges = {
	Transparency = {0, 1}, Brightness = {0, 10}, Rate = {0, 100},
	ZOffset = {-10, 10}, Drag = {0, 10}, Speed = {0, 50},
	Lifetime = {0, 5}, Rotation = {-360, 360}, RotSpeed = {-360, 360},
	LightEmission = {0, 1}, LightInfluence = {0, 1},
	EmitCount = {0, 100}, EmitDelay = {0, 5}, LoopDelay = {0, 5},
	Width0 = {0, 10}, Width1 = {0, 10}, CurveSize0 = {-10, 10}, CurveSize1 = {-10, 10},
	Segments = {1, 100}, MinLength = {0, 10},
	SpreadAngle = {0, 180}, VelocityInheritance = {0, 1}, TimeScale = {0, 10},
	TextureLength = {0, 10}, TextureSpeed = {-10, 10},
}
PropertiesPanel.SliderRanges = SliderRanges
local panelGui = nil

local function prettyName(prop)
	return prop:gsub("(%l)(%u)", "%1 %2")
end

local function detect()
	local emitter = EmitterManager.CurrentEmitters[1]
	if not emitter then return nil end
	local info = { emitter = emitter }
	info.lightning = EmitterManager.IsLightningEmitter(emitter)
	info.singleBeam = EmitterManager.IsSingleBeamEmitter(emitter)
	info.particle = emitter:IsA("ParticleEmitter")
	info.beam = emitter:IsA("Beam")
	info.trail = emitter:IsA("Trail")
	info.structured = StructuredRuntime.IsStructured(emitter)
	if info.structured then info.kind = EmitterManager.GetStructuredKind(emitter) end
	info.custom = (emitter:IsA("Folder") or emitter:IsA("Model")) and emitter:GetAttribute("IsMeshEmitter") == true
	return info
end

local function listFor(info)
	if info.lightning then return PropertiesPanel.TypeLists.Lightning end
	if info.singleBeam then return PropertiesPanel.TypeLists.Beam end
	if info.particle then return PropertiesPanel.TypeLists.Particle end
	if info.beam then return PropertiesPanel.TypeLists.Beam end
	if info.trail then return PropertiesPanel.TypeLists.Trail end
	if info.structured then return info.kind == "Beam" and PropertiesPanel.TypeLists.Beam or PropertiesPanel.TypeLists.Mesh end
	return PropertiesPanel.TypeLists.Mesh
end

local function readProp(emitter, prop, info)
	local value
	if info.lightning or info.singleBeam then
		value = EmitterManager.GetSetting(emitter, prop, nil)
		if value == nil then value = emitter:GetAttribute(prop) end
		return value
	end
	if info.structured then
		local ok, result = pcall(AttributeSchema.Read, emitter, prop, false)
		if ok then return result end
		return emitter:GetAttribute(prop)
	end
	local target = EmitterManager.GetPropertyTarget(emitter, prop) or emitter
	value = target:GetAttribute(prop)
	if value ~= nil then return value end
	local ok, result = pcall(function() return target[prop] end)
	if ok then return result end
	return nil
end

local function formatValue(value)
	if value == nil then return "" end
	local t = typeof(value)
	if t == "boolean" then return value and "true" or "false" end
	if t == "EnumItem" then return value.Name end
	if t == "NumberRange" then return string.format("%.3f, %.3f", value.Min, value.Max) end
	if t == "Vector2" then return string.format("%.3f, %.3f", value.X, value.Y) end
	if t == "Vector3" then return string.format("%.3f, %.3f, %.3f", value.X, value.Y, value.Z) end
	if t == "Color3" then
		return string.format("%d, %d, %d", math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
	end
	if t == "ColorSequence" or t == "NumberSequence" then return "Sequence" end
	if t == "number" then
		local s = string.format("%.3f", value)
		s = s:gsub("0+$", ""):gsub("%.$", ".0")
		if math.abs(value) >= 100 then
			s = string.format("%.1f", value)
		end
		return s
	end
	return tostring(value)
end

local function apply(prop, text)
	EmitterManager.ApplySmartProperty(prop, text)
	PropertiesPanel.UpdateUI()
end

local function buildSlider(holder, prop, info)
	local range = SliderRanges[prop] or {0, 10}
	local min, max = range[1], range[2]
	local startValue = min
	if info and info.emitter then
		local ok, v = pcall(readProp, info.emitter, prop, info)
		if ok and typeof(v) == "number" then startValue = v end
	end
	local value = source(startValue)
	local track = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Background(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.new(1, -30, 0, 6),
		Text = "",
		Parent = holder,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local fill = create "Frame" {
		BackgroundColor3 = Theme.Accent(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local knob = create "Frame" {
		BackgroundColor3 = Theme.Accent(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 13),
		Position = UDim2.new(0, 0, 0.5, 0),
		Parent = track,
		create "UICorner" { CornerRadius = UDim.new(0, 4) },
	}
	local hit = create "TextButton" {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(22, 10),
		Text = "",
		ZIndex = 2,
		Parent = knob,
	}
	local label = create "TextLabel" {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		Size = UDim2.new(0, 28, 1, 0),
		Position = UDim2.new(1, 4, 0, 0),
		Text = function()
			local v = value()
			if math.abs(v) >= 100 then return string.format("%.1f", v) end
			return string.format("%.3g", v)
		end,
		TextColor3 = Theme.SubText(),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = track,
	}
	local function updateVisual()
		local alpha = math.clamp((value() - min) / math.max(max - min, 0.0001), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end
	updateVisual()
	local sliding = false
	local function fromMouse(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		value(min + (max - min) * alpha)
		updateVisual()
		apply(prop, string.format("%.3f", value()))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			fromMouse(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			fromMouse(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
	end)
	PropertiesPanel.Inputs[prop] = { Set = function(text) value(tonumber(text) or min) updateVisual() end }
	return track
end

local function buildToggle(holder, prop, info)
	local initial = nil
	if info and info.emitter then
		local ok, v = pcall(readProp, info.emitter, prop, info)
		if ok then initial = v end
	end
	local on = initial == true or initial == "true"
	-- BetterVfx CheckboxInput: square, primary when on else overlay, nano round.
	local track = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = on and Theme.Accent() or Theme.Overlay(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -20, 0.5, -9),
		Text = "",
		Parent = holder,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Nano) },
		create "UIAspectRatioConstraint" { AspectRatio = 1 },
	}
	track.Activated:Connect(function()
		on = not on
		TweenService:Create(track, TweenInfo.new(0.15), {
			BackgroundColor3 = on and Theme.Accent() or Theme.Overlay(),
		}):Play()
		apply(prop, on and "true" or "false")
	end)
	PropertiesPanel.Inputs[prop] = {
		Set = function(text)
			on = text == "true" or text == true
			track.BackgroundColor3 = on and Theme.Accent() or Theme.Overlay()
		end,
	}
	return track
end

local function buildDropdown(holder, prop, info)
	local initial = ""
	if info then initial = formatValue(readProp(info.emitter, prop, info)) end
	local current = source(initial)
	local open = source(false)
	local btn = Kit.Button(holder, {
		Text = function() return current() .. "  v" end,
		TextSize = 11,
		Size = UDim2.new(1, 0, 1, -4),
		LayoutOrder = 1,
		OnClick = function() open(not open()) end,
	})
	btn.Position = UDim2.new(0, 0, 0, 3)
	local list = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, #OptionsMap[prop] * 20 + 6),
		Position = UDim2.new(0, 0, 1, 2),
		Visible = function() return open() end,
		ZIndex = 10,
		Parent = holder,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
		create "UIStroke" { Color = Theme.Border(), Thickness = 1 },
		create "UIListLayout" { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder },
		create "UIPadding" {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		},
	}
	for i, option in ipairs(OptionsMap[prop]) do
		Kit.Button(list, {
			Text = option,
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = i,
			Corner = 4,
			ZIndex = 11,
			OnClick = function()
				open(false)
				current(option)
				apply(prop, option)
			end,
		})
	end
	PropertiesPanel.Inputs[prop] = { Set = function(text) current(text) end }
	return btn
end

local function buildVector3(holder, prop)
	local boxes = {}
	for i = 1, 3 do
		local box = Kit.TextInput(holder, {
			Size = UDim2.new(0.32, 0, 1, -4),
			Position = UDim2.new((i - 1) * 0.34, 0, 0, 2),
			TextSize = 11,
			Placeholder = ({"X", "Y", "Z"})[i],
			OnFocusLost = function()
				local parts = {}
				for _, b in ipairs(boxes) do table.insert(parts, b.Text) end
				apply(prop, table.concat(parts, ", "))
			end,
		})
		table.insert(boxes, box)
	end
	PropertiesPanel.Inputs[prop] = {
		Set3 = function(x, y, z)
			boxes[1].Text = x
			boxes[2].Text = y
			boxes[3].Text = z
		end,
	}
	return boxes[1]
end

local function buildMeshRotation(holder, prop)
	local axes = {}
	for i, axis in ipairs({ "X", "Y", "Z" }) do
		local box = Kit.TextInput(holder, {
			Size = UDim2.new(0.32, 0, 1, -4),
			Position = UDim2.new((i - 1) * 0.34, 0, 0, 2),
			TextSize = 11,
			Placeholder = axis,
			OnFocusLost = function(text)
				local a, b = text:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)")
				if a and b then
					apply(prop .. "_" .. axis, a .. ", " .. b)
				else
					apply(prop .. "_" .. axis, (tonumber(text) or 0) .. ", " .. (tonumber(text) or 0))
				end
			end,
		})
		table.insert(axes, box)
	end
	PropertiesPanel.Inputs[prop] = { Axes = axes }
	return axes[1]
end

local function buildColor(holder, prop, info)
	local ColorWheel = require(script.Parent.ColorWheel)
	local box = Kit.TextInput(holder, {
		Size = UDim2.new(1, -24, 1, -4),
		Position = UDim2.new(0, 24, 0, 2),
		TextSize = 11,
		Placeholder = "R, G, B",
		OnFocusLost = function(text) apply(prop, text) end,
	})
	local swatch = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Name = "Swatch",
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 0, 0, 1),
		Text = "",
		Parent = holder,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
		create "UIStroke" { Color = Theme.Border(), Transparency = 0.3 },
		Activated = function()
			local r, g, b = box.Text:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
			if r and g and b then
				ColorWheel.SetColor(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
			end
			ColorWheel.Create(panelGui, function(rgb) apply(prop, rgb) end)
			ColorWheel.Open()
		end,
	}
	PropertiesPanel.Inputs[prop] = {
		Set = function(text, color)
			box.Text = text
			if color then swatch.BackgroundColor3 = color end
		end,
	}
	return box
end

local function buildDefault(holder, prop)
	local box = Kit.TextInput(holder, {
		Size = UDim2.new(1, 0, 1, -4),
		Position = UDim2.new(0, 0, 0, 2),
		TextSize = 11,
		OnFocusLost = function(text) apply(prop, text) end,
	})
	PropertiesPanel.Inputs[prop] = { Set = function(text) box.Text = text end }
	return box
end

local rowOrder = 0
local function nextOrderRow()
	rowOrder += 1
	return rowOrder
end

local function buildRow(sectionContent, prop, info, index)
	-- BetterVfx Attribute: 24px surface row, 1px overlay separator, 50/50 split.
	local row = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = nextOrderRow(),
		Size = UDim2.new(1, 0, 0, Theme.RowH),
		Name = "Row_" .. prop,
		Parent = sectionContent,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
	}
	if (index or 1) > 1 then
		create "Frame" {
			BackgroundColor3 = Theme.Overlay(),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Name = "Separator",
			Size = UDim2.new(1, 0, 0, 1),
			Parent = row,
		}
	end
	local label = create "TextLabel" {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		Size = UDim2.new(0.5, -Theme.Padding.Prop, 1, 0),
		Position = UDim2.new(0, Theme.Padding.Prop, 0, 0),
		Text = prettyName(prop),
		TextColor3 = Theme.Text(),
		TextSize = Theme.TextSizes.Mini,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	}
	local holder = create "Frame" {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(0.5, 0, 1, -2),
		Parent = row,
	}
	if OptionsMap[prop] then
		buildDropdown(holder, prop, info)
	elseif prop == "Enabled" or prop == "LockedToPart" or prop == "HL_Enabled"
		or prop == "FaceCamera" then
		buildToggle(holder, prop, info)
	elseif Vector3Props[prop] then
		buildVector3(holder, prop)
	elseif prop == "MeshRotation" or prop == "MeshRotSpeed" then
		buildMeshRotation(holder, prop)
	elseif ColorProps[prop] then
		buildColor(holder, prop, info)
	elseif SliderRanges[prop] then
		buildSlider(holder, prop, info)
	else
		buildDefault(holder, prop)
	end
	PropertiesPanel.Rows[prop] = { Row = row, Prop = prop }
	return row
end

-- Returns { Window, Destroy }.
function PropertiesPanel.Create(parentGui)
	panelGui = parentGui
	PropertiesPanel.Inputs = {}
	PropertiesPanel.Rows = {}
	PropertiesPanel.Sections = {}
	rowOrder = 0
	local window, order
	local stop = mount(function()
		order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabProperties",
			Id = "attributes",
			Title = "Properties",
			Subtitle = "Select an emitter to edit",
			Size = UDim2.fromOffset(270, 400),
			Position = UDim2.new(0.5, 0, 0.3, 0),
		})
		window = built.Frame
		local content = built.Content
		local searchBox = create "Frame" {
			BackgroundColor3 = Theme.Background(),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			Parent = content,
			create "UICorner" { CornerRadius = UDim.new(0, 7) },
		}
		local searchInput = create "TextBox" {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			FontFace = Theme.Font,
PlaceholderColor3 = Theme.SubText(),
			PlaceholderText = "Search",
			Size = UDim2.new(1, -34, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			Text = "",
TextColor3 = Theme.Text(),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = searchBox,
		}
		searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			PropertiesPanel.UpdateUI()
		end)
		PropertiesPanel._search = searchInput
		local keyframeBar = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
			Name = "KeyframeBar",
			Size = UDim2.new(1, 0, 0, 28),
			Visible = false,
			Parent = content,
		}
		PropertiesPanel._keyframeBar = keyframeBar
		Kit.Button(keyframeBar, {
			Text = "START",
			Size = UDim2.new(0.48, 0, 1, 0),
			LayoutOrder = 1,
			OnClick = function() EmitterManager.SetStructuredState("Start") end,
		})
		Kit.Button(keyframeBar, {
			Text = "END",
			Size = UDim2.new(0.48, 0, 1, 0),
			Position = UDim2.new(0.52, 0, 0, 0),
			LayoutOrder = 2,
			OnClick = function() EmitterManager.SetStructuredState("End") end,
		})
		local info = detect()
		for _, cat in ipairs(Categories) do
			local section = Kit.Section(content, cat.Name, nextOrder())
			PropertiesPanel.Sections[cat.Name] = section
			local rowIndex = 0
			for _, prop in ipairs(cat.Props) do
				if not PropertiesPanel.Rows[prop] then
					rowIndex += 1
					buildRow(section, prop, info, rowIndex)
				end
			end
		end
	end)
	PropertiesPanel._stop = stop
	PropertiesPanel.UpdateUI()
	return { Window = window, Destroy = stop }
end

function PropertiesPanel.Destroy()
	if PropertiesPanel._stop then PropertiesPanel._stop() PropertiesPanel._stop = nil end
end

-- Mirrors the reference: search narrows, type list filters, values refresh.
function PropertiesPanel.UpdateUI()
	if not PropertiesPanel.Sections or not next(PropertiesPanel.Sections) then return end
	local info = detect()
	local searchBox = PropertiesPanel._search
	local query = searchBox and string.lower(searchBox.Text) or ""
	for prop, entry in pairs(PropertiesPanel.Rows) do
		local show = false
		if info then
			if query ~= "" then
				show = string.find(string.lower(prop), query, 1, true) ~= nil
			else
				show = table.find(listFor(info), prop) ~= nil
			end
		end
		entry.Row.Visible = show
		if show and info then
			local value = readProp(info.emitter, prop, info)
			local input = PropertiesPanel.Inputs[prop]
			if input then
				if input.Set3 and typeof(value) == "Vector3" then
					input.Set3(string.format("%.3f", value.X), string.format("%.3f", value.Y), string.format("%.3f", value.Z))
				elseif input.Axes then
					local emitter = info.emitter
					for _, axis in ipairs({ "X", "Y", "Z" }) do
						local range = emitter:GetAttribute(prop .. "_" .. axis)
						if typeof(range) == "NumberRange" then
							local map = { X = 1, Y = 2, Z = 3 }
							input.Axes[map[axis]].Text = string.format("%.2f, %.2f", range.Min, range.Max)
						end
					end
				elseif input.Set then
					if typeof(value) == "Color3" then
						input.Set(formatValue(value), value)
					elseif SliderRanges[prop] then
						input.Set(formatValue(value))
					else
						input.Set(formatValue(value))
					end
				end
			end
		end
	end
	for catName, section in pairs(PropertiesPanel.Sections) do
		local has = false
		for _, cat in ipairs(Categories) do
			if cat.Name == catName then
				for _, prop in ipairs(cat.Props) do
					local entry = PropertiesPanel.Rows[prop]
					if entry and entry.Row.Visible then has = true break end
				end
			end
		end
		section.Visible = has
	end
	local keyframeBar = PropertiesPanel._keyframeBar
	if keyframeBar then
		keyframeBar.Visible = info ~= nil and (info.singleBeam or (info.structured and info.kind == "Mesh"))
	end
end

return PropertiesPanel
