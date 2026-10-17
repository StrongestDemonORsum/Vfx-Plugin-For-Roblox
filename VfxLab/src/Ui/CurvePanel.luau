-- VfxLab CurvePanel (Vide): bezier easing editor with draggable handles.
-- Curve state lives in refs.curve so Redraw/drag/apply share it.
local UserInputService = game:GetService("UserInputService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local CurveEngine = require(script.Parent.Parent.Engine.Assets.VFXPlayer.Runtime.CurveEngine)

local CurvePanel = {}

local function segment(parent, a, b)
	local delta = b - a
	create "Frame" {
		Name = "CurveLine",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(a.X, a.Y),
		Size = UDim2.fromOffset(delta.Magnitude, 1),
		Rotation = math.deg(math.atan2(delta.Y, delta.X)),
		BackgroundColor3 = Theme.Accent(),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = parent,
	}
end

local function evaluateAt(st, alpha)
	if st.custom() then
		return CurveEngine.Bezier01(alpha, st.pts.p1, st.pts.p2)
	end
	return CurveEngine.Evaluate(st.presets[st.presetIndex()] .. st.direction(), alpha)
end

-- Returns { Window, Destroy }.
function CurvePanel.Create(parentGui)
	local refs = {}
	local stop = mount(function()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		local presets = CurveEngine.List()
		local st = {
			pts = { p1 = Vector2.new(0.25, 0.1), p2 = Vector2.new(0.25, 1) },
			custom = source(false),
			presets = presets,
			presetIndex = source(table.find(presets, "Sine") or 1),
			direction = source("Out"),
		}
		refs.curve = st
		local built = Kit.Window(parentGui, {
			Name = "VfxLabCurve",
			Id = "curve",
		Title = "CURVE",
		Subtitle = "Easing for offsets and trails",
			Size = UDim2.fromOffset(248, 250),
			Position = UDim2.new(1, -560, 0, 38),
		})
		refs.window = built.Frame
		local content = built.Content
		local graph = create "Frame" {
			BackgroundColor3 = Theme.Input(),
			BorderSizePixel = 0,
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 88),
			ClipsDescendants = true,
			Parent = content,
			create "UICorner" { CornerRadius = UDim.new(0, 5) },
		}
		refs.graph = graph
		for index = 1, 3 do
			create "Frame" {
				BackgroundColor3 = Theme.SubText(),
				BackgroundTransparency = 0.86,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, index / 4, 0),
				Parent = graph,
			}
			create "Frame" {
				BackgroundColor3 = Theme.SubText(),
			BackgroundTransparency = 0.86,
			BorderSizePixel = 0,
				Size = UDim2.new(0, 1, 1, 0),
				Position = UDim2.new(index / 4, 0, 0, 0),
				Parent = graph,
			}
		end
		local handle1 = create "TextButton" {
			AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(215, 155, 255),
			BorderSizePixel = 0,
		Size = UDim2.fromOffset(9, 9),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = "",
		ZIndex = 5,
		Visible = false,
		Parent = graph,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
		}
		local handle2 = create "TextButton" {
			AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(150, 205, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(9, 9),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Text = "",
		ZIndex = 5,
		Visible = false,
		Parent = graph,
		create "UICorner" { CornerRadius = UDim.new(1, 0) },
		}
		refs.handle1, refs.handle2 = handle1, handle2
		local nav = create "Frame" {
			BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 20),
		Parent = content,
		}
		Kit.Button(nav, {
			Text = "<",
			TextSize = 10,
			Size = UDim2.fromOffset(24, 20),
			OnClick = function()
				st.custom(false)
				local i = st.presetIndex()
				st.presetIndex(if i == 1 then #presets else i - 1)
				CurvePanel.Redraw()
			end,
		}).Position = UDim2.fromOffset(0, 0)
		refs.presetLabel = create "TextLabel" {
			BackgroundColor3 = Theme.Input(),
		BorderSizePixel = 0,
		FontFace = Theme.Font,
		Size = UDim2.new(1, -122, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		Text = presets[st.presetIndex()],
		TextColor3 = Theme.Text(),
		TextSize = 10,
		Parent = nav,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
		}
		Kit.Button(nav, {
			Text = ">",
			TextSize = 10,
			Size = UDim2.fromOffset(24, 20),
			OnClick = function()
				st.custom(false)
				local i = st.presetIndex()
				st.presetIndex(if i == #presets then 1 else i + 1)
				CurvePanel.Redraw()
			end,
		}).Position = UDim2.new(1, -26, 0, 0)
		refs.directionBtn = create "TextButton" {
			AutoButtonColor = false,
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		FontFace = Theme.FontBold,
		Size = UDim2.fromOffset(46, 20),
		Position = UDim2.new(1, -74, 0, 0),
		Text = st.direction(),
		TextColor3 = Theme.Accent(),
		TextSize = 10,
		Parent = nav,
		Activated = function()
				local d = st.direction()
				st.direction(d == "Out" and "In" or (d == "In" and "InOut" or "Out"))
				CurvePanel.Redraw()
			end,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
		}
		Kit.Button(content, {
			Text = "Apply",
			TextSize = 11,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = nextOrder(),
			Primary = true,
			OnClick = function()
				if #EmitterManager.CurrentEmitters == 0 then return end
				ChangeHistoryService:SetWaypoint("VfxLab Curve Before")
				for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
					local curveName = st.custom() and "Custom" or (presets[st.presetIndex()] .. st.direction())
					emitter:SetAttribute("EasingStyle", curveName)
					emitter:SetAttribute("VisualXCurveP1", st.custom() and st.pts.p1 or nil)
					emitter:SetAttribute("VisualXCurveP2", st.custom() and st.pts.p2 or nil)
					if emitter:IsA("Trail") and string.find(string.lower(tostring(emitter:GetAttribute("TrailPathMode") or "")), "bezier", 1, true) then
						emitter:SetAttribute("TrailPathCurve", curveName)
					end
				end
				ChangeHistoryService:SetWaypoint("VfxLab Curve")
			end,
		})
		graph:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() CurvePanel.Redraw() end)
		local activeHandle = nil
		handle1.MouseButton1Down:Connect(function() activeHandle = 1 end)
		handle2.MouseButton1Down:Connect(function() activeHandle = 2 end)
		UserInputService.InputChanged:Connect(function(input)
			if activeHandle and input.UserInputType == Enum.UserInputType.MouseMovement then
				local relative = Vector2.new(input.Position.X, input.Position.Y) - graph.AbsolutePosition
				local point = Vector2.new(
					math.clamp(relative.X / math.max(graph.AbsoluteSize.X, 1), 0, 1),
					1 - math.clamp(relative.Y / math.max(graph.AbsoluteSize.Y, 1), 0, 1)
				)
				st.custom(true)
				if activeHandle == 1 then st.pts.p1 = point else st.pts.p2 = point end
				CurvePanel.Redraw()
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then activeHandle = nil end
		end)
		task.defer(function() CurvePanel.Redraw() end)
	end)
	CurvePanel._refs = refs
	CurvePanel._stop = stop
	return { Window = refs.window, Destroy = stop }
end

function CurvePanel.Destroy()
	if CurvePanel._stop then CurvePanel._stop() CurvePanel._stop = nil end
end

function CurvePanel.Redraw()
	local refs = CurvePanel._refs
	if not refs or not refs.graph then return end
	local st = refs.curve
	if not st then return end
	local graph = refs.graph
	for _, child in ipairs(graph:GetChildren()) do
		if child.Name == "CurveLine" then child:Destroy() end
	end
	local width = math.max(graph.AbsoluteSize.X, 1)
	local height = math.max(graph.AbsoluteSize.Y, 1)
	local previousPoint = Vector2.new(0, height)
	for index = 1, 32 do
		local alpha = index / 32
		local point = Vector2.new(alpha * width, (1 - evaluateAt(st, alpha)) * height)
		segment(graph, previousPoint, point)
		previousPoint = point
	end
	refs.handle1.Position = UDim2.fromScale(st.pts.p1.X, 1 - st.pts.p1.Y)
	refs.handle2.Position = UDim2.fromScale(st.pts.p2.X, 1 - st.pts.p2.Y)
	refs.handle1.Visible = st.custom()
	refs.handle2.Visible = st.custom()
	refs.presetLabel.Text = st.custom() and "Custom" or st.presets[st.presetIndex()]
	refs.directionBtn.Text = st.direction()
end

return CurvePanel
