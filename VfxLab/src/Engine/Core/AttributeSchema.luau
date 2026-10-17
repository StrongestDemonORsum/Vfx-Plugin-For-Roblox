local AttributeSchema = {
	Version = 5,
	Definitions = {},
}

local function define(name, data)
	data.Name = name
	data.Aliases = data.Aliases or {}
	data.Category = data.Category or "General"
	data.Copy = data.Copy ~= false
	AttributeSchema.Definitions[name] = data
end

define("VisualXVersion", {Type = "number", Default = 3, Copy = false})
define("IsMeshEmitter", {Type = "boolean", Default = false, Category = "Identity", Copy = false})
define("IsEmitter", {Type = "boolean", Default = false, Category = "Identity", Copy = false})
define("Transformed", {Type = "boolean", Default = false, Category = "Identity", Copy = false})
define("Enabled", {Type = "boolean", Default = false, Category = "Emission"})
define("EmitCount", {Type = "number", Default = 1, Min = 1, Category = "Emission", Aliases = {"Count"}})
define("EmitDelay", {Type = "number", Default = 0, Min = 0, Category = "Emission", Retime = "Inverse", Aliases = {"Delay"}})
define("EmitDuration", {Type = "number", Default = 0, Min = 0, Category = "Emission", Retime = "Inverse"})
define("LoopDelay", {Type = "number", Default = 0, Min = 0, Category = "Emission", Retime = "Inverse"})
define("Rate", {Type = "number", Default = 20, Min = 0, Category = "Emission", Retime = "Multiply"})
define("Lifetime", {Type = "NumberRange", Types = {"NumberRange", "number"}, Default = NumberRange.new(1), Min = 0.01, Category = "Emission", Retime = "Inverse", Aliases = {"EffectDuration", "Duration", "Time"}})
define("TimeScale", {Type = "number", Default = 1, Min = 0, Category = "Emission", Retime = "Multiply"})
define("Speed", {Type = "NumberRange", Types = {"NumberRange", "number"}, Default = NumberRange.new(0), Category = "Motion", Resize = "Multiply"})
define("Speed_Start", {Type = "number", Default = 0, Category = "Motion", Resize = "Multiply"})
define("Speed_End", {Type = "number", Default = 0, Category = "Motion", Resize = "Multiply"})
define("SpreadAngle", {Type = "Vector2", Types = {"Vector2", "Vector3"}, Default = Vector2.zero, Category = "Motion"})
define("Acceleration", {Type = "Vector3", Default = Vector3.zero, Category = "Motion", Resize = "Multiply"})
define("Drag", {Type = "number", Default = 0, Min = 0, Category = "Motion"})
define("Velocity", {Type = "Vector3", Default = Vector3.zero, Category = "Motion", Resize = "Multiply"})
define("GravityInfluence", {Type = "number", Default = 0, Category = "Motion"})
define("LocalSpace", {Type = "boolean", Default = true, Category = "Motion"})
define("InheritVelocity", {Type = "number", Default = 0, Category = "Motion"})
define("FaceVelocity", {Type = "boolean", Default = false, Category = "Motion"})
define("FaceCamera", {Type = "boolean", Default = false, Category = "Motion"})
define("Attraction", {Type = "number", Default = 0, Category = "Motion"})
define("Rotation", {Type = "NumberRange", Default = NumberRange.new(0), Category = "Rotation"})
define("RotSpeed", {Type = "NumberRange", Default = NumberRange.new(0), Category = "Rotation"})
for _, axis in ipairs({"X", "Y", "Z"}) do
	define("Rotation_" .. axis, {
		Type = "NumberRange",
		Types = {"NumberRange", "number", "string"},
		Default = NumberRange.new(0),
		Category = "Rotation",
		Aliases = {"Rotation" .. axis},
	})
	define("RotSpeed_" .. axis, {
		Type = "NumberRange",
		Types = {"NumberRange", "number", "string"},
		Default = NumberRange.new(0),
		Category = "Rotation",
		Aliases = {"RotSpeed" .. axis},
	})
