--[[
	Test logic trồng trọt. Chạy: luau tests/FarmLogic.spec.luau
]]

local FarmLogic = require("../src/shared/FarmLogic")
local GameTime = require("../src/shared/GameTime")
local Format = require("../src/shared/Format")
local Crops = require("../src/shared/Config/Crops")
local Cfg = require("../src/shared/Config/Game")

local passed, failed = 0, 0
local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print("FAIL  " .. name .. "\n      " .. tostring(err))
	end
end
local function eq(actual, expected, label: string?)
	if actual ~= expected then
		error(string.format("%s: mong đợi %s, nhận %s", label or "giá trị", tostring(expected), tostring(actual)), 2)
	end
end

local function ctx(overrides)
	local c = {
		crops = Crops,
		cfg = Cfg,
		season = "Xuân",
		isOwner = true,
		water = 10,
		seedId = "CaRot",
		seedCount = 5,
		fertilizer = 3,
	}
	for k, v in pairs(overrides or {}) do
		c[k] = v
	end
	return c
end

local function plantedTile(cropId: string?)
	local tile = FarmLogic.newTile("grass", Cfg)
	FarmLogic.useTool(tile, "Hoe", ctx())
	FarmLogic.useTool(tile, "SeedBag", ctx({ seedId = cropId or "CaRot" }))
	return tile
end

