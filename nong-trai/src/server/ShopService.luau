--[[
	ShopService: tiệm hạt (chỉ bán hạt đúng mùa), phân bón, quầy thu mua,
	và chọn hạt giống để gieo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FarmLogic = require(ReplicatedStorage.Shared.FarmLogic)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local IslandService = require(script.Parent.IslandService)
local Net = require(script.Parent.Net)
local TimeService = require(script.Parent.TimeService)

local ShopService = {}

local function validAmount(amount: any): number?
	if type(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 then
		return nil
	end
	return math.clamp(amount, 1, 99)
end

local function onBuySeed(player: Player, cropId: any, amount: any)
	local data = DataService.get(player)
	local count = validAmount(amount)
	if not data or not count or type(cropId) ~= "string" or not Crops.List[cropId] then
		return
	end
	local def = Crops.List[cropId]
	local season = TimeService.now().season
	if def.Season ~= season then
		Net.notify(player, "Hạt " .. def.Name .. " chỉ bán vào mùa " .. def.Season .. ".", "error")
		return
	end
	local cost = def.SeedPrice * count
	if data.coins < cost then
		Net.notify(player, "Không đủ Xu! Cần " .. Format.number(cost) .. " Xu.", "error")
		return
	end
	data.coins -= cost
	data.seeds[cropId] = (data.seeds[cropId] or 0) + count
	if not Net.getSelectedSeed(player) or (data.seeds[Net.getSelectedSeed(player) :: string] or 0) <= 0 then
		Net.setSelectedSeed(player, cropId)
	end
	Net.notify(player, string.format("Đã mua %d hạt %s.", count, def.Name), "success")
	Net.push(player)
end

local function onBuyItem(player: Player, itemId: any, amount: any)
	local data = DataService.get(player)
	local count = validAmount(amount)
	if not data or not count or itemId ~= "Fertilizer" then
		return
	end
	local cost = Cfg.FertilizerPrice * count
	if data.coins < cost then
		Net.notify(player, "Không đủ Xu! Cần " .. Format.number(cost) .. " Xu.", "error")
		return
	end
	data.coins -= cost
	data.fertilizer += count
	Net.notify(player, string.format("Đã mua %d bao phân bón.", count), "success")
	Net.push(player)
end

local function onSell(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local earned, sold = 0, 0
	for key, amount in pairs(data.produce) do
		local cropId, stars = Format.parseProduceKey(key)
		if cropId and stars and Crops.List[cropId] and amount > 0 then
			earned += FarmLogic.sellPrice(cropId, stars, Crops, Cfg) * amount
			sold += amount
		end
		data.produce[key] = nil
	end
	if sold == 0 then
		Net.notify(player, "Túi chưa có nông sản nào để bán.", "error")
		return
	end
	data.coins += earned
	Net.notify(player, string.format("Đã bán %d nông sản: +%s Xu", sold, Format.number(earned)), "success")
	Net.push(player)
end

local function onSelectSeed(player: Player, cropId: any)
	local data = DataService.get(player)
	if not data or type(cropId) ~= "string" or not Crops.List[cropId] then
		return
	end
	if (data.seeds[cropId] or 0) <= 0 then
		return
	end
	Net.setSelectedSeed(player, cropId)
	Net.push(player)
end

function ShopService.init()
	local market = IslandService.world().market
	local openShop = Remotes.event("OpenShop")

	market.shopPrompt.Triggered:Connect(function(player)
		openShop:FireClient(player)
	end)
	market.sellPrompt.Triggered:Connect(onSell)

	Remotes.event("BuySeed").OnServerEvent:Connect(onBuySeed)
	Remotes.event("BuyItem").OnServerEvent:Connect(onBuyItem)
	Remotes.event("SelectSeed").OnServerEvent:Connect(onSelectSeed)
end

return ShopService