end
define("RandRotation", {Type = "boolean", Default = false, Category = "Rotation"})
define("MinInitRot", {Type = "Vector3", Default = Vector3.zero, Category = "Rotation"})
define("MaxInitRot", {Type = "Vector3", Default = Vector3.zero, Category = "Rotation"})
define("RotAroundOrigin", {Type = "boolean", Default = false, Category = "Rotation"})
define("Part_RotSpeed_Start", {Type = "NumberRange", Default = NumberRange.new(0), Category = "Rotation"})
define("Part_RotSpeed_End", {Type = "NumberRange", Default = NumberRange.new(0), Category = "Rotation"})
define("SyncPosition", {Type = "boolean", Default = false, Category = "Motion"})
define("Size", {Type = "NumberSequence", Types = {"NumberSequence", "number"}, Default = NumberSequence.new(1), Category = "Transform", Resize = "Multiply"})
for _, axis in ipairs({"X", "Y", "Z"}) do
	define("Size_" .. axis, {Type = "NumberSequence", Default = NumberSequence.new(1), Category = "Transform", Resize = "Multiply"})
end
define("SizeMultiplier", {Type = "number", Default = 1, Category = "Transform", Resize = "Multiply"})
define("OffsetStart", {Type = "Vector3", Default = Vector3.zero, Category = "Transform", Resize = "Multiply"})
define("OffsetEnd", {Type = "Vector3", Default = Vector3.zero, Category = "Transform", Resize = "Multiply"})
define("OffsetEasing", {Type = "string", Default = "Linear", Category = "Transform"})
define("SpawnCFrame", {Type = "CFrame", Default = CFrame.new(), Category = "Transform", Copy = false})
define("Part_Transparency_Start", {Type = "number", Default = 0, Category = "Appearance", Aliases = {"Transparency_Start", "StartTransparency"}})
define("Part_Transparency_End", {Type = "number", Default = 1, Category = "Appearance", Aliases = {"Transparency_End", "EndTransparency"}})
define("DecalTransStart", {Type = "number", Default = 0, Category = "Appearance", Aliases = {"Decal_StartTransparency"}})
define("DecalTransEnd", {Type = "number", Default = 1, Category = "Appearance", Aliases = {"Decal_EndTransparency"}})
define("DecalEasing", {Type = "string", Default = "Linear", Category = "Appearance"})
define("EasingStyle", {Type = "string", Default = "Linear", Category = "Curve"})
define("Part_Size_Curve", {Type = "string", Default = "", Category = "Curve"})
define("Part_CFrame_Curve", {Type = "string", Default = "", Category = "Curve"})
define("Part_Transparency_Curve", {Type = "string", Default = "", Category = "Curve"})
define("Part_RotSpeed_Curve", {Type = "string", Default = "", Category = "Curve"})
define("Mesh_Scale_Curve", {Type = "string", Default = "", Category = "Curve"})
define("Part_TweenParams", {Type = "string", Default = "", Category = "Curve"})
define("Mesh_TweenParams", {Type = "string", Default = "", Category = "Curve"})
define("Decal_TweenParams", {Type = "string", Default = "", Category = "Curve"})
define("_EasyMeshEmitData", {Type = "string", Default = "", Category = "Compatibility", Copy = false})
define("bakedAnimationTrack", {Type = "string", Default = "", Category = "Compatibility", Copy = false})
define("PoolLimit", {Type = "number", Default = 32, Min = 0, Category = "Performance", Copy = false})
define("PoolIdleLifetime", {Type = "number", Default = 30, Min = 1, Category = "Performance", Copy = false})
define("HL_Enabled", {Type = "boolean", Default = false, Category = "Highlight"})
define("HL_FillColor", {Type = "Color3", Default = Color3.new(1, 1, 1), Category = "Highlight"})
define("HL_OutlineColor", {Type = "Color3", Default = Color3.new(1, 1, 1), Category = "Highlight"})
define("HL_FillTrans", {Type = "number", Default = 0.5, Category = "Highlight"})
define("HL_OutTrans", {Type = "number", Default = 0, Category = "Highlight"})
define("IsCraterDebris", {Type = "boolean", Default = false, Category = "Rock"})
define("CraterRadius", {Type = "number", Default = 25, Category = "Rock", Resize = "Multiply"})
define("RockSize", {Type = "number", Default = 2, Category = "Rock", Resize = "Multiply"})
define("Debris_SizeMult", {Type = "number", Default = 0.43, Category = "Rock", Resize = "Multiply"})
define("Debris_Size", {Type = "number", Default = 0.7, Category = "Rock", Resize = "Multiply"})
define("TrailPathPreset", {Type = "string", Default = "Custom", Category = "Trail Path"})
define("TrailPathMode", {Type = "string", Default = "Static", Category = "Trail Path"})
define("TrailPathCurve", {Type = "string", Default = "Custom", Category = "Trail Path"})
define("TrailPathRadius", {Type = "number", Default = 8, Min = 0, Category = "Trail Path", Resize = "Multiply"})
define("TrailPathTurns", {Type = "number", Default = 2, Min = 0, Category = "Trail Path"})
define("TrailPathHeight", {Type = "number", Default = 5, Category = "Trail Path", Resize = "Multiply"})
define("TrailPathCount", {Type = "number", Default = 1, Min = 1, Max = 24, Category = "Trail Path"})
define("TrailPathBurstCount", {Type = "number", Default = 1, Min = 1, Max = 16, Category = "Trail Path"})
define("TrailPathStagger", {Type = "number", Default = 0, Min = 0, Category = "Trail Path", Retime = "Inverse"})
define("TrailPathDuration", {Type = "number", Default = 1, Min = 0.05, Category = "Trail Path", Retime = "Inverse"})
define("TrailPathDurationJitter", {Type = "number", Default = 0, Min = 0, Category = "Trail Path", Retime = "Inverse"})
define("TrailPathSmoothness", {Type = "number", Default = 0.12, Min = 0, Max = 1, Category = "Trail Path"})
define("TrailPathReverse", {Type = "boolean", Default = false, Category = "Trail Path"})
define("TrailPathPingPong", {Type = "boolean", Default = false, Category = "Trail Path"})
define("TrailPathOffsetStart", {Type = "Vector3", Default = Vector3.new(0, 0, 8), Category = "Trail Position", Resize = "Multiply"})
define("TrailPathOffsetEnd", {Type = "Vector3", Default = Vector3.zero, Category = "Trail Position", Resize = "Multiply"})
define("TrailPathControl1", {Type = "Vector3", Default = Vector3.new(0, 0, 8), Category = "Trail Position", Resize = "Multiply"})
define("TrailPathControl2", {Type = "Vector3", Default = Vector3.new(0, 0, 4), Category = "Trail Position", Resize = "Multiply"})
define("TrailPathWobble", {Type = "Vector3", Default = Vector3.zero, Category = "Trail Position", Resize = "Multiply"})
define("TrailPathWobbleSpeed", {Type = "Vector3", Default = Vector3.new(1, 1, 1), Category = "Trail Position", Retime = "Multiply"})
define("TrailPathRotationStart", {Type = "Vector3", Default = Vector3.zero, Category = "Trail Rotation"})
define("TrailPathRotationEnd", {Type = "Vector3", Default = Vector3.new(0, 360, 0), Category = "Trail Rotation"})
define("TrailPathRotationSpread", {Type = "Vector3", Default = Vector3.new(0, 360, 0), Category = "Trail Rotation"})
define("TrailPathRotationSpeed", {Type = "Vector3", Default = Vector3.zero, Category = "Trail Rotation", Retime = "Multiply"})
define("TrailPathOrientationOffset", {Type = "Vector3", Default = Vector3.zero, Category = "Trail Rotation"})
define("TrailPathRandomRotation", {Type = "boolean", Default = false, Category = "Trail Rotation"})
define("TrailPathFaceMotion", {Type = "boolean", Default = false, Category = "Trail Rotation"})

