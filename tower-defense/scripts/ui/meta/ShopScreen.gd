class_name ShopScreen
extends MetaScreen
## Màn hình Cửa hàng & Thương nhân, 4 tab:
## - Hôm nay: 4 món giá cố định, đổi mới mỗi ngày (không có nút trả tiền để đổi sớm).
## - Thương nhân: chân dung NPC + các thẻ "[đưa] » [nhận]"; thiếu đồ thì nút xám kèm lý do.
## - Ghép đồ: 5 món cùng bậc -> 1 món bậc kế tiếp.
## - Nâng cấp: nâng cấp vĩnh viễn có giới hạn.

enum Tab { DAILY, MERCHANT, FUSE, UPGRADES }

const TAB_NAMES := ["Hôm nay", "Thương nhân", "Ghép đồ", "Nâng cấp"]

var tab: Tab = Tab.DAILY
## Nút hành động đang hiển thị theo khoá (test bấm thử): "buy_0", "trade_<id>", "fuse_<bậc>", "upgrade_<id>".
var action_buttons: Dictionary = {}
var _wallet_label: Label
var _body: VBoxContainer
var _status_label: Label


func _build_content() -> void:
	title_label.text = "CỬA HÀNG"
	_wallet_label = make_label("", 16, COLOR_GOLD)
	header_extra.add_child(_wallet_label)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for i in TAB_NAMES.size():
		var button := make_button(TAB_NAMES[i])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == tab
		button.custom_minimum_size.x = 140
		button.pressed.connect(func() -> void:
			tab = i as Tab
			_status_label.text = ""
			refresh())
		tabs.add_child(button)
	content.add_child(tabs)
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	content.add_child(_body)
	_status_label = make_label("", 15, Color("#9BE564"))
	content.add_child(_status_label)


func refresh() -> void:
	_wallet_label.text = "%d Xu    %d Bụi" % [EconomyManager.get_amount(EconomyManager.COINS),
			EconomyManager.get_amount(EconomyManager.DUST)]
	clear_children(_body)
	action_buttons.clear()
	match tab:
		Tab.DAILY:
			_build_daily()
		Tab.MERCHANT:
			_build_merchant()
		Tab.FUSE:
			_build_fuse()
		Tab.UPGRADES:
			_build_upgrades()


## Báo kết quả một giao dịch ở dòng trạng thái dưới cùng.
func _report(results: Array, prefix: String) -> void:
	var parts := PackedStringArray()
	for result: Dictionary in results:
		if result.is_empty():
			continue
		var item: ItemDef = result.item
		parts.append("%s (%s)%s" % [item.display_name, Rarity.display_name(item.rarity),
				" trùng » +%d Bụi" % result.dust if result.duplicate else ""])
	_status_label.text = prefix + (", ".join(parts) if not parts.is_empty() else "")
	AudioManager.play(&"sell")
	refresh()


# --- Hôm nay ---------------------------------------------------------------------------

func _build_daily() -> void:
	_body.add_child(make_label("Hàng đổi mới mỗi ngày. Giá cố định theo độ hiếm, không thể trả tiền để đổi hàng sớm.", 14, COLOR_MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(row)
	var offers := ShopManager.get_daily_offers()
	for i in offers.size():
		var def := offers[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(205, 0)
		card.add_theme_stylebox_override("panel", card_style(Rarity.color(def.rarity)))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var slot_holder := CenterContainer.new()
		slot_holder.add_child(ItemSlot.create(def, 1, true))
		box.add_child(slot_holder)
		var name_label := make_label(def.display_name, 16, Rarity.color(def.rarity).lightened(0.2))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(name_label)
		box.add_child(make_label("%s · %s" % [Rarity.display_name(def.rarity), ItemDef.KIND_NAMES[def.kind]], 12, Rarity.color(def.rarity)))
		var note := def.effect_text() if def.kind == ItemDef.Kind.CONSUMABLE else "Skin tháp %s" % _tower_name(def)
		box.add_child(make_label(note, 12, COLOR_MUTED))
		var price := ShopManager.price_of(def)
		var button := make_button("Mua: %d Xu" % price, &"GoldButton")
		if ShopManager.is_bought(i):
			button.text = "Đã mua hôm nay"
			button.disabled = true
		elif not def.is_stackable() and InventoryManager.owns(def.id):
			button.text = "Đã có"
			button.disabled = true
		elif not EconomyManager.can_afford(EconomyManager.COINS, price):
			button.disabled = true
			button.tooltip_text = "Thiếu %d Xu" % (price - EconomyManager.get_amount(EconomyManager.COINS))
		var slot := i
		button.pressed.connect(func() -> void: _report([ShopManager.buy(slot)], "Đã mua: "))
		box.add_child(button)
		action_buttons["buy_%d" % i] = button
		row.add_child(card)


# --- Thương nhân -------------------------------------------------------------------------

func _build_merchant() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	var npc := VBoxContainer.new()
	npc.custom_minimum_size.x = 210
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(200, 200)
	portrait.draw.connect(_draw_merchant.bind(portrait))
	npc.add_child(portrait)
	npc.add_child(make_label("Bà Tư thương nhân", 18, COLOR_GOLD))
	var quote := make_label("\"Đồ thừa à? Đưa đây, bà đổi cho thứ có ích hơn. Giá cả phải chăng, không lừa ai bao giờ!\"", 13, COLOR_MUTED)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.custom_minimum_size.x = 200
	npc.add_child(quote)
	row.add_child(npc)

	var list := make_scroll_list(row)
	list.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for recipe in ShopManager.get_recipes():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", card_style(Color("#C7B8FF")))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		card.add_child(line)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(make_label(recipe.title, 16))
		info.add_child(make_label("%s  »  %s" % [_bundle_text(recipe.give), _bundle_text(recipe.receive)], 14, COLOR_GOLD))
		line.add_child(info)
		var error := ShopManager.get_trade_error(recipe)
		var button := make_button("Đổi", &"PrimaryButton")
		button.custom_minimum_size.x = 150
		button.disabled = not error.is_empty()
		button.tooltip_text = error
		if not error.is_empty():
			info.add_child(make_label(error, 12, Color("#FF8A80")))
		button.pressed.connect(func() -> void: _report(ShopManager.trade(recipe), "Đã đổi, nhận: "))
		line.add_child(button)
		action_buttons["trade_%s" % recipe.id] = button
		list.add_child(card)


func _draw_merchant(canvas: Control) -> void:
	var c := canvas.size * 0.5 + Vector2(0, 14)
	canvas.draw_circle(c + Vector2(0, 70), 70, Color("#6A4C93"))
	canvas.draw_circle(c, 46, Color("#F2C7A5"))
	canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-70, -28), c + Vector2(70, -28), c + Vector2(0, -98)]), Color("#3D2208"))
	canvas.draw_rect(Rect2(c + Vector2(-74, -32), Vector2(148, 10)), Color("#5C3310"))
	for side in [-1.0, 1.0]:
		canvas.draw_circle(c + Vector2(16 * side, -4), 5, Color("#2B193D"))
	canvas.draw_arc(c + Vector2(0, 12), 16, 0.3, PI - 0.3, 16, Color("#8C2F39"), 3.0)
	canvas.draw_circle(c + Vector2(34, 40), 10, Color("#FFC72C"))


