-- VfxLab Kit (Vide): widgets matching the reference UI spec.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local source = Vide.source
local Theme = require(script.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = {}

local FADE_TI = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDE_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local PIN_IMAGE = "rbxassetid://120413064155653"
local CLOSE_IMAGE = "rbxassetid://101421401454601"

function Kit.Label(parent, text, size, color, align)
	return create "TextLabel" {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		Text = text,
		TextColor3 = color or Theme.Text(),
		TextSize = size or 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		Parent = parent,
	}
end

local function topIconBtn(parent, image, size, x, y, onClick)
	local btn = create "TextButton" {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.new(1, x, 0, y),
		Text = "",
		Parent = parent,
		Activated = onClick,
	}
	local img = create "ImageLabel" {
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = Theme.SubText(),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Parent = btn,
	}
	btn.MouseEnter:Connect(function()
		TweenService:Create(img, FADE_TI, {
			ImageColor3 = Theme.SubText():Lerp(Color3.new(1, 1, 1), Theme.HOVER_STRENGTH),
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(img, FADE_TI, { ImageColor3 = Theme.SubText() }):Play()
	end)
	return btn, img
end

Kit.TopIconBtn = topIconBtn

-- Plugin handle for window position persistence (set once from Main).
-- Declared before Kit.Window (lexical upvalue must precede use).
function Kit.SetPlugin(plugin)
	Kit._plugin = plugin
end

local function saveWinPos(id, frame)
	local plugin = Kit._plugin
	if not plugin or not id then return end
	pcall(function()
		plugin:SetSetting("VfxLabWin_" .. id, {
			X = frame.Position.X.Offset,
			Y = frame.Position.Y.Offset,
		})
	end)
end

local function loadWinPos(id)
	local plugin = Kit._plugin
	if not plugin or not id then return nil end
	local ok, pos = pcall(function() return plugin:GetSetting("VfxLabWin_" .. id) end)
	if ok and typeof(pos) == "table" and typeof(pos.X) == "number" then
		return UDim2.fromOffset(pos.X, pos.Y)
	end
	return nil
end

Kit.SaveWinPos = saveWinPos
Kit.LoadWinPos = loadWinPos

-- BetterVfx primitives (Vide-safe: static values + imperative tweens only).
function Kit.Round(parent, scale, offset)
	return create "UICorner" {
		CornerRadius = UDim.new(scale or 0, if offset ~= nil then offset else Theme.Rounding.Base),
		Parent = parent,
	}
end

function Kit.Stroke(parent, colorKey, thickness)
	local stroke = create "UIStroke" {
		Color = Theme[colorKey] and Theme[colorKey]() or Theme.Border(),
		Thickness = thickness or 1,
		Parent = parent,
	}
	stroke:SetAttribute("ThemePaint", colorKey or "Border")
	return stroke
end

function Kit.Padding(parent, left, top, right, bottom)
	return create "UIPadding" {
		PaddingLeft = UDim.new(0, left or Theme.Padding.Side),
		PaddingTop = UDim.new(0, top or Theme.Padding.Base),
		PaddingRight = UDim.new(0, right or Theme.Padding.Side),
		PaddingBottom = UDim.new(0, bottom or Theme.Padding.Base),
		Parent = parent,
	}
end

-- Hover factory: returns MouseEnter/Leave connections that tween a color
-- property (BetterVfx Hover without Fusion Spring).
function Kit.Hover(target, prop, normal, hovered, tweenInfo)
	tweenInfo = tweenInfo or FADE_TI
	local enter = target.MouseEnter:Connect(function()
		TweenService:Create(target, tweenInfo, { [prop] = hovered }):Play()
	end)
	local leave = target.MouseLeave:Connect(function()
		TweenService:Create(target, tweenInfo, { [prop] = normal }):Play()
	end)
	return enter, leave
end

function Kit.Tooltip(parent, text)
	local tip = create "TextLabel" {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Theme.Text(),
		BorderSizePixel = 0,
		FontFace = Theme.Font,
		RichText = true,
		Text = text,
		TextColor3 = Theme.Background(),
		TextSize = Theme.TextSizes.Mini,
		Visible = false,
		ZIndex = 100,
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Base),
			PaddingBottom = UDim.new(0, Theme.Padding.Base),
		},
	}
	tip:SetAttribute("ThemePaint", "Text")
	parent.MouseEnter:Connect(function() tip.Visible = true end)
	parent.MouseLeave:Connect(function() tip.Visible = false end)
	return tip
end

-- BetterVfx CheckboxInput: 1x1 aspect, primary if true else overlay, nano round.
function Kit.Checkbox(parent, initial, onFlip, size)
	size = size or 18
	local on = initial == true
	local btn = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = on and Theme.Accent() or Theme.Overlay(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size, size),
		Text = "",
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Nano) },
		create "UIAspectRatioConstraint" { AspectRatio = 1 },
	}
	local function paint(next)
		on = next
		TweenService:Create(btn, FADE_TI, {
			BackgroundColor3 = next and Theme.Accent() or Theme.Overlay(),
		}):Play()
		if onFlip then onFlip(next) end
	end
	btn.Activated:Connect(function() paint(not on) end)
	local function set(next) paint(next == true) end
	return btn, set
