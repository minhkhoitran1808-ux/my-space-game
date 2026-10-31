--[[
	Danh sách RemoteEvent/RemoteFunction. Server tạo, client chờ.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local EVENTS = {
	-- client -> server
	"UseTool", -- (tilePart: BasePart, toolId: string)
	"SelectSeed", -- (cropId: string)
	"BuySeed", -- (cropId: string, amount: number)
	"BuyItem", -- (itemId: string, amount: number)
	"Travel", -- (target: "market" | "home" | userId)
	-- server -> client
	"StateChanged", -- (state)
	"Notify", -- (text, kind)
	"OpenShop",
}
local FUNCTIONS = {
	"GetState",
}

local folder: Folder

if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in ipairs(EVENTS) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	for _, name in ipairs(FUNCTIONS) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

function Remotes.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
