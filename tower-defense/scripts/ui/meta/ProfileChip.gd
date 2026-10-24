class_name ProfileChip
extends PanelContainer
## Thẻ hồ sơ ở góc menu chính: cấp + danh hiệu, thanh KN, Xu và Bụi.
## Bấm vào danh hiệu để đổi sang danh hiệu khác đã có.

var title_button: Button
var _level_label: Label
var _exp_label: Label
var _wallet_label: Label
var _bar_holder: HBoxContainer


func _ready() -> void:
	theme = MetaScreen.HUD_THEME
	theme_type_variation = &"StatChip"
	custom_minimum_size = Vector2(300, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var top := HBoxContainer.new()
	_level_label = MetaScreen.make_label("", 20, MetaScreen.COLOR_GOLD)
	top.add_child(_level_label)
	title_button = Button.new()
	title_button.flat = true
	title_button.add_theme_font_size_override("font_size", 14)
	title_button.tooltip_text = "Bấm để đổi danh hiệu"
	title_button.pressed.connect(_cycle_title)
	top.add_child(title_button)
	box.add_child(top)
	_bar_holder = HBoxContainer.new()
	box.add_child(_bar_holder)
	var bottom := HBoxContainer.new()
	_exp_label = MetaScreen.make_label("", 12, MetaScreen.COLOR_MUTED)
	_exp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_exp_label)
	_wallet_label = MetaScreen.make_label("", 14, Color.WHITE)
	bottom.add_child(_wallet_label)
	box.add_child(bottom)
	refresh()


func refresh() -> void:
	var level := ProgressionManager.get_level()
	var exp := ProgressionManager.get_exp()
	var needed := ProgressionManager.exp_to_next(level)
	_level_label.text = "Cấp %d" % level
	var title := ProgressionManager.get_active_title()
	title_button.text = "« %s »" % title if not title.is_empty() else ""
	title_button.visible = not title.is_empty()
	MetaScreen.clear_children(_bar_holder)
	_bar_holder.add_child(MetaScreen.make_progress_bar(float(exp) / needed, Color("#4EA8DE"), 8))
	_exp_label.text = "%d / %d KN" % [exp, needed]
	_wallet_label.text = "%d Xu  ·  %d Bụi" % [EconomyManager.get_amount(EconomyManager.COINS),
			EconomyManager.get_amount(EconomyManager.DUST)]


func _cycle_title() -> void:
	var titles := ProgressionManager.get_titles()
	if titles.size() < 2:
		return
	var index := titles.find(ProgressionManager.get_active_title())
	ProgressionManager.set_active_title(titles[(index + 1) % titles.size()])
	refresh()