end

function Kit.ToolbarButton(parent, opts)
	return Kit.Button(parent, {
		Text = opts.Text or "",
		TextSize = Theme.TextSizes.Mini,
		Size = UDim2.fromOffset(30, 30),
		Radius = Theme.Rounding.Mini,
		LayoutOrder = opts.LayoutOrder or 1,
		OnClick = opts.OnClick,
		Bg = opts.Bg,
		Primary = opts.Primary,
	})
end

function Kit.Button(parent, opts)
	local isPrimary = opts.Primary == true
	local isDanger = opts.Danger == true
	local dim = not isPrimary and not isDanger and not opts.BrightText
	local hover = source(false)
	local pressed = source(false)
	local baseTransparency = opts.Transparent and 1 or 0
	local btn = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = opts.Bg or (isDanger and Theme.Error()) or (isPrimary and Theme.Accent()) or Theme.Surface(),
		BackgroundTransparency = baseTransparency,
		BorderSizePixel = 0,
		FontFace = Theme.FontBold,
		LayoutOrder = opts.LayoutOrder or 1,
		Size = opts.Size or UDim2.new(1, 0, 0, 28),
		ZIndex = opts.ZIndex or 1,
		Text = opts.Text or "",
		TextColor3 = dim and Theme.SubText() or (isPrimary or isDanger) and Theme.OnAccent() or Theme.Text(),
		TextSize = opts.TextSize or 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
		MouseEnter = function() hover(true) end,
		MouseLeave = function()
			hover(false)
			pressed(false)
		end,
		MouseButton1Down = function() pressed(true) end,
		MouseButton1Up = function() pressed(false) end,
		Activated = function()
			if opts.OnClick then opts.OnClick() end
		end,
		create "UICorner" { CornerRadius = UDim.new(0, opts.Radius or 6) },
	}
	if not opts.Bg then
		btn:SetAttribute("ThemePaint", isDanger and "Error" or (isPrimary and "Accent" or "Surface"))
		btn:SetAttribute("ThemePaintProp", dim and "SubText" or ((isPrimary or isDanger) and "OnAccent" or "Text"))
	end
	return btn
end

