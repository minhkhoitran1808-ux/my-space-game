@tool
class_name HudIcon
extends Control
## Icon vector đơn giản cho HUD, vẽ bằng đa giác (không cần file ảnh, nét ở mọi độ phân giải).
##
## Dùng trong các ô thông tin (vàng, máu, wave) và bảng thắng / thua. Đổi "kind" / "color"
## ngay trong Inspector; icon tự vẽ lại và co giãn theo kích thước của Control.

enum Kind { COIN, HEART, WAVE, TROPHY, SKULL, FLAG }

@export var kind: Kind = Kind.COIN:
	set(value):
		kind = value
		queue_redraw()
@export var color: Color = Color("#FFC72C"):
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(28, 28)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var dark := color.darkened(0.45)
	match kind:
		Kind.COIN:
			draw_circle(c, s * 0.46, dark)
			draw_circle(c, s * 0.40, color)
			draw_arc(c, s * 0.28, 0.0, TAU, 24, dark, maxf(1.5, s * 0.06))
			# Vệt sáng nhỏ để đồng xu trông nổi khối.
			draw_arc(c, s * 0.34, PI * 1.1, PI * 1.45, 8, color.lightened(0.5), maxf(1.0, s * 0.05))
		Kind.HEART:
			draw_colored_polygon(_heart_points(c, s * 0.46), dark)
			draw_colored_polygon(_heart_points(c + Vector2(0, -s * 0.02), s * 0.38), color)
			draw_circle(c + Vector2(-s * 0.13, -s * 0.12), s * 0.06, color.lightened(0.45))
		Kind.WAVE:
			# Ba "con sóng" xếp chồng = các đợt địch.
			for i in 3:
				var y := c.y + (i - 1) * s * 0.26
				var points := PackedVector2Array()
				for step in 9:
					var t := step / 8.0
					points.append(Vector2(c.x + (t - 0.5) * s * 0.8, y + sin(t * TAU) * s * 0.08))
				draw_polyline(points, color, maxf(2.0, s * 0.09), true)
		Kind.TROPHY:
			var cup := PackedVector2Array([
				c + Vector2(-0.32, -0.38) * s, c + Vector2(0.32, -0.38) * s,
				c + Vector2(0.24, -0.02) * s, c + Vector2(0.08, 0.1) * s,
				c + Vector2(-0.08, 0.1) * s, c + Vector2(-0.24, -0.02) * s])
			draw_arc(c + Vector2(-0.3, -0.2) * s, s * 0.13, PI * 0.5, PI * 1.5, 12, dark, s * 0.06)
			draw_arc(c + Vector2(0.3, -0.2) * s, s * 0.13, -PI * 0.5, PI * 0.5, 12, dark, s * 0.06)
			draw_colored_polygon(cup, color)
			draw_rect(Rect2(c + Vector2(-0.05, 0.08) * s, Vector2(0.1, 0.18) * s), dark)
			draw_rect(Rect2(c + Vector2(-0.22, 0.26) * s, Vector2(0.44, 0.12) * s), color)
		Kind.SKULL:
			draw_circle(c + Vector2(0, -0.06) * s, s * 0.36, color)
			draw_rect(Rect2(c + Vector2(-0.2, 0.14) * s, Vector2(0.4, 0.22) * s), color)
			draw_circle(c + Vector2(-0.14, -0.06) * s, s * 0.1, dark)
			draw_circle(c + Vector2(0.14, -0.06) * s, s * 0.1, dark)
			for i in 3:
				draw_rect(Rect2(c + Vector2(-0.13 + i * 0.1, 0.24) * s, Vector2(0.04, 0.12) * s), dark)
		Kind.FLAG:
			draw_rect(Rect2(c + Vector2(-0.3, -0.4) * s, Vector2(0.07, 0.8) * s), dark)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-0.23, -0.4) * s,
					c + Vector2(0.36, -0.22) * s, c + Vector2(-0.23, -0.04) * s]), color)


func _heart_points(center: Vector2, radius: float) -> PackedVector2Array:
	# Đường cong trái tim tham số (chuẩn hoá về bán kính "radius").
	var points := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y + 2.0) * radius / 17.0)
	return points
