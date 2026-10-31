--[[
	TimeService: chạy đồng hồ trong game, điều khiển ngày/đêm và báo
	"sang giờ mới" / "bình minh ngày mới" cho các service khác.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local GameTime = require(ReplicatedStorage.Shared.GameTime)

local TimeService = {}

local hourListeners: { (GameTime.Info) -> () } = {}
local dawnListeners: { (GameTime.Info, boolean) -> () } = {}

function TimeService.now(): GameTime.Info
	return GameTime.at(workspace:GetServerTimeNow(), Cfg.Time)
end

function TimeService.onHour(callback: (GameTime.Info) -> ())
	table.insert(hourListeners, callback)
end

-- callback(info, seasonChanged)
function TimeService.onDawn(callback: (GameTime.Info, boolean) -> ())
	table.insert(dawnListeners, callback)
end

local function applyLighting(info: GameTime.Info)
	Lighting.ClockTime = info.hour
	-- Đêm không quá tối để vẫn chơi được trên điện thoại
	local night = info.hour < 6 or info.hour >= 19
	Lighting.Ambient = if night then Color3.fromRGB(70, 80, 120) else Color3.fromRGB(120, 115, 105)
	Lighting.OutdoorAmbient = if night then Color3.fromRGB(90, 100, 140) else Color3.fromRGB(150, 145, 135)
end

function TimeService.start()
	Lighting.Brightness = 2.5
	Lighting.GlobalShadows = true

	local current = TimeService.now()
	local lastHour = current.hourIndex
	local lastDay = current.day
	local lastSeason = current.season
	applyLighting(current)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local info = TimeService.now()
			applyLighting(info)

			if info.day ~= lastDay then
				local seasonChanged = info.season ~= lastSeason
				lastDay = info.day
				lastSeason = info.season
				for _, callback in ipairs(dawnListeners) do
					task.spawn(callback, info, seasonChanged)
				end
			end
			if info.hourIndex ~= lastHour then
				lastHour = info.hourIndex
				for _, callback in ipairs(hourListeners) do
					task.spawn(callback, info)
				end
			end
		end
	end)
end

return TimeService
