-- VfxLab EmitCodePanel: BetterVfx EmitCode parity. Bracket-safe ancestry
-- paths, optional service imports (Settings > Emit Code), mono textbox,
-- and a runtime-installer button (EmitImportPanel).
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local source = Vide.source
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local SettingsPanel = require(script.Parent.SettingsPanel)
local EmitImportPanel = require(script.Parent.EmitImportPanel)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local Selection = game:GetService("Selection")

local EmitCodePanel = {}
local pluginHandle = nil

function EmitCodePanel.SetPlugin(plugin)
	pluginHandle = plugin
end

local function pathToken(name)
	if name:match("^[%a_][%w_]*$") then
		return "." .. name
	end
	return "[\"" .. name:gsub("\"", "\\\"") .. "\"]"
end

local function targetPath()
	local selected = Selection:Get()
	if #selected == 0 then return "workspace" end
	local current = selected[1]
	if current == workspace then return "workspace" end
	local parts = {}
	while current and current ~= workspace and current ~= game do
		table.insert(parts, 1, current)
		current = current.Parent
	end
	if #parts == 0 then return "workspace" end
	local service = parts[1]
	local svcName = service.ClassName
	local path
	if SettingsPanel.Get(pluginHandle, "ImportWorkspace") and service == workspace then
		path = "workspace"
	else
		path = "game:GetService(\"" .. svcName .. "\")"
		for i = 2, #parts do
			path ..= pathToken(parts[i].Name)
		end
		return path
	end
	for i = 2, #parts do
		path ..= pathToken(parts[i].Name)
	end
	return path
end

local function generateCode()
	local first = EmitterManager.CurrentEmitters[1]
	if not first then
		return "-- select an emitter to generate code"
	end
	local lines = {}
	if SettingsPanel.Get(pluginHandle, "ImportServices") then
		table.insert(lines, "local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")")
	end
	table.insert(lines, "local VfxLabRuntime = require(ReplicatedStorage:WaitForChild(\"VfxLabRuntime\"))")
	table.insert(lines, "")
	table.insert(lines, "VfxLabRuntime.Get().Emit(" .. targetPath() .. ")")
	return table.concat(lines, "\n")
end

function EmitCodePanel.Create(parentGui)
	local refs = {}
	local codeText = source(generateCode())
	local stop = mount(function()
		local built = Kit.Window(parentGui, {
			Name = "VfxLabEmitCode",
			Id = "emitcode",
			Title = "Emit code",
			Size = UDim2.fromOffset(400, 120),
			Position = UDim2.new(0, 10, 1, -140),
		})
		refs.window = built.Frame
		local content = built.Content
		local codeBox = create "TextBox" {
			BackgroundColor3 = Theme.Input(),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Enum.Font.Code,
			MultiLine = true,
			Size = UDim2.new(1, 0, 1, -36),
			Position = UDim2.fromOffset(0, 0),
			Text = function() return codeText() end,
			TextColor3 = Theme.Text(),
			TextEditable = false,
			TextSize = Theme.TextSizes.Mini,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = content,
			create "UICorner" { CornerRadius = UDim.new(0, 4) },
			create "UIPadding" {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			},
		}
		refs.codeBox = codeBox
		Kit.Button(content, {
			Text = "Install runtime module",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 2,
			OnClick = function() EmitImportPanel.Open(parentGui) end,
		})
		Selection.SelectionChanged:Connect(function()
			codeText(generateCode())
		end)
	end)
	EmitCodePanel._refs = refs
	EmitCodePanel._stop = stop
	return { Window = refs.window, Destroy = stop }
end

function EmitCodePanel.Open()
	local refs = EmitCodePanel._refs
	if not refs or not refs.window then return end
	Kit.TogglePanel(refs.window, not refs.window.Visible)
end

function EmitCodePanel.Destroy()
	if EmitCodePanel._stop then EmitCodePanel._stop() EmitCodePanel._stop = nil end
end

return EmitCodePanel
