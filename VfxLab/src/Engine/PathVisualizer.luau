local PathVisualizer = {}
local Bezier3D = require(script.Parent.Assets.VFXPlayer.Runtime.Bezier3D)
local StructuredRuntime = require(script.Parent.Assets.VFXPlayer.StructuredRuntime)

local folder
local pool = {}
local used = 0

local function cacheFolder()
	if not folder or not folder.Parent then
		folder = workspace:FindFirstChild("VfxLab_Visualizer_Cache")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "VfxLab_Visualizer_Cache"
			folder.Parent = workspace
		end
	end
	return folder
end

local function segment()
	used += 1
	local part = pool[used]
	if not part or not part.Parent then
		part = Instance.new("Part")
		part.Name = "VisualX_Path"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(205, 165, 255)
		part.Transparency = 0.35
		part.Parent = cacheFolder()
		pool[used] = part
	end
	part.Transparency = 0.35
	return part
end

local function draw(a, b)
	local delta = b - a
	if delta.Magnitude < 0.001 then return end
	local part = segment()
	part.Size = Vector3.new(0.025, 0.025, delta.Magnitude)
	part.CFrame = CFrame.lookAt((a + b) * 0.5, b)
end

local function finish()
	for index = used + 1, #pool do
		local part = pool[index]
		if part and part.Parent then part.Transparency = 1 end
	end
end

local function rangeMax(value, fallback)
	if typeof(value) == "NumberRange" then return value.Max end
	if type(value) == "number" then return value end
	return fallback
end

local function sourceCFrame(emitter)
	if emitter:IsA("ParticleEmitter") then
		local parent = emitter.Parent
		if parent and parent:IsA("Attachment") then return parent.WorldCFrame end
		if parent and parent:IsA("BasePart") then return parent.CFrame end
	elseif StructuredRuntime.IsStructured(emitter) then
		return StructuredRuntime.GetSourcePivot(emitter)
	elseif emitter:IsA("Model") then
		return emitter:GetPivot()
	end
	if emitter:IsA("BasePart") then return emitter.CFrame end
	local part = emitter:FindFirstChildWhichIsA("BasePart", true)
	return part and part.CFrame or CFrame.new()
end

local directions = {
	[Enum.NormalId.Top] = Vector3.yAxis,
	[Enum.NormalId.Bottom] = -Vector3.yAxis,
	[Enum.NormalId.Front] = -Vector3.zAxis,
	[Enum.NormalId.Back] = Vector3.zAxis,
	[Enum.NormalId.Right] = Vector3.xAxis,
	[Enum.NormalId.Left] = -Vector3.xAxis,
}

local function trajectoryData(emitter)
	local base = sourceCFrame(emitter)
	local speed, lifetime, spread, acceleration, drag
	local direction = Vector3.yAxis
	if emitter:IsA("ParticleEmitter") then
		speed = emitter.Speed.Max
		lifetime = emitter.Lifetime.Max
		spread = emitter.SpreadAngle
		acceleration = emitter.Acceleration
		drag = emitter.Drag
		direction = directions[emitter.EmissionDirection] or Vector3.yAxis
	else
		speed = rangeMax(emitter:GetAttribute("Speed"), rangeMax(emitter:GetAttribute("Speed_End"), 0))
		lifetime = rangeMax(emitter:GetAttribute("Lifetime"), rangeMax(emitter:GetAttribute("EffectDuration"), rangeMax(emitter:GetAttribute("Duration"), 1)))
		spread = emitter:GetAttribute("SpreadAngle") or Vector2.zero
		acceleration = emitter:GetAttribute("Acceleration") or Vector3.zero
		drag = emitter:GetAttribute("Drag") or 0
	end
	if typeof(spread) == "Vector3" then spread = Vector2.new(spread.X, spread.Z ~= 0 and spread.Z or spread.Y) end
	if typeof(spread) ~= "Vector2" then spread = Vector2.zero end
	return base, speed or 0, math.max(lifetime or 1, 0.01), spread, acceleration, drag or 0, direction
end

local function drawTrajectory(emitter)
	local base, speed, lifetime, spread, acceleration, drag, emissionDirection = trajectoryData(emitter)
	local pathCount = spread.Magnitude > 0 and 10 or 1
	local steps = 22
	local random = Random.new(8317)
	for _ = 1, pathCount do
		local x = math.rad((random:NextNumber() - 0.5) * spread.X)
		local z = math.rad((random:NextNumber() - 0.5) * spread.Y)
		local localDirection = CFrame.Angles(x, 0, z):VectorToWorldSpace(emissionDirection)
		local velocity = base:VectorToWorldSpace(localDirection) * speed
		local position = base.Position
		local deltaTime = lifetime / steps
		for _ = 1, steps do
			local previous = position
			velocity += acceleration * deltaTime
			if drag > 0 then velocity *= math.exp(-drag * deltaTime) end
			position += velocity * deltaTime
			draw(previous, position)
		end
	end
end

local function drawBeamTrail(effect)
	local a = effect.Attachment0
	local b = effect.Attachment1
	if a and b then draw(a.WorldPosition, b.WorldPosition) end
end

function PathVisualizer.Show(emitters)
	used = 0
	cacheFolder()
	for _, emitter in ipairs(emitters or {}) do
		if emitter:IsA("Beam") or emitter:IsA("Trail") then
			drawBeamTrail(emitter)
		elseif emitter:GetAttribute("IsBezier3D") == true then
			local curve = Bezier3D.FromFolder(emitter)
			local points = curve:Sample(28)
			for index = 1, #points - 1 do draw(points[index], points[index + 1]) end
		else
			drawTrajectory(emitter)
		end
	end
	finish()
end

function PathVisualizer.Clear()
	used = 0
	if folder and folder.Parent then folder:ClearAllChildren() end
	table.clear(pool)
end

return PathVisualizer