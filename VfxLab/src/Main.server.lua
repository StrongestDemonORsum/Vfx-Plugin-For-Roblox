-- VfxLab Main: plugin entry. Toolbar button toggles a CoreGui workspace of
-- Vide windows (creation mode). Animation mode arrives in phase 2.
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Vide = require(script.Parent.Modules.vide)
local source = Vide.source
local Theme = require(script.Parent.Ui.Theme)
local Kit = require(script.Parent.Ui.Kit)
local Sidebar = require(script.Parent.Ui.Sidebar)
local ToolsPanel = require(script.Parent.Ui.ToolsPanel)
local PropertiesPanel = require(script.Parent.Ui.PropertiesPanel)
local SettingsPanel = require(script.Parent.Ui.SettingsPanel)
local Library = require(script.Parent.Ui.Library)
local EmitPopup = require(script.Parent.Ui.EmitPopup)
local Adder = require(script.Parent.Ui.Adder)
local ShifterPanel = require(script.Parent.Ui.ShifterPanel)
local UpdateLogPanel = require(script.Parent.Ui.UpdateLogPanel)
local FlipbookPanel = require(script.Parent.Ui.FlipbookPanel)
local AdjustPanel = require(script.Parent.Ui.AdjustPanel)
local CopierPanel = require(script.Parent.Ui.CopierPanel)
local CurvePanel = require(script.Parent.Ui.CurvePanel)
local ColorShiftPanel = require(script.Parent.Ui.ColorShiftPanel)
local ScreenFXPanel = require(script.Parent.Ui.ScreenFXPanel)
local DebrisPanel = require(script.Parent.Ui.DebrisPanel)
local EmitCodePanel = require(script.Parent.Ui.EmitCodePanel)
local SelectionManager = require(script.Parent.Ui.SelectionManager)
local EmitController = require(script.Parent.Engine.EmitController)
local EmitterManager = require(script.Parent.Engine.EmitterManager)
local PathVisualizer = require(script.Parent.Engine.PathVisualizer)
local VFXPlayer = require(script.Parent.Engine.Assets.VFXPlayer)
local PresetLibrary = require(script.Parent.Engine.Core.PresetLibrary)

