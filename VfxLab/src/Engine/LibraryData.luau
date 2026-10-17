local LibraryData = {}

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local EmitterManager = require(script.Parent.EmitterManager)
local StructuredRuntime = require(script.Parent.Assets.VFXPlayer.StructuredRuntime)

local function templatesRoot()
	local assets = script.Parent:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("Templates")
end

local function cleanPath(path)
	return path:gsub("^Templates/", "")
end

local function containsVisual(instance)
	if StructuredRuntime.IsStructured(instance) then return true end
	if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then return true end
	if instance:IsA("BasePart") then
		return instance:FindFirstChildWhichIsA("ParticleEmitter", true) ~= nil
			or instance:FindFirstChildWhichIsA("Beam", true) ~= nil
			or instance:FindFirstChildWhichIsA("Trail", true) ~= nil
			or instance:FindFirstChildWhichIsA("Decal", true) ~= nil
			or instance:FindFirstChildWhichIsA("Texture", true) ~= nil
	end
	return false
end

function LibraryData.GetTemplates()
	local root = templatesRoot()
	if not root then return {} end
	local result = {}
	local function visit(instance, category, path)
		if containsVisual(instance) then
			table.insert(result, {
				Source = instance,
				Name = instance.Name,
				Category = category,
				Path = cleanPath(path),
			})
			return
		end
		for _, child in ipairs(instance:GetChildren()) do
			visit(child, category, path .. "/" .. child.Name)
		end
	end
	for _, categoryFolder in ipairs(root:GetChildren()) do
		for _, child in ipairs(categoryFolder:GetChildren()) do
			visit(child, categoryFolder.Name, categoryFolder.Name .. "/" .. child.Name)
		end
	end
	table.sort(result, function(a, b)
		if a.Category == b.Category then return a.Path < b.Path end
		return a.Category < b.Category
	end)
	local nameCounts = {}
	for _, item in ipairs(result) do
		local key = item.Category .. "/" .. item.Name
		nameCounts[key] = (nameCounts[key] or 0) + 1
	end
	local seen = {}
	for _, item in ipairs(result) do
		local key = item.Category .. "/" .. item.Name
		if nameCounts[key] > 1 then
			seen[key] = (seen[key] or 0) + 1
			item.DisplayName = item.Name .. " " .. string.format("%02d", seen[key])
		else
			item.DisplayName = item.Name
		end
	end
	return result
end

local function setPreviewState(clone)
	local endState = clone:FindFirstChild("End")
	if endState then
		local targets = {endState}
		for _, descendant in ipairs(endState:GetDescendants()) do table.insert(targets, descendant) end
		for _, instance in ipairs(targets) do
			if instance:IsA("BasePart") then
				instance.Transparency = 1
				instance.LocalTransparencyModifier = 1
			elseif instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
				instance.Enabled = false
			end
		end
	end
	for _, instance in ipairs(clone:GetDescendants()) do
		if instance:IsA("LuaSourceContainer") then
			instance:Destroy()
		elseif instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
		elseif instance:IsA("Beam") or instance:IsA("ParticleEmitter") then
			if not (endState and instance:IsDescendantOf(endState)) then instance.Enabled = true end
		end
	end
end

local function rootBounds(instance)
	if instance:IsA("Model") then
		local ok, cf, size = pcall(instance.GetBoundingBox, instance)
		if ok then return cf, size end
	elseif instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	end
	local parts = {}
	if instance:IsA("BasePart") then table.insert(parts, instance) end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then table.insert(parts, descendant) end
	end
	if #parts == 0 then return CFrame.new(), Vector3.new(4, 4, 4) end
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ipairs(parts) do
		local half = part.Size * 0.5
		minimum = Vector3.new(
			math.min(minimum.X, part.Position.X - half.X),
			math.min(minimum.Y, part.Position.Y - half.Y),
			math.min(minimum.Z, part.Position.Z - half.Z)
		)
		maximum = Vector3.new(
			math.max(maximum.X, part.Position.X + half.X),
			math.max(maximum.Y, part.Position.Y + half.Y),
			math.max(maximum.Z, part.Position.Z + half.Z)
		)
	end
	local size = maximum - minimum
	return CFrame.new((minimum + maximum) * 0.5), size
end

