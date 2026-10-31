--[[
	Net: gửi thông báo và trạng thái người chơi xuống client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local Net = {}

local NotifyRemote = Remotes.event("Notify")
local StateChanged = Remotes.event("StateChanged")

local selectedSeed: { [Player]: string? } = {}

function Net.notify(player: Player, text: string, kind: string?)
	NotifyRemote:FireClient(player, text, kind or "info")
end

function Net.getSelectedSeed(player: Player): string?
	return selectedSeed[player]
end

function Net.setSelectedSeed(player: Player, cropId: string?)
	selectedSeed[player] = cropId
end

function Net.buildState(player: Player)
	local data = DataService.get(player)
	if not data then
		return nil
	end
	return {
		coins = data.coins,
		seeds = data.seeds,
		produce = data.produce,
		fertilizer = data.fertilizer,
		water = data.water,
		zones = data.zones,
		totalHarvested = data.totalHarvested,
		selectedSeed = selectedSeed[player],
		canSave = DataService.canSave(player),
	}
end

function Net.push(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		(stats:FindFirstChild("Xu") :: IntValue).Value = data.coins;
		(stats:FindFirstChild("Thu hoạch") :: IntValue).Value = data.totalHarvested
	end
	StateChanged:FireClient(player, Net.buildState(player))
end

Players.PlayerRemoving:Connect(function(player)
	selectedSeed[player] = nil
end)

return Net
