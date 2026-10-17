-- VfxLab CopierPanel (Vide): copy/paste emitter properties between VFX.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local StructuredRuntime = require(script.Parent.Parent.Engine.Assets.VFXPlayer.StructuredRuntime)
local PropertiesPanel = require(script.Parent.PropertiesPanel)

local CopierPanel = {}

local ALL_PROPS = {
	"EmitCount", "EmitDelay", "LoopDelay", "Rate", "Lifetime", "Speed",
	"Size", "Size_X", "Size_Y", "Size_Z", "Squash",
	"MeshRotation", "MeshRotSpeed", "Drag", "SpreadAngle", "Acceleration",
	"OffsetStart", "OffsetEnd", "OffsetEasing", "EasingStyle",
	"HL_Enabled", "HL_FillColor", "HL_OutlineColor", "HL_FillTrans", "HL_OutTrans",
	"DecalTransStart", "DecalTransEnd", "DecalEasing",
	"Texture", "Orientation", "LightEmission", "LightInfluence",
	"Color", "Transparency", "Rotation", "RotSpeed", "Material",
	"Width0", "Width1", "CurveSize0", "CurveSize1",
	"TextureLength", "TextureSpeed", "TextureMode", "Segments",
	"FaceCamera", "ZOffset", "Brightness", "WidthScale", "MinLength",
	"TrailPathPreset", "TrailPathMode", "TrailPathCurve", "TrailPathRadius", "TrailPathTurns", "TrailPathHeight",
	"TrailPathCount", "TrailPathBurstCount", "TrailPathStagger", "TrailPathDuration", "TrailPathDurationJitter", "TrailPathSmoothness", "TrailPathReverse", "TrailPathPingPong",
	"TrailPathOffsetStart", "TrailPathControl1", "TrailPathControl2", "TrailPathOffsetEnd", "TrailPathWobble", "TrailPathWobbleSpeed",
	"TrailPathRotationStart", "TrailPathRotationEnd", "TrailPathRotationSpread", "TrailPathRotationSpeed", "TrailPathOrientationOffset", "TrailPathRandomRotation", "TrailPathFaceMotion",
	"LightningPartColor", "LightningHighlightColor",
	"LightningMode", "LightningBoltCount", "LightningSpread",
	"LightningCurveSize0", "LightningCurveSize1", "LightningSegments", "LightningFrequency",
	"LightningMinRadius", "LightningMaxRadius",
	"LightningThickness", "LightningMinThicknessMultiplier", "LightningMaxThicknessMultiplier",
	"LightningGlowThickness", "LightningTransparency", "LightningGlowTransparency", "LightningFlicker",
	"LightningLifetime", "LightningAnimationSpeed", "LightningRefreshRate", "LightningPulseSpeed",
	"LightningPulseLength", "LightningFadeLength", "LightningContractFrom",
	"LightningBranches", "LightningBranchChance", "LightningBranchLength", "LightningBranchSegments",
}

local function toggleMap(toggles)
	local map = {}
	for prop, get in pairs(toggles) do
		map[prop] = get()
	end
	return map
end

local function detectType()
	local emitter = EmitterManager.CurrentEmitters[1]
	if not emitter then return nil end
	if EmitterManager.IsLightningEmitter(emitter) then return "Lightning" end
	if EmitterManager.IsSingleBeamEmitter(emitter) then return "Beam" end
	if emitter:IsA("ParticleEmitter") then return "Particle" end
	if emitter:IsA("Beam") then return "Beam" end
	if emitter:IsA("Trail") then return "Trail" end
	if StructuredRuntime.IsStructured(emitter) then
		return EmitterManager.GetStructuredKind(emitter) == "Beam" and "Beam" or "Mesh"
	end
	return "Mesh"
end

