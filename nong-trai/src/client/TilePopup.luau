--[[
	TilePopup: bảng nhỏ cho biết tình trạng ô đất đang nhắm
	(cây gì, ngày mấy, sao chất lượng, ướt/khô, cỏ, sâu, màu mỡ, nên làm gì tiếp).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Format = require(ReplicatedStorage.Shared.Format)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local State = require(script.Parent.State)
local ToolController = require(script.Parent.ToolController)

local TilePopup = {}
local C = Theme.Colors
local create = Components.create

local function chip(parent: Instance, text: string, bg: Color3, fg: Color3, order: number)
	local label = Components.text({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = bg,
		TextColor3 = fg,
		TextSize = 13,
		FontFace = Theme.Font.Heavy,
		Text = text,
		LayoutOrder = order,
		Parent = parent,
	})
	Components.corner(8).Parent = label
	create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }).Parent = label
end

-- Ô đất nằm trong Island > Tiles > ô. Trả về chủ đảo (nếu đang online).
local function ownerOf(tile: BasePart): Player?
	local island = tile.Parent and tile.Parent.Parent
	local ownerId = island and island:GetAttribute("OwnerId")
	if type(ownerId) ~= "number" or ownerId == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(ownerId)
end

function TilePopup.init(gui: ScreenGui)
	local panel = Components.panel({
		Name = "TilePopup",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.45, 0),
		Size = UDim2.fromOffset(230, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = gui,
	})
	Components.padding(10).Parent = panel
	local layout = Components.list(Enum.FillDirection.Vertical, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = panel

	local title = Components.text({ Size = UDim2.new(1, 0, 0, 22), TextSize = 19, FontFace = Theme.Font.Heavy, LayoutOrder = 1, Parent = panel })
	local subtitle = Components.text({ Size = UDim2.new(1, 0, 0, 16), TextSize = 13, TextColor3 = C.InkSoft, LayoutOrder = 2, Parent = panel })
	local stars = Components.text({ Size = UDim2.new(1, 0, 0, 20), TextSize = 18, TextColor3 = C.SunDark, FontFace = Theme.Font.Heavy, LayoutOrder = 3, Parent = panel })
	local chips = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = panel,
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.fromOffset(100, 22),
			CellPadding = UDim2.fromOffset(4, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local fertRow = create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 5, Parent = panel })
	Components.text({ Size = UDim2.fromOffset(62, 16), Text = "Màu mỡ", TextSize = 12, TextColor3 = C.InkSoft, Parent = fertRow })
	local fertTrack = create("Frame", {
		Position = UDim2.fromOffset(66, 4),
		Size = UDim2.new(1, -66, 0, 8),
		BackgroundColor3 = C.Track,
		Parent = fertRow,
	}, { Components.corner(4) })
	local fertFill = create("Frame", { Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = C.Soil, Parent = fertTrack }, { Components.corner(4) })
	local hint = Components.text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = C.Leaf,
		FontFace = Theme.Font.Heavy,
		LayoutOrder = 6,
		Parent = panel,
	})

	local function render(tile: BasePart)
		local state = tile:GetAttribute("State")
		local cropId = tile:GetAttribute("Crop")
		local watered = tile:GetAttribute("Watered") == true
		local weed = tile:GetAttribute("Weed") == true
		local pest = tile:GetAttribute("Pest") == true
		local fertility = tile:GetAttribute("Fertility") or 0
		local season = State.time().season
		local owner = ownerOf(tile)

		Components.clear(chips)
		stars.Visible = false
		fertRow.Visible = state == "tilled"
		fertFill.Size = UDim2.fromScale(math.clamp(fertility / 100, 0, 1), 1)
		local nextStep = ""

		if state == "debris" then
			title.Text = "Đá / gốc cây"
			subtitle.Text = "Cuốc thêm " .. tostring(tile:GetAttribute("Hp") or 1) .. " nhát để dọn"
			nextStep = "Dùng Cuốc"
		elseif state == "grass" then
			title.Text = "Đất cỏ"
			subtitle.Text = "Chưa trồng được"
			nextStep = "Dùng Cuốc để làm luống"
		elseif type(cropId) == "string" and Crops.List[cropId] then
			local def = Crops.List[cropId]
			local growth = tonumber(tile:GetAttribute("Growth")) or 0
			local ripe = growth >= def.Days
			title.Text = def.Name
			subtitle.Text = if ripe then "Đã chín!" else string.format("Ngày %s/%d", tostring(math.floor(growth * 10) / 10), def.Days)
			stars.Visible = true
			stars.Text = Format.stars(tonumber(tile:GetAttribute("Stars")) or 1)
			if ripe then
				nextStep = "Dùng Liềm để thu hoạch"
			elseif pest then
				nextStep = "Dùng Bình xịt diệt sâu"
			elseif weed then
				nextStep = "Dùng Liềm cắt cỏ"
			elseif not watered then
				nextStep = "Dùng Bình tưới"
			elseif fertility < Cfg.Fertility.Good then
				nextStep = "Bón phân để được 3 sao"
			else
				nextStep = "Chờ sáng mai cây sẽ lớn"
			end
			if def.Season ~= season then
				chip(chips, "Trái mùa", C.GreyDark, C.White, 0)
				nextStep = "Trái mùa: cây đứng yên tới mùa " .. def.Season
			end
		else
			title.Text = "Đất đã cuốc"
			subtitle.Text = "Sẵn sàng gieo hạt"
			nextStep = if weed then "Dùng Liềm cắt cỏ" else "Dùng Túi hạt để gieo"
		end

		if state == "tilled" then
			chip(chips, if watered then "Đất ướt" else "Đất khô", if watered then C.Water else C.Bag, C.White, 1)
			if weed then
				chip(chips, "Có cỏ dại", C.Danger, C.White, 2)
			end
			if pest then
				chip(chips, "Có sâu", C.Danger, C.White, 3)
			end
		end

		if owner and owner ~= Players.LocalPlayer then
			nextStep = "Đảo của " .. owner.DisplayName .. ": bạn có thể tưới, cắt cỏ, diệt sâu giúp."
		end
		hint.Text = nextStep
	end

	task.spawn(function()
		while panel.Parent do
			local tile = ToolController.target()
			panel.Visible = tile ~= nil
			if tile then
				render(tile)
			end
			task.wait(0.15)
		end
	end)
end

return TilePopup
