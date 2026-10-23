class_name RewardSummary
extends VBoxContainer
## Khối "phần thưởng" trong bảng kết thúc ván: xu và KN đếm lên, thanh KN chạy tới mức mới
## (lên cấp thì chạy đầy, báo "LÊN CẤP", rồi chạy tiếp), và danh sách vật phẩm rơi.
## Dựng hoàn toàn bằng code; HUD chèn vào thẻ kết quả. Tween chạy cả khi game đang pause.

const COLOR_COINS := Color("#FFC72C")
const COLOR_EXP := Color("#4EA8DE")
const COUNT_TIME := 0.6
const BAR_TIME := 0.5

var _currency_label: Label
var _level_label: Label
var _exp_label: Label
var _items_label: Label
var _bar: Control
## Tỉ lệ thanh KN đang vẽ (0..1).
var _fill := 0.0


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_currency_label = _make_label(20, COLOR_COINS, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_currency_label)

	var row := HBoxContainer.new()
	_level_label = _make_label(14, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_exp_label = _make_label(14, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT)
	_exp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_level_label)
	row.add_child(_exp_label)
	add_child(row)

	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 10)
	_bar.draw.connect(_draw_bar)
	add_child(_bar)

	_items_label = _make_label(14, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	_items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_items_label)
	hide()


## rewards: ProgressionManager.grant_match_rewards() (+ "items": tên vật phẩm rơi, nếu có).
func play(rewards: Dictionary) -> void:
	show()
	var items: Array = rewards.get("items", [])
	_items_label.visible = not items.is_empty()
	_items_label.text = "Nhận được: " + ", ".join(items)
	_set_level_text(rewards.level_before, rewards.exp_before)
	_fill = float(rewards.exp_before) / ProgressionManager.exp_to_next(rewards.level_before)
	_bar.queue_redraw()

	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_currency_label.text = "+%d Xu    +%d KN" % [roundi(rewards.coins * t), roundi(rewards.exp * t)],
		0.0, 1.0, COUNT_TIME)
	var level: int = rewards.level_before
	for i in rewards.levels_gained:
		tween.tween_method(_set_fill, _fill if i == 0 else 0.0, 1.0, BAR_TIME)
		level += 1
		var reached := level
		tween.tween_callback(func() -> void:
			_set_level_text(reached, 0)
			_level_label.text = "LÊN CẤP %d!" % reached
			UiFx.pulse(_level_label, 1.3, 0.3)
			_fill = 0.0)
	var target := float(rewards.exp_after) / ProgressionManager.exp_to_next(rewards.level_after)
	tween.tween_method(_set_fill, _fill if rewards.levels_gained == 0 else 0.0, target, BAR_TIME)
	tween.tween_callback(_set_level_text.bind(rewards.level_after, rewards.exp_after))


func _set_level_text(level: int, exp: int) -> void:
	_level_label.text = "Cấp %d" % level
	_exp_label.text = "%d / %d KN" % [exp, ProgressionManager.exp_to_next(level)]


func _set_fill(value: float) -> void:
	_fill = value
	_bar.queue_redraw()


func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, _bar.size)
	_bar.draw_rect(rect, Color(0, 0, 0, 0.45))
	_bar.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(_fill, 0.0, 1.0), rect.size.y)), COLOR_EXP)
	_bar.draw_rect(rect, Color(1, 1, 1, 0.15), false, 1.0)


func _make_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
