extends Node2D
## Nền tạm của bản đồ (thay cho TileMapLayer khi chưa có asset).
##
## Vẽ cỏ dạng ô cờ, đường đi theo Curve2D của mọi làn (Path2D) trên bản đồ, và nhà chính
## ở cuối làn đầu tiên. Khi có tileset thật, có thể thay node này bằng TileMapLayer mà
## không ảnh hưởng các hệ thống khác (chỉ cần giữ đúng GameConfig.CELL_SIZE).

## Các làn đường cần vẽ (Main gọi setup() sau khi nạp bản đồ).
var paths: Array[Path2D] = []
## Bản đồ (để vẽ địa hình bùn / đồi). Có thể null.
var map: GameMap = null

@export_group("Màu sắc")
@export var background_color := Color(0.12, 0.14, 0.16)
@export var grass_color_a := Color(0.24, 0.42, 0.24)
@export var grass_color_b := Color(0.22, 0.39, 0.22)
@export var path_color := Color(0.62, 0.5, 0.33)
@export var path_border_color := Color(0.42, 0.33, 0.2)
@export var base_color := Color(0.3, 0.55, 0.9)


func setup(p_paths: Array[Path2D], p_map: GameMap = null) -> void:
	paths = p_paths
	map = p_map
	queue_redraw()


func _draw() -> void:
	# Vẽ tràn ra ngoài màn hình một chút để khi rung màn hình không lộ mép.
	draw_rect(get_viewport_rect().grow(32.0), background_color)
	_draw_grass()
	_draw_hills()
	if paths.is_empty():
		return
	# Vẽ viền của mọi làn trước rồi mới vẽ mặt đường, để chỗ các làn nhập nhau liền mạch.
	for path in paths:
		_draw_path_layer(path, GameConfig.PATH_WIDTH + 8.0, path_border_color)
	for path in paths:
		_draw_path_layer(path, GameConfig.PATH_WIDTH, path_color)
	_draw_mud()
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


## Đồi: cỏ sáng hơn + 2 đường đồng mức (vẽ dưới đường đi).
func _draw_hills() -> void:
	if map == null:
		return
	for points: PackedVector2Array in map.get_terrain_polygons(GameMap.TERRAIN_HILL):
		draw_colored_polygon(points, Color(0.36, 0.55, 0.3))
		var center := Vector2.ZERO
		for point in points:
			center += point
		center /= points.size()
		for scale in [0.8, 0.55]:
			var ring := PackedVector2Array()
			for point in points:
				ring.append(center + (point - center) * scale)
			ring.append(ring[0])
			draw_polyline(ring, Color(0.5, 0.7, 0.4), 2.0)


## Bùn: nâu sẫm có chấm, vẽ ĐÈ lên đường đi để thấy rõ đoạn đường bị chậm.
func _draw_mud() -> void:
	if map == null:
		return
	for points: PackedVector2Array in map.get_terrain_polygons(GameMap.TERRAIN_MUD):
		draw_colored_polygon(points, Color(0.33, 0.25, 0.16, 0.85))
		var bounds := Rect2(points[0], Vector2.ZERO)
		for point in points:
			bounds = bounds.expand(point)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(points)
		for i in int(bounds.get_area() / 400.0):
			var dot := bounds.position + Vector2(rng.randf(), rng.randf()) * bounds.size
			if Geometry2D.is_point_in_polygon(dot, points):
				draw_circle(dot, rng.randf_range(2.0, 4.0), Color(0.24, 0.18, 0.1))


## Vẽ một lớp của làn đường; hình tròn ở mỗi điểm giúp bo tròn góc cua.
func _draw_path_layer(path: Path2D, width: float, color: Color) -> void:
	var curve := path.curve
	var points := curve.get_baked_points()
	for i in points.size():
		points[i] = path.to_global(points[i])
	draw_polyline(points, color, width)
	for i in curve.point_count:
		draw_circle(path.to_global(curve.get_point_position(i)), width * 0.5, color)


func _draw_base() -> void:
	var path := paths[0]
	var base_pos := path.to_global(path.curve.get_point_position(path.curve.point_count - 1))
	var size := Vector2(56, 56)
	draw_rect(Rect2(base_pos - size * 0.5, size), base_color)
	draw_rect(Rect2(base_pos - size * 0.5, size), base_color.darkened(0.5), false, 3.0)
	var font := ThemeDB.fallback_font
	# Căn phải theo mép nhà để chữ không bị tràn khỏi màn hình.
	draw_string(font, base_pos + Vector2(size.x * 0.5 - 100.0, -size.y * 0.5 - 8.0), "NHÀ CHÍNH",
			HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 14)