-- ===== Cấu hình =====
test("mọi cây trong Order đều có trong List và ngược lại", function()
	local count = 0
	for _, id in ipairs(Crops.Order) do
		assert(Crops.List[id], "thiếu " .. id)
		local def = Crops.List[id]
		assert(table.find(Cfg.Time.Seasons, def.Season), id .. " có mùa sai: " .. def.Season)
		assert(def.SellPrice > 0 and def.SeedPrice > 0 and def.Days > 0, id .. " số liệu không hợp lệ")
		assert(#def.Color == 3, id .. " màu phải có 3 số")
		count += 1
	end
	for _ in pairs(Crops.List) do
		count -= 1
	end
	eq(count, 0, "số cây lệch giữa Order và List")
end)

test("mỗi mùa có ít nhất 3 loại cây", function()
	for _, season in ipairs(Cfg.Time.Seasons) do
		local n = 0
		for _, def in pairs(Crops.List) do
			if def.Season == season then
				n += 1
			end
		end
		assert(n >= 3, season .. " chỉ có " .. n .. " cây")
	end
end)

-- ===== Công cụ =====
test("cuốc biến cỏ thành đất, cuốc lần nữa thì báo lỗi", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	eq(FarmLogic.useTool(tile, "Hoe", ctx()).ok, true)
	eq(tile.s, "tilled")
	eq(FarmLogic.useTool(tile, "Hoe", ctx()).ok, false)
end)

test("dọn đá cần đúng DebrisHp nhát", function()
	local tile = FarmLogic.newTile("debris", Cfg, "rock")
	for _ = 1, Cfg.DebrisHp - 1 do
		FarmLogic.useTool(tile, "Hoe", ctx())
		eq(tile.s, "debris")
	end
	FarmLogic.useTool(tile, "Hoe", ctx())
	eq(tile.s, "grass")
	eq(tile.hp, nil)
end)

test("không gieo được trên cỏ, gieo được trên đất cuốc", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	eq(FarmLogic.useTool(tile, "SeedBag", ctx()).ok, false)
	FarmLogic.useTool(tile, "Hoe", ctx())
	local r = FarmLogic.useTool(tile, "SeedBag", ctx())
	eq(r.ok, true)
	eq(r.seedUsed, "CaRot")
	eq(tile.crop and tile.crop.id, "CaRot")
end)

test("không gieo được cây trái mùa", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	FarmLogic.useTool(tile, "Hoe", ctx())
	eq(FarmLogic.useTool(tile, "SeedBag", ctx({ seedId = "DuaHau" })).ok, false)
	eq(tile.crop, nil)
end)

test("hết hạt thì không gieo được", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	FarmLogic.useTool(tile, "Hoe", ctx())
	eq(FarmLogic.useTool(tile, "SeedBag", ctx({ seedCount = 0 })).ok, false)
end)

test("có cỏ dại thì phải cắt trước khi gieo", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	FarmLogic.useTool(tile, "Hoe", ctx())
	tile.weed = true
	eq(FarmLogic.useTool(tile, "SeedBag", ctx()).ok, false)
	eq(FarmLogic.useTool(tile, "Sickle", ctx()).ok, true)
	eq(tile.weed, false)
	eq(FarmLogic.useTool(tile, "SeedBag", ctx()).ok, true)
end)

test("tưới tốn 1 nước, không tưới 2 lần, hết nước thì báo", function()
	local tile = plantedTile()
	local r = FarmLogic.useTool(tile, "WateringCan", ctx())
	eq(r.ok, true)
	eq(r.waterUsed, 1)
	eq(FarmLogic.useTool(tile, "WateringCan", ctx()).ok, false)
	local dry = plantedTile()
	eq(FarmLogic.useTool(dry, "WateringCan", ctx({ water = 0 })).ok, false)
end)

test("khách chỉ được tưới, cắt cỏ, xịt sâu", function()
	local guest = ctx({ isOwner = false })
	local tile = FarmLogic.newTile("grass", Cfg)
	eq(FarmLogic.useTool(tile, "Hoe", guest).ok, false)
	FarmLogic.useTool(tile, "Hoe", ctx())
	eq(FarmLogic.useTool(tile, "SeedBag", guest).ok, false)
	eq(FarmLogic.useTool(tile, "Fertilizer", guest).ok, false)
	FarmLogic.useTool(tile, "SeedBag", ctx())
	local r = FarmLogic.useTool(tile, "WateringCan", guest)
	eq(r.ok, true)
	eq(r.helped, true)
	tile.pest = true
	eq(FarmLogic.useTool(tile, "Sprayer", guest).ok, true)
end)

test("khách không được thu hoạch", function()
	local tile = plantedTile()
	tile.crop.g = Crops.List.CaRot.Days
	eq(FarmLogic.useTool(tile, "Sickle", ctx({ isOwner = false })).ok, false)
	assert(tile.crop ~= nil, "cây bị mất")
end)

test("phân bón tăng màu mỡ, tối đa 100", function()
	local tile = FarmLogic.newTile("grass", Cfg)
	FarmLogic.useTool(tile, "Hoe", ctx())
	FarmLogic.useTool(tile, "Fertilizer", ctx())
	eq(tile.f, Cfg.Fertility.Start + Cfg.Fertility.FertilizerGain)
	FarmLogic.useTool(tile, "Fertilizer", ctx())
	eq(tile.f, 100)
	eq(FarmLogic.useTool(tile, "Fertilizer", ctx()).ok, false)
end)

-- ===== Ngày mới =====
test("cây được tưới lớn 1 ngày, đất khô lại lúc bình minh", function()
	local tile = plantedTile()
	FarmLogic.useTool(tile, "WateringCan", ctx())
	FarmLogic.dawnTick(tile, "Xuân", Crops)
	eq(tile.crop.g, 1)
	eq(tile.w, false)
	eq(tile.crop.pen, 0)
end)

test("không tưới thì cây đứng yên và bị phạt", function()
	local tile = plantedTile()
	FarmLogic.dawnTick(tile, "Xuân", Crops)
	eq(tile.crop.g, 0)
	eq(tile.crop.pen, 1)
end)

test("có cỏ lớn nửa ngày, có sâu không lớn", function()
	local weedy = plantedTile()
	weedy.w = true
	weedy.weed = true
	FarmLogic.dawnTick(weedy, "Xuân", Crops)
	eq(weedy.crop.g, 0.5)
	local buggy = plantedTile()
	buggy.w = true
	buggy.pest = true
	FarmLogic.dawnTick(buggy, "Xuân", Crops)
	eq(buggy.crop.g, 0)
	eq(buggy.crop.pen, 1)
end)

test("trái mùa thì cây đứng yên nhưng không bị phạt", function()
	local tile = plantedTile()
	tile.w = true
	FarmLogic.dawnTick(tile, "Hạ", Crops)
	eq(tile.crop.g, 0)
	eq(tile.crop.pen, 0)
end)

test("giai đoạn: hạt -> mầm -> cây non -> chín", function()
	local tile = plantedTile("DauTay") -- 4 ngày
	eq(FarmLogic.stage(tile, Crops), 1)
	local seen = {}
	for _ = 1, 4 do
		tile.w = true
		FarmLogic.dawnTick(tile, "Xuân", Crops)
		table.insert(seen, FarmLogic.stage(tile, Crops))
	end
	eq(table.concat(seen, ","), "2,3,3,4")
	-- không lớn quá số ngày
	tile.w = true
	FarmLogic.dawnTick(tile, "Xuân", Crops)
	eq(tile.crop.g, 4)
end)

-- ===== Thu hoạch & chất lượng =====
local function grow(tile, perfect: boolean)
	local days = Crops.List[tile.crop.id].Days
	for _ = 1, days do
		if perfect then
			tile.w = true
		end
		FarmLogic.dawnTick(tile, "Xuân", Crops)
	end
end

test("chăm hoàn hảo + bón phân = 3 sao", function()
	local tile = plantedTile()
	FarmLogic.useTool(tile, "Fertilizer", ctx())
	grow(tile, true)
	local r = FarmLogic.useTool(tile, "Sickle", ctx())
	eq(r.ok, true)
	eq(r.harvest.stars, 3)
	eq(tile.crop, nil)
end)

test("chăm hoàn hảo không bón phân = 2 sao", function()
	local tile = plantedTile()
	grow(tile, true)
	eq(FarmLogic.useTool(tile, "Sickle", ctx()).harvest.stars, 2)
end)

test("bỏ bê nhiều = 1 sao", function()
	local tile = plantedTile()
	for _ = 1, 3 do
		FarmLogic.dawnTick(tile, "Xuân", Crops) -- không tưới 3 ngày
	end
	grow(tile, true)
	eq(FarmLogic.useTool(tile, "Sickle", ctx()).harvest.stars, 1)
end)

test("cây chưa chín thì không thu hoạch", function()
	local tile = plantedTile()
	eq(FarmLogic.useTool(tile, "Sickle", ctx()).ok, false)
	assert(tile.crop ~= nil)
end)

test("thu hoạch làm giảm màu mỡ", function()
	local tile = plantedTile()
	grow(tile, true)
	FarmLogic.useTool(tile, "Sickle", ctx())
	eq(tile.f, Cfg.Fertility.Start - Cfg.Fertility.HarvestCost)
end)

test("cây thu nhiều lần ra quả lại sau Regrow ngày", function()
	local tile = plantedTile("DauTay")
	grow(tile, true)
	FarmLogic.useTool(tile, "Sickle", ctx())
	assert(tile.crop ~= nil, "dâu tây phải còn trên ruộng")
	eq(FarmLogic.isRipe(tile, Crops), false)
	for _ = 1, Crops.List.DauTay.Regrow do
		tile.w = true
		FarmLogic.dawnTick(tile, "Xuân", Crops)
	end
	eq(FarmLogic.isRipe(tile, Crops), true)
end)

test("giá bán nhân theo sao", function()
	eq(FarmLogic.sellPrice("CaRot", 1, Crops, Cfg), 50)
	eq(FarmLogic.sellPrice("CaRot", 2, Crops, Cfg), 63)
	eq(FarmLogic.sellPrice("CaRot", 3, Crops, Cfg), 75)
end)

-- ===== Cỏ & sâu =====
test("cỏ & sâu chỉ xuất hiện trên đất cuốc, sâu không ăn cây chín", function()
	local always = function()
		return 0
	end
	local grass = FarmLogic.newTile("grass", Cfg)
	eq(FarmLogic.hourTick(grass, Cfg, Crops, always), false)
	local tile = plantedTile()
	eq(FarmLogic.hourTick(tile, Cfg, Crops, always), true)
	eq(tile.weed, true)
	eq(tile.pest, true)
	local ripe = plantedTile()
	ripe.crop.g = Crops.List.CaRot.Days
	FarmLogic.hourTick(ripe, Cfg, Crops, always)
	eq(ripe.pest, false)
end)

test("sinh khu đất cố định theo seed và đúng số ô", function()
	local zone = Cfg.Zones[2]
	local a = FarmLogic.generateZone(zone, Cfg, 12345)
	local b = FarmLogic.generateZone(zone, Cfg, 12345)
	eq(#a, zone.Cols * zone.Rows)
	local debris = 0
	for i = 1, #a do
		eq(a[i].s, b[i].s, "ô " .. i)
		if a[i].s == "debris" then
			debris += 1
		end
	end
	assert(debris > 0 and debris < #a, "số vật cản bất thường: " .. debris)
end)

-- ===== Thời gian =====
test("lịch: bình minh 6:00, sang ngày & mùa đúng", function()
	local T = Cfg.Time
	local t0 = GameTime.at(T.Epoch, T)
	eq(t0.day, 0)
	eq(t0.clock, "06:00")
	eq(t0.season, "Xuân")
	eq(t0.dayOfSeason, 1)
	local noon = GameTime.at(T.Epoch + T.DayLength / 4, T)
	eq(noon.clock, "12:00")
	local midnight = GameTime.at(T.Epoch + T.DayLength * 0.75, T)
	eq(midnight.clock, "00:00")
	local summer = GameTime.at(T.Epoch + T.DayLength * T.DaysPerSeason, T)
	eq(summer.season, "Hạ")
	eq(summer.dayOfSeason, 1)
	local nextYear = GameTime.at(T.Epoch + T.DayLength * T.DaysPerSeason * 4, T)
	eq(nextYear.season, "Xuân")
	eq(nextYear.year, 2)
end)

-- ===== Format =====
test("định dạng số và khoá nông sản", function()
	eq(Format.number(1234567), "1.234.567")
	eq(Format.number(999), "999")
	local id, stars = Format.parseProduceKey(Format.produceKey("CaRot", 3))
	eq(id, "CaRot")
	eq(stars, 3)
	eq((Format.parseProduceKey("bad key")), nil)
end)

print(string.format("\n%d test đạt, %d test lỗi", passed, failed))
if failed > 0 then
	error("Có test lỗi")
end
