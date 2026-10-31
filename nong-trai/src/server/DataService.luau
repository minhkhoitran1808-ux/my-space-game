--[[
	DataService: tải / lưu tiến trình bằng DataStore.

	- Khoá phiên: khi một server đang giữ dữ liệu của bạn, server khác phải chờ
	  (tránh mất đồ hoặc nhân bản đồ khi chuyển server nhanh, rất quan trọng khi
	  có giao dịch ở giai đoạn 4).
	- Thử lại khi Roblox báo lỗi, tự lưu định kỳ, lưu khi thoát & khi server tắt.
	- Tải thất bại: vẫn cho chơi nhưng KHÔNG ghi đè dữ liệu cũ.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)

local DataService = {}

local AUTOSAVE_INTERVAL = 60
local LOCK_TIMEOUT = 30 * 60 -- khoá cũ hơn 30 phút coi như server kia đã chết
local LOAD_ATTEMPTS = 5

local store: DataStore? = nil
do
	local ok, err = pcall(function()
		store = DataStoreService:GetDataStore(Cfg.DataStoreName)
	end)
	if not ok then
		warn("[DataService] Không mở được DataStore (đã Publish và bật API Services chưa?):", err)
	end
end

local sessions: { [Player]: any } = {}
local canSave: { [Player]: boolean } = {}
local activeSaves = 0

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

local TEMPLATE = {
	coins = Cfg.StartingCoins,
	seeds = {}, -- [cropId] = số hạt
	produce = {}, -- ["CaRot:3"] = số nông sản
	fertilizer = Cfg.StartingFertilizer,
	water = Cfg.WaterCapacity,
	zones = { ["1"] = true }, -- khu đất đã mở
	tiles = {}, -- ["1:5"] = tile (xem FarmLogic)
	totalHarvested = 0,
	lastDay = -1, -- ngày trong game lần cuối xử lý bình minh
	isNew = true,
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

local function keyFor(player: Player): string
	return "Farm_" .. player.UserId
end

-- Trả về (data, loadedOk). data = nil nếu người chơi rời game trong lúc tải.
function DataService.load(player: Player)
	local stored = nil
	local success = false

	if store then
		for attempt = 1, LOAD_ATTEMPTS do
			local lockedByOther = false
			local ok, err = pcall(function()
				(store :: DataStore):UpdateAsync(keyFor(player), function(old)
					old = if type(old) == "table" then old else {}
					local lock = old.lock
					local stillLocked = lock and lock.job ~= game.JobId and os.time() - (lock.t or 0) < LOCK_TIMEOUT
					if stillLocked and attempt < LOAD_ATTEMPTS then
						lockedByOther = true
						return nil -- huỷ cập nhật, thử lại sau
					end
					old.lock = { job = game.JobId, t = os.time() }
					stored = old.data
					return old
				end)
			end)
			if ok and not lockedByOther then
				success = true
				break
			end
			if not ok then
				warn(string.format("[DataService] Tải %s lỗi (lần %d): %s", player.Name, attempt, tostring(err)))
			end
			if player.Parent == nil then
				return nil, false
			end
			task.wait(if lockedByOther then 6 else attempt * 2)
		end
	end

	if player.Parent == nil then
		-- Đã rời game: nhả khoá vừa lấy
		if success then
			sessions[player] = if type(stored) == "table" then stored else deepCopy(TEMPLATE)
			canSave[player] = true
			DataService.release(player)
		end
		return nil, false
	end

	local data = if type(stored) == "table" then stored else deepCopy(TEMPLATE)
	reconcile(data, TEMPLATE)

	sessions[player] = data
	canSave[player] = success
	return data, success
end

function DataService.get(player: Player)
	return sessions[player]
end

function DataService.canSave(player: Player): boolean
	return canSave[player] == true
end

local function write(player: Player, releaseLock: boolean): boolean
	local data = sessions[player]
	if not data or not canSave[player] or not store then
		return false
	end
	activeSaves += 1
	local saved = false
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(keyFor(player), function(old)
				old = if type(old) == "table" then old else {}
				local lock = old.lock
				if lock and lock.job ~= game.JobId and os.time() - (lock.t or 0) < LOCK_TIMEOUT then
					return nil -- server khác đang giữ: không ghi đè
				end
				old.data = data
				old.lock = if releaseLock then nil else { job = game.JobId, t = os.time() }
				return old, { player.UserId }
			end)
		end)
		if ok then
			saved = true
			break
		end
		warn(string.format("[DataService] Lưu %s lỗi (lần %d): %s", player.Name, attempt, tostring(err)))
		task.wait(attempt * 2)
	end
	activeSaves -= 1
	return saved
end

function DataService.save(player: Player): boolean
	return write(player, false)
end

function DataService.release(player: Player)
	if sessions[player] then
		write(player, true)
	end
	sessions[player] = nil
	canSave[player] = nil
end

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				if sessions[player] then
					task.spawn(DataService.save, player)
				end
			end
		end
	end)

	game:BindToClose(function()
		for player in pairs(sessions) do
			task.spawn(DataService.release, player)
		end
		task.wait()
		local startTime = os.clock()
		while activeSaves > 0 and os.clock() - startTime < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
