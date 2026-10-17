local TweenService = game:GetService("TweenService")
local StructuredRuntime = require(script.Parent.Assets.VFXPlayer.StructuredRuntime)
local AttributeSchema = require(script.Parent.Core.AttributeSchema)

local EmitterManager = {
	CurrentEmitters = {},
	CurrentParts = {}, 
	TargetName = "None"
}

local TRAIL_PATH_PRESETS = {
	["b1 - Swirl Burst"] = {
		TrailPathMode = "Bezier Orbit", TrailPathCurve = "Custom",
		TrailPathCount = 6, TrailPathBurstCount = 5, TrailPathStagger = 0.025,
		TrailPathDuration = 0.5, TrailPathDurationJitter = 0, TrailPathSmoothness = 0.18,
		TrailPathReverse = false, TrailPathPingPong = false,
		TrailPathOffsetStart = Vector3.new(0, 0, 10.5), TrailPathOffsetEnd = Vector3.zero,
		TrailPathControl1 = Vector3.new(0, 0, 10.5), TrailPathControl2 = Vector3.new(0, 0, 8.1),
		TrailPathWobble = Vector3.new(0.35, 0.2, 0.35), TrailPathWobbleSpeed = Vector3.new(1.4, 2.1, 1.7),
		TrailPathRotationStart = Vector3.zero, TrailPathRotationEnd = Vector3.new(0, 360, 0),
		TrailPathRotationSpread = Vector3.new(0, 360, 0), TrailPathRotationSpeed = Vector3.new(0, 90, 0),
		TrailPathOrientationOffset = Vector3.zero, TrailPathRandomRotation = false,
		TrailPathFaceMotion = false, VisualXCurveP1 = Vector2.new(0.7, 0), VisualXCurveP2 = Vector2.new(0.97, 0.23),
	},
	["b2 - Scatter Burst"] = {
		TrailPathMode = "Bezier Orbit", TrailPathCurve = "Quad In",
		TrailPathCount = 1, TrailPathBurstCount = 12, TrailPathStagger = 0.035,
		TrailPathDuration = 0.55, TrailPathDurationJitter = 0.18, TrailPathSmoothness = 0.1,
		TrailPathReverse = false, TrailPathPingPong = false,
		TrailPathOffsetStart = Vector3.new(0, 0, 10.5), TrailPathOffsetEnd = Vector3.zero,
		TrailPathControl1 = Vector3.new(0, 0, 9), TrailPathControl2 = Vector3.new(0, 0, 3),
		TrailPathWobble = Vector3.new(0.2, 0.2, 0.2), TrailPathWobbleSpeed = Vector3.new(2.2, 1.7, 2.5),
		TrailPathRotationStart = Vector3.zero, TrailPathRotationEnd = Vector3.zero,
		TrailPathRotationSpread = Vector3.new(360, 360, 360), TrailPathRotationSpeed = Vector3.zero,
		TrailPathOrientationOffset = Vector3.zero, TrailPathRandomRotation = true,
		TrailPathFaceMotion = true, VisualXCurveP1 = Vector2.new(0.55, 0), VisualXCurveP2 = Vector2.new(0.8, 0.35),
	},
	["b3 - Orbit Burst"] = {
		TrailPathMode = "Bezier Orbit", TrailPathCurve = "Custom",
		TrailPathCount = 1, TrailPathBurstCount = 5, TrailPathStagger = 0.055,
		TrailPathDuration = 0.5, TrailPathDurationJitter = 0, TrailPathSmoothness = 0.2,
		TrailPathReverse = false, TrailPathPingPong = false,
		TrailPathOffsetStart = Vector3.new(0, 0, 10.5), TrailPathOffsetEnd = Vector3.zero,
		TrailPathControl1 = Vector3.new(0, 0, 10.5), TrailPathControl2 = Vector3.new(0, 0, 8.1),
		TrailPathWobble = Vector3.new(0.15, 0.1, 0.15), TrailPathWobbleSpeed = Vector3.new(1.2, 1.8, 1.4),
		TrailPathRotationStart = Vector3.zero, TrailPathRotationEnd = Vector3.new(0, 360, 0),
		TrailPathRotationSpread = Vector3.new(0, 360, 0), TrailPathRotationSpeed = Vector3.new(0, 135, 0),
		TrailPathOrientationOffset = Vector3.zero, TrailPathRandomRotation = false,
		TrailPathFaceMotion = false, VisualXCurveP1 = Vector2.new(0.7, 0), VisualXCurveP2 = Vector2.new(0.97, 0.23),
	},
}

local function applyTrailPathPreset(emitter, presetName)
	local preset = TRAIL_PATH_PRESETS[presetName]
	emitter:SetAttribute("TrailPathPreset", presetName)
	if not preset then return end
	for name, value in pairs(preset) do emitter:SetAttribute(name, value) end
end

local function ensureBezierTrailDefaults(emitter)
	local defaults = {
		TrailPathPreset = "Custom", TrailPathCurve = "Custom", TrailPathCount = 1,
		TrailPathBurstCount = 1, TrailPathStagger = 0, TrailPathDuration = 1,
		TrailPathDurationJitter = 0, TrailPathSmoothness = 0.12,
		TrailPathReverse = false, TrailPathPingPong = false, TrailPathOffsetStart = Vector3.new(0, 0, 8),
		TrailPathOffsetEnd = Vector3.zero, TrailPathControl1 = Vector3.new(0, 0, 8),
		TrailPathControl2 = Vector3.new(0, 0, 4), TrailPathWobble = Vector3.zero,
		TrailPathWobbleSpeed = Vector3.new(1, 1, 1), TrailPathRotationStart = Vector3.zero,
		TrailPathRotationEnd = Vector3.new(0, 360, 0), TrailPathRotationSpread = Vector3.new(0, 360, 0),
		TrailPathRotationSpeed = Vector3.zero, TrailPathOrientationOffset = Vector3.zero,
		TrailPathRandomRotation = false, TrailPathFaceMotion = false,
		VisualXCurveP1 = Vector2.new(0.35, 0), VisualXCurveP2 = Vector2.new(0.65, 1),
	}
	for name, value in pairs(defaults) do
		if emitter:GetAttribute(name) == nil then emitter:SetAttribute(name, value) end
	end
end

local function lightningTemplate()
	local assets = script.Parent:FindFirstChild("Assets")
	local meshes = assets and assets:FindFirstChild("Meshes")
	local template = meshes and meshes:FindFirstChild("LightningTemplate")
	return template and template:IsA("BasePart") and template or nil
end

local function lightningTemplateSettings()
	local template = lightningTemplate()
	local highlight = template and template:FindFirstChildWhichIsA("Highlight")
	return {
		Template = template,
		PartColor = template and template.Color or Color3.fromRGB(255, 0, 0),
		HighlightColor = highlight and highlight.FillColor or Color3.fromRGB(0, 0, 0),
		HighlightTransparency = highlight and highlight.FillTransparency or 0,
	}
end

function EmitterManager.GetLightningTemplate()
	return lightningTemplate()
end

function EmitterManager.SyncLightningTemplate()
	local template = lightningTemplate()
	if not template then return false end
	local targets = {}
	local pluginRuntime = script.Parent.Assets.VFXPlayer.Runtime:FindFirstChild("LightningRuntime")
	if pluginRuntime then table.insert(targets, pluginRuntime) end
	for _, rootName in ipairs({"VisualX", "VFXPlayer"}) do
		local runtimeRoot = game.ReplicatedStorage:FindFirstChild(rootName)
		local runtimeFolder = runtimeRoot and runtimeRoot:FindFirstChild("Runtime")
		local runtimeModule = runtimeFolder and runtimeFolder:FindFirstChild("LightningRuntime")
		if runtimeModule then table.insert(targets, runtimeModule) end
	end
	for _, runtimeModule in ipairs(targets) do
		local old = runtimeModule:FindFirstChild("LightningTemplate")
		if old then old:Destroy() end
		local packaged = template:Clone()
		packaged.Name = "LightningTemplate"
		packaged.Parent = runtimeModule
	end
	return true
end

local function isCustomEmitter(instance)
	return (instance:IsA("Folder") or instance:IsA("Model")) and instance:GetAttribute("IsMeshEmitter") == true
end

local function isStructuredEmitter(instance)
	return StructuredRuntime.IsStructured(instance)
end

local function isLightningEmitter(instance)
	return instance:IsA("BasePart") and instance:GetAttribute("IsLightning") == true
		and (instance:GetAttribute("VisualXVersion") ~= nil or instance:FindFirstChild("Settings") ~= nil)
end

local function isSingleBeamEmitter(instance)
	return instance:IsA("BasePart") and instance:GetAttribute("VisualXSingleBeam") == true
		and instance:FindFirstChildWhichIsA("Beam", true) ~= nil
end

EmitterManager.IsStructuredEmitter = isStructuredEmitter
EmitterManager.IsLightningEmitter = isLightningEmitter
EmitterManager.IsSingleBeamEmitter = isSingleBeamEmitter

local function settingsObject(emitter, create)
	if not emitter or typeof(emitter) ~= "Instance" then return nil end
	local settings = emitter:FindFirstChild("Settings")
	if settings and settings:IsA("Configuration") then return settings end
	if not create then return nil end
	settings = Instance.new("Configuration")
	settings.Name = "Settings"
	settings.Parent = emitter
	return settings
end

function EmitterManager.GetSettings(emitter, create)
	return settingsObject(emitter, create)
end

function EmitterManager.GetSetting(emitter, name, defaultValue)
	local settings = settingsObject(emitter, false)
	local value = settings and settings:GetAttribute(name)
	if value == nil and emitter then value = emitter:GetAttribute(name) end
	if value == nil then return defaultValue end
	return value
end

function EmitterManager.SetSetting(emitter, name, value)
	local settings = settingsObject(emitter, true)
	settings:SetAttribute(name, value)
end

local BEAM_NATIVE_PROPERTIES = {
	Width0 = true, Width1 = true, CurveSize0 = true, CurveSize1 = true,
	Segments = true, ZOffset = true, Brightness = true,
	LightEmission = true, LightInfluence = true, FaceCamera = true,
	Texture = true, TextureLength = true, TextureSpeed = true,
	TextureMode = true, Color = true, Transparency = true,
}

local function serializeColorSequence(sequence)
	local chunks = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(chunks, string.format("%.6f,%.6f,%.6f,%.6f", point.Time, point.Value.R, point.Value.G, point.Value.B))
	end
	return table.concat(chunks, ";")
