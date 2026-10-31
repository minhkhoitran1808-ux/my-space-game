--[[
	FarmServer (Script)
	Đặt tại: ServerScriptService > FarmServer

	Logic chính của game. Mọi giao dịch (mua, trồng, thu hoạch, bán) đều được
	kiểm tra ở server nên người chơi không thể hack Xu từ phía client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local MapBuilder = require(ServerScriptService:WaitForChild("MapBuilder"))

local Colors = MapBuilder.Colors

-- ===================== Remotes =====================
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	remotes:Destroy()
end
remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function newRemote(className: string, name: string)
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local BuySeed = newRemote("RemoteEvent", "BuySeed") -- client -> server (cropId, amount)
local BuyUpgrade = newRemote("RemoteEvent", "BuyUpgrade") -- client -> server (upgradeId)
local SelectSeed = newRemote("RemoteEvent", "SelectSeed") -- client -> server (cropId)
local GetState = newRemote("RemoteFunction", "GetState") -- client -> server, trả về state
local StateChanged = newRemote("RemoteEvent", "StateChanged") -- server -> client (state)
local Notify = newRemote("RemoteEvent", "Notify") -- server -> client (text, kind)
local OpenShop = newRemote("RemoteEvent", "OpenShop") -- server -> client

-- ===================== Bản đồ =====================
local map = MapBuilder.build()
remotes.Parent = ReplicatedStorage -- đặt sau cùng để client chỉ thấy khi mọi remote đã sẵn sàng

local plots = map.plots
local plotOwner = {} -- [plotIndex] = Player
local playerPlot = {} -- [Player] = plot
local selectedSeed = {} -- [Player] = cropId
local tileCache = {} -- [plotIndex][tileIndex] = { crop, stage }

for i = 1, #plots do
	tileCache[i] = {}
	for t = 1, GameConfig.MaxTiles do
		tileCache[i][t] = {}
	end
end

-- ===================== Tiện ích =====================
local function notify(player: Player, text: string, kind: string?)
	Notify:FireClient(player, text, kind or "info")
end

local function isValidId(value, list): boolean
	return type(value) == "string" and list[value] ~= nil
end

local function buildState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return nil
	end
	return {
		coins = data.coins,
		totalHarvested = data.totalHarvested,
		seeds = data.seeds,
		crops = data.crops,
		upgrades = data.upgrades,
		selectedSeed = selectedSeed[player],
		tileCount = GameConfig.getTileCount(data.upgrades.Expand),
		hasPlot = playerPlot[player] ~= nil,
		canSave = DataManager.canSave(player),
	}
end

local function syncLeaderstats(player: Player)
	local data = DataManager.get(player)
	local stats = player:FindFirstChild("leaderstats")
	if not data or not stats then
		return
	end
	stats["Xu"].Value = data.coins
	stats["Thu hoạch"].Value = data.totalHarvested
end

local function pushState(player: Player)
	syncLeaderstats(player)
	local state = buildState(player)
	if state then
		StateChanged:FireClient(player, state)
	end
end

-- Chọn hạt giống mặc định nếu hạt đang chọn đã hết
local function ensureSelectedSeed(player: Player, data)
	local current = selectedSeed[player]
	if current and (data.seeds[current] or 0) > 0 then
		return
	end
	selectedSeed[player] = nil
	for _, cropId in ipairs(GameConfig.CropOrder) do
		if (data.seeds[cropId] or 0) > 0 then
			selectedSeed[player] = cropId
			return
		end
	end
end

-- ===================== Hình ảnh cây trồng =====================
local PLANT_OFFSETS = { Vector3.new(-2, 0, -2), Vector3.new(2, 0, -2), Vector3.new(-2, 0, 2), Vector3.new(2, 0, 2) }
local LEAF_GREEN = Color3.fromRGB(80, 180, 70)
local STEM_GREEN = Color3.fromRGB(50, 120, 45)

local function visualPart(model: Model, size: Vector3, color: Color3, position: Vector3, isBall: boolean)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	if isBall then
		part.Shape = Enum.PartType.Ball
	end
	part.Position = position
	part.Parent = model
	return part
end

-- stage: 0 = trống, 1 = mầm, 2 = cây non, 3 = chín
local function setCropVisual(tilePart: BasePart, cropId: string?, stage: number)
	local old = tilePart:FindFirstChild("CropVisual")
	if old then
		old:Destroy()
	end
	if not cropId or stage == 0 then
		return
	end

	local crop = GameConfig.Crops[cropId]
	local model = Instance.new("Model")
	model.Name = "CropVisual"
	local top = tilePart.Position + Vector3.new(0, tilePart.Size.Y / 2, 0)

	for _, offset in ipairs(PLANT_OFFSETS) do
		local base = top + offset
		if stage == 1 then
			visualPart(model, Vector3.new(0.8, 0.8, 0.8), LEAF_GREEN, base + Vector3.new(0, 0.4, 0), true)
		elseif stage == 2 then
			visualPart(model, Vector3.new(0.3, 1.6, 0.3), STEM_GREEN, base + Vector3.new(0, 0.8, 0), false)
			visualPart(model, Vector3.new(1.6, 1.6, 1.6), LEAF_GREEN, base + Vector3.new(0, 1.8, 0), true)
		else
			visualPart(model, Vector3.new(0.3, 1.6, 0.3), STEM_GREEN, base + Vector3.new(0, 0.8, 0), false)
			local fruit = visualPart(model, Vector3.new(2.2, 2.2, 2.2), crop.Color, base + Vector3.new(0, 2.2, 0), true)
			fruit.Material = Enum.Material.Neon
		end
	end
	model.Parent = tilePart
end

-- ===================== Cập nhật ô đất =====================
local function updateTile(plot, tileIndex: number)
	local tile = plot.tiles[tileIndex]
	local cache = tileCache[plot.index][tileIndex]
	local owner = plotOwner[plot.index]
	local data = owner and DataManager.get(owner)

	local cropId = nil
	local stage = 0

	if not data then
		-- Ruộng chưa có chủ
		tile.part.Color = Colors.LockedSoil
		tile.prompt.Enabled = false
		tile.billboard.Enabled = false
	elseif tileIndex > GameConfig.getTileCount(data.upgrades.Expand) then
		-- Ô chưa mở khoá
		tile.part.Color = Colors.LockedSoil
		tile.prompt.Enabled = false
		tile.billboard.Enabled = true
		tile.label.Text = "🔒"
	else
		tile.part.Color = Colors.Soil
		tile.prompt.Enabled = true
		tile.billboard.Enabled = true

		local info = data.plots[tostring(tileIndex)]
		if not info then
			tile.prompt.ActionText = "Trồng hạt"
			tile.prompt.ObjectText = "Ô đất trống"
			tile.label.Text = "➕"
		else
			local crop = GameConfig.Crops[info.crop]
			cropId = info.crop
			local remaining = info.plantedAt + info.growTime - os.time()
			if remaining <= 0 then
				stage = 3
				tile.prompt.ActionText = "Thu hoạch"
				tile.prompt.ObjectText = crop.Emoji .. " " .. crop.Name .. " (đã chín)"
				tile.label.Text = crop.Emoji .. " Chín!"
			else
				stage = if remaining > info.growTime / 2 then 1 else 2
				tile.prompt.ActionText = if info.watered then "Đã tưới 💧" else "Tưới nước 💧"
				tile.prompt.ObjectText = crop.Emoji .. " " .. crop.Name .. " – còn " .. GameConfig.formatTime(remaining)
				tile.label.Text = crop.Emoji .. " " .. GameConfig.formatTime(remaining)
			end
		end
	end

	if cache.crop ~= cropId or cache.stage ~= stage then
		cache.crop = cropId
		cache.stage = stage
		setCropVisual(tile.part, cropId, stage)
	end
end

local function refreshPlot(plot)
	local owner = plotOwner[plot.index]
	if owner then
		plot.signLabel.Text = "🌻 Ruộng của " .. owner.DisplayName
		plot.model:SetAttribute("OwnerId", owner.UserId)
	else
		plot.signLabel.Text = "Ruộng trống"
		plot.model:SetAttribute("OwnerId", 0)
	end
	for t = 1, GameConfig.MaxTiles do
		updateTile(plot, t)
	end
end

-- ===================== Hành động trên ô đất =====================
local function onTileTriggered(plot, tileIndex: number, player: Player)
	local data = DataManager.get(player)
	local owner = plotOwner[plot.index]
	if not data or not owner then
		return
	end
	local ownerData = DataManager.get(owner)
	if not ownerData or tileIndex > GameConfig.getTileCount(ownerData.upgrades.Expand) then
		return
	end

	local key = tostring(tileIndex)
	local info = ownerData.plots[key]
	local isOwner = owner == player

	if info then
		local crop = GameConfig.Crops[info.crop]
		local remaining = info.plantedAt + info.growTime - os.time()

		if remaining <= 0 then
			-- Thu hoạch
			if not isOwner then
				notify(player, "Chỉ " .. owner.DisplayName .. " mới thu hoạch được ruộng này!", "error")
				return
			end
			data.plots[key] = nil
			data.crops[info.crop] = (data.crops[info.crop] or 0) + 1
			data.totalHarvested += 1
			notify(player, "+1 " .. crop.Emoji .. " " .. crop.Name, "success")
			pushState(player)
		elseif info.watered then
			notify(player, crop.Emoji .. " Cây đã được tưới rồi – còn " .. GameConfig.formatTime(remaining), "info")
		else
			-- Tưới nước: rút ngắn thời gian lớn (ai cũng tưới được – co-op!)
			info.watered = true
			info.plantedAt -= math.floor(info.growTime * GameConfig.WaterSpeedup + 0.5)
			if isOwner then
				notify(player, "💧 Đã tưới " .. crop.Name .. "! Cây lớn nhanh hơn.", "success")
			else
				data.coins += GameConfig.HelperReward
				notify(player, "💧 Bạn đã tưới giúp " .. owner.DisplayName .. "! +" .. GameConfig.HelperReward .. " Xu", "success")
				notify(owner, "💧 " .. player.DisplayName .. " đã tưới cây giúp bạn!", "info")
				pushState(player)
			end
		end
	else
		-- Trồng cây
		if not isOwner then
			notify(player, "Đây là ruộng của " .. owner.DisplayName .. ".", "error")
			return
		end
		ensureSelectedSeed(player, data)
		local cropId = selectedSeed[player]
		if not cropId then
			notify(player, "Bạn hết hạt giống! Mở 🛒 Cửa hàng để mua.", "error")
			return
		end
		data.seeds[cropId] -= 1
		data.plots[key] = {
			crop = cropId,
			plantedAt = os.time(),
			growTime = GameConfig.getGrowTime(cropId, data.upgrades.Fertilizer),
			watered = false,
		}
		ensureSelectedSeed(player, data)
		pushState(player)
	end

	updateTile(plot, tileIndex)
end

for _, plot in ipairs(plots) do
	for t, tile in ipairs(plot.tiles) do
		tile.prompt.Triggered:Connect(function(player)
			onTileTriggered(plot, t, player)
		end)
	end
end

-- ===================== Quầy bán & cửa hàng =====================
map.sellPrompt.Triggered:Connect(function(player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local earned = 0
	local count = 0
	for cropId, amount in pairs(data.crops) do
		if amount > 0 then
			earned += GameConfig.getSellPrice(cropId, data.upgrades.Merchant) * amount
			count += amount
		end
		data.crops[cropId] = nil
	end
	if count == 0 then
		notify(player, "Túi của bạn trống. Hãy thu hoạch cây trước!", "error")
		return
	end
	data.coins += earned
	notify(player, string.format("Đã bán %d nông sản: +%s Xu 💰", count, GameConfig.formatNumber(earned)), "success")
	pushState(player)
end)

map.shopPrompt.Triggered:Connect(function(player)
	OpenShop:FireClient(player)
end)

BuySeed.OnServerEvent:Connect(function(player, cropId, amount)
	local data = DataManager.get(player)
	if not data or not isValidId(cropId, GameConfig.Crops) then
		return
	end
	if type(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 then
		return
	end
	amount = math.clamp(amount, 1, 100)

	local crop = GameConfig.Crops[cropId]
	if data.totalHarvested < crop.Unlock then
		notify(player, string.format("🔒 Cần thu hoạch %d cây để mở khoá %s.", crop.Unlock, crop.Name), "error")
		return
	end
	local cost = crop.SeedPrice * amount
	if data.coins < cost then
		notify(player, "Không đủ Xu! Cần " .. GameConfig.formatNumber(cost) .. " Xu.", "error")
		return
	end

	data.coins -= cost
	data.seeds[cropId] = (data.seeds[cropId] or 0) + amount
	if not selectedSeed[player] then
		selectedSeed[player] = cropId
	end
	notify(player, string.format("Đã mua %d hạt %s %s", amount, crop.Emoji, crop.Name), "success")
	pushState(player)
end)

BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local data = DataManager.get(player)
	if not data or not isValidId(upgradeId, GameConfig.Upgrades) then
		return
	end
	local upgrade = GameConfig.Upgrades[upgradeId]
	local level = data.upgrades[upgradeId] or 0
	local cost = GameConfig.getUpgradeCost(upgradeId, level)
	if not cost then
		notify(player, upgrade.Name .. " đã đạt cấp tối đa!", "info")
		return
	end
	if data.coins < cost then
		notify(player, "Không đủ Xu! Cần " .. GameConfig.formatNumber(cost) .. " Xu.", "error")
		return
	end

	data.coins -= cost
	data.upgrades[upgradeId] = level + 1
	notify(player, string.format("%s %s lên cấp %d!", upgrade.Emoji, upgrade.Name, level + 1), "success")
	pushState(player)

	local plot = playerPlot[player]
	if upgradeId == "Expand" and plot then
		refreshPlot(plot)
	end
end)

SelectSeed.OnServerEvent:Connect(function(player, cropId)
	local data = DataManager.get(player)
	if not data or not isValidId(cropId, GameConfig.Crops) then
		return
	end
	if (data.seeds[cropId] or 0) <= 0 then
		return
	end
	selectedSeed[player] = cropId
	pushState(player)
end)

GetState.OnServerInvoke = function(player)
	return buildState(player)
end

-- ===================== Người chơi vào / rời =====================
local function teleportToPlot(player: Player)
	local plot = playerPlot[player]
	local character = player.Character
	if not plot or not character then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root and character.Parent then
		character:PivotTo(plot.spawnCFrame)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		teleportToPlot(player)
	end)

	local data, loadedOk = DataManager.load(player)
	if not data then
		return -- người chơi đã rời trong lúc tải
	end

	-- Bảng xếp hạng (bấm Tab để xem)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Xu"
	coins.Parent = stats
	local harvested = Instance.new("IntValue")
	harvested.Name = "Thu hoạch"
	harvested.Parent = stats
	stats.Parent = player

	-- Nhận mảnh ruộng trống
	for i, plot in ipairs(plots) do
		if not plotOwner[i] then
			plotOwner[i] = player
			playerPlot[player] = plot
			break
		end
	end

	ensureSelectedSeed(player, data)
	pushState(player)

	local plot = playerPlot[player]
	if plot then
		refreshPlot(plot)
		task.spawn(teleportToPlot, player)
		notify(player, "Chào mừng đến Nông Trại! Mua hạt ở 🛒, trồng bằng phím E.", "info")
	else
		notify(player, "Server đã hết ruộng trống. Hãy thử server khác!", "error")
	end
	if not loadedOk then
		notify(player, "⚠️ Không tải được dữ liệu – tiến trình lần này sẽ KHÔNG được lưu.", "error")
	end
end

local function onPlayerRemoving(player: Player)
	local plot = playerPlot[player]
	playerPlot[player] = nil
	selectedSeed[player] = nil
	if plot then
		plotOwner[plot.index] = nil
		refreshPlot(plot)
	end
	DataManager.release(player)
end

DataManager.init()
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- ===================== Vòng lặp cây lớn =====================
while true do
	task.wait(1)
	for _, plot in ipairs(plots) do
		local owner = plotOwner[plot.index]
		local data = owner and DataManager.get(owner)
		if data then
			local tileCount = GameConfig.getTileCount(data.upgrades.Expand)
			for t = 1, tileCount do
				if data.plots[tostring(t)] then
					updateTile(plot, t)
				end
			end
		end
	end
end
