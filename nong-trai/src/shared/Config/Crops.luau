--[[
	Danh sách cây trồng. Dữ liệu thuần (không dùng kiểu Roblox) để chạy được test.

	Season   : mùa trồng được ("Xuân" | "Hạ" | "Thu" | "Đông")
	Days     : số ngày được tưới cần để chín
	SeedPrice: giá 1 hạt   | SellPrice: giá bán 1 nông sản 1 sao
	Regrow   : (tuỳ chọn) cây thu nhiều lần, ra quả lại sau bấy nhiêu ngày
	Color    : {r, g, b} màu nông sản
	Shape    : hình khi chín: "ball" | "root" | "tall" | "leafy" | "bush"
	Size     : (tuỳ chọn) độ to của nông sản khi Shape = "ball"
]]

local Crops = {}

Crops.Order = {
	"RauMuong", "CaRot", "DauTay",
	"Ngo", "DuaHau", "ThanhLong",
	"KhoaiLang", "LuaNuoc", "BiNgo",
	"CuCaiTrang", "SuHao", "CaiBap",
}

Crops.List = {
	-- Xuân
	RauMuong = { Name = "Rau muống", Season = "Xuân", Days = 2, SeedPrice = 10, SellPrice = 25, Color = { 76, 175, 80 }, Shape = "leafy" },
	CaRot = { Name = "Cà rốt", Season = "Xuân", Days = 3, SeedPrice = 20, SellPrice = 50, Color = { 255, 140, 40 }, Shape = "root" },
	DauTay = { Name = "Dâu tây", Season = "Xuân", Days = 4, SeedPrice = 60, SellPrice = 45, Regrow = 2, Color = { 229, 57, 80 }, Shape = "bush" },
	-- Hạ
	Ngo = { Name = "Ngô", Season = "Hạ", Days = 4, SeedPrice = 30, SellPrice = 80, Color = { 244, 196, 48 }, Shape = "tall" },
	DuaHau = { Name = "Dưa hấu", Season = "Hạ", Days = 6, SeedPrice = 80, SellPrice = 240, Color = { 62, 158, 74 }, Shape = "ball", Size = 2.8 },
	ThanhLong = { Name = "Thanh long", Season = "Hạ", Days = 5, SeedPrice = 120, SellPrice = 90, Regrow = 3, Color = { 224, 64, 138 }, Shape = "bush" },
	-- Thu
	KhoaiLang = { Name = "Khoai lang", Season = "Thu", Days = 4, SeedPrice = 35, SellPrice = 95, Color = { 156, 79, 122 }, Shape = "root" },
	LuaNuoc = { Name = "Lúa nước", Season = "Thu", Days = 5, SeedPrice = 40, SellPrice = 120, Color = { 217, 194, 90 }, Shape = "tall" },
	BiNgo = { Name = "Bí ngô", Season = "Thu", Days = 6, SeedPrice = 90, SellPrice = 270, Color = { 255, 122, 0 }, Shape = "ball", Size = 2.6 },
	-- Đông
	CuCaiTrang = { Name = "Củ cải trắng", Season = "Đông", Days = 2, SeedPrice = 15, SellPrice = 38, Color = { 242, 242, 242 }, Shape = "root" },
	SuHao = { Name = "Su hào", Season = "Đông", Days = 3, SeedPrice = 25, SellPrice = 65, Color = { 139, 199, 122 }, Shape = "ball", Size = 1.7 },
	CaiBap = { Name = "Cải bắp", Season = "Đông", Days = 4, SeedPrice = 45, SellPrice = 120, Color = { 111, 191, 94 }, Shape = "ball", Size = 2.3 },
}

return Crops
