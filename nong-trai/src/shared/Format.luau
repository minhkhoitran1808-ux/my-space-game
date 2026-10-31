local Format = {}

-- 1234567 -> "1.234.567"
function Format.number(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if formatted:sub(1, 1) == "." then
		formatted = formatted:sub(2)
	end
	return formatted
end

-- Khoá nông sản trong túi: "CaRot:3" = cà rốt 3 sao
function Format.produceKey(cropId: string, stars: number): string
	return cropId .. ":" .. tostring(stars)
end

function Format.parseProduceKey(key: string): (string?, number?)
	local cropId, stars = string.match(key, "^(%w+):(%d)$")
	if not cropId then
		return nil, nil
	end
	return cropId, tonumber(stars)
end

function Format.stars(n: number): string
	return string.rep("★", n) .. string.rep("☆", 3 - n)
end

return Format
