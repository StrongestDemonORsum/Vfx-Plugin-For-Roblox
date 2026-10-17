-- VfxLab ToolsPanel (Vide): creation actions + quick values + path view.
-- Same behavior as before: convert mesh/beam/lightning/trail, quick
-- values, texture preload, beam/trail path visualizer toggle.
local Selection = game:GetService("Selection")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local EmitController = require(script.Parent.Parent.Engine.EmitController)
local TexturePreloader = require(script.Parent.Parent.Engine.Assets.VFXPlayer.Runtime.TexturePreloader)
local StructuredRuntime = require(script.Parent.Parent.Engine.Assets.VFXPlayer.StructuredRuntime)

local ToolsPanel = {}

local function quickRow(content, order, labelText, initial, onApply)
	local row, holder = Kit.Row(content, labelText, order)
	row.Name = "Quick_" .. labelText
	local box = Kit.TextInput(holder, {
		Size = UDim2.new(1, 0, 1, -6),
		Position = UDim2.new(0, 0, 0, 3),
		Text = initial,
		TextSize = 12,
		OnFocusLost = function(text)
			onApply(text)
			ToolsPanel.UpdateUI()
		end,
	})
	return box
end

-- Returns { Window, Destroy }. UpdateUI refreshes target/visibility/values.
function ToolsPanel.Create(parentGui)
	local refs = {}
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabTools",
			Id = "tools",
			Title = "Tools",
			Subtitle = "Create emitters, then preview",
			Size = UDim2.fromOffset(224, 430),
			Position = UDim2.new(0, 60, 0.5, -215),
		})
		refs.window = built.Frame
		refs.content = built.Content
		refs.target = Kit.Label(built.Content, "No selection", 12, Theme.SubText())
		refs.target.LayoutOrder = nextOrder()
		refs.target.Size = UDim2.new(1, 0, 0, 18)
		refs.target.Name = "Target"
		local actionSection = Kit.Section(built.Content, "Create", nextOrder())
		refs.convertMesh = Kit.Button(actionSection, {
			Text = "+ Mesh Single State",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			OnClick = function()
				local part = EmitterManager.CurrentParts[1]
				if part then EmitterManager.ConvertToMeshEmitter(part) end
			end,
		})
		refs.convertAnim = Kit.Button(actionSection, {
			Text = "+ Mesh Start / End",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 2,
			OnClick = function()
				local part = EmitterManager.CurrentParts[1]
				if part then EmitterManager.ConvertToStructuredMeshEmitter(part) end
			end,
		})
		refs.beamBtn = Kit.Button(actionSection, {
			Text = "+ Beam",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 3,
			OnClick = function()
				local made, reason = EmitterManager.CreateStructuredBeam()
				if not made and refs.target then
					refs.target.Text = tostring(reason or "Cannot create beam")
				end
			end,
		})
		refs.boltBtn = Kit.Button(actionSection, {
			Text = "+ Lightning",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 4,
			OnClick = function()
				local made, reason = EmitterManager.CreateLightningEmitter()
				if not made and refs.target then
					refs.target.Text = tostring(reason or "Cannot create lightning")
				end
			end,
		})
		refs.trailBtn = Kit.Button(actionSection, {
			Text = "+ Trail (bezier)",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 5,
			OnClick = function()
				local made, reason = EmitterManager.CreateBezierTrail()
				if not made and refs.target then
					refs.target.Text = tostring(reason or "Cannot create trail")
				end
			end,
		})
		local quickSection = Kit.Section(built.Content, "Quick values", nextOrder())
		refs.countBox = quickRow(quickSection, 1, "Emit", "1", function(text)
			EmitterManager.ApplySmartProperty("EmitCount", text)
		end)
		refs.delayBox = quickRow(quickSection, 2, "Emit Delay", "0", function(text)
			EmitterManager.ApplySmartProperty("EmitDelay", text)
		end)
		refs.durationBox = quickRow(quickSection, 3, "Duration", "0.6", function(text)
			EmitterManager.ApplySmartProperty("EffectDuration", text)
		end)
		refs.loopDelayBox = quickRow(quickSection, 4, "Loop Delay", "0", function(text)
			EmitterManager.ApplySmartProperty("LoopDelay", text)
		end)
		local viewSection = Kit.Section(built.Content, "View", nextOrder())
		refs.pathsOn = Vide.source(false)
		Kit.Button(viewSection, {
			Text = function() return refs.pathsOn() and "Paths: ON" or "Paths: OFF" end,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 1,
			OnClick = function()
				local next = not refs.pathsOn()
				refs.pathsOn(next)
				_G.VfxLab_ShowBeams = next
				if not next then EmitController.ClearVisualizer() end
			end,
		})
		Kit.Button(viewSection, {
			Text = "Preload textures",
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 2,
			OnClick = function()
				local n = 0
				for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
					pcall(TexturePreloader.Load, emitter)
					n += 1
				end
				if refs.target then
					refs.target.Text = "Preloaded " .. n .. " emitter" .. (n == 1 and "" or "s")
				end
			end,
		})
		refs.quickSection = quickSection
		refs.actionSection = actionSection
	end)
	ToolsPanel._refs = refs
	ToolsPanel._stop = stop
	return refs.window
end

function ToolsPanel.Destroy()
	if ToolsPanel._stop then ToolsPanel._stop() ToolsPanel._stop = nil end
end

-- Mirrors the reference visibility rules.
function ToolsPanel.UpdateUI()
	local refs = ToolsPanel._refs
	if not refs or not refs.window then return end
	refs.target.Text = EmitterManager.TargetName or "No selection"
	local selected = Selection:Get()
	local parts, attachments, nativeBeam, nativeTrail = {}, {}, false, false
	for _, item in ipairs(selected) do
		if item:IsA("BasePart") and not StructuredRuntime.Contains(item) then
			table.insert(parts, item)
		end
		if item:IsA("Attachment") and not StructuredRuntime.Contains(item) then
			table.insert(attachments, item)
		end
		if item:IsA("Beam") then nativeBeam = true end
		if item:IsA("Trail") then nativeTrail = true end
	end
	local hasEmitter = #EmitterManager.CurrentEmitters > 0
	local hasPart = #parts > 0
	refs.convertMesh.Visible = hasPart
	refs.convertAnim.Visible = hasPart
	refs.beamBtn.Visible = hasPart or #attachments >= 2 or nativeBeam
	refs.boltBtn.Visible = hasPart or #attachments >= 2 or nativeBeam
	refs.trailBtn.Visible = hasPart or #attachments >= 2 or nativeBeam or nativeTrail
	refs.quickSection.Visible = hasEmitter
	if hasEmitter then
		local first = EmitterManager.CurrentEmitters[1]
		refs.countBox.Text = tostring(EmitterManager.GetSetting(first, "EmitCount", 1))
		refs.delayBox.Text = tostring(EmitterManager.GetSetting(first, "EmitDelay", 0))
		refs.durationBox.Text = tostring(EmitterManager.GetSetting(first, "EffectDuration", 0.6))
		refs.loopDelayBox.Text = tostring(EmitterManager.GetSetting(first, "LoopDelay", 0))
	end
end

return ToolsPanel
