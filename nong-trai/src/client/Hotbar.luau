--[[
	Hotbar: thanh 6 công cụ to (dưới giữa) thay cho Backpack mặc định,
	phím 1-6 trên máy tính, và hàng chọn hạt khi đang cầm Túi hạt.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Theme = require(script.Parent.UI.Theme)
local Components = require(script.Parent.UI.Components)
local State = require(script.Parent.State)
local ToolController = require(script.Parent.ToolController)

local Hotbar = {}
local C = Theme.Colors
local create = Components.create

local player = Players.LocalPlayer
local SelectSeed = Remotes.event("SelectSeed")

local KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
}

type Slot = { button: TextButton, stroke: UIStroke, badge: TextLabel, bar: Frame?, barFill: Frame? }
local slots: { [string]: Slot } = {}

local function equip(toolId: string)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local current = ToolController.equipped()
	if current and current.Name == toolId then
		humanoid:UnequipTools()
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = backpack and backpack:FindFirstChild(toolId)
	if tool and tool:IsA("Tool") then
		humanoid:EquipTool(tool)
	end
end

local function disableDefaultBackpack()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

function Hotbar.init(gui: ScreenGui)
	task.spawn(disableDefaultBackpack)

	local bar = create("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(0, 84),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = C.Shade,
		BackgroundTransparency = 0.45,
		Parent = gui,
	}, {
		Components.corner(20),
		Components.padding(8),
		Components.list(Enum.FillDirection.Horizontal, 8),
	})

	for index, toolId in ipairs(Cfg.ToolOrder) do
		local button = create("TextButton", {
			Name = toolId,
			Size = UDim2.fromOffset(64, 68),
			BackgroundColor3 = C.Cream,
			AutoButtonColor = true,
			Text = "",
			LayoutOrder = index,
			Parent = bar,
		}, { Components.corner(14) })
		local stroke = Components.stroke(C.CreamBorder, 3)
		stroke.Parent = button

		Components.text({
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.fromOffset(0, 6),
			Text = Theme.ToolIcons[toolId],
			TextSize = 28,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})
		Components.text({
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.fromOffset(0, 40),
			Text = Cfg.Tools[toolId].Name,
			TextSize = 12,
			FontFace = Theme.Font.Heavy,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})
		Components.text({
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.fromOffset(5, 2),
			Text = tostring(index),
			TextSize = 11,
			TextColor3 = C.InkSoft,
			FontFace = Theme.Font.Heavy,
			Parent = button,
		})
		local badge = Components.text({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 2),
			Size = UDim2.fromOffset(40, 14),
			Text = "",
			TextSize = 12,
			FontFace = Theme.Font.Heavy,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = button,
		})

		local slot: Slot = { button = button, stroke = stroke, badge = badge }
		if toolId == "WateringCan" then
			local track = create("Frame", {
				Position = UDim2.new(0, 8, 1, -10),
				Size = UDim2.new(1, -16, 0, 5),
				BackgroundColor3 = C.WaterLight,
				Parent = button,
			}, { Components.corner(3) })
			slot.bar = track
			slot.barFill = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.Water,
				Parent = track,
			}, { Components.corner(3) })
		end
		slots[toolId] = slot

		button.Activated:Connect(function()
			equip(toolId)
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local index = KEYS[input.KeyCode]
		if index then
			equip(Cfg.ToolOrder[index])
		end
	end)

	-- ===== Hàng chọn hạt giống =====
	local seedRow = create("Frame", {
		Name = "SeedPicker",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.fromOffset(0, 58),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}, { Components.list(Enum.FillDirection.Horizontal, 6) })

	local function renderSeeds()
		Components.clear(seedRow)
		local data = State.data
		if not data then
			return
		end
		local season = State.time().season
		local any = false
		for order, cropId in ipairs(Crops.Order) do
			local count = data.seeds[cropId] or 0
			if count > 0 then
				any = true
				local def = Crops.List[cropId]
				local selected = data.selectedSeed == cropId
				local inSeason = def.Season == season
				local chip = create("TextButton", {
					Size = UDim2.fromOffset(0, 52),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundColor3 = if selected then C.White elseif inSeason then C.Cream else C.Muted,
					Text = "",
					LayoutOrder = order,
					Parent = seedRow,
				}, {
					Components.corner(14),
					Components.stroke(if selected then C.Sun else C.CreamBorder, if selected then 4 else 3),
					Components.list(Enum.FillDirection.Horizontal, 8),
					create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }),
				})
				create("Frame", {
					Size = UDim2.fromOffset(26, 26),
					BackgroundColor3 = Color3.fromRGB(def.Color[1], def.Color[2], def.Color[3]),
					LayoutOrder = 1,
					Parent = chip,
				}, { Components.corner(13), Components.stroke(C.Ink, 2) })
				Components.text({
					Size = UDim2.fromOffset(0, 40),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = string.format("%s x%d%s", def.Name, count, if inSeason then "" else "\n(trái mùa)"),
					TextSize = 15,
					TextColor3 = if inSeason then C.Ink else C.InkSoft,
					LayoutOrder = 2,
					Parent = chip,
				})
				chip.Activated:Connect(function()
					SelectSeed:FireServer(cropId)
				end)
			end
		end
		if not any then
			local hint = Components.text({
				Size = UDim2.fromOffset(0, 44),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0,
				BackgroundColor3 = C.Cream,
				Text = "Hết hạt giống: mua ở Tiệm hạt trên Đảo Chợ",
				TextSize = 15,
				Parent = seedRow,
			})
			Components.corner(12).Parent = hint
			create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }).Parent = hint
		end
	end

	local function renderCounts(data)
		local seedId = data.selectedSeed
		slots.SeedBag.badge.Text = if seedId then "x" .. tostring(data.seeds[seedId] or 0) else "x0"
		slots.Fertilizer.badge.Text = "x" .. tostring(data.fertilizer)
		local can = slots.WateringCan
		if can.barFill then
			can.barFill.Size = UDim2.fromScale(math.clamp(data.water / Cfg.WaterCapacity, 0, 1), 1)
		end
		can.badge.Text = tostring(data.water)
	end

	State.onChanged(function(data)
		renderCounts(data)
		if seedRow.Visible then
			renderSeeds()
		end
	end)

	-- Viền vàng ô đang cầm + hiện hàng chọn hạt khi cầm Túi hạt
	local lastEquipped: string? = nil
	task.spawn(function()
		while bar.Parent do
			local tool = ToolController.equipped()
			local name = if tool then tool.Name else nil
			if name ~= lastEquipped then
				lastEquipped = name
				for toolId, slot in pairs(slots) do
					local active = toolId == name
					slot.stroke.Color = if active then C.Sun else C.CreamBorder
					slot.stroke.Thickness = if active then 4 else 3
					slot.button.BackgroundColor3 = if active then C.White else C.Cream
				end
				seedRow.Visible = name == "SeedBag"
				if seedRow.Visible then
					renderSeeds()
				end
			end
			task.wait(0.1)
		end
	end)
end

return Hotbar
