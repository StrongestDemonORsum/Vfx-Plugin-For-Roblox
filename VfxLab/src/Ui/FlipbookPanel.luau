-- VfxLab FlipbookPanel (Vide): BetterVfx FlipbookImporter parity (UI).
-- Frame grid (75px thumbs) sourced from the texture Library, per-flipbook
-- name/duration/fps properties, persisted via plugin settings. Apply tags
-- the current emitters with Flipbook attributes for the runtime.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local EmitterManager = require(script.Parent.Parent.Engine.EmitterManager)
local LibraryData = require(script.Parent.Parent.Engine.LibraryData)

local FlipbookPanel = {}
local refs = {}
local pluginHandle = nil

function FlipbookPanel.SetPlugin(plugin)
	pluginHandle = plugin
end

local function getFrames()
	if pluginHandle then
		local ok, val = pcall(function() return pluginHandle:GetSetting("VfxLabFlipFrames") end)
		if ok and typeof(val) == "table" then return val end
	end
	return {}
end

local function setFrames(frames)
	if pluginHandle then pcall(function() pluginHandle:SetSetting("VfxLabFlipFrames", frames) end) end
end

local function getFps()
	if pluginHandle then
		local ok, val = pcall(function() return pluginHandle:GetSetting("VfxLabFlipFPS") end)
		if ok and typeof(val) == "number" then return val end
	end
	return 60
end

function FlipbookPanel.Create(parentGui)
	local query = ""
	local stop = mount(function()
		local built = Kit.Window(parentGui, {
			Name = "VfxLabFlipbooks",
			Title = "FLIPBOOKS",
			Subtitle = "Mesh flipbook importer",
			Size = UDim2.fromOffset(400, 300),
			Position = UDim2.new(0.5, -200, 0.5, -150),
			Id = "flipbooks",
		})
		refs.window = built.Frame
		local content = built.Content
		local top = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 28),
			Parent = content,
			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, Theme.Padding.Side),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		Kit.Button(top, {
			Text = "+",
			TextSize = Theme.TextSizes.Special,
			Size = UDim2.new(0, 28, 1, 0),
			LayoutOrder = 1,
			Primary = true,
			OnClick = function()
				-- Add the Library's first selected texture as a frame.
				local textures = LibraryData.GetTextures()
				local frames = getFrames()
				local existing = {}
				for _, f in ipairs(frames) do existing[f.Asset] = true end
				local added = 0
				for _, tex in ipairs(textures) do
					if not existing[tex.Asset] then
						table.insert(frames, { Asset = tex.Asset, Name = tex.Name })
						added += 1
						break
					end
				end
				setFrames(frames)
				FlipbookPanel.Refresh()
				Kit.Notify(parentGui, added > 0 and "Frame added" or "No new textures")
			end,
		})
		local search = Kit.TextInput(top, {
			Size = UDim2.new(1, -36, 1, 0),
			LayoutOrder = 2,
			Text = "",
			TextSize = Theme.TextSizes.Mini,
			Placeholder = "search",
			OnFocusLost = function(text) query = text or "" FlipbookPanel.Refresh() end,
		})
		refs.grid = create "ScrollingFrame" {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			LayoutOrder = 2,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.SubText(),
			Size = UDim2.new(1, 0, 1, -110),
			Parent = content,
			create "UIGridLayout" {
				CellSize = UDim2.fromOffset(75, 75),
				CellPadding = UDim2.fromOffset(Theme.Padding.Side, Theme.Padding.Side),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		local bottom = create "Frame" {
			BackgroundTransparency = 1,
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 56),
			Parent = content,
			create "UIListLayout" {
				Padding = UDim.new(0, Theme.Padding.Base),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
		}
		refs.fpsBox = Kit.TextInput(bottom, {
			Size = UDim2.new(1, 0, 0, 24),
			Text = tostring(getFps()),
			TextSize = Theme.TextSizes.Mini,
			Placeholder = "FPS",
			OnFocusLost = function(text)
				local fps = tonumber(text)
				if fps and fps > 0 and pluginHandle then
					pcall(function() pluginHandle:SetSetting("VfxLabFlipFPS", fps) end)
				end
			end,
		})
		refs.durLabel = Kit.Label(bottom, "", Theme.TextSizes.Mini, Theme.SubText())
		refs.durLabel.Size = UDim2.new(1, 0, 0, 16)
		Kit.Button(bottom, {
			Text = "Apply to selection",
			TextSize = Theme.TextSizes.Mini,
			Size = UDim2.new(1, 0, 0, 24),
			Primary = true,
			OnClick = function()
				local frames = getFrames()
				if #frames == 0 or #EmitterManager.CurrentEmitters == 0 then
					Kit.Notify(parentGui, "Need frames + selection")
					return
				end
				local history = game:GetService("ChangeHistoryService")
				history:SetWaypoint("VfxLab Flipbook - Before")
				for _, emitter in ipairs(EmitterManager.CurrentEmitters) do
					pcall(function()
						emitter:SetAttribute("FlipbookEnabled", true)
						emitter:SetAttribute("FlipbookFPS", getFps())
						emitter:SetAttribute("FlipbookCount", #frames)
						emitter:SetAttribute("FlipbookDuration", #frames / getFps())
					end)
				end
				history:SetWaypoint("VfxLab Flipbook")
				Kit.Notify(parentGui, "Flipbook applied (" .. #frames .. " frames)")
			end,
		})
		FlipbookPanel.Refresh()
	end)
	refs.stop = stop
	return { Window = refs.window, Destroy = stop }
end

function FlipbookPanel.Refresh()
	if not refs.grid then return end
	for _, child in ipairs(refs.grid:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	local frames = getFrames()
	local q = string.lower(query or "")
	local order = 0
	for i, frame in ipairs(frames) do
		if q == "" or string.find(string.lower(frame.Name or ""), q, 1, true) then
			order += 1
			local cell = create "ImageButton" {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Surface(),
				BorderSizePixel = 0,
				Image = frame.Asset,
				LayoutOrder = order,
				Parent = refs.grid,
			}
			local more = create "TextButton" {
				AutoButtonColor = false,
				BackgroundColor3 = Theme.Background(),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				FontFace = Theme.FontBold,
				Position = UDim2.fromOffset(2, 2),
				Size = UDim2.fromOffset(18, 18),
				Text = "...",
				TextColor3 = Theme.Text(),
				TextSize = 10,
				ZIndex = 2,
				Parent = cell,
				create "UICorner" { CornerRadius = UDim.new(0, 4) },
				Activated = function()
					Kit.Options(cell:FindFirstAncestorOfClass("ScreenGui"),
						cell.AbsolutePosition + Vector2.new(20, 0), {
						{ Name = "Delete", OnClick = function()
							local fresh = getFrames()
							table.remove(fresh, i)
							setFrames(fresh)
							FlipbookPanel.Refresh()
						end },
					})
				end,
			}
		end
	end
	if refs.durLabel then
		local fps = getFps()
		refs.durLabel.Text = #frames .. " frames • " .. string.format("%.2fs @ %sfps", #frames / fps, tostring(fps))
	end
end

function FlipbookPanel.Toggle()
	if not refs.window then return end
	if refs.window.Visible ~= true then FlipbookPanel.Refresh() end
	Kit.TogglePanel(refs.window, refs.window.Visible ~= true)
end

return FlipbookPanel