local function transform(value, multiplier)
	local kind = typeof(value)
	if kind == "number" then
		return value * multiplier
	elseif kind == "Vector2" or kind == "Vector3" then
		return value * multiplier
	elseif kind == "NumberRange" then
		return NumberRange.new(value.Min * multiplier, value.Max * multiplier)
	elseif kind == "NumberSequence" then
		local points = {}
		for _, point in ipairs(value.Keypoints) do
			table.insert(points, NumberSequenceKeypoint.new(
				point.Time,
				point.Value * multiplier,
				point.Envelope * math.abs(multiplier)
			))
		end
		return NumberSequence.new(points)
	end
	return value
end

function AttributeSchema.GetDefinition(name)
	if AttributeSchema.Definitions[name] then
		return AttributeSchema.Definitions[name]
	end
	for _, definition in pairs(AttributeSchema.Definitions) do
		if table.find(definition.Aliases, name) then
			return definition
		end
	end
	return nil
end

function AttributeSchema.Read(instance, name, useDefault)
	local definition = AttributeSchema.GetDefinition(name)
	if not definition then
		return instance:GetAttribute(name)
	end
	local value = instance:GetAttribute(definition.Name)
	if value ~= nil then
		return value, definition.Name
	end
	for _, alias in ipairs(definition.Aliases) do
		value = instance:GetAttribute(alias)
		if value ~= nil then
			return value, alias
		end
	end
	if useDefault then
		return definition.Default, definition.Name
	end
	return nil, definition.Name
