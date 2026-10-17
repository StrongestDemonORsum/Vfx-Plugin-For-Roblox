-- VfxLab EmitPopup (Vide): smaller window, live theme, text glyph buttons.
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local EmitController = require(script.Parent.Parent.Engine.EmitController)
local SettingsPanel = require(script.Parent.SettingsPanel)

local EmitPopup = {}

local function refresh(countBox, delayBox, durationBox, loopOn)
	local first = EmitterManager.CurrentEmitters[1]
	if countBox then countBox.Text = tostring(EmitterManager.GetSetting(first, "EmitCount", 1)) end
	if delayBox then delayBox.Text = tostring(EmitterManager.GetSetting(first, "EmitDelay", 0)) end
	if durationBox then durationBox.Text = tostring(EmitterManager.GetSetting(first, "EffectDuration", 0)) end
	if loopOn and first then loopOn(EmitterManager.IsEnabled(first)) end
end

local function fieldRow(content, order, labelText, initial, applyFn, labelWidth)
	-- BetterVfx Emit row: measured label (surface, mini round) + value field.
	local row = create "Frame" {
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, Theme.TextSizes.Mini + Theme.Padding.Base * 2),
		Parent = content,
	}
	local w = labelWidth or Kit.MeasureLabel(labelText, Theme.TextSizes.Mini)
	local label = create "TextLabel" {
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		FontFace = Theme.Font,
		Size = UDim2.new(0, w, 1, 0),
		Text = labelText,
		TextColor3 = Theme.Text(),
		TextSize = Theme.TextSizes.Mini,
		TextTruncate = Enum.TextTruncate.SplitWord,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
		create "UIPadding" {
			PaddingLeft = UDim.new(0, Theme.Padding.Prop),
			PaddingRight = UDim.new(0, Theme.Padding.Prop),
		},
	}
	local holder = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(1, -(Theme.Padding.Side + w), 1, 0),
		Parent = row,
		create "UICorner" { CornerRadius = UDim.new(0, Theme.Rounding.Mini) },
	}
	local box = Kit.TextInput(holder, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = initial,
		TextSize = Theme.TextSizes.Mini,
	})
	box.BackgroundTransparency = 1
	box.FocusLost:Connect(function()
		if applyFn then applyFn(box.Text) end
		EmitPopup.ApplyFields()
		EmitPopup.Refresh()
	end)
	return box
end

function EmitPopup.ApplyFields()
	local refs = EmitPopup._refs
	if not refs then return end
	EmitterManager.ApplySmartProperty("EmitCount", refs.countBox.Text)
	EmitterManager.ApplySmartProperty("EmitDelay", refs.delayBox.Text)
	EmitterManager.ApplySmartProperty("EffectDuration", refs.durationBox.Text)
end

function EmitPopup.Refresh()
	local refs = EmitPopup._refs
	if refs and refs.window then
		refresh(refs.countBox, refs.delayBox, refs.durationBox, refs.loopOn)
	end
end

