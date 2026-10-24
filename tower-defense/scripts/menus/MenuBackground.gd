extends Control
## Nền trang trí cho các menu: cỏ ô cờ tối màu và một con đường uốn lượn (vẽ bằng code).

@export var grass_color_a := Color(0.16, 0.27, 0.17)
@export var grass_color_b := Color(0.15, 0.25, 0.16)
@export var path_color := Color(0.42, 0.34, 0.23)
@export var cell_size := 64


func _draw() -> void:
	var columns := ceili(size.x / cell_size)
	var rows := ceili(size.y / cell_size)
	for y in rows:
		for x in columns:
			draw_rect(Rect2(x * cell_size, y * cell_size, cell_size, cell_size),
					grass_color_a if (x + y) % 2 == 0 else grass_color_b)

	var points := PackedVector2Array([
		Vector2(-40, size.y * 0.25), Vector2(size.x * 0.2, size.y * 0.25),
		Vector2(size.x * 0.2, size.y * 0.75), Vector2(size.x * 0.55, size.y * 0.75),
		Vector2(size.x * 0.55, size.y * 0.35), Vector2(size.x * 0.82, size.y * 0.35),
		Vector2(size.x * 0.82, size.y * 0.85), Vector2(size.x + 40, size.y * 0.85),
	])
	draw_polyline(points, path_color, 48.0)
	for point in points:
		draw_circle(point, 24.0, path_color)
	# Phủ tối để chữ và nút dễ đọc.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
