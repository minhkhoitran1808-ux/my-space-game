--[[
	Inventory: túi đồ: nông sản (theo sao), hạt giống, phân bón, nước.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FarmLogic = require(ReplicatedStorage.Shared.FarmLogic)
local Format = require(ReplicatedStorage.Shared.Format)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local Panels = require(script.Parent.UI.Panels)
local State = require(script.Parent.State)

local Inventory = {}
local C = Theme.Colors
local create = Components.create

function Inventory.init(gui: ScreenGui)
	local panel = Components.panel({
		Name = "Inventory",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.84),
		Parent = gui,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(560, 440) }).Parent = panel

	Components.text({
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -90, 0, 30),
		Text = "Túi đồ",
		TextSize = 26,
		FontFace = Theme.Font.Heavy,
		TextColor3 = C.Leaf,
		Parent = panel,
	})
	Components.closeButton(panel, function()
		Panels.close("Inventory")
	end)

	local list = create("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 64),
		Size = UDim2.new(1, -24, 1, -76),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.InkSoft,
		Parent = panel,
	}, { Components.list(Enum.FillDirection.Vertical, 6) })

	local order = 0
	local function header(text: string)
		order += 1
		Components.text({ Size = UDim2.new(1, 0, 0, 28), Text = text, TextSize = 18, FontFace = Theme.Font.Heavy, LayoutOrder = order, Parent = list })
	end
	local function row(color: Color3, name: string, right: string)
		order += 1
		local frame = create("Frame", {
			Size = UDim2.new(1, -8, 0, 44),
			BackgroundColor3 = C.White,
			LayoutOrder = order,
			Parent = list,
		}, { Components.corner(12), Components.stroke(C.CreamBorder, 2) })
		create("Frame", { Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = color, Parent = frame }, {
			Components.corner(13),
			Components.stroke(C.Ink, 2),
		})
		Components.text({ Position = UDim2.fromOffset(46, 0), Size = UDim2.new(0.55, -46, 1, 0), Text = name, TextSize = 16, Parent = frame })
		Components.text({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Text = right,
			TextSize = 15,
			TextColor3 = C.InkSoft,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = frame,
		})
	end
	local function note(text: string)
		order += 1
		Components.text({ Size = UDim2.new(1, 0, 0, 22), Text = text, TextSize = 14, TextColor3 = C.InkSoft, LayoutOrder = order, Parent = list })
	end

	local function render()
		Components.clear(list)
		order = 0
		local data = State.data
		if not data then
			return
		end
		local season = State.time().season

		header("Nông sản (bán ở Quầy thu mua, Đảo Chợ)")
		local total, any = 0, false
		for _, cropId in ipairs(Crops.Order) do
			for stars = 3, 1, -1 do
				local count = data.produce[Format.produceKey(cropId, stars)] or 0
				if count > 0 then
					any = true
					local def = Crops.List[cropId]
					local price = FarmLogic.sellPrice(cropId, stars, Crops, Cfg)
					total += price * count
					row(Color3.fromRGB(def.Color[1], def.Color[2], def.Color[3]), def.Name .. " " .. Format.stars(stars), string.format("x%d · %s Xu/cái", count, Format.number(price)))
				end
			end
		end
		if any then
			note("Tổng giá trị: " .. Format.number(total) .. " Xu")
		else
			note("Chưa có nông sản. Thu hoạch bằng Liềm khi cây chín.")
		end

		header("Hạt giống")
		any = false
		for _, cropId in ipairs(Crops.Order) do
			local count = data.seeds[cropId] or 0
			if count > 0 then
				any = true
				local def = Crops.List[cropId]
				row(
					Color3.fromRGB(def.Color[1], def.Color[2], def.Color[3]),
					def.Name,
					string.format("x%d · mùa %s%s", count, def.Season, if def.Season == season then "" else " (chờ mùa)")
				)
			end
		end
		if not any then
			note("Hết hạt giống. Mua ở Tiệm hạt trên Đảo Chợ.")
		end

		header("Vật dụng")
		row(C.Soil, "Phân bón", "x" .. tostring(data.fertilizer))
		row(C.Water, "Nước trong bình", string.format("%d/%d", data.water, Cfg.WaterCapacity))
		row(C.Sun, "Đã thu hoạch tổng cộng", Format.number(data.totalHarvested))
	end

	Panels.register("Inventory", panel, render)
	State.onChanged(function()
		if panel.Visible then
			render()
		end
	end)
end

return Inventory
