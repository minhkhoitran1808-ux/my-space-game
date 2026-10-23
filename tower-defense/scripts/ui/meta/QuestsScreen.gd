class_name QuestsScreen
extends MetaScreen
## Màn hình Nhiệm vụ: quà đăng nhập 7 ngày (không reset khi bỏ lỡ) + nhiệm vụ ngày
## (tích luỹ tối đa 3 ngày, đổi miễn phí 1 nhiệm vụ mỗi ngày).

var login_button: Button
## index -> nút Nhận / Đổi của từng nhiệm vụ (test bấm thử).
var claim_buttons: Dictionary = {}
var reroll_buttons: Dictionary = {}
var _login_row: HBoxContainer
var _list: VBoxContainer


func _build_content() -> void:
	title_label.text = "NHIỆM VỤ"
	content.add_child(make_label("QUÀ ĐĂNG NHẬP  ·  bỏ lỡ ngày nào cũng không mất chuỗi", 14, COLOR_GOLD))
	var login_box := HBoxContainer.new()
	login_box.add_theme_constant_override("separation", 10)
	_login_row = HBoxContainer.new()
	_login_row.add_theme_constant_override("separation", 8)
	_login_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_box.add_child(_login_row)
	login_button = make_button("Nhận quà hôm nay", &"GoldButton")
	login_button.custom_minimum_size = Vector2(190, 60)
	login_button.pressed.connect(func() -> void:
		if not DailyManager.claim_login().is_empty():
			AudioManager.play(&"sell")
		refresh())
	login_box.add_child(login_button)
	content.add_child(login_box)
	content.add_child(make_label("NHIỆM VỤ NGÀY  ·  giữ tối đa 3 ngày, đổi miễn phí 1 nhiệm vụ mỗi ngày", 14, COLOR_GOLD))
	_list = make_scroll_list(content)


func refresh() -> void:
	DailyManager.refresh_day()
	clear_children(_login_row)
	var next := DailyManager.get_login_index()
	var can_claim := DailyManager.can_claim_login()
	for i in DailyManager.LOGIN_REWARDS.size():
		var done := i < next or (not can_claim and i == next - 1)
		var current := i == next and can_claim
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(84, 60)
		var accent := COLOR_GOLD if current else (Color("#38B000") if done else Color(1, 1, 1, 0.2))
		cell.add_theme_stylebox_override("panel", card_style(accent))
		var box := VBoxContainer.new()
		box.add_child(make_label("Ngày %d" % (i + 1), 12, accent.lightened(0.2)))
		box.add_child(make_label(_reward_text(DailyManager.LOGIN_REWARDS[i]), 12, COLOR_MUTED if done else Color.WHITE))
		cell.add_child(box)
		_login_row.add_child(cell)
	login_button.disabled = not can_claim
	login_button.text = "Nhận quà hôm nay" if can_claim else "Mai quay lại nhé"

	clear_children(_list)
	claim_buttons.clear()
	reroll_buttons.clear()
	var active := DailyManager.get_active()
	if active.is_empty():
		_list.add_child(make_label("Chưa có nhiệm vụ.", 15, COLOR_MUTED))
	for i in active.size():
		_list.add_child(_make_quest_card(i, active[i]))


func _make_quest_card(index: int, quest: Dictionary) -> Control:
	var def := DailyManager.get_def(quest)
	var progress := DailyManager.get_progress(quest)
	var claimed: bool = quest.get("claimed", false)
	var complete := DailyManager.is_complete(quest)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(Color("#38B000") if complete else Color("#4EA8DE")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var age := DailyManager.days_between(quest.day, DailyManager.today())
	info.add_child(make_label(def.get_text() + ("" if age == 0 else "   (từ %d ngày trước)" % age), 16))
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	progress_row.add_child(make_progress_bar(float(progress.x) / maxf(progress.y, 1), Color("#4EA8DE")))
	progress_row.add_child(make_label("%d / %d" % [progress.x, progress.y], 12, COLOR_MUTED))
	info.add_child(progress_row)
	row.add_child(info)
	row.add_child(make_label("%d Xu + %d KN" % [def.reward_coins, def.reward_exp], 13, COLOR_GOLD))

	var reroll := make_button("Đổi")
	reroll.tooltip_text = "Đổi nhiệm vụ này (miễn phí, 1 lần mỗi ngày)"
	reroll.disabled = claimed or complete or not DailyManager.can_reroll()
	reroll.pressed.connect(func() -> void:
		DailyManager.reroll(index)
		refresh())
	row.add_child(reroll)
	reroll_buttons[index] = reroll
	var claim := make_button("Đã nhận" if claimed else ("Nhận" if complete else "Chưa xong"), &"GoldButton" if complete and not claimed else &"")
	claim.custom_minimum_size.x = 120
	claim.disabled = claimed or not complete
	claim.pressed.connect(func() -> void:
		if DailyManager.claim_quest(index):
			AudioManager.play(&"sell")
		refresh())
	row.add_child(claim)
	claim_buttons[index] = claim
	return card


func _reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	for key: String in reward:
		parts.append("%d %s" % [int(reward[key]), ShopManager.display_name(key)])
	return "\n".join(parts)
