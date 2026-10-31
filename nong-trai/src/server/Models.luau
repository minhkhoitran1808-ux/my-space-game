--[[
	Models: dựng hình ô đất, cây trồng, vật cản và công cụ bằng code,
	theo bản thiết kế (hoạt hình, khối bo tròn, màu tươi).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cfg = require(ReplicatedStorage.Shared.Config.Game)
local Crops = require(ReplicatedStorage.Shared.Config.Crops)
local FarmLogic = require(ReplicatedStorage.Shared.FarmLogic)

local Models = {}

Models.Colors = {
	Grass = Color3.fromRGB(124, 195, 91),
	GrassDark = Color3.fromRGB(90, 154, 61),
	SoilDry = Color3.fromRGB(160, 123, 85),
	SoilWet = Color3.fromRGB(90, 61, 40),
	Leaf = Color3.fromRGB(93, 187, 76),
	LeafDark = Color3.fromRGB(47, 122, 40),
	Sprout = Color3.fromRGB(126, 217, 87),
	Seed = Color3.fromRGB(200, 163, 106),
	Weed = Color3.fromRGB(158, 157, 36),
	Pest = Color3.fromRGB(192, 57, 43),
	Rock = Color3.fromRGB(158, 158, 158),
	Wood = Color3.fromRGB(141, 110, 79),
	WoodDark = Color3.fromRGB(94, 69, 47),
	Gold = Color3.fromRGB(255, 201, 60),
}
local C = Models.Colors

function Models.rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Tạo Part trang trí (không va chạm)
function Models.part(parent: Instance, size: Vector3, color: Color3, cframe: CFrame, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.Size = size
	p.Color = color
	p.CFrame = cframe
	if props then
		for key, value in pairs(props) do
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end

local function ball(parent: Instance, diameter: number, color: Color3, position: Vector3): Part
	return Models.part(parent, Vector3.one * diameter, color, CFrame.new(position), { Shape = Enum.PartType.Ball })
end

-- ===================== Cây trồng =====================
local function buildRipe(model: Model, top: Vector3, cropId: string)
	local def = Crops.List[cropId]
	local color = Models.rgb(def.Color)
	local shape = def.Shape

	if shape == "ball" then
		local size = def.Size or 2.4
		ball(model, size * 0.55, C.Leaf, top + Vector3.new(-0.9, 0.35, 0.6))
		ball(model, size, color, top + Vector3.new(0, size / 2, 0))
	elseif shape == "root" then
		ball(model, 1.6, C.Leaf, top + Vector3.new(0, 1.5, 0))
		Models.part(model, Vector3.new(0.3, 0.9, 0.3), C.LeafDark, CFrame.new(top + Vector3.new(0, 0.7, 0)))
		ball(model, 1.0, color, top + Vector3.new(0, 0.25, 0))
	elseif shape == "tall" then
		for _, dx in ipairs({ -0.7, 0.7 }) do
			Models.part(model, Vector3.new(0.35, 3.2, 0.35), C.LeafDark, CFrame.new(top + Vector3.new(dx, 1.6, 0)))
			Models.part(model, Vector3.new(0.6, 1.2, 0.6), color, CFrame.new(top + Vector3.new(dx + 0.35, 2.4, 0)))
		end
	elseif shape == "leafy" then
		ball(model, 1.4, color, top + Vector3.new(-0.6, 0.6, 0))
		ball(model, 1.4, color, top + Vector3.new(0.6, 0.6, 0.3))
		ball(model, 1.5, C.Leaf, top + Vector3.new(0, 0.9, -0.5))
	else -- "bush"
		ball(model, 2.4, C.Leaf, top + Vector3.new(0, 1.1, 0))
		ball(model, 0.7, color, top + Vector3.new(0.9, 1.4, 0.6))
		ball(model, 0.7, color, top + Vector3.new(-0.8, 1.0, 0.8))
		ball(model, 0.7, color, top + Vector3.new(0.2, 2.1, -0.7))
	end
end

local function buildCrop(model: Model, top: Vector3, cropId: string, stage: number)
	if stage == 1 then
		ball(model, 0.5, C.Seed, top + Vector3.new(0, 0.15, 0))
	elseif stage == 2 then
		Models.part(model, Vector3.new(0.2, 0.6, 0.2), C.LeafDark, CFrame.new(top + Vector3.new(0, 0.3, 0)))
		ball(model, 0.9, C.Sprout, top + Vector3.new(0, 0.75, 0))
	elseif stage == 3 then
		Models.part(model, Vector3.new(0.3, 1.4, 0.3), C.LeafDark, CFrame.new(top + Vector3.new(0, 0.7, 0)))
		ball(model, 1.7, C.Leaf, top + Vector3.new(0, 1.6, 0))
	else
		buildRipe(model, top, cropId)
	end
end

-- ===================== Ô đất =====================
--[[
	Vẽ một ô đất theo dữ liệu `tile`. Chỉ dựng lại hình khi trạng thái đổi.
	Đồng thời ghi thuộc tính để client hiển thị bảng thông tin ô.
]]
function Models.renderTile(tilePart: BasePart, tile)
	local stage = FarmLogic.stage(tile, Crops)
	local crop = tile.crop

	if tile.s == "tilled" then
		tilePart.Color = if tile.w then C.SoilWet else C.SoilDry
		tilePart.Material = Enum.Material.Ground
	else
		tilePart.Color = C.Grass
		tilePart.Material = Enum.Material.Grass
	end

	tilePart:SetAttribute("State", tile.s)
	tilePart:SetAttribute("Watered", tile.w)
	tilePart:SetAttribute("Weed", tile.weed)
	tilePart:SetAttribute("Pest", tile.pest)
	tilePart:SetAttribute("Fertility", tile.f)
	tilePart:SetAttribute("Hp", tile.hp)
	tilePart:SetAttribute("Crop", if crop then crop.id else nil)
	tilePart:SetAttribute("Growth", if crop then crop.g else nil)
	tilePart:SetAttribute("Stars", if crop then FarmLogic.stars(tile, Cfg) else nil)

	local sig = table.concat({
		tile.s,
		tile.dk or "",
		if crop then crop.id else "",
		tostring(stage),
		tostring(tile.weed),
		tostring(tile.pest),
	}, "|")
	if tilePart:GetAttribute("Sig") == sig then
		return
	end
	tilePart:SetAttribute("Sig", sig)

	local old = tilePart:FindFirstChild("Visual")
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "Visual"
	local top = tilePart.Position + Vector3.new(0, tilePart.Size.Y / 2, 0)

	if tile.s == "debris" then
		if tile.dk == "stump" then
			Models.part(model, Vector3.new(1.8, 1.2, 1.8), C.Wood, CFrame.new(top + Vector3.new(0, 0.6, 0)), { Material = Enum.Material.Wood })
			Models.part(model, Vector3.new(1.4, 0.1, 1.4), Color3.fromRGB(214, 180, 130), CFrame.new(top + Vector3.new(0, 1.25, 0)))
		else
			Models.part(model, Vector3.new(2.8, 1.6, 2.4), C.Rock, CFrame.new(top + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, math.rad(20), 0), { Material = Enum.Material.Slate })
		end
	end

	if crop then
		buildCrop(model, top, crop.id, stage)
		if stage == 4 then
			local box = Instance.new("SelectionBox")
			box.Name = "RipeBox"
			box.Adornee = tilePart
			box.Color3 = C.Gold
			box.LineThickness = 0.08
			box.SurfaceTransparency = 1
			box.Parent = model
		end
		if tile.pest then
			ball(model, 0.45, C.Pest, top + Vector3.new(0.5, 1.2, 0.4))
			ball(model, 0.45, C.Pest, top + Vector3.new(-0.4, 0.8, -0.3))
		end
	end

	if tile.weed then
		for _, offset in ipairs({ Vector3.new(-1.4, 0, -1.3), Vector3.new(1.3, 0, 1.4), Vector3.new(1.4, 0, -1.2) }) do
			Models.part(model, Vector3.new(0.35, 0.9, 0.35), C.Weed, CFrame.new(top + offset + Vector3.new(0, 0.45, 0)))
		end
	end

	model.Parent = tilePart
end

-- ===================== Công cụ =====================
local function toolPart(tool: Tool, handle: BasePart, size: Vector3, color: Color3, offset: CFrame, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = tool
	return p
end

function Models.buildTool(toolId: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolId
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = Cfg.Tools[toolId].Name

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local red = Color3.fromRGB(192, 57, 43)
	local blue = Color3.fromRGB(31, 111, 181)
	local metal = Color3.fromRGB(176, 176, 176)

	if toolId == "Hoe" or toolId == "Sickle" then
		handle.Size = Vector3.new(0.3, 0.3, 3.4)
		handle.Color = C.Wood
		handle.Material = Enum.Material.Wood
		if toolId == "Hoe" then
			toolPart(tool, handle, Vector3.new(1.2, 0.9, 0.2), metal, CFrame.new(0, -0.35, -1.7), Enum.Material.Metal)
		else
			handle.Size = Vector3.new(0.3, 0.3, 1.6)
			toolPart(tool, handle, Vector3.new(0.15, 0.25, 1.4), metal, CFrame.new(0, 0.5, -0.9) * CFrame.Angles(math.rad(50), 0, 0), Enum.Material.Metal)
			toolPart(tool, handle, Vector3.new(0.15, 0.25, 1.0), metal, CFrame.new(0, 0.9, -0.25) * CFrame.Angles(math.rad(-20), 0, 0), Enum.Material.Metal)
		end
	elseif toolId == "WateringCan" then
		handle.Size = Vector3.new(1.2, 1.1, 1.4)
		handle.Color = blue
		toolPart(tool, handle, Vector3.new(0.25, 0.25, 1.3), blue, CFrame.new(0, 0.3, -1.1) * CFrame.Angles(math.rad(25), 0, 0))
		toolPart(tool, handle, Vector3.new(0.2, 0.9, 0.2), Color3.fromRGB(20, 78, 130), CFrame.new(0, 0.8, 0.3))
	elseif toolId == "SeedBag" or toolId == "Fertilizer" then
		handle.Size = Vector3.new(1.1, 1.3, 0.9)
		handle.Color = if toolId == "SeedBag" then Color3.fromRGB(200, 163, 106) else Color3.fromRGB(109, 76, 51)
		handle.Material = Enum.Material.Fabric
		toolPart(tool, handle, Vector3.new(0.6, 0.25, 0.6), C.LeafDark, CFrame.new(0, 0.75, 0))
	else -- Sprayer
		handle.Size = Vector3.new(0.8, 1.3, 0.8)
		handle.Color = red
		toolPart(tool, handle, Vector3.new(0.2, 0.2, 1.2), metal, CFrame.new(0, 0.5, -0.8), Enum.Material.Metal)
	end

	return tool
end

return Models