end

local function deserializeColorSequence(encoded)
	local points = {}
	for chunk in string.gmatch(tostring(encoded or ""), "[^;]+") do
		local time, red, green, blue = chunk:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		if time and red and green and blue then
			table.insert(points, ColorSequenceKeypoint.new(tonumber(time), Color3.new(tonumber(red), tonumber(green), tonumber(blue))))
		end
	end
	if #points == 0 then return ColorSequence.new(Color3.new(1, 1, 1)) end
	if #points == 1 then return ColorSequence.new(points[1].Value) end
	return ColorSequence.new(points)
end

local function serializeNumberSequence(sequence)
	local chunks = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(chunks, string.format("%.6f,%.6f,%.6f", point.Time, point.Value, point.Envelope))
	end
	return table.concat(chunks, ";")
end

local function deserializeNumberSequence(encoded)
	local points = {}
	for chunk in string.gmatch(tostring(encoded or ""), "[^;]+") do
		local time, value, envelope = chunk:match("([^,]+),([^,]+),([^,]+)")
		if time and value and envelope then
			table.insert(points, NumberSequenceKeypoint.new(tonumber(time), tonumber(value), tonumber(envelope)))
		end
	end
	if #points == 0 then return NumberSequence.new(0) end
	if #points == 1 then return NumberSequence.new(points[1].Value) end
	return NumberSequence.new(points)
end

local function timelineState(container, stateName, create)
	local timeline = container:FindFirstChild("Timeline")
	if not timeline and create then
		timeline = Instance.new("Folder")
		timeline.Name = "Timeline"
		timeline.Parent = container
	end
	if not timeline then return nil end
	local state = timeline:FindFirstChild(stateName)
	if state and state:IsA("Configuration") then return state end
	if not create then return nil end
	state = Instance.new("Configuration")
	state.Name = stateName
	state.Parent = timeline
	return state
end

local function captureBeamStateRaw(container, stateName)
	local beam = container:FindFirstChildWhichIsA("Beam", true)
	local state = timelineState(container, stateName, true)
	if not beam or not state then return nil end
	for propertyName in pairs(BEAM_NATIVE_PROPERTIES) do
		local value = beam[propertyName]
		if propertyName == "Color" then
			state:SetAttribute(propertyName, serializeColorSequence(value))
		elseif propertyName == "Transparency" then
			state:SetAttribute(propertyName, serializeNumberSequence(value))
		elseif typeof(value) == "EnumItem" then
			state:SetAttribute(propertyName, value.Name)
		else
			state:SetAttribute(propertyName, value)
		end
	end
	state:SetAttribute("Initialized", true)
	return state
end

local function ensureSingleBeamTimeline(container)
	if not isSingleBeamEmitter(container) then return nil end
	local startState = timelineState(container, "Start", true)
	local endState = timelineState(container, "End", true)
	if startState:GetAttribute("Initialized") ~= true then
		captureBeamStateRaw(container, "Start")
	end
	if endState:GetAttribute("Initialized") ~= true then
		captureBeamStateRaw(container, "End")
		endState:SetAttribute("Width0", 0)
		endState:SetAttribute("Width1", 0)
		endState:SetAttribute("Brightness", 0)
		endState:SetAttribute("Transparency", serializeNumberSequence(NumberSequence.new(1)))
	end
	return startState, endState
end

local function applyBeamStateRaw(container, stateName)
	local beam = container:FindFirstChildWhichIsA("Beam", true)
	local state = timelineState(container, stateName, false)
	if not beam or not state then return end
	for propertyName in pairs(BEAM_NATIVE_PROPERTIES) do
		local value = state:GetAttribute(propertyName)
		if value ~= nil then
			if propertyName == "Color" then
				beam.Color = deserializeColorSequence(value)
			elseif propertyName == "Transparency" then
				beam.Transparency = deserializeNumberSequence(value)
			elseif propertyName == "TextureMode" then
				beam.TextureMode = Enum.TextureMode[tostring(value)] or Enum.TextureMode.Stretch
			else
				pcall(function() beam[propertyName] = value end)
			end
		end
	end
	beam.Enabled = false
end

function EmitterManager.EnsureSingleBeamTimeline(container)
	return ensureSingleBeamTimeline(container)
end

function EmitterManager.CaptureSingleBeamState(container, stateName)
	ensureSingleBeamTimeline(container)
	return captureBeamStateRaw(container, stateName or EmitterManager.StructuredState)
end

function EmitterManager.ApplySingleBeamState(container, stateName)
	ensureSingleBeamTimeline(container)
	applyBeamStateRaw(container, stateName or EmitterManager.StructuredState)
end

local MESH_STATE_PROPERTIES = {
	Size = true, Size_X = true, Size_Y = true, Size_Z = true,
	Material = true, Color = true, Transparency = true, Texture = true,
}

EmitterManager.StructuredState = "Start"

function EmitterManager.GetStructuredKind(container)
	if not isStructuredEmitter(container) then return nil end
	local startRoot = container:FindFirstChild("Start")
	if not startRoot then return nil end
	if startRoot:IsA("Beam") or startRoot:FindFirstChildWhichIsA("Beam", true) then return "Beam" end
	if startRoot:IsA("BasePart") or startRoot:FindFirstChildWhichIsA("BasePart", true) then return "Mesh" end
	return nil
end

function EmitterManager.GetStructuredStateObject(container, stateName)
	if not isStructuredEmitter(container) then return nil end
	local root = container:FindFirstChild(stateName or EmitterManager.StructuredState)
	if not root then return nil end
	local kind = EmitterManager.GetStructuredKind(container)
	if kind == "Beam" then return root:IsA("Beam") and root or root:FindFirstChildWhichIsA("Beam", true) end
	if kind == "Mesh" then return root:IsA("BasePart") and root or root:FindFirstChildWhichIsA("BasePart", true) end
	return nil
end

function EmitterManager.GetPropertyTarget(emitter, propertyName)
	if isSingleBeamEmitter(emitter) and BEAM_NATIVE_PROPERTIES[propertyName] then
		return emitter:FindFirstChildWhichIsA("Beam", true)
	end
	if isStructuredEmitter(emitter) then
		local kind = EmitterManager.GetStructuredKind(emitter)
		if kind == "Beam" and BEAM_NATIVE_PROPERTIES[propertyName] then
			return EmitterManager.GetStructuredStateObject(emitter)
		elseif kind == "Mesh" and MESH_STATE_PROPERTIES[propertyName] then
			return EmitterManager.GetStructuredStateObject(emitter)
		end
	end
	return emitter
end

function EmitterManager.SetStructuredState(stateName)
	local nextState = stateName == "End" and "End" or "Start"
	local previousState = EmitterManager.StructuredState
	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		if isSingleBeamEmitter(emitter) then
			ensureSingleBeamTimeline(emitter)
			captureBeamStateRaw(emitter, previousState)
		end
	end
	EmitterManager.StructuredState = nextState
	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		if isSingleBeamEmitter(emitter) then
			applyBeamStateRaw(emitter, EmitterManager.StructuredState)
		elseif isStructuredEmitter(emitter) then
			local kind = EmitterManager.GetStructuredKind(emitter)
			if kind == "Beam" then
				local startBeam = EmitterManager.GetStructuredStateObject(emitter, "Start")
				local endBeam = EmitterManager.GetStructuredStateObject(emitter, "End")
				if startBeam then startBeam.Enabled = EmitterManager.StructuredState == "Start" end
				if endBeam then endBeam.Enabled = EmitterManager.StructuredState == "End" end
			elseif kind == "Mesh" then
				for _, stateName in ipairs({"Start", "End"}) do
					local stateRoot = emitter:FindFirstChild(stateName)
					if stateRoot then
						local modifier = stateName == EmitterManager.StructuredState and 0 or 1
						if stateRoot:IsA("BasePart") then
							stateRoot.LocalTransparencyModifier = modifier
						end
						for _, descendant in ipairs(stateRoot:GetDescendants()) do
							if descendant:IsA("BasePart") then
								descendant.LocalTransparencyModifier = modifier
							end
						end
					end
				end
			end
		end
	end
end

local function configureBeamHost(host, cframe0, cframe1)
	host.Name = "Beam_StartEndVFX"
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = CFrame.new((cframe0.Position + cframe1.Position) * 0.5)
	host.Anchored = true
	host.CanCollide = false
	host.CanTouch = false
	host.CanQuery = false
	host.CastShadow = false
	host.Transparency = 1

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "Attachment0"
	attachment0.CFrame = host.CFrame:ToObjectSpace(cframe0)
	attachment0.Parent = host

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "Attachment1"
	attachment1.CFrame = host.CFrame:ToObjectSpace(cframe1)
	attachment1.Parent = host

	return attachment0, attachment1
end

local function findNamedAttachment(host, name)
	for _, child in ipairs(host:GetChildren()) do
		if child.Name == name and child:IsA("Attachment") then return child end
	end
	return nil
end

local function configureLightningOnExistingPart(host, cframe0, cframe1)
	local attachment0 = findNamedAttachment(host, "VisualX_LightningStart") or Instance.new("Attachment")
	attachment0.Name = "VisualX_LightningStart"
	attachment0.CFrame = host.CFrame:ToObjectSpace(cframe0)
	attachment0.Parent = host

	local attachment1 = findNamedAttachment(host, "VisualX_LightningEnd") or Instance.new("Attachment")
	attachment1.Name = "VisualX_LightningEnd"
	attachment1.CFrame = host.CFrame:ToObjectSpace(cframe1)
	attachment1.Parent = host

	return attachment0, attachment1
end

