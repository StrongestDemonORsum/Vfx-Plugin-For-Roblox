local EmitterManager = require(script.Parent.EmitterManager)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CameraShaker = require(script.Parent.CameraShaker)
local StructuredRuntime = require(script.Parent.Assets.VFXPlayer.StructuredRuntime)
local BeamTrailRuntime = require(script.Parent.Assets.VFXPlayer.Runtime.BeamTrailRuntime)
local LightningRuntime = require(script.Parent.Assets.VFXPlayer.Runtime.LightningRuntime)
local Cleanup = require(script.Parent.Assets.VFXPlayer.Runtime.Cleanup)
local TweenRuntime = require(script.Parent.Assets.VFXPlayer.Runtime.TweenRuntime)
local ShockwaveRuntime = require(script.Parent.Assets.VFXPlayer.Runtime.ShockwaveRuntime)
local TweenPropertyRuntime = require(script.Parent.Assets.VFXPlayer.Runtime.TweenPropertyRuntime)
local PathVisualizer = require(script.Parent.PathVisualizer)

local RockModule
do
	local debris = script.Parent:FindFirstChild("Debris")
	if debris then
		local ok, mod = pcall(require, debris)
		if ok then RockModule = mod end
	end
end

local EmitController = {}

local activeFOVTween
local preservedFOV

if _G.VfxLab_Preview_Loop and _G.VfxLab_Preview_Loop.Connected then _G.VfxLab_Preview_Loop:Disconnect() end
_G.VfxLab_Preview_Loop = nil
if _G.VfxLab_Cache_Folder then pcall(function() _G.VfxLab_Cache_Folder:ClearAllChildren() end) end

local previewCleanup = Cleanup.new()

local function emitStructuredPreview(emitter, cache, amount)
	local startBeam
	if EmitterManager.GetStructuredKind(emitter) == "Beam" then
		startBeam = EmitterManager.GetStructuredStateObject(emitter, "Start")
	end
	local wasEnabled = startBeam and startBeam.Enabled
	if startBeam then startBeam.Enabled = true end
	local handle = StructuredRuntime.Emit(emitter, nil, cache, amount)
	if startBeam then startBeam.Enabled = wasEnabled end
	return handle
end

local function getPreviewCache()
	local cache = workspace:FindFirstChild("VfxLab_Preview_Cache")
	if not cache then
		cache = Instance.new("Folder")
		cache.Name = "VfxLab_Preview_Cache"
		cache.Parent = workspace
	end
	return cache
end

local function findLightningAttachment(emitter, specificName, legacyName)
	local legacy
	for _, child in ipairs(emitter:GetChildren()) do
		if child:IsA("Attachment") then
			if child.Name == specificName then return child end
			if child.Name == legacyName then legacy = child end
		end
	end
	return legacy
end