local GUI_NAME = "VfxLab_CoreUI"
print("[VfxLab] v0.6 boot (Vide)")
local bootOk, bootErr = pcall(function()
Kit.SetPlugin(plugin)
FlipbookPanel.SetPlugin(plugin)
EmitCodePanel.SetPlugin(plugin)
local oldGui = CoreGui:FindFirstChild(GUI_NAME)
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.Parent = CoreGui

local mode = source("Creation")

local toolsUI = ToolsPanel.Create(screenGui)
local propsUI = PropertiesPanel.Create(screenGui).Window
local settingsUI = SettingsPanel.Create(screenGui, plugin).Window
local libraryUI = Library.Create(screenGui).Window
local adjustUI = AdjustPanel.Create(screenGui).Window
local copierUI = CopierPanel.Create(screenGui).Window
local curveUI = CurvePanel.Create(screenGui).Window
local colorUI = ColorShiftPanel.Create(screenGui).Window
local screenUI = ScreenFXPanel.Create(screenGui).Window
local debrisUI = DebrisPanel.Create(screenGui).Window
local emitCodeUI = EmitCodePanel.Create(screenGui).Window
local shifterUI = ShifterPanel.Create(screenGui).Window
local updlogUI = UpdateLogPanel.Create(screenGui).Window
local flipbookUI = FlipbookPanel.Create(screenGui).Window
SettingsPanel._openLog = UpdateLogPanel.Toggle

local animNote = Kit.Window(screenGui, {
	Name = "VfxLabAnimSoon",
	Title = "ANIMATION MODE",
	Subtitle = "Phase 2",
	Size = UDim2.fromOffset(300, 120),
	Position = UDim2.fromScale(0.5, 0.4),
})
local animLabel = Kit.Label(animNote.Content, "Keyframe timelines and playback live here soon. Creation mode is fully usable today.", 12, Theme.SubText())
animLabel.TextWrapped = true
animLabel.Size = UDim2.new(1, 0, 1, 0)
Kit.TogglePanel(animNote.Frame, false)

local creationWindows = { toolsUI, propsUI, settingsUI, libraryUI, adjustUI, copierUI, curveUI, colorUI, screenUI, debrisUI, emitCodeUI, shifterUI, updlogUI, flipbookUI }
local function setMode(next)
	mode(next)
	local isAnim = next == "Animation"
	for _, frame in ipairs(creationWindows) do
		if isAnim then frame.Visible = false end
	end
	Kit.TogglePanel(animNote.Frame, isAnim)
end

Sidebar.Create(screenGui, {
	Emit = function() EmitPopup.Toggle(screenGui) end,
	Properties = function() Kit.TogglePanel(propsUI, propsUI.Visible ~= true) end,
	Beam = function()
		toolsUI.Visible = true
		propsUI.Visible = true
	end,
	Library = function() Library.Open() end,
	Flips = function() FlipbookPanel.Toggle() end,
	Adjust = function() Kit.TogglePanel(adjustUI, adjustUI.Visible ~= true) end,
	Shift = function() Kit.TogglePanel(shifterUI, shifterUI.Visible ~= true) end,
	Copy = function() Kit.TogglePanel(copierUI, copierUI.Visible ~= true) end,
	Curve = function() Kit.TogglePanel(curveUI, curveUI.Visible ~= true) end,
	Color = function() ColorShiftPanel.Open() end,
	Screen = function() Kit.TogglePanel(screenUI, screenUI.Visible ~= true) end,
	Debris = function() Kit.TogglePanel(debrisUI, debrisUI.Visible ~= true) end,
	Settings = function() Kit.TogglePanel(settingsUI, settingsUI.Visible ~= true) end,
	Mode = setMode,
}, mode)

local toolbar = plugin:CreateToolbar("VfxLab")
-- No custom icon yet: an asset ID you don't own renders blank, so the
-- default plugin icon shows until you paste your own image ID here.
local toggleBtn = toolbar:CreateButton("VfxLab Editor", "Open the VfxLab creation workspace", "")

local isOpen = plugin:GetSetting("VfxLab_IsOpen")
if isOpen == nil then isOpen = false end
screenGui.Enabled = isOpen
toggleBtn:SetActive(isOpen)

toggleBtn.Click:Connect(function()
	isOpen = not isOpen
	screenGui.Enabled = isOpen
	toggleBtn:SetActive(isOpen)
	plugin:SetSetting("VfxLab_IsOpen", isOpen)
end)

	local emitShortcut = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isOpen or not screenGui.Enabled then return end
		if UserInputService:GetFocusedTextBox() then return end
		if mode() ~= "Creation" then return end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.R then
			EmitController.Emit()
		end
	end)
	local adderShortcut = Kit.OnKeybind({ "Backquote" }, function()
		if not isOpen or not screenGui.Enabled then return end
		if mode() ~= "Creation" then return end
		Adder.Toggle(screenGui)
	end)

SelectionManager.Init(toolsUI, propsUI)

local function withEmitter(effect, callback)
	local previousEmitters = EmitterManager.CurrentEmitters
	local previousParts = EmitterManager.CurrentParts
	local previousName = EmitterManager.TargetName
	EmitterManager.UpdateEmitters({ effect })
	local ok, result = pcall(callback)
	EmitterManager.CurrentEmitters = previousEmitters
	EmitterManager.CurrentParts = previousParts
	EmitterManager.TargetName = previousName
	if not ok then error(result) end
	return result
end

local studioAPI = {
	Version = 1,
	Curve = VFXPlayer.Curve,
	Tween = VFXPlayer.Tween,
	Bezier3D = VFXPlayer.Bezier3D,
	Flipbook = VFXPlayer.Flipbook,
	Lightning = VFXPlayer.Lightning,
	Rocks = VFXPlayer.Rocks,
	RotatingModel = VFXPlayer.RotatingModel,
	Presets = PresetLibrary,
}