function Kit.TextInput(parent, opts)
	local box = create "TextBox" {
		BackgroundColor3 = Theme.Input(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		FontFace = if opts.Mono then nil else Theme.FontBold,
		Font = if opts.Mono then Theme.Mono else nil,
		LayoutOrder = opts.LayoutOrder or 1,
		PlaceholderColor3 = Theme.SubText(),
		PlaceholderText = opts.Placeholder or "",
		Position = opts.Position,
		Size = opts.Size or UDim2.new(1, 0, 0, 22),
		Text = opts.Text or "",
		TextColor3 = Theme.Text(),
		TextSize = opts.TextSize or 12,
		TextXAlignment = if opts.Center then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, 6) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, if opts.Center then 0 else 8),
			PaddingRight = UDim.new(0, if opts.Center then 0 else 8),
		},
	}
	if opts.OnFocusLost then
		box.FocusLost:Connect(function(enterPressed)
			opts.OnFocusLost(box.Text, enterPressed)
		end)
	end
	return box
end

function Kit.Toggle(parent, initial, onFlip, layoutOrder)
	local current = source(initial == true)
	local track = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = current() and Theme.Accent() or Theme.Raised(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Size = UDim2.fromOffset(34, 18),
		Text = "",
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local knob = create "Frame" {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 3, 0.5, 0),
		Parent = track,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local function flip(next)
		current(next)
		track.BackgroundColor3 = next and Theme.Accent() or Theme.Raised()
		TweenService:Create(knob, FADE_TI, {
			Position = next and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		}):Play()
		if onFlip then onFlip(next) end
	end
	track.Activated:Connect(function() flip(not current()) end)
	local function set(on) flip(on) end
	return track, set
end

function Kit.Separator(parent, layoutOrder, width)
	return create "Frame" {
		BackgroundColor3 = Theme.Border(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Size = UDim2.new(0, width or 24, 0, 1),
		Parent = parent,
	}
end

function Kit.Window(parent, opts)
	local savedPos = opts.Id and loadWinPos(opts.Id) or nil
	local frame = create "Frame" {
		Active = true,
		BackgroundColor3 = Theme.Background(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Name = opts.Name or "Panel",
		Position = savedPos or opts.Position or UDim2.fromScale(0.5, 0.5),
		Size = opts.Size or UDim2.fromOffset(280, 360),
		Visible = false,
		ZIndex = opts.ZIndex or 1,
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, 8) },
		create "UIScale" { Name = "KitPop" },
	}
	frame:SetAttribute("ThemePaint", "Background")
	-- BetterVfx Window: 1px primary stroke (static here; repainted via Changed).
	local winStroke = create "UIStroke" {
		Color = Theme.Accent(),
		Thickness = 1,
		Transparency = 0.85,
		Parent = frame,
	}
	winStroke:SetAttribute("ThemePaint", "Accent")
	local bar = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, Theme.TitleBarH),
		Parent = frame,
		create "UICorner" { CornerRadius = UDim.new(0, 8) },
	}
	bar:SetAttribute("ThemePaint", "Surface")
	-- Square off the title bar's bottom edge so it blends into the body.
	local barFix = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Name = "TitleBarFix",
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = bar,
	}
	barFix:SetAttribute("ThemePaint", "Surface")
	local titleLabel = Kit.Label(bar, opts.Title or "Panel", Theme.TextSizes.TitleBar, Theme.Text())
	titleLabel.FontFace = Theme.FontBold
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	topIconBtn(bar, PIN_IMAGE, 15, -48, 5, opts.OnPin or nil)
	topIconBtn(bar, CLOSE_IMAGE, 10, -26, 7, function()
		Kit.TogglePanel(frame, false)
		if opts.OnClose then opts.OnClose() end
	end)
	local content = create "ScrollingFrame" {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Name = "Content",
		Position = UDim2.new(0, 0, 0, Theme.TitleBarH),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.SubText(),
		Size = UDim2.new(1, 0, 1, -Theme.TitleBarH),
		Parent = frame,
		create "UIListLayout" {
			Padding = UDim.new(0, Theme.Padding.Side),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		create "UIPadding" {
			PaddingTop = UDim.new(0, Theme.Padding.Base),
			PaddingBottom = UDim.new(0, Theme.Padding.Base),
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
		},
	}
	local dragging, dragStart, startPos = false, nil, nil
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, dragStart, startPos = true, input.Position, frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - dragStart
			frame.Position = startPos + UDim2.fromOffset(d.X, d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
			dragging = false
			if opts.Id then saveWinPos(opts.Id, frame) end
		end
	end)
	-- Live theme repaint for static (non-mount) windows.
	pcall(function()
		Theme.Changed.Event:Connect(function()
			Theme.RepaintStatic(frame)
		end)
	end)
	return { Frame = frame, Content = content }
end

function Kit.TogglePanel(frame, show)
	local scale = frame:FindFirstChild("KitPop")
	frame:SetAttribute("KitOpen", show)
	if show then
		frame.Visible = true
		if scale and scale:IsA("UIScale") then
			scale.Scale = 0.96
			TweenService:Create(scale, POP_TWEEN, { Scale = 1 }):Play()
		end
	else
		if scale and scale:IsA("UIScale") then
			local tween = TweenService:Create(scale, HIDE_TWEEN, { Scale = 0.97 })
			tween:Play()
			tween.Completed:Once(function()
				if frame:GetAttribute("KitOpen") ~= true then
					frame.Visible = false
				end
			end)
		else
			frame.Visible = false
		end
	end
end

function Kit.Section(parent, title, layoutOrder, openDefault, depth)
	depth = depth or 1
	local isOpen = openDefault ~= false
	-- BetterVfx Container: stroked card, surface child area, highlight bar.
	local card = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Name = title .. "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIStroke" { Color = Theme.Overlay(), Thickness = 1 },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Prop + Theme.Padding.Prop * (depth - 1)),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Base),
			PaddingBottom = UDim.new(0, Theme.Padding.Base),
		},
		create "UIListLayout" {
			Padding = UDim.new(0, Theme.Padding.Base),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
	local header = create "TextButton" {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Theme.FontBold,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = math.max(Theme.TextSizes.TitleBar - depth * 2, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = (isOpen and "v " or "> ") .. string.upper(title),
		TextColor3 = Theme.SubText(),
		Parent = card,
	}
	local content = create "Frame" {
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Name = title .. "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = isOpen,
		Parent = card,
		create "UIListLayout" {
			Padding = UDim.new(0, Theme.Padding.Base),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
	header.Activated:Connect(function()
		isOpen = not isOpen
		content.Visible = isOpen
		header.Text = (isOpen and "v " or "> ") .. string.upper(title)
	end)
	return content, card
end

-- BetterVfx Attribute row: 24px, surface bg, 1px overlay separator, 50/50.
function Kit.Row(parent, labelText, layoutOrder, index)
	local row = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Size = UDim2.new(1, 0, 0, Theme.RowH),
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
	}
	if (index or 1) > 1 then
		create "Frame" {
			BackgroundColor3 = Theme.Overlay(),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Name = "Separator",
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			Parent = row,
		}
	end
	local label = Kit.Label(row, labelText, Theme.TextSizes.Mini, Theme.Text())
	label.FontFace = Theme.Font
	label.Size = UDim2.new(0.5, -Theme.Padding.Prop, 1, 0)
	label.Position = UDim2.new(0, Theme.Padding.Prop, 0, 0)
	label.TextTruncate = Enum.TextTruncate.AtEnd
	local holder = create "Frame" {
		BackgroundTransparency = 1,
		Name = "Control",
		Position = UDim2.new(0.5, 0, 0, 1),
		Size = UDim2.new(0.5, 0, 1, -2),
		Parent = row,
	}
	return row, holder
end

function Kit.Slider(parent, opts)
	local min, max = opts.Min or 0, opts.Max or 1
	local value = source(opts.Value or min)
	local track = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Slider(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = opts.LayoutOrder or 1,
		Size = opts.Size or UDim2.new(1, 0, 0, 6),
		Text = "",
		Parent = parent,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	if opts.Gradient then
		create "UIGradient" { Color = opts.Gradient, Parent = track }
	end
	local fill = create "Frame" {
		BackgroundColor3 = Theme.Accent(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local knob = create "Frame" {
		BackgroundColor3 = Theme.Accent(),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		Parent = track,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
	}
	local function updateVisual()
		local alpha = math.clamp((value() - min) / math.max(max - min, 0.0001), 0, 1)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
	end
	updateVisual()
	local api = {}
	function api.Set(next, silent)
		next = math.clamp(next, min, max)
		value(next)
		updateVisual()
		if not silent and opts.OnChange then
			opts.OnChange(next)
		end
	end
	local sliding = false
	local function fromMouse(x)
		local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		api.Set(min + (max - min) * alpha)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			fromMouse(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
			fromMouse(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
	end)
	api.Value = value
	return api
end

-- AlphaBlend helper (BetterVfx AlphaBlend): mix two colors by alpha.
function Kit.AlphaBlend(alpha, a, b)
	return a:Lerp(b, math.clamp(alpha, 0, 1))
end

-- Measure a label's pixel width (BetterVfx widest-label pattern), imperatively.
local TextService = game:GetService("TextService")
function Kit.MeasureLabel(text, size)
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = Theme.Font
		params.Size = size or Theme.TextSizes.Mini
		params.Width = 10000
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and bounds then
		return bounds.X + Theme.Padding.Prop * 2
	end
	return 64
end

-- OnHold: press-and-hold/drag helper. Returns a stop function.
-- onMove(mousePos: Vector2, delta: number) return true to cancel early.
function Kit.OnHold(target, onMove, inputType)
	inputType = inputType or Enum.UserInputType.MouseButton1
	local holding = false
	local connMove, connEnd
	connMove = UserInputService.InputChanged:Connect(function(input)
		if holding and input.UserInputType == Enum.UserInputType.MouseMovement then
			if onMove then
				local cancel = onMove(input.Position, 0)
				if cancel then holding = false end
			end
		end
	end)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == inputType then holding = true end
	end)
	connEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == inputType then holding = false end
	end)
	return function()
		holding = false
		if connMove then connMove:Disconnect() end
		if connEnd then connEnd:Disconnect() end
	end
end

-- OnKeybind: keyboard shortcut helper. seq is an array like {"R"} or
-- {"LCtrl","Q"}. Skips when a textbox is focused. Returns a stop function.
function Kit.OnKeybind(seq, callback)
	local pressed = {}
	local function keyOf(input)
		return input.KeyCode.Name
	end
	local connB = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if UserInputService:GetFocusedTextBox() then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local key = keyOf(input)
		if not table.find(pressed, key) then table.insert(pressed, key) end
		if #pressed == #seq then
			local match = true
			for _, want in ipairs(seq) do
				if not table.find(pressed, want) then match = false break end
			end
			if match then task.spawn(callback) end
		end
	end)
	local connE = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local key = keyOf(input)
		local i = table.find(pressed, key)
		if i then table.remove(pressed, i) end
	end)
	return function()
		if connB then connB:Disconnect() end
		if connE then connE:Disconnect() end
	end
end

-- Options: context menu popup at a screen position. opts = { {Name, OnClick} }.
function Kit.Options(parentGui, position, opts)
	local layer = create "ScreenGui" {
		Name = "VfxLabOptions",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = Theme.DisplayOrder + 10,
		Parent = parentGui,
	}
	local dismiss = create "TextButton" {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = layer,
	}
	local menu = create "CanvasGroup" {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(position.X, position.Y),
		Parent = layer,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIStroke" { Color = Theme.Highlight(), Thickness = 1 },
		create "UIListLayout" {
			Padding = UDim.new(0, Theme.Padding.Base),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Base),
			PaddingBottom = UDim.new(0, Theme.Padding.Base),
		},
	}
	for i, opt in ipairs(opts) do
		Kit.Button(menu, {
			Text = opt.Name,
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, Theme.TextSizes.Mini + Theme.Padding.Prop),
			LayoutOrder = i,
			OnClick = function()
				layer:Destroy()
				if opt.OnClick then opt.OnClick() end
			end,
		})
	end
	dismiss.Activated:Connect(function() layer:Destroy() end)
	-- Clamp inside viewport.
	task.defer(function()
		if not menu.Parent then return end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local abs = menu.AbsolutePosition
		local size = menu.AbsoluteSize
		local x = math.clamp(abs.X, 4, math.max(4, vp.X - size.X - 4))
		local y = math.clamp(abs.Y, 4, math.max(4, vp.Y - size.Y - 4))
		menu.Position = UDim2.fromOffset(x, y)
	end)
	return layer
end

-- Prompt: modal dialog. onClose called on dismiss. Returns {Frame, Close}.
function Kit.Prompt(parentGui, opts)
	local layer = create "ScreenGui" {
		Name = "VfxLabPrompt",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = Theme.DisplayOrder + 5,
		Parent = parentGui,
	}
	local overlay = create "TextButton" {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = layer,
	}
	local size = opts.Size or UDim2.fromOffset(350, 0)
	local frame = create "Frame" {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background(),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		Parent = layer,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIStroke" { Color = Theme.Accent(), Thickness = 1, Transparency = 0.85 },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Side),
			PaddingBottom = UDim.new(0, Theme.Padding.Side),
		},
		create "UIListLayout" {
			Padding = UDim.new(0, Theme.Padding.Side),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
	}
	local title = Kit.Label(frame, opts.Title or "Prompt", Theme.TextSizes.TitleBar, Theme.Text())
	title.FontFace = Theme.FontBold
	title.Size = UDim2.new(1, 0, 0, Theme.TitleBarH)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		layer:Destroy()
		if opts.OnClose then opts.OnClose() end
	end
	overlay.Activated:Connect(close)
	return { Frame = frame, Layer = layer, Close = close }
end

-- ErrorPrompt: modal error dialog with wrapped message.
function Kit.ErrorPrompt(parentGui, text, title)
	local prompt = Kit.Prompt(parentGui, { Title = title or "Error", Size = UDim2.fromOffset(350, 0) })
	local box = create "TextBox" {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		FontFace = Theme.Font,
		Size = UDim2.fromScale(1, 0),
		Text = text,
		TextColor3 = Theme.Text(),
		TextEditable = false,
		TextSize = Theme.TextSizes.Base,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = prompt.Frame,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Side),
			PaddingBottom = UDim.new(0, Theme.Padding.Side),
		},
	}
	Kit.Button(prompt.Frame, {
		Text = "OK",
		Size = UDim2.new(1, 0, 0, 28),
		Primary = true,
		OnClick = prompt.Close,
	})
	return prompt
end

-- Notify: top-center auto-hiding notification bar.
function Kit.Notify(parentGui, text, duration)
	duration = duration or 10
	local old = parentGui:FindFirstChild("VfxLabNotif")
	if old then old:Destroy() end
	local label = create "TextLabel" {
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Text(),
		BorderSizePixel = 0,
		FontFace = Theme.FontBold,
		Name = "VfxLabNotif",
		Position = UDim2.new(0.5, 0, 0, Theme.Padding.Side * 2),
		Text = text,
		TextColor3 = Theme.Background(),
		TextSize = Theme.TextSizes.Base,
		ZIndex = 200,
		Parent = parentGui,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Base) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Side),
			PaddingRight = UDim.new(0, Theme.Padding.Side),
			PaddingTop = UDim.new(0, Theme.Padding.Base),
			PaddingBottom = UDim.new(0, Theme.Padding.Base),
		},
	}
	task.delay(duration, function()
		if label.Parent then label:Destroy() end
	end)
	return label
end

return Kit
