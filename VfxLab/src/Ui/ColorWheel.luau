-- VfxLab ColorWheel (Vide): HSV picker with hex input.
local UserInputService = game:GetService("UserInputService")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)

local ColorWheel = {}

-- Returns the window. Create(parentGui, onPick) re-targets the callback.
function ColorWheel.Create(parentGui, onPick)
	local refs = ColorWheel._refs
	if refs and refs.window.Parent then
		refs.callback = onPick
		return refs.window
	end
	local hue, sat, val = source(0), source(1), source(1)
	local refs = { callback = onPick, hue = hue, sat = sat, val = val }
	local stop = mount(function()
		local window = create "Frame" {
			BackgroundColor3 = Theme.Background(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Name = "VfxLabWheel",
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(252, 336),
		Visible = false,
		Parent = parentGui,
		create "UICorner" { CornerRadius = UDim.new(0, 8) },
		create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0 },
		create "UIScale" { Name = "KitPop" },
		}
		refs = { window = window, hue = hue, sat = sat, val = val, callback = onPick }
		ColorWheel._refs = refs
		refs.window = window
		ColorWheel._refs = refs
		local title = Kit.Label(window, "COLOR", 13, Theme.Text())
		title.FontFace = Theme.FontBold
		title.Position = UDim2.fromOffset(12, 6)
		title.Size = UDim2.new(1, -24, 0, 20)
		local svMap = create "TextButton" {
			AutoButtonColor = false,
		BackgroundColor3 = function() return Color3.fromHSV(hue(), 1, 1) end,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 160),
		Position = UDim2.fromOffset(12, 30),
		Text = "",
		Parent = window,
		create "UICorner" { CornerRadius = UDim.new(0, 6) },
		}
		create "Frame" {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = svMap,
		create "UICorner" { CornerRadius = UDim.new(0, 6) },
		create "UIGradient" {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		},
		}
		create "Frame" {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = svMap,
		create "UICorner" { CornerRadius = UDim.new(0, 6) },
		create "UIGradient" {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		},
		}
		local svKnob = create "Frame" {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 5,
		Position = function() return UDim2.new(sat(), 0, 1 - val(), 0) end,
		Parent = svMap,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
		create "UIStroke" { Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Transparency = 0.3 },
		}
		local hueBar = create "TextButton" {
			AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, 12),
		Position = UDim2.fromOffset(12, 196),
		Text = "",
		Parent = window,
		create "UICorner" { CornerRadius = UDim.new(0, 6) },
		create "UIGradient" {
			Rotation = 0,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				}),
			},
		}
		local hueKnob = create "Frame" {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 5,
		Position = function() return UDim2.new(hue(), 0, 0.5, 0) end,
		Parent = hueBar,
			create "UICorner" { CornerRadius = UDim.new(1, 0) },
			create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0 },
		}
		local bottom = create "Frame" {
			BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 0, 110),
		Position = UDim2.fromOffset(12, 214),
		Parent = window,
		create "UIListLayout" {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		}
		local pushOutputs
		local valuesRow = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 26),
			Parent = bottom,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
		}		local swatch = create "Frame" {
			BackgroundColor3 = function() return Color3.fromHSV(hue(), sat(), val()) end,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(0, 26, 0, 26),
			Parent = valuesRow,
			create "UICorner" { CornerRadius = UDim.new(0, 4) },
			create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0 },
		}
		local hexBox = Kit.TextInput(valuesRow, {
			Size = UDim2.new(0, 84, 0, 24),
			Text = "FF0000",
			TextSize = 11,
			Mono = true,
			LayoutOrder = 2,
			Placeholder = "RRGGBB",
			OnFocusLost = function(text)
				local clean = text:gsub("#", ""):gsub("%s+", "")
				local r, g, b = clean:match("(%x%x)(%x%x)(%x%x)")
				if r and g and b then
					local h, s, v = Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)):ToHSV()
					hue(h)
					sat(s)
					val(v)
					pushOutputs()
				end
			end,
		})
		refs.hexBox = hexBox
		local rgbLabel = create "TextLabel" {
			BackgroundTransparency = 1,
			Font = Enum.Font.Code,
			LayoutOrder = 3,
			Size = UDim2.new(1, -118, 0, 24),
			Text = function()
				local c = Color3.fromHSV(hue(), sat(), val())
				return string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
			end,
			TextColor3 = Theme.SubText(),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = valuesRow,
		}
		local rgbRow = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = bottom,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		local function channelBox(initial, layoutOrder, apply)
			return Kit.TextInput(rgbRow, {
				Size = UDim2.new(0.33, -3, 1, 0),
				Text = initial,
				TextSize = 11,
				Mono = true,
				LayoutOrder = layoutOrder,
				OnFocusLost = function(text)
					local n = math.clamp(math.floor((tonumber(text) or 0) + 0.5), 0, 255)
					apply(n)
					pushOutputs()
				end,
			})
		end
		refs.rBox = channelBox("255", 1, function(n)
			local c = Color3.fromHSV(hue(), sat(), val())
			local h, s, v = Color3.fromRGB(n, math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)):ToHSV()
			hue(h)
			sat(s)
			val(v)
		end)
		refs.gBox = channelBox("255", 2, function(n)
			local c = Color3.fromHSV(hue(), sat(), val())
			local h, s, v = Color3.fromRGB(math.floor(c.R * 255 + 0.5), n, math.floor(c.B * 255 + 0.5)):ToHSV()
			hue(h)
			sat(s)
			val(v)
		end)
		refs.bBox = channelBox("255", 3, function(n)
			local c = Color3.fromHSV(hue(), sat(), val())
			local h, s, v = Color3.fromRGB(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), n):ToHSV()
			hue(h)
			sat(s)
			val(v)
		end)
		local paletteRow = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 20),
			Parent = bottom,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		for i, hex in ipairs({ "FFFFFF", "FF3B30", "FF9500", "FFCC00", "34C759", "00C7BE", "32ADE6", "0A84FF", "BF5AF2", "000000" }) do
			local pr = tonumber(hex:sub(1, 2), 16)
			local pg = tonumber(hex:sub(3, 4), 16)
			local pb = tonumber(hex:sub(5, 6), 16)
			local sw = create "TextButton" {
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(pr, pg, pb),
				BorderSizePixel = 0,
				LayoutOrder = i,
				Size = UDim2.new(0.1, -4, 1, 0),
				Text = "",
				Parent = paletteRow,
				create "UICorner" { CornerRadius = UDim.new(0, 4) },
				create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0 },
			}
			sw.Activated:Connect(function()
				local h, s, v = Color3.fromRGB(pr, pg, pb):ToHSV()
				hue(h)
				sat(s)
				val(v)
				pushOutputs()
			end)
		end
		function pushOutputs()
			local color = Color3.fromHSV(hue(), sat(), val())
			local r = math.floor(color.R * 255 + 0.5)
			local g = math.floor(color.G * 255 + 0.5)
			local b = math.floor(color.B * 255 + 0.5)
			local focused = UserInputService:GetFocusedTextBox()
			if refs.hexBox and refs.hexBox ~= focused then refs.hexBox.Text = string.format("%02X%02X%02X", r, g, b) end
			if refs.rBox and refs.rBox ~= focused then refs.rBox.Text = tostring(r) end
			if refs.gBox and refs.gBox ~= focused then refs.gBox.Text = tostring(g) end
			if refs.bBox and refs.bBox ~= focused then refs.bBox.Text = tostring(b) end
		end
		refs.push = pushOutputs
