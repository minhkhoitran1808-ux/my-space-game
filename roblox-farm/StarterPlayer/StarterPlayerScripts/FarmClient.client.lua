--[[
	FarmClient (LocalScript)
	Đặt tại: StarterPlayer > StarterPlayerScripts > FarmClient

	Giao diện người chơi (tự tạo bằng code, dùng được trên máy tính & điện thoại):
	- Bảng Xu / túi nông sản (góc trên trái)
	- Nút 🛒 Cửa hàng: tab Hạt giống & Nâng cấp
	- Thanh chọn hạt giống (dưới màn hình)
	- Thông báo nổi
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BuySeed = Remotes:WaitForChild("BuySeed")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local SelectSeed = Remotes:WaitForChild("SelectSeed")
local GetState = Remotes:WaitForChild("GetState")
local StateChanged = Remotes:WaitForChild("StateChanged")
local Notify = Remotes:WaitForChild("Notify")
local OpenShop = Remotes:WaitForChild("OpenShop")

local FONT = Enum.Font.GothamBold
local WHITE = Color3.new(1, 1, 1)
local PANEL = Color3.fromRGB(35, 45, 30)
local ROW = Color3.fromRGB(55, 70, 45)
local GREEN = Color3.fromRGB(70, 170, 70)
local GREY = Color3.fromRGB(100, 100, 100)
local GOLD = Color3.fromRGB(255, 210, 60)
local RED = Color3.fromRGB(200, 60, 60)
local BLUE = Color3.fromRGB(60, 130, 210)

local state = nil
local currentTab = "Seeds"

-- ===================== Hàm dựng giao diện =====================
local function create(className: string, props, children)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius: number?)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color: Color3, thickness: number?)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function label(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextSize = props.TextSize or 16
	return create("TextLabel", props)
end

local function button(props, children)
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextSize = props.TextSize or 16
	props.AutoButtonColor = true
	children = children or {}
	table.insert(children, corner(8))
	return create("TextButton", props, children)
end

local function clearGuiChildren(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local gui = create("ScreenGui", {
	Name = "FarmUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

-- ===================== Bảng thông tin (trên trái) =====================
local statsFrame = create("Frame", {
	Position = UDim2.fromOffset(12, 12),
	Size = UDim2.fromOffset(230, 86),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { corner(12), stroke(GOLD, 2) })

local coinsLabel = label({
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 0, 34),
	Text = "💰 Đang tải...",
	TextSize = 24,
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statsFrame,
})

local bagLabel = label({
	Position = UDim2.fromOffset(12, 42),
	Size = UDim2.new(1, -24, 0, 18),
	Text = "",
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statsFrame,
})

local harvestLabel = label({
	Position = UDim2.fromOffset(12, 62),
	Size = UDim2.new(1, -24, 0, 18),
	Text = "",
	TextSize = 13,
	TextColor3 = Color3.fromRGB(200, 220, 190),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = statsFrame,
})

local shopButton = button({
	Position = UDim2.fromOffset(12, 108),
	Size = UDim2.fromOffset(160, 44),
	BackgroundColor3 = BLUE,
	Text = "🛒 Cửa hàng",
	TextSize = 20,
	Parent = gui,
}, { stroke(WHITE, 2) })

-- ===================== Thanh hạt giống (dưới) =====================
local seedBar = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(0, 64),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

-- ===================== Cửa hàng =====================
local shopFrame = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.75),
	BackgroundColor3 = PANEL,
	Visible = false,
	Parent = gui,
}, {
	corner(14),
	stroke(GOLD, 3),
	create("UISizeConstraint", { MaxSize = Vector2.new(560, 460) }),
})

label({
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.new(1, -70, 0, 36),
	Text = "🛒 Cửa hàng Nông Trại",
	TextSize = 22,
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = shopFrame,
})

local closeButton = button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(36, 36),
	BackgroundColor3 = RED,
	Text = "X",
	TextSize = 20,
	Parent = shopFrame,
})

local seedsTab = button({
	Position = UDim2.fromOffset(16, 52),
	Size = UDim2.new(0.5, -20, 0, 36),
	Text = "🌱 Hạt giống",
	Parent = shopFrame,
})

