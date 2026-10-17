-- VfxLab UpdateLogPanel (Vide): BetterVfx UpdateLog parity. Scrollable
-- version entries (newest first). Opened from Settings > System.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local UpdateLogData = require(script.Parent.Parent.Engine.UpdateLogData)

local UpdateLogPanel = {}
local refs = {}

function UpdateLogPanel.Create(parentGui)
	local stop = mount(function()
		local built = Kit.Window(parentGui, {
			Name = "VfxLabUpdateLog",
			Title = "Update Log",
			Size = UDim2.fromOffset(400, 300),
			Position = UDim2.new(0.5, -200, 0.5, -150),
			Id = "updlog",
		})
		refs.window = built.Frame
		local content = built.Content
		for i, entry in ipairs(UpdateLogData) do
			local ver = Kit.Label(content, "Version " .. entry.Version, Theme.TextSizes.Base, Theme.Text())
			ver.FontFace = Theme.FontBold
			ver.LayoutOrder = i * 2 - 1
			ver.Size = UDim2.new(1, 0, 0, 22)
			local notes = create "TextLabel" {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Surface(),
				BorderSizePixel = 0,
				FontFace = Theme.Font,
				LayoutOrder = i * 2,
				RichText = true,
				Size = UDim2.new(1, 0, 0, 0),
				Text = entry.Notes,
				TextColor3 = Theme.Text(),
				TextSize = Theme.TextSizes.Base,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = content,
				create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
				create "UIPadding" {
					PaddingLeft = UDim.new(0, Theme.Padding.Side),
					PaddingRight = UDim.new(0, Theme.Padding.Side),
					PaddingTop = UDim.new(0, Theme.Padding.Base),
					PaddingBottom = UDim.new(0, Theme.Padding.Base),
				},
			}
		end
	end)
	refs.stop = stop
	return { Window = refs.window, Destroy = stop }
end

function UpdateLogPanel.Toggle()
	if not refs.window then return end
	Kit.TogglePanel(refs.window, refs.window.Visible ~= true)
end

return UpdateLogPanel
