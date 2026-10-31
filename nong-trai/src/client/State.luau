--[[
	State: trạng thái người chơi do server gửi xuống + tiện ích thời gian.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local GameTime = require(ReplicatedStorage.Shared.GameTime)

local State = {}

State.data = nil :: any
local listeners: { (any) -> () } = {}

function State.set(data)
	State.data = data
	for _, callback in ipairs(listeners) do
		task.spawn(callback, data)
	end
end

function State.onChanged(callback: (any) -> ())
	table.insert(listeners, callback)
	if State.data then
		task.spawn(callback, State.data)
	end
end

function State.time(): GameTime.Info
	return GameTime.at(workspace:GetServerTimeNow(), Cfg.Time)
end

return State