local upgradesTab = button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 52),
	Size = UDim2.new(0.5, -20, 0, 36),
	Text = "⬆️ Nâng cấp",
	Parent = shopFrame,
})

local list = create("ScrollingFrame", {
	Position = UDim2.fromOffset(12, 98),
	Size = UDim2.new(1, -24, 1, -110),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	Parent = shopFrame,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	create("UIPadding", { PaddingRight = UDim.new(0, 8) }),
})

-- ===================== Thông báo =====================
local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.new(0.9, 0, 0, 200),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UISizeConstraint", { MaxSize = Vector2.new(420, 200) }),
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local toastCount = 0
local function showToast(text: string, kind: string?)
	toastCount += 1
	local color = if kind == "error" then RED elseif kind == "success" then GREEN else BLUE

	local toast = label({
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.1,
		Text = text,
		TextSize = 16,
		TextWrapped = true,
		LayoutOrder = toastCount,
		Parent = toastHolder,
	})
	corner(8).Parent = toast

	-- Giữ tối đa 4 thông báo
	local toasts = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #toasts - 4 do
		toasts[i]:Destroy()
	end

	task.delay(2.5, function()
		if toast.Parent then
			local tween = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

-- ===================== Vẽ lại theo dữ liệu =====================
local function renderStats()
	if not state then
		return
	end
	coinsLabel.Text = "💰 " .. GameConfig.formatNumber(state.coins) .. " Xu"

	local bagCount, bagValue = 0, 0
	for cropId, amount in pairs(state.crops) do
		if GameConfig.Crops[cropId] then
			bagCount += amount
			bagValue += amount * GameConfig.getSellPrice(cropId, state.upgrades.Merchant)
		end
	end
	bagLabel.Text = string.format("🧺 Túi: %d nông sản (~%s Xu)", bagCount, GameConfig.formatNumber(bagValue))
	harvestLabel.Text = "🌾 Đã thu hoạch: " .. GameConfig.formatNumber(state.totalHarvested)
end

local function renderSeedBar()
	clearGuiChildren(seedBar)
	if not state then
		return
	end

	local hasAny = false
	for order, cropId in ipairs(GameConfig.CropOrder) do
		local count = state.seeds[cropId] or 0
		if count > 0 then
			hasAny = true
			local crop = GameConfig.Crops[cropId]
			local selected = state.selectedSeed == cropId
			local seedButton = button({
				Size = UDim2.fromOffset(68, 64),
				BackgroundColor3 = if selected then Color3.fromRGB(90, 120, 60) else PANEL,
				BackgroundTransparency = 0.1,
				Text = crop.Emoji .. "\nx" .. count,
				TextSize = 18,
				LayoutOrder = order,
				Parent = seedBar,
			}, { stroke(if selected then GOLD else Color3.fromRGB(120, 140, 110), if selected then 3 else 1) })

			seedButton.Activated:Connect(function()
				SelectSeed:FireServer(cropId)
			end)
		end
	end

	if not hasAny then
		label({
			Size = UDim2.fromOffset(300, 40),
			BackgroundColor3 = PANEL,
			BackgroundTransparency = 0.2,
			Text = "Hết hạt giống – mở 🛒 Cửa hàng!",
			Parent = seedBar,
		})
	end
end

local function makeRow(order: number, emoji: string, title: string, info: string)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = ROW,
		LayoutOrder = order,
		Parent = list,
	}, { corner(10) })

	label({
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.fromOffset(48, 76),
		Text = emoji,
		TextSize = 34,
		Parent = row,
	})
	label({
		Position = UDim2.fromOffset(60, 8),
		Size = UDim2.new(1, -220, 0, 22),
		Text = title,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	label({
		Position = UDim2.fromOffset(60, 32),
		Size = UDim2.new(1, -220, 0, 38),
		Text = info,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(210, 225, 200),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = row,
	})
	return row
end

local function renderSeedsTab()
	for order, cropId in ipairs(GameConfig.CropOrder) do
		local crop = GameConfig.Crops[cropId]
		local unlocked = state.totalHarvested >= crop.Unlock
		local growTime = GameConfig.getGrowTime(cropId, state.upgrades.Fertilizer)
		local sellPrice = GameConfig.getSellPrice(cropId, state.upgrades.Merchant)

		local info
		if unlocked then
			info = string.format(
				"Giá hạt: %s Xu • Lớn: %s • Bán: %s Xu • Đang có: %d",
				GameConfig.formatNumber(crop.SeedPrice),
				GameConfig.formatTime(growTime),
				GameConfig.formatNumber(sellPrice),
				state.seeds[cropId] or 0
			)
		else
			info = string.format("🔒 Thu hoạch %d cây để mở khoá (còn %d)", crop.Unlock, crop.Unlock - state.totalHarvested)
		end

		local row = makeRow(order, crop.Emoji, crop.Name, info)

		for i, amount in ipairs({ 1, 10 }) do
			local affordable = unlocked and state.coins >= crop.SeedPrice * amount
			local buyButton = button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, if i == 1 then -84 else -8, 0.5, 0),
				Size = UDim2.fromOffset(72, 44),
				BackgroundColor3 = if affordable then GREEN else GREY,
				Text = "Mua " .. amount,
				TextSize = 15,
				Parent = row,
			})
			buyButton.Activated:Connect(function()
				BuySeed:FireServer(cropId, amount)
			end)
		end
	end