function EmitterManager.CreateStructuredBeam()
	local Selection = game:GetService("Selection")
	local history = game:GetService("ChangeHistoryService")
	local selected = Selection:Get()
	local template
	local attachments, parts = {}, {}

	for _, item in ipairs(selected) do
		if item:IsA("Beam") and not StructuredRuntime.Contains(item) then template = item end
		if item:IsA("Attachment") then table.insert(attachments, item) end
		if item:IsA("BasePart") then table.insert(parts, item) end
	end

	-- A selected native Beam is already the user's authored effect. Upgrade its
	-- existing host in place so appearance, attachments, and placement are kept.
	if template then
		local existingHost = template:FindFirstAncestorWhichIsA("BasePart")
		if existingHost and not isLightningEmitter(existingHost) then
			history:SetWaypoint("VisualX Add Beam Timeline - Before")
			existingHost:SetAttribute("VisualXVersion", 8)
			existingHost:SetAttribute("VisualXSingleBeam", true)
			existingHost:SetAttribute("IsEmitter", true)

			local settings = settingsObject(existingHost, true)
			local defaults = {
				Enabled = false,
				EmitCount = 1,
				EmitDelay = 0,
				LoopDelay = 0,
				Rate = 2,
				EffectDuration = 0.6,
			}
			for name, value in pairs(defaults) do
				if settings:GetAttribute(name) == nil then
					settings:SetAttribute(name, value)
				end
			end

			ensureSingleBeamTimeline(existingHost)
			applyBeamStateRaw(existingHost, "Start")
			history:SetWaypoint("VisualX Add Beam Timeline")
			Selection:Set({existingHost})
			return existingHost
		end
	end
	local cframe0, cframe1, parent
	if template and template.Attachment0 and template.Attachment1 then
		cframe0, cframe1 = template.Attachment0.WorldCFrame, template.Attachment1.WorldCFrame
		local host = template:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #attachments >= 2 then
		cframe0, cframe1 = attachments[1].WorldCFrame, attachments[2].WorldCFrame
		local host = attachments[1]:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #parts >= 2 then
		cframe0, cframe1 = parts[1].CFrame, parts[2].CFrame
		parent = parts[1].Parent
	elseif #parts == 1 then
		cframe0 = parts[1].CFrame * CFrame.new(0, 0, -3)
		cframe1 = parts[1].CFrame * CFrame.new(0, 0, 3)
		parent = parts[1].Parent
	else
		return nil, "Select a Beam, two Attachments, two Parts, or one Part."
	end
	if not parent or parent:IsA("BasePart") or parent:IsA("Attachment") then parent = workspace end

	history:SetWaypoint("VisualX Create Beam - Before")
	local container = Instance.new("Part")
	local attachment0, attachment1 = configureBeamHost(container, cframe0, cframe1)
	container.Name = (template and template.Name or "Beam") .. "_BeamVFX"
	container:SetAttribute("VisualXVersion", 7)
	container:SetAttribute("VisualXSingleBeam", true)
	container:SetAttribute("IsEmitter", true)

	local settings = settingsObject(container, true)
	settings:SetAttribute("Enabled", false)
	settings:SetAttribute("EmitCount", 1)
	settings:SetAttribute("EmitDelay", 0)
	settings:SetAttribute("LoopDelay", 0)
	settings:SetAttribute("Rate", 2)
	settings:SetAttribute("EffectDuration", 0.6)

	local beam = template and template:Clone() or Instance.new("Beam")
	beam.Name = "Beam"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Enabled = false
	beam.FaceCamera = true
	if not template then
		beam.Width0 = 0.65
		beam.Width1 = 0.25
		beam.Brightness = 4
		beam.LightEmission = 1
		beam.Color = ColorSequence.new(Color3.fromRGB(80, 210, 255))
	end
	beam.Parent = container
	ensureSingleBeamTimeline(container)
	applyBeamStateRaw(container, "Start")
	container.Parent = parent
	if template then template.Enabled = false end

	history:SetWaypoint("VisualX Create Beam")
	Selection:Set({container})
	return container
end

function EmitterManager.CreateLightningEmitter()
	local Selection = game:GetService("Selection")
	local history = game:GetService("ChangeHistoryService")
	local selected = Selection:Get()
	local templateBeam
	local attachments, parts = {}, {}

	for _, item in ipairs(selected) do
		if item:IsA("Beam") and item.Attachment0 and item.Attachment1 then templateBeam = item end
		if item:IsA("Attachment") then table.insert(attachments, item) end
		if item:IsA("BasePart") then table.insert(parts, item) end
	end

	local cframe0, cframe1, parent, selectedHost
	if templateBeam then
		cframe0, cframe1 = templateBeam.Attachment0.WorldCFrame, templateBeam.Attachment1.WorldCFrame
		local host = templateBeam:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #attachments >= 2 then
		cframe0, cframe1 = attachments[1].WorldCFrame, attachments[2].WorldCFrame
		local host = attachments[1]:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #parts >= 2 then
		cframe0, cframe1 = parts[1].CFrame, parts[2].CFrame
		parent = parts[1].Parent
	elseif #parts == 1 then
		selectedHost = parts[1]
		cframe0 = selectedHost.CFrame
		cframe1 = selectedHost.CFrame * CFrame.new(0, 0, 6)
		parent = selectedHost.Parent
	else
		return nil, "Select a Beam, two Attachments, two Parts, or one Part."
	end
	if not selectedHost and (not parent or parent:IsA("BasePart") or parent:IsA("Attachment")) then parent = workspace end

	history:SetWaypoint("VisualX Create Lightning - Before")
	EmitterManager.SyncLightningTemplate()
	local templateSettings = lightningTemplateSettings()
	local partColor = templateSettings.PartColor
	local highlightColor = templateSettings.HighlightColor
	local emitter
	if selectedHost then
		emitter = selectedHost
		configureLightningOnExistingPart(emitter, cframe0, cframe1)
	else
		emitter = Instance.new("Part")
		configureBeamHost(emitter, cframe0, cframe1)
		emitter.Name = "Lightning"
		emitter.Color = partColor
		emitter.Material = Enum.Material.Neon
	end
	emitter:SetAttribute("VisualXVersion", 7)
	emitter:SetAttribute("IsEmitter", true)
	emitter:SetAttribute("IsLightning", true)

	local settings = settingsObject(emitter, true)
	settings:SetAttribute("Enabled", false)
	settings:SetAttribute("EmitCount", 1)
	settings:SetAttribute("EmitDelay", 0)
	settings:SetAttribute("LoopDelay", 0.55)
	settings:SetAttribute("Rate", 2)
	settings:SetAttribute("LightningPartColor", partColor)
	settings:SetAttribute("LightningHighlightColor", highlightColor)
	settings:SetAttribute("LightningMode", "Single")
	settings:SetAttribute("LightningBoltCount", 5)
	settings:SetAttribute("LightningSpread", 6)
	settings:SetAttribute("LightningCurveSize0", 0)
	settings:SetAttribute("LightningCurveSize1", 0)
	settings:SetAttribute("LightningSegments", 30)
	settings:SetAttribute("LightningJitter", 2.4)
	settings:SetAttribute("LightningMinRadius", 0)
	settings:SetAttribute("LightningMaxRadius", 2.4)
	settings:SetAttribute("LightningFrequency", 1)
	settings:SetAttribute("LightningThickness", 0.18)
	settings:SetAttribute("LightningMinThicknessMultiplier", 0.2)
	settings:SetAttribute("LightningMaxThicknessMultiplier", 1)
	settings:SetAttribute("LightningGlowThickness", 0.55)
	settings:SetAttribute("LightningTransparency", 0)
	settings:SetAttribute("LightningGlowTransparency", templateSettings.HighlightTransparency)
	settings:SetAttribute("LightningLifetime", 0.6)
	settings:SetAttribute("LightningAnimationSpeed", 7)
	settings:SetAttribute("LightningRefreshRate", 60)
	settings:SetAttribute("LightningPulseSpeed", 2)
	settings:SetAttribute("LightningPulseLength", 1000000)
	settings:SetAttribute("LightningFadeLength", 0.2)
	settings:SetAttribute("LightningContractFrom", 0.5)
	settings:SetAttribute("LightningBranches", 4)
	settings:SetAttribute("LightningBranchChance", 0.26)
	settings:SetAttribute("LightningBranchLength", 4.5)
	settings:SetAttribute("LightningBranchSegments", 4)
	settings:SetAttribute("LightningFlicker", 0.16)
	if not selectedHost then emitter.Parent = parent end

	history:SetWaypoint("VisualX Create Lightning")
	Selection:Set({emitter})
	return emitter
end

-- BetterVfx preset parity: standalone Tween emitter (no selection needed).
function EmitterManager.CreateTweenEmitter(parent, propName)
	local history = game:GetService("ChangeHistoryService")
	history:SetWaypoint("VfxLab Create Tween - Before")
	parent = parent or workspace
	if parent:IsA("BasePart") then parent = parent.Parent or workspace end
	local ray = Instance.new("RayValue")
	ray.Name = propName or "Transparency"
	ray:SetAttribute("EmitDelay", 0)
	ray:SetAttribute("Duration", NumberRange.new(1, 1))
	ray:SetAttribute("ResetOnFinish", true)
	local ok, cur = pcall(function() return parent[ray.Name] end)
	if ok and cur ~= nil and typeof(cur) ~= "Instance" then
		ray:SetAttribute("_END_VALUE", cur)
	else
		ray:SetAttribute("_END_VALUE", 0)
	end
	ray.Parent = parent
	game:GetService("Selection"):Set({ ray })
	EmitterManager.UpdateEmitters({ ray })
	history:SetWaypoint("VfxLab Create Tween")
	return ray
end

-- BetterVfx preset parity: standalone shockwave emitter kinds.
function EmitterManager.CreateShockwaveEmitter(kind, parent)
	kind = string.lower(tostring(kind or "ring"))
	if kind ~= "ring" and kind ~= "line" and kind ~= "debris" then kind = "ring" end
	local history = game:GetService("ChangeHistoryService")
	history:SetWaypoint("VfxLab Create Shockwave - Before")
	parent = parent or workspace
	if parent:IsA("BasePart") or parent:IsA("Attachment") then parent = workspace end
	local host = Instance.new("Part")
	host.Name = "Shockwave" .. string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
	host.Anchored = true
	host.CanCollide = false
	host.Transparency = 1
	host.Size = Vector3.new(1, 1, 1)
	host.CFrame = workspace.CurrentCamera and (workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -10)) or CFrame.new(0, 5, 0)
	local pretty = string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
	host:SetAttribute("ShockwaveKind", pretty)
	host:SetAttribute("EmitDelay", 0)
	host:SetAttribute("Radius", 5)
	host:SetAttribute("Segments", 7)
	host:SetAttribute("Length", 50)
	host:SetAttribute("Direction", Vector3.new(0, 0, -1))
	host:SetAttribute("Amount", NumberRange.new(5, 10))
	host:SetAttribute("Lifetime", NumberRange.new(2, 3))
	host:SetAttribute("Transparency_Start", 0)
	host:SetAttribute("Transparency_End", kind == "debris" and 1 or 0)
	host:SetAttribute("MinSize", Vector3.new(2, 1, 2))
	host:SetAttribute("MaxSize", Vector3.new(3, 2, 3))
	host:SetAttribute("LinearMagnitude", NumberRange.new(15, 25))
	host:SetAttribute("AngularMagnitude", NumberRange.new(5, 15))
	host.Parent = parent
	game:GetService("Selection"):Set({ host })
	EmitterManager.UpdateEmitters({ host })
	history:SetWaypoint("VfxLab Create Shockwave")
	return host
