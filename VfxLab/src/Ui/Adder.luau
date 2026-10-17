-- VfxLab Adder (Vide): BetterVfx Adder parity. Mouse-anchored 170x200
-- modal with search + template buttons. Click inserts the template
-- (LibraryData.InsertTemplate selects it) and closes. All static props.
local UserInputService = game:GetService("UserInputService")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local LibraryData = require(script.Parent.Parent.Engine.LibraryData)

local Adder = {}
local stopFn = nil

local function rank(name, query, index)
	if query == "" then return index end
	local start, stop = string.find(name:lower(), query:lower(), 1, true)
	if start and stop ~= 0 then return start * start end
	return 1000 + index
end

function Adder.Toggle(parentGui)
	if stopFn then
		stopFn()
		stopFn = nil
		return nil
	end
	local query = source("")
	local size = Vector2.new(170, 200)
	local mouse = UserInputService:GetMouseLocation()
	local cam = workspace.CurrentCamera
	local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local pad = Theme.Padding.Side
	local pos = Vector2.new(
		math.clamp(mouse.X, pad, math.max(pad, viewport.X - size.X - pad)),
		math.clamp(mouse.Y, pad, math.max(pad, viewport.Y - size.Y - pad)))
	local templates = LibraryData.GetTemplates()
	local rows = {}
	stopFn = mount(function()
		local layer = create "TextButton" {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Name = "VfxLabAdderLayer",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 1000,
			Parent = parentGui,
		}
		local box = create "Frame" {
			BackgroundColor3 = Theme.Background(),
			BorderSizePixel = 0,
			Name = "VfxLabAdder",
			Position = UDim2.fromOffset(pos.X, pos.Y),
			Size = UDim2.fromOffset(size.X, size.Y),
			ZIndex = 1001,
			Parent = layer,
			create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
			create "UIStroke" { Color = Theme.Accent(), Thickness = 1 },
			create "UIPadding" {
				PaddingLeft = UDim.new(0, Theme.Padding.Side),
				PaddingRight = UDim.new(0, Theme.Padding.Side),
				PaddingTop = UDim.new(0, Theme.Padding.Side),
				PaddingBottom = UDim.new(0, Theme.Padding.Side),
			},
			create "UIListLayout" {
				Padding = UDim.new(0, Theme.Padding.Side),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
			},
		}
		local searchWrap = create "Frame" {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Surface(),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = box,
			create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
			create "UISizeConstraint" {
				MinSize = Vector2.new(0, Theme.TextSizes.Mini + Theme.Padding.Base * 2),
			},
		}
		local search = create "TextBox" {
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			FontFace = Theme.Font,
			PlaceholderColor3 = Theme.Muted(),
			PlaceholderText = "search",
			Size = UDim2.new(1, -Theme.Padding.Side * 2, 0, Theme.TextSizes.Mini + Theme.Padding.Base * 2),
			Position = UDim2.new(0, Theme.Padding.Side, 0, 0),
			Text = "",
			TextColor3 = Theme.Text(),
			TextSize = Theme.TextSizes.Mini,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClipsDescendants = true,
			Parent = searchWrap,
		}
		search:GetPropertyChangedSignal("Text"):Connect(function() query(search.Text) applyFilter() end)
		search:CaptureFocus()
		local scroll = create "ScrollingFrame" {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			LayoutOrder = 2,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.SubText(),
			Size = UDim2.new(1, 0, 1, 0),
			Parent = box,
			create "UIListLayout" {
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		for i, item in ipairs(templates) do
			local btn = create "TextButton" {
				AutoButtonColor = false,
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Surface(),
				BorderSizePixel = 0,
				FontFace = Theme.Font,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 0),
				Text = item.DisplayName or item.Name,
				TextColor3 = Theme.Text(),
				TextSize = Theme.TextSizes.Mini,
				TextTruncate = Enum.TextTruncate.SplitWord,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = scroll,
				create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
				create "UIPadding" {
					PaddingLeft = UDim.new(0, Theme.Padding.Side),
					PaddingRight = UDim.new(0, Theme.Padding.Side),
					PaddingTop = UDim.new(0, Theme.Padding.Base),
					PaddingBottom = UDim.new(0, Theme.Padding.Base),
				},
				Activated = function()
					LibraryData.InsertTemplate(item)
					Adder.Close()
				end,
			}
			rows[i] = { Btn = btn, Item = item, Index = i }
		end
		local function applyFilter()
			local ordered = {}
			for _, row in ipairs(rows) do
				table.insert(ordered, { Rank = rank(row.Item.DisplayName or row.Item.Name, query(), row.Index), Row = row })
			end
			table.sort(ordered, function(a, b) return a.Rank < b.Rank end)
			for order, entry in ipairs(ordered) do
				entry.Row.Btn.LayoutOrder = order
				entry.Row.Btn.Visible = entry.Rank < 1000
			end
		end
		-- Re-run filter whenever the query source changes (mount scope: safe).
		layer.Activated:Connect(function() Adder.Close() end)
	end)
	return true
end

function Adder.Close()
	if stopFn then stopFn() stopFn = nil end
end

return Adder
