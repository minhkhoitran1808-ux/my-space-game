--[[
	Main (Script): khởi động server và quản lý người chơi vào/ra, di chuyển giữa các đảo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Remotes = require(ReplicatedStorage.Shared.Remotes) -- tạo các remote trước tiên

local DataService = require(script.Parent.DataService)
local FarmService = require(script.Parent.FarmService)
local IslandService = require(script.Parent.IslandService)
local Net = require(script.Parent.Net)
local ShopService = require(script.Parent.ShopService)
local TimeService = require(script.Parent.TimeService)
local ToolService = require(script.Parent.ToolService)
local WorldBuilder = require(script.Parent.WorldBuilder)

Players.CharacterAutoLoads = true

local world = WorldBuilder.build()
IslandService.init(world)
DataService.start()
TimeService.start()
FarmService.init()
ShopService.init()

-- ===================== Di chuyển =====================
local function teleport(player: Player, cframe: CFrame)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(cframe)
	end
end

local function goHome(player: Player)
	local island = IslandService.islandOf(player)
	if island then
		teleport(player, island.spawnCFrame)
	else
		teleport(player, world.market.spawnCFrame)
	end
end

Remotes.event("Travel").OnServerEvent:Connect(function(player, target)
	if target == "market" then
		teleport(player, world.market.spawnCFrame)
	elseif target == "home" then
		goHome(player)
	elseif type(target) == "number" then
		local friend = Players:GetPlayerByUserId(target)
		local island = friend and IslandService.islandOf(friend)
		if island then
			teleport(player, island.spawnCFrame)
			Net.notify(player, "Bạn đang thăm đảo của " .. (friend :: Player).DisplayName .. ". Có thể tưới, cắt cỏ, diệt sâu giúp bạn ấy.", "info")
		end
	end
end)

world.market.travelPrompt.Triggered:Connect(goHome)
for _, island in ipairs(world.islands) do
	island.travelPrompt.Triggered:Connect(function(player)
		teleport(player, world.market.spawnCFrame)
	end)
end

Remotes.func("GetState").OnServerInvoke = function(player)
	return Net.buildState(player)
end

-- ===================== Người chơi vào / ra =====================
local function giveStarterKit(data, season: string)
	-- Tặng hạt rẻ nhất của mùa hiện tại để trồng được ngay
	local cheapest, price = nil, math.huge
	for _, cropId in ipairs(Crops.Order) do
		local def = Crops.List[cropId]
		if def.Season == season and def.SeedPrice < price then
			cheapest, price = cropId, def.SeedPrice
		end
	end
	if cheapest then
		data.seeds[cheapest] = (data.seeds[cheapest] or 0) + Cfg.StartingSeedCount
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		ToolService.give(player)
		task.wait(0.2)
		goHome(player)
	end)

	local data, loadedOk = DataService.load(player)
	if not data then
		return
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Xu"
	coins.Parent = stats
	local harvested = Instance.new("IntValue")
	harvested.Name = "Thu hoạch"
	harvested.Parent = stats
	stats.Parent = player

	local info = TimeService.now()
	if data.isNew then
		giveStarterKit(data, info.season)
		data.isNew = false
	end

	local island = IslandService.assign(player)
	if island then
		FarmService.attach(player, island, data)
		task.spawn(goHome, player)
		Net.notify(player, "Chào mừng đến Nông Trại Vui Vẻ! Cầm Cuốc (phím 1) và bấm vào ô cỏ để cuốc đất.", "info")
	else
		FarmService.ensureSeed(player, data, info.season)
		Net.notify(player, "Server đã hết đảo trống. Hãy thử server khác!", "error")
	end
	if not loadedOk then
		Net.notify(player, "Không tải được dữ liệu. Tiến trình lần này sẽ KHÔNG được lưu.", "error")
	end
	Net.push(player)
end

local function onPlayerRemoving(player: Player)
	IslandService.release(player)
	DataService.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