local function emitLightningPreview(emitter, cache, amount)
	if not EmitterManager.IsLightningEmitter(emitter) then return end
	local attachment0 = findLightningAttachment(emitter, "VisualX_LightningStart", "Attachment0")
	local attachment1 = findLightningAttachment(emitter, "VisualX_LightningEnd", "Attachment1")
	local mode = tostring(EmitterManager.GetSetting(emitter, "LightningMode", "Single"))
	local isRadial = string.lower(mode) == "radial"
	local startPosition = isRadial and emitter.Position
		or (attachment0 and attachment0.WorldPosition or (emitter.CFrame * CFrame.new(0, 0, -3)).Position)
	local endPosition = attachment1 and attachment1.WorldPosition or (emitter.CFrame * CFrame.new(0, 0, 3)).Position
	if (endPosition - startPosition).Magnitude <= 0.001 then
		endPosition = (emitter.CFrame * CFrame.new(0, 0, 6)).Position
	end
	for index = 1, math.max(math.floor(tonumber(amount) or 1), 1) do
		local handle = LightningRuntime.Play({
			Parent = cache,
			Template = EmitterManager.GetLightningTemplate(),
			Start = startPosition,
			End = endPosition,
			Mode = mode,
			BoltCount = EmitterManager.GetSetting(emitter, "LightningBoltCount", 5),
			Spread = EmitterManager.GetSetting(emitter, "LightningSpread", 6),
			CurveSize0 = EmitterManager.GetSetting(emitter, "LightningCurveSize0", 0),
			CurveSize1 = EmitterManager.GetSetting(emitter, "LightningCurveSize1", 0),
			Segments = EmitterManager.GetSetting(emitter, "LightningSegments", 30),
			Jitter = EmitterManager.GetSetting(emitter, "LightningJitter", 2.4),
			MinRadius = EmitterManager.GetSetting(emitter, "LightningMinRadius", 0),
			MaxRadius = EmitterManager.GetSetting(emitter, "LightningMaxRadius", 2.4),
			Frequency = EmitterManager.GetSetting(emitter, "LightningFrequency", 1),
			Thickness = EmitterManager.GetSetting(emitter, "LightningThickness", 0.18),
			MinThicknessMultiplier = EmitterManager.GetSetting(emitter, "LightningMinThicknessMultiplier", 0.2),
			MaxThicknessMultiplier = EmitterManager.GetSetting(emitter, "LightningMaxThicknessMultiplier", 1),
			GlowThickness = EmitterManager.GetSetting(emitter, "LightningGlowThickness", 0.48),
			PartColor = EmitterManager.GetSetting(emitter, "LightningPartColor",
				EmitterManager.GetSetting(emitter, "Color", emitter.Color)),
			HighlightColor = EmitterManager.GetSetting(emitter, "LightningHighlightColor",
				EmitterManager.GetSetting(emitter, "LightningCoreColor", Color3.fromRGB(0, 0, 0))),
			Transparency = EmitterManager.GetSetting(emitter, "LightningTransparency", 0),
			GlowTransparency = EmitterManager.GetSetting(emitter, "LightningGlowTransparency", 0.5),
			Lifetime = EmitterManager.GetSetting(emitter, "LightningLifetime", 0.6),
			AnimationSpeed = EmitterManager.GetSetting(emitter, "LightningAnimationSpeed", 7),
			RefreshRate = EmitterManager.GetSetting(emitter, "LightningRefreshRate", 60),
			PulseSpeed = EmitterManager.GetSetting(emitter, "LightningPulseSpeed", 2),
			PulseLength = EmitterManager.GetSetting(emitter, "LightningPulseLength", 1000000),
			FadeLength = EmitterManager.GetSetting(emitter, "LightningFadeLength", 0.2),
			ContractFrom = EmitterManager.GetSetting(emitter, "LightningContractFrom", 0.5),
			Seed = math.random(1, 1000000000) + index,
			Branches = EmitterManager.GetSetting(emitter, "LightningBranches", 6),
			BranchChance = EmitterManager.GetSetting(emitter, "LightningBranchChance", 0.32),
			BranchLength = EmitterManager.GetSetting(emitter, "LightningBranchLength", 4.5),
			BranchSegments = EmitterManager.GetSetting(emitter, "LightningBranchSegments", 4),
			Flicker = EmitterManager.GetSetting(emitter, "LightningFlicker", 0.16),
		})
		previewCleanup:Add(handle, "Stop")
	end
end

local function emitSingleBeamPreview(emitter, cache)
	local runtime = BeamTrailRuntime.Create(emitter, emitter.CFrame, cache, emitter.CFrame)
	runtime:Emit()
	previewCleanup:Add(runtime, "Stop")
end

local function evalRange(nRange)
	if not nRange then return 0 end
	if type(nRange) == "number" then return nRange end
	if nRange.Min == nRange.Max then return nRange.Min end
	return nRange.Min + (math.random() * (nRange.Max - nRange.Min))
end

