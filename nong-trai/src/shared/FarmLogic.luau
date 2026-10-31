--[[
	FarmLogic: toàn bộ luật trồng trọt, viết THUẦN (không đụng tới Roblox)
	nên chạy test được bằng Luau CLI. Server gọi các hàm này rồi vẽ kết quả.

	Một ô đất (tile):
	{
		s = "grass" | "debris" | "tilled",
		hp = số nhát cuốc còn lại (khi s = "debris"),
		dk = "rock" | "stump" (loại vật cản),
		w = true nếu đất đã được tưới hôm nay,
		f = độ màu mỡ 0..100,
		weed = có cỏ dại, pest = có sâu,
		crop = nil | { id = cropId, g = số ngày đã lớn, pen = điểm phạt chăm sóc },
	}
]]

local FarmLogic = {}

export type Crop = { id: string, g: number, pen: number }
export type Tile = {
	s: string,
	hp: number?,
	dk: string?,
	w: boolean,
	f: number,
	weed: boolean,
	pest: boolean,
	crop: Crop?,
}
export type Result = {
	ok: boolean,
	msg: string?,
	waterUsed: number?,
	seedUsed: string?,
	fertilizerUsed: number?,
	harvest: { id: string, stars: number }?,
	helped: boolean?,
}

function FarmLogic.newTile(kind: string, cfg, debrisKind: string?): Tile
	local tile: Tile = { s = kind, w = false, f = cfg.Fertility.Start, weed = false, pest = false }
	if kind == "debris" then
		tile.hp = cfg.DebrisHp
		tile.dk = debrisKind or "rock"
	end
	return tile
end

