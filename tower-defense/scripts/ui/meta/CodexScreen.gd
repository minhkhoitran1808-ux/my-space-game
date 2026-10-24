class_name CodexScreen
extends MetaScreen
## Codex: album các loại địch đã gặp (chỉ số + mẹo) và mọi vật phẩm trong game.
## Thứ chưa gặp / chưa có hiện bóng tối kèm nguồn nhận, để người chơi có mục tiêu rõ ràng.

const ENEMIES_FOLDER := "res://resources/enemies"

enum Tab { ENEMIES, ITEMS }

var tab: Tab = Tab.ENEMIES
var _summary: Label
var _list: VBoxContainer
var _grid: GridContainer
var _item_detail: Label
## Các loại địch (nạp một lần), sắp xếp theo máu.
var _enemies: Array[EnemyData] = []
## Số thẻ / ô đang hiển thị (test kiểm tra).
var shown_count := 0


func _build_content() -> void:
	title_label.text = "CODEX"
	for file_name in ResourceLoader.list_directory(ENEMIES_FOLDER):
		if file_name.ends_with(".tres"):
			var data := load(ENEMIES_FOLDER.path_join(file_name)) as EnemyData
			if data:
				_enemies.append(data)
	_enemies.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.max_health < b.max_health)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for i in 2:
		var button := make_button(["Địch", "Vật phẩm"][i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == 0
		button.custom_minimum_size.x = 140
		button.pressed.connect(func() -> void:
			tab = i as Tab
			refresh())
		tabs.add_child(button)
	_summary = make_label("", 15, COLOR_GOLD)
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tabs.add_child(_summary)
	content.add_child(tabs)
	_list = make_scroll_list(content)


func refresh() -> void:
	clear_children(_list)
	shown_count = 0
	if tab == Tab.ENEMIES:
		var seen := 0
		for data in _enemies:
			if StatsManager.has_seen_enemy(data.id):
				seen += 1
			_list.add_child(_make_enemy_card(data))
			shown_count += 1
		_summary.text = "Đã gặp %d / %d loại địch" % [seen, _enemies.size()]
	else:
		var owned := 0
		_grid = GridContainer.new()
		_grid.columns = 9
		_grid.add_theme_constant_override("h_separation", 10)
		_grid.add_theme_constant_override("v_separation", 10)
		_list.add_child(_grid)
		_item_detail = make_label("Chọn một ô để xem nguồn nhận.", 14, COLOR_MUTED)
		_item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(_item_detail)
		for def in InventoryManager.get_all():
			var has := InventoryManager.owns(def.id)
			owned += 1 if has else 0
			var slot := ItemSlot.create(def, 0, has)
			slot.pressed.connect(func() -> void:
				_item_detail.text = "%s (%s · %s)%s\nNguồn: %s" % [def.display_name if has else "???",
						Rarity.display_name(def.rarity), ItemDef.KIND_NAMES[def.kind],
						"" if has else " · chưa có", def.source_hint])
			_grid.add_child(slot)
			shown_count += 1
		_summary.text = "Sưu tập %d / %d vật phẩm" % [owned, InventoryManager.defs.size()]


func _make_enemy_card(data: EnemyData) -> Control:
	var seen := StatsManager.has_seen_enemy(data.id)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(data.color if seen else Color(1, 1, 1, 0.15)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.draw.connect(_draw_enemy.bind(icon, data, seen))
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	if not seen:
		info.add_child(make_label("???", 18))
		info.add_child(make_label("Chưa gặp. Tiếp tục chơi các màn khó hơn để khám phá.", 13, COLOR_MUTED))
		return card
	var title := data.display_name + ("  ·  BOSS" if data.elite else "") + ("  ·  BAY" if data.is_flying else "")
	info.add_child(make_label(title, 18, data.color.lightened(0.3)))
	var stats := "Máu %d  ·  Tốc độ %d  ·  Thưởng %d vàng  ·  Trừ %d máu nhà" % [roundi(data.max_health),
			roundi(data.speed), data.reward, data.damage_to_base]
	var resist := PackedStringArray()
	if data.armor > 0.0:
		resist.append("giáp %d%%" % roundi(data.armor * 100))
	if data.magic_resist > 0.0:
		resist.append("kháng phép %d%%" % roundi(data.magic_resist * 100))
	if data.slow_resistance > 0.0:
		resist.append("kháng chậm %d%%" % roundi(data.slow_resistance * 100))
	if not resist.is_empty():
		stats += "  ·  " + ", ".join(resist)
	info.add_child(make_label(stats, 13, COLOR_MUTED))
	if not data.hint.is_empty():
		info.add_child(make_label("Mẹo: " + data.hint, 13, COLOR_GOLD))
	return card


## Vẽ hình địch theo EnemyData.shape (bóng tối nếu chưa gặp).
func _draw_enemy(canvas: Control, data: EnemyData, seen: bool) -> void:
	var c := canvas.size * 0.5
	var r := clampf(data.radius * 1.3, 12.0, 28.0)
	var color := data.color if seen else Color(0.12, 0.12, 0.15)
	var outline := data.color.darkened(0.5) if seen else Color(0.3, 0.3, 0.35)
	match data.shape:
		EnemyData.Shape.SQUARE:
			canvas.draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), color)
			canvas.draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), outline, false, 2.0)
		EnemyData.Shape.TRIANGLE:
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)]), color)
		EnemyData.Shape.DIAMOND:
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)
		EnemyData.Shape.BLOB:
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, r * 0.3), c + Vector2(0, r * 1.5), c + Vector2(r * 0.7, r * 0.3)]), Color(color, 0.75))
			canvas.draw_circle(c, r, Color(color, 0.75))
		EnemyData.Shape.BAT:
			for side in [-1.0, 1.0]:
				canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(side * r * 0.3, -r * 0.2),
						c + Vector2(side * r * 1.4, -r * 0.6), c + Vector2(side * r, r * 0.4)]), color.darkened(0.25))
			canvas.draw_circle(c, r * 0.55, color)
		_:
			canvas.draw_circle(c, r, color)
			canvas.draw_arc(c, r, 0.0, TAU, 32, outline, 2.0)
			if data.shape == EnemyData.Shape.CROSS and seen:
				canvas.draw_rect(Rect2(c - Vector2(r * 0.55, r * 0.15), Vector2(r * 1.1, r * 0.3)), Color.WHITE)
				canvas.draw_rect(Rect2(c - Vector2(r * 0.15, r * 0.55), Vector2(r * 0.3, r * 1.1)), Color.WHITE)