local function evalSequence(seq, timeAlpha)
	if typeof(seq) ~= "NumberSequence" then return typeof(seq) == "number" and seq or 1 end
	local keypoints = seq.Keypoints
	if timeAlpha <= 0 then return keypoints[1].Value end
	if timeAlpha >= 1 then return keypoints[#keypoints].Value end
	for i = 1, #keypoints - 1 do
		local this, nextKp = keypoints[i], keypoints[i+1]
		if timeAlpha >= this.Time and timeAlpha < nextKp.Time then
			local alpha = (timeAlpha - this.Time) / (nextKp.Time - this.Time)
			return this.Value + (nextKp.Value - this.Value) * alpha
		end
	end
	return keypoints[#keypoints].Value
end

local function evalColorSequence(seq, timeAlpha)
	if typeof(seq) ~= "ColorSequence" then return typeof(seq) == "Color3" and seq or Color3.new(1,1,1) end
	local keypoints = seq.Keypoints
	if timeAlpha <= 0 then return keypoints[1].Value end
	if timeAlpha >= 1 then return keypoints[#keypoints].Value end
	for i = 1, #keypoints - 1 do
		local this, nextKp = keypoints[i], keypoints[i+1]
		if timeAlpha >= this.Time and timeAlpha < nextKp.Time then
			local alpha = (timeAlpha - this.Time) / (nextKp.Time - this.Time)
			return this.Value:Lerp(nextKp.Value, alpha)
		end
	end
	return keypoints[#keypoints].Value
end

local function applyEasing(a, style)
	style = string.lower(style or "linear")
	if style:find("spike") then
		return 1 - math.abs((a * 2) - 1)
	elseif style:find("sine") then
		return (1 - math.cos(a * math.pi)) / 2
	elseif style:find("inout") then
		return a < 0.5 and 8 * a * a * a * a or 1 - math.pow(-2 * a + 2, 4) / 2
	elseif style:find("out") then
		return 1 - math.pow(1 - a, 4)
	elseif style:find("in") then
		return a * a * a * a
	end
	return a
end

local function fetchRot(emitter, baseName)
	local rx = emitter:GetAttribute(baseName .. "_X")
	local ry = emitter:GetAttribute(baseName .. "_Y")
	local rz = emitter:GetAttribute(baseName .. "_Z")

	if rx or ry or rz then return evalRange(rx), evalRange(ry), evalRange(rz) end

	local raw = emitter:GetAttribute(baseName)
	if typeof(raw) == "Vector3" then return raw.X, raw.Y, raw.Z
	elseif typeof(raw) == "NumberRange" or type(raw) == "number" then return 0, evalRange(raw), 0 end
	return 0, 0, 0
end

local function applyHighlight(vfxModel, p)
	if vfxModel:GetAttribute("HL_Enabled") then
		local hl = Instance.new("Highlight")
		hl.FillColor = vfxModel:GetAttribute("HL_FillColor") or Color3.new(1,1,1)
		hl.OutlineColor = vfxModel:GetAttribute("HL_OutlineColor") or Color3.new(1,1,1)
		hl.FillTransparency = vfxModel:GetAttribute("HL_FillTrans") or 0.5
		hl.OutlineTransparency = vfxModel:GetAttribute("HL_OutTrans") or 0
		hl.Parent = p
	end
end

local function PlayScreenEffects(holder, isStudioPreview)
	if not holder:GetAttribute("SFX_Enabled") then return end

	local Camera = workspace.CurrentCamera
	local Lighting = game:GetService("Lighting")

	if holder:GetAttribute("SFX_UseShake") then
		local magnitude = holder:GetAttribute("SFX_ShakeMag") or 5
		local roughness = holder:GetAttribute("SFX_ShakeRough") or 10
		local fadeIn = holder:GetAttribute("SFX_ShakeFadeIn") or 0.05
		local fadeOut = holder:GetAttribute("SFX_ShakeFadeOut") or 0.15

		if not _G.ActiveCameraShaker then
			local lastShake = CFrame.new() 
			local RunService = game:GetService("RunService")

			_G.ActiveCameraShaker = CameraShaker.new(
				Enum.RenderPriority.Camera.Value,
				function(shakeCFrame)
					if RunService:IsRunning() then
						Camera.CFrame = Camera.CFrame * shakeCFrame
					else
						local posOnlyShake = CFrame.new(shakeCFrame.Position)
						Camera.CFrame = (Camera.CFrame * lastShake:Inverse()) * posOnlyShake
						lastShake = posOnlyShake
					end
				end
			)
			_G.ActiveCameraShaker:Start()
		end

		local isPlaying = game:GetService("RunService"):IsRunning()
		local rotInfluence = isPlaying and Vector3.new(0.1, 0.1, 0.1) or Vector3.zero

		_G.ActiveCameraShaker:ShakeOnce(
			magnitude,
			roughness,
			fadeIn,
			fadeOut,
			Vector3.new(0.1, 0.1, 0.1),
			rotInfluence                
		)
	end

	if holder:GetAttribute("SFX_UseFOV") then
		preservedFOV = preservedFOV or Camera.FieldOfView
		if activeFOVTween then activeFOVTween:Cancel() end
		local startFOV = holder:GetAttribute("SFX_StartFOV") or 110
		local configuredEnd = holder:GetAttribute("SFX_EndFOV")
		local endFOV = configuredEnd ~= nil and configuredEnd or preservedFOV
		local duration = math.max(holder:GetAttribute("SFX_FOVDuration") or 0.3, 0)

		Camera.FieldOfView = startFOV
		local tween = TweenService:Create(Camera, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = endFOV})
		activeFOVTween = tween
		tween.Completed:Connect(function()
			if activeFOVTween == tween then
				activeFOVTween = nil
				preservedFOV = nil
			end
		end)
		tween:Play()
	end

	if holder:GetAttribute("SFX_UseBlur") then
		local blurSize = holder:GetAttribute("SFX_BlurSize") or 25
		local duration = holder:GetAttribute("SFX_BlurDuration") or 0.4

		local blur = Instance.new("BlurEffect")
		blur.Name = "VisualXRuntimeBlur"
		blur.Size = blurSize
		blur.Parent = Lighting

		TweenService:Create(blur, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0}):Play()
		task.delay(duration + 0.05, function() blur:Destroy() end)
	end

	if holder:GetAttribute("SFX_UseVignette") then
		local color = holder:GetAttribute("SFX_VigColor") or Color3.new(0,0,0)
		local targetTrans = holder:GetAttribute("SFX_VigTrans") or 0.3
		local fadeIn = holder:GetAttribute("SFX_VigFadeIn") or 0.1
		local duration = holder:GetAttribute("SFX_VigDuration") or 0.2
		local fadeOut = holder:GetAttribute("SFX_VigFadeOut") or 0.3

		local targetParent
		if isStudioPreview then
			targetParent = game:GetService("CoreGui"):FindFirstChild("VfxLab_CoreUI")
		else
			local Players = game:GetService("Players")
			if Players.LocalPlayer then targetParent = Players.LocalPlayer:WaitForChild("PlayerGui") end
		end

		if targetParent then
			local vigGui = targetParent:FindFirstChild("RuntimeVignette") 
			if not vigGui then
				vigGui = Instance.new("ScreenGui")
				vigGui.Name = "RuntimeVignette"
				vigGui.Parent = targetParent
			end

			local img = Instance.new("ImageLabel")
			img.Name = "VisualXRuntimeVignetteImage"
			img.Size = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.Image = "rbxassetid://127366667073715"
			img.ImageColor3 = color
			img.ImageTransparency = 1
			img.ZIndex = 100
			img.Parent = vigGui

			TweenService:Create(img, TweenInfo.new(fadeIn, Enum.EasingStyle.Sine), {ImageTransparency = targetTrans}):Play()

			task.delay(fadeIn + duration, function()
				local outTween = TweenService:Create(img, TweenInfo.new(fadeOut, Enum.EasingStyle.Sine), {ImageTransparency = 1})
				outTween:Play()
				outTween.Completed:Wait()
				if img then img:Destroy() end
			end)
		end
	end
end

function EmitController.StopScreenEffects()
	if activeFOVTween then activeFOVTween:Cancel() activeFOVTween = nil end
	local camera = workspace.CurrentCamera
	if camera and preservedFOV then camera.FieldOfView = preservedFOV end
	preservedFOV = nil
	for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
		if effect.Name == "VisualXRuntimeBlur" then effect:Destroy() end
	end
	local coreGui = game:GetService("CoreGui")
	for _, item in ipairs(coreGui:GetDescendants()) do
		if item.Name == "VisualXRuntimeVignetteImage" then item:Destroy() end
	end
	if _G.ActiveCameraShaker then
		pcall(function() _G.ActiveCameraShaker:Stop() end)
		_G.ActiveCameraShaker = nil
	end
end

function EmitController.ClearCache()
	local cache = workspace:FindFirstChild("VfxLab_Preview_Cache")
	if cache then cache:ClearAllChildren() end
end

function EmitController.ClearVisualizer()
	PathVisualizer.Clear()
end

function EmitController.UpdateVisualizer()
	PathVisualizer.Show(EmitterManager.CurrentEmitters)
end

function EmitController.SpawnMeshParticle(holder)
	-- Mesh reliability: fall back when there is no Template child so
	-- emission never silently does nothing. Prefers a Template child,
	-- then the holder itself (BasePart), then the first BasePart descendant.
	local template = holder:FindFirstChild("Template")
	if not template then
		if holder:IsA("BasePart") then
			template = holder
		else
			template = holder:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	if not template then return end

	local baseCFrame = CFrame.new()
	if holder:GetAttribute("IsScreenFX") then
		baseCFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -2.5)
	else
		if holder:IsA("Model") and holder.PrimaryPart then baseCFrame = holder.PrimaryPart.CFrame
		else
			local livePart = template
			for _, child in ipairs(holder:GetChildren()) do
				if child:IsA("BasePart") and child.Name ~= "Template" then livePart = child; break end
			end
			if not livePart then return end; baseCFrame = livePart.CFrame
		end
	end

	local cacheFolder = workspace:FindFirstChild("VfxLab_Preview_Cache")
	if not cacheFolder then cacheFolder = Instance.new("Folder"); cacheFolder.Name = "VfxLab_Preview_Cache"; cacheFolder.Parent = workspace end
	_G.VfxLab_Cache_Folder = cacheFolder

	local p = template:Clone()
	p.Name = "VFX_Particle"
	p.Parent = cacheFolder

	-- Mesh reliability: Model templates have no CFrame/Size/Color of
	-- their own, so drive their BasePart descendants instead.
	local pIsModel = p:IsA("Model")
	local pParts = nil
	local pInitSizes = nil
	if pIsModel then
		pParts = {}
		pInitSizes = {}
		for _, d in ipairs(p:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(pParts, d)
				pInitSizes[d] = d.Size
			end
		end
	end
	local function setParticleCFrame(cf)
		if pIsModel then p:PivotTo(cf) else p.CFrame = cf end
	end

	applyHighlight(holder, p)

	local spread = holder:GetAttribute("SpreadAngle") or Vector2.new(0,0)
	-- Mesh reliability: missing/zero Lifetime made particles die on the
	-- first frame (alpha = elapsed / 0). Default to 1 second.
	local lifetime = evalRange(holder:GetAttribute("Lifetime"))
	if lifetime <= 0 then lifetime = 1 end
	local speed = evalRange(holder:GetAttribute("Speed"))
	local accel = holder:GetAttribute("Acceleration") or Vector3.zero
	local drag = holder:GetAttribute("Drag") or 0

	local initRotX, initRotY, initRotZ = fetchRot(holder, "Rotation")
	local rotSpeedX, rotSpeedY, rotSpeedZ = fetchRot(holder, "RotSpeed")

	local sizeXSeq = holder:GetAttribute("Size_X")
	local sizeYSeq = holder:GetAttribute("Size_Y")
	local sizeZSeq = holder:GetAttribute("Size_Z")

	local offsetStart = holder:GetAttribute("OffsetStart") or Vector3.new(0,0,0)
	local offsetEnd = holder:GetAttribute("OffsetEnd") or Vector3.new(0,0,0)
	local offsetEasing = holder:GetAttribute("OffsetEasing") or "Linear"
	local transSeq = holder:FindFirstChild("DataBank") and holder.DataBank:FindFirstChild("Transparency") and holder.DataBank.Transparency.Value or (holder:FindFirstChild("DataBank") and holder.DataBank.Transparency) or NumberSequence.new(0)

	-- THE FIX: Safe Decal Extraction (Prevents Math/Lag Errors!)
	local dStartAttr = holder:GetAttribute("DecalTransStart")
	local dEndAttr = holder:GetAttribute("DecalTransEnd")

	local decalStart = 0
	if typeof(dStartAttr) == "NumberRange" then decalStart = dStartAttr.Min
	elseif type(dStartAttr) == "number" then decalStart = dStartAttr end

	local decalEnd = 1
	if typeof(dEndAttr) == "NumberRange" then decalEnd = dEndAttr.Min
	elseif type(dEndAttr) == "number" then decalEnd = dEndAttr end

	local decalEasing = holder:GetAttribute("DecalEasing") or "Linear"

	local innerDecals = {}
	for _, child in ipairs(p:GetDescendants()) do
		if child:IsA("Decal") or child:IsA("Texture") then
			table.insert(innerDecals, child)
		end
	end

	local spreadX = math.rad((math.random() - 0.5) * spread.X)
	local spreadZ = math.rad((math.random() - 0.5) * spread.Y)

	local localVelocity = CFrame.Angles(spreadX, 0, spreadZ).UpVector * speed
	local localPosition = Vector3.zero
	local currentRotX, currentRotY, currentRotZ = initRotX, initRotY, initRotZ

	local startTime = os.clock()
	local connection

	connection = RunService.RenderStepped:Connect(function(dt)
		if not p or not p.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / lifetime, 0, 1)

		if alpha >= 1 then
			if connection then connection:Disconnect() end
			p:Destroy()
			return
		end

		localVelocity = localVelocity + (accel * dt)
		if drag > 0 then localVelocity = localVelocity * (1 - math.clamp(drag * dt, 0, 1)) end
		localPosition = localPosition + (localVelocity * dt)

		currentRotX = currentRotX + (rotSpeedX * dt)
		currentRotY = currentRotY + (rotSpeedY * dt)
		currentRotZ = currentRotZ + (rotSpeedZ * dt)

		if holder:GetAttribute("IsScreenFX") then
			baseCFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -2.5)
		end

		local basePhysicsCFrame = baseCFrame * CFrame.new(localPosition) * CFrame.Angles(math.rad(currentRotX), math.rad(currentRotY), math.rad(currentRotZ))

		local oAlpha = applyEasing(alpha, offsetEasing)
		local currentOffset = offsetStart:Lerp(offsetEnd, oAlpha)
		p.CFrame = basePhysicsCFrame * CFrame.new(currentOffset)

		-- THE FIX: Cleanly restored standard Size sequence math
		local currentSize
		if sizeXSeq or sizeYSeq or sizeZSeq then
			local sx = evalSequence(sizeXSeq, alpha)
			local sy = evalSequence(sizeYSeq or sizeXSeq, alpha)
			local sz = evalSequence(sizeZSeq or sizeXSeq, alpha)
			currentSize = Vector3.new(sx, sy, sz)
		else
			local sizeData = holder:FindFirstChild("DataBank") and holder.DataBank:FindFirstChild("Size")
			local sizeSeq = sizeData and sizeData.Value or (holder:FindFirstChild("DataBank") and holder.DataBank.Size) or NumberSequence.new(1)
			local s = evalSequence(sizeSeq, alpha)
			currentSize = Vector3.new(s, s, s)
		end

		-- 1. Scale the Base Part
		p.Size = template.Size * currentSize

		-- 2. NEW FIX: Safely scale any internal Mesh objects (SpecialMesh, CylinderMesh, etc.)
		local internalMesh = p:FindFirstChildWhichIsA("DataModelMesh")
		if internalMesh then
			local templateMesh = template:FindFirstChildWhichIsA("DataModelMesh")
			if templateMesh then
				-- Multiply the original template's scale by the current animated size
				internalMesh.Scale = templateMesh.Scale * currentSize
			end
		end

		local colorSeq = holder:FindFirstChild("DataBank") and holder.DataBank.Color or ColorSequence.new(Color3.new(1,1,1))
		local currentColor = evalColorSequence(colorSeq, alpha)

		-- THE FIX: Decal Isolation without the lag
		if #innerDecals > 0 then
			p.Transparency = 1 
			local dAlpha = applyEasing(alpha, decalEasing)
			local cTrans = decalStart + (decalEnd - decalStart) * dAlpha
			p.Color = currentColor 
			for _, d in ipairs(innerDecals) do 
				d.Transparency = cTrans 
				d.Color3 = currentColor
			end
		else
			p.Transparency = evalSequence(transSeq, alpha)
			p.Color = currentColor
		end
	end)
