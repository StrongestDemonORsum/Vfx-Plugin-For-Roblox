-- VfxLab SelectionManager: selection -> emitters -> panels.
-- Same visibility rules as the reference: VFX selection shows tools and
-- properties; raw parts/attachments show tools only (creation targets).
local Selection = game:GetService("Selection")
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local ToolsPanel = require(script.Parent.ToolsPanel)
local PropertiesPanel = require(script.Parent.PropertiesPanel)
local StructuredRuntime = require(script.Parent.Parent.Engine.Assets.VFXPlayer.StructuredRuntime)

local SelectionManager = {}

function SelectionManager.Init(toolsUI, propsUI)
	local function refresh()
		local selected = Selection:Get()
		EmitterManager.UpdateEmitters(selected)
		ToolsPanel.UpdateUI()
		PropertiesPanel.UpdateUI()
		local isVFX = #EmitterManager.CurrentEmitters > 0
		local rawPartCount, rawAttachmentCount = 0, 0
		for _, item in ipairs(selected) do
			if item:IsA("BasePart") and not StructuredRuntime.Contains(item) then
				rawPartCount += 1
			end
			if item:IsA("Attachment") and not StructuredRuntime.Contains(item) then
				rawAttachmentCount += 1
			end
		end
		local isRawPart = rawPartCount == 1 and #selected == 1
		local isBeamSetup = rawPartCount >= 1 or rawAttachmentCount >= 2
		if isVFX then
			if toolsUI then toolsUI.Visible = true end
			if propsUI then propsUI.Visible = true end
		elseif isRawPart or isBeamSetup then
			if toolsUI then toolsUI.Visible = true end
			if propsUI then propsUI.Visible = false end
		else
			if toolsUI then toolsUI.Visible = false end
			if propsUI then propsUI.Visible = false end
		end
	end
	Selection.SelectionChanged:Connect(refresh)
	refresh()
end

return SelectionManager
