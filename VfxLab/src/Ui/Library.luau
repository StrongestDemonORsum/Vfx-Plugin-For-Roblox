-- VfxLab Library (Vide): one window for everything reusable. Tabs switch
-- the grid between effect templates (live 3D previews) and textures.
local Vide = require(script.Parent.Parent.Modules.vide)
local create = Vide.create
local mount = Vide.mount
local source = Vide.source
local Theme = require(script.Parent.Theme)
local Kit = require(script.Parent.Kit)
local LibraryData = require(script.Parent.Parent.Engine.LibraryData)

local Library = {}

local function flash(card)
	card.BackgroundColor3 = Theme.Surface()
	task.delay(0.2, function()
		if card.Parent then card.BackgroundColor3 = Theme.Surface() end
	end)
end

local function makeEffectCard(grid, status, item)
	local card = create "Frame" {
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		Name = "Template_" .. item.Name,
		Parent = grid,
		create "UICorner" { CornerRadius = UDim.new(0, 12) },
		create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0.15 },
	}
	local preview = create "ViewportFrame" {
		BackgroundColor3 = Color3.fromRGB(13, 15, 18),
		BorderSizePixel = 0,
		Name = "Preview",
		Size = UDim2.new(1, -12, 0, 102),
		Position = UDim2.fromOffset(6, 6),
		Parent = card,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
	}
	LibraryData.BuildViewport(preview, item.Source)
	local name = Kit.Label(card, item.DisplayName or item.Name, 13, Theme.Text())
	name.Position = UDim2.fromOffset(8, 112)
	name.Size = UDim2.new(1, -16, 0, 19)
	local cat = Kit.Label(card, item.Category, 10, Theme.SubText())
	cat.Position = UDim2.fromOffset(8, 130)
	cat.Size = UDim2.new(1, -16, 0, 15)
	local insert = Kit.Button(card, {
		Text = "INSERT",
		TextSize = 11,
		Size = UDim2.new(1, -16, 0, 22),
		LayoutOrder = 1,
		Primary = true,
		OnClick = function()
			local ok, result = pcall(LibraryData.InsertTemplate, item)
			if ok and result then
				status.Text = "Inserted  " .. (item.DisplayName or item.Name)
				flash(card)
			else
				status.Text = "Could not insert this template"
				warn("[VfxLab] Template insert failed:", result)
			end
		end,
	})
	insert.Position = UDim2.fromOffset(8, 148)
end

local function selectTextureCard(status, card, item, selected)
	if selected() and selected().Parent then
		local old = selected()
		old.BackgroundColor3 = Theme.Surface()
		local stroke = old:FindFirstChild("SelectionStroke")
		if stroke then stroke:Destroy() end
	end
	selected(card)
	card.BackgroundColor3 = Theme.Selected()
	create "UIStroke" {
		Color = Theme.Accent(),
		Thickness = 1,
		Transparency = 0,
		Name = "SelectionStroke",
		Parent = card,
	}
	status.Text = item.Kind .. "  -  " .. tostring(item.Id)
end

