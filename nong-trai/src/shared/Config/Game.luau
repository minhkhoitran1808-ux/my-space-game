--[[
	Thông số chung của game. Dữ liệu thuần (không dùng kiểu Roblox) để chạy được test.
	Muốn cân bằng lại game: sửa các con số ở đây.
]]

local Game = {}

Game.DataStoreName = "NongTraiVuiVe_v1" -- đổi tên = xoá sạch tiến trình mọi người

-- ===== Người chơi mới =====
Game.StartingCoins = 100
Game.StartingSeedCount = 6 -- tặng 6 hạt cây rẻ nhất của mùa hiện tại
Game.StartingFertilizer = 3

-- ===== Thời gian =====
Game.Time = {
	DayLength = 720, -- 1 ngày trong game = 720 giây thật (12 phút)
	DaysPerSeason = 7,
	Seasons = { "Xuân", "Hạ", "Thu", "Đông" },
	DawnHour = 6, -- ngày mới bắt đầu lúc 6:00 sáng
	Epoch = 1735689600, -- mốc tính lịch (mọi server dùng chung một lịch)
}

-- ===== Công cụ =====
Game.ToolOrder = { "Hoe", "WateringCan", "SeedBag", "Sickle", "Fertilizer", "Sprayer" }
Game.Tools = {
	Hoe = { Name = "Cuốc" },
	WateringCan = { Name = "Bình tưới" },
	SeedBag = { Name = "Túi hạt" },
	Sickle = { Name = "Liềm" },
	Fertilizer = { Name = "Phân bón" },
	Sprayer = { Name = "Bình xịt" },
}
Game.ToolRange = 16 -- khoảng cách tối đa (stud) từ nhân vật tới ô đất
Game.ToolCooldown = 0.2 -- giây giữa 2 lần dùng công cụ

-- ===== Đất & cây =====
Game.WaterCapacity = 15 -- số lần tưới mỗi bình
Game.DebrisHp = 3 -- số nhát cuốc để dọn đá/gốc cây
Game.Fertility = {
	Start = 50,
	HarvestCost = 15, -- mỗi lần thu hoạch đất mất bấy nhiêu màu mỡ
	FertilizerGain = 40,
	Good = 60, -- từ mức này trở lên được tính là "đất tốt"
}
Game.WeedChancePerHour = 0.01 -- xác suất cỏ mọc mỗi giờ trong game (mỗi ô)
Game.PestChancePerHour = 0.006 -- xác suất sâu xuất hiện mỗi giờ trong game (mỗi cây)
Game.QualityMultiplier = { 1, 1.25, 1.5 } -- giá bán theo số sao

-- ===== Cửa hàng =====
Game.FertilizerPrice = 25

-- ===== Đảo =====
Game.MaxIslands = 8
Game.TileSize = 4
-- Các khu đất trên đảo (toạ độ tính từ tâm đảo, đơn vị stud)
Game.Zones = {
	{ Id = 1, Name = "Khu 1", Cols = 6, Rows = 6, X = -36, Z = -24, Price = 0, DebrisChance = 0.15 },
	{ Id = 2, Name = "Khu 2", Cols = 4, Rows = 6, X = -8, Z = -24, Price = 500, DebrisChance = 0.35 },
	{ Id = 3, Name = "Khu 3", Cols = 6, Rows = 4, X = -36, Z = 6, Price = 1500, DebrisChance = 0.35 },
	{ Id = 4, Name = "Khu 4", Cols = 4, Rows = 4, X = -8, Z = 6, Price = 4000, DebrisChance = 0.4 },
}

return Game
