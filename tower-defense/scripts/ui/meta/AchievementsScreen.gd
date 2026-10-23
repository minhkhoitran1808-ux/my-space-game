class_name AchievementsScreen
extends MetaScreen
## Màn hình Thành tựu: tổng tiến độ, tab lọc (Tất cả / Đang làm / Hoàn thành / Ẩn),
## mỗi thành tựu là một thẻ có thanh tiến độ "x / y", phần thưởng và nút "Nhận".
## Thành tựu ẩn chưa mở hiện "???".

enum Filter { ALL, IN_PROGRESS, DONE, HIDDEN }

const FILTER_NAMES := ["Tất cả", "Đang làm", "Hoàn thành", "Ẩn"]
const CATEGORY_COLORS := [Color("#4EA8DE"), Color("#F77F00"), Color("#38B000"), Color("#A335EE")]
const CATEGORY_ICONS := [HudIcon.Kind.FLAG, HudIcon.Kind.TROPHY, HudIcon.Kind.WAVE, HudIcon.Kind.SKULL]

var filter: Filter = Filter.ALL
var claim_all_button: Button
var _summary_label: Label
var _summary_bar_holder: HBoxContainer
var _list: VBoxContainer
var _filter_buttons: Array[Button] = []
## id -> nút "Nhận" của thẻ đang hiển thị (test bấm thử).
var claim_buttons: Dictionary = {}


func _build_content() -> void:
	title_label.text = "THÀNH TỰU"
	claim_all_button = make_button("Nhận tất cả", &"GoldButton")
	claim_all_button.pressed.connect(func() -> void:
		AchievementManager.claim_all()
		refresh())
	header_extra.add_child(claim_all_button)

	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 14)
	_summary_label = make_label("", 16, COLOR_GOLD)
	summary.add_child(_summary_label)
	_summary_bar_holder = HBoxContainer.new()
	_summary_bar_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_bar_holder.alignment = BoxContainer.ALIGNMENT_CENTER
	summary.add_child(_summary_bar_holder)
	content.add_child(summary)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for i in FILTER_NAMES.size():
		var tab := make_button(FILTER_NAMES[i])
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = i == filter
		tab.custom_minimum_size.x = 120
		tab.pressed.connect(func() -> void:
			filter = i as Filter
			refresh())
		tabs.add_child(tab)
		_filter_buttons.append(tab)
	content.add_child(tabs)
	_list = make_scroll_list(content)


func refresh() -> void:
	var total := AchievementManager.defs.size()
	var unlocked := AchievementManager.get_unlocked_count()
	_summary_label.text = "%d / %d thành tựu (%d%%)" % [unlocked, total, roundi(100.0 * unlocked / maxf(total, 1))]
	clear_children(_summary_bar_holder)
	_summary_bar_holder.add_child(make_progress_bar(float(unlocked) / maxf(total, 1), COLOR_GOLD, 10))
	var unclaimed := AchievementManager.get_unclaimed_count()
	claim_all_button.disabled = unclaimed == 0
	claim_all_button.text = "Nhận tất cả (%d)" % unclaimed if unclaimed > 0 else "Nhận tất cả"

	clear_children(_list)
	claim_buttons.clear()
	for def in AchievementManager.get_sorted():
		if _passes_filter(def):
			_list.add_child(_make_card(def))


func _passes_filter(def: AchievementDef) -> bool:
	var unlocked := AchievementManager.is_unlocked(def.id)
	match filter:
		Filter.IN_PROGRESS:
			return not unlocked and not def.is_hidden()
		Filter.DONE:
			return unlocked
		Filter.HIDDEN:
			return def.is_hidden()
		_:
			return true


func _make_card(def: AchievementDef) -> Control:
	var unlocked := AchievementManager.is_unlocked(def.id)
	var claimed := AchievementManager.is_claimed(def.id)
	var secret := def.is_hidden() and not unlocked
	var accent: Color = CATEGORY_COLORS[def.category]
	if not unlocked:
		accent = accent.darkened(0.45)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(accent))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon := HudIcon.new()
	icon.kind = CATEGORY_ICONS[def.category]
	icon.color = accent if unlocked else Color(0.5, 0.5, 0.55)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	title_row.add_child(make_label("???" if secret else def.title, 17))
	title_row.add_child(make_label(AchievementDef.CATEGORY_NAMES[def.category], 12, accent.lightened(0.3)))
	info.add_child(title_row)
	var description := make_label("Thành tựu ẩn: tiếp tục chơi để khám phá." if secret else def.description, 13, COLOR_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(description)
	if not secret:
		var progress := AchievementManager.get_progress(def)
		var progress_row := HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 10)
		progress_row.add_child(make_progress_bar(float(progress.x) / maxf(progress.y, 1), accent.lightened(0.15)))
		progress_row.add_child(make_label("%d / %d" % [progress.x, progress.y], 12, COLOR_MUTED))
		info.add_child(progress_row)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 210
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var reward := make_label("???" if secret else def.reward_text(), 13, COLOR_GOLD)
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(reward)
	var button: Button
	if claimed:
		button = make_button("Đã nhận")
		button.disabled = true
	elif unlocked:
		button = make_button("Nhận", &"GoldButton")
		button.pressed.connect(func() -> void:
			if AchievementManager.claim(def.id):
				AudioManager.play(&"sell")
			refresh())
	else:
		button = make_button("Chưa xong")
		button.disabled = true
	claim_buttons[def.id] = button
	right.add_child(button)
	return card