function LibraryData.BuildViewport(viewport, source)
	for _, child in ipairs(viewport:GetChildren()) do
		if child:IsA("WorldModel") or child:IsA("Camera") then child:Destroy() end
	end
	viewport.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
	viewport.Ambient = Color3.fromRGB(130, 135, 150)
	viewport.LightColor = Color3.fromRGB(235, 240, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local world = Instance.new("WorldModel")
	world.Name = "PreviewWorld"
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 32
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local ok, clone = pcall(source.Clone, source)
	if not ok or not clone then return false end
	setPreviewState(clone)
	clone.Parent = world
	if clone:IsA("Model") then
		pcall(clone.PivotTo, clone, CFrame.new())
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new()
	end

	local cf, size = rootBounds(clone)
	local extent = math.max(size.X, size.Y, size.Z, 1)
	local center = cf.Position
	local direction = Vector3.new(0.85, 0.55, 1).Unit
	local distance = extent * 2.05 + 2
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
	camera.Focus = CFrame.new(center)
	return true
end

local function targetCFrame()
	local selected = Selection:Get()
	local first = selected[1]
	if first then
		if first:IsA("Attachment") then return first.WorldCFrame end
		if first:IsA("BasePart") then return first.CFrame * CFrame.new(0, first.Size.Y * 0.5 + 2, 0) end
		if first:IsA("Model") then return first:GetPivot() * CFrame.new(0, 3, 0) end
	end
	local camera = workspace.CurrentCamera
	if camera then
		local focus = camera.Focus
		if focus.Position.Magnitude > 0 then return focus end
		return camera.CFrame * CFrame.new(0, 0, -12)
	end
	return CFrame.new()
end

function LibraryData.InsertTemplate(item)
	if not item or not item.Source or not item.Source.Parent then return nil, "Template is missing" end
	ChangeHistoryService:SetWaypoint("VisualX Insert Template - Before")
	local clone = item.Source:Clone()
	clone.Name = item.DisplayName or item.Name
	clone.Parent = workspace
	local target = targetCFrame()
	if clone:IsA("Model") then
		clone:PivotTo(target)
	elseif clone:IsA("BasePart") then
		clone.CFrame = target
	end
	Selection:Set({clone})
	ChangeHistoryService:SetWaypoint("VisualX Insert Template")
	return clone
end

local function textureValue(instance)
	if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
		return instance.Texture
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		return instance.Texture
	elseif instance:IsA("MeshPart") then
		return instance.TextureID
	elseif instance:IsA("SpecialMesh") then
		return instance.TextureId
	end
	return nil
end

function LibraryData.GetTextures()
	local root = templatesRoot()
	if not root then return {} end
	local result, seen = {}, {}
	local objects = {root}
	for _, descendant in ipairs(root:GetDescendants()) do table.insert(objects, descendant) end
	for _, instance in ipairs(objects) do
		local asset = textureValue(instance)
		if type(asset) == "string" and asset ~= "" then
			local id = asset:match("%d+")
			local key = id or asset
			if not seen[key] then
				seen[key] = true
				local relative = instance:GetFullName():match("Templates%.(.+)$") or instance:GetFullName()
				local kind = instance.ClassName
				table.insert(result, {
					Asset = id and ("rbxassetid://" .. id) or asset,
					Id = id or asset,
					Name = instance.Name,
					Kind = kind,
					Path = relative,
				})
			end
		end
	end
	table.sort(result, function(a, b)
		if a.Kind == b.Kind then return tostring(a.Id) < tostring(b.Id) end
		return a.Kind < b.Kind
	end)
	return result
end

local function applyTextureObject(instance, asset)
	if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
		or instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Texture = asset
		return 1
	elseif instance:IsA("MeshPart") then
		instance.TextureID = asset
		return 1
	elseif instance:IsA("SpecialMesh") then
		instance.TextureId = asset
		return 1
	end
	return 0
end

local function applyTree(root, asset)
	if not root then return 0 end
	local count = applyTextureObject(root, asset)
	for _, descendant in ipairs(root:GetDescendants()) do
		count += applyTextureObject(descendant, asset)
	end
	return count
end

function LibraryData.ApplyTexture(asset)
	if type(asset) ~= "string" or asset == "" then return 0 end
	ChangeHistoryService:SetWaypoint("VisualX Apply Texture - Before")
	local changed = 0
	local current = EmitterManager.CurrentEmitters
	if #current > 0 then
		for _, emitter in ipairs(current) do
			if EmitterManager.IsSingleBeamEmitter(emitter) then
				changed += applyTree(EmitterManager.GetPropertyTarget(emitter, "Texture"), asset)
			elseif EmitterManager.IsStructuredEmitter(emitter) then
				changed += applyTree(EmitterManager.GetStructuredStateObject(emitter), asset)
			else
				changed += applyTree(emitter, asset)
			end
		end
		pcall(function() EmitterManager.ApplySmartProperty("Texture", asset) end)
	else
		for _, selected in ipairs(Selection:Get()) do changed += applyTree(selected, asset) end
	end
	if changed > 0 then
		pcall(function()
			local PropertiesPanel = require(script.Parent.Parent.Ui.PropertiesPanel)
			PropertiesPanel.UpdateUI()
		end)
		ChangeHistoryService:SetWaypoint("VisualX Apply Texture")
	end
	return changed
end

return LibraryData