end

function EmitterManager.UpdateEmitters(selectedInstances)
	EmitterManager.CurrentEmitters = {}
	EmitterManager.CurrentParts = {}

	if #selectedInstances == 0 then
		EmitterManager.TargetName = "None"
		return
	end

	EmitterManager.TargetName = selectedInstances[1].Name
	local emitterSeen = {}
	local partSeen = {}

	local function addEmitter(instance)
		if not emitterSeen[instance] then
			emitterSeen[instance] = true
			table.insert(EmitterManager.CurrentEmitters, instance)
		end
	end

	local function addPart(instance)
		if not partSeen[instance] then
			partSeen[instance] = true
			table.insert(EmitterManager.CurrentParts, instance)
		end
	end

	local function scan(instance)
		if isLightningEmitter(instance) or isSingleBeamEmitter(instance) then
			addEmitter(instance)
			addPart(instance)
			return
		end
		local structuredContainer = StructuredRuntime.FindContainer(instance)
		if structuredContainer then
			addEmitter(structuredContainer)
			for _, descendant in ipairs(structuredContainer:GetDescendants()) do
				if descendant:IsA("BasePart") then
					addPart(descendant)
				end
			end
			return
		end

		if instance:IsA("ParticleEmitter") then
			if instance.Name ~= "DataBank" then
				addEmitter(instance)
			end
		elseif instance:IsA("Beam") or instance:IsA("Trail") then
			addEmitter(instance)
		elseif instance:IsA("RayValue") and instance:GetAttribute("_END_VALUE") ~= nil then
			addEmitter(instance)
		elseif isLightningEmitter(instance) then
			addEmitter(instance)
		elseif isCustomEmitter(instance) then
			addEmitter(instance)
		elseif instance:GetAttribute("ShockwaveKind") ~= nil then
			addEmitter(instance)
		end

		if instance:IsA("BasePart") then
			addPart(instance)
		end

		for _, child in ipairs(instance:GetChildren()) do
			scan(child)
		end
	end

	for _, instance in ipairs(selectedInstances) do
		scan(instance)
	end
	if #EmitterManager.CurrentEmitters > 0 then
		EmitterManager.TargetName = EmitterManager.CurrentEmitters[1].Name
	end
	EmitterManager.SetStructuredState(EmitterManager.StructuredState)
end

function EmitterManager.ConvertToMeshEmitter(targetPart)
	if not targetPart:IsA("BasePart") then return end
	local parent = targetPart.Parent

	local holder = Instance.new("Model")
	holder.Name = targetPart.Name .. "_MeshVFX"
	holder:SetAttribute("IsMeshEmitter", true)

	holder:SetAttribute("EmitCount", 10)
	holder:SetAttribute("EmitDelay", 0) 
	holder:SetAttribute("LoopDelay", 0) 
	holder:SetAttribute("Rate", 20)
	holder:SetAttribute("Lifetime", NumberRange.new(1, 2))
	holder:SetAttribute("Speed", NumberRange.new(10, 15))
	holder:SetAttribute("SpreadAngle", Vector2.new(45, 45))
	holder:SetAttribute("Acceleration", Vector3.new(0, -10, 0))
	holder:SetAttribute("Drag", 0)

	holder:SetAttribute("Rotation_X", NumberRange.new(0))
	holder:SetAttribute("Rotation_Y", NumberRange.new(0))
	holder:SetAttribute("Rotation_Z", NumberRange.new(0))
	holder:SetAttribute("RotSpeed_X", NumberRange.new(0))
	holder:SetAttribute("RotSpeed_Y", NumberRange.new(0))
	holder:SetAttribute("RotSpeed_Z", NumberRange.new(0))

	holder:SetAttribute("Enabled", false)
	holder:SetAttribute("SpawnCFrame", targetPart.CFrame)

	holder:SetAttribute("Size_X", NumberSequence.new(1))
	holder:SetAttribute("Size_Y", NumberSequence.new(1))
	holder:SetAttribute("Size_Z", NumberSequence.new(1))

	holder:SetAttribute("OffsetStart", Vector3.new(0, 0, 0))
	holder:SetAttribute("OffsetEnd", Vector3.new(0, 0, 0))
	holder:SetAttribute("OffsetEasing", "Linear") 

	-- THE FIX: Highlight Default Properties
	holder:SetAttribute("HL_Enabled", false)
	holder:SetAttribute("HL_FillColor", Color3.new(1, 1, 1))
	holder:SetAttribute("HL_OutlineColor", Color3.new(1, 1, 1))
	holder:SetAttribute("HL_FillTrans", 0.5)
	holder:SetAttribute("HL_OutTrans", 0)

	local dataBank = Instance.new("ParticleEmitter")
	dataBank.Name = "DataBank"
	dataBank.Enabled = false
	dataBank.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	dataBank.Color = ColorSequence.new(Color3.new(1, 1, 1)) 
	dataBank.Parent = holder

	local template = targetPart:Clone()
	template.Name = "Template"
	template.Anchored = true
	template.CanCollide = false
	template.Transparency = 1
	template.Parent = holder

	holder.Parent = parent
	targetPart.Parent = holder
	holder.PrimaryPart = targetPart
	game:GetService("Selection"):Set({holder})
end

