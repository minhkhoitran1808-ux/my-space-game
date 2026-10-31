--[[
	Main (LocalScript): dựng giao diện và nhận dữ liệu từ server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Components = require(script.Parent.UI.Components)
local HUD = require(script.Parent.HUD)
local Hotbar = require(script.Parent.Hotbar)
local Inventory = require(script.Parent.Inventory)
local Notifications = require(script.Parent.Notifications)
local Shop = require(script.Parent.Shop)
local State = require(script.Parent.State)
local TilePopup = require(script.Parent.TilePopup)
local ToolController = require(script.Parent.ToolController)
local Travel = require(script.Parent.Travel)

local player = Players.LocalPlayer

local gui = Components.create("ScreenGui", {
	Name = "NongTraiUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

Notifications.init(gui)
ToolController.init()
HUD.init(gui)
Hotbar.init(gui)
TilePopup.init(gui)
Shop.init(gui)
Inventory.init(gui)
Travel.init(gui)

Remotes.event("Notify").OnClientEvent:Connect(function(text, kind)
	Notifications.show(text, kind)
end)
Remotes.event("StateChanged").OnClientEvent:Connect(function(data)
	State.set(data)
end)

task.spawn(function()
	local ok, data = pcall(function()
		return Remotes.func("GetState"):InvokeServer()
	end)
	if ok and data and not State.data then
		State.set(data)
	end
end)
