extends CanvasLayer
## ToastLayer (Autoload): thông báo nhỏ ở góc trên bên phải (thành tựu, lên cấp...).
##
## - Xếp hàng: mỗi lúc chỉ một thông báo, cái sau chờ cái trước xong.
## - Không chặn thao tác (mouse_filter = IGNORE), không pause game, chạy cả khi đang pause.
## - Trượt vào từ mép phải 0.25s, giữ 3s, trượt ra; "Giảm chuyển động" thì chỉ mờ dần.

const HOLD_TIME := 3.0
const SLIDE_TIME := 0.25
const WIDTH := 320.0
const MARGIN := 16.0
const TOP := 72.0

var _queue: Array[Dictionary] = []
var _card: PanelContainer
var _caption: Label
var _title: Label
var _detail: Label
var _showing := false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	Events.achievement_unlocked.connect(_on_achievement_unlocked)
	Events.level_up.connect(func(level: int) -> void:
		push("LÊN CẤP", "Cấp %d" % level, "+%d Xu" % (ProgressionManager.LEVEL_UP_COINS_PER_LEVEL * level),
				Color("#4EA8DE")))


## Thêm một thông báo vào hàng đợi.
func push(caption: String, title: String, detail: String = "", accent: Color = Color("#FFC72C")) -> void:
	_queue.append({"caption": caption, "title": title, "detail": detail, "accent": accent})
	if not _showing:
		_show_next()


func is_showing() -> bool:
	return _showing


func get_queue_size() -> int:
	return _queue.size()


## Bỏ mọi thông báo đang chờ / đang hiện (test dùng).
func clear() -> void:
	_queue.clear()
	_showing = false
	_card.hide()


func _on_achievement_unlocked(id: StringName) -> void:
	var def: AchievementDef = AchievementManager.defs.get(id)
	if def:
		push("THÀNH TỰU MỚI", def.title, "Nhận thưởng ở menu Thành tựu: %s" % def.reward_text())
		AudioManager.play(&"achievement")


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		_card.hide()
		return
	_showing = true
	var toast: Dictionary = _queue.pop_front()
	_caption.text = toast.caption
	_caption.add_theme_color_override("font_color", toast.accent)
	_title.text = toast.title
	_detail.text = toast.detail
	_detail.visible = not toast.detail.is_empty()
	var style := _card.get_theme_stylebox("panel") as StyleBoxFlat
	style.border_color = toast.accent

	_card.show()
	_card.size = Vector2(WIDTH, 0)
	_card.reset_size()
	var viewport_width := _card.get_viewport_rect().size.x
	var shown_x := viewport_width - WIDTH - MARGIN
	var hidden_x := viewport_width + 8.0
	var tween := create_tween()
	if VisualSettings.reduced_motion:
		_card.position = Vector2(shown_x, TOP)
		_card.modulate.a = 0.0
		tween.tween_property(_card, "modulate:a", 1.0, SLIDE_TIME)
		tween.tween_interval(HOLD_TIME)
		tween.tween_property(_card, "modulate:a", 0.0, SLIDE_TIME)
	else:
		_card.modulate.a = 1.0
		_card.position = Vector2(hidden_x, TOP)
		tween.tween_property(_card, "position:x", shown_x, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(HOLD_TIME)
		tween.tween_property(_card, "position:x", hidden_x, SLIDE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next)


func _build() -> void:
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.custom_minimum_size = Vector2(WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.14, 0.95)
	style.border_width_left = 4
	style.border_color = Color("#FFC72C")
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	_card.add_child(box)
	_caption = _label(12)
	_title = _label(18)
	_detail = _label(13)
	_detail.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Nhãn tự xuống dòng cần bề rộng cố định, nếu không nó xuống dòng từng chữ và kéo dài thẻ.
	_detail.custom_minimum_size.x = WIDTH - 30.0
	for label in [_caption, _title, _detail]:
		box.add_child(label)
	add_child(_card)
	_card.hide()


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	return label