end

local function renderUpgradesTab()
	for order, upgradeId in ipairs(GameConfig.UpgradeOrder) do
		local upgrade = GameConfig.Upgrades[upgradeId]
		local level = state.upgrades[upgradeId] or 0
		local maxLevel = #upgrade.Costs
		local cost = GameConfig.getUpgradeCost(upgradeId, level)

		local info = string.format("%s\nCấp %d/%d", upgrade.Description, level, maxLevel)
		if upgradeId == "Expand" then
			info ..= string.format(" • Đang có %d ô đất", state.tileCount)
		end

		local row = makeRow(order, upgrade.Emoji, upgrade.Name, info)

		local affordable = cost ~= nil and state.coins >= cost
		local upgradeButton = button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(148, 44),
			BackgroundColor3 = if cost == nil then GOLD elseif affordable then GREEN else GREY,
			TextColor3 = if cost == nil then Color3.new(0, 0, 0) else WHITE,
			Text = if cost then "⬆ " .. GameConfig.formatNumber(cost) .. " Xu" else "TỐI ĐA",
			TextSize = 15,
			Parent = row,
		})
		upgradeButton.Activated:Connect(function()
			if cost then
				BuyUpgrade:FireServer(upgradeId)
			end
		end)
	end
end

local function renderShop()
	seedsTab.BackgroundColor3 = if currentTab == "Seeds" then GREEN else GREY
	upgradesTab.BackgroundColor3 = if currentTab == "Upgrades" then GREEN else GREY
	if not shopFrame.Visible or not state then
		return
	end
	clearGuiChildren(list)
	if currentTab == "Seeds" then
		renderSeedsTab()
	else
		renderUpgradesTab()
	end
end

local function renderAll()
	renderStats()
	renderSeedBar()
	renderShop()
end

-- ===================== Sự kiện =====================
local function setShopVisible(visible: boolean)
	shopFrame.Visible = visible
	renderShop()
end

shopButton.Activated:Connect(function()
	setShopVisible(not shopFrame.Visible)
end)
closeButton.Activated:Connect(function()
	setShopVisible(false)
end)
seedsTab.Activated:Connect(function()
	currentTab = "Seeds"
	renderShop()
end)
upgradesTab.Activated:Connect(function()
	currentTab = "Upgrades"
	renderShop()
end)

OpenShop.OnClientEvent:Connect(function()
	setShopVisible(true)
end)

Notify.OnClientEvent:Connect(function(text, kind)
	showToast(text, kind)
end)

StateChanged.OnClientEvent:Connect(function(newState)
	state = newState
	renderAll()
end)

renderShop()

-- Lấy dữ liệu ban đầu (nếu server chưa tải xong, StateChanged sẽ gửi sau)
task.spawn(function()
	local ok, initialState = pcall(function()
		return GetState:InvokeServer()
	end)
	if ok and initialState and not state then
		state = initialState
		renderAll()
	end
end)
