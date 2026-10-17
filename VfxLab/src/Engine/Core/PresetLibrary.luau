local HttpService = game:GetService("HttpService")

local PresetLibrary = {}

local properties = {
	ParticleEmitter = {"Color", "LightEmission", "LightInfluence", "Size", "Speed", "Lifetime", "Rate", "Rotation", "RotSpeed", "SpreadAngle", "Squash", "Transparency", "Drag", "TimeScale", "ZOffset", "EmissionDirection", "Orientation", "Shape", "ShapeStyle", "ShapeInOut"},
	Beam = {"Color", "Transparency", "Width0", "Width1", "CurveSize0", "CurveSize1", "Brightness", "LightEmission", "LightInfluence", "Texture", "TextureLength", "TextureMode", "TextureSpeed", "ZOffset", "FaceCamera", "Segments"},
	Trail = {"Color", "Transparency", "WidthScale", "Lifetime", "MinLength", "MaxLength", "Brightness", "LightEmission", "LightInfluence", "Texture", "TextureLength", "TextureMode", "FaceCamera"},
	Decal = {"Color3", "Transparency", "Texture"},
	Texture = {"Color3", "Transparency", "Texture", "StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV"},
	PointLight = {"Color", "Brightness", "Range", "Shadows"},
	SpotLight = {"Color", "Brightness", "Range", "Angle", "Face", "Shadows"},
	SurfaceLight = {"Color", "Brightness", "Range", "Angle", "Face", "Shadows"},
	Highlight = {"FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency", "DepthMode"},
	Sound = {"SoundId", "Volume", "PlaybackSpeed", "Looped", "RollOffMaxDistance", "RollOffMinDistance"},
}

local function pack(value)
	local kind = typeof(value)
	if kind == "nil" or kind == "number" or kind == "string" or kind == "boolean" then return value end
	if kind == "Vector2" then return {__type = kind, value.X, value.Y} end
	if kind == "Vector3" then return {__type = kind, value.X, value.Y, value.Z} end
	if kind == "Color3" then return {__type = kind, value.R, value.G, value.B} end
	if kind == "CFrame" then return {__type = kind, value:GetComponents()} end
	if kind == "NumberRange" then return {__type = kind, value.Min, value.Max} end
	if kind == "NumberSequence" then
		local points = {}
		for _, point in ipairs(value.Keypoints) do
			table.insert(points, {point.Time, point.Value, point.Envelope})
		end
		return {__type = kind, points = points}
	end
	if kind == "ColorSequence" then
		local points = {}
		for _, point in ipairs(value.Keypoints) do
			table.insert(points, {point.Time, point.Value.R, point.Value.G, point.Value.B})
		end
		return {__type = kind, points = points}
	end
	if kind == "EnumItem" then
		return {__type = kind, enum = tostring(value.EnumType):gsub("^Enum%.", ""), name = value.Name}
	end
	return nil
end

local function unpackValue(value)
	if type(value) ~= "table" or not value.__type then return value end
	local kind = value.__type
	if kind == "Vector2" then return Vector2.new(value[1], value[2]) end
	if kind == "Vector3" then return Vector3.new(value[1], value[2], value[3]) end
	if kind == "Color3" then return Color3.new(value[1], value[2], value[3]) end
	if kind == "CFrame" then local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = table.unpack(value, 1, 12)
		return CFrame.new(x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22) end
	if kind == "NumberRange" then return NumberRange.new(value[1], value[2]) end
	if kind == "NumberSequence" then
		local points = {}
		for _, point in ipairs(value.points or {}) do
			table.insert(points, NumberSequenceKeypoint.new(point[1], point[2], point[3]))
		end
		return #points > 0 and NumberSequence.new(points) or NumberSequence.new(0)
	end
	if kind == "ColorSequence" then
		local points = {}
		for _, point in ipairs(value.points or {}) do
			table.insert(points, ColorSequenceKeypoint.new(point[1], Color3.new(point[2], point[3], point[4])))
		end
		return #points > 0 and ColorSequence.new(points) or ColorSequence.new(Color3.new(1, 1, 1))
	end
	if kind == "EnumItem" then
		local enumType = Enum[value.enum]
		return enumType and enumType[value.name] or nil
	end
	return nil
end

local function siblingIndex(instance)
	local index = 0
	for _, sibling in ipairs(instance.Parent:GetChildren()) do
		if sibling.Name == instance.Name and sibling.ClassName == instance.ClassName then index += 1 end
		if sibling == instance then return index end
	end
	return 1
end

local function pathOf(instance, root)
	if instance == root then return "." end
	local segments = {}
	local current = instance
	while current and current ~= root do
		table.insert(segments, 1, current.Name .. "\31" .. current.ClassName .. "\31" .. siblingIndex(current))
		current = current.Parent
	end
	return current == root and table.concat(segments, "\30") or nil
end

local function buildIndex(root)
	local index = {["."] = root}
	for _, descendant in ipairs(root:GetDescendants()) do
		local path = pathOf(descendant, root)
		if path then index[path] = descendant end
	end
	return index
end

local function propertyList(instance)
	local list = properties[instance.ClassName]
	if list then return list end
	if instance:IsA("Light") then return properties.PointLight end
	return nil
end

function PresetLibrary.Capture(root)
	assert(typeof(root) == "Instance", "PresetLibrary.Capture requires an Instance")
	local preset = {
		Version = 1,
		RootClass = root.ClassName,
		RootName = root.Name,
		Entries = {},
	}
	local instances = {root}
	for _, descendant in ipairs(root:GetDescendants()) do table.insert(instances, descendant) end
	for _, instance in ipairs(instances) do
		local attributes = {}
		for name, value in pairs(instance:GetAttributes()) do
			local packed = pack(value)
			if packed ~= nil then attributes[name] = packed end
		end
		local savedProperties = {}
		for _, name in ipairs(propertyList(instance) or {}) do
			local ok, value = pcall(function() return instance[name] end)
			if ok then
				local packed = pack(value)
				if packed ~= nil then savedProperties[name] = packed end
			end
		end
		if next(attributes) or next(savedProperties) then
			table.insert(preset.Entries, {
				Path = pathOf(instance, root),
				ClassName = instance.ClassName,
				Attributes = attributes,
				Properties = savedProperties,
			})
		end
	end
	return preset
end

function PresetLibrary.Apply(root, preset)
	assert(typeof(root) == "Instance", "PresetLibrary.Apply requires an Instance")
	assert(type(preset) == "table" and type(preset.Entries) == "table", "Invalid VisualX preset")
	local index = buildIndex(root)
	local applied = 0
	for _, entry in ipairs(preset.Entries) do
		local instance = index[entry.Path]
		if instance and (not entry.ClassName or instance.ClassName == entry.ClassName) then
			for name, packed in pairs(entry.Attributes or {}) do
				local value = unpackValue(packed)
				if value ~= nil then
					pcall(function() instance:SetAttribute(name, value) end)
				end
			end
			for name, packed in pairs(entry.Properties or {}) do
				local value = unpackValue(packed)
				if value ~= nil then
					pcall(function() instance[name] = value end)
				end
			end
			applied += 1
		end
	end
	return applied
end

function PresetLibrary.Encode(preset)
	return HttpService:JSONEncode(preset)
end

function PresetLibrary.Decode(json)
	local preset = HttpService:JSONDecode(json)
	assert(type(preset) == "table" and type(preset.Entries) == "table", "Invalid VisualX preset JSON")
	return preset
end

return PresetLibrary