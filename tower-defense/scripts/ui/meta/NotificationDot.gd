class_name NotificationDot
extends Control
## Chấm đỏ có số ở góc trên phải của một nút (vd "có 3 thưởng chưa nhận").
## count = 0 thì ẩn. Gắn bằng NotificationDot.attach(button).

const COLOR := Color("#E63946")
const DIAMETER := 20.0

var count := 0:
	set(value):
		count = value
		visible = count > 0
		queue_redraw()


## Tạo chấm và gắn vào góc trên phải của nút.
static func attach(button: Control) -> NotificationDot:
	var dot := NotificationDot.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	dot.size = Vector2(DIAMETER, DIAMETER)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.position = Vector2(-DIAMETER * 0.6, -DIAMETER * 0.4)
	button.add_child(dot)
	dot.count = 0
	return dot


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, DIAMETER * 0.5, COLOR)
	draw_arc(center, DIAMETER * 0.5, 0.0, TAU, 24, Color(0, 0, 0, 0.5), 1.5, true)
	var font := ThemeDB.fallback_font
	var text := str(count) if count < 10 else "9+"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(font, center + Vector2(-text_size.x * 0.5, 4.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
