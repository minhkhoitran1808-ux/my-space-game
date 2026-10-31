--[[
	MapBuilder (ModuleScript)
	Đặt tại: ServerScriptService > MapBuilder

	Tự động dựng bản đồ khi server chạy: nền cỏ, 6 mảnh ruộng (ô đất, hàng rào,
	biển tên), quầy bán và quầy cửa hàng ở giữa. Bạn không cần tự xây gì cả.
	Mọi thứ nằm trong Workspace > FarmMap.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local MapBuilder = {}

local GROUND_TOP = 0.1
local PLOT_SIZE = 56
local TILE_SIZE = 8
local TILE_GAP = 3
local FENCE_HEIGHT = 3

MapBuilder.Colors = {
	Grass = Color3.fromRGB(106, 170, 72),
	PlotFloor = Color3.fromRGB(124, 160, 80),
	Soil = Color3.fromRGB(110, 72, 40),
	LockedSoil = Color3.fromRGB(85, 95, 70),
	Fence = Color3.fromRGB(150, 100, 60),
	Sell = Color3.fromRGB(240, 180, 40),
	Shop = Color3.fromRGB(60, 150, 230),
}
local Colors = MapBuilder.Colors

-- Vị trí tâm 6 mảnh ruộng; dir = hướng cổng (quay về khu trung tâm)
local PLOT_LAYOUT = {
	{ x = -66, z = -62, dir = 1 },
	{ x = 0, z = -62, dir = 1 },
	{ x = 66, z = -62, dir = 1 },
	{ x = -66, z = 62, dir = -1 },
	{ x = 0, z = 62, dir = -1 },
	{ x = 66, z = 62, dir = -1 },
}

local function makePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		if key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent
	return part
end

local function makeBillboard(parent: Instance, text: string, size: UDim2, offsetY: number, maxDistance: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = size
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.MaxDistance = maxDistance
	billboard.LightInfluence = 0
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = billboard

	return billboard, label
end

local function makePrompt(parent: Instance, actionText: string, objectText: string, distance: number)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Parent = parent
	return prompt
end

local function buildGround(map: Instance)
	makePart({
		Name = "Ground",
		Size = Vector3.new(320, 0.2, 320),
		Position = Vector3.new(0, GROUND_TOP - 0.1, 0),
		Color = Colors.Grass,
		Material = Enum.Material.Grass,
		Parent = map,
	})

	-- Dùng SpawnLocation có sẵn (template Baseplate) hoặc tạo mới ở giữa bản đồ
	if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		local spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Size = Vector3.new(10, 1, 10)
		spawn.Position = Vector3.new(0, GROUND_TOP + 0.5, 0)
		spawn.Color = Color3.fromRGB(230, 230, 230)
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Duration = 0 -- không có khiên bảo vệ
		spawn.Parent = map
	end
end

local function buildStand(map: Instance, name: string, position: Vector3, color: Color3, title: string)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = map

	local counter = makePart({
		Name = "Counter",
		Size = Vector3.new(12, 3.5, 4),
		Position = position + Vector3.new(0, 1.75, 0),
		Color = color,
		Material = Enum.Material.WoodPlanks,
		Parent = model,
	})
	for _, dx in ipairs({ -5.5, 5.5 }) do
		makePart({
			Name = "Post",
			Size = Vector3.new(0.8, 8, 0.8),
			Position = position + Vector3.new(dx, 4, -1.5),
			Color = Colors.Fence,
			Material = Enum.Material.Wood,
			Parent = model,
		})
	end
	makePart({
		Name = "Roof",
		Size = Vector3.new(14, 0.8, 6),
		Position = position + Vector3.new(0, 8.4, -0.5),
		Color = Color3.fromRGB(200, 60, 60),
		Parent = model,
	})
	makeBillboard(counter, title, UDim2.fromOffset(220, 50), 8, 150)
	model.PrimaryPart = counter
	return counter
end

local function buildPlot(map: Instance, index: number, layout)
	local center = Vector3.new(layout.x, GROUND_TOP, layout.z)
	local dir = layout.dir
	local half = PLOT_SIZE / 2

	-- Chuyển toạ độ "cục bộ" (lx = ngang, lz = về phía cổng) thành toạ độ thế giới
	local function at(lx: number, y: number, lz: number): Vector3
		return center + Vector3.new(lx * dir, y, lz * dir)
	end

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("OwnerId", 0)
	model.Parent = map

	makePart({
		Name = "Floor",
		Size = Vector3.new(PLOT_SIZE, 0.4, PLOT_SIZE),
		Position = at(0, 0.2, 0),
		Color = Colors.PlotFloor,
		Material = Enum.Material.Grass,
		Parent = model,
	})

	-- Hàng rào: sau, trái, phải và 2 đoạn phía trước (chừa cổng ở giữa)
	local fenceY = 0.4 + FENCE_HEIGHT / 2
	local fences = {
		{ size = Vector3.new(PLOT_SIZE, FENCE_HEIGHT, 0.6), pos = at(0, fenceY, -half) },
		{ size = Vector3.new(0.6, FENCE_HEIGHT, PLOT_SIZE), pos = at(-half, fenceY, 0) },
		{ size = Vector3.new(0.6, FENCE_HEIGHT, PLOT_SIZE), pos = at(half, fenceY, 0) },
		{ size = Vector3.new(22, FENCE_HEIGHT, 0.6), pos = at(-17, fenceY, half) },
		{ size = Vector3.new(22, FENCE_HEIGHT, 0.6), pos = at(17, fenceY, half) },
	}
	for _, fence in ipairs(fences) do
		makePart({
			Name = "Fence",
			Size = fence.size,
			Position = fence.pos,
			Color = Colors.Fence,
			Material = Enum.Material.WoodPlanks,
			Parent = model,
		})
	end

	-- Biển tên chủ ruộng ở cổng
	local signPost = makePart({
		Name = "Sign",
		Size = Vector3.new(0.8, 6, 0.8),
		Position = at(-8, 3.4, half),
		Color = Colors.Fence,
		Material = Enum.Material.Wood,
		Parent = model,
	})
	local _, signLabel = makeBillboard(signPost, "Ruộng trống", UDim2.fromOffset(260, 50), 4.5, 120)

	-- Ô đất: hàng 1 gần cổng nhất, mỗi cấp "Mở rộng ruộng" mở thêm 1 hàng
	local tilesFolder = Instance.new("Folder")
	tilesFolder.Name = "Tiles"
	tilesFolder.Parent = model

	local step = TILE_SIZE + TILE_GAP
	local tiles = {}
	for i = 1, GameConfig.MaxTiles do
		local row = math.ceil(i / GameConfig.TilesPerRow)
		local col = (i - 1) % GameConfig.TilesPerRow + 1
		local lx = (col - (GameConfig.TilesPerRow + 1) / 2) * step
		local lz = 13.5 - (row - 1) * step

		local tilePart = makePart({
			Name = "Tile" .. i,
			Size = Vector3.new(TILE_SIZE, 0.6, TILE_SIZE),
			Position = at(lx, 0.7, lz),
			Color = Colors.LockedSoil,
			Material = Enum.Material.Ground,
			Parent = tilesFolder,
		})
		tilePart:SetAttribute("TileIndex", i)

		local prompt = makePrompt(tilePart, "Trồng hạt", "Ô đất", 10)
		prompt.Enabled = false

		local billboard, label = makeBillboard(tilePart, "", UDim2.fromOffset(110, 30), 5, 60)
		billboard.Enabled = false

		tiles[i] = { part = tilePart, prompt = prompt, billboard = billboard, label = label }
	end

	return {
		index = index,
		model = model,
		signLabel = signLabel,
		tiles = tiles,
		-- Đứng ở cổng, nhìn vào trong ruộng
		spawnCFrame = CFrame.lookAt(at(0, 4, half - 4), at(0, 4, 0)),
	}
end

--[[
	Dựng toàn bộ bản đồ. Trả về:
	{
		plots = { {index, model, signLabel, tiles = {{part, prompt, billboard, label}}, spawnCFrame}, ... },
		sellPrompt = ProximityPrompt,
		shopPrompt = ProximityPrompt,
	}
]]
function MapBuilder.build()
	local old = workspace:FindFirstChild("FarmMap")
	if old then
		old:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "FarmMap"
	map.Parent = workspace

	buildGround(map)

	local sellCounter = buildStand(map, "SellStand", Vector3.new(-24, GROUND_TOP, 0), Colors.Sell, "💰 QUẦY BÁN")
	local sellPrompt = makePrompt(sellCounter, "Bán tất cả", "Quầy bán nông sản", 12)
	sellPrompt.HoldDuration = 0.3

	local shopCounter = buildStand(map, "ShopStand", Vector3.new(24, GROUND_TOP, 0), Colors.Shop, "🛒 CỬA HÀNG")
	local shopPrompt = makePrompt(shopCounter, "Mở cửa hàng", "Hạt giống & Nâng cấp", 12)

	local plots = {}
	for i = 1, math.min(GameConfig.MaxPlots, #PLOT_LAYOUT) do
		plots[i] = buildPlot(map, i, PLOT_LAYOUT[i])
	end

	return {
		plots = plots,
		sellPrompt = sellPrompt,
		shopPrompt = shopPrompt,
	}
end

return MapBuilder