local function makeTextureCard(grid, status, selected, item)
	local card = create "TextButton" {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.Surface(),
		BorderSizePixel = 0,
		Name = "Texture_" .. tostring(item.Id),
		Text = "",
		Parent = grid,
		MouseEnter = function()
			if card ~= selected() then card.BackgroundColor3 = Theme.Hover() end
		end,
		MouseLeave = function()
			card.BackgroundColor3 = card == selected() and Theme.Selected() or Theme.Surface()
		end,
		Activated = function() selectTextureCard(status, card, item, selected) end,
		create "UICorner" { CornerRadius = UDim.new(0, 12) },
		create "UIStroke" { Color = Theme.Border(), Thickness = 1, Transparency = 0.15 },
	}
	local checker = create "Frame" {
		BackgroundColor3 = Color3.fromRGB(43, 46, 52),
		BorderSizePixel = 0,
		Name = "PreviewBackground",
		Size = UDim2.new(1, -12, 0, 93),
		Position = UDim2.fromOffset(6, 6),
		Parent = card,
		create "UICorner" { CornerRadius = UDim.new(0, 5) },
	}
	create "ImageLabel" {
		BackgroundTransparency = 1,
		Name = "Preview",
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		Image = item.Asset,
		ScaleType = Enum.ScaleType.Fit,
		ResampleMode = Enum.ResamplerMode.Pixelated,
		Parent = checker,
	}
	local name = Kit.Label(card, item.Name, 11, Theme.Text())
	name.Position = UDim2.fromOffset(7, 102)
	name.Size = UDim2.new(1, -14, 0, 16)
	local kind = Kit.Label(card, item.Kind, 9, Theme.SubText())
	kind.Position = UDim2.fromOffset(7, 119)
	kind.Size = UDim2.new(1, -14, 0, 14)
	local apply = Kit.Button(card, {
		Text = "APPLY",
		TextSize = 10,
		Size = UDim2.new(1, -14, 0, 17),
		LayoutOrder = 1,
		Primary = true,
		OnClick = function()
			selectTextureCard(status, card, item, selected)
			local ok, count = pcall(LibraryData.ApplyTexture, item.Asset)
			if ok and count and count > 0 then
				status.Text = "Applied to " .. count .. " object" .. (count == 1 and "" or "s")
				card.BackgroundColor3 = Theme.Accent()
				task.delay(0.16, function()
					if card.Parent then card.BackgroundColor3 = Theme.Selected() end
				end)
			elseif ok then
				status.Text = "Select an emitter, beam, decal, or mesh first"
			else
				status.Text = "Could not apply texture"
				warn("[VfxLab] Texture apply failed:", count)
			end
		end,
	})
	apply.Position = UDim2.fromOffset(7, 136)
end

-- Returns { Window, Destroy, Open, Refresh }.
function Library.Create(parentGui)
	local refs = {}
	local stop = mount(function()
		local mode = source("Effects")
		local filter = source("All")
		local items = {}
		local selected = source(nil)
		refs.mode = mode
		refs.filter = filter
		local built = Kit.Window(parentGui, {
			Name = "VfxLabLibrary",
			Id = "library",
		Title = "LIBRARY",
		Subtitle = "Effects and textures from Assets",
		Size = UDim2.fromOffset(548, 512),
		Position = UDim2.fromScale(0.5, 0.5),
		})
		refs.window = built.Frame
		local content = built.Content
		local tabRow = create "Frame" {
			BackgroundTransparency = 1,
		LayoutOrder = 1,
		Name = "Tabs",
		Size = UDim2.new(1, 0, 0, 28),
		Parent = content,
		create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		}
		for i, tabName in ipairs({ "Effects", "Textures" }) do
			Kit.Button(tabRow, {
				Text = tabName,
			TextSize = 11,
			Size = UDim2.new(0.5, -4, 1, 0),
				LayoutOrder = i,
			Bg = function()
					return mode() == tabName and Theme.Selected() or Theme.Input()
				end,
				BrightText = true,
				OnClick = function()
					mode(tabName)
					filter("All")
					refs.search.Text = ""
					refs.search.PlaceholderText = mode() == "Effects" and "Search templates..." or "Search texture, type, or asset ID..."
					Library.Refresh()
				end,
			})
		end
		local refresh = Kit.Button(built.Frame, {
			Text = "REFRESH",
			TextSize = 10,
			Size = UDim2.fromOffset(70, 24),
			OnClick = function() Library.Refresh() end,
		})
		refresh.Position = UDim2.new(1, -112, 0, 12)
		refs.search = Kit.TextInput(content, {
			Placeholder = "Search templates...",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 31),
		})
		refs.search:GetPropertyChangedSignal("Text"):Connect(function() Library.RefreshGrid() end)
		refs.chipBar = create "ScrollingFrame" {
			BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Name = "Groups",
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Border(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = content,
	}
		refs.grid = create "ScrollingFrame" {
			BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 4,
		Name = "Grid",
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Border(),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 1, -190),
		Parent = content,
		create "UIGridLayout" {
				CellSize = UDim2.fromOffset(160, 176),
				CellPadding = UDim2.fromOffset(9, 9),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
		}
		refs.status = Kit.Label(content, "Loading...", 10, Theme.SubText())
		refs.status.LayoutOrder = 5
		refs.status.Size = UDim2.new(1, 0, 0, 16)
		refs.items = items
		refs.selected = selected
	end)
	Library._refs = refs
	Library._stop = stop
	return { Window = refs.window, Destroy = stop }