end

local function spawnCraterDebris(holder)
	local template = holder:FindFirstChild("Template")
	if not template then return end

	local target = holder.Parent
	local centerPos = Vector3.zero
	if target:IsA("Model") and target.PrimaryPart then centerPos = target.PrimaryPart.Position
	else
		for _, d in ipairs(target:GetDescendants()) do if d:IsA("BasePart") then centerPos = d.Position break end end
	end

	local count = holder:GetAttribute("EmitCount") or 15
	local radius = holder:GetAttribute("CraterRadius") or 25
	local baseSize = holder:GetAttribute("RockSize") or 2

	local cacheFolder = workspace:FindFirstChild("VfxLab_Preview_Cache")

	for i = 1, count do
		local p = template:Clone()
		p.Name = "CraterRock"
		p.Parent = cacheFolder

		applyHighlight(holder, p)

		local angle = (i / count) * math.pi * 2 + (math.random() - 0.5) * 0.4
		local rad = radius * (0.6 + math.random() * 0.4)
		local targetPos = centerPos + Vector3.new(math.cos(angle)*rad, 0, math.sin(angle)*rad)

		local lookAtCFrame = CFrame.lookAt(targetPos, centerPos)
		local tiltX = math.rad(math.random(15, 55))
		local rollZ = math.rad(math.random(-15, 15))
		local finalCFrame = lookAtCFrame * CFrame.Angles(tiltX, 0, rollZ)

		local sx = baseSize * (0.8 + math.random() * 0.6)
		local sy = baseSize * (0.4 + math.random() * 0.4)
		local sz = baseSize * (1.0 + math.random() * 0.8)
		local targetSize = Vector3.new(sx, sy, sz)

		p.Size = Vector3.zero
		p.CFrame = finalCFrame - Vector3.new(0, sy + 3, 0)

		local tweenUp = TweenService:Create(p, TweenInfo.new(0.3 + math.random()*0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = targetSize, CFrame = finalCFrame + Vector3.new(0, sy/2 - 0.1, 0)
		})
		tweenUp:Play()

		task.delay(2 + math.random() * 1.5, function()
			if not p or not p.Parent then return end
			local tweenDown = TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.zero, CFrame = finalCFrame - Vector3.new(0, sy + 3, 0)
			})
			tweenDown:Play()
			tweenDown.Completed:Wait()
			if p and p.Parent then p:Destroy() end
		end)
	end
