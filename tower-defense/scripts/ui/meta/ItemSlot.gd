class_name ItemSlot
extends Button
## Một ô vật phẩm: nền + khung theo độ hiếm (Rarity.draw_frame), hình minh hoạ vẽ bằng code
## (skin = tháp thu nhỏ đúng màu skin, tiêu hao = đồng xu / trái tim, nguyên liệu = tinh thể),
## số lượng góc dưới phải, nhãn NEW góc trên trái, chấm xanh khi đang trang bị / đã chuẩn bị.
## Đồ chưa sở hữu (dùng cho Codex / cửa hàng) vẽ bóng tối.

const SLOT_SIZE := 84.0
const TOWERS_FOLDER := "res://resources/towers"

## TowerData cấp 1 theo id (để vẽ skin), nạp một lần.
static var _tower_cache: Dictionary = {}

var item: ItemDef
var amount := 0
var is_new := false
var active := false
var selected := false:
	set(value):
		selected = value
		queue_redraw()
## false = vẽ bóng tối (chưa sở hữu).
var owned := true


static func create(p_item: ItemDef, p_amount: int, p_owned: bool = true) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.item = p_item
	slot.amount = p_amount
	slot.owned = p_owned
	slot.flat = true
	slot.focus_mode = Control.FOCUS_ALL
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.tooltip_text = "%s\n%s · %s" % [p_item.display_name, Rarity.display_name(p_item.rarity),
			ItemDef.KIND_NAMES[p_item.kind]]
	return slot


static func get_tower_data(tower_id: StringName) -> TowerData:
	if _tower_cache.is_empty():
		for file_name in ResourceLoader.list_directory(TOWERS_FOLDER):
			if file_name.ends_with(".tres"):
				var data := load(TOWERS_FOLDER.path_join(file_name)) as TowerData
				if data and data.level == 1:
					_tower_cache[data.id] = data
	return _tower_cache.get(tower_id)


func _draw() -> void:
	var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	Rarity.draw_frame(self, rect, item.rarity)
	var center := rect.get_center()
	var shade := 1.0 if owned else 0.0
	# Tháp thu nhỏ (đế 48px) cần to hơn các icon khác để thấy rõ màu skin.
	var icon_scale := 1.0 if item.kind == ItemDef.Kind.SKIN else 0.62
	draw_set_transform(center, 0.0, Vector2.ONE * icon_scale * size.x / SLOT_SIZE)
	_draw_icon(shade)
	draw_set_transform(Vector2.ZERO)
	if not owned:
		draw_colored_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
				Vector2(rect.position.x, rect.end.y)]), Color(0, 0, 0, 0.35))

	var font := get_theme_default_font()
	if amount > 1:
		var text := "x%d" % amount
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string_outline(font, Vector2(rect.end.x - width - 6, rect.end.y - 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
		draw_string(font, Vector2(rect.end.x - width - 6, rect.end.y - 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	if is_new:
		draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(34, 16)), Color("#E63946"))
		draw_string(font, rect.position + Vector2(7, 17), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	if active:
		var dot := Vector2(rect.end.x - 10, rect.position.y + 10)
		draw_circle(dot, 7.0, Color("#38B000"))
		draw_polyline(PackedVector2Array([dot + Vector2(-3.5, 0), dot + Vector2(-1, 3), dot + Vector2(4, -3)]), Color.WHITE, 2.0)
	if selected or has_focus():
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color(1, 1, 1, 0.9), false, 2.0)


## Hình minh hoạ, vẽ quanh gốc toạ độ (đã được dời về tâm ô và thu nhỏ).
func _draw_icon(shade: float) -> void:
	var tint := Color(0, 0, 0, 1.0 - shade) if shade < 1.0 else Color(0, 0, 0, 0)
	match item.kind:
		ItemDef.Kind.SKIN:
			var data := get_tower_data(item.tower_id)
			if data:
				Tower.draw_body(self, data, -PI * 0.5, Color(0.05, 0.05, 0.08, 0.9) if shade < 1.0 else tint, 1.0, item)
		ItemDef.Kind.CONSUMABLE:
			if item.effect == &"bonus_lives":
				_draw_heart(Color("#E63946") if shade > 0.0 else Color(0.1, 0.1, 0.12))
			else:
				var radius := 20.0 if item.effect_value < 20.0 else 26.0
				draw_circle(Vector2.ZERO, radius, Color("#FFC72C") if shade > 0.0 else Color(0.1, 0.1, 0.12))
				draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 24, Color("#B8860B") if shade > 0.0 else Color(0.2, 0.2, 0.22), 4.0)
		_:
			var color := Rarity.color(item.rarity).lightened(0.25) if shade > 0.0 else Color(0.1, 0.1, 0.12)
			var crystal := PackedVector2Array([Vector2(0, -30), Vector2(18, -6), Vector2(10, 28), Vector2(-10, 28), Vector2(-18, -6)])
			draw_colored_polygon(crystal, color)
			draw_line(Vector2(0, -30), Vector2(0, 28), Color(1, 1, 1, 0.35 * shade), 2.0)


func _draw_heart(color: Color) -> void:
	var points := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(Vector2(x, y) * 1.6)
	draw_colored_polygon(points, color)