func _bundle_text(bundle: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: String in bundle:
		parts.append("%d %s" % [int(bundle[key]), ShopManager.display_name(key)])
	return " + ".join(parts)


# --- Ghép đồ ----------------------------------------------------------------------------

func _build_fuse() -> void:
	_body.add_child(make_label("Ghép %d món tiêu hao / nguyên liệu cùng bậc thành 1 món ngẫu nhiên bậc cao hơn. Skin là độc nhất nên không ghép được." % ShopManager.FUSE_COUNT, 14, COLOR_MUTED))
	for tier in Rarity.Tier.LEGENDARY:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", card_style(Rarity.color(tier)))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		card.add_child(line)
		var text := make_label("%d × %s  »  1 × %s ngẫu nhiên" % [ShopManager.FUSE_COUNT, Rarity.display_name(tier), Rarity.display_name(tier + 1)], 16)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		line.add_child(make_label("Đang có: %d" % ShopManager.get_fusable_count(tier), 14, COLOR_MUTED))
		var button := make_button("Ghép", &"PrimaryButton")
		button.custom_minimum_size.x = 130
		button.disabled = not ShopManager.can_fuse(tier)
		var fuse_tier := tier
		button.pressed.connect(func() -> void: _report([ShopManager.fuse(fuse_tier)], "Ghép thành công: "))
		line.add_child(button)
		action_buttons["fuse_%d" % tier] = button
		_body.add_child(card)


# --- Nâng cấp vĩnh viễn -------------------------------------------------------------------

func _build_upgrades() -> void:
	_body.add_child(make_label("Nâng cấp áp dụng cho mọi ván. Có giới hạn để màn chơi vẫn là thử thách.", 14, COLOR_MUTED))
	for id: StringName in ShopManager.UPGRADES:
		var upgrade: Dictionary = ShopManager.UPGRADES[id]
		var level := ShopManager.get_upgrade_level(id)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", card_style(COLOR_GOLD))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		card.add_child(line)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(make_label("%s  ·  cấp %d / %d" % [upgrade.name, level, upgrade.max_level], 17))
		info.add_child(make_label(upgrade.description, 13, COLOR_MUTED))
		info.add_child(make_progress_bar(float(level) / upgrade.max_level, COLOR_GOLD))
		line.add_child(info)
		var cost := ShopManager.get_upgrade_cost(id)
		var button := make_button("Tối đa" if cost < 0 else "Nâng: %d Xu" % cost, &"GoldButton")
		button.custom_minimum_size.x = 170
		button.disabled = cost < 0 or not EconomyManager.can_afford(EconomyManager.COINS, cost)
		button.pressed.connect(func() -> void:
			if ShopManager.buy_upgrade(id):
				_status_label.text = "%s lên cấp %d!" % [upgrade.name, ShopManager.get_upgrade_level(id)]
				AudioManager.play(&"upgrade")
			refresh())
		line.add_child(button)
		action_buttons["upgrade_%s" % id] = button
		_body.add_child(card)


func _tower_name(def: ItemDef) -> String:
	var data := ItemSlot.get_tower_data(def.tower_id)
	return data.display_name if data else String(def.tower_id)