end

local activeSpawners = {}
local loopTimers = {}
local beamTrailLoops = {}
local visUpdateTimer = 0

local function stopBeamTrailLoop(emitter)
	local runtime = beamTrailLoops[emitter]
	if runtime then
		runtime:Stop()
		beamTrailLoops[emitter] = nil
	end
end

_G.VfxLab_Preview_Loop = previewCleanup:Add(RunService.RenderStepped:Connect(function(dt)
	if _G.VfxLab_ShowBeams then
		visUpdateTimer = visUpdateTimer + dt
		if visUpdateTimer > 0.15 then 
			visUpdateTimer = 0
			EmitController.UpdateVisualizer() 
		end
	end

	local liveBeamTrails = {}
	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		local isBeamTrail = emitter:IsA("Beam") or emitter:IsA("Trail")
		if isBeamTrail then
			liveBeamTrails[emitter] = true
			if emitter.Enabled then
				if not beamTrailLoops[emitter] then
					local attachment = emitter.Attachment0 or emitter.Attachment1
					local baseCFrame = attachment and attachment.WorldCFrame or CFrame.new()
					local runtime = BeamTrailRuntime.Create(emitter, baseCFrame, getPreviewCache(), baseCFrame)
					beamTrailLoops[emitter] = runtime
					runtime:Enable()
					previewCleanup:Add(runtime, "Stop")
				end
			else
				stopBeamTrailLoop(emitter)
			end
		end

		local isLegacy = (emitter:IsA("Folder") or emitter:IsA("Model")) and emitter:GetAttribute("IsMeshEmitter")
		local isStructured = StructuredRuntime.IsStructured(emitter)
		local isLightning = EmitterManager.IsLightningEmitter(emitter)
		local isSingleBeam = EmitterManager.IsSingleBeamEmitter(emitter)
		if isLegacy or isStructured or isLightning or isSingleBeam then
			if EmitterManager.GetSetting(emitter, "Enabled", false) then
				local function emitAmount(amount)
					if isLightning then
						emitLightningPreview(emitter, getPreviewCache(), amount)
					elseif isSingleBeam then
						emitSingleBeamPreview(emitter, getPreviewCache())
					elseif isStructured then
						local cache = workspace:FindFirstChild("VfxLab_Preview_Cache")
						if not cache then
							cache = Instance.new("Folder")
							cache.Name = "VfxLab_Preview_Cache"
							cache.Parent = workspace
						end
						local handle = emitStructuredPreview(emitter, cache, amount)
						if handle then previewCleanup:Add(handle, "Stop") end
					else
						for _ = 1, amount do
							EmitController.SpawnMeshParticle(emitter)
						end
					end
				end

				local loopDelay = EmitterManager.GetSetting(emitter, "LoopDelay", 0)
				if loopDelay > 0 then
					if not loopTimers[emitter] then loopTimers[emitter] = 0 end
					loopTimers[emitter] = loopTimers[emitter] - dt
					if loopTimers[emitter] <= 0 then
						loopTimers[emitter] = loopDelay
						emitAmount(EmitterManager.GetSetting(emitter, "EmitCount", 1))
					end
				else
					local rate = EmitterManager.GetSetting(emitter, "Rate", isLightning and 2 or 20)
					if not activeSpawners[emitter] then activeSpawners[emitter] = 0 end
					activeSpawners[emitter] = activeSpawners[emitter] + (rate * dt)
					while activeSpawners[emitter] >= 1 do
						activeSpawners[emitter] = activeSpawners[emitter] - 1
						emitAmount(1)
					end
				end
			else
				activeSpawners[emitter] = 0
				loopTimers[emitter] = nil
			end
		end
	end
	for emitter in pairs(beamTrailLoops) do
		if not liveBeamTrails[emitter] or not emitter.Parent then
			stopBeamTrailLoop(emitter)
		end
	end
end))

