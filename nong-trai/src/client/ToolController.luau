--[[
	ToolController: tìm ô đất đang nhắm (chuột / chạm, hoặc ô ngay trước mặt),
	viền sáng ô đó và gửi yêu cầu dùng công cụ lên server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Theme = require(script.Parent.UI.Theme)
local Notifications = require(script.Parent.Notifications)

local ToolController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local UseTool = Remotes.event("UseTool")

local currentTarget: BasePart? = nil
local hooked: { [Tool]: boolean } = {}

local selection = Instance.new("SelectionBox")
selection.Name = "TileTarget"
selection.Color3 = Theme.Colors.White
selection.LineThickness = 0.07
selection.SurfaceColor3 = Theme.Colors.White
selection.SurfaceTransparency = 0.85

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

-- Leo ngược từ Part trúng chuột lên tới Part ô đất (có thuộc tính TileKey)
local function tileFrom(instance: Instance?): BasePart?
	while instance and instance ~= workspace do
		if instance:IsA("BasePart") and instance:GetAttribute("TileKey") then
			return instance
		end
		instance = instance.Parent
	end
	return nil
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function ToolController.equipped(): Tool?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
end

local function findTarget(): BasePart?
	local root = rootPart()
	if not root then
		return nil
	end
	local hit = tileFrom(mouse.Target)
	if hit and (hit.Position - root.Position).Magnitude <= Cfg.ToolRange then
		return hit
	end

	-- Không nhắm được bằng chuột: lấy ô gần nhất ngay trước mặt nhân vật
	local world = workspace:FindFirstChild("World")
	if not world then
		return nil
	end
	overlapParams.FilterDescendantsInstances = { world }
	local probe = root.Position + root.CFrame.LookVector * 3.5 - Vector3.new(0, 2.5, 0)
	local best, bestDistance = nil, math.huge
	for _, part in ipairs(workspace:GetPartBoundsInRadius(probe, 3, overlapParams)) do
		local tile = tileFrom(part)
		if tile then
			local distance = (tile.Position - probe).Magnitude
			if distance < bestDistance then
				best, bestDistance = tile, distance
			end
		end
	end
	return best
end

function ToolController.target(): BasePart?
	return currentTarget
end

local function hookTool(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		local target = findTarget()
		if target then
			UseTool:FireServer(target, tool.Name)
		else
			Notifications.show("Bấm vào một ô đất trên đảo (hoặc đứng ngay trước ô đất).", "info")
		end
	end)
	tool.Destroying:Connect(function()
		hooked[tool] = nil
	end)
end

local function watchContainer(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

function ToolController.init()
	selection.Parent = player:WaitForChild("PlayerGui")

	local function onCharacter(character: Model)
		watchContainer(character)
		watchContainer(player:WaitForChild("Backpack"))
	end
	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	RunService.RenderStepped:Connect(function()
		currentTarget = if ToolController.equipped() then findTarget() else nil
		selection.Adornee = currentTarget
	end)
end

return ToolController
