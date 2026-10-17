-- VfxLab Sidebar (Vide): organized rail. Sections group Creation, Edit,
-- FX, Library and System actions; the mode row switches Creation /
-- Animation (phase 2).
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)

local Sidebar = {}

local function sectionLabel(parent, text, order)
	local label = Kit.Label(parent, text, 10, Theme.SubText())
	label.LayoutOrder = order
	label.Size = UDim2.new(1, -8, 0, 14)
	return label
end

-- callbacks: Emit, Properties, Beam, Adjust, Copy, Curve, Color, Screen,
-- Debris, Library, Settings, Style, Mode(mode). mode is a Vide source.
-- Returns { Rail, Destroy }.
function Sidebar.Create(parentGui, callbacks, mode)
	local rail
	local stop = mount(function()
		rail = create "ScrollingFrame" {
			BackgroundColor3 = Theme.Background(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Name = "VfxLabSidebar",
		Position = UDim2.new(1, -76, 0.5, -215),
		Size = UDim2.fromOffset(68, 430),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Border(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = parentGui,
			create "UICorner" { CornerRadius = UDim.new(0, 6) },
			create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0 },
			create "UIListLayout" {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			},
			create "UIPadding" {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			},
		}
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local function action(text, tip, fn, wide)
			local btn = Kit.Button(rail, {
				Text = text,
				TextSize = 10,
				Size = UDim2.fromOffset(wide or 60, 30),
				LayoutOrder = nextOrder(),
				OnClick = fn,
			})
			btn.Name = "Side_" .. text
			return btn
		end
		sectionLabel(rail, "MAKE", nextOrder())
		action("Emit", "Emit popup (R)", callbacks.Emit)
		action("Props", "Properties", callbacks.Properties)
		action("Beam", "Beam tools", callbacks.Beam)
		Kit.Separator(rail, nextOrder())
		sectionLabel(rail, "EDIT", nextOrder())
		action("Adjust", "Resize, retime, shift", callbacks.Adjust)
		action("Shift", "Arithmetic prop ops", callbacks.Shift)
		action("Copy", "Copy properties", callbacks.Copy)
		action("Curve", "Easing curves", callbacks.Curve)
		action("Color", "Color shift", callbacks.Color)
		Kit.Separator(rail, nextOrder())
		sectionLabel(rail, "FX", nextOrder())
		action("Screen", "Screen effects", callbacks.Screen)
		action("Debris", "Ground debris", callbacks.Debris)
		Kit.Separator(rail, nextOrder())
		sectionLabel(rail, "LIB", nextOrder())
		action("Library", "Template + texture library", callbacks.Library)
		action("Flips", "Flipbook importer", callbacks.Flips)
		Kit.Separator(rail, nextOrder())
		sectionLabel(rail, "SYS", nextOrder())
		action("Settings", "Settings", callbacks.Settings)
		Kit.Separator(rail, nextOrder())
		sectionLabel(rail, "MODE", nextOrder())
		local modeBtn = Kit.Button(rail, {
			Text = function() return mode() == "Animation" and "Anim" or "Make" end,
			TextSize = 10,
		Size = UDim2.fromOffset(60, 30),
			LayoutOrder = nextOrder(),
			Bg = function()
				return mode() == "Animation" and Theme.Selected() or Theme.Input()
			end,
			BrightText = true,
			OnClick = function()
				if callbacks.Mode then
					callbacks.Mode(if mode() == "Animation" then "Creation" else "Animation")
				end
			end,
		})
		modeBtn.Name = "Side_Mode"
		local ver = Kit.Label(rail, "v0.5", 9, Theme.SubText())
		ver.LayoutOrder = nextOrder()
		ver.Size = UDim2.new(1, 0, 0, 12)
		ver.TextXAlignment = Enum.TextXAlignment.Center
	end)
	return { Rail = rail, Destroy = stop }
end

return Sidebar