function EmitController.Emit(overrideAmount)
	for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
		local emitOk, emitErr = pcall(function()
		local delayTime = EmitterManager.GetSetting(emitter, "EmitDelay", 0)
		local targetAmount = overrideAmount or EmitterManager.GetSetting(emitter, "EmitCount", 1)

		local function triggerVFX()
			if emitter:GetAttribute("Debris_Enabled") and RockModule then
				local rings = emitter:GetAttribute("Debris_Rings") or 3
				local amount = emitter:GetAttribute("Debris_Amount") or 8
				local sizeMult = emitter:GetAttribute("Debris_SizeMult") or 0.43
				local baseSize = emitter:GetAttribute("Debris_Size") or 0.7

				local startPos = Vector3.zero
				if emitter:IsA("BasePart") then
					startPos = emitter.Position
				elseif emitter:IsA("Model") and emitter.PrimaryPart then
					startPos = emitter.PrimaryPart.Position
				else
					local childPart = emitter:FindFirstChildWhichIsA("BasePart", true)
					if childPart then startPos = childPart.Position end
				end

				for i = 1, rings do
					RockModule.GroundCrater({
						Seed = math.random(1, 1000000000),
						Start = startPos + Vector3.new(0, 0.1, 0),
						End = Vector3.new(0, -14, 0),
						Amount = amount + (i / 2),
						NoSound = emitter:GetAttribute("Debris_NoSound"),
						NoSmoke = emitter:GetAttribute("Debris_NoSmoke"),
						NoDebris = emitter:GetAttribute("Debris_NoDebris"),
						SizeMult = sizeMult * i,
						Size = baseSize * i,
					})
				end
			end

			local isScreen = emitter:GetAttribute("IsScreenFX")
			if not isScreen and emitter.Parent then
				isScreen = emitter.Parent:GetAttribute("IsScreenFX")
			end

			PlayScreenEffects(emitter, true)

			if EmitterManager.IsLightningEmitter(emitter) then
				emitLightningPreview(emitter, getPreviewCache(), targetAmount)
				local boltDuration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
				if boltDuration > 0 then
					local interval = tonumber(EmitterManager.GetSetting(emitter, "LightningLifetime", 0.6)) or 0.6
					if interval <= 0 then interval = 0.6 end
					task.spawn(function()
						local deadline = os.clock() + boltDuration
						while os.clock() < deadline and emitter.Parent do
							task.wait(interval)
							if os.clock() >= deadline or not emitter.Parent then break end
							pcall(emitLightningPreview, emitter, getPreviewCache(), targetAmount)
						end
					end)
				end
			elseif EmitterManager.IsSingleBeamEmitter(emitter) then
				emitSingleBeamPreview(emitter, getPreviewCache())
				local beamDuration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
				if beamDuration > 0 then
					task.spawn(function()
						local deadline = os.clock() + beamDuration
						while os.clock() < deadline and emitter.Parent do
							task.wait(0.5)
							if os.clock() >= deadline or not emitter.Parent then break end
							pcall(emitSingleBeamPreview, emitter, getPreviewCache())
						end
					end)
				end
			elseif emitter:IsA("Beam") or emitter:IsA("Trail") then
				local cacheFolder = workspace:FindFirstChild("VfxLab_Preview_Cache")
				if not cacheFolder then
					cacheFolder = Instance.new("Folder")
					cacheFolder.Name = "VfxLab_Preview_Cache"
					cacheFolder.Parent = workspace
				end
				local attachment = emitter.Attachment0 or emitter.Attachment1
				local baseCFrame = attachment and attachment.WorldCFrame or CFrame.new()
				local runtime = BeamTrailRuntime.Create(emitter, baseCFrame, cacheFolder, baseCFrame)
				runtime:Emit()
				previewCleanup:Add(runtime, "Stop")
				local beamDuration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
				if beamDuration > 0 then
					local wasEnabled = emitter.Enabled
					emitter.Enabled = true
					task.delay(beamDuration, function()
						if emitter.Parent then emitter.Enabled = wasEnabled end
					end)
				end
			elseif emitter:IsA("ParticleEmitter") then
				if isScreen then
					local cacheFolder = workspace:FindFirstChild("VfxLab_Preview_Cache")
					if not cacheFolder then 
						cacheFolder = Instance.new("Folder")
						cacheFolder.Name = "VfxLab_Preview_Cache"
						cacheFolder.Parent = workspace 
					end

					local hostName = "ScreenFX_" .. emitter.Name
					local oldHost = cacheFolder:FindFirstChild(hostName)
					if oldHost then oldHost:Destroy() end

					local screenPart = Instance.new("Part")
					screenPart.Name = hostName
					screenPart.Transparency = 1
					screenPart.Anchored = true
					screenPart.CanCollide = false
					screenPart.Locked = true 
					screenPart.CanQuery = false 

					screenPart.Size = Vector3.new(16, 9, 0.1) 
					screenPart.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -2.5)
					screenPart.Parent = cacheFolder

					local targetParent = screenPart

					if emitter.Parent and emitter.Parent:IsA("Attachment") then
						local attClone = emitter.Parent:Clone()
						attClone:ClearAllChildren()
						attClone.Parent = screenPart
						targetParent = attClone
					end

					local clone = emitter:Clone()
					clone.Parent = targetParent

					if emitter.Enabled then
						clone.Enabled = true
					else
						clone.Enabled = false 
						clone:Emit(targetAmount)
					end

					local conn
					conn = RunService.RenderStepped:Connect(function()
						if screenPart.Parent then
							screenPart.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -2.5)
						else
							conn:Disconnect()
						end
					end)

					if not emitter.Enabled then
						task.delay(clone.Lifetime.Max + 0.5, function()
							if conn then conn:Disconnect() end
							if screenPart then screenPart:Destroy() end
						end)
					end
			else
				emitter:SetAttribute("EmitCount", targetAmount)
				local duration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
				if duration > 0 then
					local wasEnabled = emitter.Enabled
					emitter.Enabled = true
					emitter:Emit(targetAmount)
					task.delay(duration, function()
						if emitter.Parent then emitter.Enabled = wasEnabled end
					end)
				else
					emitter:Emit(targetAmount)
				end
			end
			elseif emitter:GetAttribute("IsCraterDebris") then
				spawnCraterDebris(emitter)
			elseif StructuredRuntime.IsStructured(emitter) then
				local cacheFolder = workspace:FindFirstChild("VfxLab_Preview_Cache")
				if not cacheFolder then
					cacheFolder = Instance.new("Folder")
					cacheFolder.Name = "VfxLab_Preview_Cache"
					cacheFolder.Parent = workspace
				end
				local handle = emitStructuredPreview(emitter, cacheFolder, targetAmount)
				if handle then
					previewCleanup:Add(handle, "Stop")
					local structDuration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
					if structDuration > 0 then
						task.delay(structDuration, function()
							pcall(function() handle:Stop() end)
						end)
					end
				end
			elseif (emitter:IsA("Folder") or emitter:IsA("Model")) and emitter:GetAttribute("IsMeshEmitter") then
				for _ = 1, targetAmount do EmitController.SpawnMeshParticle(emitter) end
				local meshDuration = tonumber(EmitterManager.GetSetting(emitter, "EffectDuration", 0)) or 0
				if meshDuration > 0 then
					task.spawn(function()
						local deadline = os.clock() + meshDuration
						while os.clock() < deadline and emitter.Parent do
							task.wait(0.2)
							if os.clock() >= deadline or not emitter.Parent then break end
							pcall(EmitController.SpawnMeshParticle, emitter)
						end
					end)
				end
			end
		end

		local structuredOwnsDelay = StructuredRuntime.IsStructured(emitter)
			if delayTime > 0 and not structuredOwnsDelay then
				task.delay(delayTime, triggerVFX)
			else
				triggerVFX()
			end
		end)
		if not emitOk then
			warn("[VfxLab] Emit error: " .. tostring(emitErr))
		end
	end
end

function EmitController.Shutdown()
	if previewCleanup and not previewCleanup:IsDestroyed() then
		pcall(function() previewCleanup:Destroy() end)
	end
	_G.VfxLab_Preview_Loop = nil
	table.clear(activeSpawners)
	table.clear(loopTimers)
	table.clear(beamTrailLoops)
	pcall(function() StructuredRuntime.StopAll() end)
	pcall(function() StructuredRuntime.ClearCaches() end)
	pcall(function() EmitController.ClearVisualizer() end)
	pcall(function() EmitController.ClearCache() end)
	pcall(function() EmitController.StopScreenEffects() end)
end

return EmitController
