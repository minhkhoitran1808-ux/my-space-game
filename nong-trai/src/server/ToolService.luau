--[[
	ToolService: phát bộ công cụ cho người chơi mỗi lần hồi sinh.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Models = require(script.Parent.Models)

local ToolService = {}

local templates = Instance.new("Folder")
templates.Name = "ToolTemplates"
templates.Parent = ServerStorage

for _, toolId in ipairs(Cfg.ToolOrder) do
	Models.buildTool(toolId).Parent = templates
end

function ToolService.give(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	for _, toolId in ipairs(Cfg.ToolOrder) do
		if not backpack:FindFirstChild(toolId) then
			local template = templates:FindFirstChild(toolId)
			if template then
				template:Clone().Parent = backpack
			end
		end
	end
end

return ToolService
