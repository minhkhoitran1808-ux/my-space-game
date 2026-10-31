--[[
	IslandService: giao đảo cho người chơi, tạo/xoá các ô đất trên đảo,
	và tra cứu ô đất từ Part (để kiểm tra yêu cầu từ client).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local WorldBuilder = require(script.Parent.WorldBuilder)

local IslandService = {}

local world: WorldBuilder.World
local owners: { [number]: Player } = {}
local playerIsland: { [Player]: WorldBuilder.Island } = {}
local tileParts: { [number]: { [string]: BasePart } } = {}
local partLookup: { [BasePart]: { island: WorldBuilder.Island, key: string } } = {}

local zoneById = {}
for _, zone in ipairs(Cfg.Zones) do
	zoneById[zone.Id] = zone
end

function IslandService.init(builtWorld: WorldBuilder.World)
	world = builtWorld
	for _, island in ipairs(world.islands) do
		tileParts[island.index] = {}
	end
end

function IslandService.world(): WorldBuilder.World
	return world
end

function IslandService.zone(zoneId: number)
	return zoneById[zoneId]
end

function IslandService.islandOf(player: Player): WorldBuilder.Island?
	return playerIsland[player]
end

function IslandService.ownerOf(island: WorldBuilder.Island): Player?
	return owners[island.index]
end

-- Tra cứu ô đất từ Part. Trả về nil nếu không phải ô đất hợp lệ.
function IslandService.lookup(part: BasePart): (WorldBuilder.Island?, string?)
	local entry = partLookup[part]
	if not entry then
		return nil, nil
	end
	return entry.island, entry.key
end

function IslandService.tilePart(island: WorldBuilder.Island, key: string): BasePart?
	return tileParts[island.index][key]
end

function IslandService.tileKeys(island: WorldBuilder.Island): { [string]: BasePart }
	return tileParts[island.index]
end

function IslandService.tileKey(zoneId: number, i: number): string
	return zoneId .. ":" .. i
end

-- Tạo các Part ô đất cho một khu đã mở; ẩn tấm phủ "chưa mở"
function IslandService.buildZone(island: WorldBuilder.Island, zoneId: number)
	local zone = zoneById[zoneId]
	local visual = island.zones[zoneId]
	visual.plate.Transparency = 1
	visual.post.Transparency = 1
	visual.post.CanCollide = false
	visual.prompt.Enabled = false
	visual.label.Visible = false

	for i = 1, zone.Cols * zone.Rows do
		local key = IslandService.tileKey(zoneId, i)
		if not tileParts[island.index][key] then
			local part = Instance.new("Part")
			part.Name = key
			part.Anchored = true
			part.CanCollide = true
			part.CastShadow = false
			part.TopSurface = Enum.SurfaceType.Smooth
			part.Size = Vector3.new(Cfg.TileSize - 0.15, 0.4, Cfg.TileSize - 0.15)
			part.CFrame = WorldBuilder.tileCFrame(island, zone, i)
			part:SetAttribute("TileKey", key)
			part:SetAttribute("IslandIndex", island.index)
			part.Parent = island.tilesFolder
			tileParts[island.index][key] = part
			partLookup[part] = { island = island, key = key }
		end
	end
end

local function resetZones(island: WorldBuilder.Island, ownerName: string?)
	for zoneId, visual in pairs(island.zones) do
		local zone = zoneById[zoneId]
		visual.plate.Transparency = 0.35
		visual.post.Transparency = 0
		visual.post.CanCollide = true
		visual.prompt.Enabled = ownerName ~= nil
		visual.label.Visible = true
		visual.label.Text = if ownerName then string.format("%s · %d Xu", zone.Name, zone.Price) else zone.Name
	end
end

local function clearTiles(island: WorldBuilder.Island)
	for _, part in pairs(tileParts[island.index]) do
		partLookup[part] = nil
		part:Destroy()
	end
	tileParts[island.index] = {}
end

-- Giao đảo trống đầu tiên. Trả về nil nếu hết đảo.
function IslandService.assign(player: Player): WorldBuilder.Island?
	for _, island in ipairs(world.islands) do
		if not owners[island.index] then
			owners[island.index] = player
			playerIsland[player] = island
			island.model:SetAttribute("OwnerId", player.UserId)
			island.ownerLabel.Text = "Đảo của " .. player.DisplayName
			resetZones(island, player.DisplayName)
			return island
		end
	end
	return nil
end

function IslandService.release(player: Player)
	local island = playerIsland[player]
	if not island then
		return
	end
	playerIsland[player] = nil
	owners[island.index] = nil
	island.model:SetAttribute("OwnerId", 0)
	island.ownerLabel.Text = "Đảo trống"
	clearTiles(island)
	resetZones(island, nil)
end

return IslandService
