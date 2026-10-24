class_name InventoryScreen
extends MetaScreen
## Màn hình Kho đồ: tab theo loại bên trái, lưới ô vật phẩm ở giữa, chi tiết bên phải
## (độ hiếm bằng chữ + màu + khung, mô tả, nguồn nhận) với các nút:
## Trang bị / Bỏ trang bị (skin), Dùng ở ván sau / Bỏ chọn (tiêu hao), Phân rã (+Bụi).

const TAB_NAMES := ["Tất cả", "Skin tháp", "Tiêu hao", "Nguyên liệu"]
const GRID_COLUMNS := 5

## -1 = tất cả, còn lại = ItemDef.Kind.
var kind_filter := -1
var selected_item: ItemDef = null
## id -> ItemSlot đang hiển thị (test bấm thử).
var slots: Dictionary = {}
var equip_button: Button
var prepare_button: Button
var salvage_button: Button

var _dust_label: Label
var _grid: GridContainer
var _empty_label: Label
var _prepared_label: Label
var _detail_box: VBoxContainer
var _detail_preview: Control
var _detail_name: Label
var _detail_meta: Label
var _detail_description: Label
var _detail_source: Label


func _build_content() -> void:
	title_label.text = "KHO ĐỒ"
	_dust_label = make_label("", 16, Color("#C7B8FF"))
	header_extra.add_child(_dust_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	content.add_child(body)

	var tabs := VBoxContainer.new()
	tabs.custom_minimum_size.x = 150
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for i in TAB_NAMES.size():
		var tab := make_button(TAB_NAMES[i])
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = i == 0
		tab.pressed.connect(func() -> void:
			kind_filter = i - 1
			refresh())
		tabs.add_child(tab)
	body.add_child(tabs)

	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(middle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	middle.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = GRID_COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	_empty_label = make_label("Kho trống. Chơi một ván để nhận đồ rơi!", 15, COLOR_MUTED)
	middle.add_child(_empty_label)
	_prepared_label = make_label("", 14, Color("#9BE564"))
	_prepared_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(_prepared_label)

	var detail := PanelContainer.new()
	detail.custom_minimum_size.x = 300
	detail.add_theme_stylebox_override("panel", card_style(Color(1, 1, 1, 0.15)))
	body.add_child(detail)
	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 8)
	detail.add_child(_detail_box)
	_detail_preview = CenterContainer.new()
	_detail_preview.custom_minimum_size = Vector2(0, 110)
	_detail_box.add_child(_detail_preview)
	_detail_name = make_label("", 20)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_meta = make_label("", 13)
	_detail_description = make_label("", 14, COLOR_MUTED)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_source = make_label("", 12, COLOR_MUTED)
	_detail_source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [_detail_name, _detail_meta, _detail_description, _detail_source]:
		_detail_box.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_box.add_child(spacer)
	equip_button = make_button("", &"PrimaryButton")
	equip_button.pressed.connect(_on_equip_pressed)
	prepare_button = make_button("", &"PrimaryButton")
	prepare_button.pressed.connect(_on_prepare_pressed)
	salvage_button = make_button("")
	salvage_button.pressed.connect(_on_salvage_pressed)
	for button in [equip_button, prepare_button, salvage_button]:
		_detail_box.add_child(button)


func refresh() -> void:
	_dust_label.text = "Bụi: %d    Xu: %d" % [EconomyManager.get_amount(EconomyManager.DUST),
			EconomyManager.get_amount(EconomyManager.COINS)]
	clear_children(_grid)
	slots.clear()
	var items := InventoryManager.get_owned(kind_filter)
	if selected_item and not InventoryManager.owns(selected_item.id):
		selected_item = null
	if selected_item == null and not items.is_empty():
		selected_item = items[0]
	for def in items:
		var slot := ItemSlot.create(def, InventoryManager.count(def.id))
		slot.is_new = InventoryManager.is_new(def.id)
		slot.active = InventoryManager.is_equipped(def.id) or InventoryManager.is_prepared(def.id)
		slot.selected = def == selected_item
		slot.pressed.connect(select.bind(def))
		_grid.add_child(slot)
		slots[def.id] = slot
	_empty_label.visible = items.is_empty()
	var prepared := InventoryManager.get_prepared().map(func(def: ItemDef) -> String: return def.display_name)
	_prepared_label.text = "Ván sau sẽ dùng: %s (tối đa %d)" % [", ".join(prepared), InventoryManager.MAX_PREPARED] \
			if not prepared.is_empty() else ""
	_refresh_detail()


## Chọn một vật phẩm để xem chi tiết (bỏ nhãn NEW).
func select(def: ItemDef) -> void:
	selected_item = def
	InventoryManager.mark_seen(def.id)
	refresh()


func _refresh_detail() -> void:
	_detail_box.visible = selected_item != null
	if selected_item == null:
		return
	var def := selected_item
	clear_children(_detail_preview)
	var preview := ItemSlot.create(def, InventoryManager.count(def.id))
	preview.custom_minimum_size = Vector2(100, 100)
	preview.disabled = true
	_detail_preview.add_child(preview)
	_detail_name.text = def.display_name
	_detail_name.add_theme_color_override("font_color", Rarity.color(def.rarity).lightened(0.2))
	_detail_meta.text = "%s  ·  %s" % [Rarity.display_name(def.rarity), ItemDef.KIND_NAMES[def.kind]]
	_detail_meta.add_theme_color_override("font_color", Rarity.color(def.rarity))
	var text := def.description
	if not def.effect_text().is_empty():
		text += "\nHiệu ứng: " + def.effect_text()
	if def.kind == ItemDef.Kind.SKIN:
		var data := ItemSlot.get_tower_data(def.tower_id)
		text += "\nÁp dụng cho: tháp %s (chỉ đổi ngoại hình)" % (data.display_name if data else String(def.tower_id))
	_detail_description.text = text
	_detail_source.text = "Nguồn: %s" % def.source_hint

	equip_button.visible = def.kind == ItemDef.Kind.SKIN
	equip_button.text = "Bỏ trang bị" if InventoryManager.is_equipped(def.id) else "Trang bị"
	prepare_button.visible = def.kind == ItemDef.Kind.CONSUMABLE
	var prepared := InventoryManager.is_prepared(def.id)
	prepare_button.text = "Bỏ chọn" if prepared else "Dùng ở ván sau"
	prepare_button.disabled = not prepared and InventoryManager.get_prepared().size() >= InventoryManager.MAX_PREPARED
	salvage_button.text = "Phân rã: +%d Bụi" % Rarity.DUST_VALUES[def.rarity]


func _on_equip_pressed() -> void:
	if selected_item == null:
		return
	if InventoryManager.is_equipped(selected_item.id):
		InventoryManager.unequip_skin(selected_item.tower_id)
	else:
		InventoryManager.equip_skin(selected_item.id)
	refresh()


func _on_prepare_pressed() -> void:
	if selected_item:
		InventoryManager.toggle_prepared(selected_item.id)
		refresh()


func _on_salvage_pressed() -> void:
	if selected_item and InventoryManager.salvage(selected_item.id) > 0:
		AudioManager.play(&"sell")
		refresh()