end

function AttributeSchema.Validate(name, value)
	local definition = AttributeSchema.GetDefinition(name)
	if not definition or value == nil then return true end
	local actualType = typeof(value)
	local allowed = definition.Types or {definition.Type}
	if not table.find(allowed, actualType) then
		return false, string.format("%s expects %s, got %s", definition.Name, table.concat(allowed, " or "), actualType)
	end
	if type(value) == "number" then
		if definition.Min ~= nil and value < definition.Min then
			return false, string.format("%s must be at least %s", definition.Name, tostring(definition.Min))
		end
		if definition.Max ~= nil and value > definition.Max then
			return false, string.format("%s must be at most %s", definition.Name, tostring(definition.Max))
		end
	end
	return true
end

function AttributeSchema.Write(instance, name, value)
	local definition = AttributeSchema.GetDefinition(name)
	if not definition then
		instance:SetAttribute(name, value)
		return name
	end
	local _, existingName = AttributeSchema.Read(instance, definition.Name, false)
	instance:SetAttribute(existingName or definition.Name, value)
	return existingName or definition.Name
end

function AttributeSchema.ApplyBehavior(instance, behaviorName, multiplier)
	for name, definition in pairs(AttributeSchema.Definitions) do
		local behavior = definition[behaviorName]
		if behavior then
			local value, actualName = AttributeSchema.Read(instance, name, false)
			if value ~= nil then
				local factor = behavior == "Inverse" and 1 / math.max(multiplier, 0.0001) or multiplier
				instance:SetAttribute(actualName, transform(value, factor))
			end
		end
	end
end

function AttributeSchema.GetVisibleDefinitions(instance)
	local result = {}
	for name, definition in pairs(AttributeSchema.Definitions) do
		local value = AttributeSchema.Read(instance, name, false)
		if value ~= nil then
			table.insert(result, definition)
		end
	end
	table.sort(result, function(a, b)
		if a.Category == b.Category then
			return a.Name < b.Name
		end
		return a.Category < b.Category
	end)
	return result
end

return AttributeSchema