function EmitterManager.ConvertToStructuredMeshEmitter(targetPart)
	if not targetPart or not targetPart:IsA("BasePart") then return nil end
	local history = game:GetService("ChangeHistoryService")
	local selection = game:GetService("Selection")
	local http = game:GetService("HttpService")
	local originalParent = targetPart.Parent
	local originalName = targetPart.Name

	history:SetWaypoint("VisualX Create Start End Mesh - Before")

	-- Clean hierarchy: one holder Model with the two state parts directly inside.
	local holder = Instance.new("Model")
	holder.Name = originalName .. "_StartEndVFX"
	holder:SetAttribute("VisualXVersion", 8)
	holder:SetAttribute("IsEmitter", true)
	holder:SetAttribute("Enabled", false)
	holder:SetAttribute("EmitCount", 1)
	holder:SetAttribute("EmitDelay", 0)
	holder:SetAttribute("EffectDuration", 1)
	holder:SetAttribute("EasingStyle", "Linear")
	holder:SetAttribute("OffsetStart", Vector3.zero)
	holder:SetAttribute("OffsetEnd", Vector3.zero)
	holder:SetAttribute("DecalTransStart", 0)
	holder:SetAttribute("DecalTransEnd", 1)
	holder:SetAttribute("DecalEasing", "Linear")

	local visualId = http:GenerateGUID(false)
	targetPart.Name = "Start"
	targetPart:SetAttribute("VisualXId", visualId)
	targetPart.Anchored = true
	targetPart.CanCollide = false
	targetPart.CanTouch = false
	targetPart.CanQuery = false
	targetPart.Parent = holder

	local endPart = targetPart:Clone()
	endPart.Name = "End"
	endPart:SetAttribute("VisualXId", visualId)
	endPart.Transparency = 1
	endPart.Size = Vector3.new(
		math.max(targetPart.Size.X * 0.2, 0.05),
		math.max(targetPart.Size.Y * 0.2, 0.05),
		math.max(targetPart.Size.Z * 0.2, 0.05)
	)
	endPart.LocalTransparencyModifier = 1
	for _, descendant in ipairs(endPart:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		end
	end
	endPart.Parent = holder

	local firstStartSurface = targetPart:FindFirstChildWhichIsA("Decal", true)
		or targetPart:FindFirstChildWhichIsA("Texture", true)
	if firstStartSurface then
		holder:SetAttribute("DecalTransStart", firstStartSurface.Transparency)
	end
	targetPart.LocalTransparencyModifier = 0
	holder.PrimaryPart = targetPart
	holder.Parent = originalParent

	history:SetWaypoint("VisualX Create Start End Mesh")
	selection:Set({holder})
	return holder
end

local function setStructuredSurfaceTransparency(container, stateName, value)
	local stateRoot = container:FindFirstChild(stateName)
	if not stateRoot then return end
	local function apply(instance)
		if instance:IsA("Decal") or instance:IsA("Texture") then
			instance.Transparency = value
		end
	end
	apply(stateRoot)
	for _, descendant in ipairs(stateRoot:GetDescendants()) do
		apply(descendant)
	end
end

function EmitterManager.ApplySmartProperty(propertyName, textInput)
	local actualProp = propertyName:gsub("Mesh", "")

	for _, selectedEmitter in ipairs(EmitterManager.CurrentEmitters) do
		local applied = pcall(function()
			local emitter = EmitterManager.GetPropertyTarget(selectedEmitter, actualProp) or selectedEmitter
			if actualProp == "EmitCount" or actualProp == "EmitDelay" or actualProp == "LoopDelay"
				or actualProp == "EffectDuration" or actualProp == "Duration" then
				local settingName = actualProp == "Duration" and "EffectDuration" or actualProp
				if isLightningEmitter(selectedEmitter) and settingName == "EffectDuration" then settingName = "LightningLifetime" end
				if isLightningEmitter(selectedEmitter) or isSingleBeamEmitter(selectedEmitter) then
					EmitterManager.SetSetting(selectedEmitter, settingName, tonumber(textInput) or 0)
				else
					selectedEmitter:SetAttribute(settingName, tonumber(textInput) or 0)
				end
				return
			end

			if isLightningEmitter(selectedEmitter) then
				if actualProp == "LightningPartColor" or actualProp == "LightningHighlightColor"
					or actualProp == "Color" or actualProp == "LightningCoreColor" then
					local red, green, blue = textInput:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
					if red and green and blue then
						local color = Color3.fromRGB(tonumber(red), tonumber(green), tonumber(blue))
						local settingName = actualProp
						if actualProp == "Color" then settingName = "LightningPartColor" end
						if actualProp == "LightningCoreColor" then settingName = "LightningHighlightColor" end
						EmitterManager.SetSetting(selectedEmitter, settingName, color)
						if settingName == "LightningPartColor" then
							selectedEmitter.Color = color
							selectedEmitter.Material = Enum.Material.Neon
						end
					end
				elseif actualProp == "Enabled" then
					local lower = string.lower(tostring(textInput))
					EmitterManager.SetSetting(selectedEmitter, "Enabled", lower == "true" or lower == "on" or lower == "1")
				elseif actualProp == "LightningMode" then
					local lower = string.lower(tostring(textInput))
					local mode = lower:find("radial", 1, true) and "Radial"
						or (lower:find("spread", 1, true) and "Spread" or "Single")
					EmitterManager.SetSetting(selectedEmitter, "LightningMode", mode)
				else
					local number = tonumber(textInput)
					if number ~= nil then EmitterManager.SetSetting(selectedEmitter, actualProp, number) end
				end
				return
			end

			if isStructuredEmitter(selectedEmitter)
				and EmitterManager.GetStructuredKind(selectedEmitter) == "Mesh"
				and (actualProp == "DecalTransStart" or actualProp == "DecalTransEnd") then
				local value = math.clamp(tonumber(textInput) or 0, 0, 1)
				AttributeSchema.Write(selectedEmitter, actualProp, value)
				setStructuredSurfaceTransparency(
					selectedEmitter,
					actualProp == "DecalTransStart" and "Start" or "End",
					value
				)
				return
			end

			if isStructuredEmitter(selectedEmitter)
				and EmitterManager.GetStructuredKind(selectedEmitter) == "Mesh"
				and emitter ~= selectedEmitter then
				if actualProp == "Size_X" or actualProp == "Size_Y" or actualProp == "Size_Z" then
					local axis = actualProp:sub(-1)
					local size = emitter.Size
					local value = math.max(tonumber(textInput) or size[axis], 0.01)
					emitter.Size = Vector3.new(axis == "X" and value or size.X, axis == "Y" and value or size.Y, axis == "Z" and value or size.Z)
				elseif actualProp == "Size" then
					local x, y, z = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
					if x and y and z then emitter.Size = Vector3.new(math.max(tonumber(x), 0.01), math.max(tonumber(y), 0.01), math.max(tonumber(z), 0.01)) end
				elseif actualProp == "Color" then
					local red, green, blue = textInput:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
					if red and green and blue then emitter.Color = Color3.fromRGB(tonumber(red), tonumber(green), tonumber(blue)) end
				elseif actualProp == "Transparency" then
					emitter.Transparency = math.clamp(tonumber(textInput) or emitter.Transparency, 0, 1)
				elseif actualProp == "Material" then
					local requested = string.lower(textInput:gsub("%s.*", ""))
					for _, material in ipairs(Enum.Material:GetEnumItems()) do
						if string.lower(material.Name) == requested then emitter.Material = material; break end
					end
				elseif actualProp == "Texture" then
					local texture = tonumber(textInput) and ("rbxassetid://" .. textInput) or textInput
					if emitter:IsA("MeshPart") then
						emitter.TextureID = texture
					else
						local mesh = emitter:FindFirstChildWhichIsA("SpecialMesh")
						if mesh then mesh.TextureId = texture end
					end
				end
				return
			end
		-- THE FIX: Parses Highlight Toggles instantly!
		if actualProp == "HL_Enabled" then
			emitter:SetAttribute(actualProp, string.lower(textInput) == "true")
			return
		end

		-- ShockwaveKind: string attribute on any emitter (None clears it).
		if actualProp == "ShockwaveKind" then
			local lower = string.lower(tostring(textInput))
			if lower == "none" or lower == "" or lower == "off" then
				emitter:SetAttribute(actualProp, nil)
			elseif lower:find("ring", 1, true) then
				emitter:SetAttribute(actualProp, "Ring")
			elseif lower:find("line", 1, true) then
				emitter:SetAttribute(actualProp, "Line")
			elseif lower:find("debris", 1, true) then
				emitter:SetAttribute(actualProp, "Debris")
			end
			return
		end

		-- TweenProperty emitters (RayValue): Duration range + reset flag.
		if selectedEmitter:IsA("RayValue") then
			if actualProp == "EmitDelay" then
				selectedEmitter:SetAttribute("EmitDelay", tonumber(textInput) or 0)
			elseif actualProp == "Duration" then
				local a, b = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)")
				if a and b then
					selectedEmitter:SetAttribute("Duration", NumberRange.new(tonumber(a), tonumber(b)))
				else
					local n = tonumber(textInput) or 1
					selectedEmitter:SetAttribute("Duration", NumberRange.new(n, n))
				end
			elseif actualProp == "ResetOnFinish" then
				local lower = string.lower(tostring(textInput))
				selectedEmitter:SetAttribute("ResetOnFinish", lower == "true" or lower == "on" or lower == "1")
			elseif actualProp == "Property" and selectedEmitter.Parent then
				local parent = selectedEmitter.Parent
				local ok, cur = pcall(function() return parent[textInput] end)
				if ok and cur ~= nil and typeof(cur) ~= "Instance" then
					selectedEmitter.Name = textInput
					selectedEmitter:SetAttribute("_END_VALUE", cur)
				end
			end
			return
		end

			if actualProp == "Orientation" then
				local txt = string.lower(textInput)
				local orient = Enum.ParticleOrientation.FacingCamera
				if txt:find("world") or txt:find("up") then orient = Enum.ParticleOrientation.FacingCameraWorldUp
				elseif txt:find("parallel") then orient = Enum.ParticleOrientation.VelocityParallel
				elseif txt:find("perp") then orient = Enum.ParticleOrientation.VelocityPerpendicular
				end
				if not isCustomEmitter(emitter) then emitter.Orientation = orient end
				return
			elseif actualProp == "Color" then
				local r,g,b = textInput:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
				if r and g and b then
					local newColor = ColorSequence.new(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
					if isCustomEmitter(emitter) then emitter.DataBank.Color = newColor
					else emitter.Color = newColor end
				end
				return
			elseif actualProp == "Material" then
				local txt = string.lower(textInput)
				local m = Enum.Material.Plastic
				if txt:find("neon") then m = Enum.Material.Neon
				elseif txt:find("glass") then m = Enum.Material.Glass
				elseif txt:find("metal") then m = Enum.Material.Metal
				elseif txt:find("wood") then m = Enum.Material.Wood
				elseif txt:find("force") then m = Enum.Material.ForceField
				end
				for _, part in ipairs(EmitterManager.CurrentParts) do part.Material = m end
				return
			end

			if isStructuredEmitter(emitter) then
				local currentVal = AttributeSchema.Read(emitter, actualProp, false)
				local val1, val2 = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)")
				local lower = string.lower(textInput)
				if typeof(currentVal) == "boolean" then
					AttributeSchema.Write(emitter, actualProp, lower == "true" or lower == "on" or lower == "1")
				elseif typeof(currentVal) == "NumberRange" then
					if val1 and val2 then
						AttributeSchema.Write(emitter, actualProp, NumberRange.new(tonumber(val1), tonumber(val2)))
					else
						AttributeSchema.Write(emitter, actualProp, NumberRange.new(tonumber(textInput) or 0))
					end
				elseif typeof(currentVal) == "Vector2" then
					AttributeSchema.Write(emitter, actualProp, Vector2.new(tonumber(val1) or 0, tonumber(val2) or tonumber(val1) or 0))
				elseif typeof(currentVal) == "Vector3" then
					local x, y, z = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
					if x and y and z then
						AttributeSchema.Write(emitter, actualProp, Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
					end
				elseif typeof(currentVal) == "Color3" then
					local red, green, blue = textInput:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
					if red and green and blue then
						AttributeSchema.Write(emitter, actualProp, Color3.fromRGB(tonumber(red), tonumber(green), tonumber(blue)))
					end
				elseif type(currentVal) == "number" then
					AttributeSchema.Write(emitter, actualProp, tonumber(textInput) or currentVal)
				elseif type(currentVal) == "string" or currentVal == nil then
					AttributeSchema.Write(emitter, actualProp, tonumber(textInput) or textInput)
				end
				return
			end

			if isCustomEmitter(emitter) then
				local currentVal = emitter:GetAttribute(actualProp)
				local val1, val2 = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)")

				if actualProp:match("Rotation_[XYZ]") or actualProp:match("RotSpeed_[XYZ]") then
					if val1 and val2 then emitter:SetAttribute(actualProp, NumberRange.new(tonumber(val1), tonumber(val2)))
					else emitter:SetAttribute(actualProp, NumberRange.new(tonumber(textInput) or 0)) end
					return
				end

				if actualProp == "ColorStart" or actualProp == "ColorEnd" or actualProp == "HL_FillColor" or actualProp == "HL_OutlineColor" then
					local r,g,b = textInput:match("([%d]+)%s*,%s*([%d]+)%s*,%s*([%d]+)")
					if r and g and b then emitter:SetAttribute(actualProp, Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))) end
					return
				elseif actualProp == "OffsetEasing" then
					emitter:SetAttribute(actualProp, textInput)
					return
				elseif actualProp == "OffsetStart" or actualProp == "OffsetEnd" or actualProp == "Acceleration"
				or actualProp == "Direction" or actualProp == "MinSize" or actualProp == "MaxSize" then
					local x,y,z = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
					if x and y and z then
						emitter:SetAttribute(actualProp, Vector3.new(tonumber(x), tonumber(y), tonumber(z)))
					elseif tonumber(textInput) then
						local n = tonumber(textInput)
						emitter:SetAttribute(actualProp, Vector3.new(n,n,n))
					end
					return
				elseif actualProp == "Size_X" or actualProp == "Size_Y" or actualProp == "Size_Z" then
					local n = tonumber(textInput)
					-- [FIX] Save as a standard number because Attributes reject NumberSequences
					if n then emitter:SetAttribute(actualProp, n) end
					return
				elseif actualProp == "Transparency" then
					emitter.DataBank[actualProp] = NumberSequence.new(tonumber(textInput) or 1)
					return
				elseif typeof(currentVal) == "NumberRange" then
					if val1 and val2 then emitter:SetAttribute(actualProp, NumberRange.new(tonumber(val1), tonumber(val2)))
					else emitter:SetAttribute(actualProp, NumberRange.new(tonumber(textInput) or 0)) end
					return
				elseif typeof(currentVal) == "Vector2" then
					if val1 and val2 then emitter:SetAttribute(actualProp, Vector2.new(tonumber(val1), tonumber(val2)))
					else emitter:SetAttribute(actualProp, Vector2.new(tonumber(textInput) or 0, tonumber(textInput) or 0)) end
					return
				else
					emitter:SetAttribute(actualProp, tonumber(textInput) or currentVal)
					return
				end
			end

			if emitter:IsA("Trail") and string.sub(actualProp, 1, 9) == "TrailPath" then
				if actualProp == "TrailPathPreset" then
					applyTrailPathPreset(emitter, tostring(textInput))
				elseif actualProp == "TrailPathMode" then
					local lower = string.lower(tostring(textInput))
					local mode = lower:find("bezier", 1, true) and "Bezier Orbit"
						or (lower:find("spiral", 1, true) and "Spiral"
						or (lower:find("radial", 1, true) and (lower:find("in", 1, true) and "Radial In" or "Radial Out") or "Static"))
					emitter:SetAttribute(actualProp, mode)
					if mode == "Bezier Orbit" then ensureBezierTrailDefaults(emitter) end
				elseif actualProp == "TrailPathCurve" then
					emitter:SetAttribute(actualProp, tostring(textInput))
				elseif actualProp == "TrailPathRandomRotation" or actualProp == "TrailPathFaceMotion"
					or actualProp == "TrailPathReverse" or actualProp == "TrailPathPingPong" then
					local lower = string.lower(tostring(textInput))
					emitter:SetAttribute(actualProp, lower == "true" or lower == "on" or lower == "1")
				elseif actualProp == "TrailPathOffsetStart" or actualProp == "TrailPathOffsetEnd"
					or actualProp == "TrailPathControl1" or actualProp == "TrailPathControl2"
					or actualProp == "TrailPathWobble" or actualProp == "TrailPathWobbleSpeed"
					or actualProp == "TrailPathRotationStart" or actualProp == "TrailPathRotationEnd"
					or actualProp == "TrailPathRotationSpread" or actualProp == "TrailPathRotationSpeed"
					or actualProp == "TrailPathOrientationOffset" then
					local x,y,z = tostring(textInput):match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
					if x and y and z then emitter:SetAttribute(actualProp, Vector3.new(tonumber(x), tonumber(y), tonumber(z))) end
				else
					local number = tonumber(textInput)
					if number ~= nil then emitter:SetAttribute(actualProp, number) end
				end
				return
			end

			if actualProp == "Texture" then
				if tonumber(textInput) then emitter.Texture = "rbxassetid://" .. textInput
				else emitter.Texture = textInput end
				return
			elseif actualProp == "TextureMode" then
				local modeName = string.lower(textInput:gsub("%s.*", ""))
				if modeName == "wrap" then emitter.TextureMode = Enum.TextureMode.Wrap
				elseif modeName == "static" then emitter.TextureMode = Enum.TextureMode.Static
				else emitter.TextureMode = Enum.TextureMode.Stretch end
				return
			end

			local currentVal = emitter[actualProp]
			local val1, val2 = textInput:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)")

			if typeof(currentVal) == "boolean" then
				local lower = string.lower(textInput)
				emitter[actualProp] = lower == "true" or lower == "on" or lower == "1"
			elseif typeof(currentVal) == "NumberRange" then
				if val1 and val2 then emitter[actualProp] = NumberRange.new(tonumber(val1), tonumber(val2))
				else emitter[actualProp] = NumberRange.new(tonumber(textInput) or 0) end
			elseif typeof(currentVal) == "NumberSequence" and tonumber(textInput) then
				emitter[actualProp] = NumberSequence.new(tonumber(textInput))
			elseif typeof(currentVal) == "Vector2" then
				if val1 and val2 then emitter[actualProp] = Vector2.new(tonumber(val1), tonumber(val2))
				else emitter[actualProp] = Vector2.new(tonumber(textInput) or 0, tonumber(textInput) or 0) end
			else
				emitter[actualProp] = tonumber(textInput) or currentVal
			end
		end)
		if applied and isSingleBeamEmitter(selectedEmitter) then
			captureBeamStateRaw(selectedEmitter, EmitterManager.StructuredState)
		end
	end