end

function Library.Destroy()
	if Library._fillStop then Library._fillStop() Library._fillStop = nil end
	if Library._stop then Library._stop() Library._stop = nil end
end

local function isEffects()
	local refs = Library._refs
	return refs and refs.mode() == "Effects"
end

local function rebuild()
	local refs = Library._refs
	if not refs or not refs.grid then return end
	local grid, status, mode, filter = refs.grid, refs.status, refs.mode, refs.filter
	for _, child in ipairs(grid:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end
	local layout = grid:FindFirstChildOfClass("UIGridLayout")
	if layout then
		layout.CellSize = isEffects() and UDim2.fromOffset(160, 176) or UDim2.fromOffset(122, 157)
	end
	local q = string.lower(refs.search.Text)
	local shown = 0
	local selected = refs.selected
	for _, item in ipairs(refs.items) do
		local group = isEffects() and item.Category or item.Kind
		local groupOk = filter() == "All" or group == filter()
		local hay
		if isEffects() then
			hay = string.lower((item.DisplayName or item.Name) .. " " .. item.Category .. " " .. item.Path)
		else
			hay = string.lower(item.Name .. " " .. item.Kind .. " " .. item.Path .. " " .. tostring(item.Id))
		end
		if groupOk and (q == "" or string.find(hay, q, 1, true)) then
			shown += 1
			if isEffects() then
				makeEffectCard(grid, status, item)
			else
				selected(nil)
			makeTextureCard(grid, status, selected, item)
			end
		end
	end
	local unit = isEffects() and "template" or "texture"
	status.Text = shown == 1 and ("1 " .. unit) or (tostring(shown) .. " " .. unit .. "s")
end

local function buildChips()
	local refs = Library._refs
	if not refs then return end
	local chipBar, mode, filter, items = refs.chipBar, refs.mode, refs.filter, refs.items
	for _, child in ipairs(chipBar:GetChildren()) do child:Destroy() end
	local list, seen = { "All" }, { All = true }
	for _, item in ipairs(items) do
		local group = mode() == "Effects" and item.Category or item.Kind
		if not seen[group] then
			seen[group] = true
			table.insert(list, group)
		end
	end
	table.sort(list, function(a, b)
		if a == "All" then return true end
		if b == "All" then return false end
		return a < b
	end)
	create "UIListLayout" {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = chipBar,
	}
	for _, name in ipairs(list) do
		local isCurrent = filter() == name
		local b = Kit.Button(chipBar, {
			Text = name,
			TextSize = 10,
			Size = UDim2.fromOffset(62, 25),
			Primary = isCurrent,
			BrightText = isCurrent,
			OnClick = function()
				filter(name)
				Library.RefreshGrid()
			end,
		})
		b.Name = "Group_" .. name
		b.AutomaticSize = Enum.AutomaticSize.X
		create "UIPadding" {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = b,
		}
	end
end

-- Rebuilds chips + grid inside a disposable scope (Vide bindings need one).
function Library.RefreshGrid()
	local refs = Library._refs
	if not refs then return end
	if Library._fillStop then Library._fillStop() end
	for _, child in ipairs(refs.chipBar:GetChildren()) do child:Destroy() end
	for _, child in ipairs(refs.grid:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end
	Library._fillStop = mount(function()
		buildChips()
		rebuild()
	end)
end

function Library.Refresh()
	local refs = Library._refs
	if not refs then return end
	if refs.mode() == "Effects" then
		refs.items = LibraryData.GetTemplates()
	else
		refs.items = LibraryData.GetTextures()
	end
	Library.RefreshGrid()
end

function Library.Open()
	if not Library._refs or not Library._refs.window then return end
	Library.Refresh()
	Kit.TogglePanel(Library._refs.window, true)
end

return Library
