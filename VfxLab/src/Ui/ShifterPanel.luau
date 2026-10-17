-- VfxLab ShifterPanel (Vide): BetterVfx PropertyShifter parity.
-- Amount field + ×/+/−/÷ op buttons + scrollable selectable numeric-prop
-- list. All props are static values + imperative updates (Vide-safe).
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local StructuredRuntime = require(script.Parent.Parent.Engine.Assets.VFXPlayer.StructuredRuntime)
local PropertiesPanel = require(script.Parent.PropertiesPanel)

local ShifterPanel = {}
local refs = {}

-- Numeric-shiftable props: slider ranges + sequences/vectors/colors.
local NUMERIC_EXTRA = {
	Size = true, Squash = true, Acceleration = true, Color = true,
}

local function numericPropsFor(list)
	local out = {}
	for _, prop in ipairs(list) do
		if PropertiesPanel.SliderRanges[prop] or NUMERIC_EXTRA[prop] then
			table.insert(out, prop)
		end
	end
	return out
end

local function detectList()
	local emitter = EmitterManager.CurrentEmitters[1]
	if not emitter then return nil end
	if EmitterManager.IsLightningEmitter(emitter) then
		return PropertiesPanel.TypeLists.Lightning
	end
	if EmitterManager.IsSingleBeamEmitter(emitter) then
		return PropertiesPanel.TypeLists.Beam
	end
	if emitter:IsA("ParticleEmitter") then
		return PropertiesPanel.TypeLists.Particle
	end
	if emitter:IsA("Beam") then
		return PropertiesPanel.TypeLists.Beam
	end
	if emitter:IsA("Trail") then
		return PropertiesPanel.TypeLists.Trail
	end
	if StructuredRuntime.IsStructured(emitter) then
		return EmitterManager.GetStructuredKind(emitter) == "Beam"
			and PropertiesPanel.TypeLists.Beam
			or PropertiesPanel.TypeLists.Mesh
	end
	return PropertiesPanel.TypeLists.Mesh
end

local function applyOp(op)
	local amount = tonumber(refs.amountBox and refs.amountBox.Text or nil)
	if not amount then
		if refs.status then refs.status.Text = "Enter an amount first" end
		return
	end
	local count, picked = 0, 0
	for prop, on in pairs(refs.selected) do
		if on then
			picked += 1
			if EmitterManager.ShiftNumeric(prop, op, amount) then count += 1 end
		end
	end
	if refs.status then
		refs.status.Text = picked == 0 and "Select props below"
			or ("Shifted " .. count .. " prop" .. (count == 1 and "" or "s"))
	end
	pcall(PropertiesPanel.UpdateUI)
	ShifterPanel.UpdateUI()
end

function ShifterPanel.Create(parentGui)
	refs = { selected = {} }
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local built = Kit.Window(parentGui, {
			Name = "VfxLabShifter",
			Title = "SHIFTER",
			Subtitle = "Arithmetic prop ops",
			Size = UDim2.fromOffset(248, 480),
			Position = UDim2.new(0, 300, 0.5, -240),
			Id = "shifter",
		})
		refs.window = built.Frame
		local content = built.Content
		refs.amountBox = Kit.TextInput(content, {
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = nextOrder(),
			Text = "",
			TextSize = Theme.TextSizes.Mini,
			Placeholder = "amount",
		})
		local ops = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 24),
			Parent = content,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = UDim.new(0, Theme.Padding.Side),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		local opDefs = { { "×", "mul" }, { "+", "add" }, { "−", "sub" }, { "÷", "div" } }
		for i, def in ipairs(opDefs) do
			Kit.Button(ops, {
				Text = def[1],
				TextSize = Theme.TextSizes.Special,
				Size = UDim2.new(1, 0, 1, 0),
				LayoutOrder = i,
				Primary = true,
				OnClick = function() applyOp(def[2]) end,
			})
		end
		refs.status = Kit.Label(content, "Select props below", Theme.TextSizes.Mini, Theme.SubText())
		refs.status.LayoutOrder = nextOrder()
		refs.status.Size = UDim2.new(1, 0, 0, 18)
		refs.list = create "ScrollingFrame" {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			LayoutOrder = nextOrder(),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.SubText(),
			Size = UDim2.new(1, 0, 1, -120),
			Parent = content,
			create "UIListLayout" {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		ShifterPanel.UpdateUI()
	end)
	refs.stop = stop
	return { Window = refs.window, Destroy = stop }
end

function ShifterPanel.UpdateUI()
	if not refs.list then return end
	for _, child in ipairs(refs.list:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	local list = detectList()
	if not list then return end
	for i, prop in ipairs(numericPropsFor(list)) do
		if refs.selected[prop] == nil then refs.selected[prop] = false end
		local btn = create "TextButton" {
			AutoButtonColor = false,
			BackgroundColor3 = refs.selected[prop]
				and Kit.AlphaBlend(0.5, Theme.Surface(), Theme.Accent())
				or Theme.Surface(),
			BorderSizePixel = 0,
			FontFace = Theme.Font,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, Theme.TextSizes.Mini + Theme.Padding.Base * 2),
			Text = prop,
			TextColor3 = Theme.Text(),
			TextSize = Theme.TextSizes.Mini,
			TextTruncate = Enum.TextTruncate.SplitWord,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = refs.list,
			create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
			create "UIPadding" {
				PaddingLeft = UDim.new(0, Theme.Padding.Side),
				PaddingRight = UDim.new(0, Theme.Padding.Side),
			},
		}
		btn.Activated:Connect(function()
			refs.selected[prop] = not refs.selected[prop]
			btn.BackgroundColor3 = refs.selected[prop]
				and Kit.AlphaBlend(0.5, Theme.Surface(), Theme.Accent())
				or Theme.Surface()
		end)
	end
end

function ShifterPanel.Destroy()
	if refs.stop then refs.stop() refs.stop = nil end
	refs = { selected = {} }
end

return ShifterPanel