-- Returns { Window, Destroy }. UpdateUI filters rows by emitter type.
function CopierPanel.Create(parentGui)
	local refs = { toggles = {} }
	local order = 0
	local stop = mount(function()
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabCopier",
			Id = "copier",
			Title = "COPIER",
			Subtitle = "Copy properties between VFX",
			Size = UDim2.fromOffset(264, 480),
			Position = UDim2.new(0, 300, 0.5, -240),
		})
		refs.window = built.Frame
		local content = built.Content
		Kit.Button(content, {
			Text = "Toggle all",
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = nextOrder(),
			OnClick = function()
				local anyOff = false
				for _, get in pairs(refs.toggles) do
					if not get() then anyOff = true break end
				end
				for _, set in pairs(refs.setters) do set(anyOff) end
				CopierPanel.UpdateUI()
			end,
		})
		refs.mode = "props"
		refs.curveToggles = {}
		refs.curveSetters = {}
		refs.curveBank = {}
		local CURVE_PROPS = {
			Particle = { "Color", "Transparency", "Size" },
			Beam = { "Color", "Transparency" },
			Trail = { "Color", "Transparency", "WidthScale" },
			Mesh = { "Color", "Transparency" },
			Lightning = {},
		}
		refs.curveProps = CURVE_PROPS
		local modeBtn = Kit.Button(content, {
			Text = "Mode: Props",
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = nextOrder(),
			OnClick = function()
				refs.mode = refs.mode == "props" and "curves" or "props"
				modeBtn.Text = refs.mode == "props" and "Mode: Props" or "Mode: Curves"
				CopierPanel.UpdateUI()
			end,
		})
		for _, prop in ipairs({ "Color", "Transparency", "Size", "WidthScale" }) do
			local row, holder = Kit.Row(content, prop .. " ~", nextOrder())
			row.Name = "Curve_" .. prop
			row.Visible = false
			local checked = Vide.source(false)
			refs.curveToggles[prop] = function() return checked() end
			refs.curveSetters[prop] = function(v) checked(v) end
			create "TextButton" {
				AutoButtonColor = false,
			BackgroundColor3 = Theme.Input(),
			BorderSizePixel = 0,
			FontFace = Theme.FontBold,
			Size = UDim2.new(1, 0, 1, -6),
			Position = UDim2.new(0, 0, 0, 3),
			Text = function() return checked() and "X" or "" end,
			TextColor3 = Theme.Text(),
			TextSize = 12,
			Parent = holder,
			create "UICorner" { CornerRadius = UDim.new(0, 5) },
			Activated = function() checked(not checked()) end,
			}
		end
		local function curveTarget(emitter, prop)
			return EmitterManager.GetPropertyTarget(emitter, prop) or emitter
		end
		local function readCurve(emitter, prop)
			local target = curveTarget(emitter, prop)
			local ok, cur = pcall(function() return target[prop] end)
			if ok and (typeof(cur) == "ColorSequence" or typeof(cur) == "NumberSequence" or typeof(cur) == "Color3") then
				return cur
			end
			local attr = target:GetAttribute(prop)
			if typeof(attr) == "ColorSequence" or typeof(attr) == "NumberSequence" or typeof(attr) == "Color3" then
				return attr
			end
			return nil
		end
		local function writeCurve(emitter, prop, value)
			local target = curveTarget(emitter, prop)
			local okNative, cur = pcall(function() return target[prop] end)
			if okNative and typeof(cur) == typeof(value) then
				target[prop] = value
				return
			end
			target:SetAttribute(prop, value)
		end
		refs.copyCurves = function()
			local first = EmitterManager.CurrentEmitters[1]
			if not first then return end
			for prop, get in pairs(refs.curveToggles) do
				if get() then
					refs.curveBank[prop] = readCurve(first, prop)
				end
			end
		end
		refs.pasteCurves = function()
			if #EmitterManager.CurrentEmitters == 0 then return false end
			local history = game:GetService("ChangeHistoryService")
			history:SetWaypoint("VfxLab Paste Curves - Before")
			for prop, get in pairs(refs.curveToggles) do
				local value = refs.curveBank[prop]
				if get() and value ~= nil then
					for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
						pcall(writeCurve, emitter, prop, value:Clone())
					end
				end
			end
			history:SetWaypoint("VfxLab Paste Curves")
			return true
		end
		for i, prop in ipairs(ALL_PROPS) do
			local row, holder = Kit.Row(content, prop, nextOrder())
			row.Name = "Copy_" .. prop
			row.Visible = false
			local checked = Vide.source(false)
			refs.toggles[prop] = function() return checked() end
			refs.setters = refs.setters or {}
			refs.setters[prop] = function(v) checked(v) end
			create "TextButton" {
				AutoButtonColor = false,
			BackgroundColor3 = Theme.Input(),
			BorderSizePixel = 0,
			FontFace = Theme.FontBold,
			Size = UDim2.new(1, 0, 1, -6),
			Position = UDim2.new(0, 0, 0, 3),
			Text = function() return checked() and "X" or "" end,
			TextColor3 = Theme.Text(),
			TextSize = 12,
			Parent = holder,
			create "UICorner" { CornerRadius = UDim.new(0, 5) },
			Activated = function() checked(not checked()) end,
			}
		end
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
			Text = "Copy",
			TextSize = 11,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 1,
			Primary = true,
			OnClick = function()
				if refs.mode == "curves" then refs.copyCurves()
				else EmitterManager.CopyProps(toggleMap(refs.toggles)) end
			end,
		})
		Kit.Button(actions, {
			Text = "Copy All",
			TextSize = 11,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 2,
			OnClick = function()
				if refs.mode == "curves" then
					for _, set in pairs(refs.curveSetters) do set(true) end
					refs.copyCurves()
				else
					for _, set in pairs(refs.setters) do set(true) end
					EmitterManager.CopyProps(toggleMap(refs.toggles))
				end
			end,
		})
		Kit.Button(actions, {
			Text = "Paste",
			TextSize = 11,
			Size = UDim2.new(0.33, -4, 1, 0),
			LayoutOrder = 3,
			Primary = true,
			OnClick = function()
				if refs.mode == "curves" then
					if refs.pasteCurves() then
						pcall(function() PropertiesPanel.UpdateUI() end)
					end
				elseif EmitterManager.PasteProps(toggleMap(refs.toggles)) then
					pcall(function() PropertiesPanel.UpdateUI() end)
				end
			end,
		})
	end)
	CopierPanel._refs = refs
	CopierPanel._stop = stop
	CopierPanel.UpdateUI()
	return { Window = refs.window, Destroy = stop }
end

function CopierPanel.Destroy()
	if CopierPanel._stop then CopierPanel._stop() CopierPanel._stop = nil end
end

function CopierPanel.UpdateUI()
	local refs = CopierPanel._refs
	if not refs or not refs.window then return end
	local kind = detectType()
	local lists = PropertiesPanel.TypeLists
	local list = kind and lists[kind] or nil
	local curveMode = refs.mode == "curves"
	for prop, _ in pairs(refs.toggles) do
		local row = refs.window:FindFirstChild("Copy_" .. prop, true)
		if row then
			row.Visible = not curveMode and list ~= nil and table.find(list, prop) ~= nil
		end
	end
	local curveList = kind and refs.curveProps and refs.curveProps[kind] or nil
	for prop, _ in pairs(refs.curveToggles or {}) do
		local row = refs.window:FindFirstChild("Curve_" .. prop, true)
		if row then
			row.Visible = curveMode and curveList ~= nil and table.find(curveList, prop) ~= nil
		end
	end
end

return CopierPanel
