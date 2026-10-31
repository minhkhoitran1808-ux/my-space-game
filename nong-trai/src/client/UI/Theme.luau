--[[
	Theme: màu & chữ theo bản thiết kế đã duyệt.
]]

local Theme = {}

Theme.Colors = {
	Leaf = Color3.fromRGB(46, 125, 50),
	LeafDark = Color3.fromRGB(27, 94, 32),
	Water = Color3.fromRGB(31, 111, 181),
	WaterDark = Color3.fromRGB(20, 78, 130),
	WaterLight = Color3.fromRGB(207, 227, 245),
	Sun = Color3.fromRGB(255, 201, 60),
	SunDark = Color3.fromRGB(201, 148, 0),
	Danger = Color3.fromRGB(192, 57, 43),
	DangerDark = Color3.fromRGB(142, 42, 32),
	Soil = Color3.fromRGB(109, 76, 51),
	SoilDark = Color3.fromRGB(74, 51, 34),
	Bag = Color3.fromRGB(160, 115, 77),
	Cream = Color3.fromRGB(255, 246, 229),
	CreamBorder = Color3.fromRGB(232, 200, 143),
	Ink = Color3.fromRGB(59, 42, 30),
	InkSoft = Color3.fromRGB(90, 68, 51),
	White = Color3.new(1, 1, 1),
	Muted = Color3.fromRGB(237, 227, 209),
	Grey = Color3.fromRGB(158, 158, 158),
	GreyDark = Color3.fromRGB(110, 110, 110),
	Shade = Color3.fromRGB(59, 42, 30),
	Track = Color3.fromRGB(232, 220, 198),
}

Theme.Seasons = {
	["Xuân"] = { Fill = Color3.fromRGB(248, 187, 208), Border = Color3.fromRGB(217, 131, 159) },
	["Hạ"] = { Fill = Color3.fromRGB(255, 213, 79), Border = Color3.fromRGB(201, 162, 30) },
	["Thu"] = { Fill = Color3.fromRGB(255, 178, 122), Border = Color3.fromRGB(217, 128, 63) },
	["Đông"] = { Fill = Color3.fromRGB(179, 229, 252), Border = Color3.fromRGB(111, 184, 218) },
}

local family = Font.fromEnum(Enum.Font.Nunito).Family

Theme.Font = {
	Bold = Font.new(family, Enum.FontWeight.Bold),
	ExtraBold = Font.new(family, Enum.FontWeight.ExtraBold),
	Heavy = Font.new(family, Enum.FontWeight.Heavy),
}

-- Biểu tượng tạm cho công cụ (bản sau có thể thay bằng ảnh tải lên Roblox)
Theme.ToolIcons = {
	Hoe = "⛏️",
	WateringCan = "💧",
	SeedBag = "🌱",
	Sickle = "🌾",
	Fertilizer = "🧪",
	Sprayer = "💨",
}

return Theme