-- Sinh các ô đất của một khu, vị trí đá/gốc cây cố định theo `seed`
function FarmLogic.generateZone(zone, cfg, seed: number): { [number]: Tile }
	local state = (seed * 7919 + zone.Id * 104729) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local function rand(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end

	local tiles = {}
	for i = 1, zone.Cols * zone.Rows do
		if rand() < zone.DebrisChance then
			tiles[i] = FarmLogic.newTile("debris", cfg, if rand() < 0.5 then "rock" else "stump")
		else
			tiles[i] = FarmLogic.newTile("grass", cfg)
		end
	end
	return tiles
end

function FarmLogic.isRipe(tile: Tile, crops): boolean
	local crop = tile.crop
	if not crop then
		return false
	end
	return crop.g >= crops.List[crop.id].Days
end

-- 0 = không có cây, 1 = hạt, 2 = mầm, 3 = cây non, 4 = chín
function FarmLogic.stage(tile: Tile, crops): number
	local crop = tile.crop
	if not crop then
		return 0
	end
	local days = crops.List[crop.id].Days
	if crop.g >= days then
		return 4
	elseif crop.g <= 0 then
		return 1
	elseif crop.g < days / 2 then
		return 2
	end
	return 3
end

-- Số sao dự kiến nếu thu hoạch bây giờ
function FarmLogic.stars(tile: Tile, cfg): number
	local crop = tile.crop
	if not crop then
		return 0
	end
	local care = if crop.pen <= 0.5 then 2 elseif crop.pen <= 2 then 1 else 0
	local soil = if tile.f >= cfg.Fertility.Good then 1 else 0
	local total = care + soil
	return if total >= 3 then 3 elseif total >= 2 then 2 else 1
end

function FarmLogic.sellPrice(cropId: string, stars: number, crops, cfg): number
	local mult = cfg.QualityMultiplier[stars] or 1
	return math.floor(crops.List[cropId].SellPrice * mult + 0.5)
end

function FarmLogic.inSeason(cropId: string, season: string, crops): boolean
	return crops.List[cropId].Season == season
end

local function fail(msg: string): Result
	return { ok = false, msg = msg }
end

--[[
	Dùng công cụ lên một ô đất. Thay đổi `tile` trực tiếp.
	ctx = {
		crops, cfg, season,
		isOwner = người dùng có phải chủ đảo,
		water = số nước trong bình,
		seedId = hạt đang chọn, seedCount = số hạt đó còn,
		fertilizer = số bao phân,
	}
]]
function FarmLogic.useTool(tile: Tile, toolId: string, ctx): Result
	local crops, cfg = ctx.crops, ctx.cfg

	if toolId == "Hoe" then
		if not ctx.isOwner then
			return fail("Chỉ chủ đảo mới được cuốc đất.")
		end
		if tile.s == "debris" then
			tile.hp = (tile.hp or 1) - 1
			if (tile.hp :: number) <= 0 then
				tile.s = "grass"
				tile.hp = nil
				tile.dk = nil
				return { ok = true, msg = "Đã dọn sạch!" }
			end
			return { ok = true, msg = "Còn " .. tostring(tile.hp) .. " nhát nữa" }
		elseif tile.s == "grass" then
			tile.s = "tilled"
			tile.w = false
			tile.weed = false
			tile.pest = false
			return { ok = true }
		elseif tile.crop then
			return fail("Ô này đang có cây.")
		end
		return fail("Đất đã được cuốc rồi.")
	elseif toolId == "WateringCan" then
		if tile.s ~= "tilled" then
			return fail("Chỉ tưới được đất đã cuốc.")
		end
		if tile.w then
			return fail("Đất đã ướt rồi.")
		end
		if (ctx.water or 0) <= 0 then
			return fail("Bình hết nước! Ra giếng múc nước.")
		end
		tile.w = true
		return { ok = true, waterUsed = 1, helped = not ctx.isOwner }
	elseif toolId == "SeedBag" then
		if not ctx.isOwner then
			return fail("Chỉ chủ đảo mới được gieo hạt.")
		end
		if tile.s ~= "tilled" then
			return fail("Hãy cuốc đất trước khi gieo.")
		end
		if tile.crop then
			return fail("Ô này đã có cây.")
		end
		if tile.weed then
			return fail("Cắt cỏ dại trước đã.")
		end
		local seedId = ctx.seedId
		if not seedId or not crops.List[seedId] or (ctx.seedCount or 0) <= 0 then
			return fail("Bạn chưa có hạt giống. Mua ở Đảo Chợ.")
		end
		if not FarmLogic.inSeason(seedId, ctx.season, crops) then
			return fail(crops.List[seedId].Name .. " chỉ trồng được vào mùa " .. crops.List[seedId].Season .. ".")
		end
		tile.crop = { id = seedId, g = 0, pen = 0 }
		return { ok = true, seedUsed = seedId }
	elseif toolId == "Sickle" then
		if tile.weed then
			tile.weed = false
			return { ok = true, msg = "Đã cắt cỏ dại", helped = not ctx.isOwner }
		end
		local crop = tile.crop
		if not crop then
			return fail("Không có gì để cắt.")
		end
		if not FarmLogic.isRipe(tile, crops) then
			return fail("Cây chưa chín.")
		end
		if not ctx.isOwner then
			return fail("Chỉ chủ đảo mới được thu hoạch.")
		end
		local stars = FarmLogic.stars(tile, cfg)
		local def = crops.List[crop.id]
		local harvest = { id = crop.id, stars = stars }
		if def.Regrow then
			crop.g = math.max(0, def.Days - def.Regrow)
			crop.pen = 0
		else
			tile.crop = nil
		end
		tile.f = math.max(0, tile.f - cfg.Fertility.HarvestCost)
		return { ok = true, harvest = harvest }
	elseif toolId == "Fertilizer" then
		if not ctx.isOwner then
			return fail("Chỉ chủ đảo mới được bón phân.")
		end
		if tile.s ~= "tilled" then
			return fail("Chỉ bón phân cho đất đã cuốc.")
		end
		if tile.f >= 100 then
			return fail("Đất đã rất màu mỡ.")
		end
		if (ctx.fertilizer or 0) <= 0 then
			return fail("Hết phân bón! Mua ở Đảo Chợ.")
		end
		tile.f = math.min(100, tile.f + cfg.Fertility.FertilizerGain)
		return { ok = true, fertilizerUsed = 1 }
	elseif toolId == "Sprayer" then
		if not tile.pest then
			return fail("Không có sâu ở đây.")
		end
		tile.pest = false
		return { ok = true, msg = "Đã diệt sâu", helped = not ctx.isOwner }
	end
	return fail("Công cụ không hợp lệ.")
end

--[[
	Mỗi giờ trong game: cỏ có thể mọc, sâu có thể xuất hiện.
	`rand` là hàm trả về số ngẫu nhiên trong [0, 1). Trả về true nếu ô thay đổi.
]]
function FarmLogic.hourTick(tile: Tile, cfg, crops, rand: () -> number): boolean
	if tile.s ~= "tilled" then
		return false
	end
	local changed = false
	if not tile.weed and rand() < cfg.WeedChancePerHour then
		tile.weed = true
		changed = true
	end
	if tile.crop and not tile.pest and not FarmLogic.isRipe(tile, crops) and rand() < cfg.PestChancePerHour then
		tile.pest = true
		changed = true
	end
	return changed
end

--[[
	Bình minh (ngày mới): cây được tưới hôm qua thì lớn thêm, đất khô lại.
	- Có sâu: không lớn, bị phạt 1
	- Không tưới: không lớn, bị phạt 1
	- Có cỏ: chỉ lớn nửa ngày, bị phạt 0,5
	- Trái mùa: đứng yên, không bị phạt
]]
function FarmLogic.dawnTick(tile: Tile, season: string, crops)
	local crop = tile.crop
	if tile.s == "tilled" and crop and not FarmLogic.isRipe(tile, crops) and FarmLogic.inSeason(crop.id, season, crops) then
		local days = crops.List[crop.id].Days
		if tile.pest then
			crop.pen += 1
		elseif tile.w then
			if tile.weed then
				crop.g = math.min(days, crop.g + 0.5)
				crop.pen += 0.5
			else
				crop.g = math.min(days, crop.g + 1)
			end
		else
			crop.pen += 1
		end
	end
	tile.w = false
end

return FarmLogic
