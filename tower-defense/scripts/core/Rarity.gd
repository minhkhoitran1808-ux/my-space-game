class_name Rarity
extends RefCounted
## Năm bậc độ hiếm của vật phẩm: màu chuẩn ngành (xám -> xanh lá -> xanh dương -> tím -> cam),
## trọng số rơi, lượng Bụi khi phân rã / nhận trùng, và HÌNH KHUNG riêng cho từng bậc
## (người mù màu vẫn phân biệt được). UI luôn hiện kèm tên bậc bằng chữ.

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const NAMES := ["Thường", "Ít gặp", "Hiếm", "Sử thi", "Huyền thoại"]
const COLORS := [Color("#9E9E9E"), Color("#4CAF50"), Color("#2196F3"), Color("#A335EE"), Color("#FF8000")]
const BACKGROUNDS := [Color("#2B2B2B"), Color("#1E3320"), Color("#14283F"), Color("#2A1640"), Color("#3D2208")]
## Trọng số rơi (%), cộng lại = 100.
const DROP_WEIGHTS := [60.0, 25.0, 11.0, 3.5, 0.5]
## Bụi nhận được khi phân rã / nhận đồ trùng.
const DUST_VALUES := [5, 15, 50, 150, 500]


static func color(tier: int) -> Color:
	return COLORS[clampi(tier, 0, COLORS.size() - 1)]


static func display_name(tier: int) -> String:
	return NAMES[clampi(tier, 0, NAMES.size() - 1)]


## Chọn một bậc theo trọng số. luck > 0 dời trọng số lên các bậc cao (vd thắng, wave sâu).
static func roll(rng: RandomNumberGenerator, luck: float = 0.0) -> int:
	var weights: Array[float] = []
	var total := 0.0
	for tier in DROP_WEIGHTS.size():
		var weight: float = DROP_WEIGHTS[tier] * (1.0 + luck * tier)
		weights.append(weight)
		total += weight
	var pick := rng.randf() * total
	for tier in weights.size():
		pick -= weights[tier]
		if pick <= 0.0:
			return tier
	return Tier.COMMON


## Vẽ nền + khung theo bậc trong rect:
## Thường = vuông trơn, Ít gặp = vuông + 1 vạch, Hiếm = góc vát, Sử thi = lục giác,
## Huyền thoại = lục giác + hào quang (glow = 0..1, UI có thể cho nhấp nháy nhẹ).
static func draw_frame(canvas: CanvasItem, rect: Rect2, tier: int, glow: float = 1.0) -> void:
	var color := Rarity.color(tier)
	var background: Color = BACKGROUNDS[clampi(tier, 0, BACKGROUNDS.size() - 1)]
	var points := _frame_points(rect, tier)
	if tier >= Tier.LEGENDARY:
		var center := rect.get_center()
		var halo := PackedVector2Array()
		for point in points:
			halo.append(center + (point - center) * 1.08)
		canvas.draw_colored_polygon(halo, Color(color, 0.35 * glow))
	canvas.draw_colored_polygon(points, background)
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline, color, 2.0, true)
	if tier == Tier.UNCOMMON:
		canvas.draw_line(rect.position + Vector2(6, rect.size.y - 7), rect.end - Vector2(6, 7), Color(color, 0.8), 2.0)


static func _frame_points(rect: Rect2, tier: int) -> PackedVector2Array:
	var p := rect.position
	var s := rect.size
	if tier >= Tier.EPIC:
		var cut := s.x * 0.22
		return PackedVector2Array([p + Vector2(cut, 0), p + Vector2(s.x - cut, 0), p + Vector2(s.x, s.y * 0.5),
				p + Vector2(s.x - cut, s.y), p + Vector2(cut, s.y), p + Vector2(0, s.y * 0.5)])
	if tier == Tier.RARE:
		var bevel := s.x * 0.16
		return PackedVector2Array([p + Vector2(bevel, 0), p + Vector2(s.x - bevel, 0), p + Vector2(s.x, bevel),
				p + Vector2(s.x, s.y - bevel), p + Vector2(s.x - bevel, s.y), p + Vector2(bevel, s.y),
				p + Vector2(0, s.y - bevel), p + Vector2(0, bevel)])
	return PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y)])