end

function EmitterManager.ToggleEnabled()
	if #EmitterManager.CurrentEmitters == 0 then return false end

	local first = EmitterManager.CurrentEmitters[1]
	local targetState
	if isCustomEmitter(first) or isStructuredEmitter(first) or isLightningEmitter(first) or isSingleBeamEmitter(first) then targetState = not (EmitterManager.GetSetting(first, "Enabled", false) == true)
	else targetState = not first.Enabled end

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		if isLightningEmitter(emitter) or isSingleBeamEmitter(emitter) then EmitterManager.SetSetting(emitter, "Enabled", targetState)
		elseif isCustomEmitter(emitter) or isStructuredEmitter(emitter) then emitter:SetAttribute("Enabled", targetState)
		else emitter.Enabled = targetState end
	end

	if targetState == false then
		local cache = workspace:FindFirstChild("VfxLab_Preview_Cache")
		if cache then cache:ClearAllChildren() end
	end

	return targetState
end

function EmitterManager.IsEnabled(emitter)
	if not emitter then return false end
	if isCustomEmitter(emitter) or isStructuredEmitter(emitter) then
		return emitter:GetAttribute("Enabled") == true
	end
	if isLightningEmitter(emitter) or isSingleBeamEmitter(emitter) then
		return EmitterManager.GetSetting(emitter, "Enabled", false) == true
	end
	local ok, enabled = pcall(function() return emitter.Enabled end)
	return ok and enabled == true
end

function EmitterManager.GenerateDebris(debrisType, countStr, powerStr, sizeStr)
	local target = game:GetService("Selection"):Get()[1]
	if not target or (not target:IsA("Model") and not target:IsA("Folder")) then
		warn("VFX Editor: Please select a Model or Folder to spawn the debris inside!")
		return
	end

	local count = tonumber(countStr) or 15
	local power = tonumber(powerStr) or 25
	local baseSize = tonumber(sizeStr) or 1.5

	local centerPos = target:IsA("Model") and target.PrimaryPart and target.PrimaryPart.Position or Vector3.zero
	if centerPos == Vector3.zero then
		for _, d in ipairs(target:GetDescendants()) do if d:IsA("BasePart") then centerPos = d.Position break end end
	end

	local rayOrigin = centerPos + Vector3.new(0, 10, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {target} 
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ray = workspace:Raycast(rayOrigin, Vector3.new(0, -500, 0), rayParams)
	local groundColor = Color3.new(0.5, 0.5, 0.5)
	local groundMat = Enum.Material.Slate

	if ray and ray.Instance then
		groundColor = ray.Instance.Color
		groundMat = ray.Instance.Material
	end

	if debrisType == "Flying" then
		local holder = Instance.new("Model")
		holder.Name = "FlyingRocks_MeshVFX"
		holder:SetAttribute("IsMeshEmitter", true)

		holder:SetAttribute("EmitCount", count)
		holder:SetAttribute("EmitDelay", 0) 
		holder:SetAttribute("Lifetime", NumberRange.new(1.5, 2.5))
		holder:SetAttribute("Speed", NumberRange.new(power * 0.8, power * 1.5))
		holder:SetAttribute("SpreadAngle", Vector2.new(60, 360)) 
		holder:SetAttribute("Acceleration", Vector3.new(0, -workspace.Gravity * 1.2, 0))
		holder:SetAttribute("Drag", 0.5)

		holder:SetAttribute("Rotation_X", NumberRange.new(-180, 180))
		holder:SetAttribute("Rotation_Y", NumberRange.new(-180, 180))
		holder:SetAttribute("Rotation_Z", NumberRange.new(-180, 180))
		holder:SetAttribute("RotSpeed_X", NumberRange.new(-360, 360))
		holder:SetAttribute("RotSpeed_Y", NumberRange.new(-360, 360))
		holder:SetAttribute("RotSpeed_Z", NumberRange.new(-360, 360))

		local shrinkSeq = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 0)})
		holder:SetAttribute("Size_X", shrinkSeq)
		holder:SetAttribute("Size_Y", shrinkSeq)
		holder:SetAttribute("Size_Z", shrinkSeq)
		holder:SetAttribute("OffsetStart", Vector3.new(0, 0, 0))
		holder:SetAttribute("OffsetEnd", Vector3.new(0, 0, 0))
		holder:SetAttribute("OffsetEasing", "Linear") 
		holder:SetAttribute("Enabled", false)

		-- Give Flying rocks a subtle dark highlight by default to match Anime style
		holder:SetAttribute("HL_Enabled", true)
		holder:SetAttribute("HL_FillColor", groundColor)
		holder:SetAttribute("HL_OutlineColor", Color3.new(0.1, 0.1, 0.1))
		holder:SetAttribute("HL_FillTrans", 1)
		holder:SetAttribute("HL_OutTrans", 0.2)

		local template = Instance.new("Part")
		template.Name = "Template"
		template.Shape = Enum.PartType.Block
		template.Size = Vector3.new(baseSize, baseSize, baseSize)
		template.Color = groundColor
		template.Material = groundMat
		template.Anchored = true
		template.CanCollide = false
		template.Parent = holder

		holder.Parent = target

	elseif debrisType == "Surrounding" then
		local holder = Instance.new("Model")
		holder.Name = "Crater_Debris"
		holder:SetAttribute("IsCraterDebris", true)
		holder:SetAttribute("EmitCount", count)
		holder:SetAttribute("EmitDelay", 0)
		holder:SetAttribute("CraterRadius", power)
		holder:SetAttribute("RockSize", baseSize)

		-- Default outline for the crater too
		holder:SetAttribute("HL_Enabled", true)
		holder:SetAttribute("HL_FillColor", groundColor)
		holder:SetAttribute("HL_OutlineColor", Color3.new(0.1, 0.1, 0.1))
		holder:SetAttribute("HL_FillTrans", 1)
		holder:SetAttribute("HL_OutTrans", 0.2)

		local template = Instance.new("WedgePart") 
		template.Name = "Template"
		template.Size = Vector3.new(baseSize, baseSize, baseSize)
		template.Color = groundColor
		template.Material = groundMat
		template.Anchored = true
		template.CanCollide = false
		template.Parent = holder

		holder.Parent = target
	end
end

EmitterManager.Clipboard = {}

