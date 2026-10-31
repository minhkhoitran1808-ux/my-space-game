--[[
	FarmService: xử lý dùng công cụ, cỏ/sâu theo giờ, cây lớn lúc bình minh,
	mở khu đất, múc nước, và vẽ lại ô đất.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FarmLogic = require(ReplicatedStorage.Shared.FarmLogic)
local Format = require(ReplicatedStorage.Shared.Format)
local GameTime = require(ReplicatedStorage.Shared.GameTime)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DataService = require(script.Parent.DataService)
local IslandService = require(script.Parent.IslandService)
local Models = require(script.Parent.Models)
local Net = require(script.Parent.Net)
local TimeService = require(script.Parent.TimeService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FarmService = {}

local rng = Random.new()
local lastUse: { [Player]: number } = {}
local lastHelpNotice: { [string]: number } = {}

local function randomNumber(): number
	return rng:NextNumber()
end

-- ===================== Vẽ =====================
function FarmService.render(island: WorldBuilder.Island, key: string)
	local owner = IslandService.ownerOf(island)
	local data = owner and DataService.get(owner)
	local part = IslandService.tilePart(island, key)
	if data and part and data.tiles[key] then
		Models.renderTile(part, data.tiles[key])
	end
end

function FarmService.renderIsland(island: WorldBuilder.Island)
	for key in pairs(IslandService.tileKeys(island)) do
		FarmService.render(island, key)
	end
end

-- ===================== Hạt giống đang chọn =====================
-- Nếu hạt đang chọn đã hết, tự chọn hạt khác (ưu tiên đúng mùa)
function FarmService.ensureSeed(player: Player, data, season: string)
	local current = Net.getSelectedSeed(player)
	if current and (data.seeds[current] or 0) > 0 then
		return
	end
	local fallback = nil
	for _, cropId in ipairs(Crops.Order) do
		if (data.seeds[cropId] or 0) > 0 then
			if Crops.List[cropId].Season == season then
				Net.setSelectedSeed(player, cropId)
				return
			end
			fallback = fallback or cropId
		end
	end
	Net.setSelectedSeed(player, fallback)
end

-- ===================== Mở khu đất =====================
local function ensureZoneTiles(player: Player, data, zoneId: number)
	local zone = IslandService.zone(zoneId)
	local generated = nil
	for i = 1, zone.Cols * zone.Rows do
		local key = IslandService.tileKey(zoneId, i)
		if not data.tiles[key] then
			generated = generated or FarmLogic.generateZone(zone, Cfg, player.UserId)
			data.tiles[key] = generated[i]
		end
	end
end

-- Gọi khi người chơi vào game và đã có đảo
function FarmService.attach(player: Player, island: WorldBuilder.Island, data)
	local info = TimeService.now()

	-- Bù 1 bình minh nếu đã sang ngày mới khi offline (cây tưới hôm trước vẫn được lớn)
	if data.lastDay >= 0 and data.lastDay < info.day then
		for _, tile in pairs(data.tiles) do
			FarmLogic.dawnTick(tile, info.season, Crops)
		end
	end
	data.lastDay = info.day

	for _, zone in ipairs(Cfg.Zones) do
		if data.zones[tostring(zone.Id)] then
			ensureZoneTiles(player, data, zone.Id)
			IslandService.buildZone(island, zone.Id)
		end
	end
	FarmService.renderIsland(island)
	FarmService.ensureSeed(player, data, info.season)
end

local function onBuyZone(island: WorldBuilder.Island, zoneId: number, player: Player)
	if IslandService.ownerOf(island) ~= player then
		Net.notify(player, "Đây không phải đảo của bạn.", "error")
		return
	end
	local data = DataService.get(player)
	local zone = IslandService.zone(zoneId)
	if not data or data.zones[tostring(zoneId)] then
		return
	end
	if data.coins < zone.Price then
		Net.notify(player, "Cần " .. Format.number(zone.Price) .. " Xu để mua " .. zone.Name .. ".", "error")
		return
	end
	data.coins -= zone.Price
	data.zones[tostring(zoneId)] = true
	ensureZoneTiles(player, data, zoneId)
	IslandService.buildZone(island, zoneId)
	FarmService.renderIsland(island)
	Net.notify(player, "Đã mua " .. zone.Name .. "! Hãy dọn đá và gốc cây.", "success")
	Net.push(player)
end

-- ===================== Dùng công cụ =====================
local function onUseTool(player: Player, tilePart: any, toolId: any)
	if typeof(tilePart) ~= "Instance" or not tilePart:IsA("BasePart") then
		return
	end
	if type(toolId) ~= "string" or not Cfg.Tools[toolId] then
		return
	end
	local now = os.clock()
	if now - (lastUse[player] or 0) < Cfg.ToolCooldown then
		return
	end
	lastUse[player] = now

	local island, key = IslandService.lookup(tilePart)
	if not island or not key then
		return
	end
	local owner = IslandService.ownerOf(island)
	local ownerData = owner and DataService.get(owner)
	local data = DataService.get(player)
	local tile = ownerData and ownerData.tiles[key]
	if not owner or not data or not tile then
		return
	end

	-- Phải đang cầm đúng công cụ và đứng đủ gần
	local character = player.Character
	local equipped = character and character:FindFirstChildOfClass("Tool")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not equipped or equipped.Name ~= toolId or not root then
		return
	end
	if (root.Position - tilePart.Position).Magnitude > Cfg.ToolRange then
		Net.notify(player, "Lại gần ô đất hơn nữa.", "error")
		return
	end

	local info = TimeService.now()
	local isOwner = owner == player
	local seedId = Net.getSelectedSeed(player)
	local result = FarmLogic.useTool(tile, toolId, {
		crops = Crops,
		cfg = Cfg,
		season = info.season,
		isOwner = isOwner,
		water = data.water,
		seedId = seedId,
		seedCount = if seedId then data.seeds[seedId] or 0 else 0,
		fertilizer = data.fertilizer,
	})

	if not result.ok then
		Net.notify(player, result.msg or "Không làm được.", "error")
		return
	end

	if result.waterUsed then
		data.water = math.max(0, data.water - result.waterUsed)
	end
	if result.seedUsed then
		data.seeds[result.seedUsed] = math.max(0, (data.seeds[result.seedUsed] or 0) - 1)
		FarmService.ensureSeed(player, data, info.season)
	end
	if result.fertilizerUsed then
		data.fertilizer = math.max(0, data.fertilizer - result.fertilizerUsed)
	end
	if result.harvest then
		local harvest = result.harvest
		local produceKey = Format.produceKey(harvest.id, harvest.stars)
		data.produce[produceKey] = (data.produce[produceKey] or 0) + 1
		data.totalHarvested += 1
		Net.notify(player, "+1 " .. Crops.List[harvest.id].Name .. " " .. Format.stars(harvest.stars), "success")
	elseif result.msg then
		Net.notify(player, result.msg, "info")
	end

	if result.helped then
		local noticeKey = owner.UserId .. ":" .. player.UserId
		if os.clock() - (lastHelpNotice[noticeKey] or 0) > 60 then
			lastHelpNotice[noticeKey] = os.clock()
			Net.notify(owner, player.DisplayName .. " đang giúp chăm ruộng của bạn!", "info")
		end
	end

	FarmService.render(island, key)
	Net.push(player)
end

-- ===================== Theo thời gian =====================
local function forEachOwnedIsland(callback: (WorldBuilder.Island, Player, any) -> ())
	for _, island in ipairs(IslandService.world().islands) do
		local owner = IslandService.ownerOf(island)
		local data = owner and DataService.get(owner)
		if owner and data then
			callback(island, owner, data)
		end
	end
end

local function onHour(_info: GameTime.Info)
	forEachOwnedIsland(function(island, _owner, data)
		for key, tile in pairs(data.tiles) do
			if FarmLogic.hourTick(tile, Cfg, Crops, randomNumber) then
				FarmService.render(island, key)
			end
		end
	end)
end

local function onDawn(info: GameTime.Info, seasonChanged: boolean)
	forEachOwnedIsland(function(island, owner, data)
		for _, tile in pairs(data.tiles) do
			FarmLogic.dawnTick(tile, info.season, Crops)
		end
		data.lastDay = info.day
		FarmService.renderIsland(island)
		if seasonChanged then
			Net.notify(owner, "Mùa " .. info.season .. " đã đến! Tiệm hạt có hạt giống mới. Cây trái mùa sẽ ngừng lớn.", "info")
		else
			Net.notify(owner, string.format("Ngày %d mùa %s. Đất đã khô, nhớ tưới cây!", info.dayOfSeason, info.season), "info")
		end
		FarmService.ensureSeed(owner, data, info.season)
		Net.push(owner)
	end)
end

-- ===================== Khởi động =====================
function FarmService.init()
	local world = IslandService.world()

	Remotes.event("UseTool").OnServerEvent:Connect(onUseTool)

	for _, island in ipairs(world.islands) do
		for zoneId, visual in pairs(island.zones) do
			visual.prompt.Triggered:Connect(function(player)
				onBuyZone(island, zoneId, player)
			end)
		end
	end

	local function refill(player: Player)
		local data = DataService.get(player)
		if not data then
			return
		end
		data.water = Cfg.WaterCapacity
		Net.notify(player, string.format("Đã múc đầy bình (%d/%d).", data.water, Cfg.WaterCapacity), "success")
		Net.push(player)
	end
	world.market.wellPrompt.Triggered:Connect(refill)
	for _, island in ipairs(world.islands) do
		island.wellPrompt.Triggered:Connect(refill)
	end

	TimeService.onHour(onHour)
	TimeService.onDawn(onDawn)

	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return FarmService
