--[[
	GameConfig (ModuleScript)
	Đặt tại: ReplicatedStorage > GameConfig

	Toàn bộ thông số cân bằng game nằm ở đây. Muốn đổi giá, thời gian lớn,
	thêm cây mới... chỉ cần sửa file này (server và client đều dùng chung).
]]

local GameConfig = {}

-- ===== Cài đặt chung =====
GameConfig.DataStoreName = "NongTraiTycoon_v1" -- đổi tên này = xoá sạch tiến trình cũ của mọi người
GameConfig.StartingCoins = 50
GameConfig.StartingSeeds = { Wheat = 3 } -- người chơi mới được tặng
GameConfig.AutoSaveInterval = 60 -- giây

-- ===== Ruộng =====
GameConfig.MaxPlots = 6 -- số mảnh ruộng trên bản đồ = số người tối đa mỗi server
GameConfig.TilesPerRow = 4
GameConfig.MaxTiles = 16
GameConfig.BaseTiles = 4 -- số ô đất lúc mới vào
GameConfig.TilesPerExpand = 4 -- mỗi cấp "Mở rộng ruộng" thêm bao nhiêu ô

-- ===== Tưới giúp (co-op) =====
GameConfig.WaterSpeedup = 0.2 -- tưới nước giảm 20% tổng thời gian lớn (1 lần / mỗi lần trồng)
GameConfig.HelperReward = 2 -- Xu thưởng khi tưới giúp ruộng người khác

-- ===== Cây trồng =====
-- SeedPrice: giá 1 hạt | GrowTime: số giây để chín | SellPrice: giá bán 1 nông sản
-- Unlock: cần đã thu hoạch tổng cộng bao nhiêu cây thì mới mua được hạt này
GameConfig.CropOrder = { "Wheat", "Carrot", "Tomato", "Pumpkin", "Watermelon", "GoldenCorn" }

GameConfig.Crops = {
	Wheat = {
		Name = "Lúa mì",
		Emoji = "🌾",
		SeedPrice = 5,
		GrowTime = 10,
		SellPrice = 10,
		Unlock = 0,
		Color = Color3.fromRGB(235, 200, 90),
	},
	Carrot = {
		Name = "Cà rốt",
		Emoji = "🥕",
		SeedPrice = 15,
		GrowTime = 20,
		SellPrice = 32,
		Unlock = 10,
		Color = Color3.fromRGB(255, 140, 40),
	},
	Tomato = {
		Name = "Cà chua",
		Emoji = "🍅",
		SeedPrice = 40,
		GrowTime = 35,
		SellPrice = 90,
		Unlock = 30,
		Color = Color3.fromRGB(225, 50, 50),
	},
	Pumpkin = {
		Name = "Bí ngô",
		Emoji = "🎃",
		SeedPrice = 100,
		GrowTime = 60,
		SellPrice = 240,
		Unlock = 75,
		Color = Color3.fromRGB(255, 120, 0),
	},
	Watermelon = {
		Name = "Dưa hấu",
		Emoji = "🍉",
		SeedPrice = 250,
		GrowTime = 90,
		SellPrice = 620,
		Unlock = 150,
		Color = Color3.fromRGB(60, 170, 60),
	},
	GoldenCorn = {
		Name = "Ngô vàng",
		Emoji = "🌽",
		SeedPrice = 600,
		GrowTime = 150,
		SellPrice = 1600,
		Unlock = 300,
		Color = Color3.fromRGB(255, 215, 0),
	},
}

-- ===== Nâng cấp =====
-- Costs[i] = giá để lên cấp i. Hết danh sách = cấp tối đa.
GameConfig.UpgradeOrder = { "Expand", "Fertilizer", "Merchant" }

GameConfig.Upgrades = {
	Expand = {
		Name = "Mở rộng ruộng",
		Emoji = "🚜",
		Description = "+4 ô đất để trồng",
		Costs = { 150, 600, 2000 },
	},
	Fertilizer = {
		Name = "Phân bón",
		Emoji = "🧪",
		Description = "Cây lớn nhanh hơn 15% mỗi cấp",
		Costs = { 100, 400, 1200, 3500, 8000 },
	},
	Merchant = {
		Name = "Thương lái",
		Emoji = "💰",
		Description = "Bán nông sản giá cao hơn 20% mỗi cấp",
		Costs = { 200, 800, 2500, 6000, 15000 },
	},
}

-- ===== Công thức (dùng chung cho server & client) =====
function GameConfig.getTileCount(expandLevel: number): number
	return math.min(GameConfig.BaseTiles + expandLevel * GameConfig.TilesPerExpand, GameConfig.MaxTiles)
end

function GameConfig.getGrowTime(cropId: string, fertilizerLevel: number): number
	local crop = GameConfig.Crops[cropId]
	return math.max(1, math.floor(crop.GrowTime * (0.85 ^ fertilizerLevel) + 0.5))
end

function GameConfig.getSellPrice(cropId: string, merchantLevel: number): number
	local crop = GameConfig.Crops[cropId]
	return math.floor(crop.SellPrice * (1 + 0.2 * merchantLevel) + 0.5)
end

-- Trả về giá của cấp tiếp theo, hoặc nil nếu đã tối đa
function GameConfig.getUpgradeCost(upgradeId: string, currentLevel: number): number?
	local upgrade = GameConfig.Upgrades[upgradeId]
	return upgrade.Costs[currentLevel + 1]
end

function GameConfig.formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 60 then
		return string.format("%dp%02ds", seconds // 60, seconds % 60)
	end
	return seconds .. "s"
end

-- 1234567 -> "1.234.567"
function GameConfig.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if formatted:sub(1, 1) == "." then
		formatted = formatted:sub(2)
	end
	return formatted
end

return GameConfig
