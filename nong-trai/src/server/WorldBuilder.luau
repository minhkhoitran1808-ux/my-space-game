--[[
	WorldBuilder: dựng thế giới khi server chạy.
	- Biển (Terrain) bao quanh
	- Đảo Chợ ở giữa: tiệm hạt, quầy bán, giếng, cổng về đảo
	- 8 đảo riêng xếp vòng tròn: nhà, giếng, chỗ nhà kính, cổng sang chợ, các khu đất
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Models = require(script.Parent.Models)

local WorldBuilder = {}

local ISLAND_TOP = 2
local RING_RADIUS = 230
local ISLAND_SIZE = 100

local Colors = {
	Sand = Color3.fromRGB(232, 213, 154),
	Grass = Models.Colors.Grass,
	Wood = Models.Colors.Wood,
	WoodDark = Models.Colors.WoodDark,
	Roof = Color3.fromRGB(192, 57, 43),
	Wall = Color3.fromRGB(255, 246, 229),
	Water = Color3.fromRGB(31, 111, 181),
	Stone = Color3.fromRGB(150, 150, 150),
	Portal = Color3.fromRGB(126, 87, 194),
	Locked = Color3.fromRGB(70, 90, 60),
	Shop = Color3.fromRGB(46, 125, 50),
	Sell = Color3.fromRGB(255, 201, 60),
}

export type ZoneVisual = { plate: BasePart, post: BasePart, prompt: ProximityPrompt, label: TextLabel }
export type Island = {
	index: number,
	center: Vector3,
	model: Model,
	tilesFolder: Folder,
	spawnCFrame: CFrame,
	ownerLabel: TextLabel,
	wellPrompt: ProximityPrompt,
	travelPrompt: ProximityPrompt,
	zones: { [number]: ZoneVisual },
}
export type Market = {
	spawnCFrame: CFrame,
	shopPrompt: ProximityPrompt,
	sellPrompt: ProximityPrompt,
	wellPrompt: ProximityPrompt,
	travelPrompt: ProximityPrompt,
}
export type World = { market: Market, islands: { Island } }

-- ===================== Tiện ích =====================
local function solid(parent: Instance, name: string, size: Vector3, color: Color3, cframe: CFrame, material: Enum.Material?): Part
	local p = Models.part(parent, size, color, cframe, { CanCollide = true, CastShadow = true })
	p.Name = name
	p.Material = material or Enum.Material.SmoothPlastic
	return p
end

local function billboard(parent: Instance, text: string, width: number, offsetY: number, maxDistance: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width, 44)
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.FontFace = Font.new(Font.fromEnum(Enum.Font.Nunito).Family, Enum.FontWeight.Heavy)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end

local function prompt(parent: Instance, action: string, object: string, hold: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function islandBase(parent: Instance, center: Vector3, size: number)
	solid(parent, "Sand", Vector3.new(size + 12, 5, size + 12), Colors.Sand, CFrame.new(center + Vector3.new(0, ISLAND_TOP - 3.5, 0)), Enum.Material.Sand)
	solid(parent, "Ground", Vector3.new(size, 6, size), Colors.Grass, CFrame.new(center + Vector3.new(0, ISLAND_TOP - 3, 0)), Enum.Material.Grass)
end

local function stall(parent: Instance, position: Vector3, color: Color3, title: string): BasePart
	local model = Instance.new("Model")
	model.Name = title
	model.Parent = parent
	local counter = solid(model, "Counter", Vector3.new(12, 3.5, 4), color, CFrame.new(position + Vector3.new(0, 1.75, 0)), Enum.Material.WoodPlanks)
	for _, dx in ipairs({ -5.5, 5.5 }) do
		solid(model, "Post", Vector3.new(0.8, 8, 0.8), Colors.Wood, CFrame.new(position + Vector3.new(dx, 4, -1.5)), Enum.Material.Wood)
	end
	solid(model, "Roof", Vector3.new(14, 0.8, 6), Colors.Roof, CFrame.new(position + Vector3.new(0, 8.4, -0.5)))
	billboard(counter, title, 240, 8, 160)
	return counter
end

local function well(parent: Instance, position: Vector3): BasePart
	local model = Instance.new("Model")
	model.Name = "Well"
	model.Parent = parent
	local base = solid(model, "Base", Vector3.new(5, 3, 5), Colors.Stone, CFrame.new(position + Vector3.new(0, 1.5, 0)), Enum.Material.Cobblestone)
	Models.part(model, Vector3.new(3.6, 0.2, 3.6), Colors.Water, CFrame.new(position + Vector3.new(0, 3.05, 0)), { Material = Enum.Material.Glass, Transparency = 0.2 })
	for _, dx in ipairs({ -2.2, 2.2 }) do
		solid(model, "Post", Vector3.new(0.5, 4, 0.5), Colors.Wood, CFrame.new(position + Vector3.new(dx, 5, 0)), Enum.Material.Wood)
	end
	solid(model, "Roof", Vector3.new(6, 0.6, 4), Colors.Roof, CFrame.new(position + Vector3.new(0, 7.2, 0)))
	billboard(base, "Giếng nước", 160, 7, 80)
	return base
end

local function portal(parent: Instance, position: Vector3, title: string): BasePart
	local pad = solid(parent, "TravelPad", Vector3.new(8, 0.6, 8), Colors.Portal, CFrame.new(position + Vector3.new(0, 0.3, 0)), Enum.Material.Neon)
	billboard(pad, title, 220, 4, 120)
	return pad
end

local function house(parent: Instance, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "House"
	model.Parent = parent
	solid(model, "Walls", Vector3.new(16, 9, 12), Colors.Wall, CFrame.new(position + Vector3.new(0, 4.5, 0)), Enum.Material.WoodPlanks)
	solid(model, "Roof", Vector3.new(18, 1.2, 14), Colors.Roof, CFrame.new(position + Vector3.new(0, 9.6, 0)))
	Models.part(model, Vector3.new(3, 5, 0.2), Colors.WoodDark, CFrame.new(position + Vector3.new(0, 2.5, 6.05)))
end

-- ===================== Đảo Chợ =====================
local function buildMarket(world: Instance): Market
	local model = Instance.new("Model")
	model.Name = "Market"
	model.Parent = world
	islandBase(model, Vector3.zero, 150)

	local top = Vector3.new(0, ISLAND_TOP, 0)
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(top + Vector3.new(0, 0.5, 10))
	spawn.Color = Colors.Sand
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0
	spawn.Parent = model

	local shopCounter = stall(model, top + Vector3.new(-26, 0, -20), Colors.Shop, "Tiệm hạt Bà Bảy")
	local sellCounter = stall(model, top + Vector3.new(26, 0, -20), Colors.Sell, "Quầy thu mua")
	local wellBase = well(model, top + Vector3.new(0, 0, 34))
	local pad = portal(model, top + Vector3.new(0, 0, -40), "Về đảo của tôi")

	return {
		spawnCFrame = CFrame.new(top + Vector3.new(0, 4, 10)),
		shopPrompt = prompt(shopCounter, "Mua hạt giống", "Tiệm hạt"),
		sellPrompt = prompt(sellCounter, "Bán tất cả", "Quầy thu mua", 0.4),
		wellPrompt = prompt(wellBase, "Múc nước", "Giếng"),
		travelPrompt = prompt(pad, "Về đảo", "Cổng dịch chuyển"),
	}
end

-- ===================== Đảo riêng =====================
local function buildIsland(world: Instance, index: number): Island
	local angle = (index - 1) / Cfg.MaxIslands * math.pi * 2
	local center = Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS)
	local top = center + Vector3.new(0, ISLAND_TOP, 0)

	local model = Instance.new("Model")
	model.Name = "Island" .. index
	model:SetAttribute("IslandIndex", index)
	model:SetAttribute("OwnerId", 0)
	model.Parent = world
	islandBase(model, center, ISLAND_SIZE)

	house(model, top + Vector3.new(-30, 0, -38))
	local wellBase = well(model, top + Vector3.new(-10, 0, -38))
	local greenhouse = Models.part(model, Vector3.new(14, 0.3, 10), Color3.fromRGB(200, 230, 255), CFrame.new(top + Vector3.new(14, 0.15, -38)), { Transparency = 0.4 })
	billboard(greenhouse, "Nhà kính (sắp có)", 200, 3, 60)
	local pad = portal(model, top + Vector3.new(34, 0, 34), "Đến Đảo Chợ")

	local signPost = solid(model, "OwnerSign", Vector3.new(0.8, 6, 0.8), Colors.Wood, CFrame.new(top + Vector3.new(24, 3, 14)), Enum.Material.Wood)
	local ownerLabel = billboard(signPost, "Đảo trống", 280, 5, 200)

	local tilesFolder = Instance.new("Folder")
	tilesFolder.Name = "Tiles"
	tilesFolder.Parent = model

	-- Khu đất: tấm phủ "chưa mở" + cọc biển có nút mua
	local zones = {}
	for _, zone in ipairs(Cfg.Zones) do
		local w, d = zone.Cols * Cfg.TileSize, zone.Rows * Cfg.TileSize
		local zoneCenter = top + Vector3.new(zone.X + w / 2, 0, zone.Z + d / 2)
		local plate = Models.part(model, Vector3.new(w, 0.2, d), Colors.Locked, CFrame.new(zoneCenter + Vector3.new(0, 0.1, 0)), { Transparency = 0.35, Material = Enum.Material.Grass })
		plate.Name = "ZonePlate" .. zone.Id
		local post = solid(model, "ZonePost" .. zone.Id, Vector3.new(0.6, 5, 0.6), Colors.Wood, CFrame.new(zoneCenter + Vector3.new(0, 2.5, 0)), Enum.Material.Wood)
		local label = billboard(post, zone.Name, 220, 4, 80)
		local buy = prompt(post, "Mua khu đất", zone.Name, 0.5)
		zones[zone.Id] = { plate = plate, post = post, prompt = buy, label = label }
	end

	return {
		index = index,
		center = center,
		model = model,
		tilesFolder = tilesFolder,
		spawnCFrame = CFrame.lookAt(top + Vector3.new(24, 4, 4), top + Vector3.new(-20, 4, 4)),
		ownerLabel = ownerLabel,
		wellPrompt = prompt(wellBase, "Múc nước", "Giếng"),
		travelPrompt = prompt(pad, "Sang chợ", "Cổng dịch chuyển"),
		zones = zones,
	}
end

function WorldBuilder.build(): World
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace

	-- Biển & đáy cát
	local terrain = workspace.Terrain
	terrain:FillBlock(CFrame.new(0, -12, 0), Vector3.new(1400, 8, 1400), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(1400, 8, 1400), Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(94, 194, 232)
	terrain.WaterTransparency = 0.4

	local market = buildMarket(world)
	local islands = {}
	for i = 1, Cfg.MaxIslands do
		islands[i] = buildIsland(world, i)
	end
	return { market = market, islands = islands }
end

-- Vị trí ô số i (1-based, theo hàng) của một khu trên đảo
function WorldBuilder.tileCFrame(island: Island, zone, i: number): CFrame
	local col = (i - 1) % zone.Cols
	local row = (i - 1) // zone.Cols
	local x = zone.X + (col + 0.5) * Cfg.TileSize
	local z = zone.Z + (row + 0.5) * Cfg.TileSize
	return CFrame.new(island.center + Vector3.new(x, ISLAND_TOP + 0.2, z))
end

return WorldBuilder
