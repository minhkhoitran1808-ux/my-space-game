--[[
	Shop: Tiệm hạt Bà Bảy, chỉ bán hạt của mùa hiện tại, cùng phân bón.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FarmLogic = require(ReplicatedStorage.Shared.FarmLogic)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local Panels = require(script.Parent.UI.Panels)
local State = require(script.Parent.State)

local Shop = {}
local C = Theme.Colors
local create = Components.create

local BuySeed = Remotes.event("BuySeed")
local BuyItem = Remotes.event("BuyItem")

function Shop.init(gui: ScreenGui)
	local panel = Components.panel({
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.84),
		Parent = gui,
	})
	create("UISizeConstraint", { MaxSize = Vector2.new(780, 440) }).Parent = panel

	Components.text({
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -200, 0, 30),
		Text = "Tiệm hạt Bà Bảy",
		TextSize = 26,
		FontFace = Theme.Font.Heavy,
		TextColor3 = C.Leaf,
		Parent = panel,
	})
	local subtitle = Components.text({
		Position = UDim2.fromOffset(18, 42),
		Size = UDim2.new(1, -200, 0, 18),
		TextSize = 14,
		TextColor3 = C.InkSoft,
		Parent = panel,
	})
	local coins = Components.text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -70, 0, 18),
		Size = UDim2.fromOffset(120, 30),
		TextSize = 20,
		FontFace = Theme.Font.Heavy,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	Components.closeButton(panel, function()
		Panels.close("Shop")
	end)

	local grid = create("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 70),
		Size = UDim2.new(1, -24, 1, -82),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.InkSoft,
		Parent = panel,
	}, {
		create("UIGridLayout", {
			CellSize = UDim2.new(1 / 3, -8, 0, 166),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function card(order: number, color: Color3, name: string, line1: string, line2: string, tag: string?, onBuy: (number) -> ())
		local frame = create("Frame", { BackgroundColor3 = C.White, LayoutOrder = order, Parent = grid }, {
			Components.corner(16),
			Components.stroke(C.CreamBorder, 3),
		})
		create("Frame", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(40, 40),
			BackgroundColor3 = color,
			Parent = frame,
		}, { Components.corner(20), Components.stroke(C.Ink, 2) })
		Components.text({ Position = UDim2.fromOffset(58, 8), Size = UDim2.new(1, -66, 0, 22), Text = name, TextSize = 18, FontFace = Theme.Font.Heavy, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame })
		Components.text({ Position = UDim2.fromOffset(58, 30), Size = UDim2.new(1, -66, 0, 18), Text = line1, TextSize = 13, TextColor3 = C.InkSoft, Parent = frame })
		Components.text({ Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 18), Text = line2, TextSize = 13, TextWrapped = true, Parent = frame })
		if tag then
			local label = Components.text({
				Position = UDim2.fromOffset(10, 78),
				Size = UDim2.new(1, -20, 0, 20),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(227, 242, 228),
				TextColor3 = C.LeafDark,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = tag,
				Parent = frame,
			})
			Components.corner(8).Parent = label
		end
		for i, amount in ipairs({ 1, 5 }) do
			local _, button = Components.button({
				Text = "Mua " .. amount,
				Color = C.Leaf,
				Dark = C.LeafDark,
				TextSize = 16,
				Size = UDim2.new(0.5, -14, 0, 50),
				Position = UDim2.new(if i == 1 then 0 else 0.5, if i == 1 then 10 else 4, 1, -58),
				Parent = frame,
			})
			button.Activated:Connect(function()
				onBuy(amount)
			end)
		end
	end

	local function render()
		Components.clear(grid)
		local data = State.data
		local season = State.time().season
		subtitle.Text = "Mùa " .. season .. ": hạt mùa khác sẽ bán khi tới mùa"
		coins.Text = if data then Format.number(data.coins) .. " Xu" else ""

		local order = 0
		for _, cropId in ipairs(Crops.Order) do
			local def = Crops.List[cropId]
			if def.Season == season then
				order += 1
				card(
					order,
					Color3.fromRGB(def.Color[1], def.Color[2], def.Color[3]),
					def.Name,
					"Lớn trong " .. def.Days .. " ngày",
					string.format("Hạt %s Xu · Bán %s–%s Xu", Format.number(def.SeedPrice), Format.number(def.SellPrice), Format.number(FarmLogic.sellPrice(cropId, 3, Crops, Cfg))),
					if def.Regrow then "Thu nhiều lần · ra quả lại sau " .. def.Regrow .. " ngày" else nil,
					function(amount)
						BuySeed:FireServer(cropId, amount)
					end
				)
			end
		end
		card(
			order + 1,
			C.Soil,
			"Phân bón",
			"Đang có: " .. (if data then tostring(data.fertilizer) else "0"),
			string.format("%d Xu/bao · +%d màu mỡ cho 1 ô", Cfg.FertilizerPrice, Cfg.Fertility.FertilizerGain),
			"Đất màu mỡ giúp nông sản đạt 3 sao",
			function(amount)
				BuyItem:FireServer("Fertilizer", amount)
			end
		)
	end

	Panels.register("Shop", panel, render)
	State.onChanged(function()
		if panel.Visible then
			render()
		end
	end)
	Remotes.event("OpenShop").OnClientEvent:Connect(function()
		Panels.open("Shop")
	end)
end

return Shop
