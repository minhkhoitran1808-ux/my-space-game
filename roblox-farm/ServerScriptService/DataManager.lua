--[[
	DataManager (ModuleScript)
	Đặt tại: ServerScriptService > DataManager

	Tải / lưu tiến trình người chơi bằng DataStore.
	- Thử lại tối đa 3 lần nếu Roblox báo lỗi.
	- Nếu tải thất bại, người chơi vẫn chơi được nhưng KHÔNG ghi đè dữ liệu cũ.
	- Tự lưu định kỳ, lưu khi thoát và khi server tắt.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local DataManager = {}

local MAX_RETRIES = 3

local store = nil
do
	local ok, err = pcall(function()
		store = DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if not ok then
		warn("[DataManager] Không mở được DataStore (đã Publish game và bật API Services chưa?):", err)
	end
end

local sessionData = {} -- [Player] = data
local canSave = {} -- [Player] = true nếu dữ liệu đã tải thành công
local activeSaves = 0 -- số lượt lưu đang chạy (để BindToClose chờ)

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Khung dữ liệu: dùng để bổ sung các khoá còn thiếu khi game có cập nhật mới
local TEMPLATE = {
	coins = GameConfig.StartingCoins,
	totalHarvested = 0,
	seeds = {},
	crops = {},
	upgrades = { Expand = 0, Fertilizer = 0, Merchant = 0 },
	plots = {}, -- ["1"] = { crop = "Wheat", plantedAt = os.time(), growTime = 10, watered = false }
}

local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
end

local function newPlayerData()
	local data = deepCopy(TEMPLATE)
	data.seeds = deepCopy(GameConfig.StartingSeeds)
	return data
end

-- Xoá dữ liệu không còn hợp lệ (ví dụ cây đã bị xoá khỏi GameConfig)
local function sanitize(data)
	for key, info in pairs(data.plots) do
		if type(info) ~= "table" or not GameConfig.Crops[info.crop] then
			data.plots[key] = nil
		end
	end
	for cropId in pairs(data.seeds) do
		if not GameConfig.Crops[cropId] then
			data.seeds[cropId] = nil
		end
	end
	for cropId in pairs(data.crops) do
		if not GameConfig.Crops[cropId] then
			data.crops[cropId] = nil
		end
	end
end

local function keyFor(player: Player): string
	return "Farm_" .. player.UserId
end

-- Trả về (data, loadedOk). data = nil nếu người chơi đã rời game trong lúc tải.
function DataManager.load(player: Player)
	local stored = nil
	local success = false

	if store then
		for attempt = 1, MAX_RETRIES do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				stored = result
				success = true
				break
			end
			warn(string.format("[DataManager] Tải dữ liệu %s thất bại (lần %d): %s", player.Name, attempt, tostring(result)))
			if attempt < MAX_RETRIES then
				task.wait(attempt * 2)
			end
		end
	end

	if player.Parent == nil then
		return nil, false
	end

	local data
	if type(stored) == "table" then
		data = stored
		reconcile(data, TEMPLATE)
		sanitize(data)
	else
		data = newPlayerData()
	end

	sessionData[player] = data
	canSave[player] = success
	return data, success
end

function DataManager.get(player: Player)
	return sessionData[player]
end

function DataManager.canSave(player: Player): boolean
	return canSave[player] == true
end

function DataManager.save(player: Player): boolean
	local data = sessionData[player]
	if not data or not canSave[player] or not store then
		return false
	end
	activeSaves += 1
	local saved = false
	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			store:SetAsync(keyFor(player), data, { player.UserId })
		end)
		if ok then
			saved = true
			break
		end
		warn(string.format("[DataManager] Lưu dữ liệu %s thất bại (lần %d): %s", player.Name, attempt, tostring(err)))
		if attempt < MAX_RETRIES then
			task.wait(attempt * 2)
		end
	end
	activeSaves -= 1
	return saved
end

-- Gọi khi người chơi rời game: lưu lần cuối rồi xoá khỏi bộ nhớ
function DataManager.release(player: Player)
	if sessionData[player] then
		DataManager.save(player)
	end
	sessionData[player] = nil
	canSave[player] = nil
end

local started = false
function DataManager.init()
	if started then
		return
	end
	started = true

	-- Tự lưu định kỳ
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutoSaveInterval)
			for _, player in ipairs(Players:GetPlayers()) do
				if sessionData[player] then
					task.spawn(DataManager.save, player)
				end
			end
		end
	end)

	-- Server tắt: lưu tất cả cùng lúc (kể cả lượt lưu do người chơi thoát), chờ tối đa 25 giây
	game:BindToClose(function()
		for player in pairs(sessionData) do
			task.spawn(DataManager.save, player)
		end
		task.wait() -- cho các lượt lưu kịp bắt đầu
		local startTime = os.clock()
		while activeSaves > 0 and os.clock() - startTime < 25 do
			task.wait(0.1)
		end
	end)
end

return DataManager
