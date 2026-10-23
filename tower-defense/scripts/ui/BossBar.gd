class_name BossBar
extends Control
## Thanh máu Boss trên HUD (giữa, ngay dưới thanh trên cùng).
##
## Dùng lại component HealthBar (cùng màu theo ngưỡng, vệt sát thương, vạch chia 25%),
## chỉ phóng to và thêm tên + số máu. Main gọi track() mỗi khi có địch tinh nhuệ xuất hiện;
## có nhiều Boss cùng lúc thì hiện con đầu tiên kèm "×N", con đó mất thì chuyển con kế tiếp.
## Chỉ nghe signal của Enemy (health_changed, tree_exiting), không đụng logic trận.

const HEALTH_BAR_SCENE := preload("res://scenes/enemies/HealthBar.tscn")
const BAR_SIZE := Vector2(440, 12)
const FADE_TIME := 0.2

var _bosses: Array[Enemy] = []
var _current: Enemy = null
var _bar: HealthBar
var _name_label: Label
var _value_label: Label
var _fade_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label = _make_label(HORIZONTAL_ALIGNMENT_LEFT, Color(1.0, 0.82, 0.82))
	_value_label = _make_label(HORIZONTAL_ALIGNMENT_RIGHT, Color(0.92, 0.92, 0.95))
	_bar = HEALTH_BAR_SCENE.instantiate()
	_bar.z_index = 0 # Trong HUD: không được nổi lên trên menu tạm dừng / bảng kết quả.
	_bar.bar_size = BAR_SIZE
	_bar.always_visible = true
	_bar.show_ticks = true
	add_child(_bar)
	resized.connect(_layout)
	_layout()
	hide()


## Theo dõi một Boss mới xuất hiện.
func track(enemy: Enemy) -> void:
	if enemy in _bosses:
		return
	_bosses.append(enemy)
	enemy.tree_exiting.connect(_on_boss_exiting.bind(enemy), CONNECT_ONE_SHOT)
	if _current == null:
		_show_boss(enemy)
	_update_name()


## Boss đang hiển thị (null nếu không có).
func get_current_boss() -> Enemy:
	return _current


func get_health_bar() -> HealthBar:
	return _bar


func _show_boss(enemy: Enemy) -> void:
	_current = enemy
	enemy.health_changed.connect(_on_health_changed)
	_bar.set_health(enemy.health, enemy.max_health, false)
	_update_value(enemy.health, enemy.max_health)
	_update_name()
	if not visible:
		show()
		_fade_to(1.0)


func _on_boss_exiting(enemy: Enemy) -> void:
	_bosses.erase(enemy)
	if enemy != _current:
		_update_name()
		return
	if enemy.health_changed.is_connected(_on_health_changed):
		enemy.health_changed.disconnect(_on_health_changed)
	_current = null
	if not is_inside_tree():
		return
	if _bosses.is_empty():
		_bar.set_health(0.0, 1.0)
		_fade_to(0.0)
	else:
		_show_boss(_bosses[0])


func _on_health_changed(current: float, maximum: float) -> void:
	_bar.set_health(current, maximum)
	_update_value(current, maximum)


func _update_name() -> void:
	if _current == null:
		return
	var text := "BOSS · %s" % _current.data.display_name
	if _bosses.size() > 1:
		text += "  ×%d" % _bosses.size()
	_name_label.text = text


func _update_value(current: float, maximum: float) -> void:
	_value_label.text = "%d / %d" % [ceili(current), roundi(maximum)]


func _fade_to(alpha: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, FADE_TIME).from(modulate.a if visible else 0.0)
	if alpha <= 0.0:
		_fade_tween.tween_callback(hide)


func _layout() -> void:
	var width := size.x
	_name_label.position = Vector2(0, 0)
	_name_label.size = Vector2(width, 18)
	_value_label.position = Vector2(0, 0)
	_value_label.size = Vector2(width, 18)
	_bar.position = Vector2(roundf(width * 0.5), 22)


func _make_label(alignment: HorizontalAlignment, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label