local actions = create "Frame" {
			BackgroundTransparency = 1,
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 28),
		Parent = bottom,
		create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		Kit.Button(actions, {
			Text = "CANCEL",
			TextSize = 10,
			Size = UDim2.new(0.5, -3, 1, 0),
			LayoutOrder = 1,
			OnClick = function() Kit.TogglePanel(window, false) end,
		})
		Kit.Button(actions, {
			Text = "APPLY",
			TextSize = 10,
			Size = UDim2.new(0.5, -3, 1, 0),
			LayoutOrder = 2,
			Primary = true,
			OnClick = function()
				local color = Color3.fromHSV(hue(), sat(), val())
				Kit.TogglePanel(window, false)
				if refs.callback then
					refs.callback(string.format("%d, %d, %d",
						math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)))
				end
			end,
		})
		local function dragOn(gui, fn)
			local sliding = false
			gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					sliding = true
					fn(Vector2.new(input.Position.X, input.Position.Y))
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
					fn(Vector2.new(input.Position.X, input.Position.Y))
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
			end)
		end
		dragOn(svMap, function(pos)
			local rel = pos - svMap.AbsolutePosition
			sat(math.clamp(rel.X / math.max(svMap.AbsoluteSize.X, 1), 0, 1))
			pushOutputs()
			val(1 - math.clamp(rel.Y / math.max(svMap.AbsoluteSize.Y, 1), 0, 1))
			pushOutputs()
		end)
		dragOn(hueBar, function(pos)
			hue(math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999))
			pushOutputs()
		end)
		pushOutputs()
	end)
	ColorWheel._stop = stop
	return refs.window
end

function ColorWheel.SetColor(color)
	local refs = ColorWheel._refs
	if typeof(color) == "Color3" and refs and refs.hue then
		local h, s, v = color:ToHSV()
		refs.hue(h)
		refs.sat(s)
		refs.val(v)
		if refs.push then refs.push() end
	end
end

function ColorWheel.Open()
	local refs = ColorWheel._refs
	if refs and refs.window then Kit.TogglePanel(refs.window, true) end
end

function ColorWheel.Destroy()
	if ColorWheel._stop then ColorWheel._stop() ColorWheel._stop = nil end
end

return ColorWheel
