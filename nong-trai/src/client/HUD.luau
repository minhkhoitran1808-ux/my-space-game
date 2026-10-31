--[[
	HUD: đồng hồ & mùa (giữa trên), Xu (trái trên), nút Túi đồ / Đi lại.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local Panels = require(script.Parent.UI.Panels)
local State = require(script.Parent.State)

local HUD = {}
local C = Theme.Colors
local create = Components.create

local function sideButton(parent: Instance, order: number, icon: string, caption: string, color: Color3, dark: Color3, onClick: () -> ())
	local root, button = Components.button({
		Text = "",
		Color = color,
		Dark = dark,
		Size = UDim2.fromOffset(60, 64),
		LayoutOrder = order,
		Parent = parent,
	})
	Components.text({
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.fromOffset(0, 4),
		Text = icon,
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	Components.text({
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -20),
		Text = caption,
		TextSize = 12,
		TextColor3 = C.White,
		FontFace = Theme.Font.Heavy,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	button.Activated:Connect(onClick)
	return root
end

function HUD.init(gui: ScreenGui)
	-- ===== Đồng hồ =====
	local clockCard = Components.panel({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(0, 58),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = gui,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 8) }).Parent = clockCard
	Components.list(Enum.FillDirection.Horizontal, 10).Parent = clockCard

	local timeColumn = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(110, 50),
		LayoutOrder = 1,
		Parent = clockCard,
	})
	local dayLabel = Components.text({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 4),
		TextSize = 13,
		TextColor3 = C.InkSoft,
		FontFace = Theme.Font.Heavy,
		Text = "",
		Parent = timeColumn,
	})
	local clockLabel = Components.text({
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.fromOffset(0, 21),
		TextSize = 26,
		FontFace = Theme.Font.Heavy,
		Text = "",
		Parent = timeColumn,
	})
	local seasonChip = Components.text({
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		TextSize = 17,
		FontFace = Theme.Font.Heavy,
		Text = "",
		LayoutOrder = 2,
		Parent = clockCard,
	})
	Components.corner(12).Parent = seasonChip
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }).Parent = seasonChip
	local seasonStroke = Components.stroke(C.Ink, 3)
	seasonStroke.Parent = seasonChip

	task.spawn(function()
		while clockCard.Parent do
			local info = State.time()
			dayLabel.Text = string.format("NGÀY %d · NĂM %d", info.dayOfSeason, info.year)
			clockLabel.Text = info.clock
			seasonChip.Text = "Mùa " .. info.season
			local colors = Theme.Seasons[info.season]
			seasonChip.BackgroundColor3 = colors.Fill
			seasonStroke.Color = colors.Border
			task.wait(0.5)
		end
	end)

	-- ===== Xu + nút bên trái =====
	local leftLayout = Components.list(Enum.FillDirection.Vertical, 8)
	leftLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	local left = create("Frame", {
		Name = "Left",
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.fromOffset(160, 240),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { leftLayout })

	local coinPill = create("Frame", {
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.Cream,
		LayoutOrder = 1,
		Parent = left,
	}, { Components.corner(22), Components.stroke(C.SunDark, 3), Components.list(Enum.FillDirection.Horizontal, 8) })
	create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14) }).Parent = coinPill
	create("Frame", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = C.Sun,
		LayoutOrder = 1,
		Parent = coinPill,
	}, { Components.corner(14), Components.stroke(C.SunDark, 3) })
	local coinLabel = Components.text({
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 22,
		FontFace = Theme.Font.Heavy,
		Text = "...",
		LayoutOrder = 2,
		Parent = coinPill,
	})

	sideButton(left, 2, "🎒", "Túi đồ", C.Bag, C.SoilDark, function()
		Panels.toggle("Inventory")
	end)
	sideButton(left, 3, "🧭", "Đi lại", C.Water, C.WaterDark, function()
		Panels.toggle("Travel")
	end)

	State.onChanged(function(data)
		coinLabel.Text = Format.number(data.coins)
	end)
end

return HUD