local function readCopyValue(source, property)
	if isStructuredEmitter(source) then
		return AttributeSchema.Read(source, property, false)
	end
	if isCustomEmitter(source) then
		if property == "Color" or property == "Transparency" or property == "Size" then
			local dataBank = source:FindFirstChild("DataBank")
			if not dataBank then return nil end
			local node = dataBank:FindFirstChild(property)
			if node and node:IsA("ValueBase") then return node.Value end
			return dataBank[property]
		end
		return source:GetAttribute(property)
	end
	if property == "EmitCount" or property == "EmitDelay" or property == "LoopDelay" or string.sub(property, 1, 9) == "TrailPath" then
		return source:GetAttribute(property)
	end
	return source[property]
end

local function writeCopyValue(target, property, value)
	if isStructuredEmitter(target) then
		local definition = AttributeSchema.GetDefinition(property)
		if definition then
			AttributeSchema.Write(target, property, value)
		end
		return
	end
	if isCustomEmitter(target) then
		if property == "Color" or property == "Transparency" or property == "Size" then
			local dataBank = target:FindFirstChild("DataBank")
			if not dataBank then return end
			local node = dataBank:FindFirstChild(property)
			if node and node:IsA("ValueBase") then
				node.Value = value
			else
				dataBank[property] = value
			end
		else
			target:SetAttribute(property, value)
		end
		return
	end
	if property == "EmitCount" or property == "EmitDelay" or property == "LoopDelay" or string.sub(property, 1, 9) == "TrailPath" then
		target:SetAttribute(property, value)
	else
		target[property] = value
	end
end

function EmitterManager.CopyProps(propsDict)
	if #EmitterManager.CurrentEmitters == 0 then return false end
	local source = EmitterManager.CurrentEmitters[1]
	EmitterManager.Clipboard = {}

	for property, selected in pairs(propsDict) do
		if selected then
			local ok, value = pcall(readCopyValue, source, property)
			if ok and value ~= nil then
				EmitterManager.Clipboard[property] = value
			end
		end
	end
	return next(EmitterManager.Clipboard) ~= nil
end

function EmitterManager.PasteProps(propsDict)
	if #EmitterManager.CurrentEmitters == 0 then return false end
	local history = game:GetService("ChangeHistoryService")
	history:SetWaypoint("VisualX Paste Before")
	local applied = false

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		for property, selected in pairs(propsDict) do
			local value = EmitterManager.Clipboard[property]
			if selected and value ~= nil then
				local ok = pcall(writeCopyValue, emitter, property, value)
				applied = applied or ok
			end
		end
	end

	if applied then
		history:SetWaypoint("VisualX Paste")
	end
	local okPanel, PropsPanel = pcall(require, script.Parent.PropertiesPanel)
	if okPanel and PropsPanel and type(PropsPanel.UpdateUI) == "function" then
		pcall(PropsPanel.UpdateUI)
	end
	return applied
end

-- === MATH HELPERS ===
local function scaleNumberSequence(seq, mult)
	local newKPs = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(newKPs, NumberSequenceKeypoint.new(kp.Time, math.clamp(kp.Value * mult, 0, 10000), math.clamp(kp.Envelope * mult, 0, 10000)))
	end
	return NumberSequence.new(newKPs)
end

local function scaleNumberRange(nr, mult)
	return NumberRange.new(nr.Min * mult, nr.Max * mult)
end

local function scaleValue(value, multiplier)
	local kind = typeof(value)
	if kind == "number" then
		return value * multiplier
	elseif kind == "Vector2" or kind == "Vector3" then
		return value * multiplier
	elseif kind == "NumberRange" then
		return scaleNumberRange(value, multiplier)
	elseif kind == "NumberSequence" then
		return scaleNumberSequence(value, multiplier)
	end
	return value
end

local function scaleAttribute(instance, name, multiplier)
	local value = instance:GetAttribute(name)
	if value ~= nil then
		instance:SetAttribute(name, scaleValue(value, multiplier))
	end
end

local function treeItems(root)
	local items = {root}
	for _, descendant in ipairs(root:GetDescendants()) do
		table.insert(items, descendant)
	end
	return items
end

local function resizeStructuredTree(root, pivot, multiplier)
	for _, instance in ipairs(treeItems(root)) do
		if instance:IsA("BasePart") then
			local relative = pivot:ToObjectSpace(instance.CFrame)
			local rotation = relative - relative.Position
			instance.CFrame = pivot * CFrame.new(relative.Position * multiplier) * rotation
			if not instance:FindFirstChildWhichIsA("DataModelMesh") then
				instance.Size *= multiplier
			end
		elseif instance:IsA("DataModelMesh") then
			instance.Scale *= multiplier
			instance.Offset *= multiplier
		elseif instance:IsA("Attachment") then
			instance.Position *= multiplier
		elseif instance:IsA("Beam") then
			instance.Width0 *= multiplier
			instance.Width1 *= multiplier
			instance.CurveSize0 *= multiplier
			instance.CurveSize1 *= multiplier
			instance.TextureLength *= multiplier
			instance.ZOffset *= multiplier
		elseif instance:IsA("Trail") then
			instance.WidthScale = scaleNumberSequence(instance.WidthScale, multiplier)
			instance.MinLength *= multiplier
			instance.TextureLength *= multiplier
		elseif instance:IsA("Light") then
			instance.Range *= multiplier
		end
	end
end

local function retimeNative(instance, multiplier)
	if instance:IsA("ParticleEmitter") then
		instance.Lifetime = scaleNumberRange(instance.Lifetime, 1 / multiplier)
		instance.Speed = scaleNumberRange(instance.Speed, multiplier)
		instance.Acceleration *= multiplier * multiplier
		instance.Rate *= multiplier
		instance.RotSpeed = scaleNumberRange(instance.RotSpeed, multiplier)
		instance.TimeScale *= multiplier
	elseif instance:IsA("Beam") then
		instance.TextureSpeed *= multiplier
	elseif instance:IsA("Trail") then
		instance.Lifetime /= multiplier
	elseif instance:IsA("Sound") then
		instance.PlaybackSpeed *= multiplier
	end
end

function EmitterManager.ResizeVFX(multiplier, noHistory)
	multiplier = tonumber(multiplier)
	if not multiplier or multiplier <= 0 or #EmitterManager.CurrentEmitters == 0 then return false end
	local history = game:GetService("ChangeHistoryService")
	if not noHistory then history:SetWaypoint("VisualX Resize Before") end

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		pcall(function()
			if isStructuredEmitter(emitter) then
				AttributeSchema.ApplyBehavior(emitter, "Resize", multiplier)
				local startRoot = emitter:FindFirstChild("Start")
				local endRoot = emitter:FindFirstChild("End")
				local pivot = StructuredRuntime.GetSourcePivot(emitter)
				if startRoot then resizeStructuredTree(startRoot, pivot, multiplier) end
				if endRoot then resizeStructuredTree(endRoot, pivot, multiplier) end
			elseif isCustomEmitter(emitter) then
				AttributeSchema.ApplyBehavior(emitter, "Resize", multiplier)
				local dataBank = emitter:FindFirstChild("DataBank")
				if dataBank then
					dataBank.Size = scaleNumberSequence(dataBank.Size, multiplier)
				end
			elseif emitter:IsA("ParticleEmitter") then
				emitter.Size = scaleNumberSequence(emitter.Size, multiplier)
				emitter.Speed = scaleNumberRange(emitter.Speed, multiplier)
				emitter.Acceleration *= multiplier
				emitter.ZOffset *= multiplier
			elseif emitter:IsA("Beam") then
				emitter.Width0 *= multiplier
				emitter.Width1 *= multiplier
				emitter.CurveSize0 *= multiplier
				emitter.CurveSize1 *= multiplier
				emitter.TextureLength *= multiplier
				emitter.ZOffset *= multiplier
			elseif emitter:IsA("Trail") then
				emitter.WidthScale = scaleNumberSequence(emitter.WidthScale, multiplier)
				emitter.MinLength *= multiplier
				emitter.TextureLength *= multiplier
				scaleAttribute(emitter, "TrailPathRadius", multiplier)
				scaleAttribute(emitter, "TrailPathHeight", multiplier)
				for _, name in ipairs({
					"TrailPathOffsetStart", "TrailPathOffsetEnd", "TrailPathControl1", "TrailPathControl2", "TrailPathWobble",
				}) do
					scaleAttribute(emitter, name, multiplier)
				end
			end
		end)
	end

	history:SetWaypoint("VisualX Resize")
	return true
end

function EmitterManager.RetimeVFX(multiplier, noHistory)
	multiplier = tonumber(multiplier)
	if not multiplier or multiplier <= 0 or #EmitterManager.CurrentEmitters == 0 then return false end
	local history = game:GetService("ChangeHistoryService")
	if not noHistory then history:SetWaypoint("VisualX Retime Before") end

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		pcall(function()
			if isStructuredEmitter(emitter) then
				AttributeSchema.ApplyBehavior(emitter, "Retime", multiplier)
				scaleAttribute(emitter, "Speed", multiplier)
				scaleAttribute(emitter, "Speed_Start", multiplier)
				scaleAttribute(emitter, "Speed_End", multiplier)
				scaleAttribute(emitter, "Acceleration", multiplier * multiplier)
				for _, axis in ipairs({"X", "Y", "Z"}) do
					scaleAttribute(emitter, "RotSpeed_" .. axis, multiplier)
				end
				for _, instance in ipairs(treeItems(emitter.Start)) do retimeNative(instance, multiplier) end
				for _, instance in ipairs(treeItems(emitter.End)) do retimeNative(instance, multiplier) end
			elseif isCustomEmitter(emitter) then
				AttributeSchema.ApplyBehavior(emitter, "Retime", multiplier)
				scaleAttribute(emitter, "Speed", multiplier)
				scaleAttribute(emitter, "Acceleration", multiplier * multiplier)
				for _, axis in ipairs({"X", "Y", "Z"}) do
					scaleAttribute(emitter, "RotSpeed_" .. axis, multiplier)
				end
			else
				retimeNative(emitter, multiplier)
				if emitter:IsA("Trail") then
					scaleAttribute(emitter, "TrailPathDuration", 1 / multiplier)
					scaleAttribute(emitter, "TrailPathDurationJitter", 1 / multiplier)
					scaleAttribute(emitter, "TrailPathStagger", 1 / multiplier)
					scaleAttribute(emitter, "TrailPathRotationSpeed", multiplier)
					scaleAttribute(emitter, "TrailPathWobbleSpeed", multiplier)
				end
			end
		end)
	end

	history:SetWaypoint("VisualX Retime")
	return true
end