function studioAPI.Emit(effect, target)
	return VFXPlayer.Emit(effect, target)
end

function studioAPI.CreateRuntime(effect, target)
	return VFXPlayer.Create(effect, target)
end

function studioAPI.Enable(effect, target)
	local handle = VFXPlayer.Create(effect, target)
	handle:Enable()
	return handle
end

function studioAPI.Disable(handle)
	if type(handle) == "table" and handle.Disable then handle:Disable() end
end

function studioAPI.Resize(effect, multiplier)
	return withEmitter(effect, function()
		return EmitterManager.ResizeVFX(multiplier)
	end)
end

function studioAPI.Retime(effect, multiplier)
	return withEmitter(effect, function()
		return EmitterManager.RetimeVFX(multiplier)
	end)
end

function studioAPI.Recolor(effect, config)
	return withEmitter(effect, function()
		return EmitterManager.RecolorVFX(config)
	end)
end

function studioAPI.ShowPaths(effect)
	return withEmitter(effect, function()
		PathVisualizer.Show(EmitterManager.CurrentEmitters)
	end)
end

function studioAPI.HidePaths()
	PathVisualizer.Clear()
end

function studioAPI.LoadTextures(effect)
	return VFXPlayer.LoadTextures(effect)
end

function studioAPI.ClearCaches(effect)
	return VFXPlayer.ClearCaches(effect)
end

function studioAPI.GetRuntimeStats()
	return VFXPlayer.GetRuntimeStats()
end

function studioAPI.StopScreenEffects()
	EmitController.StopScreenEffects()
	VFXPlayer.StopScreenEffects()
end

function studioAPI.ExportPreset(effect)
	return PresetLibrary.Encode(PresetLibrary.Capture(effect))
end

function studioAPI.ImportPreset(effect, json)
	ChangeHistoryService:SetWaypoint("VfxLab Import Preset")
	local applied = PresetLibrary.Apply(effect, PresetLibrary.Decode(json))
	ChangeHistoryService:SetWaypoint("VfxLab Import Preset Complete")
	return applied
end

function studioAPI.SavePreset(name, effect)
	assert(type(name) == "string" and name ~= "", "Preset name is required")
	local json = studioAPI.ExportPreset(effect)
	plugin:SetSetting("VfxLab_Preset_" .. name, json)
	local names = plugin:GetSetting("VfxLab_PresetNames") or {}
	if not table.find(names, name) then
		table.insert(names, name)
		table.sort(names)
		plugin:SetSetting("VfxLab_PresetNames", names)
	end
	return json
end

function studioAPI.LoadPreset(name, effect)
	local json = plugin:GetSetting("VfxLab_Preset_" .. tostring(name))
	assert(type(json) == "string", "VfxLab preset not found: " .. tostring(name))
	return studioAPI.ImportPreset(effect, json)
end

function studioAPI.ListPresets()
	local names = plugin:GetSetting("VfxLab_PresetNames") or {}
	return table.clone(names)
end

function studioAPI.DeletePreset(name)
	plugin:SetSetting("VfxLab_Preset_" .. tostring(name), nil)
	local names = plugin:GetSetting("VfxLab_PresetNames") or {}
	local index = table.find(names, name)
	if index then table.remove(names, index) end
	plugin:SetSetting("VfxLab_PresetNames", names)
end

shared.vfxlab = studioAPI

plugin.Unloading:Connect(function()
	if emitShortcut and emitShortcut.Connected then emitShortcut:Disconnect() end
	if adderShortcut then adderShortcut() end
	pcall(function() Adder.Close() end)
	pcall(function() PathVisualizer.Clear() end)
	pcall(function() EmitController.Shutdown() end)
	pcall(function() studioAPI.StopScreenEffects() end)
	pcall(function() VFXPlayer.ClearCaches() end)
	if shared.vfxlab == studioAPI then shared.vfxlab = nil end
	if screenGui then screenGui:Destroy() end
end)
end)
if not bootOk then
	warn("[VfxLab] Boot error: " .. tostring(bootErr))
end