function EmitPopup.Toggle(parentGui)
	local refs = EmitPopup._refs
	if refs and refs.window.Parent then
		if refs.window.Visible then
			Kit.TogglePanel(refs.window, false)
		else
			refresh(refs.countBox, refs.delayBox, refs.durationBox, refs.loopOn)
			Kit.TogglePanel(refs.window, true)
		end
		return { Window = refs.window, Destroy = function() EmitPopup.Destroy() end }
	end
	local repeating = source(false)
	local refs = {}
	local stop = mount(function()
		local frame = create "Frame" {
			Active = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Background(),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Name = "VfxLabEmit",
			Position = Kit.LoadWinPos("emit") or UDim2.new(0, 80, 0.5, -73),
			Size = UDim2.fromOffset(240, 146),
			Visible = false,
			Parent = parentGui,
			create "UICorner" { CornerRadius = UDim.new(0, 8) },
			create "UIStroke" { Color = Theme.Accent(), Thickness = 1, Transparency = 0.85 },
			create "UIScale" { Name = "KitPop" },
		}
		refs.window = frame
		local bar = create "Frame" {
			BackgroundTransparency = 1,
			Name = "TitleBar",
			Size = UDim2.new(1, 0, 0, 25),
			Parent = frame,
		}
		local title = Kit.Label(bar, "Emit", 13, nil)
		title.FontFace = Theme.FontBold
		title.Position = UDim2.new(0, 10, 0, 0)
		title.Size = UDim2.new(1, -60, 1, 0)
		local pinned = source(false)
		local pinLabel = create "TextLabel" {
			BackgroundTransparency = 1,
			FontFace = Theme.FontBold,
			Size = UDim2.fromOffset(15, 15),
			Position = UDim2.new(1, -48, 0, 5),
			Text = "PIN",
			TextColor3 = function() return pinned() and Theme.Pinned() or Theme.SubText() end,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = bar,
		}
		local pinBtn = create "TextButton" {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(15, 15),
			Position = UDim2.new(1, -48, 0, 5),
			Text = "",
			Parent = bar,
			Activated = function()
				pinned(not pinned())
			end,
		}
		local closeBtn = create "TextButton" {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = Theme.FontBold,
			Size = UDim2.fromOffset(15, 15),
			Position = UDim2.new(1, -26, 0, 5),
			Text = "x",
			TextColor3 = Theme.SubText(),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = bar,
			Activated = function()
				Kit.TogglePanel(frame, false)
			end,
		}
		closeBtn.MouseEnter:Connect(function()
			TweenService:Create(closeBtn, TweenInfo.new(0.15), {
				TextColor3 = Theme.SubText():Lerp(Color3.new(1, 1, 1), Theme.HOVER_STRENGTH),
			}):Play()
		end)
		closeBtn.MouseLeave:Connect(function()
			TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = Theme.SubText() }):Play()
		end)
		local content = create "Frame" {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = "Content",
			Position = UDim2.new(0, 0, 0, 25),
			Size = UDim2.new(1, 0, 0, 0),
			Parent = frame,
			create "UIListLayout" {
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
			create "UIPadding" {
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, Theme.Padding.Side),
				PaddingLeft = UDim.new(0, Theme.Padding.Side),
				PaddingRight = UDim.new(0, Theme.Padding.Side),
			},
		}
		refs.Content = content
		local widest = 0
		for _, name in ipairs({ "Count", "Delay", "Duration" }) do
			widest = math.max(widest, Kit.MeasureLabel(name, Theme.TextSizes.Mini))
		end
		refs.countBox = fieldRow(content, 1, "Count", "1", nil, widest)
		refs.delayBox = fieldRow(content, 2, "Delay", "0", nil, widest)
		refs.durationBox = fieldRow(content, 3, "Duration", "1", nil, widest)
		-- BetterVfx-style presets: burst / continuous / loop-on.
		local presets = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = content,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
		}
		Kit.Button(presets, {
			Text = "Burst",
			TextSize = 11,
			Size = UDim2.new(0.5, -3, 1, 0),
			LayoutOrder = 1,
			OnClick = function()
				EmitPopup.ApplyFields()
				EmitController.Emit(20)
			end,
		})
		Kit.Button(presets, {
			Text = "Loop 2s",
			TextSize = 11,
			Size = UDim2.new(0.5, -3, 1, 0),
			LayoutOrder = 2,
			OnClick = function()
				repeating(not repeating())
				if repeating() then
					task.spawn(function()
						while repeating() do
							EmitController.Emit()
							task.wait(2)
						end
					end)
				end
			end,
		})
		local bottom = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 5,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = content,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
		}
		Kit.Button(bottom, {
			Text = "emit",
			TextSize = Theme.TextSizes.Mini,
			Radius = Theme.Rounding.Mini,
			Size = UDim2.new(1, -69, 1, 0),
			LayoutOrder = 1,
			Primary = true,
			OnClick = function()
				EmitPopup.ApplyFields()
				EmitController.Emit()
				EmitPopup.Refresh()
			end,
		})
		local repBtn = create "TextButton" {
			AutoButtonColor = false,
			BackgroundColor3 = function()
				return repeating() and Theme.Accent() or Theme.Surface()
			end,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(24, 24),
			LayoutOrder = 2,
			Text = "",
			Parent = bottom,
			create "UICorner" { CornerRadius = UDim.new(0, 8) },
		}
		local repIcon = create "TextLabel" {
			BackgroundTransparency = 1,
			FontFace = Theme.Font,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(15, 15),
			Text = "R",
			TextColor3 = function()
				return repeating() and Theme.OnAccent() or Theme.SubText()
			end,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = repBtn,
		}
		repBtn.MouseEnter:Connect(function()
			if not repeating() then
				TweenService:Create(repIcon, TweenInfo.new(0.15), {
					TextColor3 = Theme.SubText():Lerp(Color3.new(1, 1, 1), Theme.HOVER_STRENGTH),
				}):Play()
			end
		end)
		repBtn.MouseLeave:Connect(function()
			if not repeating() then
				TweenService:Create(repIcon, TweenInfo.new(0.15), { TextColor3 = Theme.SubText() }):Play()
			end
		end)
		local debounce = false
		repBtn.Activated:Connect(function()
			if debounce then return end
			debounce = true
			task.delay(0.1, function() debounce = false end)
			repeating(not repeating())
			if repeating() then
				task.spawn(function()
					while repeating() do
						EmitController.Emit()
						local interval = 2
						pcall(function()
							interval = SettingsPanel.Get(nil, "RepeatTimer") or 2
						end)
						task.wait(interval)
					end
				end)
			end
		end)
		local toggleBtn, setToggle = Kit.Toggle(bottom, false, nil, 3)
		refs.loopOn = setToggle
		toggleBtn.Activated:Connect(function()
			EmitterManager.ToggleEnabled()
			local first = EmitterManager.CurrentEmitters[1]
			if first then setToggle(EmitterManager.IsEnabled(first)) end
		end)
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
				Kit.SaveWinPos("emit", frame)
			end
		end)
		refresh(refs.countBox, refs.delayBox, refs.durationBox, refs.loopOn)
		EmitPopup._refs = refs
		Kit.TogglePanel(frame, true)
	end)
	EmitPopup._stop = stop
	return { Window = EmitPopup._refs.window, Destroy = function() EmitPopup.Destroy() end }
end

function EmitPopup.Destroy()
	if EmitPopup._stop then EmitPopup._stop() EmitPopup._stop = nil end
	EmitPopup._refs = nil
end

return EmitPopup