-- Live preview entry points (no undo waypoints; commit via ResizeVFX/RetimeVFX).
function EmitterManager.PreviewResize(multiplier)
	return EmitterManager.ResizeVFX(multiplier, true)
end

function EmitterManager.PreviewRetime(multiplier)
	return EmitterManager.RetimeVFX(multiplier, true)
end

local function shiftedColor(color, config)
	if config.Mode == "Replace" and typeof(config.Color) == "Color3" then
		return config.Color
	end
	local hue, saturation, value = color:ToHSV()
	hue = (hue + (tonumber(config.Hue) or 0) / 360) % 1
	saturation = math.clamp(saturation + (tonumber(config.Saturation) or 0), 0, 1)
	value = math.clamp(value + (tonumber(config.Brightness) or 0), 0, 1)
	return Color3.fromHSV(hue, saturation, value)
end

local function shiftedSequence(sequence, config)
	local points = {}
	for _, point in ipairs(sequence.Keypoints) do
		table.insert(points, ColorSequenceKeypoint.new(point.Time, shiftedColor(point.Value, config)))
	end
	return ColorSequence.new(points)
end

local function visualObjects(emitter)
	local result = {emitter}
	for _, descendant in ipairs(emitter:GetDescendants()) do
		if descendant.Name ~= "DataBank" then
			table.insert(result, descendant)
		end
	end
	return result
end

local function applyRecolor(instance, config)
	if instance:IsA("BasePart") then
		instance.Color = shiftedColor(instance.Color, config)
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Color3 = shiftedColor(instance.Color3, config)
	elseif instance:IsA("Light") then
		instance.Color = shiftedColor(instance.Color, config)
	elseif instance:IsA("Highlight") then
		instance.FillColor = shiftedColor(instance.FillColor, config)
		instance.OutlineColor = shiftedColor(instance.OutlineColor, config)
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
		instance.Color = shiftedSequence(instance.Color, config)
	end
end

function EmitterManager.RecolorVFX(config, suppressWaypoint)
	config = config or {}
	if #EmitterManager.CurrentEmitters == 0 then return false end
	local history = game:GetService("ChangeHistoryService")
	if not suppressWaypoint then history:SetWaypoint("VisualX Recolor Before") end

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		if isCustomEmitter(emitter) then
			local dataBank = emitter:FindFirstChild("DataBank")
			if dataBank then
				dataBank.Color = shiftedSequence(dataBank.Color, config)
			end
		end
		for _, instance in ipairs(visualObjects(emitter)) do
			pcall(applyRecolor, instance, config)
		end
	end

	if not suppressWaypoint then history:SetWaypoint("VisualX Recolor") end
	return true
end

function EmitterManager.ShiftVFX(config)
	config = config or {}
	if #EmitterManager.CurrentEmitters == 0 then return false end
	local history = game:GetService("ChangeHistoryService")
	history:SetWaypoint("VisualX Shift Before")

	local sizeFactor = tonumber(config.SizeFactor) or 1
	if sizeFactor ~= 1 then
		EmitterManager.ResizeVFX(sizeFactor)
	end

	local lifetimeFactor = tonumber(config.LifetimeFactor) or 1
	local speedFactor = tonumber(config.SpeedFactor) or 1
	local lightDelta = tonumber(config.LightEmission) or 0

	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		pcall(function()
			if isStructuredEmitter(emitter) or isCustomEmitter(emitter) then
				local lifetime, lifetimeName = AttributeSchema.Read(emitter, "Lifetime", false)
				if lifetime ~= nil and lifetimeFactor ~= 1 then
					emitter:SetAttribute(lifetimeName, scaleValue(lifetime, lifetimeFactor))
				end
				if speedFactor ~= 1 then
					scaleAttribute(emitter, "Speed", speedFactor)
					scaleAttribute(emitter, "Speed_Start", speedFactor)
					scaleAttribute(emitter, "Speed_End", speedFactor)
				end
			elseif emitter:IsA("ParticleEmitter") then
				emitter.Lifetime = scaleNumberRange(emitter.Lifetime, lifetimeFactor)
				emitter.Speed = scaleNumberRange(emitter.Speed, speedFactor)
			elseif emitter:IsA("Trail") then
				emitter.Lifetime *= lifetimeFactor
			end
		end)

		for _, instance in ipairs(visualObjects(emitter)) do
			pcall(function()
				if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
					instance.LightEmission = math.clamp(instance.LightEmission + lightDelta, 0, 1)
				elseif instance:IsA("Light") then
					instance.Brightness = math.max(0, instance.Brightness + lightDelta)
				end
			end)
		end
	end

	if config.Hue or config.Saturation or config.Brightness or config.Color then
		EmitterManager.RecolorVFX(config, true)
	end

	history:SetWaypoint("VisualX Shift")
	return true
end

-- BetterVfx PropertyShifter parity: apply an arithmetic op to one numeric
-- prop across the selection. op is "mul" | "add" | "sub" | "div".
function EmitterManager.ShiftNumeric(propName, op, amount)
	amount = tonumber(amount)
	if not amount or #EmitterManager.CurrentEmitters == 0 then return false end
	if op == "div" and amount == 0 then return false end
	local function apply(x)
		if op == "mul" then return x * amount
		elseif op == "add" then return x + amount
		elseif op == "sub" then return x - amount
		else return x / amount end
	end
	local function shiftColor(c)
		return Color3.new(
			math.clamp(apply(c.R * 255) / 255, 0, 1),
			math.clamp(apply(c.G * 255) / 255, 0, 1),
			math.clamp(apply(c.B * 255) / 255, 0, 1))
	end
	local function shiftValue(v)
		local kind = typeof(v)
		if kind == "number" then
			return apply(v)
		elseif kind == "Vector2" then
			return Vector2.new(apply(v.X), apply(v.Y))
		elseif kind == "Vector3" then
			return Vector3.new(apply(v.X), apply(v.Y), apply(v.Z))
		elseif kind == "NumberRange" then
			return NumberRange.new(apply(v.Min), apply(v.Max))
		elseif kind == "NumberSequence" then
			local kps = {}
			for _, kp in ipairs(v.Keypoints) do
				table.insert(kps, NumberSequenceKeypoint.new(kp.Time, apply(kp.Value), apply(kp.Envelope)))
			end
			return NumberSequence.new(kps)
		elseif kind == "Color3" then
			return shiftColor(v)
		elseif kind == "ColorSequence" then
			local kps = {}
			for _, kp in ipairs(v.Keypoints) do
				table.insert(kps, ColorSequenceKeypoint.new(kp.Time, shiftColor(kp.Value)))
			end
			return ColorSequence.new(kps)
		end
		return nil
	end
	local history = game:GetService("ChangeHistoryService")
	history:SetWaypoint("VfxLab Shift Before")
	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		pcall(function()
			local target = EmitterManager.GetPropertyTarget(emitter, propName) or emitter
			local okNative, cur = pcall(function() return target[propName] end)
			if okNative and shiftValue(cur) ~= nil then
				target[propName] = shiftValue(cur)
				return
			end
			local curAttr = target:GetAttribute(propName)
			local shifted = shiftValue(curAttr)
			if shifted ~= nil then
				target:SetAttribute(propName, shifted)
			end
		end)
	end
	history:SetWaypoint("VfxLab Shift")
	return true
end

-- VfxLab addition: the reference has no trail creator, so trails could only
-- be authored by hand. Same selection language as CreateStructuredBeam.
function EmitterManager.CreateBezierTrail()
	local Selection = game:GetService("Selection")
	local history = game:GetService("ChangeHistoryService")
	local selected = Selection:Get()
	local templateTrail
	local attachments, parts = {}, {}
	for _, item in ipairs(selected) do
		if item:IsA("Trail") then templateTrail = item end
		if item:IsA("Attachment") then table.insert(attachments, item) end
		if item:IsA("BasePart") then table.insert(parts, item) end
	end
	local cframe0, cframe1, parent
	if templateTrail and templateTrail.Attachment0 and templateTrail.Attachment1 then
		cframe0, cframe1 = templateTrail.Attachment0.WorldCFrame, templateTrail.Attachment1.WorldCFrame
		local host = templateTrail:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #attachments >= 2 then
		cframe0, cframe1 = attachments[1].WorldCFrame, attachments[2].WorldCFrame
		local host = attachments[1]:FindFirstAncestorWhichIsA("BasePart")
		parent = host and host.Parent or workspace
	elseif #parts >= 2 then
		cframe0, cframe1 = parts[1].CFrame, parts[2].CFrame
		parent = parts[1].Parent
	elseif #parts == 1 then
		cframe0 = parts[1].CFrame * CFrame.new(0, 0, -3)
		cframe1 = parts[1].CFrame * CFrame.new(0, 0, 3)
		parent = parts[1].Parent
	else
		return nil, "Select a Trail, two Attachments, two Parts, or one Part."
	end
	if not parent or parent:IsA("BasePart") or parent:IsA("Attachment") then parent = workspace end
	history:SetWaypoint("VfxLab Create Trail - Before")
	local container = Instance.new("Part")
	local attachment0, attachment1 = configureBeamHost(container, cframe0, cframe1)
	container.Name = (templateTrail and templateTrail.Name or "Trail") .. "_TrailVFX"
	container:SetAttribute("VisualXVersion", 7)
	container:SetAttribute("IsEmitter", true)
	local settings = settingsObject(container, true)
	settings:SetAttribute("Enabled", false)
	settings:SetAttribute("EmitCount", 1)
	settings:SetAttribute("EmitDelay", 0)
	settings:SetAttribute("LoopDelay", 0)
	settings:SetAttribute("Rate", 2)
	settings:SetAttribute("EffectDuration", 0.6)
	container:SetAttribute("TrailPathMode", "Bezier Orbit")
	local trail = templateTrail and templateTrail:Clone() or Instance.new("Trail")
	trail.Name = "Trail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Enabled = false
	if not templateTrail then
		trail.Color = ColorSequence.new(Color3.fromRGB(80, 210, 255))
		trail.Transparency = NumberSequence.new(0)
		trail.Lifetime = 0.5
		trail.FaceCamera = true
		trail.LightEmission = 1
	end
	trail.Parent = container
	ensureBezierTrailDefaults(container)
	container.Parent = parent
	if templateTrail then templateTrail.Enabled = false end
	history:SetWaypoint("VfxLab Create Trail")
	Selection:Set({container})
	return container
end

pcall(EmitterManager.SyncLightningTemplate)
return EmitterManager