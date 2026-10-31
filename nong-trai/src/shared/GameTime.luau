--[[
	GameTime: đổi thời gian thật (giây) sang lịch trong game.
	Thuần, không đụng tới Roblox. Server & client cùng gọi với
	workspace:GetServerTimeNow() nên mọi người thấy cùng một giờ.
]]

local GameTime = {}

export type Info = {
	day: number, -- số ngày tuyệt đối kể từ mốc (tăng mãi)
	hourIndex: number, -- số giờ tuyệt đối (dùng để biết khi nào sang giờ mới)
	hour: number, -- 0..24 (số thực)
	season: string,
	seasonIndex: number,
	dayOfSeason: number,
	year: number,
	clock: string, -- "06:30"
}

function GameTime.at(seconds: number, timeCfg): Info
	local total = math.max(0, seconds - timeCfg.Epoch)
	local day = total // timeCfg.DayLength
	local frac = (total % timeCfg.DayLength) / timeCfg.DayLength
	local hour = (timeCfg.DawnHour + frac * 24) % 24
	local seasonCount = #timeCfg.Seasons
	local seasonIndex = (day // timeCfg.DaysPerSeason) % seasonCount + 1
	local minutes = math.floor(hour * 60)

	return {
		day = day,
		hourIndex = total // (timeCfg.DayLength / 24),
		hour = hour,
		season = timeCfg.Seasons[seasonIndex],
		seasonIndex = seasonIndex,
		dayOfSeason = day % timeCfg.DaysPerSeason + 1,
		year = day // (timeCfg.DaysPerSeason * seasonCount) + 1,
		clock = string.format("%02d:%02d", minutes // 60, minutes % 60),
	}
end

return GameTime
