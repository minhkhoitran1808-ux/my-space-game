extends Node2D
## Nền tạm của bản đồ (thay cho TileMapLayer khi chưa có asset).
##
## Vẽ cỏ dạng ô cờ, đường đi theo Curve2D của Path2D, điểm xuất phát và nhà chính.
## Khi có tileset thật, có thể thay node này bằng TileMapLayer mà không ảnh hưởng
## các hệ thống khác (chỉ cần giữ đúng GameConfig.CELL_SIZE).

@export var enemy_path: Path2D

@export_group("Màu sắc")
@export var background_color := Color(0.12, 0.14, 0.16)
@export var grass_color_a := Color(0.24, 0.42, 0.24)
@export var grass_color_b := Color(0.22, 0.39, 0.22)
@export var path_color := Color(0.62, 0.5, 0.33)
@export var path_border_color := Color(0.42, 0.33, 0.2)
@export var base_color := Color(0.3, 0.55, 0.9)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(get_viewport_rect(), background_color)
	_draw_grass()
	if enemy_path and enemy_path.curve and enemy_path.curve.point_count >= 2:
		_draw_path()
		_draw_base()


func _draw_grass() -> void:
	var area := GameConfig.BUILD_AREA
	var cell := GameConfig.CELL_SIZE
	var first := GameConfig.world_to_cell(area.position)
	var last := GameConfig.world_to_cell(area.end - Vector2.ONE)
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			var color := grass_color_a if (x + y) % 2 == 0 else grass_color_b
			draw_rect(Rect2(x * cell, y * cell, cell, cell), color)


func _draw_path() -> void:
	var curve := enemy_path.curve
	var points := curve.get_baked_points()
	for i in points.size():
		points[i] = enemy_path.to_global(points[i])

	# Vẽ viền trước rồi mới vẽ mặt đường; hình tròn ở mỗi điểm giúp bo tròn góc cua.
	var width := GameConfig.PATH_WIDTH
	_draw_path_layer(curve, points, width + 8.0, path_border_color)
	_draw_path_layer(curve, points, width, path_color)


func _draw_path_layer(curve: Curve2D, points: PackedVector2Array, width: float, color: Color) -> void:
	draw_polyline(points, color, width)
	for i in curve.point_count:
		draw_circle(enemy_path.to_global(curve.get_point_position(i)), width * 0.5, color)


func _draw_base() -> void:
	var curve := enemy_path.curve
	var base_pos := enemy_path.to_global(curve.get_point_position(curve.point_count - 1))
	var size := Vector2(56, 56)
	draw_rect(Rect2(base_pos - size * 0.5, size), base_color)
	draw_rect(Rect2(base_pos - size * 0.5, size), base_color.darkened(0.5), false, 3.0)
	var font := ThemeDB.fallback_font
	# Căn phải theo mép nhà để chữ không bị tràn khỏi màn hình.
	draw_string(font, base_pos + Vector2(size.x * 0.5 - 100.0, -size.y * 0.5 - 8.0), "NHÀ CHÍNH",
			HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 14)
